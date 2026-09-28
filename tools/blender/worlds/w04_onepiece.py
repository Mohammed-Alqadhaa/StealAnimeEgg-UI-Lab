"""
World 4 — One Piece / Dressrosa Corrida Colosseum, boss Doflamingo (reference R02 "DRESSROSA" panel)

  blender -b --factory-startup --python tools/blender/worlds/w04_onepiece.py -- <repo_root> [render] [export]

Reference elements reproduced (R02 Dressrosa):
  * warm sandstone colosseum: tiered stands full of spectators on both sides,
    two-storey arcade (round arches) crowning the stands, pennant flags on top
  * straight light-stone path down the arena floor, edged by iron lamp posts with warm lamps
  * big red banners with a white Jolly Roger hanging on the arena wall
  * Doflamingo at the far end on a raised stage in front of a huge pink feather fan (his coat)
  * extra identity: "Birdcage" string cage behind the stage, royal box with pink canopy, flower planters
Gameplay: centre lane |x| < 54 clear and flat; arena wall at |x| = 75 (collides); open entry/exit arches.
"""
import os
import sys
import math
import random

REPO = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
DO_RENDER = "render" in sys.argv
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import sae_bpy as S  # noqa: E402

rng = random.Random(404)
S.reset()

# ── palette (from R02 Dressrosa) ──────────────────────────────────────────────
SAND = S.mat("OP_ArenaStone", "#cdb48a", rough=0.85, roblox="Sandstone")
SAND_D = S.mat("OP_ArenaStoneDark", "#b69c72", rough=0.9, roblox="Sandstone")
PATHS = S.mat("OP_PathStone", "#e3d6b8", rough=0.8, roblox="Limestone")
GROUT = S.mat("OP_Grout", "#7a6a50", rough=0.95, roblox="Sandstone")
WALL = S.mat("OP_Wall", "#c9a878", rough=0.85, roblox="Sandstone")
WALL_D = S.mat("OP_WallShade", "#a8875c", rough=0.85, roblox="Sandstone")
TRIM = S.mat("OP_Trim", "#e8dcc0", rough=0.7, roblox="Limestone")
SEAT = S.mat("OP_Seats", "#b89868", rough=0.9, roblox="Sandstone")
RED = S.mat("OP_BannerRed", "#a8161f", rough=0.8, roblox="Fabric")
WHITE = S.mat("OP_JollyWhite", "#f2efe8", rough=0.6, roblox="SmoothPlastic")
BLACK = S.mat("OP_JollyBlack", "#1b1a1c", rough=0.6, roblox="SmoothPlastic")
IRON = S.mat("OP_Iron", "#2a2724", rough=0.45, metal=0.8, roblox="Metal")
LAMP = S.mat("OP_LampGlow", "#ffc35c", emit="#ffb640", strength=8.0, roblox="Neon")
GOLD = S.mat("OP_Gold", "#d4a23a", rough=0.35, metal=0.9, roblox="Metal")
GOLDGLOW = S.mat("OP_GoldGlow", "#ffd46a", emit="#ffcc55", strength=6.0, roblox="Neon")
PINK = S.mat("OP_Feather", "#ff5fa8", rough=0.8, roblox="Fabric")
PINK_L = S.mat("OP_FeatherLight", "#ff8cc4", rough=0.8, roblox="Fabric")
STAGE = S.mat("OP_Stage", "#8c6b4a", rough=0.7, roblox="Sandstone")
THRONE = S.mat("OP_ThroneRed", "#7d1020", rough=0.6, roblox="Fabric")
STRING = S.mat("OP_String", "#ffe6f2", emit="#ffe6f2", strength=0.8, roblox="Neon", transparency=0.3)
POLE = S.mat("OP_FlagPole", "#4a3a2a", rough=0.6, roblox="Wood")
LEAF = S.mat("OP_Leaf", "#4f9a3a", rough=0.8, roblox="Grass")
FLOWER = S.mat("OP_Flower", "#ffd23c", rough=0.6, roblox="SmoothPlastic")
CROWD = [S.mat(f"OP_Crowd{n}", c, rough=0.8, roblox="SmoothPlastic") for n, c in
         (("Red", "#b8322e"), ("Blue", "#3a5fa8"), ("Yellow", "#d9b23a"), ("White", "#e8e2d6"), ("Green", "#4d8a4a"))]
