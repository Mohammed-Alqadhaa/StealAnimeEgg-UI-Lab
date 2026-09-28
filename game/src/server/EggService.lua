--[[
	EggService — server-authoritative world-egg lifecycle (§53–§61, §116, §119).

	SPAWN → AVAILABLE → PICKED_UP → CARRIED_UNSAFE → (DROPPED | RETURNED)
	      → FARM_SAFE_ZONE_ENTRY → SECURED (profile egg, HATCHING)

	* 45 permanent character-specific spawns (§53, §140): baked models at
	  SAE_World.Worlds.<World>.Eggs.<SpawnName> with attribute EggId. A spawn always
	  holds the same character's egg.
	* One egg carried at a time (§56).
	* Securing is detected HERE, server-side, the moment the carrier's root is inside the
	  Farm Safe Zone rectangle (§59, §60). No remote can secure an egg (§123).
	* Once secured an egg is profile data: it can't be dropped, stolen or knocked loose.
	* Dropped eggs remain DroppedEggSeconds (PROVISIONAL 30 s) then return to their spawn.
	* Every time a world egg becomes available it gets a fresh instance uid, which is the
	  key used when securing → the same instance can never be secured twice (§159).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Worlds = require(Shared.Worlds)
local Layout = require(Shared.Layout)
local Balance = require(Shared.Balance)
local Profile = require(Shared.Profile)

local EggService = {}

local DataService, Remotes, RoundService -- injected
local records = {} -- [eggId] = record
local carrying = {} -- [player] = record
local hiddenFolder
local pickedUpListeners = {}
local resolvedListeners = {} -- fired when a carrier stops carrying (secured/dropped/returned)

local STATE = { AVAILABLE = "AVAILABLE", CARRIED = "CARRIED_UNSAFE", DROPPED = "DROPPED", TAKEN = "SECURED" }

local function newUid(): string
	return HttpService:GenerateGUID(false)
end

local function rootOf(player: Player): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function setCarryAttributes(player: Player, rec)
	if rec then
		player:SetAttribute("CarryEggId", rec.eggId)
		player:SetAttribute("CarryState", "UNSAFE")
		player:SetAttribute("CarryWorld", Worlds.EGGS[rec.eggId].world)
	else
		player:SetAttribute("CarryEggId", nil)
		player:SetAttribute("CarryState", nil)
		player:SetAttribute("CarryWorld", nil)
	end
end

-- Prepare a copy of an egg visual for carrying / dropping: unanchored, massless, no collision.
local function cloneVisual(rec, anchored: boolean): Model
	local copy = rec.visualTemplate:Clone()
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = anchored
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		elseif d:IsA("ProximityPrompt") or d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	return copy
end

local function weldAll(model: Model, to: BasePart)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local w = Instance.new("WeldConstraint")
			w.Part0 = to
			w.Part1 = d
			w.Parent = d
		end
	end
end

local function showSpawn(rec, visible: boolean)
	if visible then
		rec.visual.Parent = rec.spawn
	else
		rec.visual.Parent = hiddenFolder
	end
	rec.prompt.Enabled = visible
end

local function clearCarry(rec)
	if rec.carryModel then
		rec.carryModel:Destroy()
		rec.carryModel = nil
	end
	if rec.carrier then
		carrying[rec.carrier] = nil
		setCarryAttributes(rec.carrier, nil)
		for _, fn in resolvedListeners do
			task.spawn(fn, rec.carrier, rec.eggId)
		end
	end
	rec.carrier = nil
end

local function clearDrop(rec)
	if rec.dropModel then
		rec.dropModel:Destroy()
		rec.dropModel = nil
	end
	rec.dropToken = nil
end

-- back to its permanent spawn, fresh instance uid
local function returnToSpawn(rec, reason: string?)
	clearCarry(rec)
	clearDrop(rec)
	rec.state = STATE.AVAILABLE
	rec.uid = newUid()
	showSpawn(rec, true)
	if reason then
		rec.spawn:SetAttribute("LastReturnReason", reason)
	end
end

local function canPickUp(player: Player, rec, fromPosition: Vector3): (boolean, string?)
	if RoundService and not RoundService.IsOpen() then
		return false, "Round is resetting"
	end
	if carrying[player] then
		return false, "You can only carry ONE egg"
	end
	local root = rootOf(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return false, "no character"
	end
	if (root.Position - fromPosition).Magnitude > Balance.EggPickupDistance + 4 then
		return false, "too far"
	end
	if rec.state ~= STATE.AVAILABLE and rec.state ~= STATE.DROPPED then
		return false, "egg not available"
	end
	return true
end

local function attachCarry(player: Player, rec)
	local char = player.Character
	local head = char and char:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local model = cloneVisual(rec, false)
	model.Name = "CarriedEgg"
	pcall(function()
		model:ScaleTo(0.55)
	end)
	model:PivotTo(head.CFrame * CFrame.new(0, 3.2, 0))
	weldAll(model, head)
	model.Parent = char
	rec.carryModel = model
end

local function pickUp(player: Player, rec, fromPosition: Vector3)
	local ok, why = canPickUp(player, rec, fromPosition)
	if not ok then
		if why and why ~= "too far" then
			Remotes.notify(player, "warn", why)
		end
		return
	end
	if rec.state == STATE.AVAILABLE then
		showSpawn(rec, false)
	else
		clearDrop(rec)
	end
	rec.state = STATE.CARRIED
	rec.carrier = player
	carrying[player] = rec
	attachCarry(player, rec)
	setCarryAttributes(player, rec)
	Remotes.fire(player, "EggFx", "PICKED_UP", { eggId = rec.eggId })
	for _, fn in pickedUpListeners do
		task.spawn(fn, player, rec.eggId, Worlds.EGGS[rec.eggId].world)
	end
end

local function makePrompt(parent: Instance, text: string, holdSeconds: number): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EggPrompt"
	prompt.ActionText = text
	prompt.HoldDuration = holdSeconds
	prompt.MaxActivationDistance = Balance.EggPickupDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = parent
	return prompt
end

-- ── public API ──────────────────────────────────────────────────────────────
function EggService.Init()
	hiddenFolder = Instance.new("Folder")
	hiddenFolder.Name = "SAE_HiddenEggs"
	hiddenFolder.Parent = ServerStorage
	local worldsFolder = workspace:WaitForChild("SAE_World"):WaitForChild("Worlds")
	for eggId, egg in Worlds.EGGS do
		local worldModel = worldsFolder:WaitForChild(egg.world, 30)
		local eggsFolder = worldModel and worldModel:WaitForChild("Eggs", 30)
		local spawn = eggsFolder and eggsFolder:WaitForChild(egg.spawnName, 30)
		if not spawn then
			warn("[Egg] missing spawn " .. egg.spawnName .. " in " .. egg.world)
			continue
		end
		local visual = spawn:FindFirstChild("Visual")
		local anchor = spawn:FindFirstChild("PromptAnchor") or spawn:FindFirstChild("Pad")
		assert(visual and anchor, egg.spawnName .. " needs Visual + PromptAnchor")
		local rec = {
			eggId = eggId,
			spawn = spawn,
			visual = visual,
			visualTemplate = visual:Clone(),
			state = STATE.AVAILABLE,
			uid = newUid(),
		}
		local character = Worlds.CHARACTERS[egg.character]
		rec.prompt = makePrompt(anchor, "STEAL " .. string.upper(character.name) .. " EGG", Balance.EggPickupHoldSeconds)
		rec.prompt.ObjectText = Worlds.WORLDS[egg.world].name
		rec.prompt.Triggered:Connect(function(player)
			pickUp(player, rec, anchor.Position)
		end)
		records[eggId] = rec
	end
end

function EggService.Start(deps)
	DataService, Remotes, RoundService = deps.DataService, deps.Remotes, deps.RoundService

	Remotes.onEvent("RequestDropEgg", function(player)
		EggService.Drop(player, "manual")
	end)

	local function hookCharacter(player: Player, char: Model)
		local hum = char:WaitForChild("Humanoid", 10)
		if hum then
			hum.Died:Connect(function()
				if carrying[player] then
					EggService.Drop(player, "died")
				end
			end)
		end
	end
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function(c)
			hookCharacter(p, c)
		end)
	end)
	for _, p in Players:GetPlayers() do
		p.CharacterAdded:Connect(function(c)
			hookCharacter(p, c)
		end)
		if p.Character then
			task.spawn(hookCharacter, p, p.Character)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		local rec = carrying[player]
		if rec then
			returnToSpawn(rec, "carrier left")
		end
	end)

	-- Farm Safe Zone detection (§59): 10 Hz server check of every carrier.
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		acc = 0
		for player, rec in carrying do
			local root = rootOf(player)
			if root and Layout.isInSafeZone(root.Position.X, root.Position.Y, root.Position.Z) then
				EggService.Secure(player, rec)
			end
		end
	end)
