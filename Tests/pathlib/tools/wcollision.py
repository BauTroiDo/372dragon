#!/usr/bin/env python3
"""CYS-NAV: giải mã *.WCollision của CY (PathLib BuildingCollsionImpl, magic 0xff000002/0xff000001) và so với
*.Heightmap: mặt đi được của công trình (bục, cầu, bậc thang) cao hơn địa hình bao nhiêu.

  python wcollision.py <SceneFolder> <scene> <outdir> [--probe x,z ...]

Định dạng (đo từ cy_PathLib.dll: BuildingCollsionImpl slot1 FUN_180004580 -> slot4 FUN_180004a00 ->
FUN_180003d80; slot2 FUN_180004380 = tia thẳng đứng từ y=10000 xuống, lấy điểm chạm GẦN NHẤT = mặt trên cùng):
  u32 magic = 0xff000002
  u16 meshCount; meshCount x { u16 nv; nv x f32[3]; u16 nt; nt x u16[3] }
  f32[3] offset; f32[3] scale                           (toạ độ cảnh = (thế giới - offset) / scale)
  u16 instCount; instCount x { f32[3] scale; f32[3] pos; f32[4] quat (w,x,y,z); u16 mesh }   (42 byte)
  thế giới = T(pos) * R(quat) * S(scale) * v
magic 0xff000001 (và bản không magic của 0.85): u32 magic/version, u32 cellCount,
  cellCount x { i32 x, i32 z, u32 n, n x f32[9] }  (toạ độ cảnh sẵn)
Ra: <outdir>/<scene>_wcoll.json (số đo), <scene>_wcoll_height.png (xám = địa hình, màu = mặt công trình cao hơn),
     <scene>_wcoll_tris.bin (float32 x9 mỗi tam giác, toạ độ cảnh — cho test C++).
"""
import json
import math
import os
import struct
import sys

from PIL import Image


def quat_to_m3(w, x, y, z):
    # Ogre::Quaternion::ToRotationMatrix
    tx, ty, tz = 2 * x, 2 * y, 2 * z
    twx, twy, twz = tx * w, ty * w, tz * w
    txx, txy, txz = tx * x, ty * x, tz * x
    tyy, tyz, tzz = ty * y, tz * y, tz * z
    return [[1 - (tyy + tzz), txy - twz, txz + twy],
            [txy + twz, 1 - (txx + tzz), tyz - twx],
            [txz - twy, tyz + twx, 1 - (txx + tyy)]]


def read_wcollision(fn):
    d = open(fn, 'rb').read()
    p = 0
    (magic,) = struct.unpack_from('<I', d, p)
    tris = []
    info = {'magic': '0x%08x' % magic, 'bytes': len(d)}
    if magic == 0xff000002:
        p = 4
        (nm,) = struct.unpack_from('<H', d, p); p += 2
        meshes = []
        for _ in range(nm):
            (nv,) = struct.unpack_from('<H', d, p); p += 2
            v = struct.unpack_from('<%df' % (3 * nv), d, p); p += 12 * nv
            (nt,) = struct.unpack_from('<H', d, p); p += 2
            t = struct.unpack_from('<%dH' % (3 * nt), d, p); p += 6 * nt
            meshes.append(([(v[3 * i], v[3 * i + 1], v[3 * i + 2]) for i in range(nv)],
                           [(t[3 * i], t[3 * i + 1], t[3 * i + 2]) for i in range(nt)]))
        off = struct.unpack_from('<3f', d, p); p += 12
        sc = struct.unpack_from('<3f', d, p); p += 12
        (ni,) = struct.unpack_from('<H', d, p); p += 2
        insts = []
        for _ in range(ni):
            r = struct.unpack_from('<3f3f4fH', d, p); p += 42
            insts.append(r)
        info.update({'meshes': nm, 'offset': off, 'scale': sc, 'instances': ni, 'parsed': p})
        for r in insts:
            s, pos, q, mi = r[0:3], r[3:6], r[6:10], r[10]
            if mi >= len(meshes):
                continue
            m3 = quat_to_m3(*q)
            verts, idx = meshes[mi]
            tv = []
            for (vx, vy, vz) in verts:
                sx, sy, sz = vx * s[0], vy * s[1], vz * s[2]
                wx = m3[0][0] * sx + m3[0][1] * sy + m3[0][2] * sz + pos[0]
                wy = m3[1][0] * sx + m3[1][1] * sy + m3[1][2] * sz + pos[1]
                wz = m3[2][0] * sx + m3[2][1] * sy + m3[2][2] * sz + pos[2]
                tv.append(((wx - off[0]) / sc[0], (wy - off[1]) / sc[1], (wz - off[2]) / sc[2]))
            for (a, b, c) in idx:
                if a < len(tv) and b < len(tv) and c < len(tv):
                    tris.append((tv[a], tv[b], tv[c]))
    else:
        p = 4
        (n,) = struct.unpack_from('<I', d, p); p += 4
        for _ in range(n):
            x, z, k = struct.unpack_from('<iiI', d, p); p += 12
            for _ in range(k):
                f = struct.unpack_from('<9f', d, p); p += 36
                tris.append(((f[0], f[1], f[2]), (f[3], f[4], f[5]), (f[6], f[7], f[8])))
        info.update({'cells': n, 'parsed': p})
    info['tris'] = len(tris)
    return tris, info


