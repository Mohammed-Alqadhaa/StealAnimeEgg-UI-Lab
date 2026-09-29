"""
sae_bpy — shared Blender (bpy) helpers for Steal An Anime Egg production assets.

Real Blender work: every asset is authored as bpy geometry inside Blender and saved as an
editable .blend (art/blender/...). Exports are Roblox-ready FBX modules + a placement manifest.

Conventions
  * 1 Blender unit = 1 Roblox stud.
  * World-local space: origin = world entrance centre (Roblox z0), Blender +Y = down the lane
    (Roblox +Z), Blender +Z = up (Roblox +Y), Blender -X = Roblox +X.
      Roblox (X, Y, Z) = (-x, z, z0 + y)
  * Each export module is a Blender collection named "EXPORT_<Module>__<RobloxMaterial>".
    At export time its objects are joined into one mesh (≤ 20k triangles, the Roblox limit),
    origin at the bounds centre, and written to art/exports/.../<Module>.fbx.
  * Runtime VFX (glow pulses, smoke, flowing water …) are NOT baked here: Roblox owns them.
    Blender provides the geometry plus named anchor empties ("VFX_*") recorded in the manifest.

Rendering: this container has no EGL/OpenGL, so review renders use Cycles on CPU (no denoiser).
"""
import bpy
import bmesh
import json
import math
import os
import random
from mathutils import Vector, Euler, Matrix

TRI_LIMIT = 20000

# ─────────────────────────────────────────────────────────────── scene ──
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.unit_settings.system = "NONE"
    return sc


def collection(name, parent=None):
    col = bpy.data.collections.get(name)
    if not col:
        col = bpy.data.collections.new(name)
        (parent or bpy.context.scene.collection).children.link(col)
    return col


_active = {"col": None}


def use(col):
    _active["col"] = col
    return col


def _link(obj, col=None):
    col = col or _active["col"] or bpy.context.scene.collection
    col.objects.link(obj)
    return obj


# ──────────────────────────────────────────────────────────── materials ──
_mats = {}


def hexc(h, a=1.0):
    h = h.lstrip("#")
    srgb = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb]
    return (*lin, a)


def mat(name, color, rough=0.75, metal=0.0, emit=None, strength=0.0, roblox="SmoothPlastic", transparency=0.0):
    """Principled material. `roblox` = the Roblox Material the module should use in Studio."""
    if name in _mats:
        return _mats[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = hexc(color)
    p.inputs["Roughness"].default_value = rough
    p.inputs["Metallic"].default_value = metal
    if emit:
        p.inputs["Emission Color"].default_value = hexc(emit)
        p.inputs["Emission Strength"].default_value = strength
    if transparency > 0:
        p.inputs["Alpha"].default_value = 1.0 - transparency
        m.blend_method = "BLEND"
    m["roblox_material"] = roblox
    m["roblox_color"] = color
    m["roblox_transparency"] = transparency
    m.diffuse_color = hexc(color)
    _mats[name] = m
    return m


# ─────────────────────────────────────────────────────────── primitives ──
def _obj_from_bm(name, bm, material=None, col=None):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    if material:
        me.materials.append(material)
    return _link(ob, col)


def _place(ob, loc, rot):
    ob.location = Vector(loc)
    ob.rotation_euler = Euler([math.radians(r) for r in rot], "XYZ")
    return ob


def bevel(ob, width=0.15, segments=2):
    if width <= 0:
        return ob
    m = ob.modifiers.new("Bevel", "BEVEL")
    m.width = width
    m.segments = segments
    m.limit_method = "ANGLE"
    return ob


def box(name, size, loc, rot=(0, 0, 0), material=None, bev=0.0, col=None):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    ob = _obj_from_bm(name, bm, material, col)
    bevel(ob, bev)
    return _place(ob, loc, rot)


def cyl(name, r, h, loc, rot=(0, 0, 0), material=None, verts=12, r2=None, bev=0.0, col=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=verts, radius1=r, radius2=r if r2 is None else r2, depth=h)
    ob = _obj_from_bm(name, bm, material, col)
    bevel(ob, bev)
    return _place(ob, loc, rot)


def sphere(name, r, loc, material=None, seg=16, rings=10, scale=(1, 1, 1), col=None):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=r)
    bmesh.ops.scale(bm, vec=Vector(scale), verts=bm.verts)
    ob = _obj_from_bm(name, bm, material, col)
    return _place(ob, loc, (0, 0, 0))


