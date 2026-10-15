#!/usr/bin/env python3
# CY-Source sky-enscene: match the scene draws of two d3d9 trace frames taken at the same camera by (vertex count,
# index count, world translation rounded to 1 unit) and list what only one side draws, with the distance to the eye
# and the world scale (a proxy of the object's size). usage: draw_match.py <cy frame> <proj frame> [--min-dist 4000]
import argparse
import json
import math
from collections import Counter


def load(frame):
    eye = None
    out = []
    scene_pass = None
    for line in open(frame + '/events.jsonl', encoding='utf-8'):
        if '"ev":"draw"' not in line:
            continue
        d = json.loads(line)
        vsc = d.get('vsc') or {}
        v, p = vsc.get('view_matrix'), vsc.get('projection_matrix')
        if v and p and abs(p[15]) < 1e-6 and eye is None:
            r = [v[0:3], v[4:7], v[8:11]]
            t = [v[3], v[7], v[11]]
            eye = [-(r[0][i] * t[0] + r[1][i] * t[1] + r[2][i] * t[2]) for i in range(3)]
            scene_pass = d['pass']
        w = vsc.get('world_matrix')
        kind = 'static'
        if not w:
            arr = vsc.get('world_matrix_array_3x4')
            if isinstance(arr, dict) and arr.get('head'):
                w = arr['head'][:12]
                kind = 'skinned'
        if not w:
            continue
        out.append((d, w, kind))
    rows = []
    for d, w, kind in out:
        if d['pass'] != scene_pass:
            continue
        pos = (w[3], w[7], w[11])
        scale = math.sqrt(w[0] ** 2 + w[4] ** 2 + w[8] ** 2)
        dist = math.sqrt(sum((pos[i] - eye[i]) ** 2 for i in range(3)))
        key = (d.get('nv'), d.get('pc'), round(pos[0]), round(pos[1]), round(pos[2]))
        rows.append(dict(key=key, dist=dist, scale=scale, kind=kind, px=d.get('px') or 0, n=d['n'], ps=d.get('ps'),
                         nv=d.get('nv'), pos=pos))
    return eye, rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cy')
    ap.add_argument('proj')
    ap.add_argument('--min-dist', type=float, default=4000)
    ap.add_argument('--top', type=int, default=25)
    a = ap.parse_args()
    ecy, cy = load(a.cy)
    epr, pr = load(a.proj)
    print('eye CY %s proj %s' % (['%.1f' % x for x in ecy], ['%.1f' % x for x in epr]))
    kcy = Counter(r['key'] for r in cy)
    kpr = Counter(r['key'] for r in pr)
    both = sum((kcy & kpr).values())
    print('draws CY %d proj %d matched %d' % (len(cy), len(pr), both))
    only_pr = [r for r in pr if kpr[r['key']] > kcy.get(r['key'], 0)]
    only_cy = [r for r in cy if kcy[r['key']] > kpr.get(r['key'], 0)]
    for label, rows in (('only CY-Source', only_pr), ('only CY', only_cy)):
        far = [r for r in rows if r['dist'] >= a.min_dist]
        print('%s: %d draws, %d at >= %.0f (px %d)' % (label, len(rows), len(far), a.min_dist, sum(r['px'] for r in far)))
        buckets = Counter((int(r['dist'] // 2000) * 2000, r['kind']) for r in rows)
        for (b, k), c in sorted(buckets.items()):
            print('   %6d-%-6d %-8s %d' % (b, b + 2000, k, c))
        for r in sorted(far, key=lambda r: -r['px'])[:a.top]:
            print('   dist %.0f #%d %s nv %s scale %.2f px %d pos (%.0f,%.0f,%.0f)' % (
                r['dist'], r['n'], r['kind'], r['nv'], r['scale'], r['px'], r['pos'][0], r['pos'][1], r['pos'][2]))
    matched_far = [r for r in cy if r['dist'] >= a.min_dist and kpr.get(r['key'], 0)]
    print('CY far draws also drawn by CY-Source: %d; their distances %s' % (
        len(matched_far), sorted(int(r['dist']) for r in matched_far)[-10:]))


if __name__ == '__main__':
    main()
