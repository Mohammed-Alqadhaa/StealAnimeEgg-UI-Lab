# Solo Leveling Export Recovery: Handoff (v02)

**Status:** COMPLETE OFFLINE · STATICALLY TESTED · STUDIO VALIDATION PENDING.

**Machine-readable report:** `art/integration/world-import-v02/08_SoloLeveling/collision_recovery_report.json`.

## A. Root cause

`tools/blender/sae_bpy.py` exported a single-material collection under its bare module name.

The Solo Leveling knight builder splits one module into three collections: `EXPORT_<Mod>__Metal`,
`EXPORT_<Mod>__Fabric` and `EXPORT_<Mod>__Neon`. The Fabric collection (capes) and the Neon collection (glowing
eyes) of the same module therefore both wrote `<Mod>.fbx`. The Neon export ran later and overwrote the capes.

The manifest listed 48 pieces, but only 45 FBX files existed.

## B. The three collisions (from the committed manifest and a re-import of the surviving files)

| Colliding file | Overwritten group: Fabric, `SL_ShadowCape` | Surviving group: Neon, `SL_ShadowEyes` |
|---|---|---|
| `art/exports/worlds/08_SoloLeveling/ShadowArmy.fbx` | 13,028 tris | 480 tris |
| `art/exports/worlds/08_SoloLeveling/Colossi.fbx` | 1,308 tris | 48 tris |
| `art/exports/worlds/08_SoloLeveling/EndGuards.fbx` | 2,612 tris | 96 tris |

## C. What was lost

The cape geometry of:
* the 20 alcove shadow soldiers (`ShadowArmy`);
* the 2 colossal knights (`Colossi`);
* the 4 end-wall guards (`EndGuards`).

In total that is **16,948 triangles**. The eyes survived.

## D. What was recovered

All six groups now export as uniquely named pieces:
* `ShadowArmy_ShadowCape` and `ShadowArmy_ShadowEyes`
* `Colossi_ShadowCape` and `Colossi_ShadowEyes`
* `EndGuards_ShadowCape` and `EndGuards_ShadowEyes`

**Naming fix:** `sae_bpy.module_groups()`. A piece keeps its bare module name only if the module has one
collection and one material; otherwise it gets `<Module>_<MaterialSuffix>`. Uniqueness is asserted. For the other
six worlds the piece names were verified unchanged against their committed manifests.

## E. Corrected output paths

All outputs are new; the historical exports in `art/exports/worlds/08_SoloLeveling/` are left as they were.

| Output | Path |
|---|---|
| 48 per-piece FBXs + `manifest.json` (validation PASS) | `art/integration/world-import-v02/08_SoloLeveling/pieces/` |
| Combined import scene | `art/integration/world-import-v02/import-scenes/SoloLeveling_Combined_Final.fbx` (1,235,580 B, SHA-256 `eef9dc819ba05853048a3c8323c234606341dd142b9b923823267ccd45458121`) |
| Packaging report (per-piece Roblox position, size, colour, material, layer, collision, triangles) | `…/import-scenes/SoloLeveling_Combined_Final.report.json` |
| Source-object mapping (piece → `.blend` collections, materials, 1,492 source objects) | `…/08_SoloLeveling/source_object_map.json` |
| Collision recovery report | `…/08_SoloLeveling/collision_recovery_report.json` |
| Tool | `tools/blender/package_world_scene.py` (modes `names`, `map`, `package`) |

## F. Combined-scene validation (offline)

The combined FBX was re-imported into an empty Blender scene:
* **48 / 48** objects, names unique, no extras;
* **80,128** triangles, matching the source;
* maximum centre/size deviation **0.000063 studs** against the packaging report;
* **0.01 studs** against the committed manifest, which is its 2-decimal rounding. The three recovered capes were
  matched by colour.

## G. Canonical `.blend` unchanged

* **File:** `art/blender/worlds/08_SoloLeveling.blend`.
* **SHA-256:** `2626078ce4db5764df34cdae47a3e5ea2dba485be1a11ded7ee66c505d0a036f`, the version committed in `3d2fe1e`.
* **Proof:** the SHA-256 is identical before and after every packaging run, `git diff` is empty, and the packager
  opens the `.blend` read-only (it never saves it).
* **Other worlds:** all 7 canonical `.blend` files are verified byte-identical.

## H. Studio import instruction

1. Import `SoloLeveling_Combined_Final.fbx` with the Roblox 3D Importer at **scale 0.01**, the scale already proven
   on MHA.
2. Import it into **STAGING**, away from the active route.
3. Do **not** import the 48 single-piece FBXs one by one.

## I. What Astra must verify in Studio

Use `tools/studio/StagingValidateRestore.lua` with `tools/studio/world_data/SoloLeveling.lua`.

1. Run `T.run("SoloLeveling", <model>)` and check it reports:
   * **48** pieces, with no missing, duplicate or unexpected pieces;
   * dimensions, positions and rotations (identity) match;
   * no scale warning: not ~100× (giant) and not ~0.01× (collapsed).
2. Run `T.run("SoloLeveling", <model>, { restore = true })` to restore Materials and Colors. The report must then
   show APPEARANCE OK.
3. Check visually:
   * the capes are present on the 20 soldiers, 2 colossi and 4 guards (dark `#0d0f16` Fabric);
   * the blue Neon eyes are present (`#39b5ff`);
   * the full composition is intact: symmetric corridor, alcoves, closed end walls, the Monarch's gate and throne.

## J. Status

**COMPLETE OFFLINE · STATICALLY TESTED · STUDIO VALIDATION PENDING**
