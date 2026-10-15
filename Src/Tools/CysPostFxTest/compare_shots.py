"""Compares the CysPostFxTest shots (shot_<case>.png) with the reference shot_none.png.

Uses Tests/oracle/compare.py (SSIM on luma, PSNR, heat map diff_<case>.png) and builds contact.png, a labelled
contact sheet of every shot. Writes ssim.txt next to the shots.

    python compare_shots.py <shot folder>
"""
import glob
import os
import subprocess
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
COMPARE = os.path.normpath(os.path.join(HERE, '..', '..', '..', 'Tests', 'oracle', 'compare.py'))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else '.'
    ref = os.path.join(out, 'shot_none.png')
    if not os.path.exists(ref):
        print('missing ' + ref)
        return 1
    shots = sorted(glob.glob(os.path.join(out, 'shot_*.png')))
    lines = ['case            result (vs shot_none.png, Tests/oracle/compare.py)']
    for path in shots:
        name = os.path.basename(path)[5:-4]
        if name == 'none':
            continue
        r = subprocess.run([sys.executable, COMPARE, ref, path, '--out', os.path.join(out, 'diff_%s.png' % name)],
                           capture_output=True, text=True)
        lines.append('%-15s %s' % (name, (r.stdout.strip() or r.stderr.strip())))
    with open(os.path.join(out, 'ssim.txt'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print('\n'.join(lines))

    # contact sheet: 480x270 thumbnails with the case name
    thumbs = []
    for path in shots:
        im = Image.open(path).convert('RGB')
        im.thumbnail((480, 270), Image.LANCZOS)
        canvas = Image.new('RGB', (480, 290), (16, 16, 16))
        canvas.paste(im, (0, 20))
        ImageDraw.Draw(canvas).text((6, 4), os.path.basename(path)[5:-4], fill=(240, 240, 240))
        thumbs.append(canvas)
    if thumbs:
        cols = 4
        rows = (len(thumbs) + cols - 1) // cols
        sheet = Image.new('RGB', (cols * 480, rows * 290), (0, 0, 0))
        for i, t in enumerate(thumbs):
            sheet.paste(t, ((i % cols) * 480, (i // cols) * 290))
        sheet.save(os.path.join(out, 'contact.png'))
        print('contact sheet: ' + os.path.join(out, 'contact.png'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
