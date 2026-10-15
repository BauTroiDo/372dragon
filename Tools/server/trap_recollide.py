#!/usr/bin/env python3
"""trap-recollide — gỡ 66 ID bẫy "va chạm" giữa bảng CY và bảng GL/HJ của server riêng.

Vì sao: `SkillData_V1` của server đã là CY 3.71, còn `SpecialObjData` là nhánh GL/HJ. 66 ID bẫy **có dòng**
trên server nhưng là **đồ vật khác** ⇒ kỹ năng CY kích hoạt nhầm bẫy. Kế hoạch (agent `trap-collide`,
`Docs/specs/server/trap-data_vi.md` mục 5 + `Build/Logs/2026-09-17-trap-collide/README_vi.md`):
**65 ID** được cấp ID mới trong dải **3000–3064** (chép nguyên dòng CY sang ID mới, sửa ô `参数值` tương ứng
của `SkillData_V1`), **1 ID `1750` không đụng** (impact CY `46907` cũng sai nghĩa trên server).

Luật: **chỉ THÊM dòng**, không xoá, không sửa dòng cũ. Ba bảng phải đi cùng nhau:
  1. `R/configs/SpecialObjData.txt`   (GBK, 64 cột) — thêm 65 dòng CY ở ID mới.
  2. `R/configs/SkillData_V1.txt`     (GBK, 54 cột) — sửa đúng 213 ô `参数值` (ID cũ → ID mới).
  3. `CY-Source/Assets/CanonicalCY/Data/ConfigFolder/SpecialObjData.txt` (DBC nhị phân `00CCBBDD`, 63 cột,
     string pool GBK) — thêm 65 bản ghi tương ứng, nếu thiếu thì bẫy **mất hiệu ứng nhìn thấy** phía client.

Ánh xạ cột khi nhập dòng CY vào bảng server (như `trap_data.py`, đặc tả mục 2): cột 0–24 chép thẳng
(cột 0 thay bằng ID mới); 25–30 = `0` (预留/预留新增); cặp `参数说明`/`参数值` của CY (từ cột 25) đổ vào cặp của
server (từ cột 31, 16 cặp); cột 63 `详细说明(内部使用)` để rỗng. Bảng client giữ đúng 63 cột của bảng CY.

  trap_recollide.py plan   --out <dir> [--only ID,ID]   dựng <dir>/configs/*.txt + <dir>/client/SpecialObjData.txt
  trap_recollide.py apply  --staging <dir> [--dry-run]  chép vào R + client, sao lưu R/backups/trap-recollide-<UTC>/
  trap_recollide.py verify [--backup <dir>] [--out j]   GBK/cột/ID/213 ô/0 dòng cũ đổi (so hash từng dòng với sao lưu)

Chạy trong WSL TLBB bằng root: `python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/trap_recollide.py <lệnh>`.
Idempotent: chạy lại `plan` sau khi `apply` cho ra file trùng sha với bảng đang chạy; `apply` từ chối nếu phát
hiện **bất kỳ dòng cũ nào** bị đổi.
"""
import argparse
import collections
import datetime
import hashlib
import json
import os
import shutil
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table, write_table, g, sha  # noqa: E402

R = '/home/ubuntu/cys-test-20260913'
CY_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
CYS = '/mnt/c/TLBB/085/CY-Source'
PLAN_DIR = os.path.join(CYS, 'Build/Logs/2026-09-17-trap-recollide')
CLIENT = os.path.join(CYS, 'Assets/CanonicalCY/Data/ConfigFolder/SpecialObjData.txt')
SO = 'configs/SpecialObjData.txt'
SD = 'configs/SkillData_V1.txt'
SI = 'configs/StandardImpact.txt'
CLIENT_REL = 'client/SpecialObjData.txt'
MARK = 'trap-recollide'