SKIN = S.mat("OP_CrowdSkin", "#d9a878", rough=0.8, roblox="SmoothPlastic")

HALF, LEN, LANE = 75.0, 230.0, 54.0
EGGS = [(-42, 118), (42, 118), (-26, 158), (26, 158), (0, 184)]
BOSS_Y = 206.0
TIERS = 9  # stand steps
TIER_W, TIER_H = 5.0, 4.0
ST0 = HALF + 3.5  # first seating tier (x)
Y0, Y1 = -30.0, 228.0  # world slot (sae_bpy.WORLD_SLOT_Y): nothing may leave it
YM, YL = (Y0 + Y1) / 2, Y1 - Y0
RB_Y = 100.0  # royal box on the west stand


def C(name):
    return S.use(S.collection(name))


# ══════════════════════════════════════════════════════════ ARENA FLOOR ══
C("EXPORT_Grout__Sandstone")
S.box("Grout", (HALF * 2, YL, 0.4), (0, YM, -0.45), material=GROUT)
for part, (y0, y1) in enumerate([(Y0, 64), (64, 140), (140, Y1)]):
    C(f"EXPORT_Floor{part + 1}__Sandstone")
    for side in (-1, 1):
        x0, x1 = (-HALF, -12.0) if side < 0 else (12.0, HALF)
        for ob in S.slab_floor(f"Arena{part}{side}", x0, x1, y0, y1, 9.0, 0.14, 0.0, 0.8, SAND, rng, jitter=0.18, tilt=0.004, bev=0.1, gap_var=0.08):
            if rng.random() < 0.25:
                ob.data.materials[0] = SAND_D
    C(f"EXPORT_Path{part + 1}__Limestone")  # the light central path (R02 shows a pale stone road)
    S.slab_floor(f"Path{part}", -12.0, 12.0, y0, y1, 6.0, 0.12, 0.03, 0.8, PATHS, rng, jitter=0.05, tilt=0.0, bev=0.08)
C("EXPORT_PathBorder__Sandstone")
for side in (-1, 1):
    S.box(f"PathBorder{side}", (0.9, YL, 0.3), (side * 12.3, YM, 0.08), material=WALL_D)

# ═════════════════════════════════════════════════════════ ARENA WALL ══
C("EXPORT_ArenaWall__Sandstone")
for side in (-1, 1):
    S.box(f"ArenaWall{side}", (3.0, YL, 9), (side * (HALF + 1.5), YM, 4.5), material=WALL, bev=0.15)
    S.box(f"ArenaWallCap{side}", (4.0, YL, 0.8), (side * (HALF + 1.5), YM, 9.2), material=TRIM, bev=0.1)
    for y in range(int(Y0) + 6, int(Y1), 16):
        S.box(f"WallPilaster{side}_{y}", (0.8, 2.2, 9), (side * (HALF - 0.1), y, 4.5), material=TRIM, bev=0.08)

# Jolly Roger banners on the arena wall (face the lane)
BANNERS = [(side, y) for side in (-1, 1) for y in (24, 72, 120, 168)]
C("EXPORT_Banners__Fabric")
for side, y in BANNERS:
    S.banner(f"Banner{side}_{y}", 9, 15, (side * (HALF - 0.4), y, 17.5), (0, 0, -90 * side), RED, rng, torn=False, wave=0.35)
C("EXPORT_BannerRods__Metal")
for side, y in BANNERS:
    S.cyl(f"BannerRod{side}_{y}", 0.2, 10.5, (side * (HALF - 0.4), y, 17.6), (90, 0, 0), IRON, verts=8)
C("EXPORT_JollyRoger__SmoothPlastic")
for side, y in BANNERS:
    fx = side * (HALF - 0.75)  # just in front of the cloth
    S.sphere(f"Skull{side}_{y}", 1.7, (fx, y, 11.8), WHITE, seg=14, rings=8, scale=(0.5, 1, 1))
    S.box(f"Jaw{side}_{y}", (0.8, 2.0, 1.1), (fx, y, 10.2), material=WHITE, bev=0.15)
    for a in (35, -35):
        S.box(f"Bone{side}_{y}_{a}", (0.6, 6.0, 0.7), (fx + side * 0.2, y, 11.0), (a, 0, 0), WHITE, bev=0.2)
    for dy in (-0.6, 0.6):
        S.sphere(f"Eye{side}_{y}_{dy}", 0.42, (fx - side * 0.55, y + dy, 12.1), BLACK, seg=8, rings=6, scale=(0.4, 1, 1))

