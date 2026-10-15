# -*- coding: utf-8 -*-
"""CYS-MSGEMPTY: kiem ke MOI khoa tu dien tra CHUOI RONG o cua COLORMSGFUNC/NOCOLORMSGFUNC.

Khac `cys_crtguard_callcheck.py` o cho: callcheck chi DEM va in 20 dong dau.
Bo nay tra ve BANG DAY DU kem hai thu ma callcheck khong co:

  1. `sink`  - ket qua chuoi di ve DAU: chat (`ADDTALKMSG`, bo qua chuoi rong),
               thong bao noi (`GE_NEW_DEBUGMESSAGE` -> `DebugListBox`, KHONG bo qua),
               hay bi vut di (duong chet).
  2. `guards`- day dieu kien bao quanh cho goi. Mot cho goi nam sau mot phep canh
               KHONG BAO GIO DUNG thi them dong tu dien vao cung khong doi mot diem anh.

Phep dem DOC LAP voi callcheck (tu viet lai tach cau, tach doi so, tach chu thich) de hai
con so phai khop - luat "dem hai lan" cua muc 17.

    python cys_msgempty_scan.py --out msgempty.json [--dict <StrDictionary.txt>]
"""
import argparse
import hashlib
import json
import os
import re
import sys
import time

BS = chr(92)
NL = chr(10)

DEFAULT_SRC = r"C:\TLBB\085\CY-Source\Src"
DEFAULT_DICTS = [
    ("CanonicalCY", r"C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ConfigFolder\StrDictionary.txt"),
    ("Canonical", r"C:\TLBB\085\CY-Source\Assets\Canonical\Data\ConfigFolder\StrDictionary.txt"),
    ("gui-cy", r"C:\TLBB\085\CY-Source\Assets\CanonicalCY\_generated\gui-cy\ConfigFolder\StrDictionary.txt"),
]

MACROS = ("COLORMSGFUNC", "NOCOLORMSGFUNC")

# bang khoa co dinh: (ten bien, duong dan tuong doi trong Src, sink da doc tay)
TABLES = [
    ("pRelationString", r"Client\WXClient\Network\PacketHandler\GCRelationHandler.cpp"),
    ("pString", r"Client\WXClient\Network\PacketHandler\GCTeamErrorHandler.cpp"),
    ("pErrString", r"Client\WXClient\Network\PacketHandler\GCTeamFollowErrHandler.cpp"),
    ("g_szGemAttName", r"Client\WXClient\Object\Item\Obj_Item_Gem.cpp"),
]


# ---------------------------------------------------------------- tach chu thich
def strip_comments(src):
    """xoa // va /* */, GIU do dai (so dong khong lech)."""
    out = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == '/' and i + 1 < n and src[i + 1] == '/':
            j = src.find(NL, i)
            if j < 0:
                j = n
            out.append(' ' * (j - i))
            i = j
        elif c == '/' and i + 1 < n and src[i + 1] == '*':
            j = src.find('*/', i + 2)
            j = n if j < 0 else j + 2
            out.append(''.join(ch if ch == NL else ' ' for ch in src[i:j]))
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


def skip_string(src, i):
    q = src[i]
    j = i + 1
    n = len(src)
    while j < n:
        if src[j] == BS:
            j += 2
            continue
        if src[j] == q:
            return j + 1
        j += 1
    return n


def match_paren(src, op):
    """tra ve chi so cua ')' dong voi '(' tai op, hoac None."""
    depth = 0
    i = op
    n = len(src)
    while i < n:
        c = src[i]
        if c in '"\'':
            i = skip_string(src, i)
            continue
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return None


def split_top_args(src, op, cl):
    """tach doi so cap cao nhat giua '(' op va ')' cl."""
    args = []
    cur = []
    depth = 0
    i = op + 1
    while i < cl:
        c = src[i]
        if c in '"\'':
            j = skip_string(src, i)
            cur.append(src[i:j])
            i = j
            continue
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        if c == ',' and depth == 0:
            args.append(''.join(cur).strip())
            cur = []
            i += 1
            continue
        cur.append(c)
        i += 1
    last = ''.join(cur).strip()
    if last or args:
        args.append(last)
    return args


