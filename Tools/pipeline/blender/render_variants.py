# -*- coding: utf-8 -*-
"""render_variants.py - Blender (5.2) headless renderer for CY-Source review.py.

  blender.exe -b --factory-startup -P render_variants.py -- <job.json>

job.json = {"size": 512, "samples": 32, "front": [0,-1,0], "ambient": 0.45, "key": 3.0, "fill": 1.0,
            "rim": 1.8, "views": [["f", 35, 15], ["b", 215, 15]],
            "objects": [{"oid": "...", "out": "<dir>", "variants": [{"vid": "...", "glb": "..."}]}]}

Camera/light rule (identical for every variant of an object, so they are comparable):
  * every variant GLB of the object is imported into one empty scene and posed at the first
    frame of its single animation (review.py picks DefaultAnimation / 站立 / 休闲) or bind pose;
  * posed vertices that leave the bind-pose box expanded by 100 % per axis are ignored for
    framing (parts that an idle animation parks far away, e.g. props at Z -5000 or CY weapon
    bones at Y -9000; the engine shows them nowhere either);
  * per view, ONE perspective camera (50 mm) is fitted to the projected silhouette of the
    kept vertices of ALL variants together (8 % margin), so relative size stays visible;
  * 3 sun lights (key / fill / rim) placed relative to the camera + flat white ambient world;
    Eevee, Standard view transform, transparent film (review.py adds the neutral grey).
Writes <out>/<vid>_<tag>.png and <out>/result.json; reads only the GLB files of the job.
"""
import json
import math
import os
import sys
import time
import traceback

import bpy
import numpy as np
from mathutils import Matrix, Vector

FIT_POINTS = 60000       # per variant, for the camera fit


def job_args():
    a = sys.argv
    return a[a.index('--') + 1:] if '--' in a else []


def try_set(obj, attr, val):
    try:
        setattr(obj, attr, val)
        return True
    except (AttributeError, TypeError, ValueError):
        return False


def set_engine(sc):
    items = [e.identifier for e in sc.render.bl_rna.properties['engine'].enum_items]
    for eng in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT'):
        if eng in items:
            sc.render.engine = eng
            return eng
    sc.render.engine = 'CYCLES'
    return 'CYCLES'


