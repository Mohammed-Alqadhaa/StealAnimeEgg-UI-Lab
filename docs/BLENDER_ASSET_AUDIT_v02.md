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
| `.blend` sources | `art/blender/worlds/NN_<Name>.blend` (Git LFS) |
| Exports | `art/exports/worlds/NN_<Name>/<Module>.fbx` + `manifest.json` |
| Review renders | `art/review_renders/v02/NN_<Name>/` |

**Conventions:**
* 1 Blender unit = 1 stud. World-local origin is the world entrance, on the lane centre line.
* Blender +Y runs down the lane, so Roblox `(X, Y, Z) = (-x, z, Layout.worldZ0(i) + y)`. The FBX export
  (`axis_forward="Z", axis_up="Y"`) produces exactly that mapping, and the manifest records each module's Roblox
  position, size, triangles and material.
* Every export module is one collection named `EXPORT_<Module>__<RobloxMaterial>`. It is joined into a single mesh
  and becomes one MeshPart with that Roblox Material. Colour comes from the Blender material's `roblox_color`.
* `VFX_*` empties are **runtime anchors only**. Particles, lights, beams and tweens are authored in Roblox, not baked.
* Layout contract: lane `|x| < 54` stays clear and flat; walls at `|x| ≈ 75–77`; length 230; egg nests at the
  `Layout.EGG_OFFSETS`; boss stage at 206; entry and exit gates are open, so the next world is visible.
* **Collision (to apply at import):** the floor, plaza, dais and walls collide. Everything else is decoration
  (`CanCollide=false`, collision group `Decor`), per the no-blocking-decoration rule.

## 02_MHA — Shigaraki (reference **R01**)

| Field | Value |
|---|---|
| Source | `art/blender/worlds/02_MHA.blend` (13.7 MB; SHA-256 `5fce24dd95950991d166e484253996ce991be12443cf94d2423937994ce1a23b`) |
| Script | `tools/blender/worlds/w02_mha.py` (deterministic, `random.Random(202)`) |
| Exports | `art/exports/worlds/02_MHA/`: **47 FBX modules, 137,784 triangles total, 0 over the limit**. `manifest.json` also holds 14 VFX anchors |
| Renders | `pass1_*` … `pass4_*` (iterations, 24 spp), `final_gameplay.png`, `final_throne.png`, `final_overview.png` (64 spp) |
| Target Roblox path | `Workspace.SAE_World.Worlds.MHA.Environment.<Module>` (MeshParts), `…MHA.V02_VFX` (anchors) |
| Status | **BLENDER MODELED · BLENDER RENDER VERIFIED · EXPORTED · OWNER APPROVAL PENDING** |

**Largest modules (triangles):**

| Module | Triangles |
|---|---|
| ChainsE / ChainsW | 11,900 each (split per side) |
| Rubble | 10,800 |
| ThroneChains | 10,400 |
| WallsE / WallsW | 9,936 / 10,152 (split per side) |
| Floor1 / Floor2 / Floor3 | 7,456 / 7,412 / 8,588 |
| GateChains | 8,400 |

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
