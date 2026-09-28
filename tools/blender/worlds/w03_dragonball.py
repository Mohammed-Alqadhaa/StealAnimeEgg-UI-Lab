"""
World 3 — Dragon Ball / Planet Namek, boss Frieza (reference R02 "PLANET NAMEK" panel)

  blender -b --factory-startup --python tools/blender/worlds/w03_dragonball.py -- <repo_root> [render] [export]

Reference elements reproduced (R02 Namek):
  * bright green sky with a large pale-green planet hanging over the horizon
  * grey stone causeway running straight to Frieza, edged by a low balustrade with warm lanterns on posts
  * turquoise Namek sea on both sides; small grass islands with blue-ball Ajisa trees and white dome houses
  * tan/ochre layered mesas on the horizon, with waterfalls pouring into the sea
  * Frieza at the far end on a dark stage framed by a glowing purple arch
  * extra Dragon Ball identity: seven orange Dragon Balls on plinths, Frieza's hover pod, crashed Saiyan pods
Gameplay: centre lane |x| < 54 clear and flat; invisible boundary colliders at the causeway edge (no one enters
the sea, no falling); world length 230; open entry/exit gates.
"""
import os
import sys
import math
import random

REPO = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
DO_RENDER = "render" in sys.argv
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import sae_bpy as S  # noqa: E402

rng = random.Random(303)
S.reset()

# ── palette (from R02 Namek) ──────────────────────────────────────────────────
PATH = S.mat("DB_PathStone", "#a3a2a8", rough=0.85, roblox="Slate")
PATH_D = S.mat("DB_PathStoneDark", "#86868f", rough=0.9, roblox="Slate")
GROUT = S.mat("DB_Grout", "#5d5a55", rough=0.95, roblox="Slate")
CURB = S.mat("DB_Curb", "#d6d1c4", rough=0.8, roblox="Limestone")
GRASS = S.mat("DB_Grass", "#58b84e", rough=0.9, roblox="Grass")
GRASS_D = S.mat("DB_GrassDark", "#3f9a44", rough=0.9, roblox="Grass")
ROCK = S.mat("DB_Rock", "#b99a6a", rough=0.9, roblox="Sandstone")
ROCK_B = S.mat("DB_RockBand", "#9c7a4e", rough=0.9, roblox="Sandstone")
SEA = S.mat("DB_Sea", "#2fc4c7", rough=0.08, roblox="Glass", transparency=0.25)
SEABED = S.mat("DB_Seabed", "#1f7f86", rough=0.9, roblox="Sand")
FALL = S.mat("DB_Waterfall", "#c9f4ff", emit="#b5ecff", strength=0.15, rough=0.2, roblox="Glass", transparency=0.3)
TRUNK = S.mat("DB_Trunk", "#8a7a5c", rough=0.8, roblox="Wood")
LEAF = S.mat("DB_AjisaBlue", "#2f5fc4", rough=0.7, roblox="Grass")
LEAF_L = S.mat("DB_AjisaBlueLight", "#4b82e0", rough=0.7, roblox="Grass")
DOME = S.mat("DB_Dome", "#eef3f1", rough=0.5, roblox="SmoothPlastic")
DOME_W = S.mat("DB_DomeWindow", "#2a3d3a", rough=0.3, roblox="Glass")
LANTERN = S.mat("DB_LanternGlow", "#ffc25a", emit="#ffb640", strength=8.0, roblox="Neon")
IRON = S.mat("DB_Iron", "#3a3a40", rough=0.45, metal=0.8, roblox="Metal")
STAGE = S.mat("DB_Stage", "#3a2f4d", rough=0.6, roblox="Slate")
STAGE_L = S.mat("DB_StageTrim", "#5a4a74", rough=0.5, roblox="Slate")
ARCGLOW = S.mat("DB_FriezaGlow", "#b25cff", emit="#c07aff", strength=10.0, roblox="Neon")
PORTAL = S.mat("DB_PortalGlass", "#3b1a5c", emit="#6a2cb0", strength=0.8, roblox="Glass", transparency=0.55)
DBALL = S.mat("DB_DragonBall", "#ff9a1f", emit="#ff8a00", strength=1.2, rough=0.1, roblox="Glass")
DSTAR = S.mat("DB_DragonBallStar", "#d0121b", rough=0.4, roblox="SmoothPlastic")
POD = S.mat("DB_PodWhite", "#e9e9ee", rough=0.3, metal=0.2, roblox="SmoothPlastic")
PODGLASS = S.mat("DB_PodGlass", "#7a2d9e", rough=0.1, roblox="Glass", transparency=0.3)
PODRED = S.mat("DB_PodRed", "#b21e2a", rough=0.4, roblox="SmoothPlastic")
PEDESTAL = S.mat("DB_Pedestal", "#2d2a33", rough=0.5, roblox="Slate")
PEDGLOW = S.mat("DB_PedestalGlow", "#6cff8a", emit="#6cff8a", strength=6.0, roblox="Neon")
PLANET = S.mat("DB_SkyPlanet", "#a8e6a0", emit="#b9f0ae", strength=0.35, rough=0.9, roblox="SmoothPlastic")
PLANET_B = S.mat("DB_SkyPlanetBand", "#7fcf86", emit="#8fd996", strength=0.3, rough=0.9, roblox="SmoothPlastic")
PLAZA_L = S.mat("DB_PlazaLight", "#d9d4c8", rough=0.8, roblox="Limestone")
EMBLEM = S.mat("DB_Emblem", "#ff9a1f", rough=0.5, roblox="SmoothPlastic")

