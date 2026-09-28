# World Composition Correction — v02 (Owner "World Production Correction Directive")

**Branch:** `claude/loving-pasteur-oayq18`.
**Pre-correction checkpoint:** `a39cc93`, recorded in `WORLD_CORRECTION_CHECKPOINT_v02.md` (commit `350d9ad`).

**Status labels:**
* Each world: BLENDER MODELED · BLENDER RENDER REVIEWED · REFERENCE COMPARED · OFFLINE EXPORTED ·
  STATICALLY TESTED (validator + cross-world check).
* **Not** Studio tested, **not** visually verified in Roblox, **Owner approval pending**.

## 1. Pipeline changes

### 1.1 Layers (directive §5, §24)

`tools/blender/sae_bpy.py` `set_layers()` / `organize()`. Every export module has a layer, and each world `.blend`
is organised as `WORLD_<id>/<id>_{PLAYABLE, BOUNDARY, BOSS_STAGE, PROPS, BACKGROUND, SKY, COLLISION, VFX_ANCHORS}`.

| Layer | Collides | Bounds policy |
|---|---|---|
| PLAYABLE (floors, route, egg pedestals) | yes | strict gameplay slot `y ∈ [-30, 228]` |
| BOUNDARY (walls, balustrades, gate piers, end walls / stands / cliffs inside the footprint) | yes | strict |
| BOSS_STAGE (dais, stairs, stage) | yes | strict |
| PROPS (lanterns, banners, statues, furniture, rubble, …) | **no** (decoration never blocks, §21) | strict |
| BACKGROUND (skylines, stands, cliffs, towers, sea, mesas, …) | **no** | may leave the slot; must stay out of every neighbour's playable corridor (`|x| < 82`, below z 120) |
| SKY (planet / moon) | no | free; may become a Roblox Sky at import |
| COLLISION (invisible proxy boxes) | yes | strict |

Every manifest module now records `layer`, `canCollide`, `boundsLocal` and per-object `objectBounds`.

### 1.2 Validator (directive §6)

`validate()` writes its results to each manifest's `validation` block. It replaces the old blanket slot check,
which forced reference scenery to be deleted. It checks:

1. Strict layers and colliders stay inside the gameplay slot.
2. BACKGROUND beyond the slot stays out of neighbour corridors.
3. The running lane (`|x| < 54`, y 0–186) has no collidable blocker. Egg pedestals are exempt as interaction objects.
4. **Walk-through scenery:** no non-collidable BACKGROUND stands in the walkable area at ground level.
5. **Floor coverage:** a 2-stud grid over the whole walkable area has no gaps, so there are no accidental falls.
6. **Exit opening, walkable:** ray casts along +y through the exit band at z 3/5/7 hit collidable surfaces only.
7. **Exit opening, visible:** ray casts at z 2/5/8 hit opaque surfaces only.

Checks 6 and 7 each require an open run of at least 16 studs.

### 1.3 Cross-world check

`tools/blender/check_adjacent_worlds.py` puts all seven worlds and Akaza's far-end parts into one frame and
checks every pair of objects from different worlds. The result is in
`art/exports/worlds/cross_world_check.json`: **0 conflicts, 10 notes**, all Akaza against MHA's entry threshold:
* **Protected river-rock supports.** They end at or below floor level (z ≤ 0.1), under MHA's threshold floor.
* **v01 invisible wall colliders.** They sit on the same line as MHA's walls, so the overlap is harmless.

## 2. Per-world result

Render sets:
* "Before" = `pre_correction_*`.
* "Correction pass" = `corr1_*` (24 spp).
* "After" = `final_*` (48–64 spp).

All are in `art/review_renders/v02/<NN_Name>/`, with the same cameras before and after.

