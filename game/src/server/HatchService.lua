--[[
	HatchService — SECURED → HATCHING → READY → OPEN → CHARACTER_REVEAL → GRANTED (§62–§66).

	* hatchAt is an absolute server timestamp written at secure time; clients count down
	  locally (§63). No per-second remotes.
	* READY is decided by the SERVER clock at OPEN time. Opening consumes the egg before
	  granting the unit, under the per-player mutation lock → no double open (§127).
	* The response carries everything the client needs for the reveal presentation
	  (real model preview rig key, name, world, whether it's a new Index discovery).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Profile = require(Shared.Profile)
local Worlds = require(Shared.Worlds)

local HatchService = {}

function HatchService.Start(deps)
	local DataService, Remotes = deps.DataService, deps.Remotes
	Remotes.onInvoke("RequestOpenEgg", function(player, eggUid)
		if type(eggUid) ~= "string" or #eggUid > 64 then
			return false, "bad request"
		end
		local unitUid = HttpService:GenerateGUID(false)
		local ok, result = DataService.mutate(player, function(p)
			return Profile.openEgg(p, eggUid, unitUid, DataService.Now())
		end)
		if not ok then
			return false, result
		end
		local c = Worlds.CHARACTERS[result.characterId]
		return true,
			{
				uid = result.unit.uid,
				characterId = result.characterId,
				name = c.name,
				worldId = c.world,
				worldName = Worlds.WORLDS[c.world].name,
				isBoss = c.isBoss,
				isNewDiscovery = result.isNewDiscovery,
				equipped = result.equipped,
			}
	end)
end

return HatchService
