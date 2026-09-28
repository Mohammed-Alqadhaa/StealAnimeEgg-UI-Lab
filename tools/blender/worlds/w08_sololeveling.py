"""
World 8 — Solo Leveling / Shadow Corridor, boss Sung Jin-Woo (reference R02 "SOLO LEVELING SHADOW CORRIDOR" panel)

  blender -b --factory-startup --python tools/blender/worlds/w08_sololeveling.py -- <repo_root> [render] [export]

Reference elements reproduced (R02 Shadow Corridor):
  * a deep-blue dungeon corridor with a dark, glossy stone floor
  * rows of giant shadow-soldier statues (horned knights with capes and planted swords, glowing blue eyes)
    standing in gothic alcoves along both walls
  * blue-flame braziers and candle clusters lining the path; ribbed gothic arches overhead
  * the Shadow Monarch's throne on a dais at the far end, framed by a glowing gate and two colossal knights
  * dark egg pedestals with a cold blue/violet glow
Review lighting stays readable (deep-blue sky colour for identity, neutral ambient) — no night lighting (§32).
Gameplay: centre lane |x| < 54 clear and flat; dungeon walls at |x| = 75 (collide); open entry gate.
"""
import os
import sys
import math
import random

REPO = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
DO_RENDER = "render" in sys.argv
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import sae_bpy as S  # noqa: E402

rng = random.Random(808)
S.reset()

# ── palette (from R02 Shadow Corridor) ────────────────────────────────────────
FLOOR = S.mat("SL_FloorStone", "#252a36", rough=0.22, roblox="Slate")
FLOOR_L = S.mat("SL_FloorStoneLight", "#2f3544", rough=0.25, roblox="Slate")
RUNNER = S.mat("SL_Runner", "#171b24", rough=0.2, roblox="Slate")
GROUT = S.mat("SL_Grout", "#0c0e13", rough=0.9, roblox="Slate")
WALL = S.mat("SL_WallStone", "#2b3140", rough=0.7, roblox="Slate")
WALL_D = S.mat("SL_WallStoneDark", "#1b202b", rough=0.7, roblox="Slate")
TRIM = S.mat("SL_Trim", "#4a5468", rough=0.6, roblox="Slate")
SHADOW = S.mat("SL_ShadowArmor", "#12141b", rough=0.35, metal=0.5, roblox="Metal")
SHADOW_E = S.mat("SL_ShadowEdge", "#2a3350", rough=0.35, metal=0.5, roblox="Metal")
CAPE = S.mat("SL_ShadowCape", "#0d0f16", rough=0.8, roblox="Fabric")
EYES = S.mat("SL_ShadowEyes", "#39b5ff", emit="#39b5ff", strength=12.0, roblox="Neon")
BLUEFIRE = S.mat("SL_BlueFire", "#2f8dff", emit="#2f8dff", strength=12.0, roblox="Neon")
BLUEFIRE_C = S.mat("SL_BlueFireCore", "#bfe6ff", emit="#bfe6ff", strength=14.0, roblox="Neon")
VIOLET = S.mat("SL_ShadowViolet", "#7b5cff", emit="#7b5cff", strength=6.0, roblox="Neon")
IRON = S.mat("SL_Iron", "#1d1f25", rough=0.4, metal=0.85, roblox="Metal")
CANDLE = S.mat("SL_Candle", "#d9dce4", rough=0.6, roblox="SmoothPlastic")
THRONE = S.mat("SL_Throne", "#14161d", rough=0.3, roblox="Marble")
GATEGLOW = S.mat("SL_GateGlow", "#3aa0ff", emit="#3aa0ff", strength=8.0, roblox="Neon")
PORTAL = S.mat("SL_GatePortal", "#0f2a66", emit="#1c4dbb", strength=0.45, roblox="Glass", transparency=0.65)

HALF, LEN, LANE = 75.0, 230.0, 54.0
EGGS = [(-42, 118), (42, 118), (-26, 158), (26, 158), (0, 184)]
BOSS_Y = 206.0
Y0, Y1 = -30.0, 228.0  # world slot (sae_bpy.WORLD_SLOT_Y): nothing may leave it
YM, YL = (Y0 + Y1) / 2, Y1 - Y0


def C(name):
    return S.use(S.collection(name))


