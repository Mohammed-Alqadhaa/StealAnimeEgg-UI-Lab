--!nocheck
--[[
	B — builder primitives for the Lune assembler (bakes geometry into the place).

	Lune note: BasePart.Position is not available in Lune's DOM — always CFrame.
	Every created part is Anchored, smooth-surfaced and CastShadow-tuned; collision is
	explicit (collide=false for decoration keeps the centre lane clean for gameplay).
]]
local R = require("@lune/roblox")

local B = {}
B.R = R
B.Enum = R.Enum
local V3, CF = R.Vector3.new, R.CFrame.new
B.V3, B.CF = V3, CF
B.Angles = R.CFrame.Angles
B.lookAt = R.CFrame.lookAt

function B.hex(h: string)
	h = h:gsub("#", "")
	return R.Color3.fromRGB(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16))
end
B.rgb = R.Color3.fromRGB

local function color(c)
	if type(c) == "string" then
		return B.hex(c)
	end
	return c or R.Color3.fromRGB(200, 200, 200)
end
B.color = color

local MAT = {}
for _, m in R.Enum.Material:GetEnumItems() do
	MAT[m.Name] = m
end
B.MAT = MAT

B.stats = { parts = 0 }

function B.folder(parent, name)
	local f = R.Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function B.model(parent, name)
	local m = R.Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- generic part. opts: collide, transparency, shape ("Ball"/"Cylinder"), class, reflect, cast, attrs
function B.part(parent, name, size, cframe, col, mat, opts)
	opts = opts or {}
	local p = R.Instance.new(opts.class or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color(col)
	p.Material = MAT[mat or "SmoothPlastic"] or MAT.SmoothPlastic
	p.Anchored = opts.anchored ~= false
	p.CanCollide = opts.collide == true
	p.CanTouch = opts.touch == true
	p.CanQuery = opts.query ~= false and (opts.collide == true or opts.query == true)
	p.CastShadow = opts.cast ~= false
	if opts.class == nil or opts.class == "Part" then
		p.TopSurface = R.Enum.SurfaceType.Smooth
		p.BottomSurface = R.Enum.SurfaceType.Smooth
		if opts.shape then
			p.Shape = R.Enum.PartType[opts.shape]
		end
	end
	if opts.transparency then
		p.Transparency = opts.transparency
	end
	if opts.reflect then
		p.Reflectance = opts.reflect
	end
	if opts.attrs then
		for k, v in opts.attrs do
			p:SetAttribute(k, v)
		end
	end
	p.Parent = parent
	B.stats.parts += 1
	return p
end

-- axis-aligned box by centre + size (studs) — the workhorse
function B.box(parent, name, sx, sy, sz, x, y, z, col, mat, opts)
	return B.part(parent, name, V3(sx, sy, sz), CF(x, y, z), col, mat, opts)
end

-- box rotated about Y (degrees) and optional X/Z tilt
function B.rbox(parent, name, sx, sy, sz, x, y, z, ry, col, mat, opts, rx, rz)
	return B.part(parent, name, V3(sx, sy, sz), CF(x, y, z) * B.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0)), col, mat, opts)
end

-- vertical cylinder (axis Y) centred at x,y,z
function B.cyl(parent, name, diameter, height, x, y, z, col, mat, opts)
	opts = opts or {}
	opts.shape = "Cylinder"
	return B.part(parent, name, V3(height, diameter, diameter), CF(x, y, z) * B.Angles(0, 0, math.rad(90)), col, mat, opts)
end

-- cylinder along an arbitrary CFrame's X axis
function B.cylCF(parent, name, diameter, length, cframe, col, mat, opts)
	opts = opts or {}
	opts.shape = "Cylinder"
	return B.part(parent, name, V3(length, diameter, diameter), cframe, col, mat, opts)
end

function B.ball(parent, name, d, x, y, z, col, mat, opts)
	opts = opts or {}
	opts.shape = "Ball"
	return B.part(parent, name, V3(d, d, d), CF(x, y, z), col, mat, opts)
end

-- ellipsoid via SpecialMesh(Sphere) on a block
function B.ellipsoid(parent, name, sx, sy, sz, cframe, col, mat, opts)
	local p = B.part(parent, name, V3(sx, sy, sz), cframe, col, mat, opts)
	local m = R.Instance.new("SpecialMesh")
	m.MeshType = R.Enum.MeshType.Sphere
	m.Parent = p
	return p
