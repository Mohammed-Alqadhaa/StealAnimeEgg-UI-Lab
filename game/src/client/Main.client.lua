--!strict
--[[
	SAE_Client boot (StarterPlayerScripts.SAE_Client).
	Production UI = StarterGui.SAE_UI, built from the UI Lab design system
	(tools/build-prod.js). No demo data and no UI Lab preview panel.
]]
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local here = script.Parent

local UIController = require(here:WaitForChild("UIController"))
local AssetBinder = require(here:WaitForChild("AssetBinder"))
local ClientNet = require(here:WaitForChild("ClientNet"))
local ClientState = require(here:WaitForChild("ClientState"))

local gui = player:WaitForChild("PlayerGui"):WaitForChild("SAE_UI") :: ScreenGui
AssetBinder.bind(gui)
local ui = UIController.start(gui)

local ctx = {
	gui = gui,
	ui = ui,
	net = ClientNet,
	state = ClientState,
	toast = function(_kind: string, _text: string) end,
	openEgg = function(_uid: string) end,
}

local function boot(name: string)
	local ok, err = pcall(function()
		local mod = require(here:WaitForChild(name)) :: any
		mod.start(ctx)
		if name == "HudApp" then
			ctx.toast = mod.toast
		end
	end)
	if not ok then
		warn("[SAE_Client] " .. name .. " failed to start: " .. tostring(err))
	end
end

boot("HudApp")
boot("MenusApp")
boot("WorldClient")
boot("FxClient")
boot("DevClient")
ClientState.start()
