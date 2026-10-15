#!/usr/bin/env python3
# CYS-UIFRAMES: quet TOAN BO khung giao dien de tim cho ma stub sinh tu dong
# lam ham Lua NEM, giet ca ham cap nhat khung.
#
# VI SAO CAN BO QUET MOI (bo cu `cys_sefit_nullobj_scan.py` co BA diem mu, do duoc):
#   Site that: SelfEquip.lua:3039  LEVEL_MAX_ENABLE = Lua_GetMyMaxLevelLimit()
#              SelfEquip.lua:1480  if( LEVEL_MAX_ENABLE <= nCompatPKLevel ...
#   Bo cu bo sot vi: (1) goi ham `_G` KHONG co receiver (`R:N()` bat buoc dau `:`),
#   (2) dung TRUC TIEP gia tri chu khong phai `v.field`, (3) cach nhau 1.559 dong
#   va o HAI ham khac nhau (cua so 30 dong).
#   Log phien choi that 19/09 22:44 xac nhan site nay NEM:
#     "SelfEquip_Env ... :1480: attempt to compare table with number"
#
# BON LOP LOI (moi lop deu co it nhat mot vi du DO DUOC tu log nguoi dung):
#   N1  nullobj lam BAN GHI     -> v.field la HAM   -> "compare number with function"
#                                  (SelfEquip.lua:1465, play-1)
#   N2  nullobj lam GIA TRI     -> so sanh thang    -> "compare table with number"
#                                  (SelfEquip.lua:1480, play-2)
#   N3  't' = bang RONG that    -> v.field la nil   -> "compare number with nil"
#   N4  THIEU GIA TRI TRA VE    -> script lay k gia tri, stub tra n < k
#                                  -> cac bien du = nil
#                                  (Friend.lua:854 <- DataPool:GetIMIconNum spec "n"
#                                   nhung script lay 4 gia tri, play-1)
#
# Bang ma tra ve (LuaApiGen_Common.cpp:112-137):
#   n->0  1->1  N->-1  s->""  b->false  z->nil  t->NewTable()  <bat ky>-> PushNullObject
#
# Ket qua LUON ghi ra JSON (--out). Co --self-test (doi chung am bat buoc).

import argparse
import hashlib
import json
import os
import re
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cys_uifix2_hosts  # CYS-UIFIX2: phep nhan host DAY DU (3 thanh ngu, khong phai 2)

# ----------------------------------------------------------------- stub table

STUB_RE = re.compile(
    r'Stub\s*\(\s*\w+\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]*)"\s*\)'
)
# RegisterOn(globals, "WGAch", "GetCJMaxCur", fn)
REGON_RE = re.compile(r'RegisterOn\s*\(\s*\w+\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"')
# globals.Register("Lua_GetMyMaxLevelLimit", fn)   -> ("_G", name)
REGG_RE = re.compile(r'\bglobals\s*\.\s*Register\s*\(\s*"([^"]+)"')

KIND_OF = {
    "n": "number", "1": "number", "N": "number",
    "s": "string", "b": "bool", "z": "nil", "t": "emptytable",
}


def kind_for(ch):
    return KIND_OF.get(ch, "nullobj")


def read_text(path):
    with open(path, "rb") as fh:
        return fh.read().decode("utf-8", errors="replace")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def load_stubs(src_dir):
    """Tra ve (stubs, implemented).

    stubs       : (recv, name) -> spec, CHI tu cac file sinh tu dong LuaApiGen_*.cpp
    implemented : {(recv, name)} da co host that trong CysHost*.cpp -> stub KHONG chay
    """
    stubs = {}
    implemented = set()
    for fn in sorted(os.listdir(src_dir)):
        if not fn.endswith(".cpp"):
            continue
        text = read_text(os.path.join(src_dir, fn))
        if fn.startswith("CysHost"):
            for recv, name in REGON_RE.findall(text):
                implemented.add((recv, name))
            for name in REGG_RE.findall(text):
                implemented.add(("_G", name))
            # CYS-UIFIX2 20/09: hai thanh ngu tren chi bat duoc 3 host tren TONG SO 176 dang ky
            # that su. 12/13 tep CysHost_*.cpp dang ky bang MOT BANG
            # (`const Entry kEntries[] = {{"DataPool","CreateActionItemForShow",fn}, ...}`
            #  roi `table.Register(e.name, e.fn)`), khong khop regex nao o tren.
            # Hau qua do duoc: 39 site cua bo nay va 55 site (17 %) cua cys_sefit_nullobj_scan
            # bi dem oan, va sai so ay TO DAN moi lan mot nhanh cai them host.
            implemented |= cys_uifix2_hosts.hosts_in_text(text)
            continue
        for recv, name, spec in STUB_RE.findall(text):
            stubs[(recv, name)] = spec
    return stubs, implemented


