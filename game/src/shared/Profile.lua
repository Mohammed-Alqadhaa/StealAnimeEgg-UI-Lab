--!strict
--[[
	Profile — the persistent player-state schema and every authoritative mutation on it.

	Pure Luau (no Roblox services): the server services call these functions and the
	Lune test-suite exercises them directly, including double-action / replay cases
	(§127). Every mutation validates its own preconditions and returns
	(ok: boolean, resultOrReason). The server never accepts client-supplied amounts.

	Characters are individual owned UNITS (§67): duplicates are separate uids.
	Eggs occupy 0 character slots; each EQUIPPED unit occupies 1 slot (§69).
]]

local Worlds = require(script.Parent.Worlds)
local Balance = require(script.Parent.Balance)
local Economy = require(script.Parent.Economy)
local Trails = require(script.Parent.Trails)

local P = {}

P.VERSION = 1

export type Unit = { uid: string, characterId: string, worldId: string, level: number, obtainedAt: number }
export type SecuredEgg = { uid: string, eggId: string, securedAt: number, hatchAt: number }

function P.new(): { [string]: any }
	return {
		version = P.VERSION,
		cash = Balance.StartingCash,
		speed = 0,
		farmLevel = 1,
		treadmillLevel = 1,
		units = {}, -- [uid] = Unit
		equipped = {}, -- array of uids (order = farm pad order)
		eggs = {}, -- [eggUid] = SecuredEgg
		index = {}, -- [characterId] = discoveredAt
		trails = {}, -- [trailId] = true
		equippedTrail = nil,
		entitlements = {}, -- [passKey] = true
		boosts = {}, -- [boostKey] = expiresAt (unix)
		receipts = {}, -- array of processed purchase ids (bounded)
		stats = { eggsSecured = 0, eggsOpened = 0, unitsSold = 0 },
	}
end

-- Fills missing fields / upgrades old versions. Never throws on unexpected shapes.
function P.migrate(data: any): { [string]: any }
	local fresh = P.new()
	if type(data) ~= "table" then
		return fresh
	end
	for k, v in fresh do
		if data[k] == nil then
			data[k] = v
		end
	end
	-- drop units whose character no longer exists in the active roster (e.g. legacy ids)
	for uid, unit in data.units do
		if type(unit) ~= "table" or not Worlds.CHARACTERS[unit.characterId] then
			data.units[uid] = nil
		end
	end
	local cleaned = {}
	for _, uid in data.equipped do
		if data.units[uid] and not table.find(cleaned, uid) then
			table.insert(cleaned, uid)
		end
	end
	data.equipped = cleaned
	for eggUid, egg in data.eggs do
		if type(egg) ~= "table" or not Worlds.EGGS[egg.eggId] then
			data.eggs[eggUid] = nil
		end
	end
	data.cash = math.max(0, tonumber(data.cash) or 0)
	data.speed = math.max(0, tonumber(data.speed) or 0)
	data.version = P.VERSION
	return data
end

-- ── units ───────────────────────────────────────────────────────────────────
function P.slots(p): number
	return Economy.farmSlots(p.farmLevel)
end

function P.unitIncome(unit: Unit): number
	return Economy.incomeAt(unit.characterId, unit.level)
end

function P.activeIncome(p): number
	local total = 0
	for _, uid in p.equipped do
		local u = p.units[uid]
		if u then
			total += P.unitIncome(u)
		end
	end
	return total
end

function P.unitCount(p): number
	local n = 0
	for _ in p.units do
		n += 1
	end
	return n
end

function P.addUnit(p, characterId: string, uid: string, now: number): (boolean, any)
	if not Worlds.CHARACTERS[characterId] then
		return false, "unknown character"
	end
	if p.units[uid] then
		return false, "uid collision"
	end
	if P.unitCount(p) >= Balance.MaxInventory then
		return false, "inventory full"
	end
	local unit = { uid = uid, characterId = characterId, worldId = Worlds.CHARACTERS[characterId].world, level = 1, obtainedAt = now }
	p.units[uid] = unit
	-- §70: auto-equip only when a slot is free; otherwise it simply stays in inventory
	if #p.equipped < P.slots(p) then
		table.insert(p.equipped, uid)
	end
	return true, unit
end

function P.isEquipped(p, uid: string): boolean
	return table.find(p.equipped, uid) ~= nil
end

