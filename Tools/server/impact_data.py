#!/usr/bin/env python3
"""impact-data — bù các dòng StandardImpact còn thiếu bằng NGUỒN THẬT trước, suy luận sau.

Sau `server-impact` (suy R1/R2/R3, +1.686 dòng) và `impact-logic` (6 module), server riêng còn **3.840 ID impact
không có dòng** (4.955 ô SkillData), trong đó **716 ô thuộc kỹ năng 15 phái cấp 1–4** → chiêu "dùng được nhưng
không có tác dụng". Công cụ này tìm dòng THẬT cho các ID đó:

  1 name/name2  dòng SI server có `效果名称` = tên kỹ năng CY, hoặc bắt đầu bằng tên kỹ năng ("回天术（护盾）",
                "拘魂·地攻击", "净心观月(免疫)"), mà chính kỹ năng đó chưa dùng → ghép ô (theo thứ tự cột) với
                nhóm tên (theo thứ tự ID) rồi rải theo cấp. Bằng chứng: số trong tip CY khớp 参数值/总持续时间.
  2 hj         cặp HJ: client `CYHJ091026/Config/SkillData_V1.txt` + server tlbb15 — cùng tên kỹ năng, CÙNG PHÁI
                (ánh xạ phái HJ→CY dựng từ số tên kỹ năng trùng nhau), cùng cấp, cùng nhãn → ID impact HJ → dòng
                đã có trong SI server (SI server ⊇ tlbb15). Chạy SAU luật tên vì CY làm lại một số kỹ năng.
  3 series     cấp khác của chính ô đó đã có dòng → chép dòng cấp gần nhất.
  4 gmname     `GMVisible_Impact.txt` (client CY 3.71) cho tên thật của ID impact CY → tìm dòng SI cùng tên.
  5 gl         dòng GL (mốc GL_REV) cùng ID và tên chứa tên kỹ năng — nối tiếp R2 của server-impact.

Dòng sinh ra là **bản sao nguyên vẹn** của một dòng thật (chỉ đổi `Data_Index`, và `效果名称` khi GMVisible cho tên
CY khác) → không bịa số. Ô không có nguồn thật vẫn để trống và ghi lý do trong `impact_data.tsv`.

  impact_data.py plan   --out <dir>                  dựng <dir>/configs/StandardImpact.txt + plan.json + impact_data.tsv (không chạm R)
  impact_data.py apply  --staging <dir> [--dry-run]  chép vào R, sao lưu R/backups/impact-data-<UTC>/

17/09 (agent `impact-data-2`, đặc tả mục 8) — hai lệnh nữa, đều đọc bảng SỐNG của R (không qua `git show`,
vì trong buổi có agent khác đang sửa bảng mà chưa commit):

  impact_data.py interp --base 6ca25a8 --tsv <impact_data_final.tsv> [--scale-tsv <impact_scale.tsv>] --out <dir>
        nội suy/ngoại suy TUYẾN TÍNH theo cấp cho các dòng luật `series` (chúng chép nguyên dòng của cấp gần
        nhất nên chiêu không mạnh lên theo cấp). Chỉ đổi `参数值` + `总持续时间` của tham số ĐANG dùng, chỉ với
        nhãn trong INTERP_LABELS, khi ô đó có ≥ 2 mốc thật ở các cấp khác. KHÔNG đụng `修正步长` (bước theo
        tu luyện, và `cfghelper:read_std_impact` còn không đọc cột đó).
  impact_data.py p1fill --base 6ca25a8 --out <dir>
        bù ô impact cấp 1–4 còn thiếu bằng bảng khai báo tay P1_CELLS (dòng mẫu THẬT + điều kiện tự kiểm,
        khuôn của `trap_impacts.py`); P1_DECLINED ghi các nhóm đã xét và cố ý không dựng.
  impact_data.py verify [--staging <dir>] [--out j]  GBK/tab/ID tăng, dòng mới: logic đã đăng ký (hoặc buff rỗng
                                                     KHÔNG bị lật), SE có ở client CY hoặc −1, mọi ID con có dòng, staging = R

Chạy trong WSL TLBB bằng root: `python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/impact_data.py <lệnh>`.
Nguồn chỉ đọc: R tại HEAD, GL tại GL_REV, client CY 3.71, client CYHJ091026. Đặc tả: Docs/specs/server/impact-data_vi.md.
"""
import argparse
import collections
import datetime
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table_bytes, read_table, write_table, g, sha  # noqa: E402

R = '/home/ubuntu/cys-test-20260913'
GL_REV = '995c2df'
CY_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
HJ_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/CYHJ091026/Config'
SI = 'configs/StandardImpact.txt'
GS = 'GameServer'
MARK = 'impact-data'

ST_MENPAI, ST_NAME, ST_PET_IMPACT = 2, 3, 30
ST_LEVELS = list(range(58, 74))
SD_TIP, SD_LOGIC = 3, 5
EQUIP_IMPACT_COL = 19
SI_NAME, SI_LOGIC, SI_OVERTIME, SI_SE = 1, 2, 4, 5
SI_PARAM0 = 27            # 参数1说明; bộ ba (说明, 值, 步长) × 16
SI_PARAM_N = 16
SI_DURATION = 20          # 总持续时间(毫秒)

MENPAI = {0: '少林', 1: '明教', 2: '丐帮', 3: '武当', 4: '峨嵋', 5: '星宿', 6: '大理', 7: '天山', 8: '逍遥',
          10: '慕容', 11: '唐门', 12: '鬼谷', 13: '桃花岛', 14: '绝情谷', 15: '恶人谷'}

IMPACT_WORDS = ('效果', 'buff', 'BUFF', 'Buff')
EXCLUDE_WORDS = ('几率', '概率', '集合', '陷阱', '次数', '数目', '上限', '半径', '时间', '距离', '类型', '百分', '%', '权重',
                 '层数', '脚本', '冷却', '范围', '说明', '宽度', '步长', '技能ID', '阈值', '倍率', '系数')
COLOR_RE = re.compile(r'#c[0-9A-Fa-f]{6}|#[rRWGYBnbe]')
NUM_RE = re.compile(r'\d+(?:\.\d+)?')
AB_RE = re.compile(r'\{A:(-?\d+(?:\.\d+)?)\s+B:(-?\d+(?:\.\d+)?)\}')


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, **kw)


def git_show(rev, rel):
    return subprocess.run(['git', '-C', R, 'show', '%s:%s' % (rev, rel)], capture_output=True, check=True).stdout


def head_sha():
    return subprocess.run(['git', '-C', R, 'rev-parse', '--short', 'HEAD'], capture_output=True, check=True).stdout.decode().strip()


def ival(b):
    try:
        return int(b)
    except (ValueError, TypeError):
        return None


def is_impact_label(d):
    return any(w in d for w in IMPACT_WORDS) and not any(w in d for w in EXCLUDE_WORDS)


def clean_tip(b):
    return COLOR_RE.sub('', g(b)).replace('\\n', ' ')


def tip_numbers(tip):
    """mọi con số trong tip (gồm cả {A:x B:y}) — dùng làm bằng chứng căn dòng mẫu."""
    out = set()
    for a, b in AB_RE.findall(tip):
        for v in (a, b):
            f = float(v)
            out.add(int(f) if f == int(f) else f)
    for m in NUM_RE.findall(AB_RE.sub(' ', tip)):
        f = float(m)
        out.add(int(f) if f == int(f) else f)
    return out


# ---------------------------------------------------------------- nguồn
class Src:
    def __init__(self, base='HEAD', live_tables=False):
        """live_tables=True: đọc SkillData/SkillTemplate từ CÂY LÀM VIỆC của R thay vì `git show`.
        Cần khi trong buổi có agent khác đang sửa bảng mà chưa commit (trap-recollide 17/09 sửa
        `SkillData_V1.txt`) — `git show` sẽ trả bản cũ và ghép ô sai."""
        self.base = base
        self.rev = head_sha()
        self.si = read_table_bytes(git_show(base, SI))
        self.si_by = {int(r[0]): r for r in self.si['rows']}
        self.ncol = len(self.si['types'])

        def _tbl(rel):
            if live_tables:
                with open(os.path.join(R, rel), 'rb') as f:
                    return read_table_bytes(f.read())
            return read_table_bytes(git_show(base, rel))

        self.sd = _tbl('configs/SkillData_V1.txt')
        self.sd_by = {int(r[0]): r for r in self.sd['rows']}
        self.st = _tbl('configs/SkillTemplate_V1.txt')
        self.eb = _tbl('configs/EquipBase.txt')
        self.param_pos = [i for i, n in enumerate(self.sd['names']) if g(n) == '参数说明']
        self.gl_si = {int(r[0]): r for r in read_table_bytes(git_show(GL_REV, SI))['rows']}
        self.se_cy = set(int(r[0]) for r in read_table(os.path.join(CY_DIR, 'ImpactSEData_V1.txt'))['rows'])
        # tên impact thật của CY (GMVisible_Impact: cột 1 = Data_Index, cột 3 = tên)
        self.cy_name = {}
        for r in read_table(os.path.join(CY_DIR, 'GMVisible_Impact.txt'))['rows']:
            i = ival(r[1])
            if i is not None and i not in self.cy_name:
                self.cy_name[i] = r[3]
        # chỉ mục theo tên trong SI server
        self.si_by_name = collections.defaultdict(list)
        for r in self.si['rows']:
            self.si_by_name[g(r[SI_NAME]).strip()].append(int(r[0]))
        # client HJ (cặp với tlbb15)
        self.hj_sd = read_table(os.path.join(HJ_DIR, 'SkillData_V1.txt'))
        self.hj_sd_by = {int(r[0]): r for r in self.hj_sd['rows']}
        self.hj_st = read_table(os.path.join(HJ_DIR, 'SkillTemplate_V1.txt'))
        self.hj_pp = list(range(24, 48, 2))          # bố cục GL: 12 bộ (参数说明, 参数值) từ cột 24
        self.hj_by_name = collections.defaultdict(list)
        for r in self.hj_st['rows']:
            self.hj_by_name[g(r[ST_NAME]).strip()].append(int(r[0]))
        self.hj_data_of, self.hj_menpai = {}, {}
        for r in self.hj_st['rows']:
            self.hj_menpai[int(r[0])] = ival(r[ST_MENPAI])
            for k, c in enumerate(ST_LEVELS):
                v = ival(r[c]) if c < len(r) else None
                if v is not None and v >= 0:
                    self.hj_data_of[(int(r[0]), k + 1)] = v
        # số phái HJ/GL ≠ số phái CY (CS3b): dựng ánh xạ theo số tên kỹ năng trùng nhau
        cy_names, hj_names = collections.defaultdict(set), collections.defaultdict(set)
        for r in self.st['rows']:
            m = ival(r[ST_MENPAI])
            if m is not None and m >= 0:
                cy_names[m].add(g(r[ST_NAME]).strip())
        for r in self.hj_st['rows']:
            m = ival(r[ST_MENPAI])
            if m is not None and m >= 0:
                hj_names[m].add(g(r[ST_NAME]).strip())
        self.hj2cy = {}
        for m, names in hj_names.items():
            best = max(((len(names & v), c) for c, v in cy_names.items()), default=(0, None))
            if best[0] >= 5:
                self.hj2cy[m] = best[1]
        self.lua = {}

    def lua_head(self, rel):
        if rel not in self.lua:
            self.lua[rel] = git_show(self.base, GS + '/' + rel).decode('utf-8')
        return self.lua[rel]

    def cells(self, sid):
        """[(pos, nhãn, impact_id)] của một SkillData."""
        r = self.sd_by.get(sid)
        if r is None:
            return []
        out = []
        for p in self.param_pos:
            if p + 1 >= len(r):
                continue
            d = g(r[p]).strip()
            v = ival(r[p + 1])
            if d and v is not None and v >= 0 and is_impact_label(d):
                out.append((p, d, v))
        return out

    def tip(self, sid):
        r = self.sd_by.get(sid)
        return clean_tip(r[SD_TIP]) if r is not None else ''


def collect_refs(src):
    """[(nguồn, id_nguồn, vị trí, nhãn, impact_id)] — như server_impact.collect_refs."""
    refs = []
    for r in src.sd['rows']:
        sid = int(r[0])
        for p, d, v in src.cells(sid):
            refs.append(('SkillData', sid, p, d, v))
    for r in src.st['rows']:
        v = ival(r[ST_PET_IMPACT]) if ST_PET_IMPACT < len(r) else None
        if v is not None and v > 0:
            refs.append(('SkillTemplate.珍兽技能产生的效果ID', int(r[0]), ST_PET_IMPACT, '珍兽技能产生的效果ID', v))
    for r in src.eb['rows']:
        v = ival(r[EQUIP_IMPACT_COL]) if EQUIP_IMPACT_COL < len(r) else None
        if v is not None and v >= 0:
            refs.append(('EquipBase.19', int(r[0]), EQUIP_IMPACT_COL, 'EquipBase.19', v))
    return refs


# ---------------------------------------------------------------- nhóm ô thiếu theo kỹ năng
class Group:
    """một ô tham số của một kỹ năng, gồm ID impact theo từng cấp."""
    __slots__ = ('tid', 'skill', 'menpai', 'pos', 'label', 'levels', 'used', 'have')

    def __init__(self, tid, skill, menpai, pos, label):
        self.tid, self.skill, self.menpai, self.pos, self.label = tid, skill, menpai, pos, label
        self.levels = {}        # cấp -> impact id (thiếu dòng)
        self.have = {}          # cấp -> impact id (đã có dòng)


