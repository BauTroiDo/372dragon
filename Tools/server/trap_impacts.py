#!/usr/bin/env python3
"""trap-impacts — dựng dòng `StandardImpact` cho các hiệu ứng mà BẪY của CY trỏ tới nhưng server chưa có.

Nối tiếp `trap_data.py` (nhập dòng `SpecialObjData` của CY). Một bẫy CY chỉ có tác dụng khi `效果N` của nó có dòng
trong `StandardImpact`; sau khi nhập 111 dòng bẫy vẫn còn 94 ID impact chưa có dòng, và **0/94** có tên trong
`GMVisible_Impact` nên luật `gmname` của `impact_data.py` không dùng được.

Luật ở đây (nối tiếp luật `hj` của impact-data, chỉ khác đường đi):

    kỹ năng CY (SkillData_V1 của server) --ô nhãn bẫy--> bẫy T (bảng CY) --效果N--> impact I (thiếu)
    kỹ năng HJ cùng TÊN + cùng PHÁI + cùng CẤP (client CYHJ091026) --ô impact--> impact J
    J đã có dòng trong StandardImpact của server  ==>  chép NGUYÊN dòng J sang ID I (chỉ đổi Data_Index)

Chỉ nhận khi HJ cho **đúng một** giá trị impact ở cấp đó (ưu tiên nhãn `|引导周期的附加效果1`, rồi
`|生效一次的附加效果1`, rồi ô impact duy nhất) — mọi trường hợp mơ hồ bị bỏ và ghi lý do vào TSV.
Không bịa số: dòng sinh ra là bản sao nguyên vẹn của một dòng thật.

**17/09 đợt 2 (agent `trap-impacts`)** — 78 ID mà luật `hj` bỏ được bù bằng hai luật mới, cả hai đều dựng
dòng từ MỘT DÒNG CÓ THẬT trong bảng (mọi dòng mẫu đều đã có ở mốc `6ca25a8`, tức trước khi impact-data thêm gì):

  `pct115` — tip CY ghi "造成N%普通攻击伤害/普攻伤害" ⇒ dòng `逻辑ID = 115` (`伤害量缩放系数`) dựng từ mẫu thật
             `43918 撼岳群攻效果`, đúng khuôn mà `impact_data.py scale` đã dùng (xem `impact-data_vi.md` mục 6.3).
  `copy`   — chép NGUYÊN một dòng thật cùng kỹ năng / cùng vai trò, chỉ đổi `Data_Index` (và khi tip cho đúng
             một con số cho đúng nhãn ấy thì đặt `总持续时间`/`参数值` theo tip — luật mục 6 của impact-data).

Hai bảng `SCALE_CELLS` / `COPY_CELLS` chọn tay (như `SCALE_CELLS` của `impact_data.py`), nhưng **mỗi mục đều
khai báo bằng chứng và công cụ tự kiểm lại trên bảng sống**: chuỗi phải có trong tip, `参数值` của dòng mẫu,
ô `强化陷阱1/2` của SkillData, hoặc `效果N` của một bẫy CY khác. Sai một điều kiện ⇒ mục đó bị BỎ và ghi lý do,
không âm thầm sinh dòng.

  trap_impacts.py plan   --out <dir> [--only I,I]    dựng <dir>/configs/StandardImpact.txt + plan.json + trap_impacts.tsv
  trap_impacts.py apply  --staging <dir> [--dry-run] chép vào R, sao lưu R/backups/trap-impacts-<UTC>/
  trap_impacts.py verify [--staging <dir>]           GBK, ID tăng dần, dòng cũ y nguyên, logic của dòng mới đã đăng ký,
                                                     SE có ở client CY, không có dòng cy_four ≥ 8000 thiếu ánh xạ

Chạy trong WSL TLBB bằng root: `python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/trap_impacts.py <lệnh>`.
Đặc tả: `Docs/specs/server/trap-data_vi.md`.
"""
import argparse
import bisect
import collections
import datetime
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table, write_table, g, sha  # noqa: E402
import trap_data  # noqa: E402

R = trap_data.R
HJ_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/CYHJ091026/Config'
CY_DIR = trap_data.CY_DIR
SI = 'configs/StandardImpact.txt'
ST = 'configs/SkillTemplate_V1.txt'
SD = 'configs/SkillData_V1.txt'
GS = 'GameServer'
CY_FOUR_CFG = 'lualib/cy_four_combat/native_config.lua'
MARK = 'trap-impacts'

ST_MENPAI, ST_NAME = 2, 3
ST_LEVELS = list(range(58, 74))
SD_TIP = 3
SI_ID, SI_NAME, SI_LOGIC, SI_OVERTIME, SI_SE = 0, 1, 2, 4, 5
SI_DURATION = 20                           # 总持续时间(毫秒)
SI_PARAM0, SI_PARAM_N = 27, 16             # bộ ba (说明, 值, 步长) × 16
HJ_PAIRS = list(range(24, 48, 2))          # bố cục GL: 12 cặp (参数说明, 参数值) từ cột 24
PREFER = ['|引导周期的附加效果1', '|生效一次的附加效果1']
COLOR_RE = re.compile(r'#c[0-9A-Fa-f]{6}|#[rRWGYBnbe]')


def ival(b):
    try:
        return int(g(b).strip())
    except ValueError:
        return None


