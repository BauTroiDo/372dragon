#!/usr/bin/env python3
"""CS3c (phần còn lại) — bảng server theo ID CY 3.71 cho SERVER RIÊNG: StandardImpact/ImpactSEData/ImpactDirectly/Bullet,
MonsterAttrEx/PetAttr/PetHuanhua/PetSkillBook/PetCollection, CommonItem/ShopTable, MonsterDropBoxs/DropBoxContent/DropRateOfItemTable,
EquipBase cột 19 (impact), cầu nối cy_four_combat theo ID CY, hằng impact trong Lua, và _monster.ini cảnh 2.

Chạy trong WSL TLBB bằng root (python3 -B). Chỉ ghi vào R=/home/ubuntu/cys-test-20260913 (sau backup); nguồn CY/tlbb15/Registry chỉ đọc.
Bảng server giữ GBK ở mức byte. Đặc tả: Docs/specs/server/cs3c-tables_vi.md. Khuôn mẫu: cs3b_menpai.py.

  cs3c_tables.py plan   --out <dir>                  dựng bảng/Lua/ini vào <dir>/{configs,lua,scene}; plan.json (không chạm R)
  cs3c_tables.py apply  --staging <dir> [--dry-run]  chép vào R (sao lưu từng file R/backups/cs3c-<UTC>/), idempotent
  cs3c_tables.py verify [--staging <dir>] [--out json]  GBK, tab, ID, tham chiếu chéo, luac -p, nạp thử config cy_four bằng lua5.4

Nguồn dòng (ID = CY):  CY  = bảng client CY (Tools/DATA NEW/DataCY31-08-26/Config, không có tên cột)
                       HJP = tlbb15/Public/Config (bố cục GL + tên cột, ID CY)   HJS = tlbb15/Server/Config (StandardImpact, drop, ShopTable)
                       GL  = bảng server riêng tại 995c2df (trước CS3b) — chỉ để lấy cột chỉ-GL trên dòng cùng ID cùng tên, và lưu trữ dòng chỉ-GL.
"""
import argparse
import collections
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table_bytes, read_table, write_table, git_show, g, sha, MENPAI_MAP  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
R = '/home/ubuntu/cys-test-20260913'
CY_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
HJP_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/tlbb15/Public/Config'
HJS_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/tlbb15/Server/Config'
BASE_REV = '995c2df'          # bảng GL (server riêng trước CS3b)
BORROW_ID_OLD, BORROW_ID_NEW = 19001, 69001   # 借力状态 (GL tự chế, logic 532): HJS 19001 = 高级血爆 → dời sang ID trống
LOGIC_8000_REMAP = {8507: 14, 8513: 14}     # HJS: 2 dòng 定身 có 逻辑ID说明 = STD_IMPACT_014 [SL]
RESERVED = {'StandardImpact.txt': 100000, 'ImpactSEData_V1.txt': 100000, 'ImpactDirectly.txt': 10000, 'Bullet.txt': 1000,
            'MonsterAttrExTable.txt': 100000, 'PetAttrTable.txt': 100000, 'CommonItem.txt': 1000000, 'ShopTable.txt': 1000,
            'PetHuanhuaTable.txt': 100000, 'PetCollection.txt': 100000, 'MonsterDropBoxs.txt': 100000, 'DropBoxContent.txt': 100000,
            'DropRateOfItemTable.txt': 1000000}
CONV_TABLES = ['StandardImpact.txt', 'ImpactSEData_V1.txt', 'ImpactDirectly.txt', 'Bullet.txt', 'MonsterAttrExTable.txt', 'PetAttrTable.txt',
               'CommonItem.txt', 'ShopTable.txt', 'PetHuanhuaTable.txt', 'PetSkillBook.txt', 'PetCollection.txt',
               'MonsterDropBoxs.txt', 'DropBoxContent.txt', 'DropRateOfItemTable.txt']
# Ánh xạ cột GL(server) ← CY, bằng chứng: Build/Logs/2026-09-14-cs3c-tables/{03,04}-survey-*.json (khớp ≥ 0.9 trên dòng cùng ID cùng tên,
# hoặc ma trận HJP↔CY vì HJP có tên cột và ID CY). Cột không có trong map: lấy dòng GL cùng ID cùng tên, không thì mặc định (giá trị phổ biến).
COLMAP = {
    'ImpactSEData_V1.txt': {k: k for k in range(22)},                                   # CY 0–21 cùng kiểu/vị trí; CY 22–27 thêm
    'Bullet.txt': {**{k: k for k in range(9)}, 14: 13, 15: 14},                          # registry 0–8; 描述 ← CY 13; 标记 ← CY 14
    'MonsterAttrExTable.txt': {**{k: k for k in range(4)}, 4: 66, 6: 64, 7: 68, 8: 69, 9: 70, 10: 71, 11: 72,
                               **{12 + k: 4 + k for k in range(32)}, 44: 36, **{45 + k: 37 + k for k in range(25)}},   # HJP↔CY 100 % cả 8 cột server
    'PetAttrTable.txt': {0: 0, 1: 1, **{2 + k: 3 + k for k in range(21)}, **{33 + k: 24 + k for k in range(18)}},   # GL 23–32 (被动6–10) CY không có
    'CommonItem.txt': {**{k: k for k in range(15)}, 15: 27, **{16 + k: 15 + k for k in range(9)}, 25: 24, 26: 25},  # 是否消耗 ← CY 27 (HJP 99,9 %)
    'PetHuanhuaTable.txt': {0: 0, 1: 1, 2: 2, 3: 4, 4: 5},
    'PetSkillBook.txt': {0: 0, 1: 1},
}
# ImpactDirectly: server không nạp; ghi theo bố cục tlbb15 Public (20 cột có tên) ← CY 25 cột (nhóm 4: 特效/音效/绑定点/INT thêm)
IMPACTDIRECTLY_HJP_FROM_CY = {0: 0, 1: 1, 2: 2, 3: 3, 4: 5, 5: 6, 6: 7, 7: 9, 8: 10, 9: 11, 10: 13, 11: 14, 12: 15, 13: 17, 14: 18, 15: 19, 16: 21, 17: 22, 18: 23, 19: 24}
SHOP_FIXED_GL, SHOP_FIXED_CY, SHOP_ITEMS = 27, 29, 200     # CY thêm 3 cột 18–20; GL có is_yuanbao_shop (26); 6 cột/món
NAME_COL = {'MonsterAttrExTable.txt': (1, 1), 'PetAttrTable.txt': (1, 1), 'CommonItem.txt': (6, 6), 'StandardImpact.txt': (1, 1), 'Bullet.txt': (14, 13)}
MONSTER_COL = {'base_ai': 7, 'ext_ai': 8, 'friend': 5, 'skill': 70}
PET_GL_ONLY_COLS = list(range(23, 33))
EQUIP_IMPACT_COL, EQUIP_CY_IMPACT_COL = 19, 101
LUA_IMPACT_CONSTS = [   # (file, hằng GL, tên hiệu ứng GL) → tra HJS theo tên (duy nhất) → ID CY
    ('GameServer/services/scene/skill/murong_skill_common.lua', 'M.HUAQI_BUFF_DATA_INDEX = %d', 12608),
    ('GameServer/services/scene/skill/human/skill_73.lua', 'impactenginer:send_impact_to_unit(target, %d, obj_me', 8425),
    ('GameServer/services/scene/skill/talent_logic/std_talent_757.lua', 'local DINGSHEN_DATA_INDEX = %d', 1331),
]
CY4_DIR = 'GameServer/lualib/cy_four_combat'


# ---------------------------------------------------------------- nguồn
class Sources:
    def __init__(self, base_rev):
        self.base_rev = base_rev
        self.gl, self.cy, self.hjp, self.hjs = {}, {}, {}, {}
        for t in CONV_TABLES + ['EquipBase.txt', 'SkillData_V1.txt', 'SkillTemplate_V1.txt']:
            if t in CONV_TABLES:
                self.gl[t] = read_table_bytes(git_show(base_rev, 'configs/' + t))
            p = os.path.join(CY_DIR, t)
            if os.path.exists(p):
                self.cy[t] = read_table(p)
            p = os.path.join(HJP_DIR, t)
            if os.path.exists(p) and t in ('MonsterAttrExTable.txt', 'PetAttrTable.txt', 'CommonItem.txt', 'ImpactDirectly.txt'):
                self.hjp[t] = read_table(p)
            p = os.path.join(HJS_DIR, t)
            if os.path.exists(p) and t in ('StandardImpact.txt', 'MonsterDropBoxs.txt', 'DropBoxContent.txt', 'DropRateOfItemTable.txt', 'ShopTable.txt'):
                self.hjs[t] = read_table(p)
        self.now = {}     # bảng R hiện tại (đã CY sau CS3b)
        for t in ('EquipBase.txt', 'SkillData_V1.txt', 'SkillTemplate_V1.txt'):
            self.now[t] = read_table(os.path.join(R, 'configs', t))
        self.gl_by_id = {t: by_id(v) for t, v in self.gl.items()}
        self.cy_by_id = {t: by_id(v) for t, v in self.cy.items()}
        self.hjs_by_id = {t: by_id(v) for t, v in self.hjs.items()}