function P.equip(p, uid: string): (boolean, string?)
	if not p.units[uid] then
		return false, "not owned"
	end
	if P.isEquipped(p, uid) then
		return false, "already equipped"
	end
	if #p.equipped >= P.slots(p) then
		return false, "no free slot"
	end
	table.insert(p.equipped, uid)
	return true
end

function P.unequip(p, uid: string): (boolean, string?)
	local i = table.find(p.equipped, uid)
	if not i then
		return false, "not equipped"
	end
	table.remove(p.equipped, i)
	return true
end

-- §76: rank ONLY by actual $/sec; ties broken by uid for determinism.
function P.equipBest(p): { string }
	local list = {}
	for uid, u in p.units do
		table.insert(list, { uid = uid, income = P.unitIncome(u) })
	end
	table.sort(list, function(a, b)
		if a.income ~= b.income then
			return a.income > b.income
		end
		return a.uid < b.uid
	end)
	local chosen = {}
	for i = 1, math.min(P.slots(p), #list) do
		table.insert(chosen, list[i].uid)
	end
	p.equipped = chosen
	return chosen
end

function P.upgradeUnit(p, uid: string): (boolean, any)
	local u = p.units[uid]
	if not u then
		return false, "not owned"
	end
	local cost = Economy.upgradeCost(u.characterId, u.level)
	if not cost then
		return false, "max level"
	end
	if p.cash < cost then
		return false, "not enough cash"
	end
	p.cash -= cost
	u.level += 1
	return true, { unit = u, cost = cost }
end

-- §103/§104: client sends only uids; value computed here; equipped units are unequipped.
function P.sell(p, uids: { any }): (boolean, any)
	if type(uids) ~= "table" or #uids == 0 or #uids > Balance.MaxInventory then
		return false, "nothing selected"
	end
	local seen = {}
	for _, uid in uids do
		if type(uid) ~= "string" or seen[uid] or not p.units[uid] then
			return false, "invalid selection"
		end
		seen[uid] = true
	end
	local payout = 0
	for _, uid in uids do
		local u = p.units[uid]
		payout += Economy.sellValue(u.characterId, u.level)
		P.unequip(p, uid)
		p.units[uid] = nil
	end
	p.cash += payout
	p.stats.unitsSold += #uids
	return true, { payout = payout, count = #uids }
end

-- ── eggs ───────────────────────────────────────────────────────────────────
function P.secureEgg(p, eggId: string, eggUid: string, now: number): (boolean, any)
	if not Worlds.EGGS[eggId] then
		return false, "unknown egg"
	end
	if p.eggs[eggUid] then
		return false, "already secured" -- same world-egg instance can never secure twice
	end
	local egg = { uid = eggUid, eggId = eggId, securedAt = now, hatchAt = now + Balance.HatchSeconds }
	p.eggs[eggUid] = egg
	p.stats.eggsSecured += 1
	return true, egg
end

function P.eggState(egg: SecuredEgg, now: number): string
	return now >= egg.hatchAt and "READY" or "HATCHING"
end

-- OPEN → CHARACTER_REVEAL → CHARACTER_GRANTED → INDEX_DISCOVERY (§55). Consumes the egg
-- first, so a replayed/double OPEN finds no egg and fails (§127).
function P.openEgg(p, eggUid: string, unitUid: string, now: number): (boolean, any)
	local egg = p.eggs[eggUid]
	if not egg then
		return false, "no such egg"
	end
	if now < egg.hatchAt then
		return false, "not ready"
	end
	if P.unitCount(p) >= Balance.MaxInventory then
		return false, "inventory full"
	end
	p.eggs[eggUid] = nil
	local charId = Worlds.EGGS[egg.eggId].character
	local ok, unit = P.addUnit(p, charId, unitUid, now)
	if not ok then
		p.eggs[eggUid] = egg -- restore on failure; nothing lost
		return false, unit
	end
	local isNew = p.index[charId] == nil
	if isNew then
		p.index[charId] = now -- §14: discovery happens on OPEN/REVEAL only
	end
	p.stats.eggsOpened += 1
	return true, { unit = unit, characterId = charId, isNewDiscovery = isNew, equipped = P.isEquipped(p, unitUid) }
end

function P.discoveredIn(p, worldId: string): number
	local n = 0
	for _, charId in Worlds.WORLDS[worldId].roster do
		if p.index[charId] then
			n += 1
		end
	end
	return n
end

-- ── farm / treadmill ───────────────────────────────────────────────────────
function P.upgradeFarm(p): (boolean, any)
	local cost = Economy.farmUpgradeCost(p.farmLevel)
	if not cost or p.farmLevel >= Economy.farmMaxLevel() then
		return false, "max level"
	end
	if p.cash < cost then
		return false, "not enough cash"
	end
	p.cash -= cost
	p.farmLevel += 1
	return true, { level = p.farmLevel, cost = cost, slots = P.slots(p) }
end

function P.upgradeTreadmill(p): (boolean, any)
	local cost = Economy.treadmillUpgradeCost(p.treadmillLevel)
	if not cost then
		return false, "max level"
	end
	if p.cash < cost then
		return false, "not enough cash"
	end
	p.cash -= cost
	p.treadmillLevel += 1
	return true, { level = p.treadmillLevel, cost = cost, gain = Economy.treadmillGain(p.treadmillLevel) }
end

-- ── trails ─────────────────────────────────────────────────────────────────
function P.buyTrailCash(p, trailId: string): (boolean, any)
	local tier = Trails.BY_ID[trailId]
	if not tier then
		return false, "unknown trail"
	end
	if p.trails[trailId] then
		return false, "already owned"
	end
	if p.cash < tier.cashPrice then
		return false, "not enough cash"
	end
	p.cash -= tier.cashPrice
	p.trails[trailId] = true
	return true, { cost = tier.cashPrice }
end

function P.equipTrail(p, trailId: string?): (boolean, string?)
	if trailId == nil then
		p.equippedTrail = nil
		return true
	end
	if not Trails.BY_ID[trailId] or not p.trails[trailId] then
		return false, "not owned"
	end
	p.equippedTrail = trailId -- exactly one; replaces any previous (no stacking, §95)
	return true
end

-- ── receipts (§127 replay protection) ──────────────────────────────────────
function P.hasReceipt(p, purchaseId: string): boolean
	return table.find(p.receipts, purchaseId) ~= nil
end

function P.recordReceipt(p, purchaseId: string)
	table.insert(p.receipts, purchaseId)
	while #p.receipts > Balance.MaxReceiptHistory do
		table.remove(p.receipts, 1)
	end
end

-- ── snapshot for the owning client (no other player's data) ───────────────
function P.snapshot(p, now: number): { [string]: any }
	local units = {}
	for uid, u in p.units do
		table.insert(units, {
			uid = uid,
			characterId = u.characterId,
			worldId = u.worldId,
			level = u.level,
			income = P.unitIncome(u),
			nextIncome = u.level < Balance.CharacterMaxLevel and Economy.incomeAt(u.characterId, u.level + 1) or nil,
			upgradeCost = Economy.upgradeCost(u.characterId, u.level),
			sellValue = Economy.sellValue(u.characterId, u.level),
			equipped = P.isEquipped(p, uid),
		})
	end
	local eggs = {}
	for uid, e in p.eggs do
		table.insert(eggs, { uid = uid, eggId = e.eggId, characterId = Worlds.EGGS[e.eggId].character, securedAt = e.securedAt, hatchAt = e.hatchAt })
	end
	local trails = {}
	for id in p.trails do
		table.insert(trails, id)
	end
	return {
		cash = p.cash,
		speed = p.speed,
		income = P.activeIncome(p),
		farmLevel = p.farmLevel,
		slots = P.slots(p),
		nextSlots = Economy.farmUpgradeCost(p.farmLevel) and Economy.farmSlots(p.farmLevel + 1) or nil,
		farmUpgradeCost = Economy.farmUpgradeCost(p.farmLevel),
		treadmillLevel = p.treadmillLevel,
		treadmillGain = Economy.treadmillGain(p.treadmillLevel),
		treadmillNextGain = p.treadmillLevel < Balance.TreadmillMaxLevel and Economy.treadmillGain(p.treadmillLevel + 1) or nil,
		treadmillUpgradeCost = Economy.treadmillUpgradeCost(p.treadmillLevel),
		units = units,
		equipped = table.clone(p.equipped),
		eggs = eggs,
		index = table.clone(p.index),
		trails = trails,
		equippedTrail = p.equippedTrail,
		entitlements = table.clone(p.entitlements),
		boosts = table.clone(p.boosts),
		serverTime = now,
	}
end

return P