def torus(name, R, r, loc, rot=(0, 0, 0), material=None, major=12, minor=6, scale=(1, 1, 1), col=None):
    bm = bmesh.new()
    for i in range(major):
        a = 2 * math.pi * i / major
        for j in range(minor):
            b = 2 * math.pi * j / minor
            x = (R + r * math.cos(b)) * math.cos(a)
            y = (R + r * math.cos(b)) * math.sin(a)
            z = r * math.sin(b)
            bm.verts.new((x * scale[0], y * scale[1], z * scale[2]))
    bm.verts.ensure_lookup_table()
    for i in range(major):
        for j in range(minor):
            a = i * minor + j
            b = ((i + 1) % major) * minor + j
            c = ((i + 1) % major) * minor + (j + 1) % minor
            d = i * minor + (j + 1) % minor
            bm.faces.new((bm.verts[a], bm.verts[b], bm.verts[c], bm.verts[d]))
    ob = _obj_from_bm(name, bm, material, col)
    return _place(ob, loc, rot)


def arch(name, span, thick, depth, loc, rot=(0, 0, 0), material=None, segs=12, col=None):
    """Semicircular arch band in the XZ plane (springing line at loc.z), rectangular section, open ends
    (sits on pillars). Inner radius span/2, outer span/2 + thick, depth along Y."""
    bm = bmesh.new()
    ri, ro, hd = span / 2, span / 2 + thick, depth / 2
    ring = []
    for i in range(segs + 1):
        a = math.pi * i / segs
        c, s_ = math.cos(a), math.sin(a)
        ring.append([bm.verts.new((c * ri, -hd, s_ * ri)), bm.verts.new((c * ro, -hd, s_ * ro)),
                     bm.verts.new((c * ro, hd, s_ * ro)), bm.verts.new((c * ri, hd, s_ * ri))])
    for i in range(segs):
        A, B = ring[i], ring[i + 1]
        for k in range(4):
            bm.faces.new((A[k], A[(k + 1) % 4], B[(k + 1) % 4], B[k]))
    bm.faces.new(list(reversed(ring[0])))
    bm.faces.new(ring[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = _obj_from_bm(name, bm, material, col)
    return _place(ob, loc, rot)


def prism(name, poly, z0, z1, material=None, col=None, top_tilt=(0.0, 0.0)):
    """Extruded polygon (list of (x,y)) from z0 to z1; top may tilt (dz per unit x/y)."""
    bm = bmesh.new()
    cx = sum(p[0] for p in poly) / len(poly)
    cy = sum(p[1] for p in poly) / len(poly)
    bot = [bm.verts.new((x, y, z0)) for x, y in poly]
    top = [bm.verts.new((x, y, z1 + (x - cx) * top_tilt[0] + (y - cy) * top_tilt[1])) for x, y in poly]
    bm.faces.new(list(reversed(bot)))
    bm.faces.new(top)
    n = len(poly)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((bot[i], bot[j], top[j], top[i]))
    return _obj_from_bm(name, bm, material, col)


def collider(name, size, loc):
    """Invisible gameplay collider (axis-aligned box). Not exported as a mesh: written to the manifest
    `colliders` list and created as an invisible anchored Part at import. Hidden in review renders."""
    col = collection("COLLIDERS")
    ob = box(name, size, loc, col=col)
    ob.hide_render = True
    ob.display_type = "WIRE"
    return ob


def empty(name, loc, col=None):
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_size = 1.5
    ob.location = Vector(loc)
    return _link(ob, col)


# ─────────────────────────────────────────────────────────── generators ──
def slab_floor(name, x0, x1, y0, y1, cell, gap, top, thick, material, rng, jitter=0.3, tilt=0.0, raise_edge=None, col=None, bev=0.0, gap_var=0.0):
    """Irregular cracked flagstones: jittered grid, each cell inset by `gap` and extruded.
    The gaps expose whatever is underneath (e.g. an emissive crack plane)."""
    nx = max(1, int(round((x1 - x0) / cell)))
    ny = max(1, int(round((y1 - y0) / cell)))
    dx, dy = (x1 - x0) / nx, (y1 - y0) / ny
    pts = {}
    for i in range(nx + 1):
        for j in range(ny + 1):
            jx = 0 if i in (0, nx) else rng.uniform(-jitter, jitter) * dx
            jy = 0 if j in (0, ny) else rng.uniform(-jitter, jitter) * dy
            pts[(i, j)] = (x0 + i * dx + jx, y0 + j * dy + jy)
    objs = []
    for i in range(nx):
        for j in range(ny):
            quad = [pts[(i, j)], pts[(i + 1, j)], pts[(i + 1, j + 1)], pts[(i, j + 1)]]
            cx = sum(p[0] for p in quad) / 4
            cy = sum(p[1] for p in quad) / 4
            poly = []
            g = gap + rng.uniform(0, gap_var)
            for (px, py) in quad:
                vx, vy = cx - px, cy - py
                l = math.hypot(vx, vy) or 1
                poly.append((px + vx / l * g, py + vy / l * g))
            h = top + rng.uniform(-0.06, 0.06)
            if raise_edge and raise_edge(cx, cy):
                h += rng.uniform(0.2, 0.9)
            t = (rng.uniform(-tilt, tilt), rng.uniform(-tilt, tilt))
            ob = prism(f"{name}_{i}_{j}", poly, top - thick, h, material, col, t)
            if bev > 0:
                bevel(ob, bev, 1)
            objs.append(ob)
    return objs


def rubble(name, n, region, rng, material, size=(0.6, 2.2), zbase=0.0, col=None):
    (x0, x1, y0, y1) = region
    out = []
    for k in range(n):
        s = rng.uniform(*size)
        sz = (s * rng.uniform(0.7, 1.4), s * rng.uniform(0.7, 1.4), s * rng.uniform(0.4, 1.0))
        out.append(box(f"{name}_{k}", sz, (rng.uniform(x0, x1), rng.uniform(y0, y1), zbase + sz[2] * 0.35),
                       (rng.uniform(-25, 25), rng.uniform(-25, 25), rng.uniform(0, 90)), material, bev=min(0.12, s * 0.08), col=col))
    return out


def chain(name, p0, p1, sag, link, material, col=None):
    """Hanging chain of alternating torus links along a catenary-ish parabola."""
    p0, p1 = Vector(p0), Vector(p1)
    L = (p1 - p0).length
    n = max(2, int(L / (link * 1.55)))
    out = []
    for i in range(n + 1):
        t = i / n
        p = p0.lerp(p1, t)
        p.z -= sag * 4 * t * (1 - t)
        # tangent for orientation
        t2 = min(1.0, t + 1 / n)
        q = p0.lerp(p1, t2)
        q.z -= sag * 4 * t2 * (1 - t2)
        d = (q - p) if i < n else (p - p0.lerp(p1, (i - 1) / n))
        yaw = math.degrees(math.atan2(d.y, d.x))
        pitch = math.degrees(math.atan2(d.z, math.hypot(d.x, d.y)))
        roll = 90 if i % 2 else 0
        ob = torus(f"{name}_{i}", link * 0.5, link * 0.13, p, (roll, -pitch, yaw), material, major=10, minor=5, scale=(1.35, 0.8, 1))
        out.append(ob)
    return out


def hand(name, loc, rot, s, material, col=None):
    """Stylised open hand (Shigaraki's 'Decay' hands): palm + 4 fingers + thumb."""
    parts = [box(f"{name}_palm", (1.1 * s, 0.35 * s, 1.2 * s), (0, 0, 0), (0, 0, 0), material, bev=0.08 * s, col=col)]
    for k, fx in enumerate((-0.42, -0.14, 0.14, 0.42)):
        ln = (0.95, 1.1, 1.05, 0.85)[k] * s
        parts.append(cyl(f"{name}_f{k}", 0.13 * s, ln, (fx * s, 0, 0.6 * s + ln / 2), (0, 0, 0), material, verts=8, r2=0.1 * s, col=col))
    parts.append(cyl(f"{name}_th", 0.14 * s, 0.75 * s, (-0.72 * s, 0, 0.1 * s), (0, -50, 0), material, verts=8, r2=0.1 * s, col=col))
    ob = join(parts, name)
    return _place(ob, loc, rot)


def banner(name, w, h, loc, rot, material, rng, torn=True, wave=0.35, col=None):
    """Hanging cloth with a torn bottom edge and a gentle wave (solidified)."""
    bm = bmesh.new()
    cols, rows = 10, 14
    grid = []
    for r in range(rows + 1):
        row = []
        for c in range(cols + 1):
            x = -w / 2 + w * c / cols
            z = -h * r / rows
            if torn and r == rows:
                z -= rng.uniform(0, h * 0.18)
            y = math.sin(c / cols * math.pi * 2 + r * 0.3) * wave * (r / rows)
            row.append(bm.verts.new((x, y, z)))
        grid.append(row)
    for r in range(rows):
        for c in range(cols):
            if torn and r == rows - 1 and rng.random() < 0.25:
                continue
            bm.faces.new((grid[r][c], grid[r][c + 1], grid[r + 1][c + 1], grid[r + 1][c]))
    ob = _obj_from_bm(name, bm, material, col)
    sol = ob.modifiers.new("Solid", "SOLIDIFY")
    sol.thickness = 0.12
    return _place(ob, loc, rot)


def join(objs, name):
    objs = [o for o in objs if o]
    if len(objs) == 1:
        objs[0].name = name
        return objs[0]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        if o.name not in bpy.context.view_layer.objects:
            continue
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    for o in objs:
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = name
    return objs[0]


# ─────────────────────────────────────────────────────────────── render ──
def look_at(cam, target):
    d = Vector(target) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()


def setup_render(sky="#2a1850", sky_strength=1.0, res=(1280, 720), samples=48, sky_light=None, ambient="#ffffff"):
    """`sky_light`: if set, the sky keeps its colour for camera rays but lights the scene with
    `ambient` at this strength (mimics Roblox, where sky colour and Ambient are independent)."""
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = False
    sc.cycles.max_bounces = 4
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Filmic" if "Filmic" in [e.identifier for e in sc.view_settings.bl_rna.properties["view_transform"].enum_items] else "Standard"
    w = bpy.data.worlds.new("World")
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = hexc(sky)
    bg.inputs["Strength"].default_value = sky_strength
    if sky_light is not None:
        nt = w.node_tree
        amb = nt.nodes.new("ShaderNodeBackground")
        amb.inputs["Color"].default_value = hexc(ambient)
        amb.inputs["Strength"].default_value = sky_light
        lp = nt.nodes.new("ShaderNodeLightPath")
        mix = nt.nodes.new("ShaderNodeMixShader")
        out = nt.nodes["World Output"]
        nt.links.new(lp.outputs["Is Camera Ray"], mix.inputs[0])
        nt.links.new(amb.outputs[0], mix.inputs[1])
        nt.links.new(bg.outputs[0], mix.inputs[2])
        nt.links.new(mix.outputs[0], out.inputs["Surface"])
    sc.world = w
    return sc


def sun(name, rot, strength=2.0, color="#ffffff", angle=4.0):
    ld = bpy.data.lights.new(name, "SUN")
    ld.energy = strength
    ld.color = hexc(color)[:3]
    ld.angle = math.radians(angle)
    ob = bpy.data.objects.new(name, ld)
    ob.rotation_euler = Euler([math.radians(r) for r in rot])
    bpy.context.scene.collection.objects.link(ob)
    return ob


def point(name, loc, power, color, radius=0.5):
    ld = bpy.data.lights.new(name, "POINT")
    ld.energy = power
    ld.color = hexc(color)[:3]
    ld.shadow_soft_size = radius
    ob = bpy.data.objects.new(name, ld)
    ob.location = Vector(loc)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def render(path, cam_loc, target, lens=24, res=None):
    sc = bpy.context.scene
    cam = bpy.data.objects.get("ReviewCam")
    if not cam:
        cd = bpy.data.cameras.new("ReviewCam")
        cam = bpy.data.objects.new("ReviewCam", cd)
        sc.collection.objects.link(cam)
    cam.data.lens = lens
    cam.data.clip_end = 2000
    cam.location = Vector(cam_loc)
    look_at(cam, target)
    sc.camera = cam
    if res:
        sc.render.resolution_x, sc.render.resolution_y = res
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("RENDERED", path)


# ─────────────────────────────────────────────────────────────── export ──
def tri_count(ob):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    me = ev.to_mesh()
    me.calc_loop_triangles()
    n = len(me.loop_triangles)
    ev.to_mesh_clear()
    return n


# ───────────────────────────────────────────────────── world layers + validation ──
# Each world owns local y in [-30, 230] (build.luau ZoneMinZ = z0 - 30: the 30-stud entry threshold belongs to the
# world; the next world's threshold starts at 230). Since the Owner's World Production Correction Directive this slot
# is a GAMEPLAY constraint (PLAYABLE / BOUNDARY / BOSS_STAGE / PROPS / colliders), not a visual limit:
# BACKGROUND may extend beyond it as long as it is non-collidable and stays out of the neighbours' playable corridor.
WORLD_SLOT_Y = (-30.0, 228.0)
WORLD_STRIDE = 260.0
NEIGHBOUR_CORRIDOR_X = 82.0   # half-width of every world's playable/boundary footprint (walls sit at |x| <= ~81)
SKY_MIN_Z = 120.0              # background wholly above this is sky-level scenery (never meets a player)
LANE = 54.0
LAYERS = {  # layer -> (collides in Roblox, strict gameplay-slot bounds)
    "PLAYABLE": (True, True),     # floors, route, egg interaction areas
    "BOUNDARY": (True, True),     # intentional outside boundaries (walls, balustrades, gate piers, end walls)
    "BOSS_STAGE": (True, True),   # boss dais / stairs / stage platforms
    "PROPS": (False, True),       # in-world decoration (lanterns, banners, statues, furniture, rubble, ...)
    "BACKGROUND": (False, False), # scenery / depth layers (skylines, stands, cliffs, towers, sea, mesas, ...)
    "SKY": (False, False),        # sky-level objects (planets, moons); may become a Roblox Sky at import
}
_layer_cfg = {"rules": [], "default": "PROPS"}


def set_layers(rules, default="PROPS"):
    """rules: list of (EXPORT module-name prefix, LAYER); the longest matching prefix wins."""
    for _, lay in rules:
        assert lay in LAYERS, lay
    _layer_cfg["rules"] = list(rules)
    _layer_cfg["default"] = default


def module_layer(mod):
    best = None
    for pre, lay in _layer_cfg["rules"]:
        if mod.startswith(pre) and (best is None or len(pre) > len(best[0])):
            best = (pre, lay)
    return best[1] if best else _layer_cfg["default"]


def _export_cols():
    for col in list(bpy.data.collections):
        if col.name.startswith("EXPORT_"):
            yield col, col.name[len("EXPORT_"):].partition("__")[0]


def organize(world_id):
    """Collection pass: WORLD_<id>/<id>_{PLAYABLE,BOUNDARY,BOSS_STAGE,PROPS,BACKGROUND,SKY,COLLISION,VFX_ANCHORS}."""
    scene_root = bpy.context.scene.collection
    root = collection(f"WORLD_{world_id}")
    parents = {lay: collection(f"{world_id}_{lay}", root) for lay in list(LAYERS) + ["COLLISION", "VFX_ANCHORS"]}

    def move(col, parent):
        for p in list(bpy.data.collections) + [scene_root]:
            if p is not parent and col.name in p.children:
                p.children.unlink(col)
        if col.name not in parent.children:
            parent.children.link(col)

    for col, mod in list(_export_cols()):
        lay = module_layer(mod)
        col["sae_layer"] = lay
        move(col, parents[lay])
    if bpy.data.collections.get("COLLIDERS"):
        move(bpy.data.collections["COLLIDERS"], parents["COLLISION"])
    if bpy.data.collections.get("VFX"):
        move(bpy.data.collections["VFX"], parents["VFX_ANCHORS"])


def _aabb(ob, dg):
    ev = ob.evaluated_get(dg)
    pts = [ob.matrix_world @ Vector(c) for c in ev.bound_box]
    return (min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts),
            max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts))