# Nhãn `参数说明` của SkillData thật sự chứa ID SpecialObjData (đã loại nhãn đếm/buff/tập ID).
TRAP_LABELS = {
    '脚下生成陷阱ID', '陷阱数据ID', '强化陷阱1', '强化陷阱2', '陷阱id', '陷阱Data',
    '会心陷阱', '命中陷阱', '预警陷阱id', '引爆的陷阱类型ID', '引导周期释放陷阱',
    '溅射效果陷阱id', '傀儡回收后，原地留下陷阱ID', '1队友伤害陷阱', '2队友伤害陷阱',
    '3队友伤害陷阱', '4队友伤害陷阱', '5队友伤害陷阱', '陷阱ID', '生成陷阱id',
}
# Hai nhãn `trap-collide` tìm thêm (trỏ 1079/1080/1081, không va chạm) — handoff mục "VIỆC TIẾP THEO" #6.
EXTRA_LABELS = {'引导节点的陷阱ID', '增强的陷阱ID'}
ALL_LABELS = TRAP_LABELS | EXTRA_LABELS

COPY_COLS = 25             # cột 0..24 giống hệt giữa hai bảng
RESERVED = range(25, 31)   # 预留 x5 + 预留新增
PAIR0_SRV, PAIRS_SRV = 31, 16
PAIR0_CY = 25
DETAIL_COL = 63
WU = '无'
KEEP_IDS = set(range(1110, 1126))   # 16 dòng `1110–1125`: SI 13305–13316 trỏ vào 1110–1121, chuỗi còn sống
SI_KUILEI = (13305, 13316)          # dòng `傀儡香` phải giữ nguyên trỏ 1110–1121
MAGIC = b'\x00\xcc\xbb\xdd'
T_INT, T_FLOAT, T_STRING = 0, 1, 2


# ------------------------------------------------------------------ nguồn kế hoạch (scripts 20/30 dựng lại)
def load_plan_json():
    p = os.path.join(PLAN_DIR, '30-plan.json')
    with open(p, encoding='utf-8') as f:
        doc = json.load(f)
    mapping = {int(k): int(v['id_moi']) for k, v in doc['plan'].items() if v['phuong_an'] == 'a'}
    other = {int(k): v['phuong_an'] for k, v in doc['plan'].items() if v['phuong_an'] != 'a'}
    return mapping, other, doc


def load_cells_tsv():
    """(SkillData_id, cột giá trị) -> (id_cu, id_moi, nhãn) — 213 ô do `30-build-plan.py` liệt kê."""
    out = {}
    with open(os.path.join(PLAN_DIR, 'skilldata-cells.tsv'), encoding='utf-8') as f:
        f.readline()
        for ln in f:
            c = ln.rstrip('\n').split('\t')
            if len(c) < 7 or not c[2].isdigit():
                continue
            out[(int(c[2]), int(c[4]))] = (int(c[0]), int(c[1]), c[3])
    return out


# ------------------------------------------------------------------ bảng text (server + CY)
def read_cy():
    t = read_table(os.path.join(CY_DIR, 'SpecialObjData.txt'))
    return {int(r[0]): r for r in t['rows']}, t


def read_srv(rel):
    return read_table(os.path.join(R, rel))


def sd_pairs(t):
    names = [g(x).strip() for x in (t['names'] or [])]
    return [(i, i + 1) for i, n in enumerate(names) if n == '参数说明']


def build_srv_row(cy_row, ncols, new_id):
    """Dòng CY -> dòng bảng server (64 cột), ô ID thay bằng `new_id`."""
    row = [b''] * ncols
    for i in range(COPY_COLS):
        row[i] = cy_row[i] if i < len(cy_row) else b''
    row[0] = str(new_id).encode('ascii')
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


# ------------------------------------------------------------------ bảng client (DBC 00CCBBDD)
def dbc_read(path):
    with open(path, 'rb') as f:
        b = f.read()
    if b[:4] != MAGIC:
        raise SystemExit('%s khong phai DBC 00CCBBDD' % path)
    nF, nR, pool_size = struct.unpack_from('<3I', b, 4)
    types = list(struct.unpack_from('<%dI' % nF, b, 16))
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]
    if len(pool) != pool_size:
        raise SystemExit('pool %d != header %d' % (len(pool), pool_size))
    return {'nF': nF, 'nR': nR, 'types': types, 'cells': cells, 'pool': bytearray(pool)}


