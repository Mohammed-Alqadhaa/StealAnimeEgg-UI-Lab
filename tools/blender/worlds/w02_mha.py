"""
World 2 — My Hero Academia / Shigaraki (reference R01_MHA_Shigaraki_world.png)

  blender -b --factory-startup --python tools/blender/worlds/w02_mha.py -- <repo_root> [render]

Reference elements reproduced (R01):
  * irregular cracked stone flagstones with purple light glowing through every gap
  * circular plaza with a white hand emblem; three-step dais to the throne
  * Shigaraki throne: fan of jagged tilted stone slabs, many white "decay" hands, red cloak drape
  * spiky black-crystal egg nests with purple glow cores (5 egg spawns, Layout.EGG_OFFSETS)
  * lane edged by stone posts with warm lanterns linked by hanging chains
  * LEFT: League-of-Villains bar (counter, stools, bottle shelves, purple neon strip)
  * RIGHT: lounge (red sofas, low tables, candles)
  * tall ruined stone pillars with framed purple-hand posters and torn red hand banners
  * heavy chains running from the pillars to the throne
  * ruined block walls + a purple city skyline with lit windows and an elevated bridge
Gameplay: centre lane |x| < 54 kept clear; walls at |x| = 75; world length 230; open exit gate.
"""
import os
import sys
import math
import random

REPO = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
DO_RENDER = "render" in sys.argv
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import sae_bpy as S  # noqa: E402

rng = random.Random(202)
S.reset()

# ── palette (from R01) ────────────────────────────────────────────────────────
STONE = S.mat("MHA_Stone", "#6c6279", rough=0.85, roblox="Slate")
STONE_D = S.mat("MHA_StoneDark", "#4a4058", rough=0.9, roblox="Slate")
STONE_L = S.mat("MHA_StoneLight", "#8d8398", rough=0.8, roblox="Slate")
CRACK = S.mat("MHA_CrackGlow", "#a24dff", emit="#b25cff", strength=9.0, roblox="Neon")
CRACKBED = S.mat("MHA_CrackBed", "#140c24", rough=0.95, roblox="Slate")
CRYSTAL = S.mat("MHA_Obsidian", "#150d22", rough=0.15, metal=0.2, roblox="Glass")
CORE = S.mat("MHA_EggCore", "#c07aff", emit="#c07aff", strength=6.0, roblox="Neon")
HANDW = S.mat("MHA_HandWhite", "#e7e0d6", rough=0.6, roblox="SmoothPlastic")
RED = S.mat("MHA_BannerRed", "#9b1422", rough=0.8, roblox="Fabric")
CLOAK = S.mat("MHA_CloakRed", "#7c0f1c", rough=0.8, roblox="Fabric")
IRON = S.mat("MHA_Iron", "#29242f", rough=0.45, metal=0.8, roblox="Metal")
WOOD = S.mat("MHA_BarWood", "#4b2c22", rough=0.6, roblox="WoodPlanks")
WOOD_L = S.mat("MHA_BarTop", "#7a4a2a", rough=0.5, roblox="Wood")
NEON = S.mat("MHA_Neon", "#b366ff", emit="#b366ff", strength=12.0, roblox="Neon")
BOTTLE = S.mat("MHA_Bottle", "#d9a6ff", emit="#c78bff", strength=3.0, roblox="Neon")
SOFA = S.mat("MHA_Sofa", "#8a1b26", rough=0.7, roblox="Fabric")
LANTERN = S.mat("MHA_LanternGlow", "#ffb24d", emit="#ffab40", strength=10.0, roblox="Neon")
POSTER = S.mat("MHA_Poster", "#241a38", rough=0.7, roblox="SmoothPlastic")
POSTERHAND = S.mat("MHA_PosterHand", "#a466ff", emit="#a466ff", strength=5.0, roblox="Neon")
CITY = S.mat("MHA_City", "#1b1236", rough=0.9, roblox="SmoothPlastic")
CITY_FAR = S.mat("MHA_CityFar", "#3a2a72", rough=0.9, roblox="SmoothPlastic")
WINDOW = S.mat("MHA_Windows", "#9d7ae0", emit="#a47cff", strength=1.8, roblox="Neon")
INLAY = S.mat("MHA_Inlay", "#d9d2cc", rough=0.7, roblox="SmoothPlastic")

HALF, LEN, LANE = 75.0, 230.0, 54.0
EGGS = [(-42, 118), (42, 118), (-26, 158), (26, 158), (0, 184)]  # Roblox x → Blender x = -x (symmetric)
BOSS_Y = 206.0
Y0, Y1 = -30.0, 228.0  # world slot (sae_bpy.WORLD_SLOT_Y): nothing may leave it
PLAZA = (0.0, 168.0, 36.0)


def C(name):
    return S.use(S.collection(name))


