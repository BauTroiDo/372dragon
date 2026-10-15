#!/usr/bin/env python3
# CYS-SEFIT: do QUY MO cua lop loi "null object tra ve cho mot gia tri DU LIEU".
#
# LuaApiGen tra loi cac ham host con thieu theo mot dac ta `rets`. Khi dac ta la "o",
# stub tra ve NULL OBJECT dung chung: mot bang ma __index tra ve mot HAM cho MOI truong.
# Dung cho ham chi de goi day chuyen (a:b():c()); SAI cho moi ham co ket qua dung nhu
# DU LIEU, vi:
#     x ~= nil        -> DUNG   (null object la bang)  => moi guard nil bi vo hieu
#     x.field >= 1    -> NEM    "attempt to compare number with function"
#     x <= 129        -> NEM    "attempt to compare table with number"
#     if x.field then -> LUON DUNG (ham la truthy)     => loi LOGIC IM LANG
# Mot lan nem giet CA HAM Lua dang chay => moi :SetText() sau do khong chay => o giao
# dien giu nguyen chu mau cua layout.
#
# ---------------------------------------------------------------------------------------
# BAN 2 (19/09, sau khi ban 1 BO SOT chinh loi thu hai cua nhanh nay). Ban 1 chi tim
#     local v = Recv:Name()   roi   v.<truong>
# nen mu hai duong, va ca hai deu da can loi that:
#   (1) Ham cua `_G` duoc goi TRAN, khong co receiver:  LEVEL_MAX_ENABLE = Lua_GetMyMaxLevelLimit()
#       -> regex cu doi `recv:name(` nen khong thay.
#   (2) Gia tri KHONG bi doc truong ma bi DUNG NHU SO (so sanh / so hoc).
#       -> ban 1 chi dem truy cap truong.
#   (3) Gan vao ten KHONG-local (global/upvalue) o mot ham, roi so sanh o HAM KHAC,
#       cach nhau hang nghin dong (that: gan o dong 3039, nem o dong 1480).
#       -> cua so 30 dong cua ban 1 khong voi toi.
# Ban 2 xu ly ca ba. Day la dang 2 cua muc 17: phep do chay hoan hao tren mot dinh
# nghia THIEU - khong co trieu chung nao de ma ngo.
#
# Ket qua LUON ghi ra JSON (--out). Con so la CAN TREN: moi diem van phai doc bang mat.

import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cys_uifix2_hosts  # CYS-UIFIX2: phep nhan host (bo nay truoc day khong co)
from collections import defaultdict

# int LAG_..(LuaPlus::LuaState* s) { return Stub(s, "Recv", "Name", "o"); }
STUB_RE = re.compile(
    r'Stub\s*\(\s*\w+\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]*)"\s*\)'
)

KNOWN_RETS = set("nsbzt1N")


def load_nullobj_stubs(src_dir):
    """(receiver, name) cho moi stub tra ve NULL OBJECT."""
    nullobj = set()
    all_stubs = {}
    for fn in sorted(os.listdir(src_dir)):
        if not fn.endswith(".cpp"):
            continue
        with open(os.path.join(src_dir, fn), "rb") as fh:
            text = fh.read().decode("utf-8", errors="replace")
        for recv, name, rets in STUB_RE.findall(text):
            all_stubs[(recv, name)] = rets
            if rets and any(ch not in KNOWN_RETS for ch in rets):
                nullobj.add((recv, name))
    return nullobj, all_stubs


def strip_comment(line):
    """Bo phan chu thich `--` de khong nham dau tru."""
    i = line.find("--")
    return line if i < 0 else line[:i]


def numeric_use_patterns(var):
    v = re.escape(var)
    return [
        # so sanh hai chieu
        (re.compile(r"\b%s\s*(<=|>=|<|>)" % v), "so-sanh"),
        (re.compile(r"(<=|>=|<|>)\s*%s\b" % v), "so-sanh"),
        # so hoc (tru '-' da duoc loai chu thich o tren)
        (re.compile(r"\b%s\s*[\+\*/%%^]" % v), "so-hoc"),
        (re.compile(r"[\+\*/%%^]\s*%s\b" % v), "so-hoc"),
        (re.compile(r"\b%s\s*-\s*\w" % v), "so-hoc"),
        # ep kieu / thu vien so
        (re.compile(r"\btonumber\s*\(\s*%s\b" % v), "tonumber"),
        (re.compile(r"\bmath\.\w+\s*\(\s*%s\b" % v), "math"),
        # noi chuoi: null object khong noi duoc
        (re.compile(r"\b%s\s*\.\." % v), "noi-chuoi"),
        (re.compile(r"\.\.\s*%s\b" % v), "noi-chuoi"),
    ]


