--!strict
-- StagingValidateRestore: validate a combined-scene world import in Roblox Studio against its Blender export
-- manifest, and (optionally) restore the manifest's Roblox Material / Color / Transparency / CanCollide, and build
-- the gameplay colliders + VFX / egg anchors. Studio-only tooling (edit mode, command bar). Never touches Akaza.
--
-- Setup (once): put this ModuleScript and the generated data modules (tools/studio/world_data/<World>.lua, as
-- ModuleScripts named <World>) under ServerStorage.SAE_WorldStaging.
--
-- Command bar:
--   local T = require(game.ServerStorage.SAE_WorldStaging.StagingValidateRestore)
--   T.run("SoloLeveling", workspace.STAGING.SoloLeveling_Combined_Final)                     -- DEFAULT: validate + report only
--   T.run("SoloLeveling", workspace.STAGING.SoloLeveling_Combined_Final, { restore = true })   -- explicit: restore Material/Color/...
--   T.run("SoloLeveling", workspace.STAGING.SoloLeveling_Combined_Final, { build = true })     -- explicit: build colliders + anchors
--
-- The tool NEVER moves, rotates or rescales imported pieces. A bad import (missing pieces, 100x / 0.01x scale, moved
-- pieces) is reported so the world can be re-imported correctly; geometry is not "fixed" in place.
-- Geometry PASS/FAIL and appearance (Material/Color) are reported separately: raw FBX imports arrive gray, so an
-- appearance mismatch before { restore = true } is expected and does not fail geometry validation.
--
-- Import the combined FBX with the 3D Importer at scale 0.01 (validated during MHA staging). Pieces keep their
-- FBX object names; a missing name or a size off by ~100x means a bad import, not bad art.

local T = {}

local SIZE_TOL = 0.02 -- studs (+0.1% relative)
local POS_TOL = 0.05 -- studs, after removing the common import offset
local ROT_TOL = 0.5 -- degrees (pieces are exported with transforms applied)

local function collectMeshParts(root: Instance): { [string]: { MeshPart } }
	local byName: { [string]: { MeshPart } } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("MeshPart") then
			byName[d.Name] = byName[d.Name] or {}
			table.insert(byName[d.Name], d)
		end
	end
	return byName
end

