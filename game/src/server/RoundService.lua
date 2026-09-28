--[[
	RoundService — 5-minute rounds with a Fog Gate (§117–§119).

	GATE  (FogGateSeconds, 7 s): Fog Gate closed; countdown shown to everyone.
	OPEN  (rest of the 300 s round): gate open, eggs can be taken.
	RESET (instant): players outside the Farm Safe Zone return to the hub; unsafe carried
	      eggs, dropped eggs and every untaken/taken world egg are restored to their
	      spawns; bosses return home and their states clear; gate closes; next round.
	Secured eggs and owned characters are profile data and are never touched by resets
	(no duplicate rewards, no loss).

	Timing is published as absolute server timestamps on Workspace attributes
	(RoundPhase, PhaseEndsAt, RoundNumber); clients render the countdown locally (§125).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Balance = require(Shared.Balance)
local Layout = require(Shared.Layout)

local RoundService = {}

local phase = "GATE"
local gate -- Model with Blocker (Part) + visuals tagged FogVisual
local deps

local function setGate(closed: boolean)
	if not gate then
		return
	end
	for _, d in gate:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "Blocker" then
				d.CanCollide = closed
			end
			local base = d:GetAttribute("BaseTransparency")
			if base ~= nil then
				d.Transparency = closed and base or 1
			end
		elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Light") then
			d.Enabled = closed
		end
	end
	gate:SetAttribute("Closed", closed)
end

local function setPhase(name: string, seconds: number)
	phase = name
	workspace:SetAttribute("RoundPhase", name)
	workspace:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + seconds)
end

local function waitPhase()
	while workspace:GetServerTimeNow() < (workspace:GetAttribute("PhaseEndsAt") or 0) do
		task.wait(0.25)
	end
end

local function returnOutsidePlayers()
	for _, p in Players:GetPlayers() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root and not Layout.isInSafeZone(root.Position.X, root.Position.Y, root.Position.Z) then
			local s = Layout.HUB_SPAWN
			local offset = Vector3.new(math.random(-12, 12), 0, math.random(-6, 6))
			p.Character:PivotTo(CFrame.new(Vector3.new(s.x, s.y + 3, s.z) + offset))
			deps.Remotes.notify(p, "info", "Round over — back to the Farm!")
		end
	end
end

function RoundService.IsOpen(): boolean
	return phase == "OPEN"
end

function RoundService.Phase(): string
	return phase
end

function RoundService.Start(d)
	deps = d
	gate = workspace:WaitForChild("SAE_World"):WaitForChild("Hub"):WaitForChild("FogGate", 30)
	task.spawn(function()
		local round = 0
		while true do
			round += 1
			workspace:SetAttribute("RoundNumber", round)
			-- GATE
			setGate(true)
			setPhase("GATE", Balance.OWNER_LOCKED.FogGateSeconds)
			waitPhase()
			-- OPEN
			setGate(false)
			local openSeconds = Balance.OWNER_LOCKED.RoundSeconds - Balance.OWNER_LOCKED.FogGateSeconds
			setPhase("OPEN", openSeconds)
			waitPhase()
			-- RESET (instant, ordered: players first so no one re-grabs mid-reset)
			phase = "RESET"
			workspace:SetAttribute("RoundPhase", "RESET")
			returnOutsidePlayers()
			d.EggService.ResetAll()
			d.BossService.ResetAll()
			task.wait(0.5)
		end
	end)
end

-- Developer/testing helper (DevService, Studio only)
function RoundService.SkipPhase()
	workspace:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow())
end

return RoundService
