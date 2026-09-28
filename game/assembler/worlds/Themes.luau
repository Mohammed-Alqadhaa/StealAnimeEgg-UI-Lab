--!nocheck
--[[
	Themes — world identity builders for worlds 2–9 (Master Prompt §34–§51).
	Each theme: Kit.frame + pads + boss stage + side/background storytelling.
	The centre lane (|x| < 54) stays clear for running, PvP, egg carrying and chases.
	Built from native parts (no uploaded meshes available in this environment); every
	world has a distinct silhouette, palette and lighting profile (client ZoneLighting).
]]
local B = require("../lib/B")
local Kit = require("./Kit")
local V3, CF, A = B.V3, B.CF, B.Angles

local T = {}

-- helpers ----------------------------------------------------------------------
local function hand(env, cf, col, scale)
	scale = scale or 1
	B.part(env, "HandPalm", V3(2.4, 2.8, 0.7) * scale, cf, col, "SmoothPlastic")
	for i, f in { -0.9, -0.3, 0.3, 0.9 } do
		local len = (i == 2 or i == 3) and 2.4 or 2
		B.part(env, "HandFinger", V3(0.5, len, 0.5) * scale, cf * CF(f * scale, (1.4 + len / 2) * scale, 0), col, "SmoothPlastic")
	end
	B.part(env, "HandThumb", V3(0.5, 1.6, 0.5) * scale, cf * CF(-1.4 * scale, 0.2 * scale, 0) * A(0, 0, math.rad(45)), col, "SmoothPlastic")
end

local function chain(env, a, b, col)
	local n = math.max(2, math.floor((b - a).Magnitude / 0.9))
	for i = 0, n - 1 do
		local p = a:Lerp(b, (i + 0.5) / n)
		B.part(env, "ChainLink", V3(0.5, 0.25, 0.9), B.lookAt(p, b) * A(0, 0, (i % 2) * math.rad(90)), col, "Metal")
	end
end

local function skyline(ctx, col, winCol, count, minH, maxH, dist)
	local rng = ctx.rng
	for _, s in { -1, 1 } do
		for i = 1, count do
			local h = rng(minH, maxH)
			local w = rng(14, 26)
			local x = s * rng(dist, dist + 60)
			local dz = (i - 0.5) * ctx.len / count + rng(-6, 6)
			local blk = ctx.box("Skyline", w, h, w, x, h / 2, dz, col, "Concrete")
			for k = 1, math.floor(h / 9) do
				if rng() > 0.35 then
					ctx.box("SkylineWindow", w * 0.7, 0.8, 0.2, x, k * 9 - 2, dz - s * 0 - w / 2 - 0.1, winCol, "Neon", { transparency = rng(0, 0.4) })
				end
			end
			blk:SetAttribute("Background", true)
		end
	end
end

local function fireBowl(ctx, x, dz, col, bowlCol, h)
	h = h or 5
	ctx.box("BrazierStem", 1.2, h, 1.2, x, h / 2, dz, bowlCol or "#2A2A2A", "Metal")
	local bowl = B.cyl(ctx.env, "BrazierBowl", 3.4, 1.2, x, h + 0.4, ctx.z0 + dz, bowlCol or "#2A2A2A", "Metal")
	local flame = ctx.box("BrazierFlame", 1, 1, 1, x, h + 1.4, dz, "#FFFFFF", "SmoothPlastic", { transparency = 1 })
	B.fire(flame, col or { "#FFD23F", "#FF4D1A" }, 2.4, 22)
	B.light(flame, col and col[1] or "#FF9A3D", 22, 1.3)
	return bowl
end