def read_heightmap(fn):
    d = open(fn, 'rb').read()
    ver, w, h = struct.unpack_from('<III', d, 4)
    import array
    a = array.array('f'); a.frombytes(d[16:16 + w * h * 4])
    return w, h, a


def main():
    a = sys.argv[1:]
    if len(a) < 3:
        print(__doc__)
        return 2
    folder, scene, outdir = a[0], a[1], a[2]
    probes = []
    i = 3
    while i < len(a):
        if a[i] == '--probe':
            probes.append(tuple(float(v) for v in a[i + 1].split(','))); i += 2
        else:
            i += 1
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(folder, scene)
    tris, info = read_wcollision(base + '.WCollision')
    W, H, hm = read_heightmap(base + '.Heightmap')

    def terrain(x, z):
        x = min(max(x, 0.0), W - 1.001); z = min(max(z, 0.0), H - 1.001)
        ix, iz = int(x), int(z); fx, fz = x - ix, z - iz
        h00 = hm[iz * W + ix]; h10 = hm[iz * W + ix + 1]; h01 = hm[(iz + 1) * W + ix]; h11 = hm[(iz + 1) * W + ix + 1]
        return (h00 * (1 - fx) + h10 * fx) * (1 - fz) + (h01 * (1 - fx) + h11 * fx) * fz

    # lưới ô nguyên (như bản đồ POINT_2D của 0.85)
    cells = {}
    for ti, t in enumerate(tris):
        x0 = int(math.floor(min(v[0] for v in t))); x1 = int(math.floor(max(v[0] for v in t)))
        z0 = int(math.floor(min(v[2] for v in t))); z1 = int(math.floor(max(v[2] for v in t)))
        for gx in range(x0, x1 + 1):
            for gz in range(z0, z1 + 1):
                cells.setdefault((gx, gz), []).append(ti)

    def top(x, z):
        best = None
        for ti in cells.get((int(math.floor(x)), int(math.floor(z))), ()):
            (ax, ay, az), (bx, by, bz), (cx, cy, cz) = tris[ti]
            den = (bx - ax) * (cz - az) - (bz - az) * (cx - ax)
            if abs(den) < 1e-9:
                continue
            u = ((x - ax) * (cz - az) - (z - az) * (cx - ax)) / den
            v = ((z - az) * (bx - ax) - (x - ax) * (bz - az)) / den
            if u >= 0 and v >= 0 and u + v <= 1:
                y = ay + u * (by - ay) + v * (cy - ay)
                if best is None or y > best:
                    best = y
        return best

    scale = 3
    img = Image.new('RGB', (W * scale, H * scale))
    px = img.load()
    above = covered = 0
    maxd = 0.0
    for gz in range(0, H - 1):
        for gx in range(0, W - 1):
            x, z = gx + 0.5, gz + 0.5
            t = terrain(x, z)
            b = top(x, z)
            g = int(max(0, min(255, 60 + t * 6)))
            col = (g, g, g)
            if b is not None:
                covered += 1
                dd = b - t
                if dd > 0.05:
                    above += 1
                    maxd = max(maxd, dd)
                    k = int(max(0, min(255, dd * 60)))
                    col = (255, 255 - k, 0) if dd < 4 else (255, 0, min(255, int(dd * 20)))
                else:
                    col = (0, 150, 255)
            for yy in range(scale):
                for xx in range(scale):
                    px[gx * scale + xx, gz * scale + yy] = col
    img.save(os.path.join(outdir, scene + '_wcoll_height.png'))
    info.update({'cells_covered_1u': covered, 'cells_building_above_terrain_1u': above,
                 'max_building_minus_terrain': round(maxd, 3)})
    pr = []
    for (x, z) in probes:
        t = terrain(x, z); b = top(x, z)
        pr.append({'x': x, 'z': z, 'terrain': round(t, 3), 'building_top': None if b is None else round(b, 3)})
    info['probes'] = pr
    with open(os.path.join(outdir, scene + '_wcoll_tris.bin'), 'wb') as f:
        for t in tris:
            f.write(struct.pack('<9f', *t[0], *t[1], *t[2]))
    with open(os.path.join(outdir, scene + '_wcoll.json'), 'w', encoding='utf-8') as f:
        json.dump(info, f, ensure_ascii=False, indent=1)
    print(json.dumps(info, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    sys.exit(main())
