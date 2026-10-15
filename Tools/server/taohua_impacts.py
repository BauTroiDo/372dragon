#!/usr/bin/env python3
"""taohua-impacts — dựng nội dung cho các ID impact 桃花岛 mà `impact_recollide` vừa dời sang dải 64000–64035.

`impact_recollide` (17/09, `trap-data_vi.md` mục 6.9) gỡ va chạm ID: 96 ô của **3820 棹歌中流** và
**3822 劝君酒** đang trỏ vào khối `坐骑` của nhánh GL/HJ (`逻辑ID = 97`) nên gắn nhầm buff thú cưỡi.
Chúng được dời sang **64000–64035**, và vì không có bảng `StandardImpact` của CY 3.71 nên **ID mới chưa có dòng**
⇒ ô hết tác dụng (sai theo kiểu khác). Công cụ này bù dòng cho các ID ĐÃ CHỨNG MINH ĐƯỢC, và **ghi lý do**
cho các ID cố ý không dựng.

NGUỒN THẬT tìm được trong chính bảng của server (agent `skill-data-final`, 17/09): bảng có sẵn **khối CY 桃花岛
4260–4560** — cùng nhánh với các dòng mà `cy_four_combat/tao.lua` (bản port mã native CY) gọi tên:

  4504–4515  `棹歌中流`  逻辑 3, `威力修正` = 95 / 100 / 105 … 150  (12 cấp)
  4543–4549  `棹歌中流`  dur 10.000 ms, `转换比例` = 95 … 125
  4400       `桃花岛暗伤标记` 逻辑 8038, dur 10.000 ms
  4517/4518  `劝君酒散攻效果` (4 s) / `劝君酒减速效果` (5 s, −45 %)

Hai nhóm được dựng (đều là **bản sao nguyên vẹn** một dòng có thật ở mốc gốc, chỉ đổi `Data_Index` + `效果名称`):

  A. ô `生效一次的效果1(傀儡周围敌人)` của 3820 → mẫu **4505** (`威力修正` = 100 — thành viên "100 %" của dãy thật).
     Bằng chứng khớp khít: ô anh em `对效果1伤害的修正，效果1必须用3号伤害类BUFF` chạy −5 … +50 theo cấp và
     `skill_cy_spec:send` đổi thành hệ số `rate = 100 + ô` (chỉ áp cho `逻辑ID = 3` — đúng như tên ô đòi hỏi),
     nên 100 % × rate = **95 % (cấp 1) … 150 % (cấp 16)** = đúng dãy trong tip CY.
  B. ô `生效一次给傀儡加效果` (bản THEO CẤP) của 3820 → mẫu **4544** (`逻辑ID` 38 = cờ trạng thái, dur 10.000 ms
     = "持续10秒" của tip, SE 4375 của chính kỹ năng). `转换比例` **không được Lua nào đọc** nên bản sao không
     thể gây tác dụng phụ.

Mọi ID còn lại đều CỐ Ý không dựng — lý do đầy đủ trong `DECLINED` (in ra `taohua_declined.txt`).

  taohua_impacts.py plan   --out <dir>                dựng <dir>/configs/StandardImpact.txt + plan.json + .tsv + declined
  taohua_impacts.py apply  --staging <dir> [--dry-run] chép vào R, sao lưu R/backups/taohua-impacts-<UTC>/
  taohua_impacts.py verify [--staging <dir>] [--out j] GBK/cột/ID tăng; dòng cũ Y NGUYÊN so với --base;
                                                       dòng mới: logic đã có trong bảng gốc, < 8000 (hoặc đã ánh xạ
                                                       cy_four), SE có ở client CY hoặc −1, mọi 子效果 có dòng

Chạy trong WSL TLBB bằng root: `python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/taohua_impacts.py <lệnh>`.
Idempotent: chạy lại `plan` sau `apply` cho ra bảng trùng sha với bảng đang chạy.
Đặc tả: `Docs/specs/server/trap-data_vi.md` mục 6.9 (nguồn) và mục mới của `skill-data-final`.
"""
import argparse
import collections
import datetime
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table, read_table_bytes, write_table, g, sha  # noqa: E402