end

function B.wedge(parent, name, sx, sy, sz, cframe, col, mat, opts)
	opts = opts or {}
	opts.class = "WedgePart"
	return B.part(parent, name, V3(sx, sy, sz), cframe, col, mat, opts)
end

-- tapered spike built from shrinking cylinders along cframe's up axis
function B.spike(parent, name, baseD, length, cframe, col, mat, steps)
	steps = steps or 4
	local seg = length / steps
	for i = 0, steps - 1 do
		local d = baseD * (1 - i / steps) + 0.05
		B.part(parent, name, V3(seg * 1.05, d, d), cframe * CF(0, seg * (i + 0.5), 0) * B.Angles(0, 0, math.rad(90)), col, mat, { shape = "Cylinder" })
	end
end

-- flat ring of segments (torus approximation) in the plane of cframe's XZ
function B.ring(parent, name, cframe, radius, thickness, segments, col, mat, opts)
	segments = segments or 24
	local out = {}
	for i = 1, segments do
		local a = (i - 1) / segments * math.pi * 2
		local b = i / segments * math.pi * 2
		local pa = cframe * V3(math.sin(a) * radius, 0, math.cos(a) * radius)
		local pb = cframe * V3(math.sin(b) * radius, 0, math.cos(b) * radius)
		local mid = (pa + pb) / 2
		local len = (pb - pa).Magnitude + thickness * 0.3
		local up = cframe.UpVector
		table.insert(out, B.part(parent, name, V3(thickness, thickness, len), R.CFrame.lookAt(mid, pb, up), col, mat, opts))
	end
	return out
end

-- a segment (beam-like part) between two points
function B.segment(parent, name, a, b, thickness, col, mat, opts)
	local len = (b - a).Magnitude
	return B.part(parent, name, V3(thickness, thickness, len), R.CFrame.lookAt((a + b) / 2, b), col, mat, opts)
end

function B.light(parent, col, range, brightness, kind)
	local l = R.Instance.new(kind or "PointLight")
	l.Color = color(col)
	l.Range = range or 16
	l.Brightness = brightness or 1
	l.Shadows = false
	l.Parent = parent
	return l
end

B.TEX = {
	sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
}

function B.cseq(colors)
	local kps = {}
	for i, c in colors do
		table.insert(kps, R.ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), color(c)))
	end
	if #kps == 1 then
		table.insert(kps, R.ColorSequenceKeypoint.new(1, kps[1].Value))
	end
	return R.ColorSequence.new(kps)
end