# ------------------------------------------------------------------ lua lexer

BLOCK_COMMENT = re.compile(r"--\[(=*)\[.*?\]\1\]", re.S)
LONG_STRING = re.compile(r"\[(=*)\[.*?\]\1\]", re.S)


def strip_noise(text):
    """Bo chu thich va noi dung chuoi, GIU nguyen so dong va do dai dong."""

    def blank(m):
        return re.sub(r"[^\n]", " ", m.group(0))

    text = BLOCK_COMMENT.sub(blank, text)
    text = LONG_STRING.sub(blank, text)
    out = []
    for line in text.split("\n"):
        res = []
        i, n = 0, len(line)
        quote = None
        while i < n:
            ch = line[i]
            if quote:
                res.append(" ")
                if ch == "\\" and i + 1 < n:
                    res.append(" ")
                    i += 2
                    continue
                if ch == quote:
                    res[-1] = ch  # giu dau nhay dong de van nhan ra la chuoi
                    quote = None
                i += 1
                continue
            if ch in "\"'":
                quote = ch
                res.append(ch)
                i += 1
                continue
            if ch == "-" and i + 1 < n and line[i + 1] == "-":
                res.append(" " * (n - i))
                break
            res.append(ch)
            i += 1
        out.append("".join(res))
    return "\n".join(out)


FUNC_RE = re.compile(r"^\s*(?:local\s+)?function\s+([\w.:]+)?")

# LHS co the la "a, b, c" hoac "local a, b"
ASSIGN_CALL_RE = re.compile(
    r"(?P<local>\blocal\s+)?(?P<lhs>[A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*=\s*"
    r"(?:(?P<recv>[A-Za-z_]\w*)\s*:\s*)?(?P<fn>[A-Za-z_]\w*)\s*\("
)
# `R:N().field` / `N().field` dung truc tiep khong qua bien
DIRECT_FIELD_RE = re.compile(
    r"(?:(?P<recv>[A-Za-z_]\w*)\s*:\s*)?(?P<fn>[A-Za-z_]\w*)\s*\([^()]*\)\s*\.\s*(?P<fld>[A-Za-z_]\w*)"
)

REL_OPS = r"(?:<=|>=|<|>)"
ARITH_OPS = r"(?:\+|-|\*|/|%|\^)"


def uses_of(name):
    """Cac mau dung mot bien theo kieu SE NEM."""
    v = re.escape(name)
    return [
        ("relational", re.compile(r"\b%s\s*%s" % (v, REL_OPS))),
        ("relational", re.compile(r"%s\s*\b%s\b" % (REL_OPS, v))),
        ("arith", re.compile(r"\b%s\s*%s(?!-)" % (v, ARITH_OPS))),
        ("arith", re.compile(r"%s\s*\b%s\b" % (ARITH_OPS, v))),
        ("concat", re.compile(r"\b%s\s*\.\." % v)),
        ("concat", re.compile(r"\.\.\s*\b%s\b" % v)),
        ("length", re.compile(r"#\s*\b%s\b" % v)),
        ("getn", re.compile(r"table\s*\.\s*getn\s*\(\s*%s\s*\)" % v)),
        ("index", re.compile(r"\b%s\s*\[" % v)),
        ("field", re.compile(r"\b%s\s*\.\s*([A-Za-z_]\w*)" % v)),
    ]


