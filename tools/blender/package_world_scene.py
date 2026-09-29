"""
Export-only world packager for Roblox Studio integration (never modifies or saves the canonical .blend).

  blender -b --factory-startup --python tools/blender/package_world_scene.py -- <repo> <NN_Name> <WorldId> <out_root> [names|package]

  names    compare the piece names the exporter would produce now with the committed manifest (no files written)
  package  write corrected per-piece FBXs + manifest to <out_root>/<NN_Name>/pieces/ and ONE combined import scene
           <out_root>/import-scenes/<WorldId>_Combined_Final.fbx + <WorldId>_Combined_Final.report.json

Why a combined scene: Roblox Studio's 3D Importer kept only the last file of a multi-file selection (found during
Studio integration), so each world is imported as one FBX scene containing every piece at its world position.
Studio import scale for these exports: 0.01 (validated on MHA during Studio staging).
Layers come from the collection property `sae_layer` written by sae_bpy.organize() into the .blend.
"""
import json
import os
import sys

argv = sys.argv[sys.argv.index("--") + 1:]
REPO, NN, WORLD, OUT = argv[0], argv[1], argv[2], argv[3]
MODE = argv[4] if len(argv) > 4 else "package"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import bpy  # noqa: E402
import sae_bpy as S  # noqa: E402

src = os.path.join(REPO, "art", "blender", "worlds", f"{NN}.blend")
bpy.ops.wm.open_mainfile(filepath=src)
rules = []
for c in bpy.data.collections:
    if c.name.startswith("EXPORT_") and "sae_layer" in c:
        rules.append((c.name[len("EXPORT_"):].partition("__")[0], c["sae_layer"]))
S.set_layers(sorted(set(rules)))

names_now = sorted(p[0] for p in S.module_groups())
committed = json.load(open(os.path.join(REPO, "art", "exports", "worlds", NN, "manifest.json")))
names_old = sorted(m["module"] for m in committed["modules"])
print(f"NAMES {NN}: now {len(names_now)} (unique {len(set(names_now))}), committed manifest {len(names_old)} "
      f"(unique {len(set(names_old))}); renamed/new: {sorted(set(names_now) - set(names_old))}; "
      f"no longer produced: {sorted(set(names_old) - set(names_now))}")

if MODE == "package":
    VALID = S.validate(WORLD, walk_half=committed["validation"]["walkHalf"])
    pieces = os.path.join(OUT, NN, "pieces")
    m = S.export_modules(pieces, committed["z0"], WORLD, validation=VALID)
    fbx = os.path.join(OUT, "import-scenes", f"{WORLD}_Combined_Final.fbx")
    rep = S.export_combined_scene(fbx, fbx.replace(".fbx", ".report.json"), WORLD, source_blend=f"art/blender/worlds/{NN}.blend")
    print(f"PACKAGED {WORLD}: pieces {len(m['modules'])} (files {len([f for f in os.listdir(pieces) if f.endswith('.fbx')])}), "
          f"combined scene pieces {rep['pieceCount']}, triangles {rep['triangles']}, validation {m['validation']['pass']}")
# nothing is saved: the canonical .blend stays byte-identical
