--!strict
-- DevClient — developer panel, shown ONLY in Roblox Studio. The server
-- (DevService) independently rejects dev commands outside Studio unless the
-- player is on its explicit developer whitelist.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Worlds = require(Shared:WaitForChild("Worlds"))

local DevClient = {}

function DevClient.start(ctx)
	local panel = ctx.gui:FindFirstChild("DevPanel")
	if not panel then
		return
	end
	if not RunService:IsStudio() then
		panel:Destroy()
		return
	end
	panel.Visible = true
	for _, b in panel:GetDescendants() do
		local cmd = b:GetAttribute("DevCmd")
		if b:IsA("GuiButton") and typeof(cmd) == "string" then
			b.Activated:Connect(function()
				local arg: any = b:GetAttribute("DevArg")
				if arg == "random" then
					local list = Worlds.characterList()
					arg = list[math.random(1, #list)]
				elseif tonumber(arg) then
					arg = tonumber(arg)
				end
				local ok, why = ctx.net.invoke("RequestDevCommand", cmd, arg)
				ctx.toast(ok and "ok" or "warn", "[dev] " .. cmd .. (ok and " ok" or (": " .. tostring(why))))
			end)
		end
	end
end

return DevClient
