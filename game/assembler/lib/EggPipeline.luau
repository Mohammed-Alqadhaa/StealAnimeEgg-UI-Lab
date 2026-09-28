--!nocheck
--[[
	EggPipeline — the Master Egg Pipeline (§54): ONE config-driven builder for every
	generated character egg. Input: Worlds.EGG_VISUALS[charId]
	  { primary, secondary, glow, motifs = {...}, boss?, cosmic?, redBoost?, splitColors? }
	Output: Model "Visual" (shell + motifs + aura + light) standing on y = 0.

	The egg communicates the character's ESSENCE through colour, motif geometry and
	energy (§30) — never a portrait. Shell = two blended ellipsoids (egg profile: wide
	base, narrower taller crown). Motifs are composable primitives; boss eggs get a
	crown ring + stronger aura (§52: visual only, no gameplay difference).
	Demon Slayer eggs are NOT generated here (§31) — the approved models are reused.
]]
local B = require("./B")
local R = B.R
local V3, CF, A = B.V3, B.CF, B.Angles

local P = {}

-- egg profile ---------------------------------------------------------------
local LOW = { cy = 2.6, rx = 2.5, ry = 2.6 }
local UP = { cy = 3.9, rx = 2.05, ry = 2.95 }
P.HEIGHT = UP.cy + UP.ry -- ≈ 6.85
local function radiusAt(y)
	local function r(e)
		local t = (y - e.cy) / e.ry
		if math.abs(t) >= 1 then
			return 0
		end
		return e.rx * math.sqrt(1 - t * t)
	end
	return math.max(r(LOW), r(UP))
end
P.radiusAt = radiusAt

-- point on the shell at angle theta (0 = front, facing -Z) and height y; returns CFrame facing outward
local function surface(theta, y, lift)
	local r = radiusAt(y) + (lift or 0)
	local x, z = math.sin(theta) * r, -math.cos(theta) * r
	local pos = V3(x, y, z)
	local out = V3(x, 0, z).Unit
	return R.CFrame.lookAt(pos, pos + out)
end

local function col(v)
	return B.color(v)
end

-- motif primitives -------------------------------------------------------------
local M = {}

function M.band(m, s, y, c, thick, mat)
	local d = radiusAt(y) * 2 + 0.12
	B.cyl(m, "Band", d, thick or 0.35, 0, y, 0, c, mat or "SmoothPlastic")
end

function M.plates(m, cols, rows, ymin, ymax, colors, size, mat, pattern)
	local i = 0
	for row = 0, rows - 1 do
		local y = ymin + (ymax - ymin) * (row + 0.5) / rows
		for k = 0, cols - 1 do
			i += 1
			local useSecond = pattern == "checker" and ((row + k) % 2 == 1) or (pattern ~= "checker" and (i % 2 == 0))
			local c = useSecond and colors[2] or colors[1]
			if c then
				local theta = (k + (row % 2) * 0.5) / cols * math.pi * 2
				local cf = surface(theta, y, -0.05)
				B.part(m, "Plate", V3(size, size * 0.9, 0.25), cf, c, mat or "SmoothPlastic")
			end
		end
	end
end

function M.spikes(m, n, y, len, c, mat, tilt)
	for i = 1, n do
		local theta = i / n * math.pi * 2
		local base = surface(theta, y, -0.15)
		B.spike(m, "Spike", 0.8, len, base * A(math.rad(-90 + (tilt or 20)), 0, 0), c, mat or "SmoothPlastic", 3)
	end
end

function M.crown(m, c, mat, n)
	n = n or 7
	local y = P.HEIGHT - 0.9
	for i = 1, n do
		local theta = i / n * math.pi * 2
		local r = radiusAt(y) * 0.8
		local base = CF(math.sin(theta) * r, y, -math.cos(theta) * r) * A(math.cos(theta) * math.rad(-18), 0, math.sin(theta) * math.rad(-18))
		B.spike(m, "CrownSpike", 0.55, 1.4, base, c, mat or "Neon", 3)
	end
