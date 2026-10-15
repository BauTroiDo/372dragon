#!/usr/bin/env python3
"""impact-recollide — gỡ lớp va chạm ID **impact** giữa bảng CY và bảng GL/HJ, + bù hiệu ứng cho 刀域 `2102`.

Cùng loại lỗi mà `trap_recollide.py` đã gỡ cho 66 ID **bẫy**, lần này ở tầng `StandardImpact`:
`SkillData_V1` của server đã là CY 3.71 nhưng `StandardImpact` là nhánh GL/HJ, nên **96 ô impact** của hai chiêu
桃花岛 **3820 棹歌中流** và **3822 劝君酒** rơi trúng **khối 坐骑** (`逻辑ID = 97`) — ví dụ ô
`生效一次的效果(目标)桃花岛苦昼短专用` chạy `45445 → 45460` theo 16 cấp = `白牦牛`, `白鹿`, `白雕`, `白狼`, `狮子`…
Impact vẫn lên người chơi và **không báo lỗi** nên trước giờ không ai thấy (agent `taohua-doll` truy ra;
số đo của người điều phối: `3822` trả `buffs_other = {19695: 1, …}`).

Cách gỡ (đúng khuôn `trap_recollide`): **cấp ID mới cho bản CY** rồi sửa ô `参数值` tương ứng của `SkillData_V1`.
**Không đụng dòng cũ** — khối 坐骑 đang được nội dung khác dùng. Khác `trap_recollide` ở một điểm: **không có bảng
`StandardImpact` của CY 3.71** (đã chứng minh ở `impact-data_vi.md` mục 1.1), nên ID mới **chưa có dòng**:
`impactenginer:init_impact_from_data` trả `false` và logic kỹ năng bỏ qua ⇒ ô **không còn tác dụng SAI**,
chờ ai đó dựng nội dung đúng ở ID mới. Bảng client **không cần** đồng bộ (chỉ bảng bẫy mới cần).

Việc thứ hai trong cùng lượt — `SpecialObjData 2102 荡千军刀域` (绝情谷 4516, `skill_840` đặt bẫy này từ mốc gốc):
`效果1..4 = -1` và `陷阱专用标记 = 0` ⇒ 刀域 chỉ là hiệu ứng nhìn. Bù bằng **hai dòng có thật của chính kỹ năng**:
`4626 荡千军（直接伤血）` (`伤害数值+ = 100`) và `4808 荡千军(麻痹)` (`总持续时间 = 2000`) — trùng khít tip
"造成**100点**直接伤害和**2秒**麻痹", và đặt `陷阱专用标记`/`是否即刻生效一次` **bằng đúng** bẫy anh em
`1800`/`2166` của cùng kỹ năng ở template khác.

  impact_recollide.py plan   --out <dir>              dựng <dir>/configs/{SkillData_V1,SpecialObjData}.txt + plan.json + .tsv
  impact_recollide.py apply  --staging <dir> [--dry-run]  chép vào R, sao lưu R/backups/impact-recollide-<UTC>/
  impact_recollide.py verify [--out j]                GBK, số dòng/cột y nguyên, CHỈ các ô đã khai bị đổi

Chạy trong WSL TLBB bằng root: `python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/impact_recollide.py <lệnh>`.
Idempotent: chạy lại `plan` sau `apply` cho ra file trùng sha với bảng đang chạy.
Đặc tả: `Docs/specs/server/trap-data_vi.md` mục 6.9.
"""
import argparse
import collections
import datetime
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table, write_table, g, sha  # noqa: E402

R = '/home/ubuntu/cys-test-20260913'
SD = 'configs/SkillData_V1.txt'
SO = 'configs/SpecialObjData.txt'
SI = 'configs/StandardImpact.txt'
MARK = 'impact-recollide'

ST_LEVELS = list(range(58, 74))
ST_NAME = 3
MOUNT_LOGIC = 97                 # khối 坐骑 của bảng GL/HJ — dấu hiệu nhận ra va chạm
NEW_BASE = 64000                 # dải ID mới (Data_Index lớn nhất của bảng là 63101)

# (template, nhãn ô) — mọi ô impact của hai chiêu 桃花岛 đang rơi vào khối 坐骑
RECOLLIDE_CELLS = [
    (3820, '生效一次的效果1(傀儡周围敌人)'),
    (3820, '生效一次给傀儡加效果'),
    (3822, '生效一次的效果(目标)桃花岛苦昼短专用'),
    (3822, '生效一次的效果(傀儡罩子)桃花岛苦昼短专用'),
    (3822, '生效一次的效果(傀儡连线)桃花岛苦昼短专用'),
]

