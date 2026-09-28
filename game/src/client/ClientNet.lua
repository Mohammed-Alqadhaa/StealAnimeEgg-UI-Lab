--!strict
-- ClientNet — thin wrapper over ReplicatedStorage.SAE_Net (created by the server).
-- Sends INTENT only; the server validates and decides every value (Net.lua).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Net = require(Shared:WaitForChild("Net"))

local ClientNet = {}
local folder = ReplicatedStorage:WaitForChild(Net.FOLDER)

local function remote(name: string): Instance
	return folder:WaitForChild(name)
end

function ClientNet.fire(name: string, ...: any)
	(remote(name) :: RemoteEvent):FireServer(...)
end

function ClientNet.invoke(name: string, ...: any): ...any
	local rf = remote(name) :: RemoteFunction
	local results = table.pack(pcall(rf.InvokeServer, rf, ...))
	if not results[1] then
		warn("[SAE] " .. name .. " failed: " .. tostring(results[2]))
		return false, "network error"
	end
	return table.unpack(results, 2, results.n)
end

function ClientNet.on(name: string, handler: (...any) -> ()): RBXScriptConnection
	return (remote(name) :: RemoteEvent).OnClientEvent:Connect(handler)
end

return ClientNet
