-- Binds uploaded image ids to every ImageLabel/ImageButton that carries an
-- `AssetKey` attribute. Atlas crops (ImageRectOffset/Size) come from
-- AssetManifest.lua (generated) so art can be re-packed without touching the UI.

local AssetIds = require(script.Parent:WaitForChild("AssetIds"))
local Manifest = require(script.Parent:WaitForChild("AssetManifest"))

local AssetBinder = {}

local PLACEHOLDER = "rbxassetid://0"
local warned = false

local function resolve(key: string): (string?, Vector2?, Vector2?)
	local entry = Manifest.images[key]
	if not entry then
		return nil
	end
	if entry.atlas then
		return AssetIds[entry.atlas], Vector2.new(entry.offset[1], entry.offset[2]), Vector2.new(entry.size[1], entry.size[2])
	end
	return AssetIds[entry.image], nil, nil
end

function AssetBinder.apply(obj: Instance)
	if not (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
		return
	end
	local key = obj:GetAttribute("AssetKey")
	if typeof(key) ~= "string" then
		return
	end
	local id, offset, size = resolve(key)
	if not id or id == "" or id == PLACEHOLDER then
		if not warned then
			warned = true
			warn("[SAE_UI] Image ids not set yet - upload assets/png and fill SAE_Client.AssetIds (OWNER ACTION, see docs/IMPORT_GUIDE.md)")
		end
		return
	end
	obj.Image = id
	if offset and size then
		obj.ImageRectOffset = offset
		obj.ImageRectSize = size
	end
end

function AssetBinder.bind(root: Instance)
	for _, d in root:GetDescendants() do
		AssetBinder.apply(d)
	end
	root.DescendantAdded:Connect(AssetBinder.apply)
end

return AssetBinder
