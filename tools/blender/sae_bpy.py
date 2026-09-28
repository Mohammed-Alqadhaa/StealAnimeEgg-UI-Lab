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


# Each world owns local y in [-30, 230] (build.luau ZoneMinZ = z0 - 30: the 30-stud entry threshold belongs to
# the world; the next world's threshold starts at 230). Geometry must stay inside, or neighbours intersect.
WORLD_SLOT_Y = (-30.0, 228.0)


def _export_group(objs, mod, rmat, out_dir, manifest):
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
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    tris = tri_count(j)
    ys = [(j.matrix_world @ v.co).y for v in j.data.vertices]
    outside = (min(ys) < WORLD_SLOT_Y[0] - 0.01 or max(ys) > WORLD_SLOT_Y[1] + 0.01) and not mod.startswith("Sky")
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
        "module": mod, "fbx": os.path.basename(path), "robloxMaterial": rmat or "SmoothPlastic",
        "triangles": tris, "overLimit": tris > TRI_LIMIT, "outsideSlot": outside,
        "slotY": [round(min(ys), 2), round(max(ys), 2)],
        "robloxPosition": [round(-c.x, 3), round(c.z, 3), round(c.y, 3)],
        "sizeStuds": [round(dims.x, 3), round(dims.z, 3), round(dims.y, 3)],
        "materials": sorted({m.name for m in mats}),
        "color": mats[0].get("roblox_color", "") if mats else "",
        "transparency": max([m.get("roblox_transparency", 0.0) for m in mats] or [0.0]),
    })
    bpy.data.objects.remove(j, do_unlink=True)


def export_modules(out_dir, z0_note, world_id):
    """Join every EXPORT_* collection into one mesh (temporary copies), write FBX + manifest.
    The editable objects in the .blend are left untouched."""
    os.makedirs(out_dir, exist_ok=True)
    manifest = {"worldSlotY": list(WORLD_SLOT_Y), "world": world_id, "units": "1 Blender unit = 1 stud", "mapping": "Roblox(X,Y,Z) = (-x, z, z0 + y)", "z0": z0_note, "modules": [], "anchors": []}
    for col in list(bpy.data.collections):
        if not col.name.startswith("EXPORT_"):
            continue
        mod, _, rmat = col.name[len("EXPORT_"):].partition("__")
        objs = [o for o in col.all_objects if o.type == "MESH"]
        if not objs:
            continue
        # A Roblox MeshPart has one Color: split multi-material modules into one sub-module per material.
        groups = {}
        for o in objs:
            m = o.data.materials[0] if o.data.materials else None
            groups.setdefault(m.name if m else "", []).append(o)
        for mname, gobjs in sorted(groups.items()):
            sub = mod if len(groups) == 1 else f"{mod}_{mname.split('_', 1)[-1]}"
            _export_group(gobjs, sub, rmat, out_dir, manifest)
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
    with open(os.path.join(out_dir, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1)
    return manifest