# ═══════════════════════════════════════════════════════════════ FLOOR ══
# glowing crack plane under everything (visible only through slab gaps)
C("EXPORT_CrackBed__Slate")
S.box("CrackBed", (HALF * 2, Y1 - Y0, 0.2), (0, (Y0 + Y1) / 2, -0.55), material=CRACKBED)
C("EXPORT_CrackGlow__Neon")
# glow veins: irregular emissive patches just above the dark bed, visible only through gaps.
# Concentrated around the plaza, egg nests, throne and wall bases (R01 lighting language).
glow_centres = [(PLAZA[0], PLAZA[1], 30, 16)] + [(-ex, ey, 9, 4) for ex, ey in EGGS] + [(0, 205, 22, 6)]
glow_centres += [(rng.choice((-1, 1)) * rng.uniform(20, 72), rng.uniform(0, LEN), rng.uniform(5, 11), 1) for _ in range(34)]
k = 0
for (gx, gy, gr, n) in glow_centres:
    for _ in range(n):
        r = rng.uniform(gr * 0.35, gr * 0.8)
        ang = rng.uniform(0, 2 * math.pi)
        d = rng.uniform(0, gr * 0.7)
        cx, cy = gx + math.cos(ang) * d, gy + math.sin(ang) * d
        poly = [(cx + math.cos(2 * math.pi * s / 7) * r * rng.uniform(0.55, 1.0), cy + math.sin(2 * math.pi * s / 7) * r * rng.uniform(0.55, 1.0)) for s in range(7)]
        poly = [(x, min(max(y, Y0 + 0.2), Y1 - 0.2)) for (x, y) in poly]
        S.prism(f"GlowVein{k}", poly, -0.34, -0.28, CRACK)
        k += 1


def in_plaza(x, y):
    return math.hypot(x - PLAZA[0], y - PLAZA[1]) < PLAZA[2] + 1.5


def glow_weight(x, y):
    return max((1.0 - math.hypot(x - gx, y - gy) / (gr * 1.1)) for (gx, gy, gr, n) in glow_centres)


def edge_raise(x, y):
    # broken, heaved slabs outside the lane only (the centre lane stays flat and readable)
    return abs(x) > LANE + 2 and rng.random() < 0.55


for part, (y0, y1) in enumerate([(Y0, 60), (60, 135), (135, Y1)]):
    C(f"EXPORT_Floor{part + 1}__Slate")
    for ob in S.slab_floor(f"Slab{part}", -HALF, HALF, y0, y1, 8.0, 0.22, 0.0, 1.0, STONE, rng, jitter=0.36, tilt=0.018, raise_edge=edge_raise, bev=0.14, gap_var=0.3):
        # carve the plaza out of the regular flagstones (plaza has its own rings)
        cx = sum(v.co.x for v in ob.data.vertices) / len(ob.data.vertices)
        cy = sum(v.co.y for v in ob.data.vertices) / len(ob.data.vertices)
        if in_plaza(cx, cy):
            S.bpy.data.objects.remove(ob, do_unlink=True)
        else:
            w = glow_weight(cx, cy)
            if w > 0:  # broken slabs pulled apart: wider glowing cracks near glow sources
                f = 1.0 - min(0.2, 0.08 + 0.2 * w)
                for v in ob.data.vertices:
                    v.co.x = cx + (v.co.x - cx) * f
                    v.co.y = cy + (v.co.y - cy) * f
            if rng.random() < 0.18:
                ob.data.materials[0] = STONE_D

# ═════════════════════════════════════════════════════════════ PLAZA ══
C("EXPORT_Plaza__Slate")
px, py, pr = PLAZA
rings = [(pr, pr - 7.5, 0.05), (pr - 7.8, pr - 16, 0.08), (pr - 16.3, 0.0, 0.1)]
for ri, (ro, rin, h) in enumerate(rings):
    segs = 28 if ri < 2 else 1
    for k in range(segs):
        a0, a1 = 2 * math.pi * k / segs, 2 * math.pi * (k + 1) / segs
        if rin > 0:
            poly = []
            steps = 4
            for s in range(steps + 1):
                a = a0 + (a1 - a0) * s / steps
                poly.append((px + math.cos(a) * (ro - 0.15), py + math.sin(a) * (ro - 0.15)))
            for s in range(steps, -1, -1):
                a = a0 + (a1 - a0) * s / steps
                poly.append((px + math.cos(a) * (rin + 0.15), py + math.sin(a) * (rin + 0.15)))
        else:
            poly = [(px + math.cos(2 * math.pi * s / 32) * ro, py + math.sin(2 * math.pi * s / 32) * ro) for s in range(32)]
        ob = S.prism(f"PlazaRing{ri}_{k}", poly, -0.9, h + rng.uniform(-0.03, 0.03), STONE_L if ri == 1 else STONE)
