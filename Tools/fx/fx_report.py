# -*- coding: utf-8 -*-
"""fx-audit: compact text summary of Registry/fx/census-<set>-summary.json and of sheet runs.

Usage: py -3 Tools/fx/fx_report.py [--sets stage,canonical,s2] [--runs <run dir> ...]
"""
from __future__ import annotations

import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
REG = os.path.join(ROOT, "Registry", "fx")


def census(sets):
    for s in sets:
        p = os.path.join(REG, "census-%s-summary.json" % s)
        if not os.path.exists(p):
            print("== %s: no summary" % s)
            continue
        d = json.load(open(p, encoding="utf-8"))
        print("== %s  (dictionaries: %s)" % (s, os.path.basename(d.get("dictionaries", "?"))))
        print("   static  :", d["static"])
        print("   runtime :", d["runtime"])
        print("   counts  :", d["counts"])
        for k, v in d["by_status"].items():
            print("   %-78s %8d" % (k, v))


def runs(dirs):
    import fx_sheet as F
    for r in dirs:
        idx = F.read_tsv(os.path.join(r, "sheet-index.tsv"))
        st = {}
        for x in idx:
            st[x["status"]] = st.get(x["status"], 0) + 1
        print("== %s: %s" % (os.path.basename(r), st))


def _extent(m):
    try:
        return max(float(m["box_max_x"]) - float(m["box_min_x"]), float(m["box_max_y"]) - float(m["box_min_y"]),
                   float(m["box_max_z"]) - float(m["box_min_z"]))
    except (KeyError, ValueError):
        return 0.0


def item_table(run):
    """id -> dict(status, coverage, saturated, particles, extent, class) for one sheet run (doc 07 §4 rules)."""
    import fx_sheet as F
    idx = {r["id"]: r for r in F.read_tsv(os.path.join(run, "sheet-index.tsv"))}
    met = {r["id"]: r for r in F.read_tsv(os.path.join(run, "metrics.tsv"))}
    out = {}
    for iid, r in idx.items():
        m = met.get(iid, {})
        cov = float(r.get("coverage_black_max") or 0)
        sat = float(r.get("saturated_black_max") or 0)
        p = int(r.get("particles_max_t1") or 0)
        ext = _extent(m)
        if r["status"] != "ok":
            cls = r["status"]
        elif cov < 0.001:
            cls = "no-particles" if p == 0 else ("bounds-blowup" if ext > 5000 else "alive-nothing-drawn")
        elif ext > 5000:
            cls = "visible-bounds-blowup"
        elif sat > 0.02:
            cls = "saturated"
        else:
            cls = "visible"
        out[iid] = {"name": r.get("name", ""), "status": r["status"], "coverage": cov, "saturated": sat,
                    "particles": p, "extent": ext, "class": cls}
    return out


def classify(run):
    t = item_table(run)
    by = {}
    for iid, v in sorted(t.items()):
        by.setdefault(v["class"], []).append(iid)
    print("== %s (%d items)" % (os.path.basename(run.rstrip("\\/")), len(t)))
    for cls, ids in sorted(by.items(), key=lambda kv: -len(kv[1])):
        print("   %-24s %4d  %s" % (cls, len(ids), " ".join(ids[:24])))


def diff(before, after):
    """Per-item change of class / coverage / saturation between two sheet runs of the same list (acceptance)."""
    a, b = item_table(before), item_table(after)
    changed = 0
    common = sorted(set(a) & set(b))
    print("== %s -> %s (%d common items; %d only before, %d only after)" %
          (os.path.basename(before.rstrip("\\/")), os.path.basename(after.rstrip("\\/")), len(common),
           len(set(a) - set(b)), len(set(b) - set(a))))
    for iid in common:
        x, y = a[iid], b[iid]
        if x["class"] != y["class"] or abs(x["coverage"] - y["coverage"]) > 0.02 or \
                abs(x["saturated"] - y["saturated"]) > 0.02:
            changed += 1
            print("   %-6s %-20s -> %-20s cov %.3f -> %.3f  sat %.3f -> %.3f  ext %d -> %d" %
                  (iid, x["class"], y["class"], x["coverage"], y["coverage"], x["saturated"], y["saturated"],
                   x["extent"], y["extent"]))
    print("   %d items changed" % changed)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sets", default="stage,canonical,s2")
    ap.add_argument("--runs", nargs="*", default=[])
    ap.add_argument("--classify", nargs="*", default=[], help="sheet run dirs: class of every item (doc 07 §4)")
    ap.add_argument("--diff", nargs=2, metavar=("BEFORE", "AFTER"), help="per-item change between two runs")
    a = ap.parse_args()
    if a.classify or a.diff:
        for r in a.classify:
            classify(r)
        if a.diff:
            diff(a.diff[0], a.diff[1])
        return
    census([s for s in a.sets.split(",") if s])
    if a.runs:
        runs(a.runs)


if __name__ == "__main__":
    main()
