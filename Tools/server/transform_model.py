#!/usr/bin/env python3
"""transform-model — dựng dòng `StandardImpact` cho ô `变身男buff` / `变身女buff` của 星宿 (巨蝎).

Nút thắt mà hai agent trước dừng lại (`trap-data_vi.md` mục 6.8, `impact-data_vi.md` mục 8.4) là
**không biết `变身ID` tra vào bảng nào**. Lượt này đã bẻ được, bằng hai đầu:

  * Server: `std_impact_014:get_refix_model_id` KHÔNG hề "0 chỗ gọi" — nó được gọi **theo tên động**
    từ `impact_logic/base.lua:31` (`fn = string.format("get_refix_%s", key)`) khi `human_attrib`
    tính lại thuộc tính `model_id` (`imp_get_attrib_refix` → `logic:get_refix(imp, key, ...)`).
    `grep get_refix_model_id` không thấy chỗ gọi vì tên hàm được ghép từ chuỗi.
  * Client: `model_id` chảy tới `CObject_PlayerOther::CalcCharModelID` ("经过变身… 直接从模型定义表中读取模型名")
    → `DBC_CHARACTER_MODEL` = **`CharModelEx.txt`**. Kiểm chéo bằng các `变身ID` CÓ THẬT trên bảng:
    804 = `白色山羊.obj` (变羊BUFF), 806 = `白兔.obj` (变身：兔子), 823 = `绿褐龟.obj` (变身：乌龟),
    2003 = `黄鸭.obj` (飘飘鸭), 444/445 = `变身冰人/雪人.obj`, 8430 = `npc变身_2025唐门技改神枢战甲.obj`.

`CharModelEx` của CY 3.71 có đúng **6** model cho 巨蝎, đúng thứ tự nam→nữ × 3 bậc:

    8676/8677/8678 = npc变身_2026星宿巨蝎男1级/2级/3级
    8679/8680/8681 = npc变身_2026星宿巨蝎女1级/2级/3级

và `SkillData_V1` của server có đúng 6 ID còn thiếu, cùng bố cục:

    434 神蝎百相   变身男buff 59700  变身女buff 59703   (triệu hồi — bậc 1)
    841 蝎行无阻   变身男buff 59701  变身女buff 59704   (tiến hoá lần 1 — bậc 2)
    844 蝎行无阻   变身男buff 59702  变身女buff 59705   (tiến hoá lần 2 — bậc 3)

Tip CY của 434 nói "巨蝎…可使巨蝎进化，**最多2次**" ⇒ đúng 3 bậc. Song ánh 6↔6.

Luật dựng dòng giữ nguyên của `trap_impacts.py` / `impact_data.py p1fill`: **bản sao một dòng THẬT**,
chỉ đổi ô đã chứng minh được, mỗi điều kiện đều được công cụ kiểm lại trên bảng SỐNG; sai một điều
kiện ⇒ BỎ dòng đó và ghi lý do, không âm thầm sinh dòng.

Dòng mẫu: **`31577 蚩尤青龙驾驶BUFF`** (logic 14) — họ `X驾驶BUFF` là trạng thái "cưỡi con X", đúng vai
với "驱使巨蝎供自身骑乘". Nó là dòng GỐC (có mặt ở mốc `6ca25a8`, y nguyên tới HEAD) và là dòng biến thân
duy nhất **không khoá kỹ năng** (CanAction1/2 = -1 — bắt buộc, vì 434 nói "骑乘状态下只能使用巨蝎技能",
tức vẫn phải bấm được chiêu) **và** `瞬发效果ID = -1` (không mượn hiệu ứng hình ảnh của chiêu khác).

Bốn ô đổi so với dòng mẫu, mỗi ô một nguồn:

  | ô | mẫu | mới | nguồn |
  |---|---|---|---|
  | `Data_Index`   | 31577 | 59700…59705 | ô `变身男/女buff` của SkillData (công cụ kiểm lại) |
  | `效果名称$1$`   | 蚩尤青龙驾驶BUFF | 神蝎百相/蝎行无阻（CY推导变身…） | khuôn tên của `59706 神蝎百相（CY推导免控）` |
  | `变身ID(-1为无效)` | 2261 | 8676…8681 | `CharModelEx` CY 3.71, tên model khớp từng bậc/giới tính |
  | `总持续时间(毫秒)` | -1 | 10000 | tip 434 "持续**10秒**" (đúng một `持续N秒` trong tip, và nó nói về chính trạng thái cưỡi); 841/844 "进化后**重置存在时间**" ⇒ cùng thời lượng |

Mọi ô còn lại chép nguyên: `互斥ID = 1025` (⇒ ba bậc THAY NHAU, và nam/nữ loại trừ nhau — đúng cơ chế
tiến hoá), `互斥优先级 = 160` (`can_impactA_replace_impactB` là `>=` nên bậc sau thay bậc trước),
`是否可以被技能驱散 = 0`, `死后是否保留 = 0`, `下线就消失否 = 1`.

  transform_model.py plan   --out <dir> [--only 59700,59703]  dựng <dir>/configs/StandardImpact.txt + plan.json + transform_model.tsv
  transform_model.py apply  --staging <dir> [--dry-run]       chép vào R, sao lưu R/backups/transform-model-<UTC>/
  transform_model.py verify [--staging <dir>] [--base <rev>] [--out j]

Chạy trong WSL TLBB bằng root:
    python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/transform_model.py plan --out /tmp/tm
Đặc tả: `Docs/specs/server/impact-data_vi.md` mục 9.
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
from cs3b_menpai import read_table, read_table_bytes, write_table, g, sha  # noqa: E402

R = '/home/ubuntu/cys-test-20260913'
CY_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
SI = 'configs/StandardImpact.txt'
ST = 'configs/SkillTemplate_V1.txt'
SD = 'configs/SkillData_V1.txt'
GS = 'GameServer'
MARK = 'transform-model'
BASE_REV = '6ca25a8'

SI_ID, SI_NAME, SI_LOGIC, SI_SE = 0, 1, 2, 5
SI_DURATION = 20
SI_PARAM0, SI_PARAM_N = 27, 16       # bộ ba (参数N说明, 参数值, 修正步长) × 16
ST_MENPAI, ST_NAME = 2, 3
ST_LEVELS = list(range(58, 74))
SD_TIP = 3
LABEL_MODEL = '变身ID(-1为无效)'
COLOR_RE = re.compile(r'#c[0-9A-Fa-f]{6}|#[rRWGYBnbe]')

DONOR = 31577                         # 蚩尤青龙驾驶BUFF — xem docstring

# Mỗi mục: ID đích, ô SkillData phải trỏ tới nó, model CharModelEx + TÊN model phải khớp, và chuỗi
# bắt buộc có trong tip của template thì mới nhận thời lượng đã khai.
ROWS = [
    dict(id=59700, tpl=434, cell='变身男buff', model=8676, model_name='npc变身_2026星宿巨蝎男1级.obj',
         duration=10000, tip_need='持续10秒', name='神蝎百相（CY推导变身男1级）'),
    dict(id=59703, tpl=434, cell='变身女buff', model=8679, model_name='npc变身_2026星宿巨蝎女1级.obj',
         duration=10000, tip_need='持续10秒', name='神蝎百相（CY推导变身女1级）'),
    dict(id=59701, tpl=841, cell='变身男buff', model=8677, model_name='npc变身_2026星宿巨蝎男2级.obj',
         duration=10000, tip_need='重置存在时间', name='蝎行无阻（CY推导变身男2级）'),
    dict(id=59704, tpl=841, cell='变身女buff', model=8680, model_name='npc变身_2026星宿巨蝎女2级.obj',
         duration=10000, tip_need='重置存在时间', name='蝎行无阻（CY推导变身女2级）'),
    dict(id=59702, tpl=844, cell='变身男buff', model=8678, model_name='npc变身_2026星宿巨蝎男3级.obj',
         duration=10000, tip_need='重置存在时间', name='蝎行无阻（CY推导变身男3级）'),
    dict(id=59705, tpl=844, cell='变身女buff', model=8681, model_name='npc变身_2026星宿巨蝎女3级.obj',
         duration=10000, tip_need='重置存在时间', name='蝎行无阻（CY推导变身女3级）'),
]

# Nhóm CỐ Ý KHÔNG dựng — giữ lại lý do để lần sau khỏi tra lại từ đầu.
DECLINED = [
    ('59864-59879', '星宿 圣蚕护身 445 `冰蚕buff` (16 cấp)',
     'KHÔNG phải biến thân. Model của 冰蚕 trong CharModelEx CY là 8691/8692/8693 '
     '`npc怪_2026星宿冰蚕1级/2级/3级` — tiền tố `npc怪_` (thực thể quái), không phải `npc变身_` như '
     '6 model 巨蝎; ô của 445 cũng KHÔNG có nhãn 变身男/女buff nào, chỉ một ô `冰蚕buff` duy nhất mỗi cấp. '
     'Tip mô tả hành vi của CON 冰蚕 (hút hiệu ứng xấu, tốn 12% máu, 55% tiến hoá, tự nổ) chứ không cho '
     'biết BẢN THÂN buff làm gì ⇒ vẫn không có dòng mẫu. Cần hệ TRIỆU HỒI (như skill-summon đã làm cho '
     '毒蟾功 174) chứ không phải logic 14.'),
]


def run_git(rev, rel):
    return subprocess.run(['git', '-C', R, 'show', '%s:%s' % (rev, rel)],
                          capture_output=True, check=True).stdout


def ival(b):
    try:
        return int(g(b).strip())
    except (ValueError, AttributeError):
        return None


def clean_tip(b):
    return COLOR_RE.sub('', g(b)).replace('\\n', ' ')


def si_param_slots(row):
    """[(chỉ số cột nhãn, cột giá trị)] của 16 bộ ba tham số."""
    return [(SI_PARAM0 + 3 * k, SI_PARAM0 + 3 * k + 1) for k in range(SI_PARAM_N)]


def si_label(row, i):
    return g(row[i]).strip().strip('"') if i < len(row) else ''


def find_model_slot(row):
    for a, b in si_param_slots(row):
        if si_label(row, a) == LABEL_MODEL:
            return a, b
    return None, None


def read_charmodel():
    """CharModelEx.txt của CY 3.71 (văn bản, GBK, 2 dòng tiêu đề) -> {id: tên model}."""
    with open(os.path.join(CY_DIR, 'CharModelEx.txt'), 'rb') as f:
        raw = f.read()
    out = {}
    for line in raw.decode('gbk', 'replace').split('\n')[2:]:
        c = line.rstrip('\r').split('\t')
        if len(c) < 2:
            continue
        try:
            out[int(c[0])] = c[1].strip()
        except ValueError:
            continue
    return out


class Src:
    def __init__(self):
        self.si = read_table(os.path.join(R, SI))
        self.si_by = {int(r[0]): r for r in self.si['rows']}
        self.st = read_table(os.path.join(R, ST))
        self.st_by = {int(r[0]): r for r in self.st['rows']}
        self.sd = read_table(os.path.join(R, SD))
        self.sd_by = {int(r[0]): r for r in self.sd['rows']}
        names = [g(x).strip() for x in (self.sd['names'] or [])]
        self.sd_pairs = [(i, i + 1) for i, n in enumerate(names) if n == '参数说明']
        self.charmodel = read_charmodel()
        base = read_table_bytes(run_git(BASE_REV, SI))
        self.base_by = {int(r[0]): r for r in base['rows']}

    def levels(self, tpl):
        """[(cấp, dòng SkillData)] của một template."""
        row = self.st_by.get(tpl)
        if row is None:
            return []
        out = []
        for lv, col in enumerate(ST_LEVELS, start=1):
            sid = ival(row[col]) if col < len(row) else None
            if sid is None or sid < 0:
                continue
            d = self.sd_by.get(sid)
            if d is not None:
                out.append((lv, sid, d))
        return out

    def cell_levels(self, tpl, cell, want_id):
        """các cấp mà ô `cell` của template trỏ đúng vào `want_id`."""
        hit = []
        for lv, sid, d in self.levels(tpl):
            for a, b in self.sd_pairs:
                if si_label(d, a) == cell and ival(d[b]) == want_id:
                    hit.append(lv)
                    break
        return hit

    def tip(self, tpl):
        lv = self.levels(tpl)
        return clean_tip(lv[0][2][SD_TIP]) if lv else ''


def check(src, spec):
    """trả (dòng mới hoặc None, dict bằng chứng/lý do)."""
    ev = {'id': spec['id'], 'tpl': spec['tpl'], 'cell': spec['cell'], 'model': spec['model'],
          'donor': DONOR, 'duration': spec['duration']}

    donor = src.si_by.get(DONOR)
    if donor is None:
        return None, dict(ev, skip='khong co dong mau %d tren bang song' % DONOR)
    base_donor = src.base_by.get(DONOR)
    if base_donor is None:
        return None, dict(ev, skip='dong mau %d khong co o moc %s' % (DONOR, BASE_REV))
    if list(base_donor) != list(donor):
        return None, dict(ev, skip='dong mau %d da bi doi so voi moc %s' % (DONOR, BASE_REV))
    if ival(donor[SI_LOGIC]) != 14:
        return None, dict(ev, skip='dong mau khong phai logic 14')
    la, lb = find_model_slot(donor)
    if la is None:
        return None, dict(ev, skip='dong mau khong khai nhan %s' % LABEL_MODEL)
    ev['donor_name'] = g(donor[SI_NAME])
    ev['donor_model'] = ival(donor[lb])
    ev['donor_se'] = ival(donor[SI_SE])
    ev['donor_mutex'] = g(donor[7]).strip()

    if spec['id'] in src.si_by:
        return None, dict(ev, skip='ID %d DA co dong' % spec['id'], already=True)

    lv = src.cell_levels(spec['tpl'], spec['cell'], spec['id'])
    if not lv:
        return None, dict(ev, skip='o `%s` cua template %d KHONG tro toi %d o cap nao'
                                   % (spec['cell'], spec['tpl'], spec['id']))
    ev['levels'] = lv

    name = src.charmodel.get(spec['model'])
    if name is None:
        return None, dict(ev, skip='CharModelEx CY khong co dong %d' % spec['model'])
    if name != spec['model_name']:
        return None, dict(ev, skip='CharModelEx %d ten la %r, khai %r'
                                   % (spec['model'], name, spec['model_name']))
    ev['model_name'] = name

    tip = src.tip(spec['tpl'])
    if spec['tip_need'] not in tip:
        return None, dict(ev, skip='tip template %d khong chua %r' % (spec['tpl'], spec['tip_need']))
    ev['tip_need'] = spec['tip_need']
    ev['tpl_name'] = g(src.st_by[spec['tpl']][ST_NAME])

    row = list(donor)
    row[SI_ID] = str(spec['id']).encode('ascii')
    row[SI_NAME] = spec['name'].encode('gbk')
    row[SI_DURATION] = str(spec['duration']).encode('ascii')
    row[lb] = str(spec['model']).encode('ascii')
    ev['changed_cols'] = [SI_ID, SI_NAME, SI_DURATION, lb]
    return row, ev


def build(src, only):
    made, evs = [], []
    for spec in ROWS:
        if only and spec['id'] not in only:
            continue
        row, ev = check(src, spec)
        evs.append(ev)
        if row is not None:
            made.append(row)
    return made, evs


def cmd_plan(args):
    only = set(int(x) for x in args.only.split(',')) if args.only else None
    src = Src()
    made, evs = build(src, only)
    rows = list(src.si['rows']) + made
    rows.sort(key=lambda r: int(r[0]))
    out_si = os.path.join(args.out, SI)
    write_table(out_si, src.si['types'], src.si['names'], rows, src.si['eol'])

    tsv = [['Data_Index', 'ten', 'template', 'ten_ky_nang', 'o', 'cap', 'dong_mau', 'bien_than_ID',
            'ten_model', 'thoi_luong_ms', 'ghi_chu']]
    for ev, spec in zip(evs, [s for s in ROWS if not only or s['id'] in only]):
        tsv.append([str(ev['id']), spec['name'], str(ev['tpl']), ev.get('tpl_name', ''), ev['cell'],
                    ','.join(str(x) for x in ev.get('levels', [])), str(DONOR), str(ev['model']),
                    ev.get('model_name', ''), str(ev['duration']), ev.get('skip', 'OK')])
    with open(os.path.join(args.out, 'transform_model.tsv'), 'w', encoding='utf-8') as f:
        for r in tsv:
            f.write('\t'.join(r) + '\n')
    with open(os.path.join(args.out, 'declined.txt'), 'w', encoding='utf-8') as f:
        for ids, what, why in DECLINED:
            f.write('%s  %s\n    %s\n\n' % (ids, what, why))

    plan = {'base_rows': len(src.si['rows']), 'new_rows': len(rows), 'added': len(made),
            'donor': DONOR, 'evidence': evs, 'staging': out_si, 'sha': sha(out_si)}
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: plan[k] for k in ('base_rows', 'new_rows', 'added', 'donor', 'sha')},
                     ensure_ascii=False))
    for ev in evs:
        if 'skip' in ev:
            print('  BO %s: %s' % (ev['id'], ev['skip']))


def cmd_apply(args):
    src_file = os.path.join(args.staging, SI)
    dst = os.path.join(R, SI)
    base = read_table(dst)
    new = read_table(src_file)
    old = {int(r[0]): r for r in base['rows']}
    for r in new['rows']:
        i = int(r[0])
        if i in old and list(old[i]) != list(r):
            raise SystemExit('dong cu %d bi doi -> tu choi' % i)
    if args.dry_run:
        print(json.dumps({'dry_run': True, 'base': len(base['rows']), 'new': len(new['rows'])}))
        return
    if len(new['rows']) == len(base['rows']):
        print(json.dumps({'no_change': True, 'rows': len(base['rows']), 'sha': sha(dst)}))
        return
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(R, 'backups', '%s-%s' % (MARK, stamp))
    os.makedirs(bak, exist_ok=True)
    shutil.copy2(dst, os.path.join(bak, 'StandardImpact.txt'))
    shutil.copy2(src_file, dst)
    print(json.dumps({'backup': bak, 'rows': len(new['rows']), 'sha': sha(dst)}, ensure_ascii=False))


def installed_logics():
    txt = open(os.path.join(R, GS, 'lualib/impactenginer.lua'), encoding='utf-8').read()
    return set(int(m) for m in re.findall(r'\[(\d+)\]\s*=\s*"scene\.skill\.impact_logic', txt))


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

    new_by = {int(r[0]): r for r in t['rows']}
    base = read_table_bytes(run_git(args.base, SI))
    base_by = {int(r[0]): r for r in base['rows']}
    added = sorted(set(new_by) - set(base_by))
    changed = sorted(i for i in set(new_by) & set(base_by) if list(new_by[i]) != list(base_by[i]))
    if changed:
        errors.append('%d dong cu bi doi: %s' % (len(changed), changed[:6]))

    mine = sorted(i for i in added if i in set(s['id'] for s in ROWS))
    logics = installed_logics()
    charmodel = read_charmodel()
    spec_by = {s['id']: s for s in ROWS}
    for i in mine:
        r = new_by[i]
        lg = ival(r[SI_LOGIC])
        if lg not in logics:
            errors.append('ID %d logic %s chua dang ky' % (i, lg))
        la, lb = find_model_slot(r)
        if la is None:
            errors.append('ID %d khong co nhan %s' % (i, LABEL_MODEL))
            continue
        m = ival(r[lb])
        if m not in charmodel:
            errors.append('ID %d 变身ID %s khong co trong CharModelEx CY' % (i, m))
        elif charmodel[m] != spec_by[i]['model_name']:
            errors.append('ID %d 变身ID %s ten %r != %r'
                          % (i, m, charmodel[m], spec_by[i]['model_name']))
        if ival(r[SI_DURATION]) != spec_by[i]['duration']:
            errors.append('ID %d thoi luong %s != %s' % (i, g(r[SI_DURATION]), spec_by[i]['duration']))
        se = ival(r[SI_SE])
        if se is not None and se >= 0:
            warn.append('ID %d muon hieu ung %s cua dong mau' % (i, se))

    # ô SkillData trỏ tới ID nào của mình mà vẫn thiếu dòng?
    src_ok = True
    try:
        src = Src()
    except Exception as e:                                       # noqa: BLE001
        src_ok, src = False, None
        warn.append('khong doc duoc SkillData/SkillTemplate: %s' % e)
    still_missing = []
    if src_ok:
        for s in ROWS:
            if s['id'] not in new_by and src.cell_levels(s['tpl'], s['cell'], s['id']):
                still_missing.append(s['id'])

    if args.staging:
        same = sha(path) == sha(os.path.join(R, SI))
    else:
        same = True

    out = {'ok': not errors, 'rows': len(t['rows']), 'cols': n, 'added': len(added),
           'added_mine': mine, 'changed': len(changed), 'errors': errors, 'warn': warn,
           'still_missing': still_missing, 'staging_equals_R': same, 'base': args.base}
    txt = json.dumps(out, ensure_ascii=False, indent=1)
    print(txt)
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            f.write(txt + '\n')
    if errors:
        raise SystemExit(1)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('plan')
    a.add_argument('--out', required=True)
    a.add_argument('--only')
    a.set_defaults(fn=cmd_plan)
    b = sub.add_parser('apply')
    b.add_argument('--staging', required=True)
    b.add_argument('--dry-run', action='store_true')
    b.set_defaults(fn=cmd_apply)
    c = sub.add_parser('verify')
    c.add_argument('--staging')
    c.add_argument('--base', default=BASE_REV)
    c.add_argument('--out')
    c.set_defaults(fn=cmd_verify)
    args = p.parse_args()
    if args.cmd == 'plan':
        os.makedirs(os.path.join(args.out, 'configs'), exist_ok=True)
    args.fn(args)


if __name__ == '__main__':
    main()
