# -*- coding: utf-8 -*-
"""wardrobe: kiem ke stub con lai tren 18 khung `NewExterior_*`, XEP THEO DUONG MO KHUNG.

Vi sao khong dung thang `cys_sefit_frame_audit.py`: no doc MOT file va coi moi ten trong
`LuaApiGen_*` la stub. Nhung `wardrobe` + `wardrobe-2` da cai THAT 14 + 9 ham qua bang
`table.Register` trong `CysHost_*.cpp` — chung DE LEN stub luc chay. Dem ma khong tru phan
do thi con so to len va sai huong (dung lop benh "so dung ve THU MUC SAI").

Bo do nay:
  1. doc MOI bang dang ky that trong `Src/Client/LuaApiGen/CysHost_*.cpp`  -> tap HOSTED
  2. doc MOI stub sinh tu dong trong `LuaApiGen_*.cpp`                      -> tap STUB + dac ta rets
  3. dem loi goi trong tung file `.lua` cua 18 khung
  4. chia theo: da co host that | con stub
  5. VA tach rieng nhung loi goi nam trong DUONG MO KHUNG (`_OnLoad`, `_Show`,
     `_OnEvent`, `_UpdateObj`, `_PreLoad`) — day moi la thu nguoi choi thay khi VUA MO.

DOI CHUNG AM bat buoc: mot ten chac chan da co host that phai ra HOSTED, va mot ten bia
dat phai ra KHONG CO O DAU. Neu doi chung am truot, moi con so ben duoi vo nghia.
"""

import argparse
import json
import os
import re
from collections import defaultdict

STUB_RE = re.compile(
    r'Stub\s*\(\s*\w+\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]*)"\s*\)')
# {"Recv", "LuaFnName", Fn},  trong bang dang ky that
HOST_RE = re.compile(r'\{\s*"([A-Za-z_][\w]*)"\s*,\s*"([A-Za-z_][\w]*)"\s*,\s*&?\w+\s*\}')
CALL_RE = re.compile(r'\b([A-Za-z_]\w*)\s*:\s*(LuaFn\w+|Get\w+|Set\w+|Is\w+|Buy\w+)\s*\(')
FUNC_RE = re.compile(r'^\s*function\s+([A-Za-z_][\w]*)\s*\(', re.M)


def load_stubs(d):
    out = {}
    for fn in sorted(os.listdir(d)):
        if not fn.startswith('LuaApiGen') or not fn.endswith('.cpp'):
            continue
        for recv, name, rets in STUB_RE.findall(open(os.path.join(d, fn), encoding='utf-8', errors='replace').read()):
            out[(recv, name)] = rets
    return out


def load_hosted(d):
    out = set()
    for fn in sorted(os.listdir(d)):
        if not fn.startswith('CysHost') or not fn.endswith('.cpp'):
            continue
        for recv, name in HOST_RE.findall(open(os.path.join(d, fn), encoding='utf-8', errors='replace').read()):
            out.add((recv, name))
    return out


OPEN_SUFFIX = ('_PreLoad', '_OnLoad', '_Show', '_OnEvent', '_UpdateObj', '_OnShow', '_Update')


