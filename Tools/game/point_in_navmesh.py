# -*- coding: utf-8 -*-
"""CY-Source Tools/game/point_in_navmesh.py (scenes-lo2 18/09): diem (x,z) co nam trong tam giac DI DUOC nao cua <map>.path (v2 0x2000 / v1 0x1000) khong? [DK]

Bo cuc .path (memory tlbb-path-navmesh-format, be tu PathLib.dll):
  u16 version; u32 pointCount; pointCount x {f32 x, f32 z}; u32 triCount;
  triCount x { u32 v0,v1,v2; u32 n0,n1,n2; u8 flag (bit0 = BI CHAN); u32 extra (vung lien thong) } (29 byte)
  (v1 0x1000: moi so u16, tam giac 15 byte)
Chay: python -X utf8 16-point-in-navmesh.py  -> in bang + ghi 16-point-in-navmesh.json
"""
import json, os, struct

CYS = r'C:\TLBB\085\CY-Source'
SCENE = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'SceneFolder')
OUT = os.path.join(CYS, 'Build', 'Logs', '2026-09-17-scenes-lo2', '16-point-in-navmesh.json')

# (nhan, ban do, x, z, nguon cua toa do)
DIEM = [
    ('1326 diem vao maps-instance', 'erengu', 58.23, 100.28, 'trong tam "da giac" tu erengu_1.path doc kieu 5 diem'),
    ('1326 de nghi: quai 山流儿', 'erengu', 111.0, 120.0, 'erengu_monster.ini'),
    ('1326 de nghi: quai 印祖', 'erengu', 133.0, 122.0, 'erengu_monster.ini'),
    ('quai gan nhat 齐小环', 'erengu', 50.0, 141.0, 'erengu_monster.ini'),
    ('125 diem vao da dung', 'huashan', 138.28, 130.88, 'huashan_monster.ini 吴铭'),
    ('410 diem vao da dung', 'shengsileitai', 12.0, 33.0, 'shengsileitai_monster.ini 枯荣大师'),
    ('130 diem vao da dung', 'shaolin', 92.43, 83.93, 'shaolin_1_monster.ini (dong 130 dung shaolin.path)'),
    ('hoi sinh mac dinh canh 2', 'dali_new_320', 160.0, 150.0, 'define.DEFAULT_SCENEID_AND_WORLD_POS'),
    ('NPC dich chuyen -> Dai Ly', 'dali_new_320', 253.0, 121.0, 'transfer-npc handoff'),
    ('NPC dich chuyen -> Lac Duong', 'luoyang_new', 235.0, 322.0, 'transfer-npc handoff'),
    ('NPC dich chuyen -> To Chau', 'suzhou_new', 204.0, 256.0, 'transfer-npc handoff'),
    ('NPC dich chuyen -> Bien Kinh', 'bianjing', 530.0, 937.0, 'transfer-npc handoff'),
    ('NPC dich chuyen -> 1007', 'SnowWorld2024', 160.0, 290.0, 'transfer-npc handoff'),
]


def doc_path(p):
    b = open(p, 'rb').read()
    ver = struct.unpack_from('<H', b, 0)[0]
    o = 2
    if ver == 0x2000:
        n = struct.unpack_from('<I', b, o)[0]; o += 4
        pts = list(struct.unpack_from('<%df' % (2 * n), b, o)); o += 8 * n
        nt = struct.unpack_from('<I', b, o)[0]; o += 4
        tris = []
        for i in range(nt):
            v0, v1, v2, n0, n1, n2, fl, ex = struct.unpack_from('<IIIIIIBI', b, o); o += 29
            tris.append((v0, v1, v2, fl, ex))
    elif ver == 0x1000:
        n = struct.unpack_from('<H', b, o)[0]; o += 2
        pts = list(struct.unpack_from('<%df' % (2 * n), b, o)); o += 8 * n
        nt = struct.unpack_from('<H', b, o)[0]; o += 2
        tris = []
        for i in range(nt):
            v0, v1, v2, n0, n1, n2, fl, ex = struct.unpack_from('<HHHHHHBH', b, o); o += 15
            tris.append((v0, v1, v2, fl, ex))
    else:
        raise SystemExit('%s: version %#x la gi?' % (p, ver))
    return ver, [(pts[2 * i], pts[2 * i + 1]) for i in range(n)], tris


def trong(pt, a, b, c):
    (px, pz), (ax, az), (bx, bz), (cx, cz) = pt, a, b, c
    d1 = (px - bx) * (az - bz) - (ax - bx) * (pz - bz)
    d2 = (px - cx) * (bz - cz) - (bx - cx) * (pz - cz)
    d3 = (px - ax) * (cz - az) - (cx - ax) * (pz - az)
    neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    return not (neg and pos)


def main():
    cache = {}
    rows = []
    print('%-30s %-14s %8s %8s  %s' % ('diem', 'ban do', 'x', 'z', 'ket qua'))
    for nhan, m, x, z, nguon in DIEM:
        p = os.path.join(SCENE, m + '.path')
        if not os.path.isfile(p):
            # thu tim khong phan biet hoa thuong
            cand = [n for n in os.listdir(SCENE) if n.lower() == (m + '.path').lower()]
            p = os.path.join(SCENE, cand[0]) if cand else p
        if not os.path.isfile(p):
            rows.append({'diem': nhan, 'map': m, 'x': x, 'z': z, 'ket_qua': 'KHONG CO .path'}); print(nhan, m, 'KHONG CO .path'); continue
        if m not in cache:
            cache[m] = doc_path(p)
        ver, pts, tris = cache[m]
        hit = [(i, t[3], t[4]) for i, t in enumerate(tris) if trong((x, z), pts[t[0]], pts[t[1]], pts[t[2]])]
        di_duoc = [h for h in hit if (h[1] & 1) == 0]
        if not hit:
            kq = 'NGOAI LUOI (khong tam giac nao chua diem)'
        elif di_duoc:
            kq = 'DI DUOC (tri %d, flag %d, vung %d)' % di_duoc[0]
        else:
            kq = 'BI CHAN (tri %d, flag %d)' % (hit[0][0], hit[0][1])
        rows.append({'diem': nhan, 'map': m, 'x': x, 'z': z, 'version': hex(ver), 'so_diem': len(pts), 'so_tam_giac': len(tris),
                     'tam_giac_chua': [list(h) for h in hit], 'ket_qua': kq, 'nguon': nguon})
        print('%-30s %-14s %8.2f %8.2f  %s' % (nhan, m, x, z, kq))
    json.dump(rows, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('ghi', OUT)


if __name__ == '__main__':
    main()
