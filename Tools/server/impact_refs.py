#!/usr/bin/env python3
"""impact_refs.py - quet MOI noi tham chieu ID `StandardImpact` tren server rieng (server-data 18/09/2026).

VI SAO. Commit `ed09b4f` doi `configs/StandardImpact.txt` sang **truc ID cua CY** nhung khong doi cac
o TRO TOI bang do. Tinh toi 18/09 da tim ra **ba** cho bi bo quen:

  1. `Exterior_Ride.txt`                      -> nhanh `ride-data` da va
  2. `cy_four_combat/native_config.lua params`-> `cyfour_params.py` da va (282 o)
  3. `g_Impact1/2` cua script vat pham        -> `impact_map.py` da va (341 o)

Cong cu nay tra loi cau hoi "**con cho thu tu khong?**" bang cach quet co he thong, khong doan.

CACH PHAN BIET NGHI NGO THAT VOI BAO DONG GIA - luat quan trong nhat cua file nay:

  Mot bang **da la bang CY** thi o impact cua no **da o truc CY** => khac ten so voi bang 0.85 la
  DUNG, khong phai loi. Vi du `EquipBase.txt` co 26 ID "khac ten" nhung ca 26 deu khong co dong
  `+30000` => do la ID cua CY that. Neu khong phan biet dieu nay, phep do se bao "hong 26 o" va nguoi
  sua se pha bang CY.

  Vi vay moi bang duoc gan **nguon**, do bang cach so voi hai ban goc:
    `CY`   - trung so cot voi ban do text cua CY (`<TLBB>/Tools/DATA NEW/DataCY31-08-26/Config/`)
             va khac ban 0.85  => o cua no da o truc CY, KHONG nghi ngo
    `0.85` - trung byte (hoac trung so cot + so dong) voi `/home/ubuntu/configs/`  => o cua no con o
             truc 0.85 => **nghi ngo that** neu ID doi nghia
    `?`    - khong ket luan duoc => bao rieng, phai soi tay

Nguon doi chieu nghia goc: bang 0.85 o `/home/ubuntu/configs/StandardImpact.txt` (= ban `67fc059`
cua cay R, da kiem cung 18.167 dong).

Lenh:

  impact_refs.py scan [--json F] [--tsv F]
        quet ca hai lop va in bang tong ket:
          * LOP BANG : moi cot cua moi bang trong `configs/` co ten goi y "ID hieu ung"
          * LOP LUA  : `g_Impact\\d`, doi so thu 4 cua `LuaFnSendSpecificImpactToUnit`, va cac loi goi
                       `SendSpecificImpactToUnit` / `send_impact_to_unit` co hang so
        Moi o duoc xep mot trong bon trang thai:
          `thieu`      ID khong co dong trong bang CY
          `doi_nghia`  co o CA HAI bang nhung KHAC TEN  -> nghi ngo (neu nguon la 0.85)
          `ok`         co o ca hai bang, cung ten
          `chi_CY`     co trong bang CY, khong co trong bang 0.85 -> ID rieng cua CY, binh thuong

Chi doc, khong ghi gi vao server.

    python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/impact_refs.py scan
Dac ta: `Docs/specs/server/server-data_vi.md` muc 5.
"""
import argparse
import collections
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table, g  # noqa: E402

R = '/home/ubuntu/cys-test-20260913'
OLD = '/home/ubuntu'
CYDUMP = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
SI = 'configs/StandardImpact.txt'
SHIFT = 30000

# Ten cot goi y "day la mot ID cua StandardImpact".
COL_PAT = re.compile('|'.join([
    '效果ID', '效果编号', 'buffID', 'BuffID', 'buff_id', 'impact', 'Impact',
    '免疫ID', '状态ID', '附加效果', '驻留效果', '瞬发效果',
]))
# Cot CHAC CHAN khong phai ID impact du ten co chu "效果".
COL_DENY = re.compile('效果描述|效果名称|说明|特效|音效|效果类型|效果范围|效果几率|效果值|效果时间')

# Cot co TEN goi y "ID hieu ung" nhung DA TRUY RA la thu khac. Bo han, kem ly do.
# (Ban dau cong cu nay bao 5.569 o nghi o day - mot BAO DONG GIA do chinh no tao ra.)
COL_EXCLUDE = {
    ('StandardImpact.txt', 5):
        'cot 5 `瞬发效果ID/驻留效果ID` KHONG phai chi so vao StandardImpact. '
        '`cfghelper.lua:1383 read_std_impact` do no vao `t.impact_id`, '
        '`impactenginer.lua:66 imp:set_impact_id`, roi `scenecore.lua:1761 impact.buffer_id = imp.impact_id` '
        '-> di thang ra goi GCDetailImpactListUpdate cho client. Do la ID BIEU TUONG BUFF phia client, '
        'khong phai ID dong impact. So no voi ten dong StandardImpact la sai pham tru.',
}

LUA_G = re.compile(rb'g_Impact\d*\s*=\s*(-?\d+)')
LUA_SEND = re.compile(rb'(?:LuaFn)?Send(?:Specific)?Impact(?:ToUnit)?\s*\(([^)]{0,200})\)')
LUA_DEFINE = re.compile(rb'([A-Z_][A-Z0-9_]*IMPACT[A-Z0-9_]*)\s*=\s*(\d+)')


