--!nocheck
--[[
	Kit — common frame shared by every world (§26, §27).
	Same footprint for all worlds (the Akaza world's final footprint):
	  * playable width 150 (walls' inner faces at x = ±75), centre lane |x| < 54
	  * length 230 (z0 … z0+230) + a 30-stud themed entry threshold before z0
	  * 5 egg pads (Layout.EGG_OFFSETS), boss stage at the far end (Layout.BOSS_HOME_DZ)
	  * tall invisible colliders on the walls so the route stays linear
	Themes add identity mostly on the LEFT/RIGHT bands (|x| 54…75) and background (§26).
]]
local B = require("../lib/B")
local R = B.R
local V3, CF, A = B.V3, B.CF, B.Angles

local Kit = {}

function Kit.new(worldModel, worldId, index, L, W)
	local ctx = {
		model = worldModel,
		id = worldId,
		index = index,
		z0 = L.worldZ0(index),
		len = L.WORLD_LENGTH,
		half = L.WORLD_HALF_WIDTH, -- 75
		lane = L.WORLD_LANE_WIDTH / 2, -- 54
		info = W.WORLDS[worldId],
		pal = W.WORLDS[worldId].palette,
		env = B.model(worldModel, "Environment"),
		rng = B.rng(1000 + index * 97),
	}
	function ctx.cf(x, y, dz)
		return CF(x, y, ctx.z0 + dz)
	end
	function ctx.box(name, sx, sy, sz, x, y, dz, col, mat, opts)
		return B.box(ctx.env, name, sx, sy, sz, x, y, ctx.z0 + dz, col, mat, opts)
	end
	function ctx.rbox(name, sx, sy, sz, x, y, dz, ry, col, mat, opts, rx, rz)
		return B.rbox(ctx.env, name, sx, sy, sz, x, y, ctx.z0 + dz, ry, col, mat, opts, rx, rz)
	end
	-- mirrored helper: builds fn(sign) for left (-1) and right (+1)
	function ctx.mirror(fn)
		fn(-1)
		fn(1)
	end
	return ctx
end

-- floor, walls, colliders, entry threshold + title arch, back wall/gate
function Kit.frame(ctx, o)
	o = o or {}
	local z0, len, half = ctx.z0, ctx.len, ctx.half
	local pal = ctx.pal
	-- ground under the whole footprint + threshold
	B.box(ctx.env, "Ground", half * 2 + 10, 2, len + 30, 0, -1, z0 + len / 2 - 15, o.ground or pal.floor, o.groundMat or "Slate", { collide = true })
	-- entry threshold (30 studs before z0): portal arch carrying the world title
	local tz = z0 - 15
	for _, s in { -1, 1 } do
		B.box(ctx.env, "ThresholdWall", 4, o.wallH or 30, 30, s * (half + 2), (o.wallH or 30) / 2, tz, pal.wall, o.wallMat or "Slate", { collide = true })
		B.box(ctx.env, "PortalPillar", 6, 34, 6, s * 46, 17, z0 - 2, pal.wall, "Slate", { collide = true })
		B.box(ctx.env, "PortalGlow", 6.4, 0.8, 6.4, s * 46, 33.6, z0 - 2, pal.glow, "Neon")
		-- close the gap between the portal and the side walls
		B.box(ctx.env, "PortalFill", half - 49, 34, 3, s * (49 + (half - 49) / 2), 17, z0 - 2, pal.wall, "Slate", { collide = true })
	end
	local beam = B.box(ctx.env, "PortalBeam", 98, 6, 4, 0, 36, z0 - 2, pal.wall, "Slate", { collide = true })
	B.surfaceText(beam, string.format("WORLD %d • %s", ctx.index, string.upper(ctx.info.name)), { face = "Back", color = pal.glow, name = "TitleIn" })
	B.surfaceText(beam, "◀ BACK TO THE FARM", { face = "Front", color = "#7CFF5A", name = "TitleOut" })
	local band = B.box(ctx.env, "PortalGlowBand", 98.4, 0.6, 4.4, 0, 32.8, z0 - 2, pal.glow, "Neon")
	B.light(band, pal.glow, 40, 1.2)
	-- side walls + top trim + invisible anti-climb colliders
	local wallH = o.wallH or 30
	for _, s in { -1, 1 } do
		if not o.customWalls then
			B.box(ctx.env, "SideWall", 4, wallH, len, s * (half + 2), wallH / 2, z0 + len / 2, pal.wall, o.wallMat or "Slate", { collide = true })
			B.box(ctx.env, "WallTrim", 4.6, 0.8, len, s * (half + 2), wallH + 0.4, z0 + len / 2, pal.accent, o.trimMat or "Neon")
		end
		B.box(ctx.env, "WallCollider", 4, 90, len + 30, s * (half + 2), 45, z0 + len / 2 - 15, "#FFFFFF", "SmoothPlastic", { collide = true, transparency = 1 })
	end
	-- lane edge guide lines (readable centre lane, §26)
	for _, s in { -1, 1 } do
		B.box(ctx.env, "LaneEdge", 0.8, 0.12, len, s * ctx.lane, 0.08, z0 + len / 2, pal.accent, o.laneEdgeMat or "Neon", { transparency = 0.2 })
	end
	-- back wall: gate to the next world (or closed for the last world)
	if o.last then
		B.box(ctx.env, "BackWall", half * 2 + 8, wallH + 20, 4, 0, (wallH + 20) / 2, z0 + len + 2, pal.wall, o.wallMat or "Slate", { collide = true })
	end
end

-- five pedestal pads (theme colours) — the eggs themselves are placed by the assembler
function Kit.eggPads(ctx, L, W, style)
	local pads = {}
	for _, charId in ctx.info.roster do
		local egg = W.EGGS["egg_" .. charId]
		local x, z = L.eggPosition(egg.id)
		pads[charId] = { x = x, z = z }
		style = style or {}
		local base = B.cyl(ctx.env, "EggPlinth", 10, 1.4, x, 0.7, z, style.plinth or ctx.pal.wall, style.plinthMat or "Slate", { collide = true })
		B.cyl(ctx.env, "EggPlinthRing", 10.6, 0.3, x, 1.35, z, style.ring or ctx.pal.glow, "Neon")
		local plate = B.box(ctx.env, "EggNamePlate", 6, 1.2, 0.4, x, 0.9, z - 5.3, "#1B1036", "SmoothPlastic")
		B.surfaceText(plate, string.upper(W.CHARACTERS[charId].name), { face = "Front", color = style.text or ctx.pal.glow, name = "NameGui" })
		base:SetAttribute("EggPad", charId)
	end
	return pads
end

-- boss stage at the far end; returns home CFrame (boss faces -Z toward the players)
function Kit.bossStage(ctx, L, o)
	o = o or {}
	local hx, hz = L.bossHome(ctx.id)
	B.box(ctx.env, "BossStage", o.w or 36, o.h or 1.6, o.d or 20, hx, (o.h or 1.6) / 2, hz + 2, o.col or ctx.pal.wall, o.mat or "Slate", { collide = true })
	B.box(ctx.env, "BossStageEdge", (o.w or 36) + 0.6, 0.3, 0.6, hx, (o.h or 1.6), hz - 8, ctx.pal.glow, "Neon")
	local anchor = B.box(ctx.env, "BossLight", 1, 1, 1, hx, 18, hz, "#FFFFFF", "SmoothPlastic", { transparency = 1 })
	B.light(anchor, ctx.pal.glow, 45, 1.6)
	return CF(hx, 0, hz)
end

-- sparse ambient lights along the lane (bounded count for performance)
function Kit.laneLights(ctx, col, every, y, range)
	for dz = 20, ctx.len - 10, every or 45 do
		for _, s in { -1, 1 } do
			local a = B.box(ctx.env, "AmbientLight", 1, 1, 1, s * (ctx.lane + 6), y or 10, ctx.z0 + dz, "#FFFFFF", "SmoothPlastic", { transparency = 1 })
			B.light(a, col, range or 40, 0.9)
		end
	end
end

return Kit
