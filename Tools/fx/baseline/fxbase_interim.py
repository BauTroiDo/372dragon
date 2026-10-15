#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CYS-FXBASE: interim deliverable -> markdown block (top-N most divergent effects with a one-line reading of the
metrics, scope covered / not covered, controls, self-test summary) written to compare/all/interim.md and spliced into
Timeline/handoff/fx-cy-baseline.md between '## 3.' and '## 4.'.

usage: fxbase_interim.py [--top 20] [--no-splice]
"""
import argparse
import csv
import io
import json
import os

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
LOGS = os.path.join(ROOT, 'Build', 'Logs', '2026-09-19-fx-cy-baseline')
HANDOFF = os.path.join(ROOT, 'Timeline', 'handoff', 'fx-cy-baseline.md')
NL = chr(10)


def f(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def reading(r):
    """One sentence: where does it diverge (area / brightness / colour / shape / onset / one side missing)."""
    v = r['verdict']
    if v == 'CHI CY VE':
        return 'CY vẽ (đỉnh %.1f %% vùng đo), ta không vẽ gì qua sàn nhiễu' % (100 * f(r['peak_area_cy']))
    if v == 'CHI TA VE':
        return 'ta vẽ (đỉnh %.1f %% vùng đo), CY không vẽ gì qua sàn nhiễu' % (100 * f(r['peak_area_ours']))
    parts = []
    la, le, hue, iou = f(r['log2_area']), f(r['log2_energy']), f(r['hue_l1']), f(r['iou'])
    if la is not None:
        if la >= 0.8:
            parts.append('ta phủ rộng gấp %.1f lần' % (2 ** la))
        elif la <= -0.8:
            parts.append('ta phủ hẹp, còn 1/%.1f' % (2 ** -la))
    if le is not None:
        if le >= 0.6:
            parts.append('ta sáng hơn (năng lượng ×%.1f)' % (2 ** le))
        elif le <= -0.6:
            parts.append('ta tối hơn (năng lượng ×%.2f)' % (2 ** le))
    if hue is not None:
        if hue >= 0.45:
            parts.append('màu khác hẳn (hue L1 %.2f)' % hue)
        elif hue >= 0.25:
            parts.append('màu lệch (hue L1 %.2f)' % hue)
    if iou is not None and iou < 0.3:
        parts.append('vị trí/hình khác (IoU %.2f)' % iou)
    do, d = f(r.get('D_onset')), f(r['D'])
    if do is not None and d is not None and do - d > 1.5:
        parts.append('khởi phát lệch (D 0,3 s = %.1f)' % do)
    sc, so = f(r['sat_cy']), f(r['sat_ours'])
    if sc is not None and so is not None and abs(sc - so) > 0.15:
        parts.append('cháy trắng %s' % ('CY %.0f %% / ta %.0f %%' % (100 * sc, 100 * so)))
    return '; '.join(parts) if parts else 'lệch nhỏ trên nhiều trục (không trục nào trội)'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--top', type=int, default=20)
    ap.add_argument('--no-splice', action='store_true')
    a = ap.parse_args()
    table = os.path.join(LOGS, 'compare', 'all', 'table.tsv')
    rows = list(csv.DictReader(io.open(table, encoding='utf-8'), delimiter=chr(9)))
    # D_onset lives in compare.json; pull it per batch
    onset = {}
    for r in rows:
        p = os.path.join(LOGS, 'compare', r['batch'], 'compare.json')
        if os.path.exists(p) and r['batch'] not in onset:
            onset[r['batch']] = {x['fid']: x.get('D_onset') for x in json.load(io.open(p, encoding='utf-8'))['results']}
    for r in rows:
        r['D_onset'] = onset.get(r['batch'], {}).get(r['fid'])
    real = [r for r in rows if r['fid'] not in ('REAL13', 'CTRL')]
    both = [r for r in real if r['verdict'] in ('LECH', 'LECH NHE', 'GIONG')]
    top = sorted([r for r in both if f(r['D']) is not None], key=lambda r: -f(r['D']))[:a.top]
    one_cy = [r for r in real if r['verdict'] == 'CHI CY VE']
    one_ours = [r for r in real if r['verdict'] == 'CHI TA VE']
    counts = {}
    for r in real:
        counts[r['verdict']] = counts.get(r['verdict'], 0) + 1
    plan = json.load(io.open(os.path.join(ROOT, 'Build', 're', 'fx-cy-baseline', 'tables', 'plan.json'), encoding='utf-8'))
    listed = [p['fid'] for p in plan if p['fid'] != 'CTRL']
    done = {r['fid'] for r in real}
    not_done = [x for x in listed if x not in done]
    md = []
    md.append('### 3a. %d ca LỆCH NHẤT trong số ca cả hai phía đều vẽ (D giảm dần; sheet = CY | ta | mặt nạ CY | mặt nạ ta)' % len(top))
    md.append('')
    md.append('| # | id | hiệu ứng | phán quyết | D | lệch ở đâu (đọc từ số) | cặp ảnh |')
    md.append('|---:|---|---|---|---:|---|---|')
    for i, r in enumerate(top, 1):
        md.append('| %d | %s | `%s` | %s | %s | %s | `%s` |' % (i, r['fid'], r['effect'], r['verdict'], r['D'], reading(r), r['sheet']))
    md.append('')
    md.append('### 3b. Chỉ một bên vẽ (không có cặp để chấm D; đây là **lệch lớn nhất**, không phải "chưa đo")')
    md.append('')
    md.append('- **Chỉ ta vẽ, CY không** (%d): %s' % (len(one_ours), ', '.join('%s `%s` (ta %.1f %%)' % (r['fid'], r['effect'], 100 * f(r['peak_area_ours'])) for r in one_ours) or '(không)'))
    md.append('- **Chỉ CY vẽ, ta không** (%d): %s' % (len(one_cy), ', '.join('%s `%s` (CY %.1f %%)' % (r['fid'], r['effect'], 100 * f(r['peak_area_cy'])) for r in one_cy) or '(không)'))
    md.append('')
    md.append('### 3c. Phạm vi đã phủ (đếm trên `compare\\all\\table.tsv`)')
    md.append('')
    md.append('| phán quyết | số hiệu ứng |')
    md.append('|---|---:|')
    for v, n in sorted(counts.items(), key=lambda x: -x[1]):
        md.append('| %s | %d |' % (v, n))
    md.append('| **đã so và chấm** | **%d / %d** (141 danh sách CY + 4 hiệu ứng oracle E020/E048/E061/E090) |' % (len(real), len(listed)))
    md.append('| chưa có cặp ảnh lành (đang chạy lại) | %d: %s |' % (len(not_done), ', '.join(not_done)))
    md.append('')
    with io.open(os.path.join(LOGS, 'compare', 'all', 'interim.md'), 'w', encoding='utf-8', newline=NL) as fh:
        fh.write(NL.join(md) + NL)
    print('top %d, one-sided ours %d cy %d, done %d/%d, pending %d' % (len(top), len(one_ours), len(one_cy), len(real), len(listed), len(not_done)))
    if not a.no_splice:
        h = io.open(HANDOFF, encoding='utf-8').read()
        s0, s1 = h.index('## 3. Đã chứng minh được gì'), h.index('## 4. Việc tiếp theo đúng ngay')
        marker_a, marker_b = '<!-- interim-table -->', '<!-- /interim-table -->'
        block = marker_a + NL + NL.join(md) + NL + marker_b + NL
        sec = h[s0:s1]
        if marker_a in sec:
            i0, i1 = sec.index(marker_a), sec.index(marker_b) + len(marker_b) + 1
            sec = sec[:i0] + block + sec[i1:]
        else:
            sec = sec.rstrip(NL) + NL + NL + block + NL
        h = h[:s0] + sec + h[s1:]
        io.open(HANDOFF, 'w', encoding='utf-8', newline=NL).write(h)
        print('spliced into the handoff')


if __name__ == '__main__':
    main()
