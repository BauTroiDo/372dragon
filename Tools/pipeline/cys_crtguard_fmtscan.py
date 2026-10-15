# -*- coding: utf-8 -*-
"""CYS-CRTGUARD: dem MOI duong vao ho printf co chuoi dinh dang KHONG phai hang chuoi.

Hai dinh nghia doc lap (luat "dem hai lan"):
  A. token goi ham  -> doc doi so dinh dang theo VI TRI (biet sprintf khac snprintf khac vsnprintf)
  B. bieu thuc chinh quy tho -> dem SO LAN xuat hien ten ham, khong phan tich doi so

Neu A va B lech, IN RA CHO LECH, khong chon con so dep hon.
"""
import os
import re
import json
import sys

ROOT = os.environ.get("CYS_SRC", r"C:\TLBB\085\CY-Source\Src")

# (ten, chi so 0-based cua doi so CHUOI DINH DANG)
PRINTF_FAM = [
    ("_vsnprintf", 2), ("_vsnwprintf", 2), ("_snprintf", 2), ("_snwprintf", 2),
    ("_sntprintf", 2), ("vsnprintf", 2), ("snprintf", 2), ("tvsnprintf", 2),
    ("_vsnprintf_s", 3), ("_snprintf_s", 3), ("_vsnwprintf_s", 3),
    ("sprintf", 1), ("swprintf", 1), ("_stprintf", 1), ("wsprintf", 1),
    ("sprintf_s", 2), ("swprintf_s", 2),
    ("vsprintf", 1), ("vswprintf", 1),
    ("printf", 0), ("wprintf", 0), ("vprintf", 0),
    ("fprintf", 1), ("fwprintf", 1), ("vfprintf", 1),
    # bo boc rieng cua du an - deu ket thuc o _vsnprintf/_vsnprintf_s
    ("TDU_Log", 0), ("tThrowStringException", 0), ("TDThrow", 0),
    # AxTrace(unsigned char nWnd, unsigned char nType, const char* pszFmt, ...) -> fmt la doi so 2
    # (lan dau toi dat 1 va thu duoc 34 duong gia; sua sau khi doc AxTrace.h:61)
    ("AxTrace", 2), ("CysPerfLog", 0),
]
# khoa TU DIEN (khong phai chuoi dinh dang - chuoi dinh dang lay tu StrDictionary)
DICT_FAM = [
    ("COLORMSGFUNC", 0), ("NOCOLORMSGFUNC", 0),
    ("ParserString_VarParam", 0), ("ParserString_NoColor_VarParam", 0),
]

BS = chr(92)   # dau gach cheo nguoc, viet the nay de heredoc khong nuot


def strip_comments(src):
    """xoa // va /* */ nhung GIU nguyen do dai (de so dong khong lech)."""
    out = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == '/' and i + 1 < n and src[i + 1] == '/':
            j = src.find(chr(10), i)
            if j < 0:
                j = n
            out.append(' ' * (j - i))
            i = j
        elif c == '/' and i + 1 < n and src[i + 1] == '*':
            j = src.find('*/', i + 2)
            j = n if j < 0 else j + 2
            out.append(''.join(ch if ch == chr(10) else ' ' for ch in src[i:j]))
            i = j
        elif c == '"':
            j = i + 1
            while j < n:
                if src[j] == BS:
                    j += 2
                    continue
                if src[j] == '"':
                    j += 1
                    break
                j += 1
            out.append(src[i:j])
            i = j
        elif c == "'":
            j = i + 1
            while j < n:
                if src[j] == BS:
                    j += 2
                    continue
                if src[j] == "'":
                    j += 1
                    break
                j += 1
            out.append(src[i:j])
            i = j
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def split_args(src, open_paren, want):
    """tra ve doi so thu `want` (0-based) cua loi goi bat dau tai open_paren."""
    depth = 0
    i = open_paren
    n = len(src)
    start = open_paren + 1
    idx = 0
    while i < n:
        c = src[i]
        if c == '"':
            j = i + 1
            while j < n:
                if src[j] == BS:
                    j += 2
                    continue
                if src[j] == '"':
                    j += 1
                    break
                j += 1
            i = j
            continue
        if c == "'":
            j = i + 1
            while j < n:
                if src[j] == BS:
                    j += 2
                    continue
                if src[j] == "'":
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
                if idx == want:
                    return src[start:i], idx + 1
                return None, idx + 1
        elif c == ',' and depth == 1:
            if idx == want:
                return src[start:i], None
            idx += 1
            start = i + 1
        i += 1
    return None, None


