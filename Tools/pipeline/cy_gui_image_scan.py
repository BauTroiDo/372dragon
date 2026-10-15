# -*- coding: utf-8 -*-
"""cy_gui_image_scan.py - inventory of the images a set of CY 3.71 layouts shows (ui-image-vi, 15/09/2026).

For every layout (and the Lua script next to it) the tool lists each `set:<Imageset> image:<Image>` reference,
resolves the imageset through the scheme (Schema/WoWLookSkin.scheme.xml -> <Imageset> file), crops the image
rectangle from its texture and writes:
    <out>/images.tsv          layout, source (layout|lua), imageset, image, texture, x, y, w, h, sheet, cell
    <out>/sheet-<layout>-N.png  contact sheets (cell index + imageset:image) for the visual census
The census (which crops carry Chinese characters) is done by looking at the sheets; the result goes into
Registry/i18n/cy_gui_image_vi.tsv (cy_gui_image_vi.py). Read only: the InterfaceFolder given by --ui.

Usage: cy_gui_image_scan.py --ui <Data\\InterfaceFolder> --out <dir> LAYOUT [LAYOUT ...]
       (LAYOUT = folder name or path of a .layout.xml below --ui)
"""
import argparse
import csv
import io
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cy_gui_image_vi as GIV  # noqa: E402  (imageset index + texture decode)

REF = re.compile(r'set:\s*([^\s"\']+)\s+image:\s*([^"\'\s<>]+)')


def layout_files(ui, name):
    p = os.path.join(ui, name)
    if os.path.isfile(p):
        return [p], os.path.dirname(p)
    if os.path.isdir(p):
        return sorted(os.path.join(p, f) for f in os.listdir(p) if f.lower().endswith(('.layout.xml', '.lua'))), p
    raise SystemExit('layout not found: ' + name)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--ui', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--cols', type=int, default=8)
    ap.add_argument('--rows', type=int, default=10)
    ap.add_argument('--min', type=int, default=8, help='skip images smaller than this in both directions')
    ap.add_argument('layouts', nargs='+')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    idx = GIV.ImagesetIndex(a.ui, reader=GIV.DiskReader(a.ui))
    font = ImageFont.truetype(os.path.join(a.ui, 'Schema', 'NotoSansSC-Regular.ttf'), 11)
    rows = []
    cache = {}
    for lay in a.layouts:
        files, _ = layout_files(a.ui, lay)
        seen = []
        for f in files:
            with open(f, 'rb') as fh:
                raw = fh.read()
            try:
                text = GIV.decode_text(raw)
            except UnicodeDecodeError:
                continue
            src = 'lua' if f.lower().endswith('.lua') else 'layout'
            for m in REF.finditer(text):
                key = (m.group(1), m.group(2))
                if key not in [s[1] for s in seen]:
                    seen.append((src, key))
        cells = []
        for src, (iset, img) in seen:
            info = idx.image(iset, img)
            if info is None:
                rows.append((lay, src, iset, img, '(unresolved)', '', '', '', '', '', ''))
                continue
            tex, x, y, w, h = info
            if w < a.min and h < a.min:
                continue
            if tex not in cache:
                try:
                    cache[tex] = idx.texture_rgba(tex)
                except Exception as ex:  # noqa: BLE001 - census: report and continue
                    cache[tex] = None
                    print('texture', tex, type(ex).__name__, ex)
            px = cache[tex]
            if px is None:
                rows.append((lay, src, iset, img, tex + ' (undecodable)', x, y, w, h, '', ''))
                continue
            crop = px[y:y + h, x:x + w]
            cells.append((src, iset, img, tex, x, y, w, h, crop))
        per = a.cols * a.rows
        cw, ch = 200, 96
        for s in range(0, len(cells), per):
            part = cells[s:s + per]
            nrows = (len(part) + a.cols - 1) // a.cols
            sheet = Image.new('RGB', (a.cols * cw, nrows * ch), (70, 70, 78))
            d = ImageDraw.Draw(sheet)
            name = 'sheet-%s-%d.png' % (lay.replace('\\', '_').replace('/', '_'), s // per)
            for i, (src, iset, img, tex, x, y, w, h, crop) in enumerate(part):
                cx, cy = (i % a.cols) * cw, (i // a.cols) * ch
                im = Image.fromarray(crop, 'RGBA')
                sc = min(2.0, (cw - 8) / max(1, w), (ch - 26) / max(1, h))
                im = im.resize((max(1, int(w * sc)), max(1, int(h * sc))), Image.NEAREST if sc >= 1 else Image.LANCZOS)
                bg = Image.new('RGBA', im.size, (40, 44, 52, 255))
                bg.alpha_composite(im)
                sheet.paste(bg.convert('RGB'), (cx + 4, cy + 22))
                d.rectangle([cx, cy, cx + cw - 1, cy + ch - 1], outline=(110, 110, 120))
                d.text((cx + 3, cy + 1), '%d %s' % (s + i, img)[:30], fill=(255, 255, 0), font=font)
                d.text((cx + 3, cy + 11), '%s %dx%d' % (iset, w, h)[:32], fill=(170, 200, 255), font=font)
                rows.append((lay, src, iset, img, tex, x, y, w, h, name, s + i))
            sheet.save(os.path.join(a.out, name))
        print(lay, 'references', len(seen), 'cells', len(cells))
    with open(os.path.join(a.out, 'images.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('layout\tsource\timageset\timage\ttexture\tx\ty\tw\th\tsheet\tcell\n')
        for r in rows:
            f.write('\t'.join(str(v) for v in r) + '\n')


if __name__ == '__main__':
    main()
