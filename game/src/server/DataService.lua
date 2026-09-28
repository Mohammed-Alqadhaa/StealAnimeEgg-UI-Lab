--[[
	DataService — persistence with session locking (§126, §127).

	* One DataStore key per user: { data = <Profile>, lock = { job = JobId, t = unix } }.
	* Load uses UpdateAsync to acquire the session lock; a lock held by another live
	  server is respected (retry), a stale lock (> LOCK_STALE s) is taken over. This
	  prevents two servers writing the same profile (duplication on teleport/rejoin).
	* Saves only while we still own the lock. Autosave, save on leave, BindToClose.
	* If DataStores are unavailable (Studio without "Enable Studio Access to API
	  Services"), profiles are kept in memory for the session and a warning is printed —
	  gameplay still works, nothing is claimed as persisted.
	* Every mutation goes through DataService.mutate(player, fn) which marks the profile
	  dirty and pushes a private snapshot + public attributes to the client.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Profile = require(Shared.Profile)
local Balance = require(Shared.Balance)

local DataService = {}

local STORE_NAME = "SAE_Profiles_v1"
local LOCK_STALE = 30 * 60
local MAX_LOAD_ATTEMPTS = 6

local store = nil
local persistent = false
local profiles = {} -- [player] = profile table
local dirty = {} -- [player] = true
local loaded = {} -- [player] = true once the profile is usable
local pushQueued = {} -- [player] = true (debounced snapshot)
local listeners = {} -- functions(player, profile) called after every mutation
local loadedListeners = {}

local Remotes -- injected in Start to avoid a require cycle

local function now(): number
	return workspace:GetServerTimeNow()
end

local function key(userId: number): string
	return "u_" .. userId
end

local function tryStore()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		-- a cheap probe: Studio without API access errors here
		local probeOk = pcall(function()
			result:GetAsync("__probe")
		end)
		if probeOk then
			return result
		end
	end
	return nil
end

local function acquire(player: Player)
	if not persistent then
		return Profile.new()
	end
	for attempt = 1, MAX_LOAD_ATTEMPTS do
		local data, lockedElsewhere = nil, false
		local ok, err = pcall(function()
			store:UpdateAsync(key(player.UserId), function(old)
				old = old or {}
				local lock = old.lock
				if lock and lock.job ~= game.JobId and os.time() - (lock.t or 0) < LOCK_STALE then
					lockedElsewhere = true
					return nil -- keep as is
				end
				old.lock = { job = game.JobId, t = os.time() }
				data = old.data
				return old
			end)
		end)
		if ok and not lockedElsewhere then
			return Profile.migrate(data)
		end
		warn(string.format("[Data] load attempt %d for %s failed: %s", attempt, player.Name, lockedElsewhere and "session locked elsewhere" or tostring(err)))
		task.wait(math.min(2 ^ attempt, 12))
		if not player.Parent then
			return nil
		end
	end
	return nil
end

local function write(player: Player, release: boolean): boolean
	if not persistent then
		return true
	end
	local p = profiles[player]
	if not p then
		return false
	end
	local ok, err = pcall(function()
		store:UpdateAsync(key(player.UserId), function(old)
			old = old or {}
			if old.lock and old.lock.job ~= game.JobId then
				return nil -- we lost the lock; never overwrite another server's session
			end
			old.data = p
			old.lock = if release then nil else { job = game.JobId, t = os.time() }
			return old
		end)
	end)
	if not ok then
		warn("[Data] save failed for " .. player.Name .. ": " .. tostring(err))
	else
		dirty[player] = nil
	end
	return ok
end

-- ── public attributes (readable by every client, written only here) ──────────
local function publish(player: Player, p)
	player:SetAttribute("Cash", p.cash)
	player:SetAttribute("Speed", math.floor(p.speed))
	player:SetAttribute("IncomePerSec", Profile.activeIncome(p))
	player:SetAttribute("EquippedTrail", p.equippedTrail or "")
	player:SetAttribute("TreadmillLevel", p.treadmillLevel)
	player:SetAttribute("FarmLevel", p.farmLevel)
end

local function queuePush(player: Player)
	if pushQueued[player] then
		return
	end
	pushQueued[player] = true
	task.delay(0.1, function()
		pushQueued[player] = nil
		local p = profiles[player]
		if p and player.Parent and Remotes then
			Remotes.fire(player, "StateSnapshot", Profile.snapshot(p, now()))
		end
	end)
end

function DataService.Init()
	store = tryStore()
	persistent = store ~= nil
	if not persistent then
		warn("[Data] DataStores unavailable — profiles are IN-MEMORY for this session (Studio API access off?)")
	end
end

function DataService.Start(remotes)
	Remotes = remotes
	local function onJoin(player: Player)
		local p = acquire(player)
		if not p then
			player:Kick("Your data could not be loaded safely. Please rejoin in a moment.")
			return
		end
		profiles[player] = p
		loaded[player] = true
		publish(player, p)
		player:SetAttribute("DataLoaded", true)
		for _, fn in loadedListeners do
			task.spawn(fn, player, p)
		end
		queuePush(player)
	end
	Players.PlayerAdded:Connect(onJoin)
	for _, player in Players:GetPlayers() do
		task.spawn(onJoin, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		if profiles[player] then
			write(player, true)
		end
		profiles[player] = nil
		loaded[player] = nil
		dirty[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(Balance.AutosaveSeconds)
			for player in dirty do
				if player.Parent then
					task.spawn(write, player, false)
				end
			end
		end
	end)
	game:BindToClose(function()
		if RunService:IsStudio() and not persistent then
			return
		end
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				write(player, true)
				pending -= 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 25 do
			task.wait(0.2)
		end
	end)
	remotes.onInvoke("RequestInitialState", function(player)
		local p = profiles[player]
		return p and Profile.snapshot(p, now()) or nil
	end)
end

function DataService.Get(player: Player)
	return profiles[player]
end

function DataService.IsLoaded(player: Player): boolean
	return loaded[player] == true
end

function DataService.OnLoaded(fn)
	table.insert(loadedListeners, fn)
end

function DataService.OnChanged(fn)
	table.insert(listeners, fn)
end

-- Run an authoritative mutation. fn(profile) -> ok, result. Changes are published.
function DataService.mutate(player: Player, fn): (boolean, any)
	local p = profiles[player]
	if not p then
		return false, "profile not loaded"
	end
	local ok, result = fn(p)
	if ok then
		dirty[player] = true
		publish(player, p)
		queuePush(player)
		for _, l in listeners do
			task.spawn(l, player, p)
		end
	end
	return ok, result
end

-- Cheap path for high-frequency numeric updates (income, treadmill) — no snapshot spam.
function DataService.touchNumbers(player: Player)
	local p = profiles[player]
	if p then
		dirty[player] = true
		publish(player, p)
	end
end

function DataService.ForceSave(player: Player): boolean
	return write(player, false)
end

function DataService.IsPersistent(): boolean
	return persistent
end

function DataService.Now(): number
	return now()
end

return DataService
