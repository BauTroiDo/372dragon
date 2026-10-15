#!/usr/bin/env python3
"""CS3b/CS3c(đầu) — môn phái theo CY + XinFa/SkillTemplate/SkillData/EquipBase theo ID CY cho SERVER RIÊNG.

Chạy trong WSL TLBB bằng root (python3 -B). Chỉ ghi vào R=/home/ubuntu/cys-test-20260913 (sau backup); nguồn CY/tlbb15 và
Registry chỉ đọc. Bảng server giữ GBK ở mức byte. Đặc tả: Docs/specs/server/cs3b-menpai_vi.md.

  cs3b_menpai.py plan   --out <dir>                    tính ánh xạ + dựng bảng/Lua vào <dir> (không chạm R); ghi plan.json
  cs3b_menpai.py apply  --staging <dir> [--dry-run]    chép staging vào R (sao lưu từng file vào R/backups/cs3b-<UTC>/), idempotent
  cs3b_menpai.py verify [--staging <dir>] [--out json] kiểm R: GBK, số tab, ID, luac -p, tham chiếu ID trong define/extensions
  cs3b_menpai.py mongo-inspect --out <json>            chỉ đọc bản ghi test (GUID 200001)
  cs3b_menpai.py mongo-apply --staging <dir> --out <json>   dời menpai/xinfa/skill của bản ghi test theo plan (có sao lưu)

Số phái GL/server → CY (bằng chứng: tên tâm pháp XinFa_V1, Build/Logs/2026-09-14-cs3b-menpai/scripts/02-xinfa-compare.out.txt):
  0..8 giữ; 9 = không phái; 10 曼陀山庄 → 16 (CY không có: giữ ở ô 16, TẮT); 11 恶人谷 → 15; 12 慕容 → 10;
  13 唐门 → 11; 14 鬼谷 → 12; 15 桃花岛 → 13; 16 绝情谷 → 14.
"""
import argparse
import collections
import datetime
import hashlib
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
R = '/home/ubuntu/cys-test-20260913'
CY_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
HJ_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/tlbb15/Public/Config'
REGISTRY = os.path.join(ROOT, 'Registry', 'abi', 'dbc_columns_cy.tsv')
BASE_REV = '995c2df'
GUID = 200001

MENPAI_MAP = {0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9, 10: 16, 11: 15, 12: 10, 13: 11, 14: 12, 15: 13, 16: 14}
MENPAI_CY_NAME = {0: '少林', 1: '明教', 2: '丐帮', 3: '武当', 4: '峨嵋', 5: '星宿', 6: '大理', 7: '天山', 8: '逍遥', 9: '无门派',
                  10: '慕容', 11: '唐门', 12: '鬼谷', 13: '桃花岛', 14: '绝情谷', 15: '恶人谷', 16: '曼陀(tắt)'}
LEGACY_CY = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 15, 16]      # phái có mã Lua riêng (không qua menpai_extensions)
RESERVED = {'SkillTemplate_V1.txt': 50000, 'SkillData_V1.txt': 50000, 'XinFa_V1.txt': 1000, 'EquipBase.txt': 9000000}
TABLES = ['XinFa_V1.txt', 'SkillTemplate_V1.txt', 'SkillData_V1.txt', 'EquipBase.txt', 'XinFaStudySpend_V1.txt']
NAME_COL = {'XinFa_V1.txt': (2, 2), 'SkillTemplate_V1.txt': (3, 2), 'SkillData_V1.txt': (2, 4), 'EquipBase.txt': (10, 10)}  # (gl, cy)
MENPAI_COL = {'XinFa_V1.txt': (1, 1), 'SkillTemplate_V1.txt': (2, 1), 'EquipBase.txt': (12, 12)}
# Ánh xạ cột CY→GL thêm vào registry (bằng chứng: 10-survey-lua4.out.txt — phân bố giá trị / khớp theo vị trí)
MANUAL_MAP = {
    'SkillData_V1.txt': {1: 3, 2: 4, 3: 1, 4: 2, **{24 + k: 24 + k for k in range(30)}},   # cặp tham số theo vị trí (97 %+)
    # EquipBase: 22-diag — GL k ← CY k-1 cho k = 25..34 (khớp 14.254–14.262/14.262 dòng cùng tên); CY 22, 23 là cột thêm;
    # CY 100/101/102 = 镶嵌上限 / impact / script (phân bố giá trị trùng GL 18/19/20); CY 17 = 修理失败上限 (hằng 3)
    'EquipBase.txt': {17: 17, 20: 23, 21: 24, **{k: k + 1 for k in range(24, 34)}, 100: 18, 101: 19, 102: 20},
    # SkillTemplate: 22-diag — cột GL chưa ánh xạ khớp ≥ 0.94 với cột CY trên dòng cùng tên có giá trị khác 0
    'SkillTemplate_V1.txt': {16: 20, 89: 1, 90: 13, 91: 14, 95: 45, 96: 46, 97: 48, 98: 53, 79: 74, 99: 77, 100: 78, 101: 81},
}
MANUAL_DROP = {'EquipBase.txt': [22, 23]}      # registry ghi CY 23 → GL 25, dữ liệu cùng tên bác bỏ (GL 25 ← CY 24)
SKILLDATA_EXTRA_PAIRS = 3    # server 12 cặp → 15 cặp như CY (txtreader gộp cột trùng tên thành mảng)
EQUIP_IMPACT_COL, EQUIP_SCRIPT_COL = 19, 20


# ---------------------------------------------------------------- đọc/ghi bảng ở mức byte
def read_table_bytes(data):
    lines = data.split(b'\n')
    eol = b'\r\n' if lines and lines[0].endswith(b'\r') else b'\n'
    lines = [l.rstrip(b'\r') for l in lines]
    if lines and lines[-1] == b'':
        lines.pop()
    types = lines[0].split(b'\t')
    row2 = lines[1].split(b'\t')
    names = None if row2[:1] == types[:1] and all(x in (b'INT', b'FLOAT', b'STRING', b'') for x in row2) else row2
    rows = []
    for l in lines[2:]:
        if not l.strip():
            continue
        c = l.split(b'\t')
        try:
            int(c[0])
        except ValueError:
            continue
        if len(c) < len(types):            # dòng ngắn: txtreader cũng đệm chuỗi rỗng
            c += [b''] * (len(types) - len(c))
        rows.append(c)
    return {'types': types, 'names': names, 'rows': rows, 'eol': eol}


def read_table(path):
    with open(path, 'rb') as f:
        return read_table_bytes(f.read())


def git_show(rev, rel):
    return subprocess.run(['git', '-C', R, 'show', '%s:%s' % (rev, rel)], capture_output=True, check=True).stdout


def write_table(path, types, names, rows, eol):
    n = len(types)
    out = [b'\t'.join(types), b'\t'.join(names)]
    for r in rows:
        if len(r) != n:
            raise SystemExit('row %s has %d cols, want %d' % (r[0], len(r), n))
        out.append(b'\t'.join(r))
    data = eol.join(out) + eol
    data.decode('gbk')   # bảng server phải là GBK toàn file (bẫy txtreader)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(data)


def g(b):
    return b.decode('gbk', 'replace')


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        h.update(f.read())
    return h.hexdigest()


def load_registry():
    out = collections.defaultdict(dict)
    with open(REGISTRY, encoding='utf-8') as f:
        for line in f:
            if line.startswith('#') or not line.strip():
                continue
            c = line.rstrip('\n').split('\t')
            if len(c) >= 5 and c[1].isdigit() and c[4].strip().isdigit():
                out[c[0]][int(c[1])] = int(c[4])
    return out


