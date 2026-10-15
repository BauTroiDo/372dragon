#!/usr/bin/env python3
"""CYS-PERF: before/after table of Game.exe perf runs (report.json of run_game_perf.ps1), one row per state.

  compare_runs.py RUN_DIR [RUN_DIR ...] [--md OUT]

States (settled distribution of the segment that starts at the mark):
  Login idle       first "proc:Login" (smoke paused by CYS_PERF_HOLD)
  Select built     "scene-built" (CharSel after the incremental scene build finished)
  Select idle #2   second "proc:CharSel" (back from creation, paused)
  Create idle      last "proc:CharCreate" (after the smoke finished, until the run ends)
CPU busy = frame time - pacer wait. logsize.csv gives the mean number of compilers running on the machine.
"""
import argparse
import json
import os
import sys

STATES = [("Login idle", "proc:Login", 0), ("Select built", "scene-built", 0),
          ("Select idle #2", "proc:CharSel", 1), ("Create idle", "proc:CharCreate", -1)]


def pick(segments, label, index):
    found = [s for s in segments if s["label"] == label]
    if not found:
        return None
    try:
        return found[index]
    except IndexError:
        return None


def contention(run_dir):
    path = os.path.join(run_dir, "logsize.csv")
    if not os.path.isfile(path):
        return None
    rows = [l.strip().split(",") for l in open(path, encoding="utf-8") if l.strip()]
    if len(rows) < 2 or "compilers" not in rows[0]:
        return None
    i = rows[0].index("compilers")
    values = [float(r[i]) for r in rows[1:] if len(r) > i]
    return sum(values) / len(values) if values else None


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("runs", nargs="+")
    parser.add_argument("--md")
    args = parser.parse_args(argv)
    lines = ["| Trạng thái | Lượt | fps | p95 ms | p99 ms | max ms | >50 ms | CPU bận ms | draw ms | uidraw ms | GPU ms |"
             " uirebuild/khung | psc/khung | cấp phát/khung | biên dịch nền |",
             "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for state, label, index in STATES:
        for run_dir in args.runs:
            path = os.path.join(run_dir, "report.json")
            if not os.path.isfile(path):
                continue
            report = json.load(open(path, encoding="utf-8"))
            seg = pick(report["segments"], label, index)
            if not seg:
                continue
            d = seg["settled"] if seg["settled"].get("frames") else seg["raw"]
            cpu, gpu, ctr = seg["cpu_ms"], seg["gpu_ms"], seg["counters"]
            busy = d["mean"] - cpu.get("cpu_wait_ms", 0.0)
            comp = contention(run_dir)
            lines.append("| %s | %s | %.1f | %.1f | %.1f | %.1f | %d | %.2f | %.2f | %.2f | %.2f | %.2f | %.0f | %.0f | %s |" % (
                state, os.path.basename(os.path.normpath(run_dir)), d["fps"], d["p95"], d["p99"], d["max"],
                d["hitches"]["gt50"], busy, cpu.get("cpu_draw_ms", 0.0), cpu.get("cpu_uidraw_ms", 0.0),
                gpu.get("gpu_frame_ms", -1.0), ctr.get("uirebuild", 0.0), ctr.get("psc", 0.0), ctr.get("allocs", 0.0),
                ("%.1f" % comp) if comp is not None else "-"))
    text = "\n".join(lines)
    if args.md:
        with open(args.md, "w", encoding="utf-8") as handle:
            handle.write(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
