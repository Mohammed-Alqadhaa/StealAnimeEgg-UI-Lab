--!nocheck
--[[
	Steal an Anime Egg — Owner Review assembler (Lune).

	  lune run game/assembler/build.luau            (from the repository root)

	Input : checkpoints/StealAnAnimeEgg_PreClaudeTakeover_20260928.rbxlx (read-only baseline)
	Output: checkpoints/StealAnAnimeEgg_FullProduction_OwnerReview_v01.rbxlx
	        docs/generated/ASSEMBLY_REPORT.json (every archive/move/create + import audit)

	The baseline is never modified. Legacy content is ARCHIVED to ServerStorage.SAE_Archive
	(disabled), not deleted, except the explicitly obsolete per-plot fences and BoxingBag
	parts (§80, §83) which are removed after FarmService no longer depends on them.
]]
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")

local B = require("./lib/B")
local Rigs = require("./lib/Rigs")
local EggPipeline = require("./lib/EggPipeline")
local Hub = require("./lib/Hub")
local Kit = require("./worlds/Kit")
local Themes = require("./worlds/Themes")
local DS = require("./worlds/DemonSlayer")
local shared = require("./lib/shared")
local Worlds = shared("Worlds")
local Layout = shared("Layout")

local R = B.R
local V3, CF = B.V3, B.CF

local BASELINE = "checkpoints/StealAnAnimeEgg_PreClaudeTakeover_20260928.rbxlx"
local OUT = process.args[1] or "checkpoints/StealAnAnimeEgg_FullProduction_OwnerReview_v01.rbxlx"
local UI_MODEL = "game/ui/SAE_UI.rbxmx"

local report = { archived = {}, removed = {}, created = {}, moved = {}, importAudit = {}, warnings = {}, standIns = {} }
local function log(kind, what)
	table.insert(report[kind], what)
end

print("[assembler] loading baseline " .. BASELINE)
local game = R.deserializePlace(fs.readFile(BASELINE))
local ws = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")
local SG = game:GetService("StarterGui")
local SP = game:GetService("StarterPlayer")
local SPS = SP:FindFirstChild("StarterPlayerScripts")

-- ── 1. archive legacy presentation + obsolete systems ───────────────────────
local archive = B.folder(SS, "SAE_Archive")
archive:SetAttribute("Note", "Pre-takeover content kept for reference. Disabled. Nothing here runs.")
local function disableScripts(root)
	local list = root:GetDescendants()
	table.insert(list, root)
	for _, d in list do
		if d:IsA("Script") or d:IsA("LocalScript") then
			pcall(function()
				d.Disabled = true
			end)
			pcall(function()
				d.Enabled = false
			end)
		end
	end
end
local function archiveInst(inst, bucket, why)
	if not inst then
		return
	end
	local folder = archive:FindFirstChild(bucket) or B.folder(archive, bucket)
	local path = inst:GetFullName()
	inst.Parent = folder
	disableScripts(inst)
	log("archived", { path = path, to = "ServerStorage.SAE_Archive." .. bucket, why = why })
end
-- legacy server systems (Muscle / BoxingBag / 6-zone runtime builder / old boss)
for _, n in { "Phase1Init", "FarmService", "PlayerStatsService", "TrainingService", "InspectionWorld", "AkazaBossController", "GiyuWaterEggAnimation" } do
	archiveInst(SSS:FindFirstChild(n), "LegacyServer", "replaced by SAE_Server services (Muscle/BoxingBag/6-zone obsolete)")
end
-- legacy client presentation (old nav incl. Rebirth, Muscle HUD, farm marker, Akaza-only FX)
for _, n in { "AnimeEggUiDesign", "MuscleHud", "FarmOwnershipClient", "AkazaLocalAtmosphere", "AkazaZoneVFX" } do
	archiveInst(SPS:FindFirstChild(n), "LegacyClient", "replaced by SAE_Client (UI Lab UI, ZoneFx, no Rebirth)")
end
for _, n in { "AnimeEggUI", "ScreenGui" } do
	archiveInst(SG:FindFirstChild(n), "LegacyUI", "legacy ScreenGui (basic UI / Muscle HUD / NavStack)")