# white hand emblem inlaid in front of the boss egg + thin ring lines
C("EXPORT_PlazaInlay__SmoothPlastic")
emb = S.hand("HandEmblem", (0, 160.5, 0.14), (-90, 0, 180), 3.2, INLAY)
emb.scale = (1, 1, 0.08)
for r in (pr - 7.65, pr - 16.15):
    S.torus(f"InlayRing{int(r)}", r, 0.18, (px, py, 0.1), (0, 0, 0), INLAY, major=64, minor=4, scale=(1, 1, 0.4))

# ═════════════════════════════════════════════════════════════ THRONE ══
C("EXPORT_Throne__Slate")
for s in range(3):  # dais steps
    S.box(f"Dais{s}", (44 - s * 8, 5.0, 1.2), (0, 196 + s * 3.2, 0.6 + s * 1.2), material=STONE_L, bev=0.12)
S.box("DaisTop", (30, 16, 3.6), (0, 211, 1.8), material=STONE, bev=0.15)
# jagged fan of tilted slabs
for k in range(23):
    a = -82 + k * (164 / 22)
    rad = math.radians(a)
    h = rng.uniform(22, 38) * (1.0 - abs(a) / 200)
    w = rng.uniform(4.2, 7.0)
    x = math.sin(rad) * 21
    y = 216.5 + math.cos(rad) * 7
    S.box(f"ThroneSlab{k}", (w, rng.uniform(1.6, 2.6), h), (x, y, h / 2 + 2), (rng.uniform(-10, -2), math.degrees(rad) * 0.55 + rng.uniform(-6, 6), rng.uniform(-8, 8)), STONE if k % 3 else STONE_D, bev=0.25)
for k in range(10):  # rubble at the throne base
    S.box(f"ThroneRubble{k}", (rng.uniform(2, 4), rng.uniform(2, 4), rng.uniform(1.2, 2.6)), (rng.uniform(-18, 18), rng.uniform(203, 214), 3.6), (rng.uniform(-20, 20), rng.uniform(-20, 20), rng.uniform(0, 90)), STONE_D, bev=0.2)
S.box("ThroneSeat", (12, 6.5, 2.6), (0, 212.5, 4.9), material=STONE_D, bev=0.3)
S.box("ThroneBack", (12, 2.0, 12), (0, 216, 11), (-8, 0, 0), STONE_D, bev=0.3)
C("EXPORT_ThroneHands__SmoothPlastic")
for k in range(16):
    a = -72 + k * (144 / 15)
    rad = math.radians(a)
    rr = rng.uniform(12, 21)
    z = rng.uniform(11, 30)
    hx, hy = math.sin(rad) * rr, 212 + math.cos(rad) * 3
    hs = rng.uniform(2.2, 3.2)
    S.hand(f"ThroneHand{k}", (hx, hy, z), (rng.uniform(-15, 15), -a * 0.6, rng.uniform(-20, 20)), hs, HANDW)
    # decayed forearm reaching up from behind the slab fan (hands never float)
    p0 = (hx, hy, z - hs * 0.9)
    p1 = (hx * 0.85, hy + 7, 2.0)
    d = [p0[i] - p1[i] for i in range(3)]
    L = math.sqrt(sum(c * c for c in d))
    ax = math.degrees(math.asin(-d[1] / L))
    ay = math.degrees(math.atan2(d[0], d[2]))
    S.cyl(f"ThroneArm{k}", hs * 0.28, L, tuple((p0[i] + p1[i]) / 2 for i in range(3)), (ax, ay, 0), HANDW, verts=8, r2=hs * 0.36)
C("EXPORT_ThroneCloak__Fabric")
S.banner("ThroneCloak", 13, 14, (0, 216.4, 16.5), (-14, 0, 0), CLOAK, rng, torn=True, wave=1.1)
S.banner("ThroneCloakSeat", 12, 6.5, (0, 212.6, 6.4), (-80, 0, 0), CLOAK, rng, torn=True, wave=0.6)
for side in (-1, 1):
    S.banner(f"ThroneCloakSide{side}", 5.0, 9.0, (side * 7.2, 213.5, 11.0), (-6, 0, side * 70), CLOAK, rng, torn=True, wave=0.7)
S.use(S.collection("VFX"))
for n, loc in (("VFX_ThroneAura", (0, 212, 9)), ("VFX_BossStage", (0, BOSS_Y, 4))):
    e = S.empty(n, loc)
    e["vfx"] = "decay purple aura + dust (runtime)"

