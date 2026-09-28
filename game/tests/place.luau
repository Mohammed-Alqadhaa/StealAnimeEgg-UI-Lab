--!nocheck
--[[
	Integration checks on the assembled Owner Review place (static, under Lune).
	lune run game/tests/place.luau [path.rbxlx]      (from repo root)

	This inspects the saved place file. It is NOT a Roblox Studio play test: nothing
	here executes Roblox runtime behaviour (physics, remotes, DataStores, rendering).
]]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local H = require("./harness")
local check, eq = H.check, H.eq

local PATH = process.args[1] or "checkpoints/StealAnAnimeEgg_FullProduction_OwnerReview_v01.rbxlx"
local BASELINE = "checkpoints/StealAnAnimeEgg_PreClaudeTakeover_20260928.rbxlx"
local game = roblox.deserializePlace(fs.readFile(PATH))
local Worlds = H.shared("Worlds")
local Layout = H.shared("Layout")
local Net = H.shared("Net")

local ws = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SS = game:GetService("ServerStorage")
local SG = game:GetService("StarterGui")
local SPS = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")

local function path(root, p)
	local cur = root
	for part in string.gmatch(p, "[^%.]+") do
		cur = cur and cur:FindFirstChild(part)
	end
	return cur
end
local function count(root, pred)
	local n = 0
	for _, d in root:GetDescendants() do
		if pred(d) then
			n += 1
		end
	end
	return n
end
local ACTIVE = { ws, RS, SSS, SG, SPS }

------------------------------------------------------------------ settings
H.section("settings")
eq(game:GetService("Players").MaxPlayers, 7, "Players.MaxPlayers = 7 (also set it in Game Settings: OWNER ACTION)")
eq(ws:GetAttribute("SAE_Build"), "FullProduction_OwnerReview_v01", "build stamp")

------------------------------------------------------------------ obsolete systems
H.section("obsolete systems removed from active containers (§ obsolete: Rebirth, BoxingBag, 6-world, Muscle)")
for _, root in ACTIVE do
	eq(count(root, function(d)
		local n = string.lower(d.Name)
		return string.find(n, "boxingbag", 1, true) ~= nil or string.find(n, "rebirth", 1, true) ~= nil or string.find(n, "muscle", 1, true) ~= nil
	end), 0, root.Name .. ": no BoxingBag/Rebirth/Muscle instances")
	eq(count(root, function(d)
		return d.Name == "SixZoneRoute" or d.Name == "FarmHubVisualPrototype"
	end), 0, root.Name .. ": no 6-zone prototype")
