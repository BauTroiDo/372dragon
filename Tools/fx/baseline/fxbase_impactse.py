#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'CYS-FXBASE (fx-cy-baseline, 19/09/2026): fake ImpactSEData_V1 rows so CY 3.71 and CY-Source play the SAME effect\ntemplate on the SAME NPC through the SAME packet (GCCharImpactListUpdate), one row per effect of the 141-effect list.'
import argparse
import hashlib
import json
import os
import re
import struct
import sys

MAGIC = b'\x00\xcc\xbb\xdd'
T_INT, T_FLOAT, T_STRING = 0, 1, 2
COL_ENABLE_FX, COL_ENABLE_BIND, COL_FX, COL_BIND = 4, 6, 7, 9
COL_NAME, COL_DESC = 3, 16
TEMPLATE_ID = 13          # Buff0_9: continuous buff (buff_fengxue_01 at 脚下光圈点), proven on CY in run-24-fx
BIND_BODY = '身体受击点'
BIND_FOOT = '脚下光圈点'
LATE = {'B10': 6100, 'T01': 3150}   # StartTime (ms) of the first element (fx-rescore bẫy 10)
MODE = 'continuous'


def dbc_read(path):
    b = open(path, 'rb').read()
    if b[:4] != MAGIC:
        sys.exit('%s: not a 00CCBBDD DBC' % path)
    nF, nR, pool_size = struct.unpack_from('<3I', b, 4)
    types = list(struct.unpack_from('<%dI' % nF, b, 16))
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]
    if len(pool) != pool_size:
        sys.exit('%s: pool %d != header %d' % (path, len(pool), pool_size))
    return {'nF': nF, 'nR': nR, 'types': types, 'cells': cells, 'pool': bytearray(pool),
            'sha256': hashlib.sha256(b).hexdigest(), 'bytes': len(b), 'path': path}


def dbc_bytes(d):
    out = bytearray(MAGIC)
    out += struct.pack('<3I', d['nF'], d['nR'], len(d['pool']))
    out += struct.pack('<%dI' % d['nF'], *d['types'])
    out += struct.pack('<%dI' % (d['nF'] * d['nR']), *d['cells'])
    out += bytes(d['pool'])
    return bytes(out)


def s_at(pool, o):
    if o >= len(pool):
        return b''
    e = pool.find(b'\0', o)
    return bytes(pool[o:e if e >= 0 else len(pool)])


def cell_bytes(d, r, c):
    return s_at(d['pool'], d['cells'][r * d['nF'] + c])


def row_int(d, r, c):
    return struct.unpack('<i', struct.pack('<I', d['cells'][r * d['nF'] + c]))[0]


def find_row(d, id_):
    for r in range(d['nR']):
        if row_int(d, r, 0) == id_:
            return r
    return -1


def pool_add(d, raw):
    """Append raw bytes + NUL to the pool, return the offset (pool must end with NUL: it does, we only append)."""
    if raw == b'':
        return 0
    off = len(d['pool'])
    d['pool'] += raw + b'\0'
    return off


def read_list(path, only=None):
    rows = []
    with open(path, encoding='utf-8-sig') as f:
        for line in f:
            line = line.rstrip('\r\n')
            if not line or line.startswith('#'):
                continue
            c = line.split('\t')
            if only is not None and c[0] not in only:
                continue
            rows.append((c[0], c[1], c[2]))
    return rows


def bind_for(fid, name):
    if fid.startswith('A') or re.search(r'光环|aura|脚下|projector', name):
        return BIND_FOOT
    return BIND_BODY


def append_rows(d, plan):
    """Appends one row per plan item (cloned from TEMPLATE_ID), returns the list of new record indexes."""
    tr = find_row(d, TEMPLATE_ID)
    if tr < 0:
        sys.exit('template row %d missing in %s' % (TEMPLATE_ID, d['path']))
    nF = d['nF']
    tmpl = d['cells'][tr * nF:(tr + 1) * nF]
    if d['types'][COL_FX] != T_STRING or d['types'][COL_BIND] != T_STRING:
        sys.exit('unexpected column types')
    empty = None
    for c in range(nF):
        if d['types'][c] == T_STRING and cell_bytes(d, tr, c) == b'':
            empty = tmpl[c]
            break
    if empty is None:
        empty = pool_add(d, b'')
    last_id = row_int(d, d['nR'] - 1, 0)
    new = []
    for item in plan:
        if item['impact'] <= last_id:
            sys.exit('impact id %d not above the last id %d' % (item['impact'], last_id))
        last_id = item['impact']
        cells = list(tmpl)
        cells[0] = item['impact']
        cells[1] = item['impact']
        cells[COL_NAME] = pool_add(d, ('FxBase_%s' % item['fid']).encode('ascii'))
        if MODE == 'enable':


            cells[COL_ENABLE_FX] = pool_add(d, item['effect'].encode('gbk'))
            cells[COL_ENABLE_BIND] = pool_add(d, item['bind'].encode('gbk'))
            cells[COL_FX] = empty
            cells[COL_BIND] = empty
        else:
            cells[COL_ENABLE_FX] = empty
            cells[COL_ENABLE_BIND] = empty
            cells[COL_FX] = pool_add(d, item['effect'].encode('gbk'))
            cells[COL_BIND] = pool_add(d, item['bind'].encode('gbk'))
        cells[COL_DESC] = pool_add(d, ('CYS-FXBASE %s' % item['fid']).encode('ascii'))
        d['cells'] += cells
        new.append(d['nR'])
        d['nR'] += 1
    return new