# ---------------------------------------------------------------- nguồn
class Sources:
    def __init__(self, base_rev):
        self.base_rev = base_rev
        self.gl = {t: read_table_bytes(git_show(base_rev, 'configs/' + t)) for t in TABLES}
        self.cy = {t: read_table(os.path.join(CY_DIR, t)) for t in TABLES}
        self.hj = {t: read_table(os.path.join(HJ_DIR, t)) for t in TABLES if t != 'XinFaStudySpend_V1.txt'}
        self.registry = load_registry()
        self.gl_by_id = {t: {int(r[0]): r for r in self.gl[t]['rows']} for t in TABLES}
        self.cy_by_id = {t: {int(r[0]): r for r in self.cy[t]['rows']} for t in TABLES}
        self.hj_by_id = {t: {int(r[0]): r for r in self.hj[t]['rows']} for t in self.hj}

    def colmap(self, t):
        m = dict(self.registry.get(t, {}))
        for k in MANUAL_DROP.get(t, []):
            m.pop(k, None)
        m.update(MANUAL_MAP.get(t, {}))
        return m


# ---------------------------------------------------------------- tra ID theo tên
class Resolver:
    """GL id → CY id cho SkillTemplate (tên + môn phái đã ánh xạ, phá hoà theo mọi cột INT đã ánh xạ) và XinFa (tên)."""

    def __init__(self, src, colmap=None):
        self.src = src
        t = 'SkillTemplate_V1.txt'
        self.colmap = colmap or src.colmap(t)
        self.gl_name_ids = collections.defaultdict(set)
        for r in src.gl[t]['rows']:
            self.gl_name_ids[r[3]].add(int(r[0]))
        self.cy_skill_key = collections.defaultdict(list)
        for r in src.cy[t]['rows']:
            self.cy_skill_key[(int(r[1]), r[2])].append(int(r[0]))
        self.cy_xinfa_name = {}
        for r in src.cy['XinFa_V1.txt']['rows']:
            self.cy_xinfa_name.setdefault(r[2], int(r[0]))
        self.gl_xinfa = {int(r[0]): r for r in src.gl['XinFa_V1.txt']['rows']}
        self.log = {}

    def xinfa(self, gl_id):
        r = self.gl_xinfa.get(gl_id)
        if not r:
            return None
        return self.cy_xinfa_name.get(r[2])

    def skill(self, gl_id):
        if gl_id in self.log:
            return self.log[gl_id][0]
        gl = self.src.gl_by_id['SkillTemplate_V1.txt'].get(gl_id)
        if not gl:
            self.log[gl_id] = (None, 'not-in-gl', [])
            return None
        cm = MENPAI_MAP.get(int(gl[2]), int(gl[2]))
        if int(gl[2]) == 10:
            self.log[gl_id] = (None, 'mantuo', [])
            return None
        cands = self.cy_skill_key.get((cm, gl[3]), [])
        if not cands:
            self.log[gl_id] = (None, 'missing', [])
            return None
        if len(cands) == 1:
            self.log[gl_id] = (cands[0], 'unique', cands)
            return cands[0]
        # ứng viên trùng ID với một dòng GL khác cùng tên thì thuộc về dòng đó (vd 281 伏虎拳 ↔ 3266 伏虎拳 bản viễn công)
        own = [c for c in cands if c == gl_id or not (c in self.gl_name_ids[gl[3]])]
        if len(own) == 1:
            self.log[gl_id] = (own[0], 'claimed', cands)
            return own[0]
        cands2 = own or cands
        # phá hoà: xinfa (GL 11 ↔ CY 10, qua tên) + số cột INT/FLOAT đã ánh xạ có giá trị bằng nhau + ID trùng
        gx = self.xinfa(int(gl[11])) if gl[11].lstrip(b'-').isdigit() else None
        types = self.src.gl['SkillTemplate_V1.txt']['types']
        best = []
        for c in cands2:
            cy = self.src.cy_by_id['SkillTemplate_V1.txt'][c]
            score = 0
            if gx is not None and cy[10].lstrip(b'-').isdigit() and int(cy[10]) == gx:
                score += 4
            for cyc, glc in self.colmap.items():
                if glc < len(gl) and cyc < len(cy) and glc not in (0, 1, 2, 3) and types[glc] != b'STRING' and gl[glc] == cy[cyc]:
                    score += 1
            if c == gl_id:
                score += 2
            best.append((score, -c))
        best.sort(reverse=True)
        chosen = -best[0][1]
        tie = len(best) > 1 and best[0][0] == best[1][0]
        self.log[gl_id] = (chosen, 'tie' if tie else 'scored', cands)
        return chosen

    def xinfa7_skills(self, cy_menpai, cy_xinfa7):
        """Các kỹ năng CY của phái có 心法ID = xinfa thứ 7, bỏ bản sao 化气式 (tên trùng kỹ năng phái khác)."""
        t = 'SkillTemplate_V1.txt'
        # chỉ 慕容 (10) có bản sao 化气式 mang tên kỹ năng phái khác (788–800); các phái khác giữ nguyên
        other = {r[2] for r in self.src.cy[t]['rows'] if int(r[1]) not in (cy_menpai, -1)} if cy_menpai == 10 else set()
        return sorted(int(r[0]) for r in self.src.cy[t]['rows'] if int(r[1]) == cy_menpai and r[10] == str(cy_xinfa7).encode() and r[2] not in other)

    def skills7(self, gl_ids, cy_menpai, cy_xinfa7):
        """skills7 theo vị trí: tra tên; nếu thiếu hoặc không thuộc xinfa7 thì lấy kỹ năng xinfa7 chưa dùng theo thứ tự ID."""
        pool = self.xinfa7_skills(cy_menpai, cy_xinfa7)
        out, how = [], []
        for gid in gl_ids:
            c = self.skill(gid)
            if c in pool and c not in out:
                out.append(c)
                how.append('name')
            else:
                out.append(None)
                how.append('position')
        for i, c in enumerate(out):
            if c is None:
                rest = [p for p in pool if p not in out]
                out[i] = rest[0] if rest else -1
        return out, how, pool


# ---------------------------------------------------------------- dựng bảng
def mode_defaults(types, rows):
    out = []
    for i, t in enumerate(types):
        vals = collections.Counter(r[i] for r in rows if i < len(r))
        out.append(vals.most_common(1)[0][0] if vals else (b'-1' if t in (b'INT',) else b''))
    return out