-- ─────────────────────────────────────────────────────────────── MHA (R01)
T.MHA = function(ctx, L, W)
	Kit.frame(ctx, { ground = "#3A3444", wallH = 26 })
	local rng = ctx.rng
	-- cracked slab floor with purple energy glowing through the seams (no pits, §34)
	for gx = -5, 4 do
		for gz = 0, 22 do
			local x, dz = gx * 10.8 + 5.4, gz * 10 + 5
			ctx.rbox("FloorSlab", 10.2, 0.6, 9.4, x, 0.3 + rng(-0.12, 0.12), dz, rng(-4, 4), rng() > 0.5 and "#4F4A5A" or "#5A5566", "Slate", { collide = true }, rng(-1.5, 1.5), rng(-1.5, 1.5))
		end
	end
	for i = 1, 26 do
		local x, dz = rng(-50, 50), rng(10, 220)
		ctx.rbox("PurpleCrack", 0.35, 0.1, rng(4, 14), x, 0.64, dz, rng(0, 180), "#B266FF", "Neon")
	end
	-- one-level villain bar / lounge structures on both sides (§21: no second floors)
	ctx.mirror(function(s)
		local x0 = s * 65
		for seg = 0, 4 do
			local dz = 20 + seg * 44
			ctx.box("LoungeRoof", 20, 1, 30, x0, 12, dz + 12, "#221C2B", "Slate")
			ctx.box("LoungeRoofNeon", 0.4, 0.3, 30, s * 55.2, 11.4, dz + 12, "#B266FF", "Neon")
			ctx.box("LoungeBackWall", 1, 12, 30, s * 74, 6, dz + 12, "#2B2433", "Brick")
			-- bar counter + bottle shelf
			ctx.box("BarCounter", 3, 3.6, 22, s * 62, 1.8, dz + 12, "#4A2A1E", "Wood", { collide = true })
			ctx.box("BarTop", 3.6, 0.4, 22.4, s * 62, 3.8, dz + 12, "#1B1B1B", "Marble")
			for b = 0, 9 do
				local col = ({ "#B266FF", "#FFB347", "#3FE0FF", "#FF4D6D" })[(b % 4) + 1]
				B.cyl(ctx.env, "Bottle", 0.5, 1.4, s * 72.6, 7 + (b % 2) * 2.2, ctx.z0 + dz + 2 + b * 2.2, col, "Neon", { transparency = 0.2 })
			end
			ctx.box("Shelf", 1.4, 0.3, 24, s * 72.8, 6.2, dz + 12, "#3A2A20", "Wood")
			ctx.box("Shelf", 1.4, 0.3, 24, s * 72.8, 8.4, dz + 12, "#3A2A20", "Wood")
			for k = 0, 2 do
				B.cyl(ctx.env, "Stool", 1.6, 2.4, s * 58.6, 1.2, ctx.z0 + dz + 5 + k * 7, "#8E1B2E", "Fabric")
			end
			ctx.box("LoungeBooth", 5, 2.4, 6, s * 68, 1.2, dz + 30, "#8E1B2E", "Fabric")
			local lamp = ctx.box("BarLamp", 1, 1, 1, s * 62, 10.5, dz + 12, "#FFB347", "Neon")
			B.light(lamp, "#B266FF", 18, 1)
			-- red hand banner on the lounge wall (League of Villains)
			ctx.box("HandBanner", 0.4, 9, 6, s * 73.4, 18, dz + 12, "#8E0E1E", "Fabric")
			hand(ctx.env, ctx.cf(s * 73, 18.6, dz + 12) * A(0, math.rad(s * -90), 0), "#EDE6D6", 1)
		end
		-- broken pillars + rubble + chains toward the lane edge
		for i = 0, 6 do
			local dz = 12 + i * 34
			local h = rng(6, 16)
			ctx.rbox("BrokenPillar", 3, h, 3, s * 56.5, h / 2, dz, rng(-10, 10), "#6E6878", "Concrete", { collide = true }, 0, rng(-6, 6))
			for r = 1, 4 do
				ctx.rbox("Rubble", rng(1, 3), rng(0.6, 1.6), rng(1, 3), s * rng(55, 60), 0.6, dz + rng(-4, 4), rng(0, 90), "#5A5566", "Slate", nil, rng(-20, 20), rng(-20, 20))
			end
			chain(ctx.env, V3(s * 56.5, h, ctx.z0 + dz), V3(s * 74, 22, ctx.z0 + dz + 10), "#6E7385")
		end
	end)
	skyline(ctx, "#1A1426", "#B266FF", 6, 40, 90, 90)
	-- boss: Shigaraki's rubble throne with reaching hands behind (R01)
	local home = Kit.bossStage(ctx, L, { w = 40, d = 22, col = "#3A3444" })
	for i = 0, 6 do
		ctx.rbox("ThroneSlab", 10 - i, 1.4, 6, home.Position.X, 1.8 + i * 1.3, (home.Position.Z - ctx.z0) + 5 + i * 0.4, (i % 2) * 8 - 4, "#5A5566", "Slate", { collide = true })
	end
	for i = -4, 4 do
		hand(ctx.env, ctx.cf(i * 3.2, 11 + math.abs(i) * -0.8, (home.Position.Z - ctx.z0) + 10) * A(math.rad(-15), 0, math.rad(i * 8)), "#E8E0DA", 1.6)
	end
	for _, s in { -1, 1 } do
		ctx.box("ThroneBanner", 0.5, 22, 10, s * 22, 14, (home.Position.Z - ctx.z0) + 12, "#8E0E1E", "Fabric")
	end
	Kit.eggPads(ctx, L, W, { plinth = "#2B2433", ring = "#B266FF" })
	Kit.laneLights(ctx, "#B266FF", 55, 11, 45)
end

