#!/usr/bin/env python3
"""title_data.py - nhap danh hieu CY con thieu vao `CharTitleNew.txt` cua server rieng (power-attrib 17/09/2026).

    python -B Tools/server/title_data.py plan   [--root R] [--out DIR]
    python -B Tools/server/title_data.py apply  [--root R] [--out DIR]
    python -B Tools/server/title_data.py verify [--root R] [--out DIR]

VI SAO LAM DUOC. `human_attrib:title_new_effect_flush` (lualib/db/human_attrib.lua:1876, goi tu dong 2135
trong lan dung lai thuoc tinh) cong 6 cap (IA, IV) cua moi dong `id_titles` vao nhan vat. Da do live 17/09:
danh hieu 1043 cho `hp_max +5000` (IA 0) va `hit +1288` (IA 35), khop dung cap trong bang. Nen moi dong
nhap them la suc manh dung duoc ngay, khong phai du lieu chet.

BON SU THAT PHAI BIET TRUOC KHI DOC MA (do 17/09, `Build/Logs/2026-09-17-power-attrib/`):

 1. **Bang cua CLIENT chinh la ban CY.** `Assets/CanonicalCY/Data/ConfigFolder/CharTitleNew.txt` la DBC nhi
    phan 00CCBBDD voi **53 cot / 1186 ban ghi** - dung bang so dong cua ban CY. Server rieng chi co **492**
    dong. Vi vay hom nay client va server dang **lech nghia** o phan lon ID.
 2. **ID KHONG dung chung.** Trong 491 ID co o ca hai ban, **0 dong trung**; vi du ID 1043: server la
    "一世有你", CY la "$N的宿敌". Chi 84 danh hieu trung TEN, va 80 trong so do **lech ID**.
    => Cong cu nay chi THEM 695 ID **chua co** tren server. Nhung ID do se khop voi client (vi client la CY).
    495 ID dang lech thi **khong dung toi** - dung luat "chi them, khong de".
 3. **Bo cot lech dung MOT cho: cot 8 va 9 doi nhau.** Dong kieu: server `... 7 STRING, 8 STRING, 9 INT ...`
    con CY `... 7 STRING, 8 INT, 9 STRING ...`. Van tay gia tri xac nhan: o CA HAI ban khoi (IA, IV) nam o
    cot **13..22** (5 cap thuc dung; cot 23..52 luon -1), cot 10/11/12 cung mien gia tri.
    => Anh xa CY -> server = **doi cot 8 va 9**, moi cot khac giu nguyen. Khong che them so nao.
 4. **`CharTitleBoard.txt` KHONG phai bang cua server.** `grep` toan bo `GameServer` khong co dong nao doc no
    (configenginer chi nap `char_title`, `char_title_new`, `pet_title`). No la bang CLIENT (bang anh danh hieu)
    va client **da co du ban CY 318 ban ghi**. Vi vay cong cu nay **khong dong toi CharTitleBoard** - them file
    do vao `configs/` chi la rac.

LUAT DA TUAN THU
  * chi chep dong CO THAT tu bang CY, khong chinh mot con so nao (ngoai viec doi cho hai cot);
  * lam o muc BYTE, khong decode/encode: `configs/*.txt` la **GBK** va `txtreader` cua server doi `gbk.toutf8`
    ca dong vo dieu kien - mot o UTF-8 le byte se nuot tab va lam lech cot am tham;
  * chi THEM dong vao cuoi, khong sua dong tieu de, khong de dong dang co (append-merge, giong cach
    `pets-wild` lam voi `MonsterAttrExTable`);
  * sao luu truoc khi ghi (`<file>.bak-title-data-<UTC>`), va idempotent: chay lai `apply` khong them gi nua.
"""
import argparse
import datetime
import json
import os
import shutil
import sys

DEFAULT_ROOT = '/home/ubuntu/cys-test-20260913'
CY_CONFIG = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
TABLE = 'CharTitleNew.txt'
HEADER_ROWS = 2
COLUMNS = 53
SWAP = (8, 9)          # anh xa CY -> server: doi hai cot nay, con lai giu nguyen
IA_PAIRS = ((13, 14), (15, 16), (17, 18), (19, 20), (21, 22), (23, 24))
TAB, CRLF, LF = b'\t', b'\r\n', b'\n'


def split_rows(raw):
    """Tach file thanh (tieu de, cac dong du lieu, ket thuc dong) o muc BYTE."""
    eol = CRLF if CRLF in raw else LF
    parts = raw.split(eol)
    while parts and not parts[-1].strip():
        parts.pop()
    return parts[:HEADER_ROWS], parts[HEADER_ROWS:], eol


def row_id(line):
    return line.split(TAB, 1)[0]


def remap(line):
    """CY -> server: doi cot 8 va 9. Tra None neu dong khong du cot (khong nhap dong hong)."""
    cells = line.split(TAB)
    if len(cells) != COLUMNS:
        return None
    i, j = SWAP
    cells[i], cells[j] = cells[j], cells[i]
    return TAB.join(cells)


def ia_pairs(line):
    cells = line.split(TAB)
    out = []
    for a, v in IA_PAIRS:
        if a < len(cells) and v < len(cells):
            try:
                ia, iv = int(cells[a]), int(cells[v])
            except ValueError:
                continue
            if ia >= 0 and iv > 0:
                out.append((ia, iv))
    return out


def load(path):
    with open(path, 'rb') as f:
        return f.read()


