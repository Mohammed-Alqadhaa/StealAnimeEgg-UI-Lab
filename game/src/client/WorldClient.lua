--!strict
--[[
	WorldClient — local-only world presentation and interaction glue.
	  * ZoneLighting: per-world LOCAL lighting profile (AkazaNight etc.), tweened on
	    entry/exit (continues the approved Akaza local-atmosphere approach, §32/§137)
	  * kiosk prompts: PromptAnchor parts with an `OpensMenu` attribute (Trail Shop /
	    Sell) get a local ProximityPrompt that opens the menu (menus are UI only;
	    every purchase/sale is validated by the server)
	  * prompts on other players' farm signs/treadmills are hidden locally (the server
	    also rejects them)
	  * fog gate countdown board text from workspace PhaseEndsAt
	  * Knockback event → velocity change on the client-owned character
]]
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Layout = require(Shared:WaitForChild("Layout"))
local Worlds = require(Shared:WaitForChild("Worlds"))

local player = Players.LocalPlayer

local WorldClient = {}

-- lighting profiles (local only). ClockTime is set instantly (never sweep day→night).
local HUB = {
	ClockTime = 13.5,
	Brightness = 2.25,
	Ambient = Color3.fromRGB(130, 145, 156),
	OutdoorAmbient = Color3.fromRGB(165, 184, 196),
	ExposureCompensation = 0,
	atmo = { Density = 0.18, Haze = 0.6, Color = Color3.fromRGB(199, 225, 255), Decay = Color3.fromRGB(106, 150, 200), Glare = 0 },
	tint = Color3.new(1, 1, 1),
	contrast = 0,
	saturation = 0.05,
	bloom = 0.05,
}
local PROFILES: { [string]: any } = {
	AkazaNight = {
		ClockTime = 20.15,
		Brightness = 2.25,
		Ambient = Color3.fromRGB(135, 165, 215),
		OutdoorAmbient = Color3.fromRGB(135, 165, 215),
		ExposureCompensation = 0,
		atmo = { Density = 0.12, Haze = 0.5, Color = Color3.fromRGB(78, 126, 181), Decay = Color3.fromRGB(44, 72, 133), Glare = 0.08 },
		tint = Color3.fromRGB(220, 235, 255),
		contrast = 0.06,
		saturation = -0.02,
		bloom = 0.12,
	},
	VillainViolet = {
		ClockTime = 19.4,
		Brightness = 1.6,
		Ambient = Color3.fromRGB(120, 90, 160),
		OutdoorAmbient = Color3.fromRGB(110, 80, 150),
		ExposureCompensation = 0.1,
		atmo = { Density = 0.28, Haze = 1.2, Color = Color3.fromRGB(120, 70, 170), Decay = Color3.fromRGB(60, 20, 90), Glare = 0.2 },
		tint = Color3.fromRGB(235, 220, 255),
		contrast = 0.1,
		saturation = 0.05,
		bloom = 0.25,
	},
	NamekDay = {
		ClockTime = 12.5,
		Brightness = 2.8,
		Ambient = Color3.fromRGB(140, 175, 150),
		OutdoorAmbient = Color3.fromRGB(160, 200, 170),
		ExposureCompensation = 0.05,
		atmo = { Density = 0.22, Haze = 0.8, Color = Color3.fromRGB(160, 230, 190), Decay = Color3.fromRGB(90, 170, 150), Glare = 0.3 },
		tint = Color3.fromRGB(235, 255, 240),
		contrast = 0.05,
		saturation = 0.12,
		bloom = 0.08,
	},
	DressrosaSun = {
		ClockTime = 14.2,
		Brightness = 3,
		Ambient = Color3.fromRGB(170, 150, 120),
		OutdoorAmbient = Color3.fromRGB(200, 180, 150),
		ExposureCompensation = 0.1,
		atmo = { Density = 0.15, Haze = 0.5, Color = Color3.fromRGB(255, 225, 180), Decay = Color3.fromRGB(230, 170, 120), Glare = 0.4 },
		tint = Color3.fromRGB(255, 245, 230),
		contrast = 0.06,
		saturation = 0.15,
		bloom = 0.06,
	},
	KonohaDusk = {
		ClockTime = 17.6,
		Brightness = 2,
		Ambient = Color3.fromRGB(165, 130, 110),
		OutdoorAmbient = Color3.fromRGB(190, 140, 110),
		ExposureCompensation = 0,
		atmo = { Density = 0.2, Haze = 1, Color = Color3.fromRGB(255, 180, 120), Decay = Color3.fromRGB(200, 110, 80), Glare = 0.5 },
		tint = Color3.fromRGB(255, 235, 215),
		contrast = 0.06,
		saturation = 0.08,
		bloom = 0.1,
	},
	CrimsonEclipse = {
		ClockTime = 18.8,
		Brightness = 1.4,
		Ambient = Color3.fromRGB(150, 60, 60),
		OutdoorAmbient = Color3.fromRGB(130, 40, 40),
		ExposureCompensation = 0,
		atmo = { Density = 0.35, Haze = 1.6, Color = Color3.fromRGB(170, 30, 30), Decay = Color3.fromRGB(60, 0, 0), Glare = 0.6 },
		tint = Color3.fromRGB(255, 215, 210),
		contrast = 0.14,
		saturation = -0.05,
		bloom = 0.3,
	},
	HopelessPalace = {
		ClockTime = 21.5,
		Brightness = 1.3,
		Ambient = Color3.fromRGB(120, 120, 135),
		OutdoorAmbient = Color3.fromRGB(110, 110, 125),
		ExposureCompensation = 0.15,
		atmo = { Density = 0.3, Haze = 1.2, Color = Color3.fromRGB(150, 150, 170), Decay = Color3.fromRGB(40, 40, 55), Glare = 0.1 },
		tint = Color3.fromRGB(235, 235, 245),
		contrast = 0.12,
		saturation = -0.25,
		bloom = 0.18,
	},
	CursedShibuya = {
		ClockTime = 22.5,
		Brightness = 1.2,
		Ambient = Color3.fromRGB(95, 90, 140),
		OutdoorAmbient = Color3.fromRGB(80, 75, 130),
		ExposureCompensation = 0.2,
		atmo = { Density = 0.32, Haze = 1.4, Color = Color3.fromRGB(90, 80, 170), Decay = Color3.fromRGB(30, 20, 70), Glare = 0.3 },
		tint = Color3.fromRGB(230, 225, 255),
		contrast = 0.12,
		saturation = 0.05,
		bloom = 0.28,
	},
	ShadowMonarch = {
		ClockTime = 23.2,
		Brightness = 1.1,
		Ambient = Color3.fromRGB(80, 90, 150),
		OutdoorAmbient = Color3.fromRGB(70, 80, 140),
		ExposureCompensation = 0.2,
		atmo = { Density = 0.34, Haze = 1.5, Color = Color3.fromRGB(70, 90, 200), Decay = Color3.fromRGB(10, 10, 40), Glare = 0.4 },
		tint = Color3.fromRGB(220, 230, 255),
		contrast = 0.14,
		saturation = -0.05,
		bloom = 0.32,
	},
}