# ---------------------------------------------------------------- phep canh
BLOCK_KW = re.compile(r'(?<![A-Za-z0-9_])(if|else\s+if|else|while|for|switch|case\s[^:]*|default)\s*$')


def enclosing_guards(src, pos, maxdepth=8):
    """di nguoc tu `pos`, gom tieu de cua tung khoi `{` con dang mo."""
    guards = []
    depth = 0
    i = pos - 1
    while i >= 0 and len(guards) < maxdepth:
        c = src[i]
        if c == '}':
            depth += 1
        elif c == '{':
            if depth == 0:
                # tieu de khoi = van ban truoc '{' tren cung dong hoac dong truoc
                head_end = i
                j = i - 1
                while j >= 0 and src[j] in ' \t\r\n':
                    j -= 1
                # lui toi dau cau: tim ';' '{' '}' hoac dau tep
                k = j
                while k >= 0 and src[k] not in ';{}':
                    k -= 1
                head = src[k + 1:head_end].strip()
                head = re.sub(r'\s+', ' ', head)
                if head:
                    guards.append(head[:240])
            else:
                depth -= 1
        i -= 1
    return guards[::-1]


# ---------------------------------------------------------------- sink
# Moi bo boc DAN chuoi len man hinh. Lan dau toi bo sot `ADD_GUILD_MSG` va bon anh em cua no
# (GMInterface_Script_Talk.h:128-139) nen `Guild_New_Member` bi xep nham la "VUT DI".
# Dung dang bay muc 17: cong dem hoan hao tren mot DINH NGHIA THIEU.
CHAT_MACROS = ("ADDTALKMSG", "ADD_TEAM_MSG", "ADD_GUILD_MSG", "ADD_MENPAI_MSG", "ADD_SYSTEM_MSG")
NOTICE_MACROS = ("ADDNEWDEBUGMSG",)


def enclosing_block_range(src, pos):
    """tra ve (bat dau, ket thuc) cua khoi `{}` gan nhat bao quanh pos."""
    depth = 0
    i = pos - 1
    start = 0
    while i >= 0:
        c = src[i]
        if c == '}':
            depth += 1
        elif c == '{':
            if depth == 0:
                start = i
                break
            depth -= 1
        i -= 1
    end = match_paren_brace(src, start)
    return start, end


def match_paren_brace(src, ob):
    depth = 0
    i = ob
    n = len(src)
    while i < n:
        c = src[i]
        if c in '"\'':
            i = skip_string(src, i)
            continue
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return n