# Bù hiệu ứng cho dòng bẫy đã có sẵn: {ID bẫy: {nhãn: (giá trị mới, giá trị cũ bắt buộc)}} + cột 0-30 cần đặt
TRAP_FIX = {
    2102: {
        'name': '荡千军刀域',
        'pairs': {'效果1': ('4626', '-1'), '效果2': ('4808', '-1'), '是否即刻生效一次': ('1', None)},
        'cols': {6: ('2', '0')},           # 陷阱专用标记: 0 -> 2 (như bẫy anh em 1800/2166)
        'donors': {4626: ('伤害数值+', '100'), 4808: ('总持续时间', '2000')},
        'why': 'tip 绝情谷 4516: "造成100点直接伤害和2秒麻痹"; bẫy anh em 1800/2166 cùng hồ sơ mang đúng hai vai trò này',
    },
}
SI_DURATION, SI_PARAM0, SI_PARAM_N = 20, 27, 16


def ival(b):
    try:
        return int(g(b).strip())
    except (ValueError, TypeError):
        return None


class Src:
    def __init__(self, root=R):
        self.sd = read_table(os.path.join(root, SD))
        self.sd_by = {int(r[0]): r for r in self.sd['rows']}
        self.st = read_table(os.path.join(root, 'configs/SkillTemplate_V1.txt'))
        self.tpl = {int(r[0]): r for r in self.st['rows']}
        names = [g(x).strip() for x in (self.sd['names'] or [])]
        self.pairs = [(i, i + 1) for i, n in enumerate(names) if n == '参数说明']
        self.si = read_table(os.path.join(root, SI))
        self.si_by = {int(r[0]): r for r in self.si['rows']}
        self.so = read_table(os.path.join(root, SO))
        self.so_by = {int(r[0]): r for r in self.so['rows']}
        self.so_names = [g(x).strip() for x in (self.so['names'] or [])]

    def levels(self, tpl):
        t = self.tpl.get(tpl)
        if t is None:
            return []
        out = []
        for k, c in enumerate(ST_LEVELS):
            v = ival(t[c]) if c < len(t) else None
            if v is not None and v >= 0 and v in self.sd_by:
                out.append((k + 1, v))
        return out

    def param(self, row, label):
        for k in range(SI_PARAM_N):
            p = SI_PARAM0 + 3 * k
            if p + 1 < len(row) and g(row[p]).strip().strip('"') == label:
                return p, g(row[p + 1]).strip()
        return None, None


def collect(src):
    """[(tpl, cấp, sd_id, vị trí, nhãn, ID cũ)] — chỉ nhận ô đang trỏ dòng 逻辑ID = 97 (khối 坐骑)."""
    cells, bad = [], []
    for tpl, lab in RECOLLIDE_CELLS:
        for lv, sid in src.levels(tpl):
            row = src.sd_by[sid]
            for a, b in src.pairs:
                if a >= len(row) or b >= len(row) or g(row[a]).strip() != lab:
                    continue
                v = ival(row[b])
                if v is None or v <= 0:
                    continue
                r = src.si_by.get(v)
                if r is None or ival(r[2]) != MOUNT_LOGIC:
                    bad.append((tpl, lv, sid, lab, v, g(r[2]).strip() if r is not None else 'THIEU'))
                    continue
                cells.append((tpl, lv, sid, a, lab, v, g(r[1]).strip()))
    return cells, bad


def allocate(cells):
    """ID cũ -> ID mới, dải liên tục từ NEW_BASE theo thứ tự ID cũ tăng dần (tái lập được)."""
    olds = sorted({c[5] for c in cells})
    return {o: NEW_BASE + i for i, o in enumerate(olds)}


