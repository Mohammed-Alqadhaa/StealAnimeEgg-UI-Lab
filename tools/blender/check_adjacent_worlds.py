"""
Cross-world overlap check for the v02 Blender worlds (plain Python, no Blender needed).

  python3 tools/blender/check_adjacent_worlds.py [repo_root]

Every world sits in one line: world i's local origin is at Roblox Z = Layout.worldZ0(i) = 205 + (i - 1) * 260,
and module bounds in each manifest are Blender world-local (x, y, z) with Roblox (X, Y, Z) = (-x, z, z0 + y).
This shifts every exported module of worlds 2-8 into one frame and reports AABB intersections between modules of
DIFFERENT worlds (all pairs, not just neighbours: sky-level objects can reach several worlds away).

Akaza (world 1) is preserved, not exported from Blender, so its far-end extents are listed from a Lune scan of
SAFE_TEST (see AKAZA_FAR_END below). Only the parts that reach past its zone end are relevant.

Classification of an intersection:
  CONFLICT  - either side collides AND both are within character height of the playable band, or a visible mesh
              sits inside the other world's playable corridor (|x| < 82, z < 60)
  NOTE      - everything else (e.g. both non-collidable scenery far from any route)
Exit code 1 if any CONFLICT is found.
"""
import json
import os
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
STRIDE = 260.0
WORLDS = [(2, "02_MHA"), (3, "03_DragonBall"), (4, "04_OnePiece"), (5, "05_Naruto"), (6, "06_Bleach"),
          (7, "07_JJK"), (8, "08_SoloLeveling")]
CORRIDOR_X, CORRIDOR_Z = 82.0, 60.0

# Akaza parts that extend past its zone end (Roblox Z > 435), from a Lune scan of SAFE_TEST (2026-09-28).
# Converted to Akaza-local Blender coords: x = -X, y = Z - 205, z = Y.
AKAZA_FAR_END = [
    # name, xmin, ymin, zmin, xmax, ymax, zmax, collides, protected
    ("Akaza:Environment.Rocks.RiverRockSupport_1_10", -76.2, 206.9, -7.1, -60.8, 243.1, 0.1, False, True),
    ("Akaza:Environment.Rocks.RiverRockSupport_-1_10", 61.2, 210.3, -6.1, 76.9, 239.7, -0.1, False, True),
    ("Akaza:NightDressing.WallCollider(+X)", -80.0, -5.0, 0.0, -76.0, 235.0, 90.0, True, False),
    ("Akaza:NightDressing.WallCollider(-X)", 76.0, -5.0, 0.0, 80.0, 235.0, 90.0, True, False),
    ("Akaza:NightDressing.Moon", 37.0, 307.0, 127.0, 83.0, 353.0, 173.0, False, False),
    ("Akaza:NightDressing.MoonHalo", 31.0, 303.0, 121.0, 89.0, 361.0, 179.0, False, False),
]


def boxes():
    out = []
    for (name, x0, y0, z0, x1, y1, z1, col, prot) in AKAZA_FAR_END:
        out.append({"world": 1, "id": name, "layer": "AKAZA", "collides": col, "b": (x0, y0, z0, x1, y1, z1)})
    for idx, folder in WORLDS:
        path = os.path.join(REPO, "art", "exports", "worlds", folder, "manifest.json")
        m = json.load(open(path))
        off = (idx - 1) * STRIDE
        for mod in m["modules"]:
            for b in mod.get("objectBounds") or [mod["boundsLocal"]]:  # per-object bounds when available
                out.append({"world": idx, "id": f"{folder}:{mod['module']}", "layer": mod["layer"],
                            "collides": mod["canCollide"], "b": (b[0], b[1] + off, b[2], b[3], b[4] + off, b[5])})
        for c in m.get("colliders", []):
            X, Y, Z = c["robloxPosition"]
            sx, sy, sz = c["sizeStuds"]
            x, y, z = -X, Z, Y
            out.append({"world": idx, "id": f"{folder}:collider:{c['name']}", "layer": "COLLISION", "collides": True,
                        "b": (x - sx / 2, y - sz / 2 + off, z - sy / 2, x + sx / 2, y + sz / 2 + off, z + sy / 2)})
    return out


def inter(a, b):
    return all(a[i] < b[i + 3] and b[i] < a[i + 3] for i in range(3))


def main():
    bx = boxes()
    conflicts, notes, seen = [], [], set()
    for i in range(len(bx)):
        for j in range(i + 1, len(bx)):
            A, B = bx[i], bx[j]
            if A["world"] == B["world"] or not inter(A["b"], B["b"]):
                continue
            ov = [max(A["b"][k], B["b"][k]) for k in range(3)] + [min(A["b"][k + 3], B["b"][k + 3]) for k in range(3)]
            in_corridor = ov[0] < CORRIDOR_X and ov[3] > -CORRIDOR_X and ov[2] < CORRIDOR_Z
            low = ov[2] < 12.0 and ov[5] > 0.0
            kind = "CONFLICT" if ((A["collides"] or B["collides"]) and low) or (in_corridor and ov[5] > 0.5 and
                                                                              "AKAZA" not in (A["layer"], B["layer"])) else "NOTE"
            # protected Akaza geometry flush with / below floor level under the next world's threshold floor
            if kind == "CONFLICT" and "AKAZA" in (A["layer"], B["layer"]) and ov[5] <= 0.2:
                kind = "NOTE"
            # two boundary colliders on the same wall line are harmless
            if kind == "CONFLICT" and A["collides"] and B["collides"] and A["layer"] in ("BOUNDARY", "COLLISION", "AKAZA") \
                    and B["layer"] in ("BOUNDARY", "COLLISION", "AKAZA") and abs(ov[0]) > 70 and abs(ov[3]) > 70:
                kind = "NOTE"
            rec = f"{A['id']} [{A['layer']}] x {B['id']} [{B['layer']}] overlap x[{ov[0]:.1f},{ov[3]:.1f}] z[{ov[2]:.1f},{ov[5]:.1f}] globalY[{ov[1]:.1f},{ov[4]:.1f}]"
            key = (A["id"], B["id"], kind)
            if key in seen:
                continue
            seen.add(key)
            (conflicts if kind == "CONFLICT" else notes).append(rec)
    print(f"CROSS-WORLD CHECK: {len(conflicts)} conflict(s), {len(notes)} note(s)")
    for r in conflicts:
        print("  CONFLICT", r)
    for r in notes:
        print("  NOTE", r)
    report = {"conflicts": conflicts, "notes": notes}
    with open(os.path.join(REPO, "art", "exports", "worlds", "cross_world_check.json"), "w") as f:
        json.dump(report, f, indent=1)
    return 1 if conflicts else 0


if __name__ == "__main__":
    sys.exit(main())