# Lop loi nao NEM voi kieu gia tri nao.
# 'field' voi nullobj: v.f la mot HAM -> chi nem khi ham do bi dem so sanh/tinh toan.
THROWS = {
    "nullobj": {"relational": "N2", "arith": "N2", "concat": "N2",
                "length": "N2", "getn": "N2", "field": "N1"},
    "nil": {"relational": "N4", "arith": "N4", "concat": "N4",
            "length": "N4", "getn": "N4", "field": "N4", "index": "N4"},
    "emptytable": {"relational": "N3", "arith": "N3", "concat": "N3", "field": "N3"},
    "bool": {"relational": "N2", "arith": "N2", "concat": "N2",
             "length": "N2", "getn": "N2", "field": "N2", "index": "N2"},
}

# `field` tren nullobj chi NEM neu ket qua bi dung tiep nhu mot so.
FIELD_FOLLOWUP = re.compile(
    r"(?:%s|%s|\.\.)" % (REL_OPS, ARITH_OPS)
)

# ---------------------------------------------------------------- nil guards
#
# KHAC BIET COT LOI, do duoc tay tren PlayerFrame.lua:758-762:
#   - N1/N2 (NULL OBJECT): `x ~= nil` tra ve DUNG (null object la mot BANG)
#     => moi phep canh cua script CY bi VO HIEU => gan nhu chac chan nem.
#   - N3/N4 (nil / bang rong): `x ~= nil` tra ve SAI
#     => phep canh cua script CY CHAY DUNG => KHONG nem, chi lang le bo qua.
# Nen voi N3/N4 phai tru nhung cho da co phep canh, neu khong se bao oan.
# Doi chung: PlayerFrame.lua:762 (`nDayCount < nTblDayCount + 7`) CO canh o dong
# 760 => phai bi loai. Friend/friend.lua:854 KHONG co canh => phai giu lai.


def guard_re(name):
    v = re.escape(name)
    return re.compile(
        r"\b%s\s*(?:~=|==)\s*nil\b"          # v ~= nil / v == nil
        r"|\bnil\s*(?:~=|==)\s*\b%s\b"       # nil ~= v
        r"|\bif\s+not\s+%s\b"                # if not v
        r"|\band\s+not\s+%s\b"
        r"|\bif\s*\(?\s*%s\s*\)?\s+then\b"   # if v then
        r"|\b%s\s*=\s*%s\s+or\b"             # v = v or 0
        % (v, v, v, v, v, v, v)
    )