# ═══════════════════════════════════════════════════════════ EGG NESTS ══
C("EXPORT_EggNests__Glass")
for i, (ex, ey) in enumerate(EGGS):
    bx = -ex
    for k in range(11):
        a = 2 * math.pi * k / 11 + rng.uniform(-0.1, 0.1)
        r = 3.7 + rng.uniform(-0.3, 0.3)
        h = rng.uniform(3.2, 5.6)
        S.cyl(f"Nest{i}_{k}", 1.0, h, (bx + math.cos(a) * r, ey + math.sin(a) * r, h / 2 - 0.2), (math.cos(a) * 32, -math.sin(a) * 0 + 0, 0) if False else (math.degrees(math.sin(a)) * 0.55, -math.degrees(math.cos(a)) * 0.55, 0), CRYSTAL, verts=5, r2=0.02)
    S.cyl(f"NestBase{i}", 3.6, 0.6, (bx, ey, 0.3), material=CRYSTAL, verts=10)
C("EXPORT_EggNestGlow__Neon")
for i, (ex, ey) in enumerate(EGGS):
    S.torus(f"NestGlowRing{i}", 3.9, 0.22, (-ex, ey, 0.25), (0, 0, 0), CORE, major=28, minor=5)
S.use(S.collection("VFX"))
for i, (ex, ey) in enumerate(EGGS):
    e = S.empty(f"VFX_EggNest{i + 1}", (-ex, ey, 1.2))
    e["vfx"] = "purple swirl + rising motes (runtime); egg spawn anchor"

# ══════════════════════════════════════════════ LANE LANTERN POSTS + CHAINS ══
C("EXPORT_LanternPosts__Slate")
posts = []
for side in (-1, 1):
    for y in range(12, 200, 26):
        x = side * (LANE + 1.5)
        S.box(f"Post{side}_{y}", (2.6, 2.6, 4.2), (x, y, 2.1), (0, 0, rng.uniform(-4, 4)), STONE, bev=0.18)
        posts.append((x, y))
C("EXPORT_LanternFrames__Metal")
for (x, y) in posts:
    for dx in (-0.7, 0.7):
        for dy in (-0.7, 0.7):
            S.box(f"LanFrame{x}_{y}_{dx}_{dy}", (0.16, 0.16, 1.9), (x + dx, y + dy, 5.15), material=IRON)
    S.box(f"LanRoof{x}_{y}", (1.9, 1.9, 0.25), (x, y, 6.2), material=IRON, bev=0.05)
C("EXPORT_LanternGlow__Neon")
for (x, y) in posts:
    S.box(f"LanGlow{x}_{y}", (1.2, 1.2, 1.6), (x, y, 5.15), material=LANTERN)
S.use(S.collection("VFX"))
for (x, y) in posts[::3]:
    e = S.empty(f"VFX_Lantern_{int(x)}_{y}", (x, y, 5.2))
    e["vfx"] = "warm PointLight + subtle flicker (runtime)"
for side in (-1, 1):  # one module per side keeps each under the 20k-triangle MeshPart limit
    C(f"EXPORT_Chains{'E' if side < 0 else 'W'}__Metal")
    ys = [p[1] for p in posts if p[0] * side > 0]
    for a, b in zip(ys, ys[1:]):
        S.chain(f"LaneChain{side}_{a}", (side * (LANE + 1.5), a + 1.2, 3.6), (side * (LANE + 1.5), b - 1.2, 3.6), 1.6, 0.9, IRON)

# ═══════════════════════════════════════════════════════ RUINED WALLS ══
for side in (-1, 1):
    C(f"EXPORT_Walls{'E' if side < 0 else 'W'}__Slate")
    y = Y0
    while y < Y1 - 0.5:
        w = min(rng.uniform(6, 11), Y1 - y)
        h = rng.uniform(15, 25)
        S.box(f"WallBlock{side}_{int(y)}", (4.5, w, h), (side * (HALF + 2.2), y + w / 2, h / 2), (0, rng.uniform(-2, 2), 0), STONE_D if rng.random() < 0.5 else STONE, bev=0.3)
        # broken crown blocks
        for k in range(rng.randint(1, 3)):
            cs = rng.uniform(1.8, 3.2)
            S.box(f"WallCrown{side}_{int(y)}_{k}", (cs, cs, cs), (side * (HALF + 2.2 + rng.uniform(-1, 1)), min(Y1 - cs, max(Y0 + cs, y + rng.uniform(0, w))), h + cs * 0.4), (rng.uniform(-20, 20), rng.uniform(-20, 20), rng.uniform(0, 90)), STONE, bev=0.2)
        y += w
C("EXPORT_WallCracks__Neon")
for side in (-1, 1):
    for k in range(26):
        y = rng.uniform(0, LEN)
        z = rng.uniform(2, 14)
        S.box(f"WallCrack{side}_{k}", (0.15, rng.uniform(0.15, 0.3), rng.uniform(2.5, 6)), (side * (HALF - 0.05), y, z), (rng.uniform(-35, 35), 0, 0), CRACK)

