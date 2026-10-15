# -*- coding: utf-8 -*-
"""CYS-CRTGUARD: nua con lai cua lop loi - CHO GOI KHOA HANG.

`GMInterface_Script_Talk.cpp` (cua `SrvMsg`) dem dac ta LUC CHAY vi server moi biet ten khoa.
Nhung 57 cho goi con lai truyen KHOA HANG: so doi so da co ngay trong ma nguon, nen so dac ta
PHAI khop, va co the kiem TINH - khong can chay game, khong can khe.

    COLORMSGFUNC("KHOA", a, b)   -> 2 doi so;  o tu dien phai co dung 2 dac ta
    NOCOLORMSGFUNC("KHOA")       -> 0 doi so;  o tu dien phai co 0 dac ta

Dem THUA  => `_vsnprintf` doc doi so KHONG TON TAI  (`%s` -> con tro rac, `%n` -> 0xC0000409)
Dem THIEU => chi la doi so thua, vo hai, nhung van bao vi no la dau hieu ban dich sai.

Thoat 1 neu co bat ky cho goi nao DOC QUA (dem thua). Dung lam cong.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cys_crtguard_fmtscan import strip_comments, split_args, is_literal, walk_files  # noqa: E402
from cys_crtguard_keycheck import count_args  # ban dem Python doc lap  # noqa: E402

SRC = os.environ.get("CYS_SRC", r"C:\TLBB\085\CY-Source\Src")
DICT = os.environ.get(
    "CYS_DICT",
    r"C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ConfigFolder\StrDictionary.txt")

MACROS = ("COLORMSGFUNC", "NOCOLORMSGFUNC")
KEY_RE = re.compile(r'^\s*[(]*\s*(?:_T\s*\(\s*)?"([^"]*)"')


def n_args_at(src, open_paren):
    """dem so doi so cua loi goi, khong ke doi so dau (la khoa)."""
    depth = 0
    i = open_paren
    n = len(src)
    commas = 0
    while i < n:
        c = src[i]
        if c == '"':
            j = i + 1
            while j < n:
                if src[j] == chr(92):
                    j += 2
                    continue
                if src[j] == '"':
                    j += 1
                    break
                j += 1
            i = j
            continue
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
            if depth == 0:
                return commas
        elif c == ',' and depth == 1:
            commas += 1
        i += 1
    return None


def main():
    d = {}
    with open(DICT, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            if '\t' not in line:
                continue
            k, v = line.rstrip('\n').split('\t', 1)
            d[k] = v

    sites = 0
    literal_sites = 0
    over = []
    under = []
    nokey = []
    for p in walk_files(SRC):
        try:
            raw = open(p, 'rb').read().decode('utf-8', 'replace')
        except Exception:
            continue
        src = strip_comments(raw)
        rel = os.path.relpath(p, SRC).replace('\\', '/')
        for name in MACROS:
            pat = re.compile(r'(?<![A-Za-z0-9_])' + re.escape(name) + r'\s*[(]')
            for m in pat.finditer(src):
                op = src.rindex('(', m.start(), m.end())
                ls = src.rfind(chr(10), 0, m.start()) + 1
                if src[ls:m.start()].lstrip().startswith('#define'):
                    continue
                sites += 1
                a0, _ = split_args(src, op, 0)
                if a0 is None or not is_literal(a0):
                    continue            # khoa chay-thoi -> cong o GMInterface_Script_Talk lo
                km = KEY_RE.match(a0)
                if not km:
                    continue
                key = km.group(1)
                literal_sites += 1
                nargs = n_args_at(src, op)
                line = src[:m.start()].count(chr(10)) + 1
                if key not in d:
                    nokey.append((rel, line, name, key))
                    continue
                need, fatal = count_args(d[key])
                if need > nargs or fatal:
                    over.append((rel, line, name, key, need, nargs, fatal, d[key][:60]))
                elif need < nargs:
                    under.append((rel, line, name, key, need, nargs, d[key][:60]))

    print("cho goi %s: %d (khoa HANG: %d)" % ("/".join(MACROS), sites, literal_sites))
    print("khoa hang KHONG CO trong tu dien : %d" % len(nokey))
    for r in nokey[:20]:
        print("    %-52s:%-5d %-16s %s" % r)
    print()
    print("DOC QUA (dac ta > doi so) - LOI THAT : %d" % len(over))
    for r in over:
        print("    %-52s:%-5d %-16s %-28s can %d, co %d%s  [%s]"
              % (r[0], r[1], r[2], r[3], r[4], r[5], "  + %n GIET" if r[6] else "", r[7]))
    print()
    print("doi so THUA (dac ta < doi so) - vo hai, nhung dang ngo : %d" % len(under))
    for r in under[:20]:
        print("    %-52s:%-5d %-16s %-28s can %d, co %d  [%s]" % r)

    print()
    if over:
        print("KET QUA: DO - %d cho goi doc doi so khong ton tai" % len(over))
        return 1
    print("KET QUA: XANH - 0 cho goi khoa hang doc doi so khong ton tai")
    return 0


if __name__ == '__main__':
    sys.exit(main())
