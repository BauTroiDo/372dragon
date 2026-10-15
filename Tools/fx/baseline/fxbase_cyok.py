#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CYS-FXBASE: is a CY run usable? exit 0 = yes. Checks: reached the world, >= 20 captures, no capture with an empty
method (window minimised: b02-r1 lost 19 frames and its camera), camera read-back c0 present, and c1 (end of run) equal
to c0 within 0.5 deg / 20 units when both exist (a drifted camera invalidates the later tags).
usage: fxbase_cyok.py <cy run dir>   (prints the reason when not ok)
"""
import json
import os
import re
import sys


def main():
    return main_dir(sys.argv[1])


def main_dir(d):
    log = os.path.join(d, 'run.log')
    if not os.path.exists(log):
        print('no run.log'); return 1
    lines = open(log, encoding='utf-8', errors='replace').read().splitlines()
    if not any('wait matched IN WORLD' in l for l in lines):
        print('never reached the world'); return 1
    shots = [l for l in lines if re.search(r'\bshot \S+ via ', l)]
    if len(shots) < 20:
        print('only %d captures' % len(shots)); return 1
    empty = [l for l in shots if re.search(r'via  t0=', l)]
    if empty:
        print('%d captures with an empty method (window minimised/hidden), first: %s' % (len(empty), empty[0].strip()[:60])); return 1
    # every timeline tag must have been matched by the runner within 2.5 s of the oracle packet (b00b-calib-r2: a 15 s
    # camera scan let the runner fall behind, the captures of tag X showed effect X+1..X+3)
    olog = os.path.join(d, 'oracle', 'oracle.log')
    if os.path.exists(olog):
        t0 = None
        tag_epoch = {}
        for l in open(olog, encoding='utf-8', errors='replace'):
            m = re.match(r'\s*(\d+) wallclock t0=([\d.]+)', l)
            if m:
                t0 = float(m.group(2))
            m = re.match(r'\s*(\d+) timeline (\S+): ', l)
            if m and t0 is not None:
                tag_epoch[m.group(2)] = t0 * 1000.0 + int(m.group(1))
        late = []
        for l in lines:
            m = re.search(r'wait matched timeline (\S+): @(\d+)', l)
            if m and m.group(1) in tag_epoch:
                lag = int(m.group(2)) - tag_epoch[m.group(1)]
                # base tags only need their captures inside their own window (a sync camera scan delayed base0 by 3 s
                # in b00b-calib-r1 without harm); effect tags must be matched promptly
                if lag > (4000 if m.group(1).startswith('base') else 3500):
                    late.append('%s +%.1fs' % (m.group(1), lag / 1000.0))
        if late:
            print('tags matched late: ' + ', '.join(late[:6])); return 1
    c0 = os.path.join(d, 'cam-c0.json')
    if not os.path.exists(c0):
        print('no cam-c0.json'); return 1
    a = (json.load(open(c0, encoding='utf-8')).get('candidates') or [None])[0]
    if not a:
        print('cam-c0 has no candidate'); return 1
    c1 = os.path.join(d, 'cam-c1.json')
    if os.path.exists(c1):
        b = (json.load(open(c1, encoding='utf-8')).get('candidates') or [None])[0]
        if b:
            if abs(a['yaw_deg'] - b['yaw_deg']) > 0.5 or abs(a['pitch_down_deg'] - b['pitch_down_deg']) > 0.5 or abs(a['orbit_distance'] - b['orbit_distance']) > 20:
                print('camera drifted during the run: c0 yaw %.2f pitch %.2f orbit %.0f -> c1 yaw %.2f pitch %.2f orbit %.0f' % (
                    a['yaw_deg'], a['pitch_down_deg'], a['orbit_distance'], b['yaw_deg'], b['pitch_down_deg'], b['orbit_distance'])); return 1
    print('ok (%d captures, yaw %.2f)' % (len(shots), a['yaw_deg']))
    return 0


if __name__ == '__main__':
    sys.exit(main())
