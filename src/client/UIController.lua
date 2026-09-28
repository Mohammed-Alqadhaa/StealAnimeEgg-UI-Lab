-- UIController: production-style behaviour for the StealAnimeEgg UI.
--   * responsive scale (every UIScale named "AutoScale")
--   * navigation: NavTarget buttons open/close menus, CloseMenu buttons, backdrop
--   * Upgrade tabs (buttons with a `Tab` attribute)
--   * chunky button feedback: hover grow, press sink (Face moves onto the Lip)
--   * idle animation attributes: Spin (deg/s), Wobble, Bob, Pulse
--   * optional ViewportFrame 3D egg (ViewportFrame with Enable3D = true)
-- Contains NO gameplay and NO sample data.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BASE = Vector2.new(1280, 720)
local MIN_SCALE, MAX_SCALE = 0.45, 2

local UIController = {}
UIController.__index = UIController

local function tween(obj: Instance, time: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

-- Face of a chunky button (tab buttons hold Active/Inactive variants)
local function faceOf(btn: Instance): GuiObject?
	local face = btn:FindFirstChild("Face")
	if face then
		return face :: GuiObject
	end
	for _, variant in btn:GetChildren() do
		if variant:IsA("GuiObject") and variant.Visible and variant:FindFirstChild("Face") then
			return variant:FindFirstChild("Face") :: GuiObject
		end
	end
	return nil
end

local function isShown(obj: Instance, gui: Instance): boolean
	local cur: Instance? = obj
	while cur and cur ~= gui do
		if cur:IsA("GuiObject") and not cur.Visible then
			return false
		end
		cur = cur.Parent
	end
	return true
end

function UIController.start(gui: ScreenGui)
	local self = setmetatable({}, UIController)
	self.Gui = gui
	self.CurrentMenu = nil :: string?
	self.Menus = {} :: { [string]: GuiObject }
	self._changed = Instance.new("BindableEvent")
	self.MenuChanged = self._changed.Event -- fires (newMenu: string?)
	self._hovered = {} :: { [Instance]: boolean }

	for _, child in gui:GetChildren() do
		local id = child:GetAttribute("Menu")
		if typeof(id) == "string" and child:IsA("GuiObject") then
			self.Menus[id] = child
			child.Visible = false
		end
	end

	for _, d in gui:GetDescendants() do
		if d:IsA("GuiButton") then
			self:_bindButton(d)
		end
	end

	self:_setupAutoScale()
	self:_setupAnimations()
	self:_setupViewportEggs()
	self:_refreshNav()
	return self
end

---------------------------------------------------------------- responsive
function UIController:_setupAutoScale()
	local camera = Workspace.CurrentCamera
	local function apply()
		local vp = camera and camera.ViewportSize or BASE
		local s = math.clamp(math.min(vp.X / BASE.X, vp.Y / BASE.Y), MIN_SCALE, MAX_SCALE)
		for _, d in self.Gui:GetDescendants() do
			if d:IsA("UIScale") and d.Name == "AutoScale" then
				d:SetAttribute("BaseScale", s)
				d.Scale = s
			end
		end
	end
	apply()
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
	end
end

---------------------------------------------------------------- navigation
function UIController:OpenMenu(name: string)
	local menu = self.Menus[name]
	if not menu then
		return
	end
	if self.CurrentMenu and self.CurrentMenu ~= name then
		self.Menus[self.CurrentMenu].Visible = false
	end
	self.CurrentMenu = name
	menu.Visible = true
	-- pop-in: animate the menu's AutoScale from 85% to its responsive base scale
	local scale = menu:FindFirstChild("AutoScale")
	if scale and scale:IsA("UIScale") then
		local base = scale:GetAttribute("BaseScale") or 1
		scale.Scale = base * 0.85
		tween(scale, 0.22, { Scale = base }, Enum.EasingStyle.Back)
	end
	self:_refreshNav()
	self._changed:Fire(name)
end

function UIController:CloseMenu()
	if self.CurrentMenu then
		self.Menus[self.CurrentMenu].Visible = false
	end
	self.CurrentMenu = nil
	self:_refreshNav()
	self._changed:Fire(nil)
end

function UIController:ToggleMenu(name: string)
	if self.CurrentMenu == name then
		self:CloseMenu()
	else
		self:OpenMenu(name)
	end
end

function UIController:_refreshNav()
	local backdrop = self.Gui:FindFirstChild("MenuBackdrop")
	if backdrop and backdrop:IsA("GuiObject") then
		backdrop.Visible = self.CurrentMenu ~= nil
	end
	local nav = self.Gui:FindFirstChild("Nav")
	if not nav then
		return
	end
	for _, btn in nav:GetChildren() do
		local target = btn:GetAttribute("NavTarget")
		local glow = btn:FindFirstChild("SelectedGlow")
		if target and glow and glow:IsA("GuiObject") then
			glow.Visible = target == self.CurrentMenu
		end
	end
end

-- Upgrade tabs: `Tab` attribute -> <Tab>Page under the menu's Pages frame
function UIController:SetTab(button: Instance, tab: string)
	local menu = button:FindFirstAncestorWhichIsA("GuiObject")
	while menu and menu.Parent ~= self.Gui do
		menu = menu.Parent :: any
	end
	if not menu then
		return
	end
	local pages = menu:FindFirstChild("Pages", true)
	local tabs = button.Parent
	if pages then
		for _, page in pages:GetChildren() do
			if page:IsA("GuiObject") then
				page.Visible = page.Name == tab .. "Page"
			end
		end
	end
	if tabs then
		for _, t in tabs:GetChildren() do
			local id = t:GetAttribute("Tab")
			if id then
				local on = id == tab
				local a, i = t:FindFirstChild("Active"), t:FindFirstChild("Inactive")
				if a then
					(a :: GuiObject).Visible = on
				end
				if i then
					(i :: GuiObject).Visible = not on
				end
			end
		end
	end
end

------------------------------------------------------------ button feedback
function UIController:_bindButton(btn: GuiButton)
	local chunky = btn:GetAttribute("Chunky") == true
	local lip = btn:GetAttribute("LipDepth") or 6
	local pressScale = btn:FindFirstChild("PressScale")
	local disabled = btn:GetAttribute("Disabled") == true

	if chunky and not disabled then
		btn.MouseEnter:Connect(function()
			self._hovered[btn] = true
			if pressScale then
				tween(pressScale, 0.12, { Scale = 1.06 }, Enum.EasingStyle.Back)
			end
		end)
		btn.MouseLeave:Connect(function()
			self._hovered[btn] = nil
			if pressScale then
				tween(pressScale, 0.12, { Scale = 1 })
			end
			local face = faceOf(btn)
			if face then
				face.Position = UDim2.new()
			end
		end)
		btn.MouseButton1Down:Connect(function()
			local face = faceOf(btn)
			if face then
				tween(face, 0.06, { Position = UDim2.fromOffset(0, lip - 2) })
			end
			if pressScale then
				tween(pressScale, 0.06, { Scale = 0.96 })
			end
		end)
		btn.MouseButton1Up:Connect(function()
			local face = faceOf(btn)
			if face then
				tween(face, 0.1, { Position = UDim2.new() }, Enum.EasingStyle.Back)
			end
			if pressScale then
				tween(pressScale, 0.1, { Scale = self._hovered[btn] and 1.06 or 1 }, Enum.EasingStyle.Back)
			end
		end)
	end

	btn.Activated:Connect(function()
		local nav = btn:GetAttribute("NavTarget")
		if typeof(nav) == "string" then
			self:ToggleMenu(nav)
			return
		end
		if btn:GetAttribute("Action") == "CloseMenu" then
			self:CloseMenu()
			return
		end
		local tab = btn:GetAttribute("Tab")
		if typeof(tab) == "string" then
			self:SetTab(btn, tab)
		end
	end)
end

--------------------------------------------------------------- idle motion
function UIController:_setupAnimations()
	local spin, wobble, bob, pulse = {}, {}, {}, {}
	for _, d in self.Gui:GetDescendants() do
		if d:IsA("GuiObject") then
			local s = d:GetAttribute("Spin")
			if typeof(s) == "number" then
				table.insert(spin, { obj = d, speed = s })
			end
			if d:GetAttribute("Wobble") == true then
				table.insert(wobble, { obj = d, base = d.Rotation, phase = math.random() * 6 })
			end
			if d:GetAttribute("Bob") == true then
				table.insert(bob, { obj = d, base = d.Position, phase = math.random() * 6 })
			end
			if d:GetAttribute("Pulse") == true then
				local sc = d:FindFirstChild("PressScale") or d:FindFirstChildOfClass("UIScale")
				if not sc then
					sc = Instance.new("UIScale")
					sc.Name = "PulseScale"
					sc.Parent = d
				end
				table.insert(pulse, { obj = d, scale = sc })
			end
		end
	end
	local gui = self.Gui
	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		for _, e in spin do
			if isShown(e.obj, gui) then
				e.obj.Rotation = (e.obj.Rotation + e.speed * dt) % 360
			end
		end
		for _, e in wobble do
			if isShown(e.obj, gui) then
				e.obj.Rotation = e.base + math.sin(t * 5 + e.phase) * 6
			end
		end
		for _, e in bob do
			if isShown(e.obj, gui) then
				e.obj.Position = e.base + UDim2.fromOffset(0, math.sin(t * 2.2 + e.phase) * 4)
			end
		end
		for _, e in pulse do
			if not self._hovered[e.obj] and isShown(e.obj, gui) then
				e.scale.Scale = 1 + math.sin(t * 6) * 0.045
			end
		end
	end)