def classify_sink(src, stmt_start, call_start, func_end):
    """Doc phia SAU cho goi trong cung ham, lan theo bien, tra ve (nhan, bang chung)."""
    # dang 1: MSGFUNC nam THANG trong mot bo boc hien thi
    before = src[max(0, call_start - 220):call_start]
    m = re.search(r'([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*$', before)
    if m and (m.group(1) in CHAT_MACROS or m.group(1) in NOTICE_MACROS
              or m.group(1) in ('addTalkMsg', 'AddInfo')):
        return m.group(1), "loi goi long thang"

    # dang 2: <bien> = MSGFUNC(...)
    stmt = src[stmt_start:call_start]
    ma = re.search(r'([A-Za-z_][A-Za-z0-9_]*)\s*=\s*$', stmt)
    if not ma:
        return "VUT DI", "ket qua khong duoc gan, khong duoc long"
    var = ma.group(1)
    if var.startswith('m_'):
        # bien THANH VIEN: vong doi vuot qua ham, cong nay khong theo duoc -> doi doc tay,
        # KHONG duoc phep im lang xep vao "VUT DI" (do la mot ket luan, khong phai mot phep do).
        return "THANH VIEN - TRA TAY", "gan vao `%s`, vong doi ngoai ham" % var
    tail = src[call_start:func_end]
    ev = []
    # lan luot 1: bien goc
    names = [var]
    seen = set(names)
    for _ in range(3):
        newnames = []
        for nm in names:
            e = re.escape(nm)
            probes = [(r'(?<![A-Za-z0-9_])' + mc + r'\s*\(\s*' + e + r'\s*\)', mc)
                      for mc in CHAT_MACROS + NOTICE_MACROS]
            probes.append((r'(?<![A-Za-z0-9_])addTalkMsg\s*\(\s*' + e, 'addTalkMsg'))
            for pat, label in probes:
                if re.search(pat, tail):
                    ev.append(label)
            # sao chep sang bo dem: strncpy(dst, var.c_str()  /  _snprintf(dst,..., var.c_str())
            for mm in re.finditer(
                    r'(?:strncpy|strcpy|_snprintf|_sntprintf|sprintf)\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)[^;]*?'
                    + e + r'\s*(?:\.c_str\s*\(\s*\)|)\s*[,)]', tail):
                dst = mm.group(1)
                if dst not in seen:
                    seen.add(dst)
                    newnames.append(dst)
            # PushEvent(GE_..., var)
            for mm in re.finditer(r'PushEvent\s*\(\s*(GE_[A-Z_]+)\s*,[^;]*?' + e, tail):
                ev.append(mm.group(1))
        if not newnames:
            break
        names = newnames
    if not ev:
        return "VUT DI", "bien `%s` khong toi mot cua hien thi nao" % var
    # thu tu uu tien: chat > thong bao noi
    order = list(CHAT_MACROS) + ["addTalkMsg", "GE_CHAT_MESSAGE",
                                 "ADDNEWDEBUGMSG", "GE_NEW_DEBUGMESSAGE"]
    uniq = []
    for o in order:
        if o in ev and o not in uniq:
            uniq.append(o)
    for o in ev:
        if o not in uniq:
            uniq.append(o)
    return "+".join(uniq), "bien `%s`" % var


# ---------------------------------------------------------------- tu dien
def load_dict(path):
    d = {}
    dup = 0
    if not os.path.isfile(path):
        return None, 0
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            if '\t' not in line:
                continue
            k, v = line.rstrip(NL).rstrip('\r').split('\t', 1)
            if k in d:
                dup += 1
            d[k] = v
    return d, dup


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def walk_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in ("ThirdParty", "OGRE", "_sdk")]
        for fn in filenames:
            if fn.lower().endswith(('.cpp', '.c', '.h', '.hpp', '.inl', '.cxx')):
                yield os.path.join(dirpath, fn)


def table_keys(src_root, var, rel):
    p = os.path.join(src_root, rel)
    txt = open(p, 'rb').read().decode('utf-8', 'replace')
    m = re.search(re.escape(var) + r'\s*\[\s*\]\s*=\s*(?:\s*)\{(.*?)\};', txt, re.S)
    if not m:
        return [], None
    body = m.group(1)
    body = re.sub(r'//[^\n]*', '', body)
    line0 = txt[:m.start()].count(NL) + 1
    keys = re.findall(r'"([^"]*)"', body)
    return keys, line0