end

-- Server-only: called by the safe-zone loop above. Never reachable from a remote.
function EggService.Secure(player: Player, rec)
	if carrying[player] ~= rec or rec.state ~= STATE.CARRIED then
		return
	end
	local instanceUid = rec.uid
	local ok = DataService.mutate(player, function(p)
		return Profile.secureEgg(p, rec.eggId, instanceUid, DataService.Now())
	end)
	if not ok then
		-- profile not loaded / already secured: never duplicate, put the egg back
		returnToSpawn(rec, "secure failed")
		return
	end
	rec.state = STATE.TAKEN
	clearCarry(rec)
	player:SetAttribute("CarryState", "SECURED")
	task.delay(2.5, function()
		if player.Parent and not carrying[player] and player:GetAttribute("CarryState") == "SECURED" then
			player:SetAttribute("CarryState", nil)
		end
	end)
	Remotes.fire(player, "EggFx", "SECURED", { eggId = rec.eggId, uid = instanceUid })
end

-- Drop at/near the carrier (manual, PvP bat, boss catch outside its world, death).
function EggService.Drop(player: Player, reason: string): boolean
	local rec = carrying[player]
	if not rec or rec.state ~= STATE.CARRIED then
		return false
	end
	local root = rootOf(player)
	local pos = root and root.Position or rec.spawn:GetPivot().Position
	if Layout.isInSafeZone(pos.X, pos.Y, pos.Z) then
		return false -- secured eggs can't be dropped (the secure loop will catch this carrier)
	end
	clearCarry(rec)
	local model = cloneVisual(rec, true)
	model.Name = "DroppedEgg_" .. rec.eggId
	local groundCF = CFrame.new(pos.X, pos.Y - 1.5, pos.Z)
	model:PivotTo(groundCF)
	local anchor = Instance.new("Part")
	anchor.Name = "PromptAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(2, 2, 2)
	anchor.CFrame = groundCF
	anchor.Parent = model
	local character = Worlds.CHARACTERS[Worlds.EGGS[rec.eggId].character]
	local prompt = makePrompt(anchor, "GRAB " .. string.upper(character.name) .. " EGG", 0.25)
	prompt.Triggered:Connect(function(p)
		pickUp(p, rec, anchor.Position)
	end)
	model:SetAttribute("ExpiresAt", DataService.Now() + Balance.DroppedEggSeconds)
	model.Parent = workspace:FindFirstChild("SAE_World") or workspace
	rec.dropModel = model
	rec.state = STATE.DROPPED
	local token = newUid()
	rec.dropToken = token
	task.delay(Balance.DroppedEggSeconds, function()
		if rec.dropToken == token and rec.state == STATE.DROPPED then
			returnToSpawn(rec, "drop expired")
		end
	end)
	Remotes.fire(player, "EggFx", "DROPPED", { eggId = rec.eggId, reason = reason })
	return true