# --------------------------------------------------------------- bang tham chieu

def by_id(t):
    return {int(r[0]): r for r in t['rows']}


def load():
    live = by_id(read_table(os.path.join(R, SI)))
    base = by_id(read_table(os.path.join(OLD, SI)))
    return live, base


def classify(v, H, S):
    if v not in H:
        return 'thieu'
    if v not in S:
        return 'chi_CY'
    return 'ok' if g(H[v][1]) == g(S[v][1]) else 'doi_nghia'


def table_origin(name):
    """'CY' | '0.85' | '?' - bang nay dang o truc nao."""
    p_live = os.path.join(R, 'configs', name)
    p_old = os.path.join(OLD, 'configs', name)
    p_cy = os.path.join(CYDUMP, name)
    if not os.path.exists(p_live):
        return '?'
    try:
        live = read_table(p_live)
    except Exception:
        return '?'
    n_live, c_live = len(live['rows']), len(live['types'])
    cy = old = None
    if os.path.exists(p_cy):
        try:
            cy = read_table(p_cy)
        except Exception:
            cy = None
    if os.path.exists(p_old):
        try:
            old = read_table(p_old)
        except Exception:
            old = None
    same_cy = cy is not None and len(cy['types']) == c_live and abs(len(cy['rows']) - n_live) <= 2
    same_old = old is not None and len(old['types']) == c_live and abs(len(old['rows']) - n_live) <= 2
    if same_cy and not same_old:
        return 'CY'
    if same_old and not same_cy:
        return '0.85'
    if same_cy and same_old:
        # ca hai giong nhau ve hinh dang -> so noi dung
        if old is not None and len(old['rows']) == n_live:
            same_rows = sum(1 for a, b in zip(old['rows'], live['rows']) if a == b)
            if same_rows >= n_live * 0.98:
                return '0.85'
        return 'CY'
    return '?'


# --------------------------------------------------------------- lop bang

def scan_tables(H, S):
    out = []
    cfg = os.path.join(R, 'configs')
    for fn in sorted(os.listdir(cfg)):
        if not fn.endswith('.txt'):
            continue
        p = os.path.join(cfg, fn)
        try:
            t = read_table(p)
        except Exception:
            continue
        if not t['names']:
            continue
        names = [g(x) for x in t['names']]
        cols = [i for i, n in enumerate(names)
                if i > 0 and COL_PAT.search(n) and not COL_DENY.search(n)]
        if not cols:
            continue
        origin = table_origin(fn)
        for c in cols:
            if (fn, c) in COL_EXCLUDE:
                out.append({'noi': 'bang %s cot %d "%s"' % (fn, c, names[c][:40]),
                            'file': fn, 'cot': c, 'ten_cot': names[c], 'nguon': origin,
                            'so_o': 0, 'trang_thai': {}, 'nghi_ngo': 0,
                            'bo_qua': COL_EXCLUDE[(fn, c)], 'mau': {}})
                continue
            st = collections.Counter()
            samples = collections.defaultdict(list)
            for r in t['rows']:
                if c >= len(r):
                    continue
                s = g(r[c]).strip()
                if not re.fullmatch(r'-?\d+', s):
                    continue
                v = int(s)
                if v <= 0:
                    continue
                k = classify(v, H, S)
                st[k] += 1
                if len(samples[k]) < 5:
                    samples[k].append((int(r[0]), v,
                                       g(S[v][1]) if v in S else '-',
                                       g(H[v][1]) if v in H else '-',
                                       (v + SHIFT) in H and g(H[v + SHIFT][1]) == (g(S[v][1]) if v in S else None)))
            if sum(st.values()) == 0:
                continue
            out.append({'noi': 'bang %s cot %d "%s"' % (fn, c, names[c][:40]),
                        'file': fn, 'cot': c, 'ten_cot': names[c], 'nguon': origin,
                        'so_o': sum(st.values()), 'trang_thai': dict(st),
                        'nghi_ngo': (st['doi_nghia'] + st['thieu']) if origin != 'CY' else 0,
                        'mau': {k: v for k, v in samples.items() if k in ('doi_nghia', 'thieu')}})
    return out


# --------------------------------------------------------------- lop Lua

