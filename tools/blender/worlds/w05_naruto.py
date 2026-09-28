"""
World 5 — Naruto / Konoha, boss Madara (reference R02 "KONOHA" panel)

  blender -b --factory-startup --python tools/blender/worlds/w05_naruto.py -- <repo_root> [render] [export]

Reference elements reproduced (R02 Konoha):
  * village main street: stone path, wooden lantern posts with warm lanterns
  * cream-walled wooden houses with red/orange tiled roofs lining both sides, hanging red paper lanterns
  * red banners with the white Leaf-village spiral
  * Hokage Rock: a cliff with carved faces overlooking the far end (kept inside the world slot, off the lane)
  * Madara at the far end on a stone stage under a big Uchiha fan crest, red round tower behind
  * extra identity: Konoha main gate (open) at the entry, Ichiraku-style ramen stand, round green trees
Gameplay: centre lane |x| < 54 clear and flat; house fronts at |x| >= 60 with invisible colliders; open gate.
"""
import os
import sys
import math
import random

REPO = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
DO_RENDER = "render" in sys.argv
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import sae_bpy as S  # noqa: E402

rng = random.Random(505)
S.reset()

# ── palette (from R02 Konoha) ─────────────────────────────────────────────────
PATH = S.mat("NA_PathStone", "#a8a39a", rough=0.85, roblox="Cobblestone")
PATH_D = S.mat("NA_PathStoneDark", "#8f8a82", rough=0.9, roblox="Cobblestone")
DIRT = S.mat("NA_Dirt", "#b79a72", rough=0.95, roblox="Ground")
GROUT = S.mat("NA_Grout", "#5e5448", rough=0.95, roblox="Ground")
PLASTER = S.mat("NA_Plaster", "#efe2c4", rough=0.85, roblox="SmoothPlastic")
TIMBER = S.mat("NA_Timber", "#5a3a22", rough=0.7, roblox="Wood")
ROOF = S.mat("NA_RoofRed", "#b7412c", rough=0.6, roblox="Slate")
ROOF_O = S.mat("NA_RoofOrange", "#c9642e", rough=0.6, roblox="Slate")
ROOF_G = S.mat("NA_RoofGreen", "#4d7a52", rough=0.6, roblox="Slate")
RED = S.mat("NA_BannerRed", "#b3171f", rough=0.8, roblox="Fabric")
WHITE = S.mat("NA_SymbolWhite", "#f3efe6", rough=0.6, roblox="SmoothPlastic")
PAPER = S.mat("NA_PaperLantern", "#e0332b", emit="#ff5a3a", strength=2.5, roblox="Neon")
LANTERN = S.mat("NA_LanternGlow", "#ffc35c", emit="#ffb640", strength=8.0, roblox="Neon")
ROCK = S.mat("NA_HokageRock", "#a98d6c", rough=0.9, roblox="Rock")
ROCK_D = S.mat("NA_HokageRockDark", "#8c7358", rough=0.9, roblox="Rock")
FACE_D = S.mat("NA_FaceShadow", "#5a4838", rough=0.9, roblox="Rock")
TRUNK = S.mat("NA_Trunk", "#6b4a2e", rough=0.8, roblox="Wood")
LEAF = S.mat("NA_Leaf", "#3f8f3a", rough=0.8, roblox="Grass")
LEAF_L = S.mat("NA_LeafLight", "#58a948", rough=0.8, roblox="Grass")
GRASS = S.mat("NA_Grass", "#5aa04a", rough=0.9, roblox="Grass")
STAGE = S.mat("NA_Stage", "#6f6a66", rough=0.8, roblox="Slate")
STAGE_L = S.mat("NA_StageTrim", "#8e8983", rough=0.8, roblox="Slate")
UCHIHA_R = S.mat("NA_UchihaRed", "#c3141f", rough=0.5, roblox="SmoothPlastic")
UCHIHA_W = S.mat("NA_UchihaWhite", "#f2f0ea", rough=0.5, roblox="SmoothPlastic")
TOWER = S.mat("NA_TowerRed", "#b8432f", rough=0.7, roblox="SmoothPlastic")
GATE_G = S.mat("NA_GateGreen", "#3e6b45", rough=0.6, roblox="Wood")
PEDGLOW = S.mat("NA_PedestalGlow", "#ff8a1f", emit="#ff8a1f", strength=6.0, roblox="Neon")
NOREN = S.mat("NA_Noren", "#f3efe6", rough=0.8, roblox="Fabric")

