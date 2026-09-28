--!strict
-- ClientState — latest private StateSnapshot from the server (read-only mirror).
-- Countdowns are rendered from absolute server timestamps (hatchAt) with
-- workspace:GetServerTimeNow(); the server never streams per-second ticks.
local ClientNet = require(script.Parent:WaitForChild("ClientNet"))

local ClientState = {}
ClientState.data = nil :: any
local changed = Instance.new("BindableEvent")
ClientState.Changed = changed.Event

local function set(snap: any)
	if type(snap) ~= "table" then
		return
	end
	ClientState.data = snap
	-- index helpers
	snap.unitsByUid = {}
	for _, u in snap.units or {} do
		snap.unitsByUid[u.uid] = u
	end
	changed:Fire(snap)
end

function ClientState.start()
	ClientNet.on("StateSnapshot", set)
	task.spawn(function()
		for _ = 1, 20 do
			local snap = ClientNet.invoke("RequestInitialState")
			if type(snap) == "table" then
				if not ClientState.data then
					set(snap)
				end
				return
			end
			task.wait(1)
		end
	end)
end

-- calls fn(data) now (if loaded) and on every change
function ClientState.observe(fn: (any) -> ())
	if ClientState.data then
		task.spawn(fn, ClientState.data)
	end
	return ClientState.Changed:Connect(fn)
end

function ClientState.now(): number
	return workspace:GetServerTimeNow()
end

return ClientState
