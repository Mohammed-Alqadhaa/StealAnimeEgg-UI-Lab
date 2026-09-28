--!strict
--[[
	Economy — pure, deterministic formulas. The server calls these; the client may call
	them for display only (the server re-computes everything it charges or pays).
]]

local Worlds = require(script.Parent.Worlds)
local Balance = require(script.Parent.Balance)

local E = {}

local function round(n: number): number
	return math.floor(n + 0.5)
end

function E.baseIncome(charId: string): number
	local c = Worlds.CHARACTERS[charId]
	assert(c, "unknown character " .. tostring(charId))
	local w = Worlds.WORLDS[c.world]
	return round(Balance.WorldBaseIncome[w.index] * Balance.SlotFactor[c.slot])
end

function E.incomeAt(charId: string, level: number): number
	local base = E.baseIncome(charId)
	return round(base * (1 + Balance.IncomePerLevel * (level - 1)))
end

-- Cost to go from `level` to `level + 1`; nil when already at max level.
function E.upgradeCost(charId: string, level: number): number?
	if level >= Balance.CharacterMaxLevel then
		return nil
	end
	return round(E.baseIncome(charId) * Balance.UpgradeCostBaseSeconds * Balance.UpgradeCostGrowth ^ (level - 1))
end

function E.sellValue(charId: string, level: number): number
	return round(E.incomeAt(charId, level) * Balance.SellValueSeconds)
end

function E.farmSlots(farmLevel: number): number
	local t = Balance.FarmSlotsByLevel
	return t[math.clamp(farmLevel, 1, #t)]
end

function E.farmMaxLevel(): number
	return #Balance.FarmSlotsByLevel
end

function E.farmUpgradeCost(farmLevel: number): number?
	return Balance.FarmUpgradeCost[farmLevel]
end

function E.treadmillGain(level: number): number
	return Balance.TreadmillGainPerSecond[math.clamp(level, 1, Balance.TreadmillMaxLevel)]
end

function E.treadmillUpgradeCost(level: number): number?
	if level >= Balance.TreadmillMaxLevel then
		return nil
	end
	return Balance.TreadmillUpgradeCost[level]
end

-- §97: trained speed × trail multiplier → configured, capped movement conversion.
function E.walkSpeed(trainedSpeed: number, trailMultiplier: number, boostMultiplier: number?): number
	local m = Balance.Movement
	local effective = (math.max(0, trainedSpeed) + m.BaseSpeedPoints) * trailMultiplier * (boostMultiplier or 1)
	local t = 1 - math.exp(-effective / m.Softness)
	return m.BaseWalkSpeed + (m.CapWalkSpeed - m.BaseWalkSpeed) * t
end

-- Compact number formatting for UI and signs: 1.2K, 3.4M, 5.6B, 7.8T, 9Qa
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }
function E.format(n: number): string
	if n ~= n then
		return "0"
	end
	local neg = n < 0
	n = math.abs(n)
	local i = 1
	while n >= 1000 and i < #SUFFIXES do
		n /= 1000
		i += 1
	end
	local s
	if i == 1 then
		s = tostring(math.floor(n))
	elseif n >= 100 then
		s = string.format("%d%s", math.floor(n), SUFFIXES[i])
	else
		s = (string.format("%.1f", math.floor(n * 10) / 10):gsub("%.0$", "")) .. SUFFIXES[i]
	end
	return (neg and "-" or "") .. s
end

return E