def cmd_plan(args):
    src = Src()
    cells, bad = collect(src)
    remap = allocate(cells)
    busy = [n for n in remap.values() if n in src.si_by]
    if busy:
        raise SystemExit('dai ID moi da co dong: %s' % busy[:5])

    # --- SkillData: chỉ đổi đúng các ô đã thu
    sd_rows = {i: list(r) for i, r in src.sd_by.items()}
    changed = []
    for tpl, lv, sid, pos, lab, old, nm in cells:
        row = sd_rows[sid]
        if ival(row[pos + 1]) != old:
            raise SystemExit('o (sd %d, vi tri %d) khong con la %d' % (sid, pos, old))
        row[pos + 1] = str(remap[old]).encode('ascii')
        changed.append((tpl, lv, sid, pos, lab, old, remap[old], nm))
    os.makedirs(os.path.join(args.out, 'configs'), exist_ok=True)
    sd_out = os.path.join(args.out, SD)
    write_table(sd_out, src.sd['types'], src.sd['names'],
                [sd_rows[int(r[0])] for r in src.sd['rows']], src.sd['eol'])

    # --- SpecialObjData: bù hiệu ứng cho dòng bẫy đã có sẵn (2102)
    so_rows = [list(r) for r in src.so['rows']]
    so_idx = {int(r[0]): k for k, r in enumerate(so_rows)}
    trap_notes = []
    for tid, spec in TRAP_FIX.items():
        k = so_idx.get(tid)
        if k is None:
            trap_notes.append((tid, 'KHONG co dong tren server'))
            continue
        row = so_rows[k]
        if g(row[1]).strip() != spec['name']:
            trap_notes.append((tid, 'ten "%s" khac "%s" -> bo' % (g(row[1]).strip(), spec['name'])))
            continue
        okd = True
        for did, (lab, want) in spec['donors'].items():
            d = src.si_by.get(did)
            if d is None:
                trap_notes.append((tid, 'dong mau %d khong co' % did))
                okd = False
                break
            got = g(d[SI_DURATION]).strip() if lab == '总持续时间' else src.param(d, lab)[1]
            if got != want:
                trap_notes.append((tid, 'dong mau %d co %s=%s, cho %s' % (did, lab, got, want)))
                okd = False
                break
        if not okd:
            continue
        for col, (new, must) in spec['cols'].items():
            cur = g(row[col]).strip()
            if must is not None and cur not in (must, new):
                trap_notes.append((tid, 'cot %d dang la %s, cho %s' % (col, cur, must)))
                okd = False
                break
            row[col] = new.encode('ascii')
        if not okd:
            continue
        # cặp 参数说明/参数值 từ cột 31
        free = None
        for p in range(31, len(row) - 1, 2):
            lab = g(row[p]).strip()
            if lab in spec['pairs']:
                new, must = spec['pairs'][lab]
                cur = g(row[p + 1]).strip()
                if must is not None and cur not in (must, new):
                    trap_notes.append((tid, 'o %s dang la %s, cho %s' % (lab, cur, must)))
                    okd = False
                    break
                row[p + 1] = new.encode('ascii')
                trap_notes.append((tid, '%s %s -> %s' % (lab, cur, new)))
            elif not lab and free is None:
                free = p
        if not okd:
            continue
        have = {g(row[p]).strip() for p in range(31, len(row) - 1, 2)}
        for lab, (new, _must) in spec['pairs'].items():
            if lab in have:
                continue
            if free is None:
                trap_notes.append((tid, 'het cap tham so trong de them %s' % lab))
                break
            row[free], row[free + 1] = lab.encode('gbk'), new.encode('ascii')
            trap_notes.append((tid, '%s (them moi) = %s' % (lab, new)))
            free = next((p for p in range(free + 2, len(row) - 1, 2) if not g(row[p]).strip()), None)
    so_out = os.path.join(args.out, SO)
    write_table(so_out, src.so['types'], src.so['names'], so_rows, src.so['eol'])

    with open(os.path.join(args.out, 'impact_recollide.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('template\tky_nang\tcap\tskilldata\tnhan_o\tid_cu\tten_dong_cu_GL\tid_moi\n')
        for tpl, lv, sid, _pos, lab, old, new, nm in changed:
            f.write('%d\t%s\t%d\t%d\t%s\t%d\t%s\t%d\n'
                    % (tpl, g(src.tpl[tpl][ST_NAME]).strip(), lv, sid, lab, old, nm, new))
    # tách "đã dời rồi" (ID nằm trong dải mới) khỏi "bất thường" — chạy lại plan sau apply phải ra 0 bất thường
    done = [b for b in bad if NEW_BASE <= b[4] < NEW_BASE + 200]
    odd = [b for b in bad if not (NEW_BASE <= b[4] < NEW_BASE + 200)]
    plan = {'cells': len(changed), 'ids': len(remap), 'remap': {str(k): v for k, v in sorted(remap.items())},
            'already_moved': len(done), 'unexpected': odd, 'trap_fix': [[t, n] for t, n in trap_notes],
            'sd_rows': len(src.sd['rows']), 'so_rows': len(src.so['rows']),
            'sha_sd': sha(sd_out), 'sha_so': sha(so_out)}
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: plan[k] for k in ('cells', 'ids', 'already_moved', 'unexpected', 'trap_fix')},
                     ensure_ascii=False))


def _copy(src_file, dst, bak, name):
    shutil.copy2(dst, os.path.join(bak, name))
    shutil.copy2(src_file, dst)