end

function M.ringAround(m, y, radius, c, tilt, mat)
	B.ring(m, "EnergyRing", CF(0, y, 0) * A(math.rad(tilt or 12), 0, math.rad((tilt or 12) * 0.6)), radius, 0.28, 28, c, mat or "Neon")
end

function M.halo(m, c)
	B.ring(m, "Halo", CF(0, P.HEIGHT + 0.9, 0), 1.6, 0.3, 20, c, "Neon")
end

function M.horns(m, c, mat, big)
	for _, s in { -1, 1 } do
		local base = CF(s * 1.55, P.HEIGHT - 1.6, 0) * A(0, 0, math.rad(s * -40))
		B.spike(m, "Horn", big and 1.1 or 0.8, big and 3.2 or 2.2, base, c, mat or "Marble", 5)
		B.spike(m, "HornTip", 0.45, 1.2, base * CF(0, big and 3.0 or 2.1, 0) * A(0, 0, math.rad(s * 35)), c, mat or "Marble", 3)
	end
end

function M.wings(m, c, mat, kind)
	for _, s in { -1, 1 } do
		for i = 0, 2 do
			local cf = CF(s * (2.4 + i * 0.9), 4 + i * 0.35, 0.6) * A(0, math.rad(s * 15), math.rad(s * (-25 - i * 12)))
			B.wedge(m, kind == "insect" and "InsectWing" or "Wing", 0.15, 2.8 - i * 0.5, 1.6 + i * 0.3, cf, c, mat or (kind == "insect" and "Glass" or "SmoothPlastic"), { transparency = kind == "insect" and 0.35 or 0 })
		end
	end
end

function M.tongues(m, c1, c2)
	for i = 1, 9 do
		local theta = i / 9 * math.pi * 2
		local base = surface(theta, 1.2, -0.3)
		B.wedge(m, "FlameTongue", 0.2, 2.2 + (i % 3) * 0.6, 1.1, base * CF(0, 1, 0), i % 2 == 0 and c1 or c2, "Neon")
	end
end

function M.lightning(m, c, count)
	for k = 1, count or 3 do
		local theta = k / (count or 3) * math.pi * 2 + 0.4
		local y = 1.3
		local prev = surface(theta, y, 0.05).Position
		for step = 1, 5 do
			y += 0.95
			theta += (step % 2 == 0) and 0.28 or -0.28
			local nxt = surface(theta, math.min(y, P.HEIGHT - 0.6), 0.05).Position
			B.segment(m, "Bolt", prev, nxt, 0.22, c, "Neon")
			prev = nxt
		end
	end
end

function M.cracks(m, c)
	M.lightning(m, c, 4)
end

function M.emblem(m, y, d, c, mat, name)
	local cf = surface(0, y, 0.05)
	return B.part(m, name or "Emblem", V3(d, d, 0.2), cf, c, mat or "SmoothPlastic", { shape = nil }), cf
end

function M.disc(m, cf, d, c, mat, name)
	return B.cylCF(m, name or "Disc", d, 0.18, cf * A(0, math.rad(90), 0), c, mat or "SmoothPlastic")
end

