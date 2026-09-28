-- Paste into Roblox Studio's Command Bar (View > Command Bar) AFTER filling
-- StarterGui.StealAnimeEggUI.LabScripts.AssetIds with your uploaded image ids.
-- It writes Image / ImageRectOffset / ImageRectSize directly onto the StarterGui
-- copy so the icons are visible while editing (not only in Play mode).
-- Safe to run multiple times. Undo with Ctrl+Z (one ChangeHistory waypoint).

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local gui = game:GetService("StarterGui"):FindFirstChild("StealAnimeEggUI")
assert(gui, "StarterGui.StealAnimeEggUI not found - import the model first")
local scripts = gui:FindFirstChild("LabScripts")
assert(scripts, "LabScripts folder missing")

-- clone before require so edits made in this session are picked up
local ids = require(scripts.AssetIds:Clone())
local manifest = require(scripts.AssetManifest:Clone())

local recording = ChangeHistoryService:TryBeginRecording("Apply StealAnimeEgg asset ids")
local applied, missing = 0, {}
for _, obj in gui:GetDescendants() do
	if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
		local key = obj:GetAttribute("AssetKey")
		local entry = key and manifest.images[key]
		if entry then
			local source = entry.atlas or entry.image
			local id = ids[source]
			if id and id ~= "" and id ~= "rbxassetid://0" then
				obj.Image = id
				if entry.atlas then
					obj.ImageRectOffset = Vector2.new(entry.offset[1], entry.offset[2])
					obj.ImageRectSize = Vector2.new(entry.size[1], entry.size[2])
				end
				applied += 1
			else
				missing[source] = true
			end
		end
	end
end
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
local list = {}
for k in missing do
	table.insert(list, k)
end
print(string.format("[StealAnimeEggUI] applied %d images. Missing ids: %s", applied, #list > 0 and table.concat(list, ", ") or "none"))
