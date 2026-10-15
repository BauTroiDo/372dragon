#!/usr/bin/env python3
"""CYS: vẽ navmesh *.path (client_GL) + các đường đi/click của navmesh_test ra PNG (bằng chứng).

  python draw_navmesh.py <scene.path> <paths.json> <out.png> [--scale 4] [--crop x0,z0,x1,z1]

Định dạng *.path: memory tlbb-path-navmesh-format (0x2000 = u32, 0x1000 = u16). Toạ độ .path = toạ độ thế giới.
Màu: trắng = đi được, đỏ nhạt = bị chặn, đen = cạnh ràng buộc (tường), xanh lam = đường FindPath, cam = click
mô phỏng, chấm đỏ = click vào ô chặn (vòng chuột đỏ), chấm xanh lục = điểm xuất phát.
"""
import json
import struct
import sys

from PIL import Image, ImageDraw


def read_path(fn):
    data = open(fn, 'rb').read()
    pos = 0
    (ver,) = struct.unpack_from('<H', data, pos); pos += 2
    wide = ver == 0x2000
    if ver not in (0x1000, 0x2000):
        raise SystemExit('bad version %x' % ver)

    def un():
        nonlocal pos
        if wide:
            (v,) = struct.unpack_from('<I', data, pos); pos += 4
        else:
            (v,) = struct.unpack_from('<H', data, pos); pos += 2
        return v

    npt = un()
    pts = list(struct.unpack_from('<%df' % (2 * npt), data, pos)); pos += 8 * npt
    pts = [(pts[2 * i], pts[2 * i + 1]) for i in range(npt)]
    ntri = un()
    tris = []
    for _ in range(ntri):
        v0, v1, v2, n0, n1, n2 = un(), un(), un(), un(), un(), un()
        flag = data[pos]; pos += 1
        extra = un()
        tris.append((v0, v1, v2, flag, extra))
    nedge = un()
    edges = []
    for _ in range(nedge):
        a, b, t1, t2 = un(), un(), un(), un()
        edges.append((a, b))
    return pts, tris, edges


def main():
    args = sys.argv[1:]
    if len(args) < 3:
        print(__doc__)
        return 2
    scene, pj, out = args[0], args[1], args[2]
    scale = 4.0
    crop = None
    i = 3
    while i < len(args):
        if args[i] == '--scale':
            scale = float(args[i + 1]); i += 2
        elif args[i] == '--crop':
            crop = [float(v) for v in args[i + 1].split(',')]; i += 2
        else:
            i += 1
    pts, tris, edges = read_path(scene)
    info = json.load(open(pj, encoding='utf-8'))
    maxx = max(p[0] for p in pts); maxz = max(p[1] for p in pts)
    if crop is None:
        crop = [0, 0, maxx, maxz]
    x0, z0, x1, z1 = crop
    W = int((x1 - x0) * scale) + 1
    H = int((z1 - z0) * scale) + 1
    img = Image.new('RGB', (W, H), (245, 245, 245))
    d = ImageDraw.Draw(img)

    def P(p):  # world -> pixel (z lên trên: lật trục để nhìn như bản đồ)
        return ((p[0] - x0) * scale, (z1 - p[1]) * scale)

    for v0, v1, v2, flag, extra in tris:
        poly = [P(pts[v0]), P(pts[v1]), P(pts[v2])]
        if flag & 1:
            d.polygon(poly, fill=(235, 170, 170))
        else:
            d.polygon(poly, fill=(255, 255, 255), outline=(225, 225, 225))
    for a, b in edges:
        d.line([P(pts[a]), P(pts[b])], fill=(40, 40, 40), width=max(1, int(scale / 3)))

    # lưới 8 đơn vị mờ
    step = 8
    gx = int(x0 // step) * step
    while gx <= x1:
        d.line([P((gx, z0)), P((gx, z1))], fill=(210, 210, 230), width=1); gx += step
    gz = int(z0 // step) * step
    while gz <= z1:
        d.line([P((x0, gz)), P((x1, gz))], fill=(210, 210, 230), width=1); gz += step

    def dot(p, col, r=None):
        r = r or max(3, scale)
        x, y = P(p)
        d.ellipse([x - r, y - r, x + r, y + r], fill=col, outline=(0, 0, 0))

    start = info['start']
    for k, path in enumerate(info.get('paths', [])):
        seq = [start] + path['way']
        d.line([P(p) for p in seq], fill=(30, 90, 220), width=max(2, int(scale / 2)))
        for p in path['way'][:-1]:
            dot(p, (30, 90, 220), max(2, scale * 0.6))
        dot(path['to'], (30, 90, 220))
        d.text(P(path['to']), 'P%d' % k, fill=(0, 0, 120))
    for k, c in enumerate(info.get('clicks', [])):
        seq = [c['from']] + c['way']
        if len(seq) >= 2:
            d.line([P(p) for p in seq], fill=(240, 130, 20), width=max(2, int(scale / 2)))
        dot(c['click'], (220, 30, 30) if c['blocked'] else (240, 130, 20))
        d.text(P(c['click']), 'C%d%s' % (k + 1, ' (chan)' if c['blocked'] else ''), fill=(120, 0, 0) if c['blocked'] else (120, 60, 0))
    if 'blocked' in info:
        dot(info['blocked'], (220, 30, 30))
    dot(start, (30, 180, 60))
    d.text(P(start), 'start', fill=(0, 100, 0))
    img.save(out)
    print('wrote', out, W, 'x', H, 'tris', len(tris), 'edges', len(edges))
    return 0


if __name__ == '__main__':
    sys.exit(main())
