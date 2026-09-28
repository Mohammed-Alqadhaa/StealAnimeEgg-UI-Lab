# Blender Asset Audit — v02

**Toolchain:** Blender **4.0.2** (Ubuntu `4.0.2+dfsg-1ubuntu8`), headless `bpy`, Cycles CPU (no EGL in the container,
so no EEVEE; no OIDN, so denoising is off and the review renders show some grain). Details are in `V02_BASELINE_AUDIT.md` §2.

**Status labels in this file:**

| Label | Meaning |
|---|---|
| BLENDER MODELED | A real `.blend` source was authored with bpy and saved in the repo |
| BLENDER RENDER VERIFIED | Cycles review renders were produced from that `.blend` and compared against the authoritative reference, with the fix iterations listed |
| EXPORTED | FBX modules + `manifest.json` written, every module ≤ 20,000 triangles |

None of the assets below is **OFFLINE INTEGRATED**, **STUDIO TESTED** or **VISUALLY VERIFIED** in Roblox. MeshParts
need uploaded mesh assets (Studio 3D Importer or Open Cloud), which cannot be done from this cloud container.
All visual choices are **OWNER APPROVAL PENDING**.

## Pipeline (shared by every world)

| Item | Location |
|---|---|
| Helper library | `tools/blender/sae_bpy.py`: materials carry `roblox_material` / `roblox_color`; kit primitives, flagstone floor, chain, hand, torn banner; Cycles setup; FBX module export + manifest |
| World scripts | `tools/blender/worlds/wNN_<name>.py` |
| Run | `blender -b --factory-startup --python tools/blender/worlds/w02_mha.py -- <repo> [render] [export]` (`SAE_SAMPLES`, `SAE_TAG` env vars) |
| `.blend` sources | `art/blender/worlds/NN_<Name>.blend` (regular git: LFS upload to `lfs.github.com` is blocked by the environment proxy, HTTP 403; files are < 100 MB) |
| Exports | `art/exports/worlds/NN_<Name>/<Module>.fbx` + `manifest.json` |
| Review renders | `art/review_renders/v02/NN_<Name>/` |

**Conventions:**
* 1 Blender unit = 1 stud. World-local origin is the world entrance, on the lane centre line.
* Blender +Y runs down the lane, so Roblox `(X, Y, Z) = (-x, z, Layout.worldZ0(i) + y)`. The FBX export
  (`axis_forward="Z", axis_up="Y"`) produces exactly that mapping, and the manifest records each module's Roblox
  position, size, triangles and material.
* Every export module is one collection named `EXPORT_<Module>__<RobloxMaterial>`, joined into a single mesh.
* **One colour per MeshPart:** a Roblox MeshPart has a single `Color`. The exporter therefore splits a collection that
  mixes Blender materials into `<Module>_<Material>` sub-modules. The manifest gives each module one
  `color` and `transparency`.
* `VFX_*` empties are **runtime anchors only**. Particles, lights, beams and tweens are authored in Roblox, not baked.
* Layout contract: lane `|x| < 54` stays clear and flat; walls at `|x| ≈ 75–77`; length 230; egg nests at the
  `Layout.EGG_OFFSETS`; boss stage at 206.
* **World slot `y ∈ [-30, 228]`** (`sae_bpy.WORLD_SLOT_Y`). `build.luau` gives each world
  `ZoneMinZ = z0 − 30`, so the 30-stud entry threshold belongs to the world, and the next world's threshold
  starts at 230.
  * All geometry must stay inside the slot, or adjacent worlds intersect. The exporter flags `outsideSlot` per
    module. Only `Sky*` modules are exempt; they become Sky/billboard objects at import.
  * Each world has an **entry** gate only. The next world's entry frames the exit, and the view past the boss
    is the next world.
  * Found and fixed during the One Piece pass: MHA had a back skyline row and a bridge up to y ≈ 365; Dragon Ball
    had a back sea and mesas up to y ≈ 560; both had exit gates at y = 232. All are now clamped or removed.