function T.run(worldId: string, root: Instance, opts: { restore: boolean?, build: boolean? }?, dataOverride: any?)
	local o = opts or {}
	-- dataOverride: pass the world data table directly (offline Lune tests); in Studio it is required by name
	local data = dataOverride or (require((script :: any).Parent:FindFirstChild(worldId) :: ModuleScript) :: any)
	local parts = collectMeshParts(root)
	local report = { world = worldId, expected = data.pieceCount, matched = 0, missing = {}, duplicates = {},
		unexpected = {}, sizeErrors = {}, posErrors = {}, rotErrors = {}, appearance = {}, restored = 0,
		scaleHint = nil :: string?, offset = Vector3.new(0, 0, 0), geometryPass = false, appearancePass = false }
	local matched: { { part: MeshPart, spec: any } } = {}
	local expectedNames: { [string]: boolean } = {}
	for _, spec in data.pieces do
		expectedNames[spec.name] = true
		local list = parts[spec.name]
		if not list then
			table.insert(report.missing, spec.name)
		else
			if #list > 1 then
				table.insert(report.duplicates, spec.name .. " x" .. #list)
			end
			table.insert(matched, { part = list[1], spec = spec })
		end
	end
	for name in parts do
		if not expectedNames[name] then
			table.insert(report.unexpected, name)
		end
	end
	report.matched = #matched
	-- sizes + scale sanity
	local ratioSum, ratioN = 0, 0
	for _, m in matched do
		local e: Vector3, a: Vector3 = m.spec.size, m.part.Size
		local big = math.max(e.X, e.Y, e.Z)
		if big > 1 then
			ratioSum += math.max(a.X, a.Y, a.Z) / big
			ratioN += 1
		end
		local d = (a - e).Magnitude
		if d > SIZE_TOL + 0.001 * e.Magnitude then
			table.insert(report.sizeErrors, string.format("%s size %s expected %s (delta %.3f studs)", m.spec.name, tostring(a), tostring(e), d))
		end
		-- rotation angle from the CFrame matrix trace (pieces are exported with transforms applied -> identity)
		local _, _, _, r00, _, _, _, r11, _, _, _, r22 = m.part.CFrame:GetComponents()
		local angle = math.deg(math.acos(math.clamp((r00 + r11 + r22 - 1) / 2, -1, 1)))
		if angle > ROT_TOL then
			table.insert(report.rotErrors, string.format("%s rotated %.2f deg", m.spec.name, angle))
		end
	end
	local ratio = ratioN > 0 and ratioSum / ratioN or 1
	if ratio > 20 then
		report.scaleHint = string.format("pieces are ~%.0fx too large: re-import at scale 0.01", ratio)
	elseif ratio < 0.05 then
		report.scaleHint = string.format("pieces are ~%.3fx (collapsed): check the importer scale", ratio)
	end
	-- positions relative to the common import offset
	local sum = Vector3.new(0, 0, 0)
	for _, m in matched do
		sum += m.part.CFrame.Position - m.spec.position
	end
	local offset = #matched > 0 and sum / #matched or Vector3.new(0, 0, 0)
	report.offset = offset
	for _, m in matched do
		local delta = m.part.CFrame.Position - (m.spec.position + offset)
		if delta.Magnitude > POS_TOL then
			table.insert(report.posErrors, string.format("%s off by %.3f studs (delta %s)", m.spec.name, delta.Magnitude, tostring(delta)))
		end
	end
	-- appearance (Material / Color / Transparency / CanCollide) against the manifest
	local function appearanceIssues(p: MeshPart, s: any): { string }
		local out = {}
		local want = Color3.fromHex(s.color)
		local c = p.Color
		if math.max(math.abs(c.R - want.R), math.abs(c.G - want.G), math.abs(c.B - want.B)) > 1.5 / 255 then
			table.insert(out, "color")
		end
		if p.Material.Name ~= s.material then
			table.insert(out, "material " .. p.Material.Name .. "->" .. s.material)
		end
		if math.abs(p.Transparency - s.transparency) > 0.01 then
			table.insert(out, "transparency")
		end
		if p.CanCollide ~= s.canCollide then
			table.insert(out, "canCollide")
		end
		return out
	end
	for _, m in matched do
		local issues = appearanceIssues(m.part, m.spec)
		if #issues > 0 then
			table.insert(report.appearance, m.spec.name .. ": " .. table.concat(issues, ", "))
		end
	end
	-- restore appearance + collision from the manifest (FBX imports arrive gray)
	if o.restore then
		for _, m in matched do
			local p, s = m.part, m.spec
			p.Anchored = true
			p.Color = Color3.fromHex(s.color)
			local ok, mat = pcall(function()
				return (Enum.Material :: any)[s.material]
			end)
			if ok and mat then
				p.Material = mat
			end
			p.Transparency = s.transparency
			p.CanCollide = s.canCollide
			p.CanTouch = s.canCollide
			p:SetAttribute("SAE_Layer", s.layer)
			report.restored += 1
		end
		-- re-check after the explicit restore
		table.clear(report.appearance)
		for _, m in matched do
			local issues = appearanceIssues(m.part, m.spec)
			if #issues > 0 then
				table.insert(report.appearance, m.spec.name .. ": " .. table.concat(issues, ", "))
			end
		end
	end
	-- gameplay colliders + VFX / egg anchors, positioned with the same import offset
	if o.build then
		local model = root :: Instance
		local cols = model:FindFirstChild("V02_Colliders") or Instance.new("Folder")
		cols.Name = "V02_Colliders"
		cols.Parent = model
		for _, c in data.colliders do
			local p = Instance.new("Part")
			p.Name = c.name
			p.Anchored, p.CanCollide, p.CanTouch = true, true, false
			p.Transparency = 1
			p.Size = c.size
			p.CFrame = CFrame.new(c.position + offset)
			p.Parent = cols
		end
		local vfx = model:FindFirstChild("V02_VFX") or Instance.new("Part")
		vfx.Name = "V02_VFX"
		local root0 = vfx :: Part
		root0.Anchored, root0.CanCollide, root0.CanTouch, root0.CanQuery = true, false, false, false
		root0.Transparency, root0.Size, root0.CFrame = 1, Vector3.new(1, 1, 1), CFrame.new(offset)
		root0.Parent = model
		for _, a in data.anchors do
			local att = Instance.new("Attachment")
			att.Name = a.name
			att.Position = a.position
			att:SetAttribute("Kind", a.kind)
			att.Parent = root0
		end
	end
	local pass = #report.missing == 0 and #report.duplicates == 0 and #report.unexpected == 0 and #report.sizeErrors == 0
		and #report.posErrors == 0 and #report.rotErrors == 0 and report.scaleHint == nil and report.matched == data.pieceCount
	report.geometryPass = pass
	report.appearancePass = #report.appearance == 0
	print(string.format("[SAE staging] %s: GEOMETRY %s  matched %d/%d  missing %d  duplicates %d  unexpected %d  size %d  pos %d  rot %d  offset %s%s",
		worldId, pass and "PASS" or "FAIL", report.matched, data.pieceCount, #report.missing, #report.duplicates,
		#report.unexpected, #report.sizeErrors, #report.posErrors, #report.rotErrors, tostring(offset),
		report.scaleHint and ("  SCALE: " .. report.scaleHint) or ""))
	print(string.format("[SAE staging] %s: APPEARANCE %s  mismatched %d  restored %d%s", worldId,
		report.appearancePass and "OK" or "MISMATCH", #report.appearance, report.restored,
		(not report.appearancePass and not o.restore) and "  (raw FBX imports are gray: run with { restore = true })" or ""))
	for _, k in { "missing", "duplicates", "unexpected", "sizeErrors", "posErrors", "rotErrors", "appearance" } do
		for i, v in (report :: any)[k] do
			if i > 10 then
				break
			end
			print("   ", k, v)
		end
	end
	print(string.format("[SAE staging] %s egg anchors in data: %d", worldId, data.eggAnchorCount))
	return pass, report
end

return T
