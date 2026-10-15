# -*- coding: utf-8 -*-
"""CYS-MTSWEEP - kiem lop loi "metatable dung chung + ep kieu mu m_pWindow" trong UILuaControl.cpp.

Vi sao lop loi nay ton tai
--------------------------
`Window::RegisterMetaTable` lam `*X::s_pMetaTable = *Window::s_pMetaTable` cho MOI lop dieu khien, ma
`LuaPlus::LuaObject` la tham chieu => ca client chi co MOT bang metatable. Vi vay mot ten ham Lua giai
quyet ve DANG KY DUY NHAT cua ten do, bat ke cua so that thuoc lop nao. Neu than ham do ep kieu mu
`((CEGUI::T*)m_pWindow)->...` thi loi goi se doc/ghi truong o offset cua T tren mot doi tuong khong phai T:
khong co loi Lua, khong co thong bao, tien trinh chet ngay (xem `Timeline\\handoff\\qlog-crash.md`).

Phep kiem nay khong dem ep kieu tinh. No chi bao dong khi CA BA dieu sau dung cung luc:
  1. co mot cho ep kieu mu trong ham binding thang ten Lua do,
  2. co mot tep `.lua` that goi `<TenCuaSo>:<TenHam>(` ,
  3. lop THAT cua cua so do (layout -> scheme FalagardMapping -> WidgetTypeName -> lop C++) khong nam
     trong chuoi to tien cua kieu bi ep, VA ham do khong he co nhanh `dynamic_cast` bat duoc lop that.

Chay
----
    python Tests/ui/metatable_cast_tests.py --out <thu muc>
    python Tests/ui/metatable_cast_tests.py --out <thu muc> --self-test

`--self-test` chay lai dung phep kiem tren ban `git show <rev>:...` TRUOC khi vá (mac dinh HEAD) va doi
no PHAI bao dong - tuc phep kiem BIET TRUOT. Neu ban cu ma van "xanh" thi phep kiem vo gia tri.
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
UILUA_REL = "Src/Client/CEGUISystem/UILuaControl.cpp"
SRC = os.path.join(ROOT, "Src")
IFACE = os.path.join(ROOT, "Assets", "CanonicalCY", "Data", "InterfaceFolder")
SCHEME = os.path.join(IFACE, "Schema", "WoWLookSkin.scheme.xml")

REG_RE = re.compile(r'RegisterObjectFunctor\s*\(\s*"([^"]+)"\s*,\s*&\s*(\w+)::(\w+)\s*\)')
DEF_RE = re.compile(r"^[A-Za-z_][\w:<>\*&\s]*?\b(\w+)::(\w+)\s*\(", re.M)
CASTCHAIN = re.compile(r"((?:\(\s*(?:CEGUI::)?\w+\s*\*\s*\)\s*)+)(?:\(\s*)?m_pWindow\b(?!\s*->\s*getUserData)")
ONECAST = re.compile(r"\(\s*((?:CEGUI::)?\w+)\s*\*\s*\)")
DYN_RE = re.compile(r"dynamic_cast\s*<\s*((?:CEGUI::)?\w+)\s*\*\s*>")
# Khoi doi chung A/B: `if (cysXxxOff())` - ma trong do CO CHU Y giu duong ep kieu mu cu.
CONTROL_RE = re.compile(r"^\s*if\s*\(\s*cys\w*Off\s*\(\s*\)\s*\)\s*$")
WIN_RE = re.compile(r'<\s*Window\s+Type\s*=\s*"([^"]+)"\s+Name\s*=\s*"([^"]+)"')
WIN_RE2 = re.compile(r'<\s*Window\s+Name\s*=\s*"([^"]+)"\s+Type\s*=\s*"([^"]+)"')
CALL_RE = re.compile(r"\b(\w+)\s*:\s*(\w+)\s*\(")


def read(path):
    with open(path, "rb") as f:
        raw = f.read()
    return decode(raw)


def decode(raw):
    for enc in ("utf-8-sig", "utf-8", "gbk", "latin-1"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode("latin-1")


def control_lines(lines):
    """Tap chi so dong nam trong mot khoi `if (cysXxxOff()) { ... }`."""
    out = set()
    i = 0
    while i < len(lines):
        if CONTROL_RE.match(lines[i]):
            j = i + 1
            while j < len(lines) and "{" not in lines[j]:
                j += 1
            depth = 0
            while j < len(lines):
                depth += lines[j].count("{") - lines[j].count("}")
                out.add(j + 1)
                j += 1
                if depth <= 0:
                    break
        i += 1
    return out


def parse_binding(text):
    lines = text.split("\n")
    skip = control_lines(lines)
    regs = collections.OrderedDict()
    for m in REG_RE.finditer(text):
        regs.setdefault(m.group(1), []).append((m.group(2), m.group(3)))
    defs = sorted((text.count("\n", 0, m.start()) + 1, m.group(1), m.group(2)) for m in DEF_RE.finditer(text))
    bounds = {}
    for i, (ln, c, me) in enumerate(defs):
        bounds[(c, me)] = (ln, defs[i + 1][0] - 1 if i + 1 < len(defs) else len(lines))
    sites, dispatch = collections.defaultdict(list), collections.defaultdict(set)
    for key, (s, e) in bounds.items():
        for off, raw in enumerate(lines[s - 1: e]):
            ln = s + off
            for m in DYN_RE.finditer(raw):
                dispatch[key].add(m.group(1).split("::")[-1])
            if ln in skip:
                continue
            for m in CASTCHAIN.finditer(raw):
                types = [t.split("::")[-1] for t in ONECAST.findall(m.group(1))]
                sites[key].append({"line": ln, "inner": types[-1], "code": raw.strip()[:160]})
    # "uy quyen": than ham chi gom DUNG MOT cau `return <ham>(...);` - dung de biet hai ban dang ky trung ten
    # co thuc su cung mot hanh vi hay khong.
    delegate = {}
    for key, (s, e) in bounds.items():
        # Cat dung than ham: tu dau `{` den khi ngoac can bang lai (bo dong chu ky va moi thu sau ham).
        raw_body, depth, started = [], 0, False
        for l in lines[s: e]:
            code = l.split("//")[0]
            depth += code.count("{") - code.count("}")
            if not started and "{" in code:
                started = True
                continue
            if started and depth <= 0:
                break
            if started:
                raw_body.append(code.strip())
        body = [l for l in raw_body if l and l not in ("{", "}")]
        if len(body) == 1:
            m = re.match(r"^return\s+(\w+)\s*\(.*\)\s*;$", body[0])
            if m:
                delegate[key] = m.group(1)
    return regs, sites, dispatch, len(skip), delegate


def scan_cpp_tree():
    type2class, parents = {}, collections.defaultdict(list)
    class_pat = re.compile(r"\bclass\s+(?:[A-Z_][A-Z0-9_]*\s+)?(\w+)\s*(?::\s*([^{;]*))?\{", re.S)
    base_pat = re.compile(r"(?:public|protected|private)\s+(?:virtual\s+)?((?:\w+::)*\w+)")
    for base, _d, files in os.walk(SRC):
        for fn in files:
            if not fn.endswith((".h", ".hpp", ".cpp", ".inl")):
                continue
            t = read(os.path.join(base, fn))
            for m in re.finditer(r"\b(\w+)\s*::\s*WidgetTypeName\s*\[\s*\]\s*=\s*\"([^\"]+)\"", t):
                type2class.setdefault(m.group(2), m.group(1))
            for m in re.finditer(r"\b\w+\s*::\s*(\w+)\s*::\s*WidgetTypeName\s*\[\s*\]\s*=\s*\"([^\"]+)\"", t):
                type2class.setdefault(m.group(2), m.group(1))
            for m in class_pat.finditer(t):
                if not m.group(2):
                    continue
                for bm in base_pat.finditer(m.group(2)):
                    p = bm.group(1).split("::")[-1]
                    if p not in parents[m.group(1)]:
                        parents[m.group(1)].append(p)
    return type2class, parents


def chain(cls, parents, seen=None):
    if seen is None:
        seen = set()
    out = [cls]
    for p in parents.get(cls, []):
        if p in seen:
            continue
        seen.add(p)
        out.extend(chain(p, parents, seen))
    return out


def parse_assets():
    scheme = {}
    for m in re.finditer(r'FalagardMapping\s+WindowType\s*=\s*"([^"]+)"\s+TargetType\s*=\s*"([^"]+)"', read(SCHEME)):
        scheme[m.group(1)] = m.group(2)
    per_dir, glob, files, n_layout, n_lua = collections.defaultdict(dict), collections.defaultdict(set), collections.defaultdict(set), 0, 0
    calls = collections.defaultdict(list)
    for base, _d, fl in os.walk(IFACE):
        for fn in fl:
            p = os.path.join(base, fn)
            if fn.endswith(".layout.xml"):
                n_layout += 1
                t = read(p)
                pairs = [(m.group(2), m.group(1)) for m in WIN_RE.finditer(t)]
                pairs += [(m.group(1), m.group(2)) for m in WIN_RE2.finditer(t)]
                for name, wtype in pairs:
                    per_dir[base].setdefault(name, wtype)
                    glob[name].add(wtype)
                    files[name].add(os.path.relpath(p, ROOT).replace("\\", "/"))
            elif fn.endswith(".lua"):
                n_lua += 1
                rel = os.path.relpath(p, ROOT).replace("\\", "/")
                for i, line in enumerate(read(p).split("\n"), start=1):
                    s = line.strip()
                    if s.startswith("--"):
                        continue
                    for m in CALL_RE.finditer(s.split("--")[0]):
                        calls[(base, m.group(1), m.group(2))].append("%s:%d" % (rel, i))
    return scheme, per_dir, glob, files, calls, n_layout, n_lua


def analyse(text, assets, tree):
    scheme, per_dir, glob, lfiles, calls, n_layout, n_lua = assets
    type2class, parents = tree
    regs, sites, dispatch, n_skip, delegate = parse_binding(text)
    winner = {k: v[-1] for k, v in regs.items()}
    duplicates = {k: ["%s::%s" % v for v in lst] for k, lst in regs.items() if len(lst) > 1}
    # Mot ten Lua bi dang ky nhieu lan thi ban SAU nuot ban truoc trong bang metatable dung chung => thu tu
    # dang ky quyet dinh hanh vi cho MOI cua so. Chi chap nhan khi dieu do KHONG con quan trong:
    #   * moi ban deu uy quyen cho CUNG mot ham dieu huong, hoac
    #   * moi ban deu tu dieu huong theo kieu that (co `dynamic_cast`).
    dup_unsafe = {}
    for name, lst in regs.items():
        if len(lst) < 2:
            continue
        keys = list(lst)
        dels = [delegate.get(k) for k in keys]
        if len(set(dels)) == 1 and dels[0] is not None:
            continue
        bad = ["%s::%s" % k for k in keys if not dispatch.get(k)]
        if bad:
            dup_unsafe[name] = bad
    mines, n_pairs = [], 0
    for (d, obj, meth), where in calls.items():
        if meth not in winner:
            continue
        key = winner[meth]
        if not sites.get(key):
            continue
        wtype = per_dir.get(d, {}).get(obj)
        if wtype is None:
            g = glob.get(obj)
            wtype = next(iter(g)) if g and len(g) == 1 else None
        if wtype is None:
            continue
        actual = type2class.get(scheme.get(wtype, ""))
        if actual is None:
            continue
        n_pairs += 1
        ach = set(chain(actual, parents))
        if any(t in ach for t in dispatch.get(key, ())):
            continue                              # ham co nhanh dynamic_cast bat duoc lop nay
        for s in sites[key]:
            if s["inner"] in ach:
                continue                          # nang kieu hop le
            mines.append({
                "lua_method": meth, "window": obj, "window_type": wtype, "actual_class": actual,
                "binding": "%s::%s" % key, "cast_to": s["inner"], "cpp_line": s["line"],
                "calls": len(where), "example": sorted(where)[0],
                "layout": sorted(lfiles.get(obj, []))[:1],
            })
    return {
        "duplicate_registrations": duplicates,
        "duplicate_registrations_unsafe": dup_unsafe,
        "registered_lua_names": len(regs),
        "blind_cast_sites": sum(len(v) for v in sites.values()),
        "blind_cast_lines_in_ab_control_blocks": n_skip,
        "lua_names_with_blind_cast": len([n for n, k in winner.items() if sites.get(k)]),
        "resolved_window_method_pairs": n_pairs,
        "layouts": n_layout, "lua_files": n_lua,
        "mines": sorted(mines, key=lambda m: (-m["calls"], m["lua_method"], m["window"])),
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", required=True)
    ap.add_argument("--self-test", action="store_true",
                    help="chay lai phep kiem tren ban truoc khi va va doi no PHAI bao dong")
    ap.add_argument("--rev", default="HEAD", help="ban goc dung cho --self-test")
    args = ap.parse_args()
    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)

    assets = parse_assets()
    tree = scan_cpp_tree()
    live = analyse(read(os.path.join(ROOT, UILUA_REL)), assets, tree)

    checks = []
    checks.append({"name": "khong con cho ep kieu mu nao kich hoat duoc tu layout + lua",
                   "passed": not live["mines"],
                   "detail": "%d min tren %d cap (cua so, ham) giai duoc lop that"
                             % (len(live["mines"]), live["resolved_window_method_pairs"])})
    checks.append({"name": "mo hinh co du lieu de ket luan (khong phai xanh vi rong)",
                   "passed": live["resolved_window_method_pairs"] > 1000 and live["blind_cast_sites"] > 50,
                   "detail": "%d cap giai duoc, %d cho ep kieu mu, %d layout, %d lua"
                             % (live["resolved_window_method_pairs"], live["blind_cast_sites"],
                                live["layouts"], live["lua_files"])})

    # Cung mot goc (MOT metatable) nhung khac trieu chung: mot ten dang ky nhieu lan thi ban sau NUOT ban truoc,
    # va moi cua so - ke ca loai dung - deu nhan ban sau. Day la thu da giet 159 loi goi `:AddItem(` mot cach
    # IM LANG (xem Timeline\handoff\metatable-sweep.md muc 3.6). Phep kiem khong cam trung ten; no doi thu tu
    # dang ky KHONG con quyet dinh hanh vi.
    checks.append({"name": "ten Lua dang ky nhieu lan: thu tu dang ky khong duoc quyet dinh hanh vi",
                   "passed": not live["duplicate_registrations_unsafe"],
                   "detail": "trung ten: %s | khong an toan: %s"
                             % (", ".join(sorted(live["duplicate_registrations"])) or "(khong)",
                                "; ".join("%s -> %s" % (k, ", ".join(v))
                                          for k, v in sorted(live["duplicate_registrations_unsafe"].items()))
                                or "(khong)")})

    baseline = None
    if args.self_test:
        raw = subprocess.check_output(["git", "-C", ROOT, "show", "%s:%s" % (args.rev, UILUA_REL)])
        baseline = analyse(decode(raw), assets, tree)
        names = sorted({m["lua_method"] for m in baseline["mines"]})
        checks.append({"name": "phep kiem BIET TRUOT: ban %s (truoc khi va) phai bao dong" % args.rev,
                       "passed": len(baseline["mines"]) > 0,
                       "detail": "%d min o ban goc: %s" % (len(baseline["mines"]), ", ".join(names))})
        checks.append({"name": "phep kiem bat duoc dung ca da dong cua qlog-crash (SetScrollPosition)",
                       "passed": any(m["lua_method"] == "SetScrollPosition" and m["window"] == "QuestLog_Desc"
                                     for m in baseline["mines"]),
                       "detail": "QuestLog_Desc:SetScrollPosition co trong danh sach min cua ban goc"})
        checks.append({"name": "phep kiem trung ten cung BIET TRUOT: ban %s phai bao `AddItem` khong an toan" % args.rev,
                       "passed": "AddItem" in baseline["duplicate_registrations_unsafe"],
                       "detail": "khong an toan o ban goc: %s"
                                 % (", ".join(sorted(baseline["duplicate_registrations_unsafe"])) or "(khong)")})

    failed = [c for c in checks if not c["passed"]]
    result = {"passed": len(checks) - len(failed), "failed": len(failed), "checks": checks,
              "live": live, "baseline": baseline,
              "scope": "Phan tich tinh nguon C++ + layout + lua; khong can Game, GPU hay mang."}
    with open(os.path.join(out, "result.json"), "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=1)
    print(json.dumps({"passed": result["passed"], "failed": result["failed"],
                      "checks": [{k: c[k] for k in ("name", "passed", "detail")} for c in checks]},
                     ensure_ascii=False, indent=1))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