HALF, LEN, LANE = 75.0, 230.0, 54.0
EDGE = 56.0  # causeway edge (balustrade)
EGGS = [(-42, 118), (42, 118), (-26, 158), (26, 158), (0, 184)]
BOSS_Y = 206.0
Y0, Y1 = -30.0, 228.0  # world slot (sae_bpy.WORLD_SLOT_Y): nothing may leave it (sky objects excepted)
YM, YL = (Y0 + Y1) / 2, Y1 - Y0
PLAZA = (0.0, 168.0, 34.0)


def C(name):
    return S.use(S.collection(name))


def blob(cx, cy, r, n=9, var=0.25):
    return [(cx + math.cos(2 * math.pi * k / n) * r * rng.uniform(1 - var, 1), cy + math.sin(2 * math.pi * k / n) * r * rng.uniform(1 - var, 1)) for k in range(n)]


def star(cx, cy, r, points=5):
    return [(cx + math.cos(math.pi / 2 + math.pi * k / points) * (r if k % 2 == 0 else r * 0.42),
             cy + math.sin(math.pi / 2 + math.pi * k / points) * (r if k % 2 == 0 else r * 0.42)) for k in range(points * 2)]


def in_plaza(x, y):
    return math.hypot(x - PLAZA[0], y - PLAZA[1]) < PLAZA[2] + 1.0


# ═══════════════════════════════════════════════════════════ CAUSEWAY ══
C("EXPORT_Grout__Slate")
S.box("Grout", (EDGE * 2, YL, 0.4), (0, YM, -0.4), material=GROUT)
for part, (y0, y1) in enumerate([(Y0, 64), (64, 140), (140, Y1)]):
    C(f"EXPORT_Causeway{part + 1}__Slate")
    for ob in S.slab_floor(f"Path{part}", -EDGE, EDGE, y0, y1, 9.0, 0.16, 0.0, 0.8, PATH, rng, jitter=0.1, tilt=0.004, bev=0.1, gap_var=0.06):
        cx = sum(v.co.x for v in ob.data.vertices) / len(ob.data.vertices)
        cy = sum(v.co.y for v in ob.data.vertices) / len(ob.data.vertices)
        if in_plaza(cx, cy):
            S.bpy.data.objects.remove(ob, do_unlink=True)
        elif rng.random() < 0.22:
            ob.data.materials[0] = PATH_D

