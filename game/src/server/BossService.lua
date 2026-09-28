--[[
	BossService — one server-authoritative boss per world (§105–§113, §33, §35, §46).

	State machine:  IDLE/PRESENTATION → REACTION → CHASE → (HIT | ESCAPED) → RETURN → IDLE
	* Triggered when ANY egg of the boss's world is picked up (§107).
	* Reaction delay: Akaza 1.0 s (Owner baseline); others configurable (§108).
	* Target = carrier of this world's eggs closest to the Farm Safe Zone; re-evaluated
	  every decision and after every resolution (§113). One boss, never per-player clones.
	* Catch inside the boss's own world → egg returns to its spawn + moderate knockback
	  (§111). Catch after the carrier left the world but before the safe zone → egg drops
	  at the player, boss returns home (§112). Safe zone → untouchable.
	* Seated bosses (Shigaraki, Yhwach, Sung Jin-Woo) start in a throne pose and rise
	  when the chase starts (§35, §46, §50).
	* Bosses never enter the Farm Safe Zone; they stop at the hub fence.
	* ONE shared loop at BossDecisionHz drives all bosses; IDLE bosses are dormant.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Worlds = require(Shared.Worlds)
local Layout = require(Shared.Layout)
local Balance = require(Shared.Balance)
local BossLogic = require(Shared.BossLogic)
local Animations = require(Shared.Animations)

local BossService = {}

-- presentation per world (PROVISIONAL scales; Akaza's 2.7 was set by the Owner's tests)
local PRESENTATION = {
	DemonSlayer = { scale = 2.7, alreadyScaled = true },
	MHA = { scale = 1.35, seated = true },
	DragonBall = { scale = 1.9 },
	OnePiece = { scale = 2.0 },
	Naruto = { scale = 2.0 },
	Berserk = { scale = 2.1 },
	Bleach = { scale = 2.2, seated = true },
	JJK = { scale = 2.2 },
	SoloLeveling = { scale = 2.0, seated = true },
}
BossService.PRESENTATION = PRESENTATION

local deps
local bosses = {} -- [worldId] = state

local function now(): number
	return os.clock()
end

local function loadTrack(hum: Humanoid, id: string): AnimationTrack?
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local a = Instance.new("Animation")
	a.AnimationId = id
	local ok, t = pcall(function()
		return animator:LoadAnimation(a)
	end)
	return ok and t or nil
end

local function hipJoints(model: Model)
	local torso = model:FindFirstChild("Torso")
	if not torso then
		return nil
	end
	local r, l = torso:FindFirstChild("Right Hip"), torso:FindFirstChild("Left Hip")
	if r and l and r:IsA("Motor6D") and l:IsA("Motor6D") then
		return r, l
	end
	return nil
end

local function setSeated(b, seated: boolean)
	b.seated = seated
	local r, l = hipJoints(b.model)
	if r and l then
		if seated then
			r.C0 = b.hipC0.r * CFrame.Angles(0, 0, math.rad(80))
			l.C0 = b.hipC0.l * CFrame.Angles(0, 0, -math.rad(80))
		else
			r.C0, l.C0 = b.hipC0.r, b.hipC0.l
		end
	end
	b.root.Anchored = seated
	if seated then
		b.model:PivotTo(b.homeCF * CFrame.new(0, -b.seatDrop, 0))
	end
end

local function playState(b)
	if not b.tracks then
		return
	end
	local moving = b.state == "CHASE" or b.state == "RETURN"
	if moving then
		if b.tracks.idle and b.tracks.idle.IsPlaying then
			b.tracks.idle:Stop(0.2)
		end
		if b.tracks.run and not b.tracks.run.IsPlaying then
			b.tracks.run.Looped = true
			b.tracks.run:Play(0.15)
			b.tracks.run:AdjustSpeed(1.3)
		end
	else
		if b.tracks.run and b.tracks.run.IsPlaying then
			b.tracks.run:Stop(0.25)
		end
		if b.tracks.idle and not b.tracks.idle.IsPlaying and not b.seated then
			b.tracks.idle.Looped = true
			b.tracks.idle:Play(0.3)
		end
	end
end

local function setState(b, state: string)
	b.state = state
	b.model:SetAttribute("BossState", state)
	playState(b)
end

local function knockback(player: Player, fromPos: Vector3)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local dir = root.Position - fromPos
	dir = Vector3.new(dir.X, 0, dir.Z)
	dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 0, -1)
	deps.Remotes.fire(player, "Knockback", dir * Balance.KnockbackStuds * 2.2 + Vector3.new(0, Balance.KnockbackUpward, 0))
end

local function carriersList()
	local list = {}
	for _, c in deps.EggService.GetCarriers() do
		table.insert(
			list,
			{ id = c.player, x = c.position.X, z = c.position.Z, worldOfEgg = c.worldId, secured = false, player = c.player, position = c.position }
		)
	end
	return list
end

local function goHome(b)
	b.target = nil
	setState(b, "RETURN")
	b.hum:MoveTo(b.homeCF.Position)
end

local function reset(b)
	b.target = nil
	b.root.Anchored = false
	b.model:PivotTo(b.homeCF)
	setState(b, "IDLE")
	if b.presentation.seated then
		setSeated(b, true)
	end
end

local function onEggTaken(worldId: string)
	local b = bosses[worldId]
	if not b then
		return
	end
	if b.state == "IDLE" or b.state == "RETURN" then
		b.reactAt = now() + (Balance.BossReactionByWorld[worldId] or Balance.BossReactionSeconds)
		setState(b, "REACTION")
		b.model:SetAttribute("Alert", true)
	end
end

local function tick(b)
	local t = now()
	if b.state == "IDLE" then
		return
	end
	if b.state == "REACTION" then
		if t >= b.reactAt then
			if b.seated then
				setSeated(b, false)
			end
			b.model:SetAttribute("Alert", false)
			setState(b, "CHASE")
		end
		return
	end
	if b.state == "RETURN" then
		local target = BossLogic.pickTarget(b.worldId, carriersList())
		if target then
			setState(b, "CHASE")
			return
		end
		if (b.root.Position - b.homeCF.Position).Magnitude < 5 then
			b.model:PivotTo(b.homeCF)
			setState(b, "IDLE")
			if b.presentation.seated then
				setSeated(b, true)
			end
		else
			b.hum:MoveTo(b.homeCF.Position)
		end
		return
	end
	-- CHASE
	local carriers = carriersList()
	local target = BossLogic.pickTarget(b.worldId, carriers)
	if not target then
		goHome(b)
		return
	end
	local pos = target.position
	if BossLogic.shouldGiveUp(b.worldId, b.root.Position.Z, pos.Z, Balance.BossGiveUpDistance) then
		goHome(b)
		return
	end
	-- never step into the Farm Safe Zone: clamp the goal just outside the north fence
	local goal = Vector3.new(pos.X, pos.Y, math.max(pos.Z, Layout.SAFE_MAX.z + 6))
	b.hum:MoveTo(goal)
	local flat = Vector3.new(pos.X - b.root.Position.X, 0, pos.Z - b.root.Position.Z).Magnitude
	local reach = Balance.BossHitRange * math.max(1, b.presentation.scale * 0.6)
	if flat <= reach and t - (b.lastHit or 0) >= Balance.BossHitCooldown then
		b.lastHit = t
		local player = target.player
		local outcome = BossLogic.catchOutcome(b.worldId, pos.X, pos.Y, pos.Z)
		if outcome == "RETURN_EGG" then
			deps.EggService.ReturnCarried(player, b.worldId .. " boss caught you")
			knockback(player, b.root.Position)
			deps.Remotes.notify(player, "danger", Worlds.CHARACTERS[Worlds.WORLDS[b.worldId].boss].name .. " took the egg back!")
		elseif outcome == "DROP_EGG" then
			deps.EggService.Drop(player, "boss")
			knockback(player, b.root.Position)
			deps.Remotes.notify(player, "danger", "You dropped the egg!")
			goHome(b)
		end
	end
end

function BossService.Start(d)
	deps = d
	local worldsFolder = workspace:WaitForChild("SAE_World"):WaitForChild("Worlds")
	for _, worldId in Worlds.ORDER do
		local worldModel = worldsFolder:WaitForChild(worldId, 30)
		local model = worldModel and worldModel:WaitForChild("Boss", 30)
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		local root = model and model:FindFirstChild("HumanoidRootPart")
		if not (model and hum and root) then
			warn("[Boss] missing boss rig for " .. worldId)
			continue
		end
		local pres = PRESENTATION[worldId]
		if not pres.alreadyScaled and pres.scale ~= 1 then
			pcall(function()
				model:ScaleTo(pres.scale)
			end)
		end
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = false
				p.CanTouch = false
			end
		end
		hum.WalkSpeed = Balance.BossWalkSpeedByWorld[Worlds.WORLDS[worldId].index]
		hum.AutoRotate = true
		hum.BreakJointsOnDeath = false
		hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		local hx, hz = Layout.bossHome(worldId)
		local _, size = model:GetBoundingBox()
		local homeCF = CFrame.lookAt(Vector3.new(hx, size.Y / 2 + 0.6, hz), Vector3.new(hx, size.Y / 2 + 0.6, hz - 10))
		local r, l = hipJoints(model)
		local b = {
			worldId = worldId,
			model = model,
			hum = hum,
			root = root,
			homeCF = homeCF,
			presentation = pres,
			state = "IDLE",
			hipC0 = r and { r = r.C0, l = l.C0 } or {},
			seatDrop = size.Y * 0.18,
			characterId = Worlds.WORLDS[worldId].boss,
		}
		b.tracks = {
			idle = loadTrack(hum, Animations.get("idle", b.characterId, true)),
			run = loadTrack(hum, Animations.get("run", b.characterId, true)),
		}
		model:SetAttribute("BossOf", worldId)
		bosses[worldId] = b
		reset(b)
	end
	d.EggService.OnPickedUp(function(_, _, worldId)
		onEggTaken(worldId)
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1 / Balance.BossDecisionHz then
			return
		end
		acc = 0
		for _, b in bosses do
			if b.state ~= "IDLE" then
				local ok, err = pcall(tick, b)
				if not ok then
					warn("[Boss] " .. b.worldId .. ": " .. tostring(err))
					reset(b)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function()
		-- targets are re-picked every decision; nothing to clean up
	end)
end

function BossService.ResetAll()
	for _, b in bosses do
		reset(b)
	end
end

function BossService.Count(): number
	local n = 0
	for _ in bosses do
		n += 1
	end
	return n
end

return BossService