end
for _, root in ACTIVE do
	eq(count(root, function(d)
		return (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and table.find(Net.FORBIDDEN, d.Name) ~= nil
	end), 0, root.Name .. ": no forbidden remotes (RequestSecure etc.)")
end
local archive = path(SS, "SAE_Archive")
check(archive ~= nil, "legacy content preserved in ServerStorage.SAE_Archive (not deleted)")
check(path(SS, "SAE_Archive.PreservedEggs.Egg_Giyu_Water") ~= nil, "Giyu Water egg preserved (§31)")

------------------------------------------------------------------ scripts
H.section("scripts: only SAE_* code is active; every script compiles")
local active = {}
for _, root in ACTIVE do
	for _, d in root:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			table.insert(active, d)
		end
	end
end
local foreign = {}
for _, s in active do
	local owner = s:FindFirstAncestor("SAE_Server") or s:FindFirstAncestor("SAE_Client") or s:FindFirstAncestor("SAE_Shared") or s:FindFirstAncestor("SAE_StudioTests")
	if not owner then
		table.insert(foreign, s:GetFullName())
	end
end
eq(#foreign, 0, "no scripts outside SAE_Server/SAE_Client/SAE_Shared" .. (#foreign > 0 and (" (" .. table.concat(foreign, ", ") .. ")") or ""))
local compileErrors = 0
for _, s in active do
	local ok, err = pcall(luau.compile, s.Source)
	if not ok then
		compileErrors += 1
		print("  compile error in " .. s:GetFullName() .. ": " .. tostring(err))
	end
end
eq(compileErrors, 0, #active .. " scripts compile")
check(path(SSS, "SAE_Server.Main") and path(SSS, "SAE_Server.Main"):IsA("Script"), "server entry Script")
check(path(SPS, "SAE_Client.Main") and path(SPS, "SAE_Client.Main"):IsA("LocalScript"), "client entry LocalScript")
for _, m in { "UIController", "AssetBinder", "ClientNet", "ClientState", "HudApp", "MenusApp", "WorldClient", "FxClient", "DevClient", "ViewportService", "UIUtil", "AssetIds", "AssetManifest" } do
	check(path(SPS, "SAE_Client." .. m) ~= nil, "client module " .. m)
end

------------------------------------------------------------------ sanitization
H.section("imported asset sanitization (§ asset rules)")
for _, root in { ws, path(SS, "SAE_Assets"), path(RS, "SAE_Preview") } do
	eq(count(root, function(d)
		return d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript")
	end), 0, root.Name .. ": no scripts")
	eq(count(root, function(d)
		return d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("BindableEvent") or d:IsA("BindableFunction") or d:IsA("Tool")
	end), 0, root.Name .. ": no remotes/bindables/tools")
end

------------------------------------------------------------------ hub / farms
H.section("hub: one fenced safe zone, 7 farms, treadmill + signs (§ farms)")
local hub = path(ws, "SAE_World.Hub")
check(hub ~= nil, "Workspace.SAE_World.Hub")
local farms = path(hub, "Farms")
local farmCount = 0
for i = 1, 7 do
	local f = path(farms, "Farm" .. i)
	if f then
		farmCount += 1
		check(path(f, "Plot") ~= nil, "Farm" .. i .. ".Plot")
		check(path(f, "Characters") ~= nil, "Farm" .. i .. ".Characters")
		local tm = path(f, "Treadmill")
		check(tm and path(tm, "Belt") and path(tm, "TrainZone") and path(tm, "Tiers"), "Farm" .. i .. " treadmill (Belt/TrainZone/Tiers)")
		if tm then
			for t = 1, 10 do
				check(path(tm, "Tiers.Tier" .. t) ~= nil, "Farm" .. i .. " treadmill Tier" .. t)
			end
		end
		check(path(f, "TreadmillSign.PromptAnchor") ~= nil, "Farm" .. i .. " physical treadmill upgrade sign")
		check(path(f, "FarmSign") ~= nil, "Farm" .. i .. " farm upgrade sign")
		check(path(f, "OwnerPlate") ~= nil, "Farm" .. i .. " owner plate")
		eq(count(f, function(d)
			local n = string.lower(d.Name)
			return string.find(n, "fence", 1, true) ~= nil
		end), 0, "Farm" .. i .. " has no per-plot fence")
	end
end
eq(farmCount, 7, "7 farms")
check(count(hub, function(d)
	return string.find(d.Name, "Fence", 1, true) ~= nil
end) > 0, "perimeter fence around the whole Farm Safe Zone")
local gate = path(hub, "FogGate")
check(gate and path(gate, "Blocker") ~= nil, "fog gate with blocker")
check(gate and gate:FindFirstChild("Countdown", true) ~= nil, "fog gate countdown board")
for _, k in { { "TrailShop", "TrailShop" }, { "SellKiosk", "Sell" } } do
	local m = path(hub, k[1])
	local anchor = m and path(m, "PromptAnchor")
	check(anchor and anchor:GetAttribute("OpensMenu") == k[2], k[1] .. " kiosk opens " .. k[2])
	check(m and count(m, function(d)
		return d.Name == "HumanoidRootPart"
	end) == 1, k[1] .. " has its vendor")
end

------------------------------------------------------------------ worlds
H.section("worlds: 9 in order, 5 egg spawns each, boss (§ worlds)")
local worlds = path(ws, "SAE_World.Worlds")
local spawns = 0
for i, id in Worlds.ORDER do
	local w = path(worlds, id)
	check(w ~= nil, "world " .. i .. " " .. id)
	if w then
		eq(w:GetAttribute("WorldIndex"), i, id .. " WorldIndex attribute")
		check(path(w, "Boss") ~= nil, id .. " boss")
		for _, c in Worlds.WORLDS[id].roster do
			local egg = Worlds.EGGS["egg_" .. c]
			local sp = path(w, "Eggs." .. egg.spawnName)
			check(sp and path(sp, "Visual") and path(sp, "PromptAnchor"), id .. " spawn " .. egg.spawnName)
			if sp and path(sp, "PromptAnchor") then
				spawns += 1
				local p = path(sp, "PromptAnchor").CFrame.Position
				eq(Layout.worldAt(p.X, p.Z), id, egg.spawnName .. " lies inside " .. id)
			end
		end
	end
end
eq(spawns, 45, "45 egg spawns")
local bossCount = 0
for _, id in Worlds.ORDER do
	local b = path(worlds, id .. ".Boss")
	if b then
		bossCount += 1
	end
end
eq(bossCount, 9, "9 bosses")

------------------------------------------------------------------ Demon Slayer
H.section("Demon Slayer: approved eggs moved unchanged, width ×1.5 (§27, §31)")
local base = roblox.deserializePlace(fs.readFile(BASELINE))
local raw = base:GetService("Workspace"):FindFirstChild("OfficialEggInspection", true)
raw = raw and raw:FindFirstChild("RawAssets", true)
for _, c in Worlds.WORLDS.DemonSlayer.roster do
	local spec = Worlds.EGG_VISUALS[c]
	if spec.approvedAsset then
		local egg = Worlds.EGGS["egg_" .. c]
		local sp = path(worlds, "DemonSlayer.Eggs." .. egg.spawnName)
		local src = raw and raw:FindFirstChild(spec.approvedAsset)
		check(sp and sp:GetAttribute("ApprovedAsset") == spec.approvedAsset, c .. " uses approved asset " .. spec.approvedAsset)
		if sp and src then
			eq(#path(sp, "Visual"):GetDescendants(), #src:GetDescendants(), c .. " approved egg descendant count unchanged")
		end
	end
end
local env = path(worlds, "DemonSlayer.Environment")
check(env ~= nil, "Akaza world environment retained")
local walk = env and env:FindFirstChild("ContinuousWalkSurface", true)
check(walk and math.abs(walk.Size.X - 122) < 0.01, "walk surface widened 72 → 122")

------------------------------------------------------------------ previews / UI
H.section("UI: production SAE_UI from the UI Lab, preview models for ViewportFrames")
eq(#path(RS, "SAE_Preview.Rigs"):GetChildren(), 45, "45 preview rigs")
eq(#path(RS, "SAE_Preview.Eggs"):GetChildren(), 45, "45 preview eggs")
for _, id in Worlds.characterList() do
	check(path(RS, "SAE_Preview.Rigs." .. id) ~= nil, "preview rig " .. id)
	check(path(RS, "SAE_Preview.Eggs.egg_" .. id) ~= nil, "preview egg egg_" .. id)
end
local ui = path(SG, "SAE_UI")
check(ui and ui.ClassName == "ScreenGui", "StarterGui.SAE_UI")
check(path(SG, "StealAnimeEggUI") == nil, "UI Lab demo ScreenGui not shipped")
check(ui and path(ui, "PreviewPanel") == nil, "no UI Lab preview panel")
-- every path the client scripts bind to
local PATHS = {
	"HUD.Speed.Pill.Value", "HUD.Cash.Pill.Value", "HUD.Cash.Pill.Rate", "RoundTimer.Pill.Phase", "RoundTimer.Pill.Time",
	"EggCarry.Unsafe.Banner.Title", "EggCarry.Unsafe.Banner.WarnRow.Sub", "EggCarry.Unsafe.EggSlot.Egg3D", "EggCarry.Unsafe.DropButton", "EggCarry.Secured",
	"HatchTimer.StateHatching.EggName", "HatchTimer.StateHatching.TimerRow.Timer", "HatchTimer.StateHatching.Bar", "HatchTimer.StateReady.OpenButton",
	"HatchTimer.TitleRibbon.Title", "HatchTimer.More", "HatchTimer.EggSlot.Egg3D", "Nav.EggsButton.Badge", "Nav.IndexButton.Badge", "Toasts.Templates.Toast",
	"IndexMenu.Rim.Body.Content.Sidebar.Tabs", "IndexMenu.Rim.Body.Content.Grid", "IndexMenu.Rim.Body.Content.Header.World", "IndexMenu.Rim.Body.Content.Header.Discovered",
	"IndexMenu.Rim.Body.Content.Header.Total", "IndexMenu.Rim.Body.Content.Templates.WorldTab.Active.Face.Content.Count", "IndexMenu.Rim.Body.Content.Templates.IndexCard.LockBadge",
	"IndexMenu.Rim.Body.Content.Templates.IndexCard.NamePlate.Name", "IndexMenu.Rim.Body.Content.Templates.IndexCard.BossTag",
	"EggsMenu.Rim.Body.Content.Grid", "EggsMenu.Rim.Body.Content.Empty", "EggsMenu.Rim.Body.Content.Templates.EggCard.OpenButton",
	"EggsMenu.Rim.Body.Content.Templates.EggCard.Hatching.Timer", "EggsMenu.Rim.Body.Content.Templates.EggCard.Hatching.Bar.Fill",
	"CharactersMenu.Rim.Body.Content.TopBar.SlotsChip.Value", "CharactersMenu.Rim.Body.Content.TopBar.IncomeChip.Value", "CharactersMenu.Rim.Body.Content.TopBar.EquipBestButton",
	"CharactersMenu.Rim.Body.Content.Templates.UnitCard.EquipButton.Face.Content.Label", "CharactersMenu.Rim.Body.Content.Templates.UnitCard.Income.Text",
	"UpgradeMenu.Rim.Body.Content.Cards.FarmCard.Stat", "UpgradeMenu.Rim.Body.Content.Cards.FarmCard.UpgradeButton.Face.Content.Sub",
	"UpgradeMenu.Rim.Body.Content.Cards.TreadmillCard.UpgradeButton", "UpgradeMenu.Rim.Body.Content.List", "UpgradeMenu.Rim.Body.Content.Templates.UpgradeRow.Pips.Pip10",
	"UpgradeMenu.Rim.Body.Content.Templates.UpgradeRow.UpgradeButton.Face.Content.Sub",
	"TrailShopMenu.Rim.Body.Content.TopBar.Current.Text", "TrailShopMenu.Rim.Body.Content.TopBar.UnequipButton", "TrailShopMenu.Rim.Body.Content.Templates.TrailCard.Swatch.Mult",
	"TrailShopMenu.Rim.Body.Content.Templates.TrailCard.BuyButton.Face.Content.Sub",
	"SellMenu.Rim.Body.Content.Grid", "SellMenu.Rim.Body.Content.TopBar.Sort_Value", "SellMenu.Rim.Body.Content.TopBar.Sort_Name", "SellMenu.Rim.Body.Content.BottomBar.Total",
	"SellMenu.Rim.Body.Content.BottomBar.SellButton", "SellMenu.Rim.Body.Content.Templates.SellCard.Selected", "SellMenu.Rim.Body.Content.Templates.SellCard.Value",
	"ShopMenu.Rim.Body.Content.Templates.ShopCard.BuyButton.Face.Content.Label", "ShopMenu.Rim.Body.Content.Templates.ShopCard.Icon",
	"HatchReveal.Center.Model", "HatchReveal.Center.Name", "HatchReveal.Center.World", "HatchReveal.Center.NewTag", "HatchReveal.Center.BossTag", "HatchReveal.Center.AutoScale",
	"DevPanel",
}
local missing = {}
for _, p in PATHS do
	if not (ui and path(ui, p)) then
		table.insert(missing, p)
	end
end
eq(#missing, 0, #PATHS .. " client-bound UI paths exist" .. (#missing > 0 and (": missing " .. table.concat(missing, ", ")) or ""))
for _, m in { "Shop", "Index", "Eggs", "Characters", "Upgrade", "TrailShop", "Sell" } do
	local menu = ui and path(ui, m .. "Menu")
	eq(menu and menu:GetAttribute("Menu"), m, m .. "Menu registered (Menu attribute)")
end
local navTargets = {}
for _, b in path(ui, "Nav"):GetChildren() do
	local t = b:GetAttribute("NavTarget")
	if t then
		table.insert(navTargets, t)
	end
end
table.sort(navTargets)
eq(table.concat(navTargets, ","), "Characters,Eggs,Index,Shop,Upgrade", "nav = Shop/Index/Eggs/Characters/Upgrade (no Rebirth)")
local carryText = path(ui, "EggCarry.Unsafe.Banner.WarnRow.Sub")
eq(carryText and carryText.Text, "Reach the Farm Safe Zone!", "carry text")
eq(count(ui, function(d)
	return (d:IsA("TextLabel") or d:IsA("TextButton")) and string.find(string.lower(d.Text), "rebirth", 1, true) ~= nil
end), 0, "no Rebirth text in UI")
check(count(ui, function(d)
	return d:IsA("ViewportFrame")
end) >= 8, "ViewportFrames for real models")

------------------------------------------------------------------ runtime contracts
H.section("runtime contracts expected by the server services")
for _, id in Worlds.ORDER do
	local b = path(worlds, id .. ".Boss")
	if b then
		check(b:FindFirstChildOfClass("Humanoid") ~= nil, id .. " boss Humanoid (BossService)")
		check(b:FindFirstChild("HumanoidRootPart") ~= nil, id .. " boss HumanoidRootPart")
		local torso = b:FindFirstChild("Torso")
		local hip = torso and torso:FindFirstChild("Right Hip")
		check(hip and hip:IsA("Motor6D"), id .. " boss R6 hips (seated pose)")
	end
end
local rigs = path(SS, "SAE_Assets.CharacterRigs")
eq(rigs and #rigs:GetChildren(), 45, "45 character rigs for farm NPCs")
for _, id in Worlds.characterList() do
	local r = rigs and rigs:FindFirstChild(id)
	check(r and r:FindFirstChildOfClass("Humanoid") and r:FindFirstChild("HumanoidRootPart") and r:FindFirstChild("Head"), "rig " .. id .. " (Humanoid/HRP/Head)")
end
for i = 1, 7 do
	local f = path(farms, "Farm" .. i)
	for _, l in { "Owner", "Level", "Slots", "Next", "Cost" } do
		local found = f and f:FindFirstChild("FarmSign") and (f.FarmSign:FindFirstChild(l, true) or f.OwnerPlate:FindFirstChild(l, true))
		check(found and found:IsA("TextLabel"), "Farm" .. i .. " sign label " .. l)
	end
	for _, l in { "Title", "Level", "Gain", "Next", "Cost" } do
		local found = f and f:FindFirstChild("TreadmillSign") and f.TreadmillSign:FindFirstChild(l, true)
		check(found and found:IsA("TextLabel"), "Farm" .. i .. " treadmill sign label " .. l)
	end
	check(f and path(f, "FarmSign.PromptAnchor") ~= nil, "Farm" .. i .. " FarmSign.PromptAnchor")
end

------------------------------------------------------------------ spawns
H.section("spawn locations inside the Farm Safe Zone")
local spawnsIn, spawnsOut = 0, 0
for _, d in ws:GetDescendants() do
	if d.ClassName == "SpawnLocation" then
		local p = d.CFrame.Position
		if Layout.isInSafeZone(p.X, p.Y, p.Z) then
			spawnsIn += 1
		else
			spawnsOut += 1
			print("  spawn outside safe zone: " .. d:GetFullName())
		end
	end
end
check(spawnsIn >= 1, "at least one SpawnLocation in the safe zone (" .. spawnsIn .. ")")
eq(spawnsOut, 0, "no SpawnLocation outside the safe zone")

process.exit(H.finish() > 0 and 1 or 0)
