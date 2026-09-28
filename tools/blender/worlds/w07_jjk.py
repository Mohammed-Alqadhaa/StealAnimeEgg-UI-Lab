"""
World 7 — Jujutsu Kaisen / Shibuya, boss Sukuna (reference R02 "JUJUTSU KAISEN SHIBUYA" panel)

  blender -b --factory-startup --python tools/blender/worlds/w07_jjk.py -- <repo_root> [render] [export]

Reference elements reproduced (R02 Shibuya):
  * Shibuya street at dusk under a blood-red sky: asphalt road with zebra crossings, flush sidewalks
  * dark city blocks on both sides with lit windows, vertical red/pink neon signboards and rooftop billboards
  * a giant red torii at the far end with Sukuna before it; red paper lanterns / street lamps
  * cursed-energy red egg pedestals — SIX (JJK roster: Yuji, Gojo, Toji, Mahoraga, Maki, Sukuna)
  * extra identity: Malevolent-Shrine-style horned shrine with a skull pile behind the torii, a round
    "109"-style tower, a wrecked car, cursed-energy cracks
Review lighting stays readable (dusk-red sky colour, neutral ambient) — no night lighting (§32).
Gameplay: centre lane |x| < 54 clear and flat; building fronts at |x| >= 76 (collide); open entry.
NOTE: the 6th egg offset (0, 132) is a PROPOSAL — Layout.EGG_OFFSETS has 5; the gameplay phase adds it.
"""
import os
import sys
import math
import random

REPO = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
DO_RENDER = "render" in sys.argv
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import sae_bpy as S  # noqa: E402

rng = random.Random(707)
S.reset()

# ── palette (from R02 Shibuya) ────────────────────────────────────────────────
ASPHALT = S.mat("JJ_Asphalt", "#3b3a40", rough=0.6, roblox="Asphalt")
ASPHALT_D = S.mat("JJ_AsphaltDark", "#333238", rough=0.6, roblox="Asphalt")
SIDEWALK = S.mat("JJ_Sidewalk", "#6e6a72", rough=0.8, roblox="Concrete")
PAINT = S.mat("JJ_RoadPaint", "#e9e6e0", rough=0.5, roblox="SmoothPlastic")
GROUT = S.mat("JJ_Grout", "#1d1c20", rough=0.9, roblox="Asphalt")
BLDG = S.mat("JJ_Building", "#2e2b35", rough=0.8, roblox="Concrete")
BLDG_L = S.mat("JJ_BuildingLight", "#4a4452", rough=0.8, roblox="Concrete")
BLDG_R = S.mat("JJ_BuildingRed", "#5a2a30", rough=0.8, roblox="Concrete")
WINDOW = S.mat("JJ_Windows", "#ffd9a8", emit="#ffcf96", strength=2.2, roblox="Neon")
NEON_R = S.mat("JJ_NeonRed", "#ff2a3c", emit="#ff2a3c", strength=9.0, roblox="Neon")
NEON_P = S.mat("JJ_NeonPink", "#ff4fb0", emit="#ff4fb0", strength=8.0, roblox="Neon")
NEON_C = S.mat("JJ_NeonCyan", "#4fe3ff", emit="#4fe3ff", strength=7.0, roblox="Neon")
SIGNBOARD = S.mat("JJ_SignBoard", "#1a1820", rough=0.6, roblox="SmoothPlastic")
TORII = S.mat("JJ_ToriiRed", "#c0182a", rough=0.5, roblox="SmoothPlastic")
TORII_B = S.mat("JJ_ToriiBlack", "#18161a", rough=0.5, roblox="SmoothPlastic")
IRON = S.mat("JJ_Iron", "#2a292e", rough=0.45, metal=0.8, roblox="Metal")
LAMP = S.mat("JJ_LampGlow", "#ffd2a0", emit="#ffc27a", strength=8.0, roblox="Neon")
LANTERN = S.mat("JJ_PaperLantern", "#e0232f", emit="#ff3a3a", strength=3.0, roblox="Neon")
CURSE = S.mat("JJ_CursedGlow", "#ff2448", emit="#ff2448", strength=7.0, roblox="Neon")
MAW = S.mat("JJ_ShrineMaw", "#8a0e1c", emit="#b0101e", strength=2.5, roblox="Neon")
PED = S.mat("JJ_Pedestal", "#221f26", rough=0.5, roblox="Slate")
SHRINE = S.mat("JJ_ShrineWood", "#3a1c1c", rough=0.7, roblox="Wood")
SHRINE_R = S.mat("JJ_ShrineRoof", "#2a1416", rough=0.6, roblox="Slate")
BONE = S.mat("JJ_Bone", "#e8e0cc", rough=0.6, roblox="SmoothPlastic")
CAR = S.mat("JJ_CarWhite", "#d8d8dc", rough=0.3, metal=0.4, roblox="SmoothPlastic")
CARGLASS = S.mat("JJ_CarGlass", "#1b1e24", rough=0.1, roblox="Glass")

