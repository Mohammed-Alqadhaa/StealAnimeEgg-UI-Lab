--!nocheck
--[[
	Rigs — character rigs for gameplay (ServerStorage), UI previews (ReplicatedStorage)
	and bosses.

	1. sanitize(model, audit): §130 — strips Scripts/LocalScripts/ModuleScripts, remotes,
	   bindables, Tools, Configurations, and every attribute/tag, recording what was
	   removed in the import audit (§131).
	2. standIn(charId, spec): an ORIGINAL R6 rig built from parts when no real model of
	   the character exists in the place. Standard R6 joint layout (Motor6D names/C0/C1),
	   so default R6 animations work and a real model can later replace it 1:1.
	   Identity comes from colours, hair silhouette and signature props (Worlds.rig).
	   Every stand-in carries attribute StandIn=true → listed as OWNER ACTION REQUIRED.
]]
local B = require("./B")
local R = B.R
local V3, CF, A = B.V3, B.CF, B.Angles

local Rigs = {}

local REMOVE_CLASSES = {
	Script = true, LocalScript = true, ModuleScript = true,
	RemoteEvent = true, RemoteFunction = true, UnreliableRemoteEvent = true,
	BindableEvent = true, BindableFunction = true,
	Tool = true, HopperBin = true, Configuration = true,
}

function Rigs.sanitize(model, audit, label)
	local removed = {}
	local function note(kind)
		removed[kind] = (removed[kind] or 0) + 1
	end
	local toDelete = {}
	for _, d in model:GetDescendants() do
		if REMOVE_CLASSES[d.ClassName] then
			table.insert(toDelete, d)
		end
	end
	for _, d in toDelete do
		if d.Parent then
			note(d.ClassName)
			d:Destroy()
		end
	end
	local attrCount, tagCount = 0, 0
	for _, d in { model, table.unpack(model:GetDescendants()) } do
		for k in d:GetAttributes() do
			d:SetAttribute(k, nil)
			attrCount += 1
		end
		for _, t in d:GetTags() do
			d:RemoveTag(t)
			tagCount += 1
		end
	end
	if attrCount > 0 then
		removed.Attributes = attrCount
	end
	if tagCount > 0 then
		removed.Tags = tagCount
	end
	if audit then
		table.insert(audit, { name = label or model.Name, removed = removed })
	end
	return removed
end

-- ── stand-in R6 rig ─────────────────────────────────────────────────────────
local R6 = {
	-- name = { size, offset from torso centre }
	Head = { V3(2, 1, 1), V3(0, 1.5, 0) },
	Torso = { V3(2, 2, 1), V3(0, 0, 0) },
	["Left Arm"] = { V3(1, 2, 1), V3(-1.5, 0, 0) },
	["Right Arm"] = { V3(1, 2, 1), V3(1.5, 0, 0) },
	["Left Leg"] = { V3(1, 2, 1), V3(-0.5, -2, 0) },
	["Right Leg"] = { V3(1, 2, 1), V3(0.5, -2, 0) },
}

local function motor(parent, name, p0, p1, c0, c1)
	local m = R.Instance.new("Motor6D")
	m.Name = name
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = c0
	m.C1 = c1
	m.MaxVelocity = 0.1
	m.Parent = parent
	return m
end

local function attach(rig, part, name, pieceSize, offsetCF, col, mat, opts)
	local p = B.part(rig, name, pieceSize, part.CFrame * offsetCF, col, mat, opts)
	p.Anchored = false
	p.CanCollide = false
	p.Massless = true
	B.rigidWeld(part, p)
	return p
end

-- hair / headwear silhouettes: each returns nothing, builds onto head
local HAIR = {}
local function spikesOn(rig, head, col, count, len, spread, tilt, mat)
	for i = 1, count do
		local a = (i - 1) / count * math.pi * 2
		local cf = CF(math.sin(a) * spread, 0.35, math.cos(a) * spread * 0.8) * A(math.cos(a) * math.rad(tilt), 0, -math.sin(a) * math.rad(tilt))
		attach(rig, head, "HairSpike", V3(0.55, len, 0.55), cf * CF(0, len / 2, 0), col, mat or "SmoothPlastic")
	end
end
HAIR.spiky = function(rig, head, c)
	attach(rig, head, "HairCap", V3(2.15, 0.6, 1.15), CF(0, 0.45, 0), c)
	spikesOn(rig, head, c, 7, 1.1, 0.75, 35)
