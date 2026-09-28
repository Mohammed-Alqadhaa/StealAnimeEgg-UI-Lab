# UI Hierarchy

The full generated outline (every frame, modifier, image key and attribute) is in
[`UI_HIERARCHY_TREE.txt`](UI_HIERARCHY_TREE.txt). Instance counts of the exported model:
~4,400 instances: Frame 1,067 · UICorner 905 · UIStroke 819 · ImageLabel 447 ·
UIGradient 433 · TextLabel 373 · TextButton 105 · UIScale 89 · UIListLayout 82 ·
UIPadding 36 · UITextSizeConstraint 16 · UIGridLayout 10 · ScrollingFrame 3 ·
ViewportFrame 2 · ModuleScript 7 · LocalScript 1.

## Top level (`StarterGui.StealAnimeEggUI`, ScreenGui)

`ResetOnSpawn=false`, `ZIndexBehavior=Sibling`, `IgnoreGuiInset=true`,
`ScreenInsets=DeviceSafeInsets`, `DisplayOrder=5`. Paint order is fixed with explicit
ZIndex on every GuiObject (the build re-ranks siblings deterministically).

| # | Frame | Anchor / position | Purpose |
|---|---|---|---|
| 1 | `HUD` | (0,1) bottom-left | Speed + Cash bars with icon badges, caption tabs, `+` buttons, income rate |
| 2 | `HatchTimer` | (1,1) bottom-right | HATCHING (timer + bar) / READY (pulsing text + OPEN) |
| 3 | `EggCarry` | (0.5,1) bottom-centre | `Unsafe` (hazard banner + **DropButton**) / `Secured` (green, shield, **no DROP**) + `Egg3D` ViewportFrame |
| 4 | `MenuBackdrop` | full screen | dims the world while a menu is open |
| 5 | `Nav` | (0,0.5) left | ShopButton, IndexButton, EggsButton, CharactersButton, UpgradeButton (UIListLayout) |
| 6–10 | `ShopMenu`, `IndexMenu`, `EggsMenu`, `CharactersMenu`, `UpgradeMenu` | centre | menus (hidden by default) |
| 11 | `PREVIEW_Panel` | (1,0) top-right | **preview-only** state switcher |
| — | `LabScripts` (Folder) | — | `Main` LocalScript + ModuleScripts |

## Menu anatomy (all five share it)

```
<Id>Menu [Frame]  attrs: Layer=Menu, Menu=<Id>
├─ AutoScale [UIScale]
├─ DropShadow
├─ Rim  {Corner, Gradient, Stroke}
│  ├─ RimPattern (pattern_dots) · RimGloss · Rivet1..4 (deco_rivet)
│  └─ Body {Corner, Stroke}
│     ├─ BodyPattern (pattern_tiles) · TopShade
│     └─ Content            <- menu-specific content lives here
├─ TitleBadge (Glow + Icon)   Title [TextLabel]   CloseButton (Action=CloseMenu)
```

### Shop — `ShopMenu.Rim.Body.Content.Scroll` (ScrollingFrame, UIListLayout)
`Featured` (Anime Egg banner: EggStage, NewTag, Title, DropStrip with 5 `Drop_<id>` tiles,
Prices `Buy1..3`) · `PacksRow` (StarterPack, VIP) · `CashHeader` + `CashRow` (Cash1..4) ·
`BoostHeader` + `BoostRow` (Boost1..4) · `SpecialHeader` + `SpecialRow` (Special1..2).
All buy buttons carry `Purchase` + `SamplePrice` attributes. Header shows `SampleTag`.

### Index — `IndexMenu.Rim.Body.Content`
`CollectionHeader` (Emblem, Series "DEMON SLAYER", Discovered "X / 5 Discovered",
`Progress` bar, Reward) · `Grid` (UIGridLayout) → `Card_rengoku`, `Card_yoriichi`,
`Card_muzan`, `Card_akaza`, `Card_tanjiro`, each with **`Unlocked`** (colour portrait +
name) and **`Locked`** (same portrait, `ImageColor3 = black` silhouette, `???`,
LockBadge) · `Hint`.