HALF, LEN, LANE = 75.0, 230.0, 54.0
EGGS = [(-42, 118), (42, 118), (-26, 158), (26, 158), (0, 184), (0, 132)]  # 6th = proposed JJK offset
BOSS_Y = 206.0
Y0, Y1 = -30.0, 228.0  # world slot (sae_bpy.WORLD_SLOT_Y): nothing may leave it
YM, YL = (Y0 + Y1) / 2, Y1 - Y0
FRONT = 78.0


def C(name):
    return S.use(S.collection(name))


# ═════════════════════════════════════════════════════════════ ROAD ══
C("EXPORT_Grout__Asphalt")
S.box("Grout", ((FRONT + 2) * 2, YL, 0.4), (0, YM, -0.45), material=GROUT)
for part, (y0, y1) in enumerate([(Y0, 64), (64, 140), (140, Y1)]):
    C(f"EXPORT_Road{part + 1}__Asphalt")
    for ob in S.slab_floor(f"Road{part}", -40.0, 40.0, y0, y1, 16.0, 0.05, 0.0, 0.8, ASPHALT, rng, jitter=0.0, tilt=0.0):
        if rng.random() < 0.35:
            ob.data.materials[0] = ASPHALT_D
    C(f"EXPORT_Sidewalk{part + 1}__Concrete")
    for side in (-1, 1):
        x0, x1 = (-(FRONT + 2), -40.0) if side < 0 else (40.0, FRONT + 2)
        S.slab_floor(f"Walk{part}{side}", x0, x1, y0, y1, 5.0, 0.08, 0.0, 0.8, SIDEWALK, rng, jitter=0.0, tilt=0.0)
C("EXPORT_RoadPaint__SmoothPlastic")
for cy in (10.0, 90.0, 170.0):  # zebra crossings
    for k in range(-9, 10):
        S.box(f"Zebra{int(cy)}_{k}", (2.2, 9.0, 0.05), (k * 4.0, cy, 0.03), material=PAINT)
for y in range(-24, 190, 14):  # centre dashes
    if not any(abs(y - cy) < 8 for cy in (10, 90, 170)):
        S.box(f"Dash{y}", (0.5, 6.0, 0.05), (0, y, 0.03), material=PAINT)
for side in (-1, 1):
    S.box(f"EdgeLine{side}", (0.5, YL, 0.05), (side * 38.8, YM, 0.03), material=PAINT)
# cursed-energy cracks spreading from the torii across the road
C("EXPORT_CurseCracks__Neon")
for k in range(26):
    y = rng.uniform(120, 200)
    x = rng.uniform(-40, 40)
    if any(math.hypot(x + ex, y - ey) < 5 for ex, ey in EGGS):
        continue
    S.box(f"CurseCrack{k}", (rng.uniform(2, 6), 0.25, 0.06), (x, y, 0.035), (0, 0, rng.uniform(0, 180)), CURSE)

# ═════════════════════════════════════════════════════════ BUILDINGS ══
BLDGS = []
for side in (-1, 1):
    y = Y0 + 1
    while y < Y1 - 6:
        d = min(rng.uniform(16, 28), Y1 - 1 - y)
        if d < 8:
            break
        w = rng.uniform(18, 30)
        h = rng.uniform(30, 90)
        BLDGS.append((side, side * (FRONT + w / 2), y + d / 2, w, d, h))
        y += d + rng.uniform(1, 3)