def build_table(src, t, plan, staging):
    gl, cy = src.gl[t], src.cy[t]
    types, names, eol = list(gl['types']), list(gl['names']), gl['eol']
    stats = collections.Counter()
    notes = []
    if t == 'XinFaStudySpend_V1.txt':
        ncy = len(cy['types'])
        assert names[0] == b'Index' and all(names[2 + 2 * k] == b'\xcf\xfb\xba\xc4\xbd\xf0\xc7\xae' for k in range((ncy - 2) // 2))
        rows = [r[:ncy] for r in cy['rows']]
        write_table(os.path.join(staging, 'configs', t), types[:ncy], names[:ncy], rows, eol)
        plan['tables'][t] = {'cols': ncy, 'gl_cols': len(types), 'rows': len(rows), 'gl_rows': len(gl['rows']), 'source': 'CY (cột 0..%d, tên cột GL)' % (ncy - 1)}
        return
    colmap = src.colmap(t)
    gname, cname = NAME_COL[t]
    hj = src.hj.get(t)
    hj_by_id = src.hj_by_id.get(t, {})
    gl_by_id = src.gl_by_id[t]
    ngl = len(types)
    if t == 'SkillData_V1.txt':
        # nới 12 → 15 cặp tham số (cột 48..53), tên cột lặp như 12 cặp trước
        for k in range(SKILLDATA_EXTRA_PAIRS):
            types += [b'STRING', b'INT']
            names += [names[24], names[25]]
        ngl = len(types)
    gl_by_id = {i: (r + [b''] * (ngl - len(r)))[:ngl] for i, r in gl_by_id.items()}
    hj_by_id = {i: (r + [b''] * (ngl - len(r)))[:ngl] for i, r in hj_by_id.items()}
    # kiểm ánh xạ cột trên dòng chung (cùng ID, cùng tên) → bằng chứng trong plan
    common = [i for i in gl_by_id if i in src.cy_by_id[t] and gl_by_id[i][gname] == src.cy_by_id[t][i][cname]]
    agree = {}
    for cyc, glc in sorted(colmap.items()):
        if glc >= ngl or cyc >= len(cy['types']):
            continue
        n = sum(1 for i in common if gl_by_id[i][glc] == src.cy_by_id[t][i][cyc])
        agree[glc] = (cyc, round(n / max(1, len(common)), 3))
    weak = {glc: v for glc, v in agree.items() if v[1] < 0.6}
    # ánh xạ registry yếu (< 0.6, không phải cột chuỗi/mô tả, không do MANUAL) → bỏ, giữ giá trị nền
    dropped_weak = {}
    for glc, (cyc, rate) in weak.items():
        if cyc in MANUAL_MAP.get(t, {}) or types[glc] == b'STRING':
            continue
        if t == 'EquipBase.txt' and glc == 7:
            continue                      # 适应规则: giá trị CY khác thật (cùng cột, cân bằng lại) — giữ CY
        dropped_weak[glc] = (cyc, rate)
        colmap.pop(cyc, None)
    # tự dò cột GL chưa ánh xạ (cùng kiểu, khớp ≥ 0.9 trên ≥ 100 dòng có giá trị khác mặc định)
    mapped_gl = set(colmap.values())
    auto = {}
    for glc in range(ngl):
        if glc in mapped_gl or glc == 0:
            continue
        vals = [i for i in common if gl_by_id[i][glc] not in (b'', b'0', b'-1')]
        if len(vals) < 100:
            continue
        best = None
        for cyc in range(len(cy['types'])):
            if cy['types'][cyc] != types[glc] or cyc in colmap:
                continue
            n = sum(1 for i in vals if gl_by_id[i][glc] == src.cy_by_id[t][i][cyc])
            if best is None or n > best[1]:
                best = (cyc, n)
        if best and best[1] / len(vals) >= 0.9:
            auto[glc] = (best[0], round(best[1] / len(vals), 3), len(vals))
            colmap[best[0]] = glc
    defaults = mode_defaults(types, hj['rows'] if hj else gl['rows'])
    if t == 'SkillTemplate_V1.txt':
        defaults[81] = b'0'
    hj_ok = set()
    rows = []
    src_counter = collections.Counter()
    impact_reset = script_reset = 0
    script_ids = plan.get('script_ids', set())
    for cid, cyrow in sorted(src.cy_by_id[t].items()):
        base, source = None, None
        h = hj_by_id.get(cid)
        if h is not None and h[gname] == cyrow[cname]:
            base = list(h)
            if t == 'SkillTemplate_V1.txt':
                base[81] = b'0'
            source = 'hj'
            hj_ok.add(cid)
        elif cid in gl_by_id and gl_by_id[cid][gname] == cyrow[cname] and (t not in MENPAI_COL or MENPAI_MAP.get(int(gl_by_id[cid][MENPAI_COL[t][0]]), int(gl_by_id[cid][MENPAI_COL[t][0]])) == int(cyrow[MENPAI_COL[t][1]])):
            base = list(gl_by_id[cid])
            source = 'gl'
        else:
            base = list(defaults)
            source = 'default'
        src_counter[source] += 1
        row = base
        for cyc, glc in colmap.items():
            if glc < ngl and cyc < len(cyrow):
                row[glc] = cyrow[cyc]
        for k in range(ngl):
            if row[k] == b'' and types[k] in (b'INT', b'FLOAT'):
                row[k] = defaults[k] if defaults[k] != b'' else b'0'
        if t == 'EquipBase.txt':
            # cột 19 impact (StandardImpact) và 20 script: đánh số CY chưa có trên server → giữ GL nếu có, không thì -1
            if source != 'gl':
                glrow = gl_by_id.get(cid)
                if glrow is not None and glrow[gname] == cyrow[cname]:
                    row[EQUIP_IMPACT_COL] = glrow[EQUIP_IMPACT_COL]
                elif row[EQUIP_IMPACT_COL] != b'-1':
                    row[EQUIP_IMPACT_COL] = b'-1'
                    impact_reset += 1
            if row[EQUIP_SCRIPT_COL] != b'-1' and int(row[EQUIP_SCRIPT_COL]) not in script_ids:
                row[EQUIP_SCRIPT_COL] = b'-1'
                script_reset += 1
        if t == 'SkillTemplate_V1.txt':
            # cột 79 未知 / 80 七情技能 / 81: giữ theo nguồn nền (GL) nếu có, HJ/mặc định không có cột này
            if source != 'gl' and cid in gl_by_id and gl_by_id[cid][gname] == cyrow[cname]:
                for k in (79, 80, 81):
                    row[k] = gl_by_id[cid][k]
        rows.append(row)
    write_table(os.path.join(staging, 'configs', t), types, names, rows, eol)
    # lưu trữ dòng chỉ-GL (ID không có ở CY, hoặc cùng ID khác tên/khác phái) sang dải riêng, TẮT (không nạp)
    archived, reserved = [], []
    cy_ids = src.cy_by_id[t]
    for gid, r in sorted(gl_by_id.items()):
        c = cy_ids.get(gid)
        same = c is not None and c[cname] == r[gname]
        if same and t in MENPAI_COL and MENPAI_MAP.get(int(r[MENPAI_COL[t][0]]), int(r[MENPAI_COL[t][0]])) != int(c[MENPAI_COL[t][1]]):
            same = False
        if not same:
            archived.append(r)
            reserved.append((gid, gid + RESERVED[t]))
    if archived:
        write_table(os.path.join(staging, 'configs', 'cys_gl_only', t), gl['types'], gl['names'], [r[:len(gl['types'])] for r in archived], eol)
        with open(os.path.join(staging, 'configs', 'cys_gl_only', t + '.reserved_ids.tsv'), 'w', encoding='utf-8') as f:
            f.write('# ID gốc GL\tID dải riêng đề xuất (+%d) — dòng CHƯA nạp, chỉ lưu trữ (CS3b)\n' % RESERVED[t])
            for a, b in reserved:
                f.write('%d\t%d\n' % (a, b))
    plan['tables'][t] = {
        'cols': ngl, 'gl_cols': len(gl['types']), 'rows': len(rows), 'gl_rows': len(gl['rows']), 'hj_rows': len(hj['rows']) if hj else None,
        'row_source': dict(src_counter), 'common_same_name_for_colcheck': len(common),
        'colmap_cy_to_gl': {str(k): v for k, v in sorted(colmap.items())}, 'agreement_by_gl_col': {str(k): v for k, v in sorted(agree.items())},
        'weak_registry_maps': {str(k): v for k, v in weak.items()}, 'dropped_weak_maps': {str(k): v for k, v in dropped_weak.items()},
        'auto_aligned_gl_cols': {str(k): v for k, v in auto.items()},
        'unmapped_gl_cols': [k for k in range(ngl) if k not in colmap.values() and k != 0],
        'archived_gl_only_rows': len(archived), 'equip_impact_reset_to_-1': impact_reset, 'equip_script_reset_to_-1': script_reset,
        'defaults_source': 'tlbb15 mode' if hj else 'GL mode',
    }


# ---------------------------------------------------------------- Lua
MENPAI_VARS = r'(?:menpai|MenPai|nMenPai|nMenpai|MenPaiID|playerMenpai|havemenpai|target_menpai|nMenPaiID|menpaiID|oldMenPai|mymenpai|myMenpai|menpai_id|MP)'
CMP_RE = re.compile(r'(\b' + MENPAI_VARS + r'\b|get_menpai\(\)|GetMenPai\([^)]*\))(\s*)(==|~=)(\s*)(1[0-6])\b')
SKIP_DIRS = ('GameServer/lualib/cy_four_combat/',)


def lua_generic_edits(plan):
    """Đổi so sánh `<biến phái> ==/~= 10..16` theo MENPAI_MAP trong Game_2/Script + GameServer (trừ cy_four_combat: số donor)."""
    edits = []
    roots = ['Game_2/Script', 'GameServer/services', 'GameServer/lualib']
    for root in roots:
        for dp, dn, fn in os.walk(os.path.join(R, root)):
            for f in fn:
                if not f.endswith('.lua'):
                    continue
                rel = os.path.relpath(os.path.join(dp, f), R).replace('\\', '/')
                if any(rel.startswith(s) for s in SKIP_DIRS) or rel.endswith('/define.lua') or rel.endswith('menpai_extensions.lua') or rel.endswith('jianzong_ranklist.lua'):
                    continue
                with open(os.path.join(dp, f), 'rb') as fh:
                    data = fh.read()
                if b'enpai' not in data and b'MenPai' not in data:
                    continue
                text = data.decode('utf-8', 'surrogateescape')
                hits = []

                def sub(m):
                    old = int(m.group(5))
                    new = MENPAI_MAP[old]
                    hits.append((old, new))
                    return m.group(1) + m.group(2) + m.group(3) + m.group(4) + str(new)
                new_text = CMP_RE.sub(sub, text)
                if hits:
                    edits.append({'file': rel, 'kind': 'menpai-compare', 'hits': hits, 'text': new_text})
    return edits


def lua_explicit_edits(res, plan):
    """Sửa chuỗi chính xác (old → new); mỗi mục phải khớp đúng số lần `n`."""
    x7, x8 = lambda i: res.xinfa(i), lambda i: res.xinfa(i)
    sk = res.skill
    E = []

    def add(rel, pairs):
        E.append({'file': rel, 'kind': 'exact', 'pairs': pairs})

    add('GameServer/lualib/define.lua', [
        ('    MATTRIBUTE_MANTUOSHANZHUANG = 10, ---曼陀山庄', '    MATTRIBUTE_MANTUOSHANZHUANG = 16, ---曼陀山庄 (CS3b: CY không có, ô 16 TẮT)', 1),
        ('    MATTRIBUTE_ERENGU = 11, ---恶人谷', '    MATTRIBUTE_ERENGU = 15, ---恶人谷 (CS3b: số CY)', 1),
        ('    MATTRIBUTE_GUSU = 12, ---慕容', '    MATTRIBUTE_GUSU = 10, ---慕容 (CS3b: số CY)', 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG]  = { [785] = 1, [784] = 2, [786] = 3,},',
         '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG]  = { [%d] = 1, [%d] = 2, [%d] = 3,}, -- CS3b: dải riêng, tắt' % (50785, 50784, 50786), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU]  = { [808] = 1, [810] = 2, [811] = 3,},',
         '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU]  = { [%d] = 1, [%d] = 2, [%d] = 3,}, -- CS3b: ID CY (无我三界/判指阴阳/魂离魄散, 心法 119)' % tuple(res.skills7((808, 810, 811), 15, x7(87))[0]), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]    = { [830] = 1, [831] = 2, [832] = 3,},',
         '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]    = { [784] = 1, [785] = 2, [781] = 3,}, -- CS3b: CY 慕容 心法 70 星璇剑典: 破天式/凌神式/化气式 (GL 830-832 thuộc 心法 69 ở CY)', 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG] = 110,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG] = 50110, -- CS3b: dải riêng, tắt', 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU] = 111,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU] = %d, -- CS3b: ID CY' % sk(111), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]   = 112,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]   = %d, -- CS3b: ID CY (慕容轻功)' % sk(113), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG]    = 70,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG]    = 1070, -- CS3b: dải riêng, tắt', 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU]    = 87,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU]    = %d, -- CS3b: ID CY' % x7(87), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]       = 95,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]       = %d, -- CS3b: ID CY' % x7(95), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG]    = 71,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG]    = 1071, -- CS3b: dải riêng, tắt', 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU]    = 88,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU]    = %d, -- CS3b: ID CY' % x8(88), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]       = 96,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]       = %d, -- CS3b: ID CY' % x8(96), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU] = 847,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU] = %d, -- CS3b: ID CY' % sk(847), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN]    = 3266,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN]    = %d, -- CS3b: ID CY' % sk(3266), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO]   = 3269,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO]   = %d, -- CS3b: ID CY' % sk(3269), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG]    = 3267,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG]    = %d, -- CS3b: ID CY' % sk(3267), 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN]   = 3268,', '    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN]   = %d, -- CS3b: ID CY' % sk(3268), 1),
        ('\t[10] = {760,771,775},\n\t[11] = {788,799,803},',
         '\t[10] = {760,771,775}, -- CS3b: 慕容 CY (柳拂衣/重云掩日/剑锁江山, GL đã dùng đúng ID CY cho 曼陀)\n\t[16] = {}, -- CS3b: 曼陀 tắt\n\t[15] = {%d,%d,%d}, -- CS3b: 恶人谷, ID CY' % (sk(788), sk(799), sk(803)), 1),
        ('    [10] = "曼陀" ,\n\t[11] = "恶人谷",\n    [12] = "慕容",', '    [16] = "曼陀" , -- CS3b: tắt\n\t[15] = "恶人谷",\n    [10] = "慕容",', 1),
        ('    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU]    = {431,441,445},', None, 0),   # không có: giữ nguyên (kiểm 445 riêng)
    ])
    E[-1]['pairs'] = [p for p in E[-1]['pairs'] if p[1] is not None]
    # registry: legacy theo tập ID, không theo "≤ 12"
    add('GameServer/lualib/menpai_registry.lua', [
        ('registry.LEGACY_MAX_ID = 12\n', 'registry.LEGACY_MAX_ID = 12 -- CS3b: không dùng nữa, xem LEGACY_IDS\nregistry.LEGACY_IDS = {%s} -- CS3b: phái có mã Lua riêng theo số CY (0-8, 慕容 10, 恶人谷 15, 曼陀 16 tắt)\nfunction registry.is_legacy(id) return registry.LEGACY_IDS[id] == true end\n' % ', '.join('[%d] = true' % i for i in LEGACY_CY), 1),
        ('        if integer(id, registry.LEGACY_MAX_ID + 1, registry.MAX_ID) then', '        if registry.is_slot(id) and not registry.is_legacy(id) then', 1),
        ('    if id <= registry.LEGACY_MAX_ID then return true, "legacy_configured" end', '    if registry.is_legacy(id) then return true, "legacy_configured" end', 1),
        ('    if not ok or id <= registry.LEGACY_MAX_ID then return ok, reason end', '    if not ok or registry.is_legacy(id) then return ok, reason end', 1),
    ])
    add('GameServer/services/scene/obj/human.lua', [
        ('    if menpai > menpai_registry.LEGACY_MAX_ID or (type(source) == "number" and source > menpai_registry.LEGACY_MAX_ID) then',
         '    if not menpai_registry.is_legacy(menpai) or (type(source) == "number" and not menpai_registry.is_legacy(source)) then -- CS3b', 1),
    ])
    add('GameServer/lualib/cy_four_combat/native_config.lua', [('reverse_faction={[13]=11,[14]=12,[15]=13,[16]=14}', 'reverse_faction={[11]=11,[12]=12,[13]=13,[14]=14}', 1)])
    add('GameServer/lualib/cy_four_combat/phase2_config.lua', [('["faction"]={[11]=13,[12]=14,[13]=15,[14]=16}', '["faction"]={[11]=11,[12]=12,[13]=13,[14]=14}', 1)])
    add('GameServer/lualib/cy_four_combat/release.lua', [
        (' if id==map[3820] and menpai==15 then', ' if id==map[3820] and menpai==13 then', 1),
        (' elseif menpai==16 and (', ' elseif menpai==14 and (', 1),
        ("owner:get_menpai()~=15 then return end", "owner:get_menpai()~=13 then return end", 1),
        ("owner:get_menpai()~=15 or not owner:is_alive()", "owner:get_menpai()~=13 or not owner:is_alive()", 1),
        ("attacker:get_menpai()~=15 or target", "attacker:get_menpai()~=13 or target", 1),
    ])
    add('GameServer/lualib/cy_four_combat/resource_feedback.lua', [
        (" if faction==15 then id,base,label=328,10000,'Cong tinh'", " if faction==13 then id,base,label=328,10000,'Cong tinh'", 1),
        (" elseif faction==16 then id,base,label=331,10,'Dao y'", " elseif faction==14 then id,base,label=331,10,'Dao y'", 1),
        (" if cap==0 then cap=faction==15 and 1000 or 3 end", " if cap==0 then cap=faction==13 and 1000 or 3 end", 1),
        (" local bucket=owner:get_menpai()==15 and", " local bucket=owner:get_menpai()==13 and", 1),
    ])
    add('GameServer/services/scene/skill/human/skill_751.lua', [
        ('    elseif target_menpai >= 10 and target_menpai <= 11 then', '    elseif target_menpai >= 10 and target_menpai <= 15 then -- CS3b: số CY, SkillData CY có tham số mọi phái', 1),
    ])
    add('Game_2/Script/scripts/obj/dali/odali_azi.lua', [('\tif menpai > 13 then', '\tif menpai > 15 then -- CS3b: ≤15 = 15 phái CY', 2)])
    add('Game_2/Script/scripts/NewLua/newchangsong.lua', [('\tif menpai > 13 then', '\tif menpai > 15 then -- CS3b', 1)])
    add('Game_2/Script/scripts/obj/commonitem/item_100019_38000958.lua', [('havemenpai > 12 or havemenpai == 9', 'havemenpai > 15 or havemenpai == 9', 2)])
    add('Game_2/Script/scripts/GmTool_Self.lua', [('if p1 < 0 or p1 > 16 then', 'if p1 < 0 or p1 > 15 then', 1)])
    return E