function M.eye(m, kind, c1, c2)
	local cf = surface(0, 3.6, 0.1)
	if kind == "rinnegan" then
		-- concentric ripple rings (Rinnegan visual language, §42)
		M.disc(m, cf, 2.6, col("#C9B8FF"), "Neon", "EyeWhite")
		for i, d in { 2.2, 1.6, 1.0 } do
			M.disc(m, cf * CF(0, 0, -0.02 * i), d + 0.12, col("#3A1F5A"), "SmoothPlastic", "RippleLine")
			M.disc(m, cf * CF(0, 0, -0.02 * i - 0.01), d, col("#B08CFF"), "Neon", "Ripple")
		end
		M.disc(m, cf * CF(0, 0, -0.1), 0.45, col("#1A0A2A"), "SmoothPlastic", "Pupil")
	elseif kind == "sharingan" then
		M.disc(m, cf, 2.2, col("#D8261E"), "Neon", "Iris")
		M.disc(m, cf * CF(0, 0, -0.03), 0.5, col("#111111"), "SmoothPlastic", "Pupil")
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2
			B.ball(m, "Tomoe", 0.42, 0, 0, 0, col("#111111"), "SmoothPlastic").CFrame = cf * CF(math.sin(a) * 0.65, math.cos(a) * 0.65, -0.1)
		end
	else
		for _, x in { -0.7, 0.7 } do
			B.part(m, "GlowEye", V3(0.9, 0.3, 0.15), cf * CF(x, 0, -0.05) * A(0, 0, math.rad(x * 12)), c1 or col("#6FB8FF"), "Neon")
		end
	end
end

function M.skull(m, c)
	local cf = surface(0, 3.4, 0.2)
	B.ball(m, "Skull", 2.2, 0, 0, 0, c or col("#EDE6D6"), "Marble").CFrame = cf * CF(0, 0.2, -0.3)
	B.part(m, "Jaw", V3(1.3, 0.7, 0.8), cf * CF(0, -0.8, -0.5), c or col("#EDE6D6"), "Marble")
	for _, x in { -0.45, 0.45 } do
		B.ball(m, "EyeSocket", 0.62, 0, 0, 0, col("#1A0000"), "SmoothPlastic").CFrame = cf * CF(x, 0.3, -1.25)
		B.ball(m, "EyeGlow", 0.25, 0, 0, 0, col("#FF3B30"), "Neon").CFrame = cf * CF(x, 0.3, -1.4)
	end
	for i = -2, 2 do
		B.part(m, "Tooth", V3(0.18, 0.3, 0.12), cf * CF(i * 0.22, -0.7, -0.92), col("#F4F0E6"), "Marble")
	end
end

function M.hands(m, c)
	for _, s in { -1, 1 } do
		local palm = surface(s * 1.9, 2.4, 0.1)
		B.part(m, "Palm", V3(1.2, 1.3, 0.35), palm, c, "SmoothPlastic")
		for f = -1.5, 1.5, 1 do
			B.part(m, "Finger", V3(0.28, 1.4, 0.28), palm * CF(f * 0.32, 1.1, -0.15) * A(math.rad(-20), 0, 0), c, "SmoothPlastic")
		end
	end
end

function M.shrine(m, c1, c2)
	local top = P.HEIGHT - 0.4
	for i, w in { 3.4, 2.6, 1.8 } do
		local y = top + (i - 1) * 0.9
		for _, s in { -1, 1 } do
			B.wedge(m, "Roof", w, 0.55, w * 0.55, CF(0, y, s * w * 0.27) * A(0, s == 1 and 0 or math.pi, 0), c1, "Slate")
		end
		B.box(m, "RoofBeam", w * 0.7, 0.35, 0.35, 0, y - 0.3, 0, c2, "Wood")
	end
	for _, s in { -1, 1 } do
		B.spike(m, "ShrineHorn", 0.5, 1.8, CF(s * 1.4, top + 2.4, 0) * A(0, 0, math.rad(s * -30)), col("#EDE6D6"), "Marble", 4)
	end
	-- cursed teeth around the base (Malevolent Shrine)
	for i = 1, 10 do
		local cf = surface(i / 10 * math.pi * 2, 0.9, -0.1)
		B.wedge(m, "Tooth", 0.3, 0.9, 0.5, cf, col("#F4F0E6"), "Marble")
	end
end