class Src:
    def __init__(self):
        self.si = read_table(os.path.join(R, SI))
        self.si_by = {int(r[0]): r for r in self.si['rows']}
        self.st = read_table(os.path.join(R, ST))
        self.sd = read_table(os.path.join(R, SD))
        self.sd_by = {int(r[0]): r for r in self.sd['rows']}
        names = [g(x).strip() for x in (self.sd['names'] or [])]
        self.sd_pairs = [(i, i + 1) for i, n in enumerate(names) if n == '参数说明']
        # SkillData -> (template, cấp)
        self.data_of = {}
        self.tpl = {}
        for r in self.st['rows']:
            tid = int(r[0])
            self.tpl[tid] = r
            for k, c in enumerate(ST_LEVELS):
                v = ival(r[c]) if c < len(r) else None
                if v is not None and v >= 0:
                    self.data_of[v] = (tid, k + 1)
        self.hj_st = read_table(os.path.join(HJ_DIR, 'SkillTemplate_V1.txt'))
        self.hj_sd = {int(r[0]): r for r in read_table(os.path.join(HJ_DIR, 'SkillData_V1.txt'))['rows']}
        self.hj_by_name = collections.defaultdict(list)
        self.hj_data_of = {}
        self.hj_menpai = {}
        for r in self.hj_st['rows']:
            tid = int(r[0])
            self.hj_by_name[g(r[ST_NAME]).strip()].append(tid)
            self.hj_menpai[tid] = ival(r[ST_MENPAI])
            for k, c in enumerate(ST_LEVELS):
                v = ival(r[c]) if c < len(r) else None
                if v is not None and v >= 0:
                    self.hj_data_of[(tid, k + 1)] = v
        # dòng mẫu chỉ được lấy từ bảng CỦA SERVER (bố cục 81 cột) — xem BẪY của impact-data
        self.ncol = len(self.si['types'])
        self.se_cy = set(int(r[0]) for r in read_table(os.path.join(CY_DIR, 'ImpactSEData_V1.txt'))['rows'])
        self.cy = trap_data.read_cy()

    def skill_of_data(self, sd_id):
        return self.data_of.get(sd_id)

    def tip(self, sd_id):
        r = self.sd_by.get(sd_id)
        return COLOR_RE.sub('', g(r[SD_TIP])).replace('\\n', ' ') if r is not None else ''

    def sd_cell(self, sd_id, label):
        """giá trị ô `参数说明 == label` của một SkillData (None nếu không có)."""
        r = self.sd_by.get(sd_id)
        if r is None:
            return None
        for a, b in self.sd_pairs:
            if a < len(r) and b < len(r) and g(r[a]).strip() == label:
                return ival(r[b])
        return None

    def cy_trap_effect(self, trap_id, slot):
        """`效果N` của một dòng bẫy trong bảng CY (None nếu không có)."""
        row = self.cy.get(trap_id)
        if row is None:
            return None
        i = trap_data.PAIR0_CY
        while i + 1 < len(row):
            if g(row[i]).strip() == slot:
                return ival(row[i + 1])
            i += 2
        return None

    def param(self, row, label):
        """(vị trí, giá trị) của tham số mang nhãn `label` trong một dòng StandardImpact."""
        for k in range(SI_PARAM_N):
            p = SI_PARAM0 + 3 * k
            if p + 1 < len(row) and g(row[p]).strip().strip('"') == label:
                return p, g(row[p + 1]).strip()
        return None, None

    def pad(self, row):
        return (list(row) + [b''] * self.ncol)[:self.ncol]

    def hj_impact(self, name, menpai, level):
        """Trả (impact_id, nhãn, lý_do) — impact_id None nếu không dùng được."""
        cands = []
        for tid in self.hj_by_name.get(name, []):
            if self.hj_menpai.get(tid) != menpai:
                continue
            sid = self.hj_data_of.get((tid, level))
            if sid is None or sid not in self.hj_sd:
                continue
            row = self.hj_sd[sid]
            vals = {}
            for p in HJ_PAIRS:
                if p + 1 >= len(row):
                    break
                label, value = g(row[p]).strip(), ival(row[p + 1])
                if label and label != '无' and value is not None and value > 0:
                    vals[label] = value
            cands.append((tid, vals))
        if not cands:
            return None, '', 'HJ khong co ky nang cung ten+phai+cap'
        if len(cands) > 1:
            return None, '', 'HJ co %d template cung ten+phai' % len(cands)
        vals = cands[0][1]
        for label in PREFER:
            if label in vals:
                return vals[label], label, ''
        uniq = set(vals.values())
        if len(uniq) == 1:
            label = sorted(vals)[0]
            return vals[label], label, ''
        return None, '', 'HJ co %d o impact khac nhau: %s' % (len(uniq), sorted(vals)[:4])


def missing_trap_impacts(src):
    """impact thiếu -> danh sách (trap_id, sd_id) tham chiếu."""
    cy = trap_data.read_cy()
    ref = trap_data.referenced_traps()
    have = set(src.si_by)
    out = collections.defaultdict(list)
    for tid, info in ref.items():
        row = cy.get(tid)
        if not row:
            continue
        for imp in trap_data.cy_impacts(row):
            if imp not in have:
                for sd_id in sorted(info['skills']):
                    out[imp].append((tid, sd_id))
    return out


# ================================================================ luật `pct115` — "N % đòn đánh thường"
# CY diễn đạt "造成N%普通攻击伤害" bằng một DÒNG StandardImpact riêng mang 逻辑ID = 115, tham số 0 =
# 伤害量缩放系数 (`StdImpact115_T::OnActive` @0xa5f2f8 nạp DataIndex 0 rồi nhân hệ số). Module Lua
# `scene/skill/impact_logic/std_impact_115.lua` đã cài và đăng ký `[115]` trong `impactenginer.lua`.
# Bẫy gọi `impactenginer:send_impact_to_unit(muc_tieu, 效果N, owner, ...)` nên `caster` của impact là chủ bẫy
# ⇒ logic 115 tra được người gây và dựng được đòn đánh thường (`services/scene/special_obj/trap.lua`).
SCALE_DONOR = 43918                        # 撼岳群攻效果 (逻辑ID=115, 是否持续=0, SE 370, 伤害量缩放系数=100)
SCALE_LABEL = '伤害量缩放系数'

# (impact, template, hệ số, [chuỗi PHẢI có trong tip của kỹ năng dẫn tới impact này], tên dòng, ghi chú)
SCALE_CELLS = [
    (59194, 3448, 80, ['造成80%普攻伤害', '每多移动1名队友伤害增加20%'], '借东风', '鬼谷 借东风 — 1 đồng đội: 80 %'),
    (59195, 3448, 100, ['造成80%普攻伤害', '每多移动1名队友伤害增加20%'], '借东风', '2 đồng đội: 80 + 20×1'),
    (59196, 3448, 120, ['造成80%普攻伤害', '每多移动1名队友伤害增加20%'], '借东风', '3 đồng đội: 80 + 20×2'),
    (59197, 3448, 140, ['造成80%普攻伤害', '每多移动1名队友伤害增加20%'], '借东风', '4 đồng đội: 80 + 20×3'),
    (59198, 3448, 160, ['造成80%普攻伤害', '每多移动1名队友伤害增加20%'], '借东风', '5 đồng đội: 80 + 20×4'),
    (59757, 841, 80, ['造成80%普通攻击的伤害'], '蝎行无阻', '星宿 蝎行无阻 — 巨蝎 giai đoạn 1 (tpl 841)'),
    (59758, 844, 90, ['造成90%普通攻击的伤害'], '蝎行无阻', '巨蝎 giai đoạn 2 (tpl 844)'),
    (59759, 847, 100, ['造成100%普通攻击的伤害'], '蝎行无阻', '巨蝎 giai đoạn 3 (tpl 847)'),
    (52904, 5238, 100, ['每秒造成100%普通攻击伤害'], '棹歌中流', '棹歌中流 (tpl 5238) — mỗi nhịp 1 s'),
    (56413, 5520, 50, ['每秒造成50%普通攻击伤害'], '棹歌中流', '棹歌中流 (tpl 5520) cấp 1–7'),
    (56414, 5520, 100, ['每秒造成100%普通攻击伤害'], '棹歌中流', '棹歌中流 (tpl 5520) cấp 8'),
    (56415, 5520, 150, ['每秒造成150%普通攻击伤害'], '棹歌中流', '棹歌中流 (tpl 5520) cấp 9–16'),
    (52882, 5225, 50, ['每2秒对目标造成50%普通攻击伤害'], '定海神针', '定海神针 (tpl 5225) — mỗi 2 s'),
    (52907, 5240, 200, ['造成200%普通攻击伤害'], '荡千军', '荡千军 (tpl 5240) — 刀域'),
]

