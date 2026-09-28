--!nocheck
--[[
	Treadmill — premium futuristic treadmill with 10 physically distinct levels (§88–§90).

	Every part lives under Tiers/TierN and carries TierMin (+ optional TierMax when a
	better piece REPLACES it). TreadmillService shows exactly the pieces of the owner's
	level. Visual progression (cumulative):
	  L1  premium athletic treadmill (dark frame, belt, rollers, console)
	  L2  coloured side skirts + first neon trims + lit console
	  L3  heavy chrome rails (replace basic rails) + animated neon belt stripes
	  L4  emissive side fins
	  L5  caged energy core under the console (+ light, particles)
	  L6  giant halo arch over the belt
	  L7  twin energy pylons with lightning arcs (Beams) + second halo
	  L8  holographic side panels + mechanical pistons
	  L9  hex energy floor platform + triple spinning rings
	  L10 max: light wings, crown spires, gold trim replacing cyan, intense aura
	Local frame: runner stands on the belt facing -Z (console end). Origin = floor centre.
	Parts with attribute Spin / BeltStripe / Pulse are animated client-side (TreadmillFx).
]]
local B = require("./B")
local R = B.R
local V3, CF, A = B.V3, B.CF, B.Angles

local T = {}

local INK, METAL, DARK = "#1B1F2E", "#9AA3B8", "#23283A"
local CYAN, GOLD, VIOLET = "#3FE0FF", "#FFD23F", "#9B4DFF"
local BELT_TOP = 1.6
local LEN, WID = 12, 5

local function tierFolder(root, n)
	local f = root:FindFirstChild("Tier" .. n) or B.model(root, "Tier" .. n)
	return f
end

local function tp(folder, tierMin, tierMax, fn)
	local p = fn(folder)
	local list = type(p) == "table" and p or { p }
	for _, part in list do
		if part and part:IsA("BasePart") then
			part:SetAttribute("TierMin", tierMin)
			if tierMax then
				part:SetAttribute("TierMax", tierMax)
			end
			part:SetAttribute("BaseTransparency", part.Transparency)
		end
	end
	return p
end