R = '/home/ubuntu/cys-test-20260913'
GS = 'GameServer'
SI = 'configs/StandardImpact.txt'
SD = 'configs/SkillData_V1.txt'
ST = 'configs/SkillTemplate_V1.txt'
CY_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
CY_FOUR_CFG = 'lualib/cy_four_combat/native_config.lua'
MARK = 'taohua-impacts'
BASE_DEFAULT = '6ca25a8'                   # mốc gốc: dòng mẫu BẮT BUỘC có mặt ở đây

ST_NAME = 3
ST_LEVELS = list(range(58, 74))
SD_TIP = 3
SI_ID, SI_NAME, SI_LOGIC, SI_OVERTIME, SI_SE = 0, 1, 2, 4, 5
SI_DURATION, SI_INTERVAL = 20, 21
SI_PARAM0, SI_PARAM_N = 27, 16
NEW_LO, NEW_HI = 64000, 64035              # dải do impact_recollide cấp; KHÔNG đụng ID ngoài dải

COLOR_RE = re.compile(r'#c[0-9A-Fa-f]{6}|#[rRWGYBnbe]')

# ------------------------------------------------------------------ khai báo
# Mỗi nhóm = (template, nhãn ô, "kiểu ô") + DÒNG MẪU + ĐIỀU KIỆN. Công cụ kiểm lại mọi điều kiện trên bảng SỐNG;
# sai một điều kiện thì BỎ CẢ NHÓM và ghi lý do (không âm thầm sinh dòng).
#   kind      : 'per_level' (mỗi cấp một ID) | 'constant' (mọi cấp cùng một ID)
#   donor     : Data_Index dòng mẫu — phải có ở mốc gốc VÀ giống hệt trên bảng sống
#   dname     : chuỗi phải có trong 效果名称 của dòng mẫu
#   logic     : 逻辑ID dòng mẫu phải mang (và phải < 8000 — xem DECLINED)
#   dur       : 总持续时间 dòng mẫu phải ĐANG mang
#   pdonor    : {nhãn: giá trị} dòng mẫu phải đang mang
#   tip       : mọi chuỗi phải có trong tip CY của ít nhất một cấp
#   rate_cell : (nhãn ô hệ số, mẫu regex lấy % trong tip) — kiểm 100 + ô = % của tip ở cấp đầu VÀ cấp cuối
GROUPS = [
    dict(tpl=3820, skill='棹歌中流', label='生效一次的效果1(傀儡周围敌人)', kind='constant',
         donor=4505, name='棹歌中流（CY推导每秒伤害）',
         cond=dict(dname='棹歌中流', logic='3', pdonor={'威力修正': '100'},
                   tip=['每秒造成', '的伤害'],
                   rate_cell=('对效果1伤害的修正，效果1必须用3号伤害类BUFF', r'每秒造成(\d+)%的伤害')),
         why='dãy thật 4504–4515 `棹歌中流` (逻辑 3) mang `威力修正` = 95…150; 4505 là thành viên 100 % nên '
             'hệ số rate = 100 + ô 对效果1伤害的修正 (−5…+50) cho lại đúng 95 %…150 % của tip. '
             'Mã CY native còn ghim đúng dải này: `tao.lua M.scale_tao_damage` chỉ chạy cho source 4504..4515.'),
    dict(tpl=3820, skill='棹歌中流', label='生效一次给傀儡加效果', kind='per_level',
         donor=4544, name='棹歌中流（CY推导傀儡状态）',
         cond=dict(dname='棹歌中流', logic='38', dur='10000', tip=['持续10秒']),
         why='4543–4549 `棹歌中流` đều dur 10.000 ms = "持续10秒" của tip; 4544 là dòng 逻辑ID 38 (cờ trạng thái) '
             'nên bản sao không mang tham số nào mà server đọc (`转换比例` không có chỗ đọc nào trong lualib/services). '
             'Ô này được `cy_skill_logic_spec[799]` gửi cho CHÍNH con rối (to = doll).'),
]