end
HAIR.mane = function(rig, head, c, spec)
	attach(rig, head, "HairCap", V3(2.3, 0.7, 1.3), CF(0, 0.45, 0), c)
	spikesOn(rig, head, c, 11, 1.4, 1.05, 60)
	spikesOn(rig, head, B.hex("#D8261E"), 6, 0.7, 1.2, 75)
end
HAIR.short = function(rig, head, c)
	attach(rig, head, "HairCap", V3(2.12, 0.55, 1.12), CF(0, 0.42, 0), c)
	attach(rig, head, "HairBack", V3(2.1, 0.8, 0.3), CF(0, 0.1, 0.45), c)
end
HAIR.long = function(rig, head, c)
	HAIR.short(rig, head, c)
	attach(rig, head, "HairLong", V3(2.1, 2.2, 0.35), CF(0, -0.6, 0.55), c)
end
HAIR.ponytail = function(rig, head, c)
	HAIR.short(rig, head, c)
	attach(rig, head, "Ponytail", V3(0.6, 1.8, 0.6), CF(0, 0.2, 0.9) * A(math.rad(-35), 0, 0), c)
	spikesOn(rig, head, c, 4, 0.8, 0.3, 20)
end
HAIR.wavy = function(rig, head, c)
	HAIR.short(rig, head, c)
	for _, x in { -0.95, 0.95 } do
		attach(rig, head, "Curl", V3(0.5, 1.4, 0.9), CF(x, -0.3, 0.1), c)
	end
end
HAIR.curly = function(rig, head, c)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		attach(rig, head, "Curl", V3(0.75, 0.75, 0.75), CF(math.sin(a) * 0.75, 0.55, math.cos(a) * 0.45), c, "SmoothPlastic", { shape = "Ball" })
	end
end
HAIR.split = function(rig, head, c, spec)
	attach(rig, head, "HairL", V3(1.08, 0.6, 1.14), CF(-0.53, 0.44, 0), c)
	attach(rig, head, "HairR", V3(1.08, 0.6, 1.14), CF(0.53, 0.44, 0), B.hex(spec.hair2 or "#C0292F"))
end
HAIR.antenna = function(rig, head, c)
	HAIR.short(rig, head, c)
	for _, s in { -1, 1 } do
		attach(rig, head, "Antenna", V3(0.35, 1.6, 0.35), CF(s * 0.35, 1.2, -0.3) * A(math.rad(-20), 0, math.rad(s * -28)), c)
	end
end
HAIR.flame = function(rig, head, c)
	attach(rig, head, "HairCap", V3(2.1, 0.5, 1.1), CF(0, 0.42, 0), c)
	attach(rig, head, "Flame", V3(1.3, 1.9, 0.9), CF(0, 1.35, 0.1) * A(math.rad(8), 0, 0), c)
	spikesOn(rig, head, c, 5, 1.2, 0.45, 18)
end
HAIR.wild = function(rig, head, c)
	attach(rig, head, "HairCap", V3(2.3, 0.7, 1.3), CF(0, 0.45, 0), c)
	spikesOn(rig, head, c, 9, 1.6, 0.9, 70)
	attach(rig, head, "HairBack", V3(2.2, 2.4, 0.5), CF(0, -0.5, 0.55), c)
end
HAIR.messy = function(rig, head, c)
	attach(rig, head, "HairCap", V3(2.2, 0.6, 1.2), CF(0, 0.45, 0), c)
	spikesOn(rig, head, c, 8, 0.7, 0.85, 95)
end
HAIR.tilted = function(rig, head, c)
	attach(rig, head, "HairTilt", V3(2.1, 1.6, 1.1), CF(0.45, 0.9, 0) * A(0, 0, math.rad(-35)), c)
end
HAIR.dome = function(rig, head, c)
	attach(rig, head, "Dome", V3(2.05, 1.1, 1.1), CF(0, 0.55, 0), c, "Glass", { shape = nil })
end
HAIR.slick = function(rig, head, c)
	attach(rig, head, "HairSlick", V3(2.12, 0.5, 1.25), CF(0, 0.45, 0.05), c)
	attach(rig, head, "Strand", V3(0.2, 0.9, 0.2), CF(0.3, 0.1, -0.55), c)
end
HAIR.spikebells = function(rig, head, c)
	HAIR.spiky(rig, head, c)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		attach(rig, head, "Bell", V3(0.3, 0.3, 0.3), CF(math.sin(a) * 0.9, 1.7, math.cos(a) * 0.5), B.hex("#FFD23F"), "Metal", { shape = "Ball" })
	end
