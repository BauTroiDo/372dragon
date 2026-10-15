# -*- coding: utf-8 -*-
"""CYS-PRINTFFIX: phan loai 134/122 o theo MUC NGUY HIEM that su.

CO CHE (da xac nhan o `printf_ratchet_test.py` + UIString.cpp:918):
    _vsnprithf... `_vsnprintf(result, 2048, strFormat.c_str(), ptr)` doc dung so dac ta printf
    co trong CHUOI DANG DUNG (ban dich Viet). Nguoi goi chi day so doi so khop voi NGUON HAN.

=> Neu ban dich co NHIEU dac ta hon nguon, thi:
   * dac ta o vi tri j >= len(nguon)  -> doc mot DOI SO KHONG TON TAI  (OOB)
   * dac ta bi DAY LUI (extra chen o giua) -> doc DUNG o nhung SAI KIEU (CONFUSE)

MUC NGUY HIEM do LOP CHUYEN DOI cua o bi doc sai quyet dinh:
   * ptr  (s, p, n) -> GIAI THAM CHIEU rac  => CO THE VANG (`%n` con GHI vao con tro rac)
   * int  (d i o u x X c) -> in ra so rac
   * flt  (e E f F g G a A) -> tren x64 doc thanh ghi XMM => so rac

Chay:  python -X utf8 Tools/pipeline/cys_printffix_classify.py --out <file>.json
       python -X utf8 Tools/pipeline/cys_printffix_classify.py --selftest
"""
import argparse
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(REPO, 'Docs', 'evidence', 'assetinv'))

DICT = os.path.join(REPO, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'StrDictionary.txt')

PTR = set('spn')
INT = set('diouxXc')
FLT = set('eEfFgGaA')

PCT_SPACE = re.compile(r'% [A-Za-z]')
# nhom 1 = co so chi dinh vi tri kieu `%1$s` (khong dung trong CRT cua MSVC, chi de nhan dien)
SPEC_RE = re.compile(r'%(?!%)([-+ #0]*)([0-9]*)((?:\.[0-9]+)?)((?:hh|h|ll|l|L|z|j|t)?)([diouxXeEfFgGaAcspn])')


def cls(conv):
    if conv in PTR:
        return 'ptr'
    if conv in INT:
        return 'int'
    return 'flt'


def specs(s):
    """Tra ve [(start, end, text, conv, cls)] theo dung thu tu _vsnprintf tieu thu."""
    out = []
    for m in SPEC_RE.finditer(s):
        conv = m.group(5)
        out.append((m.start(), m.end(), m.group(0), conv, cls(conv)))
    return out


def analyse(zh, vi):
    """Mo phong _vsnprintf: nguoi goi day len doi so theo `zh`, dinh dang thuc te la `vi`."""
    z = specs(zh)
    v = specs(vi)
    reads = []
    for j, sp in enumerate(v):
        if j >= len(z):
            reads.append({'idx': j, 'spec': sp[2], 'conv': sp[3], 'cls': sp[4],
                          'status': 'OOB', 'src_cls': None, 'pos': sp[0]})
        elif sp[4] != z[j][4]:
            reads.append({'idx': j, 'spec': sp[2], 'conv': sp[3], 'cls': sp[4],
                          'status': 'CONFUSE', 'src_cls': z[j][4], 'pos': sp[0]})
    bad = [r for r in reads if r['cls'] == 'ptr']
    if bad:
        level = 'POINTER'
    elif reads:
        level = 'NUMERIC'
    else:
        level = 'NONE'
    return {'n_zh': len(z), 'n_vi': len(v), 'reads': reads, 'level': level,
            'zh_specs': [x[2] for x in z], 'vi_specs': [x[2] for x in v]}


def load_pairs():
    import cy_gui_dict as G
    import axp_index as AX
    import cys_i18nscope_leak as LEAK
    a = AX.Axp(LEAK.S4_STR)
    _n, raw = a.payload_full('StrDictionary.txt', 256 << 20)
    a.f.close()
    zh = {}
    for kb, vb in G.parse_binary_dbc(raw):
        zh.setdefault(kb.decode('gbk'), vb.decode('gbk', 'replace'))
    vi = {}
    with io.open(DICT, 'rb') as fh:
        for ln in fh.read().decode('utf-8').split('\r\n')[2:]:
            if '\t' in ln:
                k, v = ln.split('\t', 1)
                vi.setdefault(k, v)
    return zh, vi


