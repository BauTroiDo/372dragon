#!/usr/bin/env python3
"""CYS-SFX: CY / project / |diff| sheet for skill-effect frames (skill-fx-parity, 15/09).

Each row: CY frame | project frame | |CY - project| (and optionally project-after | |CY - after|), the full 1280x720
frame scaled to half size plus a zoomed crop of the effect region. Metrics per row (JSON + TSV):
  mad_full / mad_crop    mean absolute RGB difference (0..255) CY vs project
  fx_cy / fx_proj        effect energy in the crop = mean max(0, luma(frame) - luma(baseline)) with the no-effect baseline
                         frame of the same client (effect brightness/area; the baseline removes scene differences)
  fx_area_cy / _proj     share of crop pixels brighter than the baseline by > 24 luma

usage: sfx_compare.py --out sheet.png --crop x,y,w,h [--cy-base b.png --proj-base b.png [--after-base b.png]]
                      --row label cy.png proj.png [after.png] [--row ...]
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


def load(path):
    im = Image.open(path).convert('RGB')
    if im.size != (1280, 720):
        im = im.resize((1280, 720), Image.BILINEAR)
    return np.asarray(im).astype(np.int16)


def luma(a):
    return 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]


def crop(a, box):
    x, y, w, h = box
    return a[y:y + h, x:x + w]


def fx(frame, base, box):
    if base is None:
        return None, None
    d = luma(crop(frame, box)) - luma(crop(base, box))
    return float(np.maximum(d, 0).mean()), float((d > 24).mean())


def tile(a, box, zoom=1):
    full = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).resize((640, 360), Image.BILINEAR)
    x, y, w, h = box
    c = Image.fromarray(np.clip(crop(a, box), 0, 255).astype(np.uint8)).resize((w * zoom, h * zoom), Image.NEAREST)
    return full, c


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--crop', required=True)
    ap.add_argument('--cy-base')
    ap.add_argument('--proj-base')
    ap.add_argument('--after-base')
    ap.add_argument('--zoom', type=int, default=1)
    ap.add_argument('--row', nargs='+', action='append', required=True)
    a = ap.parse_args()
    box = tuple(int(v) for v in a.crop.split(','))
    cyb = load(a.cy_base) if a.cy_base else None
    pb = load(a.proj_base) if a.proj_base else None
    ab = load(a.after_base) if a.after_base else pb
    rows, metrics = [], []
    for r in a.row:
        label, cyp, pp = r[0], r[1], r[2]
        ap_ = r[3] if len(r) > 3 else None
        cy, pr = load(cyp), load(pp)
        cols = [cy, pr, np.abs(cy - pr) * 3]
        m = {'label': label, 'cy': cyp, 'proj': pp,
             'mad_full': float(np.abs(cy - pr).mean()), 'mad_crop': float(np.abs(crop(cy, box) - crop(pr, box)).mean())}
        m['fx_cy'], m['fx_area_cy'] = fx(cy, cyb, box)
        m['fx_proj'], m['fx_area_proj'] = fx(pr, pb, box)
        if ap_:
            af = load(ap_)
            cols += [af, np.abs(cy - af) * 3]
            m.update({'after': ap_, 'mad_full_after': float(np.abs(cy - af).mean()),
                      'mad_crop_after': float(np.abs(crop(cy, box) - crop(af, box)).mean())})
            m['fx_after'], m['fx_area_after'] = fx(af, ab, box)
        rows.append((label, cols))
        metrics.append(m)
    x, y, w, h = box
    cw = max(640, w * a.zoom)
    rh = 360 + h * a.zoom + 20
    ncol = max(len(c) for _, c in rows)
    sheet = Image.new('RGB', (cw * ncol, rh * len(rows)), (16, 16, 16))
    d = ImageDraw.Draw(sheet)
    heads = ['CY 3.71', 'CY-Source', '|CY-proj| x3', 'CY-Source after', '|CY-after| x3']
    for i, (label, cols) in enumerate(rows):
        for j, col in enumerate(cols):
            full, c = tile(col, box, a.zoom)
            sheet.paste(full, (j * cw, i * rh + 20))
            sheet.paste(c, (j * cw, i * rh + 20 + 360))
            if j < 3 or j == 3:
                pass
            d.text((j * cw + 4, i * rh + 4), '%s  %s' % (label, heads[j]), fill=(255, 255, 0))
            if j in (0, 1, 3):
                d.rectangle([j * cw + x // 2, i * rh + 20 + y // 2, j * cw + (x + w) // 2, i * rh + 20 + (y + h) // 2], outline=(0, 255, 0))
        m = metrics[i]
        d.text((2 * cw + 4, i * rh + 380), 'mad full %.1f crop %.1f' % (m['mad_full'], m['mad_crop']), fill=(255, 255, 255))
    sheet.save(a.out)
    Path(a.out).with_suffix('.json').write_text(json.dumps(metrics, indent=1), encoding='utf-8')
    for m in metrics:
        print(json.dumps({k: (round(v, 3) if isinstance(v, float) else v) for k, v in m.items() if k not in ('cy', 'proj', 'after')}))


if __name__ == '__main__':
    main()
