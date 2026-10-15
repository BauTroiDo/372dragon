#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""cys_uifix2_hosts.py  (CYS-UIFIX2)

Liet ke MOI ham host THAT SU da duoc dang ky trong Src/Client/LuaApiGen/CysHost_*.cpp.

VI SAO CAN: ca hai bo quet cu chi nhan RA HAI kieu dang ky
    RegisterOn(state, "Recv", "Name", fn)       (cys_uiframes_stub_scan.py REGON_RE)
    globals.Register("Name", fn)                (cys_uiframes_stub_scan.py REGG_RE)
con `cys_sefit_nullobj_scan.py` thi KHONG co phep nhan host nao ca.
Nhung 12/13 file CysHost dang ky bang MOT BANG:
    const Entry kEntries[] = { {"DataPool", "CreateActionItemForShow", fn}, {NULL, "Lua_X", fn} };
    ... table.Register(e.name, e.fn);
=> moi ten trong cac bang do bi CA HAI bo quet dem nham la "van con la stub".

Bo trich nay doc CA BA kieu. Doi chung am bat buoc: --self-test.
ASCII only trong ma nguon; du lieu ra la UTF-8 JSON.
"""
import argparse
import json
import os
import re

# {"Recv", "Name", Fn}  |  {NULL, "Name", Fn}
ENTRY_RE = re.compile(
    r'\{\s*(?:"([A-Za-z_][\w]*)"|NULL|nullptr)\s*,\s*"([A-Za-z_][\w]*)"\s*,\s*[&A-Za-z_]')
# RegisterOn(state, "Recv", "Name", ...)
REGON_RE = re.compile(r'RegisterOn\s*\(\s*\w+\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"')
# globals.Register("Name", ...)
REGG_RE = re.compile(r'\bglobals\s*\.\s*Register\s*\(\s*"([^"]+)"')
# table.Register("Name", ...)  -- receiver lay tu Receiver(globals, "X") gan nhat phia tren
REGT_RE = re.compile(r'\btable\s*\.\s*Register\s*\(\s*"([^"]+)"')
RECV_RE = re.compile(r'Receiver\s*\(\s*globals\s*,\s*"([^"]+)"')


def read_text(path):
    with open(path, "rb") as fh:
        return fh.read().decode("utf-8", errors="replace")


def hosts_in_text(text):
    """Tra ve set (recv, name).  recv == '_G' cho ham toan cuc."""
    out = set()
    for recv, name in ENTRY_RE.findall(text):
        out.add((recv or "_G", name))
    for recv, name in REGON_RE.findall(text):
        out.add((recv, name))
    for name in REGG_RE.findall(text):
        out.add(("_G", name))
    # table.Register("Literal", ...) : tim Receiver(globals,"X") gan nhat PHIA TREN
    for m in REGT_RE.finditer(text):
        head = text[:m.start()]
        recvs = RECV_RE.findall(head)
        out.add((recvs[-1] if recvs else "_G", m.group(1)))
    return out


def scan_dir(src_dir):
    per_file = {}
    allhosts = set()
    for fn in sorted(os.listdir(src_dir)):
        if not (fn.startswith("CysHost") and fn.endswith(".cpp")):
            continue
        found = hosts_in_text(read_text(os.path.join(src_dir, fn)))
        per_file[fn] = sorted("%s:%s" % k for k in found)
        allhosts |= found
    return per_file, allhosts


# --------------------------------------------------------------- doi chung
SAMPLE_TABLE = '''
        const Entry kEntries[] =
        {
            {"DataPool", "CreateActionItemForShow",     CreateActionItemForShow},
            {NULL,       "Lua_CysIconProbe",            GlobalCysIconProbe},
        };
        table.Register(e.name, e.fn);
'''
SAMPLE_GLOBALS = '        globals.Register("Lua_GetMyMaxLevelLimit", LuaGetMyMaxLevelLimit);\n'
SAMPLE_REGON = '        RegisterOn(state, "WGAch", "GetCJMaxCur", GetCJMaxCur);\n'
SAMPLE_TABLELIT = ('        LuaPlus::LuaObject table = Receiver(globals, "SystemSetup");\n'
                   '        table.Register("GetInputSetup", SystemSetupGetInputSetup);\n')
SAMPLE_NONE = '        int x = 1; // khong co dang ky nao\n'


def self_test():
    ok = True

    def check(name, cond, extra=""):
        nonlocal ok
        print(("PASS " if cond else "FAIL ") + name + ("  " + extra if extra else ""))
        if not cond:
            ok = False

    t = hosts_in_text(SAMPLE_TABLE)
    check("bang_kEntries_co_receiver", ("DataPool", "CreateActionItemForShow") in t)
    check("bang_kEntries_NULL_thanh_G", ("_G", "Lua_CysIconProbe") in t)
    check("bang_kEntries_dung_so_luong", len(t) == 2, "len=%d" % len(t))
    check("globals_Register", hosts_in_text(SAMPLE_GLOBALS) == {("_G", "Lua_GetMyMaxLevelLimit")})
    check("RegisterOn", hosts_in_text(SAMPLE_REGON) == {("WGAch", "GetCJMaxCur")})
    check("table_Register_literal_lay_dung_receiver",
          hosts_in_text(SAMPLE_TABLELIT) == {("SystemSetup", "GetInputSetup")})
    # doi chung am: bo trich PHAI biet TRUOT khi khong co dang ky nao
    check("biet_TRUOT_khi_khong_co_dang_ky", hosts_in_text(SAMPLE_NONE) == set())
    # doi chung am thu hai: mot chuoi trong binh luan khong phai dang ky
    check("khong_bat_chuoi_tran",
          hosts_in_text('        // "DataPool", "GetSomething" chi la binh luan\n') == set())
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luaapigen-src", default="Src/Client/LuaApiGen")
    ap.add_argument("--out")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        raise SystemExit(0 if self_test() else 1)
    per_file, allhosts = scan_dir(args.luaapigen_src)
    doc = {
        "luaapigen_src": args.luaapigen_src,
        "files": len(per_file),
        "hosts_total": len(allhosts),
        "hosts": sorted("%s:%s" % k for k in allhosts),
        "per_file": per_file,
    }
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, ensure_ascii=False, indent=1)
    print("files=%d hosts=%d -> %s" % (len(per_file), len(allhosts), args.out or "(stdout)"))
    for fn in sorted(per_file):
        print("  %-28s %d" % (fn, len(per_file[fn])))


if __name__ == "__main__":
    main()