HALF, LEN, LANE = 75.0, 230.0, 54.0
EGGS = [(-42, 118), (42, 118), (-26, 158), (26, 158), (0, 184)]
BOSS_Y = 206.0
Y0, Y1 = -30.0, 228.0  # world slot (sae_bpy.WORLD_SLOT_Y): nothing may leave it
YM, YL = (Y0 + Y1) / 2, Y1 - Y0
FRONT = 60.0  # house fronts


def C(name):
    return S.use(S.collection(name))


def leaf_symbol(name, loc, rotz, s, material):
    """Konoha leaf mark: a spiral ring (open torus) + a leaf-tip triangle, flat, facing -y before rotz."""
    # built flat in the XY plane, joined, then stood up (+90 deg about X) to face -y, then turned by rotz
    parts = [S.torus(f"{name}_ring", 1.0 * s, 0.16 * s, (0, 0, 0), (0, 0, 0), material, major=20, minor=4)]
    parts.append(S.torus(f"{name}_inner", 0.45 * s, 0.14 * s, (0.1 * s, -0.05 * s, 0), (0, 0, 0), material, major=14, minor=4))
    parts.append(S.prism(f"{name}_tip", [(0.7 * s, -0.12 * s), (1.9 * s, 0.9 * s), (0.95 * s, 0.35 * s)], -0.08 * s, 0.08 * s, material))
    ob = S.join(parts, name)
    ob.location = loc
    ob.rotation_euler = (math.radians(90), 0, math.radians(rotz))
    return ob


def gable_roof(name, cx, cy, w, d, z, pitch, overhang, material, along_y=True):
    """Two slanted slabs meeting at a ridge. Ridge runs along y (along_y) or x."""
    run = (w if along_y else d) / 2 + overhang
    slope_len = run / math.cos(math.radians(pitch))
    rise = run * math.tan(math.radians(pitch))
    length = (d if along_y else w) + overhang * 2
    objs = []
    for s_ in (-1, 1):
        if along_y:
            objs.append(S.box(f"{name}_{s_}", (slope_len, length, 0.6), (cx + s_ * run / 2, cy, z + rise / 2), (0, s_ * pitch, 0), material))
        else:
            objs.append(S.box(f"{name}_{s_}", (length, slope_len, 0.6), (cx, cy + s_ * run / 2, z + rise / 2), (-s_ * pitch, 0, 0), material))
    return objs, rise


# ════════════════════════════════════════════════════════════ STREET ══
C("EXPORT_Grout__Ground")
S.box("Grout", (HALF * 2, YL, 0.4), (0, YM, -0.45), material=GROUT)
for part, (y0, y1) in enumerate([(Y0, 64), (64, 140), (140, Y1)]):
    C(f"EXPORT_Street{part + 1}__Cobblestone")
    for ob in S.slab_floor(f"Street{part}", -26.0, 26.0, y0, y1, 4.5, 0.12, 0.02, 0.8, PATH, rng, jitter=0.2, tilt=0.006, bev=0.08, gap_var=0.05):
        if rng.random() < 0.3:
            ob.data.materials[0] = PATH_D
    C(f"EXPORT_Ground{part + 1}__Ground")
    for side in (-1, 1):
        x0, x1 = (-HALF, -26.0) if side < 0 else (26.0, HALF)
        S.slab_floor(f"Dirt{part}{side}", x0, x1, y0, y1, 12.0, 0.05, 0.0, 0.8, DIRT, rng, jitter=0.1, tilt=0.0)
