#!/usr/bin/env python3
"""trap-data — nhập các dòng `SpecialObjData` (bẫy / đồ vật đặc biệt) mà kỹ năng CY cần nhưng server riêng chưa có.

Vì sao: bảng của server riêng là nhánh GL/HJ (1.352 dòng), còn `SkillData_V1` đã là CY 3.71. 342 ID bẫy được kỹ năng
tham chiếu thì 111 **không có dòng** và 66 **là đồ vật khác**. `obj_special:get_data_record()` có
`assert(data_record, self.data_id)` nên bẫy thiếu dòng làm ném lỗi, còn bẫy "trùng ID khác nghĩa" thì chạy nhầm.
Đo và bằng chứng: `Docs/specs/server/trap-data_vi.md`, `Build/Logs/2026-09-17-skill-system/10-trap-gap.tsv`.

Luật: **chỉ THÊM** dòng, lấy nguyên văn từ bảng CY (`DataCY31-08-26/Config/SpecialObjData.txt`), không sửa dòng cũ,
không đụng 66 ID va chạm. Ánh xạ cột (đã đối chiếu từng cột, xem đặc tả mục 2):
cột 0–24 chép thẳng; 25–30 = `0` (预留/预留新增 của server); cặp `参数说明`/`参数值` của CY (từ cột 25) đổ vào cặp
của server (từ cột 31, 16 cặp, ô trống = nhãn rỗng + giá trị `0`); cột 63 `详细说明(内部使用)` để rỗng.

  trap_data.py plan   --out <dir> [--only ID,ID]    dựng <dir>/configs/SpecialObjData.txt + plan.json + trap_data.tsv
  trap_data.py apply  --staging <dir> [--dry-run]   chép vào R, sao lưu R/backups/trap-data-<UTC>/
  trap_data.py verify [--staging <dir>] [--out j]   GBK, đủ cột, dòng cũ y nguyên, mọi ID thêm đều có mặt,
                                                    liệt kê impact của bẫy còn thiếu dòng StandardImpact

Chạy trong WSL TLBB bằng root: `python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/trap_data.py <lệnh>`.
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
CY_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
SO = 'configs/SpecialObjData.txt'
SD = 'configs/SkillData_V1.txt'
SI = 'configs/StandardImpact.txt'
MARK = 'trap-data'

# Nhãn 参数说明 của SkillData thật sự chứa ID SpecialObjData (đã loại nhãn đếm/buff/tập ID).
TRAP_LABELS = {
    '脚下生成陷阱ID', '陷阱数据ID', '强化陷阱1', '强化陷阱2', '陷阱id', '陷阱Data',
    '会心陷阱', '命中陷阱', '预警陷阱id', '引爆的陷阱类型ID', '引导周期释放陷阱',
    '溅射效果陷阱id', '傀儡回收后，原地留下陷阱ID', '1队友伤害陷阱', '2队友伤害陷阱',
    '3队友伤害陷阱', '4队友伤害陷阱', '5队友伤害陷阱', '陷阱ID', '生成陷阱id',
}
COPY_COLS = 25             # cột 0..24 giống hệt giữa hai bảng
RESERVED = range(25, 31)   # 预留 x5 + 预留新增
PAIR0_SRV, PAIRS_SRV = 31, 16
PAIR0_CY = 25
DETAIL_COL = 63
WU = '无'


def read_cy():
    t = read_table(os.path.join(CY_DIR, 'SpecialObjData.txt'))
    return {int(r[0]): r for r in t['rows']}


def read_srv(rel):
    return read_table(os.path.join(R, rel))


def referenced_traps():
    """ID bẫy -> {skills, labels}, lấy từ SkillData_V1 của server."""
    t = read_srv(SD)
    names = [g(x).strip() for x in (t['names'] or [])]
    pairs = [(i, i + 1) for i, n in enumerate(names) if n == '参数说明']
    out = collections.defaultdict(lambda: {'skills': set(), 'labels': set()})
    for r in t['rows']:
        for a, b in pairs:
            if a >= len(r) or b >= len(r):
                continue
            label, value = g(r[a]).strip(), g(r[b]).strip()
            if label not in TRAP_LABELS:
                continue
            if value.lstrip('-').isdigit() and int(value) > 0:
                out[int(value)]['skills'].add(int(r[0]))
                out[int(value)]['labels'].add(label)
    return out


def build_row(cy_row, ncols):
    row = [b''] * ncols
    for i in range(COPY_COLS):
        row[i] = cy_row[i] if i < len(cy_row) else b''
    for i in RESERVED:
        row[i] = b'0'
    pairs = []
    i = PAIR0_CY
    while i + 1 < len(cy_row):
        label, value = cy_row[i], cy_row[i + 1]
        text = g(label).strip()
        if text and text not in ('0', WU):
            pairs.append((label, value if value.strip() else b'0'))
        i += 2
    if len(pairs) > PAIRS_SRV:
        raise SystemExit('ID %s co %d cap tham so, bang server chi co %d' % (g(cy_row[0]), len(pairs), PAIRS_SRV))
    for k in range(PAIRS_SRV):
        a = PAIR0_SRV + k * 2
        if k < len(pairs):
            row[a], row[a + 1] = pairs[k][0], pairs[k][1]
        else:
            row[a], row[a + 1] = b'', b'0'
    row[DETAIL_COL] = b''
    return row


def cy_impacts(cy_row):
    out = []
    i = PAIR0_CY
    while i + 1 < len(cy_row):
        label, value = g(cy_row[i]).strip(), g(cy_row[i + 1]).strip()
        if label.startswith('效果') and not label.endswith('几率') and value.lstrip('-').isdigit() and int(value) > 0:
            out.append(int(value))
        i += 2
    return out


def si_ids():
    return {int(r[0]) for r in read_srv(SI)['rows']}


def cmd_plan(args):
    srv = read_srv(SO)
    ncols = len(srv['types'])
    have = {int(r[0]): r for r in srv['rows']}
    cy = read_cy()
    ref = referenced_traps()
    impacts = si_ids()
    only = set(int(x) for x in args.only.split(',') if x.strip()) if args.only else None

    add, collide, no_cy, ok = [], [], [], []
    for tid in sorted(ref):
        if tid in have:
            srv_name = g(have[tid][1]).strip()
            cy_name = g(cy[tid][1]).strip() if tid in cy else ''
            (ok if srv_name == cy_name else collide).append((tid, srv_name, cy_name))
        elif tid in cy:
            if only is None or tid in only:
                add.append(tid)
        else:
            no_cy.append(tid)

    rows = list(srv['rows']) + [build_row(cy[t], ncols) for t in add]
    out_file = os.path.join(args.out, SO)
    write_table(out_file, srv['types'], srv['names'], rows, srv['eol'])

    tsv = os.path.join(args.out, 'trap_data.tsv')
    miss_imp = collections.Counter()
    with open(tsv, 'w', encoding='utf-8', newline='') as f:
        f.write('trap_id\tten_CY\tso_ky_nang\tnhan\timpact_cua_bay\timpact_thieu\n')
        for t in add:
            imps = cy_impacts(cy[t])
            miss = [str(x) for x in imps if x not in impacts]
            for x in miss:
                miss_imp[x] += 1
            f.write('%d\t%s\t%d\t%s\t%s\t%s\n' % (t, g(cy[t][1]).strip(), len(ref[t]['skills']),
                                                  ','.join(sorted(ref[t]['labels'])),
                                                  ','.join(str(x) for x in imps), ','.join(miss)))
    plan = {
        'base_rows': len(srv['rows']), 'added': len(add), 'add_ids': add,
        'collide': [{'id': t, 'server': s, 'cy': c} for t, s, c in collide],
        'ok_same_name': len(ok), 'referenced': len(ref), 'not_in_cy': no_cy,
        'impact_missing_for_added': {k: v for k, v in sorted(miss_imp.items(), key=lambda kv: int(kv[0]))},
        'out': out_file, 'sha_out': sha(out_file),
    }
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: plan[k] for k in ('base_rows', 'added', 'ok_same_name', 'referenced', 'not_in_cy')},
                     ensure_ascii=False))
    print('va cham (khong dung): %d | impact cua bay con thieu: %d | %s' % (len(collide), len(miss_imp), tsv))


def cmd_apply(args):
    src = os.path.join(args.staging, SO)
    dst = os.path.join(R, SO)
    base = read_table(dst)
    new = read_table(src)
    old_ids = {int(r[0]): r for r in base['rows']}
    for r in new['rows']:
        i = int(r[0])
        if i in old_ids and old_ids[i] != r:
            raise SystemExit('dong cu %d bi doi -> tu choi' % i)
    if args.dry_run:
        print(json.dumps({'dry_run': True, 'base': len(base['rows']), 'new': len(new['rows'])}))
        return
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(R, 'backups', '%s-%s' % (MARK, stamp))
    os.makedirs(bak, exist_ok=True)
    shutil.copy2(dst, os.path.join(bak, 'SpecialObjData.txt'))
    shutil.copy2(src, dst)
    print(json.dumps({'backup': bak, 'rows': len(new['rows']), 'sha': sha(dst)}, ensure_ascii=False))


def cmd_verify(args):
    path = os.path.join(args.staging, SO) if args.staging else os.path.join(R, SO)
    with open(path, 'rb') as f:
        data = f.read()
    errors = []
    try:
        data.decode('gbk')
    except UnicodeDecodeError as e:
        errors.append('khong phai GBK: %s' % e)
    t = read_table(path)
    n = len(t['types'])
    for r in t['rows']:
        if len(r) != n:
            errors.append('ID %s co %d cot, can %d' % (g(r[0]), len(r), n))
    ids = [int(r[0]) for r in t['rows']]
    dup = [i for i, c in collections.Counter(ids).items() if c > 1]
    if dup:
        errors.append('ID trung: %s' % dup[:10])
    ref = referenced_traps()
    have = set(ids)
    missing = sorted(t for t in ref if t not in have)
    impacts = si_ids()
    cy = read_cy()
    miss_imp = collections.Counter()
    for tid in ref:
        if tid in have and tid in cy:
            for x in cy_impacts(cy[tid]):
                if x not in impacts:
                    miss_imp[x] += 1
    out = {'file': path, 'rows': len(ids), 'errors': errors, 'referenced': len(ref),
           'still_missing': len(missing), 'still_missing_ids': missing[:20],
           'impact_missing': len(miss_imp), 'ok': not errors}
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(out, f, ensure_ascii=False, indent=1)
    print(json.dumps(out, ensure_ascii=False)[:2000])
    return 0 if not errors else 2


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
    a.add_argument('--out', default='')
    a.set_defaults(fn=cmd_verify)
    args = ap.parse_args()
    sys.exit(args.fn(args) or 0)


if __name__ == '__main__':
    main()