def render_extensions(res):
    items = []
    for gl_id, (enum, name, ab, ca, s7, x7, x8, qg, rep, at, qs) in (
        (13, ('MATTRIBUTE_TANGMEN', '唐门', (70, 71), 70, (5766, 5767, 5642), 103, 104, 5648, 59, 17, (5619, 5620, 5621))),
        (14, ('MATTRIBUTE_GUIGU', '鬼谷', (72, 73), 72, (5670, 5671, 5672), 111, 112, 5677, 60, 18, (5649, 5650, 5651))),
        (15, ('MATTRIBUTE_TAOHUADAO', '桃花岛', (74, 75), 74, (5708, 5709, 5710), 119, 120, 5718, 61, 19, (5687, 5688, 5689))),
        (16, ('MATTRIBUTE_JUEQINGGU', '绝情谷', (76, 77), 76, (5750, 5751, 5752), 127, 128, 5755, 62, 20, (5723, 5724, 5725)))):
        cy_id = MENPAI_MAP[gl_id]
        cx7 = res.xinfa(x7)
        s7c, how, pool = res.skills7(s7, cy_id, cx7)
        res.log['skills7_%d' % cy_id] = (s7c, ','.join(how), pool)
        items.append('''    [%d] = { -- GL %d
        enum = "%s", name = "%s", enabled = true,
        abilities = {%d, %d}, compound_ability = %d,
        skills7 = {%s}, -- GL {%s}: %s
        xinfa7 = %d, xinfa8 = %d,
        qinggong = %d, reputation = %d,
        attack_traits = %d, quick_skills = {%s},
    },''' % (cy_id, gl_id, enum, name, ab[0], ab[1], ca, ', '.join(str(s) for s in s7c), ', '.join(str(s) for s in s7), ', '.join(how),
             cx7, res.xinfa(x8), res.skill(qg), rep, at, ', '.join(str(res.skill(s)) for s in qs)))
    return ('-- Four schools prepared from verified donor identities.\n-- Enable only after combat, NPC and client checks succeed; do not bypass check_ready.\n'
            '-- CS3b (14/09/2026): khoá = số phái CY (11 唐门, 12 鬼谷, 13 桃花岛, 14 绝情谷); skill/xinfa = ID CY tra theo tên từ ID GL cũ.\nreturn {\n' + '\n'.join(items) + '\n}\n')