def verify(path, base, plan):
    """Re-reads the written table: old rows identical, pool prefix kept, new rows decode to the plan, ids sorted."""
    d = dbc_read(path)
    n0 = base['nR']
    ok = {'header': d['nF'] == base['nF'] and d['nR'] == n0 + len(plan) and d['types'] == base['types'],
          'old_cells': d['cells'][:n0 * d['nF']] == base['cells'],
          'pool_prefix': bytes(d['pool'][:len(base['pool'])]) == bytes(base['pool']),
          'pool_nul': d['pool'][-1] == 0}
    ids = [row_int(d, r, 0) for r in range(d['nR'])]
    ok['ids_sorted_unique'] = ids == sorted(ids) and len(set(ids)) == len(ids)
    bad = []
    for i, item in enumerate(plan):
        r = n0 + i
        fxc, bindc = (COL_ENABLE_FX, COL_ENABLE_BIND) if MODE == 'enable' else (COL_FX, COL_BIND)
        otherc = COL_FX if MODE == 'enable' else COL_ENABLE_FX
        fx = cell_bytes(d, r, fxc).decode('gbk')
        bind = cell_bytes(d, r, bindc).decode('gbk')
        if row_int(d, r, 0) != item['impact'] or fx != item['effect'] or bind != item['bind'] or cell_bytes(d, r, otherc) != b'':
            bad.append(item['fid'])
    ok['rows'] = not bad
    ok['bad'] = bad
    # second reader (Tools/game/dbc_inventory.Table mirrors TLBB_DBC.cpp)
    try:
        sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'game'))
        import dbc_inventory
        t = dbc_inventory.Table(path)
        ok['second_reader_rows'] = t.records == d['nR']
        ok['second_reader_last_fx'] = t.rows[-1][COL_ENABLE_FX if MODE == 'enable' else COL_FX] == plan[-1]['effect']
    except Exception as e:  # noqa: BLE001
        ok['second_reader_error'] = repr(e)
    ok['all'] = all(v for k, v in ok.items() if k not in ('bad',) and isinstance(v, bool))
    ok['sha256'] = d['sha256']
    ok['rows_total'] = d['nR']
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--cy-base', required=True)
    ap.add_argument('--our-base', required=True)
    ap.add_argument('--list', required=True)
    ap.add_argument('--extra', action='append', default=[], help='<list.tsv>:<id,id,...>')
    ap.add_argument('--out', required=True)
    ap.add_argument('--first-id', type=int, default=20001)
    ap.add_argument('--mode', choices=('continuous', 'enable'), default='continuous')
    a = ap.parse_args()
    global MODE
    MODE = a.mode
    items = read_list(a.list)
    for ex in a.extra:
        path, ids = ex.split(':', 1)
        items += read_list(path, set(ids.split(',')))
    plan = []
    seen = set()
    for i, (fid, kind, name) in enumerate(items):
        if kind != 'effect':
            continue
        if name in seen:
            continue
        seen.add(name)
        plan.append({'fid': fid, 'impact': a.first_id + len(plan), 'effect': name, 'bind': bind_for(fid, name),
                     'late_ms': LATE.get(fid, 0)})
    # control row: the proven template effect through a NEW id (tests the override path on both sides)
    plan.append({'fid': 'CTRL', 'impact': a.first_id + len(plan), 'effect': 'buff_fengxue_01', 'bind': BIND_FOOT, 'late_ms': 0})
    out = {}
    for side, base_path in (('cy', a.cy_base), ('ours', a.our_base)):
        base = dbc_read(base_path)
        d = dbc_read(base_path)
        append_rows(d, plan)
        dst_dir = os.path.join(a.out, side)
        os.makedirs(dst_dir, exist_ok=True)
        dst = os.path.join(dst_dir, 'ImpactSEData_V1.txt')
        with open(dst, 'wb') as f:
            f.write(dbc_bytes(d))
        v = verify(dst, base, plan)
        v['base_sha256'] = base['sha256']
        v['base_rows'] = base['nR']
        v['base_path'] = base_path
        out[side] = v
        print('%s: %s rows %d -> %d all_ok=%s bad=%s' % (side, dst, base['nR'], v['rows_total'], v['all'], v['bad']))
    # both sides must carry byte-identical effect / bind cells for every new row
    cy, ours = dbc_read(os.path.join(a.out, 'cy', 'ImpactSEData_V1.txt')), dbc_read(os.path.join(a.out, 'ours', 'ImpactSEData_V1.txt'))
    same = all(all(cell_bytes(cy, cy['nR'] - len(plan) + i, c) == cell_bytes(ours, ours['nR'] - len(plan) + i, c)
                   for c in (COL_ENABLE_FX, COL_ENABLE_BIND, COL_FX, COL_BIND))
               for i in range(len(plan)))
    # and the existing template row must agree on both sides (effect + bind bytes)
    tcy, tours = find_row(cy, TEMPLATE_ID), find_row(ours, TEMPLATE_ID)
    tmpl_same = cell_bytes(cy, tcy, COL_FX) == cell_bytes(ours, tours, COL_FX) and cell_bytes(cy, tcy, COL_BIND) == cell_bytes(ours, tours, COL_BIND)
    out['both_sides_same_new_cells'] = same
    out['template_row_same_both_sides'] = tmpl_same
    out['plan_rows'] = len(plan)
    with open(os.path.join(a.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1)
    with open(os.path.join(a.out, 'verify.json'), 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print('plan rows %d, new cells identical on both sides: %s, template row identical: %s' % (len(plan), same, tmpl_same))
    return 0 if (out['cy']['all'] and out['ours']['all'] and same and tmpl_same) else 1


if __name__ == '__main__':
    sys.exit(main())
