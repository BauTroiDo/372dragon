#!/usr/bin/env python3
# CYS-SEFIT: do lop loi thu BA - "sai SO LUONG gia tri tra ve".
#
# Hai bo quet kia chi thay ham host CON THIEU (stub). Lop nay khac han: ham CO THAT,
# da cai dat, chay binh thuong, nhung tra ve IT gia tri hon so bien ma script CY bind.
# Lua khong bao gi ca - cac bien thua chi lang le thanh `nil`, roi no ra o phep so
# sanh dau tien, cach do vai dong.
#
# Ca da xay ra that (19/09 22:45, 5 lan trong mot phien):
#     SuperTooltip.lua:181  g_pos1, g_pos2 = _SuperTooltip_:PositionSelf(...)
#     UILuaControl.cpp:2158 SuperTooltip::PositionSelf  -> `return 0;` tren CA HAI duong
#     SuperTooltip.lua:187  if tonumber(g_pos1) < tonumber(g_left) then
#         -> "attempt to compare nil with number"  => giet ca ham nap khung
#
# Bo quet: doc so gia tri tra ve toi da cua moi ham host C++ (cac cau `return <so>;`
# trong than ham) roi doi chieu voi so bien ma Lua bind tu chinh ham do.
# Bao khi  lua_bind > cpp_max_return.
#
# HAN CHE (ghi ro, dung coi la tuyet doi):
#  - chi doc `return <hang so>;`; ham nao `return n;` voi n la bien thi bo qua (ghi nhan rieng).
#  - doi chieu theo TEN ham, khong theo lop, nen hai lop cung ten ham se gop lam mot.
# => Con so la DANH SACH CAN DOC, khong phai danh sach loi da chung minh.

import argparse
import json
import os
import re
from collections import defaultdict

# INT  Class::Method( LuaPlus::LuaState* ... )
CPP_FN_RE = re.compile(
    r"^\s*(?:INT|int)\s+(?:(\w+)\s*::\s*)?(\w+)\s*\(\s*LuaPlus::LuaState\s*\*", re.M)
RET_CONST_RE = re.compile(r"\breturn\s+(\d+)\s*;")
RET_ANY_RE = re.compile(r"\breturn\b([^;]*);")


def cpp_return_counts(src_roots):
    """ten ham -> {'max': n, 'dynamic': bool, 'where': 'file:line'}"""
    out = {}
    for root in src_roots:
        for dirpath, _dirs, files in os.walk(root):
            for fn in files:
                if not fn.endswith((".cpp", ".cxx")):
                    continue
                path = os.path.join(dirpath, fn)
                with open(path, "rb") as fh:
                    text = fh.read().decode("utf-8", errors="replace")
                for m in CPP_FN_RE.finditer(text):
                    name = m.group(2)
                    # than ham: tu dau { sau chu ky den khi can bang ngoac
                    i = text.find("{", m.end())
                    if i < 0:
                        continue
                    depth, j = 0, i
                    while j < len(text):
                        if text[j] == "{":
                            depth += 1
                        elif text[j] == "}":
                            depth -= 1
                            if depth == 0:
                                break
                        j += 1
                    body = text[i:j]
                    consts = [int(x) for x in RET_CONST_RE.findall(body)]
                    dynamic = any(not r.strip().isdigit() and r.strip()
                                  for r in RET_ANY_RE.findall(body))
                    line = text.count("\n", 0, m.start()) + 1
                    rec = {"max": max(consts) if consts else 0,
                           "dynamic": dynamic,
                           "where": "%s:%d" % (os.path.relpath(path, root).replace("\\", "/"), line)}
                    prev = out.get(name)
                    if prev is None or rec["max"] > prev["max"] or (rec["dynamic"] and not prev["dynamic"]):
                        out[name] = rec
    return out


