#!/usr/bin/env python3
# CY-Source sky-enscene: which StaticEntity objects of a .Scene a d3d9 trace frame draws, against distance, scale and
# mesh bounding radius, to fit the far-object rule of CY 3.71 (camdiscull / builder window). Objects whose centre is
# inside the view frustum (with a margin) and farther than --min-dist are classified drawn / not drawn by matching
# the world translation of the frame's draws (<= 2 units).
# usage: cull_fit.py <frame> <Scene file> <Data dir> [--min-dist 4000]
import argparse
import json
import math
import os
import re
import struct


def load_frame(frame):
    eye = view = proj = None
    trans = []
    for line in open(os.path.join(frame, 'events.jsonl'), encoding='utf-8'):
        if '"ev":"draw"' not in line:
            continue
        d = json.loads(line)
        vsc = d.get('vsc') or {}
        v, p = vsc.get('view_matrix'), vsc.get('projection_matrix')
        if v and p and abs(p[15]) < 1e-6 and view is None:
            view, proj = v, p
        w = vsc.get('world_matrix')
        if w:
            trans.append((w[3], w[7], w[11]))
    r = [view[0:3], view[4:7], view[8:11]]
    t = [view[3], view[7], view[11]]
    eye = [-(r[0][i] * t[0] + r[1][i] * t[1] + r[2][i] * t[2]) for i in range(3)]
    return eye, view, proj, trans


def mesh_index(data):
    idx = {}
    for root, _, files in os.walk(data):
        for fn in files:
            if fn.lower().endswith('.mesh'):
                idx.setdefault(fn.lower(), os.path.join(root, fn))
    return idx


def mesh_radius(path):
    b = open(path, 'rb').read()
    i = b.find(struct.pack('<HI', 0x9000, 34))
    return struct.unpack_from('<f', b, i + 30)[0] if i >= 0 else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('frame')
    ap.add_argument('scene')
    ap.add_argument('data')
    ap.add_argument('--min-dist', type=float, default=4000)
    a = ap.parse_args()
    eye, view, proj, trans = load_frame(a.frame)
    grid = {}
    for p in trans:
        grid.setdefault((round(p[0] / 50), round(p[2] / 50)), []).append(p)
    idx = mesh_index(a.data)
    s = open(a.scene, 'rb').read().decode('utf-8', 'replace')
    rows = []
    for m in re.finditer(r'<Object type="StaticEntity"[^>]*>(.*?)</Object>', s, re.S):
        body = m.group(1)
        pm = re.search(r'name="position" value="([-\d.e]+) ([-\d.e]+) ([-\d.e]+)"', body)
        mm = re.search(r'name="mesh name" value="([^"]+)"', body)
        if not pm or not mm:
            continue
        pos = tuple(map(float, pm.groups()))
        sm = re.search(r'name="scale" value="([-\d.e]+) ([-\d.e]+) ([-\d.e]+)"', body)
        scale = max(map(float, sm.groups())) if sm else 1.0
        dist = math.sqrt(sum((pos[i] - eye[i]) ** 2 for i in range(3)))
        if dist < a.min_dist:
            continue
        # clip space (row-major matrices, column vectors)
        vx = [sum(view[r * 4 + c] * (list(pos) + [1])[c] for c in range(4)) for r in range(4)]
        cx = [sum(proj[r * 4 + c] * vx[c] for c in range(4)) for r in range(4)]
        if cx[3] <= 0 or abs(cx[0]) > cx[3] * 0.9 or abs(cx[1]) > cx[3] * 0.9:
            continue
        name = mm.group(1).split('/')[-1]
        try:
            fn = name.encode('gbk').decode('cp1252', errors='replace').lower()
        except UnicodeEncodeError:
            fn = name.lower()
        path = idx.get(fn) or idx.get(name.lower())
        rad = mesh_radius(path) if path else None
        drawn = any(abs(q[0] - pos[0]) <= 2 and abs(q[1] - pos[1]) <= 2 and abs(q[2] - pos[2]) <= 2
                    for q in grid.get((round(pos[0] / 50), round(pos[2] / 50)), []))
        rows.append(dict(dist=dist, scale=scale, rad=rad, drawn=drawn, pos=pos, name=name))
    rows.sort(key=lambda r: r['dist'])
    print('eye (%.1f, %.1f, %.1f); in-frustum StaticEntity beyond %.0f: %d, drawn %d' % (
        eye[0], eye[1], eye[2], a.min_dist, len(rows), sum(r['drawn'] for r in rows)))
    print('drawn  dist   scale radius dist/scale dist/radius dist/(radius*scale)  pos  name')
    for r in rows:
        rad = r['rad'] or 0
        print('%5s %6.0f %5.2f %6.0f %9.0f %9.2f %9.2f  (%.0f,%.0f,%.0f) %s' % (
            'Y' if r['drawn'] else '-', r['dist'], r['scale'], rad, r['dist'] / r['scale'],
            r['dist'] / rad if rad else 0, r['dist'] / (rad * r['scale']) if rad else 0,
            r['pos'][0], r['pos'][1], r['pos'][2], r['name']))
    for key in ('dist', 'dist/scale', 'dist/radius', 'dist/(radius*scale)'):
        def val(r):
            rad = r['rad'] or 1
            return {'dist': r['dist'], 'dist/scale': r['dist'] / r['scale'], 'dist/radius': r['dist'] / rad,
                    'dist/(radius*scale)': r['dist'] / (rad * r['scale'])}[key]
        dmax = max([val(r) for r in rows if r['drawn']] or [0])
        nmin = min([val(r) for r in rows if not r['drawn']] or [0])
        print('separation by %-20s drawn max %.3f  not-drawn min %.3f  %s' % (
            key, dmax, nmin, 'SEPARATES' if dmax < nmin else 'overlaps'))


if __name__ == '__main__':
    main()