for half, sgn in (("E", -1), ("W", 1)):
    bs = [b for b in BLDGS if b[0] == sgn]
    C(f"EXPORT_Buildings{half}__Concrete")
    for i, (side, cx, cy, w, d, h) in enumerate(bs):
        S.box(f"Bldg{half}{i}", (w, d, h), (cx, cy, h / 2), material=rng.choice((BLDG, BLDG, BLDG_L, BLDG_R)))
        S.box(f"Parapet{half}{i}", (w + 0.6, d + 0.6, 1.2), (cx, cy, h + 0.6), material=BLDG_L)
        S.box(f"Awning{half}{i}", (3.0, d - 2, 0.5), (cx - side * (w / 2 + 1.5), cy, 7.5), material=BLDG_L)
    C(f"EXPORT_Windows{half}__Neon")
    for i, (side, cx, cy, w, d, h) in enumerate(bs):
        fx = cx - side * (w / 2 + 0.08)
        for z in range(12, int(h) - 4, 6):
            for k in range(int(d // 5)):
                if rng.random() < 0.55:
                    S.box(f"Win{half}{i}_{z}_{k}", (0.15, 2.4, 2.6), (fx, cy - d / 2 + 2.5 + k * 5, z), material=WINDOW)
    C(f"EXPORT_SignBoards{half}__SmoothPlastic")
    SIGNS = []
    for i, (side, cx, cy, w, d, h) in enumerate(bs):
        if rng.random() < 0.8:  # vertical sign sticking out toward the street
            sh = rng.uniform(14, 26)
            sx, sy, sz = cx - side * (w / 2 + 1.6), cy + rng.uniform(-d / 3, d / 3), rng.uniform(12, max(13, h - sh / 2 - 4))
            S.box(f"VSign{half}{i}", (3.0, 0.6, sh), (sx, sy, sz), material=SIGNBOARD)
            SIGNS.append((sx, sy, sz, sh, rng.choice((NEON_R, NEON_R, NEON_P, NEON_C))))
        if rng.random() < 0.4:  # rooftop billboard
            S.box(f"Billboard{half}{i}", (0.8, d * 0.8, 8), (cx - side * (w / 2 - 3), cy, h + 6), material=SIGNBOARD)
            for leg in (-d * 0.3, d * 0.3):
                S.box(f"BillLeg{half}{i}_{leg}", (0.5, 0.5, 3), (cx - side * (w / 2 - 3), cy + leg, h + 1.5), material=IRON)
            SIGNS.append((cx - side * (w / 2 - 3.5), cy, h + 6, -d * 0.8, NEON_P))
    for mat, tag in ((NEON_R, "Red"), (NEON_P, "Pink"), (NEON_C, "Cyan")):
        C(f"EXPORT_Neon{tag}{half}__Neon")
        for j, (sx, sy, sz, sh, m) in enumerate(SIGNS):
            if m is not mat:
                continue
            if sh > 0:  # vertical sign: glowing frame + kanji-like strokes on both faces
                for s_ in (-1, 1):
                    S.box(f"VFrame{tag}{half}{j}_{s_}", (3.2, 0.12, 0.25), (sx, sy + s_ * 0.36, sz + sh / 2 - 0.3), material=mat)
                    for k in range(int(sh // 4)):
                        S.box(f"Glyph{tag}{half}{j}_{s_}_{k}", (rng.uniform(1.0, 2.2), 0.12, rng.uniform(0.3, 1.8)), (sx + rng.uniform(-0.5, 0.5), sy + s_ * 0.36, sz - sh / 2 + 2 + k * 4), material=mat)
            else:  # billboard: glowing border
                L = -sh
                for dz in (-3.8, 3.8):
                    S.box(f"BFrame{tag}{half}{j}_{dz}", (0.3, L, 0.3), (sx, sy, sz + dz), material=mat)
for side in (-1, 1):
    S.collider(f"StreetBoundary{side}", (2, YL, 60), (side * (FRONT - 1), YM, 30))
S.use(S.collection("VFX"))
for side in (-1, 1):
    S.empty(f"VFX_NeonFlicker{side}", (side * FRONT, YM, 20))["vfx"] = "neon sign flicker + buzz (client tween on Neon colour/transparency)"

# round "109"-style landmark tower (Roblox +x side, far end) — inside the slot
C("EXPORT_Tower109__Concrete")
TX, TY = -(FRONT + 16), 205.0
S.cyl("Tower109", 12, 70, (TX, TY, 35), material=BLDG_L, verts=28)
S.cyl("Tower109Cap", 12.6, 2, (TX, TY, 71), material=BLDG, verts=28)
C("EXPORT_Tower109Neon__Neon")
for z in (20, 40, 60):
    S.torus(f"Tower109Ring{z}", 12.2, 0.25, (TX, TY, z), (0, 0, 0), NEON_R, major=40, minor=4)
S.box("Tower109Sign", (0.3, 10, 4), (TX + 12.1, TY - 2, 64), material=NEON_R)

# ═════════════════════════════════════════════════════════ STREET LAMPS ══
C("EXPORT_StreetLamps__Metal")
lamps = [(side * (LANE + 3), y) for side in (-1, 1) for y in range(0, 200, 25)]
for (x, y) in lamps:
    S.cyl(f"LampPole{x}_{y}", 0.3, 11, (x, y, 5.5), material=IRON, verts=8)
    S.box(f"LampArm{x}_{y}", (3.4, 0.3, 0.3), (x - math.copysign(1.6, x), y, 11), material=IRON)
C("EXPORT_StreetLampGlow__Neon")
for (x, y) in lamps:
    S.box(f"LampHead{x}_{y}", (1.6, 0.9, 0.5), (x - math.copysign(3.2, x), y, 10.7), material=LAMP)
C("EXPORT_PaperLanterns__Neon")
for (x, y) in lamps:
    S.sphere(f"PaperLantern{x}_{y}", 0.8, (x, y, 7.4), LANTERN, seg=10, rings=6, scale=(1, 1, 1.35))
S.use(S.collection("VFX"))
for (x, y) in lamps[::2]:
    S.empty(f"VFX_Lamp_{int(x)}_{y}", (x, y, 10.5))["vfx"] = "street PointLight (runtime)"

# wrecked car on the sidewalk (decor)
C("EXPORT_Car__SmoothPlastic")
S.box("CarBody", (4.6, 9.5, 2.2), (-(LANE + 10), 60, 1.4), (6, 0, 18), CAR, bev=0.4)
S.box("CarCabin", (4.0, 5.0, 1.8), (-(LANE + 10.2), 60.6, 3.2), (6, 0, 18), CAR, bev=0.4)
C("EXPORT_CarGlass__Glass")
S.box("CarWindows", (4.1, 5.1, 1.2), (-(LANE + 10.2), 60.6, 3.3), (6, 0, 18), CARGLASS)

# ═══════════════════════════════════════════════════ TORII + SHRINE ══
C("EXPORT_Torii__SmoothPlastic")
TY_ = 214.0
for side in (-1, 1):
    S.cyl(f"ToriiPillar{side}", 2.2, 44, (side * 26, TY_, 22), material=TORII, verts=16)
S.box("ToriiNuki", (60, 2.2, 2.6), (0, TY_, 34), material=TORII)
S.box("ToriiKasagi", (74, 3.4, 3.0), (0, TY_, 45.5), material=TORII, bev=0.3)
for side in (-1, 1):  # upturned kasagi ends
    S.box(f"ToriiTip{side}", (8, 3.4, 3.0), (side * 38, TY_, 46.6), (0, side * -12, 0), TORII, bev=0.3)
S.box("ToriiGakuzuka", (2.2, 1.6, 8.6), (0, TY_, 39.7), material=TORII)
C("EXPORT_ToriiBlack__SmoothPlastic")
S.box("ToriiKasagiTop", (76, 3.8, 1.2), (0, TY_, 47.6), material=TORII_B, bev=0.2)
for side in (-1, 1):
    S.cyl(f"ToriiBase{side}", 2.8, 2.2, (side * 26, TY_, 1.1), material=TORII_B, verts=16)
    S.box(f"ToriiTipTop{side}", (8, 3.8, 1.2), (side * 38.5, TY_, 48.8), (0, side * -12, 0), TORII_B, bev=0.2)
# Malevolent-Shrine-style horned shrine behind the torii (behind the boss, inside the slot)
C("EXPORT_Shrine__Wood")
S.box("ShrineBase", (26, 8, 3), (0, 223, 1.5), material=SHRINE, bev=0.2)
for dx in (-10, -3.5, 3.5, 10):
    S.cyl(f"ShrinePost{dx}", 0.8, 14, (dx, 222, 10), material=SHRINE, verts=8)
C("EXPORT_ShrineRoof__Slate")
S.box("ShrineRoofL", (16, 10, 0.8), (-7, 222, 19.5), (0, -16, 0), SHRINE_R)
S.box("ShrineRoofR", (16, 10, 0.8), (7, 222, 19.5), (0, 16, 0), SHRINE_R)
for side in (-1, 1):  # horns
    S.cyl(f"ShrineHorn{side}", 1.2, 9, (side * 16.0, 222, 20.6), (0, side * 35, 0), SHRINE_R, verts=8, r2=0.1)
C("EXPORT_SkullPile__SmoothPlastic")
for k in range(40):
    a = rng.uniform(0, math.pi)
    r = rng.uniform(4, 13)
    S.sphere(f"Skull{k}", rng.uniform(0.9, 1.4), (math.cos(a) * r, 219 - math.sin(a) * 1.5 + rng.uniform(-1, 1), 3.4 + rng.uniform(0, 2.4) * (1 - r / 14)), BONE, seg=8, rings=6, scale=(1, 1.1, 0.9))
C("EXPORT_ShrineGlow__Neon")
S.box("ShrineMaw", (12, 0.3, 3.2), (0, 218.8, 7.4), material=MAW)
C("EXPORT_ShrineTeeth__SmoothPlastic")
for k in range(9):
    for z, flip in ((9.0, 1), (5.8, -1)):
        S.cyl(f"Tooth{k}_{z}", 0.5, 1.4, (-5.2 + k * 1.3, 218.6, z - flip * 0.7), (0, 180 if flip > 0 else 0, 0), BONE, verts=4, r2=0.02)
S.use(S.collection("VFX"))
S.empty("VFX_BossStage", (0, BOSS_Y, 3))["vfx"] = "boss anchor + crimson cursed-energy aura (runtime)"
S.empty("VFX_Shrine", (0, 219, 8))["vfx"] = "Malevolent Shrine red haze + slashes (runtime, boss fight)"
S.empty("VFX_ToriiGlow", (0, TY_, 40))["vfx"] = "torii red rim light pulse (runtime)"

# ═══════════════════════════════════════════════════ EGG PEDESTALS ══
C("EXPORT_EggPedestals__Slate")
for i, (ex, ey) in enumerate(EGGS):
    S.cyl(f"Pedestal{i}", 3.0, 1.2, (-ex, ey, 0.6), material=PED, verts=6)
    S.cyl(f"PedestalTop{i}", 2.5, 0.4, (-ex, ey, 1.4), material=BLDG, verts=6)
C("EXPORT_EggPedestalGlow__Neon")
for i, (ex, ey) in enumerate(EGGS):
    S.torus(f"PedGlow{i}", 2.3, 0.14, (-ex, ey, 1.62), (0, 0, 0), CURSE, major=28, minor=4)
S.use(S.collection("VFX"))
for i, (ex, ey) in enumerate(EGGS):
    S.empty(f"VFX_EggNest{i + 1}", (-ex, ey, 1.8))["vfx"] = "cursed-energy flames + black sparks (runtime); egg spawn anchor" + (" [6th slot: proposed offset]" if i == 5 else "")

# ═════════════════════════════════════════════════════════ ENTRY ══
C("EXPORT_EntrySign__Metal")
for side in (-1, 1):
    S.box(f"GantryPost{side}", (1.2, 1.2, 22), (side * 44, -3, 11), material=IRON)
S.box("GantryBeam", (90, 1.2, 1.6), (0, -3, 21.5), material=IRON)
S.box("GantrySign", (30, 0.6, 5), (0, -3, 18), material=SIGNBOARD)
C("EXPORT_EntrySignNeon__Neon")
S.box("GantrySignGlow", (28, 0.2, 0.4), (0, -3.4, 20.2), material=NEON_R)
S.box("GantrySignGlow2", (28, 0.2, 0.4), (0, -3.4, 15.8), material=NEON_R)

# ═════════════════════════════════════════════════════════ SAVE / RENDER / EXPORT ══
blend_dir = os.path.join(REPO, "art", "blender", "worlds")
os.makedirs(blend_dir, exist_ok=True)
S.bpy.ops.wm.save_as_mainfile(filepath=os.path.join(blend_dir, "07_JJK.blend"))
print("SAVED 07_JJK.blend")

if DO_RENDER:
    S.setup_render(sky="#a8303a", sky_strength=0.85, samples=int(os.environ.get("SAE_SAMPLES", "40")), sky_light=0.5, ambient="#f0e6e6")
    S.sun("Sun", (60, 0, 25), strength=2.4, color="#ffd9c8")
    for (x, y) in lamps:
        S.point(f"LampLight{x}_{y}", (x - math.copysign(3.2, x), y, 10), 400, "#ffc27a", radius=0.6)
    S.point("ToriiLight", (0, 200, 20), 4000, "#ff3040", radius=4)
    out = os.path.join(REPO, "art", "review_renders", "v02", "07_JJK")
    tag = os.environ.get("SAE_TAG", "pass1")
    S.render(os.path.join(out, f"{tag}_gameplay.png"), (0, -14, 9), (0, 120, 12), lens=22)
    S.render(os.path.join(out, f"{tag}_boss.png"), (0, 150, 12), (0, 216, 20), lens=24)
    S.render(os.path.join(out, f"{tag}_overview.png"), (0, -95, 120), (0, 115, 0), lens=24)

if "export" in sys.argv:
    m = S.export_modules(os.path.join(REPO, "art", "exports", "worlds", "07_JJK"), "Layout.worldZ0(7)", "JJK")
    tot = sum(x["triangles"] for x in m["modules"])
    print("EXPORTED", len(m["modules"]), "modules", tot, "tris", "over limit:", [x["module"] for x in m["modules"] if x["overLimit"]],
          "outside slot:", [x["module"] for x in m["modules"] if x["outsideSlot"]])