def knight(tag, x, y, s, face, mats):
    """Shadow soldier statue (stylised horned knight). `face` = +1 faces +x, -1 faces -x, 0 faces -y.
    Parts are appended to mats[material] lists so each material goes to its own module."""
    rotz = {1: -90, -1: 90, 0: 0}[face]
    ca, sa = math.cos(math.radians(rotz)), math.sin(math.radians(rotz))

    def P(lx, ly, z):  # local (lx right, ly>0 = in front of the knight, i.e. -y before rotz) → world
        return (x + lx * ca - (-ly) * sa, y + lx * sa + (-ly) * ca, z)

    A = mats[SHADOW]
    for dx in (-0.9, 0.9):
        A.append(S.box(f"{tag}Leg{dx}", (1.3 * s, 1.5 * s, 6.5 * s), P(dx * s, 0, 3.25 * s), (0, 0, rotz), SHADOW, bev=0.1 * s))
        A.append(S.box(f"{tag}Boot{dx}", (1.5 * s, 2.3 * s, 1.0 * s), P(dx * s, 0.3 * s, 0.5 * s), (0, 0, rotz), SHADOW))
    A.append(S.box(f"{tag}Hips", (3.4 * s, 2.0 * s, 1.6 * s), P(0, 0, 7.0 * s), (0, 0, rotz), SHADOW))
    A.append(S.cyl(f"{tag}Torso", 1.9 * s, 5.0 * s, P(0, 0, 10.2 * s), (0, 0, rotz), SHADOW, verts=6, r2=2.4 * s))
    A.append(S.sphere(f"{tag}Head", 1.2 * s, P(0, 0, 13.9 * s), SHADOW, seg=10, rings=6, scale=(1, 1.1, 1.2)))
    for dx in (-1, 1):
        A.append(S.cyl(f"{tag}Arm{dx}", 0.55 * s, 5.2 * s, P(dx * 2.3 * s, 0.3 * s, 9.6 * s), (0, 0, rotz), SHADOW, verts=6, r2=0.45 * s))
    E = mats[SHADOW_E]
    for dx in (-1, 1):
        E.append(S.sphere(f"{tag}Pauldron{dx}", 1.3 * s, P(dx * 2.3 * s, 0, 12.3 * s), SHADOW_E, seg=10, rings=6, scale=(1.2, 1.1, 0.8)))
        E.append(S.cyl(f"{tag}Horn{dx}", 0.35 * s, 3.2 * s, P(dx * 1.1 * s, 0, 15.6 * s), (0, dx * 28, rotz), SHADOW_E, verts=6, r2=0.02))
    # sword planted point-down in front, hands on the pommel
    E.append(S.box(f"{tag}Blade", (0.9 * s, 0.25 * s, 7.0 * s), P(0, 1.8 * s, 3.9 * s), (0, 0, rotz), SHADOW_E))
    E.append(S.box(f"{tag}Guard", (3.0 * s, 0.5 * s, 0.5 * s), P(0, 1.8 * s, 7.6 * s), (0, 0, rotz), SHADOW_E))
    E.append(S.cyl(f"{tag}Grip", 0.25 * s, 1.6 * s, P(0, 1.8 * s, 8.6 * s), (0, 0, rotz), SHADOW_E, verts=6))
    mats[CAPE].append(S.banner(f"{tag}Cape", 5.0 * s, 11 * s, P(0, -1.3 * s, 12.6 * s), (0, 0, rotz), CAPE, rng, torn=True, wave=0.5 * s))
    for dx in (-0.45, 0.45):
        mats[EYES].append(S.box(f"{tag}Eye{dx}", (0.5 * s, 0.2 * s, 0.22 * s), P(dx * s, 1.05 * s, 14.0 * s), (0, 0, rotz), EYES))


# ═════════════════════════════════════════════════════════════ FLOOR ══
C("EXPORT_Grout__Slate")
S.box("Grout", (HALF * 2, YL, 0.4), (0, YM, -0.45), material=GROUT)
for part, (y0, y1) in enumerate([(Y0, 64), (64, 140), (140, Y1)]):
    C(f"EXPORT_Floor{part + 1}__Slate")
    for ob in S.slab_floor(f"Floor{part}", -HALF, HALF, y0, y1, 8.0, 0.1, 0.0, 0.8, FLOOR, rng, jitter=0.06, tilt=0.0, bev=0.06):
        cx = sum(v.co.x for v in ob.data.vertices) / len(ob.data.vertices)
        if abs(cx) < 12:
            ob.data.materials[0] = RUNNER
        elif rng.random() < 0.3:
            ob.data.materials[0] = FLOOR_L
