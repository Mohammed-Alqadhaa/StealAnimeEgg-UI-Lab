--[[
	TreadmillService — one treadmill per farm, owner-only training (§84–§91).

	Training requires ACTIVE use (§86): the farm owner's root must be inside the belt's
	training volume, the Humanoid must be moving (MoveDirection) and grounded. Standing
	next to the machine gives nothing. The belt is a real conveyor (anchored part with
	AssemblyLinearVelocity) so the runner has to keep running to stay on it.

	Gain per second comes from the owner's treadmill level (Balance, PROVISIONAL).

	Visual evolution (§89): the baked treadmill contains Tiers/Tier1..Tier10; every part
	carries TierMin (and optional TierMax, for pieces that are REPLACED by better ones).
	A level shows exactly the geometry for that level, so every upgrade changes the
	machine's silhouette / rails / core / rings / VFX — not just a number.

	Upgrade sign (§91): server ProximityPrompt on the sign; server validates farm
	ownership, level, cash and cost; updates model, VFX and sign.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Balance = require(Shared.Balance)
local Economy = require(Shared.Economy)
local Profile = require(Shared.Profile)

local TreadmillService = {}

local deps
local machines = {} -- [farmIndex] = { model, belt, zone, tiers, sign, prompt }
local training = {} -- [player] = true while training (read by MovementService)

local function signText(sign: Model, name: string, text: string)
	local label = sign:FindFirstChild(name, true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function applyLevel(m, level: number)
	m.model:SetAttribute("Level", level)
	for _, d in m.tiers:GetDescendants() do
		local holder = d:IsA("BasePart") and d or nil
		if holder then
			local minL = holder:GetAttribute("TierMin") or 1
			local maxL = holder:GetAttribute("TierMax") or math.huge
			local visible = level >= minL and level <= maxL
			holder.Transparency = visible and (holder:GetAttribute("BaseTransparency") or 0) or 1
			holder.CanCollide = visible and (holder:GetAttribute("Collide") == true)
			holder.CanQuery = visible
			for _, fx in holder:GetChildren() do
				if fx:IsA("ParticleEmitter") or fx:IsA("Beam") or fx:IsA("Light") or fx:IsA("Trail") then
					fx.Enabled = visible
				end
			end
		end
	end
end

local function refreshSign(farmIndex: number)
	local m = machines[farmIndex]
	if not m then
		return
	end
	local owner = deps.FarmService.GetOwner(farmIndex)
	local p = owner and deps.DataService.Get(owner)
	local level = p and p.treadmillLevel or 1
	applyLevel(m, level)
	if not p then
		signText(m.sign, "Title", "TREADMILL")
		signText(m.sign, "Level", "LEVEL 1")
		signText(m.sign, "Gain", "+" .. Economy.treadmillGain(1) .. " Speed/s")
		signText(m.sign, "Next", "Claim this farm")
		signText(m.sign, "Cost", "—")
		m.prompt.Enabled = false
		return
	end
	local cost = Economy.treadmillUpgradeCost(level)
	signText(m.sign, "Title", "TREADMILL")
	signText(m.sign, "Level", "LEVEL " .. level .. (cost and (" → " .. (level + 1)) or ""))
	signText(m.sign, "Gain", "+" .. Economy.format(Economy.treadmillGain(level)) .. " Speed/s")
	signText(m.sign, "Next", cost and ("NEXT +" .. Economy.format(Economy.treadmillGain(level + 1)) .. " Speed/s") or "MAX LEVEL")
	signText(m.sign, "Cost", cost and ("$" .. Economy.format(cost)) or "MAX")
	m.prompt.Enabled = cost ~= nil
	m.prompt.ActionText = cost and ("UPGRADE $" .. Economy.format(cost)) or "MAX LEVEL"
end

function TreadmillService.Upgrade(player: Player): boolean
	local farmIndex = deps.FarmService.GetPlayerFarm(player)
	if not farmIndex then
		return false
	end
	local ok, result = deps.DataService.mutate(player, function(p)
		return Profile.upgradeTreadmill(p)
	end)
	if ok then
		deps.Remotes.notify(
			player,
			"ok",
			string.format("Treadmill Level %d!  +%s Speed/s", result.level, Economy.format(result.gain)),
			{ kind = "treadmill", level = result.level }
		)
	else
		deps.Remotes.notify(player, "warn", result == "max level" and "Treadmill is MAX LEVEL" or "Not enough Cash")
	end
	refreshSign(farmIndex)
	return ok
end

local function insideZone(zone: BasePart, pos: Vector3): boolean
	local rel = zone.CFrame:PointToObjectSpace(pos)
	local h = zone.Size / 2
	return math.abs(rel.X) <= h.X and math.abs(rel.Z) <= h.Z and rel.Y > -h.Y - 1 and rel.Y < h.Y + 6
end

function TreadmillService.IsTraining(player: Player): boolean
	return training[player] == true
end

function TreadmillService.Start(d)
	deps = d
	local farms = workspace:WaitForChild("SAE_World"):WaitForChild("Hub"):WaitForChild("Farms")
	for index = 1, Balance.OWNER_LOCKED.FarmCount do
		local farm = farms:WaitForChild("Farm" .. index)
		local model = farm:WaitForChild("Treadmill")
		local belt = model:WaitForChild("Belt") :: BasePart
		local zone = model:WaitForChild("TrainZone") :: BasePart
		local sign = farm:WaitForChild("TreadmillSign")
		local anchor = sign:WaitForChild("PromptAnchor")
		-- conveyor: pushes the runner backwards along the machine
		belt.AssemblyLinearVelocity = -belt.CFrame.LookVector * Balance.TreadmillBeltSpeed
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "UpgradePrompt"
		prompt.ObjectText = "Treadmill"
		prompt.ActionText = "UPGRADE"
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = anchor
		machines[index] = { model = model, belt = belt, zone = zone, tiers = model:WaitForChild("Tiers"), sign = sign, prompt = prompt }
		prompt.Triggered:Connect(function(player)
			if deps.FarmService.GetPlayerFarm(player) ~= index then
				deps.Remotes.notify(player, "warn", "This is not your farm's treadmill")
				return
			end
			deps.Remotes.locked(player, function()
				TreadmillService.Upgrade(player)
			end)
		end)
		refreshSign(index)
	end

	deps.Remotes.onEvent("RequestUpgradeTreadmill", function(player)
		TreadmillService.Upgrade(player)
	end)
	deps.FarmService.OnAssigned(function(_, index)
		task.defer(refreshSign, index)
	end)
	deps.FarmService.OnReleased(function(_, index)
		task.defer(refreshSign, index)
	end)
	deps.DataService.OnLoaded(function(player)
		local idx = deps.FarmService.GetPlayerFarm(player)
		if idx then
			refreshSign(idx)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		training[p] = nil
	end)

	-- training loop (owner-only, active running only)
	task.spawn(function()
		local dt = Balance.TreadmillTickSeconds
		while true do
			task.wait(dt)
			local now = deps.DataService.Now()
			for _, player in Players:GetPlayers() do
				local was = training[player]
				local isTraining = false
				local farmIndex = deps.FarmService.GetPlayerFarm(player)
				local m = farmIndex and machines[farmIndex]
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if m and hum and root and hum.Health > 0 and insideZone(m.zone, root.Position) then
					local grounded = hum.FloorMaterial ~= Enum.Material.Air
					local running = hum.MoveDirection.Magnitude > 0.35
					if grounded and running then
						isTraining = true
						local p = deps.DataService.Get(player)
						if p then
							local boost = ((p.boosts.speed2x or 0) > now) and 2 or 1
							p.speed += Economy.treadmillGain(p.treadmillLevel) * dt * boost
							deps.DataService.touchNumbers(player)
						end
					end
				end
				training[player] = isTraining or nil
				if was ~= training[player] then
					player:SetAttribute("Training", isTraining)
				end
			end
		end
	end)
end

return TreadmillService