# plaza: concentric rings + Dragon Ball emblem (orange disc with red stars)
C("EXPORT_Plaza__Limestone")
px, py, pr = PLAZA
for ri, (ro, rin) in enumerate([(pr, pr - 6), (pr - 6.3, pr - 14), (pr - 14.3, 0)]):
    segs = 24 if rin > 0 else 1
    for k in range(segs):
        if rin > 0:
            a0, a1 = 2 * math.pi * k / segs, 2 * math.pi * (k + 1) / segs
            poly = [(px + math.cos(a0 + (a1 - a0) * s / 3) * (ro - 0.12), py + math.sin(a0 + (a1 - a0) * s / 3) * (ro - 0.12)) for s in range(4)]
            poly += [(px + math.cos(a0 + (a1 - a0) * s / 3) * (rin + 0.12), py + math.sin(a0 + (a1 - a0) * s / 3) * (rin + 0.12)) for s in range(3, -1, -1)]
        else:
            poly = [(px + math.cos(2 * math.pi * s / 40) * ro, py + math.sin(2 * math.pi * s / 40) * ro) for s in range(40)]
        S.prism(f"PlazaRing{ri}_{k}", poly, -0.8, 0.04, PLAZA_L if ri == 1 else PATH)
C("EXPORT_PlazaEmblem__SmoothPlastic")
S.prism("EmblemDisc", blob(px, py, 7.0, 40, 0.0), 0.04, 0.1, EMBLEM)
for k, (sx, sy) in enumerate([(-2.6, 2.0), (2.6, 2.0), (-2.6, -2.4), (2.6, -2.4)]):
    S.prism(f"EmblemStar{k}", star(px + sx, py + sy, 1.5), 0.1, 0.16, DSTAR)

# balustrade: low curb wall with posts; lantern posts every 26 studs
C("EXPORT_Balustrade__Limestone")
for side in (-1, 1):
    S.box(f"CurbBase{side}", (1.6, YL, 0.8), (side * (EDGE + 0.8), YM, 0.4), material=CURB, bev=0.08)
    S.box(f"CurbRail{side}", (1.0, YL, 0.45), (side * (EDGE + 0.8), YM, 2.9), material=CURB, bev=0.08)
    for y in range(int(Y0) + 2, int(Y1), 6):
        S.cyl(f"Baluster{side}_{y}", 0.35, 2.1, (side * (EDGE + 0.8), y, 1.75), material=CURB, verts=8, r2=0.26)
C("EXPORT_LanternPosts__Limestone")
posts = [(side * (EDGE + 0.8), y) for side in (-1, 1) for y in range(13, 200, 26)]
for (x, y) in posts:
    S.box(f"LPost{x}_{y}", (2.2, 2.2, 5.4), (x, y, 2.7), material=CURB, bev=0.15)
    S.box(f"LPostCap{x}_{y}", (2.8, 2.8, 0.5), (x, y, 5.6), material=CURB, bev=0.1)
C("EXPORT_LanternFrames__Metal")
for (x, y) in posts:
    for dx in (-0.65, 0.65):
        for dy in (-0.65, 0.65):
            S.box(f"LF{x}_{y}_{dx}_{dy}", (0.16, 0.16, 1.8), (x + dx, y + dy, 6.75), material=IRON)
    S.box(f"LRoof{x}_{y}", (1.8, 1.8, 0.25), (x, y, 7.75), material=IRON, bev=0.05)
C("EXPORT_LanternGlow__Neon")
for (x, y) in posts:
    S.box(f"LGlow{x}_{y}", (1.1, 1.1, 1.5), (x, y, 6.75), material=LANTERN)
S.use(S.collection("VFX"))
for (x, y) in posts[::2]:
    S.empty(f"VFX_Lantern_{int(x)}_{y}", (x, y, 6.8))["vfx"] = "warm PointLight (runtime)"

# gameplay boundary: invisible colliders on the balustrade line (the sea is never walkable)
for side in (-1, 1):
    S.collider(f"BoundaryCollider{side}", (2.0, YL, 40), (side * (EDGE + 1.2), YM, 20))

# ════════════════════════════════════════════════════════════════ SEA ══
C("EXPORT_Sea__Glass")
for side in (-1, 1):
    S.box(f"SeaSurface{side}", (340, YL, 0.2), (side * (EDGE + 170), YM, -1.2), material=SEA)
C("EXPORT_Seabed__Sand")
S.box("Seabed", (760, YL, 0.4), (0, YM, -5), material=SEABED)
C("EXPORT_CausewayWall__Sandstone")  # causeway embankment face, seen above the waterline
for side in (-1, 1):
    S.box(f"Embankment{side}", (2.0, YL, 5.6), (side * (EDGE + 1.6), YM, -2.4), material=ROCK_B)
