--!strict
--[[
	Animations — animation ids used by NPC rigs (farm characters, bosses, vendors).

	Defaults are Roblox's own public R6 animations (the same ids the default R6 `Animate`
	script uses), so every rig moves instead of sliding. The Owner asked for premium
	running animations (§109): paste higher-quality R6 animation ids (owned by the game's
	creator/group) into BOSS_OVERRIDES / FARM_OVERRIDES — OWNER ACTION REQUIRED, since
	uploading/purchasing animations requires the Owner's Roblox account.
]]

local A = {}

A.R6_DEFAULT = {
	idle = "rbxassetid://180435571",
	idle2 = "rbxassetid://180435792",
	walk = "rbxassetid://180426354",
	run = "rbxassetid://180426354",
	jump = "rbxassetid://125750702",
	fall = "rbxassetid://180436148",
	sit = "rbxassetid://178130996",
	toolslash = "rbxassetid://129967390",
}

-- per boss character id: { idle=, run=, seated=, rise=, reaction= }  (nil → default)
A.BOSS_OVERRIDES = {}

-- per character id for farm wandering: { idle=, walk= }
A.FARM_OVERRIDES = {}

function A.get(kind: string, characterId: string?, isBoss: boolean?): string
	local o = characterId and (if isBoss then A.BOSS_OVERRIDES[characterId] else A.FARM_OVERRIDES[characterId])
	return (o and o[kind]) or A.R6_DEFAULT[kind] or A.R6_DEFAULT.idle
end

return A
