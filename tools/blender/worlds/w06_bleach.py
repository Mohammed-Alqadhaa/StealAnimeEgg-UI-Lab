"""
World 6 — Bleach / Yhwach's palace (reference R10_Bleach_Yhwach_palace_map.png — authoritative for the map)

  blender -b --factory-startup --python tools/blender/worlds/w06_bleach.py -- <repo_root> [render] [export]

Reference elements reproduced (R10):
  * monumental grey/white corridor with a polished dark floor and white inlaid guide lines
  * tall white banners with the black Wandenreich cross hanging from towering pillars
  * stone brazier pedestals with burning fires lining the path
  * gothic spires and towers rising on both sides under a stormy blue-grey sky
  * Yhwach enthroned at the top of a wide staircase at the far end
  * dark egg pedestals with a cold blue (reishi) glow
Gameplay: centre lane |x| < 54 clear and flat; palace walls at |x| = 75 (collide); open entry gate.
"""
import os
import sys
import math
import random

REPO = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
DO_RENDER = "render" in sys.argv
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import sae_bpy as S  # noqa: E402

rng = random.Random(606)
S.reset()

# ── palette (from R10) ────────────────────────────────────────────────────────
MARBLE = S.mat("BL_FloorMarble", "#3b3f47", rough=0.18, roblox="Marble")
MARBLE_L = S.mat("BL_FloorMarbleLight", "#4d525c", rough=0.2, roblox="Marble")
INLAY = S.mat("BL_Inlay", "#e9edf2", rough=0.3, roblox="Marble")
GROUT = S.mat("BL_Grout", "#1c1e23", rough=0.6, roblox="Slate")
STONE = S.mat("BL_PalaceStone", "#8d929b", rough=0.7, roblox="Slate")
STONE_D = S.mat("BL_PalaceStoneDark", "#4b4f58", rough=0.7, roblox="Slate")
STONE_W = S.mat("BL_PalaceWhite", "#d7dbe1", rough=0.6, roblox="Limestone")
BANNER = S.mat("BL_BannerWhite", "#eef0f3", rough=0.8, roblox="Fabric")
CROSS = S.mat("BL_WandenreichBlack", "#15161a", rough=0.6, roblox="SmoothPlastic")
IRON = S.mat("BL_Iron", "#26272b", rough=0.45, metal=0.8, roblox="Metal")
FIRE = S.mat("BL_Fire", "#ff8a2a", emit="#ff7a1a", strength=12.0, roblox="Neon")
FIRE_Y = S.mat("BL_FireCore", "#ffd25a", emit="#ffcc40", strength=14.0, roblox="Neon")
REISHI = S.mat("BL_ReishiBlue", "#7fd4ff", emit="#7fd4ff", strength=6.0, roblox="Neon")
THRONE = S.mat("BL_Throne", "#2c2e35", rough=0.4, roblox="Marble")
THRONE_W = S.mat("BL_ThroneWhite", "#e5e8ec", rough=0.4, roblox="Marble")
GLASS = S.mat("BL_SpireGlass", "#9fd8ff", emit="#8fd0ff", strength=1.5, roblox="Glass", transparency=0.2)

HALF, LEN, LANE = 75.0, 230.0, 54.0
EGGS = [(-42, 118), (42, 118), (-26, 158), (26, 158), (0, 184)]
BOSS_Y = 206.0
Y0, Y1 = -30.0, 228.0  # world slot (sae_bpy.WORLD_SLOT_Y): nothing may leave it
YM, YL = (Y0 + Y1) / 2, Y1 - Y0


def C(name):
    return S.use(S.collection(name))


def wandenreich(name, loc, rotz, s, material):
    """Wandenreich-style cross: a tall 4-point star with a longer lower arm (flat, stood up to face -y)."""
    pts = []
    arms = [(0, 1.5), (90, 1.0), (180, 2.1), (270, 1.0)]  # up, right, down, left (lengths)
    for k, (ang, ln) in enumerate(arms):
        a = math.radians(90 - ang)
        pts.append((math.cos(a) * ln * s, math.sin(a) * ln * s))
        b = math.radians(90 - ang - 45)
        pts.append((math.cos(b) * 0.28 * s, math.sin(b) * 0.28 * s))
    ob = S.prism(name, pts, -0.06, 0.06, material)
    ob.location = loc
    ob.rotation_euler = (math.radians(90), 0, math.radians(rotz))
    return ob