# ═══════════════════════════════════════════════════════════ PILLARS ══
C("EXPORT_Pillars__Slate")
PILLARS = [(side * 66, y) for side in (-1, 1) for y in (36, 124, 196)]
for (x, y) in PILLARS:
    S.box(f"Pillar{x}_{y}", (6, 6, 36), (x, y, 18), (0, 0, rng.uniform(-3, 3)), STONE, bev=0.35)
    S.box(f"PillarCap{x}_{y}", (7.4, 7.4, 2), (x, y, 36.6), material=STONE_L, bev=0.25)
    S.box(f"PillarFoot{x}_{y}", (7.6, 7.6, 2.2), (x, y, 1.1), material=STONE_L, bev=0.25)
C("EXPORT_PillarCracks__Neon")
for (x, y) in PILLARS:
    for k in range(4):
        S.box(f"PillarCrack{x}_{y}_{k}", (0.12, 0.2, rng.uniform(3, 7)), (x - math.copysign(3.02, x), y + rng.uniform(-2, 2), rng.uniform(6, 30)), (rng.uniform(-30, 30), 0, 0), CRACK)

# chains from the throne-side pillars toward the throne (R01)
C("EXPORT_ThroneChains__Metal")
for side in (-1, 1):
    S.chain(f"ThroneChain{side}", (side * 63, 196, 33), (side * 14, 216, 20), 5.5, 1.6, IRON)
    S.chain(f"CrossChain{side}", (side * 63, 124, 30), (side * 63, 196, 30), 7.0, 1.6, IRON)

# tall banner posts behind the throne (R01: two big torn red banners flank Shigaraki)
C("EXPORT_BannerPosts__Slate")
for side in (-1, 1):
    S.box(f"BannerPost{side}", (4.5, 4.5, 50), (side * 30, 224.5, 25), material=STONE, bev=0.3)
    S.box(f"BannerPostCap{side}", (5.6, 5.6, 1.8), (side * 30, 224.5, 50.6), material=STONE_L, bev=0.2)
C("EXPORT_BannerBeam__Metal")
S.box("BannerBeam", (70, 1.4, 1.4), (0, 223, 47), material=IRON)
C("EXPORT_BigBanners__Fabric")
for side in (-1, 1):
    S.banner(f"BigBanner{side}", 11, 30, (side * 20, 222.2, 46), (0, 0, 0), RED, rng, torn=True, wave=0.8)
C("EXPORT_BigBannerHands__SmoothPlastic")
for side in (-1, 1):
    S.hand(f"BigBannerHand{side}", (side * 20, 221.6, 35), (0, 0, 0), 3.4, HANDW)

# torn red banners with a white hand (R01)
C("EXPORT_Banners__Fabric")
for side in (-1, 1):
    S.banner(f"Banner{side}", 7.5, 20, (side * 61.8, 196, 34), (0, 0, 90 * side), RED, rng, torn=True, wave=0.5)
C("EXPORT_BannerHands__SmoothPlastic")
for side in (-1, 1):
    S.hand(f"BannerHand{side}", (side * 61.5, 196, 25), (0, 0, 90 * side if side > 0 else -90), 2.1, HANDW)

# ══════════════════════════════════════════════════ LEFT: VILLAIN BAR ══
BX = -64.0  # Blender -x = Roblox +x = camera-left
C("EXPORT_Bar__WoodPlanks")
S.box("BarCounter", (3.2, 30, 3.6), (BX + 6, 88, 1.8), material=WOOD, bev=0.12)
S.box("BarBackWall", (1.2, 36, 14), (BX - 7, 88, 7), material=WOOD)
for k, z in enumerate((4.5, 7.8, 11.1)):
    S.box(f"BarShelf{k}", (2.2, 30, 0.35), (BX - 5.8, 88, z), material=WOOD_L)
C("EXPORT_BarTop__Wood")
S.box("BarCounterTop", (4.0, 31, 0.4), (BX + 6, 88, 3.8), material=WOOD_L, bev=0.08)
C("EXPORT_BarStools__Metal")
for k in range(6):
    y = 76 + k * 4.8
    S.cyl(f"StoolLeg{k}", 0.18, 2.4, (BX + 9.6, y, 1.2), material=IRON, verts=8)
C("EXPORT_BarStoolSeats__Fabric")
for k in range(6):
    S.cyl(f"StoolSeat{k}", 0.95, 0.45, (BX + 9.6, 76 + k * 4.8, 2.55), material=SOFA, verts=12)
C("EXPORT_BarBottles__Neon")
for z in (4.5, 7.8, 11.1):
    for k in range(13):
        y = 75 + k * 2.1 + rng.uniform(-0.3, 0.3)
        h = rng.uniform(1.0, 1.6)
        S.cyl(f"Bottle{z}_{k}", 0.3, h, (BX - 5.8, y, z + 0.2 + h / 2), material=BOTTLE, verts=8, r2=0.18)
