-- Offline (STATICALLY TESTED) check of tools/studio/StagingValidateRestore.lua with @lune/roblox. No Roblox Studio:
-- synthetic "imported" worlds are built from the generated data modules, then each defect case is injected.
--   lune run tools/studio/tests/staging_validator_test.luau
-- Cases per world: A correct -> PASS; B missing piece; C duplicate piece; D 100x scale; D2 0.01x scale; E moved
-- piece; F wrong size; G wrong rotation; H material/colour mismatch detected, then restored with { restore = true }.
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Instance, Vector3, CFrame, Color3, Enum = roblox.Instance, roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Enum

local env = { Vector3 = Vector3, CFrame = CFrame, Color3 = Color3, Enum = Enum, Instance = Instance, print = function() end,
	string = string, math = math, table = table, pcall = pcall, require = require, tostring = tostring, ipairs = ipairs, pairs = pairs }
local function load(path: string)
	return luau.load(luau.compile(fs.readFile(path)), { debugName = path, environment = env, injectGlobals = true })()
end
local T = load("tools/studio/StagingValidateRestore.lua")
local failures, checks = 0, 0
local function check(name: string, cond: boolean)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end
local function has(list: { string }, needle: string): boolean
	for _, v in list do
		if string.find(v, needle, 1, true) then
			return true
		end
	end
	return false
end

local totals = { pieces = 0, anchors = 0, eggs = 0, colliders = 0 }
for _, world in { "MHA", "DragonBall", "OnePiece", "Naruto", "Bleach", "JJK", "SoloLeveling" } do
	local data = load("tools/studio/world_data/" .. world .. ".lua")
	totals.pieces += #data.pieces
	totals.anchors += #data.anchors
	totals.eggs += data.eggAnchorCount
	totals.colliders += #data.colliders
	check(world .. " pieceCount matches list", #data.pieces == data.pieceCount)
	local function build(mutate: ((Instance, { [string]: any }) -> ())?, painted: boolean?)
		local model = Instance.new("Model")
		local off = Vector3.new(1000, 50, -300)
		local byName = {}
		for _, p in data.pieces do
			local mp = Instance.new("MeshPart")
			mp.Name = p.name
			mp.Size = p.size
			mp.CFrame = CFrame.new(p.position + off)
			if painted then
				mp.Color = Color3.fromHex(p.color)
				mp.Material = (Enum.Material :: any)[p.material]
				mp.Transparency = p.transparency
				mp.CanCollide = p.canCollide
			end
			mp.Parent = model
			byName[p.name] = mp
		end
		if mutate then
			mutate(model, byName)
		end
		return model
	end
	local first, second = data.pieces[1].name, data.pieces[2].name
	-- A: correct import (appearance painted like after a restore) -> geometry PASS + appearance OK
	local okA, rA = T.run(world, build(nil, true), nil, data)
	check(world .. " A correct -> PASS", okA and rA.appearancePass and rA.matched == data.pieceCount)
	-- B: one missing piece -> FAIL naming it
	local okB, rB = T.run(world, build(function(_, n) n[first]:Destroy() end), nil, data)
	check(world .. " B missing piece named", not okB and has(rB.missing, first))
	-- C: duplicate piece -> FAIL naming it
	local okC, rC = T.run(world, build(function(m, n) n[second]:Clone().Parent = m end), nil, data)
	check(world .. " C duplicate named", not okC and has(rC.duplicates, second))
	-- D: 100x scale -> FAIL with scale diagnosis; D2: 0.01x -> collapsed diagnosis
	local okD, rD = T.run(world, build(function(m) for _, c in m:GetChildren() do (c :: any).Size *= 100 end end), nil, data)
	check(world .. " D 100x scale diagnosed", not okD and rD.scaleHint ~= nil and string.find(rD.scaleHint, "0.01", 1, true) ~= nil)
	local okD2, rD2 = T.run(world, build(function(m) for _, c in m:GetChildren() do (c :: any).Size *= 0.01 end end), nil, data)
	check(world .. " D2 0.01x scale diagnosed", not okD2 and rD2.scaleHint ~= nil and string.find(rD2.scaleHint, "collapsed", 1, true) ~= nil)
	-- E: moved piece -> FAIL with delta
	local okE, rE = T.run(world, build(function(_, n) n[second].CFrame = n[second].CFrame + Vector3.new(0, 3, 0) end), nil, data)
	check(world .. " E moved piece with delta", not okE and has(rE.posErrors, second) and has(rE.posErrors, "delta"))
	-- F: wrong size -> FAIL with size delta
	local okF, rF = T.run(world, build(function(_, n) n[second].Size += Vector3.new(2, 0, 0) end), nil, data)
	check(world .. " F wrong size with delta", not okF and has(rF.sizeErrors, second) and has(rF.sizeErrors, "delta 2.000"))
	-- G: wrong rotation -> FAIL with angle
	local okG, rG = T.run(world, build(function(_, n) n[second].CFrame = n[second].CFrame * CFrame.Angles(0, math.rad(15), 0) end), nil, data)
	check(world .. " G rotation mismatch", not okG and has(rG.rotErrors, second) and has(rG.rotErrors, "15.00 deg"))
	-- H: gray raw import -> appearance mismatch reported (geometry still PASS); explicit restore fixes it
	local model = build()
	local okH, rH = T.run(world, model, nil, data)
	check(world .. " H mismatch detected, geometry PASS", okH and not rH.appearancePass and #rH.appearance > 0)
	local okH2, rH2 = T.run(world, model, { restore = true }, data)
	check(world .. " H restore -> appearance OK", okH2 and rH2.appearancePass and rH2.restored == data.pieceCount)
	-- default mode never moves / rescales: positions unchanged after a validation run
	local mB = build()
	local before = (mB:GetChildren()[1] :: any).CFrame.Position
	T.run(world, mB, nil, data)
	check(world .. " validate-only does not move pieces", ((mB:GetChildren()[1] :: any).CFrame.Position - before).Magnitude < 1e-6)
	-- build mode: colliders + anchors created from data
	local mBuild = build()
	T.run(world, mBuild, { build = true }, data)
	local vfx = mBuild:FindFirstChild("V02_VFX")
	check(world .. " build anchors", vfx ~= nil and #vfx:GetChildren() == #data.anchors)
	check(world .. " build colliders", #(mBuild:FindFirstChild("V02_Colliders") :: any):GetChildren() == #data.colliders)
end
print(string.format("totals: pieces %d, effect anchors %d, egg anchors %d, colliders %d", totals.pieces, totals.anchors, totals.eggs, totals.colliders))
check("totals: 36 egg anchors", totals.eggs == 36)
check("totals: 154 effect anchors", totals.anchors == 154)
check("totals: 26 colliders", totals.colliders == 26)
check("totals: 437 pieces", totals.pieces == 437)
print(failures == 0 and string.format("ALL %d STAGING VALIDATOR CHECKS PASSED", checks) or string.format("FAILURES: %d of %d", failures, checks))