# ================================================================ luật `copy` — chép nguyên một dòng thật
# Mỗi mục: impact mới, dòng mẫu, tên mới (None = giữ tên dòng mẫu), và CÁC ĐIỀU KIỆN phải đúng trên bảng sống.
#   tip      : chuỗi phải có trong tip của (ít nhất một) kỹ năng dẫn tới impact này
#   pdonor   : {nhãn tham số: giá trị} mà dòng mẫu phải đang mang
#   dur      : 总持续时间 mà dòng mẫu phải đang mang (kiểm, không đổi)
#   set_dur  : đặt 总持续时间 (chỉ khi tip cho đúng một con số cho đúng loại hiệu ứng của dòng — mục 6 impact-data)
#   set_par  : {nhãn: giá trị} đặt lại độ lớn của tham số ĐANG DÙNG
#   trap     : (bẫy CY G, 效果N) — dòng mẫu phải đúng bằng `效果N` của bẫy G (bằng chứng "cùng bẫy, khác cấp")
#   sdcell   : {nhãn ô SkillData: giá trị} mà SkillData dẫn tới impact này phải mang
COPY_CELLS = [
    # -- 定海神针 (tpl 951, bản phó bản cốt truyện 80): bẫy 1057–1061 là bản sao bẫy 358–362 của tpl 544
    #    (cùng 名称/持续时间/间隔/半径/影响个体数目) và SkillData mang ĐÚNG cặp 强化陷阱1/2 của cấp 8–12 tpl 544.
    (19575, 29959, None, dict(trap=(358, '效果1'), sdcell={'强化陷阱1': 374, '强化陷阱2': 390},
                              pdonor={'伤害数值+': '80'}), '定海神针 tpl 951 ≙ tpl 544 cấp 8'),
    (19576, 29960, None, dict(trap=(359, '效果1'), sdcell={'强化陷阱1': 375, '强化陷阱2': 391},
                              pdonor={'伤害数值+': '90'}), '≙ tpl 544 cấp 9'),
    (19577, 29961, None, dict(trap=(360, '效果1'), sdcell={'强化陷阱1': 376, '强化陷阱2': 392},
                              pdonor={'伤害数值+': '100'}), '≙ tpl 544 cấp 10'),
    (19578, 29962, None, dict(trap=(361, '效果1'), sdcell={'强化陷阱1': 377, '强化陷阱2': 393},
                              pdonor={'伤害数值+': '110'}), '≙ tpl 544 cấp 11'),
    (19579, 29963, None, dict(trap=(362, '效果1'), sdcell={'强化陷阱1': 378, '强化陷阱2': 394},
                              pdonor={'伤害数值+': '120'}), '≙ tpl 544 cấp 12'),
    # -- 罂毒歌 (星宿): 封穴 1 s. Bẫy 1068 lấy 激发特效 `m01_xx_含笑半步癫进阶_01` ⇒ cùng họ với dòng mẫu.
    (32666, 13514, '罂毒歌（CY推导封穴）', dict(tip=['并使目标封穴1秒'], dur='1000'),
     '星宿 罂毒歌 — mẫu 含笑半步癫(封穴) 1 s, cùng phái + cùng hiệu ứng bẫy'),
    # -- 八阵图 (tpl 5594): SỐ trong tip trùng khít 参数值 của ba dòng 八阵图减血 có thật.
    (56713, 2512, None, dict(tip=['直接对目标产生136点伤害'], pdonor={'伤害数值+': '136'}), '八阵图 cấp 1–7'),
    (56714, 2515, None, dict(tip=['直接对目标产生421点伤害'], pdonor={'伤害数值+': '421'}), '八阵图 cấp 8'),
    (56715, 2518, None, dict(tip=['直接对目标产生706点伤害'], pdonor={'伤害数值+': '706'}), '八阵图 cấp 9–16'),
    (56716, 2683, None, dict(tip=['令目标散功2秒'], set_dur=2000), '八阵图(散功) cấp 1–7 — tip 2 s'),
    (56717, 2683, None, dict(tip=['令目标散功3秒'], set_dur=3000), '八阵图(散功) cấp 8 — tip 3 s'),
    (56718, 2683, None, dict(tip=['令目标散功4秒'], set_dur=4000), '八阵图(散功) cấp 9–16 — tip 4 s'),
    # -- 荡千军: bảng còn nguyên bộ dòng thật 4626 (直接伤血 100 điểm) + 4808 (麻痹 2 s) của chính kỹ năng này.
    (56419, 4626, None, dict(tip=['造成100点直接伤害和1秒麻痹'], pdonor={'伤害数值+': '100'}),
     '荡千军 tpl 5523 — 效果1 sát thương thẳng'),
    (56676, 4808, None, dict(tip=['造成100点直接伤害和1秒麻痹'], set_dur=1000), '荡千军 tpl 5523 cấp 1–7 — 麻痹 1 s'),
    (56677, 4808, None, dict(tip=['造成100点直接伤害和1秒麻痹'], set_dur=1000), '荡千军 tpl 5523 cấp 8 — 麻痹 1 s'),
    (56420, 4808, None, dict(tip=['造成100点直接伤害和1秒麻痹'], set_dur=1000), '荡千军 tpl 5523 cấp 9–16 — 麻痹 1 s'),
    (58609, 4626, None, dict(tip=['造成100点直接伤害和2秒麻痹'], pdonor={'伤害数值+': '100'}),
     '荡千军 tpl 5844 — 效果1 sát thương thẳng'),
    (58611, 4808, None, dict(tip=['造成100点直接伤害和2秒麻痹'], dur='2000'),
     '荡千军 tpl 5844 — 麻痹 2 s, dòng mẫu đã đúng 2 s (không đổi số nào)'),
    # -- 阳关三叠 (tpl 5854, bẫy 会心 2178–2183): sáu bẫy nối tiếp ↔ cấp 7–12 của tpl 510 天山, dãy %
    #    trong tip khớp từng cấp (6/6/7/7/8/8) và bẫy 会心 của tpl 510 trỏ đúng dòng mẫu.
    (58688, 2426, None, dict(tip=['增加会心攻击6%'], trap=(1810, '效果1'), dur='13000'), '阳关三叠 ≙ tpl 510 cấp 7 (6 %)'),
    (58689, 2427, None, dict(tip=['增加会心攻击6%'], trap=(1811, '效果1'), dur='13000'), '≙ tpl 510 cấp 8 (6 %)'),
    (58690, 2428, None, dict(tip=['增加会心攻击7%'], trap=(1812, '效果1'), dur='13000'), '≙ tpl 510 cấp 9 (7 %)'),
    (58691, 2429, None, dict(tip=['增加会心攻击7%'], trap=(1813, '效果1'), dur='13000'), '≙ tpl 510 cấp 10 (7 %)'),
    (58692, 2430, None, dict(tip=['增加会心攻击8%'], trap=(1814, '效果1'), dur='13000'), '≙ tpl 510 cấp 11 (8 %)'),
    (58693, 2431, None, dict(tip=['增加会心攻击8%'], trap=(1815, '效果1'), dur='13000'), '≙ tpl 510 cấp 12 (8 %)'),
    # -- 定海神针命中 (tpl 544, bẫy 333–348 是否只对自己生效=1): tip cho đúng một con số cho 命中率.
    #    `命中修正率` là PHẦN TRĂM (impact-data mục 6.0: add_rate → base*(100+rate)/100).
    (21687, 53273, '定海神针（CY推导命中）', dict(tip=['提升10%命中率'], set_par={'命中修正率': '10'}),
     'mẫu 四海归心 (logic 162, 命中修正率, 5 s) — bẫy lặp mỗi 2 s trong suốt đời bẫy'),
]
# 霹雳锁 (tpl 2921 唐门 + tpl 797): 16 cấp cùng một hiệu ứng "每2秒受到0.5秒的麻痹效果".
COPY_CELLS += [
    (i, 63003, '霹雳锁（CY推导麻痹）', dict(tip=['每2秒受到0.5秒的麻痹效果'], dur='500'),
     '唐门 霹雳锁 cấp %d — mẫu 扣冰麻痹 đã đúng 500 ms (không đổi số nào)' % (i - 37799))
    for i in range(37800, 37816)
]
# 蝎行无阻 (星宿): 效果2 theo cấp, tip mọi cấp/mọi giai đoạn đều "并使其眩晕2秒".
COPY_CELLS += [
    (i, 5362, '蝎行无阻（CY推导眩晕）', dict(tip=['并使其眩晕2秒'], set_dur=2000),
     '星宿 蝎行无阻 cấp %d — mẫu 目眩神迷眩晕, tip 2 s' % (i - 59759))
    for i in range(59760, 59776)
]