def render_training_config(res, text):
    def f_menpai(m):
        return '["menpaiId"]=%d' % MENPAI_MAP[int(m.group(1))]
    text = re.sub(r'\["menpaiId"\]=(\d+)', f_menpai, text)
    # books: type 1 = xinfa, type 2 = skill; needXinfa = xinfa
    def f_book(m):
        body = m.group(0)
        typ = int(re.search(r'\["type"\]=(\d+)', body).group(1))
        def f_id(mm):
            v = int(mm.group(1))
            nv = res.xinfa(v) if typ == 1 else res.skill(v)
            return '["id"]=%d' % (nv if nv is not None else -1)
        body = re.sub(r'\["id"\]=(\d+)', f_id, body)
        def f_nx(mm):
            v = int(mm.group(1))
            if v < 0:
                return mm.group(0)
            nv = res.xinfa(v)
            return '["needXinfa"]=%d' % (nv if nv is not None else -1)
        body = re.sub(r'\["needXinfa"\]=(-?\d+)', f_nx, body)
        return body
    text = re.sub(r'\[\d+\]=\{\["type"\]=\d+,[^{}]*\}', f_book, text)
    # factions keyed 13..16 → CY; qinggong → CY
    def f_fac(m):
        return '["factions"]={' + ''.join('[%d]=' % MENPAI_MAP[int(k)] + v for k, v in re.findall(r'\[(\d+)\]=(\{.*?\}\}\},?)', m.group(1)))
    def f_qg(m):
        v = res.skill(int(m.group(1)))
        return '["qinggong"]=%d' % (v if v is not None else -1)
    text = re.sub(r'\["qinggong"\]=(\d+)', f_qg, text)
    text = re.sub(r'(?<=\[)(1[3-6])(?=\]=\{\["name"\])', lambda m: str(MENPAI_MAP[int(m.group(1))]), text)
    return text


def basevalue_rename(data):
    text = data.decode('utf-8', 'surrogateescape')
    def f(m):
        return '[MENPAI%d]' % MENPAI_MAP[int(m.group(1))]
    return re.sub(r'\[MENPAI(1[0-6])\]', f, text).encode('utf-8', 'surrogateescape')


# ---------------------------------------------------------------- plan
def script_ids_on_server():
    ids = set()
    p = os.path.join(R, 'Game_2/Script/scripts/scripts.lua')
    with open(p, 'rb') as f:
        for m in re.finditer(rb'\[(\d+)\]\s*=', f.read()):
            ids.add(int(m.group(1)))
    return ids


