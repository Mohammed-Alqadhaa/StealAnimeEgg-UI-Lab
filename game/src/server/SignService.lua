--[[
	SignService — the physical FARM UPGRADE sign on each plot's front marker (§92),
	plus the owner name plate on each plot.

	Sign shows Farm Level, current Character Slots, next slots and cost; its
	ProximityPrompt runs the same server-validated upgrade as the Upgrade menu.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Economy = require(Shared.Economy)
local Balance = require(Shared.Balance)

local SignService = {}

local deps
local signs = {}

local function setText(root: Instance, name: string, text: string)
	local l = root:FindFirstChild(name, true)
	if l and l:IsA("TextLabel") then
		l.Text = text
	end
end

local function refresh(index: number)
	local s = signs[index]
	if not s then
		return
	end
	local owner = deps.FarmService.GetOwner(index)
	local p = owner and deps.DataService.Get(owner)
	setText(s.plate, "Owner", owner and (owner.DisplayName .. "'s Farm") or ("FARM " .. index .. " • FREE"))
	if not p then
		setText(s.sign, "Level", "FARM LEVEL 1")
		setText(s.sign, "Slots", Economy.farmSlots(1) .. " CHARACTER SLOTS")
		setText(s.sign, "Next", "")
		setText(s.sign, "Cost", "—")
		s.prompt.Enabled = false
		return
	end
	local cost = Economy.farmUpgradeCost(p.farmLevel)
	setText(s.sign, "Level", "FARM LEVEL " .. p.farmLevel)
	setText(s.sign, "Slots", Economy.farmSlots(p.farmLevel) .. " CHARACTER SLOTS")
	setText(s.sign, "Next", cost and ("NEXT: " .. Economy.farmSlots(p.farmLevel + 1) .. " SLOTS") or "MAX LEVEL")
	setText(s.sign, "Cost", cost and ("$" .. Economy.format(cost)) or "MAX")
	s.prompt.Enabled = cost ~= nil
	s.prompt.ActionText = cost and ("UPGRADE $" .. Economy.format(cost)) or "MAX LEVEL"
end

function SignService.Start(d)
	deps = d
	local farms = workspace:WaitForChild("SAE_World"):WaitForChild("Hub"):WaitForChild("Farms")
	for index = 1, Balance.OWNER_LOCKED.FarmCount do
		local farm = farms:WaitForChild("Farm" .. index)
		local sign = farm:WaitForChild("FarmSign")
		local plate = farm:WaitForChild("OwnerPlate")
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "UpgradePrompt"
		prompt.ObjectText = "Farm"
		prompt.ActionText = "UPGRADE"
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = sign:WaitForChild("PromptAnchor")
		prompt.Triggered:Connect(function(player)
			if d.FarmService.GetPlayerFarm(player) ~= index then
				d.Remotes.notify(player, "warn", "This is not your farm")
				return
			end
			d.Remotes.locked(player, function()
				d.CharacterService.UpgradeFarm(player)
			end)
		end)
		signs[index] = { sign = sign, plate = plate, prompt = prompt }
		refresh(index)
	end
	d.FarmService.OnAssigned(function(_, i)
		task.defer(refresh, i)
	end)
	d.FarmService.OnReleased(function(_, i)
		task.defer(refresh, i)
	end)
	d.DataService.OnLoaded(function(player)
		local i = d.FarmService.GetPlayerFarm(player)
		if i then
			refresh(i)
		end
	end)
	d.DataService.OnChanged(function(player)
		local i = d.FarmService.GetPlayerFarm(player)
		if i then
			refresh(i)
		end
	end)
end

return SignService