def scan_file(path, rel, stubs, implemented, max_span):
    text = strip_noise(read_text(path))
    lines = text.split("\n")
    raw = read_text(path).split("\n")

    # ham bao quanh moi dong
    owner = [""] * (len(lines) + 1)
    cur = "<file>"
    for i, line in enumerate(lines):
        m = FUNC_RE.match(line)
        if m:
            cur = (m.group(1) or "<anon>")
        owner[i] = cur

    taints = []  # {name, kind, line, origin, is_local, func}
    for i, line in enumerate(lines):
        for m in ASSIGN_CALL_RE.finditer(line):
            recv = m.group("recv") or "_G"
            fn = m.group("fn")
            key = (recv, fn)
            if key not in stubs or key in implemented:
                continue
            spec = stubs[key]
            names = [x.strip() for x in m.group("lhs").split(",")]
            for idx, nm in enumerate(names):
                if idx < len(spec):
                    kind = kind_for(spec[idx])
                    origin = "spec[%d]='%s'" % (idx, spec[idx])
                else:
                    kind = "nil"
                    origin = "arity: script lay %d gia tri, stub tra %d" % (len(names), len(spec))
                if kind in ("number", "string"):
                    continue
                taints.append({
                    "name": nm, "kind": kind, "line": i + 1,
                    "call": "%s:%s" % (recv, fn), "spec": spec,
                    "origin": origin, "is_local": bool(m.group("local")),
                    "func": owner[i],
                })

    findings = []
    for t in taints:
        pats = uses_of(t["name"])
        gre = guard_re(t["name"])
        guard_absorbs = t["kind"] in ("nil", "emptytable")
        # bien local -> chi trong cung ham; bien toan cuc/upvalue -> ca file
        if t["is_local"]:
            lo, hi = t["line"], min(len(lines), t["line"] + max_span)
        else:
            lo, hi = 0, len(lines)
        tbl = THROWS.get(t["kind"], {})
        for j in range(lo, hi):
            if j == t["line"] - 1:
                continue
            line = lines[j]
            if not line.strip():
                continue
            # bo dong gan lai chinh bien do tu mot nguon khac
            for kind_use, pat in pats:
                m = pat.search(line)
                if not m:
                    continue
                cls = tbl.get(kind_use)
                if not cls:
                    continue
                if kind_use == "field" and t["kind"] == "nullobj":
                    # v.f la HAM: chi nem neu con bi so sanh/tinh toan tiep
                    tail = line[m.end():]
                    if not FIELD_FOLLOWUP.search(tail) and "getn" not in line:
                        continue
                if guard_absorbs:
                    # co phep canh nil nao giua cho nhiem va cho dung khong?
                    span = lines[t["line"] - 1:j + 1]
                    if any(gre.search(s) for s in span):
                        continue
                same_func = owner[j] == t["func"]
                findings.append({
                    "line": j + 1,
                    "text": raw[j].strip()[:200] if j < len(raw) else "",
                    "use": kind_use,
                    "class": cls,
                    "var": t["name"],
                    "kind": t["kind"],
                    "call": t["call"],
                    "spec": t["spec"],
                    "origin": t["origin"],
                    "taint_line": t["line"],
                    "taint_func": t["func"],
                    "use_func": owner[j],
                    "confidence": "high" if same_func else "med",
                })
                break

    # `R:N().field` truc tiep, khong qua bien
    for i, line in enumerate(lines):
        for m in DIRECT_FIELD_RE.finditer(line):
            recv = m.group("recv") or "_G"
            key = (recv, m.group("fn"))
            if key not in stubs or key in implemented:
                continue
            kind = kind_for(stubs[key][0]) if stubs[key] else "nullobj"
            if kind not in ("nullobj", "emptytable"):
                continue
            tail = line[m.end():]
            if not FIELD_FOLLOWUP.search(tail):
                continue
            findings.append({
                "line": i + 1,
                "text": raw[i].strip()[:200] if i < len(raw) else "",
                "use": "direct-field",
                "class": "N1" if kind == "nullobj" else "N3",
                "var": "(truc tiep)",
                "kind": kind,
                "call": "%s:%s" % (recv, m.group("fn")),
                "spec": stubs[key],
                "origin": "goi thang roi doc truong",
                "taint_line": i + 1,
                "taint_func": owner[i],
                "use_func": owner[i],
                "confidence": "high",
            })

    # go trung: mot dong chi tinh mot lan, giu ban ghi tin cay nhat
    best = {}
    for f in findings:
        k = f["line"]
        if k not in best or (best[k]["confidence"] == "med" and f["confidence"] == "high"):
            best[k] = f
    out = sorted(best.values(), key=lambda x: x["line"])
    for f in out:
        f["file"] = rel
    return out


def scan_tree(root, stubs, implemented, max_span):
    hits = []
    files = 0
    for dirpath, _d, fnames in os.walk(root):
        for fn in fnames:
            if not fn.lower().endswith(".lua"):
                continue
            path = os.path.join(dirpath, fn)
            files += 1
            rel = os.path.relpath(path, root).replace("\\", "/")
            for f in scan_file(path, rel, stubs, implemented, max_span):
                f["frame"] = rel.split("/")[0]
                hits.append(f)
    return hits, files


# ------------------------------------------------------------------ self test