def validate(world_id, walk_half=75.0, exit_min=16.0, lane_clear_y=(0.0, 186.0)):
    """Gameplay-safety validation per layer (Owner directive §6). Stored in the manifest by export_modules.
    1 strict layers + colliders inside the gameplay slot      2 BACKGROUND beyond the slot stays out of the
    neighbours' playable corridor (|x| < 82, below sky level) 3 no collidable blocker in the running lane
    4 continuous floor over the walkable area (no falls)      5 walkable exit opening + 6 visible exit opening (ray casts through the exit band, see below)"""
    import numpy as np
    dg = bpy.context.evaluated_depsgraph_get()
    Y0, Y1 = WORLD_SLOT_Y
    objs = []  # (name, module, layer, collides, aabb, transparency)
    for col, mod in _export_cols():
        lay = module_layer(mod)
        for o in col.all_objects:
            if o.type != "MESH":
                continue
            m = o.data.materials[0] if o.data.materials else None
            objs.append((o.name, mod, lay, LAYERS[lay][0], _aabb(o, dg), m.get("roblox_transparency", 0.0) if m else 0.0))
    ccol = bpy.data.collections.get("COLLIDERS")
    colliders = [(o.name, "Collider", "COLLISION", True, _aabb(o, dg), 0.0) for o in (ccol.all_objects if ccol else [])]
    V = {"slot": [], "neighbourCorridor": [], "laneBlocked": []}
    for (n, mod, lay, _c, bb, _t) in objs + colliders:
        strict = True if lay == "COLLISION" else LAYERS[lay][1]
        if strict and (bb[1] < Y0 - 0.05 or bb[4] > Y1 + 0.05):
            V["slot"].append(f"{lay}:{mod}:{n} y[{bb[1]:.1f},{bb[4]:.1f}]")
    for (n, mod, lay, _c, bb, _t) in objs:
        if lay == "BACKGROUND" and (bb[1] < Y0 - 0.05 or bb[4] > Y1 + 0.05):
            if bb[0] < NEIGHBOUR_CORRIDOR_X and bb[3] > -NEIGHBOUR_CORRIDOR_X and bb[2] < SKY_MIN_Z:
                V["neighbourCorridor"].append(f"{mod}:{n} x[{bb[0]:.1f},{bb[3]:.1f}] y[{bb[1]:.1f},{bb[4]:.1f}]")
    for (n, mod, lay, c, bb, _t) in objs + colliders:
        if (c and "Pedestal" not in mod and bb[0] < LANE and bb[3] > -LANE and bb[1] < lane_clear_y[1]
                and bb[4] > lane_clear_y[0] and bb[5] > 2.0 and bb[2] < 12.0):
            V["laneBlocked"].append(f"{lay}:{mod}:{n}")
    # 3b: BACKGROUND is non-collidable by design, so it must not stand in the walkable area at ground level
    #     (players would walk through it); such pieces belong to BOUNDARY
    V["walkThroughScenery"] = [f"{mod}:{n}" for (n, mod, lay, _c, bb, _t) in objs
                               if lay == "BACKGROUND" and bb[0] < walk_half - 0.5 and bb[3] > -walk_half + 0.5
                               and bb[1] < Y1 - 0.5 and bb[4] > Y0 + 0.5 and bb[2] < 3.0 and bb[5] > 4.0]
    xs = np.arange(-walk_half + 1.0, walk_half - 0.99, 2.0)
    ys = np.arange(Y0 + 1.0, Y1 - 0.99, 2.0)
    cov = np.zeros((len(xs), len(ys)), dtype=bool)
    for (n, mod, lay, _c, bb, _t) in objs:
        if lay in ("PLAYABLE", "BOSS_STAGE") and bb[2] <= 0.5 and -1.5 <= bb[5] <= 9.0:
            ix = np.where((xs >= bb[0]) & (xs <= bb[3]))[0]
            iy = np.where((ys >= bb[1]) & (ys <= bb[4]))[0]
            if len(ix) and len(iy):
                cov[ix[0]:ix[-1] + 1, iy[0]:iy[-1] + 1] = True
    V["floorGaps"] = int((~cov).sum())
    V["floorSamples"] = int(cov.size)
    # 5/6: ray casts along +y through the exit band [Y1-8, Y1+0.5]: a column is blocked for walking when a ray at
    # z 3/5/7 (above step height) meets a collidable surface, and blocked for sight when a ray at z 2/5/8 meets an
    # opaque surface. Rays pass through everything else. Real geometry, so arches and gates are handled exactly.
    info = {o[0]: (o[2], o[3], o[5]) for o in objs}
    info.update({o[0]: ("COLLISION", True, 1.0) for o in colliders})
    scene = bpy.context.scene

    def blocked(x, zs, test):
        for z in zs:
            org, left = Vector((x, Y1 - 8.0, z)), 8.5
            for _ in range(24):
                hit, loc, _n, _i, ob, _m = scene.ray_cast(dg, org, Vector((0, 1, 0)), distance=left)
                if not hit:
                    break
                meta = info.get(ob.name)
                if meta and test(*meta):
                    return True
                step = (loc - org).length + 0.02
                org, left = loc + Vector((0, 0.02, 0)), left - step
                if left <= 0:
                    break
        return False

    xs_ = [(-walk_half + 0.25) + 0.5 * i for i in range(int(walk_half * 4))]
    walk_cols = [blocked(x, (3.0, 5.0, 7.0), lambda lay, c, tr: c) for x in xs_]
    vis_cols = [blocked(x, (2.0, 5.0, 8.0), lambda lay, c, tr: lay != "COLLISION" and tr < 0.5) for x in xs_]

    def longest(cols):
        best = run = 0
        for bl in cols:
            run = 0 if bl else run + 1
            best = max(best, run)
        return best * 0.5

    V["exitWalkRun"] = longest(walk_cols)
    V["exitVisibleRun"] = longest(vis_cols)
    V["exitMin"], V["walkHalf"] = exit_min, walk_half
    V["layerCounts"] = {lay: len({o[1] for o in objs if o[2] == lay}) for lay in LAYERS}
    V["pass"] = (not V["slot"] and not V["neighbourCorridor"] and not V["laneBlocked"] and not V["walkThroughScenery"] and V["floorGaps"] == 0
                 and V["exitWalkRun"] >= exit_min and V["exitVisibleRun"] >= exit_min)
    print(f"VALIDATION {world_id}: {'PASS' if V['pass'] else 'FAIL'} slot={len(V['slot'])} corridor={len(V['neighbourCorridor'])} "
          f"lane={len(V['laneBlocked'])} walkThrough={len(V['walkThroughScenery'])} floorGaps={V['floorGaps']}/{V['floorSamples']} exitWalk={V['exitWalkRun']:.1f} "
          f"exitVisible={V['exitVisibleRun']:.1f} layers={V['layerCounts']}")
    for k in ("slot", "neighbourCorridor", "laneBlocked", "walkThroughScenery"):
        for v in V[k][:8]:
            print(f"  {k}: {v}")
    return V