local function setupLighting()
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmo then
		atmo = Instance.new("Atmosphere")
		atmo.Parent = Lighting
	end
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "SAE_ZoneGrade"
	cc.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "SAE_ZoneBloom"
	bloom.Size = 24
	bloom.Threshold = 1.8
	bloom.Parent = Lighting
	local current: string? = "?"
	local tweens: { Tween } = {}
	local info = TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local function apply(worldId: string?)
		if worldId == current then
			return
		end
		current = worldId
		for _, t in tweens do
			t:Cancel()
		end
		table.clear(tweens)
		local p = HUB
		if worldId then
			p = PROFILES[Worlds.WORLDS[worldId].lighting] or HUB
		end
		Lighting.ClockTime = p.ClockTime
		local function tw(obj: Instance, props: { [string]: any })
			local t = TweenService:Create(obj, info, props)
			t:Play()
			table.insert(tweens, t)
		end
		tw(Lighting, { Brightness = p.Brightness, Ambient = p.Ambient, OutdoorAmbient = p.OutdoorAmbient, ExposureCompensation = p.ExposureCompensation })
		tw(atmo :: Atmosphere, p.atmo)
		tw(cc, { TintColor = p.tint, Contrast = p.contrast, Saturation = p.saturation })
		tw(bloom, { Intensity = p.bloom })
		Lighting:SetAttribute("SAE_Zone", worldId or "Hub")
		Lighting:SetAttribute("AkazaNightActive", worldId == "DemonSlayer")
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.2 then
			return
		end
		acc = 0
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return
		end
		local pos = root.Position
		apply(Layout.worldAt(pos.X, pos.Z))
	end)
	apply(nil)
