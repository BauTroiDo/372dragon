#!/usr/bin/env python3
"""CS3a — dựng file cảnh server (skynet riêng) cho bản đồ CY 3.71 và kiểm toạ độ trên navmesh CY.

Chạy bằng python3 trong WSL TLBB (root), không cần thư viện ngoài. Chỉ ĐỌC nguồn CY/tlbb15/server; lệnh `build`
ghi vào một thư mục staging (mặc định /dev/shm/cs3a/<city>), không bao giờ ghi thẳng vào server.

  cs3a_scene.py path-info <file.path>
  cs3a_scene.py query <file.path> x,z [x,z ...]
  cs3a_scene.py build --city dali|luoyang|suzhou|wuliang [--out DIR]
        sinh <new>.scn + ini/txt + report.json (vị trí NPC, cổng, affine, retype, sửa script, ô sạp)
  cs3a_scene.py audit-scripts --city X [--out F]   toạ độ đích vào cảnh trong Game_2/Script so với navmesh CY
  cs3a_scene.py install --city X [--staging DIR] [--force]
        chép file cảnh + .path CY, SceneInfo (cảnh gốc + phân tuyến), SceneAttr/SceneDefineEx, Stall_Info, script
  cs3a_scene.py survey --city X
  cs3a_scene.py retype --city X --map F [--src] [--out] [--disable-mode pos|rename]
  cs3a_scene.py retype-plan --city X --out F        map JSON type GL→CY theo tên (CS3c) cho <new>_monster.ini đã cài
  cs3a_scene.py block-portals --city X [--out F]    area.ini đã cài: cổng tới cảnh không giữ → script_id=-1
  cs3a_scene.py scenes-off [--out F] | scenes-on    SceneInfo.ini: active=0 cho cảnh type 0 ngoài KEEP_SCENES (ghi JSON)
  cs3a_scene.py default-pos --x 160 --z 150         define.DEFAULT_SCENEID_AND_WORLD_POS (nơi rơi về khi cảnh đích không có)

Định dạng .path 0x2000 (PathLib.dll, xem memory tlbb-path-navmesh-format): u16 ver, u32 nPt, nPt*(f32 x,z),
u32 nTri, nTri*(3 u32 v, 3 u32 kề, u8 flag, u32 vùng), u32 nEdge, nEdge*4 u32, u32 cell, u32 nx, u32 nz,
nx*nz*(u32 n1, u32 n2, n1 u32 tam giác, n2 u32 cạnh). flag bit0 = bị chặn. Bản 0x1000: mọi số u16 trừ cell.
Toạ độ đều là đơn vị ô (giống bảng server).

Thứ tự ưu tiên nguồn vị trí NPC/quái (ghi vào report.json theo từng mục):
  1. CY 3.71 client: MissionNPC_HashTable (cột scene/x/z), TransportDefine (NPC truyền tống) — [DK, CY]
  2. tlbb15 Public/Scene/<city>_monster.ini — server HJ dựng cho CÙNG navmesh (dali.path = CY dali_new_320_SP.path,
     suzhou.path = CY suzhou_new_SP.path, sha256 khớp) — [DK, HJ]
  3. Bản đồ đổi kích thước (320→512): affine khớp từ cặp NPC cùng tên (bản cũ → CY) — [SL, affine]
  4. Vị trí cũ của server skynet nếu đi được trên navmesh CY — [SL, giữ toạ độ cũ]
  5. Ô đi được gần nhất (xoắn ốc 0,5 ô, ≤ 12 ô) cùng vùng liên thông với điểm hồi sinh — [SL, dời]

Tắt mục quái (retype-plan/retype --disable-mode rename): đổi `[monsterN]` → `[monsterN_off]`. inireader chỉ tra khoá
`monster%d` nên mục bị bỏ qua hoàn toàn; quy ước cũ `pos_x=;…` vẫn tra MonsterAttrEx → vẫn MONSTER_CFG_FAIL nếu type
không có ở CY (đo 14/09: 56003/56007 cảnh 2).
"""
import argparse
import json
import math
import os
import re
import struct
import subprocess
import sys

SERVER = '/home/ubuntu/cys-test-20260913'
CY_DATA = '/mnt/c/TLBB/085/CY-Source/Assets/CanonicalCY/Data'
CY_TEXT = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
TLBB15_SCENE = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/tlbb15/Public/Scene'
GL_REV = '995c2df'      # commit server riêng còn bảng MonsterAttrEx GL (trước CS3b/CS3c) — nguồn tên GL cho retype
NO_TRI = 1000000

CITIES = {
    'dali': {
        'scene_id': 2, 'cn': '大理', 'old': 'dali', 'new': 'dali_new_320', 'tlbb15': 'dali',
        'size': 320, 'old_size': 320,
        # SceneAttr CY dòng 2 cột 4/5 ("可以站立的位置") — điểm hồi sinh/đứng mặc định của CY
        'spawn': (160.0, 150.0), 'shards': [71, 72, 1320, 1321],
    },
    # 14/09 (cs3a2): hai thành 512×512 của CY; bản cũ 320×320 nên vị trí không có ở CY/tlbb15 đi qua affine.
    'suzhou': {
        'scene_id': 1, 'cn': '苏州', 'old': 'suzhou', 'new': 'suzhou_new', 'tlbb15': 'suzhou', 'size': 512, 'old_size': 320,
        'spawn': (279.0, 371.0), 'shards': [1312],
    },
    'luoyang': {
        'scene_id': 0, 'cn': '洛阳', 'old': 'luoyang', 'new': 'luoyang_new', 'tlbb15': None, 'size': 512, 'old_size': 320,
        'spawn': (256.0, 416.0), 'shards': [1311, 1315, 1316],
    },
    # Vô Lượng Sơn: CY giữ tên file, cùng hình học navmesh (2.632 đỉnh/5.258 tam giác) nhưng .path bản 0x2000; server 0x1000.
    'wuliang': {
        'scene_id': 6, 'cn': '无量山', 'old': 'wuliang', 'new': 'wuliang', 'tlbb15': None, 'size': 320, 'old_size': 320,
        'spawn': (43.0, 172.0), 'shards': [73, 74],
    },
}

# Chỉ thị người dùng 14/09 (qua người điều phối): chỉ 3 thành chính + Vô Lượng Sơn, không làm bản đồ khác.
# Giữ: cảnh gốc + phân tuyến của 4 bản đồ, và 地府 (define.SIWANG = {77,1500,2218}, cơ chế chết/hồi sinh).
KEEP_SCENES = {0, 1, 2, 6, 71, 72, 73, 74, 77, 1311, 1312, 1315, 1316, 1320, 1321, 1500, 2218}
SCENE_OFF_RECORD = 'configs/cys_scene_off.json'