C("EXPORT_StreetCurb__Cobblestone")
for side in (-1, 1):
    S.box(f"Curb{side}", (0.8, YL, 0.35), (side * 26.2, YM, 0.12), material=PATH_D)

# ════════════════════════════════════════════════════════════ HOUSES ══
HOUSES = []
for side in (-1, 1):
    y = 8.0  # houses start inside the village gate (the threshold before it stays open ground)
    while y < Y1 - 10:
        d = min(rng.uniform(14, 22), Y1 - 2 - y)
        if d < 8:
            break
        w = rng.uniform(14, 20)
        storeys = 2 if rng.random() < 0.45 else 1
        HOUSES.append((side, side * (FRONT + w / 2), y + d / 2, w, d, storeys))
        y += d + rng.uniform(3, 7)
# the far-end right side is reserved for the Hokage Rock
HOUSES = [h for h in HOUSES if not (h[0] > 0 and h[2] > 150)]
for half, sgn in (("E", -1), ("W", 1)):
    hs = [h for h in HOUSES if h[0] == sgn]
    C(f"EXPORT_HouseWalls{half}__SmoothPlastic")
    for i, (side, cx, cy, w, d, st) in enumerate(hs):
        H = 8.5 * st
        S.box(f"HouseWall{half}{i}", (w, d, H), (cx, cy, H / 2), material=PLASTER)
    C(f"EXPORT_HouseTimber{half}__Wood")
    for i, (side, cx, cy, w, d, st) in enumerate(hs):
        H = 8.5 * st
        fx = cx - side * w / 2  # street-facing wall
        for dy in (-d / 2 + 0.4, 0.0, d / 2 - 0.4):
            S.box(f"Post{half}{i}_{dy}", (0.7, 0.7, H), (fx - side * 0.2, cy + dy, H / 2), material=TIMBER)
        for z in [8.5 * k for k in range(1, st + 1)]:
            S.box(f"Beam{half}{i}_{z}", (0.7, d, 0.6), (fx - side * 0.2, cy, z - 0.3), material=TIMBER)
        S.box(f"Door{half}{i}", (0.3, 4.2, 6), (fx - side * 0.1, cy - d / 4, 3), material=TIMBER)
        for k in range(st):
            S.box(f"Window{half}{i}_{k}", (0.3, 3.2, 2.4), (fx - side * 0.1, cy + d / 4, 4.2 + 8.5 * k), material=TIMBER)
    C(f"EXPORT_HouseRoofs{half}__Slate")
    for i, (side, cx, cy, w, d, st) in enumerate(hs):
        H = 8.5 * st
        roofmat = rng.choice((ROOF, ROOF, ROOF_O, ROOF_G))
        objs, rise = gable_roof(f"Roof{half}{i}", cx, cy, w, d, H, 28, 1.6, roofmat, along_y=True)
        S.box(f"Ridge{half}{i}", (1.0, d + 3.4, 0.8), (cx, cy, H + rise + 0.2), material=roofmat)
        if st == 2:  # small awning over the ground floor on the street side
            S.box(f"Awning{half}{i}", (3.0, d, 0.4), (cx - side * (w / 2 + 1.3), cy, 8.8), (0, side * 18, 0), roofmat)
    C(f"EXPORT_PaperLanterns{half}__Neon")
    for i, (side, cx, cy, w, d, st) in enumerate(hs):
        fx = cx - side * (w / 2 + 1.2)
        for dy in (-d / 3, d / 3):
            S.sphere(f"PaperLantern{half}{i}_{dy}", 0.7, (fx, cy + dy, 6.6), PAPER, seg=10, rings=6, scale=(1, 1, 1.3))
    for side, cx, cy, w, d, st in hs:
        S.collider(f"HouseCollider{half}{int(cy)}", (w, d, 30), (cx, cy, 15))
S.use(S.collection("VFX"))
S.empty("VFX_PaperLanterns", (0, 100, 7))["vfx"] = "paper lantern sway + soft red glow (runtime)"
for side in (-1, 1):  # boundary behind the houses (gaps between houses are closed)
    S.collider(f"StreetBoundary{side}", (2, YL, 40), (side * (FRONT + 2), YM, 20))