def _export_group(objs, mod, rmat, out_dir, manifest, layer):
    # per-object bounds (before joining) for precise cross-world checks
    dg = bpy.context.evaluated_depsgraph_get()
    obj_bounds = [[round(v, 2) for v in _aabb(o, dg)] for o in objs]
    # duplicate → apply modifiers → join (the editable objects in the .blend stay untouched)
    dups = []
    for o in objs:
        d = o.copy()
        d.data = o.data.copy()
        bpy.context.scene.collection.objects.link(d)
        dups.append(d)
    bpy.ops.object.select_all(action="DESELECT")
    for d in dups:
        bpy.context.view_layer.objects.active = d
        for m in list(d.modifiers):
            bpy.ops.object.modifier_apply(modifier=m.name)
    for d in dups:
        d.select_set(True)
    bpy.context.view_layer.objects.active = dups[0]
    if len(dups) > 1:
        bpy.ops.object.join()
    j = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    tris = tri_count(j)
    vs = [j.matrix_world @ v.co for v in j.data.vertices]
    bmin = [min(v[i] for v in vs) for i in range(3)]
    bmax = [max(v[i] for v in vs) for i in range(3)]
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    c = j.location.copy()
    dims = j.dimensions.copy()
    j.location = (0, 0, 0)
    path = os.path.join(out_dir, f"{mod}.fbx")
    bpy.ops.object.select_all(action="DESELECT")
    j.select_set(True)
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, apply_unit_scale=True, global_scale=1.0,
                             axis_forward="Z", axis_up="Y", bake_space_transform=True, mesh_smooth_type="FACE", add_leaf_bones=False)
    mats = [m for m in j.data.materials if m]
    manifest["modules"].append({
        "module": mod, "fbx": os.path.basename(path), "layer": layer, "canCollide": LAYERS[layer][0],
        "robloxMaterial": rmat or "SmoothPlastic", "triangles": tris, "overLimit": tris > TRI_LIMIT,
        "boundsLocal": [round(v, 2) for v in bmin + bmax],  # Blender world-local x,y,z min then max
        "objectBounds": obj_bounds,  # per source object, same frame
        "robloxPosition": [round(-c.x, 3), round(c.z, 3), round(c.y, 3)],
        "sizeStuds": [round(dims.x, 3), round(dims.z, 3), round(dims.y, 3)],
        "materials": sorted({m.name for m in mats}),
        "color": mats[0].get("roblox_color", "") if mats else "",
        "transparency": max([m.get("roblox_transparency", 0.0) for m in mats] or [0.0]),
    })
    bpy.data.objects.remove(j, do_unlink=True)


