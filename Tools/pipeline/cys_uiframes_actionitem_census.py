#!/usr/bin/env python3
# CYS-UIFRAMES: dem TOAN BO phia goi cua DataPool:CreateActionItemForShow /
# CreateBindActionItemForShow de suy ra CHU KY DUNG, thay vi doan mot chu ky tien.
#
# Vi sao phai dem het chu khong lay mau: `selfequip-fit` sap HAI lan lien tiep tren
# dung cau hoi nay (ban dau tra null object -> nem o 1465; ban sau tra bang -> nem o
# 1480). Ca hai lan deu vi doc THIEU phia goi. O day co 1.025 loi goi nen phai do
# bang may: dem so GIA TRI TRA VE moi cho nhan, va toan bo be mat PHUONG THUC duoc
# goi tren doi tuong tra ve.
#
# Ket qua LUON ghi ra JSON (--out). Co --self-test (doi chung am bat buoc).

import argparse
import json
import os
import re
import sys
from collections import Counter, defaultdict

FN = r"(?:CreateActionItemForShow|CreateBindActionItemForShow)"

# local a, b = DataPool:CreateActionItemForShow(...)
ASSIGN = re.compile(
    r"(?P<local>\blocal\s+)?(?P<lhs>[A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*=\s*"
    r"(?P<recv>[A-Za-z_]\w*)\s*:\s*(?P<fn>%s)\s*\((?P<args>[^()]*(?:\([^()]*\)[^()]*)*)\)" % FN
)
# dung thang, khong gan vao bien: DataPool:CreateActionItemForShow(x):GetID()
BARE = re.compile(r"(?P<recv>[A-Za-z_]\w*)\s*:\s*(?P<fn>%s)\s*\(" % FN)

FUNC_RE = re.compile(r"^\s*(?:local\s+)?function\s+([\w.:]+)?")


def strip_comments(text):
    out = []
    for line in text.split("\n"):
        i = line.find("--")
        out.append(line if i < 0 else line[:i] + " " * (len(line) - i))
    return "\n".join(out)


def split_args(s):
    """Tach doi so o muc ngoac cap 0."""
    parts, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur.strip())
    return parts


def scan(root, span):
    sites = []
    for dirpath, _d, fnames in os.walk(root):
        for fn in fnames:
            if not fn.lower().endswith(".lua"):
                continue
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, root).replace("\\", "/")
            with open(path, "rb") as fh:
                raw = fh.read().decode("utf-8", errors="replace")
            text = strip_comments(raw)
            lines = text.split("\n")
            owner, cur = [], "<file>"
            for line in lines:
                m = FUNC_RE.match(line)
                if m:
                    cur = m.group(1) or "<anon>"
                owner.append(cur)

            seen_lines = set()
            for i, line in enumerate(lines):
                for m in ASSIGN.finditer(line):
                    seen_lines.add(i)
                    names = [x.strip() for x in m.group("lhs").split(",")]
                    var = names[0]
                    methods, guards, plain = [], [], []
                    vre = re.compile(r"\b%s\s*:\s*([A-Za-z_]\w*)" % re.escape(var))
                    gre = re.compile(
                        r"\b%s\s*(?:~=|==)\s*nil\b|\bif\s+not\s+%s\b|\bif\s*\(?\s*%s\s*\)?\s+then\b"
                        % tuple([re.escape(var)] * 3))
                    pre = re.compile(r"\b%s\b\s*(?![:.])" % re.escape(var))
                    for j in range(i, min(i + span, len(lines))):
                        if owner[j] != owner[i]:
                            break
                        methods += vre.findall(lines[j])
                        if gre.search(lines[j]):
                            guards.append(j + 1)
                        if j > i and pre.search(lines[j]) and not vre.search(lines[j]):
                            plain.append(lines[j].strip()[:90])
                    # DANG PHEP CANH — quyet dinh KIEU TRA VE, nen phai dem chu khong doan.
                    # CY dung hai kieu canh khac han nhau:
                    #   `theAction:GetID() ~= 0`  (y tuong goc cua CY: doi tuong LUON co that,
                    #                              GetID()==0 nghia la khong co vat pham)
                    #   `theAction ~= nil`        (canh kieu nil)
                    # Neu tra `nil` thi kieu thu nhat VA cho khong canh deu nem ngay.
                    gid = re.compile(r"\b%s\s*:\s*GetID\s*\(\s*\)\s*(?:~=|==|<|>)" % re.escape(var))
                    guard_kind = "none"
                    for j in range(i, min(i + span, len(lines))):
                        if owner[j] != owner[i]:
                            break
                        if gid.search(lines[j]):
                            guard_kind = "GetID()~=0"
                            break
                        if gre.search(lines[j]):
                            guard_kind = "~=nil"
                            break
                    sites.append({
                        "file": rel, "frame": rel.split("/")[0], "line": i + 1,
                        "fn": m.group("fn"), "func": owner[i],
                        "guard_kind": guard_kind,
                        "nret_taken": len(names), "lhs": names,
                        "nargs": len(split_args(m.group("args"))),
                        "args": split_args(m.group("args"))[:4],
                        "methods": methods, "guards": guards,
                        "used_without_method": plain[:3],
                    })
                for m in BARE.finditer(line):
                    if i in seen_lines:
                        continue
                    sites.append({
                        "file": rel, "frame": rel.split("/")[0], "line": i + 1,
                        "fn": m.group("fn"), "func": owner[i],
                        "nret_taken": 0, "lhs": [], "nargs": None, "args": [],
                        "methods": re.findall(r"\)\s*:\s*([A-Za-z_]\w*)", line),
                        "guards": [], "used_without_method": [],
                        "bare": True,
                    })
    return sites