# ID trong dải 64000–64035 CỐ Ý không dựng — ghi lý do để lần sau không phải tra lại từ đầu.
DECLINED = collections.OrderedDict([
    ('3820 棹歌中流 ô `生效一次给傀儡加效果` bản HẰNG SỐ (64000; CY 45443)',
     'Hai ô cùng nhãn trong một dòng: bản theo cấp (đã dựng, mục B) và bản hằng số này. Mã native CY '
     '(`cy_four_combat/tao.lua:on_skill_success` nhánh 3820) đưa con rối impact **4549** và chủ impact **4543**; '
     '`tick_doll` giữ điệu múa bằng `c:has_impact(doll, ref("impacts",4549))` — tức chỉ ĐÚNG ID 4549 mới có tác dụng, '
     'bản sao ở ID mới KHÔNG bao giờ thoả điều kiện đó. 4549 lại mang 逻辑ID 8038 và 4543 mang 8168 (cy_four): '
     'chép sang ID mới sẽ tạo dòng "unmapped positional impact" (engine.lua:67, impact-data_vi.md mục 6.4). '
     'Không có bằng chứng nào tách được vai trò của ô hằng số ⇒ bỏ.'),
    ('3822 劝君酒 ô `生效一次的效果(目标)桃花岛苦昼短专用` (64002–64017; CY 45445–45460)',
     'Nội dung đúng là **dấu 暗伤 10 giây**: bảng có sẵn dòng thật `4400 桃花岛暗伤标记` (dur 10.000 ms, SE 4411) '
     'trùng khít tip "为目标施加持续10秒的暗伤标记". NHƯNG 4400 mang 逻辑ID **8038** (cy_four) và Data_Index của nó '
     'lại CHƯA có trong `cy_four_combat/native_config.lua impacts={}` — chép sang ID mới vừa thêm một dòng '
     '`cyfour_unmapped` (verify báo lỗi) vừa không chạy. Ngoài ra `tao.lua` đã gửi ĐÚNG 4400 cho từng địch quanh '
     'con rối, nên ô dữ liệu là đường song song. Việc cần làm trước: ánh xạ 4400 (và 4347/4543/4549/4260) trong '
     'native_config — thuộc chủ `cy_four`, không phải dữ liệu.'),
    ('3822 劝君酒 ô `生效一次的效果(傀儡罩子)…` (64034) và `…(傀儡连线)…` (64035); CY 45510/45511',
     'Tip 16 cấp không có câu nào nói về "罩子" (khiên quanh rối) hay "连线" (dây nối rối–mục tiêu): không có số, '
     'không có mô tả hiệu ứng. Quét cả bảng: **0 dòng** mang tên 罩子, và 5 dòng mang tên 连线 đều của kỹ năng khác '
     '(贪食四方, 阴阳无咎). `tao.lua` cũng không gửi impact nào cho hai vai trò này. Không có nguồn ⇒ bỏ.'),
])


def ival(b):
    try:
        return int(g(b).strip())
    except (ValueError, TypeError):
        return None


def git_show(rev, rel):
    import subprocess
    return subprocess.run(['git', '-C', R, 'show', '%s:%s' % (rev, rel)],
                          capture_output=True, check=True).stdout


def clean_tip(b):
    return COLOR_RE.sub('', g(b)).replace('\n', ' ').strip()


class Src:
    """Đọc bảng SỐNG của R (trong buổi có agent khác sửa bảng mà chưa commit)."""

    def __init__(self, base=BASE_DEFAULT):
        self.base = base
        self.si = read_table(os.path.join(R, SI))
        self.si_by = {int(r[0]): list(r) for r in self.si['rows']}
        self.ncol = len(self.si['types'])
        self.sd = read_table(os.path.join(R, SD))
        self.sd_by = {int(r[0]): r for r in self.sd['rows']}
        names = [g(x).strip() for x in (self.sd['names'] or [])]
        self.pairs = [(i, i + 1) for i, n in enumerate(names) if n == '参数说明']
        self.st = read_table(os.path.join(R, ST))
        self.tpl = {int(r[0]): r for r in self.st['rows']}
        self.se_cy = set(int(r[0]) for r in read_table(os.path.join(CY_DIR, 'ImpactSEData_V1.txt'))['rows'])
        try:
            self.base_by = {int(r[0]): list(r) for r in read_table_bytes(git_show(base, SI))['rows']}
        except Exception as e:                                    # noqa: BLE001
            self.base_by, self.base_err = {}, str(e)

    def levels(self, tid):
        r = self.tpl.get(tid)
        if r is None:
            return []
        out = []
        for k, c in enumerate(ST_LEVELS):
            sid = ival(r[c]) if c < len(r) else None
            if sid is not None and sid >= 0 and sid in self.sd_by:
                out.append((k + 1, sid))
        return out

    def cells(self, sid, label):
        """[(vị trí cột, giá trị)] của mọi ô mang đúng nhãn `label` trong một SkillData."""
        r = self.sd_by.get(sid)
        out = []
        if r is None:
            return out
        for a, b in self.pairs:
            if b >= len(r):
                continue
            if g(r[a]).strip() == label:
                out.append((a, ival(r[b])))
        return out

    def tip(self, sid):
        r = self.sd_by.get(sid)
        return clean_tip(r[SD_TIP]) if r is not None else ''

    def param(self, row, label):
        for m in range(SI_PARAM_N):
            p = SI_PARAM0 + 3 * m
            if p < len(row) and g(row[p]).strip() == label:
                return p, g(row[p + 1]).strip()
        return None, None

    def pad(self, row):
        row = list(row) + [b''] * max(0, self.ncol - len(row))
        return row[:self.ncol]