def by_id(tb):
    out = {}
    for r in tb['rows']:
        out.setdefault(int(r[0]), r)
    return out


def isint(b):
    return b.strip().lstrip(b'-').isdigit()


def mode_defaults(types, rows):
    out = []
    for i, t in enumerate(types):
        vals = collections.Counter(r[i] for r in rows if i < len(r))
        out.append(vals.most_common(1)[0][0] if vals else (b'-1' if t == b'INT' else b''))
    return out


def pad(r, n):
    return (list(r) + [b''] * (n - len(r)))[:n]


def archive_gl_only(staging, t, gl, keep_ids, eol, note):
    """Dòng GL có ID không nằm trong bảng mới → configs/cys_gl_only/<t>.txt (bố cục GL) + reserved_ids.tsv."""
    arch = [r for r in gl['rows'] if int(r[0]) not in keep_ids]
    if not arch:
        return 0
    n = len(gl['types'])
    names = gl['names'] if gl['names'] is not None else gl['types']
    write_table(os.path.join(staging, 'configs', 'cys_gl_only', t), gl['types'], names, [pad(r, n) for r in arch], eol)
    with open(os.path.join(staging, 'configs', 'cys_gl_only', t + '.reserved_ids.tsv'), 'w', encoding='utf-8') as f:
        f.write('# ID gốc GL\tID dải riêng đề xuất (+%d) — dòng CHƯA nạp, chỉ lưu trữ (CS3c). %s\n' % (RESERVED[t], note))
        for r in arch:
            f.write('%d\t%d\n' % (int(r[0]), int(r[0]) + RESERVED[t]))
    return len(arch)


# ---------------------------------------------------------------- bảng theo ánh xạ cột (CY → bố cục GL)
def convert_by_colmap(src, t, staging, plan, extra=None):
    gl, cy = src.gl[t], src.cy[t]
    types, names, eol = list(gl['types']), list(gl['names'] or gl['types']), gl['eol']
    n = len(types)
    colmap = COLMAP[t]
    gname, cname = NAME_COL.get(t, (None, None))
    gl_by_id = {i: pad(r, n) for i, r in src.gl_by_id[t].items()}
    defaults = mode_defaults(types, list(gl_by_id.values()))
    if t == 'PetAttrTable.txt':
        for k in PET_GL_ONLY_COLS:
            defaults[k] = b'-1' if k % 2 == 1 else b'0'
    rows, src_counter, notes = [], collections.Counter(), collections.Counter()
    skipped = []
    for cid, cyrow in sorted(src.cy_by_id[t].items()):
        if t == 'PetAttrTable.txt' and cid not in src.cy_by_id['MonsterAttrExTable.txt']:
            skipped.append(cyrow); notes['cy_pet_without_monster_skipped'] += 1     # CY 34670/34671 "新珍兽" placeholder
            continue
        glrow = gl_by_id.get(cid)
        same = glrow is not None and (gname is None or glrow[gname] == cyrow[cname])
        base = list(glrow) if same else list(defaults)
        src_counter['gl-same' if same else 'default'] += 1
        row = base
        for glc, cyc in colmap.items():
            if glc < n and cyc < len(cyrow):
                row[glc] = cyrow[cyc]
        for k in range(n):
            if row[k] == b'' and types[k] in (b'INT', b'FLOAT'):
                row[k] = defaults[k] if defaults[k] != b'' else b'0'
        if extra:
            extra(cid, row, glrow if same else None, notes)
        rows.append(row)
    write_table(os.path.join(staging, 'configs', t), types, names, rows, eol)
    arch = archive_gl_only(staging, t, gl, set(src.cy_by_id[t]), eol, 'ID không có ở CY 3.71.')
    if skipped:
        write_table(os.path.join(staging, 'configs', 'cys_gl_only', t.replace('.txt', '.cy_placeholder.txt')), cy['types'], cy['types'], skipped, eol)
    # kiểm khớp ánh xạ trên dòng cùng ID cùng tên (bằng chứng)
    agree = {}
    if gname is not None:
        common = [i for i in gl_by_id if i in src.cy_by_id[t] and gl_by_id[i][gname] == src.cy_by_id[t][i][cname]]
        for glc, cyc in sorted(colmap.items()):
            if glc < n and cyc < len(cy['types']):
                m = sum(1 for i in common if gl_by_id[i][glc] == src.cy_by_id[t][i][cyc])
                agree[glc] = [cyc, round(m / max(1, len(common)), 3), g(names[glc])]
    plan['tables'][t] = {'cols': n, 'cy_cols': len(cy['types']), 'rows': len(rows), 'gl_rows': len(gl['rows']), 'cy_rows': len(cy['rows']),
                         'row_source': dict(src_counter), 'archived_gl_only_rows': arch, 'colmap_gl_from_cy': {str(k): v for k, v in sorted(colmap.items())},
                         'unmapped_gl_cols': [(k, g(names[k])) for k in range(n) if k not in colmap], 'agreement_on_same_name_rows': agree,
                         'notes': dict(notes)}
    return rows


def build_monster(src, staging, plan):
    ai_ids = set(int(m.group(1)) for m in re.finditer(rb'(?m)^(\d+)=script', open(os.path.join(R, 'configs/AIScript.dat'), 'rb').read()))
    ai_sections = set(int(x) for x in re.findall(rb'\[AI(\d+)\]', open(os.path.join(R, 'configs/MonsterAITable.ini'), 'rb').read()))
    plan['monster_ai'] = {'AIScript_ids': len(ai_ids), 'MonsterAITable_sections': sorted(ai_sections)}

    def fix(cid, row, glrow, notes):
        b = row[MONSTER_COL['base_ai']]
        if not (isint(b) and int(b) in ai_sections):
            # CY dùng AI 47–98 (bảng AI của HJ lớn hơn MonsterAITable.ini 0–34 của skynet): lấy GL cùng tên nếu hợp lệ,
            # không thì AI3 (NPC: không đánh, không đi) cho 是否可以交互=1, AI1 (không chủ động, đánh trả) cho quái [SL]
            notes['base_ai_out_of_MonsterAITable'] += 1
            if glrow and isint(glrow[MONSTER_COL['base_ai']]) and int(glrow[MONSTER_COL['base_ai']]) in ai_sections:
                row[MONSTER_COL['base_ai']] = glrow[MONSTER_COL['base_ai']]; notes['base_ai_from_gl'] += 1
            elif row[13] == b'1':
                row[MONSTER_COL['base_ai']] = b'3'; notes['base_ai_set_3_npc'] += 1
            else:
                row[MONSTER_COL['base_ai']] = b'1'; notes['base_ai_set_1'] += 1
        e = row[MONSTER_COL['ext_ai']]
        if isint(e) and int(e) >= 0 and int(e) not in ai_ids:
            notes['ext_ai_not_in_AIScript_set_-1'] += 1
            row[MONSTER_COL['ext_ai']] = b'-1'
    return convert_by_colmap(src, 'MonsterAttrExTable.txt', staging, plan, fix)