end
archiveInst(RS:FindFirstChild("GameConfig"), "LegacyShared", "Muscle/Strength config superseded by SAE_Shared.Balance")

-- ── 2. character rigs (real DS models sanitized; others original stand-ins) ──
local assets = B.folder(SS, "SAE_Assets")
local rigFolder = B.folder(assets, "CharacterRigs")
local preview = B.folder(RS, "SAE_Preview")
local previewRigs = B.folder(preview, "Rigs")
local previewEggs = B.folder(preview, "Eggs")
local existingRigName = {}
for charId, c in Worlds.CHARACTERS do
	if c.existingModel then
		existingRigName[charId] = c.existingModel
	end
end
local rigs = {}
for _, charId in Worlds.characterList() do
	local c = Worlds.CHARACTERS[charId]
	local rig
	if existingRigName[charId] and ws:FindFirstChild(existingRigName[charId]) then
		local src = ws:FindFirstChild(existingRigName[charId])
		rig = src:Clone()
		rig.Name = charId
		Rigs.sanitize(rig, report.importAudit, c.name .. " (existing R6 model in Last CP" .. (c.asset and (", asset " .. c.asset) or "") .. ")")
		-- normalise to origin (HRP at y=3 like stand-ins)
		local hrp = rig:FindFirstChild("HumanoidRootPart")
		if hrp then
			B.translate(rig, V3(0, 3, 0) - hrp.CFrame.Position)
		end
		for _, d in rig:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = false
			end
		end
		rig:SetAttribute("CharacterId", charId)
		rig:SetAttribute("Source", "LastCP:" .. existingRigName[charId])
	else
		rig = Rigs.standIn(charId, c.name, c.rig)
		table.insert(report.standIns, { characterId = charId, name = c.name, knownAsset = c.asset })
	end
	rig.Parent = rigFolder
	rigs[charId] = rig
	local p = Rigs.previewCopy(rig)
	p.Parent = previewRigs
end
-- the original display models are now sourced into the rig library → archive them
for _, n in { "Muzan", "Rengoku", "Tanjiro Kamado", "Akaza", "Yoriichi" } do
	archiveInst(ws:FindFirstChild(n), "LegacyDisplayModels", "hub display models; copies live in SAE_Assets.CharacterRigs")
end

-- vendors (not hatchable; §94, §101). Original stand-ins until real models are imported.
local vendors = {
	makima = Rigs.standIn("Makima", "Makima", { skin = "#F7DDD0", top = "#F4F4F4", bottom = "#1B1B2A", hair = "#C0504D", hairStyle = "ponytail", eyes = "#FFD23F", belt = "#1B1B2A" }),
	seller = Rigs.standIn("Rem", "Rem", { skin = "#F7DDD0", top = "#1B1B2A", bottom = "#1B1B2A", hair = "#6FA8FF", hairStyle = "short", belt = "#F4F4F4" }),
}
report.vendors = { trailShop = "Makima (stand-in)", sell = "Rem — Re:Zero (stand-in; not in the 45 hatchable roster)" }

-- ── 3. hub / farm safe zone ──────────────────────────────────────────────────
local proto = ws:FindFirstChild("FarmHubVisualPrototype")
assert(proto, "baseline FarmHubVisualPrototype missing")
local sae = B.model(ws, "SAE_World")
local oldRoute = proto:FindFirstChild("SixZoneRoute")
local zone1 = oldRoute and oldRoute:FindFirstChild("Zone1")
local hub = Hub.build(ws, proto, Layout, report, vendors)
log("created", "Workspace.SAE_World.Hub (7 farms, perimeter fence, treadmills, signs, TrailShop, SellKiosk, FogGate)")

-- ── 4. worlds ────────────────────────────────────────────────────────────────
local worldsFolder = B.folder(sae, "Worlds")
local worldModels = {}
for index, worldId in Worlds.ORDER do
	local m = B.model(worldsFolder, worldId)
	m:SetAttribute("WorldIndex", index)
	m:SetAttribute("WorldName", Worlds.WORLDS[worldId].name)
	m:SetAttribute("LightingProfile", Worlds.WORLDS[worldId].lighting)
	m:SetAttribute("ZoneMinZ", Layout.worldZ0(index) - (index == 1 and 5 or 30))
	m:SetAttribute("ZoneMaxZ", Layout.worldZ0(index) + Layout.WORLD_LENGTH)
	worldModels[worldId] = m
	B.folder(m, "Eggs")