def cmd_plan(args):
    staging = args.out
    os.makedirs(staging, exist_ok=True)
    src = Sources(args.base_rev)
    plan = {'created': datetime.datetime.utcnow().isoformat() + 'Z', 'base_rev': args.base_rev, 'menpai_map': MENPAI_MAP,
            'menpai_cy_name': MENPAI_CY_NAME, 'tables': {}, 'lua': [], 'script_ids': script_ids_on_server()}
    for t in TABLES:
        build_table(src, t, plan, staging)
    plan['script_ids'] = len(plan['script_ids'])
    res = Resolver(src, {int(k): v for k, v in plan['tables']['SkillTemplate_V1.txt']['colmap_cy_to_gl'].items()})
    # Exterior_Ride.txt: chỉ đổi số ở cột 门派 (bảng server GL, giữ nguyên byte khác)
    ride_path = os.path.join(R, 'configs/Exterior_Ride.txt')
    with open(ride_path, 'rb') as f:
        ride = f.read()
    rl = ride.split(b'\n')
    names = rl[1].rstrip(b'\r').split(b'\t')
    mcol = names.index('门派'.encode('gbk'))
    ride_hits = collections.Counter()
    for i in range(2, len(rl)):
        line = rl[i].rstrip(b'\r')
        if not line.strip():
            continue
        c = line.split(b'\t')
        if mcol < len(c) and c[mcol].isdigit() and 10 <= int(c[mcol]) <= 16:
            ride_hits[int(c[mcol])] += 1
            c[mcol] = str(MENPAI_MAP[int(c[mcol])]).encode()
            rl[i] = b'\t'.join(c) + (b'\r' if rl[i].endswith(b'\r') else b'')
    ride2 = b'\n'.join(rl)

    def gbk_ok(b):
        try:
            b.decode('gbk')
            return True
        except UnicodeDecodeError as ex:
            return 'byte %r at %d' % (ex.object[ex.start:ex.start + 1], ex.start)
    if gbk_ok(ride) is True:
        ride2.decode('gbk')
    with open(os.path.join(staging, 'configs/Exterior_Ride.txt'), 'wb') as f:
        f.write(ride2)
    plan['tables']['Exterior_Ride.txt'] = {'menpai_col': mcol, 'remapped_values': dict(ride_hits), 'changed': ride2 != ride,
                                           'source': 'GL server, chỉ đổi số phái', 'gbk_original': gbk_ok(ride), 'gbk_after': gbk_ok(ride2)}
    # Lua
    edits = lua_explicit_edits(res, plan) + lua_generic_edits(plan)
    lua_dir = os.path.join(staging, 'lua')
    rendered = []
    for e in edits:
        rel = e['file']
        path = os.path.join(R, rel)
        with open(path, 'rb') as f:
            data = f.read()
        text = data.decode('utf-8', 'surrogateescape')
        if e['kind'] == 'exact':
            status = []
            for old, new, n in e['pairs']:
                c = text.count(old)
                if c == n:
                    text = text.replace(old, new)
                    status.append('applied:%d' % n)
                elif c == 0 and text.count(new) >= 1:
                    status.append('already')
                else:
                    raise SystemExit('%s: expected %d of %r, found %d' % (rel, n, old[:60], c))
            e['status'] = status
        else:
            text = e['text']
            del e['text']
        out = os.path.join(lua_dir, rel)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, 'wb') as f:
            f.write(text.encode('utf-8', 'surrogateescape'))
        e['changed'] = text.encode('utf-8', 'surrogateescape') != data
        rendered.append(e)
    # menpai_extensions.lua, cy_four_training_config.lua, BaseValueTable.ini
    ext = render_extensions(res)
    out = os.path.join(lua_dir, 'GameServer/lualib/menpai_extensions.lua')
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        f.write(ext)
    rendered.append({'file': 'GameServer/lualib/menpai_extensions.lua', 'kind': 'render'})
    tc = os.path.join(R, 'GameServer/lualib/cy_four_training_config.lua')
    with open(tc, 'rb') as f:
        tct = f.read().decode('utf-8', 'surrogateescape')
    tct2 = render_training_config(res, tct)
    out = os.path.join(lua_dir, 'GameServer/lualib/cy_four_training_config.lua')
    with open(out, 'wb') as f:
        f.write(tct2.encode('utf-8', 'surrogateescape'))
    rendered.append({'file': 'GameServer/lualib/cy_four_training_config.lua', 'kind': 'render', 'changed': tct2 != tct})
    with open(os.path.join(R, 'configs/BaseValueTable.ini'), 'rb') as f:
        bv = f.read()
    bv2 = basevalue_rename(bv)
    with open(os.path.join(staging, 'configs/BaseValueTable.ini'), 'wb') as f:
        f.write(bv2)
    rendered.append({'file': 'configs/BaseValueTable.ini', 'kind': 'render', 'changed': bv2 != bv,
                     'sections': re.findall(r'\[MENPAI\d+\]', bv2.decode('utf-8', 'surrogateescape'))})
    # jianzong_ranklist: dữ liệu xếp hạng mẫu, đổi số phái
    jz = os.path.join(R, 'GameServer/lualib/jianzong_ranklist.lua')
    with open(jz, 'rb') as f:
        jt = f.read().decode('utf-8', 'surrogateescape')
    jt2 = re.sub(r'(\bmenpai = )(1[0-6])(,)', lambda m: m.group(1) + str(MENPAI_MAP[int(m.group(2))]) + m.group(3), jt)
    out = os.path.join(lua_dir, 'GameServer/lualib/jianzong_ranklist.lua')
    with open(out, 'wb') as f:
        f.write(jt2.encode('utf-8', 'surrogateescape'))
    rendered.append({'file': 'GameServer/lualib/jianzong_ranklist.lua', 'kind': 'regex', 'changed': jt2 != jt, 'hits': len(re.findall(r'\bmenpai = 1[0-6],', jt))})
    plan['lua'] = rendered
    plan['skill_resolve_log'] = {str(k): {'cy': v[0], 'how': v[1], 'cands': v[2]} for k, v in sorted(res.log.items(), key=lambda x: str(x[0]))}
    plan['xinfa_resolve'] = {str(i): res.xinfa(i) for i in sorted(res.gl_xinfa)}
    # bảng khác có cột 门派 (chỉ báo cáo)
    other = {}
    for f in sorted(os.listdir(os.path.join(R, 'configs'))):
        if not f.endswith('.txt') or f in TABLES:
            continue
        try:
            with open(os.path.join(R, 'configs', f), 'rb') as fh:
                head = fh.read(200000).split(b'\n')
            if len(head) < 3:
                continue
            names = head[1].rstrip(b'\r').split(b'\t')
            cols = [i for i, n in enumerate(names) if b'\xc3\xc5\xc5\xc9' in n]   # 门派 GBK
            if cols:
                vals = collections.Counter()
                for l in head[2:]:
                    c = l.rstrip(b'\r').split(b'\t')
                    for i in cols:
                        if i < len(c) and c[i].lstrip(b'-').isdigit() and 10 <= int(c[i]) <= 16:
                            vals[int(c[i])] += 1
                other[f] = {'cols': [(i, g(names[i])) for i in cols], 'values_10_16': dict(vals)}
        except Exception as ex:   # noqa
            other[f] = {'error': str(ex)}
    plan['other_tables_with_menpai_col'] = other
    with open(os.path.join(staging, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1, default=str)
    print(json.dumps({k: v for k, v in plan.items() if k in ('tables',)}, ensure_ascii=False, indent=1))
    print('lua files:', [(e['file'], e.get('changed'), e.get('hits') or e.get('status')) for e in rendered])
    print('other tables with 门派 col:', json.dumps(other, ensure_ascii=False))


# ---------------------------------------------------------------- apply
def staged_files(staging):
    out = []
    for sub in ('configs', 'lua'):
        base = os.path.join(staging, sub)
        for dp, dn, fn in os.walk(base):
            for f in fn:
                p = os.path.join(dp, f)
                rel = os.path.relpath(p, base).replace('\\', '/')
                out.append((p, rel if sub == 'lua' else 'configs/' + rel))
    return sorted(out, key=lambda x: x[1])


def clients():
    n = 0
    for name in ('/proc/net/tcp', '/proc/net/tcp6'):
        with open(name) as f:
            for line in f.read().splitlines()[1:]:
                parts = line.split()
                port = int(parts[1].split(':')[1], 16)
                if port in (15733, 15734) and parts[3] == '01':
                    n += 1
    return n


def cmd_apply(args):
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'cs3b-' + stamp)
    changed, same = [], []
    for src_path, rel in staged_files(args.staging):
        dst = os.path.join(R, rel)
        with open(src_path, 'rb') as f:
            new = f.read()
        old = None
        if os.path.exists(dst):
            with open(dst, 'rb') as f:
                old = f.read()
        if old == new:
            same.append(rel)
            continue
        changed.append(rel)
        if args.dry_run:
            continue
        if old is not None:
            bp = os.path.join(bdir, rel)
            os.makedirs(os.path.dirname(bp), exist_ok=True)
            with open(bp, 'wb') as f:
                f.write(old)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(new)
    print(json.dumps({'dry_run': args.dry_run, 'changed': changed, 'unchanged': len(same), 'backup_dir': bdir if changed and not args.dry_run else None}, ensure_ascii=False, indent=1))


