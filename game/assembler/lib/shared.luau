--!nocheck
-- Loads Roblox-style shared ModuleScripts (game/src/shared) under Lune.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local cache = {}
local ROOT = "game/src/shared/"
local function load(name)
	if cache[name] ~= nil then return cache[name] end
	local env = setmetatable({
		script = { Name = name, Parent = setmetatable({}, { __index = function(_, k) return { __module = k } end }) },
		require = function(m)
			if type(m) == "table" and m.__module then return load(m.__module) end
			return require(m)
		end,
		warn = print,
	}, { __index = _G })
	local r = luau.load(fs.readFile(ROOT .. name .. ".lua"), { debugName = name, environment = env })()
	cache[name] = r
	return r
end
return load