# ---------------------------------------------------------------- chinh
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', default=os.environ.get('CYS_SRC', DEFAULT_SRC))
    ap.add_argument('--out', required=True)
    args = ap.parse_args()

    dicts = {}
    dictmeta = {}
    for name, p in DEFAULT_DICTS:
        d, dup = load_dict(p)
        if d is None:
            dictmeta[name] = {"path": p, "exists": False}
            continue
        dicts[name] = d
        dictmeta[name] = {
            "path": p, "exists": True, "keys": len(d), "dup_keys": dup,
            "sha256": sha256(p), "mtime": time.strftime(
                "%Y-%m-%d %H:%M:%S", time.localtime(os.path.getmtime(p))),
        }
    primary = dicts.get("CanonicalCY", {})

    sites = []
    n_sites = 0
    n_literal = 0
    for p in walk_files(args.src):
        raw = open(p, 'rb').read().decode('utf-8', 'replace')
        src = strip_comments(raw)
        rel = os.path.relpath(p, args.src).replace(BS, '/')
        for name in MACROS:
            pat = re.compile(r'(?<![A-Za-z0-9_])' + re.escape(name) + r'\s*\(')
            for m in pat.finditer(src):
                op = src.rindex('(', m.start(), m.end())
                ls = src.rfind(NL, 0, m.start()) + 1
                if src[ls:m.start()].lstrip().startswith('#define'):
                    continue
                n_sites += 1
                cl = match_paren(src, op)
                if cl is None:
                    continue
                argv = split_top_args(src, op, cl)
                a0 = argv[0] if argv else ''
                km = re.match(r'^\s*\(*\s*(?:_T\s*\(\s*)?"([^"]*)"\s*\)*\s*$', a0)
                line = src[:m.start()].count(NL) + 1
                nargs = len(argv) - 1 if argv else 0
                if not km:
                    sites.append({
                        "file": rel, "line": line, "macro": name,
                        "key": None, "key_expr": a0[:120], "literal": False,
                        "nargs": nargs,
                    })
                    continue
                n_literal += 1
                key = km.group(1)
                # pham vi ham: tu '{' mo cua ham toi '}' dong
                fs, fe = enclosing_block_range(src, m.start())
                # tim dau cau
                k = m.start()
                while k >= 0 and src[k] not in ';{}':
                    k -= 1
                stmt_start = k + 1
                sink, why = classify_sink(src, stmt_start, m.start(), fe)
                guards = enclosing_guards(src, m.start())
                sites.append({
                    "file": rel, "line": line, "macro": name, "key": key,
                    "literal": True, "nargs": nargs,
                    "in_dict": {n: (key in d) for n, d in dicts.items()},
                    "sink": sink, "sink_why": why,
                    "guards": guards,
                    "stmt": re.sub(r'\s+', ' ', src[stmt_start:min(fe, m.start() + 200)].strip())[:200],
                })

    tables = []
    for var, rel in TABLES:
        keys, line0 = table_keys(args.src, var, rel)
        tables.append({
            "var": var, "file": rel.replace(BS, '/'), "line": line0,
            "entries": len(keys),
            "keys": [{"index": i, "key": k,
                      "in_dict": {n: (k in d) for n, d in dicts.items()} if k else None}
                     for i, k in enumerate(keys)],
        })

    missing_sites = [s for s in sites
                     if s.get("literal") and not s["in_dict"].get("CanonicalCY", False)]
    missing_keys = sorted({s["key"] for s in missing_sites})
    tbl_missing = []
    for t in tables:
        for e in t["keys"]:
            if e["key"] and not e["in_dict"].get("CanonicalCY", False):
                tbl_missing.append({"table": t["var"], "index": e["index"], "key": e["key"]})

    out = {
        "generated": time.strftime("%Y-%m-%d %H:%M:%S"),
        "src": args.src,
        "dicts": dictmeta,
        "counts": {
            "call_sites_total": n_sites,
            "call_sites_literal_key": n_literal,
            "call_sites_runtime_key": n_sites - n_literal,
            "call_sites_key_missing": len(missing_sites),
            "distinct_keys_missing": len(missing_keys),
            "table_keys_missing": len(tbl_missing),
            "GRAND_TOTAL_missing_keys": len(missing_keys) + len(tbl_missing),
        },
        "missing_keys_distinct": missing_keys,
        "sites": sites,
        "tables": tables,
        "table_missing": tbl_missing,
    }
    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)

    c = out["counts"]
    print("cho goi %s          : %d  (khoa HANG %d / khoa CHAY-THOI %d)"
          % ("/".join(MACROS), c["call_sites_total"],
             c["call_sites_literal_key"], c["call_sites_runtime_key"]))
    print("cho goi khoa hang THIEU trong tu dien : %d  (%d khoa rieng biet)"
          % (c["call_sites_key_missing"], c["distinct_keys_missing"]))
    print("khoa BANG THIEU                       : %d" % c["table_keys_missing"])
    print("TONG KHOA RONG                        : %d" % c["GRAND_TOTAL_missing_keys"])
    print()
    bysink = {}
    for s in missing_sites:
        bysink[s["sink"]] = bysink.get(s["sink"], 0) + 1
    for k in sorted(bysink, key=lambda x: -bysink[x]):
        print("   sink %-34s %d cho goi" % (k, bysink[k]))
    print()
    print("-> %s" % args.out)
    return 0


if __name__ == '__main__':
    sys.exit(main())