# ══════════════════════════════════════════════════════════ STANDS ══
# side stands: TIERS steps rising outward from the arena wall
for side in (-1, 1):
    half = "E" if side < 0 else "W"
    C(f"EXPORT_Stands{half}__Sandstone")
    for t in range(TIERS):
        x = side * (ST0 + t * TIER_W + TIER_W / 2)
        top = 9 + (t + 1) * TIER_H
        S.box(f"Tier{half}{t}", (TIER_W, YL, top), (x, YM, top / 2), material=SEAT if t % 2 else WALL)
        S.box(f"TierLip{half}{t}", (0.5, YL, 0.5), (x - side * (TIER_W / 2 - 0.25), YM, top + 0.25), material=TRIM)
# crowd: stylised spectators (body + head) on every tier, sides + back, split per colour by the exporter
PEOPLE = []
for side in (-1, 1):
    for t in range(TIERS):
        x = side * (ST0 + t * TIER_W + TIER_W * 0.55)
        top = 9 + (t + 1) * TIER_H
        y = Y0 + 1.2
        while y < Y1 - 1.2:
            royal = side > 0 and 2 <= t <= 6 and abs(y - RB_Y) < 9
            if rng.random() < 0.72 and not royal:
                PEOPLE.append(("E" if side < 0 else "W", x, y, top))
            y += rng.uniform(1.9, 2.6)
for grp in ("E", "W"):
    C(f"EXPORT_Crowd{grp}__SmoothPlastic")
    for i, (g, x, y, top) in enumerate([p for p in PEOPLE if p[0] == grp]):
        S.box(f"Fan{grp}{i}", (1.1, 1.1, 1.7), (x, y, top + 0.85), (0, 0, rng.uniform(-10, 10)), rng.choice(CROWD))
    C(f"EXPORT_CrowdHeads{grp}__SmoothPlastic")
    for i, (g, x, y, top) in enumerate([p for p in PEOPLE if p[0] == grp]):
        S.box(f"Head{grp}{i}", (0.8, 0.8, 0.8), (x, y, top + 2.15), material=SKIN)
S.use(S.collection("VFX"))
for side in (-1, 1):
    S.empty(f"VFX_CrowdCheer{side}", (side * (ST0 + 20), LEN / 2, 30))["vfx"] = "crowd bob/cheer (client tween) + confetti bursts at boss fight (runtime)"

# ══════════════════════════════════════════════════════════ ARCADE ══
ARC_X = ST0 + TIERS * TIER_W + 1.5
ARC_Z = 9 + TIERS * TIER_H
BAY = 12.0
for side in (-1, 1):
    half = "E" if side < 0 else "W"
    C(f"EXPORT_Arcade{half}__Sandstone")
    nb = int(round((YL - 2.6) / BAY))
    ys = [Y0 + 1.3 + k * (YL - 2.6) / nb for k in range(nb + 1)]
    for storey in range(2):
        z0 = ARC_Z + storey * 13
        for y in ys:
            S.box(f"Pier{half}{storey}_{int(y)}", (3, 2.6, 8), (side * ARC_X, y, z0 + 4), material=WALL)
        for a, b in zip(ys, ys[1:]):
            S.arch(f"Arch{half}{storey}_{int(a)}", (ys[1] - ys[0]) - 2.6, 1.3, 3, (side * ARC_X, (a + b) / 2, z0 + 8), (0, 0, 90), WALL_D, segs=10)
        S.box(f"Cornice{half}{storey}", (3.6, ys[-1] - ys[0] + 2.4, 1.4), (side * ARC_X, (ys[0] + ys[-1]) / 2, z0 + 13.2 - 0.7 + (0 if storey else 0)), material=TRIM)
        # back wall behind the arches (sky only through the upper storey)
        if storey == 0:
            S.box(f"ArcadeBack{half}", (1.2, ys[-1] - ys[0], 12.5), (side * (ARC_X + 1.8), (ys[0] + ys[-1]) / 2, z0 + 6.2), material=WALL_D)
