#!/usr/bin/env python3
"""pets-wild — nhập các dòng `PetAttrTable` / `MonsterAttrExTable` mà script trân thú cần nhưng server riêng chưa có.

Vì sao. Hai bảng của server riêng đã được `cs3c-tables` dựng lại theo ID CY 3.71 (PetAttr 8.587 ID,
MonsterAttrEx 29.058 ID). Nhưng **script vật phẩm trứng trân thú** trong `Game_2/Script/scripts/obj/commonitem`
vẫn trỏ tới 64 ID trân thú thuộc nhánh 0.85/GL mà bảng CY KHÔNG có. 38 trong số đó là **trứng CÓ THẬT** trong
`CommonItem.txt`, nên người chơi dùng được:

    petmanager:make_capture_pet_attrib (GameServer/lualib/petmanager.lua:233)
        pet_attr_table = pet_attr_table[data_id]
        if not pet_attr_table then assert(false, "不存在珍兽ID:"..data_id) end
        monster_attr_ex = monster_attr_ex[data_id]        -- dòng sau đọc .attack_type / .speed

`300027.lua` có chốt `GetIsPetID` nên chỉ báo "ID trân thú không tồn tại"; **891217 / 893088 / 893308 / 998545
KHÔNG có chốt** ⇒ dùng trứng là ném assert trong service scene.

Nguồn. Server 0.85 gốc `/home/ubuntu/configs` — **header hai bảng giống hệt server riêng từng byte**
(PetAttr 51 cột, MonsterAttrEx 71 cột, cùng dòng kiểu và dòng tên). Vì vậy đây là phép CHÉP DÒNG NGUYÊN VĂN,
không ánh xạ cột, không chế số. Bảng CY `DataCY31-08-26/Config/PetAttrTable.txt` KHÔNG có 64 ID này (đã kiểm),
nên CY không dùng được làm nguồn.

Luật: **chỉ THÊM** dòng; dòng đã có giữ nguyên từng byte (apply từ chối nếu khác); file giữ GBK + EOL gốc;
sao lưu vào `R/backups/pet-data-<UTC>/` trước khi ghi.

  pet_data.py plan   --out <dir> [--only ID,ID]   dựng <dir>/configs/{PetAttrTable,MonsterAttrExTable}.txt
                                                  + plan.json + pet_data.tsv
  pet_data.py apply  --staging <dir> [--dry-run]  chép vào server riêng, có sao lưu
  pet_data.py verify [--staging <dir>] [--out j]  GBK, đủ cột, dòng cũ y nguyên, mọi ID script cần đều có mặt

Chạy trong WSL TLBB bằng root: `python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/pet_data.py <lệnh>`.
"""
import argparse
import datetime
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table, write_table, g, sha  # noqa: E402

R = '/home/ubuntu/cys-test-20260913'
SRC = '/home/ubuntu'                       # server 0.85 gốc, CHỈ ĐỌC
PA = 'configs/PetAttrTable.txt'
MA = 'configs/MonsterAttrExTable.txt'
CI = 'configs/CommonItem.txt'
ITEM_DIR = 'Game_2/Script/scripts/obj/commonitem'
DROPPER = 'Game_2/Script/scripts/obj/monster/petdropper.lua'
MARK = 'pet-data'


def rd(path):
    return open(path, 'rb').read().decode('gbk', 'replace').replace('\r\n', '\n').replace('\r', '\n')


def fit(row, n, tag):
    """Bảng 0.85 gốc có 147 dòng thừa TAB cuối (cột thừa đều rỗng). Cắt cho đúng bề rộng header;
    nếu cột thừa CÓ nội dung thì dừng, vì lúc đó không còn là phép chép nguyên văn."""
    if len(row) <= n:
        return row + [b''] * (n - len(row))
    extra = row[n:]
    if any(x.strip() for x in extra):
        raise SystemExit('%s: dong %s co %d cot, phan thua KHONG rong -> tu choi' % (tag, g(row[0]), len(row)))
    return row[:n]


def egg_refs():
    """{pet_data_id: [(file, item_index), ...]} lấy từ g_petList của mọi script trứng."""
    out = {}
    d = os.path.join(R, ITEM_DIR)
    for fn in sorted(os.listdir(d)):
        if not fn.endswith('.lua'):
            continue
        src = rd(os.path.join(d, fn))
        if 'CreatePetToHuman' not in src and 'CreateRMBPetToHuman' not in src:
            continue
        for m in re.finditer(r'g_petList\[(\d+)\]\s*=\s*\{\s*type=\d+,\s*dataId=(\d+)', src):
            out.setdefault(int(m.group(2)), []).append((fn, int(m.group(1))))
        for m in re.finditer(r'g_petList\[(\d+)\]\.dataIds\[\d+\]\s*=\s*\{dataId=(\d+)', src):
            out.setdefault(int(m.group(2)), []).append((fn, int(m.group(1))))
    return out


def dropper_refs():
    src = rd(os.path.join(R, DROPPER))
    out = set()
    for m in re.finditer(r'\["petList2?"\]\s*=\s*\{([^}]*)\}', src):
        out.update(int(x) for x in re.findall(r'\d+', m.group(1)))
    return out


