# -*- coding: utf-8 -*-
"""CYS-CRTGUARD buoc 2: cac HAM BAO variadic cua chinh du an.

`cys_crtguard_fmtscan.py` dem cac loi goi TRUC TIEP vao ho printf. Nhung mot chuoi dinh dang
cung co the di vong: qua mot ham bao `void QuestLog(const char* fmt, ...)` roi moi toi
`_vsnprintf`. Neu nguoi goi ham bao do truyen mot chuoi KHONG PHAI HANG, cua van mo.

Buoc nay:
  1. tim moi ham trong Src/ (khong ke ThirdParty/OGRE) co `...` trong danh sach tham so
     VA co than ham goi mot ham printf voi chinh tham so fmt cua no;
  2. dem moi loi goi toi cac ham do va phan loai hang chuoi / khong hang chuoi.
"""
import os
import re
import json
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cys_crtguard_fmtscan import strip_comments, split_args, is_literal, walk_files, ROOT

PRINTF_IN_BODY = re.compile(
    r'(?<![A-Za-z0-9_])(_?v?s?n?w?printf(_s)?|tvsnprintf|_vsctprintf|_vstprintf|_sctprintf|_stprintf)\s*\(')
# ten ham + danh sach tham so ket thuc bang ...
DEF_RE = re.compile(
    r'(?<![A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(([^;{()]*\.\.\.)\s*\)\s*(?:const\s*)?(?:throw\s*\(\s*\)\s*)?\{')

# Cac ten da xu ly o buoc 1 (goi thang vao CRT) - khong dem lai.
ALREADY = {"TDU_Log", "tThrowStringException", "TDThrow", "AxTrace"}


def find_wrappers():
    wrappers = {}
    for p in walk_files(ROOT):
        try:
            raw = open(p, 'rb').read().decode('utf-8', 'replace')
        except Exception:
            continue
        src = strip_comments(raw)
        rel = os.path.relpath(p, ROOT).replace('\\', '/')
        for m in DEF_RE.finditer(src):
            name = m.group(1)
            if name in ALREADY:
                continue
            if name in ('if', 'for', 'while', 'switch', 'catch', 'return'):
                continue
            # than ham: tu dau { toi } can bang
            i = src.index('{', m.end() - 1)
            depth = 0
            j = i
            n = len(src)
            while j < n:
                if src[j] == '{':
                    depth += 1
                elif src[j] == '}':
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            body = src[i:j]
            if PRINTF_IN_BODY.search(body):
                wrappers.setdefault(name, []).append(
                    (rel, src[:m.start()].count(chr(10)) + 1))
    return wrappers


def scan_calls(names):
    rows = []
    for p in walk_files(ROOT):
        try:
            raw = open(p, 'rb').read().decode('utf-8', 'replace')
        except Exception:
            continue
        src = strip_comments(raw)
        rel = os.path.relpath(p, ROOT).replace('\\', '/')
        for name in names:
            pat = re.compile(r'(?<![A-Za-z0-9_.>:])' + re.escape(name) + r'\s*[(]')
            for m in pat.finditer(src):
                op = src.rindex('(', m.start(), m.end())
                ls = src.rfind(chr(10), 0, m.start()) + 1
                if src[ls:m.start()].lstrip().startswith('#define'):
                    continue
                # doi so dinh dang: doi so dau tien co kieu chuoi. Cac ham bao o day deu co
                # dang (fmt, ...) hoac (co, fmt, ...) -> thu ca hai vi tri, lay cai la hang chuoi.
                a0, _ = split_args(src, op, 0)
                a1, _ = split_args(src, op, 1)
                a2, _ = split_args(src, op, 2)
                cands = [a for a in (a0, a1, a2) if a is not None]
                if not cands:
                    continue
                lit = any(is_literal(a) for a in cands)
                rows.append(dict(file=rel, line=src[:m.start()].count(chr(10)) + 1,
                                 func=name, literal=lit,
                                 arg=' '.join((a0 or '')[:80].split())))
    return rows


if __name__ == '__main__':
    wrappers = find_wrappers()
    print("HAM BAO variadic co goi printf voi fmt cua chinh no: %d" % len(wrappers))
    for k in sorted(wrappers):
        for (f, l) in wrappers[k]:
            print("   %-22s %s:%d" % (k, f, l))
    rows = scan_calls(sorted(wrappers))
    nonlit = [r for r in rows if not r['literal']]
    print()
    print("Tong loi goi toi cac ham bao do : %d" % len(rows))
    print("Trong do KHONG hang chuoi       : %d" % len(nonlit))
    for r in sorted(nonlit, key=lambda r: (r['func'], r['file'], r['line'])):
        print("   %-18s %-52s:%-5d %s" % (r['func'], r['file'], r['line'], r['arg'][:60]))
    dest = sys.argv[1] if len(sys.argv) > 1 else None
    if dest:
        with open(dest, 'w', encoding='utf-8') as f:
            json.dump(dict(wrappers={k: v for k, v in wrappers.items()}, rows=rows), f,
                      ensure_ascii=False, indent=1)
