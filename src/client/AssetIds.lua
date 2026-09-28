-- ============================================================================
--  ASSET IDS  (edit me after uploading)
--
--  1. Studio > View > Asset Manager > Bulk Import, select every PNG listed below
--     (assets/png/atlas/*.png, assets/png/fx_rays.png, assets/png/pattern_*.png).
--  2. Right-click each uploaded image > "Copy Asset ID" and paste it here.
--  3. Optional: run src/studio/ApplyAssetIds_CommandBar.lua in the Command Bar so
--     images also show in edit mode (not only at runtime).
--
--  Only 9 uploads are needed because all icons/portraits/eggs are packed into
--  three 1024x1024 atlases (see AssetManifest.lua for the ImageRect of each key).
--  Placeholder "rbxassetid://0" entries are skipped at runtime.
-- ============================================================================
return {
	-- 1024x1024 atlases (icons, portraits, eggs, decorations)
	atlas_a = "rbxassetid://0", -- assets/png/atlas/atlas_a.png
	atlas_b = "rbxassetid://0", -- assets/png/atlas/atlas_b.png
	atlas_c = "rbxassetid://0", -- assets/png/atlas/atlas_c.png

	-- stand-alone images (tiling patterns cannot come from an atlas)
	fx_rays = "rbxassetid://0", -- assets/png/fx_rays.png
	pattern_diagonal = "rbxassetid://0", -- assets/png/pattern_diagonal.png
	pattern_dots = "rbxassetid://0", -- assets/png/pattern_dots.png
	pattern_tiles = "rbxassetid://0", -- assets/png/pattern_tiles.png
	pattern_stars = "rbxassetid://0", -- assets/png/pattern_stars.png
	pattern_hazard = "rbxassetid://0", -- assets/png/pattern_hazard.png
}