function M.wheel(m, c)
	local center = CF(0, P.HEIGHT + 1.5, 0)
	B.ring(m, "WheelRim", center * A(math.rad(90), 0, 0), 1.7, 0.3, 24, c, "Metal")
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		B.part(m, "Spoke", V3(0.22, 1.7, 0.22), center * A(0, 0, a) * CF(0, 0.85, 0), c, "Metal")
		B.ball(m, "Knob", 0.5, 0, 0, 0, c, "Metal").CFrame = center * A(0, 0, a) * CF(0, 1.95, 0)
	end
	B.ball(m, "Hub", 0.7, 0, 0, 0, col("#FFE9A8"), "Neon").CFrame = center
end

function M.strawhat(m)
	local y = P.HEIGHT - 0.5
	B.cyl(m, "Brim", 4.6, 0.2, 0, y, 0, col("#E8C66A"), "Fabric")
	B.cyl(m, "Crown", 2.6, 1.3, 0, y + 0.6, 0, col("#E8C66A"), "Fabric")
	B.cyl(m, "RedBand", 2.65, 0.35, 0, y + 0.3, 0, col("#D8261E"), "Fabric")
end

function M.blades(m, c, count, crossed)
	count = count or 2
	for i = 1, count do
		local ang = crossed and ((i - (count + 1) / 2) * 35) or (i * 360 / count)
		local cf = CF(0, 3.4, 1.2) * A(0, 0, math.rad(ang))
		B.part(m, "Blade", V3(0.35, 6.5, 0.12), cf, c, "Metal")
		B.part(m, "Guard", V3(1.1, 0.25, 0.3), cf * CF(0, -2.2, 0), col("#C9A24A"), "Metal")
	end
end

function M.clouds(m, c)
	for i = 1, 10 do
		local theta = i / 10 * math.pi * 2
		local r = 2.9
		B.ball(m, "Cloud", 1.2 + (i % 3) * 0.35, math.sin(theta) * r, 0.6 + (i % 2) * 0.3, -math.cos(theta) * r, c, "SmoothPlastic")
	end
end

function M.galaxy(m, primary, secondary, glow)
	-- inner glowing core visible through a glass shell + orbiting rings (Galaxy Aizen feeling)
	B.ball(m, "CosmicCore", 3.2, 0, 3.2, 0, glow, "Neon")
	for i = 1, 14 do
		local th, y = i * 2.4, 1 + (i % 6)
		local cf = surface(th, y, 0.02)
		B.ball(m, "Star", 0.22 + (i % 3) * 0.08, 0, 0, 0, col("#FFFFFF"), "Neon").CFrame = cf
	end
	M.ringAround(m, 3.3, 3.4, secondary, 25)
	M.ringAround(m, 3.8, 3.0, glow, -35)
end

function M.spiral(m, c)
	for i = 0, 14 do
		local theta = i * 0.55
		local y = 1 + i * 0.36
		B.part(m, "Swirl", V3(0.9, 0.3, 0.2), surface(theta, y, 0.02), c, "Neon")
	end
end

function M.explosion(m, c1, c2)
	for i = 1, 12 do
		local theta = i / 12 * math.pi * 2
		local y = 2 + (i % 3) * 1.4
		B.spike(m, "Blast", 0.7, 1.4 + (i % 2) * 0.6, surface(theta, y, -0.2) * A(math.rad(-90), 0, 0), i % 2 == 0 and c1 or c2, "Neon", 3)
	end
end

function M.stars(m, c)
	for i = 1, 16 do
		B.ball(m, "StarDot", 0.35, 0, 0, 0, c, "Neon").CFrame = surface(i * 1.9, 1 + (i * 0.37) % 5, 0.02)
	end
end

function M.strings(m, c)
	for i = 1, 7 do
		local x = (i - 4) * 0.6
		local a0 = V3(x * 1.5, P.HEIGHT + 4, 0.3)
		local a1 = surface((i - 4) * 0.35, 4.5, 0).Position
		B.segment(m, "String", a0, a1, 0.07, c, "Neon")
	end
end