C("EXPORT_RunnerGlow__Neon")
for side in (-1, 1):  # faint violet guide lines along the runner
    S.box(f"RunnerLine{side}", (0.25, 190 - Y0, 0.05), (side * 12.2, (Y0 + 190) / 2, 0.03), material=VIOLET)

# ════════════════════════════════════════════════════ WALLS + ALCOVES ══
C("EXPORT_Walls__Slate")
for side in (-1, 1):
    S.box(f"Wall{side}", (4, YL, 34), (side * (HALF + 6), YM, 17), material=WALL_D)
ALC = list(range(int(Y0) + 14, int(Y1) - 10, 24))
C("EXPORT_AlcoveFrames__Slate")
for side in (-1, 1):
    for y in ALC:  # piers between alcoves + pointed arch over each alcove
        for dy in (-10.5, 10.5):
            S.box(f"Pier{side}_{y}_{dy}", (8, 3, 30), (side * (HALF + 1), y + dy, 15), material=WALL, bev=0.2)
        S.arch(f"AlcoveArch{side}_{y}", 18, 2.2, 8, (side * (HALF + 1), y, 22), (0, 0, 90), WALL, segs=12)
    S.box(f"Cornice{side}", (9, YL, 2), (side * (HALF + 1), YM, 33), material=TRIM)
    S.box(f"Plinth{side}", (9, YL, 1.4), (side * (HALF + 1), YM, 0.7), material=TRIM)

# ══════════════════════════════════════════════════════ SHADOW ARMY ══
ARMY = {SHADOW: [], SHADOW_E: [], CAPE: [], EYES: []}
for side in (-1, 1):
    for i, y in enumerate(ALC):
        knight(f"Soldier{side}_{i}", side * (HALF - 1), y, 1.25, -side, ARMY)
for m, objs in ARMY.items():
    col = S.collection(f"EXPORT_ShadowArmy__{m['roblox_material']}")
    for o in objs:
        for c in list(o.users_collection):
            c.objects.unlink(o)
        col.objects.link(o)
S.use(S.collection("VFX"))
for side in (-1, 1):
    S.empty(f"VFX_ShadowArmy{side}", (side * (HALF - 1), YM, 16))["vfx"] = "eye glow pulse + shadow smoke at feet, statues kneel when the boss wakes (runtime)"

# ═════════════════════════════════════════════════ OVERHEAD ARCHES ══
C("EXPORT_Ribs__Slate")
for y in range(10, 200, 40):
    S.arch(f"Rib{y}", HALF * 2 + 8, 3.0, 4, (0, y, 34), (0, 0, 0), WALL, segs=24)
C("EXPORT_RibGlow__Neon")
for y in range(10, 200, 40):
    S.cyl(f"RibKeystone{y}", 1.4, 0.8, (0, y - 2.1, 34 + HALF + 4 + 1.5), (90, 0, 0), BLUEFIRE, verts=4)

# ═══════════════════════════════════════════════ BLUE FLAMES / CANDLES ══
BRAZ = [(side * (LANE + 2.5), y) for side in (-1, 1) for y in range(6, 196, 20)]
C("EXPORT_Braziers__Metal")
for (x, y) in BRAZ:
    S.cyl(f"BrazierStand{x}_{y}", 0.5, 4.4, (x, y, 2.2), material=IRON, verts=6)
    S.cyl(f"BrazierFoot{x}_{y}", 1.5, 0.5, (x, y, 0.25), material=IRON, verts=6)
    S.cyl(f"BrazierBowl{x}_{y}", 0.9, 1.1, (x, y, 4.9), material=IRON, verts=8, r2=1.7)
C("EXPORT_BlueFire__Neon")
for (x, y) in BRAZ:
    for k in range(3):
        a = 2 * math.pi * k / 3 + rng.uniform(-0.3, 0.3)
        fh = rng.uniform(3.0, 4.4)
        S.cyl(f"BFlame{x}_{y}_{k}", 0.85, fh, (x + math.cos(a) * 0.6, y + math.sin(a) * 0.6, 5.4 + fh / 2), material=BLUEFIRE, verts=6, r2=0.04)