# pennant flags on top of the arcade
C("EXPORT_FlagPoles__Wood")
FLAGS = [(side * ARC_X, y) for side in (-1, 1) for y in range(int(Y0) + 6, int(Y1) - 2, 24)]
for i, (x, y) in enumerate(FLAGS):
    S.cyl(f"FlagPole{i}", 0.22, 9, (x, y, ARC_Z + 26 + 4.5), material=POLE, verts=6)
C("EXPORT_Flags__Fabric")
for i, (x, y) in enumerate(FLAGS):
    S.banner(f"Flag{i}", 3.6, 2.2, (x, y + 1.9, ARC_Z + 34.6), (0, 0, 90), PINK if i % 2 else RED, rng, torn=False, wave=0.3)

# ════════════════════════════════════════════════════════ ROYAL BOX ══
C("EXPORT_RoyalBox__Sandstone")
RBX = ST0 + 4 * TIER_W  # Blender +x = Roblox -x (west stand)
RBZ = 9 + 5 * TIER_H
S.box("RoyalBoxFloor", (12, 16, 1), (RBX, RB_Y, RBZ + 0.5), material=TRIM)
S.box("RoyalBoxFront", (0.8, 16, 3), (RBX - 5.6, RB_Y, RBZ + 2), material=TRIM, bev=0.1)
C("EXPORT_RoyalGold__Metal")
for dy in (-7.2, 7.2):
    S.box(f"RoyalPost{dy}", (1.2, 1.2, 10), (RBX - 5.4, RB_Y + dy, RBZ + 5.5), material=GOLD)
C("EXPORT_RoyalCanopy__Fabric")
S.banner("RoyalCanopy", 17, 6, (RBX - 5.9, RB_Y, RBZ + 10.8), (0, 0, 90), PINK, rng, torn=False, wave=0.5)

# ═══════════════════════════════════════════════════════ LAMP POSTS ══
C("EXPORT_LampPosts__Metal")
posts = [(side * (LANE + 2), y) for side in (-1, 1) for y in range(10, 200, 20)]
for (x, y) in posts:
    S.cyl(f"LampPost{x}_{y}", 0.35, 8, (x, y, 4), material=IRON, verts=8)
    S.cyl(f"LampBase{x}_{y}", 0.9, 0.8, (x, y, 0.4), material=IRON, verts=8)
    S.box(f"LampCage{x}_{y}", (1.6, 1.6, 0.25), (x, y, 10.2), material=IRON)
    S.cyl(f"LampCap{x}_{y}", 1.1, 0.8, (x, y, 10.7), material=IRON, verts=4, r2=0.1)
C("EXPORT_LampGlow__Neon")
for (x, y) in posts:
    S.box(f"LampGlow{x}_{y}", (1.2, 1.2, 1.9), (x, y, 9.0), material=LAMP)
S.use(S.collection("VFX"))
for (x, y) in posts[::2]:
    S.empty(f"VFX_Lamp_{int(x)}_{y}", (x, y, 9))["vfx"] = "warm PointLight (runtime)"

# flower planters (Dressrosa) between lamp posts, outside the lane
C("EXPORT_Planters__Sandstone")
PLANTERS = [(side * (LANE + 7), y) for side in (-1, 1) for y in range(20, 200, 40)]
for (x, y) in PLANTERS:
    S.box(f"Planter{x}_{y}", (4, 8, 1.6), (x, y, 0.8), material=TRIM, bev=0.12)
C("EXPORT_PlanterLeaves__Grass")
for (x, y) in PLANTERS:
    for k in range(5):
        S.sphere(f"Bush{x}_{y}_{k}", 1.3, (x + rng.uniform(-1, 1), y - 3 + k * 1.5, 2.0), LEAF, seg=8, rings=6)
C("EXPORT_PlanterFlowers__SmoothPlastic")
for (x, y) in PLANTERS:
    for k in range(9):
        S.sphere(f"Flower{x}_{y}_{k}", 0.4, (x + rng.uniform(-1.4, 1.4), y + rng.uniform(-3.5, 3.5), 3.0 + rng.uniform(0, 0.5)), FLOWER, seg=6, rings=4)

# ═════════════════════════════════════════════════ DOFLAMINGO STAGE ══
C("EXPORT_Stage__Sandstone")
for s_ in range(3):
    S.box(f"StageStep{s_}", (38 - s_ * 6, 4, 1.0), (0, 194 + s_ * 3, 0.5 + s_), material=TRIM, bev=0.1)