# ---------------------------------------------------------------- verify
def lua_table_ints(text, name):
    m = re.search(r'define\.%s = \{(.*?)\n\}' % re.escape(name), text, re.S)
    return m.group(1) if m else ''


def cmd_verify(args):
    report = {'ok': True, 'errors': [], 'tables': {}, 'lua': {}}
    err = report['errors'].append
    tabs = {}
    for t in TABLES:
        p = os.path.join(R, 'configs', t)
        with open(p, 'rb') as f:
            data = f.read()
        try:
            data.decode('gbk')
        except UnicodeDecodeError as ex:
            err('%s: not GBK: %s' % (t, ex))
        tb = read_table_bytes(data)
        n = len(tb['types'])
        bad = [r[0] for r in tb['rows'] if len(r) != n]
        ids = [int(r[0]) for r in tb['rows']]
        dup = len(ids) - len(set(ids))
        report['tables'][t] = {'cols': n, 'rows': len(tb['rows']), 'bad_tab_rows': len(bad), 'dup_ids': dup, 'sorted': ids == sorted(ids), 'sha256': hashlib.sha256(data).hexdigest()[:16]}
        if bad or dup or tb['names'] is None:
            err('%s: bad rows %d dup %d names %s' % (t, len(bad), dup, tb['names'] is not None))
        tabs[t] = tb
    st = {int(r[0]): r for r in tabs['SkillTemplate_V1.txt']['rows']}
    sd = {int(r[0]) for r in tabs['SkillData_V1.txt']['rows']}
    xf = {int(r[0]): int(r[1]) for r in tabs['XinFa_V1.txt']['rows']}
    # cấp kỹ năng 1..16 phải có trong SkillData
    miss = sum(1 for r in st.values() for k in range(58, 74) if r[k] not in (b'-1', b'0', b'') and int(r[k]) not in sd)
    report['tables']['SkillTemplate_V1.txt']['level_skill_ids_missing_in_SkillData'] = miss
    # xinfa của skill phải có trong XinFa và cùng phái
    bad_x = sum(1 for r in st.values() if r[11] not in (b'-1',) and (int(r[11]) not in xf or xf[int(r[11])] != int(r[2])))
    report['tables']['SkillTemplate_V1.txt']['skills_with_xinfa_not_matching'] = bad_x
    per = collections.Counter(int(r[1]) for r in tabs['XinFa_V1.txt']['rows'])
    report['tables']['XinFa_V1.txt']['per_menpai'] = dict(sorted(per.items()))
    if any(v != 8 for v in per.values()) or set(per) != {0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15}:
        err('XinFa per menpai not 8x15 CY')
    # define.lua + extensions
    with open(os.path.join(R, 'GameServer/lualib/define.lua'), encoding='utf-8', errors='surrogateescape') as f:
        d = f.read()
    attr = dict(re.findall(r'(MATTRIBUTE_\w+) = (\d+)', lua_table_ints(d, 'MENPAI_ATTRIBUTE')))
    attr = {k: int(v) for k, v in attr.items()}
    report['lua']['MENPAI_ATTRIBUTE'] = attr
    want = {'MATTRIBUTE_GUSU': 10, 'MATTRIBUTE_ERENGU': 15, 'MATTRIBUTE_MANTUOSHANZHUANG': 16}
    for k, v in want.items():
        if attr.get(k) != v:
            err('define %s = %s, want %d' % (k, attr.get(k), v))
    with open(os.path.join(R, 'GameServer/lualib/menpai_extensions.lua'), encoding='utf-8') as f:
        ext = f.read()
    ext_ids = [int(x) for x in re.findall(r'^\s*\[(\d+)\] = \{', ext, re.M)]
    report['lua']['extension_ids'] = ext_ids
    if ext_ids != [11, 12, 13, 14]:
        err('menpai_extensions ids %s' % ext_ids)
    checks = []
    def check_skill(label, sid, menpai):
        r = st.get(sid)
        ok = r is not None and (menpai is None or int(r[2]) == menpai)
        checks.append({'what': label, 'id': sid, 'menpai': menpai, 'found': r is not None, 'row_menpai': int(r[2]) if r else None, 'name': g(r[3]) if r else None, 'ok': ok})
        if not ok:
            err('%s skill %d (menpai %s) missing/mismatch' % (label, sid, menpai))
    def check_xinfa(label, xid, menpai):
        ok = xf.get(xid) == menpai
        checks.append({'what': label, 'id': xid, 'menpai': menpai, 'row_menpai': xf.get(xid), 'ok': ok})
        if not ok:
            err('%s xinfa %d (menpai %s) missing/mismatch' % (label, xid, menpai))
    for enum, mid in attr.items():
        if mid in (9, 16):
            continue
        for tname in ('MENPAI_7_SKILLS',):
            m = re.search(r'\[define\.MENPAI_ATTRIBUTE\.%s\]\s*=\s*\{([^}]*)\}' % enum, lua_table_ints(d, tname))
            if m:
                for sid in re.findall(r'\[(\d+)\]', m.group(1)):
                    check_skill('%s.%s' % (tname, enum), int(sid), mid)
        for tname, is_x in (('QINGGONG_SKILL', False), ('MENPAI_JINZHAN_YUANGONG_SKILL', False), ('MENPAI_7_XINFA', True), ('MENPAI_8_XINFA', True)):
            m = re.search(r'\[define\.MENPAI_ATTRIBUTE\.%s\]\s*=\s*(\d+)' % enum, lua_table_ints(d, tname))
            if m:
                (check_xinfa if is_x else check_skill)('%s.%s' % (tname, enum), int(m.group(1)), mid if not (tname == 'QINGGONG_SKILL' and mid == 8 and False) else mid)
    for mid, body in re.findall(r'^\s*\[(\d+)\] = \{(.*?)\n    \},', ext, re.S | re.M):
        mid = int(mid)
        for sid in re.findall(r'skills7 = \{([^}]*)\}', body)[0].split(','):
            check_skill('ext%d.skills7' % mid, int(sid), mid)
        for sid in re.findall(r'quick_skills = \{([^}]*)\}', body)[0].split(','):
            check_skill('ext%d.quick' % mid, int(sid), mid)
        check_skill('ext%d.qinggong' % mid, int(re.search(r'qinggong = (\d+)', body).group(1)), mid)
        check_xinfa('ext%d.xinfa7' % mid, int(re.search(r'xinfa7 = (\d+)', body).group(1)), mid)
        check_xinfa('ext%d.xinfa8' % mid, int(re.search(r'xinfa8 = (\d+)', body).group(1)), mid)
    for mid, body in re.findall(r'\t\[(\d+)\] = \{([^}]*)\}', lua_table_ints(d, 'SETTING_MENPAI_SKILLID')):
        for sid in body.split(','):
            if sid.strip():
                check_skill('SETTING_MENPAI_SKILLID.%s' % mid, int(sid), int(mid))
    # Exterior_Ride: cột 门派 không còn số GL 13..16 lệch? chỉ báo phân bố
    with open(os.path.join(R, 'configs/Exterior_Ride.txt'), 'rb') as f:
        rl = f.read().split(b'\n')
    mcol = rl[1].rstrip(b'\r').split(b'\t').index('门派'.encode('gbk'))
    report['tables']['Exterior_Ride.txt'] = {'menpai_values': dict(collections.Counter(l.rstrip(b'\r').split(b'\t')[mcol].decode() for l in rl[2:] if l.strip() and mcol < len(l.split(b'\t'))))}
    report['lua']['id_checks'] = checks
    report['lua']['id_checks_ok'] = sum(1 for c in checks if c['ok'])
    # luac -p
    lua_files = ['GameServer/lualib/define.lua', 'GameServer/lualib/menpai_registry.lua', 'GameServer/lualib/menpai_extensions.lua',
                 'GameServer/lualib/cy_four_training_config.lua', 'GameServer/lualib/jianzong_ranklist.lua', 'GameServer/services/scene/obj/human.lua']
    if args.staging:
        lua_files += [rel for _, rel in staged_files(args.staging) if rel.endswith('.lua')]
    bad = []
    for rel in sorted(set(lua_files)):
        r = subprocess.run(['luac5.4', '-p', os.path.join(R, rel)], capture_output=True, text=True)
        if r.returncode != 0:
            bad.append((rel, r.stderr.strip()[:200]))
    report['lua']['luac_checked'] = len(set(lua_files))
    report['lua']['luac_failed'] = bad
    if bad:
        err('luac: %s' % bad)
    # BaseValueTable
    with open(os.path.join(R, 'configs/BaseValueTable.ini'), 'rb') as f:
        secs = re.findall(rb'\[MENPAI(\d+)\]', f.read())
    secs = sorted(int(x) for x in secs)
    report['lua']['basevalue_sections'] = secs
    if secs != list(range(17)):
        err('BaseValueTable sections %s' % secs)
    # còn so sánh literal GL?
    left = subprocess.run(['grep', '-rnE', r'\b(nMenPai|MenPai|menpai|havemenpai)\s*(==|~=)\s*1[0-6]\b', '--include=*.lua', os.path.join(R, 'Game_2/Script')], capture_output=True, text=True).stdout
    report['lua']['script_literal_compares_left'] = len(left.splitlines())
    if args.staging:
        drift = []
        for src_path, rel in staged_files(args.staging):
            dst = os.path.join(R, rel)
            if not os.path.exists(dst) or sha(dst) != sha(src_path):
                drift.append(rel)
        report['staging_drift'] = drift
        if drift:
            err('staging differs from R: %s' % drift)
    report['ok'] = not report['errors']
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(report, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: v for k, v in report.items() if k != 'lua'} | {'lua': {k: v for k, v in report['lua'].items() if k != 'id_checks'}}, ensure_ascii=False, indent=1))
    sys.exit(0 if report['ok'] else 1)