def dbc_write(path, d):
    out = bytearray(MAGIC)
    out += struct.pack('<3I', d['nF'], d['nR'], len(d['pool']))
    out += struct.pack('<%dI' % d['nF'], *d['types'])
    out += struct.pack('<%dI' % (d['nF'] * d['nR']), *d['cells'])
    out += d['pool']
    bytes(d['pool']).decode('gbk')          # string pool của bảng client là GBK
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(bytes(out))


def dbc_str(d, off):
    end = d['pool'].find(b'\0', off)
    return bytes(d['pool'][off:end if end >= 0 else len(d['pool'])])


def dbc_value(d, r, c):
    """Giá trị ô (bytes cho STRING, int cho INT, bit-pattern cho FLOAT) — dùng để so sánh dòng cũ."""
    v = d['cells'][r * d['nF'] + c]
    if d['types'][c] == T_STRING:
        return dbc_str(d, v)
    return v


def dbc_row(d, r):
    return tuple(dbc_value(d, r, c) for c in range(d['nF']))


def dbc_ids(d):
    return [struct.unpack('<i', struct.pack('<I', d['cells'][r * d['nF']]))[0] for r in range(d['nR'])]


def dbc_pool_index(d):
    m = {}
    for r in range(d['nR']):
        for c in range(d['nF']):
            if d['types'][c] == T_STRING:
                o = d['cells'][r * d['nF'] + c]
                m.setdefault(dbc_str(d, o), o)
    return m


def dbc_intern(d, index, raw):
    o = index.get(raw)
    if o is None:
        o = len(d['pool'])
        d['pool'] += raw + b'\0'
        index[raw] = o
    return o


def dbc_append(d, index, cy_row, new_id):
    """Thêm một bản ghi từ dòng CY (text, GBK) — cột theo đúng 63 cột của bảng CY."""
    row = []
    for c in range(d['nF']):
        raw = cy_row[c] if c < len(cy_row) else b''
        t = d['types'][c]
        if c == 0:
            row.append(struct.unpack('<I', struct.pack('<i', new_id))[0])
        elif t == T_STRING:
            row.append(dbc_intern(d, index, raw.strip()))
        elif t == T_FLOAT:
            s = raw.strip() or b'0'
            row.append(struct.unpack('<I', struct.pack('<f', float(s)))[0])
        else:
            s = raw.strip() or b'0'
            row.append(struct.unpack('<I', struct.pack('<i', int(float(s))))[0])
    d['cells'] += row
    d['nR'] += 1


# ------------------------------------------------------------------ quét ô SkillData trên bảng SỐNG
def scan_cells(sd, mapping):
    """Quét bảng sống, trả (todo, done): ô đang giữ ID cũ / ô đã mang ID mới (để idempotent)."""
    pairs = sd_pairs(sd)
    rev = {v: k for k, v in mapping.items()}
    todo, done = [], []
    for ri, r in enumerate(sd['rows']):
        sid = int(r[0])
        for a, b in pairs:
            if b >= len(r):
                continue
            lab, val = g(r[a]).strip(), g(r[b]).strip()
            if lab not in ALL_LABELS or not val.lstrip('-').isdigit():
                continue
            iv = int(val)
            if iv in mapping:
                todo.append((ri, sid, b, lab, iv, mapping[iv]))
            elif iv in rev:
                done.append((ri, sid, b, lab, rev[iv], iv))
    return todo, done


def collide_now(srv_ids, cy, sd):
    """ID bẫy được SkillData tham chiếu, có trên server nhưng TÊN khác CY."""
    pairs = sd_pairs(sd)
    ref = set()
    for r in sd['rows']:
        for a, b in pairs:
            if b < len(r) and g(r[a]).strip() in ALL_LABELS:
                v = g(r[b]).strip()
                if v.lstrip('-').isdigit() and int(v) > 0:
                    ref.add(int(v))
    srv = {int(r[0]): r for r in srv_ids}
    out = []
    for t in sorted(ref):
        if t in srv and t in cy and g(srv[t][1]).strip() != g(cy[t][1]).strip():
            out.append(t)
    return out, ref


