# Design System — StealAnimeEgg UI Lab

Source of truth for tokens: `tools/lib/theme.js` (mirrored in `src/client/Theme.lua`).
Component recipes: `tools/lib/components.js`. Everything below is built from **native
Roblox GUI instances**; images are used only for icons, portraits, eggs and textures.

## 1. Principles (from `REFERENCE_ANALYSIS.md`)

1. **One ink outline**: every button, card, badge, icon and display text is stroked with
   `Ink #1B1036`. This single decision is what makes the UI read as one family.
2. **Toy-plastic depth**: three layers (Lip → Face → Gloss) instead of flat fills.
3. **One hue per function**, never decorative randomness.
4. **Break the frame**: icons overflow their buttons, badges overlap corners, title
   icons burst out of menu rims.
5. **Numbers are heroes**: currency and timers are the largest text on screen.
6. **Texture everything**: low-contrast tiled patterns on every large surface.
7. **State = colour + shape + text**: never text alone.

## 2. Colour tokens

Each swatch has `hi` (top light), `base`, `lo` (bottom saturated), `lip` (3-D edge), `body`
(menu interior).

| Swatch | hi | base | lo | lip | body | Used for |
|---|---|---|---|---|---|---|
| shop | `#FFA3BE` | `#FF4F7E` | `#D81B5A` | `#8E0E3A` | `#FFE9F0` | Shop nav + menu |
| index | `#A8ECFF` | `#35A2FF` | `#1B63D6` | `#0F3E9E` | `#E4F4FF` | Index, Rare |
| eggs | `#FFF3A6` | `#FFC21F` | `#FF8A00` | `#A85200` | `#FFF5DC` | Eggs, hatch widget |
| chars | `#DCC2FF` | `#9A5CFF` | `#6A2FE0` | `#3E1A99` | `#F1E9FF` | Characters, Epic |
| upgrade | `#D2FF96` | `#5CE63C` | `#1DA53C` | `#0B6B22` | `#EAFFE2` | Upgrade, **go/confirm** buttons |
| speed | `#A6F2FF` | `#35B8FF` | `#1E7BFF` | `#0F4AA8` | — | Speed HUD, hatching state |
| cash | `#C2FFA3` | `#46D95F` | `#1E9F3E` | `#0E5E24` | — | Cash HUD, cash packs |
| red | `#FFA597` | `#FF4D4D` | `#D81B2E` | `#7A0A18` | — | Close, Unequip, DROP, danger |
| gold | `#FFF7B0` | `#FFD23F` | `#FFA000` | `#A85F00` | — | Premium, Equip Best, active tab, Legendary |
| slate | `#A7AFD6` | `#6E76A0` | `#4A5078` | `#262A45` | — | Disabled / MAX LEVEL / inactive tabs |
| night | `#6B4DD6` | `#3A2A8F` | `#1F155A` | `#0E0930` | — | VIP, Secret |

**Rarity**: Rare = index blue · Epic = violet · Legendary = gold · Mythic = hot pink
(`#FF9AD5 → #FF3D8B → #C2126B`) · Secret = rainbow gradient at 45°
(`#FF4F7E #FFD23F #46D95F #35B8FF #9A5CFF`). Locked = slate-violet (`#6E6699 → #2A2447`).

**Semantic rules**: green = act/confirm, red = close/danger/unequip, gold = premium or
"best", slate = unavailable/maxed, blue = in-progress (hatching).

## 3. Typography

| Role | Roblox font | Size @1280×720 | Treatment |
|---|---|---|---|
| Menu title | Luckiest Guy (`rbxasset://fonts/families/LuckiestGuy.json`) | 54 | white→theme.hi gradient, 5 px ink stroke |
| HUD values | Luckiest Guy | 36 | white→theme.hi gradient, 3.5 px stroke |
| Button label | Luckiest Guy | 21–32 | white, 2.5–3.5 px stroke |
| Card name | Luckiest Guy | 21–25 | white→rarity.hi, 2.5–3 px stroke |
| Captions / body | Fredoka One (`…/FredokaOne.json`) | 13–20 | white + 2 px stroke on colour; ink/no stroke on white |

Stroke = `UIStroke` with `ApplyStrokeMode.Contextual`, `LineJoinMode.Round`.
Rule of thumb: stroke ≈ 9–10 % of text size.

## 4. Component recipes

### Chunky button (`chunky()` / `chunkyFaces()`)
```
TextButton  (transparent hit box, AutoButtonColor=false)  attrs: Chunky, LipDepth
├─ UIScale "PressScale"            hover 1.06 / press 0.96 (UIController)
├─ Lip   Frame  colour=lip, UICorner r, UIStroke 3–3.5 ink          ZIndex 1
└─ Face  Frame  size (1,0,1,-lip), UIGradient hi→base→lo @90°       ZIndex 2
   ├─ UIStroke "InnerRim" 2px hi @35% transparency (inner light edge)
   ├─ Pattern ImageLabel (tile 40, ImageTransparency .88–.9, UICorner r)
   ├─ Gloss Frame (top 46 %, white, gradient transparency .45→.95)
   └─ Content Frame (Icon ImageLabel + Label/Sub TextLabels)
```
Pressed = `Face.Position.Y = LipDepth-2` (face sinks onto the lip). Lip depth 5–8 px.
Corner radius 10–18. The Lip is darker than `lo` so the 3-D edge always reads.