-- ─────────────────────────────────────────────────────── DRAGON BALL — Namek
T.DragonBall = function(ctx, L, W)
	Kit.frame(ctx, { ground = "#7FD66B", groundMat = "Grass", wallH = 14, wallMat = "Sandstone" })
	local rng = ctx.rng
	-- blue water channels on both sides + light lane (one of the two lightest zones, §37)
	ctx.mirror(function(s)
		ctx.box("NamekWater", 14, 0.4, ctx.len, s * 64, 0.15, ctx.len / 2, "#3FB6FF", "Glass", { transparency = 0.15 })
		ctx.box("WaterBank", 1.2, 0.8, ctx.len, s * 56.6, 0.4, ctx.len / 2, "#CDEFB0", "Sand")
		-- sparse Namek trees: tall thin trunks with blue sphere clusters
		for i = 0, 5 do
			local dz = 18 + i * 38 + rng(-6, 6)
			local x = s * rng(58, 70)
			local h = rng(14, 22)
			B.cyl(ctx.env, "NamekTrunk", 1.1, h, x, h / 2, ctx.z0 + dz, "#6B8F4A", "Wood")
			for k = 0, 2 do
				B.ball(ctx.env, "NamekLeaves", rng(4.5, 6.5), x + rng(-2, 2), h + k * 1.4, ctx.z0 + dz + rng(-2, 2), "#3F7BFF", "SmoothPlastic")
			end
		end
		-- a few white domes (§37)
		for i = 0, 1 do
			local dz = 60 + i * 95
			B.ball(ctx.env, "NamekDome", 12, s * 90, 1, ctx.z0 + dz, "#F4F8F4", "SmoothPlastic")
			for w = 0, 3 do
				B.ball(ctx.env, "DomeWindow", 1.4, s * (90 - 5.5), 3, ctx.z0 + dz - 3 + w * 2, "#3FB6FF", "Glass")
			end
		end
	end)
	-- mesas in the background (stacked cylinders)
	for _, s in { -1, 1 } do
		for i = 1, 4 do
			local x, dz = s * rng(110, 170), i * 55 + rng(-10, 10)
			local h = rng(35, 70)
			B.cyl(ctx.env, "Mesa", rng(26, 40), h, x, h / 2, ctx.z0 + dz, "#8FB87A", "Sandstone")
			B.cyl(ctx.env, "MesaCap", rng(20, 30), 5, x, h + 2, ctx.z0 + dz, "#6FA85E", "Grass")
		end
	end
	local home = Kit.bossStage(ctx, L, { w = 42, d = 24, col = "#A8C98C", mat = "Sandstone" })
	-- Frieza's saucer ship behind the stage
	B.ellipsoid(ctx.env, "FriezaShip", 40, 10, 40, ctx.cf(0, 14, (home.Position.Z - ctx.z0) + 30), "#F4F4F4", "SmoothPlastic")
	B.ellipsoid(ctx.env, "FriezaShipDome", 16, 8, 16, ctx.cf(0, 19, (home.Position.Z - ctx.z0) + 30), "#9B4DFF", "Glass")
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		ctx.box("ShipLight", 1.2, 1.2, 1.2, math.sin(a) * 19, 13, (home.Position.Z - ctx.z0) + 30 + math.cos(a) * 19, "#FFD23F", "Neon")
	end
	Kit.eggPads(ctx, L, W, { plinth = "#A8C98C", plinthMat = "Sandstone", ring = "#7CFFB0" })
end

-- ─────────────────────────────────────── ONE PIECE — Dressrosa Corrida Colosseum
T.OnePiece = function(ctx, L, W)
	Kit.frame(ctx, { ground = "#E3C58F", groundMat = "Sand", wallH = 12, customWalls = true, wallMat = "Sandstone" })
	local rng = ctx.rng
	local crowd = { "#FF4F7E", "#FFD23F", "#35A2FF", "#46D95F", "#FF7A1A", "#9A5CFF", "#F4F4F4" }
	ctx.mirror(function(s)
		-- stepped colosseum stands rising outward (walls)
		for step = 0, 4 do
			local x = s * (58 + step * 4.5)
			local h = 3 + step * 4
			ctx.box("StandTier", 4.5, h, ctx.len, x, h / 2, ctx.len / 2, step % 2 == 0 and "#C9A77A" or "#B8906A", "Sandstone", { collide = true })
			-- colourful crowd suggestion
			for i = 0, 22 do
				if rng() > 0.25 then
					ctx.box("Spectator", 1.2, 2, 1.2, x + rng(-1.2, 1.2), h + 1, 5 + i * 10 + rng(-3, 3), crowd[math.floor(rng(1, 7.99))], "SmoothPlastic")
				end
			end
		end
		-- arches along the top of the stands
		for i = 0, 9 do
			local dz = 12 + i * 23
			local x = s * 80
			ctx.box("ArchPier", 3, 26, 3, x, 13, dz - 6, "#D9B98A", "Sandstone")
			ctx.box("ArchPier", 3, 26, 3, x, 13, dz + 6, "#D9B98A", "Sandstone")
			ctx.box("ArchTop", 3, 3, 15, x, 27.5, dz, "#D9B98A", "Sandstone")
			-- red pirate banner with white jolly roger
			ctx.box("PirateBanner", 0.4, 10, 7, x - s * 1.8, 19, dz, "#C0182E", "Fabric")
			B.ball(ctx.env, "JollySkull", 2.4, x - s * 2.1, 20.5, ctx.z0 + dz, "#F4F4F4", "SmoothPlastic")
			ctx.rbox("Crossbone", 0.3, 0.6, 5, x - s * 2.1, 18.4, dz, 0, "#F4F4F4", "SmoothPlastic", nil, 45)
			ctx.rbox("Crossbone", 0.3, 0.6, 5, x - s * 2.1, 18.4, dz, 0, "#F4F4F4", "SmoothPlastic", nil, -45)
		end
		-- torches along the lane edge
		for i = 0, 3 do
			fireBowl(ctx, s * 55.5, 25 + i * 55, { "#FFD23F", "#FF6A1A" }, "#6B4A2A", 4)
		end
		-- flags on poles
		for i = 0, 4 do
			local dz = 20 + i * 48
			ctx.box("FlagPole", 0.5, 34, 0.5, s * 95, 17, dz, "#6B4A2A", "Wood")
			ctx.box("Flag", 0.2, 5, 8, s * 95, 31, dz + 4, crowd[(i % 7) + 1], "Fabric")
		end
	end)
	-- arena gate at the far end + Doflamingo's string cage (pink string energy, §39)
	local home = Kit.bossStage(ctx, L, { w = 40, d = 22, col = "#C9A77A", mat = "Sandstone", h = 3 })
	local hz = home.Position.Z - ctx.z0
	ctx.box("ArenaGateL", 8, 34, 8, -26, 17, hz + 16, "#D9B98A", "Sandstone", { collide = true })
	ctx.box("ArenaGateR", 8, 34, 8, 26, 17, hz + 16, "#D9B98A", "Sandstone", { collide = true })
	ctx.box("ArenaGateTop", 60, 8, 8, 0, 36, hz + 16, "#D9B98A", "Sandstone", { collide = true })
	ctx.box("ArenaGateDark", 44, 30, 1, 0, 15, hz + 19, "#2A1A12", "Slate")
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local top = V3(0, 60, ctx.z0 + hz)
		local bottom = V3(math.sin(a) * 60, 0.5, ctx.z0 + hz + math.cos(a) * 60 - 40)
		B.segment(ctx.env, "BirdcageString", bottom, top, 0.2, "#FF6FB5", "Neon", { transparency = 0.25 })
	end
	Kit.eggPads(ctx, L, W, { plinth = "#C9A77A", plinthMat = "Sandstone", ring = "#FF6FB5" })
	Kit.laneLights(ctx, "#FFC98A", 60, 14, 50)