| World | Verdict | Reference element missing before | Restored / changed, and how | Layer | Collides | Next-world transition |
|---|---|---|---|---|---|---|
| **MHA** | **COMPOSITION CORRECTED** | The purple city and elevated highway behind Shigaraki (the earlier slot clamp had removed the back skyline row and bridge) | **EndBlocks:** ruined city façades closing the far corners (\|x\| 54–82, y 204–228). **FarCity:** 18 high-rises, 85–155 studs tall, at the far corners. **Highway:** a 400-stud elevated bridge across the back at z 58 on piers. Entry gate pillars moved from x ±47 (inside the lane) to ±57.5 | EndBlocks = BOUNDARY; FarCity, Highway = BACKGROUND | EndBlocks yes; city/highway no | Two openings beside the throne (walk 37 / visible 22 studs); the highway passes high above |
| **One Piece** | **COMPOSITION CORRECTED** | The stands behind Doflamingo (replaced before by an open façade) | **Horseshoe far stands:** 4 tiers + about 330 spectators + two-storey arcade + flags, joined to the side stands. **Grand arena gate:** 68-stud arch through the stands, with the royal box moved on top. **Stage** moved forward (y 188–212). Entry piers moved from x ±49 (in the lane) to ±58 | FarStands, ArenaGate = BOUNDARY; crowd/arcade/flags/royal box = BACKGROUND | stands yes; crowd/arcade no | Through the arena gate (walk 68 / visible 68) |
| **Naruto** | **COMPOSITION CORRECTED** | The Hokage Rock behind Madara (it had been moved to the side) | The cliff spans the far end (y 214–228). The four faces sit on a natural rock bridge (z 38–78) above the red Hokage tower behind the stage, with trees on top. The stage moved forward. Houses run to y 211 on both sides again. The street boundary moved in front of the house façades (x 59) | HokageCliff (\|x\| ≤ 78), Tower = BOUNDARY; outer cliff, bridge, faces, trees = BACKGROUND | cliff/tower yes | Two passes through the mountain (walk 27.5 / visible 27.5) |
| **Dragon Ball** | **COMPOSITION CORRECTED (minor)** | The horizon mesas and waterfalls (lost to the earlier slot clamp) | 8 **horizon mesas**, 2 waterfalls and a far sea restored beyond the old slot at \|x\| ≥ 139. The planet moved fully upper-left like R02 (lateral and high, clear of all worlds). Entry gate pillars moved from x ±54 to ±58.5 | BACKGROUND / SKY | no | Open causeway beside the Frieza stage (walk 39 / visible 28) |
| **Bleach** | **COMPOSITION CORRECTED** | The monumental palace façade behind Yhwach (R10); before it was two pillars against open sky | **PalaceFacade:** gothic masses (\|x\| 38–78) with buttresses, pinnacles and lit lancets. **Outer façade:** spires to \|x\| 120. **Pointed arch** with a Wandenreich medallion. The throne platform narrowed to 20 and the banner pillars moved to ±34 into the façade line | Façade = BOUNDARY; outer/arch/medallion = BACKGROUND | façade yes | Two openings beside the throne (walk 21.5 / visible 21.5) |
| **JJK** | **NO COMPOSITION CHANGE REQUIRED** | — | Gameplay fixes only: entry gantry posts moved from x ±44 to ±57; vertical signs never reach the sidewalk (they were walk-through). Torii and Shrine made collidable | Buildings/signs/neon = BACKGROUND; torii/shrine = BOUNDARY | torii/shrine yes | Street and torii (walk 63 / visible 63) |
| **Solo Leveling** | **COMPOSITION CORRECTED** | The closed corridor end (the throne was over-opened to empty sky, §14) | **EndWalls** close the corridor on both sides of the gate (\|x\| 24.5–81), with arched panels and 4 more shadow-soldier guards. The Monarch's dais moved forward. The gate's translucent portal is non-collidable | EndWalls = BOUNDARY; guards = PROPS | walls yes | Through the Monarch's gate (walk 39 / visible 39) |

## 3. Counts (pieces = exported single-colour MeshPart modules)

