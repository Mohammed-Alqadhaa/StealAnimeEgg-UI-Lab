# Akaza (Demon Slayer) World: Preservation Audit (v02)

**Owner directive:** AUDIT AKAZA. PRESERVE AKAZA. DO NOT REBUILD AKAZA DESTRUCTIVELY.
The missing `.blend` source is **not** permission to rebuild. The existing geometry is the baseline.

**Status:** **STRUCTURALLY VERIFIED** (offline, Lune). Nothing in the Akaza world has been modified by
this audit. Visual verification still requires Studio.

## 1. Two preserved versions (both backed up)

| Version | Where it lives | Backup (this repo) | SHA-256 |
|---|---|---|---|
| **A. Original Last CP Akaza** (before Claude) | `checkpoints/StealAnAnimeEgg_PreClaudeTakeover_20260928.rbxlx` → `Workspace.FarmHubVisualPrototype.SixZoneRoute.Zone1` (read-only file) | `checkpoints/akaza_preservation/Akaza_Zone1_original_LastCP.rbxmx` (652 instances, round-trip verified) | `9316485a0151b6c49dae0139ac0f2354155a5073c76efaa74e796b3d05728baa` |
| **B. Current Akaza in SAFE_TEST** (= v01 state) | `checkpoints/StealAnAnimeEgg_v01_SAFE_TEST.rbxlx` → `Workspace.SAE_World.Worlds.DemonSlayer` | `checkpoints/akaza_preservation/Akaza_DemonSlayerWorld_from_SAFE_TEST.rbxmx` (796 instances, round-trip verified) | `88a66afebf641796f6631a25f49862972e626c3240db26796e79af9ae8fc2797` |

**Fingerprint:** `checkpoints/akaza_preservation/Akaza_fingerprint_SAFE_TEST.json` (SHA-256 `9e1eae18…`).

* **Coverage:** 376 parts, i.e. all 372 Environment BaseParts plus the 4 approved egg Visuals.
* **Recorded per part:** class, size, CFrame, material, colour, transparency, mesh/texture ids and
  SurfaceAppearance map.

**Check tool:** `lune run game/tests/akaza_fingerprint.luau check <place> <manifest>`.

* It **fails** if any recorded part is missing or changed.
* New parts **added** under the world (VFX anchors, colliders) are reported but allowed.
* SAFE_TEST passes: 0 missing, 0 changed. **v01 passes too**, so the Owner has not modified Akaza since v01.
* A tampered manifest is correctly rejected (exit 1).

## 2. Honest provenance: version B is not pristine

Version B already contains the **v01 controlled width pass** (Master Prompt v1 §27, width ×1.5) and a
few v01 additions. None of them replaced or regenerated Owner geometry:

| v01 change | Nature | Details |
|---|---|---|
| 292 Environment parts translated outward | **move only** (no reshaping) | parts with \|x\| > 20 moved ±25 studs (walls, masks, bamboo, lanterns, river, waterfalls, rocks, railings, torii pillars) |
| 14 floor tiles cloned 25 studs outward | **additive** (clones named `*_W15`) | 286 → 300 MeshParts |
| `ContinuousWalkSurface` 72 → 122 wide | resize of an invisible walk plane | |
| `ToriiExtendedCrossbeam` 70 → 120 | resize | |
| `EntranceReturnWall/Trim` 34 wide at ±59 | resize/move | meets the hub exit |
| `NightDressing` model | **added** | Moon + halo, WorldTitle arch, 2 invisible `WallCollider`s |
| `Eggs` folder | moved in | 4 approved eggs **unchanged** (moved from `OfficialEggInspection.RawAssets`) + provisional Tanjiro pipeline egg |
| `Boss` | Akaza boss rig from Last CP Zone1, sanitized | |

Version A remains available if the Owner prefers the un-widened original for any element.

## 3. Current hierarchy (version B), exact

`Workspace.SAE_World.Worlds.DemonSlayer` (Model, 795 descendants).

**Attributes:**

| Attribute | Value | Note |
|---|---|---|
| `WorldIndex` | 1 | |
| `WorldName` | Demon Slayer | |
| `LightingProfile` | AkazaNight | disabled for review per §32, client-side only, no geometry change |
| `ZoneMinZ` / `ZoneMaxZ` | 200 / 435 | |
| `ZoneHalfWidth` | 76 | |
| `WallClearWidth` | 150 | |
| `WalkWidth` | 122 | |

**Children:**

| Child | Class | Descendants | Bounding box min → size (studs) | Contents |
|---|---|---|---|---|
| `Environment` | Model | 612 | (−80.3, −7.3, 199.4) → **160.9 × 46.3 × 248.6** | 300 MeshParts, 72 Parts, 155 SurfaceAppearance, 31 PointLights, 8 Beams, 8 ParticleEmitters, 2 Textures, 16 Attachments |
| `Eggs` | Folder | 100 | (−15.9, 1.0, 351.9) → 31.9 × 7.3 × 19.0 | 5 spawns (4 approved + Tanjiro) |
| `NightDressing` | Model | 10 | (−89, 0, 200) → 169 × 179 × 366 | Moon, halo, title arch, colliders (v01) |
| `Boss` | Model | 69 | (−7.3, 0.6, 366.0) → 14.6 × 18.8 × 4.4 | Akaza R6 rig (Humanoid, 6 Motor6D, 4 accessories) |