S.use(S.collection("VFX"))
for side in (-1, 1):
    S.empty(f"VFX_SeaShimmer{side}", (side * 90, LEN / 2, -1))["vfx"] = "sea texture scroll + sparkle (runtime)"

# ═══════════════════════════════════════════════════════════ ISLANDS ══
ISLANDS = []
for side in (-1, 1):
    y = Y0 + 12
    while y < Y1 - 12:
        r = min(rng.uniform(11, 20), (y - Y0) / 1.1, (Y1 - y) / 1.1)
        x = side * rng.uniform(EDGE + 14 + r, EDGE + 40 + r)
        ISLANDS.append((x, y, r))
        y += r * 2 + rng.uniform(6, 20)
    for k in range(4):  # a second, farther row
        r = rng.uniform(16, 28)
        ISLANDS.append((side * rng.uniform(170, 230), rng.uniform(Y0 + r * 1.1, Y1 - r * 1.1), r))
C("EXPORT_IslandRock__Sandstone")
for i, (x, y, r) in enumerate(ISLANDS):
    S.prism(f"IslandRock{i}", blob(x, y, r * 1.05, 11), -4.5, 0.2, ROCK)
C("EXPORT_IslandGrass__Grass")
for i, (x, y, r) in enumerate(ISLANDS):
    S.prism(f"IslandGrass{i}", blob(x, y, r * 0.95, 11, 0.12), 0.2, 0.9 + rng.uniform(0, 0.6), GRASS if i % 3 else GRASS_D)

# ═════════════════════════════════════════════════════ AJISA TREES ══
TREES = []
for (x, y, r) in ISLANDS:
    for k in range(rng.randint(2, 4)):
        a, d = rng.uniform(0, 2 * math.pi), rng.uniform(0, r * 0.7)
        TREES.append((x + math.cos(a) * d, y + math.sin(a) * d, rng.uniform(16, 30)))
for side in (-1, 1):  # trees rising from the water right beside the causeway (R02 lines the path)
    for y in range(4, int(Y1) - 10, 22):
        TREES.append((side * (EDGE + rng.uniform(6, 11)), y + rng.uniform(-4, 4), rng.uniform(18, 28)))
for half, pred in (("E", lambda t: t[0] < 0), ("W", lambda t: t[0] >= 0)):
    C(f"EXPORT_Trunks{half}__Wood")
    for i, (x, y, h) in enumerate([t for t in TREES if pred(t)]):
        S.cyl(f"Trunk{half}{i}", 0.55, h, (x, y, h / 2 - 1.2), (rng.uniform(-3, 3), rng.uniform(-3, 3), 0), TRUNK, verts=7, r2=0.35)
    for i, (x, y, h) in enumerate([t for t in TREES if pred(t)]):
        C(f"EXPORT_Canopy{half}{i % 2 + 1}__Grass")  # two modules per side: each stays under 20k triangles
        cr = rng.uniform(3.4, 5.0)
        S.sphere(f"Canopy{half}{i}", cr, (x, y, h - 1.2 + cr * 0.4), LEAF if i % 2 else LEAF_L, seg=14, rings=9)
        for k in range(3):
            a = rng.uniform(0, 2 * math.pi)
            S.sphere(f"Canopy{half}{i}_{k}", cr * 0.6, (x + math.cos(a) * cr * 0.7, y + math.sin(a) * cr * 0.7, h - 1.2 + cr * rng.uniform(-0.1, 0.5)), LEAF, seg=10, rings=6)

# ══════════════════════════════════════════════════ NAMEKIAN DOMES ══
C("EXPORT_Domes__SmoothPlastic")
DOMES = []
for i, (x, y, r) in enumerate(ISLANDS):
    if i % 2 == 0 and r > 13:
        dr = rng.uniform(5, 8)
        DOMES.append((x + rng.uniform(-r * 0.3, r * 0.3), y + rng.uniform(-r * 0.3, r * 0.3), dr))
