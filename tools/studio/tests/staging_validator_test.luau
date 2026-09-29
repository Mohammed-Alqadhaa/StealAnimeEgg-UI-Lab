-- Offline test of tools/studio/StagingValidateRestore.lua with @lune/roblox (no Studio): builds synthetic imported
-- worlds from the generated data modules and checks PASS / FAIL detection.
--   lune run tools/studio/tests/staging_validator_test.luau
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Instance, Vector3 = roblox.Instance, roblox.Vector3

local env = { Vector3 = Vector3, CFrame = roblox.CFrame, Color3 = roblox.Color3, Enum = roblox.Enum, Instance = Instance, print = print,
	string = string, math = math, table = table, pcall = pcall, require = require, tostring = tostring, ipairs = ipairs, pairs = pairs }
local function load(path: string)
	local fn = luau.load(luau.compile(fs.readFile(path)), { debugName = path, environment = env, injectGlobals = true })
	return fn()
end
local T = load("tools/studio/StagingValidateRestore.lua")
local failures = 0
local function check(name: string, cond: boolean)
	print((cond and "ok   " or "FAIL ") .. name)
	if not cond then
		failures += 1
	end
end

for _, world in { "MHA", "DragonBall", "OnePiece", "Naruto", "Bleach", "JJK", "SoloLeveling" } do
	local data = load("tools/studio/world_data/" .. world .. ".lua")
	local function build(mutate: ((Instance) -> ())?)
		local model = Instance.new("Model")
		model.Name = world .. "_Combined_Final"
		local off = Vector3.new(1000, 50, -300)
		for _, p in data.pieces do
			local mp = Instance.new("MeshPart")
			mp.Name = p.name
			mp.Size = p.size
			mp.CFrame = roblox.CFrame.new(p.position + off)
			mp.Parent = model
		end
		if mutate then
			mutate(model)
		end
		return model
	end
	local pass, rep = T.run(world, build(), { restore = true, build = true }, data)
	check(world .. ": correct import passes (" .. rep.matched .. "/" .. data.pieceCount .. ")", pass)
	check(world .. ": egg anchors " .. data.eggAnchorCount, data.eggAnchorCount == (world == "JJK" and 6 or 5))
	local p2 = T.run(world, build(function(m)
		m:GetChildren()[1]:Destroy()
	end), nil, data)
	check(world .. ": missing piece detected", not p2)
	local p3 = T.run(world, build(function(m)
		for _, c in m:GetChildren() do
			(c :: any).Size *= 100
		end
	end), nil, data)
	check(world .. ": 100x scale detected", not p3)
	local p4 = T.run(world, build(function(m)
		local c = m:GetChildren()[2] :: any
		c.CFrame = c.CFrame + Vector3.new(0, 3, 0)
	end), nil, data)
	check(world .. ": moved piece detected", not p4)
end
print(failures == 0 and "ALL STAGING VALIDATOR TESTS PASSED" or ("FAILURES: " .. failures))