# ================================================================ ô KHÔNG đi qua bẫy (agent khác báo thiếu)
# `skill-summon` 17/09 báo hai ô của thực thể triệu hồi 唐门 thiếu dòng. Chúng không nằm trong `SpecialObjData`
# nên luật bẫy ở trên không quét tới; dùng đúng luật `copy` và đúng cách tự kiểm.
EXTRA_CELLS = [
    # 诸葛神弩 4468, ô `无敌效果id` — `cy_skill_logic_spec[730].summon.self_impact` áp lên CHÍNH cái nỏ.
    # Mẫu `43847 溯回BUFF(宠物效果)`: logic 14, `无敌否 = 1`, CanAction1/2 và CanMove đều `-1` (vô hiệu ⇒ không
    # khoá hành động) nên nỏ vẫn bắn được trong 3 s bất khả xâm phạm. Chỉ đổi `总持续时间` 2.000 → 3.000 theo tip.
    (37922, 43847, '诸葛神弩（CY推导无敌）',
     dict(tip=['初始3秒无敌'], dur='2000', set_dur=3000,
          pdonor={'无敌否（Unbreakable标记,-1为无效）': '1',
                  '可否使用任何技能（CanAction1标记，-1为无效）': '-1',
                  '可否移动（CanMove标记,-1为无效）': '-1'}),
     '唐门 诸葛神弩 — 无敌 3 s cho thực thể triệu hồi'),
    # 鬼谷 请星入命 3457, ô `长生护盾` (logic kỹ năng 770 áp lên BẢN THÂN). Ô anh em `护盾血量百分比 = 50`
    # trùng khít `施加者护体百分比 = 50` của dòng thật `1467 延年益寿（护盾）` ⇒ chép nguyên, không đổi số nào.
    (59200, 1467, '请星入命（长生护盾）',
     dict(sdcell={'护盾血量百分比': 50}, pdonor={'施加者护体百分比': '50', '伤害吸收率': '100'}, dur='10000'),
     '鬼谷 请星入命 — khiên = 50 % máu người đặt trận'),
    # 星宿 神蝎百相 434 + 蝎行无阻 841/844, ô `免控buff` (logic kỹ năng 170 áp lên BẢN THÂN).
    # Tip: "驱使巨蝎供自身骑乘，持续10秒…不会受到部分控制效果" ⇒ buff miễn khống 10 s. Dòng thật duy nhất mang
    # ĐÚNG tên "免疫控制" và ĐÚNG 10.000 ms là `13519 横扫乾坤（免疫控制）` (免疫级别 160, tập 控制/破绽/虚弱/僵硬/HPDOT).
    (59721, 13519, '神蝎百相（CY推导免控）',
     dict(tip=['持续10秒', '不会受到部分控制效果'], dur='10000', pdonor={'免疫级别': '160', '免疫集合1': '60'}),
     '星宿 神蝎百相 / 蝎行无阻 — miễn khống 10 s (bằng thời lượng cưỡi 巨蝎)'),
]
# 大理 少商剑·刃影 821, ô `附加伤害（逻辑3）` — MỖI CẤP một ID (56851–56866).
# Dòng mẫu là chính bộ `1915–1926 少商剑` (logic 3, **đang dùng** `火系攻击`, SE 6) của kỹ năng cha;
# chỉ chỉnh ĐỘ LỚN của tham số đang dùng theo `{A:… B:…}` trong tip của ĐÚNG cấp đó (luật mục 6 impact-data).
EXTRA_CELLS += [
    (56851 + k, 1915 + min(k, 11), None,
     dict(pused=['火系攻击'], tip=['火攻击增加'], set_ab={'火系攻击': None}),
     '大理 少商剑·刃影 cấp %d — mẫu 少商剑 cấp %d, số lấy từ {A:… B:…} của tip cấp %d'
     % (k + 1, min(k, 11) + 1, k + 1))
    for k in range(16)
]
# --- 17/09 đợt 3: 5 chiêu đang "gửi chiêu không tác dụng" (điều phối, `Build\Logs\2026-09-17-coord\80-con-lai.tsv`).
# Cùng hai luật, chỉ khác đường vào: tham chiếu lấy thẳng từ ô `参数值` của SkillData.
# `cy_skill_logic_spec` cho biết ô nào Lua THẬT SỰ áp (`impacts`/`gender`) và ô nào đang `consume` (bỏ qua).

