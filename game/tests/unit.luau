--!nocheck
-- lune run game/tests/unit.luau   (from repo root)
local process = require("@lune/process")
local H = require("./harness")
local check, eq = H.check, H.eq

local Worlds = H.shared("Worlds")
local Balance = H.shared("Balance")
local Economy = H.shared("Economy")
local Profile = H.shared("Profile")
local Trails = H.shared("Trails")
local Layout = H.shared("Layout")
local BossLogic = H.shared("BossLogic")
local Net = H.shared("Net")

----------------------------------------------------------------- §162 counts
H.section("roster counts (§162)")
eq(#Worlds.ORDER, 9, "worlds")
local chars, eggs, bosses, bossEggs = 0, 0, 0, 0
for _ in Worlds.CHARACTERS do chars += 1 end
for _, e in Worlds.EGGS do
	eggs += 1
	if e.isBossEgg then bossEggs += 1 end
end
eq(chars, 45, "characters")
eq(eggs, 45, "character eggs")
eq(bossEggs, 9, "boss eggs")
local spawnNames = {}
for i, worldId in Worlds.ORDER do
	local w = Worlds.WORLDS[worldId]
	eq(w.index, i, worldId .. " index/order")
	eq(#w.roster, 5, worldId .. " has 5 characters")
	check(table.find(w.roster, w.boss) ~= nil, worldId .. " boss is one of the five")
	bosses += 1
	for _, c in w.roster do
		local egg = Worlds.EGGS["egg_" .. c]
		check(egg and egg.world == worldId, c .. " egg maps to its world")
		check(Worlds.EGG_VISUALS[c] ~= nil, c .. " has an egg visual spec")
		check(not spawnNames[egg.spawnName], "unique spawn " .. egg.spawnName)
		spawnNames[egg.spawnName] = true
	end
end
eq(bosses, 9, "bosses")
local expectedBoss = { DemonSlayer = "akaza", MHA = "shigaraki", DragonBall = "frieza", OnePiece = "doflamingo", Naruto = "madara", Berserk = "griffith", Bleach = "yhwach", JJK = "sukuna", SoloLeveling = "sungjinwoo" }
for w, b in expectedBoss do eq(Worlds.WORLDS[w].boss, b, w .. " boss") end
check(table.find(Worlds.WORLDS.OnePiece.roster, "nami") and table.find(Worlds.WORLDS.OnePiece.roster, "kaido"), "One Piece has Nami + Kaido")
check(not Worlds.CHARACTERS.sanji and not Worlds.CHARACTERS.law, "no Sanji / Law")
check(table.find(Worlds.WORLDS.JJK.roster, "mahoraga") and not Worlds.CHARACTERS.megumi, "JJK Mahoraga, no Megumi")
check(Worlds.CHARACTERS.aizen.rig.variant == "Muken", "Aizen model = Muken")
check(Worlds.EGG_VISUALS.aizen.cosmic == true, "Aizen egg = galaxy/cosmic")
check(Worlds.CHARACTERS.yhwach.rig.variant == "The Almighty", "Yhwach = The Almighty")
check(not Worlds.CHARACTERS.giyu, "Giyu not in active roster")
for _, c in { "rengoku", "yoriichi", "muzan", "akaza" } do
	check(Worlds.EGG_VISUALS[c].approvedAsset ~= nil, c .. " uses the approved existing egg asset")
end
eq(Worlds.EGGS.egg_akaza.spawnName, "AkazaSpawn", "spawn naming")
eq(Worlds.EGGS.egg_nami.spawnName, "NamiSpawn", "spawn naming")
eq(Worlds.EGGS.egg_mahoraga.spawnName, "MahoragaSpawn", "spawn naming")

----------------------------------------------------------------------- Net
H.section("remote surface (§123/§124)")
local all = {}
for _, n in Net.EVENTS do all[n] = true end
for _, n in Net.FUNCTIONS do all[n] = true end
for _, bad in Net.FORBIDDEN do check(not all[bad], "no remote named " .. bad) end
check(not all.RequestSecure, "no RequestSecure")

------------------------------------------------------------------ economy
H.section("economy")
check(Economy.baseIncome("akaza") > Economy.baseIncome("tanjiro"), "boss slot earns more")
check(Economy.baseIncome("tanjiro") < Economy.baseIncome("deku"), "later worlds earn more")
local last = 0
for lvl = 1, Balance.CharacterMaxLevel do
	local inc = Economy.incomeAt("goku", lvl)
	check(inc > last, "income rises with level " .. lvl)
	last = inc
end
eq(Economy.upgradeCost("goku", Balance.CharacterMaxLevel), nil, "no upgrade past max")
eq(Economy.farmSlots(1), 5, "initial farm slots = 5 (§71)")
eq(Economy.treadmillUpgradeCost(10), nil, "treadmill max")
local w15 = Economy.walkSpeed(100, 1.5)
local w20 = Economy.walkSpeed(100, 20)
check(w20 > w15 * 1.7, string.format("x20 dramatically faster than x1.5 (%.1f vs %.1f)", w20, w15))
check(Economy.walkSpeed(1e12, 20) <= Balance.Movement.CapWalkSpeed, "movement capped")
check(Economy.walkSpeed(0, 1) >= Balance.Movement.BaseWalkSpeed, "base walk speed floor")
eq(Economy.format(1234), "1.2K", "format K")
eq(Economy.format(5600000000000), "5.6T", "format T")
eq(Economy.format(999), "999", "format small")

------------------------------------------------------------------- trails
H.section("trails (§95)")
eq(#Trails.TIERS, 12, "12 purchasable tiers")
local expected = { 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 7, 10, 14, 20 }
for i, m in expected do eq(Trails.TIERS[i].mult, m, "tier " .. i) end
eq(Trails.multiplierFor(nil), 1.0, "base x1.0")

------------------------------------------------------------------ profile
H.section("profile: units, slots, equip best")
local now = 1000
local uidN = 0
local function uid() uidN += 1; return "U" .. uidN end
local p = Profile.new()
local ok, u1 = Profile.addUnit(p, "rengoku", uid(), now)
local _, u2 = Profile.addUnit(p, "rengoku", uid(), now)
check(ok and u1.uid ~= u2.uid, "duplicates are separate units")
eq(#p.equipped, 2, "auto-equip while slots free")
for _ = 1, 6 do Profile.addUnit(p, "tanjiro", uid(), now) end
eq(#p.equipped, 5, "slots cap equipped at 5")
eq(Profile.unitCount(p), 8, "extra units kept in inventory (§70)")
local _, akazaUnit = Profile.addUnit(p, "sungjinwoo", uid(), now)
check(not Profile.isEquipped(p, akazaUnit.uid), "no slot → stays in inventory")
Profile.equipBest(p)
check(Profile.isEquipped(p, akazaUnit.uid), "equip best picks highest $/sec")
eq(#p.equipped, 5, "equip best fills slots only")
local incomes = {}
for _, id in p.equipped do table.insert(incomes, Profile.unitIncome(p.units[id])) end
local minEquipped = math.min(table.unpack(incomes))
for id, u in p.units do
	if not Profile.isEquipped(p, id) then check(Profile.unitIncome(u) <= minEquipped, "no better unequipped unit") end
end
local okEq = Profile.equip(p, u1.uid)
check(not okEq or #p.equipped <= 5, "cannot exceed slots")

H.section("profile: upgrade")
p.cash = 0
local okUp, why = Profile.upgradeUnit(p, u1.uid)
check(not okUp and why == "not enough cash", "upgrade needs cash")
local cost = Economy.upgradeCost("rengoku", 1)
p.cash = cost
okUp = Profile.upgradeUnit(p, u1.uid)
check(okUp and p.cash == 0 and p.units[u1.uid].level == 2, "upgrade charges server cost once")
local again = Profile.upgradeUnit(p, u1.uid)
check(not again, "rapid second click without cash fails (no double charge)")

H.section("profile: sell (§103/§104)")
p.cash = 0
local equippedUid = p.equipped[1]
local expectedPay = Economy.sellValue(p.units[equippedUid].characterId, p.units[equippedUid].level)
local okSell, res = Profile.sell(p, { equippedUid })
check(okSell and res.payout == expectedPay and p.cash == expectedPay, "payout computed server-side")
check(not Profile.isEquipped(p, equippedUid) and p.units[equippedUid] == nil, "equipped unit unequipped + removed")
local okSell2 = Profile.sell(p, { equippedUid })
check(not okSell2, "double sell rejected")
eq(p.cash, expectedPay, "no duplicate cash")
check(not Profile.sell(p, { u2.uid, u2.uid }), "duplicate uid in one request rejected")
check(not Profile.sell(p, { "forged" }), "unknown uid rejected")
check(not Profile.sell(p, {}), "empty rejected")

H.section("profile: eggs + hatch + index (§55, §62–66)")
local q = Profile.new()
local okS, egg = Profile.secureEgg(q, "egg_nami", "E1", now)
check(okS and egg.hatchAt == now + Balance.HatchSeconds, "hatchAt absolute timestamp")
check(not Profile.secureEgg(q, "egg_nami", "E1", now), "same egg instance cannot secure twice")
eq(Profile.eggState(egg, now + 10), "HATCHING", "hatching")
check(not Profile.openEgg(q, "E1", "UA", now + 59), "cannot open before READY")
eq(Profile.eggState(egg, now + 60), "READY", "ready at hatchAt")
local okO, r = Profile.openEgg(q, "E1", "UA", now + 60)
check(okO and r.characterId == "nami" and r.isNewDiscovery, "open grants the egg's specific character + discovery")
check(not Profile.openEgg(q, "E1", "UB", now + 61), "double open rejected")
eq(Profile.discoveredIn(q, "OnePiece"), 1, "1/5 discovered")
Profile.secureEgg(q, "egg_nami", "E2", now)
local _, r2 = Profile.openEgg(q, "E2", "UC", now + 60)
check(not r2.isNewDiscovery, "duplicate does not rediscover")
eq(Profile.discoveredIn(q, "OnePiece"), 1, "duplicates do not count twice")
eq(Profile.unitCount(q), 2, "duplicate unit granted")

H.section("profile: farm/treadmill/trails/receipts")
local f = Profile.new()
f.cash = 10 ^ 12
for _ = 1, 20 do Profile.upgradeFarm(f) end
eq(f.farmLevel, #Balance.FarmSlotsByLevel, "farm stops at max")
for _ = 1, 20 do Profile.upgradeTreadmill(f) end
eq(f.treadmillLevel, 10, "treadmill stops at 10")
check(Profile.buyTrailCash(f, "nova"), "buy trail with cash")
check(not Profile.buyTrailCash(f, "nova"), "cannot buy twice")
check(not Profile.equipTrail(f, "infinity"), "cannot equip unowned trail")
Profile.buyTrailCash(f, "breeze")
Profile.equipTrail(f, "nova")
Profile.equipTrail(f, "breeze")
eq(f.equippedTrail, "breeze", "one trail equipped, replaces previous (no stacking)")
check(not Profile.hasReceipt(f, "R1"), "new receipt")
Profile.recordReceipt(f, "R1")
check(Profile.hasReceipt(f, "R1"), "receipt replay detected")

H.section("profile migrate")
local legacy = { cash = "12", units = { X = { characterId = "sanji", level = 1 }, Y = { characterId = "goku", level = 2 } }, equipped = { "X", "Y", "Y" }, Muscle = 50 }
local m = Profile.migrate(legacy)
eq(m.cash, 12, "numeric cash")
check(m.units.X == nil and m.units.Y ~= nil, "legacy/invalid characters dropped")
eq(#m.equipped, 1, "equipped cleaned")

------------------------------------------------------------------- layout
H.section("layout + boss logic (§27, §58, §111–113)")
eq(Layout.WORLD_WALL_CLEAR, 150, "Akaza width ×1.5 = 150")
check(Layout.isInSafeZone(0, 3, -100), "hub is safe")
check(Layout.isInSafeZone(-150, 3, 90), "whole farm area is safe, not just own plot")
check(not Layout.isInSafeZone(0, 3, 250), "world is unsafe")
eq(Layout.worldAt(0, 300), "DemonSlayer", "world 1")
eq(Layout.worldAt(0, Layout.worldCenterZ(9)), "SoloLeveling", "world 9")
for _, eggId in { "egg_goku", "egg_sukuna", "egg_tanjiro" } do
	local x, z = Layout.eggPosition(eggId)
	eq(Layout.worldAt(x, z), Worlds.EGGS[eggId].world, eggId .. " spawn lies inside its world")
end
local carriers = {
	{ id = "far", x = 0, z = Layout.worldZ0(3) + 150, worldOfEgg = "DragonBall", secured = false },
	{ id = "near", x = 0, z = Layout.worldZ0(2) + 20, worldOfEgg = "DragonBall", secured = false },
	{ id = "other", x = 0, z = 260, worldOfEgg = "MHA", secured = false },
}
eq(BossLogic.pickTarget("DragonBall", carriers).id, "near", "boss targets carrier closest to safe zone")
eq(BossLogic.pickTarget("Naruto", carriers), nil, "no target for unrelated world")
eq(BossLogic.catchOutcome("DragonBall", 0, 3, Layout.worldZ0(3) + 50), "RETURN_EGG", "caught in own world → egg returns")
eq(BossLogic.catchOutcome("DragonBall", 0, 3, Layout.worldZ0(2) + 50), "DROP_EGG", "caught after leaving world → drop")
eq(BossLogic.catchOutcome("DragonBall", 0, 3, 0), "NONE", "safe zone → nothing")

process.exit(H.finish() == 0 and 0 or 1)