function M.feathers(m, c, c2)
	for i = 1, 14 do
		local theta = i / 14 * math.pi * 2
		B.wedge(m, "Feather", 0.25, 1.6, 1.2, surface(theta, 0.9, 0.2) * A(math.rad(-40), 0, 0), i % 2 == 0 and c or c2, "SmoothPlastic")
	end
end

function M.dome(m, c)
	B.ellipsoid(m, "Dome", 3.2, 2.0, 3.2, CF(0, P.HEIGHT - 0.9, 0), c, "Glass", { reflect = 0.15 })
end

function M.gems(m, c)
	for _, y in { 2.2, 3.6, 5.0 } do
		B.part(m, "Gem", V3(0.7, 0.7, 0.7), surface(0, y, 0.15) * A(0, 0, math.rad(45)), c, "Glass")
	end
end

function M.helm(m, c, kind)
	local y = 4.2
	B.ellipsoid(m, "Helm", 4.6, 3.2, 4.6, CF(0, y, 0), c, "Metal", { reflect = 0.1 })
	B.part(m, "Visor", V3(2.6, 0.35, 0.3), surface(0, y, 0.25), col(kind == "hawk" and "#9B7BD8" or "#FF3B30"), "Neon")
	if kind == "hawk" then
		B.wedge(m, "Beak", 0.5, 1.4, 1.2, surface(0, y - 0.3, 0.6) * A(math.rad(180), 0, 0), c, "Metal")
		for _, s in { -1, 1 } do
			B.wedge(m, "HelmWing", 0.2, 2.4, 1.4, CF(s * 2.3, y + 0.9, 0) * A(0, math.rad(s * 90), math.rad(s * -20)), c, "Metal")
		end
	end
end

function M.impact(m, c)
	M.ringAround(m, 1.2, 3.3, c, 0)
	M.ringAround(m, 1.8, 3.8, c, 0)
end

function M.chains(m, c)
	for k = 0, 1 do
		for i = 0, 11 do
			local theta = i / 12 * math.pi * 2
			local y = 2.2 + k * 2.3 + math.sin(theta) * 0.4
			B.part(m, "ChainLink", V3(0.7, 0.4, 0.25), surface(theta, y, 0.1) * A(0, 0, (i % 2) * math.rad(90)), c, "Metal")
		end
	end
end