* `COLLIDERS` collection: invisible boxes are written to manifest `colliders` and are never rendered.
* **Collision (to apply at import):** the floor, plaza, dais and walls collide. Everything else is decoration
  (`CanCollide=false`, collision group `Decor`), per the no-blocking-decoration rule.

## 02_MHA — Shigaraki (reference **R01**)

| Field | Value |
|---|---|
| Source | `art/blender/worlds/02_MHA.blend` (12.7 MB; SHA-256 `41d904307200b97dd0e6ca5e7a3fb9565e9aee7e8a5f784289a32cc25464d689`) |
| Script | `tools/blender/worlds/w02_mha.py` (deterministic, `random.Random(202)`) |
| Exports | `art/exports/worlds/02_MHA/`: **63 FBX modules (single colour each), 131,236 triangles total, 0 over the limit, 0 outside the slot**. `manifest.json` also holds 14 VFX anchors |
| Renders | `pass1_*` … `pass4_*` (iterations, 24 spp), `final_gameplay.png`, `final_throne.png`, `final_overview.png` (64 spp) |
| Target Roblox path | `Workspace.SAE_World.Worlds.MHA.Environment.<Module>` (MeshParts), `…MHA.V02_VFX` (anchors) |
| Status | **BLENDER MODELED · BLENDER RENDER VERIFIED · EXPORTED · OWNER APPROVAL PENDING** |

**Largest modules (triangles):**

| Module | Triangles |
|---|---|
| ChainsE / ChainsW | 11,900 each (split per side) |
| ThroneChains | 10,400 |
| Rubble_StoneDark | 9,720 |
| WallsW_Stone / WallsE_Stone | 8,748 / 8,316 |
| Floor1_Stone | 7,368 |

Every other module is under 4,500 triangles.

**Roblox materials used:** Slate, Neon, Glass, Metal, Fabric, SmoothPlastic, WoodPlanks, Wood.

### R01 elements reproduced

* **Floor:** irregular bevelled flagstones with purple emissive cracks. The cracks widen and concentrate around
  the plaza, the egg nests and the throne.
* **Plaza and eggs:** a circular plaza with an inlaid white hand emblem and ring lines. Five spiky obsidian egg
  nests with neon glow rings.
* **Throne:** a three-step dais under a fan of 23 tilted jagged slabs. Sixteen white "decay" hands on forearms
  reach out from behind it. A red cloak covers the back and seat, with side drapes.
* **Banners:** two tall torn red banners with white hands on posts behind the throne, plus smaller banners on the
  throne-side pillars.
* **Lane edge:** stone lantern posts with warm lanterns, linked by hanging chains. Heavy chains run from the
  pillars to the throne.
* **Left side:** the villain bar, with counter, stools, glowing bottle shelves and purple neon strips.
* **Right side:** the lounge, with red sofas, low tables and candles.
* **Walls:** ruined block walls with glowing cracks, and framed neon-hand posters.
* **Backdrop:** a purple city skyline in 3 depth rows plus a back row, with dim lit windows and an elevated truss
  bridge.

### Iterations (compare → fix)

| Pass | Findings vs R01 | Fix |
|---|---|---|
| 1 | Crack glow was uniform and grid-like; slabs too small and regular; skyline too close and bright; nests too small; the cloak was a flat box; no warm lantern light | Dark crack bed plus concentrated glow patches; 8-stud bevelled slabs with gap variance; skyline moved out to x ≥ 112 with a far-row material; nest radius 3.7; draped cloak; lantern lights |
| 2 | Glow still invisible at gameplay eye height; throne too small; no large banners; windows too bright; lighting flat | Glow raised into the slab volume and slabs pulled apart near glow sources; throne scaled ×1.4; tall banner posts and two big banners; windows dimmed to purple; moonlight lowered, throne and plaza lights added |
| 3 | Throne hands floated in the air; banner hands were edge-on | Forearms connect each hand to the ground behind the fan; banner hands face the lane |
| 4 / final | Composition matches R01 (throne centre-back, bar left, lounge right, glowing cracks, flanking banners, skyline) | Final 64-spp renders + export |

### Known deviations (honest)

* The style is stylised and low-poly (Roblox-friendly). There are no painted textures; colour comes from the
  Roblox material plus colour.