def build_groups(src, missing_ids):
    groups, owner, used_by_tpl = [], {}, {}
    for r in src.st['rows']:
        tid = int(r[0])
        mp = ival(r[ST_MENPAI])
        name = g(r[ST_NAME]).strip()
        per = {}
        used = set()
        for k, c in enumerate(ST_LEVELS):
            sid = ival(r[c]) if c < len(r) else None
            if sid is None or sid < 0 or sid not in src.sd_by:
                continue
            for pos, lab, v in src.cells(sid):
                used.add(v)
                per.setdefault((pos, lab), Group(tid, name, mp, pos, lab))
                (per[(pos, lab)].levels if v in missing_ids else per[(pos, lab)].have)[k + 1] = v
        used_by_tpl[tid] = used
        for gr in per.values():
            if gr.levels:
                gr.used = used
                groups.append(gr)
    # mỗi ID thiếu chỉ do MỘT nhóm bù (nhóm có phái thấp cấp nhất được ưu tiên)
    groups.sort(key=lambda gr: (0 if (gr.menpai is not None and 0 <= gr.menpai <= 15 and gr.menpai != 9) else 1,
                                min(gr.levels), gr.tid, gr.pos))
    for gr in groups:
        for lv, v in sorted(gr.levels.items()):
            owner.setdefault(v, (gr, lv))
    return groups, owner