for k, (x, y, dr) in enumerate(DOMES):
    S.sphere(f"Dome{k}", dr, (x, y, 0.8), DOME, seg=20, rings=12, scale=(1, 1, 0.82))
    S.cyl(f"DomeTube{k}", dr * 0.14, dr * 0.5, (x + dr * 0.3, y, 0.8 + dr * 0.95), material=DOME, verts=10)
    S.sphere(f"DomeTubeCap{k}", dr * 0.16, (x + dr * 0.3, y, 0.8 + dr * 1.2), DOME, seg=10, rings=6)
C("EXPORT_DomeWindows__Glass")
for k, (x, y, dr) in enumerate(DOMES):
    face = -1 if x > 0 else 1  # windows face the causeway
    for j, (ang, z) in enumerate(((0, 0.35), (-28, 0.45), (28, 0.3))):
        a = math.radians(ang)
        wx = x + face * math.cos(a) * dr * 0.93
        wy = y + math.sin(a) * dr * 0.93
        S.cyl(f"DomeWin{k}_{j}", dr * 0.17, 0.3, (wx, wy, 0.8 + dr * z), (0, 90, ang), DOME_W, verts=14)

# ═══════════════════════════════════════════════════════════ MESAS ══
MESAS = []
for side in (-1, 1):
    for k in range(5):
        r = rng.uniform(22, 40)
        MESAS.append((side * rng.uniform(250, 330), rng.uniform(Y0 + r * 1.35, Y1 - r * 1.35), r, rng.uniform(35, 75)))
for half, pred in (("E", lambda m: m[0] < 0), ("W", lambda m: m[0] > 0)):
    C(f"EXPORT_Mesas{half}__Sandstone")
    for i, (x, y, r, h) in enumerate([m for m in MESAS if pred(m)]):
        z, rr, layer = -3.0, r, 0
        while z < h:
            lh = rng.uniform(9, 18)
            S.prism(f"Mesa{half}{i}_{layer}", blob(x + rng.uniform(-2, 2), y + rng.uniform(-2, 2), rr, 12, 0.22), z, min(h, z + lh), ROCK if layer % 2 == 0 else ROCK_B)
            z += lh
            rr *= rng.uniform(0.9, 1.02)
            layer += 1
C("EXPORT_Waterfalls__Glass")
FALLS = [m for m in MESAS if abs(m[0]) > 200][:6]
for i, (x, y, r, h) in enumerate(FALLS):
    face = -1 if x > 0 else 1
    S.box(f"Waterfall{i}", (0.4, r * 0.35, h * 0.8), (x + face * r * 0.85, y, h * 0.4 - 1), (0, face * -6, 0), FALL)
    S.use(S.collection("VFX"))
    S.empty(f"VFX_Waterfall{i + 1}", (x + face * r * 0.85, y, 0))["vfx"] = "falling water beam + splash mist (runtime)"
    S.use(S.collection(f"EXPORT_Waterfalls__Glass"))

# ═══════════════════════════════════════════════════════ FRIEZA STAGE ══
C("EXPORT_Stage__Slate")
for s in range(3):
    S.box(f"StageStep{s}", (40 - s * 7, 4.2, 1.0), (0, 194 + s * 3, 0.5 + s * 1.0), material=STAGE_L, bev=0.1)
S.box("StageTop", (34, 22, 3.0), (0, 214, 1.5), material=STAGE, bev=0.2)
for side in (-1, 1):
    S.box(f"ArchPillar{side}", (4.5, 4.5, 28), (side * 15, 220, 14), material=STAGE, bev=0.3)
    S.box(f"ArchPillarCap{side}", (5.6, 5.6, 1.6), (side * 15, 220, 28.6), material=STAGE_L, bev=0.2)
    S.box(f"StageWing{side}", (10, 12, 2.2), (side * 23, 214, 1.1), material=STAGE_L, bev=0.2)
C("EXPORT_StageArch__Slate")
S.torus("ArchRing", 15, 1.6, (0, 220, 28), (90, 0, 0), STAGE, major=40, minor=8, scale=(1, 1, 1))
C("EXPORT_StageGlow__Neon")
S.torus("ArchGlow", 13.2, 0.35, (0, 219, 28), (90, 0, 0), ARCGLOW, major=48, minor=6)
for side in (-1, 1):
    S.box(f"PillarGlow{side}", (0.3, 0.3, 24), (side * 12.7, 218, 14), material=ARCGLOW)
