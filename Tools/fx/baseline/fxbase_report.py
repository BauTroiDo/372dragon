#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CYS-FXBASE: all batches -> one table (one row per effect, worst first), report.md (verdict counts, controls, top-N,
one-sided lists, per-batch registration / noise floor) and summary.json. Reads compare/<batch>/compare.json written by
fxbase_compare.py batch.

usage: fxbase_report.py --batches b00b-calib,b01,... [--out compare/all]
"""
import argparse
import json
import os

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
LOGS = os.path.join(ROOT, 'Build', 'Logs', '2026-09-19-fx-cy-baseline')
NL, TAB = chr(10), chr(9)
ORDER = {'CHI CY VE': 0, 'CHI TA VE': 1, 'LECH': 2, 'LECH NHE': 3, 'MOT BEN RAT NHO (chi CY)': 4, 'MOT BEN RAT NHO (chi ta)': 5,
         'GIONG': 6, 'CA HAI TRONG': 7}
CONTROLS = ('REAL13', 'CTRL')


def fmt(v, f='%.2f'):
    return '' if v is None else (f % v)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--batches', required=True)
    ap.add_argument('--out', default=os.path.join(LOGS, 'compare', 'all'))
    ap.add_argument('--enable-batches', default='', help='compare dirs of the one-shot (enable) route, e.g. b01-enable,...: '
                    'an effect that the continuous route could not compare (only one side drew, or nothing) takes the '
                    'one-shot verdict when that route drew on both sides')
    a = ap.parse_args()
    batches = [b.strip() for b in a.batches.split(',') if b.strip()]
    os.makedirs(a.out, exist_ok=True)
    rows, per_batch, missing = [], [], []
    for b in batches:
        p = os.path.join(LOGS, 'compare', b, 'compare.json')
        if not os.path.exists(p):
            missing.append(b)
            continue
        s = json.load(open(p, encoding='utf-8'))
        per_batch.append({'batch': b, 'register': s['register'], 'floor': s['floor_area'], 'unstable': s.get('unstable_fraction') or {},
                          'cy_run': s['cy_run'], 'our_run': s['our_run'], 'cy_yaw': (s.get('cy_camera') or {}).get('yaw_deg')})
        for r in s['results']:
            r = dict(r)
            r.pop('pairs_detail', None)
            r['batch'] = b
            r['route'] = 'lien-tuc'
            r['sheet'] = os.path.relpath(os.path.join(LOGS, 'compare', b, r['fid'] + '.png'), ROOT)
            rows.append(r)
    # one-shot route: merge per fid
    enable = {}
    for b in [x.strip() for x in a.enable_batches.split(',') if x.strip()]:
        p = os.path.join(LOGS, 'compare', b, 'compare.json')
        if not os.path.exists(p):
            missing.append(b)
            continue
        s = json.load(open(p, encoding='utf-8'))
        for r in s['results']:
            r = dict(r)
            r.pop('pairs_detail', None)
            r['batch'] = b
            r['route'] = 'mot-lan'
            r['sheet'] = os.path.relpath(os.path.join(LOGS, 'compare', b, r['fid'] + '.png'), ROOT)
            enable[r['fid']] = r
    weak = ('CHI CY VE', 'CHI TA VE', 'CA HAI TRONG', 'MOT BEN RAT NHO (chi CY)', 'MOT BEN RAT NHO (chi ta)', 'CA HAI RAT NHO')
    merged = []
    for r in rows:
        e = enable.get(r['fid'])
        r['verdict_continuous'] = r['verdict']
        r['verdict_oneshot'] = e['verdict'] if e else ''
        r['D_oneshot'] = e['D_median'] if e else None
        if e and r['verdict'] in weak and e['verdict'] in ('GIONG', 'LECH NHE', 'LECH', 'CA HAI RAT NHO'):
            r2 = dict(e)
            r2['verdict_continuous'] = r['verdict']
            r2['verdict_oneshot'] = e['verdict']
            r2['D_oneshot'] = e['D_median']
            r2['route'] = 'mot-lan (thay cho lien-tuc)'
            merged.append(r2)
        else:
            merged.append(r)
    rows = merged

    def key(r):
        v = r['verdict']
        return (ORDER.get(v, 8 if v.startswith('KHONG') else 9), -(r['D_median'] or 0))
    rows.sort(key=key)
    cols = ['fid', 'effect', 'batch', 'route', 'verdict', 'D', 'log2_area', 'log2_energy', 'hue_l1', 'iou', 'peak_area_cy', 'peak_area_ours',
            'sat_cy', 'sat_ours', 'pairs', 'verdict_continuous', 'verdict_oneshot', 'D_oneshot', 'sheet']
    with open(os.path.join(a.out, 'table.tsv'), 'w', encoding='utf-8', newline=NL) as f:
        f.write(TAB.join(cols) + NL)
        for r in rows:
            f.write(TAB.join(str(x) for x in [r['fid'], r['effect'], r['batch'], r.get('route', ''), r['verdict'], fmt(r['D_median']), fmt(r['log2_area_median']),
                                              fmt(r['log2_energy_median']), fmt(r['hue_l1_median']), fmt(r['iou_median']),
                                              '%.5f' % r['peak_area_cy'], '%.5f' % r['peak_area_ours'], '%.4f' % r['sat_cy_max'],
                                              '%.4f' % r['sat_ours_max'], r['pairs'], r.get('verdict_continuous', ''), r.get('verdict_oneshot', ''),
                                              fmt(r.get('D_oneshot')), r['sheet']]) + NL)
    real = [r for r in rows if r['fid'] not in CONTROLS]
    controls = [r for r in rows if r['fid'] in CONTROLS]
    counts = {}
    for r in real:
        counts[r['verdict']] = counts.get(r['verdict'], 0) + 1
    both = [r for r in real if r['verdict'] in ('GIONG', 'LECH NHE', 'LECH')]
    md = ['# fx-cy-baseline: CY 3.71 vs CY-Source, %d hieu ung do duoc trong %d lo' % (len(real), len(per_batch)), '']
    if missing:
        md += ['**Lo chua so duoc (thieu compare.json): %s**' % ', '.join(missing), '']
    md += ['## Phan quyet (khong ke dong kiem REAL13/CTRL)', '', '| phan quyet | so hieu ung |', '|---|---:|']
    for v, n in sorted(counts.items(), key=lambda x: -x[1]):
        md.append('| %s | %d |' % (v, n))
    md += ['', '## Dong kiem moi lo (REAL13 = dong 13 that; CTRL = dong gia cung hieu ung)', '',
           '| lo | fid | phan quyet | D | dien tich dinh CY / ta |', '|---|---|---|---|---|']
    for r in sorted(controls, key=lambda r: (r['batch'], r['fid'])):
        md.append('| %s | %s | %s | %s | %.4f / %.4f |' % (r['batch'], r['fid'], r['verdict'], fmt(r['D_median']), r['peak_area_cy'], r['peak_area_ours']))
    md += ['', '## Lech nhieu nhat (ca hai ben deu ve; D giam dan; D = |log2 dien tich| + |log2 nang luong| + 2*hueL1 + (1-IoU))', '',
           '| # | fid | hieu ung | D | log2 dien tich | log2 nang luong | hue L1 | IoU | sheet |', '|---:|---|---|---:|---:|---:|---:|---:|---|']
    for i, r in enumerate(sorted(both, key=lambda r: -(r['D_median'] or 0))[:20], 1):
        md.append('| %d | %s | `%s` | %s | %s | %s | %s | %s | `%s` |' % (i, r['fid'], r['effect'], fmt(r['D_median']), fmt(r['log2_area_median']),
                                                                       fmt(r['log2_energy_median']), fmt(r['hue_l1_median']), fmt(r['iou_median']), r['sheet']))
    for title, verdict in (('Chi CY ve (ta khong ve gi qua san nhieu)', 'CHI CY VE'), ('Chi ta ve (CY khong ve gi qua san nhieu)', 'CHI TA VE'),
                           ('Mot ben rat nho (< 0,25 % vung do, bang chung yeu)', 'MOT BEN RAT NHO (chi CY)'), ('', 'MOT BEN RAT NHO (chi ta)'),
                           ('Ca hai trong (khong ben nao ve qua san nhieu: khong so duoc hinh)', 'CA HAI TRONG'), ('Giong (D < 0,9)', 'GIONG'),
                           ('Lech nhe (0,9 <= D < 1,6)', 'LECH NHE'), ('Lech (D >= 1,6)', 'LECH')):
        lst = [r for r in real if r['verdict'] == verdict]
        if title:
            md += ['', '## %s: %d' % (title, len(lst)), '']
        else:
            md += ['', '### %s: %d' % (verdict, len(lst)), '']
        md.append(', '.join('%s `%s` (%.4f/%.4f%s)' % (r['fid'], r['effect'], r['peak_area_cy'], r['peak_area_ours'], (', D ' + fmt(r['D_median'])) if r['D_median'] is not None else '') for r in lst) or '(khong co)')
    # per category (prefix of the fid: S = sect skill effects, A aura, B buff, W weapon, D deco weapon, H hj boss, R mount,
    # T costume, U UI, E = oracle extras)
    import re as _re
    cats = {}
    for r in real:
        c = _re.match(r'[A-Za-z]+', r['fid']).group(0)
        c = 'S' if c.startswith('S') and c != 'S' else c
        cats.setdefault(c, {}).setdefault(r['verdict'], 0)
        cats[c][r['verdict']] += 1
    verdicts = sorted(counts, key=lambda v: ORDER.get(v, 9))
    md += ['', '## Theo nhom (chu cai dau cua id: S ky nang mon phai, A hao quang, B buff, W vu khi, D vu khi trang tri, H boss, R thu cuoi, T thoi trang, U UI, E oracle)', '',
           '| nhom | tong | ' + ' | '.join(verdicts) + ' |', '|---|---:|' + '---:|' * len(verdicts)]
    for c in sorted(cats):
        tot = sum(cats[c].values())
        md.append('| %s | %d | %s |' % (c, tot, ' | '.join(str(cats[c].get(v, 0)) for v in verdicts)))
    md += ['', '## Tung lo: dang ky camera, san nhieu (held-out), yaw CY', '',
           '| lo | dx,dy (px) | san nhieu CY / ta (dien tich) | khong on dinh CY / ta | yaw CY | lo CY | lo ta |', '|---|---|---|---|---|---|---|']
    for b in per_batch:
        u = b['unstable']
        md.append('| %s | %d,%d | %.5f / %.5f | %.4f / %.4f | %s | %s | %s |' % (b['batch'], b['register']['dx'], b['register']['dy'], b['floor']['cy'], b['floor']['ours'],
                                                                                u.get('cy', 0), u.get('ours', 0), b['cy_yaw'], os.path.basename(b['cy_run']), os.path.basename(b['our_run'])))
    with open(os.path.join(a.out, 'report.md'), 'w', encoding='utf-8', newline=NL) as f:
        f.write(NL.join(md) + NL)
    json.dump({'rows': len(rows), 'effects': len(real), 'verdicts': counts, 'batches': per_batch, 'missing': missing},
              open(os.path.join(a.out, 'summary.json'), 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
    print('effects', len(real), 'controls', len(controls), counts, 'missing', missing)


if __name__ == '__main__':
    main()
