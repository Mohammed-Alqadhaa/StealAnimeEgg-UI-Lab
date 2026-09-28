--!strict
-- UIUtil — helpers for binding production templates (no gameplay logic).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Worlds = require(Shared:WaitForChild("Worlds"))
local Economy = require(Shared:WaitForChild("Economy"))

local U = {}

function U.find(root: Instance, path: string): Instance?
	local cur: Instance? = root
	for part in string.gmatch(path, "[^%.]+") do
		cur = cur and cur:FindFirstChild(part)
	end
	return cur
end

function U.text(root: Instance, path: string?, text: string)
	local o = if path then U.find(root, path) else root
	if o and (o:IsA("TextLabel") or o:IsA("TextButton")) then
		o.Text = text
	end
end

function U.show(root: Instance, path: string?, visible: boolean)
	local o = if path then U.find(root, path) else root
	if o and o:IsA("GuiObject") then
		o.Visible = visible
	end
end

-- label / sub text of a chunky button (Face.Content.Label / .Sub)
function U.button(btn: Instance, labelText: string?, subText: string?)
	if labelText then
		U.text(btn, "Face.Content.Label", labelText)
	end
	if subText then
		U.text(btn, "Face.Content.Sub", subText)
	end
end

function U.money(n: number): string
	return "$" .. Economy.format(n)
end

function U.clock(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function U.shortName(charId: string): string
	local c = Worlds.CHARACTERS[charId]
	local n = c and c.name or charId
	return (string.gsub(n, "%s*%(.*%)$", ""))
end

-- Recolour a card's Face gradient with the world palette
function U.tint(card: Instance, worldId: string?)
	local w = worldId and Worlds.WORLDS[worldId]
	local face = card:FindFirstChild("Face")
	local g = face and face:FindFirstChildOfClass("UIGradient")
	if w and g then
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex(w.palette.glow)),
			ColorSequenceKeypoint.new(0.5, Color3.fromHex(w.palette.accent)),
			ColorSequenceKeypoint.new(1, Color3.fromHex(w.palette.wall)),
		})
	end
end

function U.fill(bar: Instance?, alpha: number)
	local fill = bar and bar:FindFirstChild("Fill")
	if fill and fill:IsA("GuiObject") then
		fill.Size = UDim2.new(math.clamp(alpha, 0, 1), 0, 1, 0)
	end
end

--[[
	Keyed list reconciliation: keeps one clone of `template` per key in `container`,
	reusing existing clones (so ViewportFrames are not rebuilt every snapshot).
	build(key, item, clone, isNew) binds the clone. Returns the key → clone map.
]]
function U.reconcile(
	container: Instance,
	template: Instance,
	items: { any },
	keyOf: (any) -> string,
	build: (string, any, Instance, boolean) -> (),
	onNew: ((Instance) -> ())?
)
	local existing: { [string]: Instance } = {}
	for _, c in container:GetChildren() do
		local k = c:GetAttribute("ListKey")
		if typeof(k) == "string" then
			existing[k] = c
		end
	end
	local out = {}
	for i, item in items do
		local key = keyOf(item)
		local c = existing[key]
		local isNew = c == nil
		if not c then
			c = template:Clone()
			c:SetAttribute("ListKey", key)
			c.Name = template.Name .. "_" .. key
		end
		existing[key] = nil
		if c:IsA("GuiObject") then
			c.LayoutOrder = i
		end
		build(key, item, c, isNew)
		if isNew then
			c.Parent = container
			if onNew then
				onNew(c)
			end
		end
		out[key] = c
	end
	for _, stale in existing do
		stale:Destroy()
	end
	return out
end

return U
