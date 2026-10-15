#!/usr/bin/env python3
"""CY-Source Tools/perf/hitch_report.py - stutter census of a CYS_PERF frames.csv by scenario segment (perf-cy, 15/09).

Segments come from the #mark rows written by the replay driver (CysWorldReplay PerfMark) and the game loop:
  enter  = replay:in-world .. +10 s     (first seconds in the world: incremental scene build, first draws)
  idle   = +10 s .. replay:spin-begin   (standing, the recorded stream still plays)
  spin   = replay:spin-begin .. replay:spin-end (continuous 360 degree camera turn)
  walk   = replay:click-1 .. replay:core-1 (three ground clicks, running)
  core   = replay:core-1 .. replay:close (target, three attacks with impacts, loot, chat, bag)
  login  = replay:server-list (or proc:Login) + 3 s .. proc:CharSel (CYS_PERF_LOGIN_HOLD_MS keeps it on screen)
Frames that contain a harness capture (shot:* mark, plus the next frame) are excluded from the statistics and counted.

For every frame over --hitch ms (default 33.4) the self time of each phase is computed (nested phases subtracted from
their parent) and the frame is attributed to its largest cause:
  scene-build, particles(ctrl), animation, cull, draw, ui-draw, present/gpu, frame-listeners, lua-ui(ui), lua-script,
  lua-events, net, world, objects, input, pacer-wait, message-pump, harness, unaccounted (time outside every phase).
Counters texload / shadercreate / built are printed with each hitch (first-use texture uploads, shader creation).
"""
import argparse
import csv
import json
import statistics
import sys

NESTED = {  # parent -> children (self time = parent - children)
    'tick': ['input', 'ui', 'net', 'world', 'object', 'script'],
    'render': ['fstart', 'ctrl', 'sanim', 'graph', 'targets', 'fend'],
    'fstart': ['build'],
    'targets': ['cull', 'draw', 'present'],
    'cull': ['anim'],
    'draw': ['uidraw'],
}
CAUSE = {
    'build': 'scene-build', 'ctrl': 'particles', 'anim': 'animation', 'cull': 'cull', 'draw': 'draw', 'uidraw': 'ui-draw',
    'present': 'present/gpu', 'fstart': 'frame-listeners', 'ui': 'lua-ui', 'script': 'lua-script', 'events': 'lua-events',
    'net': 'net', 'world': 'world', 'object': 'objects', 'input': 'input', 'wait': 'pacer-wait', 'msg': 'message-pump',
    'harness': 'harness', 'tick': 'tick-other', 'render': 'render-other', 'targets': 'targets-other', 'sanim': 'scene-anim',
    'graph': 'scene-graph', 'fend': 'frame-ended',
}
TOP = ['msg', 'wait', 'tick', 'harness', 'events', 'render']


def pct(s, q):
    return s[int(round(q * (len(s) - 1)))] if s else 0.0


def load(path):
    frames, marks = [], []
    with open(path, newline='', encoding='utf-8', errors='replace') as f:
        header = None
        for row in csv.reader(f):
            if not row:
                continue
            if row[0] == '#mark':
                marks.append((int(row[1]), float(row[2]), ','.join(row[3:])))
                continue
            if header is None:
                header = row
                continue
            try:
                d = {k: float(v) for k, v in zip(header, row) if v not in ('',)}
            except ValueError:
                continue
            frames.append(d)
    return frames, marks


def self_times(fr):
    t = {}
    for p in CAUSE:
        t[p] = fr.get('cpu_%s_ms' % p, 0.0)
    out = dict(t)
    for parent, kids in NESTED.items():
        out[parent] = max(0.0, t[parent] - sum(t[k] for k in kids))
    out['unaccounted'] = max(0.0, fr['frame_ms'] - sum(t[p] for p in TOP))
    return out


