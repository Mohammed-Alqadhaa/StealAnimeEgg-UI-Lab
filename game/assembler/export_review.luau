--!nocheck
-- Export review JSON (for tools/partview) from the assembled Owner Review place.
-- usage: lune run game/assembler/export_review.luau <outdir>
local fs = require("@lune/fs")
local R = require("@lune/roblox")
local process = require("@lune/process")
local E = require("./lib/Export")
local out = process.args[1] or "build/review"
local game = R.deserializePlace(fs.readFile("checkpoints/StealAnAnimeEgg_FullProduction_OwnerReview_v01.rbxlx"))
local ws = game:GetService("Workspace")
local root = ws:FindFirstChild("SAE_World")
local hub = root:FindFirstChild("Hub")
print("hub parts", E.write(out .. "/hub.json", { hub }))
for _, w in root.Worlds:GetChildren() do
	print(w.Name, E.write(out .. "/" .. w.Name .. ".json", { w }))
end