# Leaf-village banners on tall poles between houses (face the street)
C("EXPORT_BannerPoles__Wood")
BANNERS = [(side, y) for side in (-1, 1) for y in (20, 70, 120)] + [(-1, 170), (-1, 215)]
for side, y in BANNERS:
    S.cyl(f"BannerPole{side}_{y}", 0.35, 22, (side * (FRONT - 2.5), y, 11), material=TIMBER, verts=8)
    S.cyl(f"BannerBar{side}_{y}", 0.2, 7.4, (side * (FRONT - 2.5), y, 21), (90, 0, 0), TIMBER, verts=6)
C("EXPORT_Banners__Fabric")
for side, y in BANNERS:
    S.banner(f"Banner{side}_{y}", 7, 13, (side * (FRONT - 2.7), y, 20.8), (0, 0, -90 * side), RED, rng, torn=False, wave=0.3)
C("EXPORT_LeafSymbols__SmoothPlastic")
for side, y in BANNERS:
    leaf_symbol(f"Leaf{side}_{y}", (side * (FRONT - 3.0), y, 14.5), -90 * side, 1.7, WHITE)

# ═══════════════════════════════════════════════════════ LANTERN POSTS ══
C("EXPORT_LanternPosts__Wood")
posts = [(side * (LANE + 1.5), y) for side in (-1, 1) for y in range(8, 200, 24)]
for (x, y) in posts:
    S.box(f"LPost{x}_{y}", (0.9, 0.9, 7), (x, y, 3.5), material=TIMBER)
    S.box(f"LRoof{x}_{y}", (2.4, 2.4, 0.4), (x, y, 8.9), (0, 0, 45), ROOF)
    for dx in (-0.7, 0.7):
        S.box(f"LFrame{x}_{y}_{dx}", (0.2, 1.6, 1.8), (x + dx, y, 7.8), material=TIMBER)
C("EXPORT_LanternGlow__Neon")
for (x, y) in posts:
    S.box(f"LGlow{x}_{y}", (1.2, 1.2, 1.6), (x, y, 7.8), material=LANTERN)
S.use(S.collection("VFX"))
for (x, y) in posts[::2]:
    S.empty(f"VFX_Lantern_{int(x)}_{y}", (x, y, 7.8))["vfx"] = "warm PointLight (runtime)"

# ═════════════════════════════════════════════════════════════ TREES ══
TREES = [(side * rng.uniform(FRONT + 24, 125), rng.uniform(Y0 + 8, Y1 - 8)) for side in (-1, 1) for _ in range(16)]
TREES = [t for t in TREES if not (t[0] > 0 and t[1] > 140)]
C("EXPORT_TreeTrunks__Wood")
for i, (x, y) in enumerate(TREES):
    S.cyl(f"Trunk{i}", 0.9, 12, (x, y, 6), material=TRUNK, verts=8, r2=0.6)
C("EXPORT_TreeCanopy__Grass")
for i, (x, y) in enumerate(TREES):
    r = rng.uniform(5, 7.5)
    S.sphere(f"Canopy{i}", r, (x, y, 12 + r * 0.6), LEAF if i % 2 else LEAF_L, seg=12, rings=8)
    for k in range(2):
        a = rng.uniform(0, 2 * math.pi)
        S.sphere(f"Canopy{i}_{k}", r * 0.65, (x + math.cos(a) * r * 0.7, y + math.sin(a) * r * 0.7, 11 + r * 0.5), LEAF_L, seg=10, rings=6)
C("EXPORT_OuterGrass__Grass")
for side in (-1, 1):
    S.box(f"OuterGrass{side}", (80, YL, 0.4), (side * (FRONT + 40), YM, -0.25), material=GRASS)