SELFTEST_LUA = {
    # ban sao that cua SelfEquip: nullobj lam GIA TRI, dung o HAM KHAC
    "N2/N2.lua": """
local LEVEL_MAX_ENABLE = 129
function A_OnUpdate()
\tif( LEVEL_MAX_ENABLE <= nCompatPKLevel ) then
\t\tX:Disable()
\tend
\tY:SetText("ok")
end
function A_OnShow()
\tLEVEL_MAX_ENABLE = Lua_GetMyMaxLevelLimit();
end
""",
    # ban sao that cua SelfEquip:1465: nullobj lam BAN GHI
    "N1/N1.lua": """
function B_OnUpdate()
\tlocal cur = WGAch:GetCJMaxCur()
\tif cur ~= nil and cur.cur_level >= 1 then
\t\tZ:SetText("x")
\tend
end
""",
    # ban sao that cua Friend.lua:854: thieu gia tri tra ve
    "N4/N4.lua": """
function C_Show()
\tlocal level, sunNum, moonNum, starNum = DataPool:GetIMIconNum(1)
\tif sunNum + moonNum + starNum <= 7 then
\t\tW:Show()
\tend
end
""",
    # DOI CHUNG AM: stub tra so that -> KHONG duoc bao
    "OK/OK.lua": """
function D_Show()
\tlocal n = Pet:GetAIType_PetBank()
\tif n >= 1 then
\t\tV:Show()
\tend
end
""",
    # DOI CHUNG AM: ban sao that cua PlayerFrame.lua:758-762 — script CO phep canh nil,
    # ma voi N4 thi phep canh do CHAY DUNG => KHONG duoc bao
    "GUARD/GUARD.lua": """
function F_Update()
\tlocal nOpenDate, nDayCount = Lua_Get2606SOpenDayCount()
\tif nOpenDate ~= nil and nDayCount ~= nil then
\t\tif nDayCount < 7 then
\t\t\tT:Show()
\t\tend
\tend
end
""",
    # DOI CHUNG AM: ham DA CO HOST THAT -> KHONG duoc bao
    "OKHOST/OKHOST.lua": """
function E_Show()
\tlocal cur = WGAch:GetCJMaxCur()
\tif cur.cur_level >= 1 then
\t\tU:Show()
\tend
end
""",
}

SELFTEST_STUBS = {
    ("_G", "Lua_GetMyMaxLevelLimit"): "o",
    ("_G", "Lua_Get2606SOpenDayCount"): "n",
    ("WGAch", "GetCJMaxCur"): "o",
    ("DataPool", "GetIMIconNum"): "n",
    ("Pet", "GetAIType_PetBank"): "n",
}


