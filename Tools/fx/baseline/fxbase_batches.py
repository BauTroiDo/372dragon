#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CYS-FXBASE: deterministic batch assignment of the plan (Tools/fx/baseline/fxbase_impactse.py plan.json).

Every batch starts with the positive control REAL13 (existing row 13, buff_fengxue_01: proves the impact path and the
override table of THAT run), then N plan effects in plan order. Late-start effects (StartTime > 2 s: B10 6.1 s, T01
3.15 s) go to their own --late batch (9 s per effect, shots to 8 s). Effects already covered by a batch listed in
--skip are left out.

usage: fxbase_batches.py --plan <plan.json> --out <batches dir> [--per-batch 9] [--skip b00-calib] [--start 1]
"""
import argparse
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--plan', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--per-batch', type=int, default=9)
    ap.add_argument('--interval', default='4.5')
    ap.add_argument('--skip', default='', help='comma list of batch names whose effects are already covered')
    ap.add_argument('--start', type=int, default=1)
    ap.add_argument('--npc', default='daocaoren', help='fxbase_scenario.py --npc (daocaoren: lowest idle-motion noise, b00 vs b00b)')
    a = ap.parse_args()
    plan = json.load(open(a.plan, encoding='utf-8'))
    done = set()
    for b in [x for x in a.skip.split(',') if x.strip()]:
        meta = json.load(open(os.path.join(a.out, b + '.batch.json'), encoding='utf-8'))
        done.update(it['fid'] for it in meta['items'])
    late = [p['fid'] for p in plan if p.get('late_ms', 0) > 0 and p['fid'] not in done]
    std = [p['fid'] for p in plan if p.get('late_ms', 0) == 0 and p['fid'] not in done and p['fid'] != 'CTRL']
    batches = []
    n = a.start
    for i in range(0, len(std), a.per_batch):
        batches.append(('b%02d' % n, ['13'] + std[i:i + a.per_batch], False))
        n += 1
    if late:
        batches.append(('b%02d-late' % n, ['13'] + late, True))
    for name, fids, is_late in batches:
        cmd = [sys.executable, os.path.join(HERE, 'fxbase_scenario.py'), '--plan', a.plan, '--batch', name, '--fids', ','.join(fids),
               '--interval', a.interval, '--out', a.out, '--npc', a.npc] + (['--late'] if is_late else [])
        subprocess.check_call(cmd, env=dict(os.environ, PYTHONUTF8='1', PYTHONIOENCODING='utf-8'))
    print('%d batches, %d standard effects + %d late; skipped %d already covered' % (len(batches), len(std), len(late), len(done)))
    with open(os.path.join(a.out, 'batches.json'), 'w', encoding='utf-8') as f:
        json.dump([{'batch': b, 'fids': fids, 'late': l} for b, fids, l in batches], f, ensure_ascii=False, indent=1)


if __name__ == '__main__':
    main()
