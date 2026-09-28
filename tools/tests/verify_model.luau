--!nocheck
-- Headless verification of the exported Roblox model with Lune (https://lune-org.github.io).
--   lune run tools/tests/verify_model.luau
-- 1. Loads dist/StealAnimeEgg_UI_Lab.rbxm (the binary written by Rojo)
-- 2. Checks structural requirements of the brief
-- 3. Executes the real PREVIEW_Controller ModuleScript source against the model and
--    asserts that every preview action changes the expected instances, with an audit
--    that fails on ANY hierarchy path the controller cannot resolve.
-- Lune has no input/render loop, so button events and UIController animations are not
-- exercised here (UIController is covered by lint only).

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local task = require("@lune/task")
local process = require("@lune/process")

local failures, passes = 0, 0
local function check(cond: boolean, msg: string)
	if cond then
		passes += 1
	else
		failures += 1
		print("  FAIL: " .. msg)
	end
end

local model = roblox.deserializeModel(fs.readFile("dist/StealAnimeEgg_UI_Lab.rbxm"))
local gui = model[1]
print(`Loaded {gui.ClassName} '{gui.Name}' with {#gui:GetDescendants()} descendants`)

local function at(root, path)
	local cur = root
	for part in string.gmatch(path, "[^%.]+") do
		if not cur then
			return nil
		end
		cur = cur:FindFirstChild(part)
	end
	return cur
end

------------------------------------------------------------------ structure
print("[structure]")
check(gui.ClassName == "ScreenGui", "root is a ScreenGui")
check(gui.ZIndexBehavior == roblox.Enum.ZIndexBehavior.Sibling, "ZIndexBehavior = Sibling")
check(gui.ResetOnSpawn == false, "ResetOnSpawn = false")
for _, m in { "Shop", "Index", "Eggs", "Characters", "Upgrade" } do
	local menu = gui:FindFirstChild(m .. "Menu")
	check(menu ~= nil and menu:GetAttribute("Menu") == m, m .. "Menu exists with Menu attribute")
	check(at(gui, "Nav." .. m .. "Button") ~= nil, "Nav." .. m .. "Button exists")
	check(menu and menu:FindFirstChild("AutoScale") and menu.AutoScale.ClassName == "UIScale", m .. "Menu has AutoScale UIScale")
end
local forbidden = 0
for _, d in gui:GetDescendants() do
	local n = string.lower(d.Name)
	local txt = (d.ClassName == "TextLabel" or d.ClassName == "TextButton") and string.lower(d.Text) or ""
	if string.find(n, "rebirth") or string.find(txt, "rebirth") or string.find(n, "boxing") or string.find(txt, "boxing") then
		forbidden += 1
	end
end
check(forbidden == 0, "no Rebirth / Boxing Bag anywhere")
local order = { "rengoku", "yoriichi", "muzan", "akaza", "tanjiro" }
for _, id in order do
	local card = at(gui, "IndexMenu.Rim.Body.Content.Grid.Card_" .. id)
	check(card ~= nil, "Index card " .. id)
	local lockedPortrait = card and at(card, "Locked.PortraitWell.Portrait")
	check(lockedPortrait ~= nil and lockedPortrait.ImageColor3 == roblox.Color3.new(0, 0, 0), id .. " locked portrait is a black silhouette (not a lock icon)")
	check(card and at(card, "Locked.NamePlate.Name").Text == "???", id .. " locked name = ???")
	check(card and at(card, "Unlocked.NamePlate.Name").Text ~= "???", id .. " unlocked shows real name")
end
for i = 1, 4 do
	local c = at(gui, "EggsMenu.Rim.Body.Content.Grid.EggCard_egg_" .. i)
	for _, st in { "StateOwned", "StateHatching", "StateReady", "StateOpened" } do
		check(c and c:FindFirstChild(st) ~= nil, `EggCard_egg_{i}.{st}`)
	end
end
check(at(gui, "EggCarry.Unsafe.DropButton") ~= nil, "UNSAFE carry has DROP")
check(at(gui, "EggCarry.Secured") ~= nil and at(gui, "EggCarry.Secured"):FindFirstChild("DropButton", true) == nil, "SECURED carry has no DROP")
for _, p in { "CharacterPage", "TreadmillPage", "FarmPage" } do
	check(at(gui, "UpgradeMenu.Rim.Body.Content.Pages." .. p) ~= nil, "Upgrade " .. p)
end
check(at(gui, "CharactersMenu.Rim.Body.Content.Grid.Unit_rengoku_1") and at(gui, "CharactersMenu.Rim.Body.Content.Grid.Unit_rengoku_2"), "duplicate units are separate cards")
check(at(gui, "CharactersMenu.Rim.Body.Content.TopBar.EquipBestButton") ~= nil, "Equip Best button")
local imgs, keyed = 0, 0
for _, d in gui:GetDescendants() do
	if d.ClassName == "ImageLabel" or d.ClassName == "ImageButton" then
		imgs += 1
		if d:GetAttribute("AssetKey") then
			keyed += 1
		end
	end
end
check(imgs == keyed, `every ImageLabel has an AssetKey ({keyed}/{imgs})`)

----------------------------------------------------------- run preview code
print("[PREVIEW_Controller executed against the model]")
local scripts = gui:FindFirstChild("LabScripts")
local function loadModule(ms, env)
	local chunk = luau.load(ms.Source, { debugName = ms.Name, environment = env })
	return chunk()
end
local cache = {}
local env
local function makeEnv(scriptInst)
	return setmetatable({
		script = scriptInst,
		require = function(ms)
			if not cache[ms] then
				cache[ms] = loadModule(ms, makeEnv(ms))
			end
			return cache[ms]
		end,
		warn = function(...) end,
		task = task,
		UDim2 = roblox.UDim2, UDim = roblox.UDim, Vector2 = roblox.Vector2, Color3 = roblox.Color3,
		Instance = roblox.Instance, Enum = roblox.Enum,
	}, { __index = _G })
end
-- Lune instances have no WaitForChild: alias it for this headless run
local Preview = nil
do
	local src = scripts.PREVIEW_Controller.Source
	src = string.gsub(src, ":WaitForChild%(", ":FindFirstChild(")
	env = makeEnv(scripts.PREVIEW_Controller)
	Preview = luau.load(src, { debugName = "PREVIEW_Controller", environment = env })()
end
local opened = nil
local fakeUi = {
	OpenMenu = function(_, name)
		opened = name
	end,
	CloseMenu = function()
		opened = nil
	end,
	SetTab = function(_, _btn, tab)
		for _, p in at(gui, "UpgradeMenu.Rim.Body.Content.Pages"):GetChildren() do
			p.Visible = p.Name == tab .. "Page"
		end
	end,
}
local h = Preview.start(gui, fakeUi, { bindInput = false, audit = true })
local C = "CharactersMenu.Rim.Body.Content"

h.act("menu:Index")
check(opened == "Index", "menu:Index opens Index")
h.act("index:lockAll")
check(at(gui, "IndexMenu.Rim.Body.Content.CollectionHeader.Discovered").Text == "0 / 5 Discovered", "lockAll -> 0 / 5")
check(at(gui, "IndexMenu.Rim.Body.Content.Grid.Card_rengoku.Locked").Visible == true, "lockAll -> Rengoku locked")
h.act("index:unlockNext")
check(at(gui, "IndexMenu.Rim.Body.Content.Grid.Card_rengoku.Unlocked").Visible == true, "unlockNext -> Rengoku unlocked")
h.act("index:unlockAll")
check(at(gui, "IndexMenu.Rim.Body.Content.CollectionHeader.Discovered").Text == "5 / 5 Discovered", "unlockAll -> 5 / 5")
check(at(gui, "IndexMenu.Rim.Body.Content.CollectionHeader.Progress.Fill").Size.X.Scale == 1, "progress bar full")

h.act("eggs:cycle")
local e1 = at(gui, "EggsMenu.Rim.Body.Content.Grid.EggCard_egg_1")
check(e1.StateHatching.Visible and not e1.StateOwned.Visible, "eggs:cycle OWNED -> HATCHING")
h.act("eggs:allReady")
check(at(gui, "EggsMenu.Rim.Body.Content.Grid.EggCard_egg_4.StateReady").Visible, "eggs:allReady")

h.act("carry:secured")
check(at(gui, "EggCarry.Secured").Visible and not at(gui, "EggCarry.Unsafe").Visible, "carry:secured")
h.act("carry:unsafe")
check(at(gui, "EggCarry.Unsafe").Visible and at(gui, "EggCarry.Unsafe.DropButton").Visible, "carry:unsafe shows DROP")

h.act("hatch:ready")
check(at(gui, "HatchTimer.StateReady").Visible and at(gui, "HatchTimer.TitleRibbon.Title").Text == "EGG READY", "hatch:ready")

h.act("chars:equipBest")
local best = { yoriichi_1 = true, rengoku_1 = true, muzan_1 = true, akaza_1 = true }
for _, u in h.data.units do
	local card = at(gui, C .. ".Grid.Unit_" .. u.id)
	check(card.UnequipButton.Visible == (best[u.id] == true), "equipBest by $/sec: " .. u.id)
end
check(at(gui, C .. ".TopBar.Equipped.Value").Text == "4 / 4", "equipped 4 / 4")
check(at(gui, C .. ".TopBar.Income.Value").Text == "$368/s", "income $368/s")
h.act("chars:addDupe")
local dupe = at(gui, C .. ".Grid.Unit_rengoku_3")
check(dupe ~= nil and at(dupe, "UnitChip.Text").Text == "#3", "addDupe -> Rengoku Unit #3 card")

h.act("upgrade:tab:Farm")
check(at(gui, "UpgradeMenu.Rim.Body.Content.Pages.FarmPage").Visible, "upgrade tab Farm")
h.act("upgrade:toggleMax")
check(at(gui, "UpgradeMenu.Rim.Body.Content.Pages.CharacterPage.Row_rengoku_1.MaxLevelButton").Visible, "toggleMax -> MAX LEVEL")
check(at(gui, "UpgradeMenu.Rim.Body.Content.Pages.TreadmillPage.Info.MaxLevelButton").Visible, "toggleMax treadmill")

-- 60s dev timer (sped up: poll 2 ticks)
h.act("hatch:start")
check(at(gui, "HatchTimer.StateHatching.TimerRow.Timer").Text == "1:00", "hatch:start -> 1:00")
task.wait(2.2)
check(at(gui, "HatchTimer.StateHatching.TimerRow.Timer").Text == "0:58", "timer ticks down (0:58 after 2s)")
h.act("hatch:hatching") -- stops the timer loop

check(#Preview.missing == 0, "audit: every hierarchy path used by PREVIEW_Controller resolves")
for _, m in Preview.missing do
	print("    unresolved: " .. m)
end

print(`\n{passes} passed, {failures} failed`)
process.exit(failures == 0 and 0 or 1)
