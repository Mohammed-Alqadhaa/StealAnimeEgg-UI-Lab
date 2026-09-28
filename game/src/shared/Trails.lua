--!strict
--[[
	Trails — exact tiers (Master Prompt §95) and their visual identity (§96).
	Base (no trail) = x1.0. One trail equipped at a time; trails never stack.

	Visual progression: wind/light → energy streaks → sparks → lightning → cosmic →
	shadow/divine → layered top tiers. Every tier differs in more than colour:
	ribbon shape (width curve, lifetime, segments), aura emitter family, extra layers.
	`robuxProductId` is nil until the Owner creates Developer Products (OWNER ACTION).
]]

local Balance = require(script.Parent.Balance)

local T = {}

T.TIERS = {
	{ id = "breeze", name = "Breeze Trail", mult = 1.5, family = "wind", colors = { "#E8FBFF", "#9FE3FF" }, width = 1.6, life = 0.9, aura = "wisp" },
	{ id = "dash", name = "Dash Trail", mult = 2, family = "wind", colors = { "#B8FFE8", "#3FD6A0" }, width = 1.9, life = 1.1, aura = "wisp" },
	{ id = "streak", name = "Streak Trail", mult = 2.5, family = "energy", colors = { "#FFF27A", "#FF9A1F" }, width = 2.2, life = 1.3, aura = "streaks" },
	{ id = "surge", name = "Surge Trail", mult = 3, family = "energy", colors = { "#FF8FB0", "#D81B5A" }, width = 2.4, life = 1.5, aura = "streaks" },
	{
		id = "ember",
		name = "Ember Trail",
		mult = 3.5,
		family = "sparks",
		colors = { "#FFD23F", "#FF4D1A", "#7A1A0A" },
		width = 2.6,
		life = 1.7,
		aura = "embers",
	},
	{
		id = "voltage",
		name = "Voltage Trail",
		mult = 4,
		family = "lightning",
		colors = { "#E8F6FF", "#3FB6FF", "#1E3AFF" },
		width = 2.8,
		life = 1.9,
		aura = "sparks",
		arcs = true,
	},
	{
		id = "storm",
		name = "Storm Trail",
		mult = 4.5,
		family = "lightning",
		colors = { "#F6E8FF", "#9B4DFF", "#3A1F8F" },
		width = 3.0,
		life = 2.1,
		aura = "sparks",
		arcs = true,
	},
	{
		id = "nova",
		name = "Nova Trail",
		mult = 5,
		family = "cosmic",
		colors = { "#FFFFFF", "#FF9DE6", "#6FB8FF", "#1A1440" },
		width = 3.2,
		life = 2.4,
		aura = "stars",
	},
	{
		id = "eclipse",
		name = "Eclipse Trail",
		mult = 7,
		family = "shadow",
		colors = { "#FF3B30", "#3A0508", "#000000" },
		width = 3.4,
		life = 2.7,
		aura = "shadowflame",
		rings = true,
	},
	{
		id = "divine",
		name = "Divine Trail",
		mult = 10,
		family = "divine",
		colors = { "#FFFFFF", "#FFF2B8", "#FFC21F" },
		width = 3.6,
		life = 3.0,
		aura = "halo",
		rings = true,
		cycle = true,
	},
	{
		id = "monarch",
		name = "Monarch Trail",
		mult = 14,
		family = "divine",
		colors = { "#6A5BFF", "#3A7BFF", "#0B1020", "#C77DFF" },
		width = 3.9,
		life = 3.3,
		aura = "monarch",
		rings = true,
		arcs = true,
		cycle = true,
	},
	{
		id = "infinity",
		name = "Infinity Trail",
		mult = 20,
		family = "prismatic",
		colors = { "#FF4F7E", "#FFD23F", "#46D95F", "#35B8FF", "#9A5CFF" },
		width = 4.4,
		life = 3.8,
		aura = "prismatic",
		rings = true,
		arcs = true,
		cycle = true,
		layered = true,
	},
}

T.BY_ID = {}
for i, tier in T.TIERS do
	tier.index = i
	tier.cashPrice = Balance.TrailCashPrice[i]
	tier.robuxProductId = nil -- OWNER ACTION REQUIRED: Developer Product per tier (optional)
	T.BY_ID[tier.id] = tier
end

-- sanity: tiers must match the owner-locked multipliers exactly
for i, m in Balance.OWNER_LOCKED.TrailMultipliers do
	assert(T.TIERS[i].mult == m, "trail tier multiplier mismatch at " .. i)
end

function T.multiplierFor(trailId: string?): number
	local tier = trailId and T.BY_ID[trailId]
	return tier and tier.mult or 1.0
end

return T