S.box("StageTop", (32, 24, 3), (0, 215, 1.5), material=STAGE, bev=0.2)
S.box("StageTrim", (33, 25, 0.4), (0, 215, 3.1), material=TRIM, bev=0.1)
C("EXPORT_StageGold__Metal")
S.box("StageGoldEdge", (32.4, 0.4, 0.5), (0, 202.8, 2.8), material=GOLD)
C("EXPORT_Throne__Fabric")
S.box("ThroneSeat", (6, 4.5, 2.2), (0, 218, 4.4), material=THRONE, bev=0.4)
S.box("ThroneBack", (6, 1.4, 8), (0, 220.5, 7.5), (-6, 0, 0), THRONE, bev=0.4)
C("EXPORT_ThroneGold__Metal")
for dx in (-3.3, 3.3):
    S.box(f"ThroneArm{dx}", (0.8, 4.5, 1.4), (dx, 218, 5.8), material=GOLD, bev=0.2)
S.sphere("ThroneCrest", 1.2, (0, 221, 12.2), GOLD, seg=10, rings=6)
# giant pink feather fan behind the throne (Doflamingo's coat)
C("EXPORT_FeatherFan__Fabric")
for k in range(21):
    a = -84 + k * (168 / 20)
    rad = math.radians(a)
    L = rng.uniform(15, 20) * (1.0 - abs(a) / 300)
    cx, cz = math.sin(rad) * L * 0.55, 6 + math.cos(rad) * L * 0.55
    ob = S.sphere(f"Feather{k}", 1, (0, 0, 0), PINK if k % 2 else PINK_L, seg=10, rings=8, scale=(2.2, 0.5, L * 0.55))
    ob.location = (cx, 224 + rng.uniform(-0.5, 0.5), cz)
    ob.rotation_euler = (0, rad, 0)
S.use(S.collection("VFX"))
S.empty("VFX_BossStage", (0, BOSS_Y, 3))["vfx"] = "boss anchor + pink string aura (runtime)"
S.empty("VFX_FeatherSway", (0, 224, 10))["vfx"] = "feather fan sway (client CFrame oscillation)"

# Birdcage: glowing strings from a high apex down to a half-ring behind the stage (never across the lane)
C("EXPORT_Birdcage__Neon")
APEX = (0.0, 212.0, 120.0)
for k in range(15):
    a = math.radians(-8 + k * (196 / 14))
    end = (math.cos(a) * 44, 200 + math.sin(a) * 26, 0.0)
    d = [APEX[i] - end[i] for i in range(3)]
    L = math.sqrt(sum(c * c for c in d))
    ax = math.degrees(math.asin(-d[1] / L))
    ay = math.degrees(math.atan2(d[0], d[2]))
    S.cyl(f"String{k}", 0.06, L, tuple((APEX[i] + end[i]) / 2 for i in range(3)), (ax, ay, 0), STRING, verts=5)
# open arcade facade behind the stage: frames the boss, the next world stays visible through the arches
C("EXPORT_StageFacade__Sandstone")
FX = [-24.0, -12.0, 0.0, 12.0, 24.0]
for storey in range(2):
    z0 = storey * 14.0
    for x in FX:
        S.box(f"FacadePier{storey}_{x}", (2.6, 3, 10), (x, 226, z0 + 5), material=WALL, bev=0.1)
    for a, b in zip(FX, FX[1:]):
        S.arch(f"FacadeArch{storey}_{a}", 9.4, 1.4, 3, ((a + b) / 2, 226, z0 + 10), (0, 0, 0), WALL_D, segs=10)
    S.box(f"FacadeCornice{storey}", (52, 3.6, 1.4), (0, 226, z0 + 14.0 - 0.7 + 0.7), material=TRIM)
C("EXPORT_FacadeBanners__Fabric")
for x in (-18.0, 18.0):
    S.banner(f"FacadeBanner{x}", 7, 12, (x, 224.1, 27.6), (0, 0, 0), RED, rng, torn=False, wave=0.25)
C("EXPORT_FacadeFlags__Wood")
for x in FX:
    S.cyl(f"FacadePole{x}", 0.22, 8, (x, 226, 33), material=POLE, verts=6)