# scripts không có chốt GetIsPetID: dùng trứng với ID thiếu là ném assert, không phải chỉ báo lỗi
UNGUARDED = {'891217.lua', '893088.lua', '893308.lua', '998545.lua', '998515.lua', '890041.lua'}


def cmd_plan(args):
    srv_pa, srv_ma = read_table(os.path.join(R, PA)), read_table(os.path.join(R, MA))
    src_pa, src_ma = read_table(os.path.join(SRC, PA)), read_table(os.path.join(SRC, MA))
    for tag, a, b in (('PetAttrTable', srv_pa, src_pa), ('MonsterAttrExTable', srv_ma, src_ma)):
        if a['types'] != b['types'] or a['names'] != b['names']:
            raise SystemExit('%s: header nguon KHAC header server -> tu choi chep dong' % tag)
    have_pa = {int(r[0]) for r in srv_pa['rows']}
    have_ma = {int(r[0]) for r in srv_ma['rows']}
    src_pa_rows = {int(r[0]): r for r in src_pa['rows']}
    src_ma_rows = {int(r[0]): r for r in src_ma['rows']}
    items = {int(r[0]) for r in read_table(os.path.join(R, CI))['rows']}

    eggs = egg_refs()
    drops = dropper_refs()
    only = set(int(x) for x in args.only.split(',') if x.strip()) if args.only else None

    need = sorted(set(eggs) | drops)
    add_pa, add_ma, no_src = [], [], []
    rowsinfo = []
    for pid in need:
        miss_pa, miss_ma = pid not in have_pa, pid not in have_ma
        if not miss_pa and not miss_ma:
            continue
        if pid not in src_pa_rows or pid not in src_ma_rows:
            no_src.append(pid)
            continue
        if only is not None and pid not in only:
            continue
        if miss_pa:
            add_pa.append(pid)
        if miss_ma:
            add_ma.append(pid)
        live = sorted({i for f, i in eggs.get(pid, []) if i in items})
        unguard = sorted({f for f, i in eggs.get(pid, []) if i in items and f in UNGUARDED})
        rowsinfo.append((pid, g(src_pa_rows[pid][1]).strip(), miss_pa, miss_ma,
                         len(eggs.get(pid, [])), live, unguard, pid in drops))

    npa, nma = len(srv_pa['types']), len(srv_ma['types'])
    out_pa = [fit(r, npa, PA) for r in srv_pa['rows']] + [fit(src_pa_rows[p], npa, PA) for p in add_pa]
    out_ma = [fit(r, nma, MA) for r in srv_ma['rows']] + [fit(src_ma_rows[p], nma, MA) for p in add_ma]
    p_pa = os.path.join(args.out, PA)
    p_ma = os.path.join(args.out, MA)
    write_table(p_pa, srv_pa['types'], srv_pa['names'], out_pa, srv_pa['eol'])
    write_table(p_ma, srv_ma['types'], srv_ma['names'], out_ma, srv_ma['eol'])

    with open(os.path.join(args.out, 'pet_data.tsv'), 'w', encoding='utf-8', newline='') as f:
        f.write('pet_id\tten\tthieu_PetAttr\tthieu_MonsterAttrEx\tso_lan_script_tro_toi\t'
                'trung_CO_THAT_trong_CommonItem\tscript_KHONG_co_chot\tpetdropper\n')
        for pid, name, mp, mm, n, live, unguard, isdrop in rowsinfo:
            f.write('%d\t%s\t%s\t%s\t%d\t%s\t%s\t%s\n' %
                    (pid, name, mp, mm, n, ','.join(str(x) for x in live), ','.join(unguard), isdrop))

    plan = {
        'source': SRC,
        'base_pet_rows': len(srv_pa['rows']), 'base_monster_rows': len(srv_ma['rows']),
        'referenced_pet_ids': len(need),
        'add_pet_attr': add_pa, 'add_monster_attr_ex': add_ma,
        'added_pet_attr': len(add_pa), 'added_monster_attr_ex': len(add_ma),
        'referenced_but_missing_in_source_too': no_src,
        'live_egg_items_unblocked': sorted({i for _, _, _, _, _, live, _, _ in rowsinfo for i in live}),
        'out': {'PetAttrTable': p_pa, 'MonsterAttrExTable': p_ma},
        'sha_out': {'PetAttrTable': sha(p_pa), 'MonsterAttrExTable': sha(p_ma)},
    }
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: plan[k] for k in ('base_pet_rows', 'base_monster_rows', 'referenced_pet_ids',
                                           'added_pet_attr', 'added_monster_attr_ex',
                                           'referenced_but_missing_in_source_too')}, ensure_ascii=False))
    print('trung CO THAT duoc mo khoa: %d' % len(plan['live_egg_items_unblocked']))