def resolve(src, grp):
    """Trả (ids theo cấp, lý do bỏ). `ids` = [(cấp, sd_id, vị trí cột, impact_id)] đúng kiểu ô đã khai."""
    tid, label, kind = grp['tpl'], grp['label'], grp['kind']
    t = src.tpl.get(tid)
    if t is None:
        return None, 'khong co SkillTemplate %d' % tid
    if g(t[ST_NAME]).strip() != grp['skill']:
        return None, 'tpl %d ten "%s", cho "%s"' % (tid, g(t[ST_NAME]).strip(), grp['skill'])
    lv = src.levels(tid)
    if not lv:
        return None, 'tpl %d khong co cap nao' % tid
    by_pos = collections.OrderedDict()
    for k, sid in lv:
        for pos, v in src.cells(sid, label):
            by_pos.setdefault(pos, []).append((k, sid, pos, v))
    if not by_pos:
        return None, 'khong o nao cua tpl %d mang nhan "%s"' % (tid, label)
    want = []
    for pos, items in by_pos.items():
        distinct = len(set(x[3] for x in items))
        if (kind == 'per_level' and distinct > 1) or (kind == 'constant' and distinct == 1):
            want.append(items)
    if len(want) != 1:
        return None, 'nhan "%s" cho %d o kieu "%s" (can dung 1)' % (label, len(want), kind)
    items = want[0]
    bad = [x for x in items if x[3] is None or not (NEW_LO <= x[3] <= NEW_HI)]
    if bad:
        return None, 'o tro ra ngoai dai %d-%d: %s' % (NEW_LO, NEW_HI, sorted(set(x[3] for x in bad))[:6])
    return items, None


def check_rate(src, grp, items):
    """Ô hệ số `对效果1伤害的修正…` phải cho lại ĐÚNG dãy % trong tip (cấp đầu và cấp cuối)."""
    cell, rx = grp['cond']['rate_cell']
    rx = re.compile(rx)
    seen = []
    for k, sid, _pos, _v in items:
        add = None
        for pos, val in src.cells(sid, cell):
            add = val
        m = rx.search(src.tip(sid))
        if add is None:
            return 'cap %d khong co o "%s"' % (k, cell)
        if not m:
            return 'tip cap %d khong khop mau "%s"' % (k, rx.pattern)
        if 100 + add != int(m.group(1)):
            return 'cap %d: 100 + %d = %d, tip ghi %s%%' % (k, add, 100 + add, m.group(1))
        seen.append((k, 100 + add))
    return None if seen else 'khong doc duoc cap nao'