# ------------------------------------------------------------------ plan
def cmd_plan(args):
    mapping, other, doc = load_plan_json()
    cells_tsv = load_cells_tsv()
    only = set(int(x) for x in args.only.split(',') if x.strip()) if args.only else None
    if only:
        mapping = {k: v for k, v in mapping.items() if k in only}

    errors = []
    if not args.only:
        if len(mapping) != 65:
            errors.append('ke hoach co %d ID (a), can 65' % len(mapping))
        if sorted(mapping.values()) != list(range(3000, 3065)):
            errors.append('dai ID moi khong phai 3000-3064')
    if 1750 in mapping:
        errors.append('1750 phai o phuong an (c), khong duoc cap ID moi')

    srv = read_srv(SO)
    sd = read_srv(SD)
    cy, cyt = read_cy()
    cl = dbc_read(CLIENT)
    ncols = len(srv['types'])
    have = {int(r[0]): r for r in srv['rows']}
    cl_ids = set(dbc_ids(cl))

    for old, new in sorted(mapping.items()):
        if old not in cy:
            errors.append('ID cu %d khong co trong bang CY' % old)
        if new in have and new in cl_ids:
            continue                                  # đã áp — idempotent
        if new in have or new in cl_ids:
            errors.append('ID moi %d chi co o mot bang (server=%s, client=%s)' % (new, new in have, new in cl_ids))
        if new in cy:
            errors.append('ID moi %d da co trong bang CY nguon' % new)

    # --- 65 dòng cho bảng server
    add = [(o, n) for o, n in sorted(mapping.items()) if n not in have]
    rows = list(srv['rows']) + [build_srv_row(cy[o], ncols, n) for o, n in add]
    write_table(os.path.join(args.out, SO), srv['types'], srv['names'], rows, srv['eol'])

    # --- 213 ô của SkillData
    todo, done = scan_cells(sd, mapping)
    got = {(sid, col) for _, sid, col, _, _, _ in todo} | {(sid, col) for _, sid, col, _, _, _ in done}
    if not args.only:
        want = set(cells_tsv)
        if got != want:
            errors.append('o SkillData lech ke hoach: thieu %s, thua %s' %
                          (sorted(want - got)[:5], sorted(got - want)[:5]))
    for (ri, sid, col, lab, old, new) in todo:
        exp = cells_tsv.get((sid, col))
        if exp and (exp[0], exp[1]) != (old, new):
            errors.append('o (%d,%d) ke hoach %s nhung bang song %s' % (sid, col, exp[:2], (old, new)))
    sd_rows = [list(r) for r in sd['rows']]
    for (ri, sid, col, lab, old, new) in todo:
        sd_rows[ri][col] = str(new).encode('ascii')
    write_table(os.path.join(args.out, SD), sd['types'], sd['names'], sd_rows, sd['eol'])

    # --- 65 bản ghi cho bảng client
    index = dbc_pool_index(cl)
    cl_add = [(o, n) for o, n in sorted(mapping.items()) if n not in cl_ids]
    for o, n in cl_add:
        dbc_append(cl, index, cy[o], n)
    dbc_write(os.path.join(args.out, CLIENT_REL), cl)

    # --- báo cáo
    impacts = si_ids()
    miss_imp = collections.Counter()
    tsv = os.path.join(args.out, 'trap_recollide.tsv')
    with open(tsv, 'w', encoding='utf-8', newline='') as f:
        f.write('id_cu\tid_moi\tten_CY\tten_server_cu\tso_o_SkillData\timpact_cua_bay\timpact_thieu\n')
        for o, n in sorted(mapping.items()):
            imps = cy_impacts(cy[o])
            miss = [str(x) for x in imps if x not in impacts]
            for x in miss:
                miss_imp[x] += 1
            nc = sum(1 for k in cells_tsv if cells_tsv[k][0] == o)
            f.write('%d\t%d\t%s\t%s\t%d\t%s\t%s\n' % (o, n, g(cy[o][1]).strip(),
                                                      g(have[o][1]).strip() if o in have else '',
                                                      nc, ','.join(str(x) for x in imps), ','.join(miss)))
    plan = {
        'mapping': {str(k): v for k, v in sorted(mapping.items())},
        'khong_dung': other,
        'so_dong_them_server': len(add), 'so_ban_ghi_them_client': len(cl_add),
        'so_o_SkillData_sua': len(todo), 'so_o_da_dung': len(done), 'so_o_ke_hoach': len(cells_tsv),
        'server_rows': len(rows), 'client_records': cl['nR'], 'skilldata_rows': len(sd_rows),
        'impact_cua_bay_moi_con_thieu': {k: v for k, v in sorted(miss_imp.items(), key=lambda kv: int(kv[0]))},
        'errors': errors,
        'sha': {SO: sha(os.path.join(args.out, SO)), SD: sha(os.path.join(args.out, SD)),
                CLIENT_REL: sha(os.path.join(args.out, CLIENT_REL))},
    }
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: plan[k] for k in ('so_dong_them_server', 'so_ban_ghi_them_client', 'so_o_SkillData_sua',
                                           'so_o_da_dung', 'so_o_ke_hoach', 'server_rows', 'client_records',
                                           'errors')}, ensure_ascii=False))
    print('impact cua bay moi con thieu: %d | %s' % (len(miss_imp), tsv))
    return 2 if errors else 0