# (impact, template, hệ số, [chuỗi phải có trong tip], tên dòng, ghi chú) — dòng 逻辑ID = 115
EXTRA_SCALE_CELLS = [
    (59170, 3441, 80, ['立即对目标造成80%普攻伤害', '伤害依序递增20%'], '火烧连营', '鬼谷 火烧连营 — 主目标: 80 %'),
    (59171, 3441, 100, ['立即对目标造成80%普攻伤害', '伤害依序递增20%'], '火烧连营', 'mục tiêu 2: 80 + 20×1'),
    (59172, 3441, 120, ['立即对目标造成80%普攻伤害', '伤害依序递增20%'], '火烧连营', 'mục tiêu 3: 80 + 20×2'),
    (59173, 3441, 140, ['立即对目标造成80%普攻伤害', '伤害依序递增20%'], '火烧连营', 'mục tiêu 4: 80 + 20×3'),
    (59174, 3441, 160, ['立即对目标造成80%普攻伤害', '伤害依序递增20%'], '火烧连营', 'mục tiêu 5: 80 + 20×4'),
    (59175, 3441, 180, ['立即对目标造成80%普攻伤害', '伤害依序递增20%'], '火烧连营', 'mục tiêu 6: 80 + 20×5'),
    (59176, 3441, 200, ['立即对目标造成80%普攻伤害', '伤害依序递增20%'], '火烧连营', 'mục tiêu 7: 80 + 20×6 (tối đa 6 liên kết)'),
]

# Ô đã xét và CỐ Ý không dựng (ghi vào plan.json/TSV để lần sau không phải tra lại từ đầu).
EXTRA_DECLINED = {
    37920: '千机变 4468/2922 ô 免疫控制buff: tip 16 cap KHONG co chu 免疫 nao ⇒ khong biet mien loai khong che nao '
           'va bao lau; cy_skill_logic_spec[731] ap o nay len NGUOI CHOI (to=self), ma moi dong 免疫 co that deu la '
           '"mien tat ca" (52 实物… vinh vien; 346-357 百无禁忌（全免疫） 30 s) hoac mien dung hai loai khong xac dinh '
           '(1091/1593/1880/2168) ⇒ chep bua thanh lo hong. Can nguon khac (bang CY that / tip chieu con).',
    59168: '火烧连营 3441 o 主目标连线: hieu ung DAY NOI (visual), tip khong mo ta; cy_skill_logic_spec[769] dang '
           'CONSUME o nay (khong ap) nen bu cung khong doi hanh vi. Dong "连线" co that (19652 logic 14 dur -1; '
           '42988/42989 阴阳无咎-玩家连线 logic 38 dur -1) deu VINH VIEN, chi dung khi logic tu go day noi — '
           'logic 769 chua lam chuoi lan nen chua go duoc ⇒ de trong.',
    59169: 'nhu 59168 (o 其它目标连线, cung dang CONSUME).',
    59205: '请星入命 3457 o 破军会心: tip khong cho con so nao cho 破军星君; cy_skill_logic_spec[770] dang CONSUME '
           'o nay. Can tip cua chieu 破军星阵 hoac bang CY that.',
    59700: '神蝎百相 434 o 变身男buff: can 变身ID cua 巨蝎 (nam) — KHONG co nguon. Moi dong 变身 that mang ID cua '
           'model khac (8430 神枢战甲, 2060/2061/2003 le hoi, 6934/6935 NPC); MonsterAttrExTable co 巨蝎 11534/11535/11555 '
           'nhung do la ID QUAI, chua chung minh duoc 变身ID tra vao bang do. Hon nua std_impact_014:get_refix_model_id '
           'hien KHONG co cho nao goi trong lualib/services ⇒ co dong cung chua bien than duoc.',
    59703: 'nhu 59700 (变身女buff — con can them ID ban nu).',
    59879: '圣蚕护身 445 o 冰蚕buff: tip mo ta CO CHE cua 冰蚕 (hut hieu ung xau, ton 12 % mau, tien hoa) nhung '
           'khong cho biet BAN THAN buff lam gi ⇒ khong co dong mau dung vai tro. Bang chi co 冰蚕掌 (sat thuong + '
           'giam noi phong), khong phai trang thai gan 冰蚕. Can nguon khac.',
}

PCT_RE = re.compile(r'(?:普通攻击|普攻)(?:额外)?\s*(\d+(?:\.\d+)?)\s*%|(\d+(?:\.\d+)?)\s*%\s*(?:的)?(?:普通攻击|普攻)')
AB_RE = re.compile(r'\{A:(-?\d+(?:\.\d+)?)\s+B:(-?\d+(?:\.\d+)?)\}')


def cell_refs(src, imp):
    """[(0, sd_id)] — mọi SkillData có ô `参数值` = imp (dùng cho ô KHÔNG đi qua bẫy)."""
    out = []
    for sd_id, row in src.sd_by.items():
        for a, b in src.sd_pairs:
            if a < len(row) and b < len(row) and ival(row[b]) == imp:
                out.append((0, sd_id))
                break
    return out


def tips_of(src, refs):
    """mọi tip (đã bỏ mã màu) của các SkillData dẫn tới một impact."""
    return [src.tip(sd_id) for _t, sd_id in refs]


def skill_of(src, refs):
    """mô tả ngắn 'template tên (phái, cấp …, bẫy …)' cho cột ky_nang của TSV."""
    out = []
    for trap_id, sd_id in refs:
        ts = src.skill_of_data(sd_id)
        if not ts:
            continue
        tid, level = ts
        key = (tid, trap_id)
        if key not in [o[0] for o in out]:
            out.append((key, [level]))
        else:
            next(o for o in out if o[0] == key)[1].append(level)
    parts = []
    for (tid, trap_id), levels in out[:3]:
        t = src.tpl[tid]
        parts.append('%d %s (phai %s, cap %s, bay %d)' % (
            tid, g(t[ST_NAME]).strip(), g(t[ST_MENPAI]).strip(),
            '%d-%d' % (min(levels), max(levels)) if len(levels) > 1 else levels[0], trap_id))
    return '; '.join(parts)