S.box("StageEdgeGlow", (34, 0.3, 0.25), (0, 203, 3.05), material=ARCGLOW)
C("EXPORT_StagePortal__Glass")
S.cyl("PortalPane", 12.8, 0.3, (0, 221, 28), (90, 0, 0), PORTAL, verts=40)
S.box("PortalLower", (25.6, 0.3, 25), (0, 221, 15.5), material=PORTAL)
S.use(S.collection("VFX"))
for n, loc, v in (("VFX_BossStage", (0, BOSS_Y, 3), "boss anchor + purple energy aura (runtime)"),
                  ("VFX_FriezaArch", (0, 219, 28), "arch glow pulse + swirling portal (runtime)")):
    S.empty(n, loc)["vfx"] = v

# Frieza hover pod beside the stage
C("EXPORT_HoverPod__SmoothPlastic")
S.sphere("PodBody", 3.4, (22, 206, 6.5), POD, seg=20, rings=10, scale=(1, 1, 0.55))
S.cyl("PodStem", 0.8, 3.0, (22, 206, 3.4), material=POD, verts=12, r2=0.5)
S.cyl("PodBase", 2.2, 0.6, (22, 206, 3.3), material=POD, verts=16)
C("EXPORT_HoverPodGlass__Glass")
S.sphere("PodDome", 2.6, (22, 206, 7.6), PODGLASS, seg=16, rings=8, scale=(1, 1, 0.6))

# crashed Saiyan attack pods at the lane edge (decor, never on the lane)
C("EXPORT_SaiyanPods__SmoothPlastic")
for k, (x, y) in enumerate(((-EDGE + 5, 44), (EDGE - 5, 96))):
    S.sphere(f"SaiyanPod{k}", 2.6, (x, y, 1.2), POD, seg=16, rings=10)
    S.torus(f"SaiyanPodRim{k}", 2.6, 0.3, (x, y, 1.4), (20, 0, 0), POD, major=24, minor=6)
    S.rubble(f"PodCrater{k}", 6, (x - 4, x + 4, y - 4, y + 4), rng, PATH_D, size=(0.5, 1.2))
C("EXPORT_SaiyanPodWindows__Glass")
for k, (x, y) in enumerate(((-EDGE + 5, 44), (EDGE - 5, 96))):
    S.cyl(f"SaiyanPodWin{k}", 1.3, 0.4, (x - math.copysign(2.1, x) * 0.0, y - 2.3, 1.8), (90, 0, 0), PODRED, verts=16)

# ═══════════════════════════════════════════════════ DRAGON BALLS ══
C("EXPORT_DragonBallPlinths__Limestone")
# seven plinths just inside the balustrade near the plaza/stage (outside the egg and boss paths)
BALLS = [(-50, 150), (50, 150), (-50, 176), (50, 176), (-50, 202), (50, 202), (-30, 226)]
for k, (x, y) in enumerate(BALLS):
    S.cyl(f"DBPlinth{k}", 1.4, 2.6, (x, y, 1.3), material=CURB, verts=10, r2=1.1)
C("EXPORT_DragonBalls__Glass")
for k, (x, y) in enumerate(BALLS):
    S.sphere(f"DragonBall{k}", 1.2, (x, y, 3.8), DBALL, seg=16, rings=10)
C("EXPORT_DragonBallStars__SmoothPlastic")
for k, (x, y) in enumerate(BALLS):
    n = k + 1
    for j in range(n):
        a = 2 * math.pi * j / n
        off = 0 if n == 1 else 0.38
        st = S.prism(f"DBStar{k}_{j}", star(0, 0, 0.26), 0, 0.04, DSTAR)
        st.rotation_euler = (math.radians(90), 0, 0)
        st.location = (x + math.cos(a) * off, y - 1.17, 3.8 + math.sin(a) * off)
S.use(S.collection("VFX"))
S.empty("VFX_DragonBalls", (0, 188, 4))["vfx"] = "soft orange glow + shimmer on the seven Dragon Balls (runtime)"

# ═══════════════════════════════════════════════════ EGG PEDESTALS ══
C("EXPORT_EggPedestals__Slate")
for i, (ex, ey) in enumerate(EGGS):
    S.box(f"Pedestal{i}", (6.4, 6.4, 1.2), (-ex, ey, 0.6), material=PEDESTAL, bev=0.2)
    S.box(f"PedestalTop{i}", (5.2, 5.2, 0.4), (-ex, ey, 1.4), material=STAGE_L, bev=0.12)
