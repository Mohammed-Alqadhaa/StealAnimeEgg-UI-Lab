--!nocheck
-- Generates docs/generated/BALANCE_TABLES.md from game/src/shared (PROVISIONAL values).
-- lune run game/tests/balance_table.luau
local fs = require("@lune/fs")
local H = require("./harness")
local W, E, B, T = H.shared("Worlds"), H.shared("Economy"), H.shared("Balance"), H.shared("Trails")
local out = { "# Provisional balance tables (GENERATED)", "", "Generated from `game/src/shared/Balance.lua` + `Economy.lua` by `game/tests/balance_table.luau`.", "**PROVISIONAL DEVELOPMENT BALANCE** — not an approved economy. Only the values marked OWNER_LOCKED are fixed by the Owner.", "" }
local function add(s) table.insert(out, s) end
add("## Character income ($/sec) and costs")
add("")
add("| World | Character | Boss | Lv1 $/s | Lv10 $/s | Upgrade Lv1→2 | Sell value Lv1 |")
add("|---|---|---|---:|---:|---:|---:|")
for _, wid in W.ORDER do
	for _, cid in W.WORLDS[wid].roster do
		local c = W.CHARACTERS[cid]
		add(string.format("| %s | %s | %s | %s | %s | %s | %s |", W.WORLDS[wid].name, c.name, c.isBoss and "yes" or "", E.format(E.incomeAt(cid, 1)), E.format(E.incomeAt(cid, 10)), E.format(E.upgradeCost(cid, 1)), E.format(E.sellValue(cid, 1))))
	end
end
add("")
add("## Farm slots")
add("")
add("| Farm level | Slots | Cost to next level |")
add("|---:|---:|---:|")
for lvl = 1, #B.FarmSlotsByLevel do
	local cost = E.farmUpgradeCost(lvl)
	add(string.format("| %d | %d | %s |", lvl, E.farmSlots(lvl), cost and ("$" .. E.format(cost)) or "MAX"))
end
add("")
add("## Treadmill (Speed per second of ACTIVE running)")
add("")
add("| Level | Gain/s | Cost to next level |")
add("|---:|---:|---:|")
for lvl = 1, B.TreadmillMaxLevel do
	local cost = E.treadmillUpgradeCost(lvl)
	add(string.format("| %d | %s | %s |", lvl, E.format(E.treadmillGain(lvl)), cost and ("$" .. E.format(cost)) or "MAX"))
end
add("")
add("## Trails (multipliers OWNER_LOCKED; cash prices provisional; Robux ids nil)")
add("")
add("| # | Trail | Multiplier | Family | Cash price |")
add("|---:|---|---:|---|---:|")
for i, t in T.TIERS do
	add(string.format("| %d | %s | x%s | %s | $%s |", i, t.name, tostring(t.mult), t.family, E.format(t.cashPrice)))
end
add("")
add("## Resulting WalkSpeed (soft cap)")
add("")
add("| Trained Speed | no trail | x2 | x5 | x10 | x20 |")
add("|---:|---:|---:|---:|---:|---:|")
for _, s in { 0, 100, 500, 1000, 5000, 20000 } do
	local row = { tostring(s) }
	for _, m in { 1, 2, 5, 10, 20 } do
		table.insert(row, string.format("%.1f", E.walkSpeed(s, m, 1)))
	end
	add("| " .. table.concat(row, " | ") .. " |")
end
add("")
add(string.format("Hatch %ds · dropped egg expiry %ds · round %ds · fog gate %ds · boss reaction %.1fs · knockback %d studs · autosave %ds",
	B.HatchSeconds, B.DroppedEggSeconds, B.OWNER_LOCKED.RoundSeconds, B.OWNER_LOCKED.FogGateSeconds, B.BossReactionSeconds, B.KnockbackStuds, B.AutosaveSeconds))
fs.writeFile("docs/generated/BALANCE_TABLES.md", table.concat(out, "\n") .. "\n")
print("wrote docs/generated/BALANCE_TABLES.md")
