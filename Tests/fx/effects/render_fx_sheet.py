#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tests/fx/effects/render_fx_sheet.py - drive TlbbViewer over a fixed list of effects and record the results.

Read-only against Canonical data. Renders, per case, one PNG at a fixed time step, and writes manifest.json with
the per-case exit code, PNG size and a blank/coverage check. Two case kinds:
  weapon <model.obj> <effect> <locator>   sect-preview weapon effect attached to its creation-scene model
  skill  <model.obj> <skill>               a skill (all.skill) played on a model (drives AnimEffect/Ribbon/CameraShake)
  effect <effect>                          a standalone effect at the origin

Usage:
  render_fx_sheet.py --viewer <dir> --out <dir> [--frames N] [--dt S] [--only weapon|skill|effect]
The case list lives in cases.tsv next to this file (kind<TAB>arg1<TAB>arg2<TAB>arg3<TAB>label).
"""
import argparse
import json
import os
import struct
import subprocess
import sys
import time
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DATA = os.path.join(CYS, "Assets", "Canonical", "Data")


def png_info(path):
    """(width, height, coverage) coverage = fraction of non-near-black pixels, from the raw PNG (no PIL)."""
    try:
        with open(path, "rb") as f:
            b = f.read()
    except OSError:
        return None
    if b[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    w = h = 0
    idat = bytearray()
    i = 8
    while i + 8 <= len(b):
        ln = struct.unpack_from(">I", b, i)[0]
        typ = b[i + 4:i + 8]
        data = b[i + 8:i + 8 + ln]
        if typ == b"IHDR":
            w, h = struct.unpack_from(">II", data, 0)
            depth, color = data[8], data[9]
        elif typ == b"IDAT":
            idat += data
        elif typ == b"IEND":
            break
        i += 12 + ln
    cov = None
    try:
        raw = zlib.decompress(bytes(idat))
        ch = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(color, 4)
        stride = w * ch
        nonblack = 0
        total = 0
        prev = bytearray(stride)
        pos = 0
        for _ in range(h):
            if pos >= len(raw):
                break
            filt = raw[pos]
            pos += 1
            line = bytearray(raw[pos:pos + stride])
            pos += stride
            # undo the common PNG filters enough for a luma estimate
            if filt == 1:
                for x in range(ch, stride):
                    line[x] = (line[x] + line[x - ch]) & 0xFF
            elif filt == 2:
                for x in range(stride):
                    line[x] = (line[x] + prev[x]) & 0xFF
            elif filt == 3:
                for x in range(stride):
                    a = line[x - ch] if x >= ch else 0
                    line[x] = (line[x] + ((a + prev[x]) >> 1)) & 0xFF
            elif filt == 4:
                for x in range(stride):
                    a = line[x - ch] if x >= ch else 0
                    c = prev[x - ch] if x >= ch else 0
                    p = a + prev[x] - c
                    pa, pb, pc = abs(p - a), abs(p - prev[x]), abs(p - c)
                    pr = a if (pa <= pb and pa <= pc) else (prev[x] if pb <= pc else c)
                    line[x] = (line[x] + pr) & 0xFF
            for x in range(0, stride, ch):
                total += 1
                if line[x] > 18 or line[x + 1] > 18 or line[x + 2] > 18:
                    nonblack += 1
            prev = line
        cov = nonblack / total if total else 0.0
    except Exception:
        cov = None
    return {"w": w, "h": h, "coverage": cov, "bytes": len(b)}


def main():
    global DATA  # CYS-FX: --data
    ap = argparse.ArgumentParser()
    ap.add_argument("--viewer", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--frames", type=int, default=45)
    ap.add_argument("--dt", default="0.03333")
    ap.add_argument("--size", default="640x640")
    ap.add_argument("--only", default="")
    ap.add_argument("--timeout", type=int, default=150)
    ap.add_argument("--scale", default="")  # CYS: fx-effects --scale <f> for weapon/skill (model) cases
    ap.add_argument("--effect-follow-scale", action="store_true")  # CYS: model effects follow the scale
    ap.add_argument("--data", default=DATA)  # CYS-FX: fx-cy - data folder (e.g. Assets/CanonicalCY/Data)
    ap.add_argument("--cases", default="cases.tsv")  # CYS: case list (kind\targ1..\tlabel), rel to this dir or abs
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    exe = os.path.join(args.viewer, "TlbbViewer.exe")
    cases = []
    cases_path = args.cases if os.path.isabs(args.cases) else os.path.join(HERE, args.cases)
    with open(cases_path, encoding="utf-8") as f:
        for ln in f:
            ln = ln.rstrip("\n")
            if not ln or ln.startswith("#"):
                continue
            p = ln.split("\t")
            cases.append(p)
    DATA = os.path.abspath(args.data)  # CYS-FX
    manifest = {"viewer": exe, "data": DATA, "frames": args.frames, "dt": args.dt, "cases": []}
    for p in cases:
        kind, label = p[0], p[-1]
        if args.only and kind != args.only:
            continue
        shot = os.path.join(args.out, label + ".png")
        log = os.path.join(args.out, label + ".log")
        cmd = [exe, "--data", DATA, "--size", args.size, "--frames", str(args.frames),
               "--dt", args.dt, "--shot", shot, "--log", log]
        if kind == "weapon":
            cmd += ["--model", p[1], "--effect", p[2], "--locator", p[3]]
        elif kind == "skill":
            cmd += ["--model", p[1], "--anim", p[2]]
        elif kind == "effect":
            cmd += ["--effect", p[1]]
        if args.scale and kind in ("weapon", "skill"):  # CYS: fx-effects --scale
            cmd += ["--scale", args.scale]
            if args.effect_follow_scale:
                cmd.append("--effect-follow-scale")
        t0 = time.time()
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace",
                               timeout=args.timeout)  # CYS-FX: viewer stdout carries GBK/UTF-8 names
            rc, out = r.returncode, (r.stdout or "") + (r.stderr or "")
        except subprocess.TimeoutExpired:
            rc, out = -9, "TIMEOUT"
        info = png_info(shot)
        manifest["cases"].append({
            "kind": kind, "label": label, "args": p[1:-1], "rc": rc,
            "seconds": round(time.time() - t0, 2), "png": info,
            "stdout_tail": out.strip().splitlines()[-3:] if out else [],
        })
        cov = info.get("coverage") if info else None
        print("%-22s rc=%-3s %s cov=%s" % (label, rc, (str(info["bytes"]) + "B") if info else "no-png",
                                           ("%.4f" % cov) if cov is not None else "?"))
    with open(os.path.join(args.out, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
    ok = sum(1 for c in manifest["cases"] if c["png"] and c["rc"] == 0)
    print("rendered %d/%d cases with a PNG and rc 0" % (ok, len(manifest["cases"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
