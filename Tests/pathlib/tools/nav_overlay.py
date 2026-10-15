#!/usr/bin/env python3
"""CYS-NAV: đo navmesh *.path so với đa giác *.Region (nguồn dựng navmesh của CY) và công trình trong *.Scene.

  python nav_overlay.py <SceneFolder> <scene> <outdir> [--crop x0,z0,x1,z1] [--scale 6] [--start 160,150]

Ra:
  <outdir>/<scene>_overlay.png       toàn cảnh: trắng = đi được, đỏ nhạt = navmesh chặn, xanh lam = cạnh Region,
                                     đen = cạnh ràng buộc navmesh, chấm xám = StaticEntity (.Scene)
  <outdir>/<scene>_overlay_crop.png  vùng --crop phóng to
  <outdir>/<scene>_overlay.json      số đo: tỉ lệ diện tích Region nằm trong ô chặn, tia từ --start cắt Region/navmesh
Toạ độ: .path / .Region = toạ độ lưới cảnh (= server). .Scene: grid = (world - centre)/scale + size/2.
"""
import json
import math
import re
import struct
import sys
import os

from PIL import Image, ImageDraw


def read_path(fn):
    data = open(fn, 'rb').read()
    pos = 0
    (ver,) = struct.unpack_from('<H', data, pos); pos += 2
    wide = ver == 0x2000
    fmt = '<I' if wide else '<H'
    sz = 4 if wide else 2

    def un():
        nonlocal pos
        (v,) = struct.unpack_from(fmt, data, pos); pos += sz
        return v

    npt = un()
    flat = struct.unpack_from('<%df' % (2 * npt), data, pos); pos += 8 * npt
    pts = [(flat[2 * i], flat[2 * i + 1]) for i in range(npt)]
    ntri = un()
    tris = []
    for _ in range(ntri):
        v0, v1, v2, n0, n1, n2 = un(), un(), un(), un(), un(), un()
        flag = data[pos]; pos += 1
        extra = un()
        tris.append((v0, v1, v2, flag, extra, n0, n1, n2))
    nedge = un()
    edges = []
    for _ in range(nedge):
        a, b, t1, t2 = un(), un(), un(), un()
        edges.append((a, b, t1, t2))
    return pts, tris, edges


def read_region(fn):
    data = open(fn, 'rb').read()
    pos = 0
    newver = data[:14] == b'REGION_EDIT_01'
    if newver:
        pos = 14
    (n,) = struct.unpack_from('<i', data, pos); pos += 4
    regs = []
    for _ in range(n):
        (rid,) = struct.unpack_from('<i', data, pos); pos += 4
        fly = 0
        if newver:
            (fly,) = struct.unpack_from('<i', data, pos); pos += 4
        (np_,) = struct.unpack_from('<i', data, pos); pos += 4
        pts = []
        for _ in range(np_):
            x, z, y = struct.unpack_from('<3f', data, pos); pos += 12
            pts.append((x, z, y))
        regs.append({'id': rid, 'fly': fly, 'pts': pts})
    return regs, pos, len(data)


def read_scene_entities(scene_fn, terrain_fn):
    txt = open(scene_fn, 'r', encoding='utf-8', errors='replace').read()
    ter = open(terrain_fn, 'r', encoding='utf-8', errors='replace').read()
    xs = int(re.search(r'xsize="(\d+)"', ter).group(1))
    zs = int(re.search(r'zsize="(\d+)"', ter).group(1))
    sc = re.search(r'<scale x="([-\d.e]+)" y="([-\d.e]+)" z="([-\d.e]+)"', ter)
    ce = re.search(r'<centre x="([-\d.e]+)" y="([-\d.e]+)" z="([-\d.e]+)"', ter)
    sx, sz = float(sc.group(1)), float(sc.group(3))
    cx, cz = float(ce.group(1)), float(ce.group(3))
    ents = []
    for m in re.finditer(r'<Object type="(\w+)"(.*?)</Object>', txt, re.S):
        typ, body = m.group(1), m.group(2)
        mesh = re.search(r'name="(?:mesh name|model name)" value="([^"]*)"', body)
        p = re.search(r'name="position" value="([-\d.e]+) ([-\d.e]+) ([-\d.e]+)"', body)
        if not p:
            continue
        wx, wy, wz = float(p.group(1)), float(p.group(2)), float(p.group(3))
        ents.append({'type': typ, 'mesh': mesh.group(1) if mesh else '',
                     'x': (wx - cx) / sx + xs / 2.0, 'z': (wz - cz) / sz + zs / 2.0, 'y': wy})
    return ents, (xs, zs, sx, sz, cx, cz)


def point_in_poly(x, z, poly):
    inside = False
    n = len(poly)
    j = n - 1
    for i in range(n):
        xi, zi = poly[i][0], poly[i][1]
        xj, zj = poly[j][0], poly[j][1]
        if ((zi > z) != (zj > z)) and (x < (xj - xi) * (z - zi) / (zj - zi + 1e-12) + xi):
            inside = not inside
        j = i
    return inside


