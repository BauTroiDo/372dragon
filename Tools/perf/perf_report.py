#!/usr/bin/env python3
"""CYS-PERF report: statistics of the per-frame CSV written by the CYS_PERF collector.

  perf_report.py FRAMES.csv [--settle S] [--json OUT] [--md OUT] [--title T]
  perf_report.py --table RUN_DIR [RUN_DIR ...] [--md OUT] [--only-settled]

A segment starts at every "#mark" row (procedure change, hold end, scene built, ...). For each segment the
report gives the frame time distribution (mean, p50, p95, p99, max), hitch counts and the mean of every CPU
phase, GPU time and counter. "settled" repeats the distribution without the first S seconds of the segment
(default 2 s), which is where loading work of the new state lands.

Percentiles use the same nearest-rank rule as the in-game collector: sorted[round(q * (n - 1))].
"""
import argparse
import json
import os
import sys

HITCH_THRESHOLDS = (33.4, 50.0, 100.0)


def percentile(values, q):
    if not values:
        return 0.0
    ordered = sorted(values)
    k = int(q * (len(ordered) - 1) + 0.5)
    return ordered[min(k, len(ordered) - 1)]


def load(path):
    """Returns (header, rows, marks). Rows are dicts of floats (None for empty cells)."""
    header, rows, marks = None, [], []
    with open(path, encoding="utf-8", errors="replace", newline="") as handle:
        for raw in handle:
            line = raw.rstrip("\r\n")
            if not line:
                continue
            if line.startswith("#mark,"):
                parts = line.split(",", 3)
                try:
                    marks.append((int(parts[1]), float(parts[2]), parts[3] if len(parts) > 3 else ""))
                except (ValueError, IndexError):
                    pass
                continue
            if line.startswith("#"):
                continue
            if header is None:
                header = line.split(",")
                continue
            values = line.split(",")
            if len(values) != len(header):
                continue  # truncated last row of a killed process
            try:
                rows.append({k: (float(v) if v != "" else None) for k, v in zip(header, values)})
            except ValueError:
                continue
    if header is None:
        raise ValueError("no CSV header in %s" % path)
    return header, rows, marks


def distribution(frame_ms):
    n = len(frame_ms)
    if not n:
        return {"frames": 0}
    total = sum(frame_ms)
    mean = total / n
    return {
        "frames": n,
        "seconds": round(total / 1000.0, 3),
        "fps": round(1000.0 / mean, 2) if mean > 0 else 0.0,
        "mean": round(mean, 3),
        "p50": round(percentile(frame_ms, 0.50), 3),
        "p95": round(percentile(frame_ms, 0.95), 3),
        "p99": round(percentile(frame_ms, 0.99), 3),
        "max": round(max(frame_ms), 3),
        "hitches": {("gt%g" % t): sum(1 for v in frame_ms if v > t) for t in HITCH_THRESHOLDS},
    }


def means(rows, columns):
    out = {}
    for c in columns:
        values = [r[c] for r in rows if r.get(c) is not None]
        if values:
            out[c] = round(sum(values) / len(values), 4)
    return out


def segment_rows(rows, marks):
    """Splits rows at mark frames. Returns [(label, mark_t_ms, rows)]."""
    ordered = sorted(marks, key=lambda m: (m[0], m[1]))
    bounds = [(0, 0.0, "start")] + [(f, t, label) for f, t, label in ordered]
    out = []
    for i, (frame, t_ms, label) in enumerate(bounds):
        end = bounds[i + 1][0] if i + 1 < len(bounds) else None
        chunk = [r for r in rows if r["frame"] >= frame and (end is None or r["frame"] < end)]
        out.append((label, t_ms, chunk))
    # drop empty leading "start" segment and empty segments created by marks on the same frame
    return [s for s in out if s[2]]


def analyse(path, settle_s=2.0, title=None, drop_last=0, skip_frames=0):
    header, rows, marks = load(path)
    if drop_last > 0:
        rows = rows[:-drop_last]   # e.g. the TlbbViewer --shot frame, which includes the PNG capture
    cpu_cols = [c for c in header if c.startswith("cpu_")]
    gpu_cols = [c for c in header if c.startswith("gpu_")]
    first_counter = header.index("gpu_ui_ms") + 1 if "gpu_ui_ms" in header else len(header)
    counter_cols = header[first_counter:]
    report = {"file": os.path.abspath(path), "title": title or os.path.basename(os.path.dirname(os.path.abspath(path))),
              "settle_s": settle_s, "marks": [{"frame": f, "t_s": round(t / 1000.0, 3), "label": l} for f, t, l in marks],
              "all": distribution([r["frame_ms"] for r in rows]), "segments": []}
    report["skip_frames"] = skip_frames
    for label, mark_t, chunk in segment_rows(rows, marks):
        start_ms = chunk[0]["t_ms"]
        # settled: without the first settle_s seconds AND the first skip_frames frames of the segment (the first
        # frame after a state change or engine start carries first-use work and, at start, the whole init)
        settled = [r for i, r in enumerate(chunk) if r["t_ms"] >= start_ms + settle_s * 1000.0 and i >= skip_frames]
        seg = {
            "label": label,
            "first_frame": int(chunk[0]["frame"]),
            "start_s": round(start_ms / 1000.0, 3),
            "raw": distribution([r["frame_ms"] for r in chunk]),
            "settled": distribution([r["frame_ms"] for r in settled]),
            "cpu_ms": means(settled or chunk, cpu_cols),
            "gpu_ms": means(settled or chunk, gpu_cols),
            "counters": means(settled or chunk, counter_cols),
        }
        report["segments"].append(seg)
    return report


