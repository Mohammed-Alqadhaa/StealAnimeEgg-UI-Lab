--[[
	MarketService — Robux purchases (§98, §99, §139).

	* Only products/passes with a configured id can be prompted; everything else is
	  refused with "not configured" (the UI shows COMING SOON). OWNER ACTION REQUIRED
	  lists the items to create.
	* ProcessReceipt is idempotent: purchase ids are recorded in the profile and the
	  grant + record are saved before PurchaseGranted is returned (replay safe, §127).
	* Game passes (VIP, Starter Pack) are checked on join and on in-game purchase.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Config = require(Shared.MarketplaceConfig)
local Profile = require(Shared.Profile)
local Trails = require(Shared.Trails)

local MarketService = {}

local deps
local productById = {}

local function grant(p, product, now: number): boolean
	if product.kind == "cash" then
		p.cash += product.amount
	elseif product.kind == "speed" then
		p.speed += product.amount
	elseif product.kind == "boost" then
		p.boosts[product.boost] = math.max(p.boosts[product.boost] or 0, now) + product.seconds
	elseif product.kind == "trail" then
		if not Trails.BY_ID[product.trail] then
			return false
		end
		p.trails[product.trail] = true
		p.equippedTrail = product.trail
	else
		return false
	end
	return true
end

local function checkPasses(player: Player)
	for key, pass in Config.GamePasses do
		if pass.id then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
			if ok and owns then
				deps.DataService.mutate(player, function(p)
					if p.entitlements[key] then
						return false
					end
					p.entitlements[key] = true
					if pass.grant then
						p.cash += pass.grant.cash or 0
						p.speed += pass.grant.speed or 0
					end
					return true
				end)
			end
		end
	end
end

function MarketService.Start(d)
	deps = d
	for key, product in Config.DeveloperProducts do
		product.key = key
		if product.id then
			productById[product.id] = product
		end
	end

	d.Remotes.onEvent("RequestRobuxPurchase", function(player, key)
		if type(key) ~= "string" then
			return
		end
		local product = Config.DeveloperProducts[key]
		local pass = Config.GamePasses[key]
		if product and product.id then
			MarketplaceService:PromptProductPurchase(player, product.id)
		elseif pass and pass.id then
			MarketplaceService:PromptGamePassPurchase(player, pass.id)
		else
			d.Remotes.notify(player, "info", "Coming soon")
		end
	end)

	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		if not player or not d.DataService.IsLoaded(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local product = productById[info.ProductId]
		if not product then
			warn("[Market] unknown product id " .. tostring(info.ProductId))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local purchaseId = tostring(info.PurchaseId)
		local p = d.DataService.Get(player)
		if Profile.hasReceipt(p, purchaseId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted -- replay: already granted
		end
		local ok = d.DataService.mutate(player, function(prof)
			if not grant(prof, product, d.DataService.Now()) then
				return false
			end
			Profile.recordReceipt(prof, purchaseId)
			return true
		end)
		if not ok then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if not d.DataService.ForceSave(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet -- retried later; receipt id prevents double grant
		end
		if product.kind == "trail" then
			d.TrailService.applyTo(player)
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, _passId, purchased)
		if purchased then
			checkPasses(player)
		end
	end)
	d.DataService.OnLoaded(function(player)
		checkPasses(player)
	end)
end

return MarketService