end

-- ─────────────────────────────────────────────────────────── NARUTO — Konoha
T.Naruto = function(ctx, L, W)
	Kit.frame(ctx, { ground = "#C9A77A", groundMat = "Ground", wallH = 10, wallMat = "Wood" })
	local rng = ctx.rng
	local roofs = { "#C0392B", "#E8452E", "#D35400", "#B03A2E" }
	ctx.mirror(function(s)
		-- one-level village houses with warm roofs (simple / light, §41)
		for i = 0, 5 do
			local dz = 14 + i * 36
			local x = s * 66
			ctx.box("HouseBody", 16, 9, 22, x, 4.5, dz + 8, "#F2E6CF", "Plaster", { collide = true })
			ctx.box("HouseBand", 16.4, 1, 22.4, x, 7.5, dz + 8, "#8C6A4A", "Wood")
			for _, r in { -1, 1 } do
				B.wedge(ctx.env, "Roof", 22.8, 4.5, 9, ctx.cf(x + r * 4.3, 11.2, dz + 8) * A(0, math.rad(r == 1 and -90 or 90), 0), roofs[(i % 4) + 1], "Slate")
			end
			ctx.box("Door", 0.4, 5, 3.6, s * 57.8, 2.5, dz + 8, "#6B4A2A", "Wood")
			local win = ctx.box("Window", 0.3, 2.4, 3, s * 57.8, 5, dz + 2, "#FFE9A8", "Neon", { transparency = 0.2 })
			B.light(win, "#FFC98A", 12, 0.8)
		end
		-- paper lanterns strung between poles along the lane
		for i = 0, 7 do
			local dz = 10 + i * 28
			ctx.box("LanternPole", 0.6, 9, 0.6, s * 55.5, 4.5, dz, "#6B4A2A", "Wood")
			local lan = B.ball(ctx.env, "PaperLantern", 1.8, s * 55.5, 8, ctx.z0 + dz + 1.5, "#E8321E", "Neon")
			if i % 2 == 0 then
				B.light(lan, "#FF9A5A", 16, 0.9)
			end
		end
		-- a few trees
		for i = 0, 2 do
			local dz = 30 + i * 80
			B.cyl(ctx.env, "TreeTrunk", 1.6, 10, s * 72, 5, ctx.z0 + dz, "#6B4A2A", "Wood")
			B.ball(ctx.env, "TreeCrown", 9, s * 72, 12, ctx.z0 + dz, "#46A83A", "Grass")
		end
	end)
	-- Hokage Rock background cue (§41)
	local rz = ctx.len + 60
	ctx.box("HokageCliff", 220, 70, 40, 0, 35, rz, "#8C7A64", "Rock")
	for i = -2, 2 do
		local x = i * 36
		B.ball(ctx.env, "HokageFace", 22, x, 52, ctx.z0 + rz - 16, "#9C8A74", "Rock")
		ctx.box("HokageBrow", 16, 3, 3, x, 56, rz - 27, "#7A6A56", "Rock")
	end
	local home = Kit.bossStage(ctx, L, { w = 36, d = 20, col = "#6B5A48", mat = "Rock", h = 2.4 })
	local hz = home.Position.Z - ctx.z0
	for i = -1, 1, 2 do
		local f = ctx.box("MadaraFlame", 1, 1, 1, i * 12, 3, hz, "#FFFFFF", "SmoothPlastic", { transparency = 1 })
		B.fire(f, { "#C77DFF", "#6A2FB0" }, 3, 26)
		B.light(f, "#9B4DFF", 24, 1.4)
	end
	-- leaf emblem banners at the portal
	ctx.mirror(function(s)
		ctx.box("LeafBanner", 0.4, 10, 5, s * 40, 22, -3, "#E8452E", "Fabric")
		B.ball(ctx.env, "LeafEmblem", 2.6, s * 40, 23, ctx.z0 - 3.4, "#FFD23F", "Neon")
	end)
	Kit.eggPads(ctx, L, W, { plinth = "#8C6A4A", plinthMat = "Wood", ring = "#FFB347" })