def self_test(tmp):
    import shutil
    root = os.path.join(tmp, "uiframes_selftest")
    if os.path.isdir(root):
        shutil.rmtree(root)
    for rel, body in SELFTEST_LUA.items():
        p = os.path.join(root, rel.replace("/", os.sep))
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as fh:
            fh.write(body.encode("utf-8"))

    ok = True

    def check(label, cond, detail=""):
        nonlocal ok
        print(("PASS " if cond else "FAIL ") + label + ("  " + detail if detail else ""))
        if not cond:
            ok = False

    # 1) DOI CHUNG AM TRUOC: khong ho tro host nao -> phai BAT duoc ca 3 lop
    hits, _ = scan_tree(root, SELFTEST_STUBS, set(), 400)
    by_frame = defaultdict(list)
    for h in hits:
        by_frame[h["frame"]].append(h)
    check("baseline_N2_nullobj_as_value_detected",
          any(h["class"] == "N2" and h["line"] == 4 for h in by_frame["N2"]),
          "(SelfEquip:1480 pattern)")
    check("baseline_N1_nullobj_as_record_detected",
          any(h["class"] == "N1" for h in by_frame["N1"]),
          "(SelfEquip:1465 pattern)")
    check("baseline_N4_arity_short_detected",
          any(h["class"] == "N4" for h in by_frame["N4"]),
          "(Friend:854 pattern)")
    # 2) khong bao oan tren stub tra so that
    check("no_false_positive_on_real_number_stub", not by_frame["OK"],
          "(%d hit)" % len(by_frame["OK"]))
    # 2b) N4 CO phep canh nil -> phai IM (doi chung PlayerFrame.lua:762)
    check("nil_guard_suppresses_N4", not by_frame["GUARD"],
          "(%d hit)" % len(by_frame["GUARD"]))
    # 2c) nhung N4 KHONG canh van phai duoc giu (doi chung Friend/friend.lua:854)
    check("unguarded_N4_survives_the_filter",
          any(h["class"] == "N4" for h in by_frame["N4"]))
    # 2d) phep canh nil KHONG duoc lam cam lop nullobj (N1/N2): `~= nil` la DUNG voi null object
    check("nil_guard_does_NOT_suppress_nullobject",
          any(h["class"] == "N1" for h in by_frame["N1"]),
          "(SelfEquip:1465 CO `cur ~= nil` ma van nem)")
    # 3) khi ham DA CO host that -> phep quet phai IM
    hits2, _ = scan_tree(root, SELFTEST_STUBS, {("WGAch", "GetCJMaxCur")}, 400)
    f2 = defaultdict(list)
    for h in hits2:
        f2[h["frame"]].append(h)
    check("implemented_host_silences_the_scan", not f2["OKHOST"] and not f2["N1"],
          "(%d hit)" % (len(f2["OKHOST"]) + len(f2["N1"])))
    # 4) bo quet phai BIET TRUOT: neu bo bang THROWS thi khong con hit nao
    saved = dict(THROWS)
    THROWS.clear()
    hits3, _ = scan_tree(root, SELFTEST_STUBS, set(), 400)
    THROWS.update(saved)
    check("scan_can_fail_when_rules_removed",
          len([h for h in hits3 if h["use"] != "direct-field"]) == 0)
    shutil.rmtree(root, ignore_errors=True)
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luaapigen-src")
    ap.add_argument("--interface-root")
    ap.add_argument("--out")
    ap.add_argument("--max-span", type=int, default=120,
                    help="so dong toi da tim cho DUNG sau mot bien local bi nhiem")
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--assume-no-hosts", action="store_true",
                    help="doi chung duong: bo qua cac host that da cai, de chung minh phep "
                         "quet BAT DUOC nhung site da do duoc trong log truoc khi vá")
    args = ap.parse_args()

    if args.self_test:
        import tempfile
        print("DINH NGHIA DEM: 1 'site' = 1 DONG Lua se nem. 1 'khung' = thu muc cap 1 duoi InterfaceFolder.")
        sys.exit(0 if self_test(tempfile.gettempdir()) else 1)

    if not (args.luaapigen_src and args.interface_root and args.out):
        ap.error("can --luaapigen-src, --interface-root, --out")

    stubs, implemented = load_stubs(args.luaapigen_src)
    if args.assume_no_hosts:
        implemented = set()
    hits, files = scan_tree(args.interface_root, stubs, implemented, args.max_span)

    nullobj_n = sum(1 for k, v in stubs.items()
                    if v and any(kind_for(c) == "nullobj" for c in v) and k not in implemented)

    by_frame = defaultdict(lambda: defaultdict(int))
    by_class = defaultdict(int)
    by_func = defaultdict(lambda: defaultdict(set))
    for h in hits:
        by_frame[h["frame"]][h["class"]] += 1
        by_class[h["class"]] += 1
        by_func[h["call"]]["frames"].add(h["frame"])

    frames = sorted(by_frame)
    out = {
        "counting_definition": "1 site = 1 dong Lua se NEM; 1 khung = thu muc cap 1 duoi InterfaceFolder",
        "luaapigen_src": args.luaapigen_src,
        "interface_root": args.interface_root,
        "max_span": args.max_span,
        "stubs_total": len(stubs),
        "stubs_with_nullobject_return_still_stubbed": nullobj_n,
        "host_functions_implemented": sorted("%s:%s" % k for k in implemented),
        "lua_files_scanned": files,
        "sites_total": len(hits),
        "sites_by_class": dict(by_class),
        "frames_affected_count": len(frames),
        "frames": {f: dict(by_frame[f]) for f in frames},
        "functions_involved": {
            fn: sorted(v["frames"]) for fn, v in sorted(by_func.items())
        },
        "hits": hits,
    }
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=1)
    print("sites=%d frames=%d -> %s" % (len(hits), len(frames), args.out))


if __name__ == "__main__":
    main()
