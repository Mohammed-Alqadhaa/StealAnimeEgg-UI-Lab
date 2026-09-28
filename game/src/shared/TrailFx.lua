--[[
	TrailFx — builds the movement trail + aura for a trail tier (§96, video V01).

	Shared by the server (applies it to the character so everyone sees it) and the client
	(Trail Shop live previews). Built from native Trail / ParticleEmitter / Beam instances
	and built-in particle textures only (no uploads needed).

	V01 behaviour reproduced:
	  * ribbon emitted low (hip → heel), lying FLAT: two attachments side by side at
	    ground height → the Trail sheet is horizontal and hugs the ground;
	  * narrow at the emitter, WIDENING with age (WidthScale 0.25 → 1);
	  * long persistence (Lifetime per tier), gradient colour along its length,
	    solid near the player and fading at the tail;
	  * ribbon + aura only while moving (TrailFxClient toggles by velocity) and aura
	    intensity scales with speed.
	Tier families add layers: wisps → streaks → embers → lightning arcs → stars →
	shadow flames + rings → halo + colour cycling → layered prismatic.
]]

local TrailFx = {}

local TEX = {
	sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
}

local function hex(h: string): Color3
	return Color3.fromHex(h)
end

local function gradient(colors: { string }): ColorSequence
	local kps = {}
	for i, c in colors do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), hex(c)))
	end
	if #kps == 1 then
		table.insert(kps, ColorSequenceKeypoint.new(1, kps[1].Value))
	end
	return ColorSequence.new(kps)
end