C("EXPORT_BlueFireCore__Neon")
for (x, y) in BRAZ:
    S.cyl(f"BFlameCore{x}_{y}", 0.55, 3.0, (x, y, 6.9), material=BLUEFIRE_C, verts=6, r2=0.04)
CANDLES = [(side * (LANE + rng.uniform(5, 9)), y + rng.uniform(-4, 4)) for side in (-1, 1) for y in range(16, 196, 20)]
C("EXPORT_Candles__SmoothPlastic")
for i, (x, y) in enumerate(CANDLES):
    for k in range(4):
        S.cyl(f"Candle{i}_{k}", 0.3, rng.uniform(0.8, 2.2), (x + rng.uniform(-1, 1), y + rng.uniform(-1, 1), 0.7), material=CANDLE, verts=6)
C("EXPORT_CandleFlames__Neon")
for i, (x, y) in enumerate(CANDLES):
    S.sphere(f"CandleFlame{i}", 0.3, (x, y, 2.3), BLUEFIRE_C, seg=6, rings=4, scale=(1, 1, 1.8))
S.use(S.collection("VFX"))
for (x, y) in BRAZ:
    S.empty(f"VFX_BlueFire_{int(x)}_{y}", (x, y, 7))["vfx"] = "blue fire + sparks ParticleEmitter + cold blue PointLight (runtime)"
S.empty("VFX_CorridorFog", (0, YM, 1))["vfx"] = "low blue fog layer along the floor (runtime)"

# ═════════════════════════════════════════════════ MONARCH'S THRONE ══
C("EXPORT_Dais__Marble")
for s_ in range(4):
    S.box(f"DaisStep{s_}", (40 - s_ * 5, 3.5, 0.9 + s_ * 0.9), (0, 196 + s_ * 3.5, (0.9 + s_ * 0.9) / 2), material=THRONE, bev=0.08)
S.box("DaisTop", (22, 12, 3.6), (0, 220, 1.8), material=THRONE, bev=0.1)
C("EXPORT_Throne__Marble")
S.box("ThroneSeat", (7, 4.5, 2.2), (0, 221, 4.7), material=THRONE, bev=0.3)
S.box("ThroneBack", (7.5, 1.6, 14), (0, 223.6, 10.5), material=THRONE, bev=0.3)
for dx in (-4, -2, 0, 2, 4):
    S.cyl(f"ThroneSpike{dx}", 0.7, 5 + (4 - abs(dx)) * 0.9, (dx, 223.6, 19 + (4 - abs(dx)) * 0.45), material=THRONE, verts=6, r2=0.04)
C("EXPORT_ThroneGlow__Neon")
S.box("ThroneTrim", (7.7, 0.2, 0.3), (0, 222.7, 17.4), material=GATEGLOW)
S.box("DaisGlow", (22, 0.3, 0.25), (0, 213.9, 3.65), material=GATEGLOW)
# glowing gate behind the throne (open ring; the next world stays visible through it)
C("EXPORT_Gate__Slate")
for side in (-1, 1):
    S.box(f"GatePillar{side}", (5, 5, 40), (side * 22, 225, 20), material=WALL, bev=0.3)
S.arch("GateArch", 44, 4.5, 5, (0, 225, 40), (0, 0, 0), WALL, segs=20)
C("EXPORT_GateGlowRing__Neon")
S.arch("GateGlowArch", 41.5, 0.6, 5.4, (0, 224.9, 40), (0, 0, 0), GATEGLOW, segs=24)
for side in (-1, 1):
    S.box(f"GateGlowSide{side}", (0.6, 5.4, 40), (side * 20.9, 224.9, 20), material=GATEGLOW)
C("EXPORT_GatePortal__Glass")
S.box("GatePortal", (41, 0.3, 40), (0, 226.2, 20), material=PORTAL)
# two colossal knights flanking the dais (Igris / Beru-style silhouettes, stylised)
COLOSSI = {SHADOW: [], SHADOW_E: [], CAPE: [], EYES: []}
for side in (-1, 1):
    knight(f"Colossus{side}", side * 36, 216, 2.6, 0, COLOSSI)