C("EXPORT_BarNeon__Neon")
S.box("BarNeonTop", (0.3, 34, 0.35), (BX - 6.2, 88, 13.4), material=NEON)
S.box("BarNeonCounter", (0.25, 30, 0.25), (BX + 7.7, 88, 3.2), material=NEON)
S.use(S.collection("VFX"))
e = S.empty("VFX_BarNeonFlicker", (BX - 6, 88, 13))
e["vfx"] = "neon flicker + cigarette smoke haze (runtime)"

# ════════════════════════════════════════════════════ RIGHT: LOUNGE ══
LX = 64.0
C("EXPORT_Lounge__Fabric")
for k, y in enumerate((80, 96)):
    S.box(f"SofaSeat{k}", (5, 12, 1.6), (LX + 2, y, 1.4), material=SOFA, bev=0.35)
    S.box(f"SofaBack{k}", (1.6, 12, 3.6), (LX + 4.6, y, 2.6), material=SOFA, bev=0.35)
    for s in (-1, 1):
        S.box(f"SofaArm{k}{s}", (5, 1.6, 2.6), (LX + 2, y + s * 6.4, 1.9), material=SOFA, bev=0.35)
C("EXPORT_LoungeTables__Wood")
for k, y in enumerate((80, 96)):
    S.box(f"LoungeTable{k}", (4, 6, 0.4), (LX - 4, y, 2.0), material=WOOD_L, bev=0.08)
    for dx in (-1.6, 1.6):
        for dy in (-2.6, 2.6):
            S.box(f"LoungeLeg{k}{dx}{dy}", (0.3, 0.3, 1.8), (LX - 4 + dx, y + dy, 0.9), material=WOOD)
C("EXPORT_LoungeCandles__Neon")
for k, y in enumerate((80, 96)):
    S.cyl(f"Candle{k}", 0.35, 0.9, (LX - 4, y, 2.65), material=LANTERN, verts=8)
C("EXPORT_LoungeBackWall__Slate")
S.box("LoungeBackWall", (1.2, 36, 12), (LX + 8, 88, 6), material=STONE_D)

# ══════════════════════════════════════════════ POSTERS (framed hands) ══
C("EXPORT_Posters__SmoothPlastic")
POSTERS = [(-1, 60), (1, 60), (-1, 150), (1, 150), (-1, 112), (1, 112)]
for side, y in POSTERS:
    S.box(f"PosterFrame{side}_{y}", (0.5, 6.5, 8.5), (side * (HALF - 0.6), y, 9), material=IRON)
    S.box(f"Poster{side}_{y}", (0.55, 5.5, 7.5), (side * (HALF - 0.75), y, 9), material=POSTER)
C("EXPORT_PosterHands__Neon")
for side, y in POSTERS:
    S.hand(f"PosterHand{side}_{y}", (side * (HALF - 1.1), y, 8.3), (90, 0, 90 * side), 1.6, POSTERHAND)

# ═════════════════════════════════════════════════════════════ RUBBLE ══
C("EXPORT_Rubble__Slate")
for side in (-1, 1):
    for k in range(9):
        y0 = 8 + k * 24
        S.rubble(f"Rubble{side}_{k}", 5, (side * (LANE + 5) - 3, side * (LANE + 5) + 3, y0, y0 + 10), rng, STONE_D, size=(0.8, 2.6))
S.rubble("RubbleThrone", 10, (-26, 26, 221, 225), rng, STONE, size=(1.2, 3.2))

# ═══════════════════════════════════════════════ ENTRANCE / EXIT GATES ══
C("EXPORT_Gates__Slate")
for gy, tag in ((-2.0, "Entry"),):
    for side in (-1, 1):
        S.box(f"{tag}GatePillar{side}", (7, 7, 30), (side * 57.5, gy, 15), material=STONE, bev=0.35)
        S.box(f"{tag}GateCap{side}", (8.5, 8.5, 2.2), (side * 57.5, gy, 31), material=STONE_L, bev=0.25)
    # broken lintel pieces (keeps the next world visible through the opening)
    S.box(f"{tag}LintelL", (44, 4, 3.4), (-38, gy, 33.5), (0, 4, 0), STONE_D, bev=0.3)
    S.box(f"{tag}LintelR", (34, 4, 3.4), (44, gy, 32.6), (0, -9, 0), STONE_D, bev=0.3)
C("EXPORT_GateChains__Metal")
for gy in (-2.0,):
    S.chain(f"GateChain{gy}", (-55, gy, 29), (55, gy, 29), 7.0, 1.4, IRON)

# ════════════════════════════════════════════════════════════ SKYLINE ══
C("EXPORT_Skyline__SmoothPlastic")
BUILD = []
for side in (-1, 1):
    x = 112.0
    for row in range(3):
        y = Y0
        while y < Y1 - 4:
            w = min(rng.uniform(12, 24), Y1 - y)
            d = rng.uniform(12, 22)
            h = rng.uniform(40, 95) + row * 25
            bx = side * (x + row * 38 + rng.uniform(0, 8))
            S.box(f"Bldg{side}_{row}_{int(y)}", (d, w, h), (bx, y + w / 2, h / 2 - 2), material=CITY if row == 0 else CITY_FAR)
            BUILD.append((bx, y + w / 2, d, w, h, side))
            y += w + rng.uniform(2, 8)