| World | Before: pieces / triangles | After: pieces / triangles | Δ | Anchors | Colliders |
|---|---|---|---|---|---|
| MHA | 63 / 131,236 | **74 / 139,456** | +11 / +8,220 | 16 | 0 |
| Dragon Ball | 57 / 90,076 | **61 / 92,116** | +4 / +2,040 | 25 | 2 |
| One Piece | 74 / 125,836 | **86 / 138,712** | +12 / +12,876 | 21 | 0 |
| Naruto | 59 / 66,004 | **64 / 71,544** | +5 / +5,540 | 17 | 22 |
| Bleach | 44 / 41,356 | **53 / 43,472** | +9 / +2,116 | 26 | 0 |
| JJK | 51 / 30,760 | **51 / 30,760** | 0 | 19 | 2 |
| Solo Leveling | 41 / 73,844 | **48 / 80,128** | +7 / +6,284 | 30 | 0 |

Every module is ≤ 20,000 triangles. The largest is 13,028 (Solo Leveling shadow army).

## 4. Material strategy (directive §16)

The meshes are flat-coloured stylised primitives with no UV unwrap. The exporter splits a collection into one
piece per Blender material, so each piece maps 1:1 to a Roblox `Material` + `Color`. Reasons:

* **Exact match:** it reproduces the review renders exactly, with no texture bake.
* **Runtime control:** it gives runtime scripts direct handles on each colour group. Neon modules can be tweened
  independently: MHA crack pulse, Bleach reishi, JJK neon flicker, Solo Leveling eyes.
* **Instance count:** 48–86 pieces per world, well under the preserved Akaza world's 300 MeshParts.

**When to switch:** if instance count ever matters, merge small same-material groups, or UV-unwrap and atlas them
into a SurfaceAppearance. That is not needed at these counts.

## 5. Gate checklist (directive §39)

- [x] **Akaza fingerprint-clean**, before and after: 376 parts, 0 missing, 0 changed. SAFE_TEST `f260e511…` unchanged.
- [x] **MHA:** re-evaluated; city and highway restored.
- [x] **One Piece:** re-evaluated; far stands restored.
- [x] **Naruto:** Hokage Rock behind Madara.
- [x] **Dragon Ball, Bleach, JJK, Solo Leveling:** re-reviewed (Dragon Ball, Bleach and Solo Leveling corrected; JJK unchanged).
- [x] **Pipeline and checker:** PLAYABLE vs BACKGROUND distinction implemented; the checker no longer rejects
  harmless background.
- [x] **Gameplay safety:** collision safe, no floor gaps (falls), no lane blockers (shortcuts), no walk-through
  scenery. Validator PASS × 7.
- [x] **Transitions and identity:** next-world transitions are designed openings (≥ 21.5 studs walkable and visible
  in every world); reference identity is kept.
- [x] **Evidence:** new review renders; audits updated.

**Still open (not part of this gate):**
* The world-specific runtime motion/VFX layer: anchors are exported, but the Roblox code is not written yet (§18).
* Studio integration and visual QA.
* v01 NightDressing (moon/halo, not protected) should be dropped or relocated at integration: it hangs over MHA's
  sky, and night lighting is off for review.

## 6. Full SHA-256 of the corrected `.blend` sources

* `art/blender/worlds/02_MHA.blend`: `875ee7fd3824d4a9f53d36aa569975fbb7a58453dfb5b68379427edb7d151311`
* `art/blender/worlds/03_DragonBall.blend`: `906054e074d9e7c235848a592791cc5d178bc5b0b26e05551bd930de27aa26d7`
* `art/blender/worlds/04_OnePiece.blend`: `2a8a3b7b9a2b355984d8bde2c909e1a89f52cae925ae58dc4e3274e13d57e809`
* `art/blender/worlds/05_Naruto.blend`: `992991c091b36e68e2ce78d7988550fcb7ff14cbca70d772d3f0c90114716d03`
* `art/blender/worlds/06_Bleach.blend`: `993cfec462d46ddb28e923f2f6c39d98abe5b2f3a74d528c1d6a91b325899ebc`
* `art/blender/worlds/07_JJK.blend`: `9eb016e5f7172b9348083d77e8b6bf21d08cf21fe9b6318aa760173619fa2a8a`
* `art/blender/worlds/08_SoloLeveling.blend`: `2626078ce4db5764df34cdae47a3e5ea2dba485be1a11ded7ee66c505d0a036f`