end
HAIR.bald = function() end
HAIR.skullhelm = function(rig, head, c)
	attach(rig, head, "Helm", V3(2.2, 1.3, 1.25), CF(0, 0.1, 0), c, "Marble")
	for _, x in { -0.45, 0.45 } do
		attach(rig, head, "EyeSocket", V3(0.45, 0.35, 0.1), CF(x, 0.15, -0.63), B.hex("#111111"), "SmoothPlastic")
	end
end
HAIR.plume = function(rig, head, c)
	attach(rig, head, "Helm", V3(2.2, 1.2, 1.25), CF(0, 0.1, 0), B.hex("#1B1B22"), "Metal")
	attach(rig, head, "Plume", V3(0.4, 1.4, 1.6), CF(0, 1.1, 0.3), c)
	attach(rig, head, "Visor", V3(1.6, 0.18, 0.1), CF(0, 0.2, -0.63), B.hex("#FF3B30"), "Neon")
end
HAIR.insect = function(rig, head, c)
	attach(rig, head, "Carapace", V3(2.3, 1.4, 1.4), CF(0, 0.3, 0.1), c, "Glass")
	for _, s in { -1, 1 } do
		attach(rig, head, "Antenna", V3(0.18, 1.8, 0.18), CF(s * 0.5, 1.5, -0.3) * A(math.rad(-30), 0, math.rad(s * -20)), c)
		attach(rig, head, "Eye", V3(0.45, 0.3, 0.1), CF(s * 0.5, 0.25, -0.73), B.hex("#C77DFF"), "Neon")
	end
end
HAIR.topknot = function(rig, head, c)
	HAIR.short(rig, head, c)
	attach(rig, head, "Knot", V3(0.7, 0.7, 0.7), CF(0, 1.1, 0.2), c, "SmoothPlastic", { shape = "Ball" })
end

local PROPS = {}
PROPS.katana = function(rig, parts, spec)
	attach(rig, parts.Torso, "Katana", V3(0.2, 0.3, 3.4), CF(-1.1, -0.9, 0) * A(math.rad(20), 0, 0), B.hex("#DDE4EE"), "Metal")
	attach(rig, parts.Torso, "Tsuba", V3(0.5, 0.5, 0.12), CF(-1.1, -0.35, -1.2), B.hex("#1B1B1B"))
end
PROPS.greatsword = function(rig, parts)
	attach(rig, parts.Torso, "Dragonslayer", V3(0.3, 7, 1.2), CF(0.2, 1.2, 0.8) * A(0, 0, math.rad(20)), B.hex("#3A3A3A"), "Metal")
end
PROPS.sword = PROPS.katana
PROPS.zangetsu = function(rig, parts)
	attach(rig, parts.Torso, "Zangetsu", V3(0.2, 5, 1.1), CF(0.4, 0.8, 0.8) * A(0, 0, math.rad(25)), B.hex("#1B1B1B"), "Metal")
	attach(rig, parts.Torso, "Edge", V3(0.22, 5, 0.18), CF(0.4, 0.8, 0.25) * A(0, 0, math.rad(25)), B.hex("#E8E8EE"), "Metal")
end
PROPS.staff = function(rig, parts)
	attach(rig, parts["Right Arm"], "Staff", V3(0.25, 5, 0.25), CF(0, -1, -0.6), B.hex("#6B4A2A"), "Wood")
end
PROPS.gauntlets = function(rig, parts, spec)
	for _, n in { "Left Arm", "Right Arm" } do
		attach(rig, parts[n], "Gauntlet", V3(1.35, 1, 1.35), CF(0, -0.55, 0), B.hex(spec.accent or "#FF7A1A"), "Metal")
	end
end

local function hatOn(rig, head, kind)
	if kind == "straw" then
		attach(rig, head, "Brim", V3(0.2, 3.2, 3.2), CF(0, 0.75, 0) * A(0, 0, math.rad(90)), B.hex("#E8C66A"), "Fabric", { shape = "Cylinder" })
		attach(rig, head, "Crown", V3(1.4, 1.8, 1.8), CF(0, 1.1, 0) * A(0, 0, math.rad(90)), B.hex("#E8C66A"), "Fabric", { shape = "Cylinder" })
		attach(rig, head, "Band", V3(0.35, 1.85, 1.85), CF(0, 0.95, 0) * A(0, 0, math.rad(90)), B.hex("#D8261E"), "Fabric", { shape = "Cylinder" })
	elseif kind == "fedora" then
		attach(rig, head, "Brim", V3(0.18, 3, 3), CF(0, 0.7, 0) * A(0, 0, math.rad(90)), B.hex("#F4F4F4"), "Fabric", { shape = "Cylinder" })
		attach(rig, head, "Crown", V3(1.2, 1.9, 1.9), CF(0, 1.2, 0) * A(0, 0, math.rad(90)), B.hex("#F4F4F4"), "Fabric", { shape = "Cylinder" })
		attach(rig, head, "Band", V3(0.3, 1.95, 1.95), CF(0, 0.95, 0) * A(0, 0, math.rad(90)), B.hex("#16131F"), "Fabric", { shape = "Cylinder" })
	end