C("EXPORT_SkylineWindows__Neon")
for (bx, by, d, w, h, side) in BUILD:
    face_x = bx - side * d / 2 if side else None
    for k in range(int(h / 9)):
        if rng.random() < 0.7:
            continue
        z = 6 + k * 8 + rng.uniform(-1, 1)
        if side:
            S.box(f"Win{int(bx)}_{int(by)}_{k}", (0.3, rng.uniform(1.4, 3.5), 1.4), (face_x - side * 0.16, by + rng.uniform(-w / 3, w / 3), z), material=WINDOW)
        else:
            S.box(f"Win{int(bx)}_{int(by)}_{k}", (rng.uniform(1.4, 3.5), 0.3, 1.4), (bx + rng.uniform(-6, 6), by - 8.2 + 25, z), material=WINDOW)
# ═══════════════════════════════════════ CITY BEHIND SHIGARAKI (correction pass) ══
# R01 puts the purple city + an elevated highway behind the throne. Restored inside the world as:
#   * EndBlocks (BOUNDARY, collide): ruined city facades closing the far corners (|x| 54-82, y 204-228);
#     designed openings stay on both sides of the throne (|x| ~32-54) -> the next world is visible through them
#   * FarCity (BACKGROUND, non-collidable): a dense high-rise cluster at the far corners, taller than the side skyline
#   * Highway (BACKGROUND): an elevated bridge spanning the back high above the exit (deck at z 58)
C("EXPORT_EndBlocks__Slate")
ENDB = []
for side in (-1, 1):
    x0 = side * 54.0
    for k, (w, d, h) in enumerate(((14, 24, 34), (14, 24, 26))):
        cx = side * (54.0 + 7 + k * 14)
        S.box(f"EndBlock{side}_{k}", (w, d, h), (cx, 216, h / 2), material=STONE_D if k else STONE, bev=0.3)
        ENDB.append((cx, 216, w, d, h, side))
        for j in range(4):  # ruined crown
            cs = rng.uniform(2.2, 4.2)
            S.box(f"EndCrown{side}_{k}_{j}", (cs, cs, cs), (cx + rng.uniform(-w / 3, w / 3), rng.uniform(206, 226), h + cs * 0.3), (rng.uniform(-20, 20), rng.uniform(-20, 20), rng.uniform(0, 90)), STONE, bev=0.2)
    S.box(f"HighwayPierNear{side}", (4, 4, 58), (side * 68, 225.5, 29), material=STONE_D)
C("EXPORT_EndBlockCracks__Neon")
for (cx, cy, w, d, h, side) in ENDB:
    fx = cx - side * (w / 2 + 0.05)
    for k in range(5):
        S.box(f"EndCrack{int(cx)}_{k}", (0.15, rng.uniform(0.2, 0.35), rng.uniform(3, 7)), (fx, cy + rng.uniform(-10, 10), rng.uniform(3, h - 4)), (rng.uniform(-35, 35), 0, 0), CRACK)
