--!strict
--[[
	BossLogic — pure decision rules for the shared boss state machine (§106–§113).

	States: IDLE → REACTION → CHASE → (HIT | ESCAPED) → RETURN → IDLE
	Target priority (§113): the carrier CLOSEST TO REACHING THE FARM SAFE ZONE.
	One boss instance per world; never one clone per player.
]]

local Layout = require(script.Parent.Layout)

local B = {}

B.STATES = { "IDLE", "REACTION", "CHASE", "RETURN" }

export type Carrier = { id: any, x: number, z: number, worldOfEgg: string, secured: boolean }

-- Carriers relevant to `worldId`: carrying an egg from this boss's world and not secured.
function B.pickTarget(worldId: string, carriers: { Carrier }): Carrier?
	local best, bestDist = nil, math.huge
	for _, c in carriers do
		if c.worldOfEgg == worldId and not c.secured then
			local d = Layout.distanceToSafeZone(c.x, c.z)
			if d > 0 and (d < bestDist or (d == bestDist and tostring(c.id) < tostring(best and best.id))) then
				best, bestDist = c, d
			end
		end
	end
	return best
end

-- §111/§112: what a catch does depends on where the carrier is when caught.
--   inside the boss's own world        → "RETURN_EGG" (egg back to spawn) + knockback
--   outside it, before the safe zone   → "DROP_EGG" (dropped at the player) + boss goes home
--   inside the safe zone               → "NONE" (secured eggs are untouchable)
function B.catchOutcome(bossWorldId: string, x: number, y: number, z: number): string
	if Layout.isInSafeZone(x, y, z) then
		return "NONE"
	end
	if Layout.worldAt(x, z) == bossWorldId then
		return "RETURN_EGG"
	end
	return "DROP_EGG"
end

-- Give up once the target is far beyond the boss's world (keeps bosses home-bound).
function B.shouldGiveUp(bossWorldId: string, bossZ: number, targetZ: number, giveUpDistance: number): boolean
	local worldIndex = 0
	for i, id in require(script.Parent.Worlds).ORDER do
		if id == bossWorldId then
			worldIndex = i
		end
	end
	local worldStart = Layout.worldZ0(worldIndex)
	return targetZ < worldStart - giveUpDistance or math.abs(bossZ - targetZ) > giveUpDistance * 1.5
end

return B
