--!strict
--[[
	FxClient — local visual effects (no gameplay).
	  * Trails (§96, video V01): ribbon/aura on EVERY character only while moving;
	    aura rate scales with speed; lightning arcs flicker; `Cycle` tiers shift the
	    ribbon gradient over time (the V01 colour cycling).
	  * Treadmill (§88): SpinRing models rotate, belt stripes scroll while the belt
	    runs, Pulse parts breathe. Only farms near the camera are animated.
	  * Demon Slayer zone (carried over from the approved AkazaZoneVFX): river flow
	    textures scroll, compass inlay pulses, beams/spray/lights only while inside.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Layout = require(Shared:WaitForChild("Layout"))

local player = Players.LocalPlayer

local Fx = {}

---------------------------------------------------------------------- trails
local function trailTick(t: number)
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local folder = root and root:FindFirstChild("SAE_TrailFx")
		if root and folder then
			local v = root.AssemblyLinearVelocity
			local speed = Vector3.new(v.X, 0, v.Z).Magnitude
			local moving = speed > 3
			local intensity = math.clamp(speed / 60, 0.25, 1.5)
			for _, fx in folder:GetChildren() do
				if fx:IsA("Trail") then
					fx.Enabled = moving
					if folder:GetAttribute("Cycle") == true then
						-- hue-shift the ribbon gradient over time (V01 colour cycling)
						local kps = {}
						for i = 0, 3 do
							local h = (t * 0.12 + i * 0.18) % 1
							table.insert(kps, ColorSequenceKeypoint.new(i / 3, Color3.fromHSV(h, fx.Name == "CoreRibbon" and 0.15 or 0.65, 1)))
						end
						fx.Color = ColorSequence.new(kps)
					end
				elseif fx:IsA("Beam") then
					fx.Enabled = moving and math.random() < 0.6
					fx.CurveSize0 = math.random(-20, 20) / 10
					fx.CurveSize1 = math.random(-20, 20) / 10
				end
			end
			local aura = root:FindFirstChild("Aura")
			if aura then
				for _, e in aura:GetChildren() do
					if e:IsA("ParticleEmitter") then
						e.Enabled = moving
						local baseRate = e:GetAttribute("BaseRate")
						if not baseRate then
							baseRate = e.Rate
							e:SetAttribute("BaseRate", baseRate)
						end
						e.Rate = (baseRate :: number) * intensity
					elseif e:IsA("Light") then
						e.Enabled = moving
					end
				end
			end
		end
	end
end

------------------------------------------------------------------- treadmill
type TM = {
	model: Model,
	belt: BasePart?,
	rings: { { parts: { BasePart }, base: { CFrame }, center: Vector3, speed: number } },
	stripes: { { part: BasePart, base: CFrame } },
	pulses: { { part: BasePart, base: number } },
	beltLen: number,
}
local treadmills: { TM } = {}

local function collectTreadmill(model: Model)
	local tm: TM = { model = model, belt = model:FindFirstChild("Belt") :: BasePart?, rings = {}, stripes = {}, pulses = {}, beltLen = 12 }
	if tm.belt then
		tm.beltLen = tm.belt.Size.Z
	end
	for _, d in model:GetDescendants() do
		if d:IsA("Model") and typeof(d:GetAttribute("Spin")) == "number" then
			local parts, base = {}, {}
			for _, p in d:GetDescendants() do
				if p:IsA("BasePart") then
					table.insert(parts, p)
					table.insert(base, p.CFrame)
				end
			end
			local c = d:GetAttribute("SpinCenter")
			table.insert(
				tm.rings,
				{ parts = parts, base = base, center = typeof(c) == "Vector3" and c or d:GetPivot().Position, speed = d:GetAttribute("Spin") :: number }
			)
		elseif d:IsA("BasePart") then
			if d:GetAttribute("BeltStripe") ~= nil then
				table.insert(tm.stripes, { part = d, base = d.CFrame })
			end
			if d:GetAttribute("Pulse") == true then
				table.insert(tm.pulses, { part = d, base = d.Transparency })
			end
		end
	end
	table.insert(treadmills, tm)
end

local function treadmillTick(t: number, camPos: Vector3)
	for _, tm in treadmills do
		if tm.model.Parent and (tm.model:GetPivot().Position - camPos).Magnitude < 160 then
			local level = tm.model:GetAttribute("Level") or 1
			for _, r in tm.rings do
				if r.parts[1] and r.parts[1].Transparency < 1 then
					local rot = CFrame.new(r.center) * CFrame.Angles(0, math.rad(t * r.speed), 0) * CFrame.new(-r.center)
					for i, p in r.parts do
						p.CFrame = rot * r.base[i]
					end
				end
			end
			if tm.belt then
				-- stripes travel with the belt surface (belt velocity is -LookVector)
				local axis = tm.belt.CFrame.LookVector
				local span = math.max(2, tm.beltLen - 2)
				local speed = 6 + level
				for _, st in tm.stripes do
					local rel = (st.base.Position - tm.belt.Position):Dot(axis)
					local moved = ((rel + span / 2 - t * speed) % span) - span / 2
					st.part.CFrame = st.base + axis * (moved - rel)
				end
			end
			for _, pu in tm.pulses do
				if pu.part.Transparency < 1 or pu.base < 1 then
					pu.part.Transparency = math.clamp(pu.base + 0.25 * (0.5 + 0.5 * math.sin(t * 3)), 0, 0.95)
				end
			end
		end
	end
end

------------------------------------------------------------ demon slayer zone
local ds = {
	flows = {} :: { Texture },
	beams = {} :: { Beam },
	spray = {} :: { ParticleEmitter },
	lights = {} :: { PointLight },
	glows = {} :: { BasePart },
	active = nil :: boolean?,
}
local function collectDemonSlayer(env: Instance)
	for _, o in env:GetDescendants() do
		if o:IsA("Texture") and o.Name == "AnimatedRiverFlow" then
			table.insert(ds.flows, o)
		elseif o:IsA("Beam") then
			table.insert(ds.beams, o)
		elseif o:IsA("ParticleEmitter") then
			table.insert(ds.spray, o)
		elseif o:IsA("PointLight") then
			table.insert(ds.lights, o)
		elseif o:IsA("MeshPart") and o:GetAttribute("BlenderMaterial") == "Compass luminous inlay" then
			table.insert(ds.glows, o)
		end
	end
end
local function dsTick(t: number, root: BasePart?)
	local active = false
	if root then
		active = Layout.worldAt(root.Position.X, root.Position.Z) == "DemonSlayer"
	end
	if active ~= ds.active then
		ds.active = active
		for _, b in ds.beams do
			b.Enabled = active
		end
		for _, p in ds.spray do
			p.Enabled = active
		end
	end
	for i, l in ds.lights do
		local parent = l.Parent :: BasePart
		local near = active and root ~= nil and parent:IsA("BasePart") and (root.Position - parent.Position).Magnitude < 100
		l.Enabled = near == true
		if l.Name == "LanternWarmLight" then
			l.Brightness = 1.25 + math.sin(t * 2.1 + i) * 0.08
		end
	end
	if not active then
		return
	end
	for _, tx in ds.flows do
		tx.OffsetStudsV = t * 5 % 140
	end
	for _, p in ds.glows do
		p.Transparency = 0.08 + 0.1 * (0.5 + 0.5 * math.sin(t * 2.4))
	end
end

function Fx.start(_ctx)
	local worldRoot = workspace:WaitForChild("SAE_World", 60)
	if worldRoot then
		task.spawn(function()
			local farms = worldRoot:WaitForChild("Hub"):WaitForChild("Farms", 30)
			if farms then
				for _, farm in farms:GetChildren() do
					local tm = farm:FindFirstChild("Treadmill", true)
					if tm and tm:IsA("Model") then
						collectTreadmill(tm)
					end
				end
			end
		end)
		task.spawn(function()
			local env = worldRoot:WaitForChild("Worlds"):WaitForChild("DemonSlayer"):WaitForChild("Environment", 30)
			if env then
				collectDemonSlayer(env)
			end
		end)
	end
	local t, acc = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		acc += dt
		if acc < 1 / 30 then
			return
		end
		acc = 0
		local cam = workspace.CurrentCamera
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		trailTick(t)
		if cam then
			treadmillTick(t, cam.CFrame.Position)
		end
		dsTick(t, root)
	end)
end

return Fx