-- motif name → builder (compositions of the primitives above)
local MOTIFS = {
	bands = function(m, s) M.band(m, s, 2.2, s.secondary) M.band(m, s, 4.6, s.secondary) end,
	checker = function(m, s) M.plates(m, 8, 5, 0.9, 5.8, { s.primary, s.secondary }, 1.2, "SmoothPlastic", "checker") end,
	split = function(m, s) M.plates(m, 6, 3, 3.2, 6.2, { s.secondary }, 1.4, "Metal") end,
	halfsplit = function(m, s)
		for row = 0, 5 do
			for k = 0, 3 do
				local y = 0.9 + row * 0.95
				local theta = (-0.5 - k / 3.2) * math.pi
				B.part(m, "IcePlate", V3(1.1, 1, 0.3), surface(theta, y, 0), col("#CFF4FF"), "Glass", { transparency = 0.2 })
			end
		end
		M.tongues(m, s.secondary, col("#FF8A3D"))
	end,
	icecrystals = function(m) for i = 1, 6 do B.spike(m, "Ice", 0.7, 1.6, surface(-1.8 - i * 0.25, 1.4 + i * 0.7, -0.1) * A(math.rad(-80), 0, 0), col("#E8FBFF"), "Glass", 3) end end,
	flames = function(m, s) M.tongues(m, s.glow, s.secondary) end,
	sunflame = function(m, s) M.tongues(m, col("#FF8A3D"), col("#FFD23F")) end,
	waterswirl = function(m) M.spiral(m, col("#3FB6FF")) end,
	lightning = function(m, s) M.lightning(m, s.glow, 3) end,
	explosion = function(m, s) M.explosion(m, s.glow, s.primary) end,
	gauntletcap = function(m, s) B.cyl(m, "GauntletCap", 3.2, 1.2, 0, 6.2, 0, s.secondary, "Metal") B.cyl(m, "Pin", 0.9, 1.8, 0, 7.2, 0, s.glow, "Neon") end,
	antenna = function(m, s) for _, x in { -1, 1 } do B.spike(m, "Antenna", 0.8, 3.2, CF(x * 0.6, P.HEIGHT - 0.8, 0) * A(math.rad(-10), 0, math.rad(x * -30)), s.glow, "Neon", 4) end end,
	star = function(m, s) local _, cf = M.emblem(m, 3.6, 1.6, s.glow, "Neon", "StarCore") B.part(m, "StarRayV", V3(0.5, 2.6, 0.2), cf * CF(0, 0, -0.05), s.glow, "Neon") B.part(m, "StarRayH", V3(2.6, 0.5, 0.2), cf * CF(0, 0, -0.05), s.glow, "Neon") end,
	impactring = function(m, s) M.impact(m, s.glow) end,
	cracks = function(m, s) M.cracks(m, s.secondary) end,
	hands = function(m) M.hands(m, col("#E8E0DA")) end,
	decay = function(m, s) B.emitter(m:FindFirstChild("Shell"), "Decay", { tex = "smoke", colors = { s.secondary, "#1A0F33" }, rate = 6, life = { 1, 2 }, speed = { 0.3, 0.8 }, size = { { 0, 1 }, { 1, 2.5 } }, transp = { { 0, 0.5 }, { 1, 1 } }, light = 0.3 }) end,
	kanji = function(m, s) M.emblem(m, 3.4, 1.8, col("#FFFFFF"), "SmoothPlastic", "Crest") M.emblem(m, 3.4, 1.2, s.primary, "Neon", "CrestMark") end,
	aura = function(m, s) M.ringAround(m, 0.8, 3.1, s.glow, 0) end,
	crest = function(m, s) local _, cf = M.emblem(m, 3.8, 1.8, s.secondary, "Metal", "Crest") B.part(m, "CrestGem", V3(0.7, 0.7, 0.3), cf * CF(0, 0, -0.15) * A(0, 0, math.rad(45)), s.glow, "Neon") end,
	spikes = function(m, s) M.spikes(m, 8, 4.2, 1.5, s.secondary, "Metal", 25) end,
	blades = function(m, s) M.blades(m, s.secondary, 2, true) end,
	dome = function(m, s) M.dome(m, s.secondary) end,
	gems = function(m, s) M.gems(m, s.secondary) end,
	strawhat = function(m) M.strawhat(m) end,
	swords3 = function(m) M.blades(m, col("#E8E8EE"), 3, true) end,
	slash = function(m, s) B.part(m, "Slash", V3(0.3, 7, 0.2), surface(0, 3.4, 0.15) * A(0, 0, math.rad(35)), s.glow, "Neon") end,
	clouds = function(m) M.clouds(m, col("#F4F8FF")) end,
	compass = function(m, s) local _, cf = M.emblem(m, 3.4, 1.9, col("#F4E8C8"), "SmoothPlastic", "Compass") B.part(m, "Needle", V3(0.3, 1.6, 0.2), cf * CF(0, 0, -0.1) * A(0, 0, math.rad(30)), s.secondary, "Neon") end,
	horns = function(m, s) M.horns(m, s.boss and col("#F4F4F4") or s.secondary, "Marble", true) end,
	scales = function(m, s) M.plates(m, 9, 6, 0.8, 5.8, { s.primary, s.secondary }, 0.95, "Glass") end,
	dragonwhiskers = function(m, s) for _, x in { -1, 1 } do B.segment(m, "Whisker", surface(x * 0.4, 3.2, 0).Position, surface(x * 1.2, 1.4, 1.6).Position, 0.15, s.glow, "Neon") end end,
	feathers = function(m, s) M.feathers(m, s.primary, col("#FFB8E0")) end,
	strings = function(m, s) M.strings(m, s.glow) end,
	crown = function(m, s) M.crown(m, s.secondary, "Neon") end,
	spiral = function(m, s) M.spiral(m, s.secondary) end,
	sharingan = function(m) M.eye(m, "sharingan") end,
	rinnegan = function(m) M.eye(m, "rinnegan") end,
	headband = function(m) M.band(m, nil, 4.4, col("#9AA3B8"), 0.7, "Metal") end,
	crows = function(m) for i = 1, 5 do B.wedge(m, "Crow", 0.2, 0.8, 1.4, surface(i * 1.2, 2 + i * 0.7, 0.4) * A(0, math.rad(90), 0), col("#111111"), "SmoothPlastic") end end,
	skull = function(m, s) M.skull(m) end,
	blade = function(m, s) M.blades(m, col("#3A3A3A"), 1, true) end,
	sword = function(m, s) M.blades(m, col("#E8E8EE"), 1, true) end,
	fangs = function(m, s) for i = -2, 2 do B.wedge(m, "Fang", 0.3, 1.2, 0.5, surface(i * 0.25, 2.2, 0.1) * A(math.rad(180), 0, 0), col("#F4F0E6"), "Marble") end end,
	hawkhelm = function(m, s) M.helm(m, col("#F4EEE8"), "hawk") end,
	wings = function(m, s) M.wings(m, s.secondary, "SmoothPlastic") end,
	zangetsu = function(m) B.part(m, "Zangetsu", V3(0.3, 7.2, 1.6), CF(1.8, 3.6, 1.4) * A(0, 0, math.rad(-20)), col("#1B1B1B"), "Metal") B.part(m, "Edge", V3(0.32, 7.2, 0.25), CF(1.8, 3.6, 0.65) * A(0, 0, math.rad(-20)), col("#E8E8EE"), "Metal") end,
	galaxy = function(m, s) M.galaxy(m, s.primary, s.secondary, s.glow) end,
	stars = function(m) M.stars(m, col("#FFFFFF")) end,
	rings = function(m, s) M.ringAround(m, 2.6, 3.6, s.secondary, 55) end,
	bells = function(m) for i = 1, 8 do local cf = surface(i / 8 * math.pi * 2, P.HEIGHT - 1.4, 0.4) B.ball(m, "Bell", 0.55, 0, 0, 0, col("#FFD23F"), "Metal").CFrame = cf end end,
	burningaura = function(m, s) M.ringAround(m, 0.6, 3.3, col("#FF8A3D"), 0) M.ringAround(m, 1.4, 3.6, col("#FFD23F"), 0) end,
	eyes = function(m, s) M.eye(m, "slits", s.glow) end,
	blackflash = function(m) M.lightning(m, col("#111111"), 2) M.lightning(m, col("#FF3B3B"), 2) end,
	infinity = function(m, s) M.ringAround(m, 3.4, 3.5, s.glow, 70) M.ringAround(m, 3.4, 3.5, s.secondary, -70) end,
	chains = function(m) M.chains(m, col("#8A93A6")) end,
	wheel = function(m, s) M.wheel(m, s.secondary) end,
	halo = function(m, s) M.halo(m, s.glow) end,
	shrine = function(m) M.shrine(m, col("#2A0A0A"), col("#8E0E1E")) end,
	markings = function(m) for i = 1, 4 do B.part(m, "CurseMark", V3(1.8, 0.18, 0.12), surface(i * 1.57, 2.6 + (i % 2) * 1.5, 0.05), col("#111111"), "SmoothPlastic") end end,
	knighthelm = function(m, s) M.helm(m, s.primary, "knight") end,
	plume = function(m, s) B.part(m, "Plume", V3(0.6, 2.4, 3), CF(0, P.HEIGHT + 0.6, 0.4), s.secondary, "Fabric") end,
	insectwings = function(m, s) M.wings(m, s.glow, "Glass", "insect") end,
	mandibles = function(m, s) for _, x in { -1, 1 } do B.spike(m, "Mandible", 0.5, 1.6, surface(x * 0.5, 1.4, 0) * A(math.rad(-120), 0, math.rad(x * 25)), s.secondary, "Glass", 3) end end,
	light = function(m, s) M.ringAround(m, 3.6, 3.2, s.glow, 10) end,
	heavyplates = function(m, s) M.plates(m, 6, 3, 1.4, 5.2, { s.secondary }, 1.7, "Metal") end,
	shadowflames = function(m, s) B.emitter(m:FindFirstChild("Shell"), "ShadowFlame", { tex = "fire", colors = { "#0B1020", s.secondary }, rate = 14, life = { 0.6, 1.2 }, speed = { 1, 2.5 }, spread = 25, size = { { 0, 2 }, { 1, 0.3 } }, transp = { { 0, 0.2 }, { 1, 1 } }, light = 0.4 }) end,
	light_rays = function() end,
}
P.MOTIFS = MOTIFS