def seg_hit(p, q, a, b):
    """Tham số t (0..1) trên pq nơi cắt đoạn ab, hoặc None."""
    rx, rz = q[0] - p[0], q[1] - p[1]
    sx, sz = b[0] - a[0], b[1] - a[1]
    den = rx * sz - rz * sx
    if abs(den) < 1e-12:
        return None
    qpx, qpz = a[0] - p[0], a[1] - p[1]
    t = (qpx * sz - qpz * sx) / den
    u = (qpx * rz - qpz * rx) / den
    if 0.0 <= t <= 1.0 and 0.0 <= u <= 1.0:
        return t
    return None


class TriGrid:
    def __init__(self, pts, tris, cell=4.0):
        self.pts, self.tris, self.cell = pts, tris, cell
        self.g = {}
        for ti, t in enumerate(tris):
            a, b, c = pts[t[0]], pts[t[1]], pts[t[2]]
            x0 = int(math.floor(min(a[0], b[0], c[0]) / cell)); x1 = int(math.floor(max(a[0], b[0], c[0]) / cell))
            z0 = int(math.floor(min(a[1], b[1], c[1]) / cell)); z1 = int(math.floor(max(a[1], b[1], c[1]) / cell))
            for gx in range(x0, x1 + 1):
                for gz in range(z0, z1 + 1):
                    self.g.setdefault((gx, gz), []).append(ti)

    def tri_at(self, x, z):
        for ti in self.g.get((int(math.floor(x / self.cell)), int(math.floor(z / self.cell))), ()):
            t = self.tris[ti]
            a, b, c = self.pts[t[0]], self.pts[t[1]], self.pts[t[2]]
            d1 = (x - b[0]) * (a[1] - b[1]) - (a[0] - b[0]) * (z - b[1])
            d2 = (x - c[0]) * (b[1] - c[1]) - (b[0] - c[0]) * (z - c[1])
            d3 = (x - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (z - a[1])
            neg = d1 < 0 or d2 < 0 or d3 < 0
            pos = d1 > 0 or d2 > 0 or d3 > 0
            if not (neg and pos):
                return ti
        return -1


def main():
    a = sys.argv[1:]
    if len(a) < 3:
        print(__doc__)
        return 2
    folder, scene, outdir = a[0], a[1], a[2]
    crop = (130.0, 120.0, 200.0, 190.0)
    scale = 6.0
    start = (160.0, 150.0)
    i = 3
    while i < len(a):
        if a[i] == '--crop':
            crop = tuple(float(v) for v in a[i + 1].split(',')); i += 2
        elif a[i] == '--scale':
            scale = float(a[i + 1]); i += 2
        elif a[i] == '--start':
            start = tuple(float(v) for v in a[i + 1].split(',')); i += 2
        else:
            i += 1
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(folder, scene)
    pts, tris, edges = read_path(base + '.path')
    regs, rpos, rlen = read_region(base + '.Region')
    ents, terr = read_scene_entities(base + '.Scene', base + '.Terrain')
    xs, zs = terr[0], terr[1]
    tg = TriGrid(pts, tris)
    rep = {'scene': scene, 'path': {'points': len(pts), 'tris': len(tris), 'edges': len(edges),
                                    'blocked_tris': sum(1 for t in tris if t[3] & 1)},
           'region': {'count': len(regs), 'parsed_bytes': rpos, 'file_bytes': rlen,
                      'fly_nonzero': sum(1 for r in regs if r['fly'])},
           'terrain': {'xsize': xs, 'zsize': zs}, 'entities': len(ents)}

    # 1. diện tích Region nằm trong ô chặn navmesh (lấy mẫu lưới 0.5)
    inside_total = inside_blocked = inside_outside = 0
    per_region_bad = []
    for r in regs:
        poly = r['pts']
        if len(poly) < 3:
            continue
        x0 = min(p[0] for p in poly); x1 = max(p[0] for p in poly)
        z0 = min(p[1] for p in poly); z1 = max(p[1] for p in poly)
        n_in = n_bl = 0
        x = math.floor(x0 * 2) / 2 + 0.25
        while x <= x1:
            z = math.floor(z0 * 2) / 2 + 0.25
            while z <= z1:
                if point_in_poly(x, z, poly):
                    n_in += 1
                    ti = tg.tri_at(x, z)
                    if ti < 0:
                        inside_outside += 1
                    elif tris[ti][3] & 1:
                        n_bl += 1
                z += 0.5
            x += 0.5
        inside_total += n_in
        inside_blocked += n_bl
        if n_in >= 4 and n_bl < 0.9 * n_in:
            per_region_bad.append({'id': r['id'], 'fly': r['fly'], 'samples': n_in, 'blocked': n_bl,
                                   'bbox': [round(x0, 1), round(z0, 1), round(x1, 1), round(z1, 1)]})
    rep['region_vs_path'] = {'samples_inside_region': inside_total, 'blocked': inside_blocked,
                             'outside_mesh': inside_outside,
                             'blocked_ratio': round(inside_blocked / max(1, inside_total), 4),
                             'regions_under_90pct': len(per_region_bad), 'worst': per_region_bad[:30]}
    # ngược lại: ô chặn navmesh nằm ngoài mọi Region (vùng chặn không có đa giác)
    # (lấy mẫu thô 1.0 để nhanh)
    reg_bbox = []
    for r in regs:
        poly = r['pts']
        if len(poly) >= 3:
            reg_bbox.append((min(p[0] for p in poly), min(p[1] for p in poly), max(p[0] for p in poly),
                             max(p[1] for p in poly), poly))
    rgrid = {}
    for bi, (x0, z0, x1, z1, _) in enumerate(reg_bbox):
        for gx in range(int(x0 // 8), int(x1 // 8) + 1):
            for gz in range(int(z0 // 8), int(z1 // 8) + 1):
                rgrid.setdefault((gx, gz), []).append(bi)

    def in_any_region(x, z):
        for bi in rgrid.get((int(x // 8), int(z // 8)), ()):
            x0, z0, x1, z1, poly = reg_bbox[bi]
            if x0 <= x <= x1 and z0 <= z <= z1 and point_in_poly(x, z, poly):
                return True
        return False

    walk_in_region = blk = blk_no_region = 0
    for gx in range(0, xs):
        for gz in range(0, zs):
            x, z = gx + 0.5, gz + 0.5
            ti = tg.tri_at(x, z)
            if ti < 0:
                continue
            inr = in_any_region(x, z)
            if tris[ti][3] & 1:
                blk += 1
                if not inr:
                    blk_no_region += 1
            elif inr:
                walk_in_region += 1
    rep['path_vs_region_1u'] = {'blocked_samples': blk, 'blocked_outside_regions': blk_no_region,
                                'walkable_inside_regions': walk_in_region}

    # 2. tia từ start: nơi đầu tiên cắt cạnh Region và cạnh ràng buộc navmesh
    rays = []
    for k in range(24):
        ang = 2 * math.pi * k / 24
        q = (start[0] + 60 * math.cos(ang), start[1] + 60 * math.sin(ang))
        tr = None
        for r in regs:
            poly = r['pts']
            for j in range(len(poly)):
                t = seg_hit(start, q, poly[j], poly[(j + 1) % len(poly)])
                if t is not None and (tr is None or t < tr):
                    tr = t
        te = None
        for e in edges:
            if e[0] == e[1]:
                continue
            t = seg_hit(start, q, pts[e[0]], pts[e[1]])
            if t is not None and (te is None or t < te):
                te = t
        rays.append({'deg': k * 15, 'region_hit': None if tr is None else round(tr * 60, 2),
                     'path_edge_hit': None if te is None else round(te * 60, 2)})
    rep['rays_from_start'] = {'start': start, 'len': 60, 'rays': rays}
    ti = tg.tri_at(*start)
    rep['start_tri'] = {'tri': ti, 'flag': tris[ti][3] if ti >= 0 else None, 'region': tris[ti][4] if ti >= 0 else None}

    # 3. ảnh
    def render(x0, z0, x1, z1, sc, fn):
        W, H = int((x1 - x0) * sc), int((z1 - z0) * sc)
        img = Image.new('RGB', (W, H), (255, 255, 255))
        d = ImageDraw.Draw(img)

        def P(x, z):
            return ((x - x0) * sc, (z - z0) * sc)
        for t in tris:
            if t[3] & 1:
                d.polygon([P(*pts[t[0]]), P(*pts[t[1]]), P(*pts[t[2]])], fill=(250, 190, 190))
        for e in edges:
            if e[0] != e[1]:
                d.line([P(*pts[e[0]]), P(*pts[e[1]])], fill=(0, 0, 0), width=1)
        for r in regs:
            poly = [P(p[0], p[1]) for p in r['pts']]
            if len(poly) >= 2:
                d.line(poly + [poly[0]], fill=(30, 80, 255) if not r['fly'] else (0, 170, 0), width=1)
        for en in ents:
            if en['type'] in ('StaticEntity', 'Model') and x0 <= en['x'] <= x1 and z0 <= en['z'] <= z1:
                cx, cz = P(en['x'], en['z'])
                d.ellipse([cx - 1.5, cz - 1.5, cx + 1.5, cz + 1.5], fill=(110, 110, 110))
        sx_, sz_ = P(*start)
        d.ellipse([sx_ - 4, sz_ - 4, sx_ + 4, sz_ + 4], fill=(0, 200, 0))
        img.save(fn)
    render(0, 0, xs, zs, 3.0, os.path.join(outdir, scene + '_overlay.png'))
    render(crop[0], crop[1], crop[2], crop[3], scale, os.path.join(outdir, scene + '_overlay_crop.png'))
    with open(os.path.join(outdir, scene + '_overlay.json'), 'w', encoding='utf-8') as f:
        json.dump(rep, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: v for k, v in rep.items() if k not in ('rays_from_start',)}, ensure_ascii=False)[:3000])
    print('rays', [(r['deg'], r['region_hit'], r['path_edge_hit']) for r in rays])
    return 0


if __name__ == '__main__':
    sys.exit(main())
