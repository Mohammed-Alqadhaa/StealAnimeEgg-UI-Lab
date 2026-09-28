--!nocheck
-- Dumps world/character/trail tables for the production UI review page.
-- lune run tools/prod/export-worlds.luau
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local load = require("../../game/assembler/lib/shared")
local W, T = load("Worlds"), load("Trails")
local out = { order = W.ORDER, worlds = {}, characters = {}, trails = {} }
for _, id in W.ORDER do
	local w = W.WORLDS[id]
	out.worlds[id] = { name = w.name, index = w.index, roster = w.roster, boss = w.boss, palette = w.palette }
end
for id, c in W.CHARACTERS do
	out.characters[id] = { name = c.name, world = c.world, isBoss = c.isBoss }
end
for _, t in T.TIERS do
	table.insert(out.trails, { id = t.id, name = t.name, mult = t.mult, family = t.family, colors = t.colors, cashPrice = t.cashPrice })
end
fs.writeFile("tools/prod/review/worlds.js", "// GENERATED from game/src/shared\nwindow.GAME = " .. serde.encode("json", out) .. ";\n")
print("ok")