def scan_lua(H, S):
    roots = [('Game_2/Script', 'script'), ('GameServer/lualib', 'lualib'),
             ('GameServer/services', 'services')]
    hits = collections.defaultdict(lambda: collections.defaultdict(list))   # kind -> value -> [file]
    for rel, kind in roots:
        top = os.path.join(R, rel)
        if not os.path.isdir(top):
            continue
        for dp, _dn, fns in os.walk(top):
            for fn in fns:
                if not fn.endswith('.lua'):
                    continue
                p = os.path.join(dp, fn)
                r = os.path.relpath(p, R).replace(os.sep, '/')
                with open(p, 'rb') as f:
                    raw = f.read()
                for m in LUA_G.finditer(raw):
                    v = int(m.group(1))
                    if v > 0:
                        hits['g_Impact:' + kind][v].append(r)
                for m in LUA_SEND.finditer(raw):
                    args = [a.strip() for a in m.group(1).split(b',')]
                    if len(args) >= 4 and re.fullmatch(rb'\d+', args[3]):
                        v = int(args[3])
                        if v > 0:
                            hits['SendImpact-hangso:' + kind][v].append(r)
                for m in LUA_DEFINE.finditer(raw):
                    v = int(m.group(2))
                    if v > 0:
                        hits['hang so *IMPACT*:' + kind][v].append(
                            r + ' (' + m.group(1).decode('ascii') + ')')
    out = []
    for kind, vals in sorted(hits.items()):
        st = collections.Counter()
        samples = collections.defaultdict(list)
        for v, files in vals.items():
            k = classify(v, H, S)
            st[k] += len(files)
            if len(samples[k]) < 5:
                samples[k].append((v, g(S[v][1]) if v in S else '-',
                                   g(H[v][1]) if v in H else '-',
                                   (v + SHIFT) in H and v in S and g(H[v + SHIFT][1]) == g(S[v][1]),
                                   files[0]))
        out.append({'noi': 'lua ' + kind, 'nguon': '0.85', 'so_o': sum(st.values()),
                    'so_gia_tri': len(vals), 'trang_thai': dict(st),
                    'nghi_ngo': st['doi_nghia'] + st['thieu'],
                    'mau': {k: v for k, v in samples.items() if k in ('doi_nghia', 'thieu')}})
    return out


def wire_u16_check(H):
    """BAT BIEN DAY 16 BIT: o duy nhat cua he impact di tren day 16 bit la `buffer_id`, lay tu
    cot 5 `瞬发效果ID/驻留效果ID` (`cfghelper:1383` -> `impactenginer:66` -> `scenecore:1761`).
    Ba cho ghi no deu la `stream:writeshort` (misc.lua 756 GCDetailImpactList, 3081 GCCharBuff,
    3117 GCDetailBuff), va `bostream:writeshort` **KEP** ve 32767 chu khong quan vong
    (`iostream.lua:183`), nen tran se lam moi ID thanh 32767 - sai to, khong am tham thanh ID khac.
    `Data_Index` cua dong impact KHONG BAO GIO duoc ghi vao o 16 bit.
    """
    t = read_table(os.path.join(R, SI))
    ids = [int(r[0]) for r in t['rows']]
    c5 = []
    for r in t['rows']:
        if len(r) > 5:
            s = g(r[5]).strip()
            if s.lstrip('-').isdigit():
                c5.append(int(s))
    over = [v for v in c5 if v > 32767]
    return ('DAY 16 BIT (buffer_id = cot 5): max cot 5 = %d, so o > 32767 = %d  %s\n'
            '   (Data_Index: %d dong, max = %d, so dong > 65535 = %d - KHONG di tren day 16 bit)'
            % (max(c5) if c5 else 0, len(over), 'OK' if not over else 'CANH BAO: se bi kep ve 32767',
               len(ids), max(ids), sum(1 for i in ids if i > 65535)))


def cmd_scan(args):
    H, S = load()
    rows = scan_tables(H, S) + scan_lua(H, S)
    rows.sort(key=lambda x: -x['nghi_ngo'])
    print('%-58s %-6s %7s %7s %s' % ('noi', 'nguon', 'so_o', 'nghi', 'trang thai'))
    for r in rows:
        print('%-58s %-6s %7d %7d %s' % (r['noi'][:58], r['nguon'], r['so_o'], r['nghi_ngo'],
                                         dict(sorted(r['trang_thai'].items()))))
    print()
    tong = sum(r['nghi_ngo'] for r in rows)
    print('TONG O NGHI NGO (nguon != CY, trang thai thieu/doi_nghia): %d' % tong)
    print()
    print(wire_u16_check(H))
    print()
    for r in rows:
        if not r['nghi_ngo']:
            continue
        print('--- %s (nguon %s) ---' % (r['noi'], r['nguon']))
        for k, lst in r['mau'].items():
            for s in lst:
                print('    %-10s %s' % (k, s))
    if args.json:
        with open(args.json, 'w', encoding='utf-8') as f:
            json.dump(rows, f, ensure_ascii=False, indent=1, default=str)
        print('\n-> %s' % args.json)
    if args.tsv:
        with open(args.tsv, 'w', encoding='utf-8', newline='') as f:
            f.write('noi\tnguon\tso_o\tnghi_ngo\tok\tchi_CY\tdoi_nghia\tthieu\n')
            for r in rows:
                t = r['trang_thai']
                f.write('%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n' % (
                    r['noi'], r['nguon'], r['so_o'], r['nghi_ngo'],
                    t.get('ok', 0), t.get('chi_CY', 0), t.get('doi_nghia', 0), t.get('thieu', 0)))
        print('-> %s' % args.tsv)
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('scan'); p.add_argument('--json'); p.add_argument('--tsv')
    p.set_defaults(fn=cmd_scan)
    a = ap.parse_args()
    sys.exit(a.fn(a))


if __name__ == '__main__':
    main()