end

-- ────────────────────────────────────────────────────────── BERSERK — Eclipse
T.Berserk = function(ctx, L, W)
	Kit.frame(ctx, { ground = "#2A1A1C", wallH = 22, wallMat = "Basalt" })
	local rng = ctx.rng
	-- ruined route: cracked dark stones with red veins
	for i = 1, 40 do
		ctx.rbox("RuinStone", rng(6, 12), 0.5, rng(6, 12), rng(-50, 50), 0.25, rng(5, 225), rng(0, 90), "#3A2A2C", "Slate", { collide = true })
	end
	for i = 1, 22 do
		ctx.rbox("BloodVein", 0.35, 0.1, rng(5, 16), rng(-52, 52), 0.55, rng(8, 222), rng(0, 180), "#D8261E", "Neon")
	end
	ctx.mirror(function(s)
		-- jagged rock spires + twisted dead trees + ruined pillars
		for i = 0, 11 do
			local dz = 8 + i * 19 + rng(-4, 4)
			local h = rng(12, 30)
			local x = s * rng(58, 72)
			for k = 0, 2 do
				ctx.rbox("RockSpire", 4 - k, h / 3, 4 - k, x, h / 6 + k * h / 3, dz, rng(0, 90), "#1A0E10", "Basalt", { collide = k == 0 }, rng(-8, 8), rng(-8, 8))
			end
			if i % 3 == 0 then
				local base = V3(s * 57, 0, ctx.z0 + dz + 6)
				local p = base
				for k = 1, 5 do
					local nxt = p + V3(rng(-2, 2), rng(2.5, 4), rng(-2, 2))
					B.segment(ctx.env, "DeadBranch", p, nxt, 0.9 - k * 0.12, "#140A0A", "Wood")
					p = nxt
				end
			end
		end
		-- Brand of Sacrifice glyphs on the walls (glowing red)
		for i = 0, 3 do
			local dz = 30 + i * 55
			local c = ctx.cf(s * 73.8, 12, dz) * A(0, math.rad(s * 90), 0)
			B.part(ctx.env, "BrandStem", V3(0.6, 7, 0.2), c, "#FF3B30", "Neon")
			B.part(ctx.env, "BrandArm", V3(0.6, 4, 0.2), c * CF(-1.2, 2.2, 0) * A(0, 0, math.rad(35)), "#FF3B30", "Neon")
			B.part(ctx.env, "BrandArm", V3(0.6, 4, 0.2), c * CF(1.2, 2.2, 0) * A(0, 0, math.rad(-35)), "#FF3B30", "Neon")
		end
	end)
	-- the enormous crimson eclipse (§43)
	local ez = ctx.len + 120
	B.ball(ctx.env, "EclipseSun", 110, 0, 95, ctx.z0 + ez, "#050000", "SmoothPlastic")
	B.ring(ctx.env, "EclipseCorona", ctx.cf(0, 95, ez - 2) * A(math.rad(90), 0, 0), 60, 4, 48, "#FF1E1E", "Neon")
	B.ring(ctx.env, "EclipseCorona2", ctx.cf(0, 95, ez - 1) * A(math.rad(90), 0, 0), 66, 2, 48, "#8E0E0E", "Neon", { transparency = 0.3 })
	-- ruined silhouettes on the horizon
	for i = -4, 4 do
		local h = rng(30, 70)
		ctx.box("RuinSilhouette", rng(10, 20), h, 10, i * 30, h / 2, ctx.len + 60 + rng(-10, 10), "#140A0C", "Basalt")
	end
	local home = Kit.bossStage(ctx, L, { w = 30, d = 20, col = "#1A0E10", mat = "Basalt", h = 6 })
	local hz = home.Position.Z - ctx.z0
	for i = 0, 3 do
		ctx.rbox("SpireStep", 26 - i * 5, 1.5, 16 - i * 3, 0, 6.8 + i * 1.5, hz + 2, i * 12, "#241416", "Basalt", { collide = true })
	end
	Kit.eggPads(ctx, L, W, { plinth = "#1A0E10", plinthMat = "Basalt", ring = "#FF3B30" })
	Kit.laneLights(ctx, "#FF3B30", 60, 12, 40)
end

