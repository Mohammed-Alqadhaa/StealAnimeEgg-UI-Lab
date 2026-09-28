--!strict
--[[
	Balance — every tunable number in one place (Master Prompt §128).

	ALL VALUES IN THIS FILE ARE **PROVISIONAL DEVELOPMENT BALANCE** unless listed in
	`OWNER_LOCKED`. They exist so the game is playable end-to-end; they are not an
	approved economy. Change numbers here only — gameplay code never hardcodes them.
]]

local B = {}

-- Values the Owner explicitly fixed in the master prompt (not provisional).
B.OWNER_LOCKED = {
	FarmCount = 7, -- §78
	MaxPlayers = 7, -- §79 (server size is a game setting: OWNER ACTION REQUIRED)
	CarryLimit = 1, -- §56
	RoundSeconds = 300, -- §117
	FogGateSeconds = 7, -- §118
	AkazaReactionSeconds = 1.0, -- §33/§108
	AkazaWidthMultiplier = 1.5, -- §27
	InitialFarmSlots = 5, -- §71 (historic 5 character pads per farm)
	TrailMultipliers = { 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 7, 10, 14, 20 }, -- §95
}

-- ── Eggs / hatching ─────────────────────────────────────────────────────────
B.HatchSeconds = 60 -- §62 DEVELOPMENT value, all eggs
B.DroppedEggSeconds = 30 -- §61 PROVISIONAL DEVELOPMENT BALANCE
B.EggPickupHoldSeconds = 0.35
B.EggPickupDistance = 11

-- ── Economy: character income ───────────────────────────────────────────────
-- base $/sec = WorldBase[worldIndex] × SlotFactor[rosterSlot]  (boss is slot 5)
B.WorldBaseIncome = { 10, 24, 58, 140, 330, 800, 1900, 4600, 11000 }
B.SlotFactor = { 1.0, 1.2, 1.45, 1.75, 2.3 }
B.CharacterMaxLevel = 10
B.IncomePerLevel = 0.35 -- +35% of base per level above 1
B.UpgradeCostBaseSeconds = 30 -- cost(L→L+1) = base × 30 × Growth^(L-1)
B.UpgradeCostGrowth = 1.6
B.SellValueSeconds = 45 -- sell value = current $/sec × 45
B.StartingCash = 50
B.IncomeTickSeconds = 1

-- ── Farm upgrades (slots) ────────────────────────────────────────────────────
B.FarmSlotsByLevel = { 5, 6, 7, 8, 9, 10 }
B.FarmUpgradeCost = { 2500, 25000, 250000, 2500000, 25000000 } -- index = current level

-- ── Treadmill (10 visually distinct levels, §90) ─────────────────────────────
B.TreadmillMaxLevel = 10
B.TreadmillGainPerSecond = { 1, 2, 4, 7, 12, 20, 32, 50, 80, 125 } -- Speed per second of active running
B.TreadmillUpgradeCost = { 500, 3000, 15000, 75000, 400000, 2000000, 10000000, 50000000, 250000000 }
B.TreadmillTickSeconds = 0.5
B.TreadmillBeltSpeed = 14 -- studs/s conveyor pushing the runner back

-- ── Movement conversion (§97) ────────────────────────────────────────────────
-- effective = (TrainedSpeed + BaseSpeedPoints) × trailMultiplier
-- WalkSpeed = Base + (Cap − Base) × (1 − e^(−effective / Softness))
B.Movement = {
	BaseWalkSpeed = 16,
	CapWalkSpeed = 110,
	BaseSpeedPoints = 20,
	Softness = 1000,
	CarryWalkSpeedFactor = 1.0, -- carrying does not slow (not specified)
}

-- ── Trails (cash prices PROVISIONAL; multipliers OWNER_LOCKED) ───────────────
B.TrailCashPrice = { 1000, 5000, 20000, 75000, 250000, 800000, 2500000, 8000000, 40000000, 250000000, 1500000000, 10000000000 }

-- ── Bosses ───────────────────────────────────────────────────────────────────
B.BossReactionSeconds = 1.0 -- per-world overrides in BossSpeedByWorld/ReactionByWorld
B.BossReactionByWorld = { Bleach = 1.4, SoloLeveling = 1.2 } -- throne rise takes a moment
B.BossWalkSpeedByWorld = { 26, 30, 34, 38, 42, 46, 50, 54, 58 }
B.BossHitRange = 6.5
B.BossHitCooldown = 1.2
B.BossGiveUpDistance = 260 -- studs beyond the world exit
B.BossDecisionHz = 6
B.KnockbackStuds = 22 -- moderate (§111)
B.KnockbackUpward = 18

-- ── PvP (§114) ───────────────────────────────────────────────────────────────
B.BatRange = 8
B.BatCooldown = 1.1
B.BatConeDot = 0.2

-- ── Farm characters wandering (§75) ──────────────────────────────────────────
B.WanderDecisionSeconds = { 3, 7 }
B.WanderWalkSpeed = 7
B.WanderPlotInset = 6

-- ── Persistence ──────────────────────────────────────────────────────────────
B.AutosaveSeconds = 90
B.MaxInventory = 400
B.MaxReceiptHistory = 60

return B
