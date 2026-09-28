--[[
	PvPService — Bat hits knock carried eggs loose (§114–§116).

	* Every character receives a server-created Bat tool.
	* Hit resolution is 100% server-side from Tool.Activated: the server finds a target
	  within BatRange in a forward cone. There is no "I hit player X" remote (§115).
	* Validations: attacker alive, attacker cooldown, target alive, target is carrying an
	  UNSAFE egg, target outside the Farm Safe Zone (§116).
	* Result: the egg drops at the target + moderate knockback. No kill.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Balance = require(Shared.Balance)
local Layout = require(Shared.Layout)
local Animations = require(Shared.Animations)

local PvPService = {}

local deps
local lastSwing = {}

local function makeBat(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Bat"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Knock eggs out of carriers' hands"
	tool.GripPos = Vector3.new(0, -1.1, 0)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.45, 3.6, 0.45)
	handle.Color = Color3.fromRGB(150, 96, 52)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	local head = Instance.new("Part")
	head.Name = "BatHead"
	head.Shape = Enum.PartType.Cylinder
	head.Size = Vector3.new(1.6, 0.8, 0.8)
	head.Color = Color3.fromRGB(120, 72, 36)
	head.Material = Enum.Material.Wood
	head.CanCollide = false
	head.Massless = true
	head.CFrame = handle.CFrame * CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.rad(90))
	head.Parent = tool
	local w = Instance.new("WeldConstraint")
	w.Part0 = handle
	w.Part1 = head
	w.Parent = head
	return tool
end

local function rootOf(p: Player)
	local c = p.Character
	return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end

local function swing(attacker: Player)
	local t = os.clock()
	if lastSwing[attacker] and t - lastSwing[attacker] < Balance.BatCooldown then
		return
	end
	lastSwing[attacker] = t
	local aRoot, aHum = rootOf(attacker)
	if not aRoot or not aHum or aHum.Health <= 0 then
		return
	end
	local animator = aHum:FindFirstChildOfClass("Animator")
	if animator then
		local anim = Instance.new("Animation")
		anim.AnimationId = Animations.R6_DEFAULT.toolslash
		pcall(function()
			animator:LoadAnimation(anim):Play()
		end)
	end
	local best, bestDist = nil, math.huge
	for _, target in Players:GetPlayers() do
		if target ~= attacker and deps.EggService.IsCarrying(target) then
			local tRoot, tHum = rootOf(target)
			if tRoot and tHum and tHum.Health > 0 then
				local p = tRoot.Position
				if not Layout.isInSafeZone(p.X, p.Y, p.Z) then
					local offset = p - aRoot.Position
					local dist = offset.Magnitude
					if dist <= Balance.BatRange and dist < bestDist then
						local dot = aRoot.CFrame.LookVector:Dot(offset.Unit)
						if dot >= Balance.BatConeDot then
							best, bestDist = target, dist
						end
					end
				end
			end
		end
	end
	if best then
		if deps.EggService.Drop(best, "pvp") then
			local tRoot = rootOf(best)
			local dir = (tRoot.Position - aRoot.Position) * Vector3.new(1, 0, 1)
			dir = dir.Magnitude > 0.1 and dir.Unit or aRoot.CFrame.LookVector
			deps.Remotes.fire(best, "Knockback", dir * Balance.KnockbackStuds * 2 + Vector3.new(0, Balance.KnockbackUpward, 0))
			deps.Remotes.notify(best, "danger", attacker.DisplayName .. " knocked your egg loose!")
			deps.Remotes.notify(attacker, "ok", "Egg knocked loose!")
		end
	end
end

function PvPService.Start(d)
	deps = d
	local function give(player: Player, char: Model)
		local backpack = player:WaitForChild("Backpack", 10)
		if not backpack or backpack:FindFirstChild("Bat") or char:FindFirstChild("Bat") then
			return
		end
		local tool = makeBat()
		tool.Activated:Connect(function()
			swing(player)
		end)
		tool.Parent = backpack
	end
	local function hook(p: Player)
		p.CharacterAdded:Connect(function(c)
			give(p, c)
		end)
		if p.Character then
			task.spawn(give, p, p.Character)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		lastSwing[p] = nil
	end)
end

return PvPService
