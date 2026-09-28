--!nocheck
-- Lune harness: loads Roblox-style ModuleScripts (which use `require(script.Parent.X)`)
-- from game/src/shared as plain files, with a tiny `script` shim.
local fs = require("@lune/fs")
local luau = require("@lune/luau")

local H = {}
local cache = {}

local function makeScript(dir: string, name: string)
	local parent = setmetatable({}, {
		__index = function(_, child)
			return { __module = dir .. "/" .. child .. ".lua", Name = child }
		end,
	})
	return { Name = name, Parent = parent }
end

local function load(path: string)
	if cache[path] ~= nil then
		return cache[path]
	end
	local dir, name = string.match(path, "^(.*)/([^/]+)%.lua$")
	local env = setmetatable({
		script = makeScript(dir, name),
		require = function(m)
			if type(m) == "table" and m.__module then
				return load(m.__module)
			end
			return require(m)
		end,
	}, { __index = _G })
	local chunk = luau.load(fs.readFile(path), { debugName = name, environment = env })
	local result = chunk()
	cache[path] = result
	return result
end

function H.shared(name: string)
	return load("game/src/shared/" .. name .. ".lua")
end

-- minimal test runner
local passed, failed = 0, 0
local current = ""
function H.section(name: string)
	current = name
	print("[" .. name .. "]")
end
function H.check(cond: any, msg: string)
	if cond then
		passed += 1
	else
		failed += 1
		print("  FAIL (" .. current .. "): " .. msg)
	end
end
function H.eq(a: any, b: any, msg: string)
	H.check(a == b, msg .. " (got " .. tostring(a) .. ", expected " .. tostring(b) .. ")")
end
function H.finish(): number
	print(string.format("\n%d passed, %d failed", passed, failed))
	return failed
end

return H