# a, b = obj:Method(   /   a, b = Method(
LUA_BIND_RE = re.compile(
    r"(?:local\s+)?([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)+)\s*=\s*"
    r"(?:([A-Za-z_]\w*)\s*:\s*)?([A-Za-z_]\w*)\s*\(")


def scan_lua(interface_root, cpp):
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
            for i, raw in enumerate(lines):
                line = raw.split("--")[0]
                m = LUA_BIND_RE.search(line)
                if not m:
                    continue
                name = m.group(3)
                info = cpp.get(name)
                if not info or info["dynamic"]:
                    continue        # khong biet chac -> khong bao
                binds = len([x for x in m.group(1).split(",") if x.strip()])
                if binds > info["max"]:
                    hits.append({
                        "frame": frame, "file": rel, "line": i + 1,
                        "receiver": m.group(2) or "_G", "function": name,
                        "lua_binds": binds, "cpp_max_return": info["max"],
                        "cpp_at": info["where"], "text": line.strip()[:150],
                    })
    return hits, files


def selftest():
    """Doi chung am tren vat lieu tong hop: phai BAT duoc ca thieu, phai IM khi du."""
    import tempfile, shutil
    tmp = tempfile.mkdtemp()
    ok = True
    try:
        cpp_dir = os.path.join(tmp, "src"); os.makedirs(cpp_dir)
        with open(os.path.join(cpp_dir, "x.cpp"), "w", encoding="utf-8") as fh:
            fh.write("INT Foo::PositionSelf( LuaPlus::LuaState* p )\n{\n  if (bad) { return 0; }\n  return 0;\n}\n")
            fh.write("INT Foo::GoodOne( LuaPlus::LuaState* p )\n{\n  return 2;\n}\n")
        lua_dir = os.path.join(tmp, "ui", "F"); os.makedirs(lua_dir)
        with open(os.path.join(lua_dir, "F.lua"), "w", encoding="utf-8") as fh:
            fh.write("g_pos1, g_pos2 = _SuperTooltip_:PositionSelf(a,b,c,d)\n")
            fh.write("x, y = Obj:GoodOne(1)\n")
        cpp = cpp_return_counts([cpp_dir])
        hits, _ = scan_lua(os.path.join(tmp, "ui"), cpp)
        names = {h["function"] for h in hits}
        if "PositionSelf" not in names:
            print("SELFTEST FAIL: khong bat duoc ham tra thieu gia tri"); ok = False
        else:
            print("SELFTEST OK: bat duoc 'bind 2 / return 0'")
        if "GoodOne" in names:
            print("SELFTEST FAIL: bao dong gia khi so luong khop"); ok = False
        else:
            print("SELFTEST OK: khong bao dong gia khi 'bind 2 / return 2'")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", action="append", default=[], help="thu muc nguon C++ (lap lai duoc)")
    ap.add_argument("--interface-root")
    ap.add_argument("--out")
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()

    if args.selftest:
        raise SystemExit(0 if selftest() else 1)
    if not args.src or not args.interface_root or not args.out:
        ap.error("can --src, --interface-root va --out")

    cpp = cpp_return_counts(args.src)
    hits, files = scan_lua(args.interface_root, cpp)
    frames = sorted({h["frame"] for h in hits})
    out = {
        "src_roots": args.src, "interface_root": args.interface_root,
        "cpp_lua_functions": len(cpp),
        "cpp_dynamic_return": sum(1 for v in cpp.values() if v["dynamic"]),
        "lua_files_scanned": files,
        "mismatch_sites": len(hits),
        "frames": frames, "frames_count": len(frames),
        "hits": sorted(hits, key=lambda h: (h["frame"], h["line"])),
    }
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=2)
    print("da ghi JSON: %s" % args.out)
    print("ham host C++ doc duoc=%d (bo qua %d ham tra ve dong)"
          % (len(cpp), out["cpp_dynamic_return"]))
    print("file lua=%d  diem lech so luong=%d  khung=%d" % (files, len(hits), len(frames)))


if __name__ == "__main__":
    main()