def segments(frames, marks, enter_s):
    by = {}
    for idx, tms, label in marks:
        by.setdefault(label, []).append((idx, tms))
    first = lambda lab: by[lab][0][1] if lab in by else None
    last_t = frames[-1]['t_ms'] if frames else 0.0
    seg = {}
    login = first('replay:server-list') or first('proc:Login')
    if login is not None:
        seg['login'] = (login + 3000.0, first('proc:CharSel') or first('replay:in-world') or last_t)
    inw = first('replay:in-world')
    if inw is not None:
        seg['enter'] = (inw, inw + enter_s * 1000.0)
        idle_end = first('replay:spin-begin') or first('replay:click-1') or last_t
        if idle_end > inw + enter_s * 1000.0:
            seg['idle'] = (inw + enter_s * 1000.0, idle_end)
    if first('replay:spin-begin') is not None:
        seg['spin'] = (first('replay:spin-begin'), first('replay:spin-end') or last_t)
    if first('replay:click-1') is not None:
        seg['walk'] = (first('replay:click-1'), first('replay:core-1') or first('replay:close') or last_t)
    if first('replay:core-1') is not None:
        seg['core'] = (first('replay:core-1'), first('replay:close') or last_t)
    if inw is not None:
        seg['world-all'] = (inw, first('replay:close') or last_t)
    return seg