end

-------------------------------------------------------- optional 3D preview
-- ViewportFrames with EggColor + Enable3D=true get a real 3D egg (ellipsoid
-- mesh) that slowly rotates. Disabled by default: the 2D egg art is richer.
function UIController:_setupViewportEggs()
	for _, vp in self.Gui:GetDescendants() do
		if vp:IsA("ViewportFrame") and vp:GetAttribute("Enable3D") == true then
			local color = vp:GetAttribute("EggColor")
			local part = Instance.new("Part")
			part.Anchored = true
			part.Size = Vector3.new(2, 2, 2)
			part.Material = Enum.Material.SmoothPlastic
			part.Color = typeof(color) == "string" and Color3.fromHex(color) or Color3.fromRGB(255, 200, 80)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Scale = Vector3.new(1, 1.3, 1)
			mesh.Parent = part
			part.Parent = vp
			local cam = Instance.new("Camera")
			cam.FieldOfView = 40
			cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.3, 6), Vector3.zero)
			cam.Parent = vp
			vp.CurrentCamera = cam
			vp.Visible = true
			local fallback = vp.Parent and vp.Parent:FindFirstChild("Egg")
			if fallback and fallback:IsA("GuiObject") then
				fallback.Visible = false
			end
			RunService.RenderStepped:Connect(function(dt)
				part.CFrame = part.CFrame * CFrame.Angles(0, dt * 1.2, 0)
			end)
		end
	end
end

return UIController