### Menu window (`menuWindow()`)
760×520 at base resolution, centred (AnchorPoint .5,.5).
Rim (theme gradient, 4.5 px ink stroke, dot pattern, gloss strip, 4 gold rivets) →
Body inset 14 px (theme `body` colour, tile pattern tinted with theme `base`, 3.5 px
`lip` stroke, top inner shade) → Content. Title badge icon 120 px rotated −10° bursting
out of the top-left corner; title text 54 px; red chunky close button overlapping the
top-right corner. `MenuBackdrop` dims the world (ink @45 %) while any menu is open;
the Nav stays above it.

### Collectible card (Index / Characters)
Rarity Lip + Face gradient + star pattern + gloss → PortraitWell (dark translucent,
spinning rays) → Portrait ImageLabel overflowing upward → ink NamePlate.
Locked variant: slate face, **same portrait with `ImageColor3 = 0,0,0`** (true
silhouette, outline preserved), name `???`, lock badge in the corner (the lock never
replaces the character).

### Progress bar (`progress()`)
Ink-outlined pill track (`#2A1F5C`) + inner shade → Fill with theme gradient, shine
strip and moving-stripe texture → centred label. `Fill.Size.X.Scale = value`.

### Badges & tags
Circle badge (count / "!") = pill frame with gradient + 2.5 px ink stroke, overlapping
a corner by ~6 px. Ribbon tag ("NEW!", "BEST VALUE", "SAMPLE PRICES") = small rounded
rect, rotated −12…+10°.

## 5. Iconography

53 original SVGs (`assets/svg`) drawn on a 256 grid with a **10–12 px ink outline painted
behind the fill** (`paint-order: stroke`), vertical gradients (light top), a white gloss
crescent top-left and 1–2 sparkles. No emoji, no Unicode glyphs, no third-party art.

* Nav: shopping bag + coin, star book, zig-zag egg, stacked character cards, green arrow.
* Speed: **original sprinting figure** bursting out of cyan motion streaks with a lightning
  accent (replaces the rejected sneaker clip-art of reference R3).
* Cash: three-bill stack with a gold star coin.
* Portraits: original chibi busts, each with a **unique silhouette** (flame mane, hat,
  ponytail, short spikes, medium spikes) so locked silhouettes stay identifiable.
* Eggs: five eggs with distinct patterns (checker/flame band, cosmic, flame, moon, gold).
* FX: sunburst rays (white, tinted via `ImageColor3`), radial glow, sparkles.
* Textures (tiling, white on transparent): diagonal, dots, tiles, stars, hazard.

Icons are packed into three 1024² atlases (`assets/png/atlas`) and addressed with
`ImageRectOffset/ImageRectSize` → only 9 uploads.

## 6. Layout & responsiveness

* Design resolution **1280×720**; every top-level frame has a `UIScale` named
  `AutoScale`. `UIController` sets `Scale = clamp(min(vw/1280, vh/720), 0.45, 2)`.
* Placement uses **scale anchors**: Nav = left/middle, HUD = bottom-left, Carry =
  bottom-centre, Hatch timer = bottom-right, Menus = centre, Preview panel = top-right.
  `IgnoreGuiInset = true`, `ScreenInsets = DeviceSafeInsets` (notch-safe on phones).
* Inside components: offsets for chunky pixel-precise art, `UIListLayout` /
  `UIGridLayout` for lists and grids, `AutomaticSize` for pills, `AutomaticCanvasSize`
  for scrolling lists, `UITextSizeConstraint` + `TextScaled` for long names.
* Verified layouts (browser approximation): 1280×720, 1920×1080, 1024×768, 844×390,
  667×375.

## 7. Motion (attribute driven, `UIController`)

| Attribute | Effect |
|---|---|
| `Spin = <deg/s>` | continuous rotation (rays) |
| `Wobble = true` | ±6° rocking (eggs that are hatching/ready) |
| `Bob = true` | ±4 px float (title icons, shop icons) |
| `Pulse = true` | 4.5 % breathing scale (READY!, OPEN!, warning) |
| menu open | AutoScale 85 % → 100 % with Back easing |
| button hover / press | PressScale 1.06 / 0.96, face sinks onto lip |

## 8. Naming conventions

`<Id>Menu`, `<Id>Button` (nav), `Card_<charId>`, `Unit_<unitId>`, `EggCard_<eggId>`,
`Row_<unitId>`, `State<Owned|Hatching|Ready|Opened>`, `<Tab>Page`, `Tab_<Tab>`.
Anything preview-only is prefixed `PREVIEW_`.