for m, objs in COLOSSI.items():
    col = S.collection(f"EXPORT_Colossi__{m['roblox_material']}")
    for o in objs:
        for c in list(o.users_collection):
            c.objects.unlink(o)
        col.objects.link(o)
S.use(S.collection("VFX"))
S.empty("VFX_BossStage", (0, BOSS_Y, 4))["vfx"] = "boss anchor + violet/black Monarch aura, 'ARISE' shadow burst (runtime)"
S.empty("VFX_Gate", (0, 225, 20))["vfx"] = "gate swirl + blue portal shimmer (runtime)"

# ═══════════════════════════════════════════════════ EGG PEDESTALS ══
C("EXPORT_EggPedestals__Slate")
for i, (ex, ey) in enumerate(EGGS):
    S.cyl(f"Pedestal{i}", 3.1, 1.2, (-ex, ey, 0.6), material=WALL_D, verts=8)
    S.cyl(f"PedestalTop{i}", 2.6, 0.4, (-ex, ey, 1.4), material=THRONE, verts=8)
C("EXPORT_EggPedestalGlow__Neon")
for i, (ex, ey) in enumerate(EGGS):
    S.torus(f"PedGlow{i}", 2.3, 0.14, (-ex, ey, 1.62), (0, 0, 0), VIOLET if i % 2 else GATEGLOW, major=28, minor=4)
S.use(S.collection("VFX"))
for i, (ex, ey) in enumerate(EGGS):
    S.empty(f"VFX_EggNest{i + 1}", (-ex, ey, 1.8))["vfx"] = "shadow smoke + blue/violet motes (runtime); egg spawn anchor"

# ═════════════════════════════════════════════════════════ ENTRY GATE ══
C("EXPORT_EntryGate__Slate")
GY = -3.0
for side in (-1, 1):
    S.box(f"EntryPier{side}", (8, 8, 42), (side * 60, GY, 21), material=WALL, bev=0.3)
S.arch("EntryArch", 112, 5, 7, (0, GY, 36), (0, 0, 0), WALL, segs=28)
C("EXPORT_EntryGlow__Neon")
S.arch("EntryGlowArch", 110.6, 0.5, 7.4, (0, GY, 36), (0, 0, 0), GATEGLOW, segs=28)

# ═════════════════════════════════════════════════════════ SAVE / RENDER / EXPORT ══
blend_dir = os.path.join(REPO, "art", "blender", "worlds")
os.makedirs(blend_dir, exist_ok=True)
S.bpy.ops.wm.save_as_mainfile(filepath=os.path.join(blend_dir, "08_SoloLeveling.blend"))
print("SAVED 08_SoloLeveling.blend")

if DO_RENDER:
    S.setup_render(sky="#1d2d63", sky_strength=0.9, samples=int(os.environ.get("SAE_SAMPLES", "40")), sky_light=0.55, ambient="#dfe6f5")
    S.sun("Sun", (55, 0, 25), strength=2.0, color="#cfdcff")
    for (x, y) in BRAZ:
        S.point(f"FireLight{x}_{y}", (x, y, 7), 500, "#2f8dff", radius=0.8)
    S.point("GateLight", (0, 215, 18), 4000, "#3aa0ff", radius=4)
    out = os.path.join(REPO, "art", "review_renders", "v02", "08_SoloLeveling")
    tag = os.environ.get("SAE_TAG", "pass1")
    S.render(os.path.join(out, f"{tag}_gameplay.png"), (0, -14, 9), (0, 120, 12), lens=22)
    S.render(os.path.join(out, f"{tag}_boss.png"), (0, 160, 12), (0, 220, 16), lens=24)
    S.render(os.path.join(out, f"{tag}_overview.png"), (0, -95, 120), (0, 115, 0), lens=24)

if "export" in sys.argv:
    m = S.export_modules(os.path.join(REPO, "art", "exports", "worlds", "08_SoloLeveling"), "Layout.worldZ0(8)", "SoloLeveling")
    tot = sum(x["triangles"] for x in m["modules"])
    print("EXPORTED", len(m["modules"]), "modules", tot, "tris", "over limit:", [x["module"] for x in m["modules"] if x["overLimit"]],
          "outside slot:", [x["module"] for x in m["modules"] if x["outsideSlot"]])
