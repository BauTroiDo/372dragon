#!/usr/bin/env python3
# CY-Source sky-enscene: side-by-side comparison sheet (CY | before | after ...) with labels and, optionally, a
# magnified crop row (e.g. the sky band) and per-column mean RGB of that crop.
# usage: sky_sheet.py out.png --col "CY 3.71=cy.png" --col "truoc=before.png" --col "sau=after.png"
#                     [--crop x0,y0,x1,y1] [--width 640]
import argparse
from PIL import Image, ImageDraw, ImageFont, ImageStat


def font(size):
    for name in ('arial.ttf', 'segoeui.ttf', 'tahoma.ttf'):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--col', action='append', required=True, help='label=path')
    ap.add_argument('--crop', help='x0,y0,x1,y1 in source pixels')
    ap.add_argument('--width', type=int, default=640)
    a = ap.parse_args()
    cols = []
    for c in a.col:
        label, path = c.rsplit('=', 1)
        cols.append((label, Image.open(path).convert('RGB')))
    w = a.width
    h = int(round(cols[0][1].height * w / cols[0][1].width))
    crop = tuple(int(v) for v in a.crop.split(',')) if a.crop else None
    ch = 0
    if crop:
        ch = int(round((crop[3] - crop[1]) * w / (crop[2] - crop[0])))
    head = 28
    sheet = Image.new('RGB', (w * len(cols), head + h + (ch + head if crop else 0)), (20, 20, 20))
    d = ImageDraw.Draw(sheet)
    f = font(18)
    for i, (label, im) in enumerate(cols):
        x = i * w
        d.text((x + 8, 4), label, fill=(255, 255, 255), font=f)
        sheet.paste(im.resize((w, h), Image.LANCZOS), (x, head))
        if crop:
            c = im.crop(crop)
            mean = ImageStat.Stat(c).mean
            d.text((x + 8, head + h + 4), 'crop %s mean rgb %.0f,%.0f,%.0f' % (a.crop, mean[0], mean[1], mean[2]),
                   fill=(220, 220, 220), font=font(14))
            sheet.paste(c.resize((w, ch), Image.LANCZOS), (x, head + h + head))
    sheet.save(a.out)
    print('saved', a.out, sheet.size)


if __name__ == '__main__':
    main()