* The glow is concentrated in zones. R01 shows glow in almost every crack, which would be very bright in-game.
* The throne forearms are straight tapered cylinders. The skyline is simple boxes.
* Review lights (`LanternLight*`, `NestLight*`, `ThroneLight`, `PlazaGlow`) exist only in the render; in game they
  are runtime `PointLight`s placed at the `VFX_*` anchors.
* The render lighting is a purple dusk that matches R01. The in-game review lighting will be daytime-readable (§32).

## 03_DragonBall — Planet Namek / Frieza (reference **R02** Namek panel)

| Field | Value |
|---|---|
| Source | `art/blender/worlds/03_DragonBall.blend` (9.0 MB; SHA-256 `afc99b079f3634e521b5fbeefae7fbec94a37d8b08a7f0e3ab9c2da90839fac1`) |
| Script | `tools/blender/worlds/w03_dragonball.py` (`random.Random(303)`) |
| Exports | `art/exports/worlds/03_DragonBall/`: **57 FBX modules (single colour each), 90,076 triangles, 0 over the limit, 0 outside the slot** (largest 9,956). Manifest: 24 VFX anchors, **2 boundary colliders**. The sky planet/moon are `Sky*` modules (exempt) |
| Renders | `pass1_*` … `pass3_*` (20 spp), `final_gameplay.png`, `final_boss.png`, `final_overview.png` (48 spp) |
| Target Roblox path | `Workspace.SAE_World.Worlds.DragonBall.Environment.<Module>`, `…DragonBall.V02_VFX`, `…DragonBall.V02_Colliders` |
| Status | **BLENDER MODELED · BLENDER RENDER VERIFIED · EXPORTED · OWNER APPROVAL PENDING** |

**Pipeline additions:**
* `S.collider()`: invisible boxes go to manifest `colliders` and are not rendered.
* `transparency` on materials: Sea 0.25, Waterfalls 0.3, Portal 0.55 and the pod glass are written to the manifest.
* `setup_render(sky_light=…)`: sky colour for the camera, separate neutral ambient, like Roblox Sky vs Ambient.

**Gameplay layout:**
* A 112-stud grey stone causeway (lane `|x| < 54` clear).
* A balustrade at `|x| = 56.8`, with **invisible colliders on it**, so the sea is never walkable and nobody falls.
* Open gates at both ends.

**R02 elements reproduced:**
* **Sky:** green sky with a pale-green banded planet and a small moon.
* **Causeway:** straight stone causeway to Frieza. Balustrade with stone lantern posts and warm lanterns.
* **Sea and islands:** turquoise sea on both sides. Grass islands with blue-ball Ajisa trees (also rising beside
  the causeway) and white Namekian domes with round windows and top tubes.
* **Horizon:** tan/ochre mesas, with waterfalls into the sea.
* **Frieza stage:** a dark purple stage with a glowing arch and portal pane.

**Extra identity (not in R02, kept outside the lane):**
* Seven orange Dragon Balls (1–7 stars) on plinths.
* Frieza's hover pod.
* Two crashed Saiyan pods.
* A 4-star Dragon Ball emblem in the plaza.

**Iterations:**

| Pass | Findings | Fix |
|---|---|---|
| 1 | Path tinted green; planet a flat white disc; portal pane opaque; mesas uniform "wedding cakes"; faceted small canopies | Neutral cool-grey path; banded pale-green planet + moon; portal transparency 0.55; flat-topped irregular mesas; larger canopies with 4 lobes |
| 2 | Green sky light still tinted every surface | `sky_light` ambient separation (renders only) |
| 3 / final | Matches the R02 composition | Final render + export; canopy split to meet the triangle limit |

**Known deviations:**
* Stylised low-poly. The canopies are faceted spheres, and the sea is a flat transparent plane (runtime scroll/sparkle
  at `VFX_SeaShimmer*`).
* The sky planet is a far mesh. In Roblox it may instead become a Sky/billboard (recorded in the script).
* The "stepped" mesa silhouette is a deliberate stylisation.

## 04_OnePiece — Dressrosa Corrida Colosseum / Doflamingo (reference **R02** Dressrosa panel)

