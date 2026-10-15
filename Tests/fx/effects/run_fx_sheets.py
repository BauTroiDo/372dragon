#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""fx-effects: runs fx-audit's sheet harness (Tools/fx/fx_sheet.py render()) with extra viewer arguments such as
--scale 1.5 / --effect-follow-scale, without changing the harness. One run per invocation:

  run_fx_sheets.py --viewer <exe> --set canonical --list <name|path> --label <tag> [--extra "--scale 1.5 ..."]

Output: Build/Logs/2026-09-13-fx-effects/sheets/<set>-<list>-<label>/ (items/captures/metrics.tsv + sheets via
fx_sheet.py --sheets-only). Compare two runs with: py -3 Tools/fx/fx_sheet.py --compare <A> <B>."""
import argparse
import os
import shlex
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "Tools", "fx"))
import fx_sheet  # noqa: E402  (fx-audit harness)

OUT_ROOT = os.path.join(ROOT, r"Build\Logs\2026-09-13-fx-effects\sheets")
LISTS = [os.path.join(HERE, "lists"), os.path.join(ROOT, r"Tests\fx\audit\lists")]


def find_list(name):
    if os.path.exists(name):
        return os.path.abspath(name)
    for d in LISTS:
        p = os.path.join(d, name if name.endswith(".tsv") else name + ".tsv")
        if os.path.exists(p):
            return p
    raise SystemExit("list not found: " + name)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--viewer", required=True)
    ap.add_argument("--set", default="canonical")
    ap.add_argument("--list", required=True)
    ap.add_argument("--label", required=True)
    ap.add_argument("--extra", default="", help="extra viewer arguments, e.g. \"--scale 1.5 --effect-follow-scale\"")
    ap.add_argument("--size", default="512x512")
    a = ap.parse_args()

    list_path = find_list(a.list)
    lname = os.path.splitext(os.path.basename(list_path))[0]
    out = os.path.join(OUT_ROOT, "%s-%s-%s" % (a.set, lname, a.label))
    os.makedirs(out, exist_ok=True)
    cache = os.path.join(ROOT, r"Build\re\fx-effects\ShaderCache-%s" % a.set)
    os.makedirs(cache, exist_ok=True)
    extra = shlex.split(a.extra) if a.extra else None
    with open(os.path.join(out, "render.log"), "a", encoding="utf-8") as log:
        log.write("viewer %s\nextra %s\n" % (a.viewer, extra))
        sec = fx_sheet.render(os.path.abspath(a.viewer), fx_sheet.SETS[a.set], list_path, out, a.size,
                              fx_sheet.SEED, fx_sheet.TIMES, "black,grey", cache, log, extra)
    print("rendered %s in %.0f s" % (out, sec))
    subprocess.run([sys.executable, os.path.join(ROOT, r"Tools\fx\fx_sheet.py"), "--sheets-only", out], check=False)


if __name__ == "__main__":
    main()