end
-- 4a. Demon Slayer: keep the approved Akaza world, widen ×1.5
do
	local m = worldModels.DemonSlayer
	local env = zone1:FindFirstChild("BlenderEnvironment")
	env.Parent = m
	env.Name = "Environment"
	local w = {}
	DS.widen(env, w)
	report.demonSlayerWiden = w
	DS.decorate(m, Layout)
	local akaza = zone1:FindFirstChild("Akaza")
	Rigs.sanitize(akaza, report.importAudit, "Akaza boss (Last CP Zone1, scaled 2.7, asset 17831588851)")
	akaza.Name = "Boss"
	akaza.Parent = m
	for k, v in { ZoneHalfWidth = 76, WalkWidth = 122, WallClearWidth = 150 } do
		m:SetAttribute(k, v)
	end
	log("moved", "FarmHubVisualPrototype.SixZoneRoute.Zone1.BlenderEnvironment → SAE_World.Worlds.DemonSlayer.Environment (widened ×1.5)")
end
-- 4b. the 8 new worlds
for index, worldId in Worlds.ORDER do
	if worldId ~= "DemonSlayer" then
		local ctx = Kit.new(worldModels[worldId], worldId, index, Layout, Worlds)
		Themes[worldId](ctx, Layout, Worlds)
		log("created", "Workspace.SAE_World.Worlds." .. worldId)
	end
end
-- the remaining prototype (old 6-zone placeholders, zone labels) → archive
archiveInst(proto, "LegacyWorld", "6-zone placeholder route (obsolete, §24) + old hub leftovers")

-- ── 5. egg spawns: 45 character-specific eggs ───────────────────────────────
local oei = ws:FindFirstChild("OfficialEggInspection")
local raw = oei and oei:FindFirstChild("RawAssets")
local giyu = ws:FindFirstChild("Egg_Giyu_Water")
local giyuMin = giyu and select(1, B.bounds(giyu))
local eggCount = 0
for eggId, egg in Worlds.EGGS do
	local spec = Worlds.EGG_VISUALS[egg.character]
	local spawn = B.model(worldModels[egg.world]:FindFirstChild("Eggs"), egg.spawnName)
	spawn:SetAttribute("EggId", eggId)
	spawn:SetAttribute("CharacterId", egg.character)
	spawn:SetAttribute("IsBossEgg", egg.isBossEgg)
	local visual
	if spec.approvedAsset then
		local src = raw and raw:FindFirstChild(spec.approvedAsset)
		assert(src, "approved Demon Slayer egg missing: " .. spec.approvedAsset)
		src.Name = "Visual"
		src.Parent = spawn -- unchanged visuals (§31)
		visual = src
		spawn:SetAttribute("ApprovedAsset", spec.approvedAsset)
		log("moved", "OfficialEggInspection.RawAssets['" .. spec.approvedAsset .. "'] → " .. egg.world .. ".Eggs." .. egg.spawnName .. ".Visual (unchanged)")
	else
		visual = EggPipeline.build(egg.character, spec)
		local x, z = Layout.eggPosition(eggId)
		local baseY = 1.45
		if egg.world == "DemonSlayer" then
			baseY = giyuMin and giyuMin.Y or 1.6
		end
		B.translate(visual, V3(x, baseY, z))
		visual.Parent = spawn
	end
	local mn, mx = B.bounds(visual)
	local center = (mn + mx) / 2
	local anchor = B.part(spawn, "PromptAnchor", V3(2, 2, 2), CF(center), "#FFFFFF", "SmoothPlastic", { transparency = 1 })
	anchor.CanQuery = false
	-- preview copy for UI (Eggs menu, hatch reveal) centred at origin
	local pv = visual:Clone()
	pv.Name = eggId
	B.translate(pv, V3(-center.X, -mn.Y, -center.Z))
	for _, d in pv:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		elseif d:IsA("ParticleEmitter") or d:IsA("Light") then
			d:Destroy()
		end
	end
	pv.Parent = previewEggs
	eggCount += 1
