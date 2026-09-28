--!nocheck
--[[
	Akaza (Demon Slayer world) preservation fingerprint.
	  lune run game/tests/akaza_fingerprint.luau write <place.rbxlx> <manifest.json>
	  lune run game/tests/akaza_fingerprint.luau check <place.rbxlx> <manifest.json>
	`write` records every BasePart of Workspace.SAE_World.Worlds.DemonSlayer.Environment and the
	approved egg Visuals (path, class, size, CFrame, material, color, transparency, mesh/texture ids,
	SurfaceAppearance ids). `check` fails if any recorded part is missing or changed. New parts ADDED
	under the world are reported but allowed: v02 improvements must be additive or non-destructive.
]]
local fs = require("@lune/fs")
local R = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")

local mode, placePath, manifestPath = process.args[1], process.args[2], process.args[3]
assert(mode == "write" or mode == "check", "usage: write|check <place> <manifest>")
local game = R.deserializePlace(fs.readFile(placePath))
local world = game:GetService("Workspace").SAE_World.Worlds.DemonSlayer

local function r(n)
	return math.floor(n * 1000 + 0.5) / 1000
end
local function prop(inst, name)
	local ok, v = pcall(function()
		return inst[name]
	end)
	return ok and tostring(v) or nil
end
local function key(inst)
	-- path + sibling index (names repeat, e.g. WaterfallMotion ×8)
	local parts = {}
	local cur = inst
	while cur and cur ~= world do
		local idx, i = 0, 0
		for _, s in cur.Parent:GetChildren() do
			if s.Name == cur.Name then
				i += 1
				if s == cur then
					idx = i
				end
			end
		end
		table.insert(parts, 1, cur.Name .. "#" .. idx)
		cur = cur.Parent
	end
	return table.concat(parts, "/")
end
local function record(inst)
	local cf = { inst.CFrame:GetComponents() }
	for i, v in cf do
		cf[i] = r(v)
	end
	local c = inst.Color
	local sa = inst:FindFirstChildOfClass("SurfaceAppearance")
	return {
		class = inst.ClassName,
		size = { r(inst.Size.X), r(inst.Size.Y), r(inst.Size.Z) },
		cf = cf,
		material = inst.Material.Name,
		color = { r(c.R), r(c.G), r(c.B) },
		transparency = r(inst.Transparency),
		mesh = prop(inst, "MeshId") or prop(inst, "MeshContent"),
		texture = prop(inst, "TextureID"),
		sa = sa and (prop(sa, "ColorMap") or prop(sa, "ColorMapContent")) or nil,
	}
end
local function collect()
	local out = {}
	local roots = { world:FindFirstChild("Environment") }
	for _, s in world.Eggs:GetChildren() do
		if s:GetAttribute("ApprovedAsset") then
			table.insert(roots, s:FindFirstChild("Visual"))
		end
	end
	for _, root in roots do
		for _, d in root:GetDescendants() do
			if d:IsA("BasePart") then
				out[key(d)] = record(d)
			end
		end
	end
	return out
end

local current = collect()
local n = 0
for _ in current do
	n += 1
end
if mode == "write" then
	fs.writeFile(manifestPath, serde.encode("json", { source = placePath, parts = n, fingerprint = current }, true))
	print(string.format("wrote %s (%d parts)", manifestPath, n))
	return
end
local manifest = serde.decode("json", fs.readFile(manifestPath))
local missing, changed, added = {}, {}, 0
for k, want in manifest.fingerprint do
	local got = current[k]
	if not got then
		table.insert(missing, k)
	elseif serde.encode("json", got) ~= serde.encode("json", want) then
		table.insert(changed, k)
	end
end
for k in current do
	if not manifest.fingerprint[k] then
		added += 1
	end
end
print(string.format("Akaza preservation: %d recorded parts, %d missing, %d changed, %d added (added is allowed)", manifest.parts, #missing, #changed, added))
for i = 1, math.min(10, #missing) do
	print("  MISSING " .. missing[i])
end
for i = 1, math.min(10, #changed) do
	print("  CHANGED " .. changed[i])
end
process.exit((#missing == 0 and #changed == 0) and 0 or 1)