def build_shop(src, staging, plan):
    t = 'ShopTable.txt'
    gl, cy = src.gl[t], src.cy[t]
    types, names, eol = list(gl['types']), list(gl['names']), gl['eol']
    n = len(types)
    assert n == SHOP_FIXED_GL + SHOP_ITEMS * 6 and len(cy['types']) == SHOP_FIXED_CY + SHOP_ITEMS * 6, (n, len(cy['types']))
    assert names[26] == b'is_yuanbao_shop' and names[27].startswith(b'PID') and names[18].startswith('杀气折扣'.encode('gbk'))
    rows, cnt = [], collections.Counter()
    for sid, c in sorted(src.cy_by_id[t].items()):
        c = pad(c, SHOP_FIXED_CY + SHOP_ITEMS * 6)
        glrow = src.gl_by_id[t].get(sid)
        row = c[:18] + c[21:29] + [glrow[26] if glrow and isint(glrow[26]) else b'0'] + c[29:]
        assert len(row) == n
        cnt['is_yuanbao_from_gl' if glrow else 'is_yuanbao_0'] += 1
        rows.append(row)
    write_table(os.path.join(staging, 'configs', t), types, names, rows, eol)
    arch = archive_gl_only(staging, t, gl, set(src.cy_by_id[t]), eol, 'Shop GL 2026 (419–421) không có ở CY.')
    plan['tables'][t] = {'cols': n, 'cy_cols': len(cy['types']), 'rows': len(rows), 'gl_rows': len(gl['rows']), 'archived_gl_only_rows': arch,
                         'colmap': 'GL 0–17 ← CY 0–17; GL 18–25 (杀气折扣) ← CY 21–28; GL 26 is_yuanbao_shop ← GL cùng Index (không thì 0); GL 27+6j+m ← CY 29+6j+m; CY 18–20 bỏ',
                         'notes': dict(cnt)}


def build_std_impact(src, staging, plan, bridge_logic):
    """StandardImpact: HJS (ID CY) → bố cục R (81 cột: 0–75 cùng tên/vị trí, 76–80 rỗng). Dòng cầu nối cy_four: logic = 8000 + donor_logic."""
    t = 'StandardImpact.txt'
    gl, hj = src.gl[t], src.hjs[t]
    types, names, eol = list(gl['types']), list(gl['names']), gl['eol']
    n = len(types)
    assert names[:76] == hj['names'][:76], 'StandardImpact: tên cột R/HJS khác nhau'
    # dòng GL chỉ dùng thêm khi: ID được SkillData/EquipBase CY tham chiếu, không có ở HJS, và tên hiệu ứng GL trùng tên kỹ năng CY tham chiếu (gl-name)
    sd = src.now['SkillData_V1.txt']
    pairs = [(i, i + 1) for i, nm in enumerate(sd['names']) if nm == '参数说明'.encode('gbk')]
    ref_names = collections.defaultdict(set)
    for r in sd['rows']:
        for a, b in pairs:
            if a < len(r) and b < len(r) and b'\xd0\xa7\xb9\xfb' in r[a] and isint(r[b]) and int(r[b]) > 0:
                ref_names[int(r[b])].add(r[3] if len(r) > 3 else b'')      # cột 3 GL = tên kỹ năng? (GL 2 = tên) → dùng cột 2
                ref_names[int(r[b])].add(r[2])
    se_cy = set(src.cy_by_id['ImpactSEData_V1.txt'])
    rows, cnt, gl_name_rows = [], collections.Counter(), []
    ids = set()
    for cid, h in sorted(src.hjs_by_id[t].items()):
        row = pad(h, n)
        lg = int(row[2]) if isint(row[2]) else 0
        if lg in LOGIC_8000_REMAP:
            row[2] = str(LOGIC_8000_REMAP[lg]).encode()
            cnt['logic_8000_remapped'] += 1
        if cid in bridge_logic:
            row[2] = str(8000 + bridge_logic[cid]).encode()
            cnt['bridge_logic_8000'] += 1
        if cid == BORROW_ID_NEW:
            raise SystemExit('HJS đã có ID %d' % BORROW_ID_NEW)
        rows.append(row)
        ids.add(cid)
        cnt['hjs'] += 1

    def strip(nm):
        return re.split('[（(·]'.encode('gbk'), nm)[0]
    for gid, r in sorted(src.gl_by_id[t].items()):
        if gid in ids or gid not in ref_names or not isint(r[2]) or int(r[2]) >= 8000:
            continue
        gname = strip(r[1])
        if len(gname) >= 4 and any(gname and (gname in s or strip(s) in r[1]) for s in ref_names[gid] if len(strip(s)) >= 4):
            row = pad(r, n)
            if isint(row[5]) and int(row[5]) > 0 and int(row[5]) not in se_cy:
                row[5] = b'-1'
                cnt['gl-name_se_reset'] += 1
            rows.append(row)
            ids.add(gid)
            cnt['gl-name'] += 1
            gl_name_rows.append([gid, g(r[1]), int(r[2]), sorted(g(s) for s in ref_names[gid])[:3]])
    rows.sort(key=lambda r: int(r[0]))
    write_table(os.path.join(staging, 'configs', t), types, names, rows, eol)
    arch = archive_gl_only(staging, t, gl, ids, eol, 'Đánh số GL khác CY (xem đặc tả); dòng cầu nối 59909+ đã về ID CY.')
    plan['tables'][t] = {'cols': n, 'hjs_cols': len(hj['types']), 'rows': len(rows), 'gl_rows': len(gl['rows']), 'hjs_rows': len(hj['rows']),
                         'row_source': dict(cnt), 'archived_gl_only_rows': arch, 'gl_name_rows': gl_name_rows,
                         'colmap': 'HJS 0–75 → R 0–75 cùng tên (27 cột cố định + 16 bộ 参数k说明/参数值/修正步长 + 效果描述); R 76–80 rỗng'}
    return ids


def build_drop(src, staging, plan):
    for t, note in (('MonsterDropBoxs.txt', 'ID quái GL (đổi nghĩa); thay bằng tlbb15 Server (ID CY).'),
                    ('DropBoxContent.txt', 'Gói GL đánh số riêng; thay bằng tlbb15 Server.'),
                    ('DropRateOfItemTable.txt', 'thay bằng tlbb15 Server (ID vật phẩm CY).')):
        gl, hj = src.gl[t], src.hjs[t]
        types, names, eol = list(gl['types']), list(gl['names']), gl['eol']
        n = len(types)
        assert len(hj['types']) == n, (t, n, len(hj['types']))
        rows = [pad(r, n) for r in sorted(hj['rows'], key=lambda r: int(r[0]))]
        write_table(os.path.join(staging, 'configs', t), types, names, rows, eol)   # tên cột GL (HJS DropBoxContent lặp "Item16ID")
        arch = archive_gl_only(staging, t, gl, set(), eol, note)
        plan['tables'][t] = {'cols': n, 'rows': len(rows), 'gl_rows': len(gl['rows']), 'source': 'tlbb15/Server/Config, tên cột GL', 'archived_gl_only_rows': arch,
                             'hjs_dup_names_fixed': [g(x) for x, c in collections.Counter(hj['names']).items() if c > 1 and x != b'Level']}


def build_pet_collection(src, staging, plan):
    """GL 图鉴 (CY không có bảng này): dời data_id sang ID trân thú CY theo tên; không tìm được thì lưu trữ."""
    t = 'PetCollection.txt'
    gl = src.gl[t]
    pa = src.cy_by_id['PetAttrTable.txt']
    names = collections.defaultdict(list)
    for i, r in pa.items():
        names[r[1]].append(i)
    rows, cnt, dropped = [], collections.Counter(), []
    for r in gl['rows']:
        did = int(r[0])
        if did in pa and pa[did][1] == r[2]:
            rows.append(list(r)); cnt['same'] += 1
        elif len(names.get(r[2], [])) == 1:
            rows.append([str(names[r[2]][0]).encode()] + list(r[1:])); cnt['remapped_by_name'] += 1
        else:
            dropped.append(r); cnt['dropped'] += 1
    rows.sort(key=lambda r: (int(r[0]), int(r[1])))
    write_table(os.path.join(staging, 'configs', t), gl['types'], gl['types'], rows, gl['eol'])   # bảng không có tên cột (dòng 2 = kiểu)
    if dropped:
        write_table(os.path.join(staging, 'configs', 'cys_gl_only', t), gl['types'], gl['types'], dropped, gl['eol'])
    plan['tables'][t] = {'rows': len(rows), 'gl_rows': len(gl['rows']), 'notes': dict(cnt), 'archived_gl_only_rows': len(dropped)}


def build_impact_directly(src, staging, plan):
    t = 'ImpactDirectly.txt'
    hjp, cy, gl = src.hjp[t], src.cy[t], src.gl[t]
    types, names = list(hjp['types']), list(hjp['names'])
    n = len(types)
    rows = []
    for cid, c in sorted(src.cy_by_id[t].items()):
        row = [b''] * n
        for hk, ck in IMPACTDIRECTLY_HJP_FROM_CY.items():
            if ck < len(c):
                row[hk] = c[ck]
        for k in range(n):
            if row[k] == b'' and types[k] == b'INT':
                row[k] = b'0'
        rows.append(row)
    write_table(os.path.join(staging, 'configs', t), types, names, rows, gl['eol'])
    arch = archive_gl_only(staging, t, gl, set(src.cy_by_id[t]), gl['eol'], 'server không nạp bảng này.')
    plan['tables'][t] = {'cols': n, 'rows': len(rows), 'gl_rows': len(gl['rows']), 'layout': 'tlbb15 Public (tên cột thật; bản GL mang nhầm tên cột ImpactSEData)',
                         'colmap_hjp_from_cy': IMPACTDIRECTLY_HJP_FROM_CY, 'archived_gl_only_rows': arch, 'server_reads': False}


