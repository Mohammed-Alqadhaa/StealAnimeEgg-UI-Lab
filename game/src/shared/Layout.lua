--!strict
--[[
	Layout — shared world geometry (server, client, Lune assembler, tests).

	FARM SAFE ZONE (§58): the ENTIRE farm hub is one safe zone, fenced by one shared
	perimeter fence (§80). Its rectangle contains all 7 plots, the Trail Shop and the Sell
	kiosk. The world route leaves through a single opening in the north fence, passes the
	Fog Gate (§118) and enters World 1 directly (no dead space, §82).

	WORLDS (§25–27): linear along +Z. Every world uses the Akaza world's final footprint:
	the Akaza world was 100 studs between walls; ×1.5 (§27) → 150 studs. Length is kept
	at the existing 230 studs. A 30-stud themed threshold separates consecutive worlds.
]]

local Worlds = require(script.Parent.Worlds)

local L = {}

-- ── Farm Safe Zone ───────────────────────────────────────────────────────────
L.SAFE_MIN = { x = -190, z = -192 }
L.SAFE_MAX = { x = 190, z = 190 }
L.SAFE_MAX_Y = 80
L.HUB_EXIT_HALF_WIDTH = 42 -- opening in the north perimeter fence
L.HUB_SPAWN = { x = 0, y = 3, z = -112 }

L.FARM_CENTERS = {
	{ x = -110, z = -88 },
	{ x = -110, z = 4 },
	{ x = -110, z = 96 },
	{ x = 110, z = -88 },
	{ x = 110, z = 4 },
	{ x = 110, z = 96 },
	{ x = 0, z = -140 },
}
L.FARM_FACING = { "E", "E", "E", "W", "W", "W", "S" } -- direction of the plot's front edge
L.PLOT_SIZE = { x = 92, z = 78 }

-- ── Fog Gate ─────────────────────────────────────────────────────────────────
L.FOG_GATE_Z = 198
L.FOG_GATE_HALF_WIDTH = 42

-- ── Worlds ───────────────────────────────────────────────────────────────────
L.WORLD_START_Z = 205
L.WORLD_LENGTH = 230
L.WORLD_THRESHOLD = 30
L.WORLD_PITCH = L.WORLD_LENGTH + L.WORLD_THRESHOLD
L.AKAZA_ORIGINAL_WALL_CLEAR = 100
L.WORLD_WALL_CLEAR = L.AKAZA_ORIGINAL_WALL_CLEAR * 1.5 -- 150 (§27)
L.WORLD_HALF_WIDTH = L.WORLD_WALL_CLEAR / 2 -- 75
L.WORLD_LANE_WIDTH = 108 -- readable centre lane (72 × 1.5)

function L.worldZ0(index: number): number
	return L.WORLD_START_Z + (index - 1) * L.WORLD_PITCH
end

function L.worldCenterZ(index: number): number
	return L.worldZ0(index) + L.WORLD_LENGTH / 2
end

-- Five egg spawn offsets (dx, dz from world z0) + boss home. Spread across the lane in
-- the back half so taking an egg always means a run back past the whole world.
L.EGG_OFFSETS = {
	{ x = -42, z = 118 },
	{ x = 42, z = 118 },
	{ x = -26, z = 158 },
	{ x = 26, z = 158 },
	{ x = 0, z = 184 }, -- slot 5 = boss egg, in front of the boss
}
L.BOSS_HOME_DZ = 206

-- Demon Slayer keeps the approved central egg layout around the compass needle (§31, §32).
L.DEMON_SLAYER_EGGS = {
	yoriichi = { x = 0.1, z = 353.0 },
	muzan = { x = -10.9, z = 357.5 },
	akaza = { x = -14.8, z = 369.6 },
	rengoku = { x = 14.9, z = 369.8 },
	tanjiro = { x = 11.2, z = 358.7 }, -- previous Giyu position (Giyu archived, §31)
}
L.AKAZA_HOME = { x = 0, z = 368 }

function L.eggPosition(eggId: string): (number, number)
	local egg = Worlds.EGGS[eggId]
	local world = Worlds.WORLDS[egg.world]
	if egg.world == "DemonSlayer" then
		local p = L.DEMON_SLAYER_EGGS[egg.character]
		return p.x, p.z
	end
	local o = L.EGG_OFFSETS[egg.slot]
	return o.x, L.worldZ0(world.index) + o.z
end

function L.bossHome(worldId: string): (number, number)
	if worldId == "DemonSlayer" then
		return L.AKAZA_HOME.x, L.AKAZA_HOME.z
	end
	return 0, L.worldZ0(Worlds.WORLDS[worldId].index) + L.BOSS_HOME_DZ
end

-- ── Queries ──────────────────────────────────────────────────────────────────
function L.isInSafeZone(x: number, y: number, z: number): boolean
	return x >= L.SAFE_MIN.x and x <= L.SAFE_MAX.x and z >= L.SAFE_MIN.z and z <= L.SAFE_MAX.z and y < L.SAFE_MAX_Y
end

-- Returns the world id whose footprint (incl. its trailing threshold) contains z, or nil.
function L.worldAt(x: number, z: number): string?
	if math.abs(x) > L.WORLD_HALF_WIDTH + 12 then
		return nil
	end
	local rel = z - L.WORLD_START_Z
	if rel < 0 then
		return nil
	end
	local index = math.floor(rel / L.WORLD_PITCH) + 1
	if index < 1 or index > #Worlds.ORDER then
		return nil
	end
	return Worlds.ORDER[index]
end

-- Distance still to run to reach the Farm Safe Zone (used for boss target priority, §113).
function L.distanceToSafeZone(x: number, z: number): number
	if L.isInSafeZone(x, 0, z) then
		return 0
	end
	return math.max(0, z - L.SAFE_MAX.z) + math.max(0, math.abs(x) - L.HUB_EXIT_HALF_WIDTH) * 0.25
end

return L