function B.nseq(points)
	if type(points) == "number" then
		return R.NumberSequence.new(points)
	end
	local kps = {}
	for _, p in points do
		table.insert(kps, R.NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return R.NumberSequence.new(kps)
end

-- particle emitter with sensible defaults. o: colors, rate, life{a,b}, speed{a,b}, size, transp, tex, spread, light, dir, accel
function B.emitter(parent, name, o)
	local e = R.Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = B.TEX[o.tex or "sparkle"] or o.tex
	e.Color = B.cseq(o.colors or { "#FFFFFF" })
	e.Rate = o.rate or 5
	e.Lifetime = R.NumberRange.new(o.life and o.life[1] or 1, o.life and o.life[2] or 2)
	e.Speed = R.NumberRange.new(o.speed and o.speed[1] or 0.5, o.speed and o.speed[2] or 1.5)
	e.SpreadAngle = R.Vector2.new(o.spread or 180, o.spread or 180)
	e.Size = B.nseq(o.size or { { 0, 0.4 }, { 0.6, 0.7 }, { 1, 0 } })
	e.Transparency = B.nseq(o.transp or { { 0, 0.2 }, { 1, 1 } })
	e.LightEmission = o.light or 0.6
	e.EmissionDirection = R.Enum.NormalId[o.dir or "Top"]
	if o.accel then
		e.Acceleration = o.accel
	end
	if o.rot then
		e.RotSpeed = R.NumberRange.new(-o.rot, o.rot)
		e.Rotation = R.NumberRange.new(0, 360)
	end
	e.Parent = parent
	return e
end

function B.fire(parent, colors, size, rate)
	return B.emitter(parent, "Flames", { tex = "fire", colors = colors or { "#FFD23F", "#FF4D1A" }, rate = rate or 18, life = { 0.4, 0.9 }, speed = { 1, 3 }, spread = 20, size = { { 0, size or 1.5 }, { 1, 0.2 } }, transp = { { 0, 0.15 }, { 1, 1 } }, light = 0.8 })
end

-- SurfaceGui text on a part face. o: face, color, stroke, font, ppstud, bg
function B.surfaceText(part, text, o)
	o = o or {}
	local g = R.Instance.new("SurfaceGui")
	g.Name = o.name or "Sign"
	g.Face = R.Enum.NormalId[o.face or "Front"]
	g.SizingMode = R.Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = o.ppstud or 40
	g.LightInfluence = o.lightInfluence or 0
	g.Brightness = o.brightness or 1.5
	g.Parent = part
	local l = R.Instance.new("TextLabel")
	l.Name = o.labelName or "Text"
	l.BackgroundTransparency = o.bg and 0 or 1
	if o.bg then
		l.BackgroundColor3 = color(o.bg)
	end
	l.Size = R.UDim2.fromScale(1, 1)
	l.Text = text
	l.TextScaled = true
	l.Font = R.Enum.Font[o.font or "FredokaOne"]
	l.TextColor3 = color(o.color or "#FFFFFF")
	l.TextStrokeTransparency = o.stroke == false and 1 or 0
	l.TextStrokeColor3 = color(o.strokeColor or "#1B1036")
	l.Parent = g
	return g, l
end

function B.billboard(part, text, o)
	o = o or {}
	local g = R.Instance.new("BillboardGui")
	g.Name = o.name or "Label"
	g.Size = R.UDim2.fromOffset(o.w or 220, o.h or 50)
	g.StudsOffset = o.offset or V3(0, 3, 0)
	g.MaxDistance = o.maxDistance or 80
	g.AlwaysOnTop = o.onTop == true
	g.LightInfluence = 0
	g.Parent = part
	local l = R.Instance.new("TextLabel")
	l.Name = "Text"
	l.BackgroundTransparency = 1
	l.Size = R.UDim2.fromScale(1, 1)
	l.Text = text
	l.TextScaled = true
	l.Font = R.Enum.Font[o.font or "LuckiestGuy"]
	l.TextColor3 = color(o.color or "#FFFFFF")
	l.TextStrokeTransparency = 0
	l.TextStrokeColor3 = color("#1B1036")
	l.Parent = g
	return g, l
end

function B.weld(a, b)
	local w = R.Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
	return w
end

-- rigid weld with offsets (for unanchored rigs)
function B.rigidWeld(part0, part1)
	local w = R.Instance.new("Weld")
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = part0.CFrame:Inverse() * part1.CFrame
	w.Parent = part1
	return w
end

-- positions of all BaseParts in a subtree (Lune: CFrame.Position)
function B.bounds(root)
	local minV, maxV = V3(math.huge, math.huge, math.huge), V3(-math.huge, -math.huge, -math.huge)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			local p, s = d.CFrame.Position, d.Size / 2
			minV = V3(math.min(minV.X, p.X - s.X), math.min(minV.Y, p.Y - s.Y), math.min(minV.Z, p.Z - s.Z))
			maxV = V3(math.max(maxV.X, p.X + s.X), math.max(maxV.Y, p.Y + s.Y), math.max(maxV.Z, p.Z + s.Z))
		end
	end
	return minV, maxV
end

-- move every BasePart in a subtree by delta (Lune has no PivotTo)
function B.translate(root, delta)
	if root:IsA("BasePart") then
		root.CFrame = root.CFrame + delta
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame = d.CFrame + delta
		end
	end
end

-- rotate+translate a subtree about pivot by cframe transform
function B.transform(root, fromPivot, toPivot)
	local rel = toPivot * fromPivot:Inverse()
	local function apply(p)
		p.CFrame = rel * p.CFrame
	end
	if root:IsA("BasePart") then
		apply(root)
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			apply(d)
		end
	end
end

-- deterministic RNG for reproducible builds
function B.rng(seed)
	local s = seed or 12345
	return function(a, b)
		s = (s * 1103515245 + 12345) % 2147483648
		local t = s / 2147483648
		if a == nil then
			return t
		end
		return a + (b - a) * t
	end
end

return B