def fmt_dist(d):
    if not d.get("frames"):
        return "| - | - | - | - | - | - | - |"
    h = d["hitches"]
    return "| %d | %.1f | %.2f | %.2f | %.2f | %.1f | %d |" % (
        d["frames"], d["fps"], d["mean"], d["p95"], d["p99"], d["max"], h.get("gt50", 0))


def markdown(report):
    lines = ["# %s" % report["title"], "", "File: `%s`" % report["file"], "",
             "| segment | start s | frames | fps | mean ms | p95 | p99 | max | >50 ms |",
             "|---|---|---|---|---|---|---|---|---|"]
    for seg in report["segments"]:
        d = seg["settled"] if seg["settled"].get("frames") else seg["raw"]
        lines.append("| %s | %.1f %s" % (seg["label"], seg["start_s"], fmt_dist(d)))
    lines += ["", "Settled = without the first %.1f s of each segment." % report["settle_s"], ""]
    for seg in report["segments"]:
        lines.append("## %s (start %.1f s)" % (seg["label"], seg["start_s"]))
        raw = seg["raw"]
        if raw.get("frames"):
            lines.append("raw: frames %d, fps %.1f, mean %.2f, p95 %.2f, p99 %.2f, max %.1f, hitches %s" % (
                raw["frames"], raw["fps"], raw["mean"], raw["p95"], raw["p99"], raw["max"], raw["hitches"]))
        lines.append("cpu ms: " + ", ".join("%s %.2f" % (k[4:-3], v) for k, v in seg["cpu_ms"].items() if v >= 0.01))
        if seg["gpu_ms"]:
            lines.append("gpu ms: " + ", ".join("%s %.2f" % (k[4:-3], v) for k, v in seg["gpu_ms"].items()))
        lines.append("counters/frame: " + ", ".join("%s %.1f" % (k, v) for k, v in seg["counters"].items() if v))
        lines.append("")
    return "\n".join(lines)


def table(run_dirs, only_settled=True):
    lines = ["| run | segment | frames | fps | mean ms | p95 | p99 | max | >50 ms | gpu frame ms | draws |",
             "|---|---|---|---|---|---|---|---|---|---|---|"]
    for run_dir in run_dirs:
        path = os.path.join(run_dir, "report.json")
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as handle:
            report = json.load(handle)
        for seg in report["segments"]:
            d = seg["settled"] if (only_settled and seg["settled"].get("frames")) else seg["raw"]
            gpu = seg["gpu_ms"].get("gpu_frame_ms")
            draws = seg["counters"].get("draws")
            lines.append("| %s | %s %s %s | %s |" % (
                os.path.basename(os.path.normpath(run_dir)), seg["label"], fmt_dist(d),
                ("%.2f" % gpu) if gpu is not None else "-", ("%.0f" % draws) if draws is not None else "-"))
    return "\n".join(lines)


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("inputs", nargs="+", help="frames CSV (or run directories with --table)")
    parser.add_argument("--settle", type=float, default=2.0, help="seconds skipped at the start of each segment")
    parser.add_argument("--json", help="write the report as JSON")
    parser.add_argument("--md", help="write the report as Markdown")
    parser.add_argument("--title")
    parser.add_argument("--table", action="store_true", help="combine report.json of run directories")
    parser.add_argument("--raw", action="store_true", help="with --table: raw instead of settled distributions")
    parser.add_argument("--drop-last", type=int, default=0, help="ignore the last N frames (capture frame)")
    parser.add_argument("--skip-frames", type=int, default=0,
                        help="settled numbers also skip the first N frames of each segment (short viewer runs)")
    args = parser.parse_args(argv)
    if args.table:
        text = table(args.inputs, only_settled=not args.raw)
        if args.md:
            with open(args.md, "w", encoding="utf-8") as handle:
                handle.write(text + "\n")
        print(text)
        return 0
    report = analyse(args.inputs[0], args.settle, args.title, args.drop_last, args.skip_frames)
    if args.json:
        with open(args.json, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=1)
    text = markdown(report)
    if args.md:
        with open(args.md, "w", encoding="utf-8") as handle:
            handle.write(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