def build(src, grp, items):
    """Chép dòng mẫu sang từng ID; mọi điều kiện đã đạt thì trả {id: row}, không thì (None, lý do)."""
    cond = grp['cond']
    donor_id = grp['donor']
    donor = src.si_by.get(donor_id)
    if donor is None:
        return None, 'khong co dong mau %d tren bang song' % donor_id
    if donor_id not in src.base_by:
        return None, 'dong mau %d khong co o moc goc %s' % (donor_id, src.base)
    if list(src.base_by[donor_id]) != list(donor):
        return None, 'dong mau %d da bi doi so voi moc goc' % donor_id
    if cond.get('dname') and cond['dname'] not in g(donor[SI_NAME]):
        return None, 'dong mau %d ten "%s" khong chua "%s"' % (donor_id, g(donor[SI_NAME]).strip(), cond['dname'])
    if cond.get('logic') and g(donor[SI_LOGIC]).strip() != cond['logic']:
        return None, 'dong mau %d co 逻辑ID=%s, cho %s' % (donor_id, g(donor[SI_LOGIC]).strip(), cond['logic'])
    if ival(donor[SI_LOGIC]) is None or ival(donor[SI_LOGIC]) >= 8000:
        return None, 'dong mau %d mang 逻辑ID >= 8000 (cy_four) — ban sao se thieu anh xa vi tri' % donor_id
    if cond.get('dur') and g(donor[SI_DURATION]).strip() != cond['dur']:
        return None, 'dong mau %d co 总持续时间=%s, cho %s' % (donor_id, g(donor[SI_DURATION]).strip(), cond['dur'])
    for lab, wv in (cond.get('pdonor') or {}).items():
        _p, got = src.param(donor, lab)
        if got != wv:
            return None, 'dong mau %d co %s=%s, cho %s' % (donor_id, lab, got, wv)
    tips = [src.tip(sid) for _k, sid, _p, _v in items]
    for n in cond.get('tip', []):
        if not any(n in t for t in tips):
            return None, 'tip khong chua "%s"' % n
    if cond.get('rate_cell'):
        why = check_rate(src, grp, items)
        if why:
            return None, why

    rows, se_note = {}, ''
    for _k, _sid, _pos, imp in items:
        if imp in rows:
            continue
        row = src.pad(donor)
        row[SI_ID] = str(imp).encode('ascii')
        if grp.get('name'):
            row[SI_NAME] = grp['name'].encode('gbk')
        se = ival(row[SI_SE])
        if se is not None and se >= 0 and se not in src.se_cy:
            row[SI_SE] = b'-1'
            se_note = ' SE %d -> -1' % se
        rows[imp] = row
    return (rows, se_note), None


def cmd_plan(args):
    src = Src(args.base)
    cur = dict(src.si_by)
    tsv = [['impact_id', 'template', 'ky_nang', 'nhan_o', 'kieu_o', 'cap', 'dong_mau', 'ten_dong_mau',
            'logic', 'dur', 'ket_qua', 'bang_chung']]
    made, skipped, detail = 0, [], []
    for grp in GROUPS:
        items, why = resolve(src, grp)
        if items is None:
            skipped.append('%d "%s": %s' % (grp['tpl'], grp['label'], why))
            continue
        already = [x[3] for x in items if x[3] in cur]
        items = [x for x in items if x[3] not in cur]
        if not items:
            skipped.append('%d "%s": moi ID da co dong — bo qua (idempotent)' % (grp['tpl'], grp['label']))
            continue
        built, why = build(src, grp, items)
        if built is None:
            skipped.append('%d "%s": %s' % (grp['tpl'], grp['label'], why))
            continue
        rows, se_note = built
        donor = src.si_by[grp['donor']]
        lv = collections.defaultdict(list)
        for k, _sid, _pos, imp in items:
            lv[imp].append(k)
        ev = []
        if grp['cond'].get('dname'):
            ev.append('mau mang ten ky nang "%s"' % grp['cond']['dname'])
        if grp['cond'].get('dur'):
            ev.append('mau dang %s ms' % grp['cond']['dur'])
        for lab, wv in (grp['cond'].get('pdonor') or {}).items():
            ev.append('%s=%s' % (lab, wv))
        for n in grp['cond'].get('tip', []):
            ev.append('tip "%s"' % n)
        if grp['cond'].get('rate_cell'):
            ev.append('100 + o "%s" = %% trong tip o MOI cap' % grp['cond']['rate_cell'][0])
        for imp in sorted(rows):
            cur[imp] = rows[imp]
            made += 1
            tsv.append([str(imp), str(grp['tpl']), grp['skill'], grp['label'], grp['kind'],
                        ','.join(str(x) for x in sorted(lv[imp])), str(grp['donor']),
                        g(donor[SI_NAME]).strip(), g(donor[SI_LOGIC]).strip(),
                        g(donor[SI_DURATION]).strip(), 'ok' + se_note, ' | '.join(ev)])
        detail.append({'tpl': grp['tpl'], 'nhan': grp['label'], 'kieu': grp['kind'], 'dong_mau': grp['donor'],
                       'so_dong': len(rows), 'ids': sorted(rows), 'da_co_san': sorted(already),
                       'vi_sao': grp['why']})

    os.makedirs(os.path.join(args.out, 'configs'), exist_ok=True)
    write_table(os.path.join(args.out, SI), src.si['types'], src.si['names'],
                [cur[i] for i in sorted(cur)], src.si['eol'])
    with open(os.path.join(args.out, 'taohua_impacts.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        for r in tsv:
            f.write('\t'.join(r) + '\n')
    with open(os.path.join(args.out, 'taohua_declined.txt'), 'w', encoding='utf-8', newline='\n') as f:
        for k, v in DECLINED.items():
            f.write('== %s\n   %s\n\n' % (k, v))
        f.write('== BO trong lan chay nay (dieu kien khong dat / da co dong)\n')
        for w in skipped:
            f.write('   %s\n' % w)
    still = sorted(i for i in range(NEW_LO, NEW_HI + 1) if i not in cur)
    out = {'base': args.base, 'khai_bao_nhom': len(GROUPS), 'dong_da_dung': made,
           'bo_nhom': len(skipped), 'bo_chi_tiet': skipped, 'nhom_co_y_khong_dung': len(DECLINED),
           'dai_moi_con_thieu': len(still), 'ids_con_thieu': still,
           'rows': len(cur), 'sha_staging': sha(os.path.join(args.out, SI)), 'chi_tiet': detail}
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: v for k, v in out.items() if k != 'chi_tiet'}, ensure_ascii=False, indent=1))
    return 0