def build_scale(src, imp, tpl, pct, needles, name, refs):
    """dòng 逻辑ID = 115 dựng từ mẫu thật SCALE_DONOR, hệ số = % lấy từ tip CY."""
    donor = src.si_by.get(SCALE_DONOR)
    if donor is None or ival(donor[SI_LOGIC]) != 115:
        return None, 'khong co dong mau %d logic 115' % SCALE_DONOR
    tips = tips_of(src, refs)
    if not any(all(n in t for n in needles) for t in tips):
        return None, 'tip khong chua %s' % '/'.join(needles)
    if not any(src.skill_of_data(sd)[0] == tpl for _t, sd in refs if src.skill_of_data(sd)):
        return None, 'impact khong thuoc template %d' % tpl
    row = src.pad(donor)
    row[SI_ID] = str(imp).encode('ascii')
    row[SI_NAME] = name.encode('gbk')
    se = ival(row[SI_SE])
    if se is not None and se >= 0 and se not in src.se_cy:
        row[SI_SE] = b'-1'
    p, _ = src.param(row, SCALE_LABEL)
    if p is None:
        return None, 'dong mau khong co nhan %s' % SCALE_LABEL
    row[p + 1] = ('%d' % pct if float(pct).is_integer() else '%g' % pct).encode('ascii')
    row[p + 2] = b'0'
    return row, '115|%d|%s=%s' % (SCALE_DONOR, SCALE_LABEL, g(row[p + 1]))


def build_copy(src, imp, donor_id, name, cond, refs):
    """chép nguyên dòng mẫu; chỉ đổi Data_Index (+ tên, + số mà tip cho rõ). Sai điều kiện ⇒ bỏ."""
    donor = src.si_by.get(donor_id)
    if donor is None:
        return None, 'khong co dong mau %d' % donor_id
    if 'tip' in cond:
        tips = tips_of(src, refs)
        if not any(all(n in t for n in cond['tip']) for t in tips):
            return None, 'tip khong chua %s' % '/'.join(cond['tip'])
    if 'trap' in cond:
        tid, slot = cond['trap']
        got = src.cy_trap_effect(tid, slot)
        if got != donor_id:
            return None, 'bay CY %d %s = %s, khong phai dong mau %d' % (tid, slot, got, donor_id)
    if 'sdcell' in cond:
        ok = False
        for _t, sd_id in refs:
            if all(src.sd_cell(sd_id, k) == v for k, v in cond['sdcell'].items()):
                ok = True
                break
        if not ok:
            return None, 'SkillData khong mang o %s' % cond['sdcell']
    if 'dur' in cond and g(donor[SI_DURATION]).strip() != cond['dur']:
        return None, 'dong mau co 总持续时间=%s, cho %s' % (g(donor[SI_DURATION]).strip(), cond['dur'])
    for lab, want in (cond.get('pdonor') or {}).items():
        _p, got = src.param(donor, lab)
        if got != want:
            return None, 'dong mau %d co %s=%s, cho %s' % (donor_id, lab, got, want)
    for lab in (cond.get('pused') or []):
        _p, got = src.param(donor, lab)
        if got is None or got in ('', '0', '-1'):
            return None, 'dong mau %d KHONG dung nhan %s (=%s) — khong bat tham so moi' % (donor_id, lab, got)

    row = src.pad(donor)
    row[SI_ID] = str(imp).encode('ascii')
    if name:
        row[SI_NAME] = name.encode('gbk')
    se = ival(row[SI_SE])
    if se is not None and se >= 0 and se not in src.se_cy:
        row[SI_SE] = b'-1'
    notes = []
    if cond.get('set_dur'):
        old = g(row[SI_DURATION]).strip()
        row[SI_DURATION] = str(cond['set_dur']).encode('ascii')
        if old != str(cond['set_dur']):
            notes.append('总持续时间 %s→%d' % (old, cond['set_dur']))
    for lab, want in (cond.get('set_par') or {}).items():
        p, old = src.param(row, lab)
        if p is None:
            return None, 'dong mau khong co nhan %s' % lab
        if old in ('', '0', '-1'):
            return None, 'nhan %s cua dong mau dang tat (%s) — khong bat tham so moi' % (lab, old)
        row[p + 1] = want.encode('ascii')
        if old != want:
            notes.append('%s %s→%s' % (lab, old, want))
    for lab in (cond.get('set_ab') or {}):
        # {A:x B:y} trong tip của ĐÚNG SkillData dẫn tới ID này -> 参数值 = A, 修正步长 = B
        abs_ = set()
        for t in tips_of(src, refs):
            m = AB_RE.search(t)
            if m:
                abs_.add((m.group(1), m.group(2)))
        if len(abs_) != 1:
            return None, 'tip cho %d cap {A:B} khac nhau, khong xac dinh duoc' % len(abs_)
        a, b = abs_.pop()
        p, old = src.param(row, lab)
        if p is None:
            return None, 'dong mau khong co nhan %s' % lab
        oldb = g(row[p + 2]).strip()
        row[p + 1], row[p + 2] = a.encode('ascii'), b.encode('ascii')
        notes.append('%s %s→%s, bước %s→%s' % (lab, old, a, oldb, b))
    return row, 'copy|%d|%s' % (donor_id, ';'.join(notes) if notes else 'nguyen ven')


