# -*- coding: utf-8 -*-
"""CYS-PRINTFFIX: khoa nao THAT SU toi duoc `_vsnprintf`?

`_vsnprintf` chi xuat hien DUNG MOT cho: `UIString.cpp:918`, trong `ParserString_VarParam`.
Moi duong khac (`#{KEY}` trong Lua -> `ParserString_Runtime*`, `NOPARAMMSGFUNC` ->
`ParserString_NoVarParam`) KHONG he goi printf.

=> Mot khoa chi co the gay UB neu no duoc truyen vao MOT trong cac cho goi VarParam (C++).
Tool nay liet ke MOI khoa chuoi truyen vao cac ham do, roi giao voi danh sach 134/122.

Chay: python -X utf8 Tools/pipeline/cys_printffix_reach.py --keys <file>.json --out <file>.json
      python -X utf8 Tools/pipeline/cys_printffix_reach.py --selftest
"""
import argparse
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
SRC = os.path.join(REPO, 'Src')
DATA = os.path.join(REPO, 'Assets', 'CanonicalCY', 'Data')

# ten ham thuc su di toi _vsnprintf
VARPARAM = ('COLORMSGFUNC', 'NOCOLORMSGFUNC', 'ParserString_VarParam',
            'ParserString_NoColor_VarParam')
CALL_RE = re.compile(r'\b(%s)\s*\(\s*(.*)$' % '|'.join(VARPARAM))
LIT_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')
# khoa dung hang so bien: COLORMSGFUNC(szKey) / (strKey.c_str())
DYN_RE = re.compile(r'^\s*[A-Za-z_]')
MARK_RE = re.compile(r'#\{([A-Za-z0-9_]+)')


def iter_files(root, exts):
    for dp, _dn, fn in os.walk(root):
        for f in fn:
            if os.path.splitext(f)[1].lower() in exts:
                yield os.path.join(dp, f)


def scan_varparam():
    """{key: [(file, line)]} + danh sach cho goi khoa DONG (khong doc duoc tinh)."""
    hits, dynamic = {}, []
    for p in iter_files(SRC, {'.cpp', '.h', '.hpp', '.inl'}):
        try:
            txt = io.open(p, 'rb').read().decode('utf-8', 'replace')
        except Exception:
            continue
        if not any(t in txt for t in VARPARAM):
            continue
        for i, ln in enumerate(txt.split('\n'), 1):
            m = CALL_RE.search(ln)
            if not m:
                continue
            rest = m.group(2)
            lit = LIT_RE.match(rest.lstrip())
            if lit:
                hits.setdefault(lit.group(1), []).append((os.path.relpath(p, REPO), i))
            elif DYN_RE.match(rest):
                dynamic.append((os.path.relpath(p, REPO), i, ln.strip()[:120]))
    return hits, dynamic


def scan_marks():
    """{key: [(file, line)]} cho moi `#{KEY}` trong cay du lieu + Lua (duong KHONG printf)."""
    hits = {}
    for p in iter_files(DATA, {'.lua', '.txt', '.xml', '.layout', '.ini'}):
        try:
            txt = io.open(p, 'rb').read().decode('utf-8', 'replace')
        except Exception:
            continue
        if '#{' not in txt:
            continue
        for i, ln in enumerate(txt.split('\n'), 1):
            for m in MARK_RE.finditer(ln):
                hits.setdefault(m.group(1), []).append((os.path.relpath(p, REPO), i))
    return hits


def selftest():
    ok = 0
    t = 'STRING s = COLORMSGFUNC("WIN_EXP", n);'
    m = CALL_RE.search(t)
    a = bool(m) and LIT_RE.match(m.group(2).lstrip()).group(1) == 'WIN_EXP'
    print('  %-4s bat duoc khoa hang so' % ('OK' if a else 'FAIL'))
    ok += a
    t2 = 'strTemp = NOCOLORMSGFUNC(szKey);'
    m2 = CALL_RE.search(t2)
    b = bool(m2) and not LIT_RE.match(m2.group(2).lstrip()) and bool(DYN_RE.match(m2.group(2)))
    print('  %-4s nhan ra khoa DONG (khong im lang bo qua)' % ('OK' if b else 'FAIL'))
    ok += b
    # doi chung AM: dong da bi chu thich van BI DEM -> phai biet truot
    t3 = 'STRING x = "abc";//NOCOLORMSGFUNC("stall_sold_failure");'
    m3 = CALL_RE.search(t3)
    c = bool(m3)
    print('  %-4s doi chung am: dong CHU THICH van bi bat (=> ket qua la CAN TREN)'
          % ('OK' if c else 'FAIL'))
    ok += c
    d = MARK_RE.search('SetToolTip("#{ZZZB_150811_145}")').group(1) == 'ZZZB_150811_145'
    print('  %-4s bat duoc "#{KEY}"' % ('OK' if d else 'FAIL'))
    ok += d
    e = not CALL_RE.search('NOPARAMMSGFUNC("X")')
    print('  %-4s KHONG nham NOPARAMMSGFUNC (duong khong printf)' % ('OK' if e else 'FAIL'))
    ok += e
    print('selftest: %d/5' % ok)
    return 0 if ok == 5 else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--keys', help='JSON: mang khoa, hoac {"rows":[{"key":...}]}')
    ap.add_argument('--out')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    keys = []
    if a.keys:
        with io.open(a.keys, encoding='utf-8') as fh:
            j = json.load(fh)
        keys = j if isinstance(j, list) else [r['key'] for r in j['rows']]
    vp, dyn = scan_varparam()
    mk = scan_marks()
    res = {}
    for k in keys:
        base = k.split('@')[0]
        res[k] = {'varparam': vp.get(base, []), 'mark': mk.get(base, [])[:3],
                  'n_mark': len(mk.get(base, []))}
    reach = [k for k in keys if res[k]['varparam']]
    marked = [k for k in keys if not res[k]['varparam'] and res[k]['n_mark']]
    orphan = [k for k in keys if not res[k]['varparam'] and not res[k]['n_mark']]
    out = {
        'summary': {
            'keys_checked': len(keys),
            'varparam_literal_keys_in_src': len(vp),
            'varparam_dynamic_callsites': len(dyn),
            'REACH_vsnprintf': len(reach),
            'only_mark_no_printf': len(marked),
            'no_reference_found': len(orphan),
        },
        'reach': {k: res[k]['varparam'] for k in reach},
        'dynamic_callsites': dyn,
        'detail': res,
    }
    if a.out:
        with io.open(a.out, 'w', encoding='utf-8') as fh:
            json.dump(out, fh, ensure_ascii=False, indent=1)
        print('da ghi', a.out)
    print(json.dumps(out['summary'], ensure_ascii=False, indent=1))
    for k in reach[:20]:
        print('  REACH', k, res[k]['varparam'][:2])
    return 0


if __name__ == '__main__':
    sys.exit(main())