def func_ranges(text):
    """[(ten ham, dong bat dau, dong ket thuc)] theo thu tu xuat hien."""
    lines = text.splitlines()
    starts = []
    for i, ln in enumerate(lines, 1):
        m = re.match(r'^\s*function\s+([A-Za-z_][\w.:]*)\s*\(', ln)
        if m:
            starts.append((m.group(1), i))
    out = []
    for k, (nm, ln) in enumerate(starts):
        end = starts[k + 1][1] - 1 if k + 1 < len(starts) else len(lines)
        out.append((nm, ln, end))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--luaapigen-src', required=True)
    ap.add_argument('--interface-root', required=True)
    ap.add_argument('--prefix', default='NewExterior')
    ap.add_argument('--out', required=True)
    a = ap.parse_args()

    stubs = load_stubs(a.luaapigen_src)
    hosted = load_hosted(a.luaapigen_src)

    # ---- DOI CHUNG AM ----
    neg = []
    probe_hosted = ('FashionDepot', 'LuaFnGetFashionDepotItem')
    probe_fake = ('KhongCoThat', 'LuaFnKhongCoThatXyz')
    neg.append(('host that co trong HOSTED', probe_hosted in hosted))
    neg.append(('ten bia dat KHONG o HOSTED', probe_fake not in hosted))
    neg.append(('ten bia dat KHONG o STUB', probe_fake not in stubs))
    ok_neg = all(v for _, v in neg)

    frames = sorted(d for d in os.listdir(a.interface_root)
                    if d.startswith(a.prefix) and os.path.isdir(os.path.join(a.interface_root, d)))

    per_frame = {}
    tally_stub = defaultdict(int)
    tally_stub_open = defaultdict(int)
    rets_of = {}
    for f in frames:
        p = os.path.join(a.interface_root, f, f + '.lua')
        if not os.path.isfile(p):
            continue
        text = open(p, encoding='utf-8', errors='replace').read()
        ranges = func_ranges(text)

        def owner(lineno):
            for nm, s, e in ranges:
                if s <= lineno <= e:
                    return nm
            return '(ngoai ham)'

        n_host = n_stub = n_unknown = 0
        stub_open = []
        for i, ln in enumerate(text.splitlines(), 1):
            for recv, name in CALL_RE.findall(ln):
                key = (recv, name)
                if key in hosted:
                    n_host += 1
                elif key in stubs:
                    n_stub += 1
                    tally_stub[key] += 1
                    rets_of[key] = stubs[key]
                    fn = owner(i)
                    if fn.endswith(OPEN_SUFFIX):
                        tally_stub_open[key] += 1
                        stub_open.append({'line': i, 'in': fn, 'call': '%s:%s' % key,
                                          'rets': stubs[key], 'text': ln.strip()[:150]})
                else:
                    n_unknown += 1
        per_frame[f] = {'host_that': n_host, 'con_stub': n_stub, 'khong_ro': n_unknown,
                        'stub_tren_duong_mo': stub_open}

    top = sorted(tally_stub.items(), key=lambda kv: -kv[1])
    top_open = sorted(tally_stub_open.items(), key=lambda kv: -kv[1])

    rep = {
        'doi_chung_am': [{'phep': k, 'dat': v} for k, v in neg],
        'doi_chung_am_dat': ok_neg,
        'so_stub_sinh_tu_dong': len(stubs),
        'so_host_that': len(hosted),
        'so_khung': len(per_frame),
        'theo_khung': per_frame,
        'stub_nhieu_luot_goi_nhat': [{'call': '%s:%s' % k, 'rets': rets_of[k], 'luot': v} for k, v in top[:40]],
        'stub_tren_duong_mo_khung': [{'call': '%s:%s' % k, 'rets': rets_of[k], 'luot': v} for k, v in top_open[:40]],
    }
    os.makedirs(os.path.dirname(a.out) or '.', exist_ok=True)
    json.dump(rep, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

    print('DOI CHUNG AM: %s' % ('DAT' if ok_neg else 'TRUOT - moi con so duoi vo nghia'))
    for k, v in neg:
        print('   %-34s %s' % (k, v))
    if not ok_neg:
        return 2
    print('stub sinh tu dong=%d  host that=%d  khung=%d' % (len(stubs), len(hosted), len(per_frame)))
    print()
    print('%-34s %7s %7s %7s  %s' % ('khung', 'host', 'stub', 'kho ro', 'stub tren duong mo'))
    for f, v in sorted(per_frame.items()):
        print('%-34s %7d %7d %7d  %d' % (f, v['host_that'], v['con_stub'], v['khong_ro'], len(v['stub_tren_duong_mo'])))
    print()
    print('--- stub bi goi NHIEU NHAT (ca file) ---')
    for k, v in top[:15]:
        print('  %-52s rets=%-4s %4d luot' % ('%s:%s' % k, rets_of[k], v))
    print()
    print('--- stub NAM TREN DUONG MO KHUNG (nguoi choi thay ngay) ---')
    for k, v in top_open[:20]:
        print('  %-52s rets=%-4s %4d luot' % ('%s:%s' % k, rets_of[k], v))
    print()
    print('da ghi: %s' % a.out)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