-- ─────────────────────────────────────────────────── BLEACH — Yhwach Palace (R10)
T.Bleach = function(ctx, L, W)
	Kit.frame(ctx, { ground = "#3A3D44", wallH = 60, customWalls = true })
	-- polished stone floor (light/dark) with a long dark central aisle
	for gx = -7, 6 do
		for gz = 0, 22 do
			local dark = (gx + gz) % 2 == 0
			ctx.box("FloorTile", 10.6, 0.3, 9.8, gx * 10.7 + 5.35, 0.15, gz * 10 + 5, dark and "#4B4F57" or "#5E626B", "Marble", { collide = true })
		end
	end
	ctx.box("Aisle", 20, 0.35, ctx.len, 0, 0.2, ctx.len / 2, "#15161A", "Fabric", { collide = true })
	ctx.mirror(function(s)
		ctx.box("AisleEdge", 0.4, 0.4, ctx.len, s * 10.2, 0.25, ctx.len / 2, "#CFE0FF", "Neon", { transparency = 0.3 })
		-- enormous monumental walls with pilasters (despair / dominance, §45)
		ctx.box("PalaceWall", 6, 60, ctx.len, s * 78, 30, ctx.len / 2, "#26292F", "Slate", { collide = true })
		for i = 0, 11 do
			local dz = 5 + i * 20
			ctx.box("Pilaster", 5, 64, 5, s * 74.5, 32, dz, "#1E2025", "Slate", { collide = true })
			ctx.box("PilasterCap", 7, 3, 7, s * 74.5, 63, dz, "#3A3D44", "Slate")
			if i < 11 then
				-- white hanging banners with dark insignia (Wandenreich-style star, original)
				local bz = dz + 10
				ctx.box("WhiteBanner", 0.5, 30, 8, s * 75.6, 38, bz, "#E8E8EE", "Fabric")
				local c = ctx.cf(s * 75.2, 42, bz) * A(0, math.rad(s * 90), 0)
				for k = 0, 2 do
					B.part(ctx.env, "InsigniaStroke", V3(0.7, 7, 0.2), c * A(0, 0, math.rad(k * 60)), "#15161A", "SmoothPlastic")
				end
				B.part(ctx.env, "InsigniaRing", V3(3.2, 3.2, 0.25), c, "#15161A", "SmoothPlastic")
			end
		end
		-- braziers along the approach (fire, §45)
		for i = 0, 5 do
			fireBowl(ctx, s * 52, 18 + i * 38, { "#FFB347", "#FF5A1A" }, "#2A2C31", 6)
		end
	end)
	-- grand stair + throne at the far end; Yhwach seated (§46)
	local home = Kit.bossStage(ctx, L, { w = 50, d = 24, col = "#2A2C31", h = 6 })
	local hz = home.Position.Z - ctx.z0
	for i = 0, 5 do
		ctx.box("Stair", 44 - i * 2, 1, 3, 0, 0.5 + i, hz - 12 - (5 - i) * 3 + 3, "#3A3D44", "Marble", { collide = true })
	end
	ctx.box("ThroneBack", 12, 26, 3, 0, 19, hz + 8, "#101114", "Slate", { collide = true })
	for i = -2, 2 do
		ctx.box("ThroneSpike", 1.2, 8 - math.abs(i) * 1.5, 1.2, i * 2.4, 34 - math.abs(i) * 0.75, hz + 8, "#101114", "Slate")
	end
	ctx.box("ThroneSeat", 10, 3, 8, 0, 7.5, hz + 3, "#15161A", "Slate", { collide = true })
	ctx.box("ThroneBanner", 0.5, 40, 16, 0, 38, hz + 12, "#E8E8EE", "Fabric")
	-- cold light shafts
	for i = -1, 1 do
		local a = ctx.box("ColdLight", 1, 1, 1, i * 30, 50, hz - 30, "#FFFFFF", "SmoothPlastic", { transparency = 1 })
		B.light(a, "#CFE0FF", 60, 1.2)
	end
	Kit.eggPads(ctx, L, W, { plinth = "#2A2C31", ring = "#CFE0FF", text = "#FFFFFF" })
end

