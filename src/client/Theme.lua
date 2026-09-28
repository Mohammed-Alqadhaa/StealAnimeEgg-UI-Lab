-- Design tokens (mirror of tools/lib/theme.js and docs/DESIGN_SYSTEM.md).
-- Use these when adding new UI so everything stays in the same family.

local function hex(h: string): Color3
	return Color3.fromHex(h)
end

local function swatch(hi, base, lo, lip, body)
	return { hi = hex(hi), base = hex(base), lo = hex(lo), lip = hex(lip), body = hex(body) }
end

local Theme = {
	Ink = hex("#1B1036"), -- the one outline colour used by every stroke
	Fonts = {
		Display = Font.new("rbxasset://fonts/families/LuckiestGuy.json"),
		Body = Font.new("rbxasset://fonts/families/FredokaOne.json"),
	},
	Swatch = {
		Shop = swatch("#FFA3BE", "#FF4F7E", "#D81B5A", "#8E0E3A", "#FFE9F0"),
		Index = swatch("#A8ECFF", "#35A2FF", "#1B63D6", "#0F3E9E", "#E4F4FF"),
		Eggs = swatch("#FFF3A6", "#FFC21F", "#FF8A00", "#A85200", "#FFF5DC"),
		Characters = swatch("#DCC2FF", "#9A5CFF", "#6A2FE0", "#3E1A99", "#F1E9FF"),
		Upgrade = swatch("#D2FF96", "#5CE63C", "#1DA53C", "#0B6B22", "#EAFFE2"),
		Speed = swatch("#A6F2FF", "#35B8FF", "#1E7BFF", "#0F4AA8", "#E4F6FF"),
		Cash = swatch("#C2FFA3", "#46D95F", "#1E9F3E", "#0E5E24", "#E8FFE8"),
		Red = swatch("#FFA597", "#FF4D4D", "#D81B2E", "#7A0A18", "#FFE8E8"),
		Gold = swatch("#FFF7B0", "#FFD23F", "#FFA000", "#A85F00", "#FFF8DC"),
		Slate = swatch("#A7AFD6", "#6E76A0", "#4A5078", "#262A45", "#E9EBF5"),
	},
	Rarity = {
		Rare = hex("#35A2FF"),
		Epic = hex("#9A5CFF"),
		Legendary = hex("#FFD23F"),
		Mythic = hex("#FF3D8B"),
		Secret = hex("#3A2A8F"),
	},
	BaseResolution = Vector2.new(1280, 720),
}

-- Chunky button face gradient for a swatch
function Theme.faceGradient(s): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, s.hi),
		ColorSequenceKeypoint.new(0.5, s.base),
		ColorSequenceKeypoint.new(1, s.lo),
	})
end

return Theme