def cmd_plan(args):
    src = Src()
    miss = missing_trap_impacts(src)
    n_trap_missing = len(miss)
    only = set(int(x) for x in args.only.split(',') if x.strip()) if args.only else None
    picked, skipped = {}, {}
    for imp in sorted(miss):
        if only is not None and imp not in only:
            continue
        donor = label = reason = None
        skill = ''
        trap_used = None
        for trap_id, sd_id in miss[imp]:
            ts = src.skill_of_data(sd_id)
            if not ts:
                reason = 'khong tra duoc template tu SkillData %d' % sd_id
                continue
            tid, level = ts
            tpl = src.tpl[tid]
            name, menpai = g(tpl[ST_NAME]).strip(), ival(tpl[ST_MENPAI])
            skill = '%d %s (phai %s, cap %d, bay %d)' % (tid, name, menpai, level, trap_id)
            d, lb, why = src.hj_impact(name, menpai, level)
            if d is not None and d in src.si_by:
                donor, label, trap_used = d, lb, trap_id
                break
            reason = why or ('HJ impact %s chua co dong tren server' % d)
        if donor is None:
            skipped[imp] = (skill, reason or 'khong co nguon')
        else:
            picked[imp] = (donor, label, skill, trap_used)

    # một dòng mẫu KHÔNG được dùng cho hai hiệu ứng khác nhau của CÙNG một bẫy:
    # bẫy CY có 效果1/效果2 riêng, HJ chỉ có một ô -> không phân biệt được, bỏ cả cụm.
    by_trap = collections.defaultdict(list)
    for imp, (donor, _lb, _sk, trap_id) in picked.items():
        by_trap[(trap_id, donor)].append(imp)
    for (trap_id, donor), imps in by_trap.items():
        if len(imps) > 1:
            for imp in imps:
                skill = picked[imp][2]
                del picked[imp]
                skipped[imp] = (skill, 'bay %d co %d hieu ung khac nhau nhung HJ chi cho mot dong mau %d'
                                % (trap_id, len(imps), donor))

    # ---- luật 2: `pct115` (dòng logic 115 theo tip) và `copy` (chép nguyên dòng thật) cho phần HJ bỏ
    built = {}                       # imp -> (row, luật, dòng mẫu, ghi chú, chi tiết)
    for imp, tpl, pct, needles, name, note in SCALE_CELLS:
        if imp not in skipped or (only is not None and imp not in only):
            continue
        row, info = build_scale(src, imp, tpl, pct, needles, name, miss[imp])
        if row is None:
            skipped[imp] = (skipped[imp][0], 'pct115 bo: %s' % info)
        else:
            built[imp] = (row, 'pct115', SCALE_DONOR, note, info)
    for imp, donor_id, name, cond, note in COPY_CELLS:
        if imp not in skipped or imp in built or (only is not None and imp not in only):
            continue
        row, info = build_copy(src, imp, donor_id, name, cond, miss[imp])
        if row is None:
            skipped[imp] = (skipped[imp][0], 'copy bo: %s' % info)
        else:
            built[imp] = (row, 'copy', donor_id, note, info)
    for imp in built:
        skipped.pop(imp, None)

    # ---- ô không đi qua bẫy: cùng hai luật, tham chiếu lấy thẳng từ ô `参数值` của SkillData
    extra_skipped = {}
    for imp, tpl, pct, needles, name, note in EXTRA_SCALE_CELLS:
        if imp in src.si_by or (only is not None and imp not in only):
            continue
        refs = cell_refs(src, imp)
        if not refs:
            extra_skipped[imp] = ('', 'khong o SkillData nao tro toi %d' % imp)
            continue
        miss[imp] = refs
        row, info = build_scale(src, imp, tpl, pct, needles, name, refs)
        if row is None:
            extra_skipped[imp] = (skill_of(src, refs), 'pct115 bo: %s' % info)
        else:
            built[imp] = (row, 'pct115', SCALE_DONOR, note, info)
    for imp, donor_id, name, cond, note in EXTRA_CELLS:
        if imp in src.si_by or (only is not None and imp not in only):
            continue
        refs = cell_refs(src, imp)
        if not refs:
            extra_skipped[imp] = ('', 'khong o SkillData nao tro toi %d' % imp)
            continue
        miss[imp] = refs
        row, info = build_copy(src, imp, donor_id, name, cond, refs)
        if row is None:
            extra_skipped[imp] = (skill_of(src, refs), 'extra bo: %s' % info)
        else:
            built[imp] = (row, 'extra', donor_id, note, info)
    for imp, why in EXTRA_DECLINED.items():
        if imp in src.si_by or (only is not None and imp not in only):
            continue
        refs = cell_refs(src, imp)
        miss[imp] = refs
        extra_skipped[imp] = (skill_of(src, refs), why)
    skipped.update(extra_skipped)

    rows_new, tsv_lines = [], []
    by_rule = collections.Counter()
    for imp in sorted(set(picked) | set(built) | set(skipped)):
        if imp in picked:
            donor, label, skill, _t = picked[imp]
            row = list(src.si_by[donor])
            row[SI_ID] = str(imp).encode('ascii')
            rows_new.append((imp, row))
            by_rule['hj'] += 1
            tsv_lines.append('%d\thj\t%d\t%s\t%s\t%s\t%s\t' % (
                imp, donor, g(src.si_by[donor][SI_LOGIC]).strip(), skill, 'nhan HJ %s' % label, '', ''))
        elif imp in built:
            row, rule, donor, note, info = built[imp]
            rows_new.append((imp, row))
            by_rule[rule] += 1
            tsv_lines.append('%d\t%s\t%d\t%s\t%s\t%s\t%s\t' % (
                imp, rule, donor, g(row[SI_LOGIC]).strip(), skill_of(src, miss[imp]), note, info))
        else:
            skill, reason = skipped[imp]
            tsv_lines.append('%d\t\t\t\t%s\t\t\t%s' % (imp, skill, reason))

    rows = list(src.si['rows'])
    ids = [int(r[0]) for r in rows]
    for imp, row in rows_new:
        i = bisect.bisect_left(ids, imp)
        rows.insert(i, row)
        ids.insert(i, imp)
    out_file = os.path.join(args.out, SI)
    write_table(out_file, src.si['types'], src.si['names'], rows, src.si['eol'])
    with open(os.path.join(args.out, 'trap_impacts.tsv'), 'w', encoding='utf-8', newline='') as f:
        f.write('impact_moi\tluat\tdong_mau\tlogic\tky_nang\tghi_chu\tbang_chung\tly_do_bo\n')
        f.write('\n'.join(tsv_lines) + '\n')
    plan = {'missing_total': n_trap_missing, 'missing_extra': len(EXTRA_CELLS) + len(EXTRA_SCALE_CELLS) + len(EXTRA_DECLINED),
            'added': len(rows_new), 'skipped': len(skipped),
            'by_rule': dict(by_rule), 'add_ids': [i for i, _ in rows_new],
            'skipped_ids': sorted(skipped), 'skipped_why': {str(k): v[1] for k, v in sorted(skipped.items())},
            'base_rows': len(src.si['rows']), 'out': out_file, 'sha_out': sha(out_file)}
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: plan[k] for k in ('missing_total', 'added', 'skipped', 'by_rule', 'base_rows')},
                     ensure_ascii=False))