# ═════════════════════════════════════════════════════════════ FLOOR ══
C("EXPORT_Grout__Slate")
S.box("Grout", (HALF * 2, YL, 0.4), (0, YM, -0.45), material=GROUT)
for part, (y0, y1) in enumerate([(Y0, 64), (64, 140), (140, Y1)]):
    C(f"EXPORT_Floor{part + 1}__Marble")
    for ob in S.slab_floor(f"Marble{part}", -HALF, HALF, y0, y1, 10.0, 0.08, 0.0, 0.8, MARBLE, rng, jitter=0.0, tilt=0.0, bev=0.06):
        cx = sum(v.co.x for v in ob.data.vertices) / len(ob.data.vertices)
        if abs(cx) < 30 and rng.random() < 0.5:
            ob.data.materials[0] = MARBLE_L
C("EXPORT_FloorInlay__Marble")
for x in (-30, -12, 12, 30):  # white guide lines running to the throne (R10)
    S.box(f"InlayLine{x}", (0.5, 188 - Y0, 0.06), (x, (Y0 + 188) / 2, 0.02), material=INLAY)
for y in range(0, 190, 20):
    S.box(f"InlayCross{y}", (60.5, 0.4, 0.06), (0, y, 0.02), material=INLAY)

# ═════════════════════════════════════════════════════════ PALACE WALLS ══
C("EXPORT_Walls__Slate")
for side in (-1, 1):
    S.box(f"Wall{side}", (4, YL, 22), (side * (HALF + 2), YM, 11), material=STONE)
    S.box(f"WallCap{side}", (5.2, YL, 1.2), (side * (HALF + 2), YM, 22.6), material=STONE_W)
C("EXPORT_Buttresses__Slate")
for side in (-1, 1):
    for y in range(int(Y0) + 8, int(Y1) - 4, 18):
        S.box(f"Buttress{side}_{y}", (3, 4, 30), (side * (HALF - 1.5), y, 15), material=STONE_D, bev=0.2)
        S.cyl(f"ButtressSpire{side}_{y}", 2.2, 8, (side * (HALF - 1.5), y, 34), material=STONE_D, verts=4, r2=0.05)

# ═══════════════════════════════════════════════════ BANNER PILLARS ══
PILLARS = [(side * 62.0, y) for side in (-1, 1) for y in (20, 70, 120, 170)]
C("EXPORT_BannerPillars__Slate")
for (x, y) in PILLARS:
    S.box(f"Pillar{x}_{y}", (5, 5, 46), (x, y, 23), material=STONE_D, bev=0.3)
    S.box(f"PillarCap{x}_{y}", (6.4, 6.4, 2), (x, y, 47), material=STONE_W, bev=0.2)
    S.cyl(f"PillarSpire{x}_{y}", 3.2, 12, (x, y, 54), material=STONE_D, verts=4, r2=0.05)
C("EXPORT_BannerBars__Metal")
for (x, y) in PILLARS:
    S.box(f"BannerBar{x}_{y}", (1.0, 1.0, 1.0), (x - math.copysign(3.2, x), y, 44), material=IRON)
    S.cyl(f"BannerRod{x}_{y}", 0.25, 11, (x - math.copysign(3.2, x), y, 44), (90, 0, 0), IRON, verts=8)
C("EXPORT_Banners__Fabric")
for (x, y) in PILLARS:
    S.banner(f"Banner{x}_{y}", 10, 32, (x - math.copysign(3.4, x), y, 43.6), (0, 0, -90 * (1 if x > 0 else -1)), BANNER, rng, torn=False, wave=0.4)
C("EXPORT_BannerCrosses__SmoothPlastic")
for (x, y) in PILLARS:
    side = 1 if x > 0 else -1
    wandenreich(f"Cross{x}_{y}", (x - side * 3.65, y, 29), -90 * side, 3.4, CROSS)

# ══════════════════════════════════════════════════════════ BRAZIERS ══
BRAZ = [(side * (LANE + 2), y) for side in (-1, 1) for y in range(8, 190, 22)]
C("EXPORT_BrazierPedestals__Slate")
for (x, y) in BRAZ:
    S.cyl(f"BrazierBase{x}_{y}", 1.9, 4.5, (x, y, 2.25), material=STONE_D, verts=4, r2=1.3)
    S.box(f"BrazierPlinth{x}_{y}", (3.6, 3.6, 0.6), (x, y, 0.3), material=STONE, bev=0.1)
C("EXPORT_BrazierBowls__Metal")
for (x, y) in BRAZ:
    S.cyl(f"Bowl{x}_{y}", 1.2, 1.2, (x, y, 5.1), material=IRON, verts=10, r2=2.0)
C("EXPORT_BrazierFire__Neon")
for (x, y) in BRAZ:
    for k in range(3):
        a = 2 * math.pi * k / 3
        fh = rng.uniform(3.6, 5.0)
        S.cyl(f"Flame{x}_{y}_{k}", 1.05, fh, (x + math.cos(a) * 0.8, y + math.sin(a) * 0.8, 5.6 + fh / 2), material=FIRE, verts=6, r2=0.05)
