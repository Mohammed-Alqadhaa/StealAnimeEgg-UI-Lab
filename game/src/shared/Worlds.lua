--!strict
--[[
	Worlds — the authoritative production roster (Master Prompt §24, §28, §29).

	9 worlds × 5 characters × 5 character-specific eggs. The boss is one of the five
	characters and the boss egg is one of the five eggs (no sixth egg).

	Pure data: safe to require on server, client and in Lune tests.
	Colours are hex strings so the same data drives Roblox, the UI build and docs.

	Egg `visual` blocks feed the Master Egg Pipeline (EggPipeline.lua). They describe the
	character's ESSENCE (motifs, colours, energy) — never a printed portrait (§30).
	Demon Slayer eggs are `approvedAsset` references to the existing approved models in
	the Akaza world (§31) and are NOT generated. Tanjiro has no existing egg in the Last
	CP, so a PROVISIONAL pipeline egg is flagged for Owner decision.
]]

export type Character = {
	id: string,
	name: string,
	world: string,
	isBoss: boolean,
	egg: string,
	rig: { [string]: any },
}

local W = {}

W.ORDER = {
	"DemonSlayer",
	"MHA",
	"DragonBall",
	"OnePiece",
	"Naruto",
	"Berserk",
	"Bleach",
	"JJK",
	"SoloLeveling",
}

-- palette: floor / wall / accent / glow / sky ; lighting profile name used by ZoneLighting
W.WORLDS = {
	DemonSlayer = {
		index = 1,
		name = "Demon Slayer",
		theme = "Infinity Night Arena",
		boss = "akaza",
		roster = { "tanjiro", "rengoku", "yoriichi", "muzan", "akaza" },
		palette = { floor = "#26343F", wall = "#1C2B40", accent = "#44B9DC", glow = "#2EC5F0", sky = "#0C1830" },
		lighting = "AkazaNight",
		reference = "R12 (existing Akaza world)",
	},
	MHA = {
		index = 2,
		name = "My Hero Academia",
		theme = "League of Villains Hideout",
		boss = "shigaraki",
		roster = { "deku", "bakugo", "todoroki", "allmight", "shigaraki" },
		palette = { floor = "#4A4552", wall = "#2B2433", accent = "#9B4DFF", glow = "#B266FF", sky = "#1A0F33" },
		lighting = "VillainViolet",
		reference = "R01",
	},
	DragonBall = {
		index = 3,
		name = "Dragon Ball",
		theme = "Planet Namek",
		boss = "frieza",
		roster = { "goku", "vegeta", "gohan", "broly", "frieza" },
		palette = { floor = "#8FD66B", wall = "#5FA84E", accent = "#3FB6FF", glow = "#7CFFB0", sky = "#7FE3A0" },
		lighting = "NamekDay",
		reference = "R02 (Planet Namek panel)",
	},
	OnePiece = {
		index = 4,
		name = "One Piece",
		theme = "Dressrosa Corrida Colosseum",
		boss = "doflamingo",
		roster = { "luffy", "zoro", "nami", "kaido", "doflamingo" },
		palette = { floor = "#D9B98A", wall = "#B8906A", accent = "#E83A5A", glow = "#FF6FB5", sky = "#8FD0FF" },
		lighting = "DressrosaSun",
		reference = "R02 (Dressrosa panel)",
	},
	Naruto = {
		index = 5,
		name = "Naruto",
		theme = "Konoha Village",
		boss = "madara",
		roster = { "naruto", "sasuke", "kakashi", "itachi", "madara" },
		palette = { floor = "#C9A77A", wall = "#8C6A4A", accent = "#E8452E", glow = "#FFB347", sky = "#9ED3FF" },
		lighting = "KonohaDusk",
		reference = "R02 (Konoha panel)",
	},
	Berserk = {
		index = 6,
		name = "Berserk",
		theme = "The Eclipse",
		boss = "griffith",
		roster = { "guts", "casca", "skullknight", "zodd", "griffith" },
		palette = { floor = "#2A1A1C", wall = "#1A0E10", accent = "#D8261E", glow = "#FF3B30", sky = "#3A0508" },
		lighting = "CrimsonEclipse",
		reference = "R02 (The Eclipse panel); Griffith egg = R11",
	},
	Bleach = {
		index = 7,
		name = "Bleach",
		theme = "Yhwach Palace",
		boss = "yhwach",
		roster = { "ichigo", "aizen", "kenpachi", "yamamoto", "yhwach" },
		palette = { floor = "#4B4F57", wall = "#26292F", accent = "#E8E8EE", glow = "#FF8A3D", sky = "#1B1E26" },
		lighting = "HopelessPalace",
		reference = "R10 (map); R02 (eggs)",
	},
	JJK = {
		index = 8,
		name = "Jujutsu Kaisen",
		theme = "Shibuya Incident",
		boss = "sukuna",
		roster = { "yuji", "gojo", "toji", "mahoraga", "sukuna" },
		palette = { floor = "#2E2A30", wall = "#1E1A22", accent = "#FF2E4D", glow = "#FF3B6B", sky = "#2A0A14" },
		lighting = "CursedShibuya",
		reference = "R02 (Shibuya panel)",
	},
	SoloLeveling = {
		index = 9,
		name = "Solo Leveling",
		theme = "Shadow Corridor",
		boss = "sungjinwoo",
		roster = { "igris", "beru", "chahaein", "thomasandre", "sungjinwoo" },
		palette = { floor = "#141A2E", wall = "#0B1020", accent = "#3A7BFF", glow = "#6A5BFF", sky = "#05070F" },
		lighting = "ShadowMonarch",
		reference = "R02 (Shadow Corridor panel)",
	},
}

