#!/usr/bin/env python3
"""CYS-PERF: one table for a TlbbViewer perf batch (the <case>-<size>.json reports of run_viewer_perf.ps1).

  viewer_table.py RUN_DIR [--md OUT]

Columns come from the settled distribution of the single segment (capture frame excluded by the runner).
"""
import argparse
import glob
import json
import os
import sys


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_dir")
    parser.add_argument("--md")
    args = parser.parse_args(argv)
    runs = json.load(open(os.path.join(args.run_dir, "runs.json"), encoding="utf-8-sig"))
    if isinstance(runs, dict):
        runs = [runs]
    by_name = {}
    for r in runs:
        case = r.get("case", "")
        by_name[(case, r.get("size", ""))] = r
    lines = ["| case | size | frames | fps | mean ms | p95 | p99 | max | >50 ms | gpu ms | draws | prims | allocs/frame | exit |",
             "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for path in sorted(glob.glob(os.path.join(args.run_dir, "*.json"))):
        if os.path.basename(path) == "runs.json":
            continue
        report = json.load(open(path, encoding="utf-8"))
        name = report.get("title", os.path.basename(path)[:-5])
        seg = report["segments"][0] if report["segments"] else None
        if not seg:
            continue
        d = seg["settled"] if seg["settled"].get("frames") else seg["raw"]
        c, g = seg["counters"], seg["gpu_ms"]
        size = name.rsplit("-", 1)[-1]
        case = name[: -(len(size) + 1)]
        exit_code = next((str(r.get("exit_code")) for (k, s), r in by_name.items()
                          if s == size and (k == case or k.endswith(case[5:]) or case.startswith(k[:3]))), "")
        lines.append("| %s | %s | %d | %.0f | %.2f | %.2f | %.2f | %.1f | %d | %.2f | %.0f | %.0f | %.0f | %s |" % (
            case, size, d["frames"], d["fps"], d["mean"], d["p95"], d["p99"], d["max"], d["hitches"]["gt50"],
            g.get("gpu_frame_ms", -1), c.get("draws", 0), c.get("prims", 0), c.get("allocs", 0), exit_code))
    text = "\n".join(lines)
    if args.md:
        with open(args.md, "w", encoding="utf-8") as handle:
            handle.write(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