SELF = {
    "F1/f1.lua": """
function A()
\tlocal theAction = DataPool:CreateActionItemForShow(item, 1)
\tif theAction:GetID() ~= 0 then
\t\tX:SetActionItem(theAction:GetID())
\t\tY:SetText(theAction:GetName())
\tend
end
""",
    "F2/f2.lua": """
function B()
\tlocal act, bind = DataPool:CreateBindActionItemForShow(a, b, c)
\tif act ~= nil then
\t\tZ:SetActionItem(act:GetID())
\tend
end
""",
}


def self_test(tmp):
    import shutil
    root = os.path.join(tmp, "ai_census_selftest")
    if os.path.isdir(root):
        shutil.rmtree(root)
    for rel, body in SELF.items():
        p = os.path.join(root, rel.replace("/", os.sep))
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, "wb").write(body.encode("utf-8"))
    s = scan(root, 40)
    ok = True

    def check(label, cond, detail=""):
        nonlocal ok
        print(("PASS " if cond else "FAIL ") + label + ("  " + detail if detail else ""))
        if not cond:
            ok = False

    check("finds_both_functions", len(s) == 2, "(%d)" % len(s))
    a = [x for x in s if x["fn"] == "CreateActionItemForShow"][0]
    b = [x for x in s if x["fn"] == "CreateBindActionItemForShow"][0]
    check("counts_return_values_taken", a["nret_taken"] == 1 and b["nret_taken"] == 2,
          "(%d, %d)" % (a["nret_taken"], b["nret_taken"]))
    check("collects_method_surface",
          set(a["methods"]) == {"GetID", "GetName"}, "(%s)" % sorted(set(a["methods"])))
    check("counts_arguments", a["nargs"] == 2 and b["nargs"] == 3,
          "(%d, %d)" % (a["nargs"], b["nargs"]))
    check("detects_nil_guard", bool(b["guards"]) and not a["guards"],
          "(a co canh nil? %s)" % bool(a["guards"]))
    check("classifies_guard_form",
          a["guard_kind"] == "GetID()~=0" and b["guard_kind"] == "~=nil",
          "(%s, %s)" % (a["guard_kind"], b["guard_kind"]))
    # biet truot
    saved = ASSIGN.pattern
    globals()["ASSIGN"] = re.compile(r"(?!x)x")
    blind = scan(root, 40)
    globals()["ASSIGN"] = re.compile(saved)
    check("scan_can_fail_when_pattern_broken",
          all(x.get("bare") for x in blind))
    shutil.rmtree(root, ignore_errors=True)
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--interface-root")
    ap.add_argument("--out")
    ap.add_argument("--span", type=int, default=40)
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        import tempfile
        print("DINH NGHIA DEM: 1 'cho goi' = 1 DONG Lua goi mot trong hai ham. "
              "'nret_taken' = so bien o ve trai. 'methods' = phuong thuc goi tren "
              "gia tri tra ve, trong cung mot ham Lua.")
        sys.exit(0 if self_test(tempfile.gettempdir()) else 1)
    if not (a.interface_root and a.out):
        ap.error("can --interface-root --out")
    sites = scan(a.interface_root, a.span)
    meth = Counter(m for s in sites for m in s["methods"])
    out = {
        "counting_definition": "1 cho goi = 1 dong Lua goi mot trong hai ham; "
                               "nret_taken = so bien ve trai; methods = phuong thuc "
                               "goi tren gia tri tra ve trong CUNG ham Lua",
        "interface_root": a.interface_root, "span_lines": a.span,
        "call_sites": len(sites),
        "frames": len({s["frame"] for s in sites}),
        "by_function": dict(Counter(s["fn"] for s in sites)),
        "return_values_taken": dict(Counter(s["nret_taken"] for s in sites)),
        "argument_counts": dict(Counter(s["nargs"] for s in sites if s["nargs"] is not None)),
        "method_surface": dict(meth.most_common()),
        "method_surface_size": len(meth),
        "sites_with_nil_guard": sum(1 for s in sites if s["guards"]),
        "guard_forms": dict(Counter(s.get("guard_kind", "none") for s in sites)),
        "sites_with_no_method_call": sum(1 for s in sites if not s["methods"]),
        "sites_value_used_bare": sum(1 for s in sites if s["used_without_method"]),
        "sites": sites,
    }
    json.dump(out, open(a.out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("cho goi=%d khung=%d phuong thuc khac nhau=%d -> %s"
          % (len(sites), out["frames"], len(meth), a.out))


if __name__ == "__main__":
    main()