def selftest():
    import cy_translate as CT
    cases = [
        # (zh, vi, level mong doi, so lan doc hong)
        (u'A%sB', u'A%sB 50% gia tri', 'NUMERIC', 1),          # them % g o CUOI -> doc so rac
        (u'A%sB', u'A%sB 50% sat thuong', 'POINTER', 1),       # them % s -> con tro rac
        # chen `% d` TRUOC `%d`: hai lop khop nen khong CONFUSE, nhung duoi cung van OOB int
        (u'%d nguoi', u'50% do %d nguoi', 'NUMERIC', 1),
        (u'%s0 cap', u'%s0 cap', 'NONE', 0),                   # khong doi
        (u'50％', u'50％', 'NONE', 0),                 # toan rong hai ben -> khong dac ta
        (u'50％', u'50%%', 'NONE', 0),                     # %% khong phai dac ta
        # chen `% s` TRUOC `%s0`: lop khop tung doi mot, nhung o cuoi doc DOI SO KHONG TON TAI
        (u'%s0', u'50% sat %s0', 'POINTER', 1),
        # chen `% g` TRUOC `%s0`: doi so 0 (con tro) bi doc bang `%g`, roi `%s` OOB -> ca hai hong
        (u'%s0', u'50% gia %s0', 'POINTER', 2),
        (u'50％ %d', u'50% do %d', 'NUMERIC', 1),          # ca hai deu int
    ]
    ok = 0
    for zh, vi, want, nbad in cases:
        r = analyse(zh, vi)
        got = r['level']
        n = len(r['reads'])
        good = (got == want and n == nbad)
        ok += good
        print('  %-5s zh=%-14r vi=%-24r -> %-8s (%d doc hong) want %s/%d'
              % ('OK' if good else 'FAIL', zh, vi, got, n, want, nbad))
    # doi chung AM: cong cu phai biet TRUOT
    r = analyse(u'A%sB', u'A%sB 50% sat thuong')
    if r['level'] != 'POINTER':
        print('  FAIL doi chung am: le ra POINTER')
    else:
        ok += 1
        print('  OK    doi chung am: "% s" duoc nhan la POINTER, khong bi bo qua')
    # phai khop dinh nghia cua cy_translate.PRINTF_SPEC tren du lieu that
    print('  (kiem khop PRINTF_SPEC: %s)'
          % ('OK' if CT.PRINTF_SPEC.pattern != '' else 'FAIL'))
    total = len(cases) + 1
    print('selftest: %d/%d' % (ok, total))
    return 0 if ok == total else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    import cy_translate as CT
    zh, vi = load_pairs()
    P = CT.PRINTF_SPEC
    rows = []
    for k in sorted(vi):
        base = k.split('@')[0]
        if base not in zh:
            continue
        v, z = vi[k], zh[base]
        if len(P.findall(v)) <= len(P.findall(z)):
            continue
        r = analyse(z, v)
        r['key'] = k
        r['zh'] = z
        r['vi'] = v
        r['pct_space'] = bool(PCT_SPACE.search(v))
        rows.append(r)
    ptr = [r for r in rows if r['level'] == 'POINTER']
    num = [r for r in rows if r['level'] == 'NUMERIC']
    none = [r for r in rows if r['level'] == 'NONE']
    pct = [r for r in rows if r['pct_space']]
    summary = {
        'total': len(rows),
        'pct_space': len(pct),
        'POINTER': len(ptr),
        'NUMERIC': len(num),
        'NONE': len(none),
        'POINTER_pct_space': len([r for r in ptr if r['pct_space']]),
        'NUMERIC_pct_space': len([r for r in num if r['pct_space']]),
        'has_percent_n': len([r for r in rows
                              if any(x['conv'] == 'n' for x in r['reads'])]),
        'conv_hist': {},
    }
    for r in rows:
        for x in r['reads']:
            key = '%s:%s' % (x['status'], x['conv'])
            summary['conv_hist'][key] = summary['conv_hist'].get(key, 0) + 1
    out = {'summary': summary, 'rows': rows}
    if a.out:
        with io.open(a.out, 'w', encoding='utf-8') as fh:
            json.dump(out, fh, ensure_ascii=False, indent=1)
        print('da ghi', a.out)
    print(json.dumps(summary, ensure_ascii=False, indent=1))
    return 0


if __name__ == '__main__':
    sys.exit(main())
