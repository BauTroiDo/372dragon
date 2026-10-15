#!/usr/bin/env python3
"""CY-Source Tools/perf/probe_table.py - one table row per present-probe run (perf-cy, 15/09/2026).

For every run directory holding probe_<pid>.csv: the steady window (after the last load gap > 1 s, plus --skip s, and
optionally cut at --until s), frame percentiles, frames > 33/50 ms, stutters, median time inside Present, median CPU
of the presenting thread and of the other threads (cycles / --cycles-per-ms, default 2.27e6 measured on the E5-2696 v3
from a 100 % busy load gap), median draws, and the VSync / back buffer parameters from probe_<pid>.txt.
"""
import argparse
import csv
import glob
import os
import re
import statistics


def pct(s, q):
    return s[int(round(q * (len(s) - 1)))] if s else 0.0


def row(d, skip, until, cpm, gap, longest=0.0):
    csvs = glob.glob(os.path.join(d, 'probe_*.csv'))
    if not csvs:
        return None
    rows = list(csv.DictReader(open(csvs[0], newline='')))
    t = [float(r['t_ms']) for r in rows]
    if len(t) < 10:
        return None
    start = t[0]
    for a, b in zip(t, t[1:]):
        if b - a > gap:
            start = b
    a0 = start + skip * 1000.0
    a1 = (t[0] + until * 1000.0) if until else t[-1] + 1
    if longest:
        # longest stretch without a frame longer than `longest` ms (e.g. the held login screen of a replay run)
        best = (0, 0)
        s0 = 0
        for i in range(1, len(t)):
            if t[i] - t[i - 1] > longest:
                if i - 1 - s0 > best[1] - best[0]:
                    best = (s0, i - 1)
                s0 = i
        if len(t) - 1 - s0 > best[1] - best[0]:
            best = (s0, len(t) - 1)
        a0 = t[best[0]] + skip * 1000.0
        a1 = t[best[1]] - 1000.0
    sel = [(t[i], t[i + 1] - t[i], rows[i + 1]) for i in range(len(t) - 1) if a0 <= t[i] < a1]
    if len(sel) < 10:
        return None
    dts = [x[1] for x in sel]
    s = sorted(dts)
    stut = sum(1 for i in range(30, len(dts)) if dts[i] > 2 * statistics.median(dts[i - 30:i]) and dts[i] - statistics.median(dts[i - 30:i]) > 4)
    txt = open(glob.glob(os.path.join(d, 'probe_*.txt'))[0]).read()
    m = re.findall(r'CreateDevice \(final\): backbuffer (\d+)x(\d+).*?count (\d+).*?PresentationInterval (0x[0-9a-f]+)', txt)
    vs = m[-1] if m else ('?', '?', '?', '?')
    med = lambda k, div=1.0: statistics.median(float(x[2][k]) / div for x in sel)
    return {
        'run': os.path.basename(d.rstrip('\\/')), 'size': '%sx%s' % (vs[0], vs[1]), 'bb': vs[2],
        'vsync': {'0x1': 'on', '0x80000000': 'off'}.get(vs[3], vs[3]), 'seconds': round(sum(dts) / 1000, 1), 'frames': len(dts),
        'fps': round(1000 * len(dts) / sum(dts), 1), 'p50': round(pct(s, .5), 2), 'p95': round(pct(s, .95), 2), 'p99': round(pct(s, .99), 2),
        'max': round(s[-1], 1), 'sd': round(statistics.pstdev(dts), 2), 'o33': sum(1 for x in dts if x > 33.34),
        'o50': sum(1 for x in dts if x > 50), 'stut': stut, 'present_ms': round(med('present_ms'), 2),
        'main_cpu_ms': round(med('main_cyc', cpm), 2), 'other_cpu_ms': round(med('other_cyc', cpm), 2), 'draws': int(med('draws')),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('dirs', nargs='+')
    ap.add_argument('--skip', type=float, default=3.0)
    ap.add_argument('--until', type=float, default=0.0, help='seconds since probe load where the window ends (0 = end)')
    ap.add_argument('--gap', type=float, default=1000.0)
    ap.add_argument('--cycles-per-ms', type=float, default=2.27e6)
    ap.add_argument('--longest', type=float, default=0.0, help='use the longest stretch without a frame > this many ms')
    args = ap.parse_args()
    keys = ['run', 'size', 'vsync', 'bb', 'seconds', 'frames', 'fps', 'p50', 'p95', 'p99', 'max', 'sd', 'o33', 'o50', 'stut',
            'present_ms', 'main_cpu_ms', 'other_cpu_ms', 'draws']
    print('| ' + ' | '.join(keys) + ' |')
    print('|' + '---|' * len(keys))
    for pattern in args.dirs:
        for d in sorted(glob.glob(pattern)):
            if not os.path.isdir(d):
                continue
            r = row(d, args.skip, args.until, args.cycles_per_ms, args.gap, args.longest)
            if r:
                print('| ' + ' | '.join(str(r[k]) for k in keys) + ' |')


if __name__ == '__main__':
    main()