| Field | Value |
|---|---|
| Source | `art/blender/worlds/04_OnePiece.blend` (22.9 MB; SHA-256 `c69d38f2551f3147a384a8eb4873764b00aeaae27edac84c8a6d795688ee0fb2`) |
| Script | `tools/blender/worlds/w04_onepiece.py` (`random.Random(404)`) |
| Exports | `art/exports/worlds/04_OnePiece/`: **74 FBX modules (single colour each), 125,836 triangles, 0 over the limit (largest 9,396), 0 outside the slot**. 20 VFX anchors |
| Renders | `pass1_*`, `pass2_*` (20 spp), `final_gameplay.png`, `final_boss.png`, `final_overview.png` (48 spp) |
| Target Roblox path | `Workspace.SAE_World.Worlds.OnePiece.Environment.<Module>`, `…OnePiece.V02_VFX` |
| Status | **BLENDER MODELED · BLENDER RENDER VERIFIED · EXPORTED · OWNER APPROVAL PENDING** |

**Gameplay layout:**
* Sandstone arena floor with a pale central path (|x| < 12).
* Lane `|x| < 54` clear.
* The arena wall at `|x| ≈ 76.5` collides.
* A great open entry arch spans the whole lane.

**R02 elements reproduced:**
* **Colosseum:** 9-tier stands on both sides, with about 1,900 stylised spectators in 5 shirt colours
  (auto-split by colour). A two-storey round-arch arcade crowns the stands, with red/pink pennants on top.
* **Arena floor:** a pale stone path to the boss, lined by iron lamp posts with warm lamps.
* **Banners:** red banners with a white Jolly Roger (skull + crossbones) on the arena wall.
* **Doflamingo stage:** a raised stage with a red and gold throne in front of a large pink feather fan (his coat).

**Extra identity:**
* A subtle "Birdcage" of glowing strings behind the stage (never across the lane).
* An open two-storey arcade façade behind the stage (next world visible through the arches).
* A royal box with a pink canopy on the west stand.
* Dressrosa flower planters.

**Iterations:**

| Pass | Findings | Fix |
|---|---|---|
| 1 | Birdcage strings formed a glaring white pyramid; boss had no backdrop; stands behind the boss would leave the world slot | Strings thinner, dimmer and partly transparent; open arcade façade behind the stage; far stands removed and the royal box moved to the side stand |
| 2 / final | Matches the R02 colosseum composition | Final render + export |

**Known deviations:**
* R02 shows stands behind Doflamingo. They cannot fit inside the world slot, so the façade takes their place.
* Spectators are static blocks. The `VFX_CrowdCheer±` anchors drive a client bob/cheer.
* The feather fan is stylised as petals.

## 05_Naruto — Konoha / Madara (reference **R02** Konoha panel)

| Field | Value |
|---|---|
| Source | `art/blender/worlds/05_Naruto.blend` (9.0 MB; SHA-256 `e66b77e25ea830aaa7e7222fa8fa0bd50225c3d176c8d4eb209e955321ab9f3d`) |
| Script | `tools/blender/worlds/w05_naruto.py` (`random.Random(505)`) |
| Exports | `art/exports/worlds/05_Naruto/`: **59 FBX modules (single colour each), 66,004 triangles, 0 over the limit (largest 7,920), 0 outside the slot**. 17 VFX anchors, **19 colliders** (house blocks, street boundaries, gate walls) |
| Renders | `pass1_*`, `pass2_*` (20 spp), `final_gameplay.png`, `final_boss.png`, `final_overview.png` (48 spp) |
| Target Roblox path | `Workspace.SAE_World.Worlds.Naruto.Environment.<Module>`, `…Naruto.V02_VFX`, `…Naruto.V02_Colliders` |
| Status | **BLENDER MODELED · BLENDER RENDER VERIFIED · EXPORTED · OWNER APPROVAL PENDING** |

**Gameplay layout:**
* A 52-stud cobblestone street on packed-earth ground. Lane `|x| < 54` clear.
* House fronts at `|x| ≥ 60`, with invisible colliders on each house and along the street edge.
* The Konoha main gate at the entry spans the whole lane; its open doors rest outside the lane.