def patch_equip_impact(src, staging, plan, impact_ids):
    t = 'EquipBase.txt'
    now = src.now[t]
    cy = src.cy[t]
    cy_by = by_id(cy)
    rows, cnt = [], collections.Counter()
    n = len(now['types'])
    for r in now['rows']:
        r = pad(r, n)
        c = cy_by.get(int(r[0]))
        v = c[EQUIP_CY_IMPACT_COL] if c and len(c) > EQUIP_CY_IMPACT_COL else b'-1'
        new = v if isint(v) and int(v) > 0 and int(v) in impact_ids else b'-1'
        if isint(v) and int(v) > 0 and int(v) not in impact_ids:
            cnt['cy_impact_missing_on_server'] += 1
        cnt['changed' if new != r[EQUIP_IMPACT_COL] else 'unchanged'] += 1
        cnt['set_impact' if new != b'-1' else 'minus1'] += 1
        r[EQUIP_IMPACT_COL] = new
        rows.append(r)
    write_table(os.path.join(staging, 'configs', t), now['types'], now['names'], rows, now['eol'])
    plan['tables'][t] = {'rows': len(rows), 'col19_from': 'CY EquipBase cột 101 khi ID có trong StandardImpact mới, không thì -1', 'notes': dict(cnt)}


# ---------------------------------------------------------------- cy_four_combat: khoá theo ID CY
def lua_int_map(text, key):
    """`key={[a]=b,...}` (số nguyên) → dict a→b; tìm cả dạng ["key"]= ."""
    m = re.search(r'(?:\["%s"\]|\b%s)=\{((?:\[\d+\]=\d+,?)*)\}' % (key, key), text)
    return {int(a): int(b) for a, b in re.findall(r'\[(\d+)\]=(\d+)', m.group(1))} if m else {}


def identity_map_text(d):
    return ','.join('[%d]=%d' % (k, k) for k in sorted(d))


def rekey_table(text, key, mapping, plan_log, label):
    """Đổi khoá `[GL]=` trong bảng `key={...}` (chỉ khoá mức 1) theo mapping; khoá không có trong mapping giữ nguyên + ghi log."""
    # có thể có nhiều bảng cùng tên (resolve.impacts = map số→số, config.impacts = bảng lồng): ưu tiên bảng có lồng { }
    cands = []
    for m in re.finditer(r'((?:\["%s"\]|\b%s)=\{)' % (key, key), text):
        start = m.end()
        depth, i = 1, start
        while depth and i < len(text):
            depth += {'{': 1, '}': -1}.get(text[i], 0)
            i += 1
        cands.append((start, i, '{' in text[start:i - 1]))
    if not cands:
        return text
    start, i, _ = next((c for c in cands if c[2]), cands[0])
    body = text[start:i - 1]
    kept, changed = [], 0
    def sub(mm):
        nonlocal changed
        k = int(mm.group(1))
        if k in mapping:
            changed += 1
            return '[%d]=' % mapping[k]
        kept.append(k)
        return mm.group(0)
    body2 = _rekey_top(body, sub)
    plan_log[label] = {'changed': changed, 'kept': kept[:20], 'kept_n': len(kept)}
    return text[:start] + body2 + text[i - 1:]


def _rekey_top(body, sub):
    """chỉ thay khoá ở mức lồng 0 của body."""
    out, depth, i = [], 0, 0
    while i < len(body):
        ch = body[i]
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
        if depth == 0 and ch == '[':
            m = re.match(r'\[(\d+)\]=', body[i:])
            if m:
                out.append(sub(m))
                i += m.end()
                continue
        out.append(ch)
        i += 1
    return ''.join(out)


