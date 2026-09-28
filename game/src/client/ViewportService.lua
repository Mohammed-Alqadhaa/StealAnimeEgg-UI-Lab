--!strict
--[[
	ViewportService — real 3D models in ViewportFrames (Index, Eggs, Characters, Sell,
	Upgrade, carry banner, hatch reveal).

	Models come from ReplicatedStorage.SAE_Preview (baked by the assembler from the same
	rigs/eggs used in the world): Rigs/<characterId>, Eggs/<eggId>.
	Locked Index entries use the real model as a SILHOUETTE (black, no detail, §Index).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Preview = ReplicatedStorage:WaitForChild("SAE_Preview")
local Rigs = Preview:WaitForChild("Rigs")
local Eggs = Preview:WaitForChild("Eggs")

local VS = {}
local spinning: { [ViewportFrame]: { model: Model, speed: number, base: CFrame, angle: number } } = {}

local function clearVp(vp: ViewportFrame)
	for _, c in vp:GetChildren() do
		if c:IsA("Model") or c:IsA("Camera") or c:IsA("BasePart") or c:IsA("WorldModel") then
			c:Destroy()
		end
	end
	spinning[vp] = nil
end

local function silhouette(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Color = Color3.new(0, 0, 0)
			d.Material = Enum.Material.SmoothPlastic
			if d:IsA("MeshPart") then
				d.TextureID = ""
			end
		elseif
			d:IsA("Decal")
			or d:IsA("Texture")
			or d:IsA("SurfaceAppearance")
			or d:IsA("ParticleEmitter")
			or d:IsA("Light")
			or d:IsA("Beam")
			or d:IsA("Trail")
		then
			d:Destroy()
		elseif d:IsA("SpecialMesh") then
			d.TextureId = ""
			d.VertexColor = Vector3.new(0, 0, 0)
		end
	end
end

local function mount(vp: ViewportFrame, source: Instance?, opts: { silhouette: boolean?, spin: number?, pitch: number?, fov: number?, key: string }?)
	local o = opts or ({} :: any)
	if vp:GetAttribute("VpKey") == o.key and vp:FindFirstChildOfClass("Camera") then
		return -- already showing this model in this mode
	end
	clearVp(vp)
	vp:SetAttribute("VpKey", o.key)
	if not source then
		return
	end
	local model = source:Clone() :: Model
	for _, d in model:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Humanoid") or d:IsA("ParticleEmitter") or d:IsA("Light") then
			d:Destroy()
		end
	end
	if o.silhouette then
		silhouette(model)
		vp.Ambient = Color3.new(0, 0, 0)
		vp.LightColor = Color3.new(0, 0, 0)
		vp.ImageColor3 = Color3.fromRGB(10, 8, 20)
	else
		vp.Ambient = Color3.fromRGB(170, 170, 185)
		vp.LightColor = Color3.fromRGB(255, 250, 240)
		vp.LightDirection = Vector3.new(-0.6, -1, -0.8)
		vp.ImageColor3 = Color3.new(1, 1, 1)
	end
	local world = Instance.new("WorldModel")
	world.Parent = vp
	model.Parent = world
	local cf, size = model:GetBoundingBox()
	-- put the camera in front of the model (rig HRP LookVector; eggs default to -Z)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local look = hrp and Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z) or Vector3.new(0, 0, -1)
	if look.Magnitude < 0.1 then
		look = Vector3.new(0, 0, -1)
	end
	look = look.Unit
	local cam = Instance.new("Camera")
	cam.FieldOfView = o.fov or 32
	local radius = math.max(size.X, size.Y, size.Z) * 0.5
	local dist = radius / math.tan(math.rad(cam.FieldOfView / 2)) * 1.12
	local center = cf.Position
	local pitch = math.rad(o.pitch or 8)
	local eye = center + look * (math.cos(pitch) * dist) + Vector3.new(0, math.sin(pitch) * dist, 0)
	cam.CFrame = CFrame.lookAt(eye, center)
	cam.Parent = vp
	vp.CurrentCamera = cam
	if o.spin and o.spin ~= 0 then
		spinning[vp] = { model = model, speed = o.spin, base = model:GetPivot(), angle = 0 }
	end
end

function VS.character(vp: ViewportFrame, charId: string, opts: { silhouette: boolean?, spin: number? }?)
	local o = opts or {}
	mount(vp, Rigs:FindFirstChild(charId), { silhouette = o.silhouette, spin = o.spin, key = "c:" .. charId .. (o.silhouette and ":s" or "") })
end

function VS.egg(vp: ViewportFrame, eggId: string, opts: { spin: number? }?)
	local o = opts or {}
	mount(vp, Eggs:FindFirstChild(eggId), { spin = o.spin or 0.8, pitch = 14, key = "e:" .. eggId })
end

function VS.clear(vp: ViewportFrame)
	clearVp(vp)
	vp:SetAttribute("VpKey", nil)
end

-- first ViewportFrame under root (templates carry exactly one per card)
function VS.first(root: Instance): ViewportFrame?
	return root:FindFirstChildWhichIsA("ViewportFrame", true)
end

RunService.RenderStepped:Connect(function(dt)
	for vp, s in spinning do
		if not vp.Parent or not s.model.Parent then
			spinning[vp] = nil
		elseif vp.Visible then
			s.angle += dt * s.speed
			s.model:PivotTo(s.base * CFrame.Angles(0, s.angle, 0))
		end
	end
end)

return VS