def analyse(frames, marks, hitch_ms, enter_s):
    shot_frames = set()
    for idx, _, label in marks:
        if label.startswith('shot:'):
            shot_frames.update((idx, idx + 1))
    result = {}
    for name, (a, b) in segments(frames, marks, enter_s).items():
        sel = [f for f in frames if a <= f['t_ms'] < b]
        clean = [f for f in sel if int(f['frame']) not in shot_frames]
        dts = [f['frame_ms'] for f in clean]
        if len(dts) < 2:
            result[name] = {'frames': len(dts)}
            continue
        s = sorted(dts)
        total = sum(dts)
        stut = 0
        for i in range(30, len(dts)):
            med = statistics.median(dts[i - 30:i])
            if dts[i] > 2.0 * med and dts[i] - med > 4.0:
                stut += 1
        causes = {}
        hitches = []
        for f in clean:
            if f['frame_ms'] <= hitch_ms:
                continue
            st = self_times(f)
            top = sorted(st.items(), key=lambda kv: -kv[1])[:4]
            cause = CAUSE.get(top[0][0], top[0][0])
            causes[cause] = causes.get(cause, 0) + 1
            hitches.append({
                'frame': int(f['frame']), 't_s': round(f['t_ms'] / 1000.0, 3), 'ms': round(f['frame_ms'], 1), 'cause': cause,
                'top': ['%s=%.1f' % (CAUSE.get(k, k), v) for k, v in top],
                'texload': int(f.get('texload', 0)), 'shadercreate': int(f.get('shadercreate', 0)), 'built': int(f.get('built', 0)),
                'draws': int(f.get('draws', 0)), 'gpu_ms': round(f.get('gpu_frame_ms', 0.0), 1),
                'caster': int(f.get('casterbuild', 0)), 'caster_ms': round(f.get('caster_us', 0) / 1000.0, 1),
                'variant': int(f.get('variantbuild', 0)), 'variant_ms': round(f.get('variant_us', 0) / 1000.0, 1),
                'matload': int(f.get('matload', 0)), 'matload_ms': round(f.get('matload_us', 0) / 1000.0, 1),
            })
        result[name] = {
            't0_s': round(a / 1000.0, 2), 't1_s': round(b / 1000.0, 2), 'frames': len(dts), 'shot_frames_excluded': len(sel) - len(clean),
            'fps': round(1000.0 * len(dts) / total, 2), 'p50_ms': round(pct(s, .5), 2), 'p95_ms': round(pct(s, .95), 2),
            'p99_ms': round(pct(s, .99), 2), 'max_ms': round(s[-1], 1), 'stdev_ms': round(statistics.pstdev(dts), 2),
            'over33': sum(1 for d in dts if d > 33.34), 'over50': sum(1 for d in dts if d > 50), 'over100': sum(1 for d in dts if d > 100),
            'stutters': stut, 'texload': int(sum(f.get('texload', 0) for f in clean)),
            'shadercreate': int(sum(f.get('shadercreate', 0) for f in clean)), 'built': int(sum(f.get('built', 0) for f in clean)),
            'causes': dict(sorted(causes.items(), key=lambda kv: -kv[1])), 'hitches': hitches,
            'casterbuild': int(sum(f.get('casterbuild', 0) for f in clean)), 'caster_ms': round(sum(f.get('caster_us', 0) for f in clean) / 1000.0, 1),
            'variantbuild': int(sum(f.get('variantbuild', 0) for f in clean)), 'variant_ms': round(sum(f.get('variant_us', 0) for f in clean) / 1000.0, 1),
            'matload': int(sum(f.get('matload', 0) for f in clean)), 'matload_ms': round(sum(f.get('matload_us', 0) for f in clean) / 1000.0, 1),
            'cull_over16': sum(1 for f in clean if f.get('cpu_cull_ms', 0) > 16.0), 'cull_max_ms': round(max(f.get('cpu_cull_ms', 0) for f in clean), 1),
        }
    return result


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('csv')
    ap.add_argument('--hitch', type=float, default=33.4)
    ap.add_argument('--enter', type=float, default=10.0, help='seconds after replay:in-world counted as "enter"')
    ap.add_argument('--json')
    ap.add_argument('--list', type=int, default=12, help='hitches printed per segment')
    args = ap.parse_args()
    frames, marks = load(args.csv)
    if not frames:
        print('no frames', file=sys.stderr)
        return 2
    res = analyse(frames, marks, args.hitch, args.enter)
    for name in ('login', 'enter', 'idle', 'spin', 'walk', 'core', 'world-all'):
        st = res.get(name)
        if not st or st.get('frames', 0) < 2:
            continue
        print('%-9s n=%5d fps=%6.2f p50=%6.2f p95=%6.2f p99=%6.2f max=%7.1f sd=%5.2f >33=%3d >50=%3d >100=%3d stut=%3d tex=%d sh=%d built=%d shots-=%d'
              % (name, st['frames'], st['fps'], st['p50_ms'], st['p95_ms'], st['p99_ms'], st['max_ms'], st['stdev_ms'], st['over33'],
                 st['over50'], st['over100'], st['stutters'], st['texload'], st['shadercreate'], st['built'], st['shot_frames_excluded']))
        if 'casterbuild' in st:
            print('          builds: caster %d (%.1f ms) variant %d (%.1f ms) matload %d (%.1f ms); cull>16 ms %d, cull max %.1f ms'
                  % (st['casterbuild'], st['caster_ms'], st['variantbuild'], st['variant_ms'], st['matload'], st['matload_ms'],
                     st['cull_over16'], st['cull_max_ms']))
        if st['causes']:
            print('          causes: ' + ', '.join('%s %d' % kv for kv in st['causes'].items()))
        for h in sorted(st['hitches'], key=lambda h: -h['ms'])[:args.list]:
            print('          f%-6d t=%8.3f %6.1f ms %-16s %s tex=%d sh=%d built=%d gpu=%.1f caster=%d/%.1fms variant=%d/%.1fms matload=%d/%.1fms' % (
                h['frame'], h['t_s'], h['ms'], h['cause'], ' '.join(h['top']), h['texload'], h['shadercreate'], h['built'], h['gpu_ms'],
                h['caster'], h['caster_ms'], h['variant'], h['variant_ms'], h['matload'], h['matload_ms']))
    if args.json:
        with open(args.json, 'w', encoding='utf-8') as f:
            json.dump({'csv': args.csv, 'marks': marks, 'segments': res}, f, indent=1)
    return 0


if __name__ == '__main__':
    sys.exit(main())
