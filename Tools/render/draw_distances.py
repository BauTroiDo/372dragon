#!/usr/bin/env python3
# CY-Source sky-enscene: how far from the eye the scene draws of a d3d9 trace frame are (CysD3D9Trace events.jsonl):
# eye from view_matrix, near/far from projection_matrix, object origin from world_matrix (or the first 3x4 of
# world_matrix_array_3x4); histogram of drawn distances by kind (terrain / static / skinned / other) and the farthest
# draws with pixels. usage: draw_distances.py <frame> [--top 15] [--pass N]
import argparse
import json
import math


def inv_rigid(m):
    # row-major 4x4 [r00 r01 r02 tx; ...]: eye = -R^T t
    r = [m[0:3], m[4:7], m[8:11]]
    t = [m[3], m[7], m[11]]
    return [-(r[0][i] * t[0] + r[1][i] * t[1] + r[2][i] * t[2]) for i in range(3)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('frame')
    ap.add_argument('--top', type=int, default=15)
    ap.add_argument('--pass', dest='pass_', type=int, default=0)
    a = ap.parse_args()
    eye = None
    proj = None
    rows = []
    scene_pass = None
    for line in open(a.frame + '/events.jsonl', encoding='utf-8'):
        if '"ev":"draw"' not in line:
            continue
        d = json.loads(line)
        vsc = d.get('vsc') or {}
        v = vsc.get('view_matrix')
        p = vsc.get('projection_matrix')
        if v and p and abs(p[15]) < 1e-6:          # perspective scene draw
            if eye is None or (a.pass_ and d['pass'] == a.pass_):
                eye = inv_rigid(v)
                proj = p
                scene_pass = d['pass']
        w = vsc.get('world_matrix')
        kind = 'static'
        if not w:
            arr = vsc.get('world_matrix_array_3x4')
            if isinstance(arr, dict) and arr.get('head'):
                w = arr['head'][:12] + [0, 0, 0, 1]
                kind = 'skinned'
        if not w:
            continue
        if d.get('tex') and any(isinstance(t, dict) and str(t.get('id', '')).startswith('rt') for t in d['tex'].values()):
            pass
        rows.append((d, w, kind))
    if eye is None:
        print('no perspective scene draw')
        return
    # D3D projection row-major: z' = p10*z + p11, w = -z (RH) -> near/far
    A, B = proj[10], proj[11]
    near = B / A if A else 0
    far = B / (A + 1) if (A + 1) else 0
    print('eye (%.1f, %.1f, %.1f) near %.1f far %.1f (scene pass %s)' % (eye[0], eye[1], eye[2], abs(near), abs(far), scene_pass))
    fogs = set()
    buckets = {}
    drawn = []
    for d, w, kind in rows:
        if d['pass'] != scene_pass:
            continue
        pos = (w[3], w[7], w[11])
        dist = math.sqrt(sum((pos[i] - eye[i]) ** 2 for i in range(3)))
        psc = d.get('psc') or {}
        fp = psc.get('fog_params') or (d.get('vsc') or {}).get('fog_params')
        if fp:
            fogs.add(tuple(round(x, 5) for x in fp[:3]))
        b = int(dist // 2000) * 2000
        key = (kind, b)
        c = buckets.setdefault(key, [0, 0, 0])
        c[0] += 1
        c[1] += 1 if (d.get('px') or 0) > 0 else 0
        c[2] += d.get('px') or 0
        drawn.append((dist, d['n'], kind, d.get('nv'), d.get('px') or 0, d.get('vs'), d.get('ps')))
    print('fog params seen', sorted(fogs)[:4])
    print('distance bucket (m*100)  kind     draws  with_px  px')
    for (kind, b) in sorted(buckets, key=lambda k: (k[0], k[1])):
        c = buckets[(kind, b)]
        print('  %6d-%-6d %-8s %6d %7d %9d' % (b, b + 2000, kind, c[0], c[1], c[2]))
    drawn.sort(reverse=True)
    print('farthest draws (dist, #, kind, nv, px, vs, ps):')
    for r in drawn[:a.top]:
        print('  %.0f #%d %s nv %s px %d %s %s' % r)
    withpx = [r for r in drawn if r[4] > 0]
    if withpx:
        print('farthest draw with pixels: %.0f (#%d)' % (withpx[0][0], withpx[0][1]))


if __name__ == '__main__':
    main()