def module_groups():
    """Export pieces as (piece name, Roblox material, objects, module). A Roblox MeshPart has one Color, so each
    EXPORT_<Module>__<Material> collection is split into one piece per Blender material.
    Naming: a piece is called <Module> only when that module name belongs to exactly one collection AND the
    collection has one material; otherwise it is <Module>_<MaterialSuffix>. (Before this rule, modules split across
    several collections, e.g. EXPORT_ShadowArmy__Fabric + EXPORT_ShadowArmy__Neon, both wrote ShadowArmy.fbx and one
    overwrote the other.) Names are deterministic and verified unique."""
    cols = [(c, *c.name[len("EXPORT_"):].partition("__")[::2]) for c in bpy.data.collections if c.name.startswith("EXPORT_")]
    uses = {}
    for c, mod, rmat in cols:
        uses[mod] = uses.get(mod, 0) + 1
    out = []
    for c, mod, rmat in cols:
        objs = [o for o in c.all_objects if o.type == "MESH"]
        groups = {}
        for o in objs:
            m = o.data.materials[0] if o.data.materials else None
            groups.setdefault(m.name if m else "", []).append(o)
        for mname, gobjs in sorted(groups.items()):
            sub = mod if (len(groups) == 1 and uses[mod] == 1) else f"{mod}_{mname.split('_', 1)[-1]}"
            out.append((sub, rmat, gobjs, mod))
    names = [o[0] for o in out]
    dup = sorted({n for n in names if names.count(n) > 1})
    assert not dup, f"duplicate export piece names: {dup}"
    return out