LIT_RE = re.compile(r'^\s*[(]*\s*(_T\s*\(\s*|TEXT\s*\(\s*)?(L|u8|U|u)?"')
TERNARY_LIT_RE = re.compile(r'[?].*"[^"]*".*:.*"[^"]*"', re.S)


def is_literal(a):
    """hang chuoi = bat dau bang " (co the boc _T(), TEXT(), hoac dau ngoac tron),
    HOAC mot bieu thuc ba ngoi ma CA HAI nhanh deu la hang chuoi."""
    a = a.strip()
    if LIT_RE.match(a):
        return True
    if TERNARY_LIT_RE.search(a) and a.count('"') >= 4:
        return True
    return False


def walk_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in ("ThirdParty", "OGRE", "_sdk")]
        for fn in filenames:
            if fn.lower().endswith(('.cpp', '.c', '.h', '.hpp', '.inl', '.cxx')):
                yield os.path.join(dirpath, fn)


def scan():
    rows = []
    count_b = {}
    for p in walk_files(ROOT):
        try:
            raw = open(p, 'rb').read().decode('utf-8', 'replace')
        except Exception:
            continue
        src = strip_comments(raw)
        rel = os.path.relpath(p, ROOT).replace('\\', '/')
        for fam, table in (("printf", PRINTF_FAM), ("dict", DICT_FAM)):
            for name, fmt_idx in table:
                pat = re.compile(r'(?<![A-Za-z0-9_])' + re.escape(name) + r'\s*[(]')
                # --- dinh nghia B: dem tho
                nb = len(pat.findall(src))
                if nb:
                    count_b[name] = count_b.get(name, 0) + nb
                # --- dinh nghia A: phan tich doi so
                for m in pat.finditer(src):
                    op = src.rindex('(', m.start(), m.end())
                    ls = src.rfind(chr(10), 0, m.start()) + 1
                    le = src.find(chr(10), m.start())
                    line_txt = src[ls:le if le > 0 else len(src)]
                    if line_txt.lstrip().startswith('#define'):
                        continue
                    if re.search(r'(?:VOID|void|INT|int|BOOL|STRING|virtual)[^;(]*$',
                                 src[max(0, ls):m.start()]) and src[le if le > 0 else len(src) - 1:le + 2 if le > 0 else len(src)].strip().startswith(''):
                        pass
                    arg, _ = split_args(src, op, fmt_idx)
                    if arg is None:
                        continue
                    rows.append(dict(
                        file=rel,
                        line=src[:m.start()].count(chr(10)) + 1,
                        fam=fam, func=name,
                        literal=is_literal(arg),
                        arg=' '.join(arg.split())[:160],
                    ))
    return rows, count_b


if __name__ == '__main__':
    rows, count_b = scan()
    count_a = {}
    for r in rows:
        count_a[r['func']] = count_a.get(r['func'], 0) + 1
    out = dict(rows=rows, count_a=count_a, count_b=count_b)
    dest = sys.argv[1] if len(sys.argv) > 1 else None
    if dest:
        with open(dest, 'w', encoding='utf-8') as f:
            json.dump(out, f, ensure_ascii=False, indent=1)
    nonlit = [r for r in rows if not r['literal']]
    print("TONG diem goi (A) :", len(rows))
    print("KHONG phai hang chuoi:", len(nonlit))
    print()
    print("%-32s %6s %6s %s" % ("ham", "A", "B", "lech?"))
    for k in sorted(set(list(count_a) + list(count_b))):
        a = count_a.get(k, 0)
        b = count_b.get(k, 0)
        flag = "" if a == b else "  <== LECH, phai truy"
        print("%-32s %6d %6d %s" % (k, a, b, flag))