def scan_lua(interface_root, nullobj):
    # ham cua _G duoc goi TRAN; ham cua receiver goi bang `recv:name(`
    global_names = {name for recv, name in nullobj if recv == "_G"}
    method_pairs = {(recv, name) for recv, name in nullobj if recv != "_G"}

    method_re = re.compile(
        r"(local\s+)?([A-Za-z_]\w*)\s*=\s*([A-Za-z_]\w*)\s*:\s*([A-Za-z_]\w*)\s*\("
    )
    global_re = re.compile(
        r"(local\s+)?([A-Za-z_]\w*)\s*=\s*([A-Za-z_]\w*)\s*\("
    )

    hits = []
    files = 0
    for dirpath, _dirs, fnames in os.walk(interface_root):
        for fn in fnames:
            if not fn.lower().endswith(".lua"):
                continue
            path = os.path.join(dirpath, fn)
            files += 1
            with open(path, "rb") as fh:
                lines = fh.read().decode("utf-8", errors="replace").splitlines()
            rel = os.path.relpath(path, interface_root).replace("\\", "/")
            frame = os.path.relpath(dirpath, interface_root).split(os.sep)[0]

            def record(i, var, is_local, recv, name):
                # local  -> chi nhin cua so ke tiep
                # KHONG local (global/upvalue) -> quet CA FILE, vi noi gan va noi dung
                #                                 co the cach nhau hang nghin dong
                if is_local:
                    lo, hi = i, min(i + 40, len(lines))
                else:
                    lo, hi = 0, len(lines)
                field_re = re.compile(r"\b%s\s*\.\s*([A-Za-z_]\w*)" % re.escape(var))
                pats = numeric_use_patterns(var)
                uses = []
                for j in range(lo, hi):
                    src = strip_comment(lines[j])
                    if not src.strip():
                        continue
                    for fld in field_re.findall(src):
                        uses.append({"line": j + 1, "kind": "doc-truong",
                                     "detail": fld, "text": src.strip()[:150]})
                    for rx, kind in pats:
                        if rx.search(src):
                            uses.append({"line": j + 1, "kind": kind,
                                         "detail": "", "text": src.strip()[:150]})
                            break
                if uses:
                    hits.append({
                        "file": rel, "frame": frame, "call_line": i + 1,
                        "receiver": recv, "function": name, "var": var,
                        "scope": "local" if is_local else "global/upvalue",
                        "uses": uses[:12], "use_count": len(uses),
                    })

            for i, raw in enumerate(lines):
                line = strip_comment(raw)
                m = method_re.search(line)
                if m and (m.group(3), m.group(4)) in method_pairs:
                    record(i, m.group(2), bool(m.group(1)), m.group(3), m.group(4))
                    continue
                g = global_re.search(line)
                if g and g.group(3) in global_names:
                    record(i, g.group(2), bool(g.group(1)), "_G", g.group(3))
    return hits, files


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luaapigen-src", required=True)
    ap.add_argument("--interface-root", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--selftest", action="store_true",
                    help="doi chung am: phai bat duoc CA HAI loi that cua nhanh nay")
    ap.add_argument("--assume-no-hosts", action="store_true",
                    help="doi chung duong: KHONG tru cac ham da co host that")
    args = ap.parse_args()

    nullobj, all_stubs = load_nullobj_stubs(args.luaapigen_src)

    # CYS-UIFIX2 20/09: bo nay KHONG he co phep nhan host -> moi ham DA CO HOST THAT van bi
    # dem nhu con la stub. Do duoc: 55/326 site (17 %) cua chinh bo nay, va sai so ay TO DAN
    # moi lan mot nhanh cai them host. Tru chung ra.
    # `--selftest` thi KHONG tru: hai ca doi chung cua nhanh selfequip-fit nay DA duoc va
    # (WGAch:GetCJMaxCur, _G:Lua_GetMyMaxLevelLimit), nen neu tru thi phep tu kiem se do vi
    # mot ly do SAI - no van phai chung minh bo quet BAT DUOC hai MAU ay.
    hosted = set()
    if not (args.selftest or args.assume_no_hosts):
        hosted = cys_uifix2_hosts.scan_dir(args.luaapigen_src)[1]
        nullobj = set(nullobj) - hosted

    hits, files = scan_lua(args.interface_root, nullobj)

    if args.selftest:
        # Doi chung am tren du lieu that: hai loi DA XAY RA trong game phai nam trong ket qua.
        want = [("SelfEquip", "WGAch", "GetCJMaxCur"),
                ("SelfEquip", "_G", "Lua_GetMyMaxLevelLimit")]
        ok = True
        for frame, recv, name in want:
            found = any(h["frame"] == frame and h["receiver"] == recv and h["function"] == name
                        for h in hits)
            print("%s %s:%s trong %s" % ("OK   " if found else "TRUOT", recv, name, frame))
            ok = ok and found
        if not ok:
            print("SELFTEST FAIL: bo quet KHONG bat duoc loi da biet => dang mu")
            raise SystemExit(1)
        print("SELFTEST OK: bat duoc ca hai loi da xay ra that")

    frames = sorted({h["frame"] for h in hits})
    funcs = sorted({"%s:%s" % (h["receiver"], h["function"]) for h in hits})
    by_kind = defaultdict(int)
    for h in hits:
        for u in h["uses"]:
            by_kind[u["kind"]] += 1

    out = {
        "scanner_version": 2,
        "luaapigen_src": args.luaapigen_src,
        "interface_root": args.interface_root,
        "stubs_total": len(all_stubs),
        "stubs_returning_nullobject": len(nullobj),
        "lua_files_scanned": files,
        "risk_sites": len(hits),
        "frames_at_risk": frames,
        "frames_at_risk_count": len(frames),
        "functions_involved": funcs,
        "functions_involved_count": len(funcs),
        "use_kind_counts": dict(by_kind),
        "hits": hits,
    }
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=2)
    print("da ghi JSON: %s" % args.out)
    print("stub tong=%d  tra ve null-object=%d" % (len(all_stubs), len(nullobj)))
    print("file lua quet=%d  diem rui ro=%d  khung dinh=%d  ham dinh=%d"
          % (files, len(hits), len(frames), len(funcs)))


if __name__ == "__main__":
    main()