**Environment folders** (82 direct children):

| Folder | Content |
|---|---|
| `Arena` | 9 MeshParts: central arena, **compass inlay**; BlenderMaterial "Compass luminous inlay" ×14 across the world |
| `WallModules` | 84 descendants |
| `Floor` | 84 descendants, incl. the 14 `_W15` v01 clones |
| `Bamboo` | 52 |
| `Lanterns` | 60 |
| `Rocks` | 22 `RiverRockSupport` |
| `Railings` | 24 |
| `ToriiGate` | torii + `ToriiCenterTablet`, `ToriiExtendedCrossbeam` |
| `EggPedestals` | 8 |
| `River` | 5 |
| `Riverbed` | 2 |
| `Waterfalls` | 11 |
| `OwnerMaskPack` | 4 wall masks |
| `Vegetation` | 1 |

Standalone parts:
* 18 × `LanternLightAnchor` and 18 × `LanternRoofModule`
* 12 × `MoonFill`
* `ArenaLightAnchor`
* `ContinuousWalkSurface` (122 × 1 × 230 at z = 320)
* 2 × `RiverFlowLayer` (10.8 × 0 × 230 at x = ±67.4), each holding an **`AnimatedRiverFlow` Texture**
* 2 × `RiverSafetyShelf` (15.5 × 2 × 230 at x = ±68.2)
* 8 × `WaterfallMotion`, each holding a `FlowingWaterfall` Beam
* 2 × `SolidSideBoundary`
* 2 × `EntranceReturnWall` and 2 × `EntranceReturnTrim`

**BlenderMaterial attribute values** (298 parts): Wet blue slate 71, Riverbank basalt 66,
Lacquered oxblood cedar 42, Charcoal metal 30, Bamboo jade 18, Compass luminous inlay 14,
Bamboo nodes 13, Water foam 13, Aged brass 12, Warm lantern paper 12, Animated flowing water 3,
Bamboo leaves 3, Soft pink petals 1.

**Existing motion hooks** (already authored, reused by the v01 client `FxClient`):
* `AnimatedRiverFlow` textures: scroll `OffsetStudsV`.
* `FlowingWaterfall` beams, spray emitters and lantern lights: enabled in-zone.
* Compass inlay parts: transparency pulse.

## 4. Width measurement

Original clear width **100** studs → current wall-clear **150** (`WallClearWidth`), walk surface 122,
side walls at about ±76.

**The ×1.5 width requirement is already met.** No further width change is planned unless the Owner
judges it visually wrong in Studio.

## 5. Allowed controlled improvements: non-destructive method for each

| Owner-allowed improvement | Planned method (non-destructive) |
|---|---|
| Width/scale correction | Already ×1.5 (§4). Only if the Owner asks after Studio review, and only as translation (never regeneration) |
| Clear daytime/review lighting | Client lighting profile only (`WorldClient`); **no geometry change** |
| Flowing river runtime motion | Existing `AnimatedRiverFlow` textures + `RiverFlowLayer`; add scroll speed/foam emitters as **new children** |
| Animated/pulsing compass needle | Tween existing inlay transparency/colour + **added** Light/emitters; no mesh edits |
| Environmental VFX (mist, petals, energy) | **New** attachments/emitters parented under a new `V02_VFX` folder |
| Bamboo motion | Only if needed: gentle client-side sway of bamboo CFrame from the stored rest pose (restored exactly); otherwise leaves/petal particles |
| Collision cleanup | Toggle `CanCollide` via collision groups; add invisible simple colliders; **no geometry change** |
| Non-blocking decoration | Collision group "Decor" (no player collision) |
| Boss presentation | Boss rig animation only |
| Clear transition to next world | Additive threshold framing at the far end (z ≈ 435+); existing walls untouched |

**Rules for any future change:**
1. Run `akaza_fingerprint.luau check` before and after.
2. Any `CHANGED` or `MISSING` part must be explicitly Owner-approved and listed in this document.
3. `ADDED` parts must live in clearly named containers (`V02_VFX`, `V02_Colliders`, …) so they can be
   removed without touching Owner geometry.

## 6. Clarification recorded

The earlier baseline-audit statement "8 procedural worlds" described the **old v01/SAFE_TEST
contents** (9 worlds including Berserk). The **final target is 8 active worlds**:

1. Demon Slayer (this preserved world)
2. MHA
3. Dragon Ball
4. One Piece
5. Naruto
6. Bleach
7. JJK
8. Solo Leveling

Berserk is removed from active production. Only the **7 non-Akaza active worlds** get new Blender
builds. Akaza is preserved and improved additively.
