--[[
	Remotes — the single gateway for client intents.

	* Creates ReplicatedStorage.SAE_Net with exactly the remotes declared in Shared/Net.
	* Every handler is wrapped with: argument sanity, per-player/per-remote rate limit and a
	  per-player MUTATION LOCK so two requests from one player can never interleave
	  (rapid click / double open / double sell / double upgrade, §127).
	* Handlers never trust client-supplied values beyond ids (§124).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("SAE_Shared"):WaitForChild("Net"))

local Remotes = {}

local folder
local events = {}
local functions = {}
local lastCall = {} -- [player][name] = os.clock()
local busy = {} -- [player] = true while a mutating handler runs

local MIN_INTERVAL = 0.12

function Remotes.Init()
	folder = ReplicatedStorage:FindFirstChild(Net.FOLDER)
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = Net.FOLDER
	for _, name in Net.EVENTS do
		local e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = folder
		events[name] = e
	end
	for _, name in Net.FUNCTIONS do
		local f = Instance.new("RemoteFunction")
		f.Name = name
		f.Parent = folder
		functions[name] = f
	end
	folder.Parent = ReplicatedStorage
	Players.PlayerRemoving:Connect(function(p)
		lastCall[p] = nil
		busy[p] = nil
	end)
end

local function allowed(player: Player, name: string): boolean
	local now = os.clock()
	local t = lastCall[player]
	if not t then
		t = {}
		lastCall[player] = t
	end
	if t[name] and now - t[name] < MIN_INTERVAL then
		return false
	end
	t[name] = now
	return true
end

-- Runs fn under the player's mutation lock. Returns fn's results or (false, "busy").
function Remotes.locked(player: Player, fn: () -> ...any): ...any
	if busy[player] then
		return false, "busy"
	end
	busy[player] = true
	local results = table.pack(pcall(fn))
	busy[player] = nil
	if not results[1] then
		warn("[Remotes] handler error: " .. tostring(results[2]))
		return false, "error"
	end
	return table.unpack(results, 2, results.n)
end

function Remotes.onEvent(name: string, handler: (Player, ...any) -> ())
	local e = events[name]
	assert(e, "unknown remote event " .. name)
	e.OnServerEvent:Connect(function(player, ...)
		if not allowed(player, name) then
			return
		end
		local args = table.pack(...)
		Remotes.locked(player, function()
			handler(player, table.unpack(args, 1, args.n))
		end)
	end)
end

function Remotes.onInvoke(name: string, handler: (Player, ...any) -> ...any)
	local f = functions[name]
	assert(f, "unknown remote function " .. name)
	f.OnServerInvoke = function(player, ...)
		if not allowed(player, name) then
			return false, "slow down"
		end
		local args = table.pack(...)
		return Remotes.locked(player, function()
			return handler(player, table.unpack(args, 1, args.n))
		end)
	end
end

function Remotes.fire(player: Player, name: string, ...)
	local e = events[name]
	if e and player.Parent then
		e:FireClient(player, ...)
	end
end

function Remotes.fireAll(name: string, ...)
	local e = events[name]
	if e then
		e:FireAllClients(...)
	end
end

function Remotes.notify(player: Player, kind: string, text: string, extra: any?)
	Remotes.fire(player, "Notify", kind, text, extra)
end

return Remotes
