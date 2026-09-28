--[[
	SAE Studio Play-mode test harness  (ServerScriptService.SAE_StudioTests.Runner)

	STUDIO ONLY. Does nothing unless BOTH:
	  * RunService:IsStudio()
	  * ServerStorage attribute  SAE_EnableStudioTests = true   (set in the Command Bar before Play)
	Live servers: IsStudio() is false → the script prints nothing and exits; the service test
	hooks it uses (TestGate) are inert as well.

	Drives the REAL server services (same modules Main.server.lua booted): real remotes path
	(rate limit + mutation lock), real safe-zone loop, real round loop, real bosses/PvP.

	Optional ServerStorage attributes:
	  SAE_TestRealHatch              = true  wait the real 60 s hatch instead of fast-forwarding
	  SAE_TestInteractive            = true  ask the tester to run on the treadmill if the
	                                         server cannot drive the character itself
	  SAE_TestDisconnect             = true  (2+ players) ask the tester to close Player2
	  SAE_TestPlayers                = n     wait for n players before starting (default 1)
	  SAE_StudioTestsAllowPersistent = true  allow running while DataStore API access is ON
	                                         (profiles are backed up and restored at the end)

	Output: one line per test in Studio Output
	  [SAE_TESTS] PASS   [Subsystem] name
	  [SAE_TESTS] FAIL   [Subsystem] name :: exact failed assertion
	  [SAE_TESTS] SKIP / MANUAL  … reason / instructions
	then a summary. The machine-readable report is written to
	ServerStorage.SAE_TestReport (StringValue, JSON) for MCP/automation.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local TAG = "[SAE_TESTS]"

-- ── gate ─────────────────────────────────────────────────────────────────────
if not RunService:IsStudio() then
	return
end
local Server = ServerScriptService:WaitForChild("SAE_Server", 30)
if not Server then
	warn(TAG .. " SAE_Server not found — harness cannot run")
	return
end
local TestGate = require(Server:WaitForChild("TestGate"))
if not TestGate.enabled() then
	print(TAG .. " disabled. To run: Command Bar →  game:GetService('ServerStorage'):SetAttribute('SAE_EnableStudioTests', true)  then press Play")
	return
end

-- wait for the server bootstrap to finish (Main.server.lua sets this last)
local t0 = os.clock()
while not workspace:GetAttribute("SAE_ServerReady") and os.clock() - t0 < 60 do
	task.wait(0.2)
end
if not workspace:GetAttribute("SAE_ServerReady") then
	warn(TAG .. " server never became ready (SAE_ServerReady) — aborting")
	return
end

local function svc(name)
	return require(Server:WaitForChild(name))
end
local DataService = svc("DataService")
local FarmService = svc("FarmService")
local EggService = svc("EggService")
local RoundService = svc("RoundService")
local BossService = svc("BossService")
local TreadmillService = svc("TreadmillService")
local MovementService = svc("MovementService")
local PvPService = svc("PvPService")
local Remotes = svc("Remotes")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Worlds = require(Shared.Worlds)
local Balance = require(Shared.Balance)
local Layout = require(Shared.Layout)
local Profile = require(Shared.Profile)
local Economy = require(Shared.Economy)
local Trails = require(Shared.Trails)
local BossLogic = require(Shared.BossLogic)
local Net = require(Shared.Net)

-- ── tiny test framework ──────────────────────────────────────────────────────
local results = {}
local counts = { PASS = 0, FAIL = 0, SKIP = 0, MANUAL = 0 }

local function fmt(v): string
	if type(v) == "string" then
		return string.format("%q", v)
	elseif type(v) == "number" then
		return (v == math.floor(v)) and tostring(v) or string.format("%.3f", v)
	elseif typeof(v) == "Vector3" then
		return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
	elseif typeof(v) == "Instance" then
		return v:GetFullName()
	end
	return tostring(v)
end

local function signal(kind: string, msg: string)
	error({ __sae = kind, msg = msg }, 3)
end
local function fail(msg: string)
	signal("FAIL", msg)
end
local function expect(cond: any, msg: string)
	if not cond then
		signal("FAIL", msg)
	end
end
local function eq(actual: any, expected: any, what: string)
	if actual ~= expected then
		signal("FAIL", string.format("%s: expected %s, got %s", what, fmt(expected), fmt(actual)))
	end
end
local function near(actual: number, expected: number, tol: number, what: string)
	if type(actual) ~= "number" or math.abs(actual - expected) > tol then
		signal("FAIL", string.format("%s: expected %s ±%s, got %s", what, fmt(expected), fmt(tol), fmt(actual)))
	end
end
local function skip(reason: string)
	signal("SKIP", reason)
end
local function manual(instructions: string)
	signal("MANUAL", instructions)
end

local function record(status: string, subsystem: string, name: string, detail: string?, seconds: number)
	counts[status] += 1
	table.insert(results, { status = status, subsystem = subsystem, name = name, detail = detail, seconds = seconds })
	local line = string.format("%s %-6s [%s] %s%s", TAG, status, subsystem, name, detail and ("  ::  " .. detail) or "")
	if status == "FAIL" then
		warn(line)
	else
		print(line)
	end
end

local function test(subsystem: string, name: string, fn: () -> ())
	local started = os.clock()
	local ok, err = xpcall(fn, function(e)
		if type(e) == "table" and e.__sae then
			return e
		end
		return { __sae = "FAIL", msg = "ERROR " .. tostring(e) .. "\n" .. debug.traceback() }
	end)
	local secs = os.clock() - started
	if ok then
		record("PASS", subsystem, name, nil, secs)
	else
		record(err.__sae, subsystem, name, err.msg, secs)
	end
end

-- ── helpers ──────────────────────────────────────────────────────────────────
local function waitFor(cond: () -> any, timeout: number, step: number?): any
	local start = os.clock()
	while os.clock() - start < timeout do
		local v = cond()
		if v then
			return v
		end
		task.wait(step or 0.05)
	end
	return cond()
end

local function rootOf(pl: Player): BasePart?
	local c = pl.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end
local function humOf(pl: Player): Humanoid?
	local c = pl.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

-- place the character standing at `ground` (feet level); no yield
local function teleportNow(pl: Player, ground: Vector3, lookAt: Vector3?)
	local c = pl.Character
	expect(c ~= nil, pl.Name .. " has no character")
	local pos = ground + Vector3.new(0, 3.2, 0)
	local cf = lookAt and CFrame.lookAt(pos, Vector3.new(lookAt.X, pos.Y, lookAt.Z)) or CFrame.new(pos)
	c:PivotTo(cf)
	local r = rootOf(pl)
	if r then
		r.AssemblyLinearVelocity = Vector3.zero
	end
end

-- teleport and make sure the (client-owned) character really stayed there
local function teleport(pl: Player, ground: Vector3, lookAt: Vector3?)
	for _ = 1, 5 do
		teleportNow(pl, ground, lookAt)
		task.wait(0.15)
		local r = rootOf(pl)
		if r and (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(ground.X, 0, ground.Z)).Magnitude < 6 then
			return
		end
	end
	fail("teleport of " .. pl.Name .. " to " .. fmt(ground) .. " did not stick")
end

local SAFE_POINT = Vector3.new(Layout.HUB_SPAWN.x, 0.5, Layout.HUB_SPAWN.z)
local function safePoint(i: number?): Vector3
	return SAFE_POINT + Vector3.new(((i or 1) - 1) * 8, 0, 0)
end

local function eggInfo(eggId: string)
	local info = EggService.TestEggInfo(eggId)
	expect(info ~= nil, "unknown egg " .. eggId)
	return info
end
local function nearEgg(eggId: string, dx: number?): Vector3
	local sp = eggInfo(eggId).spawnPosition
	return Vector3.new(sp.X + (dx or 5), sp.Y - 2, sp.Z)
end

local function prof(pl: Player)
	local p = DataService.Get(pl)
	expect(p ~= nil, pl.Name .. " profile not loaded")
	return p
end
local function mutate(pl: Player, fn: (any) -> ())
	local ok, why = DataService.mutate(pl, function(p)
		fn(p)
		return true
	end)
	expect(ok, "profile mutate failed: " .. tostring(why))
end
local function deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = deepCopy(v)
	end
	return c
end
local function replaceProfile(pl: Player, src)
	mutate(pl, function(p)
		for k in pairs(p) do
			p[k] = nil
		end
		for k, v in deepCopy(src) do
			p[k] = v
		end
	end)
end
local function freshProfile(pl: Player, cash: number?)
	local f = Profile.new()
	f.cash = cash or 0
	replaceProfile(pl, f)
end
local function count(t): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end
local function newUid(): string
	return HttpService:GenerateGUID(false)
end
local function addUnits(pl: Player, specs: { { any } }, keepEquipped: boolean?): { string }
	local uids = {}
	mutate(pl, function(p)
		for _, s in specs do
			local uid = newUid()
			local ok, why = Profile.addUnit(p, s[1], uid, DataService.Now())
			assert(ok, "addUnit " .. tostring(s[1]) .. ": " .. tostring(why))
			p.units[uid].level = s[2] or 1
			table.insert(uids, uid)
		end
		if not keepEquipped then
			p.equipped = {}
		end
	end)
	return uids
end
-- a secured egg directly in the profile (as if carried home earlier); ready = hatchAt in the past
local function grantSecuredEgg(pl: Player, eggId: string, ready: boolean): string
	local eggUid = newUid()
	local ok, why = DataService.mutate(pl, function(p)
		local okS, res = Profile.secureEgg(p, eggId, eggUid, DataService.Now())
		if okS and ready then
			res.hatchAt = DataService.Now() - 0.01
		end
		return okS, res
	end)
	expect(ok, "secureEgg failed: " .. tostring(why))
	return eggUid
end
-- remote exactly as a client would send it (rate limit cleared first so tests are sequential)
local function call(pl: Player, name: string, ...: any): ...any
	Remotes.TestClearRate(pl)
	return Remotes.TestCall(pl, name, ...)
end

local function phase(): string
	return workspace:GetAttribute("RoundPhase") or "?"
end
local function phaseRemaining(): number
	return (workspace:GetAttribute("PhaseEndsAt") or 0) - workspace:GetServerTimeNow()
end
-- make sure we are in OPEN with at least `minRemaining` seconds left
local function ensureOpen(minRemaining: number)
	for _ = 1, 8 do
		if phase() == "OPEN" and phaseRemaining() >= minRemaining then
			return
		end
		local before = phase()
		RoundService.SkipPhase()
		waitFor(function()
			return phase() ~= before
		end, 6)
		if phase() == "RESET" then
			waitFor(function()
				return phase() ~= "RESET"
			end, 6)
		end
	end
	eq(phase(), "OPEN", "round phase after skipping to OPEN")
end
local function calmWorld()
	BossService.ResetAll()
	EggService.ResetAll()
end
local function bossModel(worldId: string): Model
	local m = workspace:FindFirstChild("SAE_World") and workspace.SAE_World.Worlds:FindFirstChild(worldId)
	m = m and m:FindFirstChild("Boss")
	expect(m ~= nil, "boss model for " .. worldId)
	return m
end
local function bossState(worldId: string): string
	return bossModel(worldId):GetAttribute("BossState") or "?"
end
local function carriedEggOf(pl: Player): string?
	return pl:GetAttribute("CarryEggId")
end
-- pick up `eggId` for `pl` via the real prompt path (teleports next to the egg first)
local function pickUp(pl: Player, eggId: string)
	local info = eggInfo(eggId)
	local ground = info.hasDrop and (info.dropPosition + Vector3.new(3, 0, 0)) or nearEgg(eggId)
	teleport(pl, ground)
	local ok = EggService.TestPickUp(pl, eggId)
	expect(ok, pl.Name .. " could not pick up " .. eggId .. " (state " .. fmt(eggInfo(eggId).state) .. ", phase " .. phase() .. ")")
end
local function secureViaSafeZone(pl: Player, slot: number?)
	teleport(pl, safePoint(slot))
	local secured = waitFor(function()
		return not EggService.IsCarrying(pl)
	end, 2)
	expect(secured, pl.Name .. " was not auto-secured within 2 s of entering the Farm Safe Zone")
end
local function trailFolders(pl: Player): { Instance }
	local out = {}
	local c = pl.Character
	if c then
		for _, d in c:GetDescendants() do
			if d.Name == "SAE_TrailFx" then
				table.insert(out, d)
			end
		end
	end
	return out
end
local function visibleTierParts(model: Instance): { [Instance]: boolean }
	local set = {}
	local tiers = model:FindFirstChild("Tiers")
	for _, d in (tiers and tiers:GetDescendants() or {}) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			set[d] = true
		end
	end
	return set
end
local function setDiff(a, b): number
	local n = 0
	for k in a do
		if not b[k] then
			n += 1
		end
	end
	for k in b do
		if not a[k] then
			n += 1
		end
	end
	return n
end

-- ═════════════════════════════════════════════════════════════════════════════
-- setup
-- ═════════════════════════════════════════════════════════════════════════════
local wantPlayers = tonumber(ServerStorage:GetAttribute("SAE_TestPlayers")) or 1
print(string.format("%s waiting for %d player(s)…", TAG, wantPlayers))
waitFor(function()
	return #Players:GetPlayers() >= wantPlayers
end, 90, 0.25)
local players = Players:GetPlayers()
table.sort(players, function(a, b)
	return a.UserId < b.UserId
end)
for _, pl in players do
	waitFor(function()
		return DataService.IsLoaded(pl) and rootOf(pl) ~= nil and humOf(pl) ~= nil
	end, 30, 0.2)
end
task.wait(1) -- let character scripts (Bat, trail hooks) settle
local P1, P2 = players[1], players[2]

print(string.format("%s ===== RUN START  players=%d  persistentData=%s  round=%s =====", TAG, #players, tostring(DataService.IsPersistent()), phase()))

if not P1 then
	record("FAIL", "Setup", "at least one player in Play mode", "no players joined (use Play, not Run)", 0)
end
local aborted = false
if DataService.IsPersistent() and ServerStorage:GetAttribute("SAE_StudioTestsAllowPersistent") ~= true then
	aborted = true
	record(
		"FAIL",
		"Setup",
		"data safety guard",
		"DataStore API access is ON: the harness would modify real saved profiles. Turn off Game Settings → Security → "
			.. "'Enable Studio Access to API Services', or set ServerStorage.SAE_StudioTestsAllowPersistent = true "
			.. "(profiles are backed up and restored at the end)",
		0
	)
end

local backups = {}
if P1 and not aborted then
	for _, pl in players do
		backups[pl] = deepCopy(DataService.Get(pl))
	end
end

local function main()
	-- ══════════════════════════════════════════════════════════════ FARMS
	test("Farms", "exactly 7 Farms", function()
		eq(Balance.OWNER_LOCKED.FarmCount, 7, "Balance.OWNER_LOCKED.FarmCount")
		local folder = workspace.SAE_World.Hub.Farms
		local n = 0
		for _, f in folder:GetChildren() do
			if string.match(f.Name, "^Farm%d+$") then
				n += 1
				expect(f:FindFirstChild("Plot"), f.Name .. ".Plot missing")
			end
		end
		eq(n, 7, "Farm models under SAE_World.Hub.Farms")
		for i = 1, 7 do
			expect(FarmService.GetFarm(i) ~= nil, "FarmService.GetFarm(" .. i .. ")")
		end
		eq(FarmService.GetFarm(8), nil, "FarmService.GetFarm(8)")
		eq(Players.MaxPlayers, 7, "Players.MaxPlayers (also set the published Game Settings server size)")
	end)

	test("Farms", "Farm assignment", function()
		for _, pl in players do
			local idx = FarmService.GetPlayerFarm(pl)
			expect(type(idx) == "number" and idx >= 1 and idx <= 7, pl.Name .. " has no farm (got " .. fmt(idx) .. ")")
			eq(pl:GetAttribute("FarmIndex"), idx, pl.Name .. " FarmIndex attribute")
			local model = FarmService.GetFarm(idx).model
			eq(model:GetAttribute("OwnerUserId"), pl.UserId, "Farm" .. idx .. " OwnerUserId")
			eq(model:GetAttribute("OwnerName"), pl.DisplayName, "Farm" .. idx .. " OwnerName")
		end
	end)

	test("Farms", "one Farm per player", function()
		local seen = {}
		for _, pl in players do
			local idx = FarmService.GetPlayerFarm(pl)
			eq(FarmService.Assign(pl), idx, pl.Name .. " re-Assign must be idempotent")
			expect(not seen[idx], "Farm" .. tostring(idx) .. " assigned to two players")
			seen[idx] = true
			local owned = 0
			for i = 1, 7 do
				if FarmService.GetFarm(i).model:GetAttribute("OwnerUserId") == pl.UserId then
					owned += 1
				end
			end
			eq(owned, 1, pl.Name .. " number of owned farms")
		end
	end)

	test("Farms", "entire Farm area is the Safe Zone (plots, kiosks) and the Fog Gate is outside", function()
		for i = 1, 7 do
			local plot = FarmService.GetFarm(i).plot
			local h = plot.Size / 2
			for _, c in { Vector3.new(-h.X, 0, -h.Z), Vector3.new(h.X, 0, -h.Z), Vector3.new(-h.X, 0, h.Z), Vector3.new(h.X, 0, h.Z), Vector3.zero } do
				local p = plot.Position + c
				expect(Layout.isInSafeZone(p.X, 3, p.Z), "Farm" .. i .. " plot point " .. fmt(p) .. " is outside the Safe Zone")
			end
		end
		for _, k in { "TrailShop", "SellKiosk" } do
			local a = workspace.SAE_World.Hub:FindFirstChild(k) and workspace.SAE_World.Hub[k]:FindFirstChild("PromptAnchor")
			expect(a, k .. ".PromptAnchor missing")
			expect(Layout.isInSafeZone(a.Position.X, a.Position.Y, a.Position.Z), k .. " is outside the Safe Zone")
		end
		expect(not Layout.isInSafeZone(0, 3, Layout.FOG_GATE_Z), "Fog Gate must be outside the Safe Zone")
	end)

	-- ══════════════════════════════════════════════════════════════ EGGS
	local E1, E2 = "egg_tanjiro", "egg_rengoku"
	local securedEggUid

	test("Eggs", "setup: fresh profile, OPEN round, eggs/bosses reset", function()
		freshProfile(P1, 0)
		ensureOpen(150)
		calmWorld()
		teleport(P1, safePoint())
		eq(EggService.IsCarrying(P1), false, "P1 carrying after reset")
	end)

	test("Eggs", "pickup refused when out of range", function()
		teleport(P1, safePoint())
		eq(EggService.TestPickUp(P1, E1), false, "TestPickUp from the Safe Zone (far away)")
		eq(EggService.IsCarrying(P1), false, "IsCarrying after out-of-range pickup")
	end)

	test("Eggs", "Egg pickup", function()
		pickUp(P1, E1)
		eq(EggService.IsCarrying(P1), true, "IsCarrying")
		eq(P1:GetAttribute("CarryState"), "UNSAFE", "CarryState attribute")
		eq(carriedEggOf(P1), E1, "CarryEggId attribute")
		eq(P1:GetAttribute("CarryWorld"), "DemonSlayer", "CarryWorld attribute")
		local info = eggInfo(E1)
		eq(info.state, "CARRIED_UNSAFE", "egg record state")
		eq(info.carrier, P1, "egg record carrier")
		eq(info.spawnVisible, false, "spawn visual hidden while carried")
		expect(P1.Character:FindFirstChild("CarriedEgg"), "CarriedEgg model attached to the character")
	end)

	test("Eggs", "one-Egg carry limit", function()
		expect(EggService.IsCarrying(P1), "precondition: P1 carrying " .. E1)
		teleport(P1, nearEgg(E2))
		eq(EggService.TestPickUp(P1, E2), false, "second pickup while carrying")
		eq(carriedEggOf(P1), E1, "CarryEggId after second pickup attempt")
		eq(eggInfo(E2).state, "AVAILABLE", E2 .. " state")
		local mine = 0
		for _, c in EggService.GetCarriers() do
			if c.player == P1 then
				mine += 1
			end
		end
		eq(mine, 1, "carrier entries for P1")
	end)

	test("Eggs", "manual Drop outside the Safe Zone", function()
		local before = DataService.Now()
		call(P1, "RequestDropEgg")
		eq(EggService.IsCarrying(P1), false, "IsCarrying after RequestDropEgg")
		local info = eggInfo(E1)
		eq(info.state, "DROPPED", "egg record state")
		eq(info.hasDrop, true, "dropped egg model exists in the world")
		near(info.dropExpiresAt, before + Balance.DroppedEggSeconds, 2, "dropped egg ExpiresAt")
		eq(P1:GetAttribute("CarryState"), nil, "CarryState after drop")
		eq(P1.Character:FindFirstChild("CarriedEgg"), nil, "CarriedEgg model after drop")
	end)

	test("Eggs", "dropped Egg can be grabbed again", function()
		pickUp(P1, E1)
		eq(eggInfo(E1).hasDrop, false, "dropped model removed on re-grab")
		eq(eggInfo(E1).state, "CARRIED_UNSAFE", "egg record state")
	end)

	test("Eggs", "Drop is refused inside the Safe Zone", function()
		expect(EggService.IsCarrying(P1), "precondition: carrying")
		teleportNow(P1, safePoint()) -- same thread: the 10 Hz secure loop has not run yet
		eq(EggService.Drop(P1, "manual"), false, "EggService.Drop inside the Safe Zone")
		eq(eggInfo(E1).hasDrop, false, "no dropped model inside the Safe Zone")
	end)

	test("Eggs", "Farm Safe Zone auto-secure (no remote, immediate)", function()
		teleport(P1, safePoint()) -- verified arrival (the previous test only moved P1 for one frame)
		local arrived = os.clock()
		local done = waitFor(function()
			return not EggService.IsCarrying(P1)
		end, 1.5, 0.02)
		expect(done, "egg not secured within 1.5 s of standing in the Safe Zone")
		expect(os.clock() - arrived <= 0.5, string.format("secure took %.2f s after arrival (10 Hz loop; expected ≤ 0.5 s)", os.clock() - arrived))
		eq(eggInfo(E1).state, "SECURED", "egg record state")
		eq(P1:GetAttribute("CarryState"), "SECURED", "CarryState attribute")
		local p = prof(P1)
		eq(count(p.eggs), 1, "secured eggs in profile")
		for uid, e in p.eggs do
			securedEggUid = uid
			eq(e.eggId, E1, "secured eggId")
			near(e.hatchAt - e.securedAt, Balance.HatchSeconds, 0.001, "hatchAt - securedAt")
			eq(Balance.HatchSeconds, 60, "development hatch time")
		end
		local net = ReplicatedStorage:FindFirstChild(Net.FOLDER)
		for _, bad in Net.FORBIDDEN do
			eq(net and net:FindFirstChild(bad), nil, "forbidden remote " .. bad)
		end
	end)

	test("Eggs", "Drop unavailable after secure", function()
		call(P1, "RequestDropEgg")
		eq(EggService.Drop(P1, "manual"), false, "EggService.Drop after secure")
		eq(eggInfo(E1).hasDrop, false, "no dropped model after secure")
		eq(count(prof(P1).eggs), 1, "secured eggs in profile")
	end)

	test("Eggs", "a secured world Egg cannot be taken again this round", function()
		teleport(P1, nearEgg(E1))
		eq(EggService.TestPickUp(P1, E1), false, "pickup of an already secured world egg")
		teleport(P1, safePoint())
	end)

	test("Eggs", "the same Egg instance can never be secured twice", function()
		local ok, why = DataService.mutate(P1, function(p)
			return Profile.secureEgg(p, E1, securedEggUid, DataService.Now())
		end)
		eq(ok, false, "second secure of the same egg uid")
		eq(why, "already secured", "rejection reason")
		eq(count(prof(P1).eggs), 1, "secured eggs in profile")
	end)

	-- ══════════════════════════════════════════════════════════════ HATCH
	local unitUid1

	test("Hatch", "HATCHING before 60 s and OPEN refused", function()
		expect(securedEggUid, "precondition: a secured egg")
		local egg = prof(P1).eggs[securedEggUid]
		eq(Profile.eggState(egg, DataService.Now()), "HATCHING", "egg state right after securing")
		local ok, why = call(P1, "RequestOpenEgg", securedEggUid)
		eq(ok, false, "RequestOpenEgg before ready")
		eq(why, "not ready", "rejection reason")
		eq(count(prof(P1).units), 0, "units after refused open")
		eq(prof(P1).eggs[securedEggUid] ~= nil, true, "egg still present")
	end)

	test("Hatch", "60-second hatch → READY transition", function()
		local egg = prof(P1).eggs[securedEggUid]
		eq(Profile.eggState(egg, egg.hatchAt - 0.05), "HATCHING", "state 0.05 s before hatchAt")
		eq(Profile.eggState(egg, egg.hatchAt), "READY", "state at hatchAt")
		if ServerStorage:GetAttribute("SAE_TestRealHatch") == true then
			print(TAG .. " waiting for the real 60 s hatch…")
			local ready = waitFor(function()
				return Profile.eggState(prof(P1).eggs[securedEggUid], DataService.Now()) == "READY"
			end, Balance.HatchSeconds + 5, 0.5)
			expect(ready, "egg did not become READY within 65 s")
		else
			mutate(P1, function(p)
				p.eggs[securedEggUid].hatchAt = DataService.Now() - 0.01 -- same as DEV "HATCH NOW"
			end)
			eq(Profile.eggState(prof(P1).eggs[securedEggUid], DataService.Now()), "READY", "state after fast-forward")
		end
	end)

	test("Hatch", "READY → OPEN grants the Character and discovers it", function()
		local ok, res = call(P1, "RequestOpenEgg", securedEggUid)
		eq(ok, true, "RequestOpenEgg result (" .. fmt(res) .. ")")
		eq(type(res), "table", "open payload type")
		eq(res.characterId, "tanjiro", "revealed characterId")
		eq(res.isNewDiscovery, true, "isNewDiscovery on first open")
		eq(res.equipped, true, "auto-equipped into a free slot")
		unitUid1 = res.uid
		local p = prof(P1)
		eq(p.eggs[securedEggUid], nil, "egg consumed")
		expect(p.units[unitUid1], "unit " .. fmt(unitUid1) .. " granted")
		eq(p.units[unitUid1].characterId, "tanjiro", "unit characterId")
		eq(p.units[unitUid1].level, 1, "unit level")
		expect(p.index.tanjiro ~= nil, "Index entry for tanjiro")
	end)

	test("Hatch", "double-Open prevention (rapid, sequential and concurrent)", function()
		local eggUid = grantSecuredEgg(P1, E2, true)
		local before = count(prof(P1).units)
		Remotes.TestClearRate(P1)
		local ok1 = Remotes.TestCall(P1, "RequestOpenEgg", eggUid)
		local ok2, why2 = Remotes.TestCall(P1, "RequestOpenEgg", eggUid) -- rapid repeat: throttled
		local ok3, why3 = call(P1, "RequestOpenEgg", eggUid) -- after the throttle: egg already consumed
		eq(ok1, true, "first open")
		eq(ok2, false, "rapid second open")
		eq(ok3, false, "third open")
		expect(why2 == "slow down" or why2 == "no such egg", "second open reason " .. fmt(why2))
		eq(why3, "no such egg", "third open reason")
		-- concurrent: two threads race on one egg
		local eggUid2 = grantSecuredEgg(P1, E2, true)
		Remotes.TestClearRate(P1)
		local wins, done = 0, 0
		for _ = 1, 2 do
			task.spawn(function()
				Remotes.TestClearRate(P1)
				local ok = Remotes.TestCall(P1, "RequestOpenEgg", eggUid2)
				if ok then
					wins += 1
				end
				done += 1
			end)
		end
		waitFor(function()
			return done == 2
		end, 3)
		eq(wins, 1, "successful concurrent opens of one egg")
		eq(count(prof(P1).units), before + 2, "units granted (one per egg)")
	end)

	test("Hatch", "unique Character UID grant", function()
		local seen = {}
		for uid, u in prof(P1).units do
			eq(u.uid, uid, "unit.uid matches its key")
			expect(string.match(uid, "^%x+%-%x+%-%x+%-%x+%-%x+$"), "uid is a GUID: " .. fmt(uid))
			expect(not seen[uid], "duplicate uid " .. uid)
			seen[uid] = true
		end
	end)

	test("Hatch", "duplicate Character ownership", function()
		local ok, res = call(P1, "RequestOpenEgg", grantSecuredEgg(P1, E1, true))
		eq(ok, true, "open second tanjiro egg")
		eq(res.isNewDiscovery, false, "isNewDiscovery for an already discovered character")
		local n, uids = 0, {}
		for uid, u in prof(P1).units do
			if u.characterId == "tanjiro" then
				n += 1
				uids[uid] = true
			end
		end
		eq(n, 2, "tanjiro units owned")
		eq(count(uids), 2, "distinct tanjiro uids")
	end)

	test("Hatch", "Index de-duplication", function()
		local p = prof(P1)
		local first = p.index.tanjiro
		call(P1, "RequestOpenEgg", grantSecuredEgg(P1, E1, true))
		eq(prof(P1).index.tanjiro, first, "tanjiro discovery timestamp unchanged by duplicates")
		local distinct = {}
		for _, u in prof(P1).units do
			distinct[u.characterId] = true
		end
		eq(count(prof(P1).index), count(distinct), "index entries == distinct characters owned")
	end)

	-- ══════════════════════════════════════════════════════════ CHARACTERS
	test("Characters", "Farm slot overflow safety", function()
		freshProfile(P1, 0)
		eq(Profile.slots(prof(P1)), Balance.OWNER_LOCKED.InitialFarmSlots, "initial farm slots")
		local uids = addUnits(P1, { { "tanjiro" }, { "rengoku" }, { "yoriichi" }, { "muzan" }, { "akaza" }, { "deku" }, { "bakugo" } }, true)
		local p = prof(P1)
		eq(#p.equipped, 5, "auto-equipped units capped at slots")
		eq(count(p.units), 7, "units owned")
		local extra = uids[7]
		call(P1, "RequestEquipCharacter", extra)
		eq(#prof(P1).equipped, 5, "equipped after equipping into a full farm")
		eq(Profile.isEquipped(prof(P1), extra), false, "overflow unit stays unequipped")
		local ok, res = call(P1, "RequestOpenEgg", grantSecuredEgg(P1, E1, true))
		eq(ok, true, "open while the farm is full")
		eq(res.equipped, false, "new unit is NOT equipped when slots are full")
		eq(#prof(P1).equipped, 5, "equipped after open with full slots")
	end)

	test("Characters", "Equip / Unequip validation", function()
		local p = prof(P1)
		local target = p.equipped[1]
		call(P1, "RequestUnequipCharacter", target)
		eq(Profile.isEquipped(prof(P1), target), false, "unequipped")
		eq(#prof(P1).equipped, 4, "equipped count after unequip")
		call(P1, "RequestEquipCharacter", target)
		eq(Profile.isEquipped(prof(P1), target), true, "re-equipped")
		call(P1, "RequestEquipCharacter", target) -- already equipped
		local occurrences = 0
		for _, u in prof(P1).equipped do
			if u == target then
				occurrences += 1
			end
		end
		eq(occurrences, 1, "equipping twice must not duplicate the slot")
		call(P1, "RequestEquipCharacter", "not-a-real-uid")
		call(P1, "RequestEquipCharacter", 12345)
		call(P1, "RequestUnequipCharacter", { "table" })
		eq(#prof(P1).equipped, 5, "equipped count after invalid requests")
		for _, uid in prof(P1).equipped do
			expect(prof(P1).units[uid], "equipped uid " .. uid .. " not owned")
		end
	end)

	test("Characters", "Equip Best by actual $/sec only", function()
		freshProfile(P1, 0)
		-- a levelled cheap World-1 unit must beat higher-world level-1 units if its $/s is higher
		addUnits(P1, { { "tanjiro", 10 }, { "rengoku", 1 }, { "yoriichi", 1 }, { "muzan", 1 }, { "akaza", 1 }, { "deku", 1 }, { "bakugo", 1 } })
		local list = {}
		for uid, u in prof(P1).units do
			table.insert(list, { uid = uid, income = Profile.unitIncome(u) })
		end
		table.sort(list, function(a, b)
			return a.income > b.income
		end)
		call(P1, "RequestEquipBest")
		local eqSet = {}
		for _, uid in prof(P1).equipped do
			eqSet[uid] = true
		end
		eq(#prof(P1).equipped, 5, "Equip Best fills every slot")
		for i = 1, 5 do
			expect(eqSet[list[i].uid], string.format("rank %d unit ($%s/s) not equipped", i, fmt(list[i].income)))
		end
		for i = 6, #list do
			expect(not eqSet[list[i].uid] or list[i].income == list[5].income, string.format("rank %d unit ($%s/s) wrongly equipped", i, fmt(list[i].income)))
		end
	end)

	test("Characters", "income only while equipped (online, on own farm)", function()
		expect(FarmService.GetPlayerFarm(P1), "precondition: P1 owns a farm")
		mutate(P1, function(p)
			p.equipped = {}
			p.cash = 0
		end)
		task.wait(2.5)
		eq(prof(P1).cash, 0, "cash after 2.5 s with nothing equipped")
		local uid = next(prof(P1).units)
		call(P1, "RequestEquipCharacter", uid)
		local income = Profile.activeIncome(prof(P1))
		expect(income > 0, "precondition: equipped income > 0")
		task.wait(3.3)
		local cash = prof(P1).cash
		expect(
			cash >= income * 2 and cash <= income * 4,
			string.format("cash after ~3 ticks: expected %s..%s, got %s", fmt(income * 2), fmt(income * 4), fmt(cash))
		)
	end)

	test("Characters", "no offline income assumptions", function()
		local p = prof(P1)
		for _, k in { "lastOnline", "lastSeen", "lastLogout", "offlineEarnings" } do
			eq(p[k], nil, "profile field " .. k)
		end
		local copy = deepCopy(p)
		copy.cash = 1234
		copy.lastSeen = DataService.Now() - 86400
		eq(Profile.migrate(copy).cash, 1234, "migrate() must not pay anything for time away")
		local snap = Profile.snapshot(p, DataService.Now())
		eq(snap.offlineEarnings, nil, "snapshot offline earnings field")
	end)

	test("Characters", "Character upgrade validation (server-priced)", function()
		freshProfile(P1, 0)
		local uid = addUnits(P1, { { "rengoku", 1 } })[1]
		local cost = Economy.upgradeCost("rengoku", 1)
		local ok, why = call(P1, "RequestUpgradeCharacter", uid)
		eq(ok, false, "upgrade with $0")
		eq(why, "not enough cash", "reason")
		mutate(P1, function(p)
			p.cash = cost - 1
		end)
		eq((call(P1, "RequestUpgradeCharacter", uid)), false, "upgrade with cost - 1")
		eq(prof(P1).units[uid].level, 1, "level after refused upgrades")
		eq(prof(P1).cash, cost - 1, "cash after refused upgrades")
		mutate(P1, function(p)
			p.cash = cost
		end)
		local ok2, res = call(P1, "RequestUpgradeCharacter", uid)
		eq(ok2, true, "upgrade with exact cost")
		eq(res.level, 2, "returned level")
		eq(res.cost, cost, "server-computed cost")
		eq(prof(P1).cash, 0, "cash after upgrade")
		eq(prof(P1).units[uid].level, 2, "stored level")
		local ok3, why3 = call(P1, "RequestUpgradeCharacter", "not-a-real-uid")
		eq(ok3, false, "unknown uid upgrade")
		eq(why3, "not owned", "reason for unknown uid")
		local _, why4 = call(P1, "RequestUpgradeCharacter", 42)
		eq(why4, "bad request", "reason for a non-string uid")
		mutate(P1, function(p)
			p.units[uid].level = Balance.CharacterMaxLevel
			p.cash = 1e12
		end)
		local ok5, why5 = call(P1, "RequestUpgradeCharacter", uid)
		eq(ok5, false, "upgrade at max level")
		eq(why5, "max level", "reason at max level")
		eq(prof(P1).cash, 1e12, "cash untouched at max level")
	end)

	-- ══════════════════════════════════════════════════════════ TREADMILL
	local myFarm = FarmService.GetPlayerFarm(P1)
	local driveWorks = false

	test("Treadmill", "upgrade validation + physical transformation", function()
		freshProfile(P1, 0)
		TreadmillService.TestRefresh(myFarm)
		local m = TreadmillService.TestMachine(myFarm)
		eq(m.model:GetAttribute("Level"), 1, "machine level attribute")
		local visible1 = visibleTierParts(m.model)
		call(P1, "RequestUpgradeTreadmill")
		eq(prof(P1).treadmillLevel, 1, "level after upgrade with $0")
		local cost = Economy.treadmillUpgradeCost(1)
		mutate(P1, function(p)
			p.cash = cost
		end)
		call(P1, "RequestUpgradeTreadmill")
		eq(prof(P1).treadmillLevel, 2, "level after paying the exact cost")
		eq(prof(P1).cash, 0, "cash after upgrade")
		eq(m.model:GetAttribute("Level"), 2, "machine level attribute after upgrade")
		local previous = visible1
		for lvl = 3, Balance.TreadmillMaxLevel do
			mutate(P1, function(p)
				p.cash = Economy.treadmillUpgradeCost(lvl - 1)
			end)
			call(P1, "RequestUpgradeTreadmill")
			eq(prof(P1).treadmillLevel, lvl, "level " .. lvl)
			local vis = visibleTierParts(m.model)
			expect(setDiff(vis, previous) > 0, string.format("treadmill level %d looks identical to level %d (no tier part changed visibility)", lvl, lvl - 1))
			previous = vis
		end
		expect(count(previous) > count(visible1), string.format("L10 must show more machine parts than L1 (%d vs %d)", count(previous), count(visible1)))
		mutate(P1, function(p)
			p.cash = 1e15
		end)
		call(P1, "RequestUpgradeTreadmill")
		eq(prof(P1).treadmillLevel, Balance.TreadmillMaxLevel, "level beyond max")
		eq(prof(P1).cash, 1e15, "cash untouched at max level")
	end)

	test("Treadmill", "owner validation (other farms' machines are untouched)", function()
		for i = 1, 7 do
			if i ~= myFarm and not FarmService.GetOwner(i) then
				eq(TreadmillService.TestMachine(i).model:GetAttribute("Level"), 1, "unowned Farm" .. i .. " treadmill level")
			end
		end
		if P2 then
			local p2Farm = FarmService.GetPlayerFarm(P2)
			local p2Level = prof(P2).treadmillLevel
			eq(TreadmillService.TestMachine(p2Farm).model:GetAttribute("Level"), p2Level, "P2's machine shows P2's level, not P1's")
		end
	end)

	local function tryDrive(pl: Player, zone: BasePart, seconds: number)
		local hum = humOf(pl)
		local fwd = zone.CFrame.LookVector
		local stop = os.clock() + seconds
		while os.clock() < stop do
			if hum then
				hum:MoveTo(zone.Position + fwd * (zone.Size.Z * 0.5 + 6))
			end
			if pl:GetAttribute("Training") == true then
				return true
			end
			task.wait(0.1)
		end
		return pl:GetAttribute("Training") == true
	end

	test("Treadmill", "standing still on your own treadmill does not train", function()
		freshProfile(P1, 0)
		TreadmillService.TestRefresh(myFarm)
		local zone = TreadmillService.TestMachine(myFarm).zone
		teleport(P1, zone.Position - Vector3.new(0, zone.Size.Y / 2, 0))
		humOf(P1):MoveTo(rootOf(P1).Position)
		local speed0 = prof(P1).speed
		task.wait(2)
		expect(P1:GetAttribute("Training") ~= true, "Training attribute true while standing still")
		eq(prof(P1).speed, speed0, "speed after standing still 2 s")
	end)

	test("Treadmill", "owner running on own treadmill trains (state + Speed gain)", function()
		local zone = TreadmillService.TestMachine(myFarm).zone
		local speed0 = prof(P1).speed
		driveWorks = tryDrive(P1, zone, 4)
		if not driveWorks and ServerStorage:GetAttribute("SAE_TestInteractive") == true then
			print(TAG .. " >>> MANUAL STEP: hold W and run on YOUR treadmill (Farm" .. myFarm .. ") for 5 seconds — waiting 25 s…")
			waitFor(function()
				return P1:GetAttribute("Training") == true
			end, 25, 0.1)
			driveWorks = P1:GetAttribute("Training") == true
			task.wait(3)
		elseif driveWorks then
			tryDrive(P1, zone, 3)
		end
		if not driveWorks then
			manual(
				"server could not drive the character. Run on your own treadmill: the 'Training' player attribute must become true and Speed must rise ("
					.. Economy.treadmillGain(1)
					.. "/s at L1). Re-run with SAE_TestInteractive=true to automate the check"
			)
		end
		expect(prof(P1).speed > speed0, string.format("speed did not increase while training (%s → %s)", fmt(speed0), fmt(prof(P1).speed)))
		humOf(P1):MoveTo(rootOf(P1).Position)
	end)

	test("Treadmill", "running on another player's / unowned treadmill does not train", function()
		local other
		for i = 1, 7 do
			if i ~= myFarm then
				other = i
				break
			end
		end
		local zone = TreadmillService.TestMachine(other).zone
		teleport(P1, zone.Position - Vector3.new(0, zone.Size.Y / 2, 0))
		local speed0 = prof(P1).speed
		local trained = tryDrive(P1, zone, 3)
		humOf(P1):MoveTo(rootOf(P1).Position)
		if not driveWorks then
			manual("run on Farm" .. other .. "'s treadmill: 'Training' must stay false and Speed must not change")
		end
		eq(trained, false, "Training attribute on Farm" .. other .. "'s treadmill")
		eq(prof(P1).speed, speed0, "speed after running on a foreign treadmill")
		teleport(P1, safePoint())
	end)

	-- ══════════════════════════════════════════════════════════════ FARM
	test("Farm", "Farm upgrade validation (server-priced)", function()
		freshProfile(P1, 0)
		call(P1, "RequestUpgradeFarm")
		eq(prof(P1).farmLevel, 1, "farm level after upgrade with $0")
		local cost = Economy.farmUpgradeCost(1)
		mutate(P1, function(p)
			p.cash = cost
		end)
		call(P1, "RequestUpgradeFarm")
		eq(prof(P1).farmLevel, 2, "farm level after paying the exact cost")
		eq(prof(P1).cash, 0, "cash after farm upgrade")
		eq(Profile.slots(prof(P1)), Economy.farmSlots(2), "slots at farm level 2")
		mutate(P1, function(p)
			p.farmLevel = Economy.farmMaxLevel()
			p.cash = 1e15
		end)
		call(P1, "RequestUpgradeFarm")
		eq(prof(P1).farmLevel, Economy.farmMaxLevel(), "farm level beyond max")
		eq(prof(P1).cash, 1e15, "cash untouched at max farm level")
	end)

	-- ═════════════════════════════════════════════════════════════ TRAILS
	test("Trails", "Trail ownership / equip validation", function()
		freshProfile(P1, 0)
		call(P1, "RequestEquipTrail", "dash")
		eq(prof(P1).equippedTrail, nil, "equip of an unowned trail")
		local ok, why = call(P1, "RequestBuyTrailCash", "breeze")
		eq(ok, false, "buy with $0")
		eq(why, "not enough cash", "reason")
		local ok2, why2 = call(P1, "RequestBuyTrailCash", "not-a-trail")
		eq(ok2, false, "buy unknown trail")
		eq(why2, "unknown trail", "reason")
		eq((call(P1, "RequestBuyTrailCash", 5)), false, "buy with a non-string id")
		call(P1, "RequestEquipTrail", 5)
		eq(prof(P1).equippedTrail, nil, "equip with a non-string id")
		eq(count(prof(P1).trails), 0, "owned trails")
	end)

	test("Trails", "purchase is server-priced, equips, and applies the VFX", function()
		local price = Trails.BY_ID.breeze.cashPrice
		mutate(P1, function(p)
			p.cash = price
		end)
		local ok = call(P1, "RequestBuyTrailCash", "breeze")
		eq(ok, true, "buy breeze with the exact price")
		eq(prof(P1).cash, 0, "cash after purchase")
		eq(prof(P1).trails.breeze, true, "breeze owned")
		eq(prof(P1).equippedTrail, "breeze", "breeze equipped")
		local fx = waitFor(function()
			return trailFolders(P1)[1]
		end, 2)
		expect(fx, "SAE_TrailFx folder on the character")
		eq(fx:GetAttribute("TrailId"), "breeze", "applied trail id")
		mutate(P1, function(p)
			p.cash = price
		end)
		local ok2, why2 = call(P1, "RequestBuyTrailCash", "breeze")
		eq(ok2, false, "buy an owned trail again")
		eq(why2, "already owned", "reason")
		eq(prof(P1).cash, price, "cash untouched by a repeat purchase")
	end)

	test("Trails", "only one Trail equipped; multipliers never stack", function()
		mutate(P1, function(p)
			p.cash = Trails.BY_ID.dash.cashPrice
			p.speed = 100
		end)
		eq((call(P1, "RequestBuyTrailCash", "dash")), true, "buy dash")
		eq(prof(P1).equippedTrail, "dash", "dash equipped (replaces breeze)")
		task.wait(0.2)
		local folders = trailFolders(P1)
		eq(#folders, 1, "trail VFX folders on the character")
		eq(folders[1]:GetAttribute("TrailId"), "dash", "applied trail id")
		local function speedWith(id)
			call(P1, "RequestEquipTrail", id)
			MovementService.Refresh(P1)
			return humOf(P1).WalkSpeed
		end
		local wsNone, wsBreeze, wsDash = speedWith(nil), speedWith("breeze"), speedWith("dash")
		eq(#trailFolders(P1), 1, "VFX folders after switching")
		near(wsDash, Economy.walkSpeed(100, Trails.BY_ID.dash.mult, 1), 0.06, "WalkSpeed with dash (x2 only, not x1.5 × x2)")
		expect(wsNone < wsBreeze and wsBreeze < wsDash, string.format("WalkSpeed ordering none %.1f < breeze %.1f < dash %.1f", wsNone, wsBreeze, wsDash))
		call(P1, "RequestEquipTrail", nil)
		eq(prof(P1).equippedTrail, nil, "unequip")
		eq(#trailFolders(P1), 0, "VFX removed after unequip")
	end)

	-- ═══════════════════════════════════════════════════════════════ SELL
	test("Sell", "Sell validation (atomic, uids only)", function()
		freshProfile(P1, 0)
		local u = addUnits(P1, { { "tanjiro" }, { "rengoku" }, { "yoriichi" } })
		local function refused(arg, what, reason)
			local ok, why = call(P1, "RequestSellCharacters", arg)
			eq(ok, false, what)
			if reason then
				eq(why, reason, what .. " reason")
			end
		end
		refused({}, "sell nothing", "nothing selected")
		refused({ "not-a-real-uid" }, "sell unknown uid", "invalid selection")
		refused({ u[1], "not-a-real-uid" }, "sell valid + unknown", "invalid selection")
		refused({ u[1], u[1] }, "sell duplicate uid", "invalid selection")
		refused("x", "sell non-table", "bad request")
		refused({ 1 }, "sell non-string uid", "bad request")
		refused({ foo = u[1] }, "sell dictionary", "bad request")
		eq(count(prof(P1).units), 3, "units after refused sells (atomic)")
		eq(prof(P1).cash, 0, "cash after refused sells")
	end)

	test("Sell", "safe unequip before Sell + exact server payout", function()
		local p = prof(P1)
		local uid = next(p.units)
		call(P1, "RequestEquipCharacter", uid)
		expect(Profile.isEquipped(prof(P1), uid), "precondition: unit equipped")
		local u = prof(P1).units[uid]
		local expected = Economy.sellValue(u.characterId, u.level)
		local cash0 = prof(P1).cash
		local ok, payout, n = call(P1, "RequestSellCharacters", { uid })
		local cash1 = prof(P1).cash -- read in the same thread: no income tick in between
		eq(ok, true, "sell an equipped unit")
		eq(payout, expected, "server payout")
		eq(n, 1, "sold count")
		eq(cash1 - cash0, expected, "cash delta")
		eq(prof(P1).units[uid], nil, "unit removed")
		eq(Profile.isEquipped(prof(P1), uid), false, "unit removed from the farm slots")
		for _, e in prof(P1).equipped do
			expect(prof(P1).units[e], "dangling equipped uid " .. e)
		end
	end)

	test("Sell", "double-Sell prevention (rapid, sequential and concurrent)", function()
		local uid = next(prof(P1).units)
		local cash0 = prof(P1).cash
		Remotes.TestClearRate(P1)
		local ok1, pay1 = Remotes.TestCall(P1, "RequestSellCharacters", { uid })
		local ok2 = Remotes.TestCall(P1, "RequestSellCharacters", { uid })
		local ok3, why3 = call(P1, "RequestSellCharacters", { uid })
		eq(ok1, true, "first sell")
		eq(ok2, false, "rapid second sell")
		eq(ok3, false, "third sell")
		eq(why3, "invalid selection", "third sell reason")
		eq(prof(P1).cash - cash0, pay1, "cash paid exactly once")
		local last = next(prof(P1).units)
		expect(last, "precondition: one unit left")
		local lastUnit = prof(P1).units[last]
		local lastValue = Economy.sellValue(lastUnit.characterId, lastUnit.level)
		eq(#prof(P1).equipped, 0, "precondition: nothing equipped (no income during the race)")
		local wins, done = 0, 0
		local cash1 = prof(P1).cash
		for _ = 1, 2 do
			task.spawn(function()
				Remotes.TestClearRate(P1)
				if Remotes.TestCall(P1, "RequestSellCharacters", { last }) then
					wins += 1
				end
				done += 1
			end)
		end
		waitFor(function()
			return done == 2
		end, 3)
		eq(wins, 1, "successful concurrent sells of one unit")
		eq(prof(P1).cash - cash1, lastValue, "cash paid for two concurrent sells of one unit")
	end)

	test("Economy", "Cash duplication prevention (ledger over mixed operations)", function()
		freshProfile(P1, 10000)
		local u = addUnits(P1, { { "tanjiro" }, { "rengoku" } })
		local expected = 10000
		local ok, res = call(P1, "RequestUpgradeCharacter", u[1])
		if ok then
			expected -= res.cost
		end
		call(P1, "RequestUpgradeCharacter", "not-a-real-uid")
		local okS, pay = call(P1, "RequestSellCharacters", { u[2] })
		if okS then
			expected += pay
		end
		call(P1, "RequestSellCharacters", { u[2] })
		local okT = call(P1, "RequestBuyTrailCash", "breeze")
		if okT then
			expected -= Trails.BY_ID.breeze.cashPrice
		end
		call(P1, "RequestBuyTrailCash", "breeze")
		call(P1, "RequestOpenEgg", "not-a-real-egg")
		call(P1, "RequestUpgradeFarm") -- 10000 - … < farm cost: refused
		eq(prof(P1).cash, expected, "cash equals the ledger of successful server results")
		expect(prof(P1).cash >= 0, "cash never negative")
	end)

	-- ═══════════════════════════════════════════════════════════════ BOSS
	test("Boss", "targeting rule: carrier closest to the Farm Safe Zone", function()
		local z1 = Layout.worldZ0(1)
		local carriers = {
			{ id = "far", x = 0, z = z1 + 180, worldOfEgg = "DemonSlayer", secured = false },
			{ id = "near", x = 0, z = z1 + 40, worldOfEgg = "DemonSlayer", secured = false },
			{ id = "otherWorld", x = 0, z = z1 + 10, worldOfEgg = "MHA", secured = false },
			{ id = "secured", x = 0, z = 0, worldOfEgg = "DemonSlayer", secured = true },
		}
		local t = BossLogic.pickTarget("DemonSlayer", carriers)
		eq(t and t.id, "near", "target")
		eq(BossLogic.pickTarget("Bleach", carriers), nil, "Bleach boss target with no Bleach carriers")
		eq(BossLogic.catchOutcome("DemonSlayer", 0, 3, z1 + 100), "RETURN_EGG", "catch inside the boss world")
		eq(BossLogic.catchOutcome("DemonSlayer", 0, 3, Layout.worldZ0(2) + 50), "DROP_EGG", "catch after leaving the boss world")
		eq(BossLogic.catchOutcome("DemonSlayer", 0, 3, 0), "NONE", "catch inside the Safe Zone")
		eq(BossService.Count(), 9, "live bosses")
	end)

	test("Boss", "live: ~1 s reaction → CHASE → RETURN, never inside the Safe Zone", function()
		freshProfile(P1, 0)
		ensureOpen(90)
		calmWorld()
		for _, w in Worlds.ORDER do
			eq(bossState(w), "IDLE", w .. " boss state before pickup")
		end
		pickUp(P1, E1)
		local picked = os.clock()
		local reacted = waitFor(function()
			return bossState("DemonSlayer") == "REACTION"
		end, 0.6, 0.02)
		expect(reacted, "Akaza did not enter REACTION after the pickup (state " .. bossState("DemonSlayer") .. ")")
		eq(bossState("MHA"), "IDLE", "MHA boss must ignore a Demon Slayer egg")
		local chased = waitFor(function()
			return bossState("DemonSlayer") == "CHASE"
		end, Balance.BossReactionSeconds + 1.2, 0.02)
		expect(chased, "Akaza did not start CHASE")
		near(os.clock() - picked, Balance.BossReactionSeconds, 0.6, "reaction delay (s)")
		secureViaSafeZone(P1)
		local root = bossModel("DemonSlayer"):FindFirstChild("HumanoidRootPart")
		local returned = waitFor(function()
			local p = root.Position
			expect(not Layout.isInSafeZone(p.X, p.Y, p.Z), "boss entered the Farm Safe Zone at " .. fmt(p))
			return bossState("DemonSlayer") == "RETURN" or bossState("DemonSlayer") == "IDLE"
		end, 2, 0.05)
		expect(returned, "Akaza did not RETURN after the carrier secured (state " .. bossState("DemonSlayer") .. ")")
		for _ = 1, 20 do
			local p = root.Position
			expect(not Layout.isInSafeZone(p.X, p.Y, p.Z), "boss entered the Farm Safe Zone at " .. fmt(p))
			task.wait(0.1)
		end
	end)

	test("Boss", "seated bosses start seated (Shigaraki, Yhwach, Sung Jin-Woo)", function()
		calmWorld()
		for _, w in { "MHA", "Bleach", "SoloLeveling" } do
			local root = bossModel(w):FindFirstChild("HumanoidRootPart")
			eq(bossState(w), "IDLE", w .. " boss state")
			eq(root.Anchored, true, w .. " boss root anchored in the throne pose")
		end
	end)

	test("Boss", "target switching between two carriers (2 players)", function()
		if not P2 then
			skip("needs 2 players (Test → Clients and Servers → 2 players, SAE_TestPlayers = 2)")
		end
		freshProfile(P2, 0)
		ensureOpen(90)
		calmWorld()
		pickUp(P1, "egg_rengoku")
		teleport(P1, Vector3.new(0, 0.5, Layout.worldZ0(1) + 110)) -- mid-world, well away from Akaza's stage
		pickUp(P2, "egg_tanjiro")
		teleport(P2, Vector3.new(0, 0.5, Layout.worldZ0(1) + 12)) -- P2 closest to the Safe Zone
		expect(
			waitFor(function()
				return bossState("DemonSlayer") == "CHASE"
			end, 3),
			"Akaza not chasing"
		)
		local hum = bossModel("DemonSlayer"):FindFirstChildOfClass("Humanoid")
		local toP2 = waitFor(function()
			return (hum.WalkToPoint - rootOf(P2).Position).Magnitude < (hum.WalkToPoint - rootOf(P1).Position).Magnitude
		end, 1.5)
		expect(toP2, "boss is not heading for the carrier closest to the Safe Zone (P2)")
		secureViaSafeZone(P2, 2)
		local toP1 = waitFor(function()
			return (hum.WalkToPoint - rootOf(P1).Position).Magnitude < 12
		end, 2)
		expect(toP1, "boss did not switch to the remaining carrier (P1) after P2 secured")
		secureViaSafeZone(P1)
	end)

	-- ════════════════════════════════════════════════════════════════ PVP
	test("PvP", "bat knocks the Egg loose (server-validated)", function()
		if not P2 then
			skip("needs 2 players")
		end
		ensureOpen(60)
		calmWorld()
		pickUp(P2, E1)
		local victim = rootOf(P2).Position
		teleport(P1, victim - Vector3.new(0, 3.2, 3), victim)
		PvPService.TestResetCooldown(P1)
		PvPService.TestSwing(P1)
		eq(EggService.IsCarrying(P2), false, "victim still carrying after a valid hit")
		eq(eggInfo(E1).state, "DROPPED", "egg state after the hit")
	end)

	test("PvP", "bat cooldown and range", function()
		if not P2 then
			skip("needs 2 players")
		end
		pickUp(P2, E1)
		local victim = rootOf(P2).Position
		PvPService.TestResetCooldown(P1)
		teleport(P1, victim - Vector3.new(0, 3.2, Balance.BatRange + 6), victim) -- out of range
		PvPService.TestSwing(P1)
		eq(EggService.IsCarrying(P2), true, "hit from beyond BatRange")
		teleport(P1, victim - Vector3.new(0, 3.2, 3), victim)
		PvPService.TestSwing(P1) -- still on cooldown from the out-of-range swing
		eq(EggService.IsCarrying(P2), true, "hit during the bat cooldown")
	end)

	test("PvP", "Safe Zone protects carriers from bats", function()
		if not P2 then
			skip("needs 2 players")
		end
		if not EggService.IsCarrying(P2) then
			pickUp(P2, E1)
		end
		local inside = Vector3.new(0, 0.5, Layout.SAFE_MAX.z - 4)
		teleportNow(P2, inside) -- same thread: the secure loop has not run yet
		teleportNow(P1, inside - Vector3.new(0, 0, 3), inside)
		PvPService.TestResetCooldown(P1)
		PvPService.TestSwing(P1)
		eq(EggService.IsCarrying(P2), true, "carrier inside the Safe Zone was knocked loose")
		secureViaSafeZone(P2, 2)
		teleport(P1, safePoint())
	end)

	test("Multiplayer", "simultaneous Egg carriers are independent", function()
		if not P2 then
			skip("needs 2 players")
		end
		freshProfile(P1, 0)
		freshProfile(P2, 0)
		ensureOpen(60)
		calmWorld()
		pickUp(P1, "egg_deku")
		pickUp(P2, "egg_bakugo")
		eq(#EggService.GetCarriers(), 2, "carriers")
		eq(carriedEggOf(P1), "egg_deku", "P1 CarryEggId")
		eq(carriedEggOf(P2), "egg_bakugo", "P2 CarryEggId")
		secureViaSafeZone(P1)
		eq(EggService.IsCarrying(P2), true, "P2 unaffected by P1 securing")
		secureViaSafeZone(P2, 2)
		eq(count(prof(P1).eggs), 1, "P1 secured eggs")
		eq(count(prof(P2).eggs), 1, "P2 secured eggs")
		for _, e in prof(P1).eggs do
			eq(e.eggId, "egg_deku", "P1 egg")
		end
		for _, e in prof(P2).eggs do
			eq(e.eggId, "egg_bakugo", "P2 egg")
		end
	end)

	-- ══════════════════════════════════════════════════════════════ ROUND
	test("Round", "Fog Gate closed during GATE; pickups refused; opens after 7 s", function()
		ensureOpen(0)
		RoundService.SkipPhase() -- OPEN → RESET → GATE
		expect(
			waitFor(function()
				return phase() == "GATE"
			end, 6),
			"never reached GATE (phase " .. phase() .. ")"
		)
		local gate = workspace.SAE_World.Hub.FogGate
		eq(gate:GetAttribute("Closed"), true, "FogGate Closed attribute")
		eq(gate:FindFirstChild("Blocker").CanCollide, true, "FogGate blocker collides")
		near(phaseRemaining(), Balance.OWNER_LOCKED.FogGateSeconds, 1, "GATE duration remaining")
		teleport(P1, nearEgg(E2))
		eq(EggService.TestPickUp(P1, E2), false, "pickup during GATE")
		expect(
			waitFor(function()
				return phase() == "OPEN"
			end, Balance.OWNER_LOCKED.FogGateSeconds + 2),
			"GATE did not open by itself"
		)
		eq(gate:GetAttribute("Closed"), false, "FogGate Closed after opening")
		eq(gate:FindFirstChild("Blocker").CanCollide, false, "FogGate blocker after opening")
		near(phaseRemaining(), Balance.OWNER_LOCKED.RoundSeconds - Balance.OWNER_LOCKED.FogGateSeconds, 2, "OPEN duration")
		teleport(P1, safePoint())
	end)

	test("Round", "round reset: carriers lose the egg, players return home, profile eggs kept", function()
		freshProfile(P1, 0)
		ensureOpen(90)
		calmWorld()
		pickUp(P1, E1)
		secureViaSafeZone(P1)
		local keptEggs = count(prof(P1).eggs)
		pickUp(P1, E2)
		local round0 = workspace:GetAttribute("RoundNumber")
		RoundService.SkipPhase()
		expect(
			waitFor(function()
				return phase() == "GATE"
			end, 6),
			"round did not reset into GATE"
		)
		eq(workspace:GetAttribute("RoundNumber"), round0 + 1, "RoundNumber")
		eq(EggService.IsCarrying(P1), false, "carrier after reset")
		eq(eggInfo(E2).state, "AVAILABLE", "carried egg after reset")
		eq(eggInfo(E1).state, "AVAILABLE", "taken world egg restored for the next round")
		eq(eggInfo(E2).spawnVisible, true, "egg visible on its pedestal")
		local r = rootOf(P1).Position
		expect(Layout.isInSafeZone(r.X, r.Y, r.Z), "player not returned to the Farm Safe Zone (at " .. fmt(r) .. ")")
		eq(count(prof(P1).eggs), keptEggs, "secured eggs in profile survive the reset")
		for _, w in Worlds.ORDER do
			eq(bossState(w), "IDLE", w .. " boss after reset")
		end
		eq(workspace.SAE_World.Hub.FogGate:GetAttribute("Closed"), true, "FogGate closed at round start")
	end)

	-- ══════════════════════════════════════════════════════════ DISCONNECT
	test("Disconnect", "disconnect cleanup: carried egg returns, farm released", function()
		if not P2 then
			skip("needs 2 players")
		end
		if ServerStorage:GetAttribute("SAE_TestDisconnect") ~= true then
			skip("set ServerStorage.SAE_TestDisconnect = true to run (the tester closes Player2's window when asked)")
		end
		ensureOpen(90)
		calmWorld()
		pickUp(P2, E1)
		local farm = FarmService.GetPlayerFarm(P2)
		local gone = false
		local conn = Players.PlayerRemoving:Connect(function(p)
			if p == P2 then
				gone = true
			end
		end)
		print(TAG .. " >>> MANUAL STEP: close the Player2 client window now (waiting 60 s)…")
		waitFor(function()
			return gone
		end, 60, 0.2)
		conn:Disconnect()
		expect(gone, "Player2 did not leave within 60 s")
		task.wait(1)
		eq(eggInfo(E1).state, "AVAILABLE", "carried egg after the carrier left")
		eq(FarmService.GetFarm(farm).model:GetAttribute("OwnerUserId"), 0, "Farm" .. farm .. " released")
		eq(FarmService.GetOwner(farm), nil, "farm owner lookup")
		for _, c in EggService.GetCarriers() do
			expect(c.player ~= P2, "departed player still listed as a carrier")
		end
		P2 = nil
	end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- run + restore + report
-- ═════════════════════════════════════════════════════════════════════════════
if P1 and not aborted then
	local ok, err = pcall(main)
	if not ok then
		record("FAIL", "Harness", "suite aborted", tostring(err), 0)
	end
	-- restore every profile exactly as it was before the run
	for pl, snap in backups do
		if pl.Parent and DataService.Get(pl) then
			local okR, errR = pcall(replaceProfile, pl, snap)
			if not okR then
				warn(TAG .. " could not restore " .. pl.Name .. "'s profile: " .. tostring(errR))
			end
			pcall(function()
				local farm = FarmService.GetPlayerFarm(pl)
				if farm then
					TreadmillService.TestRefresh(farm)
				end
				Remotes.TestClearRate(pl)
				Remotes.TestCall(pl, "RequestEquipTrail", snap.equippedTrail)
				MovementService.Refresh(pl)
				teleportNow(pl, safePoint())
			end)
		end
	end
	pcall(calmWorld)
end

local failed = {}
for _, r in results do
	if r.status == "FAIL" then
		table.insert(failed, r)
	end
end
print(string.rep("=", 78))
print(string.format("%s SUMMARY  PASS %d   FAIL %d   SKIP %d   MANUAL %d   (players %d)", TAG, counts.PASS, counts.FAIL, counts.SKIP, counts.MANUAL, #players))
for _, r in failed do
	warn(string.format("%s   FAILED [%s] %s :: %s", TAG, r.subsystem, r.name, r.detail or ""))
end
for _, r in results do
	if r.status == "MANUAL" then
		print(string.format("%s   MANUAL [%s] %s :: %s", TAG, r.subsystem, r.name, r.detail or ""))
	end
end
print(string.format("%s RESULT: %s", TAG, counts.FAIL == 0 and "ALL AUTOMATED CHECKS PASSED" or "FAILURES PRESENT"))
print(string.rep("=", 78))

local report = ServerStorage:FindFirstChild("SAE_TestReport") or Instance.new("StringValue")
report.Name = "SAE_TestReport"
report.Value = HttpService:JSONEncode({
	finishedAt = os.time(),
	players = #players,
	persistentData = DataService.IsPersistent(),
	counts = counts,
	results = results,
})
report.Parent = ServerStorage
ServerStorage:SetAttribute("SAE_TestsPassed", counts.PASS)
ServerStorage:SetAttribute("SAE_TestsFailed", counts.FAIL)
ServerStorage:SetAttribute("SAE_TestsDone", true)