C("EXPORT_FacadePennants__Fabric")
for i, x in enumerate(FX):
    S.banner(f"FacadePennant{x}", 3.4, 2.1, (x + 1.8, 226, 36.6), (0, 0, 0), PINK if i % 2 else RED, rng, torn=False, wave=0.3)
S.use(S.collection("VFX"))
S.empty("VFX_Birdcage", APEX)["vfx"] = "string shimmer + slow tighten pulse during boss fight (runtime)"

# ═══════════════════════════════════════════════════ EGG PEDESTALS ══
C("EXPORT_EggPedestals__Limestone")
for i, (ex, ey) in enumerate(EGGS):
    S.cyl(f"Pedestal{i}", 3.2, 1.2, (-ex, ey, 0.6), material=TRIM, verts=16)
    S.cyl(f"PedestalTop{i}", 2.7, 0.4, (-ex, ey, 1.4), material=SAND_D, verts=16)
C("EXPORT_EggPedestalGold__Metal")
for i, (ex, ey) in enumerate(EGGS):
    S.torus(f"PedGold{i}", 3.2, 0.2, (-ex, ey, 1.2), (0, 0, 0), GOLD, major=28, minor=4)
C("EXPORT_EggPedestalGlow__Neon")
for i, (ex, ey) in enumerate(EGGS):
    S.torus(f"PedGlow{i}", 2.3, 0.12, (-ex, ey, 1.62), (0, 0, 0), GOLDGLOW, major=28, minor=4)
S.use(S.collection("VFX"))
for i, (ex, ey) in enumerate(EGGS):
    S.empty(f"VFX_EggNest{i + 1}", (-ex, ey, 1.8))["vfx"] = "golden sparkle + treasure glint (runtime); egg spawn anchor"

# ═════════════════════════════════════════════════════ ENTRY / EXIT ══
C("EXPORT_Gates__Sandstone")
for gy, tag in ((-3.0, "Entry"),):
    for side in (-1, 1):
        S.box(f"{tag}Pier{side}", (8, 6, 34), (side * 49, gy, 17), material=WALL, bev=0.3)
        S.box(f"{tag}PierCap{side}", (9.5, 7, 2), (side * 49, gy, 35), material=TRIM, bev=0.2)
    S.arch(f"{tag}Arch", 90, 5, 6, (0, gy, 34), (0, 0, 0), WALL, segs=24)
C("EXPORT_GateBanners__Fabric")
for side in (-1, 1):
    S.banner(f"GateBanner{side}", 5, 14, (side * 49, -6.2, 31), (0, 0, 0), RED, rng, torn=False, wave=0.3)
# ═════════════════════════════════════════════════════════ SAVE / RENDER / EXPORT ══
blend_dir = os.path.join(REPO, "art", "blender", "worlds")
os.makedirs(blend_dir, exist_ok=True)
S.bpy.ops.wm.save_as_mainfile(filepath=os.path.join(blend_dir, "04_OnePiece.blend"))
print("SAVED 04_OnePiece.blend")

if DO_RENDER:
    S.setup_render(sky="#79b6f2", sky_strength=0.9, samples=int(os.environ.get("SAE_SAMPLES", "40")), sky_light=0.55, ambient="#e6eeff")
    S.sun("Sun", (48, 0, 30), strength=3.4, color="#ffe6c0")
    for (x, y) in posts:
        S.point(f"LampLight{x}_{y}", (x, y, 9), 300, "#ffb640", radius=0.6)
    out = os.path.join(REPO, "art", "review_renders", "v02", "04_OnePiece")
    tag = os.environ.get("SAE_TAG", "pass1")
    S.render(os.path.join(out, f"{tag}_gameplay.png"), (0, -14, 9), (0, 120, 9), lens=22)
    S.render(os.path.join(out, f"{tag}_boss.png"), (0, 150, 12), (0, 216, 14), lens=24)
    S.render(os.path.join(out, f"{tag}_overview.png"), (0, -95, 120), (0, 115, 0), lens=24)

if "export" in sys.argv:
    m = S.export_modules(os.path.join(REPO, "art", "exports", "worlds", "04_OnePiece"), "Layout.worldZ0(4)", "OnePiece")
    tot = sum(x["triangles"] for x in m["modules"])
    print("EXPORTED", len(m["modules"]), "modules", tot, "tris", "over limit:", [x["module"] for x in m["modules"] if x["overLimit"]])