def cmd_apply(args):
    src = Src()
    new_sd = read_table(os.path.join(args.staging, SD))
    new_so = read_table(os.path.join(args.staging, SO))
    if len(new_sd['rows']) != len(src.sd['rows']) or len(new_so['rows']) != len(src.so['rows']):
        raise SystemExit('so dong doi -> tu choi')
    cells, _bad = collect(src)
    allowed_sd = {(c[2], c[3] + 1) for c in cells}
    cur = {int(r[0]): r for r in new_sd['rows']}
    for i, old in src.sd_by.items():
        n = cur[i]
        for k in range(min(len(old), len(n))):
            if old[k] != n[k] and (i, k) not in allowed_sd:
                raise SystemExit('SkillData %d cot %d bi doi ngoai danh sach -> tu choi' % (i, k))
    cur_so = {int(r[0]): r for r in new_so['rows']}
    for i, old in src.so_by.items():
        if old != cur_so[i] and i not in TRAP_FIX:
            raise SystemExit('SpecialObjData %d bi doi ngoai danh sach -> tu choi' % i)
    if args.dry_run:
        print(json.dumps({'dry_run': True, 'sd': len(new_sd['rows']), 'so': len(new_so['rows'])}))
        return
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(R, 'backups', '%s-%s' % (MARK, stamp))
    os.makedirs(bak, exist_ok=True)
    _copy(os.path.join(args.staging, SD), os.path.join(R, SD), bak, 'SkillData_V1.txt')
    _copy(os.path.join(args.staging, SO), os.path.join(R, SO), bak, 'SpecialObjData.txt')
    print(json.dumps({'backup': bak, 'sha_sd': sha(os.path.join(R, SD)), 'sha_so': sha(os.path.join(R, SO))},
                     ensure_ascii=False))


def cmd_verify(args):
    errors, warn = [], []
    for rel in (SD, SO):
        p = os.path.join(R, rel)
        raw = open(p, 'rb').read()
        try:
            raw.decode('gbk')
        except UnicodeDecodeError as e:
            errors.append('%s khong phai GBK: %s' % (rel, e))
        t = read_table(p)
        n = len(t['types'])
        for r in t['rows']:
            if len(r) != n:
                errors.append('%s ID %s co %d cot, can %d' % (rel, g(r[0]), len(r), n))
                break
        ids = [int(r[0]) for r in t['rows']]
        if len(set(ids)) != len(ids):
            errors.append('%s co ID trung' % rel)
    src = Src()
    cells, bad = collect(src)
    if cells:
        errors.append('van con %d o tro vao khoi 坐骑 (logic 97)' % len(cells))
    # các ô đã dời phải mang ID trong dải mới và KHÔNG có dòng (chờ nội dung)
    moved, still_mount, have_row = 0, 0, 0
    for tpl, lab in RECOLLIDE_CELLS:
        for lv, sid in src.levels(tpl):
            row = src.sd_by[sid]
            for a, b in src.pairs:
                if a >= len(row) or b >= len(row) or g(row[a]).strip() != lab:
                    continue
                v = ival(row[b])
                if v is None or v <= 0:
                    continue
                if NEW_BASE <= v < NEW_BASE + 200:
                    moved += 1
                    if v in src.si_by:
                        have_row += 1
                elif v in src.si_by and ival(src.si_by[v][2]) == MOUNT_LOGIC:
                    still_mount += 1
    if still_mount:
        errors.append('%d o van tro khoi 坐骑' % still_mount)
    trap = {}
    for tid, spec in TRAP_FIX.items():
        r = src.so_by.get(tid)
        if r is None:
            errors.append('SpecialObjData %d khong con' % tid)
            continue
        got = {}
        for p in range(31, len(r) - 1, 2):
            lab = g(r[p]).strip()
            if lab in spec['pairs']:
                got[lab] = g(r[p + 1]).strip()
        for lab, (want, _m) in spec['pairs'].items():
            if got.get(lab) != want:
                errors.append('bay %d o %s = %s, cho %s' % (tid, lab, got.get(lab), want))
        for col, (want, _m) in spec['cols'].items():
            if g(r[col]).strip() != want:
                errors.append('bay %d cot %d = %s, cho %s' % (tid, col, g(r[col]).strip(), want))
        trap[str(tid)] = got
        for did in spec['donors']:
            if did not in src.si_by:
                errors.append('bay %d tro dong mau %d khong co' % (tid, did))
    out = {'cells_moved': moved, 'cells_still_mount': still_mount, 'new_ids_with_row': have_row,
           'trap_fix': trap, 'errors': errors, 'warnings': warn, 'ok': not errors}
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(out, f, ensure_ascii=False, indent=1)
    print(json.dumps(out, ensure_ascii=False)[:2500])
    return 0 if not errors else 2


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('plan')
    a.add_argument('--out', required=True)
    a.set_defaults(fn=cmd_plan)
    a = sub.add_parser('apply')
    a.add_argument('--staging', required=True)
    a.add_argument('--dry-run', action='store_true')
    a.set_defaults(fn=cmd_apply)
    a = sub.add_parser('verify')
    a.add_argument('--out', default='')
    a.set_defaults(fn=cmd_verify)
    args = ap.parse_args()
    sys.exit(args.fn(args) or 0)


if __name__ == '__main__':
    main()