def convert_cy_four(src, plan):
    """native_config/phase2_config/release_config/deployment_config: mọi khoá GL → CY qua chính các map resolve trong native_config."""
    out = {}
    log = plan['cy_four'] = {}
    nc = open(os.path.join(R, CY4_DIR, 'native_config.lua'), encoding='utf-8').read()
    # map CY->GL luôn lấy từ bản GL trong git (BASE_REV): sau khi áp, file trong R đã là đồng nhất nên không còn thông tin GL
    nc_gl = git_show(src.base_rev, CY4_DIR + '/native_config.lua').decode('utf-8')
    p2_gl = git_show(src.base_rev, CY4_DIR + '/phase2_config.lua').decode('utf-8')
    rl_gl = git_show(src.base_rev, CY4_DIR + '/release_config.lua').decode('utf-8')
    maps = {k: lua_int_map(nc_gl, k) for k in ('impacts', 'skill_templates', 'skill_data', 'xinfa', 'collections', 'special_objects', 'monsters')}
    # resolve.impacts nằm sau `resolve={impacts={...`: lua_int_map bắt bảng `impacts={[9]=61032,...}` đầu tiên ở dạng số→số (bảng config.impacts có giá trị {…} nên không khớp)
    inv = {k: {v: kk for kk, v in m.items()} for k, m in maps.items()}
    log['resolve_sizes'] = {k: len(v) for k, v in maps.items()}
    # phase2/release có resolve riêng (impacts/monsters)
    p2 = open(os.path.join(R, CY4_DIR, 'phase2_config.lua'), encoding='utf-8').read()
    rl = open(os.path.join(R, CY4_DIR, 'release_config.lua'), encoding='utf-8').read()
    dp = open(os.path.join(R, CY4_DIR, 'deployment_config.lua'), encoding='utf-8').read()
    for name, txt in (('phase2', p2_gl), ('release', rl_gl)):
        for k in ('impacts', 'monsters'):
            mm = lua_int_map(txt, k)
            maps.setdefault(k, {}).update(mm)
            inv.setdefault(k, {}).update({v: kk for kk, v in mm.items()})
            log['resolve_%s_%s' % (name, k)] = len(mm)
    inv_imp, inv_st, inv_sd, inv_mon = inv['impacts'], inv['skill_templates'], inv['skill_data'], inv['monsters']
    # 1. native_config
    t = nc
    t = rekey_table(t, 'impacts', inv_imp, log, 'native.impacts')                 # config.impacts (mức 1, giá trị {donor_id=…})
    t = rekey_table(t, 'skill_instances', inv_sd, log, 'native.skill_instances')
    t = rekey_table(t, 'donor_skill_templates', inv_st, log, 'native.donor_skill_templates')
    t = rekey_table(t, 'disabled_impacts', inv_imp, log, 'native.disabled_impacts')
    t = re.sub(r'combat=(\d+)', lambda m: 'combat=%d' % inv_imp.get(int(m.group(1)), int(m.group(1))), t)
    t = re.sub(r'specific=(\d+)', lambda m: 'specific=%d' % inv_imp.get(int(m.group(1)), int(m.group(1))), t)
    for k in ('impacts', 'skill_templates', 'skill_data', 'xinfa', 'monsters'):
        m = lua_int_map(nc_gl, k)
        if m:
            t = re.sub(r'(?<=[,{\n])%s=\{(?:\[\d+\]=\d+,?)*\}' % k, lambda mm, k=k, m=m: '%s={%s}' % (k, identity_map_text(m)), t, count=1)
    if 'CS3c' not in t:
        t = t.replace('-- Generated positional config, NOT enabled.', '-- Generated positional config, NOT enabled. CS3c 14/09/2026: mọi khoá/resolve theo ID CY (StandardImpact/SkillTemplate/SkillData/XinFa/MonsterAttrEx server đã là CY; resolve = đồng nhất).', 1)
    out['native_config.lua'] = t
    # 2. phase2_config
    t = p2
    t = rekey_table(t, 'impacts', inv_imp, log, 'phase2.impacts')
    t = rekey_table(t, 'disabled_impacts', inv_imp, log, 'phase2.disabled_impacts')
    for k in ('impacts', 'monsters'):
        m = lua_int_map(p2_gl, k)
        t = re.sub(r'\["%s"\]=\{(?:\[\d+\]=\d+,?)*\}' % k, lambda mm, k=k, m=m: '["%s"]={%s}' % (k, identity_map_text(m)), t, count=1)
    if 'CS3c' not in t:
        t = '-- CS3c 14/09/2026: khoá impact/monster theo ID CY, resolve đồng nhất.\n' + t
    out['phase2_config.lua'] = t
    # 3. release_config
    t = rl
    t = rekey_table(t, 'impacts', inv_imp, log, 'release.impacts')
    t = rekey_table(t, 'tao_damage_scaling', inv_imp, log, 'release.tao_damage_scaling')
    m = lua_int_map(rl_gl, 'impacts')
    t = re.sub(r'\["impacts"\]=\{(?:\[\d+\]=\d+,?)*\}', '["impacts"]={%s}' % identity_map_text(m), t, count=1)
    out['release_config.lua'] = t if 'CS3c' in t else '-- CS3c 14/09/2026: khoá impact theo ID CY, resolve đồng nhất.\n' + t
    # 4. deployment_config: template_factions (khoá GL skill → CY; giá trị số phái GL → CY), resource_costs (SkillData GL → CY)
    t = dp
    st_now = by_id(src.now['SkillTemplate_V1.txt'])

    def f_tf(mm):
        body = mm.group(1)
        pairs = re.findall(r'\[(\d+)\]=(\d+)', body)
        out_pairs, dropped, fixed = [], [], 0
        for a, b in pairs:
            k = inv_st.get(int(a), int(a))
            r = st_now.get(k)
            v = int(r[2]) if r and isint(r[2]) else -1
            if 0 <= v <= 15:               # số phái lấy từ chính SkillTemplate CY (GL map lệch ở 桃花岛/绝情谷)
                out_pairs.append((k, v))
                if v != MENPAI_MAP.get(int(b), int(b)):
                    fixed += 1
            else:
                dropped.append([int(a), k, g(r[3]) if r else None])   # kỹ năng chung (门派 -1) hoặc không có: bỏ khỏi cổng phái
        log['deploy.template_factions'] = {'total': len(pairs), 'kept': len(out_pairs), 'faction_fixed_from_SkillTemplate': fixed, 'dropped': dropped}
        return 'c.template_factions={' + ','.join('[%d]=%d' % kv for kv in sorted(out_pairs)) + '}'
    t = re.sub(r'c\.template_factions=\{([^}]*)\}', f_tf, t)
    m = re.search(r'c\.resource_costs=\{', t)
    if m:
        start = m.end(); depth, i = 1, start
        while depth:
            depth += {'{': 1, '}': -1}.get(t[i], 0); i += 1
        body = t[start:i - 1]
        changed = [0]
        def sub(mm):
            k = int(mm.group(1))
            if k in inv_sd:
                changed[0] += 1
                return '[%d]=' % inv_sd[k]
            return mm.group(0)
        body2 = _rekey_top(body, sub)
        log['deploy.resource_costs'] = {'changed': changed[0], 'total': len(re.findall(r'\[\d+\]=\{', body))}
        t = t[:start] + body2 + t[i - 1:]
    # c.collections: danh sách ids (skill template) có 4 ID GL của 4 phái (5619/5649/5687/5723) → CY qua inverse skill_templates
    m = re.search(r'c\.collections=\{', t)
    if m:
        start = m.end(); depth, i = 1, start
        while depth:
            depth += {'{': 1, '}': -1}.get(t[i], 0); i += 1
        body = t[start:i - 1]
        n_ids = [0]
        def f_ids(mm):
            ids = [int(x) for x in re.findall(r'\d+', mm.group(1))]
            n_ids[0] += sum(1 for x in ids if x in inv_st)
            return '["ids"]={' + ','.join(str(inv_st.get(x, x)) for x in ids) + '}'
        body2 = re.sub(r'\["ids"\]=\{([^}]*)\}', f_ids, body)
        log['deploy.collections_ids_rekeyed'] = n_ids[0]
        t = t[:start] + body2 + t[i - 1:]
    if 'CS3c' not in t:
        t = t.replace('-- Base-four-faction release; donor talents remain disabled.',
                      '-- Base-four-faction release; donor talents remain disabled.\n-- CS3c 14/09/2026: template_factions/resource_costs theo ID CY (skill/SkillData) và số phái CY.', 1)
    out['deployment_config.lua'] = t
    # 5. jue_skill_config: khoá = donor_data_id (SkillData CY), target_template_id = donor_template_id, p4/p5 impact CY (jue_hooks.readiness đòi đúng namespace CY)
    js = open(os.path.join(R, CY4_DIR, 'jue_skill_config.lua'), encoding='utf-8').read()
    n_rows = [0]
    def f_jue(mm):
        d = dict((k, int(v)) for k, v in re.findall(r'(\w+)=(-?\d+)', mm.group(2)))
        n_rows[0] += 1
        return '[%d]={donor_data_id=%d,donor_template_id=%d,target_template_id=%d,donor_logic=%d,p4=%d,p5=%d}' % (
            d['donor_data_id'], d['donor_data_id'], d['donor_template_id'], d['donor_template_id'], d['donor_logic'],
            inv_imp.get(d['p4'], d['p4']), inv_imp.get(d['p5'], d['p5']))
    js2 = re.sub(r'\[(\d+)\]=\{([^}]*)\}', f_jue, js)
    if 'CS3c' not in js2:
        js2 = js2.replace('-- Generated exact SkillData post-cast descriptors; gameplay flag is external.',
                          '-- Generated exact SkillData post-cast descriptors; gameplay flag is external.\n-- CS3c 14/09/2026: khoá/target/p4/p5 theo ID CY (SkillData/SkillTemplate/StandardImpact server đã là CY).', 1)
    log['jue_skill_config_rows'] = n_rows[0]
    out['jue_skill_config.lua'] = js2
    # logic cầu nối cho StandardImpact: CY impact id → donor_logic (từ config.impacts đã rekey, native + phase2 + release)
    bridge = {}
    for name in ('native_config.lua', 'phase2_config.lua', 'release_config.lua'):
        for m in re.finditer(r'\[(\d+)\]=\{(?:\["donor_id"\]|donor_id)=(\d+),(?:\["donor_logic"\]|donor_logic)=(\d+)', out[name]):
            k, d, lg = int(m.group(1)), int(m.group(2)), int(m.group(3))
            if k != d:
                log.setdefault('key_ne_donor', []).append([name, k, d])
            bridge[k] = lg
    log['bridge_rows'] = len(bridge)
    log['bridge_logic_counts'] = dict(collections.Counter(bridge.values()))
    return out, bridge


# ---------------------------------------------------------------- Lua: hằng impact GL → CY theo tên
def lua_impact_consts(src, plan):
    hj = src.hjs_by_id['StandardImpact.txt']
    gl = src.gl_by_id['StandardImpact.txt']
    names = collections.defaultdict(list)
    for i, r in hj.items():
        names[r[1]].append(i)
    edits, log = [], []
    for rel, pat, old in LUA_IMPACT_CONSTS:
        gname = gl[old][1] if old in gl else None
        cands = names.get(gname, []) if gname else []
        new = cands[0] if len(cands) == 1 else (old if old in hj and hj[old][1] == gname else None)
        log.append({'file': rel, 'gl_id': old, 'gl_name': g(gname) if gname else None, 'cy_candidates': cands[:5], 'cy_id': new})
        if new is not None and new != old:
            edits.append((rel, [(pat % old, (pat % new) + ' -- CS3c: ID CY (%s)' % g(gname) if pat.startswith('M.') or pat.startswith('local') else pat % new, 1)]))
    # 借力状态 19001 (GL tự chế) → 69001 vì HJS 19001 = 高级血爆
    edits.append(('GameServer/lualib/cfghelper.lua', [('transferd[%d]' % BORROW_ID_OLD, 'transferd[%d]' % BORROW_ID_NEW, 2), ('new_table[%d]' % BORROW_ID_OLD, 'new_table[%d]' % BORROW_ID_NEW, 2),
                                                      ('            id = %d,' % BORROW_ID_OLD, '            id = %d, -- CS3c: dời khỏi 19001 (HJS = 高级血爆)' % BORROW_ID_NEW, 2),
                                                      ('            mutex_id = %d,' % BORROW_ID_OLD, '            mutex_id = %d,' % BORROW_ID_NEW, 2),
                                                      ('            impact_id = %d,' % BORROW_ID_OLD, '            impact_id = %d,' % BORROW_ID_NEW, 2),
                                                      ('imp.params["借力效果ID"] = %d' % BORROW_ID_OLD, 'imp.params["借力效果ID"] = %d' % BORROW_ID_NEW, 2)]))
    edits.append(('GameServer/services/scene/skill/talent_logic/std_talent_953.lua', [('local BORROW_IMPACT_ID = %d' % BORROW_ID_OLD, 'local BORROW_IMPACT_ID = %d -- CS3c: dời khỏi 19001' % BORROW_ID_NEW, 1)]))
    plan['lua_impact_consts'] = log
    return edits