def export_combined_scene(fbx_path, report_path, world_id, source_blend=""):
    """One FBX containing every export piece at its world-local position (Studio's importer keeps only the last file
    of a multi-file import, so worlds are imported as one scene). Same axis/unit settings as the per-piece exports.
    Pieces are temporary joined copies; the editable source objects are untouched and nothing is saved."""
    made, report = [], {"world": world_id, "source": source_blend, "fbx": os.path.basename(fbx_path),
                        "mapping": "Roblox(X,Y,Z) = (-x, z, z0 + y) * importScale", "pieces": []}
    dg = bpy.context.evaluated_depsgraph_get()
    for sub, rmat, gobjs, mod in module_groups():
        dups = []
        for o in gobjs:
            d = o.copy()
            d.data = o.data.copy()
            bpy.context.scene.collection.objects.link(d)
            dups.append(d)
        bpy.ops.object.select_all(action="DESELECT")
        for d in dups:
            bpy.context.view_layer.objects.active = d
            for m in list(d.modifiers):
                bpy.ops.object.modifier_apply(modifier=m.name)
        for d in dups:
            d.select_set(True)
        bpy.context.view_layer.objects.active = dups[0]
        if len(dups) > 1:
            bpy.ops.object.join()
        j = bpy.context.view_layer.objects.active
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
        j.name = sub
        j.data.name = sub
        c, dims = j.location.copy(), j.dimensions.copy()
        mats = [m for m in j.data.materials if m]
        report["pieces"].append({
            "piece": sub, "module": mod, "layer": module_layer(mod), "canCollide": LAYERS[module_layer(mod)][0],
            "robloxMaterial": rmat or "SmoothPlastic", "color": mats[0].get("roblox_color", "") if mats else "",
            "transparency": max([m.get("roblox_transparency", 0.0) for m in mats] or [0.0]), "triangles": tri_count(j),
            "blenderCenter": [round(v, 4) for v in c], "blenderSize": [round(v, 4) for v in dims],
            "robloxPosition": [round(-c.x, 3), round(c.z, 3), round(c.y, 3)],
            "sizeStuds": [round(dims.x, 3), round(dims.z, 3), round(dims.y, 3)]})
        made.append(j)
    bpy.ops.object.select_all(action="DESELECT")
    for j in made:
        j.select_set(True)
    os.makedirs(os.path.dirname(fbx_path), exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=fbx_path, use_selection=True, apply_unit_scale=True, global_scale=1.0,
                             axis_forward="Z", axis_up="Y", bake_space_transform=True, mesh_smooth_type="FACE", add_leaf_bones=False)
    report["pieceCount"] = len(made)
    report["triangles"] = sum(p["triangles"] for p in report["pieces"])
    for j in made:
        bpy.data.objects.remove(j, do_unlink=True)
    with open(report_path, "w") as f:
        json.dump(report, f, indent=1)
    return report