# ---------------------------------------------------------------- các luật
class Deriver:
    def __init__(self, src, missing_ids):
        self.src = src
        self.missing = missing_ids
        self.new = {}            # id -> (row, info)
        self.taken = set()       # ID dòng mẫu đã dùng (tránh hai ID thiếu chép cùng một dòng của cùng kỹ năng)
        self.notes = []

    # --- tiện ích
    def copy_row(self, donor_id, new_id, cy_name=None):
        d = self.src.si_by[donor_id]
        row = list(d) + [b''] * max(0, self.src.ncol - len(d))
        row = row[:self.src.ncol]
        row[0] = str(new_id).encode('ascii')
        if cy_name:
            row[SI_NAME] = cy_name
        se = ival(row[SI_SE])
        se_fix = False
        if se is not None and se >= 0 and se not in self.src.se_cy:
            row[SI_SE] = b'-1'
            se_fix = True
        return row, se_fix

    def row_numbers(self, donor_id):
        d = self.src.si_by[donor_id]
        out = set()
        v = ival(d[SI_DURATION])
        if v:
            out.add(v // 1000)
            out.add(v)
        for k in range(SI_PARAM_N):
            v = ival(d[SI_PARAM0 + 3 * k + 1])
            if v is not None and v not in (0, -1):
                out.add(v)
        return out

    # --- N1: cặp HJ (client CYHJ091026 + tlbb15)
    def rule_hj(self, gr, lv, iid):
        src = self.src
        for tid in src.hj_by_name.get(gr.skill, []):
            hmp = src.hj_menpai.get(tid)
            if hmp is not None and hmp >= 0 and src.hj2cy.get(hmp) != gr.menpai:
                continue                       # kỹ năng trùng tên nhưng khác phái (số phái HJ ≠ CY)
            hsid = src.hj_data_of.get((tid, lv))
            if hsid is None or hsid not in src.hj_sd_by:
                continue
            hr = src.hj_sd_by[hsid]
            slots = [p for p in src.hj_pp if p + 1 < len(hr) and g(hr[p]).strip() == gr.label]
            if not slots:
                continue
            for p in slots:
                hv = ival(hr[p + 1])
                if hv is None or hv < 0 or hv not in src.si_by or hv in gr.used or hv in self.taken:
                    continue
                return hv, 'HJ template %d, SkillData %d, cùng nhãn' % (tid, hsid)
        return None, None

    # --- N2: nhóm dòng SI có 效果名称 = tên kỹ năng (hoặc bắt đầu bằng tên kỹ năng: "回天术（护盾）", "拘魂·地攻击")
    def name_groups(self, skill, used):
        """[(tên, [ID…])] còn rảnh, xếp theo ID nhỏ nhất; tên chính xác đứng trước."""
        bases = [skill]
        for sep in ('·', '（', '('):
            if sep in skill:
                b = skill.split(sep)[0].strip()
                if len(b) >= 2 and b not in bases:
                    bases.append(b)
        out, seen = [], set()
        for b in bases:
            for nm, ids in self.src.si_by_name.items():
                if nm in seen or not nm.startswith(b):
                    continue
                free = [i for i in sorted(ids) if i not in used and i not in self.taken and i not in self.missing]
                if free:
                    seen.add(nm)
                    out.append((nm, free, 0 if nm == skill else 1))
        out.sort(key=lambda x: (x[2], min(x[1])))
        return [(nm, ids) for nm, ids, _ in out]

    # --- N3: tên impact CY (GMVisible_Impact)
    def rule_gmname(self, gr, iid):
        nm = self.src.cy_name.get(iid)
        if not nm:
            return None, None
        cands = [i for i in sorted(self.src.si_by_name.get(g(nm).strip(), []))
                 if i not in gr.used and i not in self.taken and i not in self.missing]
        if cands:
            return cands[0], 'GMVisible_Impact: tên CY "%s"' % g(nm).strip()
        return None, None

    # --- N4: dòng GL cùng ID, tên chứa tên kỹ năng
    def rule_gl(self, gr, iid):
        r = self.src.gl_si.get(iid)
        if r is None:
            return None, None
        nm = g(r[SI_NAME]).strip()
        if gr.skill and (nm == gr.skill or gr.skill in nm or nm in gr.skill):
            return r, 'dòng GL %s cùng ID, tên "%s"' % (GL_REV, nm)
        return None, None

    def tip_nums_of(self, tid):
        for r in self.src.st['rows']:
            if int(r[0]) == tid:
                for c in ST_LEVELS:
                    sid = ival(r[c]) if c < len(r) else None
                    if sid is not None and sid >= 0 and sid in self.src.sd_by:
                        return tip_numbers(self.src.tip(sid))
                break
        return set()

    def derive(self, groups, owner):
        src = self.src
        per_tpl = collections.OrderedDict()
        for gr in groups:
            per_tpl.setdefault(gr.tid, []).append(gr)
        for tid, grs in per_tpl.items():
            tip_nums = self.tip_nums_of(tid)
            grs = sorted(grs, key=lambda x: x.pos)
            want = {}                                   # group -> [(cấp, id)] còn thiếu, ID duy nhất theo thứ tự cấp
            for gr in grs:
                mine, seen = [], set()
                for lv, v in sorted(gr.levels.items()):
                    if owner.get(v, (None,))[0] is gr and v not in seen:
                        seen.add(v)
                        mine.append((lv, v))
                if mine:
                    want[gr] = mine

            # 1) nhóm tên: ghép ô còn thiếu (theo thứ tự cột) với nhóm tên (theo thứ tự ID).
            #    Ưu tiên trước cặp HJ: dòng mang ĐÚNG tên kỹ năng ràng buộc nghĩa chặt hơn, còn CY có kỹ năng
            #    bị làm lại so với HJ (vd 慕容 净心观月: CY = giải/miễn thất minh, HJ = 天魂效果 hệ nguyên tố).
            need = [gr for gr in grs if gr in want and any(v not in self.new for _, v in want[gr])]
            if need:
                ng = self.name_groups(need[0].skill, need[0].used)
                for gr, (nm, pool) in zip(need, ng):
                    rest = [(lv, v) for lv, v in want[gr] if v not in self.new]
                    if not rest:
                        continue
                    seq = len(pool) < max(l for l, _ in rest)
                    for idx, (lv, v) in enumerate(rest):
                        j = idx if seq else lv - 1
                        clamp = j >= len(pool)
                        dn = pool[min(j, len(pool) - 1)]
                        if dn in self.taken:
                            free = [x for x in pool if x not in self.taken]
                            if not free:
                                continue
                            dn, clamp = free[0], True
                        self.emit(v, dn, gr, lv, 'name' if nm == gr.skill else 'name2',
                                  'SI có %d dòng 效果名称 "%s" (kỹ năng "%s"), chép theo thứ tự cấp%s'
                                  % (len(pool), nm, gr.skill, ' [kẹp cấp cao]' if clamp else ''), tip_nums, weak=clamp)

            # 2) cặp HJ cho ô còn lại (căn cấp tuyệt đối; đã lọc theo phái qua ánh xạ HJ→CY)
            for gr, mine in want.items():
                for lv, v in mine:
                    if v in self.new:
                        continue
                    dn, why = self.rule_hj(gr, lv, v)
                    if dn is not None:
                        self.emit(v, dn, gr, lv, 'hj', why, tip_nums)

            # 3) chuỗi cấp trong cùng ô: cấp khác của CHÍNH ô này đã có dòng → chép dòng gần cấp nhất
            for gr, mine in want.items():
                pool = dict(gr.have)
                pool.update({lv: v for lv, v in mine if v in self.new})
                if not pool:
                    continue
                for lv, v in mine:
                    if v in self.new:
                        continue
                    src_lv = min(pool, key=lambda x: (abs(x - lv), x))
                    dn = pool[src_lv]
                    row = (self.new[dn][0] if dn in self.new else None)
                    if row is None and dn not in src.si_by:
                        continue
                    self.emit_from(v, dn, row, gr, lv, 'series',
                                   'cùng ô "%s" của kỹ năng ở cấp %d (ID %d), lệch %d cấp'
                                   % (gr.label, src_lv, dn, abs(src_lv - lv)), tip_nums,
                                   weak=abs(src_lv - lv) > 2)

            # 4) tên impact CY (GMVisible_Impact) rồi 5) dòng GL cùng ID
            for gr, mine in want.items():
                for lv, v in mine:
                    if v in self.new:
                        continue
                    dn, why = self.rule_gmname(gr, v)
                    if dn is not None:
                        self.emit(v, dn, gr, lv, 'gmname', why, tip_nums)
            for gr, mine in want.items():
                for lv, v in mine:
                    if v in self.new:
                        continue
                    glr, why = self.rule_gl(gr, v)
                    if glr is None:
                        continue
                    row = list(glr) + [b''] * max(0, src.ncol - len(glr))
                    row = row[:src.ncol]
                    row[0] = str(v).encode('ascii')
                    se = ival(row[SI_SE])
                    if se is not None and se >= 0 and se not in src.se_cy:
                        row[SI_SE] = b'-1'
                    self.new[v] = (row, {'rule': 'gl', 'donor': None, 'why': why, 'skill': gr.skill,
                                         'menpai': gr.menpai, 'tid': gr.tid, 'level': lv, 'label': gr.label,
                                         'confidence': 'trung bình', 'logic': ival(row[SI_LOGIC]),
                                         'name': g(row[SI_NAME]).strip(), 'se_reset': False, 'tip_match': []})

    def emit_from(self, new_id, donor_id, donor_row, gr, lv, rule, why, tip_nums, weak=False):
        """chép từ một dòng đã có (SI) hoặc một dòng vừa sinh (donor_row)."""
        if donor_row is None:
            self.emit(new_id, donor_id, gr, lv, rule, why, tip_nums, weak=weak)
            return
        row = list(donor_row)
        row[0] = str(new_id).encode('ascii')
        cy = self.src.cy_name.get(new_id)
        if cy:
            row[SI_NAME] = cy
        self.new[new_id] = (row, {'rule': rule, 'donor': donor_id, 'why': why, 'skill': gr.skill, 'menpai': gr.menpai,
                                  'tid': gr.tid, 'level': lv, 'label': gr.label,
                                  'confidence': 'thấp' if weak else 'trung bình',
                                  'logic': ival(row[SI_LOGIC]), 'name': g(row[SI_NAME]).strip(),
                                  'se_reset': False, 'tip_match': []})

    @staticmethod
    def name_related(skill, donor_name):
        if not skill or not donor_name:
            return False
        base = skill.split('·')[0].split('（')[0].split('(')[0].strip()
        return skill in donor_name or donor_name in skill or (len(base) >= 2 and base in donor_name)

    def emit(self, new_id, donor_id, gr, lv, rule, why, tip_nums, weak=False):
        cy = self.src.cy_name.get(new_id)
        row, se_fix = self.copy_row(donor_id, new_id, cy)
        self.taken.add(donor_id)
        match = sorted(tip_nums & self.row_numbers(donor_id)) if tip_nums else []
        # bằng chứng: tên dòng mẫu dính tên kỹ năng, hoặc một con số trong tip CY trùng số của dòng mẫu
        ev = bool(match) or self.name_related(gr.skill, g(self.src.si_by[donor_id][SI_NAME]).strip())
        conf = 'thấp' if weak else ('cao' if ev else 'trung bình')
        self.new[new_id] = (row, {'rule': rule, 'donor': donor_id, 'why': why, 'skill': gr.skill, 'menpai': gr.menpai,
                                  'tid': gr.tid, 'level': lv, 'label': gr.label, 'confidence': conf,
                                  'logic': ival(row[SI_LOGIC]), 'name': g(row[SI_NAME]).strip(),
                                  'se_reset': se_fix, 'tip_match': match[:6]})


# ---------------------------------------------------------------- báo cáo phái
_LOGIC_RE = re.compile(r'\[(\d+)\]\s*=\s*"scene\.skill\.impact_logic\.')


def installed_logics(src):
    return {int(m.group(1)) for m in _LOGIC_RE.finditer(src.lua_head('lualib/impactenginer.lua'))}


def known_labels(src):
    txt = src.lua_head('lualib/cfghelper.lua')
    a = txt.index('function cfghelper:read_skill_data()')
    b = txt.index('\nfunction cfghelper:', a + 10)
    body = txt[a:b]
    labels = set(re.findall(r'desc == "([^"]*)"', body))
    for fmt in re.findall(r'string\.format\("([^"]*%d[^"]*)", idx\)', body):
        for i in range(0, 12):
            labels.add(fmt.replace('%d', str(i)))
    return labels


def faction_report(src, der):
    logics = installed_logics(src)
    skill_logics = set(int(m.group(1)) for m in re.finditer(r'\[(\d+)\]\s*=\s*"scene\.skill\.', src.lua_head('lualib/skillenginer.lua')))
    known = known_labels(src)
    tot = collections.Counter()
    per = collections.defaultdict(collections.Counter)
    items = []

    def state(imps, slg, after):
        if not imps:
            return 'no_impact_param', []
        bad = []
        for d, v in imps:
            rr = src.si_by.get(v) or (der.new[v][0] if after and v in der.new else None)
            if rr is None:
                bad.append('missing:%d' % v)
                continue
            lg = ival(rr[SI_LOGIC])
            if lg is not None and lg < 8000 and lg not in logics:
                bad.append('logic%d:%d' % (lg, v))
                continue
            if d not in known and slg in skill_logics:
                bad.append('label:%s' % d)
        return ('ok' if not bad else ('partial' if len(bad) < len(imps) else 'none')), bad

    for r in src.st['rows']:
        mp = ival(r[ST_MENPAI])
        if mp is None or mp < 0 or mp > 15 or mp == 9:
            continue
        seen = set()
        for k in range(4):
            sid = ival(r[ST_LEVELS[k]])
            if sid is None or sid < 0 or sid in seen or sid not in src.sd_by:
                continue
            seen.add(sid)
            row = src.sd_by[sid]
            slg = ival(row[SD_LOGIC])
            imps = [(d, v) for _, d, v in src.cells(sid)]
            (b, bb), (a, ab) = state(imps, slg, False), state(imps, slg, True)
            tot['before_' + b] += 1
            tot['after_' + a] += 1
            per[mp]['before_' + b] += 1
            per[mp]['after_' + a] += 1
            if b != 'ok' or a != 'ok':
                items.append({'menpai': mp, 'tid': int(r[0]), 'name': g(r[ST_NAME]), 'level': k + 1, 'skill_data': sid,
                              'before': b, 'after': a, 'why_before': bb, 'why_after': ab})
    return {'totals': dict(tot), 'by_menpai': {str(k): dict(v) for k, v in sorted(per.items())}, 'items': items}


# ---------------------------------------------------------------- sửa số theo tip CY
# Dòng bù là bản sao của bản HJ; CY cân bằng lại nên số thường lệch. Ở đây chỉ **chỉnh độ lớn** của tham số
# ĐANG dùng (giá trị ≠ 0/−1) khi tip CY của đúng SkillData đó cho **một** con số cho đúng ý nghĩa ấy.
# Không bật tham số mới, không đổi logic/nhãn/đích → cấu trúc dòng giữ nguyên như dòng mẫu thật.
CLAUSE_RE = re.compile(r'[，。；、,;]|#r')
DUR_RE = re.compile(r'持续(?:时间[:：])?\s*([0-9]+(?:\.[0-9]+)?)\s*(秒|分钟)')
ATTACK_WORD = [('外功', '物理攻击+'), ('内功', '魔法攻击+'), ('冰', '冰系攻击'), ('火', '火系攻击'),
               ('玄', '电系攻击'), ('毒', '毒系攻击')]
# nhãn mang ĐỘ LỚN (khác với nhãn mang ID/tập hợp/script) — dùng để chọn mẫu đo "số khớp tip"
MAG_WORDS = ('攻击+', '系攻击', '防御+', '命中', '闪避', '会心', '修正率', '增强', '百分', '千分', '免疫率', '吸收率',
             '反射率', '上限', '伤害数值', '速度修正', 'HP修改', 'MP修改', '回复', '扫描半径', '怒气增长', '修正%')

# (nhãn trong dòng, regex trên toàn tip, nhóm bắt số, hệ số)
PCT_RULES = [
    ('怒气增长修正', r'(?:获得)?怒气(?:的)?(?:增长|增加|恢复)?(?:速度)?(?:增加|提高|提升)\s*(\d+)\s*%', 1),
    ('怒气增长率修正', r'(?:获得)?怒气(?:的)?(?:增长|增加|恢复)?(?:速度)?(?:增加|提高|提升)\s*(\d+)\s*%', 1),
    ('命中+', r'命中\s*(\d+)\s*点', 1),
    ('基础伤害增强', r'(?:造成的|对目标造成的)?伤害(?:提高|提升|增加)\s*(\d+)\s*%', 1),
    ('免疫率', r'(?:降低|减少)(?:自己|自身)?(?:及[^，。；]{0,12})?受到(?:的)?伤害(?:的)?\s*(\d+)\s*%', 1),
    ('伤害吸收率', r'吸收\s*(\d+)\s*%', 1),
    ('反射率', r'攻击者(?:受到|承受)\s*(\d+)\s*%', 1),
    ('反射伤害上限', r'(?:反弹|返还)[^，。；]{0,16}?最高为\s*(\d+)', 1),
    ('移动速度修正%（0为无效）', r'移动速度(?:降低|减少)\s*(\d+)\s*%', -1),
    # `<X>修正率` đi qua util.add_rate → human_attrib: base = ceil(base * (100 + rate) / 100) ⇒ đơn vị là PHẦN TRĂM
    ('命中修正率', r'命中(?:率)?(?:增加|提高|提升)\s*(\d+)\s*%', 1),
    ('闪避修正率', r'闪避(?:率)?(?:增加|提高|提升)\s*(\d+)\s*%', 1),
    ('会心修正率', r'会心(?:一击)?(?:攻击)?(?:增加|提高|提升)\s*(\d+)\s*%', 1),
    ('会心攻击修正率', r'会心(?:一击)?(?:攻击)?(?:增加|提高|提升)\s*(\d+)\s*%', 1),
    ('物理攻击修正率', r'外功攻击(?:增加|提高|提升)\s*(\d+)\s*%', 1),
    ('魔法攻击修正率', r'内功攻击(?:增加|提高|提升)\s*(\d+)\s*%', 1),
]

# thời lượng theo LOẠI hiệu ứng: chỉ dùng khi chính dòng đó mang hiệu ứng ấy (tên dòng hoặc tham số nói rõ),
# nên vượt được ngưỡng 1.000 ms mà vẫn có bằng chứng
CONTROL_WORDS = ('定身', '麻痹', '昏迷', '眩晕', '封穴', '失明', '沉默', '昏睡', '围困', '散功', '减速')


def tip_effect_duration_ms(row, tip):
    name = g(row[SI_NAME])
    labs = ' '.join(g(row[SI_PARAM0 + 3 * k]) for k in range(SI_PARAM_N))
    cands = []
    for w in CONTROL_WORDS:
        if w in name:
            cands.append(w)
    if '隐身级别修正' in labs or '隐身' in name:
        cands.append('隐身')
    for w in cands:
        vals = set()
        for n, unit in re.findall(w + r'[^，。；]{0,8}?(?:持续)?\s*(\d+(?:\.\d+)?)\s*(秒|分钟)', tip):
            vals.add(int(round(float(n) * (60000 if unit == '分钟' else 1000))))
        for n, unit in re.findall(r'(?:持续)\s*(\d+(?:\.\d+)?)\s*(秒|分钟)[^，。；]{0,6}?' + w, tip):
            vals.add(int(round(float(n) * (60000 if unit == '分钟' else 1000))))
        if len(vals) == 1:
            return vals.pop(), w
    return None, None


def tip_duration_ms(tip):
    """chỉ nhận khi tip có ĐÚNG MỘT thời lượng 持续 (tránh nhầm với thời lượng của hiệu ứng con)."""
    vals = set()
    for n, unit in DUR_RE.findall(tip):
        vals.add(int(round(float(n) * (60000 if unit == '分钟' else 1000))))
    return vals.pop() if len(vals) == 1 else None


def tip_attack_ab(tip):
    """{nhãn: (A, B)} từ '…内功攻击{A:x B:y}' — quy ước tip CY: A = 参数值, B = 修正步长 của cấp đó.
    Mệnh đề chỉ nói '伤害' chung (vd '每2秒对目标产生{A:10 B:1}点伤害') → nhãn 伤害数值/伤害数值+."""
    out = {}
    for cl in CLAUSE_RE.split(tip):
        m = AB_RE.search(cl)
        if not m:
            continue
        head, ab = cl[:m.start()], (m.group(1), m.group(2))
        hit = False
        for word, label in ATTACK_WORD:
            if word + '攻击' in head or word + '系攻击' in head:
                out.setdefault(label, ab)
                hit = True
        if not hit and ('伤害' in cl or '攻击' in cl):
            out.setdefault('伤害数值', ab)
            out.setdefault('伤害数值+', ab)
    return out


def fix_row(row, tip):
    """trả [(nhãn, cũ, mới, vì sao)] và sửa row tại chỗ."""
    ch = []
    ab = tip_attack_ab(tip)
    for k in range(SI_PARAM_N):
        di, vi, si_ = SI_PARAM0 + 3 * k, SI_PARAM0 + 3 * k + 1, SI_PARAM0 + 3 * k + 2
        lab = g(row[di]).strip()
        cur = ival(row[vi])
        if not lab or cur is None or cur in (0, -1):
            continue
        if lab in ab:
            a, b = ab[lab]
            if g(row[vi]) != a:
                ch.append((lab, g(row[vi]), a, 'tip {A:%s B:%s}' % (a, b)))
                row[vi] = a.encode('ascii')
                row[si_] = b.encode('ascii')
            continue
        for label, pat, sign in PCT_RULES:
            if lab != label:
                continue
            ms = set(re.findall(pat, tip))
            if len(ms) != 1:
                break
            new = int(ms.pop()) * sign
            if new != cur:
                ch.append((lab, str(cur), str(new), 'tip "%s"' % pat[:28]))
                row[vi] = str(new).encode('ascii')
            break
    cur = ival(row[SI_DURATION])
    de, word = tip_effect_duration_ms(row, tip)
    if de is not None and cur is not None and cur > 0 and cur != de:
        # dòng mang đúng hiệu ứng mà tip nêu thời lượng (tên dòng/nhãn nói rõ) → tin được kể cả khi < 1 s
        ch.append(('总持续时间(毫秒)', str(cur), str(de), 'tip "%s…秒"' % word))
        row[SI_DURATION] = str(de).encode('ascii')
        return ch
    d = tip_duration_ms(tip)
    if d is not None:
        # chỉ chỉnh khi dòng mẫu vốn đã là hiệu ứng có thời lượng thật (≥ 1 s); giá trị 1–999 ms thường là
        # cờ/nhịp của logic chứ không phải thời lượng buff → đụng vào sẽ đổi hành vi
        if cur is not None and cur >= 1000 and cur != d:
            ch.append(('总持续时间(毫秒)', str(cur), str(d), 'tip 持续'))
            row[SI_DURATION] = str(d).encode('ascii')
    return ch


CHILD_WORDS = ('子效果', '给自己的效果', '给目标的效果', '附加效果', '激活', '消散效果', '死亡效果', '效果ID', '效果id')
SECOND_FORM = ('二式', '刃影')


def scope_rows(src, added, scope, cur_by=None):
    """ô impact của kỹ năng 15 phái (cấp 1–4 nếu scope=p1) → (SkillData, cấp, nhãn, template, tên, phái).
    Có đi tiếp xuống dòng CON (子效果…) mà impact-data cũng đã thêm: số của chúng cũng nằm trong tip kỹ năng."""
    own = {}
    for r in src.st['rows']:
        mp = ival(r[ST_MENPAI])
        if mp is None or mp < 0 or mp > 15 or mp == 9:
            continue
        for k in range(4 if scope == 'p1' else len(ST_LEVELS)):
            sid = ival(r[ST_LEVELS[k]])
            if sid is None or sid < 0 or sid not in src.sd_by:
                continue
            for pos, lab, v in src.cells(sid):
                if v in added:
                    own.setdefault(v, (sid, k + 1, lab, int(r[0]), g(r[ST_NAME]).strip(), mp))
    if cur_by is None:
        return own
    frontier, depth = list(own), 0
    while frontier and depth < 3:
        depth += 1
        nxt = []
        for iid in frontier:
            row = cur_by.get(iid)
            if row is None:
                continue
            for k in range(SI_PARAM_N):
                lab = g(row[SI_PARAM0 + 3 * k]).strip()
                v = ival(row[SI_PARAM0 + 3 * k + 1])
                if v is None or v <= 0 or v in own or v not in added:
                    continue
                if any(w in lab for w in CHILD_WORDS):
                    sid, lv, plab, tid, skill, mp = own[iid]
                    own[v] = (sid, lv, plab + '→' + lab, tid, skill, mp)
                    nxt.append(v)
        frontier = nxt
    return own


def tip_for(src, sid, skill, label):
    """tip dùng để sửa số. Ô 'kích hoạt chiêu hai' (激活二式buff / 附加效果1 của ·刃影) lấy thêm tip của
    kỹ năng con `<tên>·…` — số của chiêu hai nằm ở tip con chứ không ở tip kỹ năng cha."""
    tip = src.tip(sid)
    if not any(w in label for w in SECOND_FORM):
        return tip
    extra = []
    for r in src.st['rows']:
        nm = g(r[ST_NAME]).strip()
        if not nm.startswith(skill + '·'):
            continue
        s2 = ival(r[ST_LEVELS[0]])
        if s2 is not None and s2 >= 0 and s2 in src.sd_by:
            extra.append(src.tip(s2))
    # trả về tip của CHIÊU HAI, không gộp với tip cha: ô này mang số của chiêu hai, gộp vào thì số của cha
    # (xuất hiện trước) sẽ thắng và ghi đè sai
    return ' '.join(extra) if extra else tip


def cmd_fix(args):
    src = Src(args.base)                       # nền = mốc TRƯỚC khi bù (để biết dòng nào do impact-data thêm)
    cur = read_table_bytes(open(os.path.join(R, SI), 'rb').read())
    cur_by = {int(r[0]): list(r) for r in cur['rows']}
    added = set(cur_by) - set(src.si_by)
    own = scope_rows(src, added, args.scope, cur_by if args.children else None)
    print('dòng do impact-data thêm: %d | trong phạm vi %s: %d' % (len(added), args.scope, len(own)))

    tsv = [['impact_id', 'phai', 'ky_nang', 'cap', 'skilldata', 'nhan_o', 'tham_so', 'cu', 'moi', 'vi_sao', 'tip']]
    n_row = 0
    for iid in sorted(own):
        sid, lv, lab, tid, skill, mp = own[iid]
        tip = tip_for(src, sid, skill, lab)
        row = cur_by[iid]
        ch = fix_row(row, tip)
        if ch:
            n_row += 1
            for c in ch:
                tsv.append([str(iid), MENPAI.get(mp, str(mp)), skill, str(lv), str(sid), lab,
                            c[0], c[1], c[2], c[3], tip[:160]])
    os.makedirs(os.path.join(args.out, 'configs'), exist_ok=True)
    rows = [cur_by[i] for i in sorted(cur_by)]
    write_table(os.path.join(args.out, SI), cur['types'], cur['names'], rows, cur['eol'])
    with open(os.path.join(args.out, 'impact_fix.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        for r in tsv:
            f.write('\t'.join(r) + '\n')
    print('đã chỉnh %d dòng / %d ô tham số (chi tiết impact_fix.tsv)' % (n_row, len(tsv) - 1))
    return 0


# ---------------------------------------------------------------- "N % đòn đánh thường" → dòng logic 115
# skill-logic (16/09) đã bẻ mã CY: "造成N%普通攻击伤害" KHÔNG phải tham số của dòng logic 3 mà là một dòng
# StandardImpact riêng mang 逻辑ID = 115, tham số 0 = 伤害量缩放系数 (`StdImpact115_T::OnActive` @0xa5f2f8 lấy
# dòng 0 = đòn đánh thường rồi nhân hệ số). Module Lua `std_impact_115.lua` đã cài trên server (265b531).
# Ở đây chỉ đổi DỮ LIỆU: ô đang trỏ tới dòng logic 3 (điểm công, bản HJ) → dòng logic 115 với hệ số lấy từ tip CY.
SCALE_DONOR = 43918                     # 撼岳群攻效果 (logic 115, 是否持续=0, 影响性质=-1, 伤害量缩放系数=100)
SCALE_TARGET_WORDS = ('目标', '附加效果', '攻击效果', '攻击的效果')
SCALE_SELF_WORDS = ('自己', '自身', '给自己', '对自己')
# (SkillTemplate, nhãn ô, chỉ số % trong dãy đầu tiên của tip, ghi chú) — chọn tay vì dãy "70%/95%/120%"
# là ba ĐOẠN của cùng một chiêu, phải ghép đúng đoạn với template.
SCALE_CELLS = [
    (4538, '生效一次的效果(目标)', 0, '绝情谷 宁鸣不默 — đoạn 1'),
    (4533, '生效一次的效果(目标)', 1, '绝情谷 宁鸣不默（2段）— đoạn 2'),
    (4534, '生效一次的效果(目标)', 2, '绝情谷 宁鸣不默（3段）— đoạn 3'),
    (4707, '生效一次的效果(目标)', 0, '绝情谷 宁鸣不默 (4707) — tip chỉ có một giá trị'),
    (822, '附加效果1', 0, '大理 少冲剑·刃影 — "造成100%普通攻击伤害"'),
    (463, '附加效果2', 0, '大理 少商剑 — văng 50 % phổ công quanh mục tiêu'),
]
PCT_RUN_RE = re.compile(r'(?:普通攻击|普攻)(?:额外)?\s*((?:\d+(?:\.\d+)?\s*%)(?:\s*/\s*\d+(?:\.\d+)?\s*%)*)')
PCT_RUN_RE2 = re.compile(r'((?:\d+(?:\.\d+)?\s*%)(?:\s*/\s*\d+(?:\.\d+)?\s*%)*)\s*(?:的)?(?:普通攻击|普攻)')


def tip_attack_percents(tip):
    """dãy % phổ công ĐẦU TIÊN trong tip, vd '70%/95%/120%' → [70, 95, 120]."""
    m = PCT_RUN_RE.search(tip) or PCT_RUN_RE2.search(tip)
    if not m:
        return []
    return [float(x.strip().rstrip('%')) for x in m.group(1).split('/')]


def cmd_scale(args):
    src = Src(args.base)
    cur = read_table_bytes(open(os.path.join(R, SI), 'rb').read())
    cur_by = {int(r[0]): list(r) for r in cur['rows']}
    added = set(cur_by) - set(src.si_by)
    donor = cur_by.get(SCALE_DONOR)
    if donor is None or ival(donor[SI_LOGIC]) != 115:
        print('LỖI: không có dòng mẫu %d logic 115' % SCALE_DONOR)
        return 1
    st_by = {int(r[0]): r for r in src.st['rows']}
    tsv = [['impact_id', 'phai', 'ky_nang', 'template', 'cap', 'nhan_o', 'logic_cu', 'logic_moi',
            'he_so', 'day_%_trong_tip', 'ghi_chu', 'tip']]
    n = 0
    for tid, label, idx, note in SCALE_CELLS:
        t = st_by.get(tid)
        if t is None:
            print('bỏ qua: không có SkillTemplate', tid)
            continue
        mp = ival(t[ST_MENPAI])
        skill = g(t[ST_NAME]).strip()
        if any(w in label for w in SCALE_SELF_WORDS) or not any(w in label for w in SCALE_TARGET_WORDS):
            print('bỏ qua %d "%s": không phải ô áp lên mục tiêu' % (tid, label))
            continue
        for k, c in enumerate(ST_LEVELS):
            sid = ival(t[c]) if c < len(t) else None
            if sid is None or sid < 0 or sid not in src.sd_by:
                continue
            tip = src.tip(sid)
            pcts = tip_attack_percents(tip)
            if not pcts:
                continue
            val = pcts[min(idx, len(pcts) - 1)]
            for pos, lab, v in src.cells(sid):
                if lab != label or v not in added or v not in cur_by:
                    continue
                row = cur_by[v]
                old_logic = g(row[SI_LOGIC]).strip()
                new = list(donor)
                new[0] = str(v).encode('ascii')
                new[SI_NAME] = skill.encode('gbk')
                se = ival(new[SI_SE])
                if se is not None and se >= 0 and se not in src.se_cy:
                    new[SI_SE] = b'-1'
                new[SI_PARAM0] = '伤害量缩放系数'.encode('gbk')
                new[SI_PARAM0 + 1] = ('%d' % val if float(val).is_integer() else '%g' % val).encode('ascii')
                new[SI_PARAM0 + 2] = b'0'
                if cur_by[v] != new:
                    n += 1
                    tsv.append([str(v), MENPAI.get(mp, str(mp)), skill, str(tid), str(k + 1), lab, old_logic, '115',
                                g(new[SI_PARAM0 + 1]), '/'.join('%g' % p for p in pcts), note, tip[:160]])
                cur_by[v] = new
    os.makedirs(os.path.join(args.out, 'configs'), exist_ok=True)
    write_table(os.path.join(args.out, SI), cur['types'], cur['names'],
                [cur_by[i] for i in sorted(cur_by)], cur['eol'])
    with open(os.path.join(args.out, 'impact_scale.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        for r in tsv:
            f.write('\t'.join(r) + '\n')
    print('đã đổi %d dòng sang logic 115 (chi tiết impact_scale.tsv)' % n)
    return 0


# ---------------------------------------------------------------- sửa dòng cy_four chưa có ánh xạ vị trí
# `cy_four_combat/engine.lua:67` assert(config.impacts[data_index]) → mọi dòng 逻辑ID ≥ 8000 phải có
# Data_Index trong `native_config.lua impacts={…}`. Dòng do impact-data chép theo TÊN có Data_Index MỚI nên
# không nằm trong bảng đó → "unmapped positional impact" khi impact được kích hoạt.
CY_FOUR_CFG = 'lualib/cy_four_combat/native_config.lua'


def cyfour_mapped(src=None):
    txt = open(os.path.join(R, GS, CY_FOUR_CFG), encoding='utf-8').read()
    body = txt.split('impacts={', 1)[1]
    return set(int(m) for m in re.findall(r'\[(\d+)\]=\{', body))


def cmd_cyfour(args):
    src = Src(args.base)
    cur = read_table_bytes(open(os.path.join(R, SI), 'rb').read())
    cur_by = {int(r[0]): list(r) for r in cur['rows']}
    added = set(cur_by) - set(src.si_by)
    mapped = cyfour_mapped()
    bad = sorted(i for i in added if (ival(cur_by[i][SI_LOGIC]) or 0) >= 8000 and i not in mapped)
    print('native_config.impacts: %d mục | dòng impact-data logic ≥ 8000 thiếu ánh xạ: %d' % (len(mapped), len(bad)))

    # chủ nhân của mỗi ID (kỹ năng + ô) và mọi ID mà kỹ năng đó đang dùng
    owner, used_by_tpl = {}, collections.defaultdict(set)
    for r in src.st['rows']:
        tid, tname = int(r[0]), g(r[ST_NAME]).strip()
        mp = ival(r[ST_MENPAI])
        for k in range(len(ST_LEVELS)):
            sid = ival(r[ST_LEVELS[k]])
            if sid is None or sid < 0 or sid not in src.sd_by:
                continue
            for pos, lab, v in src.cells(sid):
                used_by_tpl[tid].add(v)
                owner.setdefault(v, (tid, tname, mp, k + 1, lab))
    si_by_name = collections.defaultdict(list)
    for r in cur['rows']:
        si_by_name[g(r[SI_NAME]).strip()].append(int(r[0]))

    # bảng ánh xạ cần thêm vào native_config.lua: ID mới → ID dòng mẫu (cùng nội dung, đã có ánh xạ sẵn)
    donor_of = {}
    for p in (args.tsv or []):
        if not os.path.exists(p):
            continue
        import csv as _csv
        for row in _csv.DictReader(open(p, encoding='utf-8'), delimiter='\t'):
            d = (row.get('dong_mau') or '').strip()
            if d.isdigit():
                donor_of[int(row['impact_id'])] = int(d)
    def root_donor(i):
        """lần theo chuỗi chép (series chép lại dòng vừa sinh) tới dòng mẫu ĐÃ CÓ ánh xạ trong native_config."""
        seen, cur_id = set(), i
        for _ in range(8):
            d = donor_of.get(cur_id)
            if d is None or d in seen:
                return None
            if d in mapped:
                return d
            seen.add(d)
            cur_id = d
        return None

    mtsv = [['impact_id_moi', 'dong_mau_id', 'dong_mau_goc_da_anh_xa', 'logic', 'phai', 'ky_nang',
             'template', 'cap', 'nhan_o']]
    n_root = 0
    for i in bad:
        tid, tname, mp, lv, lab = owner.get(i, (None, '', None, 0, ''))
        dn = donor_of.get(i)
        root = dn if (dn in mapped) else root_donor(i)
        if root:
            n_root += 1
        mtsv.append([str(i), str(dn or ''), str(root or ''), g(cur_by[i][SI_LOGIC]).strip(), MENPAI.get(mp, ''),
                     tname, str(tid or ''), str(lv), lab])
    with open(os.path.join(args.out, 'cyfour-map.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        for r in mtsv:
            f.write('\t'.join(r) + '\n')
    print('đã ghi %s/cyfour-map.tsv (%d dòng; có ID dòng mẫu %d; truy được dòng mẫu GỐC đã ánh xạ %d)'
          % (args.out, len(mtsv) - 1, sum(1 for r in mtsv[1:] if r[1]), n_root))
    if not args.repair:
        return 0

    taken = set()
    tsv = [['impact_id', 'phai', 'ky_nang', 'cap', 'nhan_o', 'logic_cu', 'xu_ly', 'dong_mau_moi', 'logic_moi', 'ly_do']]
    fixed = dropped = 0
    for i in bad:
        tid, tname, mp, lv, lab = owner.get(i, (None, '', None, 0, ''))
        old_logic = g(cur_by[i][SI_LOGIC]).strip()
        pool = []
        for nm, ids in si_by_name.items():
            if not tname or not nm.startswith(tname):
                continue
            for j in sorted(ids):
                if j in added or j in taken or (tid and j in used_by_tpl[tid]):
                    continue
                lg = ival(cur_by[j][SI_LOGIC]) or 0
                if 0 <= lg < 8000:
                    pool.append(j)
        if pool:
            dn = pool[0]
            row = list(cur_by[dn])
            row[0] = str(i).encode('ascii')
            se = ival(row[SI_SE])
            if se is not None and se >= 0 and se not in src.se_cy:
                row[SI_SE] = b'-1'
            cur_by[i] = row
            taken.add(dn)
            fixed += 1
            tsv.append([str(i), MENPAI.get(mp, ''), tname, str(lv), lab, old_logic, 'thay dòng mẫu',
                        str(dn), g(row[SI_LOGIC]).strip(), 'dòng cùng tên kỹ năng, logic < 8000'])
        else:
            del cur_by[i]
            dropped += 1
            tsv.append([str(i), MENPAI.get(mp, ''), tname, str(lv), lab, old_logic, 'xoá dòng', '', '',
                        'không có dòng cùng tên kỹ năng với logic < 8000 → trả ô về trạng thái thiếu'])
    os.makedirs(os.path.join(args.out, 'configs'), exist_ok=True)
    write_table(os.path.join(args.out, SI), cur['types'], cur['names'],
                [cur_by[i] for i in sorted(cur_by)], cur['eol'])
    with open(os.path.join(args.out, 'impact_cyfour.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        for r in tsv:
            f.write('\t'.join(r) + '\n')
    print('thay dòng mẫu: %d | xoá dòng: %d (chi tiết impact_cyfour.tsv)' % (fixed, dropped))
    return 0


# ---------------------------------------------------------------- nội suy theo cấp cho dòng `series`
# Luật `series` chép NGUYÊN dòng của cấp gần nhất ⇒ mọi cấp của ô đó dùng chung một con số, chiêu
# "không mạnh lên theo cấp". Dữ liệu THẬT của bảng cho thấy `参数值` của một ô tăng TUYẾN TÍNH theo cấp:
#   1915–1926 少商剑  火系攻击 279 / 480 / 681 …            (+201 mỗi cấp)
#   37493…    催箭式   命中+    260 / 340 / 420 / 500 …      (+80)
#   2426–2431 阳关三叠 会心一击修正 96 / 108 / … / 156        (+12)
# còn `修正步长` GIỮ NGUYÊN qua các cấp (14,69565217 cho cả 12 dòng 少商剑) — nó là bước theo **tu luyện**,
# không phải theo cấp, và `cfghelper:read_std_impact` của server **không đọc** cột này (chỉ đọc `参数值`).
# ⇒ chỉ nội suy `参数值` và `总持续时间`, KHÔNG đụng `修正步长` (giống R1 của `server-impact`).
#
# Chỉ nhãn mang ĐỘ LỚN mới được nội suy. Nhãn kiểu ID/tập hợp/cờ phải loại trừ: `子效果1数据索引` của
# 回天术·九阳 chạy 16191/16192/16193/16194 theo cấp — nội suy ra 16195 là một **ID không có dòng**.
INTERP_LABELS = frozenset([
    '总持续时间(毫秒)',
    '物理攻击+', '魔法攻击+', '冰系攻击', '火系攻击', '电系攻击', '毒系攻击',
    '伤害数值', '伤害数值+', '物理伤害', '魔法伤害', '直接伤害',
    '物理防御+', '魔法防御+', '命中+', '闪避+',
    'HP修改百分率', 'MP修改百分率', 'HP修改值', 'MP修改值',
    '基础伤害增强', '伤害增强千分比', '伤害吸收率', '施加者护体百分比', '免疫率',
    '反射率', '反射伤害上限', '伤害反弹率', '会心伤害提升',
    '冰系攻击修正', '火系攻击修正', '电系攻击修正', '毒系攻击修正',
    '冰系抗性修正', '火系抗性修正', '电系抗性修正', '毒系抗性修正',
    '命中修正率', '闪避修正率', '会心修正率', '会心攻击修正率', '物理攻击修正率', '魔法攻击修正率',
    '冰系攻击修正率', '火系攻击修正率', '电系攻击修正率', '毒系攻击修正率',
    '共情修正', '共情增长率修正', '怒气增长修正', '怒气增长率修正',
    '聚气时间百分修正', '移动速度修正%（0为无效）',
    'STR修正(0为无效)', 'CON修正(0为无效)', 'DEX修正(0为无效)', 'INT修正(0为无效)', 'SPR修正(0为无效)',
])
INTERP_MAX_FACTOR = 3.0        # chặn bùng nổ: |giá trị mới| ≤ 3 × |mốc lớn nhất|
INTERP_LONG_DUR = 600000       # ≥ 10 phút = cờ gần như vĩnh viễn (vd 商阳剑·刃影 8.100.000 ms của bản HJ):
                               # kéo dài thêm không có nghĩa gì, chỉ làm nhiễu diff → bỏ
# Phần trăm của một TỔNG THỂ: ra ngoài khoảng là vô nghĩa (聚气时间百分修正 = −150 % ⇒ thời gian tụ khí ÂM).
# Khi khớp tuyến tính vượt ngưỡng ở BẤT KỲ cấp nào của ô thì bỏ cả nhãn cho mọi cấp của ô đó — cắt ngọn
# sẽ tạo bậc thang không đơn điệu (cấp 6 = −100, cấp 7 = −85).
INTERP_CAP = {
    '聚气时间百分修正': (-100.0, 100.0),
    '移动速度修正%（0为无效）': (-100.0, 100.0),
    '伤害吸收率': (0.0, 100.0),
    '免疫率': (0.0, 100.0),
    '施加者护体百分比': (0.0, 100.0),
    'HP修改百分率': (-100.0, 100.0),
    'MP修改百分率': (-100.0, 100.0),
}


def _fmt_like(x, like):
    """giữ kiểu ô gốc: số nguyên nếu ô hiện tại là số nguyên (như fmt_num của server_impact)."""
    if re.fullmatch(rb'-?\d+', (like or b'').strip() or b'0'):
        return str(int(round(x))).encode('ascii')
    return ('%.6f' % x).rstrip('0').rstrip('.').encode('ascii')


def _lsq(pts):
    """khớp bình phương tối thiểu y = a + b·x; trả (a, b, sai số lớn nhất)."""
    n = len(pts)
    sx = sum(x for x, _ in pts)
    sy = sum(y for _, y in pts)
    sxx = sum(x * x for x, _ in pts)
    sxy = sum(x * y for x, y in pts)
    den = n * sxx - sx * sx
    if den == 0:
        return None
    b = (n * sxy - sx * sy) / den
    a = (sy - b * sx) / n
    resid = max(abs(y - (a + b * x)) for x, y in pts)
    return a, b, resid


def _rule_map(paths):
    """impact_id -> luật, đọc từ impact_data*.tsv (cột `luat`)."""
    import csv as _csv
    out = {}
    for p in paths:
        if not p or not os.path.exists(p):
            continue
        with open(p, encoding='utf-8') as f:
            for row in _csv.DictReader(f, delimiter='\t'):
                ru = (row.get('luat') or '').strip()
                if ru and ru != 'chua-bu':
                    out[int(row['impact_id'])] = ru
    return out


def interp_groups(src):
    """[(tid, phái, tên kỹ năng, vị trí cột, nhãn, {cấp: impact}, {cấp: SkillData})] + tập ID dùng ở >1 ô/cấp."""
    groups, use = [], collections.Counter()
    for r in src.st['rows']:
        tid, mp, nm = int(r[0]), ival(r[ST_MENPAI]), g(r[ST_NAME]).strip()
        per, sids = {}, {}
        for k, c in enumerate(ST_LEVELS):
            sid = ival(r[c]) if c < len(r) else None
            if sid is None or sid < 0 or sid not in src.sd_by:
                continue
            sids[k + 1] = sid
            for pos, lab, v in src.cells(sid):
                per.setdefault((pos, lab), {})[k + 1] = v
                use[v] += 1
        for (pos, lab), lv in per.items():
            groups.append((tid, mp, nm, pos, lab, lv, sids))
    return groups, set(i for i, c in use.items() if c > 1)


def cmd_interp(args):
    src = Src(args.base, live_tables=True)
    cur = read_table_bytes(open(os.path.join(R, SI), 'rb').read())
    cur_by = {int(r[0]): list(r) for r in cur['rows']}
    rules = _rule_map(args.tsv or [])
    if not rules:
        print('LOI: can --tsv impact_data_final.tsv de biet dong nao la `series`')
        return 1
    scaled = set()
    for p in (args.scale_tsv or []):
        if os.path.exists(p):
            import csv as _csv
            with open(p, encoding='utf-8') as f:
                for row in _csv.DictReader(f, delimiter='\t'):
                    scaled.add(int(row['impact_id']))
    series = set(i for i, ru in rules.items() if ru == 'series' and i in cur_by)
    groups, shared = interp_groups(src)

    tsv = [['impact_id', 'phai', 'ky_nang', 'template', 'cap', 'nhan_o', 'tham_so', 'cu', 'moi',
            'kieu', 'chac_chan', 'moc_thuc_dung', 'cong_thuc']]
    why = collections.Counter()
    skipped = []
    touched = set()
    for tid, mp, nm, pos, lab, lv, sids in groups:
        tgt = {k: v for k, v in sorted(lv.items())
               if v in series and v not in shared and v not in scaled}
        if not tgt:
            continue
        anc = {k: cur_by[v] for k, v in lv.items()
               if v in cur_by and rules.get(v) != 'series' and v not in shared}
        # loai tung muc khong du dieu kien truoc, phan con lai moi dem khop
        ok_tgt = {}
        for k, v in tgt.items():
            lg = ival(cur_by[v][SI_LOGIC])
            if lg is None or lg >= 8000:
                why['logic_cy_four'] += 1
                skipped.append((v, u'd\u00f2ng logic %s (cy_four \u2014 tham s\u1ed1 \u0111\u1ecdc theo V\u1eca TR\u00cd) n\u00ean kh\u00f4ng n\u1ed9i suy' % lg))
                continue
            pts_rows = {j: r for j, r in anc.items() if ival(r[SI_LOGIC]) == lg}
            if len(pts_rows) < 2:
                why['duoi_2_moc'] += 1
                skipped.append((v, u'\u00f4 "%s" c\u1ee7a %s ch\u1ec9 c\u00f3 %d m\u1ed1c th\u1eadt c\u00f9ng logic \u2014 kh\u00f4ng suy ra \u0111\u01b0\u1ee3c \u0111\u1ed9 d\u1ed1c'
                                % (lab, nm, len(pts_rows))))
                continue
            ok_tgt[k] = (v, pts_rows)
        if not ok_tgt:
            continue

        # tap nhan ung vien = nhan DANG DUNG cua cac dong dich, giao voi danh sach cho phep
        labels = set()
        for k, (v, _) in ok_tgt.items():
            row = cur_by[v]
            if (ival(row[SI_DURATION]) or 0) > 0:
                labels.add(u'\u603b\u6301\u7eed\u65f6\u95f4(\u6beb\u79d2)')
            for m in range(SI_PARAM_N):
                labels.add(g(row[SI_PARAM0 + 3 * m]).strip())
        labels = sorted(l for l in labels if l in INTERP_LABELS)

        plan_cell = collections.defaultdict(list)
        for label in labels:
            drop_label = False
            batch = []
            for k, (v, pts_rows) in sorted(ok_tgt.items()):
                row = cur_by[v]
                if label == u'\u603b\u6301\u7eed\u65f6\u95f4(\u6beb\u79d2)':
                    c, m = SI_DURATION, None
                else:
                    ms = [x for x in range(SI_PARAM_N) if g(row[SI_PARAM0 + 3 * x]).strip() == label]
                    if len(ms) != 1:
                        continue                      # nhan lap trong cung dong -> khong xac dinh duoc o
                    m, c = ms[0], SI_PARAM0 + 3 * ms[0] + 1
                curv = ival(row[c])
                if curv is None or curv in (0, -1):
                    continue
                if c == SI_DURATION and curv >= INTERP_LONG_DUR:
                    why['thoi_luong_gan_vinh_vien'] += 1
                    continue
                pts = []
                for j, r in sorted(pts_rows.items()):
                    if m is not None and g(r[SI_PARAM0 + 3 * m]).strip() != label:
                        continue                      # bo cuc o khac nhau => khong so duoc
                    x = ival(r[c])
                    if x is None or x in (0, -1):
                        continue
                    pts.append((float(j), float(x)))
                if len(pts) < 2 or len(set(y for _, y in pts)) < 2:
                    continue
                span = max(y for _, y in pts) - min(y for _, y in pts)
                fit = _lsq(pts)
                if fit and fit[2] <= max(1.0, 0.02 * abs(span)):
                    a, b, _r = fit
                    x_new, kind = a + b * k, 'lsq%d' % len(pts)
                    formula = u'y = %.6g + %.6g\u00b7c\u1ea5p (kh\u1edbp %d m\u1ed1c)' % (a, b, len(pts))
                else:
                    near = sorted(pts, key=lambda q: (abs(q[0] - k), q[0]))[:2]
                    (j1, y1), (j2, y2) = sorted(near)
                    if y1 == y2 or j1 == j2:
                        continue
                    x_new, kind = y1 + (y2 - y1) * (k - j1) / (j2 - j1), '2moc'
                    formula = u'%g + (%g\u2212%g)\u00b7(%d\u2212%g)/(%g\u2212%g)' % (y1, y2, y1, k, j1, j2, j1)
                lo_j, hi_j = min(q[0] for q in pts), max(q[0] for q in pts)
                mx = max(abs(y) for _, y in pts)
                if abs(x_new) > INTERP_MAX_FACTOR * mx:
                    why['vuot_tran'] += 1
                    continue
                cap = INTERP_CAP.get(label)
                if cap and not (cap[0] <= x_new <= cap[1]):
                    # phan tram cua mot TONG THE: ra ngoai [lo, hi] la vo nghia => bo CA nhan cua o nay,
                    # khong cat ngon (cat se tao bac thang khong don dieu giua cac cap)
                    drop_label = True
                    skipped.append((v, u'nh\u00e3n "%s" c\u1ee7a \u00f4 "%s" (%s): kh\u1edbp tuy\u1ebfn t\u00ednh ra %.4g, ngo\u00e0i [%g, %g] '
                                       u'\u21d2 b\u1ecf c\u1ea3 nh\u00e3n cho m\u1ecdi c\u1ea5p c\u1ee7a \u00f4' % (label, lab, nm, x_new, cap[0], cap[1])))
                    break
                if (x_new > 0) != (curv > 0) or round(x_new) == 0:
                    why['doi_dau'] += 1
                    continue
                newb = _fmt_like(x_new, row[c])
                if newb == (row[c] or b'').strip():
                    continue
                bracket = lo_j < k < hi_j
                conf = (u'cao' if bracket and kind.startswith('lsq') else
                        (u'trung b\u00ecnh' if kind.startswith('lsq') and k - hi_j <= 4 else u'th\u1ea5p'))
                batch.append((v, k, c, label, g(row[c]).strip(), g(newb), newb,
                              u'n\u1ed9i suy' if bracket else u'ngo\u1ea1i suy', conf,
                              ' '.join('%d:%g' % (int(j), y) for j, y in pts), formula))
            if drop_label:
                why['vuot_nguong_phan_tram'] += 1
                continue
            for b in batch:
                plan_cell[b[0]].append(b)

        for v, items in plan_cell.items():
            row = cur_by[v]
            for (_v, k, c, label, old, new, newb, kind, conf, pts_s, formula) in items:
                row[c] = newb
                tsv.append([str(v), MENPAI.get(mp, str(mp)), nm, str(tid), str(k), lab, label,
                            old, new, kind, conf, pts_s, formula])
                touched.add(v)
        for k, (v, _pr) in ok_tgt.items():
            why['da_noi_suy' if v in touched else 'co_moc_nhung_khong_lech'] += 1

    os.makedirs(os.path.join(args.out, 'configs'), exist_ok=True)
    write_table(os.path.join(args.out, SI), cur['types'], cur['names'],
                [cur_by[i] for i in sorted(cur_by)], cur['eol'])
    with open(os.path.join(args.out, 'impact_interp.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        for r in tsv:
            f.write('\t'.join(r) + '\n')
    with open(os.path.join(args.out, 'impact_interp_skip.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('impact_id\tly_do\n')
        for i, w in skipped:
            f.write('%d\t%s\n' % (i, w))
    out = {'base': args.base, 'series_rows': len(series),
           'series_bo_qua_dung_chung_hoac_scale': len(series & (shared | scaled)),
           'rows_changed': len(touched), 'cells_changed': len(tsv) - 1, 'why': dict(why)}
    print(json.dumps(out, ensure_ascii=False, indent=1))
    with open(os.path.join(args.out, 'interp.json'), 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    return 0


# ---------------------------------------------------------------- bù ô cấp 1-4 còn thiếu (P1)
# Nối tiếp `trap_impacts.py` mục 6 (17/09): mỗi mục khai báo DÒNG MẪU THẬT + ĐIỀU KIỆN, công cụ tự kiểm lại
# trên bảng sống; sai một điều kiện thì BỎ và ghi lý do, không âm thầm sinh dòng.
#   tip     : chuỗi phải có trong tip của (ít nhất một) SkillData cấp 1-4 dẫn tới ô này
#   dur     : `总持续时间` mà dòng mẫu phải ĐANG mang (kiểm, không đổi)
#   set_dur : đặt `总持续时间` — chỉ khi tip cho đúng MỘT con số cho đúng loại hiệu ứng của dòng
#   pdonor  : {nhãn: giá trị} mà dòng mẫu phải đang mang
#   set_par : {nhãn: giá trị} đặt lại ĐỘ LỚN của tham số ĐANG DÙNG (không bật tham số mới)
#   sib     : (nhãn ô anh em, tên dòng mà ô đó đang trỏ tới) — bằng chứng "ô kia đã lo việc kia"
# Dòng mẫu BẮT BUỘC có mặt ở mốc P1_DONOR_BASE (bảng gốc), không lấy dòng do agent trước suy ra.
P1_DONOR_BASE = '6ca25a8'
P1_CELLS = [
    # -- 星宿 神蝎百相 434 ô `免控buff` (logic kỹ năng 170 áp lên BẢN THÂN). Cùng vai trò, cùng tip với ô
    #    `免控buff` của 蝎行无阻 841/844 mà `trap-impacts` đã dựng thành `59721` từ đúng dòng mẫu này.
    (59706, 434, u'\u514d\u63a7buff', 13519, u'\u795e\u874e\u767e\u76f8\uff08CY\u63a8\u5bfc\u514d\u63a7\uff09',
     dict(tip=[u'\u6301\u7eed10\u79d2', u'\u4e0d\u4f1a\u53d7\u5230\u90e8\u5206\u63a7\u5236\u6548\u679c'], dur='10000',
          pdonor={u'\u514d\u75ab\u7ea7\u522b': '160', u'\u514d\u75ab\u96c6\u54081': '60'}),
     u'c1 \u2014 nhu 59721 cua 841/844 (trap-impacts), 10 s = thoi luong cuoi 巨蝎'),
    (59707, 434, u'\u514d\u63a7buff', 13519, u'\u795e\u874e\u767e\u76f8\uff08CY\u63a8\u5bfc\u514d\u63a7\uff09',
     dict(tip=[u'\u6301\u7eed10\u79d2'], dur='10000'), u'c2'),
    (59708, 434, u'\u514d\u63a7buff', 13519, u'\u795e\u874e\u767e\u76f8\uff08CY\u63a8\u5bfc\u514d\u63a7\uff09',
     dict(tip=[u'\u6301\u7eed10\u79d2'], dur='10000'), u'c3'),
    (59709, 434, u'\u514d\u63a7buff', 13519, u'\u795e\u874e\u767e\u76f8\uff08CY\u63a8\u5bfc\u514d\u63a7\uff09',
     dict(tip=[u'\u6301\u7eed10\u79d2'], dur='10000'), u'c4'),
    # -- 鬼谷 借东风 3448 ô `霸体效果` (cy_skill_logic_spec[767] aoe cho 6 dong doi trong 15 m).
    #    "霸体" = khong bi khong che; dong that duy nhat dung co che nay la ho `免疫控制`. Tip cho DUNG MOT so: 3 s.
    (59178, 3448, u'\u9738\u4f53\u6548\u679c', 13519, u'\u501f\u4e1c\u98ce\uff08CY\u63a8\u5bfc\u9738\u4f53\uff09',
     dict(tip=[u'\u843d\u5730\u65f6\u83b7\u5f973\u79d2\u9738\u4f53'], dur='10000', set_dur=3000), u'c1'),
    (59179, 3448, u'\u9738\u4f53\u6548\u679c', 13519, u'\u501f\u4e1c\u98ce\uff08CY\u63a8\u5bfc\u9738\u4f53\uff09',
     dict(tip=[u'\u843d\u5730\u65f6\u83b7\u5f973\u79d2\u9738\u4f53'], dur='10000', set_dur=3000), u'c2'),
    (59180, 3448, u'\u9738\u4f53\u6548\u679c', 13519, u'\u501f\u4e1c\u98ce\uff08CY\u63a8\u5bfc\u9738\u4f53\uff09',
     dict(tip=[u'\u843d\u5730\u65f6\u83b7\u5f973\u79d2\u9738\u4f53'], dur='10000', set_dur=3000), u'c3'),
    (59181, 3448, u'\u9738\u4f53\u6548\u679c', 13519, u'\u501f\u4e1c\u98ce\uff08CY\u63a8\u5bfc\u9738\u4f53\uff09',
     dict(tip=[u'\u843d\u5730\u65f6\u83b7\u5f973\u79d2\u9738\u4f53'], dur='10000', set_dur=3000), u'c4'),
    # -- 星宿 饮鸩止渴 436 ô `疲劳buff` (cy_skill_logic_spec[175]: co dau "chong dung lai").
    #    Dong that `55 珍兽群攻疲劳` (logic 38 = co danh dau, 0 tham so) da DUNG 60.000 ms = tip "60秒内...一次".
    (59800, 436, u'\u75b2\u52b3buff', 55, u'\u996e\u9e29\u6b62\u6e34\uff08CY\u63a8\u5bfc\u75b2\u52b3\uff09',
     dict(tip=[u'\u540c\u4e00\u76ee\u680760\u79d2\u5185\u53ea\u80fd\u88ab\u5343\u8db3\u5b88\u62a4\u4e00\u6b21'], dur='60000'),
     u'chep nguyen ven — 60 s cua dong mau trung khit tip, khong doi so nao'),
    # -- 峨嵋 金针渡劫 423 ô `|生效一次的附加效果2`. Ô anh em `|生效一次的附加效果1` da tro toi `金针渡劫(复活)`
    #    (HP修改量/MP修改量 = 6 = "6%的血/气"), nen o thu hai la co khoa 10 phut cua tip.
    #    `64 珍兽神佑疲劳` (logic 38) da DUNG 600.000 ms = dung 10 phut.
    (21667, 423, u'|\u751f\u6548\u4e00\u6b21\u7684\u9644\u52a0\u6548\u679c2', 64, u'\u91d1\u9488\u6e21\u52ab\uff08CY\u63a8\u5bfc\u75b2\u52b3\uff09',
     dict(tip=[u'10\u5206\u949f\u5185\u540c\u4e00\u76ee\u6807\u53ea\u80fd\u53d7\u5230\u4e00\u6b21\u91d1\u9488\u6e21\u52ab\u6548\u679c'],
          dur='600000', sib=(u'|\u751f\u6548\u4e00\u6b21\u7684\u9644\u52a0\u6548\u679c1', u'\u91d1\u9488\u6e21\u52ab')),
     u'chep nguyen ven — 600.000 ms = 10 phut, khong doi so nao'),
    # -- 星宿 毒螯势 839/842/845 ô `中毒buff` (cy_skill_logic_spec[171] theo 中毒几率%). Bo dong that
    #    `1031-1034 中毒(HPDOT2)` (logic 10, nhip 1 s, 子效果 = 中毒减血 theo cap) la co che DOT doc dung khuon.
    #    Tip cho dung mot thoi luong cho trang thai trung doc: 10 s.
    (59722, 839, u'\u4e2d\u6bd2buff', 1031, u'\u6bd2\u87af\u52bf\uff08CY\u63a8\u5bfc\u4e2d\u6bd2\uff09',
     dict(tip=[u'\u4f7f\u76ee\u6807\u4e2d\u6bd2', u'\u6301\u7eed10\u79d2'], dur='12000', set_dur=10000), u'c1'),
    (59723, 839, u'\u4e2d\u6bd2buff', 1032, u'\u6bd2\u87af\u52bf\uff08CY\u63a8\u5bfc\u4e2d\u6bd2\uff09',
     dict(tip=[u'\u4f7f\u76ee\u6807\u4e2d\u6bd2', u'\u6301\u7eed10\u79d2'], dur='12000', set_dur=10000), u'c2'),
    (59724, 839, u'\u4e2d\u6bd2buff', 1033, u'\u6bd2\u87af\u52bf\uff08CY\u63a8\u5bfc\u4e2d\u6bd2\uff09',
     dict(tip=[u'\u4f7f\u76ee\u6807\u4e2d\u6bd2', u'\u6301\u7eed10\u79d2'], dur='12000', set_dur=10000), u'c3'),
    (59725, 839, u'\u4e2d\u6bd2buff', 1034, u'\u6bd2\u87af\u52bf\uff08CY\u63a8\u5bfc\u4e2d\u6bd2\uff09',
     dict(tip=[u'\u4f7f\u76ee\u6807\u4e2d\u6bd2', u'\u6301\u7eed10\u79d2'], dur='12000', set_dur=10000), u'c4'),
    # -- 星宿 无处遁形 2264 ô `|生效一次的附加效果2`: tip noi ro "使目标处于中毒状态，持续伤血，状态持续10秒".
    (32668, 2264, u'|\u751f\u6548\u4e00\u6b21\u7684\u9644\u52a0\u6548\u679c2', 1031, u'\u65e0\u5904\u9041\u5f62\uff08CY\u63a8\u5bfc\u4e2d\u6bd2\uff09',
     dict(tip=[u'\u4f7f\u76ee\u6807\u5904\u4e8e\u4e2d\u6bd2\u72b6\u6001', u'\u72b6\u6001\u6301\u7eed10\u79d2'], dur='12000', set_dur=10000),
     u'so sat thuong moi nhip la cua dong mau (tip chi ghi "持续伤血", khong co so)'),
    # -- 大理 六剑齐发 2266 ô `|生效一次的附加效果2`: tip cho DU CA HAI so — "内功防御和外功防御降低50%" + "状态持续10秒".
    #    `<X>修正率` la PHAN TRAM (impact-data muc 6.0). Dong mau la dong that duy nhat dang dung ca hai nhan.
    (32671, 2266, u'|\u751f\u6548\u4e00\u6b21\u7684\u9644\u52a0\u6548\u679c2', 6313, u'\u516d\u5251\u9f50\u53d1\uff08CY\u63a8\u5bfc\u865a\u5f31\uff09',
     dict(tip=[u'\u5185\u529f\u9632\u5fa1\u548c\u5916\u529f\u9632\u5fa1\u964d\u4f4e50%', u'\u72b6\u6001\u6301\u7eed10\u79d2'],
          dur='120000', set_dur=10000,
          pdonor={u'\u7269\u7406\u9632\u5fa1\u4fee\u6b63\u7387': '-30', u'\u9b54\u6cd5\u9632\u5fa1\u4fee\u6b63\u7387': '-30'},
          set_par={u'\u7269\u7406\u9632\u5fa1\u4fee\u6b63\u7387': '-50', u'\u9b54\u6cd5\u9632\u5fa1\u4fee\u6b63\u7387': '-50'}),
     u'muc 互斥ID 25 (破绽) thua huong tu dong mau — hai debuff cung ho se thay the nhau'),
    # -- 唐门 矢魂箭 2933 ô `生效一次的效果(自己)`: tip "每次攻击能令目标失明0.5秒，持续20秒".
    #    `3908 含沙射影` (logic 88) lam DUNG co che nay: 伤害目标时的激发几率 = 100 (moi don danh) +
    #    给目标或攻击者的子效果1 = 3920 含沙射影失明. Chi doi thoi luong trang thai 10 s -> 20 s theo tip.
    (38463, 2933, u'\u751f\u6548\u4e00\u6b21\u7684\u6548\u679c(\u81ea\u5df1)', 3908, u'\u77e2\u9b42\u7bad\uff08CY\u63a8\u5bfc\u5931\u660e\uff09',
     dict(tip=[u'\u6bcf\u6b21\u653b\u51fb\u80fd\u4ee4\u76ee\u6807\u5931\u660e0.5\u79d2', u'\u6301\u7eed20\u79d2'],
          dur='10000', set_dur=20000,
          pdonor={u'\u4f24\u5bb3\u76ee\u6807\u65f6\u7684\u6fc0\u53d1\u51e0\u7387': '100'}),
     u'子效果 3920 la dong DUNG CHUNG (0,3 s) trong khi tip ghi 0,5 s — khong sua dong con (muc 6.1 nhom F)'),
]

# Ô đã xét và CỐ Ý không dựng — ghi lý do để lần sau không phải tra lại từ đầu.
P1_DECLINED = {
    u'\u7b2c\u516b\u5fc3\u6cd5 (logic 643/644, 13 ky nang x 4 o = 52 o: 龙盘斗里 泗水围城 紫雾扰心 碎舟入渊 六合禁域 '
    u'万宿辰光 步罡踏斗 良夜游 潮生云灭 容海川 意长流 噬魂九淬 缚魂狂镰)':
        u'tip 13 ky nang giong het nhau va CO Y khong co so: "强力控制，持续时间根据自己的心法、修炼评分与目标的'
        u'心法、修炼评分差值决定". cy_skill_logic_spec[643]/[644] ghi ro "Bien 下限/上限百分比 chua ap (thieu cong thuc '
        u'diem CY)". Dung dong 14 khoa cung nao cung phai BIA thoi luong ⇒ bo. Can cong thuc native CY.',
    u'\u661f\u5bbf 变身男/女buff (59700-59705, 6 ID: 神蝎百相 434, 蝎行无阻 841/844)':
        u'Nhu trap-data_vi.md muc 6.8: can 变身ID cua 巨蝎 (nam/nu) — khong co nguon; moi dong 变身 that mang ID '
        u'model khac; MonsterAttrExTable co 巨蝎 11534/11535/11555 nhung chua chung minh duoc 变身ID tra vao bang do; '
        u'va std_impact_014:get_refix_model_id van KHONG co cho nao goi trong lualib/services. Da kiem lai 17/09: '
        u'van 0 cho goi ⇒ giu nguyen quyet dinh bo.',
    u'\u661f\u5bbf 圣蚕护身 445 冰蚕buff (59864-59867)':
        u'Cung ly do 59879 (trap-data muc 6.8): tip mo ta CO CHE cua con 冰蚕 (hut hieu ung xau, ton 12 % mau, '
        u'tien hoa) chu khong cho biet BAN THAN buff lam gi.',
    u'\u5510\u95e8 千机变 2922 免疫控制buff (37920)':
        u'Giu nguyen quyet dinh cua trap-impacts (trap-data muc 6.7): tip 16 cap khong co chu 免疫 nao; '
        u'cy_skill_logic_spec[731] ap len NGUOI CHOI nen chep dong "mien tat ca" se thanh lo hong.',
    u'\u6076\u4eba\u8c37 生死由我 4635 (55581-55584, 55738-55741, 55754-55757 — 12 ID)':
        u'Hieu ung "受到致命一击时血量降低到1点但不会死亡" KHONG co dong mau that: quet ca bang khong co dong nao '
        u'ten 不死/濒死/免死/保命 lam viec do (chi co 42834 不死不休(状态) logic 38 = co danh dau va 63067 不死不休 '
        u'logic 320 命中率+=7). Tip CO so (6/8/10 s, 3/4/5 lan) nhung khong co dong mau de dat so vao ⇒ bo.',
    u'\u5ce8\u5d4b 蚀心白骨爪·九阴 834 (57496-57499 |效果1, 57512-57515 |效果2)':
        u'|效果1 "最高属性攻击增加377点" can logic 11 (thuoc tinh CAO NHAT) — cung nut that voi 大理 诸我圆满 '
        u'(impact-data muc 6.1 nhom D, chua giai). |效果2 "九阴血痕" la DOT theo % mau CUA NGUOI GAY (0,1 %/s) + '
        u'tang sat thuong nhan vao 1 %, cong don 5 lop — khong dong mau nao lam duoc ca hai. Ca hai o deu "to = self" '
        u'trong cy_skill_logic_spec[148] trong khi tip noi hieu ung len MUC TIEU ⇒ con phai tra lai vai tro truoc.',
    u'\u9b3c\u8c37 缩地成寸 3452 |生效一次的附加效果1 (42598)':
        u'cy_skill_logic_spec[760] xu ly o nay bang `teleport = {idx = 1, to = dest, on = target}` — Lua doi toa do '
        u'dong doi chu KHONG gui impact, nen dong impact khong doi hanh vi. Chi can khi lam dung impact thuan di CY.',
    u'\u7edd\u60c5\u8c37 吾道即真 4541 (49809-49812)':
        u'"将当前刀意立即重置满层" — 刀意 la tai nguyen rieng cua CY (chua co he thong tren server rieng); '
        u'khong dong mau nao dat lai tai nguyen do.',
    u'\u5929\u5c71 冰凝霜华 516 |生效一次的附加效果2 (53395-53398)':
        u'O anh em da co dong 冰封 that (29661-29672 logic 14, 10 s). O thu hai la "doi voi muc tieu bi minh dong bang, '
        u'ky nang DAU TIEN co ti le trung +100%" — can co danh dau ma logic ky nang phai doc; khong tim duoc dong that '
        u'nao mang y nghia do.',
    u'\u5927\u7406 苦禅之心 2267 (32672)':
        u'Tip cho du so (伤害额外增加50%, 90 s) nhung dong mau thi khong: moi dong that dang dung 基础伤害增强 deu la '
        u'741-752 破釜沉舟 (logic 149, KEM 受到伤害=100 — nhan them 100 % sat thuong, tip khong he noi) hoac '
        u'3870-3873 震箭式 / 3882 风雷万钧 (逻辑ID >= 8000, cy_four — chep se thanh "unmapped positional impact"). '
        u'Chep bat ky cai nao cung them mot mat trai khong co trong tip ⇒ bo.',
    u'\u6155\u5bb9 彼道还施 2275 (32681, 32694) / 剑归我道 2276 (32682, 32683)':
        u'Moi ky nang co HAI o thieu ma tip chi mo ta mot cach mo ho ("反射极大量的伤害" / "极大的提高命中和会心") '
        u'⇒ khong biet o nao la o nao. 剑归我道 co mot so that (内外防 -30%, 10 s) nhung khong gan duoc vao o cu the '
        u'— gan sai la dat debuff len chinh minh o o dang le la buff.',
    u'C\u00e1c \u00f4 tip ch\u1ec9 ghi "\u5927\u91cf\u4f24\u5bb3/\u5927\u91cf\u6cbb\u7597/\u6781\u5927" (khong co so)':
        u'禅棍封魔 32643, 业火焚城 32644/32645, 斗犬十弄 32652 (攻击效果) + 32653 (给自己的效果 — "精通状态7秒" '
        u'nhung bang KHONG co dong nao ten 精通), 七星唤魂 32696, 无处遁形 32667, 六剑齐发 32670, 形影无踪 32680, '
        u'沙场点兵 38461, 神机幻影 37833-37836 (an than 5 s + giam nua toc do — chua tim duoc dong that mang ca hai), '
        u'饮鸩止渴 效果1 59978-59981 (tip tron 5 con so cho 5 co che khac nhau trong cung mot o).',
}


def cmd_p1fill(args):
    src = Src(args.base, live_tables=True)
    cur = read_table_bytes(open(os.path.join(R, SI), 'rb').read())
    cur_by = {int(r[0]): list(r) for r in cur['rows']}
    donor_base = set(int(r[0]) for r in read_table_bytes(git_show(P1_DONOR_BASE, SI))['rows'])
    st_by = {int(r[0]): r for r in src.st['rows']}

    tsv = [['impact_id', 'phai', 'ky_nang', 'template', 'cap', 'nhan_o', 'dong_mau', 'ten_dong_mau',
            'logic', 'doi_so', 'ket_qua', 'bang_chung', 'ghi_chu']]
    made, skipped = 0, []
    for imp, tid, label, donor_id, name, cond, note in P1_CELLS:
        t = st_by.get(tid)
        if t is None:
            skipped.append((imp, 'khong co SkillTemplate %d' % tid))
            continue
        mp, skill = ival(t[ST_MENPAI]), g(t[ST_NAME]).strip()
        levels, tips = [], []
        for k in range(4):
            sid = ival(t[ST_LEVELS[k]]) if ST_LEVELS[k] < len(t) else None
            if sid is None or sid < 0 or sid not in src.sd_by:
                continue
            for pos, lab, v in src.cells(sid):
                if lab == label and v == imp:
                    levels.append(k + 1)
                    tips.append(src.tip(sid))
        if not levels:
            skipped.append((imp, 'khong o nao cua tpl %d cap 1-4 tro toi ID nay voi nhan "%s"' % (tid, label)))
            continue
        if imp in cur_by:
            skipped.append((imp, 'da co dong tren bang song — bo qua (idempotent)'))
            continue
        donor = cur_by.get(donor_id)
        if donor is None or donor_id not in donor_base:
            skipped.append((imp, 'dong mau %d khong co o moc goc %s' % (donor_id, P1_DONOR_BASE)))
            continue
        ok = True
        for n in cond.get('tip', []):
            if not any(n in x for x in tips):
                skipped.append((imp, 'tip cap 1-4 khong chua "%s"' % n))
                ok = False
                break
        if not ok:
            continue
        if 'dur' in cond and g(donor[SI_DURATION]).strip() != cond['dur']:
            skipped.append((imp, 'dong mau %d co 总持续时间=%s, cho %s'
                            % (donor_id, g(donor[SI_DURATION]).strip(), cond['dur'])))
            continue

        def param(row, lab):
            for m in range(SI_PARAM_N):
                if g(row[SI_PARAM0 + 3 * m]).strip() == lab:
                    return SI_PARAM0 + 3 * m + 1, g(row[SI_PARAM0 + 3 * m + 1]).strip()
            return None, None
        bad = None
        for lab, want in (cond.get('pdonor') or {}).items():
            _c, got = param(donor, lab)
            if got != want:
                bad = 'dong mau %d co %s=%s, cho %s' % (donor_id, lab, got, want)
                break
        if bad:
            skipped.append((imp, bad))
            continue
        if 'sib' in cond:
            slab, sname = cond['sib']
            hit = False
            for k in range(4):
                sid = ival(t[ST_LEVELS[k]]) if ST_LEVELS[k] < len(t) else None
                if sid is None or sid < 0 or sid not in src.sd_by:
                    continue
                for pos, lab, v in src.cells(sid):
                    if lab == slab and v in cur_by and sname in g(cur_by[v][SI_NAME]):
                        hit = True
            if not hit:
                skipped.append((imp, 'o anh em "%s" khong tro toi dong ten "%s"' % (slab, sname)))
                continue

        row = list(donor) + [b''] * max(0, src.ncol - len(donor))
        row = row[:src.ncol]
        row[0] = str(imp).encode('ascii')
        if name:
            row[SI_NAME] = name.encode('gbk')
        se = ival(row[SI_SE])
        se_note = ''
        if se is not None and se >= 0 and se not in src.se_cy:
            row[SI_SE] = b'-1'
            se_note = ' SE %d -> -1' % se
        changes = []
        if cond.get('set_dur'):
            old = g(row[SI_DURATION]).strip()
            if old != str(cond['set_dur']):
                changes.append(u'\u603b\u6301\u7eed\u65f6\u95f4 %s\u2192%d' % (old, cond['set_dur']))
            row[SI_DURATION] = str(cond['set_dur']).encode('ascii')
        for lab, want in (cond.get('set_par') or {}).items():
            c, old = param(row, lab)
            if c is None or old in ('', '0', '-1'):
                bad = 'nhan %s cua dong mau dang tat (%s) — khong bat tham so moi' % (lab, old)
                break
            row[c] = want.encode('ascii')
            if old != want:
                changes.append(u'%s %s\u2192%s' % (lab, old, want))
        if bad:
            skipped.append((imp, bad))
            continue
        cur_by[imp] = row
        made += 1
        ev = []
        for n in cond.get('tip', []):
            ev.append('tip "%s"' % n)
        if 'dur' in cond:
            ev.append(u'm\u1eabu %d \u0111ang %s ms' % (donor_id, cond['dur']))
        for lab, want in (cond.get('pdonor') or {}).items():
            ev.append('%s=%s' % (lab, want))
        tsv.append([str(imp), MENPAI.get(mp, str(mp)), skill, str(tid),
                    ','.join(str(x) for x in levels), label, str(donor_id),
                    g(donor[SI_NAME]).strip(), g(row[SI_LOGIC]).strip(),
                    '; '.join(changes) if changes else u'nguy\u00ean v\u1eb9n', 'ok' + se_note,
                    ' | '.join(ev), note])

    os.makedirs(os.path.join(args.out, 'configs'), exist_ok=True)
    write_table(os.path.join(args.out, SI), cur['types'], cur['names'],
                [cur_by[i] for i in sorted(cur_by)], cur['eol'])
    with open(os.path.join(args.out, 'impact_p1fill.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        for r in tsv:
            f.write('\t'.join(r) + '\n')
    with open(os.path.join(args.out, 'impact_p1fill_declined.txt'), 'w', encoding='utf-8', newline='\n') as f:
        for k, v in P1_DECLINED.items():
            f.write('== %s\n   %s\n\n' % (k, v))
        f.write('== BO trong lan chay nay (dieu kien khong dat / da co dong)\n')
        for i, w in skipped:
            f.write('   %d: %s\n' % (i, w))
    out = {'base': args.base, 'khai_bao': len(P1_CELLS), 'da_dung': made, 'bo': len(skipped),
           'bo_chi_tiet': ['%d: %s' % x for x in skipped], 'nhom_co_y_khong_dung': len(P1_DECLINED)}
    print(json.dumps(out, ensure_ascii=False, indent=1))
    with open(os.path.join(args.out, 'p1fill.json'), 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    return 0


def cmd_tipmatch(args):
    """đo tỉ lệ 'số của dòng khớp tip CY' trên các dòng đã bù thuộc phạm vi — dùng để so trước/sau."""
    src = Src(args.base)
    path = os.path.join(args.staging, SI) if args.staging else os.path.join(R, SI)
    cur = read_table_bytes(open(path, 'rb').read())
    cur_by = {int(r[0]): r for r in cur['rows']}
    added = set(cur_by) - set(src.si_by)
    own = scope_rows(src, added, args.scope, cur_by if args.children else None)
    tot = hit = skills_tot = skills_hit = 0
    per_skill = collections.defaultdict(lambda: [0, 0])
    for iid, (sid, lv, lab, tid, skill, mp) in own.items():
        nums = tip_numbers(tip_for(src, sid, skill, lab))
        row = cur_by[iid]
        vals = set()
        d = ival(row[SI_DURATION])
        if d and d > 0:
            vals.update({d, d // 1000})
            if d % 60000 == 0:
                vals.add(d // 60000)
        scalar = bool(d and d > 0)
        for k in range(SI_PARAM_N):
            lb = g(row[SI_PARAM0 + 3 * k]).strip()
            v = ival(row[SI_PARAM0 + 3 * k + 1])
            if v is None or v in (0, -1):
                continue
            vals.add(v)
            if any(w in lb for w in MAG_WORDS):
                scalar = True
        # chỉ đếm dòng có ít nhất một tham số ĐỘ LỚN (hoặc thời lượng); dòng chỉ mang ID/tập hợp/script
        # thì tip không bao giờ có số tương ứng, đưa vào mẫu sẽ làm tỉ lệ vô nghĩa
        if not scalar:
            continue
        tot += 1
        ok = bool(vals & nums)
        hit += 1 if ok else 0
        per_skill[(mp, skill)][0] += 1
        per_skill[(mp, skill)][1] += 1 if ok else 0
    for _, (a, b) in per_skill.items():
        skills_tot += 1
        skills_hit += 1 if b else 0
    out = {'path': path, 'rows_checked': tot, 'rows_number_matches_tip': hit,
           'pct': round(100.0 * hit / tot, 1) if tot else 0.0,
           'skills': skills_tot, 'skills_with_match': skills_hit}
    print(json.dumps(out, ensure_ascii=False, indent=1))
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(out, f, ensure_ascii=False, indent=1)
    return 0


# ---------------------------------------------------------------- lệnh
def cmd_plan(args):
    src = Src(args.base)
    refs = collect_refs(src)
    missing_refs = [x for x in refs if x[4] not in src.si_by]
    missing_ids = set(x[4] for x in missing_refs)
    groups, owner = build_groups(src, missing_ids)
    der = Deriver(src, missing_ids)
    der.derive(groups, owner)

    os.makedirs(os.path.join(args.out, 'configs'), exist_ok=True)
    rows = list(src.si['rows']) + [der.new[i][0] for i in sorted(der.new)]
    rows.sort(key=lambda r: int(r[0]))
    write_table(os.path.join(args.out, SI), src.si['types'], src.si['names'], rows, src.si['eol'])

    # P1 = kỹ năng 15 phái, cấp 1–4 (ô = (SkillData, vị trí))
    p1 = set()
    for r in src.st['rows']:
        mp = ival(r[ST_MENPAI])
        if mp is None or mp < 0 or mp > 15 or mp == 9:
            continue
        for k in range(4):
            sid = ival(r[ST_LEVELS[k]])
            if sid is None or sid < 0 or sid not in src.sd_by:
                continue
            for pos, lab, v in src.cells(sid):
                if v in missing_ids:
                    p1.add((sid, pos, v))
    p1_fixed = set(x for x in p1 if x[2] in der.new)

    tsv = [['impact_id', 'luat', 'dong_mau', 'chac_chan', 'logic', 'ten', 'phai', 'ky_nang', 'cap', 'nhan', 'so_khop_tip', 'ly_do']]
    for i in sorted(missing_ids):
        if i in der.new:
            inf = der.new[i][1]
            tsv.append([str(i), inf['rule'], str(inf['donor'] or ''), inf['confidence'], str(inf['logic']), inf['name'],
                        MENPAI.get(inf['menpai'], str(inf['menpai'])), inf['skill'], str(inf['level']), inf['label'],
                        ','.join(str(x) for x in inf['tip_match']), inf['why']])
        else:
            o = owner.get(i)
            sk = o[0].skill if o else ''
            mp = MENPAI.get(o[0].menpai, '') if o else ''
            lab = o[0].label if o else ''
            tsv.append([str(i), 'chua-bu', '', '', '', '', mp, sk, str(o[1]) if o else '', lab, '',
                        'không có dòng thật cùng tên / cặp HJ / GMVisible / GL'])
    with open(os.path.join(args.out, 'impact_data.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        for r in tsv:
            f.write('\t'.join(r) + '\n')

    rep = faction_report(src, der)
    by_rule = collections.Counter(v[1]['rule'] for v in der.new.values())
    by_conf = collections.Counter(v[1]['confidence'] for v in der.new.values())
    by_mp = collections.Counter(MENPAI.get(v[1]['menpai'], 'khác') for v in der.new.values())
    plan = {'rev': src.rev, 'base': args.base, 'refs': len(refs), 'missing_refs': len(missing_refs), 'missing_ids': len(missing_ids),
            'derived': len(der.new), 'by_rule': dict(by_rule), 'by_confidence': dict(by_conf), 'by_menpai': dict(by_mp),
            'si_rows_before': len(src.si['rows']), 'si_rows_after': len(rows),
            'p1_cells': len(p1), 'p1_cells_fixed': len(p1_fixed),
            'p1_ids': len(set(x[2] for x in p1)), 'p1_ids_fixed': len(set(x[2] for x in p1 if x[2] in der.new)),
            'faction': rep}
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1)
    print('HEAD %s | tham chiếu %d | ô thiếu %d | ID thiếu %d' % (src.rev, len(refs), len(missing_refs), len(missing_ids)))
    print('bù được %d ID (%s) | chắc chắn %s' % (len(der.new), dict(by_rule), dict(by_conf)))
    print('ô P1 (15 phái cấp 1–4): %d → còn %d thiếu' % (len(p1), len(p1) - len(p1_fixed)))
    print('phái: trước ok %d / none %d → sau ok %d / none %d' %
          (rep['totals'].get('before_ok', 0), rep['totals'].get('before_none', 0),
           rep['totals'].get('after_ok', 0), rep['totals'].get('after_none', 0)))
    print('bảng: %d → %d dòng' % (len(src.si['rows']), len(rows)))


def cmd_apply(args):
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'impact-data-' + stamp)
    s, d = os.path.join(args.staging, SI), os.path.join(R, SI)
    if open(s, 'rb').read() == open(d, 'rb').read():
        print('trùng byte, bỏ qua:', SI)
        return
    if args.dry_run:
        print('DRY-RUN sẽ chép', s, '->', d)
        return
    os.makedirs(os.path.dirname(os.path.join(bdir, SI)), exist_ok=True)
    shutil.copy2(d, os.path.join(bdir, SI))
    shutil.copy2(s, d)
    print('đã chép %s (sao lưu %s)' % (SI, bdir))


def cmd_verify(args):
    src = Src(args.base)
    path = os.path.join(args.staging, SI) if args.staging else os.path.join(R, SI)
    raw = open(path, 'rb').read()
    t = read_table_bytes(raw)
    errs, warn = [], []
    try:
        raw.decode('gbk')
    except UnicodeDecodeError as e:
        errs.append('không phải GBK: %s' % e)
    ncol = len(t['types'])
    for r in t['rows']:
        if len(r) != ncol:
            errs.append('dòng %s: %d cột (cần %d)' % (g(r[0]), len(r), ncol))
            break
    ids = [int(r[0]) for r in t['rows']]
    if ids != sorted(ids):
        errs.append('ID không tăng dần')
    if len(set(ids)) != len(ids):
        errs.append('ID trùng')
    new_by = {int(r[0]): r for r in t['rows']}
    added = sorted(set(new_by) - set(src.si_by))
    changed = [i for i in set(new_by) & set(src.si_by) if new_by[i] != src.si_by[i]]
    if changed:
        errs.append('%d dòng cũ bị đổi: %s' % (len(changed), changed[:6]))

    logics = installed_logics(src)
    # buff rỗng: logic chưa cài mà MỌI dòng là hiệu ứng duy trì → null_logic_buff; dòng mới không được lật cờ này
    timed_only_before, base_logics = {}, set()
    for r in src.si['rows']:
        lg = ival(r[SI_LOGIC])
        if lg is None:
            continue
        base_logics.add(lg)
        ot = ival(r[SI_OVERTIME]) == 1
        timed_only_before[lg] = timed_only_before.get(lg, True) and ot
    flipped, unmapped = [], []
    try:
        cy_mapped = cyfour_mapped()
    except Exception as e:                      # không có cy_four (bản khác) → bỏ qua phép kiểm này
        cy_mapped, warn = None, warn + ['không đọc được cy_four native_config: %s' % e]
    for i in added:
        r = new_by[i]
        lg = ival(r[SI_LOGIC])
        if lg is None:
            errs.append('dòng mới %d không có 逻辑ID' % i)
            continue
        if lg not in base_logics:
            # logic chưa từng có dòng nào → engine phải đăng ký mới; ≥ 8000 sẽ assert khi khởi động
            errs.append('dòng mới %d dùng logic %d chưa có dòng nào trong bảng gốc' % (i, lg))
        if lg >= 8000 and cy_mapped is not None and i not in cy_mapped:
            # cy_four_combat/engine.lua:67 assert(config.impacts[data_index]) → thiếu mục ánh xạ vị trí là
            # "unmapped positional impact" mỗi lần impact được kích hoạt (cả lúc đăng nhập lẫn lúc dùng chiêu)
            unmapped.append((i, lg))
        if lg not in logics and timed_only_before.get(lg, True) and ival(r[SI_OVERTIME]) != 1:
            flipped.append((i, lg))
        se = ival(r[SI_SE])
        if se is not None and se >= 0 and se not in src.se_cy:
            errs.append('dòng mới %d có SE %d không có ở client CY' % (i, se))
        for k in range(SI_PARAM_N):
            lab = g(r[SI_PARAM0 + 3 * k])
            v = ival(r[SI_PARAM0 + 3 * k + 1])
            if v is not None and v > 100 and ('效果ID' in lab or '子效果' in lab or '效果集合' in lab or 'BUFF' in lab.upper()) \
                    and '几率' not in lab and v not in new_by:
                warn.append('dòng mới %d: ô "%s" trỏ impact %d không có dòng' % (i, lab, v))
    if flipped:
        errs.append('%d dòng mới làm logic chưa cài rơi từ buff rỗng sang std_impact_003: %s' % (len(flipped), flipped[:6]))
    if unmapped:
        errs.append('%d dòng mới dùng logic cy_four ≥ 8000 nhưng Data_Index chưa có trong '
                    'cy_four_combat/native_config.lua impacts={} → engine.lua:67 "unmapped positional impact": %s'
                    % (len(unmapped), unmapped[:6]))

    refs = collect_refs(src)
    still = sorted(set(x[4] for x in refs if x[4] not in new_by))
    out = {'path': path, 'sha256': sha(path), 'rows': len(t['rows']), 'added': len(added), 'changed': len(changed),
           'refs': len(refs), 'refs_missing_ids': len(still), 'cyfour_unmapped': len(unmapped),
           'errors': errs, 'warnings': warn[:40],
           'staging_equals_R': (raw == open(os.path.join(R, SI), 'rb').read()) if args.staging else True}
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(out, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: v for k, v in out.items() if k != 'warnings'}, ensure_ascii=False, indent=1))
    if warn:
        print('cảnh báo (%d):' % len(warn), *warn[:10], sep='\n  ')
    return 1 if errs else 0


def main():
    ap = argparse.ArgumentParser(description='impact-data — bù dòng StandardImpact thiếu bằng nguồn thật')
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('plan')
    p.add_argument('--out', required=True)
    p.add_argument('--base', default='HEAD', help='mốc git của R dùng làm nền (mặc định HEAD)')
    p.set_defaults(fn=cmd_plan)
    p = sub.add_parser('apply')
    p.add_argument('--staging', required=True)
    p.add_argument('--dry-run', action='store_true')
    p.set_defaults(fn=cmd_apply)
    p = sub.add_parser('fix', help='chỉnh SỐ của dòng đã bù cho khớp tip CY (không đổi logic/nhãn/cấu trúc)')
    p.add_argument('--out', required=True)
    p.add_argument('--base', required=True, help='mốc git của R TRƯỚC khi impact-data bù (để biết dòng nào là của mình)')
    p.add_argument('--scope', default='p1', choices=['p1', 'all'])
    p.add_argument('--no-children', dest='children', action='store_false', help='không đi tiếp xuống dòng con 子效果')
    p.set_defaults(fn=cmd_fix, children=True)
    p = sub.add_parser('cyfour', help='dòng logic ≥ 8000 thiếu ánh xạ vị trí trong cy_four native_config')
    p.add_argument('--out', required=True)
    p.add_argument('--base', required=True)
    p.add_argument('--tsv', nargs='*', help='impact_data*.tsv để lấy ID dòng mẫu')
    p.add_argument('--repair', action='store_true', help='(chỉ khi được yêu cầu) thay dòng mẫu logic < 8000, không có thì xoá dòng')
    p.set_defaults(fn=cmd_cyfour)
    # `%%`: argparse nội suy chuỗi help qua toán tử `%` → một dấu `%` trần làm `--help` ném ValueError
    p = sub.add_parser('scale', help='ô "N %% đòn đánh thường" → dòng logic 115 (伤害量缩放系数) theo tip CY')
    p.add_argument('--out', required=True)
    p.add_argument('--base', required=True, help='mốc git của R TRƯỚC khi impact-data bù')
    p.set_defaults(fn=cmd_scale)
    p = sub.add_parser('interp', help='nội suy theo cấp cho dòng `series` (chỉ 参数值/总持续时间, ≥ 2 mốc thật)')
    p.add_argument('--out', required=True)
    p.add_argument('--base', required=True, help='mốc git của R TRƯỚC khi impact-data bù (6ca25a8)')
    p.add_argument('--tsv', nargs='*', required=True, help='impact_data_final.tsv — để biết dòng nào là `series`')
    p.add_argument('--scale-tsv', nargs='*', help='impact_scale.tsv — ô đã chuyển sang logic 115, không đụng')
    p.set_defaults(fn=cmd_interp)
    p = sub.add_parser('p1fill', help='bù ô impact cấp 1–4 còn thiếu bằng dòng mẫu thật (bảng P1_CELLS)')
    p.add_argument('--out', required=True)
    p.add_argument('--base', default='HEAD')
    p.set_defaults(fn=cmd_p1fill)
    p = sub.add_parser('tipmatch', help='đo tỉ lệ số của dòng đã bù khớp với số trong tip CY')
    p.add_argument('--base', required=True)
    p.add_argument('--staging')
    p.add_argument('--scope', default='p1', choices=['p1', 'all'])
    p.add_argument('--no-children', dest='children', action='store_false')
    p.add_argument('--out')
    p.set_defaults(fn=cmd_tipmatch, children=True)
    p = sub.add_parser('verify')
    p.add_argument('--base', default='HEAD', help='mốc git của R dùng làm nền để đếm dòng thêm/đổi')
    p.add_argument('--staging')
    p.add_argument('--out')
    p.set_defaults(fn=cmd_verify)
    a = ap.parse_args()
    sys.exit(a.fn(a) or 0)


if __name__ == '__main__':
    main()