end

-- Boss caught the carrier inside the boss's own world (§111): egg back to its spawn.
function EggService.ReturnCarried(player: Player, reason: string): boolean
	local rec = carrying[player]
	if not rec then
		return false
	end
	returnToSpawn(rec, reason)
	Remotes.fire(player, "EggFx", "RETURNED", { eggId = rec.eggId, reason = reason })
	return true
end

-- Round end (§119): every unsafe / dropped / taken world egg is restored.
function EggService.ResetAll()
	for _, rec in records do
		returnToSpawn(rec, "round reset")
	end
end

function EggService.IsCarrying(player: Player): boolean
	return carrying[player] ~= nil
end

function EggService.GetCarriers(): { { player: Player, eggId: string, worldId: string, position: Vector3 } }
	local list = {}
	for player, rec in carrying do
		local root = rootOf(player)
		if root then
			table.insert(list, { player = player, eggId = rec.eggId, worldId = Worlds.EGGS[rec.eggId].world, position = root.Position })
		end
	end
	return list
end

function EggService.OnPickedUp(fn)
	table.insert(pickedUpListeners, fn)
end

function EggService.OnResolved(fn)
	table.insert(resolvedListeners, fn)
end

function EggService.Count(): number
	local n = 0
	for _ in records do
		n += 1
	end
	return n
end

return EggService
