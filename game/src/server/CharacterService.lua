--[[
	CharacterService — owned character units: equip / unequip / Equip Best / upgrade /
	sell, and the server income tick (§67–§77, §100–§104).

	* Only EQUIPPED units earn Cash; income is computed server-side every tick (§72).
	* No offline income: income only accrues while the player is in the server (§74).
	* Equip Best ranks by actual $/sec only (§76).
	* Upgrade cost / result are computed on the server (§77).
	* Sell: client sends uids only; server validates ownership + computes payout (§103).
	* Multipliers: VIP pass and timed cash boost (both only if the Owner configures the
	  Robux items; default ×1).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Profile = require(Shared.Profile)
local Balance = require(Shared.Balance)
local Marketplace = require(Shared.MarketplaceConfig)
local Economy = require(Shared.Economy)

local CharacterService = {}

local function cashMultiplier(p, now: number): number
	local m = 1
	if p.entitlements.VIP then
		m *= Marketplace.GamePasses.VIP.perks.cashMultiplier
	end
	if (p.boosts.cash2x or 0) > now then
		m *= 2
	end
	return m
end
CharacterService.cashMultiplier = cashMultiplier

function CharacterService.Start(deps)
	local DataService, Remotes, FarmService = deps.DataService, deps.Remotes, deps.FarmService

	Remotes.onEvent("RequestEquipCharacter", function(player, uid)
		if type(uid) ~= "string" then
			return
		end
		local ok, why = DataService.mutate(player, function(p)
			return Profile.equip(p, uid)
		end)
		if not ok and why == "no free slot" then
			Remotes.notify(player, "warn", "No free character slot — upgrade your Farm or unequip one")
		end
	end)

	Remotes.onEvent("RequestUnequipCharacter", function(player, uid)
		if type(uid) ~= "string" then
			return
		end
		DataService.mutate(player, function(p)
			return Profile.unequip(p, uid)
		end)
	end)

	Remotes.onEvent("RequestEquipBest", function(player)
		DataService.mutate(player, function(p)
			return true, Profile.equipBest(p)
		end)
		Remotes.notify(player, "ok", "Equipped your best $/sec characters")
	end)

	Remotes.onInvoke("RequestUpgradeCharacter", function(player, uid)
		if type(uid) ~= "string" then
			return false, "bad request"
		end
		local ok, result = DataService.mutate(player, function(p)
			return Profile.upgradeUnit(p, uid)
		end)
		if not ok then
			return false, result
		end
		return true, { level = result.unit.level, cost = result.cost, income = Economy.incomeAt(result.unit.characterId, result.unit.level) }
	end)

	Remotes.onInvoke("RequestSellCharacters", function(player, uids)
		if type(uids) ~= "table" then
			return false, "bad request"
		end
		local clean = {}
		for i, uid in uids do
			if type(i) ~= "number" or type(uid) ~= "string" or #uid > 64 then
				return false, "bad request"
			end
			table.insert(clean, uid)
		end
		local ok, result = DataService.mutate(player, function(p)
			return Profile.sell(p, clean)
		end)
		if not ok then
			return false, result
		end
		return true, result.payout, result.count
	end)

	Remotes.onEvent("RequestUpgradeFarm", function(player)
		CharacterService.UpgradeFarm(player)
	end)

	-- income tick (§72): active units only, while online (§74)
	task.spawn(function()
		while true do
			task.wait(Balance.IncomeTickSeconds)
			local now = DataService.Now()
			for _, player in Players:GetPlayers() do
				local p = DataService.Get(player)
				if p and FarmService.GetPlayerFarm(player) then
					local income = Profile.activeIncome(p)
					if income > 0 then
						p.cash += math.floor(income * cashMultiplier(p, now) * Balance.IncomeTickSeconds)
						DataService.touchNumbers(player)
					end
				end
			end
		end
	end)
	CharacterService._deps = deps
end

-- Shared by the Farm Upgrade sign (ProximityPrompt) and the Upgrade menu remote.
function CharacterService.UpgradeFarm(player: Player): boolean
	local deps = CharacterService._deps
	if not deps.FarmService.GetPlayerFarm(player) then
		return false
	end
	local ok, result = deps.DataService.mutate(player, function(p)
		return Profile.upgradeFarm(p)
	end)
	if ok then
		deps.Remotes.notify(player, "ok", string.format("Farm Level %d — %d character slots!", result.level, result.slots))
	else
		deps.Remotes.notify(player, "warn", result == "max level" and "Farm is MAX LEVEL" or "Not enough Cash")
	end
	return ok
end

return CharacterService