**R02 elements reproduced:**
* **Houses:** cream-walled timber-framed houses (1–2 storeys) with red, orange and green gable roofs. Red paper
  lanterns hang at the eaves.
* **Street:** wooden lantern posts with warm lanterns. Red banners with the white Leaf spiral.
* **Hokage Rock:** a craggy cliff with 4 carved faces (two with forehead plates) and trees on top. It sits at the
  far end on the Roblox −x side, inside the slot, facing down the street.
* **Madara stage:** a stone stage under a timber crest frame with a large red and white Uchiha fan. A red round
  tower (Hokage residence silhouette) stands to the side.

**Extra identity:**
* An open Konoha main gate with a green roof and a Leaf mark.
* An Ichiraku-style ramen stand with white noren.
* Round green trees behind the houses.

**Iterations:**

| Pass | Findings | Fix |
|---|---|---|
| 1 | Gable roofs rendered inverted (slope sign bug); Hokage Rock a flat striped box; stone street narrow against wide dirt; tower roof 1 stud outside the slot | Roof slope signs fixed; craggy layered cliff with boulders and top trees; street widened to 52 studs; tower moved inside the slot |
| 2 | Cliff outline vertex order zig-zagged (renders, but not a clean mesh); houses started in the entry threshold in front of the gate | Proper outline order; houses start inside the gate (y ≥ 8) |
| final | Matches the R02 Konoha composition | Final render + export |

**Known deviations:**
* R02 places the Hokage Rock behind Madara on the horizon. The world slot forbids that, so it is placed at the
  far-end side.
* The faces are stylised (no likeness of specific Hokage).
* The Leaf symbol is a simplified spiral + tip.

## 06_Bleach — Yhwach's palace (reference **R10**, authoritative for the Bleach map)

| Field | Value |
|---|---|
| Source | `art/blender/worlds/06_Bleach.blend` (5.7 MB; SHA-256 `27108f6b05fff6f44bdcd26b96d5eff7738d389b0b901561e6ab48de594909f0`) |
| Script | `tools/blender/worlds/w06_bleach.py` (`random.Random(606)`) |
| Exports | `art/exports/worlds/06_Bleach/`: **44 FBX modules (single colour each), 41,356 triangles, 0 over the limit (largest 5,248), 0 outside the slot**. 25 VFX anchors |
| Renders | `pass1_*` (20 spp), `final_gameplay.png`, `final_boss.png`, `final_overview.png` (48 spp) |
| Target Roblox path | `Workspace.SAE_World.Worlds.Bleach.Environment.<Module>`, `…Bleach.V02_VFX` |
| Status | **BLENDER MODELED · BLENDER RENDER VERIFIED · EXPORTED · OWNER APPROVAL PENDING** |

**Gameplay layout:**
* Polished dark marble floor. Lane `|x| < 54` clear.
* Palace walls at `|x| ≈ 77` collide.
* A great open entry arch spans the lane, between two gate towers.

**R10 elements reproduced:**
* **Corridor:** a monumental grey/white corridor with a reflective dark floor and white inlaid guide lines running
  to the throne.
* **Banners:** towering banner pillars with long white banners bearing the black Wandenreich cross.
* **Braziers:** stone brazier pedestals with burning fires along the path.
* **Skyline:** gothic towers and spires with pale-blue lit windows, and buttressed palace walls.
* **Throne:** a wide 8-step staircase up to Yhwach's dark throne (glowing cross emblem, spired back), flanked by
  two giant banner pillars.
* **Egg pedestals:** dark, with blue reishi glow.

**Iterations:**

| Pass | Findings | Fix |
|---|---|---|
| 1 | Flying buttresses read as stray floating beams; flames and banner crosses smaller than R10 | Buttresses removed; flames enlarged; banner crosses scaled ×1.3 |
| final | Matches the R10 composition | Final render + export |

**Known deviations:**
* R10's stormy clouds and moon are a Roblox Sky choice, not geometry.
* The Wandenreich cross is a simplified 4-point star with a longer lower arm.
* The review render shows some Cycles firefly noise (no denoiser in this Blender build).
