--[[
	FarmService — 7 farms, automatic assignment, max ONE farm per player (§78).

	Replaces the legacy FarmService. The legacy version did `model:WaitForChild("BoxingBag")`
	(infinite-yield hazard, §83); this one depends only on each farm's Plot. Farms are
	baked into Workspace.SAE_World.Hub.Farms by the assembler.

	Ownership is mirrored as attributes (Farm.OwnerUserId, Player.FarmIndex) for
	display only; every gameplay check calls this service.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Balance = require(Shared.Balance)

local FarmService = {}

local farms = {} -- [index] = { model, plot, min: Vector3, max: Vector3 }
local farmByUser = {}
local userByFarm = {}
local assignedListeners, releasedListeners = {}, {}

local function farmsFolder()
	return workspace:WaitForChild("SAE_World"):WaitForChild("Hub"):WaitForChild("Farms")
end

function FarmService.Init()
	local folder = farmsFolder()
	for index = 1, Balance.OWNER_LOCKED.FarmCount do
		local model = folder:WaitForChild("Farm" .. index, 30)
		assert(model, "Farm" .. index .. " missing from SAE_World.Hub.Farms")
		local plot = model:WaitForChild("Plot", 30)
		assert(plot, "Farm" .. index .. ".Plot missing")
		local half = plot.Size * 0.5
		farms[index] = {
			model = model,
			plot = plot,
			min = plot.Position - Vector3.new(half.X, 0, half.Z),
			max = plot.Position + Vector3.new(half.X, 0, half.Z),
		}
		model:SetAttribute("FarmIndex", index)
		model:SetAttribute("OwnerUserId", 0)
		model:SetAttribute("OwnerName", "")
	end
end

function FarmService.Start()
	Players.PlayerAdded:Connect(FarmService.Assign)
	Players.PlayerRemoving:Connect(FarmService.Release)
	for _, p in Players:GetPlayers() do
		FarmService.Assign(p)
	end
end

function FarmService.Assign(player: Player): number?
	if farmByUser[player.UserId] then
		return farmByUser[player.UserId]
	end
	for index = 1, Balance.OWNER_LOCKED.FarmCount do
		if not userByFarm[index] then
			userByFarm[index] = player.UserId
			farmByUser[player.UserId] = index
			local f = farms[index]
			f.model:SetAttribute("OwnerUserId", player.UserId)
			f.model:SetAttribute("OwnerName", player.DisplayName)
			player:SetAttribute("FarmIndex", index)
			for _, fn in assignedListeners do
				task.spawn(fn, player, index)
			end
			return index
		end
	end
	-- §79: servers should be capped at 7 players; an 8th player simply has no farm
	player:SetAttribute("FarmIndex", 0)
	warn("[Farm] no free farm for " .. player.Name .. " (server over capacity — set Max Players = 7)")
	return nil
end

function FarmService.Release(player: Player)
	local index = farmByUser[player.UserId]
	if not index then
		return
	end
	farmByUser[player.UserId] = nil
	userByFarm[index] = nil
	local f = farms[index]
	f.model:SetAttribute("OwnerUserId", 0)
	f.model:SetAttribute("OwnerName", "")
	for _, fn in releasedListeners do
		task.spawn(fn, player, index)
	end
end

function FarmService.OnAssigned(fn)
	table.insert(assignedListeners, fn)
end

function FarmService.OnReleased(fn)
	table.insert(releasedListeners, fn)
end

function FarmService.GetPlayerFarm(player: Player): number?
	return farmByUser[player.UserId]
end

function FarmService.GetFarm(index: number)
	return farms[index]
end

function FarmService.GetOwner(index: number): Player?
	local userId = userByFarm[index]
	return userId and Players:GetPlayerByUserId(userId) or nil
end

function FarmService.IsInsidePlot(index: number, position: Vector3, inset: number?): boolean
	local f = farms[index]
	if not f then
		return false
	end
	local e = inset or 0
	return position.X > f.min.X + e and position.X < f.max.X - e and position.Z > f.min.Z + e and position.Z < f.max.Z - e
end

-- random point inside the owner's plot (for wandering characters, §75)
function FarmService.RandomPointInPlot(index: number, inset: number, rng: Random): Vector3
	local f = farms[index]
	local x = rng:NextNumber(f.min.X + inset, f.max.X - inset)
	local z = rng:NextNumber(f.min.Z + inset, f.max.Z - inset)
	return Vector3.new(x, f.plot.Position.Y + f.plot.Size.Y / 2, z)
end

return FarmService