--[[ Character rig spec for stand-in R6 preview/gameplay rigs (used until the Owner imports
     sanitized real models — see ModelRegistry). skin/top/bottom/hair colours, hair style,
     optional props. `asset` records a known real model to import (Master Prompt §132). ]]
local function rig(skin, top, bottom, hair, style, extra)
	local r = { skin = skin, top = top, bottom = bottom, hair = hair, hairStyle = style }
	if extra then
		for k, v in extra do
			r[k] = v
		end
	end
	return r
end

W.CHARACTERS = {
	-- DEMON SLAYER (real R6 models already in the place for all five)
	tanjiro = {
		name = "Tanjiro",
		world = "DemonSlayer",
		rig = rig("#F2C9A8", "#1E7A4A", "#1E1E2A", "#6B1A1A", "spiky", { pattern = "checker", prop = "katana" }),
		existingModel = "Tanjiro Kamado",
		asset = 4167214076,
	},
	rengoku = {
		name = "Rengoku",
		world = "DemonSlayer",
		rig = rig("#F2C9A8", "#F4F4F4", "#1E1E2A", "#FFC21F", "mane", { prop = "katana" }),
		existingModel = "Rengoku",
		asset = 17831748983,
	},
	yoriichi = {
		name = "Yoriichi",
		world = "DemonSlayer",
		rig = rig("#F2C9A8", "#8E1B2E", "#1E1E2A", "#5A0F1A", "ponytail", { prop = "katana" }),
		existingModel = "Yoriichi",
		asset = 17834842386,
	},
	muzan = {
		name = "Muzan",
		world = "DemonSlayer",
		rig = rig("#FFF1EA", "#22223A", "#22223A", "#0E0A18", "wavy", { hat = "fedora" }),
		existingModel = "Muzan",
	},
	akaza = {
		name = "Akaza",
		world = "DemonSlayer",
		rig = rig("#FFE8E4", "#FF6FB8", "#F2F2F2", "#FF7FB6", "short", { tattoo = "#2F5BFF" }),
		existingModel = "Akaza",
		asset = 17831588851,
	},
	-- MY HERO ACADEMIA
	deku = { name = "Deku", world = "MHA", rig = rig("#F2C9A8", "#1F8F5A", "#1F8F5A", "#0F3D2A", "curly", { accent = "#7CFF5A" }) },
	bakugo = { name = "Bakugo", world = "MHA", rig = rig("#F2C9A8", "#1B1B1B", "#1B1B1B", "#F2E3A0", "spiky", { accent = "#FF7A1A", prop = "gauntlets" }) },
	todoroki = { name = "Todoroki", world = "MHA", rig = rig("#F2C9A8", "#1E3A6E", "#1E3A6E", "#F4F4F4", "split", { hair2 = "#C0292F" }) },
	allmight = { name = "All Might", world = "MHA", rig = rig("#F2C9A8", "#1F4FD6", "#D8261E", "#FFD23F", "antenna", { scale = 1.25 }) },
	shigaraki = {
		name = "Shigaraki",
		world = "MHA",
		rig = rig("#D9D2D6", "#1B1B22", "#1B1B22", "#BFC6D6", "messy", { hands = "#E8E0DA" }),
		asset = 17832884677,
	},
	-- DRAGON BALL
	goku = { name = "Goku", world = "DragonBall", rig = rig("#F2C9A8", "#FF7A1A", "#FF7A1A", "#111111", "spiky", { belt = "#1F4FD6" }) },
	vegeta = { name = "Vegeta", world = "DragonBall", rig = rig("#F2C9A8", "#1F3FA8", "#1F3FA8", "#111111", "flame", { armor = "#F4F4F4" }) },
	gohan = { name = "Gohan", world = "DragonBall", rig = rig("#F2C9A8", "#6A2FB0", "#6A2FB0", "#111111", "spiky", { belt = "#D8261E" }) },
	broly = { name = "Broly", world = "DragonBall", rig = rig("#E8B890", "#F4F4F4", "#F4F4F4", "#7CFF5A", "wild", { scale = 1.3, accent = "#FFD23F" }) },
	frieza = { name = "Frieza", world = "DragonBall", rig = rig("#F4F4F4", "#F4F4F4", "#F4F4F4", "#8A2BE2", "dome", { accent = "#9B4DFF", tail = true }) },
	-- ONE PIECE (Nami replaces Sanji, Kaido replaces Law)
	luffy = { name = "Luffy", world = "OnePiece", rig = rig("#F2C9A8", "#D8261E", "#1F4FD6", "#111111", "short", { hat = "straw" }) },
	zoro = { name = "Zoro", world = "OnePiece", rig = rig("#E8B890", "#F4F4F4", "#1B1B1B", "#3FBF5F", "short", { prop = "katana", sash = "#1F7A3A" }) },
	nami = { name = "Nami", world = "OnePiece", rig = rig("#F2C9A8", "#3FB6FF", "#1F4FD6", "#FF7A1A", "long", { prop = "staff" }) },
	kaido = { name = "Kaido", world = "OnePiece", rig = rig("#D9B08C", "#6A2FB0", "#F4F4F4", "#111111", "long", { horns = "#F4F4F4", scale = 1.6 }) },
	doflamingo = {
		name = "Doflamingo",
		world = "OnePiece",
		rig = rig("#F2C9A8", "#FF6FB5", "#F4F4F4", "#FFE36A", "short", { cape = "#FF6FB5", shades = true }),
	},
	-- NARUTO
	naruto = { name = "Naruto", world = "Naruto", rig = rig("#F2C9A8", "#FF7A1A", "#FF7A1A", "#FFD23F", "spiky", { accent = "#111111" }) },
	sasuke = { name = "Sasuke", world = "Naruto", rig = rig("#F2C9A8", "#E8E8EE", "#1B1B2A", "#10101A", "spiky", { prop = "katana" }) },
	kakashi = { name = "Kakashi", world = "Naruto", rig = rig("#F2C9A8", "#2F5A3A", "#1F2A4A", "#E8E8EE", "tilted", { mask = true }) },
	itachi = { name = "Itachi", world = "Naruto", rig = rig("#F2C9A8", "#111111", "#111111", "#111111", "ponytail", { cloak = "#111111", clouds = "#D8261E" }) },
	madara = { name = "Madara", world = "Naruto", rig = rig("#F2C9A8", "#8E1B2E", "#1B1B1B", "#111111", "wild", { armor = "#8E1B2E" }) },
	-- BERSERK
	guts = { name = "Guts", world = "Berserk", rig = rig("#E8B890", "#1B1B1B", "#1B1B1B", "#111111", "short", { prop = "greatsword", cape = "#1B1B1B" }) },
	casca = { name = "Casca", world = "Berserk", rig = rig("#8C5A3C", "#3A3F63", "#3A3F63", "#111111", "short", { prop = "sword" }) },
	skullknight = {
		name = "Skull Knight",
		world = "Berserk",
		rig = rig("#E8E0CC", "#1B1B1B", "#1B1B1B", "#E8E0CC", "skullhelm", { cape = "#6A0F1E", scale = 1.3 }),
	},
	zodd = { name = "Zodd", world = "Berserk", rig = rig("#6A4A3A", "#3A2A20", "#3A2A20", "#111111", "wild", { horns = "#E8E0CC", scale = 1.5 }) },
	griffith = {
		name = "Griffith / Femto",
		world = "Berserk",
		rig = rig("#F4EEE8", "#1B1B2A", "#1B1B2A", "#F4F4F4", "long", { helm = "hawk", cape = "#2A1A3A" }),
	},
	-- BLEACH (Aizen character model = Muken Aizen; Yhwach = The Almighty)
	ichigo = { name = "Ichigo", world = "Bleach", rig = rig("#F2C9A8", "#111111", "#111111", "#FF7A1A", "spiky", { prop = "zangetsu" }) },
	aizen = {
		name = "Aizen (Muken)",
		world = "Bleach",
		rig = rig("#F2C9A8", "#F4F4F4", "#F4F4F4", "#5A3A2A", "slick", { restraint = "#1B1B1B", variant = "Muken" }),
	},
	kenpachi = { name = "Kenpachi", world = "Bleach", rig = rig("#E8B890", "#111111", "#111111", "#111111", "spikebells", { haori = "#F4F4F4", scale = 1.3 }) },
	yamamoto = {
		name = "Yamamoto",
		world = "Bleach",
		rig = rig("#E8C8A8", "#111111", "#111111", "#F4F4F4", "bald", { beard = "#F4F4F4", haori = "#F4F4F4", accent = "#FF7A1A" }),
	},
	yhwach = {
		name = "Yhwach (The Almighty)",
		world = "Bleach",
		rig = rig("#E8D8C8", "#111111", "#111111", "#111111", "long", { cape = "#111111", variant = "The Almighty", scale = 1.4 }),
	},
	-- JUJUTSU KAISEN (Mahoraga replaces Megumi)
	yuji = { name = "Yuji", world = "JJK", rig = rig("#F2C9A8", "#1B1B2A", "#1B1B2A", "#FF8FA8", "short", { hood = "#D8261E" }) },
	gojo = { name = "Gojo", world = "JJK", rig = rig("#F2C9A8", "#1B1B2A", "#1B1B2A", "#F4F4F4", "spiky", { blindfold = "#111111" }) },
	toji = { name = "Toji", world = "JJK", rig = rig("#E8B890", "#1B1B1B", "#E8E8EE", "#111111", "short", { prop = "staff", scar = true }) },
	mahoraga = { name = "Mahoraga", world = "JJK", rig = rig("#E8E0D8", "#E8E0D8", "#E8E0D8", "#E8E0D8", "bald", { wheel = "#C9A24A", scale = 1.7 }) },
	sukuna = { name = "Sukuna", world = "JJK", rig = rig("#F2C9A8", "#F4F4F4", "#1B1B1B", "#FF8FA8", "spiky", { markings = "#111111", scale = 1.3 }) },
	-- SOLO LEVELING
	igris = { name = "Igris", world = "SoloLeveling", rig = rig("#1B1B22", "#2A1A20", "#2A1A20", "#D8261E", "plume", { armor = "#1B1B22", scale = 1.3 }) },
	beru = { name = "Beru", world = "SoloLeveling", rig = rig("#2A1A3A", "#3A1F5A", "#3A1F5A", "#6A2FB0", "insect", { scale = 1.3 }) },
	chahaein = { name = "Cha Hae-In", world = "SoloLeveling", rig = rig("#F2C9A8", "#F4F4F4", "#E8C66A", "#E8C66A", "long", { prop = "sword" }) },
	thomasandre = { name = "Thomas Andre", world = "SoloLeveling", rig = rig("#F2C9A8", "#1B1B1B", "#3A3F63", "#E8C66A", "slick", { scale = 1.45 }) },
	sungjinwoo = {
		name = "Sung Jin-Woo",
		world = "SoloLeveling",
		rig = rig("#F2C9A8", "#111111", "#111111", "#111111", "short", { coat = "#111111", eyes = "#3A7BFF", scale = 1.2 }),
	},
}

