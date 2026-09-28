--!strict
--[[
	TestGate — the ONLY switch for the Studio Play-mode test harness (SAE_StudioTests).

	Test hooks exposed by services (Remotes.TestCall, EggService.TestPickUp, …) refuse to
	run unless BOTH are true:
	  1. RunService:IsStudio()                    → never true on live Roblox servers
	  2. ServerStorage attribute SAE_EnableStudioTests == true (set it explicitly in Studio
	     before pressing Play; it is not set in any committed build)

	The hooks only reach code paths clients already reach (same rate limit, same mutation
	lock, same validation), so they do not widen what a player can do — and outside Studio
	they are inert.
]]
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local TestGate = {}

TestGate.FLAG = "SAE_EnableStudioTests"

function TestGate.enabled(): boolean
	return RunService:IsStudio() and ServerStorage:GetAttribute(TestGate.FLAG) == true
end

function TestGate.check(hook: string)
	if not TestGate.enabled() then
		error("[SAE] test hook " .. hook .. " is disabled (Studio + ServerStorage." .. TestGate.FLAG .. " required)", 2)
	end
end

return TestGate
