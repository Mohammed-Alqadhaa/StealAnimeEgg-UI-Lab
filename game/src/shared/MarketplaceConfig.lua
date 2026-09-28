--!strict
--[[
	MarketplaceConfig — Robux products / passes (Master Prompt §98, §99, §139).

	No Developer Product or Game Pass IDs exist yet, so every id is nil. A nil id means
	the Robux purchase action is DISABLED (the UI shows "COMING SOON") while the rest of
	the feature (e.g. Cash purchase of trails) works normally.

	OWNER ACTION REQUIRED: create the items below in Creator Dashboard and paste ids.
	Grants are fulfilled server-side in MarketplaceService.ProcessReceipt with receipt
	de-duplication persisted in the player's profile.
]]

return {
	DeveloperProducts = {
		-- cash packs: grant = amount of Cash (PROVISIONAL)
		CashSmall = { id = nil, kind = "cash", amount = 10000, label = "$10K" },
		CashMedium = { id = nil, kind = "cash", amount = 150000, label = "$150K" },
		CashLarge = { id = nil, kind = "cash", amount = 2500000, label = "$2.5M" },
		CashHuge = { id = nil, kind = "cash", amount = 50000000, label = "$50M" },
		SpeedPack = { id = nil, kind = "speed", amount = 500, label = "+500 Speed" },
		BoostCash15 = { id = nil, kind = "boost", boost = "cash2x", seconds = 900, label = "x2 Cash 15 min" },
		BoostSpeed15 = { id = nil, kind = "boost", boost = "speed2x", seconds = 900, label = "x2 Speed 15 min" },
		-- trail Robux purchases (one per tier, optional)
		Trail_breeze = { id = nil, kind = "trail", trail = "breeze" },
		Trail_dash = { id = nil, kind = "trail", trail = "dash" },
		Trail_streak = { id = nil, kind = "trail", trail = "streak" },
		Trail_surge = { id = nil, kind = "trail", trail = "surge" },
		Trail_ember = { id = nil, kind = "trail", trail = "ember" },
		Trail_voltage = { id = nil, kind = "trail", trail = "voltage" },
		Trail_storm = { id = nil, kind = "trail", trail = "storm" },
		Trail_nova = { id = nil, kind = "trail", trail = "nova" },
		Trail_eclipse = { id = nil, kind = "trail", trail = "eclipse" },
		Trail_divine = { id = nil, kind = "trail", trail = "divine" },
		Trail_monarch = { id = nil, kind = "trail", trail = "monarch" },
		Trail_infinity = { id = nil, kind = "trail", trail = "infinity" },
	},
	GamePasses = {
		VIP = { id = nil, perks = { cashMultiplier = 1.25 }, label = "VIP" },
		StarterPack = { id = nil, grant = { cash = 50000, speed = 100 }, label = "Starter Pack" },
	},
}
