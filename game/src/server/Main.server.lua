--[[
	Steal an Anime Egg — server bootstrap (replaces legacy Phase1Init).

	Boot order: remotes → data → farms → eggs → gameplay services → round loop.
	Every service receives the same `deps` table (explicit dependency injection, no
	globals, no require cycles).
]]

local root = script.Parent

local deps = {}
local function load(name: string)
	deps[name] = require(root:WaitForChild(name))
	return deps[name]
end

local order = {
	"Remotes",
	"DataService",
	"FarmService",
	"EggService",
	"RoundService",
	"BossService",
	"CharacterService",
	"HatchService",
	"FarmCharacterService",
	"TreadmillService",
	"MovementService",
	"TrailService",
	"PvPService",
	"SignService",
	"MarketService",
	"DevService",
}
for _, name in order do
	load(name)
end

-- Init (no cross-service calls yet)
deps.Remotes.Init()
deps.DataService.Init()
deps.FarmService.Init()
deps.EggService.Init()

-- Start
deps.DataService.Start(deps.Remotes)
deps.FarmService.Start()
deps.EggService.Start(deps)
deps.BossService.Start(deps)
deps.CharacterService.Start(deps)
deps.HatchService.Start(deps)
deps.FarmCharacterService.Start(deps)
deps.TreadmillService.Start(deps)
deps.MovementService.Start(deps)
deps.TrailService.Start(deps)
deps.PvPService.Start(deps)
deps.SignService.Start(deps)
deps.MarketService.Start(deps)
deps.DevService.Start(deps)
deps.RoundService.Start(deps) -- last: starts the first round once everything listens

workspace:SetAttribute("SAE_ServerReady", true)
print(
	string.format(
		"[SAE] server online — %d egg spawns, %d bosses, data %s",
		deps.EggService.Count(),
		deps.BossService.Count(),
		deps.DataService.IsPersistent() and "PERSISTENT" or "IN-MEMORY"
	)
)