# ═══════════════════════════════════════════════════════ HOKAGE ROCK ══
# a cliff at the far end on Blender +x (Roblox -x), faces carved looking down the street
RX0, RY0, RY1 = 64.0, 160.0, 226.0
C("EXPORT_HokageRock__Rock")
z, layer = 0.0, 0
while z < 72:
    lh = rng.uniform(12, 20)
    inset = layer * 2.2
    front = [(RX0 + inset + k * 11 + rng.uniform(-3, 3), RY0 + inset * 0.6 + rng.uniform(0, 4)) for k in range(11)]
    left = [(RX0 + inset + rng.uniform(0, 3), RY1 - 2 - k * (RY1 - RY0) / 4 + rng.uniform(-2, 2)) for k in range(4)]
    # outline in order: jagged front (+x), far corners, back-left corner, then down the left side (-y)
    poly = front + [(RX0 + 118, RY0 + inset), (RX0 + 118, RY1), (RX0 + inset + rng.uniform(0, 3), RY1)] + left[1:]
    S.prism(f"Cliff{layer}", poly, z, min(72, z + lh), ROCK)
    z += lh
    layer += 1
C("EXPORT_HokageRockBoulders__Rock")
for k in range(14):
    bx, by = RX0 + rng.uniform(0, 100), RY0 + rng.uniform(-6, 2)
    S.sphere(f"Boulder{k}", rng.uniform(2.5, 5.5), (bx, by, 1.5), ROCK_D, seg=8, rings=6, scale=(1.2, 0.9, 0.8))
C("EXPORT_HokageTopTrees__Grass")
for k in range(12):
    S.sphere(f"TopTree{k}", rng.uniform(4, 6.5), (RX0 + 14 + k * 8.5 + rng.uniform(-2, 2), RY0 + 26 + rng.uniform(0, 30), 74), LEAF, seg=10, rings=6)
S.use(S.collection("VFX"))
S.empty("VFX_HokageDust", (RX0, RY0, 40))["vfx"] = "drifting leaves + light dust off the cliff (runtime)"
C("EXPORT_HokageFaces__Rock")
FACES = [(RX0 + 16 + k * 19, RY0 + 1.0, 44 + (k % 2) * 3) for k in range(4)]
for k, (fx, fy, fz) in enumerate(FACES):
    S.sphere(f"Head{k}", 7.0, (fx, fy - 1.0, fz), ROCK, seg=16, rings=10, scale=(0.9, 0.55, 1.2))
    S.box(f"Brow{k}", (9.0, 2.0, 1.4), (fx, fy - 4.4, fz + 2.6), material=ROCK_D, bev=0.4)
    S.box(f"Nose{k}", (1.8, 2.4, 3.0), (fx, fy - 4.8, fz - 0.6), material=ROCK, bev=0.5)
    S.box(f"Chin{k}", (5.0, 2.0, 2.0), (fx, fy - 3.6, fz - 6.4), material=ROCK, bev=0.6)
    if k in (0, 2):  # forehead protector plate
        S.box(f"Headband{k}", (10.0, 1.2, 2.2), (fx, fy - 4.2, fz + 5.2), material=ROCK_D, bev=0.3)
C("EXPORT_HokageFaceShadows__Rock")
for k, (fx, fy, fz) in enumerate(FACES):
    for dx in (-2.2, 2.2):
        S.box(f"Eye{k}_{dx}", (2.4, 0.6, 0.9), (fx + dx, fy - 4.9, fz + 1.2), material=FACE_D)
    S.box(f"Mouth{k}", (3.0, 0.5, 0.5), (fx, fy - 4.5, fz - 3.6), material=FACE_D)

# ═════════════════════════════════════════════════════════ MADARA STAGE ══
C("EXPORT_Stage__Slate")
for s_ in range(3):
    S.box(f"StageStep{s_}", (36 - s_ * 6, 4, 1.0), (0, 194 + s_ * 3, 0.5 + s_), material=STAGE_L, bev=0.1)
S.box("StageTop", (30, 22, 3), (0, 214, 1.5), material=STAGE, bev=0.2)
for side in (-1, 1):
    S.box(f"CrestPost{side}", (2.2, 2.2, 36), (side * 13, 220, 18), material=TIMBER)