local function emitter(parent: Instance, name: string, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.LightEmission = 0.7
	e.LockedToPart = false
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

-- Remove any previously applied trail from a character.
function TrailFx.clear(char: Model)
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		local old = root:FindFirstChild("SAE_TrailFx")
		if old then
			old:Destroy()
		end
	end
end

-- Apply `tier` (Trails.TIERS entry) to a character (R6 or R15). Returns the fx folder.
function TrailFx.apply(char: Model, tier): Folder?
	TrailFx.clear(char)
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not tier then
		return nil
	end
	local folder = Instance.new("Folder")
	folder.Name = "SAE_TrailFx"
	folder:SetAttribute("TrailId", tier.id)
	folder:SetAttribute("Family", tier.family)
	folder:SetAttribute("Cycle", tier.cycle == true)
	folder.Parent = root
	local lowY = -(root.Size.Y / 2) - 2.2 -- near the feet
	local half = tier.width / 2
	local function att(name: string, pos: Vector3): Attachment
		local a = Instance.new("Attachment")
		a.Name = name
		a.Position = pos
		a.Parent = root
		a:SetAttribute("SAE_TrailFx", true)
		return a
	end
	local a0 = att("TrailL", Vector3.new(-half, lowY, 0.6))
	local a1 = att("TrailR", Vector3.new(half, lowY, 0.6))
	local main = Instance.new("Trail")
	main.Name = "Ribbon"
	main.Attachment0 = a0
	main.Attachment1 = a1
	main.Lifetime = tier.life
	main.MinLength = 0.1
	main.FaceCamera = false -- flat ribbon along the ground, like the reference
	main.LightEmission = 0.65
	main.LightInfluence = 0.2
	main.Color = gradient(tier.colors)
	main.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.7, 0.35), NumberSequenceKeypoint.new(1, 1) })
	main.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(0.35, 0.8), NumberSequenceKeypoint.new(1, 1) })
	main.Parent = folder
	if tier.layered then
		-- second, thinner raised ribbon for the top tier (a glowing core line)
		local b0 = att("CoreL", Vector3.new(-half * 0.25, lowY + 0.35, 0.6))
		local b1 = att("CoreR", Vector3.new(half * 0.25, lowY + 0.35, 0.6))
		local core = main:Clone()
		core.Name = "CoreRibbon"
		core.Attachment0 = b0
		core.Attachment1 = b1
		core.Lifetime = tier.life * 0.7
		core.Color = ColorSequence.new(Color3.new(1, 1, 1))
		core.LightEmission = 1
		core.Parent = folder
	end
	-- aura layers (all start disabled; TrailFxClient enables while moving)
	local aura = att("Aura", Vector3.new(0, -0.6, 0))
	local cs = gradient(tier.colors)
	local fam = tier.aura
	if fam == "wisp" or fam == "streaks" then
		emitter(aura, "Wisps", { Texture = TEX.smoke, Color = cs, Rate = fam == "wisp" and 8 or 16, Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(25, 25), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.6) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }), EmissionDirection = Enum.NormalId.Back, Enabled = false })
	end
	if fam == "streaks" or fam == "embers" or fam == "sparks" then
		emitter(aura, "Streaks", { Texture = TEX.sparkle, Color = cs, Rate = 24, Lifetime = NumberRange.new(0.25, 0.5), Speed = NumberRange.new(10, 18), SpreadAngle = Vector2.new(10, 10), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }), EmissionDirection = Enum.NormalId.Back, Enabled = false })
	end
	if fam == "embers" or fam == "shadowflame" then
		emitter(aura, "Flames", { Texture = TEX.fire, Color = cs, Rate = 30, Lifetime = NumberRange.new(0.3, 0.7), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(35, 35), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0.2) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }), EmissionDirection = Enum.NormalId.Top, Enabled = false })
	end
	if fam == "sparks" or tier.arcs then
		emitter(aura, "Sparks", { Texture = TEX.sparkle, Color = ColorSequence.new(Color3.new(1, 1, 1)), Rate = 40, Lifetime = NumberRange.new(0.1, 0.25), Speed = NumberRange.new(6, 14), SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new(0.35), LightEmission = 1, Enabled = false })
		-- flickering lightning beams around the legs (toggled/wiggled by the client)
		for i = 1, 2 do
			local s0 = att("Arc" .. i .. "A", Vector3.new(i == 1 and -1.2 or 1.2, lowY + 0.3, -0.4))
			local s1 = att("Arc" .. i .. "B", Vector3.new(i == 1 and -0.3 or 0.3, 0.2, 0.3))
			local beam = Instance.new("Beam")
			beam.Name = "Arc" .. i
			beam.Attachment0 = s0
			beam.Attachment1 = s1
			beam.Color = cs
			beam.Width0 = 0.25
			beam.Width1 = 0.05
			beam.LightEmission = 1
			beam.FaceCamera = true
			beam.Segments = 8
			beam.CurveSize0 = 1.5
			beam.CurveSize1 = -1.5
			beam.Enabled = false
			beam.Parent = folder
		end
	end
	if fam == "stars" or fam == "monarch" or fam == "prismatic" or fam == "halo" then
		emitter(aura, "Stars", { Texture = TEX.sparkle, Color = cs, Rate = fam == "stars" and 20 or 32, Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0) }), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-90, 90), Enabled = false })
	end
	if fam == "shadowflame" or fam == "monarch" then
		emitter(aura, "Shadow", { Texture = TEX.smoke, Color = ColorSequence.new(Color3.fromRGB(10, 6, 24), hex(tier.colors[1])), LightEmission = 0.2, Rate = 26, Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(40, 40), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 3) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }), EmissionDirection = Enum.NormalId.Top, Enabled = false })
	end
	if tier.rings then
		emitter(aura, "Rings", { Texture = TEX.sparkle, Shape = Enum.ParticleEmitterShape.Disc, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Color = cs, Rate = 18, Lifetime = NumberRange.new(0.4, 0.6), Speed = NumberRange.new(4, 6), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }), Enabled = false })
	end
	if fam == "halo" or fam == "prismatic" or fam == "monarch" then
		local light = Instance.new("PointLight")
		light.Name = "AuraLight"
		light.Color = hex(tier.colors[1])
		light.Range = 10
		light.Brightness = 1.2
		light.Enabled = false
		light.Parent = aura
	end
	return folder
end

return TrailFx
