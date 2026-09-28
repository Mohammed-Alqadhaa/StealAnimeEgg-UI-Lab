--!nocheck
-- Export BaseParts of a subtree to compact JSON for the three.js review viewer
-- (tools/partview). Review aid only — NOT a Roblox renderer.
local serde = require("@lune/serde")
local fs = require("@lune/fs")

local E = {}

local function r3(n)
	return math.floor(n * 1000 + 0.5) / 1000
end

function E.collect(roots, opts)
	opts = opts or {}
	local out = {}
	for _, root in roots do
		local list = root:GetDescendants()
		if root:IsA("BasePart") then
			table.insert(list, root)
		end
		for _, d in list do
			if d:IsA("BasePart") and d.Transparency < 0.98 then
				local cf = d.CFrame
				local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
				local shape = "Block"
				if d.ClassName == "WedgePart" then
					shape = "Wedge"
				elseif d.ClassName == "CornerWedgePart" then
					shape = "Wedge"
				elseif d.ClassName == "MeshPart" then
					shape = "Mesh"
				elseif d.ClassName == "Part" then
					shape = d.Shape.Name
					local sm = d:FindFirstChildOfClass("SpecialMesh")
					if sm then
						if sm.MeshType.Name == "Sphere" then
							shape = "Ellipsoid"
						elseif sm.MeshType.Name == "Head" then
							shape = "Head"
						elseif sm.MeshType.Name == "FileMesh" then
							shape = "Mesh"
						end
					end
				elseif d.ClassName == "UnionOperation" then
					shape = "Mesh"
				end
				local c = d.Color
				local light = nil
				local pl = d:FindFirstChildWhichIsA("Light")
				if pl and pl.Enabled then
					local lc = pl.Color
					light = { r3(lc.R), r3(lc.G), r3(lc.B), pl.Range, pl.Brightness }
				end
				table.insert(out, {
					s = { r3(d.Size.X), r3(d.Size.Y), r3(d.Size.Z) },
					cf = { r3(x), r3(y), r3(z), r3(r00), r3(r01), r3(r02), r3(r10), r3(r11), r3(r12), r3(r20), r3(r21), r3(r22) },
					c = { r3(c.R), r3(c.G), r3(c.B) },
					m = d.Material.Name,
					sh = shape,
					t = r3(d.Transparency),
					l = light,
				})
			end
		end
	end
	return out
end

function E.write(path, roots, meta)
	local data = { meta = meta or {}, parts = E.collect(roots) }
	fs.writeFile(path, serde.encode("json", data))
	return #data.parts
end

return E