C("EXPORT_BrazierFireCore__Neon")
for (x, y) in BRAZ:
    S.cyl(f"FlameCore{x}_{y}", 0.7, 3.2, (x, y, 7.2), material=FIRE_Y, verts=6, r2=0.05)
S.use(S.collection("VFX"))
for (x, y) in BRAZ:
    S.empty(f"VFX_Brazier_{int(x)}_{y}", (x, y, 7))["vfx"] = "fire + embers ParticleEmitter + warm flickering PointLight (runtime)"

# ═══════════════════════════════════════════════════════════ SPIRES ══
SPIRES = []
for side in (-1, 1):
    for k in range(11):
        w = rng.uniform(8, 16)
        SPIRES.append((side * rng.uniform(86, 150), rng.uniform(Y0 + w, Y1 - w), w, rng.uniform(50, 120)))
for half, pred in (("E", lambda t: t[0] < 0), ("W", lambda t: t[0] > 0)):
    C(f"EXPORT_Spires{half}__Slate")
    for i, (x, y, w, h) in enumerate([t for t in SPIRES if pred(t)]):
        S.box(f"Tower{half}{i}", (w, w, h), (x, y, h / 2), material=STONE if i % 3 else STONE_D)
        S.box(f"TowerBand{half}{i}", (w + 1.2, w + 1.2, 1.6), (x, y, h * 0.7), material=STONE_W)
        S.cyl(f"TowerSpire{half}{i}", w * 0.72, h * 0.35, (x, y, h + h * 0.175), material=STONE_D, verts=4, r2=0.05, rot=(0, 0, 45))
        for dx, dy in ((w * 0.5, w * 0.5), (-w * 0.5, w * 0.5), (w * 0.5, -w * 0.5), (-w * 0.5, -w * 0.5)):
            S.cyl(f"Pinnacle{half}{i}_{dx}_{dy}", 1.0, 8, (x + dx, y + dy, h + 4), material=STONE_W, verts=4, r2=0.05)
    C(f"EXPORT_SpireWindows{half}__Glass")
    for i, (x, y, w, h) in enumerate([t for t in SPIRES if pred(t)]):
        side = -1 if x < 0 else 1
        for z in range(12, int(h * 0.65), 14):
            S.box(f"Window{half}{i}_{z}", (0.3, w * 0.3, 6), (x - side * (w / 2 + 0.1), y, z), material=GLASS)
# ═══════════════════════════════════════════════════ YHWACH THRONE ══
C("EXPORT_Stairs__Marble")
for s_ in range(8):  # wide staircase rising toward the throne
    S.box(f"Stair{s_}", (46 - s_ * 2, 3.0, 0.8 + s_ * 0.8), (0, 196 + s_ * 3, (0.8 + s_ * 0.8) / 2), material=THRONE_W if s_ % 2 == 0 else STONE, bev=0.05)
S.box("ThronePlatform", (30, 6, 7.2), (0, 223, 3.6), material=THRONE_W, bev=0.1)
C("EXPORT_Throne__Marble")
S.box("ThroneSeat", (7, 4.5, 2.0), (0, 223, 8.2), material=THRONE, bev=0.3)
S.box("ThroneBack", (8, 1.6, 18), (0, 225.2, 16), material=THRONE, bev=0.3)
for dx in (-4.4, 4.4):
    S.box(f"ThroneWing{dx}", (1.4, 1.6, 12), (dx, 225.0, 13), material=THRONE)
    S.cyl(f"ThroneFinial{dx}", 0.8, 5, (dx, 225.0, 21.5), material=THRONE, verts=4, r2=0.05)
S.cyl("ThroneCrown", 1.4, 6, (0, 225.2, 28), material=THRONE, verts=4, r2=0.05)
C("EXPORT_ThroneCross__SmoothPlastic")
wandenreich("ThroneEmblem", (0, 224.3, 17.5), 0, 2.4, THRONE_W)
C("EXPORT_ThronePillars__Slate")
for side in (-1, 1):
    S.box(f"ThronePillar{side}", (5.5, 5.5, 58), (side * 20, 222, 29), material=STONE_D, bev=0.3)
    S.cyl(f"ThronePillarSpire{side}", 3.8, 16, (side * 20, 222, 66), material=STONE_D, verts=4, r2=0.05)
C("EXPORT_ThroneBanners__Fabric")
for side in (-1, 1):
    S.banner(f"ThroneBanner{side}", 11, 36, (side * 20, 218.9, 54), (0, 0, 0), BANNER, rng, torn=False, wave=0.3)
C("EXPORT_ThroneBannerCrosses__SmoothPlastic")
for side in (-1, 1):
    wandenreich(f"ThroneBannerCross{side}", (side * 20, 218.3, 40), 0, 3.0, CROSS)