def cmd_apply(args):
    src_file = os.path.join(args.staging, SI)
    dst = os.path.join(R, SI)
    base = read_table(dst)
    new = read_table(src_file)
    old = {int(r[0]): r for r in base['rows']}
    for r in new['rows']:
        i = int(r[0])
        if i in old and old[i] != r:
            raise SystemExit('dong cu %d bi doi -> tu choi' % i)
    if args.dry_run:
        print(json.dumps({'dry_run': True, 'base': len(base['rows']), 'new': len(new['rows'])}))
        return
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(R, 'backups', '%s-%s' % (MARK, stamp))
    os.makedirs(bak, exist_ok=True)
    shutil.copy2(dst, os.path.join(bak, 'StandardImpact.txt'))
    shutil.copy2(src_file, dst)
    print(json.dumps({'backup': bak, 'rows': len(new['rows']), 'sha': sha(dst)}, ensure_ascii=False))


def git_show(rev, rel):
    import subprocess
    return subprocess.run(['git', '-C', R, 'show', '%s:%s' % (rev, rel)], capture_output=True, check=True).stdout


def cyfour_mapped():
    """Data_Index có ánh xạ vị trí trong `cy_four_combat/native_config.lua impacts={}` (engine.lua:67)."""
    txt = open(os.path.join(R, GS, CY_FOUR_CFG), encoding='utf-8').read()
    return set(int(m) for m in re.findall(r'\[(\d+)\]=\{', txt.split('impacts={', 1)[1]))


def cmd_verify(args):
    path = os.path.join(args.staging, SI) if args.staging else os.path.join(R, SI)
    with open(path, 'rb') as f:
        data = f.read()
    errors, warn = [], []
    try:
        data.decode('gbk')
    except UnicodeDecodeError as e:
        errors.append('khong phai GBK: %s' % e)
    t = read_table(path)
    n = len(t['types'])
    ids = []
    for r in t['rows']:
        if len(r) != n:
            errors.append('ID %s co %d cot, can %d' % (g(r[0]), len(r), n))
        ids.append(int(r[0]))
    if ids != sorted(ids):
        errors.append('Data_Index khong tang dan')
    dup = [i for i, c in collections.Counter(ids).items() if c > 1]
    if dup:
        errors.append('ID trung: %s' % dup[:10])

    # so với mốc git của R: dòng cũ phải Y NGUYÊN; dòng mới phải hợp lệ với cả BẢNG PHỤ của engine
    new_by = {int(r[0]): r for r in t['rows']}
    added, changed = [], []
    try:
        base = read_table_bytes_local(git_show(args.base, SI))
        base_by = {int(r[0]): r for r in base['rows']}
        added = sorted(set(new_by) - set(base_by))
        changed = sorted(i for i in set(new_by) & set(base_by) if list(new_by[i]) != list(base_by[i]))
        if changed:
            errors.append('%d dong cu bi doi: %s' % (len(changed), changed[:6]))
        base_logics = set(ival(r[SI_LOGIC]) for r in base['rows'])
        timed_only = {}
        for r in base['rows']:
            lg = ival(r[SI_LOGIC])
            timed_only[lg] = timed_only.get(lg, True) and (ival(r[SI_OVERTIME]) == 1)
        try:
            mapped = cyfour_mapped()
        except Exception as e:                       # bản khác không có cy_four -> chỉ cảnh báo
            mapped, warn = None, warn + ['khong doc duoc cy_four native_config: %s' % e]
        src = Src()
        logics = installed_logics()
        unmapped, flipped = [], []
        for i in added:
            r = new_by[i]
            lg = ival(r[SI_LOGIC])
            if lg is None:
                errors.append('dong moi %d khong co 逻辑ID' % i)
                continue
            if lg not in base_logics:
                errors.append('dong moi %d dung logic %d chua co dong nao trong bang goc' % (i, lg))
            if lg >= 8000 and mapped is not None and i not in mapped:
                unmapped.append((i, lg))
            if lg not in logics and timed_only.get(lg, True) and ival(r[SI_OVERTIME]) != 1:
                flipped.append((i, lg))
            se = ival(r[SI_SE])
            if se is not None and se >= 0 and se not in src.se_cy:
                errors.append('dong moi %d co SE %d khong co o client CY' % (i, se))
        if flipped:
            errors.append('%d dong moi lam logic chua cai roi tu buff rong sang std_impact_003: %s'
                          % (len(flipped), flipped[:6]))
        if unmapped:
            errors.append('%d dong moi logic cy_four >= 8000 thieu anh xa vi tri (engine.lua:67): %s'
                          % (len(unmapped), unmapped[:6]))
    except Exception as e:                           # không có git / mốc sai -> không chặn các phép kiểm còn lại
        warn.append('khong doc duoc moc %s cua R: %s' % (args.base, e))
        unmapped = []
        src = Src()

    miss = missing_trap_impacts(src)
    have = set(ids)
    still = sorted(i for i in miss if i not in have)
    extra_still = sorted(i for i in [c[0] for c in EXTRA_CELLS] + [c[0] for c in EXTRA_SCALE_CELLS]
                         + list(EXTRA_DECLINED) if i not in have)
    out = {'file': path, 'rows': len(ids), 'added': len(added), 'changed': len(changed),
           'errors': errors, 'warnings': warn[:20], 'cyfour_unmapped': len(unmapped),
           'trap_impact_still_missing': len(still), 'still_missing_ids': still,
           'extra_still_missing': extra_still, 'ok': not errors}
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(out, f, ensure_ascii=False, indent=1)
    print(json.dumps(out, ensure_ascii=False)[:3000])
    return 0 if not errors else 2


def read_table_bytes_local(data):
    from cs3b_menpai import read_table_bytes
    return read_table_bytes(data)


def installed_logics():
    """逻辑ID đã có module Lua trong `impactenginer.lua` (dòng khác chỉ hiện icon)."""
    txt = open(os.path.join(R, GS, 'lualib/impactenginer.lua'), encoding='utf-8').read()
    body = txt.split('id_logic_module', 1)[1]
    return set(int(m) for m in re.findall(r'\[(\d+)\]\s*=\s*"scene', body))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('plan')
    a.add_argument('--out', required=True)
    a.add_argument('--only', default='')
    a.set_defaults(fn=cmd_plan)
    a = sub.add_parser('apply')
    a.add_argument('--staging', required=True)
    a.add_argument('--dry-run', action='store_true')
    a.set_defaults(fn=cmd_apply)
    a = sub.add_parser('verify')
    a.add_argument('--staging', default='')
    a.add_argument('--base', default='HEAD', help='mốc git của R làm nền để đếm dòng thêm/đổi')
    a.add_argument('--out', default='')
    a.set_defaults(fn=cmd_verify)
    args = ap.parse_args()
    sys.exit(args.fn(args) or 0)


if __name__ == '__main__':
    main()