# ------------------------------------------------------------------ apply
def cmd_apply(args):
    mapping, _, _ = load_plan_json()
    stage_so = os.path.join(args.staging, SO)
    stage_sd = os.path.join(args.staging, SD)
    stage_cl = os.path.join(args.staging, CLIENT_REL)
    cells_tsv = load_cells_tsv()

    # --- SpecialObjData: mọi dòng cũ phải y nguyên
    base_so, new_so = read_table(os.path.join(R, SO)), read_table(stage_so)
    old = {int(r[0]): r for r in base_so['rows']}
    seen = set()
    for r in new_so['rows']:
        i = int(r[0])
        if i in seen:
            raise SystemExit('ID trung trong staging: %d' % i)
        seen.add(i)
        if i in old and old[i] != r:
            raise SystemExit('dong cu %d cua SpecialObjData bi doi -> tu choi' % i)
    if set(old) - seen:
        raise SystemExit('staging thieu dong cu: %s' % sorted(set(old) - seen)[:5])

    # --- SkillData: chỉ được đổi trong 213 ô của kế hoạch
    base_sd, new_sd = read_table(os.path.join(R, SD)), read_table(stage_sd)
    if len(base_sd['rows']) != len(new_sd['rows']):
        raise SystemExit('SkillData doi so dong -> tu choi')
    changed = []
    for a, b in zip(base_sd['rows'], new_sd['rows']):
        if a == b:
            continue
        if a[0] != b[0] or len(a) != len(b):
            raise SystemExit('SkillData doi ID/so cot o dong %s -> tu choi' % g(a[0]))
        for c in range(len(a)):
            if a[c] != b[c]:
                changed.append((int(a[0]), c, g(a[c]).strip(), g(b[c]).strip()))
    bad = [x for x in changed if (x[0], x[1]) not in cells_tsv]
    if bad:
        raise SystemExit('SkillData doi %d o NGOAI ke hoach, vi du %s -> tu choi' % (len(bad), bad[:3]))
    for sid, c, ov, nv in changed:
        exp = cells_tsv[(sid, c)]
        if int(nv) != exp[1] or int(ov) != exp[0]:
            raise SystemExit('o (%d,%d) doi %s->%s, ke hoach %s -> tu choi' % (sid, c, ov, nv, exp[:2]))

    # --- client: mọi bản ghi cũ phải y nguyên (so theo GIÁ TRỊ, không theo offset)
    base_cl, new_cl = dbc_read(CLIENT), dbc_read(stage_cl)
    if new_cl['nF'] != base_cl['nF'] or new_cl['types'] != base_cl['types']:
        raise SystemExit('bang client doi so cot/kieu -> tu choi')
    if new_cl['nR'] < base_cl['nR']:
        raise SystemExit('bang client mat ban ghi -> tu choi')
    for r in range(base_cl['nR']):
        if dbc_row(base_cl, r) != dbc_row(new_cl, r):
            raise SystemExit('ban ghi client cu #%d bi doi -> tu choi' % r)
    ids_new = dbc_ids(new_cl)
    if ids_new != sorted(ids_new) or len(set(ids_new)) != len(ids_new):
        raise SystemExit('bang client khong con sap xep tang dan / co ID trung -> tu choi')

    info = {'server_rows': len(new_so['rows']), 'them_dong_server': len(new_so['rows']) - len(base_so['rows']),
            'skilldata_o_doi': len(changed), 'client_records': new_cl['nR'],
            'them_ban_ghi_client': new_cl['nR'] - base_cl['nR']}
    if args.dry_run:
        print(json.dumps(dict(info, dry_run=True), ensure_ascii=False))
        return 0

    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(R, 'backups', '%s-%s' % (MARK, stamp))
    os.makedirs(bak, exist_ok=True)
    man = {}
    for src, name in ((os.path.join(R, SO), 'SpecialObjData.txt'),
                      (os.path.join(R, SD), 'SkillData_V1.txt'),
                      (CLIENT, 'client-SpecialObjData.txt')):
        shutil.copy2(src, os.path.join(bak, name))
        man[name] = {'tu': src, 'sha256': sha(src)}
    with open(os.path.join(bak, 'manifest.json'), 'w', encoding='utf-8') as f:
        json.dump({'mark': MARK, 'utc': stamp, 'files': man, 'mapping_n': len(mapping)}, f,
                  ensure_ascii=False, indent=1)
    shutil.copy2(stage_so, os.path.join(R, SO))
    shutil.copy2(stage_sd, os.path.join(R, SD))
    shutil.copy2(stage_cl, CLIENT)
    info.update({'backup': bak, 'sha_server_so': sha(os.path.join(R, SO)),
                 'sha_server_sd': sha(os.path.join(R, SD)), 'sha_client': sha(CLIENT)})
    print(json.dumps(info, ensure_ascii=False))
    return 0


