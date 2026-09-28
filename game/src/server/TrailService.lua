--[[
	TrailService — trail ownership, purchase and equip (§93–§99).

	* Exact tiers from Shared/Trails; ONE equipped trail; no stacking (§95).
	* Cash purchase: server-validated and priced (Profile.buyTrailCash) (§98).
	* Robux purchase: only when a Developer Product id is configured; otherwise the
	  request is refused (UI shows COMING SOON) — see MarketplaceService handler (§99).
	* The equipped trail's VFX (TrailFx) is attached to the character server-side so
	  all players see it; clients drive intensity by velocity (TrailFxClient).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Trails = require(Shared.Trails)
local Profile = require(Shared.Profile)
local TrailFx = require(Shared.TrailFx)

local TrailService = {}

local deps

local function applyTo(player: Player)
	local char = player.Character
	local p = deps.DataService.Get(player)
	if not char or not p then
		return
	end
	local tier = p.equippedTrail and Trails.BY_ID[p.equippedTrail]
	local current = char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("SAE_TrailFx")
	if tier and current and current:GetAttribute("TrailId") == tier.id then
		return
	end
	if tier then
		TrailFx.apply(char, tier)
	else
		TrailFx.clear(char)
	end
end

function TrailService.Start(d)
	deps = d
	d.Remotes.onInvoke("RequestBuyTrailCash", function(player, trailId)
		if type(trailId) ~= "string" or not Trails.BY_ID[trailId] then
			return false, "unknown trail"
		end
		local ok, result = d.DataService.mutate(player, function(p)
			local okBuy, res = Profile.buyTrailCash(p, trailId)
			if okBuy then
				Profile.equipTrail(p, trailId) -- buying equips it
			end
			return okBuy, res
		end)
		if ok then
			d.Remotes.notify(player, "ok", Trails.BY_ID[trailId].name .. " unlocked!  x" .. Trails.BY_ID[trailId].mult .. " Speed")
			applyTo(player)
			return true
		end
		return false, result
	end)
	d.Remotes.onEvent("RequestEquipTrail", function(player, trailId)
		if trailId ~= nil and type(trailId) ~= "string" then
			return
		end
		local ok = d.DataService.mutate(player, function(p)
			return Profile.equipTrail(p, trailId)
		end)
		if ok then
			applyTo(player)
		end
	end)
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("HumanoidRootPart", 10)
			applyTo(player)
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	d.DataService.OnLoaded(applyTo)
end

TrailService.applyTo = function(player)
	applyTo(player)
end

return TrailService