def cmd_apply(args):
    src_file = os.path.join(args.staging, SI)
    dst = os.path.join(R, SI)
    base = read_table(dst)
    new = read_table(src_file)
    old = {int(r[0]): list(r) for r in base['rows']}
    new_by = {int(r[0]): list(r) for r in new['rows']}
    changed = sorted(i for i in set(old) & set(new_by) if old[i] != new_by[i])
    if changed:
        raise SystemExit('dong cu bi doi -> tu choi: %s' % changed[:8])
    added = sorted(set(new_by) - set(old))
    if any(not (NEW_LO <= i <= NEW_HI) for i in added):
        raise SystemExit('them ID ngoai dai %d-%d -> tu choi: %s'
                         % (NEW_LO, NEW_HI, [i for i in added if not (NEW_LO <= i <= NEW_HI)][:8]))
    if args.dry_run:
        print(json.dumps({'dry_run': True, 'them': added}, ensure_ascii=False))
        return 0
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(R, 'backups', '%s-%s' % (MARK, stamp))
    os.makedirs(bak, exist_ok=True)
    shutil.copy2(dst, os.path.join(bak, 'StandardImpact.txt'))
    shutil.copy2(src_file, dst)
    print(json.dumps({'backup': bak, 'them': added, 'rows': len(new['rows']), 'sha': sha(dst)},
                     ensure_ascii=False))
    return 0


def cyfour_mapped():
    """Data_Index có ánh xạ vị trí trong `cy_four_combat/native_config.lua impacts={}` (engine.lua:67)."""
    txt = open(os.path.join(R, GS, CY_FOUR_CFG), encoding='utf-8').read()
    # bảng dùng HAI dạng mục, phải lấy cả hai (impact_data.py chỉ đọc dạng thứ nhất):
    #   [N]={...}  descriptor đầy đủ (408 mục)      [N]=N  ánh xạ đồng nhất (1.128 mục)
    out = set(int(m) for m in re.findall(r'\[(\d+)\]=\{', txt.split('impacts={', 1)[1]))
    for blk in re.finditer(r'impacts=\{([^{}]*)\}', txt):
        out |= set(int(a) for a in re.findall(r'\[(\d+)\]=\d+', blk.group(1)))
    return out


