-- StealAnimeEgg UI Lab - client bootstrap (LocalScript)
--
-- Lives inside the StealAnimeEggUI ScreenGui (LabScripts folder), so it works
-- both when the .rbxmx/.rbxm is dropped into StarterGui and when served by Rojo.
--
--   AssetBinder      -> binds uploaded image ids (AssetIds.lua) to every ImageLabel
--   UIController     -> production-style behaviour: nav, menus, tabs, hover/press,
--                       responsive scale, idle animations
--   PREVIEW_*        -> sample-data preview system. Delete PREVIEW_Controller,
--                       PREVIEW_SampleData and the PREVIEW_Panel frame to remove it.

local root = script.Parent
local gui = script:FindFirstAncestorOfClass("ScreenGui")
if not gui then
	warn("[StealAnimeEggUI] Main must live inside the StealAnimeEggUI ScreenGui")
	return
end

local AssetBinder = require(root:WaitForChild("AssetBinder"))
local UIController = require(root:WaitForChild("UIController"))

AssetBinder.bind(gui)
local ui = UIController.start(gui)

local previewModule = root:FindFirstChild("PREVIEW_Controller")
if previewModule and gui:FindFirstChild("PREVIEW_Panel") then
	require(previewModule).start(gui, ui)
end