-- Build an egg Visual model (base at y=0) for a spec.
function P.build(charId, spec)
	local m = R.Instance.new("Model")
	m.Name = "Visual"
	local s = {
		primary = col(spec.primary),
		secondary = col(spec.secondary),
		glow = col(spec.glow),
		boss = spec.boss,
	}
	local shellMat = spec.cosmic and "Glass" or "SmoothPlastic"
	local low = B.ellipsoid(m, "Shell", LOW.rx * 2, LOW.ry * 2, LOW.rx * 2, CF(0, LOW.cy, 0), s.primary, shellMat, { reflect = 0.08 })
	B.ellipsoid(m, "ShellCrown", UP.rx * 2, UP.ry * 2, UP.rx * 2, CF(0, UP.cy, 0), s.primary, shellMat, { reflect = 0.08 })
	if spec.cosmic then
		low.Transparency = 0.25
		m:FindFirstChild("ShellCrown").Transparency = 0.25
	end
	-- glossy highlight (white translucent sliver on the upper-left, like the UI Lab eggs)
	B.ellipsoid(m, "Gloss", 0.9, 2.2, 0.4, surface(-0.55, 4.6, 0.02), "#FFFFFF", "SmoothPlastic", { transparency = 0.45 })
	for _, name in spec.motifs do
		local fn = MOTIFS[name]
		if fn then
			fn(m, s)
		else
			warn("[EggPipeline] unknown motif " .. name .. " for " .. charId)
		end
	end
	if spec.boss then
		M.crown(m, s.glow, "Neon", 9) -- boss eggs look more premium (visual only, §52)
	end
	-- aura + glow (§30: energy / aura)
	local core = m:FindFirstChild("Shell")
	B.emitter(core, "Aura", { colors = { spec.glow, spec.secondary }, rate = spec.boss and 7 or 4, life = { 0.9, 1.6 }, speed = { 0.3, 0.9 }, size = { { 0, 0.45 }, { 0.6, 0.8 }, { 1, 0 } }, light = 0.7, rot = 60 })
	if spec.redBoost then
		B.emitter(core, "RedEnergy", { tex = "fire", colors = { "#FF3B30", "#8E0E0E" }, rate = 12, life = { 0.5, 1 }, speed = { 1, 2 }, spread = 30, size = { { 0, 1.6 }, { 1, 0.2 } }, transp = { { 0, 0.2 }, { 1, 1 } }, light = 0.9 })
	end
	B.light(core, spec.glow, spec.boss and 18 or 13, spec.boss and 1.6 or 1.1)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end
	m:SetAttribute("CharacterId", charId)
	m:SetAttribute("GeneratedBy", "MasterEggPipeline")
	if spec.provisional then
		m:SetAttribute("Provisional", true)
	end
	return m
end

return P
