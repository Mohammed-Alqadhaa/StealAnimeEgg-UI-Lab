--[[
	DevService — developer test commands (§10).

	Allowed ONLY in Roblox Studio or for user ids listed in DEVELOPER_USER_IDS (empty by
	default). Normal players are refused server-side regardless of any client UI.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Profile = require(Shared.Profile)
local Worlds = require(Shared.Worlds)

local DevService = {}

DevService.DEVELOPER_USER_IDS = {} -- e.g. { 12345678 }

function DevService.IsDeveloper(player: Player): boolean
	return RunService:IsStudio() or table.find(DevService.DEVELOPER_USER_IDS, player.UserId) ~= nil
end

function DevService.Start(d)
	d.Remotes.onInvoke("RequestDevCommand", function(player, cmd, arg)
		if not DevService.IsDeveloper(player) then
			return false, "not allowed"
		end
		local now = d.DataService.Now()
		if cmd == "cash" then
			return d.DataService.mutate(player, function(p)
				p.cash += math.clamp(tonumber(arg) or 0, 0, 1e15)
				return true
			end)
		elseif cmd == "speed" then
			return d.DataService.mutate(player, function(p)
				p.speed += math.clamp(tonumber(arg) or 0, 0, 1e9)
				return true
			end)
		elseif cmd == "hatchNow" then
			return d.DataService.mutate(player, function(p)
				for _, e in p.eggs do
					e.hatchAt = now
				end
				return true
			end)
		elseif cmd == "grantEgg" then
			local eggId = "egg_" .. tostring(arg)
			if not Worlds.EGGS[eggId] then
				return false, "unknown character"
			end
			return d.DataService.mutate(player, function(p)
				return Profile.secureEgg(p, eggId, HttpService:GenerateGUID(false), now)
			end)
		elseif cmd == "skipPhase" then
			d.RoundService.SkipPhase()
			return true
		elseif cmd == "wipe" then
			return d.DataService.mutate(player, function(p)
				for k, v in Profile.new() do
					p[k] = v
				end
				return true
			end)
		end
		return false, "unknown command"
	end)
end

return DevService