def installed_logics():
    txt = open(os.path.join(R, GS, 'lualib/impactenginer.lua'), encoding='utf-8').read()
    body = txt.split('id_logic_module', 1)[1]
    return set(int(m) for m in re.findall(r'\[(\d+)\]\s*=\s*"scene', body))


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
    new_by = {int(r[0]): list(r) for r in t['rows']}
    added, changed, unmapped = [], [], []
    try:
        base = read_table_bytes(git_show(args.base, SI))
        base_by = {int(r[0]): list(r) for r in base['rows']}
        added = sorted(set(new_by) - set(base_by))
        changed = sorted(i for i in set(new_by) & set(base_by) if new_by[i] != base_by[i])
        if changed:
            errors.append('%d dong cu bi doi: %s' % (len(changed), changed[:6]))
        base_logics = set(ival(r[SI_LOGIC]) for r in base['rows'])
        mapped = cyfour_mapped()
        logics = installed_logics()
        se_cy = set(int(r[0]) for r in read_table(os.path.join(CY_DIR, 'ImpactSEData_V1.txt'))['rows'])
        for i in added:
            r = new_by[i]
            lg = ival(r[SI_LOGIC])
            if lg is None:
                errors.append('dong moi %d khong co 逻辑ID' % i)
                continue
            if lg not in base_logics:
                errors.append('dong moi %d dung logic %d chua co dong nao trong bang goc' % (i, lg))
            if lg >= 8000 and i not in mapped:
                unmapped.append((i, lg))
            if lg not in logics:
                warn.append('dong moi %d logic %d chua co module Lua' % (i, lg))
            se = ival(r[SI_SE])
            if se is not None and se >= 0 and se not in se_cy:
                errors.append('dong moi %d co SE %d khong co o client CY' % (i, se))
            for m in range(SI_PARAM_N):
                p = SI_PARAM0 + 3 * m
                lab = g(r[p]).strip()
                v = ival(r[p + 1])
                if lab.startswith('子效果') and lab.endswith('数据索引') and v is not None and v >= 0 \
                        and v not in new_by:
                    errors.append('dong moi %d tro toi 子效果 %d khong co dong' % (i, v))
        if unmapped:
            errors.append('%d dong moi logic cy_four >= 8000 thieu anh xa vi tri (engine.lua:67): %s'
                          % (len(unmapped), unmapped[:6]))
    except Exception as e:                                        # noqa: BLE001
        warn.append('khong doc duoc moc %s cua R: %s' % (args.base, e))

    # các ID đã khai phải CÓ dòng; các ID đã khai là DECLINED phải KHÔNG có dòng do công cụ này thêm
    src = Src(args.base)
    want_have, want_skip = [], []
    for grp in GROUPS:
        items, why = resolve(src, grp)
        if items is None:
            warn.append('nhom %d "%s" khong giai duoc: %s' % (grp['tpl'], grp['label'], why))
            continue
        for _k, _sid, _pos, imp in items:
            (want_have if imp in new_by else want_skip).append(imp)
    if want_skip:
        errors.append('ID da khai nhung KHONG co dong: %s' % sorted(set(want_skip))[:10])
    still = sorted(i for i in range(NEW_LO, NEW_HI + 1) if i not in new_by)
    out = {'file': path, 'rows': len(ids), 'added_vs_base': len(added), 'changed': len(changed),
           'errors': errors, 'warnings': warn[:10], 'cyfour_unmapped': len(unmapped),
           'ids_da_dung': sorted(set(want_have)), 'dai_64000_con_thieu': len(still), 'ids_con_thieu': still,
           'ok': not errors}
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(out, f, ensure_ascii=False, indent=1)
    print(json.dumps(out, ensure_ascii=False)[:3000])
    return 0 if not errors else 2


def main():
    ap = argparse.ArgumentParser(description='taohua-impacts — bù dòng cho dải ID 64000–64035 của 桃花岛')
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('plan')
    a.add_argument('--out', required=True)
    a.add_argument('--base', default=BASE_DEFAULT)
    a.set_defaults(fn=cmd_plan)
    a = sub.add_parser('apply')
    a.add_argument('--staging', required=True)
    a.add_argument('--dry-run', action='store_true')
    a.set_defaults(fn=cmd_apply)
    a = sub.add_parser('verify')
    a.add_argument('--staging', default='')
    a.add_argument('--base', default=BASE_DEFAULT)
    a.add_argument('--out', default='')
    a.set_defaults(fn=cmd_verify)
    args = ap.parse_args()
    return args.fn(args)


if __name__ == '__main__':
    sys.exit(main())