### Eggs — `EggsMenu.Rim.Body.Content`
`TopBar` (Storage, HatchTime, HatchAllButton) · `Grid` → `EggCard_<id>` each holding
four pre-built state frames **`StateOwned` / `StateHatching` / `StateReady` /
`StateOpened`** (exactly one visible). Buttons: `HatchButton`, `SkipButton`,
`OpenButton`, `CollectButton` (`EggAction` + `EggId` attributes).

### Characters — `CharactersMenu.Rim.Body.Content`
`TopBar` (Equipped "3 / 4" + Slot1..4 pips, Income total, **EquipBestButton**) ·
`Grid` (ScrollingFrame + UIGridLayout) → `Unit_<char>_<n>` (separate cards per duplicate
unit, e.g. `Unit_rengoku_1`, `Unit_rengoku_2`): LevelPill, UnitChip `#n`, PortraitWell,
Name, IncomeRow `$/s`, `EquipButton` / `UnequipButton`, `EquippedRing`, `EquippedBadge`.

### Upgrade — `UpgradeMenu.Rim.Body.Content`
`Tabs` → `Tab_Character`, `Tab_Treadmill`, `Tab_Farm` (each with `Active`/`Inactive`
variants) · `Pages` →
* `CharacterPage` (ScrollingFrame) → `Row_<unitId>`: Tile+Portrait, Name, UnitChip,
  Level, Pips (10), Income current → next, **UpgradeButton** (cost) / **MaxLevelButton**.
* `TreadmillPage`: Showcase (treadmill art, LEVEL ribbon) + Info (LevelBar, SpeedGain
  stat card current → next, UpgradeButton cost / MaxLevelButton).
* `FarmPage`: Showcase (farm art) + Info (LevelBar, Slots stat card 4 → 5, SlotsRow
  visual, UpgradeButton cost / MaxLevelButton). *No boxing bag.*

## Attribute contract

| Attribute | On | Meaning |
|---|---|---|
| `AssetKey` | ImageLabel/Button | key in `AssetManifest` → atlas id + rect (bound by `AssetBinder`) |
| `Silhouette` | Portrait | true for the locked (black) variant |
| `Layer` | top-level frames | HUD / Nav / Menu / Backdrop / Preview |
| `Menu` | menu roots | menu id used by `UIController:OpenMenu` |
| `NavTarget` | nav buttons | menu to toggle |
| `Action` | buttons | `CloseMenu`, `DropEgg`, `OpenEgg`, `BuySpeed`, `BuyCash` |
| `Tab` | tab buttons | Upgrade page to show |
| `Chunky`, `LipDepth` | chunky buttons | enables hover/press feedback |
| `Disabled` | MAX LEVEL buttons | no press feedback |
| `Spin`, `Wobble`, `Bob`, `Pulse` | any GuiObject | idle motion |
| `EggAction`/`EggId`, `UnitAction`/`UnitId`, `UpgradeAction`, `Purchase`/`SamplePrice` | buttons | hooks for real game code (preview simulates them) |
| `PreviewAction`, `PREVIEW_ONLY` | preview panel | preview-only |

## Scripts (`LabScripts`)

| Script | Type | Role |
|---|---|---|
| `Main` | LocalScript | bootstrap: AssetBinder → UIController → (optional) PREVIEW_Controller |
| `UIController` | ModuleScript | responsive scale, nav/menus/backdrop, tabs, hover/press, idle motion, optional 3D egg |
| `AssetBinder` | ModuleScript | applies `AssetIds` to every `AssetKey` image |
| `AssetIds` | ModuleScript | **you edit this** – uploaded image ids |
| `AssetManifest` | ModuleScript | generated atlas rects |
| `Theme` | ModuleScript | design tokens for new UI |
| `PREVIEW_Controller` | ModuleScript | preview-only state simulation |
| `PREVIEW_SampleData` | ModuleScript | preview-only sample data (generated) |