# ------------------------------------------------------------------ verify
def newest_backup():
    d = os.path.join(R, 'backups')
    cand = sorted(x for x in os.listdir(d) if x.startswith(MARK + '-'))
    return os.path.join(d, cand[-1]) if cand else ''


def line_hashes(path):
    """ID -> sha1 của dòng thô (bytes). Dùng để chứng minh '0 dòng cũ đổi'."""
    with open(path, 'rb') as f:
        data = f.read()
    out, extra = {}, []
    for ln in data.split(b'\n'):
        ln = ln.rstrip(b'\r')
        if not ln.strip():
            continue
        c = ln.split(b'\t')
        try:
            i = int(c[0])
        except ValueError:
            extra.append(hashlib.sha1(ln).hexdigest())
            continue
        out[i] = hashlib.sha1(ln).hexdigest()
    return out, extra


def cmd_verify(args):
    mapping, other, _ = load_plan_json()
    cells_tsv = load_cells_tsv()
    errors, warn = [], []
    so_path, sd_path = os.path.join(R, SO), os.path.join(R, SD)

    # 1. GBK + số cột + ID không trùng
    for p, ncols in ((so_path, 64), (sd_path, 54)):
        with open(p, 'rb') as f:
            data = f.read()
        try:
            data.decode('gbk')
        except UnicodeDecodeError as e:
            errors.append('%s khong phai GBK: %s' % (os.path.basename(p), e))
        t = read_table(p)
        if len(t['types']) != ncols:
            errors.append('%s co %d cot, can %d' % (os.path.basename(p), len(t['types']), ncols))
        for r in t['rows']:
            if len(r) != len(t['types']):
                errors.append('%s ID %s co %d cot' % (os.path.basename(p), g(r[0]), len(r)))
                break
        ids = [int(r[0]) for r in t['rows']]
        dup = [i for i, c in collections.Counter(ids).items() if c > 1]
        if dup:
            errors.append('%s ID trung: %s' % (os.path.basename(p), dup[:5]))

    srv = read_srv(SO)
    sd = read_srv(SD)
    cy, _ = read_cy()
    cl = dbc_read(CLIENT)
    try:
        bytes(cl['pool']).decode('gbk')
    except UnicodeDecodeError as e:
        errors.append('string pool client khong phai GBK: %s' % e)
    if cl['nF'] != 63:
        errors.append('bang client co %d cot, can 63' % cl['nF'])
    cl_ids = dbc_ids(cl)
    if cl_ids != sorted(cl_ids):
        errors.append('bang client khong sap xep tang dan (Search_Index_EQU dung nhi phan)')
    if len(set(cl_ids)) != len(cl_ids):
        errors.append('bang client co ID trung')

    # 2. 65 ID mới có mặt ở CẢ server lẫn client, và nội dung đúng dòng CY
    have = {int(r[0]): r for r in srv['rows']}
    cl_at = {i: r for r, i in enumerate(cl_ids)}
    ncols = len(srv['types'])
    miss_srv = [n for n in mapping.values() if n not in have]
    miss_cl = [n for n in mapping.values() if n not in cl_at]
    if miss_srv:
        errors.append('thieu ID moi o server: %s' % miss_srv[:10])
    if miss_cl:
        errors.append('thieu ID moi o client: %s' % miss_cl[:10])
    bad_row = []
    for o, n in sorted(mapping.items()):
        if n in have and have[n] != build_srv_row(cy[o], ncols, n):
            bad_row.append(n)
        if n in cl_at:
            r = cl_at[n]
            for c in range(cl['nF']):
                raw = cy[o][c] if c < len(cy[o]) else b''
                if cl['types'][c] == T_STRING:
                    if dbc_value(cl, r, c) != raw.strip():
                        bad_row.append('%d/client/c%d' % (n, c))
                        break
                elif c and cl['types'][c] == T_INT:
                    if struct.unpack('<i', struct.pack('<I', dbc_value(cl, r, c)))[0] != int(float(raw.strip() or b'0')):
                        bad_row.append('%d/client/c%d' % (n, c))
                        break
    if bad_row:
        errors.append('dong moi khong khop dong CY: %s' % bad_row[:10])

    # 3. 213 ô SkillData mang giá trị mới; 0 ô nhãn bẫy còn trỏ ID cũ
    todo, done = scan_cells(sd, mapping)
    if todo:
        errors.append('con %d o SkillData tro ID cu, vi du %s' % (len(todo), [(x[1], x[2], x[4]) for x in todo[:5]]))
    got = {(sid, col) for _, sid, col, _, _, _ in done}
    if got != set(cells_tsv):
        errors.append('o da doi lech ke hoach: thieu %s, thua %s' %
                      (sorted(set(cells_tsv) - got)[:5], sorted(got - set(cells_tsv))[:5]))

    # 4. so hash từng dòng với bản sao lưu -> "0 dòng cũ đổi", "0 ô nào khác đổi"
    bak = args.backup or newest_backup()
    cmp_out = {}
    if bak and os.path.isdir(bak):
        for name, live, ncol_check in (('SpecialObjData.txt', so_path, None), ('SkillData_V1.txt', sd_path, None)):
            old_h, _ = line_hashes(os.path.join(bak, name))
            new_h, _ = line_hashes(live)
            removed = sorted(set(old_h) - set(new_h))
            added = sorted(set(new_h) - set(old_h))
            chg = sorted(i for i in set(old_h) & set(new_h) if old_h[i] != new_h[i])
            cmp_out[name] = {'dong_cu': len(old_h), 'dong_moi': len(new_h), 'them': added[:70],
                             'xoa': removed, 'doi': chg}
            if removed:
                errors.append('%s: mat %d dong cu' % (name, len(removed)))
            if name == 'SpecialObjData.txt':
                if chg:
                    errors.append('SpecialObjData: %d dong cu BI DOI: %s' % (len(chg), chg[:10]))
                if added != sorted(mapping.values()):
                    errors.append('SpecialObjData: dong them khong dung dai ID moi')
            else:
                exp_rows = sorted({sid for sid, _ in cells_tsv})
                if added:
                    errors.append('SkillData: them dong moi %s' % added[:5])
                if chg != exp_rows:
                    errors.append('SkillData: dong doi %d, ke hoach %d (lech %s)' %
                                  (len(chg), len(exp_rows), sorted(set(chg) ^ set(exp_rows))[:5]))
        # client: so từng bản ghi cũ theo giá trị
        bcl = dbc_read(os.path.join(bak, 'client-SpecialObjData.txt'))
        diff = [r for r in range(min(bcl['nR'], cl['nR'])) if dbc_row(bcl, r) != dbc_row(cl, r)]
        cmp_out['client-SpecialObjData.txt'] = {'ban_ghi_cu': bcl['nR'], 'ban_ghi_moi': cl['nR'],
                                                'ban_ghi_cu_bi_doi': diff[:10], 'them': cl['nR'] - bcl['nR']}
        if diff:
            errors.append('client: %d ban ghi cu bi doi' % len(diff))
        if cl['nR'] - bcl['nR'] != len(mapping):
            errors.append('client: them %d ban ghi, can %d' % (cl['nR'] - bcl['nR'], len(mapping)))
    else:
        warn.append('khong tim thay ban sao luu trap-recollide-* -> bo qua phep so hash tung dong')

    # 5. chuỗi 傀儡香 (SI 13305-13316 -> bẫy 1110-1121) phải còn nguyên
    si = read_srv(SI)
    si_names = [g(x).strip() for x in (si['names'] or [])]
    si_pairs = [(i, i + 1) for i, n in enumerate(si_names) if n.startswith('参数') and n.endswith('说明')]
    kuilei = {}
    for r in si['rows']:
        i = int(r[0])
        if SI_KUILEI[0] <= i <= SI_KUILEI[1]:
            vals = set()
            for a, b in si_pairs:
                if b < len(r) and g(r[a]).strip() in ALL_LABELS and g(r[b]).strip().lstrip('-').isdigit():
                    vals.add(int(g(r[b]).strip()))
            kuilei[i] = sorted(vals)
    exp_kuilei = {13305 + k: [1110 + k] for k in range(12)}
    if kuilei != exp_kuilei:
        errors.append('chuoi 傀儡香 SI 13305-13316 doi: %s' % {k: v for k, v in kuilei.items()
                                                              if exp_kuilei.get(k) != v})
    for i in sorted(KEEP_IDS):
        if i not in have:
            errors.append('mat dong cu %d (1110-1125 khong duoc dung toi)' % i)

    # 6. còn bao nhiêu ID bẫy CY va chạm + impact của bẫy mới còn thiếu
    still, ref = collide_now(srv['rows'], cy, sd)
    impacts = si_ids()
    miss_imp = collections.defaultdict(list)
    for o, n in sorted(mapping.items()):
        for x in cy_impacts(cy[o]):
            if x not in impacts:
                miss_imp[x].append(n)

    out = {'server_so': {'rows': len(srv['rows']), 'sha': sha(so_path)},
           'server_sd': {'rows': len(sd['rows']), 'sha': sha(sd_path)},
           'client': {'records': cl['nR'], 'fields': cl['nF'], 'sha': sha(CLIENT)},
           'id_moi': len(mapping), 'o_SkillData_da_doi': len(done), 'o_SkillData_con_ID_cu': len(todo),
           'backup': bak, 'so_sanh_sao_luu': cmp_out,
           'bay_CY_con_va_cham': still, 'so_bay_CY_con_va_cham': len(still),
           'khong_dung': other,
           'impact_cua_bay_moi_con_thieu': {str(k): v for k, v in sorted(miss_imp.items())},
           'warnings': warn, 'errors': errors, 'ok': not errors}
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(out, f, ensure_ascii=False, indent=1)
    brief = {k: out[k] for k in ('id_moi', 'o_SkillData_da_doi', 'o_SkillData_con_ID_cu',
                                 'so_bay_CY_con_va_cham', 'bay_CY_con_va_cham', 'errors', 'ok')}
    brief['impact_thieu'] = sorted(miss_imp)
    print(json.dumps(brief, ensure_ascii=False))
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
    a.add_argument('--backup', default='')
    a.add_argument('--out', default='')
    a.set_defaults(fn=cmd_verify)
    args = ap.parse_args()
    sys.exit(args.fn(args) or 0)


if __name__ == '__main__':
    main()