--[[ Egg visual specs (Master Egg Pipeline). motifs are composable primitives. ]]
local function egg(primary, secondary, glow, motifs, extra)
	local e = { primary = primary, secondary = secondary, glow = glow, motifs = motifs }
	if extra then
		for k, v in extra do
			e[k] = v
		end
	end
	return e
end

W.EGG_VISUALS = {
	-- Demon Slayer: approved assets (§31). Only Tanjiro is generated (PROVISIONAL gap fill).
	tanjiro = egg(
		"#1FAE6A",
		"#16223A",
		"#FF8A3D",
		{ "checker", "sunflame", "waterswirl" },
		{ provisional = true, note = "No approved Tanjiro egg exists in Last CP" }
	),
	rengoku = { approvedAsset = "Rengoku - flame egg" },
	yoriichi = { approvedAsset = "Yoriichi - Flaming Egg of Burning" },
	muzan = { approvedAsset = "Muzan - McVisibility Demons Heart Egg" },
	akaza = { approvedAsset = "Akaza - Crimson Catsegg V2.0" },
	-- MHA (§36)
	deku = egg("#1F8F5A", "#0F3D2A", "#7CFF5A", { "lightning", "bands" }),
	bakugo = egg("#FF7A1A", "#1B1B1B", "#FFB347", { "explosion", "gauntletcap", "split" }),
	todoroki = egg("#9FE3FF", "#D8261E", "#FFFFFF", { "halfsplit", "icecrystals", "flames" }, { splitColors = true }),
	allmight = egg("#1F4FD6", "#D8261E", "#FFD23F", { "antenna", "star", "impactring" }),
	shigaraki = egg("#3A2A4A", "#9B4DFF", "#B266FF", { "cracks", "hands", "decay" }, { boss = true }),
	-- Dragon Ball (R02)
	goku = egg("#FF7A1A", "#1F4FD6", "#FFD23F", { "flames", "kanji", "aura" }),
	vegeta = egg("#1F4FD6", "#F4F4F4", "#FFD23F", { "crest", "spikes", "aura" }),
	gohan = egg("#6A2FB0", "#F4F4F4", "#C9A2FF", { "blades", "aura" }),
	broly = egg("#1B3A1B", "#7CFF5A", "#9BFF6A", { "spikes", "flames", "aura" }),
	frieza = egg("#F4F4F4", "#8A2BE2", "#D6A8FF", { "dome", "gems", "aura" }, { boss = true }),
	-- One Piece (R02; Nami + Kaido active)
	luffy = egg("#D8261E", "#FFD23F", "#FF8A3D", { "strawhat", "flames" }),
	zoro = egg("#1F7A3A", "#F4F4F4", "#7CFFB0", { "swords3", "slash" }),
	nami = egg("#FF7A1A", "#3FB6FF", "#9FE3FF", { "clouds", "lightning", "compass" }),
	kaido = egg("#1F4FD6", "#6A2FB0", "#6FB8FF", { "horns", "scales", "dragonwhiskers" }),
	doflamingo = egg("#FF6FB5", "#FFE36A", "#FF9DE6", { "feathers", "strings", "crown" }, { boss = true }),
	-- Naruto (R02; Madara = Rinnegan)
	naruto = egg("#FF7A1A", "#FFD23F", "#FFB347", { "spiral", "flames" }),
	sasuke = egg("#3A5BFF", "#1B1B2A", "#6FB8FF", { "sharingan", "lightning" }),
	kakashi = egg("#8FA0B8", "#1F4FD6", "#BFE0FF", { "lightning", "headband" }),
	itachi = egg("#D8261E", "#111111", "#FF4D4D", { "sharingan", "clouds", "crows" }),
	madara = egg("#3A1F5A", "#9B4DFF", "#C77DFF", { "rinnegan", "flames" }, { boss = true }),
	-- Berserk (R02; Griffith = R11)
	guts = egg("#1B1B1B", "#D8261E", "#FF3B30", { "skull", "flames", "blade" }, { redBoost = true }),
	casca = egg("#C9A24A", "#6A0F1E", "#FFD27A", { "crest", "sword" }),
	skullknight = egg("#E8E0CC", "#1B1B1B", "#B0A48A", { "skull", "horns", "crest" }),
	zodd = egg("#3A2A20", "#D8261E", "#FF6A3D", { "horns", "fangs", "flames" }),
	griffith = egg("#F4EEE8", "#9B7BD8", "#E8DAFF", { "hawkhelm", "wings", "crown" }, { boss = true, reference = "R11" }),
	-- Bleach eggs from R02 (Aizen egg = Galaxy/Cosmic identity; model = Muken)
	ichigo = egg("#FF7A1A", "#111111", "#FF8A3D", { "zangetsu", "flames" }),
	aizen = egg("#1A1440", "#9B4DFF", "#6FB8FF", { "galaxy", "stars", "rings" }, { cosmic = true }),
	kenpachi = egg("#111111", "#F4F4F4", "#FFFFFF", { "spikes", "slash", "bells" }),
	yamamoto = egg("#FFB300", "#D8261E", "#FF8A3D", { "flames", "crest", "burningaura" }),
	yhwach = egg("#111111", "#3A7BFF", "#8FB8FF", { "eyes", "crest", "spikes" }, { boss = true }),
	-- JJK (R02; Mahoraga replaces Megumi; Sukuna = shrine)
	yuji = egg("#D8261E", "#1B1B2A", "#FF6A8A", { "blackflash", "bands" }),
	gojo = egg("#F4F4F4", "#3FB6FF", "#9FE3FF", { "infinity", "eyes" }),
	toji = egg("#1B1B1B", "#8FA0B8", "#BFC6D6", { "chains", "blade" }),
	mahoraga = egg("#E8E0D8", "#C9A24A", "#FFE9A8", { "wheel", "halo" }),
	sukuna = egg("#111111", "#D8261E", "#FF3B30", { "shrine", "horns", "markings" }, { boss = true }),
	-- Solo Leveling (R02)
	igris = egg("#1B1B22", "#D8261E", "#FF4D4D", { "knighthelm", "plume" }),
	beru = egg("#3A1F5A", "#9B4DFF", "#C77DFF", { "insectwings", "mandibles" }),
	chahaein = egg("#F4F4F4", "#E8C66A", "#FFF2B8", { "light", "sword", "halo" }),
	thomasandre = egg("#3A3F63", "#E8C66A", "#FFD27A", { "impactring", "bands", "heavyplates" }),
	sungjinwoo = egg("#0B1020", "#3A7BFF", "#6A5BFF", { "shadowflames", "eyes", "crown" }, { boss = true }),
}

-- Derived tables ---------------------------------------------------------------
W.EGGS = {} -- eggId -> { id, character, world, spawnName }
for worldId, world in W.WORLDS do
	for slot, charId in world.roster do
		local c = W.CHARACTERS[charId]
		assert(c, "missing character " .. charId)
		c.id = charId
		c.isBoss = (charId == world.boss)
		c.slot = slot
		c.egg = "egg_" .. charId
		local base = c.name:match("^([^%(/]+)") or c.name
		local spawnName = (base:gsub("[^%w]", "")) .. "Spawn" -- e.g. AkazaSpawn, NamiSpawn, GriffithSpawn
		W.EGGS[c.egg] = { id = c.egg, character = charId, world = worldId, slot = slot, spawnName = spawnName, isBossEgg = c.isBoss }
	end
end

function W.characterList(): { string }
	local list = {}
	for _, worldId in W.ORDER do
		for _, charId in W.WORLDS[worldId].roster do
			table.insert(list, charId)
		end
	end
	return list
end

function W.worldOf(charId: string): string?
	local c = W.CHARACTERS[charId]
	return c and c.world
end

return W
