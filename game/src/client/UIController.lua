-- UIController (from the UI Lab, adapted for production).
--   * responsive scale (every UIScale named "AutoScale")
--   * navigation: NavTarget buttons open/close menus, CloseMenu buttons, backdrop
--   * tabs (buttons with a `Tab` attribute)
--   * chunky button feedback: hover grow, press sink (Face moves onto the Lip)
--   * idle animation attributes: Spin (deg/s), Wobble, Bob, Pulse
--   * `Action` attribute buttons fire UIController.Action(button, action)
--   * UIController:Bind(root) wires buttons/animations on template clones
-- Contains NO gameplay decisions: every action is sent to the server as intent.

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

	self._actionEvent = Instance.new("BindableEvent")
	self.Action = self._actionEvent.Event -- fires (button, action)
	self._spin, self._wobble, self._bob, self._pulse = {}, {}, {}, {}

	self:Bind(gui)
	self:_setupAutoScale()
	self:_setupAnimations()
	self:_refreshNav()
	return self
end

local function inTemplate(d: Instance): boolean
	local f = d:FindFirstAncestorOfClass("Folder")
	return f ~= nil and f.Name == "Templates"
end

-- Wire buttons + idle animations for `root` and its descendants (skips Templates).
function UIController:Bind(root: Instance)
	local list = root:GetDescendants()
	table.insert(list, root)
	for _, d in list do
		if not inTemplate(d) then
			if d:IsA("GuiButton") then
				self:_bindButton(d)
			end
			if d:IsA("GuiObject") then
				self:_track(d)
			end
		end
	end
end

function UIController:_track(d: GuiObject)
	local s = d:GetAttribute("Spin")
	if typeof(s) == "number" then
		table.insert(self._spin, { obj = d, speed = s })
	end
	if d:GetAttribute("Wobble") == true then
		table.insert(self._wobble, { obj = d, base = d.Rotation, phase = math.random() * 6 })
	end
	if d:GetAttribute("Bob") == true then
		table.insert(self._bob, { obj = d, base = d.Position, phase = math.random() * 6 })
	end
	if d:GetAttribute("Pulse") == true then
		local sc = d:FindFirstChild("PressScale") or d:FindFirstChildOfClass("UIScale")
		if not sc then
			sc = Instance.new("UIScale")
			sc.Name = "PulseScale"
			sc.Parent = d
		end
		table.insert(self._pulse, { obj = d, scale = sc })
	end
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
		local action = btn:GetAttribute("Action")
		if action == "CloseMenu" then
			self:CloseMenu()
			return
		end
		if typeof(action) == "string" then
			self._actionEvent:Fire(btn, action)
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
	local gui = self.Gui
	local t = 0
	local function live(list)
		for i = #list, 1, -1 do
			if not list[i].obj.Parent then
				table.remove(list, i)
			end
		end
	end
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		acc += dt
		if acc > 2 then -- prune destroyed clones
			acc = 0
			live(self._spin)
			live(self._wobble)
			live(self._bob)
			live(self._pulse)
		end
		for _, e in self._spin do
			if isShown(e.obj, gui) then
				e.obj.Rotation = (e.obj.Rotation + e.speed * dt) % 360
			end
		end
		for _, e in self._wobble do
			if isShown(e.obj, gui) then
				e.obj.Rotation = e.base + math.sin(t * 5 + e.phase) * 6
			end
		end
		for _, e in self._bob do
			if isShown(e.obj, gui) then
				e.obj.Position = e.base + UDim2.fromOffset(0, math.sin(t * 2.2 + e.phase) * 4)
			end
		end
		for _, e in self._pulse do
			if not self._hovered[e.obj] and isShown(e.obj, gui) then
				e.scale.Scale = 1 + math.sin(t * 6) * 0.045
			end
		end
	end)
end

return UIController