def apply_exact(rel, pairs, plan):
    path = os.path.join(R, rel)
    text = open(path, 'rb').read().decode('utf-8', 'surrogateescape')
    status = []
    for old, new, n in pairs:
        c = text.count(old)
        if c == n:
            text = text.replace(old, new); status.append('applied:%d' % n)
        elif c == 0 and text.count(new) >= 1:
            status.append('already')
        else:
            raise SystemExit('%s: expected %d of %r, found %d' % (rel, n, old[:70], c))
    plan['lua'].append({'file': rel, 'status': status})
    return text.encode('utf-8', 'surrogateescape')


# ---------------------------------------------------------------- cảnh 2: type quái theo tên CY
def scene2_retype(src, staging, plan):
    """dali_new_320_monster.ini: type GL đổi nghĩa ở CY → ID quái CY cùng tên (duy nhất); ID không có ở CY → tắt (pos_x=;…). Ghi map JSON,
    file ini do Tools/server/cs3a_scene.py retype sinh."""
    ma_cy = src.cy_by_id['MonsterAttrExTable.txt']
    ma_gl = src.gl_by_id['MonsterAttrExTable.txt']
    names = collections.defaultdict(list)
    for i, r in ma_cy.items():
        names[r[1]].append(i)
    ini = open(os.path.join(R, 'Game_2/Scene/dali_new_320_monster.ini'), 'rb').read().decode('gbk')
    retype, disable, keep_diff, cnt = {}, [], [], collections.Counter()
    for sec in re.findall(r'\[(monster\d+)\]\n(.*?)(?=\n\[|\Z)', ini, re.S):
        body = sec[1]
        m_t = re.search(r'^type=(\d+)', body, re.M)
        m_n = re.search(r'^name=(.*)$', body, re.M)
        if not m_t or re.search(r'^pos_x=;', body, re.M):
            cnt['skipped'] += 1
            continue
        tid, nm = int(m_t.group(1)), (m_n.group(1).strip() if m_n else '')
        if tid in ma_cy and (g(ma_cy[tid][1]) == nm or (tid in ma_gl and ma_gl[tid][1] == ma_cy[tid][1])):
            cnt['same'] += 1
            continue
        glrow = ma_gl.get(tid)
        glname = g(glrow[1]) if glrow else ''
        # ứng viên CY theo tên trong ini rồi tên GL (ini có thể ghi tên tuỳ biến); chọn: cùng 外型ID → cùng cờ NPC + cấp gần nhất → ID nhỏ nhất
        cand = []
        for key in (nm, glname):
            if key and names.get(key.encode('gbk')):
                cand = names[key.encode('gbk')]
                break
        if cand and glrow:
            def score(c):
                r = ma_cy[c]
                return (0 if r[36] == glrow[44] else 1, 0 if r[5] == glrow[13] else 1, abs(int(r[3]) - int(glrow[3])) if isint(r[3]) and isint(glrow[3]) else 999, c)
            best = min(cand, key=score)
            retype[sec[0]] = [tid, best, nm, 'ứng viên %d, chọn theo %s' % (len(cand), 'model' if ma_cy[best][36] == glrow[44] else 'NPC+cấp')]
            cnt['retyped'] += 1
        elif not glname:
            disable.append([sec[0], tid, nm, 'dòng GL không tên (tượng/đối tượng riêng GL) → CY %s' % (g(ma_cy[tid][1]) if tid in ma_cy else 'không có')]); cnt['disabled_gl_placeholder'] += 1
        elif tid not in ma_cy:
            disable.append([sec[0], tid, nm, 'ID không có ở CY']); cnt['disabled_missing_in_cy'] += 1
        else:
            disable.append([sec[0], tid, nm, 'NPC chỉ-GL (%s), CY không có tên này; ID CY = %s' % (glname, g(ma_cy[tid][1]))]); cnt['disabled_gl_only_npc'] += 1
    spec = {'retype': retype, 'disable': [d[0] for d in disable], 'why': 'CS3c: MonsterAttrExTable server = CY → type GL đổi nghĩa; retype theo tên, tắt NPC/đối tượng chỉ-GL'}
    os.makedirs(os.path.join(staging, 'scene'), exist_ok=True)
    spec_path = os.path.join(staging, 'scene', 'dali_new_320_retype.json')
    json.dump(spec, open(spec_path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    out = os.path.join(staging, 'scene', 'dali_new_320_monster.ini')
    r = subprocess.run(['python3', '-B', os.path.join(HERE, 'cs3a_scene.py'), 'retype', '--city', 'dali', '--map', spec_path, '--out', out], capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit('cs3a_scene.py retype: ' + r.stderr[-800:])
    plan['scene2'] = {'counts': dict(cnt), 'retype': retype, 'disable': disable, 'kept_diff_name': keep_diff, 'cs3a_retype': r.stdout.strip()[:400]}
    return out


# ---------------------------------------------------------------- plan / apply / verify
def cmd_plan(args):
    staging = args.out
    os.makedirs(os.path.join(staging, 'configs', 'cys_gl_only'), exist_ok=True)
    src = Sources(args.base_rev)
    plan = {'created': datetime.datetime.utcnow().isoformat() + 'Z', 'base_rev': args.base_rev, 'tables': {}, 'lua': []}
    cy4, bridge = convert_cy_four(src, plan)
    impact_ids = build_std_impact(src, staging, plan, bridge)
    for t in ('ImpactSEData_V1.txt', 'Bullet.txt', 'PetAttrTable.txt', 'CommonItem.txt', 'PetHuanhuaTable.txt', 'PetSkillBook.txt'):
        convert_by_colmap(src, t, staging, plan)
    build_monster(src, staging, plan)
    build_shop(src, staging, plan)
    build_impact_directly(src, staging, plan)
    build_drop(src, staging, plan)
    build_pet_collection(src, staging, plan)
    patch_equip_impact(src, staging, plan, impact_ids)
    # Lua
    lua_dir = os.path.join(staging, 'lua')
    for name, text in cy4.items():
        p = os.path.join(lua_dir, CY4_DIR, name)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, 'w', encoding='utf-8', newline='\n').write(text)
        plan['lua'].append({'file': CY4_DIR + '/' + name, 'status': ['render'], 'changed': text != open(os.path.join(R, CY4_DIR, name), encoding='utf-8').read()})
    for rel, pairs in lua_impact_consts(src, plan):
        data = apply_exact(rel, pairs, plan)
        p = os.path.join(lua_dir, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, 'wb').write(data)
    scene2_retype(src, staging, plan)
    plan['bridge_logic_by_cy_impact'] = {str(k): v for k, v in sorted(bridge.items())}
    with open(os.path.join(staging, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1, default=str)
    brief = {t: {k: v for k, v in d.items() if k in ('cols', 'rows', 'gl_rows', 'cy_rows', 'hjs_rows', 'row_source', 'archived_gl_only_rows', 'notes')} for t, d in plan['tables'].items()}
    print(json.dumps({'tables': brief, 'cy_four': plan['cy_four'], 'lua': plan['lua'], 'scene2': plan['scene2']['counts'], 'lua_impact_consts': plan['lua_impact_consts']}, ensure_ascii=False, indent=1, default=str))


def staged_files(staging):
    out = []
    for sub, prefix in (('configs', 'configs/'), ('lua', ''), ('scene', 'Game_2/Scene/')):
        base = os.path.join(staging, sub)
        for dp, dn, fn in os.walk(base):
            for f in fn:
                if sub == 'scene' and not f.endswith('.ini'):
                    continue
                p = os.path.join(dp, f)
                out.append((p, prefix + os.path.relpath(p, base).replace('\\', '/')))
    return sorted(out, key=lambda x: x[1])


def cmd_apply(args):
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'cs3c-' + stamp)
    changed, same = [], []
    for src_path, rel in staged_files(args.staging):
        dst = os.path.join(R, rel)
        new = open(src_path, 'rb').read()
        old = open(dst, 'rb').read() if os.path.exists(dst) else None
        if old == new:
            same.append(rel); continue
        changed.append(rel)
        if args.dry_run:
            continue
        if old is not None:
            bp = os.path.join(bdir, rel)
            os.makedirs(os.path.dirname(bp), exist_ok=True)
            open(bp, 'wb').write(old)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'wb').write(new)
    print(json.dumps({'dry_run': args.dry_run, 'changed': changed, 'unchanged': len(same), 'backup_dir': bdir if changed and not args.dry_run else None}, ensure_ascii=False, indent=1))


def cmd_verify(args):
    rep = {'ok': True, 'errors': [], 'tables': {}, 'xref': {}, 'lua': {}}
    err = rep['errors'].append
    T = {}
    for t in CONV_TABLES + ['EquipBase.txt', 'SkillData_V1.txt', 'SkillTemplate_V1.txt']:
        data = open(os.path.join(R, 'configs', t), 'rb').read()
        try:
            data.decode('gbk')
        except UnicodeDecodeError as ex:
            err('%s: not GBK: %s' % (t, ex))
        tb = read_table_bytes(data)
        n = len(tb['types'])
        bad = [r[0] for r in tb['rows'] if len(r) != n]
        ids = [int(r[0]) for r in tb['rows']]
        rep['tables'][t] = {'cols': n, 'rows': len(tb['rows']), 'bad_tab_rows': len(bad), 'dup_ids': len(ids) - len(set(ids)), 'sorted': ids == sorted(ids), 'sha256': hashlib.sha256(data).hexdigest()[:16]}
        if bad or (len(ids) != len(set(ids)) and t != 'PetCollection.txt'):
            err('%s: bad rows %d dup %d' % (t, len(bad), len(ids) - len(set(ids))))
        tb['by_id'] = by_id(tb)
        T[t] = tb
    X = rep['xref']
    si, se, sd, st = T['StandardImpact.txt'], T['ImpactSEData_V1.txt'], T['SkillData_V1.txt'], T['SkillTemplate_V1.txt']
    ma, pa, ci, eb, sh = T['MonsterAttrExTable.txt'], T['PetAttrTable.txt'], T['CommonItem.txt'], T['EquipBase.txt'], T['ShopTable.txt']
    # SkillData → StandardImpact
    pairs = [(i, i + 1) for i, nm in enumerate(sd['names']) if nm == '参数说明'.encode('gbk')]
    refs = collections.Counter()
    for r in sd['rows']:
        for a, b in pairs:
            if a < len(r) and b < len(r) and b'\xd0\xa7\xb9\xfb' in r[a] and isint(r[b]) and int(r[b]) > 0:
                refs[int(r[b])] += 1
    X['skilldata_impact_refs'] = {'refs': sum(refs.values()), 'distinct': len(refs), 'distinct_found': sum(1 for k in refs if k in si['by_id']), 'refs_found': sum(v for k, v in refs.items() if k in si['by_id'])}
    # StandardImpact logic: mọi logic ≥ 8000 phải là logic cầu nối (8000+donor_logic có trong config) ; SE → ImpactSEData
    logics = collections.Counter(int(r[2]) for r in si['rows'] if isint(r[2]))
    files = set(int(m.group(1)) for m in (re.match(r'std_impact_(\d+)\.lua', f) for f in os.listdir(os.path.join(R, 'GameServer/services/scene/skill/impact_logic'))) if m)
    cfg = open(os.path.join(R, CY4_DIR, 'native_config.lua'), encoding='utf-8').read() + open(os.path.join(R, CY4_DIR, 'phase2_config.lua'), encoding='utf-8').read() + open(os.path.join(R, CY4_DIR, 'release_config.lua'), encoding='utf-8').read()
    bridge = {int(a): int(b) for a, b in re.findall(r'\[(\d+)\]=\{(?:\["donor_id"\]|donor_id)=\d+,(?:\["donor_logic"\]|donor_logic)=(\d+)', cfg)}
    bridge_logics = set(8000 + v for v in bridge.values())
    bad8 = sorted(k for k in logics if k >= 8000 and k not in bridge_logics)
    X['impact_logic'] = {'distinct': len(logics), 'without_file_lt8000': sorted(k for k in logics if k < 8000 and k not in files), 'rows_without_file': sum(v for k, v in logics.items() if k < 8000 and k not in files),
                         'ge8000_not_bridge': bad8, 'bridge_rows_expected': len(bridge), 'bridge_rows_with_8000_logic': sum(1 for k, v in bridge.items() if k in si['by_id'] and isint(si['by_id'][k][2]) and int(si['by_id'][k][2]) == 8000 + v),
                         'bridge_rows_missing_in_table': sorted(k for k in bridge if k not in si['by_id'])[:20]}
    if bad8:
        err('StandardImpact logic ≥ 8000 không phải cầu nối: %s' % bad8[:10])
    if X['impact_logic']['bridge_rows_with_8000_logic'] != len(bridge):
        err('dòng cầu nối chưa mang logic 8000+: %d/%d' % (X['impact_logic']['bridge_rows_with_8000_logic'], len(bridge)))
    se_refs = collections.Counter(int(r[5]) for r in si['rows'] if isint(r[5]) and int(r[5]) > 0)
    X['impact_se_refs'] = {'refs': sum(se_refs.values()), 'found': sum(v for k, v in se_refs.items() if k in se['by_id'])}
    if BORROW_ID_OLD in si['by_id'] and BORROW_ID_NEW in si['by_id']:
        err('69001 đã tồn tại trong bảng')
    # EquipBase cột 19 → StandardImpact
    eq = [int(r[EQUIP_IMPACT_COL]) for r in eb['rows'] if isint(r[EQUIP_IMPACT_COL]) and int(r[EQUIP_IMPACT_COL]) > 0]
    X['equip_impact'] = {'refs': len(eq), 'found': sum(1 for k in eq if k in si['by_id'])}
    if X['equip_impact']['refs'] != X['equip_impact']['found']:
        err('EquipBase cột 19 trỏ impact không có')
    # Pet ↔ Monster ; Pet skills → SkillTemplate ; SkillTemplate 子弹 → Bullet
    X['pet_in_monster'] = {'pets': len(pa['by_id']), 'found': sum(1 for k in pa['by_id'] if k in ma['by_id'])}
    if X['pet_in_monster']['pets'] != X['pet_in_monster']['found']:
        err('PetAttr id không có trong MonsterAttrEx: %s' % sorted(k for k in pa['by_id'] if k not in ma['by_id'])[:10])
    ps = [int(r[k]) for r in pa['rows'] for k in (9, 11, 13, 15, 17, 19, 21) if isint(r[k]) and int(r[k]) > 0]
    X['pet_skills'] = {'refs': len(ps), 'found': sum(1 for k in ps if k in st['by_id'])}
    bl = [int(r[35]) for r in st['rows'] if len(r) > 35 and isint(r[35]) and int(r[35]) > 0]
    X['skill_bullet'] = {'refs': len(bl), 'found': sum(1 for k in bl if k in T['Bullet.txt']['by_id'])}
    # Monster AI
    ai_ids = set(int(m.group(1)) for m in re.finditer(rb'(?m)^(\d+)=script', open(os.path.join(R, 'configs/AIScript.dat'), 'rb').read()))
    ai_secs = set(int(x) for x in re.findall(rb'\[AI(\d+)\]', open(os.path.join(R, 'configs/MonsterAITable.ini'), 'rb').read()))
    X['monster_ai'] = {'base_ai_bad': sum(1 for r in ma['rows'] if not (isint(r[7]) and int(r[7]) in ai_secs)), 'ext_ai_bad': sum(1 for r in ma['rows'] if isint(r[8]) and int(r[8]) >= 0 and int(r[8]) not in ai_ids)}
    if X['monster_ai']['base_ai_bad'] or X['monster_ai']['ext_ai_bad']:
        err('MonsterAttrEx AI ngoài bảng: %s' % X['monster_ai'])
    # Shop → item tables (CommonItem/EquipBase/GemInfo/PetEquipBase)
    items = set(ci['by_id']) | set(eb['by_id'])
    for t in ('GemInfo.txt', 'PetEquipBase.txt'):
        items |= set(by_id(read_table(os.path.join(R, 'configs', t))))
    pid_cols = [i for i, nm in enumerate(sh['names']) if nm.startswith(b'PID')]
    sr = [int(r[c]) for r in sh['rows'] for c in pid_cols if c < len(r) and isint(r[c]) and int(r[c]) > 0]
    X['shop_items'] = {'pid_cols': len(pid_cols), 'refs': len(sr), 'found': sum(1 for k in sr if k in items), 'missing_examples': sorted(set(k for k in sr if k not in items))[:10]}
    # Drop
    md, dc, dr = T['MonsterDropBoxs.txt'], T['DropBoxContent.txt'], T['DropRateOfItemTable.txt']
    dids = [int(r[c]) for r in md['rows'] for c in range(3, len(r)) if isint(r[c]) and int(r[c]) > 0]
    X['drop'] = {'monsters': len(md['by_id']), 'monsters_in_MonsterAttrEx': sum(1 for k in md['by_id'] if k in ma['by_id']), 'dids': len(dids), 'dids_found': sum(1 for k in dids if k in dc['by_id']),
                 'box_items': sum(1 for r in dc['rows'] for c in range(4, len(r), 2) if isint(r[c]) and int(r[c]) > 0),
                 'box_items_found': sum(1 for r in dc['rows'] for c in range(4, len(r), 2) if isint(r[c]) and int(r[c]) > 0 and int(r[c]) in items),
                 'droprate_items_found': sum(1 for k in dr['by_id'] if k in items), 'droprate_rows': len(dr['by_id']),
                 'dropboxcontent_dup_names': [g(x) for x, c in collections.Counter(dc['names']).items() if c > 1 and x != b'Level']}
    if X['drop']['dids'] != X['drop']['dids_found'] or X['drop']['dropboxcontent_dup_names']:
        err('drop: DID thiếu hoặc tên cột lặp')
    # PetCollection / PetHuanhua / PetSkillBook
    pc = T['PetCollection.txt']
    X['pet_collection'] = {'rows': len(pc['rows']), 'in_PetAttr': sum(1 for r in pc['rows'] if int(r[0]) in pa['by_id']), 'name_eq': sum(1 for r in pc['rows'] if int(r[0]) in pa['by_id'] and pa['by_id'][int(r[0])][1] == r[2])}
    ph = T['PetHuanhuaTable.txt']
    X['pet_huanhua'] = {'rows': len(ph['rows']), 'model_in_PetAttr': sum(1 for r in ph['rows'] if int(r[0]) in pa['by_id'])}
    pb = T['PetSkillBook.txt']
    X['pet_skill_book'] = {'rows': len(pb['rows']), 'items_found': sum(1 for r in pb['rows'] if int(r[0]) in items), 'skills_found': sum(1 for r in pb['rows'] if isint(r[1]) and int(r[1]) in st['by_id'])}
    # cảnh 2
    ini = open(os.path.join(R, 'Game_2/Scene/dali_new_320_monster.ini'), 'rb').read().decode('gbk')
    types = [int(x) for x in re.findall(r'(?m)^type=(\d+)', ini)]
    act = re.findall(r'\[monster\d+\]\n(.*?)(?=\n\[|\Z)', ini, re.S)
    active = [int(re.search(r'^type=(\d+)', b, re.M).group(1)) for b in act if re.search(r'^type=(\d+)', b, re.M) and not re.search(r'^pos_x=;', b, re.M)]
    X['scene2'] = {'sections': len(types), 'active': len(active), 'active_in_MonsterAttrEx': sum(1 for t in active if t in ma['by_id'])}
    if X['scene2']['active'] != X['scene2']['active_in_MonsterAttrEx']:
        err('cảnh 2: quái active không có trong MonsterAttrEx: %s' % sorted(set(t for t in active if t not in ma['by_id']))[:10])
    # mọi cảnh: chỉ báo cáo
    allt = collections.Counter()
    for f in os.listdir(os.path.join(R, 'Game_2/Scene')):
        if f.endswith('_monster.ini'):
            for x in re.findall(rb'(?m)^type=(\d+)', open(os.path.join(R, 'Game_2/Scene', f), 'rb').read()):
                allt[int(x)] += 1
    X['all_scenes'] = {'distinct_types': len(allt), 'in_MonsterAttrEx': sum(1 for k in allt if k in ma['by_id'])}
    # Lua: luac -p + nạp thử config cy_four bằng lua5.4 (không cần skynet)
    lua_files = [CY4_DIR + '/' + f for f in ('native_config.lua', 'phase2_config.lua', 'release_config.lua', 'deployment_config.lua', 'jue_skill_config.lua')] + [e[0] for e in LUA_IMPACT_CONSTS] + \
        ['GameServer/lualib/cfghelper.lua', 'GameServer/services/scene/skill/talent_logic/std_talent_953.lua']
    if args.staging:
        lua_files += [rel for _, rel in staged_files(args.staging) if rel.endswith('.lua')]
    bad = []
    for rel in sorted(set(lua_files)):
        r = subprocess.run(['luac5.4', '-p', os.path.join(R, rel)], capture_output=True, text=True)
        if r.returncode != 0:
            bad.append((rel, r.stderr.strip()[:200]))
    rep['lua']['luac_checked'] = len(set(lua_files)); rep['lua']['luac_failed'] = bad
    if bad:
        err('luac: %s' % bad)
    lua_check = r'''
package.path="%s/GameServer/lualib/?.lua;"..package.path
local c=require "cy_four_combat.deployment_config"
local n_imp,n_id=0,0
for k,row in pairs(c.impacts) do n_imp=n_imp+1; if k==row.donor_id then n_id=n_id+1 end end
local r_id=0; local r_n=0
for k,v in pairs(c.resolve.impacts) do r_n=r_n+1; if k==v then r_id=r_id+1 end end
local tf=0; local tf_cy=0
for k,v in pairs(c.template_factions) do tf=tf+1; if k<5000 and v>=11 and v<=14 then tf_cy=tf_cy+1 end end
local p2=require "cy_four_combat.phase2_config"
local jue=require "cy_four_combat.jue_hooks"
local jcfg={resolve=c.resolve, jue_skill_instances=require "cy_four_combat.jue_skill_config"}
local stub=setmetatable({},{__index=function() return function() end end})
local jok,jmiss=jue.readiness(jcfg,stub)
print(string.format('{"impacts":%%d,"impacts_key_eq_donor":%%d,"resolve_impacts":%%d,"resolve_identity":%%d,"template_factions":%%d,"template_factions_cy":%%d,"p2_impacts_key_eq_donor":%%s,"jue_ready":%%s,"jue_missing":%%d,"jue_missing_head":"%%s"}',
  n_imp,n_id,r_n,r_id,tf,tf_cy,tostring((function() local ok=true for k,row in pairs(p2.impacts) do if k~=row.donor_id then ok=false end end return ok end)()),tostring(jok),#jmiss,table.concat({jmiss[1] or "",jmiss[2] or "",jmiss[3] or ""},"; ")))
''' % R
    r = subprocess.run(['lua5.4', '-e', lua_check], capture_output=True, text=True)
    try:
        rep['lua']['cy_four_load'] = json.loads(r.stdout.strip())
        cl = rep['lua']['cy_four_load']
        if cl['impacts'] != cl['impacts_key_eq_donor'] or cl['resolve_impacts'] != cl['resolve_identity'] or not cl.get('jue_ready'):
            err('cy_four config chưa theo ID CY / jue_hooks chưa sẵn sàng: %s' % cl)
    except Exception:
        rep['lua']['cy_four_load'] = {'error': (r.stderr or r.stdout)[-400:]}
        err('cy_four config không nạp được bằng lua5.4')
    # template_factions: khoá phải là skill CY đúng phái
    tf = {int(a): int(b) for a, b in re.findall(r'\[(\d+)\]=(\d+)', re.search(r'c\.template_factions=\{([^}]*)\}', open(os.path.join(R, CY4_DIR, 'deployment_config.lua'), encoding='utf-8').read()).group(1))}
    X['template_factions'] = {'n': len(tf), 'skill_exists_same_menpai': sum(1 for k, v in tf.items() if k in st['by_id'] and isint(st['by_id'][k][2]) and int(st['by_id'][k][2]) == v)}
    if X['template_factions']['n'] != X['template_factions']['skill_exists_same_menpai']:
        err('template_factions: skill/phái không khớp SkillTemplate')
    if args.staging:
        drift = [rel for p, rel in staged_files(args.staging) if not os.path.exists(os.path.join(R, rel)) or sha(os.path.join(R, rel)) != sha(p)]
        rep['staging_drift'] = drift
        if drift:
            err('staging differs from R: %s' % drift)
    rep['ok'] = not rep['errors']
    if args.out:
        json.dump(rep, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps(rep, ensure_ascii=False, indent=1))
    sys.exit(0 if rep['ok'] else 1)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('plan'); a.add_argument('--out', required=True); a.add_argument('--base-rev', default=BASE_REV)
    a = sub.add_parser('apply'); a.add_argument('--staging', required=True); a.add_argument('--dry-run', action='store_true')
    a = sub.add_parser('verify'); a.add_argument('--staging'); a.add_argument('--out')
    args = ap.parse_args()
    {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify}[args.cmd](args)


if __name__ == '__main__':
    main()