-- builds the machine at `origin` (CFrame, facing -Z = console end). returns Model
function T.build(parent, origin)
	local m = B.model(parent, "Treadmill")
	local tiers = B.model(m, "Tiers")
	local function at(x, y, z, rx, ry, rz)
		return origin * CF(x, y, z) * A(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
	end
	local function box(tier, maxT, name, sx, sy, sz, x, y, z, col, mat, opts, rx, ry, rz)
		local f = tierFolder(tiers, tier)
		return tp(f, tier, maxT, function(ff)
			return B.part(ff, name, V3(sx, sy, sz), at(x, y, z, rx, ry, rz), col, mat, opts)
		end)
	end
	local function cyl(tier, maxT, name, d, len, cf, col, mat, opts)
		local f = tierFolder(tiers, tier)
		return tp(f, tier, maxT, function(ff)
			return B.cylCF(ff, name, d, len, cf, col, mat, opts)
		end)
	end
	-- ── functional parts (always present) ──────────────────────────────────
	local belt = B.part(m, "Belt", V3(WID - 1, 0.3, LEN - 1.2), at(0, BELT_TOP, 0), "#15171F", "Rubber", { collide = true })
	local zone = B.part(m, "TrainZone", V3(WID - 1.2, 1, LEN - 2), at(0, BELT_TOP + 0.6, 0), "#FFFFFF", "SmoothPlastic", { transparency = 1 })
	zone.CanQuery = false
	-- ── L1: premium athletic treadmill ────────────────────────────────────
	box(1, nil, "Deck", WID + 0.6, 1.2, LEN, 0, 0.8, 0, DARK, "Metal", { collide = true })
	box(1, nil, "DeckLip", WID + 0.8, 0.25, LEN + 0.2, 0, 1.42, 0, INK, "Metal")
	for _, z in { -LEN / 2 + 0.6, LEN / 2 - 0.6 } do
		cyl(1, nil, "Roller", 0.9, WID - 0.6, at(0, BELT_TOP - 0.1, z), METAL, "Metal")
	end
	for _, s in { -1, 1 } do
		box(1, 2, "BasicRail", 0.25, 0.25, LEN * 0.55, s * (WID / 2 + 0.1), 4.4, -LEN * 0.18, METAL, "Metal")
		box(1, 2, "BasicPost", 0.3, 3.2, 0.3, s * (WID / 2 + 0.1), 3, -LEN / 2 + 0.7, METAL, "Metal")
	end
	box(1, nil, "ConsolePost", 0.8, 4.2, 0.8, 0, 3.3, -LEN / 2 + 0.4, DARK, "Metal", nil, -8)
	box(1, nil, "Console", 3.6, 1.4, 0.6, 0, 5.4, -LEN / 2 + 0.2, INK, "Metal", nil, -30)
	box(1, 1, "ScreenOff", 3, 0.9, 0.1, 0, 5.45, -LEN / 2 + 0.52, "#2A3A55", "Glass", nil, -30)
	-- ── L2: skirts + first neon ───────────────────────────────────────────
	for _, s in { -1, 1 } do
		box(2, nil, "Skirt", 0.3, 1, LEN - 0.6, s * (WID / 2 + 0.45), 0.9, 0, "#2F5BFF", "SmoothPlastic")
		box(2, 9, "NeonTrim", 0.12, 0.12, LEN - 0.8, s * (WID / 2 + 0.62), 1.2, 0, CYAN, "Neon")
		box(10, nil, "GoldTrim", 0.16, 0.16, LEN - 0.8, s * (WID / 2 + 0.64), 1.2, 0, GOLD, "Neon")
	end
	box(2, nil, "ScreenOn", 3, 0.9, 0.1, 0, 5.45, -LEN / 2 + 0.53, "#3FE0FF", "Neon", { transparency = 0.15 }, -30)
	-- ── L3: heavy chrome rails + animated belt stripes ────────────────────
	for _, s in { -1, 1 } do
		box(3, nil, "ChromeRail", 0.55, 0.55, LEN * 0.7, s * (WID / 2 + 0.25), 4.5, -LEN * 0.12, "#DDE4EE", "Metal", { reflect = 0.2 })
		box(3, nil, "RailGlow", 0.2, 0.12, LEN * 0.7, s * (WID / 2 + 0.25), 4.2, -LEN * 0.12, CYAN, "Neon")
		for _, z in { -LEN / 2 + 0.8, LEN * 0.22 } do
			box(3, nil, "RailPost", 0.5, 3.4, 0.5, s * (WID / 2 + 0.25), 2.9, z, "#DDE4EE", "Metal")
		end
	end
	for i = 0, 5 do
		local p = box(3, nil, "BeltStripe", WID - 1.4, 0.05, 0.25, 0, BELT_TOP + 0.18, -LEN / 2 + 1 + i * (LEN - 2) / 6, CYAN, "Neon")
		p:SetAttribute("BeltStripe", i)
	end
	-- ── L4: emissive side fins ────────────────────────────────────────────
	for _, s in { -1, 1 } do
		for k = 0, 2 do
			box(4, nil, "Fin", 0.25, 2.6 - k * 0.4, 1.6, s * (WID / 2 + 1.1 + k * 0.1), 2 + k * 0.1, -2.5 + k * 2.6, "#2F5BFF", "Metal", nil, 0, 0, s * -18)
			box(4, nil, "FinGlow", 0.08, 2.2 - k * 0.4, 0.2, s * (WID / 2 + 1.25 + k * 0.1), 2 + k * 0.1, -2.5 + k * 2.6 - 0.7, VIOLET, "Neon", nil, 0, 0, s * -18)
		end
	end
	-- ── L5: caged energy core ─────────────────────────────────────────────
	local core = tp(tierFolder(tiers, 5), 5, nil, function(f)
		return B.ball(f, "EnergyCore", 1.8, 0, 0, 0, "#7FF3FF", "Neon")
	end)
	core.CFrame = at(0, 2.3, -LEN / 2 - 1.3)
	core:SetAttribute("Pulse", true)
	B.light(core, "#7FF3FF", 16, 1.4)
	B.emitter(core, "CoreSparks", { colors = { "#FFFFFF", "#3FE0FF" }, rate = 10, life = { 0.4, 0.8 }, speed = { 1, 3 }, size = { { 0, 0.3 }, { 1, 0 } }, light = 1 })
	for k = 0, 3 do
		box(5, nil, "CoreCage", 0.18, 2.8, 0.18, math.sin(k * math.pi / 2) * 1.2, 2.3, -LEN / 2 - 1.3 + math.cos(k * math.pi / 2) * 1.2, "#DDE4EE", "Metal")
	end
	box(5, nil, "CoreBase", 3, 0.5, 3, 0, 0.8, -LEN / 2 - 1.3, DARK, "Metal")
	-- ── L6: halo arch ─────────────────────────────────────────────────────
	local halo = tierFolder(tiers, 6)
	for _, p in B.ring(halo, "Halo", at(0, 4.2, 0.5) * A(math.rad(90), 0, 0), 4.2, 0.45, 30, CYAN, "Neon") do
		p:SetAttribute("TierMin", 6)
		p:SetAttribute("BaseTransparency", 0)
	end
	-- ── L7: twin pylons + arcs + second halo ──────────────────────────────
	local pylonTops = {}
	for _, s in { -1, 1 } do
		box(7, nil, "Pylon", 1, 7, 1, s * (WID / 2 + 2.3), 3.7, LEN / 2 - 1, "#2A2F48", "Metal")
		local top = box(7, nil, "PylonCap", 1.5, 1.5, 1.5, s * (WID / 2 + 2.3), 7.6, LEN / 2 - 1, VIOLET, "Neon")
		top:SetAttribute("Pulse", true)
		table.insert(pylonTops, top)
	end
	local a0 = R.Instance.new("Attachment")
	a0.Parent = pylonTops[1]
	local a1 = R.Instance.new("Attachment")
	a1.Parent = pylonTops[2]
	local beam = R.Instance.new("Beam")
	beam.Name = "Arc"
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Color = B.cseq({ "#C77DFF", "#3FE0FF" })
	beam.Width0, beam.Width1 = 0.6, 0.6
	beam.LightEmission = 1
	beam.CurveSize0, beam.CurveSize1 = 3, -3
	beam.Segments = 20
	beam.FaceCamera = true
	beam.Parent = pylonTops[1]
	local halo2 = tierFolder(tiers, 7)
	for _, p in B.ring(halo2, "Halo2", at(0, 4.2, 3.4) * A(math.rad(90), 0, 0), 3.6, 0.35, 26, VIOLET, "Neon") do
		p:SetAttribute("TierMin", 7)
		p:SetAttribute("BaseTransparency", 0)
	end
	-- ── L8: holo panels + pistons ─────────────────────────────────────────
	for _, s in { -1, 1 } do
		for k = 0, 1 do
			box(8, nil, "HoloPanel", 0.1, 2.2, 3, s * (WID / 2 + 3.6), 5 + k * 2.6, -1 + k * 3, "#7FF3FF", "Neon", { transparency = 0.55 }, 0, s * -12, 0)
		end
		box(8, nil, "Piston", 0.5, 2.4, 0.5, s * (WID / 2 + 0.9), 2, LEN / 2 - 0.4, "#DDE4EE", "Metal")
		box(8, nil, "PistonGlow", 0.55, 0.3, 0.55, s * (WID / 2 + 0.9), 3.1, LEN / 2 - 0.4, CYAN, "Neon")
	end
	-- ── L9: hex floor platform + spinning rings ───────────────────────────
	for k = 0, 5 do
		local ang = k * 60
		box(9, nil, "HexEdge", 1, 0.3, 9.4, math.sin(math.rad(ang)) * 8.1, 0.2, math.cos(math.rad(ang)) * 8.1, CYAN, "Neon", nil, 0, ang + 90, 0)
	end
	box(9, nil, "HexFloor", 16, 0.2, 16, 0, 0.08, 0, "#141A2E", "Metal", nil, 0, 0, 0)
	for i = 1, 3 do
		local ringModel = B.model(tierFolder(tiers, 9), "SpinRing" .. i)
		ringModel:SetAttribute("Spin", 30 * i * (i % 2 == 0 and -1 or 1))
		ringModel:SetAttribute("SpinCenter", at(0, 8.5, 0).Position)
		for _, p in B.ring(ringModel, "Ring", at(0, 8.5, 0) * A(math.rad(90 * (i - 1) / 2), 0, math.rad(20 * i)), 2.2 + i * 0.6, 0.25, 22, i == 2 and VIOLET or CYAN, "Neon") do
			p:SetAttribute("TierMin", 9)
			p:SetAttribute("BaseTransparency", 0)
		end
	end
	-- ── L10: light wings, crown spires, gold, intense aura ────────────────
	for _, s in { -1, 1 } do
		for k = 0, 2 do
			local f = tierFolder(tiers, 10)
			tp(f, 10, nil, function(ff)
				return B.wedge(ff, "LightWing", 0.15, 5 - k, 6 - k * 1.2, at(s * (WID / 2 + 4 + k * 1.6), 6 + k * 1.3, 2.5, 0, s * 25, s * (-40 - k * 10)), GOLD, "Neon", { transparency = 0.25 })
			end)
		end
	end
	for k = -2, 2 do
		local f = tierFolder(tiers, 10)
		tp(f, 10, nil, function(ff)
			local p = B.part(ff, "CrownSpire", V3(0.35, 1.6 - math.abs(k) * 0.3, 0.35), at(k * 0.7, 6.8 - math.abs(k) * 0.15, -LEN / 2 + 0.1), GOLD, "Neon")
			return p
		end)
	end
	local aura = box(10, nil, "AuraEmitter", 1, 1, 1, 0, 1, 0, "#FFFFFF", "SmoothPlastic", { transparency = 1 })
	aura:SetAttribute("BaseTransparency", 1)
	B.emitter(aura, "MaxAura", { colors = { GOLD, "#FFFFFF", CYAN }, rate = 24, life = { 1, 2 }, speed = { 2, 5 }, size = { { 0, 0.5 }, { 1, 0 } }, light = 1, rot = 90 })
	-- disable everything above L1 in the baked copy (server applies the owner's level)
	for _, d in tiers:GetDescendants() do
		if d:IsA("BasePart") then
			local minL = d:GetAttribute("TierMin") or 1
			if minL > 1 then
				d.Transparency = 1
				for _, fx in d:GetChildren() do
					if fx:IsA("ParticleEmitter") or fx:IsA("Beam") or fx:IsA("Light") then
						fx.Enabled = false
					end
				end
			end
		end
	end
	m:SetAttribute("Level", 1)
	return m
end

-- Preview helper: show a given level in the baked copy (used for review renders only).
function T.showLevel(m, level)
	for _, d in m:FindFirstChild("Tiers"):GetDescendants() do
		if d:IsA("BasePart") then
			local minL = d:GetAttribute("TierMin") or 1
			local maxL = d:GetAttribute("TierMax") or math.huge
			local vis = level >= minL and level <= maxL
			d.Transparency = vis and (d:GetAttribute("BaseTransparency") or 0) or 1
		end
	end
end

return T