C("EXPORT_ThroneReishi__Neon")
S.box("ThroneStepGlow", (30, 0.3, 0.25), (0, 219.9, 7.25), material=REISHI)
S.use(S.collection("VFX"))
S.empty("VFX_BossStage", (0, BOSS_Y, 5))["vfx"] = "boss anchor + black shadow / blue reishi aura (runtime)"
S.empty("VFX_ThroneAura", (0, 223, 12))["vfx"] = "dark aura + blue reishi motes rising (runtime)"

# ═══════════════════════════════════════════════════ EGG PEDESTALS ══
C("EXPORT_EggPedestals__Slate")
for i, (ex, ey) in enumerate(EGGS):
    S.box(f"Pedestal{i}", (6.0, 6.0, 1.2), (-ex, ey, 0.6), material=STONE_D, bev=0.15)
    S.box(f"PedestalTop{i}", (4.8, 4.8, 0.4), (-ex, ey, 1.4), material=THRONE, bev=0.1)
C("EXPORT_EggPedestalGlow__Neon")
for i, (ex, ey) in enumerate(EGGS):
    S.torus(f"PedGlow{i}", 2.2, 0.13, (-ex, ey, 1.62), (0, 0, 0), REISHI, major=28, minor=4)
    for dx, dy in ((3.05, 0), (-3.05, 0), (0, 3.05), (0, -3.05)):
        S.box(f"PedEdgeGlow{i}_{dx}_{dy}", (0.2 if dx else 5.0, 5.0 if dx else 0.2, 0.2), (-ex + dx, ey + dy, 1.0), material=REISHI)
S.use(S.collection("VFX"))
for i, (ex, ey) in enumerate(EGGS):
    S.empty(f"VFX_EggNest{i + 1}", (-ex, ey, 1.8))["vfx"] = "blue reishi motes + faint Quincy-cross decal pulse (runtime); egg spawn anchor"

# ═════════════════════════════════════════════════════════ ENTRY GATE ══
C("EXPORT_Gate__Slate")
GY = -3.0
for side in (-1, 1):
    S.box(f"GateTower{side}", (10, 10, 52), (side * 60, GY, 26), material=STONE_D, bev=0.3)
    S.cyl(f"GateTowerSpire{side}", 7.5, 20, (side * 60, GY, 62), material=STONE_D, verts=4, r2=0.05, rot=(0, 0, 45))
S.arch("GateArch", 110, 4, 6, (0, GY, 28), (0, 0, 0), STONE_W, segs=28)
C("EXPORT_GateCross__SmoothPlastic")
wandenreich("GateEmblem", (0, GY - 3.2, 76), 0, 4.0, CROSS)
C("EXPORT_GateEmblemPlate__Limestone")
S.cyl("GatePlate", 7.5, 0.6, (0, GY - 2.8, 76), (90, 0, 0), STONE_W, verts=24)

# ═════════════════════════════════════════════════════════ SAVE / RENDER / EXPORT ══
blend_dir = os.path.join(REPO, "art", "blender", "worlds")
os.makedirs(blend_dir, exist_ok=True)
S.bpy.ops.wm.save_as_mainfile(filepath=os.path.join(blend_dir, "06_Bleach.blend"))
print("SAVED 06_Bleach.blend")

if DO_RENDER:
    S.setup_render(sky="#5d6f8c", sky_strength=0.9, samples=int(os.environ.get("SAE_SAMPLES", "40")), sky_light=0.55, ambient="#dfe8f5")
    S.sun("Sun", (55, 0, 25), strength=2.6, color="#eef3ff")
    for (x, y) in BRAZ:
        S.point(f"FireLight{x}_{y}", (x, y, 7.5), 600, "#ff8a2a", radius=0.8)
    S.point("ThroneLight", (0, 214, 16), 3000, "#7fd4ff", radius=3)
    out = os.path.join(REPO, "art", "review_renders", "v02", "06_Bleach")
    tag = os.environ.get("SAE_TAG", "pass1")
    S.render(os.path.join(out, f"{tag}_gameplay.png"), (0, -14, 9), (0, 120, 12), lens=22)
    S.render(os.path.join(out, f"{tag}_boss.png"), (0, 160, 10), (0, 222, 18), lens=24)
    S.render(os.path.join(out, f"{tag}_overview.png"), (0, -95, 120), (0, 115, 0), lens=24)

if "export" in sys.argv:
    m = S.export_modules(os.path.join(REPO, "art", "exports", "worlds", "06_Bleach"), "Layout.worldZ0(6)", "Bleach")
    tot = sum(x["triangles"] for x in m["modules"])
    print("EXPORTED", len(m["modules"]), "modules", tot, "tris", "over limit:", [x["module"] for x in m["modules"] if x["overLimit"]],
          "outside slot:", [x["module"] for x in m["modules"] if x["outsideSlot"]])