S.box("CrestBeam", (30, 2.2, 2.0), (0, 220, 35.2), material=TIMBER)
C("EXPORT_CrestRoof__Slate")
gable_roof("CrestRoof", 0, 220, 34, 4.5, 36.2, 22, 1.2, ROOF, along_y=False)
# Uchiha fan crest hanging under the beam (high: the lane below stays open to the next world)
C("EXPORT_UchihaFanRed__SmoothPlastic")
top = [(math.cos(math.pi * k / 20) * 7.5, math.sin(math.pi * k / 20) * 7.5) for k in range(21)]
fan = S.prism("FanTop", top, -0.3, 0.3, UCHIHA_R)
fan.rotation_euler = (math.radians(90), 0, 0)
fan.location = (0, 219, 24)
S.box("FanHandle", (1.4, 0.6, 6.0), (0, 219, 18.6), material=UCHIHA_R)
C("EXPORT_UchihaFanWhite__SmoothPlastic")
bot = [(math.cos(math.pi + math.pi * k / 20) * 7.5, math.sin(math.pi + math.pi * k / 20) * 7.5) for k in range(21)]
fw = S.prism("FanBottom", bot, -0.3, 0.3, UCHIHA_W)
fw.rotation_euler = (math.radians(90), 0, 0)
fw.location = (0, 219, 24)
C("EXPORT_CrestRopes__Wood")
for dx in (-5, 5):
    S.cyl(f"CrestRope{dx}", 0.12, 4.0, (dx, 219, 33.0), material=TIMBER, verts=5)
# red round tower (Hokage residence silhouette) behind-left of the stage, inside the slot
C("EXPORT_Tower__SmoothPlastic")
S.cyl("TowerBody", 13, 26, (-36, 209, 13), material=TOWER, verts=28)
S.cyl("TowerBand", 13.4, 1.2, (-36, 209, 18), material=WHITE, verts=28)
C("EXPORT_TowerRoof__Slate")
S.cyl("TowerRoof", 15, 5, (-36, 209, 28.5), material=ROOF, verts=28, r2=9)
S.cyl("TowerTop", 9, 2.5, (-36, 209, 32.2), material=ROOF_O, verts=28, r2=4)
S.use(S.collection("VFX"))
S.empty("VFX_BossStage", (0, BOSS_Y, 3))["vfx"] = "boss anchor + dark chakra / Susanoo-blue aura (runtime)"
S.empty("VFX_UchihaCrest", (0, 219, 24))["vfx"] = "crest pulse + falling leaves (runtime)"

# ════════════════════════════════════════════════════════ RAMEN STAND ══
RX, RY = -(LANE + 3.5), 88.0  # Blender -x = Roblox +x
C("EXPORT_RamenStand__Wood")
S.box("RamenCounter", (3, 14, 3.4), (RX, RY, 1.7), material=TIMBER)
S.box("RamenBack", (1, 14, 9), (RX - 4.5, RY, 4.5), material=TIMBER)
for dy in (-6.8, 6.8):
    S.box(f"RamenPost{dy}", (0.6, 0.6, 9), (RX + 1.2, RY + dy, 4.5), material=TIMBER)
for k in range(4):
    S.cyl(f"RamenStool{k}", 0.8, 2.2, (RX + 3.2, RY - 4.5 + k * 3, 1.1), material=TIMBER, verts=10)
C("EXPORT_RamenRoof__Slate")
S.box("RamenRoof", (7, 16, 0.5), (RX - 1.5, RY, 9.3), (0, -12, 0), ROOF)
C("EXPORT_RamenNoren__Fabric")
for k in range(5):
    S.box(f"Noren{k}", (0.1, 2.5, 2.4), (RX + 1.3, RY - 5.4 + k * 2.7, 7.6), material=NOREN)

