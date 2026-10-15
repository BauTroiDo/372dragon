#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""red-team: dem cac diem NEM trong ModelSystem — con so ma dieu phoi HOI (muc 22.1)
   ma chua nhanh nao tra loi.

Boi canh: `ef3c2b9e` (fx-cy-baseline) go MOT diem nem trong `LogicModel::delEffect`.
`1eb6858a` (crash-anim) go MOT `TDAssert` trong `CRFObj_Actor::Actor_SetFile`.
Cau hoi con mo: con bao nhieu diem nem nua tren cung duong chay hieu ung/hoat anh?

DINH NGHIA DEM
  diem nem = mot dong chua `OGRE_EXCEPT(`, `TDThrow(`, `TDAssert(`, `throw ` hoac
             `EXCEPT(` trong mot tep .cpp/.h duoi thu muc duoc quet.
  Moi diem duoc gan ten HAM chua no (dong `^[A-Za-z_].*::ten(` gan nhat phia tren).
Khong suy dien "ham nay chay tren duong X" — chi dem va gom nhom, roi de nguoi doc quyet.
"""
import os
import re
import sys
import json
import time
from collections import Counter, defaultdict

ROOTS = [
    r"C:\TLBB\085\CY-Source\Src\Engine\WXCore\ModelSystem",
    r"C:\TLBB\085\CY-Source\Src\Engine\WXRender\Object",
]
PAT = re.compile(r"(OGRE_EXCEPT\s*\(|TDThrow\s*\(|TDAssert\s*\(|\bthrow\b|[A-Z_]+EXCEPT\s*\()")
FUNC = re.compile(r"^[A-Za-z_][\w\s\*&:<>,]*?([A-Za-z_]\w*)::([A-Za-z_~]\w*)\s*\(")


def main():
    out = {"moc_gio_do": time.strftime("%Y-%m-%d %H:%M:%S"), "goc": ROOTS, "theo_tep": {}}
    total = Counter()
    per_func = defaultdict(Counter)
    for root in ROOTS:
        for dirpath, _d, files in os.walk(root):
            for fn in files:
                if not fn.lower().endswith((".cpp", ".h", ".inl")):
                    continue
                p = os.path.join(dirpath, fn)
                with open(p, "rb") as fh:
                    lines = fh.read().decode("utf-8", errors="replace").split("\n")
                cur = "(ngoai ham)"
                hits = []
                for i, l in enumerate(lines, 1):
                    m = FUNC.match(l)
                    if m:
                        cur = "%s::%s" % (m.group(1), m.group(2))
                    s = l.strip()
                    if s.startswith("//") or s.startswith("*"):
                        continue
                    mm = PAT.search(l)
                    if not mm:
                        continue
                    kind = mm.group(1).rstrip("( ").strip()
                    hits.append({"dong": i, "loai": kind, "ham": cur,
                                 "ma": s[:150]})
                    total[kind] += 1
                    per_func[os.path.relpath(p, os.path.dirname(root))][cur] += 1
                if hits:
                    out["theo_tep"][os.path.relpath(p, r"C:\TLBB\085\CY-Source")] = hits
    out["tong_theo_loai"] = dict(total)
    out["tong"] = sum(total.values())
    dest = r"C:\TLBB\085\CY-Source\Build\Logs\2026-09-19-red-team\rt40-throw-census.json"
    with open(dest, "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=1, sort_keys=True)
    print("moc gio do:", out["moc_gio_do"])
    print("tong diem nem:", out["tong"], out["tong_theo_loai"])
    print()
    for f in sorted(out["theo_tep"]):
        hits = out["theo_tep"][f]
        print("%-70s %3d" % (f, len(hits)))
    print("\n== nhom theo HAM, 20 ham nhieu nhat ==")
    c = Counter()
    for f, hits in out["theo_tep"].items():
        for h in hits:
            c[h["ham"]] += 1
    for ham, n in c.most_common(20):
        print("  %3d  %s" % (n, ham))
    print("\nJSON:", dest)


if __name__ == "__main__":
    main()
