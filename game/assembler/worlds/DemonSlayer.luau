--!nocheck
--[[
	DemonSlayer — retains and upgrades the existing approved Akaza world (§32).

	Width ×1.5 (§27): the walkable wall-to-wall width goes from 100 to 150 studs.
	Implementation mirrors the Owner-approved "width-only refinement" technique already
	used by BlenderEnvironment: authored detail is TRANSLATED outward (never globally
	scaled), and the floor is extended with clones of the authored tiles.
	  * every part whose centre |x| > 20 moves outward by 25 studs (walls, masks, bamboo,
	    lanterns, river, waterfalls, rocks, railings, torii pillars, light anchors)
	  * authored floor tiles with 12 < |x| ≤ 36.5 are cloned 25 studs further out
	  * the continuous walk surface grows 72 → 122; the torii crossbeam 70 → 120
	  * entrance return walls are widened to meet the hub exit
	  * adds the moon (local night sky cue) — lighting itself is client-local (§32, §137)
	The central arena, compass needle, egg pedestals and approved eggs are untouched.
]]
local B = require("../lib/B")
local V3, CF = B.V3, B.CF

local DS = {}

DS.SHIFT = 25

function DS.widen(env, report)
	local moved, cloned = 0, 0
	local floorClones = {}
	for _, d in env:GetDescendants() do
		if d:IsA("BasePart") then
			local x = d.CFrame.Position.X
			local name = d.Name
			local isFloorTile = d.Parent and d.Parent.Name == "Floor"
			if isFloorTile then
				if math.abs(x) > 12 and math.abs(x) <= 36.5 then
					table.insert(floorClones, d)
				end
			elseif name == "ContinuousWalkSurface" then
				d.Size = V3(d.Size.X + DS.SHIFT * 2, d.Size.Y, d.Size.Z)
			elseif name == "ToriiExtendedCrossbeam" then
				d.Size = V3(d.Size.X + DS.SHIFT * 2, d.Size.Y, d.Size.Z)
			elseif math.abs(x) > 20 then
				d.CFrame = d.CFrame + V3(x > 0 and DS.SHIFT or -DS.SHIFT, 0, 0)
				moved += 1
			end
		end
	end
	for _, tile in floorClones do
		local x = tile.CFrame.Position.X
		local c = tile:Clone()
		c.CFrame = tile.CFrame + V3(x > 0 and DS.SHIFT or -DS.SHIFT, 0, 0)
		c.Name = tile.Name .. "_W15"
		c.Parent = tile.Parent
		cloned += 1
	end
	-- entrance return walls: span from the side wall (±76) to the hub exit opening (±42)
	for _, d in env:GetChildren() do
		if d.Name == "EntranceReturnWall" or d.Name == "EntranceReturnTrim" then
			local sx = d.CFrame.Position.X > 0 and 1 or -1
			d.Size = V3(34, d.Size.Y, d.Size.Z)
			d.CFrame = CF(sx * 59, d.CFrame.Position.Y, d.CFrame.Position.Z)
		end
	end
	if report then
		report.moved = moved
		report.floorTilesCloned = cloned
	end
end

function DS.decorate(worldModel, L)
	local env = B.model(worldModel, "NightDressing")
	-- the moon (§32): large, softly glowing, high above the arena
	local moon = B.ball(env, "Moon", 46, -60, 150, L.worldZ0(1) + 330, "#F4F0DA", "Neon")
	moon.CastShadow = false
	B.light(moon, "#BFD8FF", 60, 0.8)
	B.ball(env, "MoonHalo", 58, -60, 150, L.worldZ0(1) + 332, "#9FC4FF", "Neon", { transparency = 0.85 })
	-- tall invisible colliders beside the (moved) side boundaries — linear route
	for _, s in { -1, 1 } do
		B.box(env, "WallCollider", 4, 90, 240, s * 78, 45, L.worldZ0(1) + 115, "#FFFFFF", "SmoothPlastic", { collide = true, transparency = 1 })
	end
	-- entry title arch continuity with other worlds (title only, keeps the torii as the hero)
	local title = B.box(env, "WorldTitle", 60, 5, 2, 0, 44, L.worldZ0(1) + 8, "#1C2B40", "Slate")
	B.surfaceText(title, "WORLD 1 • DEMON SLAYER", { face = "Back", color = "#44B9DC", name = "TitleIn" })
	B.surfaceText(title, "◀ BACK TO THE FARM", { face = "Front", color = "#7CFF5A", name = "TitleOut" })
	return env
end

return DS