C("EXPORT_EndBlockWindows__Neon")
for (cx, cy, w, d, h, side) in ENDB:
    fy = cy - d / 2 - 0.08  # windows on the face looking down the lane
    for z in range(8, int(h) - 3, 6):
        for k in range(int(w // 4)):
            if rng.random() < 0.5:
                S.box(f"EndWin{int(cx)}_{z}_{k}", (1.6, 0.15, 2.2), (cx - w / 2 + 2 + k * 4, fy, z), material=WINDOW)
C("EXPORT_FarCity__SmoothPlastic")
FAR = []
for side in (-1, 1):
    for k in range(9):
        w = rng.uniform(14, 24)
        d = rng.uniform(12, 20)
        h = rng.uniform(85, 155)
        bx = side * rng.uniform(84, 170)
        by = rng.uniform(170 + d / 2, 227 - d / 2)
        S.box(f"FarTower{side}_{k}", (w, d, h), (bx, by, h / 2 - 2), material=CITY if k % 3 else CITY_FAR)
        S.box(f"FarTowerCap{side}_{k}", (w * 0.6, d * 0.6, 6), (bx, by, h + 1), material=CITY)
        FAR.append((bx, by, w, d, h, side))
C("EXPORT_FarCityWindows__Neon")
for (bx, by, w, d, h, side) in FAR:
    fy = by - d / 2 - 0.1
    for z in range(10, int(h) - 6, 8):
        for k in range(int(w // 5)):
            if rng.random() < 0.35:
                S.box(f"FarWin{int(bx)}_{int(by)}_{z}_{k}", (2.0, 0.2, 1.4), (bx - w / 2 + 2.5 + k * 5, fy, z), material=WINDOW)
C("EXPORT_Highway__Metal")
S.box("HighwayDeck", (400, 5, 2.4), (0, 225.5, 58), material=IRON)
for side in (-1, 1):
    S.box(f"HighwayRail{side}", (400, 0.4, 1.4), (0, 225.5 + side * 2.3, 59.9), material=IRON)
for k in range(-16, 17):
    S.box(f"HighwayTruss{k}", (0.6, 4.6, 9), (k * 12, 225.5, 53), (0, 35 if k % 2 else -35, 0), IRON)
C("EXPORT_HighwayPiers__Slate")
for x in (-160, -100, 100, 160):
    S.box(f"HighwayPier{x}", (5, 5, 58), (x, 225.5, 29), material=STONE_D)
C("EXPORT_HighwayNeon__Neon")
S.box("HighwayUnderglow", (400, 0.3, 0.3), (0, 223.0, 56.7), material=NEON)
for k in range(-8, 9):
    S.box(f"HighwayLamp{k}", (0.8, 0.8, 0.5), (k * 24, 225.5, 61.2), material=LANTERN)
S.use(S.collection("VFX"))
S.empty("VFX_HighwayTraffic", (0, 225.5, 60))["vfx"] = "distant traffic light streaks along the highway (runtime beams)"
S.empty("VFX_CitySmoke", (0, 215, 30))["vfx"] = "drifting purple smoke over the ruined end blocks (runtime)"

S.set_layers([
    ("CrackBed", "PLAYABLE"), ("CrackGlow", "PLAYABLE"), ("Floor", "PLAYABLE"), ("Plaza", "PLAYABLE"),
    ("Walls", "BOUNDARY"), ("WallCracks", "BOUNDARY"), ("EndBlocks", "BOUNDARY"), ("EndBlockCracks", "BOUNDARY"),
    ("EndBlockWindows", "BOUNDARY"), ("Gates", "BOUNDARY"),
    ("Throne", "BOSS_STAGE"), ("ThroneHands", "PROPS"), ("ThroneCloak", "PROPS"), ("ThroneChains", "PROPS"),
    ("Skyline", "BACKGROUND"), ("FarCity", "BACKGROUND"), ("Highway", "BACKGROUND"),
    ("EggNests", "PROPS"),
])
S.organize("MHA")
VALID = S.validate("MHA", walk_half=75.0)

# ═════════════════════════════════════════════════════════ SAVE / RENDER / EXPORT ══
blend_dir = os.path.join(REPO, "art", "blender", "worlds")
os.makedirs(blend_dir, exist_ok=True)
S.bpy.ops.wm.save_as_mainfile(filepath=os.path.join(blend_dir, "02_MHA.blend"))
print("SAVED 02_MHA.blend")

if DO_RENDER:
    S.setup_render(sky="#4a2a9e", sky_strength=0.45, samples=int(os.environ.get("SAE_SAMPLES", "40")))
    S.sun("Moonlight", (55, 0, 35), strength=0.9, color="#b9a4ff")
    S.sun("Fill", (60, 0, -140), strength=0.35, color="#ffb070")
    # review-render stand-ins for the runtime PointLights anchored at VFX_* empties
    for (x, y) in posts:
        S.point(f"LanternLight{x}_{y}", (x, y, 5.4), 900, "#ffae55", radius=0.6)
    for (ex, ey) in EGGS:
        S.point(f"NestLight{ex}_{ey}", (-ex, ey, 2.5), 1500, "#b25cff", radius=1.0)
    S.point("BarLight", (-62, 88, 12), 2500, "#b366ff", radius=2)
    S.point("ThroneLight", (0, 198, 18), 9000, "#a24dff", radius=3)
    S.point("PlazaGlow", (0, 168, 6), 5000, "#9a48ff", radius=4)
    out = os.path.join(REPO, "art", "review_renders", "v02", "02_MHA")
    tag = os.environ.get("SAE_TAG", "pass1")
    S.render(os.path.join(out, f"{tag}_gameplay.png"), (0, -14, 9), (0, 120, 7), lens=22)
    S.render(os.path.join(out, f"{tag}_throne.png"), (0, 150, 12), (0, 214, 10), lens=24)
    S.render(os.path.join(out, f"{tag}_overview.png"), (0, -95, 120), (0, 115, 0), lens=24)

if "export" in sys.argv:
    m = S.export_modules(os.path.join(REPO, "art", "exports", "worlds", "02_MHA"), "Layout.worldZ0(2)", "MHA", validation=VALID)
    tot = sum(x["triangles"] for x in m["modules"])
    print("EXPORTED", len(m["modules"]), "modules", tot, "tris", "over limit:", [x["module"] for x in m["modules"] if x["overLimit"]], "validation:", m["validation"]["pass"])