end

-- Builds a stand-in rig. Returns Model with Humanoid, HumanoidRootPart, R6 joints.
function Rigs.standIn(charId, name, spec)
	local rig = R.Instance.new("Model")
	rig.Name = charId
	local origin = CF(0, 3, 0)
	local parts = {}
	for pname, def in R6 do
		local col = (pname == "Head") and spec.skin or ((pname:find("Arm") or pname == "Torso") and spec.top or spec.bottom)
		if pname:find("Arm") and spec.armor then
			col = spec.armor
		end
		local p = B.part(rig, pname, def[1], origin * CF(def[2]), col, "SmoothPlastic")
		p.Anchored = false
		p.CanCollide = pname == "Torso" or pname == "Head"
		parts[pname] = p
	end
	parts["Left Arm"].Color = B.hex(spec.top) -- sleeves
	if spec.skin and not spec.armor then
		-- hands in skin colour
		for _, n in { "Left Arm", "Right Arm" } do
			attach(rig, parts[n], "Hand", V3(1.02, 0.45, 1.02), CF(0, -0.8, 0), spec.skin)
		end
	end
	local headMesh = R.Instance.new("SpecialMesh")
	headMesh.MeshType = R.Enum.MeshType.Head
	headMesh.Scale = V3(1.25, 1.25, 1.25)
	headMesh.Parent = parts.Head
	local face = R.Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = R.Enum.NormalId.Front
	face.Parent = parts.Head
	local hrp = B.part(rig, "HumanoidRootPart", V3(2, 2, 1), origin, "#FFFFFF", "SmoothPlastic", { transparency = 1 })
	hrp.Anchored = false
	hrp.CanCollide = false
	local r90, rn90 = A(0, math.rad(90), 0), A(0, math.rad(-90), 0)
	local neckRot = A(math.rad(-90), 0, math.rad(180))
	motor(hrp, "RootJoint", hrp, parts.Torso, neckRot, neckRot)
	motor(parts.Torso, "Neck", parts.Torso, parts.Head, CF(0, 1, 0) * neckRot, CF(0, -0.5, 0) * neckRot)
	motor(parts.Torso, "Right Shoulder", parts.Torso, parts["Right Arm"], CF(1, 0.5, 0) * r90, CF(-0.5, 0.5, 0) * r90)
	motor(parts.Torso, "Left Shoulder", parts.Torso, parts["Left Arm"], CF(-1, 0.5, 0) * rn90, CF(0.5, 0.5, 0) * rn90)
	motor(parts.Torso, "Right Hip", parts.Torso, parts["Right Leg"], CF(1, -1, 0) * r90, CF(0.5, 1, 0) * r90)
	motor(parts.Torso, "Left Hip", parts.Torso, parts["Left Leg"], CF(-1, -1, 0) * rn90, CF(-0.5, 1, 0) * rn90)
	local hum = R.Instance.new("Humanoid")
	hum.DisplayName = name
	hum.RigType = R.Enum.HumanoidRigType.R6
	hum.Parent = rig
	local animator = R.Instance.new("Animator")
	animator.Parent = hum
	rig.PrimaryPart = hrp
	-- identity
	local hairFn = HAIR[spec.hairStyle] or HAIR.short
	hairFn(rig, parts.Head, B.hex(spec.hair), spec)
	if spec.hat then
		hatOn(rig, parts.Head, spec.hat)
	end
	if spec.horns then
		for _, s in { -1, 1 } do
			local base = parts.Head.CFrame * CF(s * 0.7, 0.8, 0) * A(0, 0, math.rad(s * -25))
			for i = 0, 2 do
				local p = B.part(rig, "Horn", V3(0.5 - i * 0.12, 0.6, 0.5 - i * 0.12), base * CF(0, 0.3 + i * 0.5, 0), spec.horns, "Marble")
				p.Anchored, p.CanCollide, p.Massless = false, false, true
				B.rigidWeld(parts.Head, p)
			end
		end
	end
	if spec.cape or spec.cloak or spec.haori or spec.coat then
		local col = spec.cape or spec.cloak or spec.haori or spec.coat
		attach(rig, parts.Torso, "Cape", V3(2.3, 3.6, 0.15), CF(0, -0.6, 0.62), col, "Fabric")
		if spec.clouds then
			for i = 1, 3 do
				attach(rig, parts.Torso, "Cloud", V3(0.7, 0.45, 0.05), CF(-0.6 + (i - 1) * 0.6, -0.8 + i * 0.35, 0.72), spec.clouds, "SmoothPlastic")
			end
		end
	end
	if spec.pattern == "checker" then
		for ix = 0, 3 do
			for iy = 0, 3 do
				if (ix + iy) % 2 == 0 then
					attach(rig, parts.Torso, "Check", V3(0.5, 0.5, 0.06), CF(-0.75 + ix * 0.5, -0.75 + iy * 0.5, -0.53), B.hex("#16223A"))
				end
			end
		end
	end
	if spec.belt or spec.sash then
		attach(rig, parts.Torso, "Belt", V3(2.05, 0.35, 1.05), CF(0, -0.85, 0), spec.belt or spec.sash)
	end
	if spec.tattoo or spec.markings then
		for i = 1, 3 do
			attach(rig, parts.Torso, "Mark", V3(1.8, 0.1, 0.04), CF(0, 0.6 - i * 0.4, -0.52), spec.tattoo or spec.markings, "Neon")
		end
	end
	if spec.mask then
		attach(rig, parts.Head, "Mask", V3(1.9, 0.5, 0.08), CF(0, -0.25, -0.62), B.hex("#1F2A4A"))
	end
	if spec.blindfold then
		attach(rig, parts.Head, "Blindfold", V3(2.08, 0.35, 1.08), CF(0, 0.15, 0), spec.blindfold)
	end
	if spec.shades then
		attach(rig, parts.Head, "Shades", V3(1.6, 0.3, 0.08), CF(0, 0.15, -0.62), B.hex("#FF6FB5"), "Glass")
	end
	if spec.eyes then
		for _, x in { -0.35, 0.35 } do
			attach(rig, parts.Head, "GlowEye", V3(0.28, 0.14, 0.05), CF(x, 0.15, -0.61), spec.eyes, "Neon")
		end
	end
	if spec.wheel then
		local center = parts.Head.CFrame * CF(0, 1.9, 0)
		for i = 1, 8 do
			local a = i / 8 * math.pi * 2
			local p = B.part(rig, "WheelSpoke", V3(0.18, 1.6, 0.18), center * A(0, 0, a) * CF(0, 0.8, 0), spec.wheel, "Metal")
			p.Anchored, p.CanCollide, p.Massless = false, false, true
			B.rigidWeld(parts.Head, p)
		end
	end
	if spec.tail then
		attach(rig, parts.Torso, "Tail", V3(0.4, 0.4, 3.2), CF(0, -1.2, 1.8) * A(math.rad(-25), 0, 0), spec.top)
	end
	if spec.helm == "hawk" then
		attach(rig, parts.Head, "HawkHelm", V3(2.2, 1.25, 1.25), CF(0, 0.15, 0), B.hex("#1B1B2A"), "Metal")
		attach(rig, parts.Head, "Beak", V3(0.4, 0.9, 0.6), CF(0, 0.2, -0.85) * A(math.rad(-30), 0, 0), B.hex("#1B1B2A"), "Metal")
	end
	if spec.restraint then
		for i = 1, 3 do
			attach(rig, parts.Torso, "Restraint", V3(2.2, 0.3, 1.2), CF(0, 0.9 - i * 0.6, 0), spec.restraint, "Fabric")
		end
	end
	if spec.hood then
		attach(rig, parts.Torso, "Hood", V3(2.1, 0.5, 1.1), CF(0, 1.05, 0.2), spec.hood)
	end
	if spec.beard then
		attach(rig, parts.Head, "Beard", V3(1.2, 1.4, 0.4), CF(0, -0.9, -0.45), spec.beard)
	end
	if spec.prop and PROPS[spec.prop] then
		PROPS[spec.prop](rig, parts, spec)
	end
	rig:SetAttribute("StandIn", true)
	rig:SetAttribute("CharacterId", charId)
	return rig
end

-- anchored, humanoid-free copy for UI viewports (cheap; no physics)
function Rigs.previewCopy(rig)
	local copy = rig:Clone()
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	return copy
end

return Rigs