# ---------------------------------------------------------------- Mongo (chỉ bản ghi test)
def provision():
    spec = importlib.util.spec_from_file_location('private_server', os.path.join(HERE, 'provision_test_wsl.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def char_projection(doc):
    a = doc.get('attrib') or {}
    return {'guid': a.get('guid'), 'menpai': a.get('menpai'), 'reputation': a.get('reputation'), 'level': a.get('level'),
            'xinfa_list': doc.get('xinfa_list'), 'skill_list': doc.get('skill_list'),
            'setting_skills': {k: v.get('data') for k, v in (doc.get('setting') or {}).items() if isinstance(v, dict) and v.get('type') == 1}}


def cmd_mongo(args, apply):
    with open(os.path.join(args.staging, 'plan.json'), encoding='utf-8') as f:
        plan = json.load(f)
    st_cy = {int(r[0]) for r in read_table(os.path.join(args.staging, 'configs/SkillTemplate_V1.txt'))['rows']}
    src = Sources(plan['base_rev'])
    res = Resolver(src, {int(k): v for k, v in plan['tables']['SkillTemplate_V1.txt']['colmap_cy_to_gl'].items()})
    server = provision()
    with server.database() as client:
        col = client['tlbb']['character']
        docs = list(col.find({'attrib.guid': GUID}, {'_id': 0}))
        if len(docs) != 1:
            sys.exit('expected one character %d, found %d' % (GUID, len(docs)))
        doc = docs[0]
        before = char_projection(doc)
        record = {'guid': GUID, 'before': before}
        menpai = before['menpai']
        new_menpai = MENPAI_MAP.get(menpai, menpai)
        new_skills, dropped = [], []
        for s in doc.get('skill_list') or []:
            cy = s if s in st_cy and src.gl_by_id['SkillTemplate_V1.txt'].get(s) is not None and src.gl_by_id['SkillTemplate_V1.txt'][s][3] == src.cy_by_id['SkillTemplate_V1.txt'][s][2] else res.skill(s)
            if cy is None:
                dropped.append(s)
            elif cy not in new_skills:
                new_skills.append(cy)
        new_xinfa = []
        xl = doc.get('xinfa_list')
        for x in (xl.values() if isinstance(xl, dict) else (xl or [])):
            if isinstance(x, dict) and 'm_nXinFaID' in x:
                cy = res.xinfa(int(x['m_nXinFaID']))
                if cy is not None:
                    new_xinfa.append({**x, 'm_nXinFaID': cy})
                else:
                    dropped.append(('xinfa', x['m_nXinFaID']))
        sets = {'attrib.menpai': new_menpai}
        if (doc.get('skill_list') or []) != new_skills:
            sets['skill_list'] = new_skills
        if xl:
            sets['xinfa_list'] = new_xinfa if not isinstance(xl, dict) else {str(i): v for i, v in enumerate(new_xinfa)}
        record.update({'planned_set': sets, 'dropped': dropped})
        if apply:
            if clients():
                sys.exit('client connected to 15733/15734; refuse')
            if os.path.exists(args.out):
                sys.exit('output exists: ' + args.out)
            with open(args.out, 'x', encoding='utf-8') as f:
                json.dump({'guid': GUID, 'backup_full_doc': doc, 'planned_set': sets}, f, ensure_ascii=False, indent=1, default=str)
            r = col.update_one({'attrib.guid': GUID}, {'$set': sets})
            record.update({'matched': r.matched_count, 'modified': r.modified_count, 'after': char_projection(col.find_one({'attrib.guid': GUID}, {'_id': 0}))})
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(record, f, ensure_ascii=False, indent=1, default=str)
        print(json.dumps(record, ensure_ascii=False, default=str))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('plan'); a.add_argument('--out', required=True); a.add_argument('--base-rev', default=BASE_REV)
    a = sub.add_parser('apply'); a.add_argument('--staging', required=True); a.add_argument('--dry-run', action='store_true')
    a = sub.add_parser('verify'); a.add_argument('--staging'); a.add_argument('--out')
    a = sub.add_parser('mongo-inspect'); a.add_argument('--staging', required=True); a.add_argument('--out', required=True)
    a = sub.add_parser('mongo-apply'); a.add_argument('--staging', required=True); a.add_argument('--out', required=True)
    args = ap.parse_args()
    if args.cmd == 'plan':
        cmd_plan(args)
    elif args.cmd == 'apply':
        cmd_apply(args)
    elif args.cmd == 'verify':
        cmd_verify(args)
    elif args.cmd == 'mongo-inspect':
        cmd_mongo(args, False)
    elif args.cmd == 'mongo-apply':
        cmd_mongo(args, True)


if __name__ == '__main__':
    main()
