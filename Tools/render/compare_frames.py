#!/usr/bin/env python3
"""CY-Source Tools/render/compare_frames.py - colour statistics of frames (CYS-COLOR, color-calib 15/09).

  stats OUT.tsv IMG... [--mask MASK.png] [--region name=x0,y0,x1,y1 ...]
      per image (and per region): mean R/G/B, luma (Rec.601, 0-255), HSV saturation mean (max-min)/max,
      HSV saturation mean over pixels with value >= 0.1 (sat_lit), luma p5/p50/p95, fraction >= 250,
      32-bin luma histogram (hist.tsv next to OUT). MASK: white = measured pixels (e.g. outside the CY login UI).
  triptych OUT.png A.png B.png C.png --labels a,b,c   side by side with captions (same height).
Numpy + Pillow only. Luma/saturation deltas are reported relative (%) and absolute.
"""
import sys
import numpy as np
from PIL import Image, ImageDraw


def load(path):
    return np.asarray(Image.open(path).convert('RGB')).astype(np.float64)


def measure(img, mask=None):
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    mx = img.max(axis=2); mn = img.min(axis=2)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-9), 0.0)
    luma = 0.299 * r + 0.587 * g + 0.114 * b
    sel = np.ones(luma.shape, bool) if mask is None else mask
    lit = sel & (mx >= 25.5)
    L = luma[sel]
    return {
        'mean_r': r[sel].mean(), 'mean_g': g[sel].mean(), 'mean_b': b[sel].mean(),
        'luma': L.mean(), 'chroma': (mx - mn)[sel].mean(), 'sat': sat[sel].mean(), 'sat_lit': sat[lit].mean() if lit.any() else 0.0,
        'p5': np.percentile(L, 5), 'p50': np.percentile(L, 50), 'p95': np.percentile(L, 95),
        'white': (L >= 250).mean(), 'pixels': int(sel.sum()),
    }, np.histogram(L, bins=32, range=(0, 256))[0] / max(1, L.size)


COLS = ['mean_r', 'mean_g', 'mean_b', 'luma', 'chroma', 'sat', 'sat_lit', 'p5', 'p50', 'p95', 'white', 'pixels']


def cmd_stats(argv):
    out = argv[0]; imgs = []; mask = None; regions = [('all', None)]
    i = 1
    while i < len(argv):
        if argv[i] == '--mask':
            mask = np.asarray(Image.open(argv[i + 1]).convert('L')) > 127; i += 2
        elif argv[i] == '--region':
            name, box = argv[i + 1].split('='); regions.append((name, [int(v) for v in box.split(',')])); i += 2
        else:
            imgs.append(argv[i]); i += 1
    rows = ['file\tregion\t' + '\t'.join(COLS)]
    hrows = ['file\tregion\t' + '\t'.join('h%d' % k for k in range(32))]
    for path in imgs:
        img = load(path)
        for name, box in regions:
            m = np.ones(img.shape[:2], bool) if mask is None else mask.copy()
            if box:
                bm = np.zeros(img.shape[:2], bool); bm[box[1]:box[3], box[0]:box[2]] = True; m &= bm
            s, h = measure(img, m)
            fname = path.replace(chr(92), '/').split('/')[-1]
            rows.append(fname + '\t' + name + '\t' + '\t'.join(('%d' % s[c]) if c == 'pixels' else ('%.4f' % s[c]) for c in COLS))
            hrows.append(fname + '\t' + name + '\t' + '\t'.join('%.5f' % v for v in h))
    open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(rows) + '\n')
    open(out[:-4] + '.hist.tsv', 'w', encoding='utf-8', newline='\n').write('\n'.join(hrows) + '\n')
    print('\n'.join(rows))


def cmd_triptych(argv):
    out = argv[0]; files = []; labels = None
    i = 1
    while i < len(argv):
        if argv[i] == '--labels':
            labels = argv[i + 1].split('|'); i += 2
        else:
            files.append(argv[i]); i += 1
    ims = [Image.open(f).convert('RGB') for f in files]
    h = min(im.height for im in ims)
    ims = [im.resize((round(im.width * h / im.height), h)) for im in ims]
    band = 28
    canvas = Image.new('RGB', (sum(im.width for im in ims) + 8 * (len(ims) - 1), h + band), (16, 16, 16))
    d = ImageDraw.Draw(canvas); x = 0
    for k, im in enumerate(ims):
        canvas.paste(im, (x, band))
        d.text((x + 8, 7), labels[k] if labels and k < len(labels) else files[k], fill=(240, 240, 240))
        x += im.width + 8
    canvas.save(out)
    print(out)


if __name__ == '__main__':
    if len(sys.argv) < 3 or sys.argv[1] not in ('stats', 'triptych'):
        print(__doc__); sys.exit(2)
    {'stats': cmd_stats, 'triptych': cmd_triptych}[sys.argv[1]](sys.argv[2:])