end

local function setupKiosks(ui, hub: Instance)
	local function attach(anchor: Instance)
		local menu = anchor:GetAttribute("OpensMenu")
		if not anchor:IsA("BasePart") or typeof(menu) ~= "string" or anchor:FindFirstChild("SAE_KioskPrompt") then
			return
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "SAE_KioskPrompt"
		prompt.ActionText = anchor:GetAttribute("PromptText") or "Open"
		prompt.ObjectText = menu == "TrailShop" and "Makima's Trail Shop" or "Rem's Sell Stand"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = anchor
		prompt.Triggered:Connect(function()
			ui:OpenMenu(menu)
		end)
	end
	for _, d in hub:GetDescendants() do
		attach(d)
	end
	hub.DescendantAdded:Connect(attach)
end

local function setupFarmPrompts(hub: Instance)
	local farms = hub:WaitForChild("Farms", 30)
	if not farms then
		return
	end
	local function refresh(farm: Instance)
		local mine = farm:GetAttribute("OwnerUserId") == player.UserId
		for _, d in farm:GetDescendants() do
			if d:IsA("ProximityPrompt") then
				d.Enabled = mine
			end
		end
	end
	for _, farm in farms:GetChildren() do
		refresh(farm)
		farm:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			refresh(farm)
		end)
		farm.DescendantAdded:Connect(function(d)
			if d:IsA("ProximityPrompt") then
				d.Enabled = farm:GetAttribute("OwnerUserId") == player.UserId
			end
		end)
	end
end

local function setupFogBoard(hub: Instance)
	local gate = hub:WaitForChild("FogGate", 30)
	local label = gate and gate:FindFirstChild("Countdown", true)
	if not (label and label:IsA("TextLabel")) then
		return
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.2 then
			return
		end
		acc = 0
		local phase = workspace:GetAttribute("RoundPhase")
		local left = math.max(0, math.ceil((workspace:GetAttribute("PhaseEndsAt") or 0) - workspace:GetServerTimeNow()))
		if phase == "GATE" then
			label.Text = "WORLDS OPEN IN " .. left
		elseif phase == "OPEN" then
			label.Text = string.format("ROUND ENDS IN %d:%02d", left // 60, left % 60)
		else
			label.Text = "RESETTING..."
		end
	end)
end

function WorldClient.start(ctx)
	setupLighting()
	local worldRoot = workspace:WaitForChild("SAE_World", 60)
	local hub = worldRoot and worldRoot:WaitForChild("Hub", 30)
	if hub then
		setupKiosks(ctx.ui, hub)
		task.spawn(setupFarmPrompts, hub)
		task.spawn(setupFogBoard, hub)
	end
	ctx.net.on("Knockback", function(impulse)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if typeof(impulse) ~= "Vector3" or not root or not hum then
			return
		end
		if impulse.Magnitude > 200 then
			impulse = impulse.Unit * 200 -- sanity clamp
		end
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
		root.AssemblyLinearVelocity = Vector3.new(impulse.X, math.max(root.AssemblyLinearVelocity.Y, 0) + impulse.Y, impulse.Z)
	end)
end

return WorldClient