# ----------------------------------------------------------------------------------------------- navmesh
class NavMesh:
    def __init__(self, path):
        data = open(path, 'rb').read()
        self.path = path
        self.bytes = len(data)
        ver = struct.unpack_from('<H', data, 0)[0]
        if ver not in (0x1000, 0x2000):
            raise SystemExit('unknown .path version %#x: %s' % (ver, path))
        wide = ver == 0x2000
        u = '<I' if wide else '<H'
        us = 4 if wide else 2
        off = 2
        self.version = ver
        n = struct.unpack_from(u, data, off)[0]; off += us
        self.pts = [struct.unpack_from('<ff', data, off + 8 * i) for i in range(n)]
        off += 8 * n
        n = struct.unpack_from(u, data, off)[0]; off += us
        tsize = 7 * us + 1
        self.tris = []
        for i in range(n):
            vals = struct.unpack_from('<' + ('I' if wide else 'H') * 6, data, off)
            flag = data[off + 6 * us]
            region = struct.unpack_from(u, data, off + 6 * us + 1)[0]
            self.tris.append((vals[0], vals[1], vals[2], flag, region))
            off += tsize
        n = struct.unpack_from(u, data, off)[0]; off += us
        self.edge_count = n
        off += 4 * us * n
        self.cell = struct.unpack_from('<I', data, off)[0]; off += 4
        self.nx, self.nz = struct.unpack_from(u * 1 + u[1:], data, off); off += 2 * us
        self.grid = []
        for _ in range(self.nx * self.nz):
            n1, n2 = struct.unpack_from(u + u[1:], data, off); off += 2 * us
            tris = struct.unpack_from('<' + ('I' if wide else 'H') * n1, data, off); off += us * n1
            off += us * n2
            self.grid.append(tris)
        self.tail = self.bytes - off
        xs = [p[0] for p in self.pts]; zs = [p[1] for p in self.pts]
        self.bbox = (min(xs), min(zs), max(xs), max(zs))

    def locate(self, x, z):
        """-> (tri index, flag, region) or None when no triangle covers the point."""
        cx, cz = int(x // self.cell), int(z // self.cell)
        if not (0 <= cx < self.nx and 0 <= cz < self.nz):
            return None
        for t in self.grid[cz * self.nx + cx]:
            a, b, c, flag, region = self.tris[t]
            (ax, az), (bx, bz), (qx, qz) = self.pts[a], self.pts[b], self.pts[c]
            d1 = (x - bx) * (az - bz) - (ax - bx) * (z - bz)
            d2 = (x - qx) * (bz - qz) - (bx - qx) * (z - qz)
            d3 = (x - ax) * (qz - az) - (qx - ax) * (z - az)
            neg = d1 < -1e-6 or d2 < -1e-6 or d3 < -1e-6
            pos = d1 > 1e-6 or d2 > 1e-6 or d3 > 1e-6
            if not (neg and pos):
                return t, flag, region
        return None

    def walkable(self, x, z, region=None):
        hit = self.locate(x, z)
        if not hit or hit[1] & 1:
            return False
        return region is None or hit[2] == region

    def nearest_walkable(self, x, z, region, max_r=12.0, step=0.5):
        if self.walkable(x, z, region):
            return x, z, 0.0
        best = None
        r = step
        while r <= max_r + 1e-9:
            n = max(8, int(2 * math.pi * r / step))
            for i in range(n):
                a = 2 * math.pi * i / n
                px, pz = round(x + r * math.cos(a), 2), round(z + r * math.sin(a), 2)
                if self.walkable(px, pz, region):
                    d = math.hypot(px - x, pz - z)
                    if best is None or d < best[2]:
                        best = (px, pz, d)
            if best:
                return best
            r += step
        return None

    def info(self):
        blocked = sum(1 for t in self.tris if t[3] & 1)
        regions = {}
        for t in self.tris:
            if not t[3] & 1:
                regions[t[4]] = regions.get(t[4], 0) + 1
        top = sorted(regions.items(), key=lambda kv: -kv[1])[:5]
        return {'file': self.path, 'bytes': self.bytes, 'version': hex(self.version), 'points': len(self.pts),
                'triangles': len(self.tris), 'blocked_triangles': blocked, 'edges': self.edge_count,
                'cell': self.cell, 'grid': [self.nx, self.nz], 'bbox': [round(v, 3) for v in self.bbox],
                'regions_walkable': len(regions), 'top_regions': top, 'trailing_bytes': self.tail}


# ----------------------------------------------------------------------------------------------- readers
def read_gbk_lines(path):
    raw = open(path, 'rb').read()
    return raw.decode('gbk', errors='strict').replace('\r\n', '\n').split('\n')


def read_table(name):
    rows = []
    for line in read_gbk_lines(os.path.join(CY_TEXT, name))[2:]:
        if line.strip():
            rows.append(line.split('\t'))
    return rows


def parse_ini_sections(text):
    """Keep order: list of (section name, [(key, value, raw line)]), header lines before first section."""
    sections, head, cur = [], [], None
    for line in text.split('\n'):
        m = re.match(r'^\s*\[([^\]]+)\]\s*$', line)
        if m:
            cur = (m.group(1), [])
            sections.append(cur)
            continue
        if cur is None:
            head.append(line)
            continue
        kv = re.match(r'^([^=;]+?)=(.*)$', line)
        if kv:
            cur[1].append((kv.group(1).strip(), kv.group(2), line))
        else:
            cur[1].append((None, None, line))
    return head, sections


def ini_get(items, key):
    for k, v, _ in items:
        if k == key:
            return v.split(';')[0].strip()
    return None


def ini_set(items, key, value):
    """Đổi giá trị, giữ chú thích sau `;` (nếu có) của dòng cũ."""
    for i, (k, v, raw) in enumerate(items):
        if k == key:
            tail = ''
            m = re.search(r'(\s*;.*)$', v)
            if m:
                tail = m.group(1)
            items[i] = (k, str(value) + tail, '%s=%s%s' % (key, value, tail))
            return
    raise KeyError(key)


def render_ini(head, sections):
    out = list(head)
    for name, items in sections:
        out.append('[%s]' % name)
        out.extend(raw for _, _, raw in items)
    return '\n'.join(out)


def fmt(v):
    return ('%.4f' % v) if isinstance(v, float) else str(v)


def fmt_like(v, old_text):
    """Ghi số theo kiểu của giá trị cũ (nguyên → nguyên, thập phân → 4 chữ số)."""
    if re.fullmatch(r'-?\d+', old_text.strip()):
        return str(int(round(v)))
    return '%.4f' % v


# ----------------------------------------------------------------------------------------------- affine
def solve3(m, v):
    """Gauss elimination 3x3."""
    a = [row[:] + [v[i]] for i, row in enumerate(m)]
    for c in range(3):
        p = max(range(c, 3), key=lambda r: abs(a[r][c]))
        a[c], a[p] = a[p], a[c]
        if abs(a[c][c]) < 1e-12:
            return None
        for r in range(3):
            if r != c:
                f = a[r][c] / a[c][c]
                for k in range(c, 4):
                    a[r][k] -= f * a[c][k]
    return [a[i][3] / a[i][i] for i in range(3)]


def fit_affine(pairs):
    """pairs [(ox, oz, nx, nz)] -> (ax, bx, cx, az, bz, cz): nx = ax*ox + bx*oz + cx."""
    m = [[0.0] * 3 for _ in range(3)]
    vx, vz = [0.0] * 3, [0.0] * 3
    for ox, oz, nx, nz in pairs:
        row = (ox, oz, 1.0)
        for i in range(3):
            for j in range(3):
                m[i][j] += row[i] * row[j]
            vx[i] += row[i] * nx
            vz[i] += row[i] * nz
    px, pz = solve3(m, vx), solve3(m, vz)
    return None if px is None or pz is None else px + pz


IDENTITY = (1.0, 0.0, 0.0, 0.0, 1.0, 0.0)


def apply_affine(t, x, z):
    return t[0] * x + t[1] * z + t[2], t[3] * x + t[4] * z + t[5]


def fit_city_affine(cy_npc, old_entries):
    """old_entries [(name, title, x, z)] → (affine, {pairs, residual…}); khớp trên NPC cùng tên duy nhất ở cả hai phía,
    bỏ ngoại lai > 3 × trung vị (tối thiểu 8 ô) rồi khớp lại (như `survey`)."""
    pairs = []
    for nm, title, ox, oz in old_entries:
        c = cy_npc.get(nm)
        if c and len(c) == 1 and sum(1 for o in old_entries if o[0] == nm) == 1:
            pairs.append((ox, oz, c[0][1], c[0][2], nm))
    if len(pairs) < 3:
        return None, {'pairs': len(pairs)}
    t = fit_affine([p[:4] for p in pairs])
    res = []
    for _ in range(2):
        res = sorted((math.hypot(*(a - b for a, b in zip(apply_affine(t, p[0], p[1]), p[2:4]))), p[4]) for p in pairs)
        med = res[len(res) // 2][0]
        keep = [p for p in pairs if math.hypot(*(a - b for a, b in zip(apply_affine(t, p[0], p[1]), p[2:4]))) <= max(3 * med, 8)]
        if len(keep) >= 3:
            t = fit_affine([p[:4] for p in keep])
    res = sorted((math.hypot(*(a - b for a, b in zip(apply_affine(t, p[0], p[1]), p[2:4]))), p[4]) for p in pairs)
    q = lambda k: round(res[min(len(res) - 1, int(k * len(res)))][0], 2)
    return t, {'pairs': len(pairs), 'affine': [round(v, 5) for v in t],
               'residual': {'median': q(0.5), 'p90': q(0.9), 'max': q(1.0), 'worst': res[-5:]}}


# ----------------------------------------------------------------------------------------------- CY tables
def cy_positions(city):
    sid = str(city['scene_id'])
    npc = {}
    for row in read_table('MissionNPC_HashTable.txt'):
        if len(row) > 5 and row[3] == sid:
            npc.setdefault(row[1], []).append(('CY MissionNPC_HashTable#' + row[0], float(row[4]), float(row[5])))
    for row in read_table('TransportDefine.txt'):
        if len(row) > 6 and row[2] == sid:
            item = ('CY TransportDefine#' + row[0], float(row[5]), float(row[6]))
            lst = npc.setdefault(row[3], [])
            if not any(abs(p[1] - item[1]) < 0.01 and abs(p[2] - item[2]) < 0.01 for p in lst):
                lst.append(item)
    portals = []
    for row in read_table('ScenePosDefineEx.txt'):
        # cột: id, tên cảnh, cảnh, x, z, tên đích, cảnh đích, x đích, z đích, loại(0 = cổng đi bộ, 1 = NPC), ...
        if len(row) > 9 and row[2] == sid and row[9] == '0':
            portals.append({'id': int(row[0]), 'x': float(row[3]), 'z': float(row[4]), 'to_scene': int(row[6]),
                            'to_name': row[5], 'to_x': float(row[7]), 'to_z': float(row[8])})
    attr = None
    for row in read_table('SceneAttr.txt'):
        if row[0] == sid:
            attr = row
    return npc, portals, attr


def cy_destinations(city):
    """Điểm đích CY VÀO cảnh này: (a) `dests` = ScenePosDefineEx loại 1 (NPC/驿站) + vị trí NPC TransportDefine;
    (b) `arrivals` = ScenePosDefineEx loại 0 (đích của cổng đi bộ từ cảnh kề)."""
    sid = str(city['scene_id'])
    dests, arrivals = {}, []
    for row in read_table('ScenePosDefineEx.txt'):
        if len(row) > 9 and row[6] == sid:
            key = (float(row[7]), float(row[8]))
            if row[9] == '0':
                arrivals.append({'id': int(row[0]), 'from_scene': int(row[2]), 'from_name': row[1], 'x': key[0], 'z': key[1]})
            else:
                dests.setdefault(key, []).append('ScenePosDefineEx#%s %s→%s' % (row[0], row[1], row[5]))
    for row in read_table('TransportDefine.txt'):
        if len(row) > 6 and row[2] == sid:
            key = (float(row[5]), float(row[6]))
            dests.setdefault(key, []).append('TransportDefine#%s %s' % (row[0], row[3]))
    return dests, arrivals


def tlbb15_monsters(city):
    if not city.get('tlbb15'):
        return []
    path = os.path.join(TLBB15_SCENE, city['tlbb15'] + '_monster.ini')
    if not os.path.exists(path):
        return []
    _, sections = parse_ini_sections('\n'.join(read_gbk_lines(path)))
    out = []
    for name, items in sections:
        if not name.lower().startswith('monster'):
            continue
        try:
            out.append({'section': name, 'name': ini_get(items, 'name') or '', 'title': ini_get(items, 'title') or '',
                        'x': float(ini_get(items, 'pos_x')), 'z': float(ini_get(items, 'pos_z')),
                        'dir': ini_get(items, 'dir'), 'type': ini_get(items, 'type')})
        except (TypeError, ValueError):
            pass
    return out


# ----------------------------------------------------------------------------------------------- MonsterAttrEx GL/CY (retype)
def monster_tables():
    """GL (git GL_REV) và CY (bảng đang cài) MonsterAttrExTable, khoá theo id, ô dạng bytes GBK."""
    gl_raw = subprocess.run(['git', '-C', SERVER, 'show', GL_REV + ':configs/MonsterAttrExTable.txt'], capture_output=True).stdout
    cy_raw = open(os.path.join(SERVER, 'configs', 'MonsterAttrExTable.txt'), 'rb').read()

    def by_id(raw):
        d = {}
        for l in raw.split(b'\n'):
            c = l.rstrip(b'\r').split(b'\t')
            if c and c[0].isdigit():
                d[int(c[0])] = c
        return d
    return by_id(gl_raw), by_id(cy_raw)


def g(b):
    return b.decode('gbk', 'replace')


def isint(b):
    return re.fullmatch(rb'-?\d+', b) is not None


def retype_plan_for_ini(text, gl, cy):
    """Quy tắc CS3c (cs3c_tables.scene2_retype): type GL đổi nghĩa ở CY → ID CY cùng tên (theo tên trong ini, rồi tên GL);
    nhiều ứng viên: cùng 外型ID (CY cột 36 ↔ GL cột 44) → cùng cờ NPC (CY 5 ↔ GL 13) + cấp gần nhất (cột 3) → ID nhỏ nhất.
    Không có tương đương → tắt. Mục đã `pos_x=;` mà type không có ở CY → cũng tắt (vẫn bị tra bảng)."""
    names = {}
    for i, r in cy.items():
        names.setdefault(r[1], []).append(i)
    retype, disable, stats = {}, [], {}
    for sec in re.findall(r'\[(monster\d+)\]\n(.*?)(?=\n\[|\Z)', text, re.S):
        body = sec[1]
        m_t = re.search(r'^type=(\d+)', body, re.M)
        m_n = re.search(r'^name=(.*)$', body, re.M)
        off = re.search(r'^pos_x=;', body, re.M) is not None
        if not m_t:
            stats['no-type'] = stats.get('no-type', 0) + 1
            continue
        tid, nm = int(m_t.group(1)), (m_n.group(1).strip() if m_n else '')
        glrow = gl.get(tid)
        glname = g(glrow[1]) if glrow else ''
        if off:
            # đã tắt kiểu cũ (pos_x=;): create_monster_data vẫn tra bảng và tạo quái với world_pos nil → đổi tên section để bỏ qua sạch
            disable.append([sec[0], tid, nm, 'đã pos_x=; (tắt kiểu cũ) → đổi tên section; type %s ở CY' % ('có' if tid in cy else 'KHÔNG có')])
            stats['disabled_legacy_off'] = stats.get('disabled_legacy_off', 0) + 1
            continue
        if tid in cy and (g(cy[tid][1]) == nm or (glrow is not None and glrow[1] == cy[tid][1])):
            stats['same'] = stats.get('same', 0) + 1
            continue
        cand = []
        for key in (nm, glname):
            if key and names.get(key.encode('gbk', 'replace')):
                cand = names[key.encode('gbk', 'replace')]
                break
        if cand and glrow:
            def score(c):
                r = cy[c]
                return (0 if r[36] == glrow[44] else 1, 0 if r[5] == glrow[13] else 1,
                        abs(int(r[3]) - int(glrow[3])) if isint(r[3]) and isint(glrow[3]) else 999, c)
            best = min(cand, key=score)
            retype[sec[0]] = [tid, best, nm, 'ứng viên %d, chọn theo %s' % (len(cand), 'model' if cy[best][36] == glrow[44] else 'NPC+cấp')]
            stats['retyped'] = stats.get('retyped', 0) + 1
        elif not glname:
            disable.append([sec[0], tid, nm, 'dòng GL không tên (tượng/đối tượng riêng GL) → CY %s' % (g(cy[tid][1]) if tid in cy else 'không có')])
            stats['disabled_gl_placeholder'] = stats.get('disabled_gl_placeholder', 0) + 1
        elif tid not in cy:
            disable.append([sec[0], tid, nm, 'ID không có ở CY (%s)' % glname])
            stats['disabled_missing_in_cy'] = stats.get('disabled_missing_in_cy', 0) + 1
        else:
            disable.append([sec[0], tid, nm, 'NPC chỉ-GL (%s), CY không có tên này; ID CY = %s' % (glname, g(cy[tid][1]))])
            stats['disabled_gl_only_npc'] = stats.get('disabled_gl_only_npc', 0) + 1
    return {'retype': retype, 'disable': [d[0] for d in disable], 'disable_detail': disable, 'stats': stats,
            'why': 'MonsterAttrExTable server = CY (CS3c) → type GL đổi nghĩa; retype theo tên, tắt mục không có tương đương'}


def apply_retype(text, spec, disable_mode):
    lines = text.split('\n')
    cur, done = None, {'retype': 0, 'disable': 0, 'already': 0}
    dis = set(spec.get('disable', []))
    for i, line in enumerate(lines):
        cr = '\r' if line.endswith('\r') else ''
        m = re.match(r'^\s*\[([^\]]+)\]\s*$', line)
        if m:
            cur = m.group(1)
            if cur in dis and disable_mode == 'rename':
                lines[i] = '[%s_off]' % cur + cr
                done['disable'] += 1
            continue
        if cur in spec.get('retype', {}) and re.match(r'^type=(\d+)\s*$', line):
            old, new = spec['retype'][cur][0], spec['retype'][cur][1]
            if int(line[5:]) == new:
                done['already'] += 1
            elif int(line[5:]) != old:
                raise SystemExit('%s: type=%s, mong %s' % (cur, line[5:], old))
            else:
                lines[i] = 'type=%d' % new + cr
                done['retype'] += 1
        if cur in dis and disable_mode == 'pos' and re.match(r'^pos_x=[^;]', line):
            lines[i] = 'pos_x=;' + line[6:]
            done['disable'] += 1
    return '\n'.join(lines), done


# ----------------------------------------------------------------------------------------------- transform helpers
def transform_ini_pairs(text, key_x, key_z, T, nav=None, region=None, snap_region=None):
    """Đổi mọi cặp khoá toạ độ (key_x/key_z là regex có nhóm chỉ số tuỳ chọn, cùng section) theo affine T.
    snap_region: nếu đặt, điểm không đi được được dời tới ô đi được gần nhất trong vùng đó (≤ 12 ô).
    Giữ chú thích sau `;`. Trả (text mới, [{section, key, old, new, walkable}])."""
    lines = text.split('\n')
    cur, xs, zs = None, {}, {}
    for i, line in enumerate(lines):
        m = re.match(r'^\s*\[([^\]]+)\]', line)
        if m:
            cur = m.group(1)
            continue
        mx = re.match(r'^(%s)=(-?[\d.]+)' % key_x, line)
        mz = re.match(r'^(%s)=(-?[\d.]+)' % key_z, line)
        if mx:
            xs[(cur, mx.group(2) if mx.lastindex and mx.lastindex >= 2 and mx.re.groups >= 3 else '')] = (i, mx)
        if mz:
            zs[(cur, mz.group(2) if mz.lastindex and mz.lastindex >= 2 and mz.re.groups >= 3 else '')] = (i, mz)
    log = []
    for key, (ix, mx) in xs.items():
        if key not in zs:
            continue
        iz, mz = zs[key]
        ox, oz = float(mx.group(mx.re.groups)), float(mz.group(mz.re.groups))
        nx, nz = apply_affine(T, ox, oz)
        snapped = None
        if snap_region is not None and nav and not nav.walkable(nx, nz, snap_region):
            mv = nav.nearest_walkable(nx, nz, snap_region, max_r=60)
            if mv:
                snapped = [round(nx, 4), round(nz, 4), round(mv[2], 2)]
                nx, nz = mv[0], mv[1]
        fx = ('%.2f' % nx) if snapped else fmt_like(nx, mx.group(mx.re.groups))
        fz = ('%.2f' % nz) if snapped else fmt_like(nz, mz.group(mz.re.groups))
        lines[ix] = lines[ix][:mx.start(mx.re.groups)] + fx + lines[ix][mx.end(mx.re.groups):]
        lines[iz] = lines[iz][:mz.start(mz.re.groups)] + fz + lines[iz][mz.end(mz.re.groups):]
        rec = {'section': key[0], 'suffix': key[1], 'old': [ox, oz], 'new': [round(nx, 4), round(nz, 4)]}
        if snapped:
            rec['snapped'] = snapped
        if nav:
            rec['walkable'] = nav.walkable(nx, nz, region)
        log.append(rec)
    return '\n'.join(lines), log


def rect_walkable_fraction(nav, region, rect, step=2.0):
    x1, x2, z1, z2 = rect
    n = ok = 0
    x = x1
    while x <= x2 + 1e-9:
        z = z1
        while z <= z2 + 1e-9:
            n += 1
            ok += nav.walkable(x, z, region)
            z += step
        x += step
    return ok / n if n else 0.0


def best_rect_shift(nav, region, rect, max_shift=30, step=2):
    """Trượt hình chữ nhật (không đổi kích thước) trong ±max_shift ô, chọn vị trí có tỉ lệ ô đi được cao nhất (gần gốc khi hoà)."""
    f0 = rect_walkable_fraction(nav, region, rect)
    best = {'rect': rect, 'shift': [0, 0], 'fraction': f0, 'fraction0': f0}
    if f0 >= 0.95:
        return best
    for dx in range(-max_shift, max_shift + 1, step):
        for dz in range(-max_shift, max_shift + 1, step):
            r = (rect[0] + dx, rect[1] + dx, rect[2] + dz, rect[3] + dz)
            f = rect_walkable_fraction(nav, region, r)
            if f > best['fraction'] + 1e-9 or (abs(f - best['fraction']) < 1e-9 and math.hypot(dx, dz) < math.hypot(*best['shift'])):
                best = {'rect': r, 'shift': [dx, dz], 'fraction': f, 'fraction0': f0}
    return best


def portal_targets_of_script(script_id, scene_id=None):
    """Cảnh đích của script cổng (scripts.lua → file lua): bảng `local x = {n, n…}`, `TransferFunc(…, N, x, z`;
    eSceneAreaTransfer (bảng `TransferConfig[<cảnh>]`): chỉ lấy `target_scene` trong khối của cảnh đang xét."""
    scripts = open(os.path.join(SERVER, 'Game_2/Script/scripts/scripts.lua'), 'rb').read().decode('utf-8', 'replace')
    m = re.search(r'^\s*\[%d\]\s*=\s*"([^"]+)"' % script_id, scripts, re.M)
    if not m:
        return None, []
    rel = m.group(1).replace('.', '/') + '.lua'
    p = os.path.join(SERVER, 'Game_2/Script', rel)
    if not os.path.exists(p):
        return rel, []
    src = open(p, 'rb').read().decode('utf-8', 'replace')
    targets = set()
    if 'TransferConfig' in src:
        if scene_id is not None:
            mm = re.search(r'^\s*\[%d\]\s*=\s*\{(.*?)^\s*\},?\s*$' % scene_id, src, re.S | re.M)
            if mm:
                targets.update(int(v) for v in re.findall(r'target_scene\s*=\s*(\d+)', mm.group(1)))
        return rel, sorted(targets)
    for mm in re.finditer(r'^\s*local\s+\w+\s*=\s*\{([\d,\s]+)\}', src, re.M):
        targets.update(int(v) for v in re.findall(r'\d+', mm.group(1)))
    for mm in re.finditer(r'TransferFunc"\s*,\s*obj:get_obj_id\(\)\s*,\s*(\d+)\s*,', src):
        targets.add(int(mm.group(1)))
    return rel, sorted(targets)


def is_walk_portal_script(rel):
    return bool(rel) and '/chuansong/echuansong_' in rel


# ----------------------------------------------------------------------------------------------- build
def build(args):
    city = CITIES[args.city]
    scene_dir = os.path.join(SERVER, 'Game_2', 'Scene')
    nav_src = os.path.join(CY_DATA, 'SceneFolder', city['new'] + '.path')
    nav = NavMesh(nav_src)
    sx, sz = city['spawn']
    spawn_hit = nav.locate(sx, sz)
    if not spawn_hit or spawn_hit[1] & 1:
        raise SystemExit('spawn (%s,%s) is not walkable on %s' % (sx, sz, nav_src))
    region = spawn_hit[2]
    out_dir = args.out or os.path.join('/dev/shm/cs3a', args.city)
    os.makedirs(out_dir, exist_ok=True)
    report = {'city': args.city, 'scene_id': city['scene_id'], 'navmesh': nav.info(), 'spawn': {
        'x': sx, 'z': sz, 'source': 'CY SceneAttr.txt dòng %d cột 4/5' % city['scene_id'], 'region': region},
        'files': {}, 'monsters': [], 'unmatched_cy': [], 'unmatched_tlbb15': [], 'notes': []}
    cy_npc, cy_portals, cy_attr = cy_positions(city)
    report['cy_scene_attr'] = cy_attr
    hj = tlbb15_monsters(city)
    hj_used = set()

    def write(name, text, source):
        data = text.encode('gbk')
        with open(os.path.join(out_dir, name), 'wb') as f:
            f.write(data)
        report['files'][name] = {'bytes': len(data), 'source': source}

    # --- monster.ini: giữ mọi khoá của server skynet (type/script/shop/ai), chỉ đổi pos_x/pos_z/dir
    old_path = os.path.join(scene_dir, city['old'] + '_monster.ini')
    raw = open(old_path, 'rb').read()
    text = raw.decode('gbk')
    if text.encode('gbk') != raw:
        raise SystemExit('GBK round-trip failed: ' + old_path)
    head, sections = parse_ini_sections(text)
    old_entries = []
    for name, items in sections:
        if name.lower().startswith('monster'):
            try:
                old_entries.append((ini_get(items, 'name') or '', ini_get(items, 'title') or '',
                                    float(ini_get(items, 'pos_x')), float(ini_get(items, 'pos_z'))))
            except (TypeError, ValueError):
                pass
    # affine bản cũ → CY khi bản đồ đổi kích thước; cùng kích thước thì đồng nhất
    if city['size'] != city['old_size']:
        T, fit = fit_city_affine(cy_npc, old_entries)
        if T is None:
            raise SystemExit('không khớp được affine: ' + json.dumps(fit))
        report['affine'] = dict(fit, note='bản cũ %d → CY %d: x\' = a·x + b·z + c [SL]' % (city['old_size'], city['size']))
    else:
        T = IDENTITY
        report['affine'] = {'affine': list(IDENTITY), 'note': 'cùng kích thước bản đồ, không biến đổi'}
    cy_used = {}
    stats = {}
    for name, items in sections:
        if not name.lower().startswith('monster'):
            continue
        nm, title = ini_get(items, 'name') or '', ini_get(items, 'title') or ''
        try:
            ox, oz = float(ini_get(items, 'pos_x')), float(ini_get(items, 'pos_z'))
        except (TypeError, ValueError):
            report['monsters'].append({'section': name, 'type': ini_get(items, 'type'), 'name': nm, 'kind': 'bo-qua',
                                       'note': 'mục gốc không có pos_x/pos_z — giữ nguyên như server skynet'})
            stats['bo-qua'] = stats.get('bo-qua', 0) + 1
            continue
        rec = {'section': name, 'type': ini_get(items, 'type'), 'name': nm, 'title': title, 'old': [ox, oz],
               'patrol_id': ini_get(items, 'patrol_id')}
        tx, tz = apply_affine(T, ox, oz)      # vị trí cũ đưa về hệ CY (đồng nhất nếu cùng kích thước)
        choice = None
        # 1. CY client
        cands = cy_npc.get(nm, [])
        if cands:
            k = cy_used.get(nm, 0)
            if k < len(cands):
                src, x, z = min(cands, key=lambda c: math.hypot(c[1] - tx, c[2] - tz))
                if len(cands) == 1 or k == 0:
                    choice = (x, z, src, 'DK')
                    cy_used[nm] = k + 1
        # 2. tlbb15 (HJ) cùng tên (+ tiêu đề nếu có), gần vị trí (đã affine) nhất, chưa dùng
        hj_match = None
        pool = [i for i, m in enumerate(hj) if i not in hj_used and m['name'] == nm and nm]
        if not pool and title:
            pool = [i for i, m in enumerate(hj) if i not in hj_used and m['type'] == rec['type'] and m['title'] == title]
        if pool:
            same_title = [i for i in pool if hj[i]['title'] == title]
            pool = same_title or pool
            best = min(pool, key=lambda i: math.hypot(hj[i]['x'] - tx, hj[i]['z'] - tz))
            if math.hypot(hj[best]['x'] - tx, hj[best]['z'] - tz) <= 60 or choice:
                hj_match = best
                hj_used.add(best)
        if choice is None and hj_match is not None:
            m = hj[hj_match]
            choice = (m['x'], m['z'], 'tlbb15 %s_monster.ini [%s]' % (city['tlbb15'], m['section']), 'DK-HJ')
        if choice is None:
            if T is IDENTITY:
                choice = (ox, oz, 'server skynet cũ %s_monster.ini [%s]' % (city['old'], name), 'SL-giu')
            else:
                choice = (tx, tz, 'affine từ server skynet cũ %s_monster.ini [%s]' % (city['old'], name), 'SL-affine')
        x, z, src, kind = choice
        rec['source'] = src
        rec['kind'] = kind
        if hj_match is not None:
            rec['tlbb15'] = [hj[hj_match]['x'], hj[hj_match]['z'], hj[hj_match]['dir']]
        hit = nav.locate(x, z)
        rec['nav'] = None if not hit else {'flag': hit[1], 'region': hit[2]}
        if not nav.walkable(x, z, region):
            moved = nav.nearest_walkable(x, z, region)
            if moved and kind != 'DK':
                rec['moved_from'] = [round(x, 4), round(z, 4)]
                x, z = moved[0], moved[1]
                rec['kind'] = kind + '+SL-doi'
                rec['moved_dist'] = round(moved[2], 2)
            elif kind == 'DK':
                rec['note'] = 'toạ độ CY không nằm trên tam giác đi được của vùng chính (NPC đứng sát nhà) — giữ theo CY'
            else:
                rec['note'] = 'không tìm được ô đi được trong 12 ô — giữ toạ độ'
        rec['new'] = [round(x, 4), round(z, 4)]
        if hj_match is not None and rec['kind'].startswith('DK-HJ') and hj[hj_match]['dir'] not in (None, ''):
            ini_set(items, 'dir', hj[hj_match]['dir'])
            rec['dir'] = hj[hj_match]['dir']
        ini_set(items, 'pos_x', fmt(round(x, 4)))
        ini_set(items, 'pos_z', fmt(round(z, 4)))
        stats[rec['kind']] = stats.get(rec['kind'], 0) + 1
        report['monsters'].append(rec)
    report['monster_stats'] = stats
    for nm, cands in cy_npc.items():
        if cy_used.get(nm, 0) == 0:
            report['unmatched_cy'].append({'name': nm, 'positions': cands})
    for i, m in enumerate(hj):
        if i not in hj_used:
            report['unmatched_tlbb15'].append(m)
    monster_text = render_ini(head, sections)
    # retype theo tên CY (CS3c) trên file đã dời vị trí; tắt = đổi tên section
    gl, cy = monster_tables()
    spec = retype_plan_for_ini(monster_text, gl, cy)
    monster_text, done = apply_retype(monster_text, spec, 'rename')
    report['retype'] = dict(spec, applied=done)
    write(city['new'] + '_monster.ini', monster_text,
          '%s_monster.ini server skynet, vị trí theo report.json; retype/tắt theo report.retype' % city['old'])

    # --- area.ini: cổng đi bộ theo CY ScenePosDefineEx (loại 0), giữ script_id của server skynet; vùng khác → affine
    head, sections = parse_ini_sections(open(os.path.join(scene_dir, city['old'] + '_area.ini'), 'rb').read().decode('gbk'))
    report['areas'] = []
    for name, items in sections:
        if not name.lower().startswith('area') or name == 'area_info':
            continue
        rect = ini_get(items, 'left') is not None
        if rect:
            l, t, r, b = (float(ini_get(items, k)) for k in ('left', 'top', 'right', 'bottom'))
            ox, oz = (l + r) / 2, (t + b) / 2
        else:
            ox, oz = float(ini_get(items, 'x')), float(ini_get(items, 'z'))
        tx, tz = apply_affine(T, ox, oz)
        best = min(cy_portals, key=lambda p: math.hypot(p['x'] - tx, p['z'] - tz)) if cy_portals else None
        rec = {'section': name, 'script_id': ini_get(items, 'script_id'), 'old': [ox, oz], 'form': 'rect' if rect else 'circle',
               'radius': ini_get(items, 'radious')}
        sid = int(ini_get(items, 'script_id') or -1)
        srel, stargets = portal_targets_of_script(sid, city['scene_id']) if sid > 0 else (None, [])
        is_portal = is_walk_portal_script(srel) and bool(stargets)
        if best and is_portal and math.hypot(best['x'] - tx, best['z'] - tz) > 20 and T is not IDENTITY:
            # cổng ở sát biên: affine tâm thành lệch xa (bản 512 rộng hơn) → chọn cổng CY cùng hướng so với tâm [SL hướng]
            co, cn = city['old_size'] / 2.0, city['size'] / 2.0
            a_old = math.atan2(oz - co, ox - co)
            ang = lambda p: abs((math.atan2(p['z'] - cn, p['x'] - cn) - a_old + math.pi) % (2 * math.pi) - math.pi)
            cand = min(cy_portals, key=ang)
            if ang(cand) <= math.radians(45):
                best = cand
                rec['match'] = 'cùng hướng từ tâm (lệch %.0f°)' % math.degrees(ang(cand))
        if best and is_portal and (math.hypot(best['x'] - tx, best['z'] - tz) <= 20 or rec.get('match')):
            nx, nz = best['x'], best['z']
            rec.update({'new': [nx, nz], 'source': 'CY ScenePosDefineEx#%d → %s(%d)' % (best['id'], best['to_name'], best['to_scene']),
                        'to_scene': best['to_scene'], 'script': srel, 'script_targets': stargets})
        else:
            if srel:
                rec.update({'script': srel, 'script_targets': stargets})
            nx, nz = tx, tz
            rec.update({'new': [round(nx, 4), round(nz, 4)],
                        'source': 'server skynet cũ' + (' qua affine [SL]' if T is not IDENTITY else '') + ' (không phải cổng CY trong 20 ô)'})
        if rect:
            hw, hh = (r - l) / 2, (b - t) / 2
            for k, v in (('left', nx - hw), ('right', nx + hw), ('top', nz - hh), ('bottom', nz + hh)):
                ini_set(items, k, fmt_like(v, ini_get(items, k)))
        else:
            ini_set(items, 'x', fmt_like(nx, ini_get(items, 'x')))
            ini_set(items, 'z', fmt_like(nz, ini_get(items, 'z')))
        hit = nav.locate(nx, nz)
        rec['nav'] = None if not hit else {'flag': hit[1], 'region': hit[2]}
        report['areas'].append(rec)
    write(city['new'] + '_area.ini', render_ini(head, sections), 'area CY ScenePosDefineEx + script skynet (vùng khác: affine)')

    # --- patrolpoint/platform/growpoint: tlbb15 (HJ, cùng navmesh) nếu có; không thì bản cũ (qua affine nếu đổi kích thước)
    report['transforms'] = {}
    for suffix, prefer_hj, kx, kz in (('_patrolpoint.ini', True, r'POSX(\d+)', r'POSZ(\d+)'), ('_platform.ini', True, r'pos_X', r'pos_Z'),
                                     ('_growpoint.txt', True, None, None), ('_growpointsetup.txt', False, None, None),
                                     ('_bus.ini', False, None, None), ('_pet.ini', False, None, None), ('_portal.ini', False, None, None)):
        hj_file = os.path.join(TLBB15_SCENE, (city['tlbb15'] or '') + suffix) if city.get('tlbb15') else ''
        old_file = os.path.join(scene_dir, city['old'] + suffix)
        if not os.path.exists(old_file) and not (hj_file and os.path.exists(hj_file)):
            continue
        src_file = hj_file if prefer_hj and hj_file and os.path.exists(hj_file) else old_file
        if not os.path.exists(src_file):
            continue
        text = open(src_file, 'rb').read().decode('gbk').replace('\r\n', '\n')
        if suffix == '_growpointsetup.txt' and os.path.exists(old_file):
            text = open(old_file, 'rb').read().decode('gbk')
            src_file = old_file
        source = ('tlbb15 ' if src_file == hj_file else 'server skynet cũ ') + os.path.basename(src_file)
        if src_file == old_file and T is not IDENTITY:
            if kx:
                # bàn thao tác (platform) phải đứng được: sau affine rơi vào nhà → ô đi được gần nhất (≤ 12 ô) [SL]
                snap = nav if suffix == '_platform.ini' else None
                text, log = transform_ini_pairs(text, kx, kz, T, nav, region, snap_region=region if snap else None)
                report['transforms'][suffix] = {'pairs': len(log), 'walkable': sum(1 for r in log if r.get('walkable')),
                                                'snapped': sum(1 for r in log if r.get('snapped'))}
                source += ' qua affine [SL]'
            elif suffix == '_growpoint.txt':
                rows = text.split('\n')
                n = 0
                for i in range(2, len(rows)):
                    c = rows[i].split('\t')
                    if len(c) >= 4 and c[0].strip():
                        nx, nz = apply_affine(T, float(c[2]), float(c[3]))
                        c[2], c[3] = fmt_like(nx, c[2]), fmt_like(nz, c[3])
                        rows[i] = '\t'.join(c)
                        n += 1
                text = '\n'.join(rows)
                report['transforms'][suffix] = {'rows': n}
                source += ' qua affine [SL]'
        write(city['new'] + suffix, text, source)
    # kiểm các điểm tuần tra / bàn thao tác / điểm thu thập trên navmesh
    checks = {}
    pat = open(os.path.join(out_dir, city['new'] + '_patrolpoint.ini'), 'rb').read().decode('gbk')
    pts = re.findall(r'POSX(\d+)=([\d.]+)\n(?:POSY\d+=[\d.]+\n)?POSZ\1=([\d.]+)', pat)
    checks['patrol_points'] = {'total': len(pts), 'walkable': sum(1 for _, x, z in pts if nav.walkable(float(x), float(z)))}
    plat = open(os.path.join(out_dir, city['new'] + '_platform.ini'), 'rb').read().decode('gbk')
    pp = re.findall(r'pos_X=([\d.]+)\D+pos_Z=([\d.]+)', plat)
    checks['platforms'] = {'total': len(pp), 'walkable': sum(1 for x, z in pp if nav.walkable(float(x), float(z)))}
    gp = [l.split('\t') for l in open(os.path.join(out_dir, city['new'] + '_growpoint.txt'), 'rb').read().decode('gbk').split('\n')[2:] if l.strip()]
    checks['growpoints'] = {'total': len(gp), 'walkable': sum(1 for r in gp if nav.walkable(float(r[2]), float(r[3])))}
    report['point_checks'] = checks

    # --- .scn
    old_scn = open(os.path.join(scene_dir, city['old'] + '.scn'), 'rb').read().decode('gbk')
    scn = ['[System]', 'navmapname=%s.path' % city['new'], 'monsterfile=%s_monster.ini' % city['new']]
    if city['new'] + '_portal.ini' in report['files'] and 'portalfile=' in old_scn:
        scn.append('portalfile=%s_portal.ini' % city['new'])
        report['notes'].append('portalfile giữ như .scn cũ (scenecore không đọc khoá này) [DK]')
    # busfile chỉ khi .scn cũ có: luoyang.scn gốc không khai busfile dù luoyang_bus.ini tồn tại (bus tuyến 53 > PATROLNUMBER=53
    # → create_bus_data nil 'patrol' = SCENE_INIT_FAIL, đo restart 23:01)
    scn += ['busfile=%s_bus.ini' % city['new'] if city['new'] + '_bus.ini' in report['files'] and 'busfile=' in old_scn else None,
            'patrolpoint=%s_patrolpoint.ini' % city['new'],
            'growpointdata=%s_growpoint.txt' % city['new'], 'growpointsetup=%s_growpointsetup.txt' % city['new'],
            'eventfile=%s_area.ini' % city['new'], 'petfile=%s_pet.ini' % city['new'],
            'platformfile=%s_platform.ini' % city['new']]
    scn = [s for s in scn if s]
    m = re.search(r'stallinfodata=(\S+)', old_scn)
    if m:
        scn.append('stallinfodata=%s' % m.group(1))
        report['notes'].append('stallinfodata giữ %s của bản đồ cũ: scenecore.init_stall_info đã bị chú thích, server không đọc .stall; '
                               'ô sạp lấy từ configs/Stall_Info.txt [DK]' % m.group(1))
    write(city['new'] + '.scn', '\n'.join(scn) + '\n', 'dựng mới theo khuôn %s.scn' % city['old'])

    # --- Stall_Info.txt: ô sạp (hình chữ nhật) của cảnh này qua affine, rồi trượt ≤ 30 ô tới chỗ nhiều ô đi được nhất
    report['stall_rows'] = []
    for line in read_gbk_lines(os.path.join(SERVER, 'configs', 'Stall_Info.txt'))[2:]:
        c = line.split('\t')
        if len(c) >= 9 and c[1].strip() == str(city['scene_id']):
            x1, z1 = apply_affine(T, float(c[5]), float(c[7]))
            x2, z2 = apply_affine(T, float(c[6]), float(c[8]))
            rect = (min(x1, x2), max(x1, x2), min(z1, z2), max(z1, z2))
            rec = {'row': c[0], 'old': [c[5], c[6], c[7], c[8]], 'affine': [round(v, 1) for v in rect],
                   'source': 'affine [SL]' if T is not IDENTITY else 'giữ nguyên'}
            if T is not IDENTITY:
                best = best_rect_shift(nav, region, rect)
                rect = best['rect']
                rec.update({'shift': best['shift'], 'walkable_fraction': best['fraction'], 'walkable_fraction_affine': best['fraction0']})
                if best['shift'] != [0, 0]:
                    rec['source'] += ' + trượt %s ô tới chỗ đi được nhiều nhất [SL]' % best['shift']
            rec['new'] = [str(int(round(v))) for v in rect]
            report['stall_rows'].append(rec)

    # --- script: toạ độ đích vào cảnh (audit) → đích CY
    report['script_fixes'] = plan_script_fixes(city, nav, region, T)

    with open(os.path.join(out_dir, 'report.json'), 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=1)
    summary = {'out': out_dir, 'navmesh': {k: report['navmesh'][k] for k in ('points', 'triangles', 'edges', 'trailing_bytes')},
               'spawn_region': region, 'affine': report['affine'].get('affine'), 'affine_residual': report['affine'].get('residual'),
               'monster_stats': stats, 'retype': report['retype']['stats'], 'retype_applied': done,
               'unmatched_cy': len(report['unmatched_cy']), 'unmatched_tlbb15': len(report['unmatched_tlbb15']),
               'areas': report['areas'], 'point_checks': checks, 'transforms': report['transforms'],
               'script_fixes': {'total': len(report['script_fixes']),
                                'kinds': {k: sum(1 for r in report['script_fixes'] if r['kind'] == k) for k in set(r['kind'] for r in report['script_fixes'])}},
               'stall_rows': report['stall_rows'], 'files': sorted(report['files'])}
    print(json.dumps(summary, ensure_ascii=False, indent=1))


# ----------------------------------------------------------------------------------------------- audit scripts
COORD_RE = re.compile(r'(TransferFunc|NewWorld|SetPos|ChangeScene)[^\n]*?[,(]\s*%s\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)')


def script_refs(city):
    rx = re.compile(COORD_RE.pattern % city['scene_id'])
    rows = []
    root = os.path.join(SERVER, 'Game_2', 'Script')
    for base, _, names in sorted(os.walk(root)):
        for n in sorted(names):
            if not n.endswith('.lua'):
                continue
            p = os.path.join(base, n)
            for i, line in enumerate(open(p, 'rb').read().decode('utf-8', errors='replace').split('\n'), 1):
                if line.lstrip().startswith('--'):
                    continue
                for m in rx.finditer(line):
                    rows.append({'file': os.path.relpath(p, SERVER), 'line': i, 'call': m.group(1),
                                 'x': float(m.group(2)), 'z': float(m.group(3))})
    return rows


def audit_scripts(args):
    city = CITIES[args.city]
    nav = NavMesh(os.path.join(CY_DATA, 'SceneFolder', city['new'] + '.path'))
    old = NavMesh(os.path.join(SERVER, 'Game_2', 'Scene', city['old'] + '.path'))
    region = nav.locate(*city['spawn'])[2]
    rows = script_refs(city)
    for r in rows:
        near = nav.nearest_walkable(r['x'], r['z'], region, max_r=15)
        r.update({'walkable_cy': nav.walkable(r['x'], r['z'], region), 'walkable_old': old.walkable(r['x'], r['z']),
                  'nearest_cy': None if not near else [near[0], near[1], round(near[2], 2)]})
    bad = [r for r in rows if not r['walkable_cy']]
    result = {'city': args.city, 'total': len(rows), 'not_walkable_on_cy': len(bad), 'rows': rows}
    text = json.dumps(result, ensure_ascii=False, indent=1)
    if args.out:
        open(args.out, 'w', encoding='utf-8').write(text + '\n')
    print(json.dumps({'total': len(rows), 'not_walkable_on_cy': len(bad), 'bad': bad}, ensure_ascii=False, indent=1))


def plan_script_fixes(city, nav, region, T):
    """Mỗi toạ độ đích `…, <scene>, x, z` trong Game_2/Script → toạ độ CY:
      (1) cùng kích thước bản đồ và đi được → giữ;
      (2) affine rồi bám điểm đích CY vào cảnh (ScenePosDefineEx loại 1 / TransportDefine) trong ≤ 12 ô [DK-CY];
      (3) script truyền tống (echuansong_*/chuan_song_*) có điểm cũ sát biên bản cũ (≤ 70 ô) → đích cổng đi bộ CY
          (ScenePosDefineEx loại 0) cùng hướng so với tâm [DK-CY, SL hướng];
      (4) còn lại: affine → ô đi được gần nhất trong vùng chính [SL]."""
    dests, arrivals = cy_destinations(city)
    fixes = []
    for r in script_refs(city):
        ox, oz = r['x'], r['z']
        rec = dict(r)
        if T is IDENTITY and nav.walkable(ox, oz, region):
            continue
        tx, tz = apply_affine(T, ox, oz)
        kind, nx, nz, why = None, None, None, None
        if dests:
            key = min(dests, key=lambda k: math.hypot(k[0] - tx, k[1] - tz))
            if math.hypot(key[0] - tx, key[1] - tz) <= 12:
                kind, nx, nz, why = 'DK-CY-dest', key[0], key[1], 'affine (%.1f,%.1f) bám đích CY %s' % (tx, tz, '; '.join(dests[key][:3]))
        if kind is None and arrivals and T is not IDENTITY and re.search(r'/(echuansong_|chuan_song_)', r['file']):
            so = city['old_size']
            if min(ox, oz, so - ox, so - oz) <= 70:
                co, cn = so / 2.0, city['size'] / 2.0
                a_old = math.atan2(oz - co, ox - co)
                best = min(arrivals, key=lambda a: abs((math.atan2(a['z'] - cn, a['x'] - cn) - a_old + math.pi) % (2 * math.pi) - math.pi))
                da = abs((math.atan2(best['z'] - cn, best['x'] - cn) - a_old + math.pi) % (2 * math.pi) - math.pi)
                if da <= math.radians(45):
                    kind, nx, nz = 'DK-CY-arrival', best['x'], best['z']
                    why = 'điểm cũ sát biên, cùng hướng cổng CY ScenePosDefineEx#%d %s→ (lệch %.0f°)' % (best['id'], best['from_name'], math.degrees(da))
        if kind is None:
            kind, nx, nz, why = 'SL-affine', tx, tz, 'affine' if T is not IDENTITY else 'giữ'
        if not nav.walkable(nx, nz, region):
            mv = nav.nearest_walkable(nx, nz, region, max_r=15)
            if mv:
                why += ' → ô đi được gần nhất %.1f ô [SL]' % mv[2]
                nx, nz = mv[0], mv[1]
                kind += '+doi'
            else:
                why += ' — KHÔNG có ô đi được trong 15 ô'
                kind += '+KHONG'
        rec.update({'new': [int(round(nx)), int(round(nz))], 'kind': kind, 'why': why})
        fixes.append(rec)
    return fixes


# ----------------------------------------------------------------------------------------------- install
# Toạ độ đích vào cảnh 2 viết cứng trong Game_2/Script bị rơi vào tam giác chặn của navmesh CY (audit-scripts).
# (file, số dòng, (x, z) cũ, (x, z) mới, nguồn) — dali (cs3a). Các thành khác lấy từ report.json (plan_script_fixes).
SCRIPT_FIXES = {
    'dali': [
        ('scripts/chuan_song_system.lua', 193, (242, 137), (253, 121), 'CY TransportDefine#65–81: 驿站 崔逢九 (253,121) là đích vào 大理'),
        ('scripts/chuan_song_system.lua', 232, (242, 137), (253, 121), 'CY TransportDefine: đích vào 大理 (253,121)'),
        ('scripts/obj/prison/oprison_jailer.lua', 79, (242, 137), (253, 121), 'CY TransportDefine: đích vào 大理 (253,121) [SL: ra tù về 驿站]'),
        ('scripts/obj/prison/oprison_jailer.lua', 115, (242, 137), (253, 121), 'như trên [SL]'),
        ('scripts/event/chuansong/echuansong_to_dali.lua', 6, (241, 141), (253, 121), 'CY ScenePosDefineEx#216/232/248/264: →大理 (253,121)'),
        ('scripts/obj/wudang/owudang_motaichong.lua', 100, (241, 141), (253, 121), 'CY ScenePosDefineEx#347 武当山→大理 (253,121)'),
        ('scripts/obj/loulangucheng/oloulan_ainiwaer.lua', 136, (241, 141), (253, 121), 'CY ScenePosDefineEx#447 楼兰→大理 (253,121)'),
        ('scripts/obj/shuhe/oshuhe_xuxiake.lua', 90, (241, 141), (253, 121), 'CY ScenePosDefineEx#464 束河古镇→大理 (253,121)'),
        ('scripts/obj/tianlong/otianlong_pochen.lua', 100, (241, 141), (253, 121), 'CY ScenePosDefineEx#363 天龙寺→大理 (253,121)'),
        ('scripts/obj/xingxiu/oxingxiu_tianlangzi.lua', 99, (241, 141), (253, 121), 'CY ScenePosDefineEx#411 星宿海→大理 (253,121)'),
        ('scripts/obj/petisland/opetisland_guijia.lua', 74, (263, 129), (253, 125), 'CY ScenePosDefineEx#529 玄武岛→大理 (253,125)'),
        ('scripts/obj/suzhou/osuzhou_dengmao.lua', 99, (241, 141), (253, 121), 'CY ScenePosDefineEx#264 苏州→大理 (253,121)'),
        ('scripts/obj/suzhou/osuzhou_lichengfeng.lua', 101, (241, 141), (253, 121), 'CY ScenePosDefineEx#248 苏州→大理 (253,121)'),
        ('scripts/obj/mingjiao/omingjiao_fangqifo.lua', 100, (241, 141), (253, 121), 'CY ScenePosDefineEx#331 光明殿→大理 (253,121)'),
        ('scripts/obj/shaolin/oshaolin_huilun.lua', 100, (241, 141), (253, 121), 'CY ScenePosDefineEx#299 少林寺→大理 (253,121)'),
        ('scripts/obj/luoyang/oluoyang_wudechang.lua', 128, (241, 141), (253, 121), 'CY ScenePosDefineEx#232 洛阳→大理 (253,121)'),
        ('scripts/obj/luoyang/oluoyang_wanghan.lua', 127, (241, 141), (253, 121), 'CY ScenePosDefineEx#216 洛阳→大理 (253,121)'),
        ('scripts/obj/tianshan/otianshan_wulaoda.lua', 100, (241, 141), (253, 121), 'CY ScenePosDefineEx#427 天山→大理 (253,121)'),
        ('scripts/obj/xiaoyao/oxiaoyao_likuilei.lua', 100, (241, 141), (253, 121), 'CY ScenePosDefineEx#379 凌波洞→大理 (253,121)'),
        ('scripts/obj/gaibang/ogaibang_zhangquanxiang.lua', 100, (241, 141), (253, 121), 'CY ScenePosDefineEx#315 丐帮总舵→大理 (253,121)'),
        ('scripts/obj/emei/oemei_yangsiniang.lua', 100, (241, 141), (253, 121), 'CY ScenePosDefineEx#395 峨嵋山→大理 (253,121)'),
        ('scripts/event/chuansong/echuansong_newbie_2_dali.lua', 6, (275, 50), (276, 50), 'ô đi được gần nhất trên navmesh CY [SL]'),
        ('scripts/event/chuansong/echuansong_murenxiang_07.lua', 9, (275, 50), (276, 50), 'ô đi được gần nhất [SL]; CY 小木人巷→大理 là (160,153)'),
    ],
}


def replace_in_line(data, line_no, scene_id, old, new):
    """Đổi `, <scene>, x, z` trên đúng một dòng (mọi lần xuất hiện của cặp cũ); trả (bytes, số lần)."""
    lines = data.split(b'\n')
    line = lines[line_no - 1]
    pat = re.compile(rb'([,(]\s*%d\s*,\s*)%s(\s*,\s*)%s\b' % (scene_id, re.escape(fmt_num(old[0])), re.escape(fmt_num(old[1]))))
    n = len(pat.findall(line))
    if n < 1:
        raise SystemExit('pattern %r not found on line %d' % (old, line_no))
    lines[line_no - 1] = pat.sub(lambda m: m.group(1) + fmt_num(new[0]) + m.group(2) + fmt_num(new[1]), line)
    return b'\n'.join(lines), n


def fmt_num(v):
    return (b'%d' % int(v)) if float(v).is_integer() else (b'%s' % repr(float(v)).encode())


def replace_table_cells(path, row_id, changes, key_col=0):
    """changes: {column index: new ascii value}; byte-level on one GBK row, keeps tab count and line ending."""
    raw = open(path, 'rb').read()
    lines = raw.split(b'\n')
    hits = [i for i, l in enumerate(lines) if len(l.split(b'\t')) > key_col and l.rstrip(b'\r').split(b'\t')[key_col] == str(row_id).encode()]
    if len(hits) != 1:
        raise SystemExit('%s: row %s found %d times' % (path, row_id, len(hits)))
    i = hits[0]
    line = lines[i]
    cr = line.endswith(b'\r')
    cells = (line[:-1] if cr else line).split(b'\t')
    before = {}
    for col, value in changes.items():
        before[col] = cells[col].decode('gbk')
        cells[col] = value.encode('ascii')
    new_line = b'\t'.join(cells) + (b'\r' if cr else b'')
    if new_line.count(b'\t') != line.count(b'\t'):
        raise SystemExit('tab count changed')
    new_line.decode('gbk')
    lines[i] = new_line
    return b'\n'.join(lines), {'row': row_id, 'line': i + 1, 'before': before,
                               'after': {c: v for c, v in changes.items()}, 'tabs': line.count(b'\t')}


def install(args):
    import hashlib
    import shutil
    city = CITIES[args.city]
    staging = args.staging or os.path.join('/dev/shm/cs3a', args.city)
    report = json.load(open(os.path.join(staging, 'report.json'), encoding='utf-8'))
    scene_dir = os.path.join(SERVER, 'Game_2', 'Scene')
    manifest = {'city': args.city, 'scene_id': city['scene_id'], 'copied': [], 'edited': []}

    def sha(p):
        return hashlib.sha256(open(p, 'rb').read()).hexdigest()

    # 1. file cảnh + navmesh CY
    for name in sorted(report['files']) + [city['new'] + '.path']:
        src = os.path.join(CY_DATA, 'SceneFolder', name) if name.endswith('.path') else os.path.join(staging, name)
        dst = os.path.join(scene_dir, name)
        rec = {'file': os.path.relpath(dst, SERVER), 'source': src}
        if os.path.exists(dst):
            rec['sha256_before'] = sha(dst)
            if rec['sha256_before'] != sha(src) and not args.force:
                raise SystemExit('refuse to overwrite different file (dùng --force): ' + dst)
        shutil.copyfile(src, dst)
        rec.update({'sha256': sha(dst), 'bytes': os.path.getsize(dst)})
        manifest['copied'].append(rec)
    # 2. SceneInfo.ini [sceneN] file= cho cảnh gốc và phân tuyến
    path = os.path.join(SERVER, 'configs', 'SceneInfo.ini')
    raw = open(path, 'rb').read()
    for sid in [city['scene_id']] + list(city.get('shards', [])):
        m = re.search(rb'(\[scene%d\][^\[]*?\n)file=%s\.scn' % (sid, city['old'].encode()), raw)
        if m and city['old'] != city['new']:
            raw2 = raw[:m.start()] + m.group(1) + b'file=' + city['new'].encode() + b'.scn' + raw[m.end():]
            if raw2.count(b'\n') != raw.count(b'\n'):
                raise SystemExit('SceneInfo line count changed')
            raw = raw2
            manifest['edited'].append({'file': 'configs/SceneInfo.ini', 'section': 'scene%d' % sid,
                                       'before': 'file=%s.scn' % city['old'], 'after': 'file=%s.scn' % city['new']})
        elif re.search(rb'\[scene%d\][^\[]*?\nfile=%s\.scn' % (sid, city['new'].encode()), raw):
            manifest['edited'].append({'file': 'configs/SceneInfo.ini', 'section': 'scene%d' % sid, 'note': 'đã trỏ sẵn ' + city['new']})
        else:
            raise SystemExit('SceneInfo.ini: [scene%d] file=%s.scn not found' % (sid, city['old']))
    open(path, 'wb').write(raw)
    # 3. SceneAttr (cột 4/5 = 可以站立的位置X/Z theo CY) và SceneDefineEx (cột 2–16 theo CY)
    cy_attr = report['cy_scene_attr']
    path = os.path.join(SERVER, 'configs', 'SceneAttr.txt')
    data, info = replace_table_cells(path, city['scene_id'], {4: cy_attr[4], 5: cy_attr[5]})
    open(path, 'wb').write(data)
    manifest['edited'].append(dict(info, file='configs/SceneAttr.txt', source='CY SceneAttr.txt dòng %d' % city['scene_id']))
    cy_def = [r for r in read_table('SceneDefineEx.txt') if r[0] == str(city['scene_id'])][0]
    path = os.path.join(SERVER, 'configs', 'SceneDefineEx.txt')
    data, info = replace_table_cells(path, city['scene_id'], {c: cy_def[c] for c in range(2, 17)})
    open(path, 'wb').write(data)
    manifest['edited'].append(dict(info, file='configs/SceneDefineEx.txt',
                                   source='CY SceneDefineEx.txt dòng %d cột 2–16 (server giữ 24 cột, không thêm cột 25)' % city['scene_id']))
    # 3b. Stall_Info.txt (ô sạp theo cảnh) — khoá theo cột 0 序号
    path = os.path.join(SERVER, 'configs', 'Stall_Info.txt')
    for st in report.get('stall_rows', []):
        if st['old'] == st['new']:
            continue
        data, info = replace_table_cells(path, st['row'], {5: st['new'][0], 6: st['new'][1], 7: st['new'][2], 8: st['new'][3]})
        open(path, 'wb').write(data)
        manifest['edited'].append(dict(info, file='configs/Stall_Info.txt', source=st['source']))
    # 4. toạ độ đích trong script
    nav = NavMesh(os.path.join(CY_DATA, 'SceneFolder', city['new'] + '.path'))
    region = nav.locate(*city['spawn'])[2]
    fixes = [(f, l, tuple(o), tuple(n), w) for f, l, o, n, w in SCRIPT_FIXES.get(args.city, [])]
    for r in report.get('script_fixes', []):
        rel = os.path.relpath(r['file'], 'Game_2/Script')
        fixes.append((rel, r['line'], (r['x'], r['z']), tuple(r['new']), r['kind'] + ': ' + r['why']))
    # gộp theo file để số dòng không đổi (chỉ đổi trong dòng)
    for rel, line_no, old, new, why in fixes:
        if not nav.walkable(new[0], new[1], region):
            raise SystemExit('fix target not walkable: %s %s' % (rel, new))
        path = os.path.join(SERVER, 'Game_2', 'Script', rel)
        raw = open(path, 'rb').read()
        if old == new:
            continue
        try:
            raw2, n = replace_in_line(raw, line_no, city['scene_id'], old, new)
        except SystemExit as e:
            # đã sửa (idempotent)?
            lines = raw.split(b'\n')
            if re.search(rb'[,(]\s*%d\s*,\s*%s\s*,\s*%s\b' % (city['scene_id'], re.escape(fmt_num(new[0])), re.escape(fmt_num(new[1]))), lines[line_no - 1]):
                manifest['edited'].append({'file': 'Game_2/Script/' + rel, 'line': line_no, 'note': 'đã sửa sẵn', 'after': list(new)})
                continue
            raise
        open(path, 'wb').write(raw2)
        manifest['edited'].append({'file': 'Game_2/Script/' + rel, 'line': line_no, 'before': list(old), 'after': list(new),
                                   'count': n, 'source': why})
    out = os.path.join(staging, 'install.json')
    json.dump(manifest, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps({'copied': len(manifest['copied']), 'edited': len(manifest['edited']), 'manifest': out},
                     ensure_ascii=False))


# ----------------------------------------------------------------------------------------------- block-portals
def block_portals(args):
    """area.ini đã cài của thành: mục có script_id là script cổng mà MỌI cảnh đích không thuộc KEEP_SCENES → script_id=-1.
    (Cổng tới cảnh đã tắt; nếu để nguyên, msgagent đưa người chơi về DEFAULT_SCENEID_AND_WORLD_POS.)"""
    city = CITIES[args.city]
    path = os.path.join(SERVER, 'Game_2', 'Scene', city['new'] + '_area.ini')
    raw = open(path, 'rb').read()
    text = raw.decode('gbk')
    if text.encode('gbk') != raw:
        raise SystemExit('GBK round-trip failed: ' + path)
    head, sections = parse_ini_sections(text)
    log = []
    for name, items in sections:
        if not name.lower().startswith('area') or name == 'area_info':
            continue
        sid = ini_get(items, 'script_id')
        if sid is None or int(sid) <= 0:
            continue
        rel, targets = portal_targets_of_script(int(sid), city['scene_id'])
        rec = {'section': name, 'script_id': int(sid), 'script': rel, 'targets': targets}
        if targets and not any(t in KEEP_SCENES for t in targets):
            ini_set(items, 'script_id', '-1')
            rec['action'] = 'script_id=-1 (mọi cảnh đích đã tắt)'
        elif targets:
            rec['action'] = 'giữ (có cảnh đích thuộc KEEP_SCENES)'
        else:
            rec['action'] = 'giữ (không phải script cổng)'
        log.append(rec)
    out = render_ini(head, sections).encode('gbk')
    if not args.dry_run:
        open(path, 'wb').write(out)
    result = {'file': os.path.relpath(path, SERVER), 'dry_run': bool(args.dry_run), 'areas': log,
              'blocked': sum(1 for r in log if r.get('action', '').startswith('script_id=-1'))}
    if args.out:
        json.dump(result, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps(result, ensure_ascii=False))


# ----------------------------------------------------------------------------------------------- scenes-off / scenes-on
def scene_info_sections(raw):
    """[(start, end, id, text)] cho từng [sceneN] trong SceneInfo.ini (bytes)."""
    out = []
    starts = [m.start() for m in re.finditer(rb'^\[scene(\d+)\]', raw, re.M)] + [len(raw)]
    for a, b in zip(starts, starts[1:]):
        sid = int(re.match(rb'\[scene(\d+)\]', raw[a:]).group(1))
        end = b
        nxt = re.search(rb'^\[', raw[a + 1:b], re.M)
        if nxt:
            end = a + 1 + nxt.start()
        out.append((a, end, sid, raw[a:end]))
    return out


def scenes_off(args):
    path = os.path.join(SERVER, 'configs', 'SceneInfo.ini')
    raw = open(path, 'rb').read()
    record = {'why': 'Chỉ thị người dùng 14/09: chỉ 3 thành chính + Vô Lượng Sơn (+ phân tuyến, 地府); cảnh khác active=0. Bật lại: cs3a_scene.py scenes-on',
              'keep': sorted(KEEP_SCENES), 'off': []}
    pieces, pos = [], 0
    for a, end, sid, sec in scene_info_sections(raw):
        if sid in KEEP_SCENES:
            continue
        if not re.search(rb'^type=0\b', sec, re.M):
            continue
        m = re.search(rb'^active=1\b', sec, re.M)
        if not m:
            continue
        name = re.search(rb'^name=([^\r\n;]*)', sec, re.M)
        record['off'].append({'id': sid, 'name': name.group(1).strip().decode('gbk', 'replace') if name else ''})
        pieces.append(raw[pos:a + m.start()] + b'active=0' + raw[a + m.end():end])
        pos = end
    pieces.append(raw[pos:])
    raw2 = b''.join(pieces)
    if raw2.count(b'\n') != raw.count(b'\n') or len(raw2) != len(raw):
        raise SystemExit('SceneInfo size/line count changed')
    rec_path = os.path.join(SERVER, SCENE_OFF_RECORD)
    if not args.dry_run:
        open(path, 'wb').write(raw2)
        json.dump(record, open(rec_path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    if args.out:
        json.dump(record, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps({'off': len(record['off']), 'record': rec_path, 'dry_run': bool(args.dry_run)}, ensure_ascii=False))


def scenes_on(args):
    path = os.path.join(SERVER, 'configs', 'SceneInfo.ini')
    raw = open(path, 'rb').read()
    record = json.load(open(os.path.join(SERVER, SCENE_OFF_RECORD), encoding='utf-8'))
    ids = {r['id'] for r in record['off']}
    pieces, pos, n = [], 0, 0
    for a, end, sid, sec in scene_info_sections(raw):
        if sid not in ids:
            continue
        m = re.search(rb'^active=0\b', sec, re.M)
        if not m:
            continue
        pieces.append(raw[pos:a + m.start()] + b'active=1' + raw[a + m.end():end])
        pos = end
        n += 1
    pieces.append(raw[pos:])
    open(path, 'wb').write(b''.join(pieces))
    print(json.dumps({'on': n}))


# ----------------------------------------------------------------------------------------------- default-pos
def default_pos(args):
    path = os.path.join(SERVER, 'GameServer', 'lualib', 'define.lua')
    raw = open(path, 'rb').read()
    m = re.search(rb'(define\.DEFAULT_SCENEID_AND_WORLD_POS = \{\s*\n\s*sceneid = 2,\s*\n\s*world_pos = \{x = )(\d+)(, y = )(\d+)(\})', raw)
    if not m:
        raise SystemExit('define.DEFAULT_SCENEID_AND_WORLD_POS không đúng khuôn')
    before = (int(m.group(2)), int(m.group(4)))
    tail = raw[m.end():]
    note = b' -- cs3a2: diem dung CY dali_new_320 (SceneAttr CY dong 2)'
    if before == (args.x, args.z) or tail.startswith(note):
        print(json.dumps({'file': 'GameServer/lualib/define.lua', 'before': before, 'after': [args.x, args.z], 'note': 'đã đúng'}))
        return
    raw2 = raw[:m.start()] + m.group(1) + b'%d' % args.x + m.group(3) + b'%d' % args.z + m.group(5) + note + tail
    open(path, 'wb').write(raw2)
    print(json.dumps({'file': 'GameServer/lualib/define.lua', 'before': before, 'after': [args.x, args.z]}))


# ----------------------------------------------------------------------------------------------- survey
def survey(args):
    city = CITIES[args.city]
    scene_dir = os.path.join(SERVER, 'Game_2', 'Scene')
    nav = NavMesh(os.path.join(CY_DATA, 'SceneFolder', city['new'] + '.path'))
    hit = nav.locate(*city['spawn'])
    region = hit[2] if hit and not hit[1] & 1 else None
    cy_npc, cy_portals, cy_attr = cy_positions(city)
    _, sections = parse_ini_sections(open(os.path.join(scene_dir, city['old'] + '_monster.ini'), 'rb').read().decode('gbk'))
    old = []
    for name, items in sections:
        try:
            old.append((ini_get(items, 'name') or '', ini_get(items, 'title') or '',
                        float(ini_get(items, 'pos_x')), float(ini_get(items, 'pos_z'))))
        except (TypeError, ValueError):
            pass
    t, fit = fit_city_affine(cy_npc, old)
    walk_old = walk_tf = 0
    for nm, title, ox, oz in old:
        walk_old += nav.walkable(ox, oz, region)
        if t:
            walk_tf += nav.walkable(*apply_affine(t, ox, oz), region)
    hj = tlbb15_monsters(city)
    hj_names = {m['name'] for m in hj}
    refs = script_refs(city)
    refs_walk_tf = sum(1 for r in refs if t and nav.walkable(*apply_affine(t, r['x'], r['z']), region))
    out = {'city': args.city, 'scene_id': city['scene_id'], 'navmesh': nav.info(),
           'cy_spawn': {'xz': city['spawn'], 'walkable': region is not None, 'region': region, 'cy_scene_attr': cy_attr[:8] if cy_attr else None},
           'cy_npc_names': len(cy_npc), 'cy_walk_portals': cy_portals,
           'old_monster_entries': len(old), 'old_positions_walkable_on_cy_as_is': walk_old,
           'name_pairs_for_fit': fit.get('pairs'), 'affine_old_to_cy': fit.get('affine'),
           'fit_residual': fit.get('residual'),
           'old_positions_walkable_after_affine': walk_tf,
           'tlbb15_entries': len(hj), 'tlbb15_names_matching_old': len({o[0] for o in old} & hj_names),
           'script_refs_to_scene': len(refs), 'script_refs_walkable_after_affine': refs_walk_tf}
    text = json.dumps(out, ensure_ascii=False, indent=1)
    if args.out:
        open(args.out, 'w', encoding='utf-8').write(text + '\n')
    print(text)


# ----------------------------------------------------------------------------------------------- retype (CS3c)
def retype(args):
    """CS3c: đổi `type=` của mục quái theo map JSON {"retype": {section: [old, new, name]}, "disable": [section...]}.
    --disable-mode pos (mặc định, quy ước cs3c: pos_x=;giá trị) | rename ([monsterN] → [monsterN_off], bỏ qua sạch)."""
    city = CITIES[args.city]
    path = args.src or os.path.join(SERVER, 'Game_2', 'Scene', city['new'] + '_monster.ini')
    raw = open(path, 'rb').read()
    text = raw.decode('gbk')
    if text.encode('gbk') != raw:
        raise SystemExit('GBK round-trip failed: ' + path)
    spec = json.load(open(args.map, encoding='utf-8'))
    text2, done = apply_retype(text, spec, args.disable_mode)
    out = text2.encode('gbk')
    open(args.out or path, 'wb').write(out)
    print(json.dumps({'file': args.out or path, 'done': done, 'bytes': len(out)}, ensure_ascii=False))


def retype_plan(args):
    city = CITIES[args.city]
    path = args.src or os.path.join(SERVER, 'Game_2', 'Scene', city['new'] + '_monster.ini')
    text = open(path, 'rb').read().decode('gbk')
    gl, cy = monster_tables()
    spec = retype_plan_for_ini(text, gl, cy)
    spec['file'] = path
    json.dump(spec, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps({'file': path, 'stats': spec['stats'], 'retype': len(spec['retype']), 'disable': len(spec['disable']), 'out': args.out}, ensure_ascii=False))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('path-info'); a.add_argument('file')
    a = sub.add_parser('query'); a.add_argument('file'); a.add_argument('points', nargs='+')
    a = sub.add_parser('build'); a.add_argument('--city', choices=sorted(CITIES), required=True); a.add_argument('--out')
    a = sub.add_parser('audit-scripts'); a.add_argument('--city', choices=sorted(CITIES), required=True); a.add_argument('--out')
    a = sub.add_parser('install'); a.add_argument('--city', choices=sorted(CITIES), required=True)
    a.add_argument('--staging'); a.add_argument('--force', action='store_true')
    a = sub.add_parser('survey'); a.add_argument('--city', choices=sorted(CITIES), required=True); a.add_argument('--out')
    a = sub.add_parser('retype'); a.add_argument('--city', choices=sorted(CITIES), required=True); a.add_argument('--map', required=True)
    a.add_argument('--src'); a.add_argument('--out'); a.add_argument('--disable-mode', choices=('pos', 'rename'), default='pos')
    a = sub.add_parser('retype-plan'); a.add_argument('--city', choices=sorted(CITIES), required=True); a.add_argument('--out', required=True); a.add_argument('--src')
    a = sub.add_parser('block-portals'); a.add_argument('--city', choices=sorted(CITIES), required=True); a.add_argument('--out'); a.add_argument('--dry-run', action='store_true')
    a = sub.add_parser('scenes-off'); a.add_argument('--out'); a.add_argument('--dry-run', action='store_true')
    sub.add_parser('scenes-on')
    a = sub.add_parser('default-pos'); a.add_argument('--x', type=int, required=True); a.add_argument('--z', type=int, required=True)
    args = ap.parse_args()
    if args.cmd == 'survey':
        survey(args)
    elif args.cmd == 'retype':
        retype(args)
    elif args.cmd == 'retype-plan':
        retype_plan(args)
    elif args.cmd == 'block-portals':
        block_portals(args)
    elif args.cmd == 'scenes-off':
        scenes_off(args)
    elif args.cmd == 'scenes-on':
        scenes_on(args)
    elif args.cmd == 'default-pos':
        default_pos(args)
    elif args.cmd == 'install':
        install(args)
    elif args.cmd == 'path-info':
        print(json.dumps(NavMesh(args.file).info(), ensure_ascii=False, indent=1))
    elif args.cmd == 'query':
        nav = NavMesh(args.file)
        for p in args.points:
            x, z = (float(v) for v in p.split(','))
            print(p, nav.locate(x, z))
    elif args.cmd == 'build':
        build(args)
    else:
        audit_scripts(args)


if __name__ == '__main__':
    main()