end
report.eggSpawns = eggCount
-- remaining inspection content + unused DS egg variants → archive (preserved, incl. Giyu §31)
archiveInst(giyu, "PreservedEggs", "Giyu Water egg + VFX — preserved, not in the active Demon Slayer 5 (§31)")
archiveInst(oei, "PreservedEggs", "egg inspection area (Shinobu/Gyomei/Mitsuri variants, scale reference)")
for _, d in ws:GetChildren() do
	if string.match(d.Name, "^Muzan_Corrupted_Egg") then
		archiveInst(d, "PreservedEggs", "alternative Muzan egg (not the approved central set)")
	end
end

-- ── 6. bosses for worlds 2–9 (stand-in rigs until real models are imported) ──
for index, worldId in Worlds.ORDER do
	if worldId ~= "DemonSlayer" then
		local charId = Worlds.WORLDS[worldId].boss
		local boss = rigs[charId]:Clone()
		boss.Name = "Boss"
		local hx, hz = Layout.bossHome(worldId)
		B.translate(boss, V3(hx, 3.6, hz))
		for _, d in boss:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true -- BossService unanchors after scaling at runtime
			end
		end
		boss.Parent = worldModels[worldId]
	end
end

-- ── 7. scripts: shared / server / client from game/src ───────────────────────
local function addScripts(dir, parent)
	for _, file in fs.readDir(dir) do
		local path = dir .. "/" .. file
		if fs.isFile(path) and string.match(file, "%.lua$") then
			local name, kind = file, "ModuleScript"
			if string.match(file, "%.server%.lua$") then
				name, kind = string.gsub(file, "%.server%.lua$", ""), "Script"
			elseif string.match(file, "%.client%.lua$") then
				name, kind = string.gsub(file, "%.client%.lua$", ""), "LocalScript"
			else
				name = string.gsub(file, "%.lua$", "")
			end
			local s = R.Instance.new(kind)
			s.Name = name
			s.Source = fs.readFile(path)
			s.Parent = parent
		end
	end
end
local sharedFolder = B.folder(RS, "SAE_Shared")
addScripts("game/src/shared", sharedFolder)
local serverFolder = B.folder(SSS, "SAE_Server")
addScripts("game/src/server", serverFolder)
if fs.isDir("game/src/client") then
	local clientFolder = B.folder(SPS, "SAE_Client")
	addScripts("game/src/client", clientFolder)
end
log("created", "ReplicatedStorage.SAE_Shared, ServerScriptService.SAE_Server, StarterPlayerScripts.SAE_Client")

-- ── 8. production UI (built from the UI Lab by tools/build-prod.js) ──────────
if fs.isFile(UI_MODEL) then
	local models = R.deserializeModel(fs.readFile(UI_MODEL))
	for _, m in models do
		m.Parent = SG
	end
	log("created", "StarterGui.SAE_UI (production UI from the UI Lab)")
else
	table.insert(report.warnings, "production UI model not found (" .. UI_MODEL .. ") — run tools/build-prod.js first")
end

-- ── 9. settings ──────────────────────────────────────────────────────────────
local players = game:GetService("Players")
local okMax = pcall(function()
	players.MaxPlayers = 7
end)
report.maxPlayersSetInFile = okMax
local lighting = game:GetService("Lighting")
pcall(function()
	lighting.TimeOfDay = "13:30:00"
end)
ws:SetAttribute("SAE_Build", "FullProduction_OwnerReview_v01")

-- ── 10. write ────────────────────────────────────────────────────────────────
local count = #game:GetDescendants()
fs.writeFile(OUT, R.serializePlace(game, true))
report.output = OUT
report.instanceCount = count
report.partsCreatedByBuilders = B.stats.parts
if not fs.isDir("docs/generated") then fs.writeDir("docs/generated") end
fs.writeFile("docs/generated/ASSEMBLY_REPORT.json", serde.encode("json", report, true))
print(string.format("[assembler] wrote %s  (%d instances, %d builder parts, %d egg spawns, %d stand-in rigs)", OUT, count, B.stats.parts, eggCount, #report.standIns))
for _, w in report.warnings do
	print("  WARN " .. w)
end