-- ───────────────────────────────────────────────────────── JJK — Shibuya
T.JJK = function(ctx, L, W)
	Kit.frame(ctx, { ground = "#2E2A30", groundMat = "Asphalt", wallH = 8, customWalls = true })
	local rng = ctx.rng
	-- road markings + crosswalk + cursed cracks
	for dz = 6, ctx.len - 6, 14 do
		ctx.box("LaneDash", 0.8, 0.08, 6, 0, 0.04, dz, "#F4F4F4", "SmoothPlastic")
	end
	for i = 0, 9 do
		ctx.box("Crosswalk", 5, 0.08, 18, -45 + i * 10, 0.05, 60, "#F4F4F4", "SmoothPlastic")
	end
	for i = 1, 30 do
		ctx.rbox("CursedCrack", 0.4, 0.12, rng(5, 18), rng(-50, 50), 0.1, rng(8, 222), rng(0, 180), "#FF2E4D", "Neon")
	end
	local signs = { "SHIBUYA", "渋谷", "109", "呪術", "SALE", "HOTEL", "KARAOKE", "BAR" }
	ctx.mirror(function(s)
		ctx.box("Sidewalk", 10, 0.6, ctx.len, s * 59, 0.3, ctx.len / 2, "#6E6A72", "Concrete", { collide = true })
		-- damaged buildings form the walls (tilted / broken tops)
		local dz = 0
		local i = 0
		while dz < ctx.len - 4 do
			i += 1
			local w = rng(18, 30)
			local h = rng(30, 75)
			local x = s * (76 + w / 2)
			local tilt = (i % 4 == 0) and rng(-6, 6) or 0
			local b = ctx.rbox("Building", w, h, w, x, h / 2, dz + w / 2, 0, i % 2 == 0 and "#3A3640" or "#2B2833", "Concrete", { collide = true }, 0, tilt)
			for k = 1, math.floor(h / 6) do
				for c = -1, 1 do
					if rng() > 0.45 then
						ctx.box("LitWindow", 0.2, 2, 3, s * 75.9, k * 6 - 2, dz + w / 2 + c * (w / 3.2), rng() > 0.8 and "#FF2E4D" or "#FFE9A8", "Neon", { transparency = rng(0, 0.5) })
					end
				end
			end
			if i % 2 == 1 then
				local sign = ctx.box("NeonSign", 0.4, 6, 10, s * 75.4, rng(14, 30), dz + w / 2, "#15101A", "SmoothPlastic")
				B.surfaceText(sign, signs[(i % #signs) + 1], { face = s == 1 and "Left" or "Right", color = ({ "#FF2E4D", "#3FE0FF", "#FFD23F", "#FF6FB5" })[(i % 4) + 1], ppstud = 20 })
			end
			if tilt ~= 0 then
				for r = 1, 5 do
					ctx.rbox("Debris", rng(2, 5), rng(1, 3), rng(2, 5), s * rng(56, 66), 1, dz + rng(0, w), rng(0, 90), "#3A3640", "Concrete", nil, rng(-25, 25), rng(-25, 25))
				end
			end
			b:SetAttribute("Damaged", tilt ~= 0)
			dz += w + 1
		end
		-- street lamps + wrecked cars
		for k = 0, 4 do
			local z = 20 + k * 48
			ctx.box("LampPost", 0.6, 12, 0.6, s * 55.5, 6, z, "#1B1B22", "Metal")
			local lamp = ctx.box("Lamp", 3, 0.6, 1.4, s * 54.2, 12, z, "#FFE9A8", "Neon")
			if k % 2 == 0 then
				B.light(lamp, "#FFC98A", 22, 0.9)
			end
		end
		for k = 0, 1 do
			local z = 45 + k * 100
			ctx.rbox("WreckedCar", 5, 3, 10, s * 49, 1.5, z, rng(-30, 30), "#8E1B2E", "Metal", { collide = true }, 0, rng(-10, 10))
		end
	end)
	-- cursed energy drifting over the road
	for i = 0, 3 do
		local a = ctx.box("CursedMist", 1, 1, 1, 0, 3, 30 + i * 55, "#FFFFFF", "SmoothPlastic", { transparency = 1 })
		B.emitter(a, "CursedEnergy", { tex = "smoke", colors = { "#FF2E4D", "#3A0510" }, rate = 5, life = { 3, 5 }, speed = { 0.5, 1.5 }, size = { { 0, 4 }, { 1, 9 } }, transp = { { 0, 0.7 }, { 1, 1 } }, light = 0.4 })
	end
	-- Malevolent Shrine at the end (Sukuna, §48)
	local home = Kit.bossStage(ctx, L, { w = 44, d = 26, col = "#1A0E12", h = 2.4 })
	local hz = home.Position.Z - ctx.z0
	for i, w in { 40, 30, 20 } do
		local y = 14 + (i - 1) * 9
		for _, s in { -1, 1 } do
			B.wedge(ctx.env, "ShrineRoof", w, 5, w * 0.35, ctx.cf(0, y, hz + 12 + s * w * 0.17) * A(0, s == 1 and 0 or math.pi, 0), "#140A0C", "Slate")
		end
		ctx.box("ShrineBeam", w * 0.8, 1.4, 2, 0, y - 2.5, hz + 12, "#8E0E1E", "Wood")
	end
	for _, s in { -1, 1 } do
		ctx.box("ShrinePillar", 3, 24, 3, s * 14, 12, hz + 6, "#8E0E1E", "Wood", { collide = true })
		B.spike(ctx.env, "ShrineHorn", 3, 14, ctx.cf(s * 18, 40, hz + 12) * A(0, 0, math.rad(s * -25)), "#EDE6D6", "Marble", 5)
	end
	for i = 1, 14 do
		local x = -20 + (i - 1) * 3
		B.wedge(ctx.env, "ShrineTooth", 1.4, 4, 2, ctx.cf(x, 2 + 2, hz - 4) , "#F4F0E6", "Marble")
	end
	Kit.eggPads(ctx, L, W, { plinth = "#1A0E12", ring = "#FF2E4D" })
end

-- ──────────────────────────────────────────── SOLO LEVELING — Shadow Corridor
T.SoloLeveling = function(ctx, L, W)
	Kit.frame(ctx, { ground = "#0B0F1C", wallH = 34, last = true })
	local rng = ctx.rng
	-- black corridor floor with blue energy lines (symmetry, §50)
	for dz = 0, ctx.len - 10, 10 do
		ctx.box("CorridorSlab", 108, 0.3, 9.6, 0, 0.15, dz + 5, (dz / 10) % 2 == 0 and "#10162A" or "#0C1122", "Marble", { collide = true })
	end
	for _, x in { -30, -12, 12, 30 } do
		ctx.box("EnergyLine", 0.4, 0.12, ctx.len, x, 0.35, ctx.len / 2, "#3A7BFF", "Neon", { transparency = 0.1 })
	end
	ctx.mirror(function(s)
		-- LIVING SHADOW WALLS: rows of shadow soldiers with glowing eyes on raised platforms
		ctx.box("SoldierPlatform", 20, 3, ctx.len, s * 65, 1.5, ctx.len / 2, "#080B14", "Slate", { collide = true })
		for row = 0, 2 do
			local x = s * (58 + row * 6)
			local y0 = 3 + row * 1.2
			for i = 0, 17 do
				local dz = 8 + i * 12.5 + (row % 2) * 6
				local sc = 1 + row * 0.12 + rng(-0.05, 0.1)
				local c = ctx.cf(x, y0, dz) * A(0, math.rad(s * 90), 0)
				B.part(ctx.env, "ShadowLegs", V3(2, 3.4, 1.2) * sc, c * CF(0, 1.7 * sc, 0), "#05060C", "SmoothPlastic")
				B.part(ctx.env, "ShadowBody", V3(2.6, 3, 1.4) * sc, c * CF(0, 4.9 * sc, 0), "#070A14", "SmoothPlastic")
				B.part(ctx.env, "ShadowPauldron", V3(3.6, 0.8, 1.6) * sc, c * CF(0, 6.3 * sc, 0), "#0B1020", "Metal")
				B.part(ctx.env, "ShadowHead", V3(1.4, 1.5, 1.4) * sc, c * CF(0, 7.4 * sc, 0), "#05060C", "SmoothPlastic")
				local eyeCol = rng() > 0.2 and "#3A7BFF" or "#9B4DFF"
				for _, ex in { -0.3, 0.3 } do
					B.part(ctx.env, "ShadowEye", V3(0.28, 0.14, 0.1) * sc, c * CF(ex * sc, 7.5 * sc, -0.72 * sc), eyeCol, "Neon")
				end
				if i % 3 == 0 then
					B.part(ctx.env, "ShadowSpear", V3(0.25, 9, 0.25) * sc, c * CF(1.6 * sc, 4.5 * sc, 0), "#141A2E", "Metal")
				end
			end
		end
		-- dark smoke rising from the shadow ranks
		for i = 0, 3 do
			local a = ctx.box("ShadowMist", 1, 1, 1, s * 64, 3, 20 + i * 60, "#FFFFFF", "SmoothPlastic", { transparency = 1 })
			B.emitter(a, "ShadowSmoke", { tex = "smoke", colors = { "#0B1020", "#3A1F8F" }, rate = 5, life = { 3, 5 }, speed = { 0.5, 1.2 }, size = { { 0, 5 }, { 1, 10 } }, transp = { { 0, 0.55 }, { 1, 1 } }, light = 0.2 })
		end
		-- symmetric pillars with blue flames
		for i = 0, 4 do
			local dz = 20 + i * 48
			ctx.box("CorridorPillar", 4, 30, 4, s * 55.5, 15, dz, "#0B1020", "Slate", { collide = true })
			local f = ctx.box("BlueFlame", 1, 1, 1, s * 55.5, 31, dz, "#FFFFFF", "SmoothPlastic", { transparency = 1 })
			B.fire(f, { "#9FC4FF", "#3A7BFF" }, 2.2, 20)
			B.light(f, "#3A7BFF", 26, 1.2)
		end
	end)
	-- throne at the far end, centred: Sung Jin-Woo reclining (§50)
	local home = Kit.bossStage(ctx, L, { w = 40, d = 22, col = "#0B1020", h = 4 })
	local hz = home.Position.Z - ctx.z0
	ctx.box("ThroneBack", 14, 22, 3, 0, 15, hz + 8, "#05060C", "Slate", { collide = true })
	ctx.box("ThroneSeat", 11, 3, 8, 0, 5.5, hz + 3, "#0B1020", "Slate", { collide = true })
	for _, s in { -1, 1 } do
		ctx.box("ThroneArm", 2, 4, 8, s * 6.5, 7, hz + 3, "#141A2E", "Slate")
		ctx.box("ThroneGlow", 0.4, 22, 0.4, s * 7.2, 15, hz + 6.4, "#6A5BFF", "Neon")
	end
	for i = -3, 3 do
		ctx.box("ThroneCrown", 1, 6 - math.abs(i), 1, i * 2, 27 - math.abs(i) * 0.5, hz + 8, "#3A7BFF", "Neon")
	end
	Kit.eggPads(ctx, L, W, { plinth = "#0B1020", ring = "#3A7BFF" })
end

return T