def cmd_apply(args):
    """NỐI dòng vào bản ĐANG CÓ trên server, không chép đè file staging.

    Lý do: `configs/MonsterAttrExTable.txt` là file DÙNG CHUNG (agent bản đồ cũng retype quái trong đó).
    Chép đè bằng ảnh chụp staging sẽ xoá mất thay đổi họ vừa ghi. Ở đây chỉ lấy các ID staging có mà bản
    hiện tại chưa có rồi nối vào cuối, nên chạy lại là không đổi (idempotent) và không giẫm lên ai."""
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(R, 'backups', '%s-%s' % (MARK, stamp))
    report = {'backup': bak, 'mode': 'append-merge', 'files': {}}
    todo = []
    for rel in (PA, MA):
        src, dst = os.path.join(args.staging, rel), os.path.join(R, rel)
        base, new = read_table(dst), read_table(src)
        if base['types'] != new['types'] or base['names'] != new['names']:
            raise SystemExit('%s: header staging khac header server -> tu choi' % rel)
        n = len(base['types'])
        old = {int(r[0]): fit(r, n, rel) for r in base['rows']}
        addrows = []
        for r in new['rows']:
            i = int(r[0])
            row = fit(r, n, rel)
            if i in old:
                if old[i] != row:
                    raise SystemExit('%s: dong cu %d bi doi -> tu choi' % (rel, i))
            else:
                addrows.append(row)
        todo.append((rel, dst, base, addrows, n))
    if args.dry_run:
        print(json.dumps({'dry_run': True, 'files': [{'file': t[0], 'base': len(t[2]['rows']),
                                                      'append': len(t[3])} for t in todo]}, ensure_ascii=False))
        return
    os.makedirs(bak, exist_ok=True)
    for rel, dst, base, addrows, n in todo:
        shutil.copy2(dst, os.path.join(bak, os.path.basename(rel)))
        rows = [fit(r, n, rel) for r in base['rows']] + addrows
        write_table(dst, base['types'], base['names'], rows, base['eol'])
        report['files'][rel] = {'rows_before': len(base['rows']), 'appended': len(addrows),
                                'rows_after': len(rows), 'added_ids': [int(r[0]) for r in addrows],
                                'sha': sha(dst)}
    print(json.dumps(report, ensure_ascii=False))


def cmd_verify(args):
    base = args.staging if args.staging else R
    errors, info = [], {}
    for rel in (PA, MA):
        path = os.path.join(base, rel)
        data = open(path, 'rb').read()
        try:
            data.decode('gbk')
        except UnicodeDecodeError as e:
            errors.append('%s khong phai GBK: %s' % (rel, e))
        t = read_table(path)
        n = len(t['types'])
        bad = [g(r[0]) for r in t['rows'] if len(r) != n]
        if bad:
            errors.append('%s: %d dong sai so cot (%s...)' % (rel, len(bad), ','.join(bad[:5])))
        ids = [int(r[0]) for r in t['rows']]
        dupes = sorted({i for i in ids if ids.count(i) > 1}) if len(ids) != len(set(ids)) else []
        if dupes:
            errors.append('%s: ID trung %s' % (rel, dupes[:10]))
        info[rel] = {'rows': len(t['rows']), 'cols': n, 'sha': sha(path)}

    pa = {int(r[0]) for r in read_table(os.path.join(base, PA))['rows']}
    ma = {int(r[0]) for r in read_table(os.path.join(base, MA))['rows']}
    eggs, drops = egg_refs(), dropper_refs()
    need = set(eggs) | drops
    miss_pa = sorted(need - pa)
    miss_ma = sorted(need - ma)
    items = {int(r[0]) for r in read_table(os.path.join(R, CI))['rows']}
    live_missing = sorted({i for p in miss_pa for f, i in eggs.get(p, []) if i in items})
    unguarded_live = sorted({(f, i) for p in miss_pa for f, i in eggs.get(p, [])
                             if i in items and f in UNGUARDED})
    out = {
        'base': base, 'tables': info,
        'referenced_pet_ids': len(need),
        'missing_in_PetAttrTable': miss_pa,
        'missing_in_MonsterAttrExTable': miss_ma,
        'live_egg_items_still_broken': live_missing,
        'live_egg_items_without_guard': [{'script': f, 'item': i} for f, i in unguarded_live],
        'errors': errors,
        'status': 'PASS' if not errors and not miss_pa and not miss_ma else 'FAIL',
    }
    text = json.dumps(out, ensure_ascii=False, indent=1)
    print(text)
    if args.out:
        open(args.out, 'w', encoding='utf-8').write(text)
    return 0 if out['status'] == 'PASS' else 1


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('plan'); p.add_argument('--out', required=True); p.add_argument('--only', default=''); p.set_defaults(fn=cmd_plan)
    p = sub.add_parser('apply'); p.add_argument('--staging', required=True); p.add_argument('--dry-run', action='store_true'); p.set_defaults(fn=cmd_apply)
    p = sub.add_parser('verify'); p.add_argument('--staging', default=''); p.add_argument('--out', default=''); p.set_defaults(fn=cmd_verify)
    args = ap.parse_args()
    sys.exit(args.fn(args) or 0)


if __name__ == '__main__':
    main()
