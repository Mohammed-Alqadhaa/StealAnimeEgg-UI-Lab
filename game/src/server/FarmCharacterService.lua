--[[
	FarmCharacterService — equipped units walk around their owner's farm (§75).

	* One rig per EQUIPPED unit, parented under Farm<N>.Characters.
	* ONE shared low-frequency loop drives all rigs (no per-rig Heartbeat, no Pathfinding):
	  each rig picks a random point inside its owner's plot every 3–7 s (PROVISIONAL) and
	  walks there with Humanoid:MoveTo. Rigs pushed out of the plot are put back.
	* Rigs never leave the owner's plot (targets are always inside plot bounds minus an
	  inset; plots don't overlap routes, hubs or worlds).
	* Collision group SAE_FarmNPC does not collide with players or each other, so
	  characters can never trap or block a player.
	* Idle/walk animations from Shared/Animations (R6 defaults unless overridden).
	* A small billboard shows name, level and $/sec.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Worlds = require(Shared.Worlds)
local Balance = require(Shared.Balance)
local Economy = require(Shared.Economy)
local Animations = require(Shared.Animations)

local FarmCharacterService = {}

local NPC_GROUP, PLAYER_GROUP = "SAE_FarmNPC", "SAE_Players"
local rigs = {} -- [player] = { [uid] = entry }
local rng = Random.new()
local FarmService, DataService

local function setupCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(NPC_GROUP)
		PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
	end)
	PhysicsService:CollisionGroupSetCollidable(NPC_GROUP, NPC_GROUP, false)
	PhysicsService:CollisionGroupSetCollidable(NPC_GROUP, PLAYER_GROUP, false)
	local function tagCharacter(char: Model)
		for _, d in char:GetDescendants() do
			if d:IsA("BasePart") then
				d.CollisionGroup = PLAYER_GROUP
			end
		end
		char.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then
				d.CollisionGroup = PLAYER_GROUP
			end
		end)
	end
	local function hook(p: Player)
		p.CharacterAdded:Connect(tagCharacter)
		if p.Character then
			tagCharacter(p.Character)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
end

local function rigTemplate(characterId: string): Model?
	local folder = ServerStorage:FindFirstChild("SAE_Assets")
	folder = folder and folder:FindFirstChild("CharacterRigs")
	return folder and folder:FindFirstChild(characterId) :: Model?
end

local function loadAnim(hum: Humanoid, id: string): AnimationTrack?
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	return ok and track or nil
end

local function billboard(model: Model, unit)
	local head = model:FindFirstChild("Head")
	if not head then
		return
	end
	local c = Worlds.CHARACTERS[unit.characterId]
	local gui = Instance.new("BillboardGui")
	gui.Name = "UnitTag"
	gui.Size = UDim2.fromOffset(160, 44)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 70
	gui.AlwaysOnTop = false
	gui.Parent = head
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, 0, 0.55, 0)
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.2
	name.Text = string.format("%s  Lv.%d", c.name, unit.level)
	name.Parent = gui
	local inc = Instance.new("TextLabel")
	inc.BackgroundTransparency = 1
	inc.Position = UDim2.fromScale(0, 0.55)
	inc.Size = UDim2.new(1, 0, 0.45, 0)
	inc.Font = Enum.Font.FredokaOne
	inc.TextScaled = true
	inc.TextColor3 = Color3.fromRGB(124, 255, 90)
	inc.TextStrokeTransparency = 0.2
	inc.Text = "$" .. Economy.format(Economy.incomeAt(unit.characterId, unit.level)) .. "/s"
	inc.Parent = gui
end

