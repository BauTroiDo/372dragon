# -*- coding: utf-8 -*-
"""fx-audit sheet harness: deterministic renders of effect lists with TlbbViewer --fx-sheet, labelled contact sheets,
per-effect cost, repeatability check.

For every item of a list (Tests/fx/audit/lists/*.tsv, "id<TAB>effect|particle|model<TAB>name[<TAB>anim]") the viewer
renders captures at t = 0.15, 0.4, 0.8, 1.5, 3 s (fixed dt 1/60 s, srand(seed) before each item) on black and mid-grey,
with the camera fitted to the union of the item bounds at those times. This script then builds
  <out>/sheets/<id>.png      one labelled contact sheet per item (rows = backgrounds, columns = times)
  <out>/overview-<bg>.png    all items at t = 0.8 s on one page (quick scan)
  <out>/sheet-index.tsv      items with cost at t = 1 s (particles, draw calls, CPU update / render / GPU ms, material
                             and texture count deltas) and simple image statistics (coverage, mean luma)
and optionally compares two runs pixel by pixel (SSIM, identical-byte PNG count).

Usage
  py -3 Tools/fx/fx_sheet.py --set stage --list oracle            # render + sheets
  py -3 Tools/fx/fx_sheet.py --set stage --list oracle --repeat   # render twice, SSIM of every capture
  py -3 Tools/fx/fx_sheet.py --compare <runA> <runB>              # SSIM between two existing runs
  py -3 Tools/fx/fx_sheet.py --sheets-only <run dir>              # rebuild sheets of an existing run
Crashes of the viewer are resumed after the crashing item (recorded as 'crash').
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
import subprocess
import sys
import time

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
VIEWER = os.path.join(ROOT, r"Build\cmake\fxaudit-x64\run-b3\TlbbViewer.exe")
LISTS = os.path.join(ROOT, r"Tests\fx\audit\lists")
OUT = os.path.join(ROOT, r"Build\Logs\2026-09-13-fx-audit\sheets")
FONT = os.path.join(ROOT, "NotoSansSC-Regular.ttf")
SETS = {
    "stage": os.path.join(ROOT, r"Build\gpt-p1-1-20260913\stage-91148e1\Data"),
    "canonical": os.path.join(ROOT, r"Assets\Canonical\Data"),
    "s2": os.path.normpath(os.path.join(ROOT, r"..\Tools\DATA NEW\DataCY31-08-26")),
    "canonicalcy": os.path.join(ROOT, r"Assets\CanonicalCY\Data"),   # CYS-FX: CY 3.71.9609 staged (fx-cy 14/09)
}
TIMES = "0.15,0.4,0.8,1.5,3"
SEED = 1234


def read_tsv(path):
    if not os.path.exists(path):
        return []
    with open(path, "rb") as f:
        lines = f.read().split(b"\n")
    header = lines[0].rstrip(b"\r").decode().split("\t")
    rows = []
    for l in lines[1:]:
        l = l.rstrip(b"\r")
        if not l:
            continue
        cols = [c.decode("gbk", "replace") for c in l.split(b"\t")]
        rows.append(dict(zip(header, cols + [""] * (len(header) - len(cols)))))
    return rows


def read_list(path):
    items = []
    with open(path, encoding="utf-8-sig") as f:
        for line in f:
            line = line.rstrip("\r\n")
            if not line or line.startswith("#"):
                continue
            items.append(line.split("\t"))
    return items


# --------------------------------------------------------------------------------------------------- render
def render(viewer, data, list_path, out, size, seed, times, bgs, cache, log, extra=None):
    """Runs the viewer; resumes after a crash with the remaining items. Returns seconds."""
    os.makedirs(out, exist_ok=True)
    items = read_list(list_path)
    done_ids = set()
    t0 = time.time()
    attempt = 0
    while True:
        attempt += 1
        remaining = [it for it in items if it[0] not in done_ids]
        if not remaining:
            break
        part = os.path.join(out, "list-part%d.tsv" % attempt)
        with open(part, "w", encoding="utf-8", newline="\n") as f:
            for it in remaining:
                f.write("\t".join(it) + "\n")
        sub = out if attempt == 1 else os.path.join(out, "part%d" % attempt)
        cmd = [viewer, "--data", data, "--fx-sheet", part, "--out", sub, "--size", size, "--seed", str(seed),
               "--times", times, "--bgs", bgs, "--shader-cache", cache, "--orbit", "30,30"]
        if extra:
            cmd += extra
        p = subprocess.run(cmd, cwd=os.path.dirname(viewer), capture_output=True)
        log.write("attempt %d exit %d: %s\n" % (attempt, p.returncode, " ".join(cmd)))
        log.write(p.stdout.decode("utf-8", "replace")[-4000:] + "\n" + p.stderr.decode("utf-8", "replace")[-4000:] + "\n")
        log.flush()
        rows = read_tsv(os.path.join(sub, "items.tsv"))
        ids = [r["id"] for r in rows]
        done_ids.update(ids)
        if p.returncode == 0 and len(ids) >= len(remaining):
            break
        # crash / abort: the first item without a row is the culprit
        culprit = next((it for it in remaining if it[0] not in done_ids), None)
        if culprit is None:
            break
        done_ids.add(culprit[0])
        with open(os.path.join(out, "crashes.tsv"), "a", encoding="utf-8") as f:
            f.write("%s\t%s\t%s\texit %d\n" % (culprit[0], culprit[1], culprit[2], p.returncode))
        if attempt > 40:
            break
    merge_parts(out)
    return time.time() - t0


def merge_parts(out):
    """Folds part<N>/ outputs (after crashes) into the main files and folders."""
    parts = sorted(d for d in os.listdir(out) if d.startswith("part") and os.path.isdir(os.path.join(out, d)))
    for d in parts:
        src = os.path.join(out, d)
        for name in ("items.tsv", "captures.tsv", "metrics.tsv"):
            p = os.path.join(src, name)
            if not os.path.exists(p):
                continue
            with open(p, "rb") as f:
                lines = f.read().split(b"\n")[1:]
            with open(os.path.join(out, name), "ab") as f:
                for l in lines:
                    if l.strip():
                        f.write(l + b"\n")
        for sub in os.listdir(src):
            sp = os.path.join(src, sub)
            if os.path.isdir(sp):
                dst = os.path.join(out, sub)
                if not os.path.exists(dst):
                    os.replace(sp, dst)


# --------------------------------------------------------------------------------------------------- images
def load_rgb(path):
    with Image.open(path) as im:
        return np.asarray(im.convert("RGB"), dtype=np.float64)


def ssim(a, b):
    """Mean SSIM over RGB (Wang et al. 2004, 7x7 uniform window, K1 .01, K2 .03, L 255)."""
    from numpy.lib.stride_tricks import sliding_window_view as win
    c1, c2 = (0.01 * 255) ** 2, (0.03 * 255) ** 2
    vals = []
    for ch in range(3):
        x, y = a[..., ch], b[..., ch]
        if np.array_equal(x, y):
            vals.append(1.0)
            continue
        wx, wy = win(x, (7, 7)), win(y, (7, 7))
        mx, my = wx.mean(axis=(-1, -2)), wy.mean(axis=(-1, -2))
        vx, vy = wx.var(axis=(-1, -2)), wy.var(axis=(-1, -2))
        cxy = (wx * wy).mean(axis=(-1, -2)) - mx * my
        s = ((2 * mx * my + c1) * (2 * cxy + c2)) / ((mx * mx + my * my + c1) * (vx + vy + c2))
        vals.append(float(s.mean()))
    return float(np.mean(vals))


def image_stats(path, bg):
    """coverage = share of pixels differing from the background by > 8 (luma); mean luma of those pixels."""
    a = load_rgb(path)
    luma = a @ np.array([0.2126, 0.7152, 0.0722])
    bl = {"black": 0.0, "grey": 127.5, "white": 255.0}.get(bg, float(np.median(luma)))
    mask = np.abs(luma - bl) > 8
    cov = float(mask.mean())
    mean = float(luma[mask].mean()) if mask.any() else 0.0
    sat = float((a.max(axis=2) >= 250).mean())
    return cov, mean, sat


def font(size):
    try:
        return ImageFont.truetype(FONT, size)
    except OSError:
        return ImageFont.load_default()


def build_sheets(run, title=""):
    items = read_tsv(os.path.join(run, "items.tsv"))
    caps = read_tsv(os.path.join(run, "captures.tsv"))
    mets = {m["id"]: m for m in read_tsv(os.path.join(run, "metrics.tsv"))}
    by_id = {}
    for c in caps:
        by_id.setdefault(c["id"], []).append(c)
    sheets = os.path.join(run, "sheets")
    os.makedirs(sheets, exist_ok=True)
    f_title, f_small = font(22), font(15)
    index = []
    overview = {}
    for it in items:
        iid = it["id"]
        cs = by_id.get(iid, [])
        m = mets.get(iid, {})
        row = {"id": iid, "kind": it["kind"], "name": it["name"], "status": it["status"]}
        for k in ("particles_max_t1", "draws_t1", "update_ms_t1", "render_ms_t1", "gpu_ms_t1", "systems_t1",
                  "quota_t1", "materials_start", "materials_end", "textures_start", "textures_end", "fit_distance",
                  "alive_end", "elements"):
            row[k] = m.get(k, "")
        if not cs:
            index.append(row)
            continue
        bgs = []
        times = []
        for c in cs:
            if c["bg"] not in bgs:
                bgs.append(c["bg"])
            if c["t_req"] not in times:
                times.append(c["t_req"])
        cell = None
        grid = {}
        for c in cs:
            p = os.path.join(run, c["png"])
            if os.path.exists(p):
                im = Image.open(p).convert("RGB")
                cell = cell or im.size
                grid[(c["bg"], c["t_req"])] = (im, c)
        if not cell:
            index.append(row)
            continue
        cw, ch = cell
        scale = 256.0 / max(cw, ch)
        tw, th = int(cw * scale), int(ch * scale)
        head = 64
        W, H = tw * len(times) + 8 * (len(times) + 1), head + (th + 26) * len(bgs) + 8
        sheet = Image.new("RGB", (W, H), (28, 28, 32))
        d = ImageDraw.Draw(sheet)
        d.text((8, 4), "%s  %s  [%s]  %s" % (iid, it["name"], it["kind"], title), fill=(240, 240, 240), font=f_title)
        d.text((8, 36), "particles@1s %s  draws@1s %s  update %s ms  render %s ms  gpu %s ms  materials %s->%s  "
               "textures %s->%s  alive@end %s" % (row["particles_max_t1"], row["draws_t1"], row["update_ms_t1"],
                                                   row["render_ms_t1"], row["gpu_ms_t1"], row["materials_start"],
                                                   row["materials_end"], row["textures_start"], row["textures_end"],
                                                   row["alive_end"]), fill=(200, 200, 160), font=f_small)
        covs = []
        for bi, bg in enumerate(bgs):
            for ti, t in enumerate(times):
                x = 8 + ti * (tw + 8)
                y = head + bi * (th + 26)
                g = grid.get((bg, t))
                if g:
                    im, c = g
                    sheet.paste(im.resize((tw, th), Image.LANCZOS), (x, y))
                    cov, mean, sat = image_stats(os.path.join(run, c["png"]), bg)
                    covs.append((bg, t, cov, mean, sat))
                    d.text((x + 2, y + th + 2), "%s t=%ss p=%s cov=%.1f%%" % (bg, t, c["particles"], cov * 100),
                           fill=(220, 220, 220), font=f_small)
                    if t.startswith("0.8"):
                        overview.setdefault(bg, []).append((iid, it["name"], im))
        sheet.save(os.path.join(sheets, "%s.png" % iid))
        blk = [c for c in covs if c[0] == "black"]
        row["coverage_black_max"] = "%.4f" % max((c[2] for c in blk), default=0.0)
        row["coverage_black_t0.8"] = "%.4f" % next((c[2] for c in blk if c[1].startswith("0.8")), 0.0)
        row["saturated_black_max"] = "%.4f" % max((c[4] for c in blk), default=0.0)
        gry = [c for c in covs if c[0] == "grey"]
        row["coverage_grey_max"] = "%.4f" % max((c[2] for c in gry), default=0.0)
        index.append(row)
    # overview pages
    for bg, cells in overview.items():
        n = len(cells)
        cols = 10
        rows = (n + cols - 1) // cols
        cw = 192
        page = Image.new("RGB", (cols * (cw + 4) + 4, rows * (cw + 22) + 4), (20, 20, 24))
        d = ImageDraw.Draw(page)
        for i, (iid, name, im) in enumerate(cells):
            x = 4 + (i % cols) * (cw + 4)
            y = 4 + (i // cols) * (cw + 22)
            page.paste(im.resize((cw, cw), Image.LANCZOS), (x, y))
            d.text((x + 2, y + cw + 2), ("%s %s" % (iid, name))[:26], fill=(230, 230, 230), font=font(13))
        page.save(os.path.join(run, "overview-%s.png" % bg))
    keys = ["id", "kind", "name", "status", "particles_max_t1", "draws_t1", "update_ms_t1", "render_ms_t1",
            "gpu_ms_t1", "systems_t1", "quota_t1", "materials_start", "materials_end", "textures_start",
            "textures_end", "fit_distance", "alive_end", "elements", "coverage_black_max", "coverage_black_t0.8",
            "saturated_black_max", "coverage_grey_max"]
    with open(os.path.join(run, "sheet-index.tsv"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\t".join(keys) + "\n")
        for r in index:
            f.write("\t".join(str(r.get(k, "")) for k in keys) + "\n")
    return index


# --------------------------------------------------------------------------------------------------- compare
def compare(run_a, run_b, out_json=None):
    ca = {(c["id"], c["bg"], c["t_req"]): c for c in read_tsv(os.path.join(run_a, "captures.tsv"))}
    cb = {(c["id"], c["bg"], c["t_req"]): c for c in read_tsv(os.path.join(run_b, "captures.tsv"))}
    res = {"pairs": 0, "identical_bytes": 0, "identical_pixels": 0, "ssim_min": 1.0, "worst": [], "missing": 0}
    worst = []
    for k, a in ca.items():
        b = cb.get(k)
        if not b:
            res["missing"] += 1
            continue
        pa, pb = os.path.join(run_a, a["png"]), os.path.join(run_b, b["png"])
        if not (os.path.exists(pa) and os.path.exists(pb)):
            res["missing"] += 1
            continue
        res["pairs"] += 1
        ha = hashlib.sha256(open(pa, "rb").read()).hexdigest()
        hb = hashlib.sha256(open(pb, "rb").read()).hexdigest()
        if ha == hb:
            res["identical_bytes"] += 1
            res["identical_pixels"] += 1
            continue
        A, B = load_rgb(pa), load_rgb(pb)
        if A.shape == B.shape and np.array_equal(A, B):
            res["identical_pixels"] += 1
            continue
        s = ssim(A, B) if A.shape == B.shape else 0.0
        worst.append((s, "/".join(k)))
        res["ssim_min"] = min(res["ssim_min"], s)
    worst.sort()
    res["worst"] = worst[:20]
    if out_json:
        with open(out_json, "w", encoding="utf-8") as f:
            json.dump(res, f, ensure_ascii=False, indent=1)
    return res


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--set", default="stage")
    ap.add_argument("--data")
    ap.add_argument("--list", default="oracle", help="name in Tests/fx/audit/lists or a path")
    ap.add_argument("--viewer", default=VIEWER)
    ap.add_argument("--out", default=OUT)
    ap.add_argument("--label", default="")
    ap.add_argument("--size", default="512x512")
    ap.add_argument("--seed", type=int, default=SEED)
    ap.add_argument("--times", default=TIMES)
    ap.add_argument("--bgs", default="black,grey")
    ap.add_argument("--turntable", type=float, default=0.0)
    ap.add_argument("--wide-names", action="store_true",
                    help="viewer --wide-names: CJK file names reachable (S2 visual truth, stage 'after D1' preview)")
    ap.add_argument("--cache", help="shader cache folder (default <viewer dir>\\..\\ShaderCache-<set>); "
                                    "repeatability runs must use a warm cache (see 07-fx-audit_vi.md)")
    ap.add_argument("--repeat", action="store_true", help="render twice and compare")
    ap.add_argument("--compare", nargs=2, metavar=("RUN_A", "RUN_B"))
    ap.add_argument("--sheets-only", metavar="RUN")
    a = ap.parse_args()

    if a.compare:
        r = compare(a.compare[0], a.compare[1], os.path.join(a.compare[1], "compare.json"))
        print(json.dumps(r, ensure_ascii=False, indent=1))
        return
    if a.sheets_only:
        idx = build_sheets(a.sheets_only)
        print("sheets: %d items" % len(idx))
        return
    list_path = a.list if os.path.exists(a.list) else os.path.join(LISTS, a.list + ".tsv")
    lname = os.path.splitext(os.path.basename(list_path))[0]
    data = a.data or SETS[a.set]
    cache = a.cache or os.path.normpath(os.path.join(os.path.dirname(a.viewer), "..", "ShaderCache-" + a.set))
    extra = ["--turntable", str(a.turntable)] if a.turntable else []
    if a.wide_names:
        extra.append("--wide-names")
    extra = extra or None
    runs = []
    for rep in range(2 if a.repeat else 1):
        run = os.path.join(a.out, "%s-%s%s%s" % (a.set, lname, ("-" + a.label) if a.label else "",
                                                ("-rep%d" % (rep + 1)) if a.repeat else ""))
        if os.path.exists(os.path.join(run, "items.tsv")):
            for fn in ("items.tsv", "captures.tsv", "metrics.tsv", "crashes.tsv"):
                p = os.path.join(run, fn)
                if os.path.exists(p):
                    os.remove(p)
        os.makedirs(run, exist_ok=True)
        with open(os.path.join(run, "harness.log"), "w", encoding="utf-8") as log:
            sec = render(a.viewer, data, list_path, run, a.size, a.seed, a.times, a.bgs, cache, log, extra)
        idx = build_sheets(run, title="%s / %s" % (a.set, lname))
        print("%s: %d items in %.0f s -> %s" % (run, len(idx), sec, run))
        runs.append(run)
    if len(runs) == 2:
        r = compare(runs[0], runs[1], os.path.join(runs[1], "compare.json"))
        print("repeatability: %d pairs, %d identical bytes, %d identical pixels, SSIM min %.6f"
              % (r["pairs"], r["identical_bytes"], r["identical_pixels"], r["ssim_min"]))


if __name__ == "__main__":
    main()