def export_modules(out_dir, z0_note, world_id, validation=None):
    """Join every EXPORT_* collection into one mesh (temporary copies), write FBX + manifest.
    The editable objects in the .blend are left untouched."""
    os.makedirs(out_dir, exist_ok=True)
    manifest = {"worldSlotY": list(WORLD_SLOT_Y), "layers": {k: {"collides": v[0], "strictSlot": v[1]} for k, v in LAYERS.items()}, "world": world_id, "units": "1 Blender unit = 1 stud", "mapping": "Roblox(X,Y,Z) = (-x, z, z0 + y)", "z0": z0_note, "modules": [], "anchors": []}
    for sub, rmat, gobjs, mod in module_groups():
        _export_group(gobjs, sub, rmat, out_dir, manifest, module_layer(mod))
    for ob in bpy.data.objects:
        if ob.type == "EMPTY" and ob.name.startswith("VFX_"):
            p = ob.matrix_world.translation
            manifest["anchors"].append({"name": ob.name, "robloxPosition": [round(-p.x, 3), round(p.z, 3), round(p.y, 3)], "kind": ob.get("vfx", "")})
    manifest["colliders"] = []
    col = bpy.data.collections.get("COLLIDERS")
    for ob in (col.all_objects if col else []):
        p, d = ob.matrix_world.translation, ob.dimensions
        manifest["colliders"].append({"name": ob.name, "robloxPosition": [round(-p.x, 3), round(p.z, 3), round(p.y, 3)],
                                      "sizeStuds": [round(d.x, 3), round(d.z, 3), round(d.y, 3)]})
    if validation is not None:
        manifest["validation"] = validation
    with open(os.path.join(out_dir, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1)
    return manifest