C("EXPORT_EggPedestalGlow__Neon")
for i, (ex, ey) in enumerate(EGGS):
    S.torus(f"PedGlow{i}", 2.3, 0.14, (-ex, ey, 1.62), (0, 0, 0), PEDGLOW, major=28, minor=4)
S.use(S.collection("VFX"))
for i, (ex, ey) in enumerate(EGGS):
    S.empty(f"VFX_EggNest{i + 1}", (-ex, ey, 1.8))["vfx"] = "ki aura ring + rising sparks (runtime); egg spawn anchor"

# ═════════════════════════════════════════════════════ ENTRY / EXIT ══
C("EXPORT_Gates__Limestone")
for gy, tag in ((-2.0, "Entry"),):
    for side in (-1, 1):
        S.box(f"{tag}GatePillar{side}", (5, 5, 22), (side * (EDGE - 2), gy, 11), material=CURB, bev=0.3)
        S.sphere(f"{tag}GateOrb{side}", 2.8, (side * (EDGE - 2), gy, 24.2), DOME, seg=14, rings=8)
C("EXPORT_GateOrbGlow__Neon")
for gy, tag in ((-2.0, "Entry"),):
    for side in (-1, 1):
        S.torus(f"{tag}GateRing{side}", 2.9, 0.18, (side * (EDGE - 2), gy, 24.2), (0, 0, 0), PEDGLOW, major=24, minor=4)

# ═══════════════════════════════════════════════════════ SKY PLANET ══
C("EXPORT_SkyPlanet__Neon")  # far backdrop; in Roblox this may become a Sky/Billboard instead of a mesh
S.sphere("SkyPlanet", 70, (-130, LEN + 520, 190), PLANET, seg=32, rings=16)
S.torus("SkyPlanetBand", 70.5, 3.0, (-130, LEN + 520, 190), (70, 20, 0), PLANET_B, major=48, minor=6)
S.sphere("SkyMoon", 16, (120, LEN + 480, 230), PLANET_B, seg=20, rings=10)

# ═════════════════════════════════════════════════════════ SAVE / RENDER / EXPORT ══
blend_dir = os.path.join(REPO, "art", "blender", "worlds")
os.makedirs(blend_dir, exist_ok=True)
S.bpy.ops.wm.save_as_mainfile(filepath=os.path.join(blend_dir, "03_DragonBall.blend"))
print("SAVED 03_DragonBall.blend")

if DO_RENDER:
    S.setup_render(sky="#7fe0a0", sky_strength=0.8, sky_light=0.5, ambient="#d8ecff", samples=int(os.environ.get("SAE_SAMPLES", "40")))
    S.sun("Sun", (50, 0, 30), strength=3.2, color="#fff4dc")
    S.sun("SkyFill", (70, 0, -150), strength=0.6, color="#b8ffd0")
    for (x, y) in posts:
        S.point(f"LanternLight{x}_{y}", (x, y, 6.8), 350, "#ffb640", radius=0.6)
    S.point("ArchLight", (0, 214, 18), 5000, "#b25cff", radius=3)
    out = os.path.join(REPO, "art", "review_renders", "v02", "03_DragonBall")
    tag = os.environ.get("SAE_TAG", "pass1")
    S.render(os.path.join(out, f"{tag}_gameplay.png"), (0, -14, 9), (0, 120, 7), lens=22)
    S.render(os.path.join(out, f"{tag}_boss.png"), (0, 150, 12), (0, 216, 14), lens=24)
    S.render(os.path.join(out, f"{tag}_overview.png"), (0, -95, 120), (0, 115, 0), lens=24)

if "export" in sys.argv:
    m = S.export_modules(os.path.join(REPO, "art", "exports", "worlds", "03_DragonBall"), "Layout.worldZ0(3)", "DragonBall")
    tot = sum(x["triangles"] for x in m["modules"])
    print("EXPORTED", len(m["modules"]), "modules", tot, "tris", "over limit:", [x["module"] for x in m["modules"] if x["overLimit"]])