local function spawnRig(_player: Player, farmIndex: number, unit)
	local template = rigTemplate(unit.characterId)
	if not template then
		warn("[FarmChars] no rig for " .. unit.characterId)
		return nil
	end
	local farm = FarmService.GetFarm(farmIndex)
	local model = template:Clone()
	model.Name = unit.characterId .. "_" .. string.sub(unit.uid, 1, 8)
	model:SetAttribute("UnitUid", unit.uid)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not root then
		model:Destroy()
		return nil
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CollisionGroup = NPC_GROUP
			d.CanTouch = false
		end
	end
	local scale = Worlds.CHARACTERS[unit.characterId].rig.scale
	if scale and scale > 1.05 then
		pcall(function()
			model:ScaleTo(math.min(scale, 1.4)) -- keep farm characters readable, not giant
		end)
	end
	hum.WalkSpeed = Balance.WanderWalkSpeed
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	local folder = farm.model:FindFirstChild("Characters")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Characters"
		folder.Parent = farm.model
	end
	local start = FarmService.RandomPointInPlot(farmIndex, Balance.WanderPlotInset, rng)
	model:PivotTo(CFrame.new(start + Vector3.new(0, 3.2, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	model.Parent = folder
	pcall(function()
		root:SetNetworkOwner(nil) -- server simulates NPCs (authoritative, no client drift)
	end)
	billboard(model, unit)
	local idle = loadAnim(hum, Animations.get("idle", unit.characterId))
	local walk = loadAnim(hum, Animations.get("walk", unit.characterId))
	if idle then
		idle.Looped = true
		idle:Play()
	end
	hum.Running:Connect(function(speed)
		if not walk then
			return
		end
		if speed > 0.5 then
			if not walk.IsPlaying then
				walk.Looped = true
				walk:Play(0.2)
			end
			walk:AdjustSpeed(speed / 12)
		elseif walk.IsPlaying then
			walk:Stop(0.25)
		end
	end)
	return { model = model, hum = hum, root = root, farm = farmIndex, nextDecision = os.clock() + rng:NextNumber(0.5, 2) }
end

local function sync(player: Player)
	local p = DataService.Get(player)
	local farmIndex = FarmService.GetPlayerFarm(player)
	local mine = rigs[player] or {}
	rigs[player] = mine
	if not p or not farmIndex then
		for uid, e in mine do
			e.model:Destroy()
			mine[uid] = nil
		end
		return
	end
	local want = {}
	for _, uid in p.equipped do
		want[uid] = true
	end
	for uid, e in mine do
		local unit = p.units[uid]
		if not want[uid] or not unit or e.level ~= unit.level then
			e.model:Destroy()
			mine[uid] = nil
		end
	end
	for uid in want do
		if not mine[uid] then
			local unit = p.units[uid]
			local e = unit and spawnRig(player, farmIndex, unit)
			if e then
				e.level = unit.level
				mine[uid] = e
			end
		end
	end
end

function FarmCharacterService.Start(deps)
	FarmService, DataService = deps.FarmService, deps.DataService
	setupCollisionGroups()
	DataService.OnLoaded(function(player)
		sync(player)
	end)
	DataService.OnChanged(function(player)
		sync(player)
	end)
	FarmService.OnAssigned(function(player)
		sync(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		for _, e in rigs[player] or {} do
			e.model:Destroy()
		end
		rigs[player] = nil
	end)
	-- the ONE shared wander loop (4 Hz decisions)
	task.spawn(function()
		while true do
			task.wait(0.25)
			local t = os.clock()
			for _, mine in rigs do
				for _, e in mine do
					if e.model.Parent and e.root.Parent then
						if not FarmService.IsInsidePlot(e.farm, e.root.Position, 1) then
							local back = FarmService.RandomPointInPlot(e.farm, Balance.WanderPlotInset, rng)
							e.model:PivotTo(CFrame.new(back + Vector3.new(0, 3.2, 0)))
						elseif t >= e.nextDecision then
							local range = Balance.WanderDecisionSeconds
							e.nextDecision = t + rng:NextNumber(range[1], range[2])
							if rng:NextNumber() < 0.7 then
								e.hum:MoveTo(FarmService.RandomPointInPlot(e.farm, Balance.WanderPlotInset, rng))
							end
						end
					end
				end
			end
		end
	end)
end

return FarmCharacterService
