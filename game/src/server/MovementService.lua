--[[
	MovementService — Speed → WalkSpeed (§87, §97).

	WalkSpeed = Economy.walkSpeed(trained Speed, equipped trail multiplier, speed boost):
	a configured, capped curve (Balance.Movement, PROVISIONAL) — never 16 × multiplier.
	While the owner is on their treadmill belt the WalkSpeed is set to a steady training
	pace so the runner stays on the machine.

	The server writes WalkSpeed and reverts any client write (same policy as the legacy
	PlayerStatsService, which this replaces — Muscle/Strength removed, §84).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Economy = require(Shared.Economy)
local Trails = require(Shared.Trails)
local Balance = require(Shared.Balance)

local MovementService = {}

local deps
local expected = {} -- [player] = number

local function compute(player: Player): number
	local p = deps.DataService.Get(player)
	if not p then
		return Balance.Movement.BaseWalkSpeed
	end
	if deps.TreadmillService.IsTraining(player) then
		return Balance.TreadmillBeltSpeed + 2
	end
	local boost = ((p.boosts.speed2x or 0) > deps.DataService.Now()) and 2 or 1
	return Economy.walkSpeed(p.speed, Trails.multiplierFor(p.equippedTrail), boost)
end

function MovementService.Refresh(player: Player)
	local value = compute(player)
	expected[player] = value
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and math.abs(hum.WalkSpeed - value) > 0.05 then
		hum.WalkSpeed = value
	end
end

function MovementService.Start(d)
	deps = d
	local function onCharacter(player: Player, char: Model)
		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then
			return
		end
		MovementService.Refresh(player)
		hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			local want = expected[player]
			if want and math.abs(hum.WalkSpeed - want) > 0.05 then
				hum.WalkSpeed = want -- revert unauthorised writes
			end
		end)
	end
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(c)
			onCharacter(player, c)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		expected[p] = nil
	end)
	deps.DataService.OnLoaded(MovementService.Refresh)
	deps.DataService.OnChanged(MovementService.Refresh)
	-- cheap periodic refresh covers training speed gains, treadmill enter/exit, boost expiry
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, p in Players:GetPlayers() do
				MovementService.Refresh(p)
			end
		end
	end)
end

return MovementService