# ═════════════════════════════════════════════════════ EGG PEDESTALS ══
C("EXPORT_EggPedestals__Slate")
for i, (ex, ey) in enumerate(EGGS):
    S.cyl(f"Pedestal{i}", 3.2, 1.2, (-ex, ey, 0.6), material=STAGE_L, verts=8)
    S.cyl(f"PedestalTop{i}", 2.6, 0.4, (-ex, ey, 1.4), material=STAGE, verts=8)
C("EXPORT_EggPedestalGlow__Neon")
for i, (ex, ey) in enumerate(EGGS):
    S.torus(f"PedGlow{i}", 2.3, 0.14, (-ex, ey, 1.62), (0, 0, 0), PEDGLOW, major=28, minor=4)
S.use(S.collection("VFX"))
for i, (ex, ey) in enumerate(EGGS):
    S.empty(f"VFX_EggNest{i + 1}", (-ex, ey, 1.8))["vfx"] = "orange chakra swirl + leaves (runtime); egg spawn anchor"

# ═══════════════════════════════════════════════════════ KONOHA GATE ══
C("EXPORT_Gate__Wood")
GY = -4.0
for side in (-1, 1):  # opening spans the whole 108-stud lane; the open door leaves rest outside it
    S.box(f"GatePillar{side}", (4, 4, 30), (side * 57, GY, 15), material=GATE_G)
    S.box(f"GateDoor{side}", (1.2, 20, 26), (side * 63, GY + 11, 13), material=GATE_G)
S.box("GateLintel", (122, 4.4, 3), (0, GY, 30.5), material=GATE_G)
C("EXPORT_GateRoof__Slate")
gable_roof("GateRoof", 0, GY, 128, 7, 32.0, 20, 1.5, ROOF_G, along_y=False)
C("EXPORT_GateMarks__SmoothPlastic")
for side in (-1, 1):
    S.box(f"GateKanjiPlate{side}", (0.3, 8, 8), (side * 62.3, GY + 11, 16), material=WHITE)
leaf_symbol("GateLeaf", (0, GY - 2.3, 26.0), 0, 1.6, WHITE)
for side in (-1, 1):
    S.collider(f"GateWall{side}", (16, 4, 30), (side * 67, GY, 15))

# ═════════════════════════════════════════════════════════ SAVE / RENDER / EXPORT ══
blend_dir = os.path.join(REPO, "art", "blender", "worlds")
os.makedirs(blend_dir, exist_ok=True)
S.bpy.ops.wm.save_as_mainfile(filepath=os.path.join(blend_dir, "05_Naruto.blend"))
print("SAVED 05_Naruto.blend")

if DO_RENDER:
    S.setup_render(sky="#86c3f5", sky_strength=0.9, samples=int(os.environ.get("SAE_SAMPLES", "40")), sky_light=0.55, ambient="#e8f0ff")
    S.sun("Sun", (52, 0, 35), strength=3.3, color="#fff0d8")
    for (x, y) in posts:
        S.point(f"LanternLight{x}_{y}", (x, y, 7.8), 250, "#ffb640", radius=0.6)
    out = os.path.join(REPO, "art", "review_renders", "v02", "05_Naruto")
    tag = os.environ.get("SAE_TAG", "pass1")
    S.render(os.path.join(out, f"{tag}_gameplay.png"), (0, -14, 9), (0, 120, 9), lens=22)
    S.render(os.path.join(out, f"{tag}_boss.png"), (0, 150, 12), (0, 216, 16), lens=24)
    S.render(os.path.join(out, f"{tag}_overview.png"), (0, -95, 120), (0, 115, 0), lens=24)

if "export" in sys.argv:
    m = S.export_modules(os.path.join(REPO, "art", "exports", "worlds", "05_Naruto"), "Layout.worldZ0(5)", "Naruto")
    tot = sum(x["triangles"] for x in m["modules"])
    print("EXPORTED", len(m["modules"]), "modules", tot, "tris", "over limit:", [x["module"] for x in m["modules"] if x["overLimit"]],
          "outside slot:", [x["module"] for x in m["modules"] if x["outsideSlot"]])
