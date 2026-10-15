#!/usr/bin/env python3
"""CY-Source Tools/perf/probe_report.py - frame pacing statistics from the present probe (perf-cy, 15/09/2026).

Input: probe_<pid>.csv written by Tools/perf/present_probe (one row per IDirect3DDevice9::Present), or a CYS_PERF
frames.csv (column t_ms or frame_ms is accepted when it has them).
Frame time = interval between two consecutive Present entries. Percentiles use nearest rank sorted[round(q*(n-1))],
like Tools/perf/perf_report.py.

Windows: --window name:start_s:end_s (seconds since the probe loaded; repeatable). Without windows the whole run after
--skip seconds is one window.

Metrics per window: frames, fps, mean, p50, p90, p95, p99, max, stdev, frames > 25/33.3/50/100 ms, "stutters" =
frames longer than 2x the median of the 30 frames before them (a pacing break the eye sees even at high fps), and the
share of time spent in the longest 1 % of frames. Every frame > --hitch ms is listed with its counters.
"""
import argparse
import csv
import json
import statistics
import sys


def pct(sorted_values, q):
    if not sorted_values:
        return 0.0
    return sorted_values[int(round(q * (len(sorted_values) - 1)))]


def load(path):
    rows = []
    with open(path, newline='', encoding='utf-8', errors='replace') as f:
        for r in csv.DictReader(f):
            try:
                r['t_ms'] = float(r['t_ms'])
            except (KeyError, ValueError):
                continue
            rows.append(r)
    return rows


def stats(frames, hitch_ms):
    """frames: list of (t_start_ms, dt_ms, row)."""
    dts = [d for _, d, _ in frames]
    if not dts:
        return {'frames': 0}
    s = sorted(dts)
    total = sum(dts)
    stutters = 0
    for i in range(30, len(dts)):
        med = statistics.median(dts[i - 30:i])
        if dts[i] > 2.0 * med and dts[i] - med > 4.0:
            stutters += 1
    top = s[-max(1, len(s) // 100):]
    out = {
        'frames': len(dts),
        'seconds': round(total / 1000.0, 2),
        'fps': round(1000.0 * len(dts) / total, 2) if total else 0.0,
        'mean_ms': round(total / len(dts), 2),
        'p50_ms': round(pct(s, 0.50), 2),
        'p90_ms': round(pct(s, 0.90), 2),
        'p95_ms': round(pct(s, 0.95), 2),
        'p99_ms': round(pct(s, 0.99), 2),
        'max_ms': round(s[-1], 2),
        'stdev_ms': round(statistics.pstdev(dts), 2),
        'over25': sum(1 for d in dts if d > 25.0),
        'over33': sum(1 for d in dts if d > 33.34),
        'over50': sum(1 for d in dts if d > 50.0),
        'over100': sum(1 for d in dts if d > 100.0),
        'stutters': stutters,
        'top1pct_time_share': round(sum(top) / total, 4) if total else 0.0,
    }
    hitches = []
    for t, d, r in frames:
        if d > hitch_ms:
            h = {'t_s': round(t / 1000.0, 3), 'ms': round(d, 1)}
            for k in ('present_ms', 'main_cyc', 'other_cyc', 'draws', 'tex', 'vb', 'ib', 'rt', 'decl', 'vs', 'ps', 'create_ms', 'offthread'):
                if k in r and r[k] != '':
                    h[k] = r[k]
            hitches.append(h)
    out['hitches'] = hitches
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('csv')
    ap.add_argument('--window', action='append', default=[], help='name:start_s:end_s')
    ap.add_argument('--skip', type=float, default=0.0, help='seconds skipped when no window is given')
    ap.add_argument('--hitch', type=float, default=50.0)
    ap.add_argument('--steady', type=float, default=None,
                    help='one window "steady": from the end of the last load gap (> --gap ms) plus this many seconds')
    ap.add_argument('--gap', type=float, default=1000.0)
    ap.add_argument('--json')
    args = ap.parse_args()
    rows = load(args.csv)
    if len(rows) < 2:
        print('not enough frames', file=sys.stderr)
        return 2
    frames = []
    for a, b in zip(rows, rows[1:]):
        frames.append((a['t_ms'], b['t_ms'] - a['t_ms'], b))
    windows = []
    for w in args.window:
        name, s0, s1 = w.split(':')
        windows.append((name, float(s0) * 1000.0, float(s1) * 1000.0))
    if args.steady is not None:
        start = frames[0][0]
        for t, d, _ in frames:
            if d > args.gap:
                start = t + d
        windows.append(('steady', start + args.steady * 1000.0, frames[-1][0] + 1.0))
    if not windows:
        windows = [('all', args.skip * 1000.0, frames[-1][0] + 1.0)]
    result = {'csv': args.csv, 'windows': {}}
    for name, a, b in windows:
        sel = [f for f in frames if a <= f[0] < b]
        result['windows'][name] = stats(sel, args.hitch)
        st = result['windows'][name]
        if st['frames']:
            print('%-14s n=%5d fps=%6.2f p50=%6.2f p95=%6.2f p99=%6.2f max=%7.1f sd=%5.2f >33=%3d >50=%3d >100=%3d stutter=%3d'
                  % (name, st['frames'], st['fps'], st['p50_ms'], st['p95_ms'], st['p99_ms'], st['max_ms'], st['stdev_ms'],
                     st['over33'], st['over50'], st['over100'], st['stutters']))
        else:
            print('%-14s no frames' % name)
    if args.json:
        with open(args.json, 'w', encoding='utf-8') as f:
            json.dump(result, f, indent=1)
    return 0


if __name__ == '__main__':
    sys.exit(main())