def setup_scene(cfg):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    eng = set_engine(sc)
    r = sc.render
    r.resolution_x = r.resolution_y = int(cfg.get('size', 512))
    r.resolution_percentage = 100
    r.film_transparent = True
    r.image_settings.file_format = 'PNG'
    r.image_settings.color_mode = 'RGBA'
    try_set(r.image_settings, 'color_depth', '8')
    vs = sc.view_settings
    try_set(vs, 'view_transform', 'Standard')
    try_set(vs, 'look', 'None')
    vs.exposure = 0.0
    vs.gamma = 1.0
    ee = sc.eevee
    try_set(ee, 'taa_render_samples', int(cfg.get('samples', 32)))
    try_set(ee, 'use_shadows', True)
    try_set(ee, 'use_raytracing', False)
    w = bpy.data.worlds.new('ReviewWorld')
    sc.world = w
    try_set(w, 'use_nodes', True)
    nt = w.node_tree
    bg = next((n for n in nt.nodes if n.type == 'BACKGROUND'), None) or nt.nodes.new('ShaderNodeBackground')
    wo = next((n for n in nt.nodes if n.type == 'OUTPUT_WORLD'), None) or nt.nodes.new('ShaderNodeOutputWorld')
    if not bg.outputs[0].is_linked:
        nt.links.new(bg.outputs[0], wo.inputs[0])
    bg.inputs[0].default_value = (1.0, 1.0, 1.0, 1.0)
    bg.inputs[1].default_value = float(cfg.get('ambient', 0.45))
    cd = bpy.data.cameras.new('ReviewCam')
    cd.lens = 50.0
    cd.sensor_width = 36.0
    cd.sensor_fit = 'HORIZONTAL'
    cam = bpy.data.objects.new('ReviewCam', cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    suns = {}
    for name, strength, angle, shadow in (('key', cfg.get('key', 3.0), 12.0, True),
                                          ('fill', cfg.get('fill', 1.0), 25.0, False),
                                          ('rim', cfg.get('rim', 1.8), 10.0, False)):
        ld = bpy.data.lights.new('Review_' + name, 'SUN')
        ld.energy = float(strength)
        try_set(ld, 'angle', math.radians(angle))
        try_set(ld, 'use_shadow', shadow)
        ob = bpy.data.objects.new('Review_' + name, ld)
        sc.collection.objects.link(ob)
        suns[name] = ob
    return sc, cam, suns, eng


def import_glb(path):
    before = set(bpy.data.objects)
    kw = dict(filepath=path, import_shading='NORMALS', guess_original_bind_pose=True, bone_heuristic='BLENDER',
              disable_bone_shape=True, import_scene_as_collection=False, import_select_created_objects=False)
    try:
        bpy.ops.import_scene.gltf(**kw)
    except TypeError:
        for k in ('disable_bone_shape', 'import_scene_as_collection', 'import_select_created_objects'):
            kw.pop(k, None)
        bpy.ops.import_scene.gltf(**kw)
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        for slot in getattr(o, 'material_slots', []):
            m = slot.material
            if m is not None:
                try_set(m, 'use_backface_culling', False)
                try_set(m, 'use_backface_culling_shadow', False)
    return new


def start_frame(objs):
    frames, names = [], []
    for o in objs:
        ad = o.animation_data
        if ad is None:
            continue
        if ad.action is not None:
            frames.append(ad.action.frame_range[0])
            names.append(ad.action.name)
            continue
        for tr in ad.nla_tracks:
            for st in tr.strips:
                if st.action is not None:
                    frames.append(st.frame_start)
                    names.append(st.action.name)
    return (int(round(min(frames))) if frames else None), names


def _to_world(co, M):
    M = np.array(M)
    return co @ M[:3, :3].T + M[:3, 3]


def posed_points(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in objs:
        if o.type != 'MESH':
            continue
        oe = o.evaluated_get(dg)
        me = oe.to_mesh()
        try:
            n = len(me.vertices)
            if n:
                co = np.empty(n * 3, np.float64)
                me.vertices.foreach_get('co', co)
                pts.append(_to_world(co.reshape(-1, 3), oe.matrix_world))
        finally:
            oe.to_mesh_clear()
    return np.concatenate(pts) if pts else None


def rest_points(objs):
    pts = []
    for o in objs:
        if o.type != 'MESH' or not len(o.data.vertices):
            continue
        co = np.empty(len(o.data.vertices) * 3, np.float64)
        o.data.vertices.foreach_get('co', co)
        pts.append(_to_world(co.reshape(-1, 3), o.matrix_world))
    return np.concatenate(pts) if pts else None


def keep_points(posed, rest):
    """Drop posed vertices far outside the bind-pose box (see module doc)."""
    if rest is None or not len(rest):
        return posed, 0
    rlo, rhi = rest.min(0), rest.max(0)
    ext = rhi - rlo
    ext = np.maximum(ext, 0.5 * max(float(ext.max()), 1e-6))
    keep = np.all((posed >= rlo - ext) & (posed <= rhi + ext), axis=1)
    if keep.mean() >= 0.5:
        return posed[keep], int((~keep).sum())
    lo, hi = np.percentile(posed, 2.0, axis=0), np.percentile(posed, 98.0, axis=0)   # whole model moved
    e2 = np.maximum(hi - lo, 1e-6)
    keep = np.all((posed >= lo - 0.5 * e2) & (posed <= hi + 0.5 * e2), axis=1)
    return posed[keep], int((~keep).sum())


def view_dir(front, az, el):
    f = Vector((front[0], front[1], 0.0))
    f = f.normalized() if f.length > 1e-9 else Vector((0.0, -1.0, 0.0))
    h = Matrix.Rotation(math.radians(az), 3, 'Z') @ f
    e = math.radians(el)
    return (h * math.cos(e) + Vector((0.0, 0.0, 1.0)) * math.sin(e)).normalized()


def fit_camera(cam, pts, dirv, margin=0.92):
    """Perspective camera looking along -dirv that frames the projected silhouette of pts."""
    z = dirv.normalized()
    x = Vector((0.0, 0.0, 1.0)).cross(z)
    x = x.normalized() if x.length > 1e-6 else Vector((1.0, 0.0, 0.0))
    y = z.cross(x)
    X, Y, Z = np.array(x), np.array(y), np.array(z)
    px, py, pz = pts @ X, pts @ Y, pts @ Z
    cx, cy, cz = (px.min() + px.max()) / 2, (py.min() + py.max()) / 2, (pz.min() + pz.max()) / 2
    t = (cam.data.sensor_width / 2.0) / cam.data.lens * margin
    d = float(np.max((pz - cz) + np.maximum(np.abs(px - cx), np.abs(py - cy)) / t))
    size = float(max(px.max() - px.min(), py.max() - py.min(), pz.max() - pz.min(), 1e-4))
    d = max(d, size * 0.6, 1e-3)
    center = Vector((cx * X + cy * Y + cz * Z).tolist())
    return Matrix.Translation(center + z * d) @ Matrix((x, y, z)).transposed().to_4x4(), d, size


def aim_suns(suns, front, az):
    for name, daz, el2 in (('key', 45.0, 40.0), ('fill', -60.0, 10.0), ('rim', 165.0, 35.0)):
        dv = view_dir(front, az + daz, el2)
        suns[name].rotation_mode = 'QUATERNION'
        suns[name].rotation_quaternion = dv.to_track_quat('Z', 'Y')


def show_only(allobjs, objs):
    vis = set(objs)
    for o in allobjs:
        o.hide_render = o not in vis


def render_object(job, ob):
    t0 = time.time()
    out = ob['out']
    os.makedirs(out, exist_ok=True)
    res = {'oid': ob['oid'], 'variants': {}, 'ok': False}
    sc, cam, suns, eng = setup_scene(job)
    res['engine'] = eng
    front = job.get('front', [0.0, -1.0, 0.0])
    loaded = []
    for v in ob['variants']:
        vr = {'ok': False}
        res['variants'][v['vid']] = vr
        tv = time.time()
        try:
            objs = import_glb(v['glb'])
            meshes = [o for o in objs if o.type == 'MESH']
            if not meshes:
                raise RuntimeError('glTF import produced no mesh object')
            fr, acts = start_frame(objs)
            vr.update(frame=fr, actions=acts, n_mesh_objects=len(meshes), import_s=round(time.time() - tv, 2))
            loaded.append((v, objs, fr))
        except Exception as ex:
            vr['error'] = 'import: %s: %s' % (type(ex).__name__, str(ex)[:300])
    allobjs = [o for _v, objs, _f in loaded for o in objs]
    fit = []
    for v, objs, fr in loaded:
        vr = res['variants'][v['vid']]
        show_only(allobjs, objs)
        sc.frame_set(fr if fr is not None else 1)
        p = posed_points(objs)
        if p is None or not len(p):
            vr['error'] = 'no vertices after evaluation'
            continue
        k, dropped = keep_points(p, rest_points(objs))
        if not len(k):
            k, dropped = p, 0
        vr.update(nverts=int(len(p)), dropped=dropped,
                  bbox=[[float(x) for x in k.min(0)], [float(x) for x in k.max(0)]])
        step = max(1, len(k) // FIT_POINTS)
        fit.append(k[::step])
    if not fit:
        res['error'] = 'nothing to render'
        res['time'] = round(time.time() - t0, 2)
        return res
    U = np.concatenate(fit)
    res['union_bbox'] = [[float(x) for x in U.min(0)], [float(x) for x in U.max(0)]]
    cams = {}
    for tag, az, el in job['views']:
        M, d, size = fit_camera(cam, U, view_dir(front, az, el))
        cams[tag] = (M, d, size, az)
    res['camera'] = {tag: {'dist': round(c[1], 4), 'size': round(c[2], 4)} for tag, c in cams.items()}
    for v, objs, fr in loaded:
        vr = res['variants'][v['vid']]
        if 'bbox' not in vr:
            continue
        tv = time.time()
        try:
            show_only(allobjs, objs)
            sc.frame_set(fr if fr is not None else 1)
            imgs = {}
            for tag, _az, _el in job['views']:
                M, d, size, az = cams[tag]
                cam.matrix_world = M
                cam.data.clip_start = max(d * 0.002, 1e-4)
                cam.data.clip_end = d + size * 20.0
                aim_suns(suns, front, az)
                path = os.path.join(out, '%s_%s.png' % (v['vid'], tag))
                sc.render.filepath = path
                bpy.ops.render.render(write_still=True)
                if not os.path.exists(path):
                    raise RuntimeError('render wrote no file: ' + path)
                imgs[tag] = path
            vr.update(ok=True, images=imgs, render_s=round(time.time() - tv, 2))
        except Exception as ex:
            vr['error'] = 'render: %s: %s' % (type(ex).__name__, str(ex)[:300])
    res['ok'] = any(v.get('ok') for v in res['variants'].values())
    res['time'] = round(time.time() - t0, 2)
    return res


def main():
    a = job_args()
    if not a:
        print('usage: blender -b -P render_variants.py -- job.json')
        return
    with open(a[0], encoding='utf-8') as f:
        job = json.load(f)
    print('REVIEW-BLENDER', bpy.app.version_string, 'objects', len(job['objects']), flush=True)
    for ob in job['objects']:
        try:
            res = render_object(job, ob)
        except Exception as ex:
            res = {'oid': ob['oid'], 'ok': False, 'error': '%s: %s' % (type(ex).__name__, str(ex)[:300]),
                   'trace': traceback.format_exc()[-1500:], 'variants': {}}
        res['blender'] = bpy.app.version_string
        with open(os.path.join(ob['out'], 'result.json'), 'w', encoding='utf-8') as f:
            json.dump(res, f, ensure_ascii=False, indent=1)
        print('RESULT', ob['oid'], 'ok' if res.get('ok') else 'FAIL', res.get('time'), flush=True)


if __name__ == '__main__':
    main()