def build_plan(root):
    server_path = os.path.join(root, 'configs', TABLE)
    cy_path = os.path.join(CY_CONFIG, TABLE)
    s_raw, c_raw = load(server_path), load(cy_path)
    s_head, s_rows, eol = split_rows(s_raw)
    c_head, c_rows, _ = split_rows(c_raw)
    have = {row_id(r) for r in s_rows}
    add, skip_dup, skip_bad = [], 0, 0
    for r in c_rows:
        rid = row_id(r)
        if rid in have:
            skip_dup += 1
            continue
        m = remap(r)
        if m is None:
            skip_bad += 1
            continue
        add.append(m)
        have.add(rid)
    with_attr = [r for r in add if ia_pairs(r)]
    return {
        'table': TABLE,
        'server_path': server_path,
        'cy_path': cy_path,
        'eol': 'CRLF' if eol == CRLF else 'LF',
        'server_rows_before': len(s_rows),
        'cy_rows': len(c_rows),
        'rows_to_add': len(add),
        'skipped_id_already_on_server': skip_dup,
        'skipped_wrong_column_count': skip_bad,
        'rows_to_add_with_ia_iv': len(with_attr),
        'server_rows_after': len(s_rows) + len(add),
        'column_map': 'identity except columns %d<->%d' % SWAP,
        'sample_new_ids': [row_id(r).decode('ascii', 'replace') for r in add[:8]],
        'sample_with_attr': [
            {'id': row_id(r).decode('ascii', 'replace'),
             'name_gbk_hex': r.split(TAB)[2].hex(),
             'ia_iv': ia_pairs(r)} for r in with_attr[:8]],
    }, s_head, s_rows, add, eol, s_raw


def write_out(out_dir, name, payload):
    if not out_dir:
        return
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, name), 'w', encoding='utf-8') as f:
        json.dump(payload, f, ensure_ascii=False, indent=1, default=str)


def cmd_plan(args):
    plan, *_ = build_plan(args.root)
    print(json.dumps(plan, ensure_ascii=False, indent=1))
    write_out(args.out, 'title_data_plan.json', plan)
    return 0


def cmd_apply(args):
    plan, s_head, s_rows, add, eol, s_raw = build_plan(args.root)
    path = plan['server_path']
    if not add:
        plan['applied'] = False
        plan['reason'] = 'khong con dong nao de them (idempotent)'
        print(json.dumps(plan, ensure_ascii=False, indent=1))
        write_out(args.out, 'title_data_apply.json', plan)
        return 0
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    backup = '%s.bak-title-data-%s' % (path, stamp)
    shutil.copy2(path, backup)
    body = eol.join(s_head + s_rows + add) + eol
    tmp = path + '.tmp-title-data'
    with open(tmp, 'wb') as f:
        f.write(body)
    # kiem tra ngay tren file tam truoc khi thay the
    t_head, t_rows, _ = split_rows(load(tmp))
    bad = [row_id(r) for r in t_rows if len(r.split(TAB)) != COLUMNS]
    if t_head != s_head or len(t_rows) != len(s_rows) + len(add) or bad:
        os.remove(tmp)
        sys.exit('tu kiem tra that bai truoc khi thay the; file goc KHONG bi dong toi (backup %s)' % backup)
    os.replace(tmp, path)
    plan.update({'applied': True, 'backup': backup,
                 'bytes_before': len(s_raw), 'bytes_after': len(body)})
    print(json.dumps(plan, ensure_ascii=False, indent=1))
    write_out(args.out, 'title_data_apply.json', plan)
    return 0


def cmd_verify(args):
    path = os.path.join(args.root, 'configs', TABLE)
    raw = load(path)
    head, rows, eol = split_rows(raw)
    ids = [row_id(r) for r in rows]
    dup = sorted({i.decode('ascii', 'replace') for i in ids if ids.count(i) > 1})
    widths = sorted({len(r.split(TAB)) for r in rows})
    gbk_ok = True
    try:
        raw.decode('gbk')
    except UnicodeDecodeError:
        gbk_ok = False
    cy_head, cy_rows, _ = split_rows(load(os.path.join(CY_CONFIG, TABLE)))
    cy_ids = {row_id(r) for r in cy_rows}
    with_attr = sum(1 for r in rows if ia_pairs(r))
    res = {
        'table': TABLE, 'path': path, 'eol': 'CRLF' if eol == CRLF else 'LF',
        'header_rows_unchanged_columns': [len(h.split(TAB)) for h in head],
        'data_rows': len(rows),
        'distinct_ids': len(set(ids)),
        'duplicate_ids': dup,
        'column_widths_seen': widths,
        'all_rows_53_columns': widths == [COLUMNS],
        'file_decodes_as_gbk': gbk_ok,
        'rows_with_ia_iv': with_attr,
        'cy_ids_now_present': len(cy_ids & set(ids)),
        'cy_ids_still_missing': len(cy_ids - set(ids)),
    }
    res['ok'] = (not dup) and res['all_rows_53_columns'] and gbk_ok and res['header_rows_unchanged_columns'] == [COLUMNS, COLUMNS]
    print(json.dumps(res, ensure_ascii=False, indent=1))
    write_out(args.out, 'title_data_verify.json', res)
    return 0 if res['ok'] else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('plan', 'apply', 'verify'))
    ap.add_argument('--root', default=DEFAULT_ROOT)
    ap.add_argument('--out', default='')
    args = ap.parse_args()
    return {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify}[args.cmd](args)


if __name__ == '__main__':
    sys.exit(main())
