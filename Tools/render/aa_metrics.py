"""CY-Source Tools/render/aa_metrics.py - jaggedness / edge-harshness numbers for still frames (CYS-AA, aa-cy 15/09).

Per image and region (luma BT.601, 0..255):
  lap     mean |4-neighbour Laplacian|           high-frequency energy (aliasing and texture detail both raise it)
  hard    % of pixels with a neighbour step > 48  hard, un-smoothed edges (staircases, sparkling texels)
  p99     99th percentile of the neighbour step   how harsh the harshest edges are
  ramp    % of strong edge pixels (step > 48) that have an intermediate neighbour (|v - mid| < step/4 across the
          edge): 0 = pure staircase, higher = anti-aliased / filtered edge
Usage:
  aa_metrics.py stats OUT.tsv IMG [IMG ...] [--region name=x0,y0,x1,y1 ...]
  aa_metrics.py sheet OUT.png x0,y0,x1,y1 SCALE LABEL=IMG [LABEL=IMG ...]   (nearest-neighbour crops side by side)
"""
import sys

import numpy as np
from PIL import Image, ImageDraw


def luma(path):
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def metrics(y):
    c = y[1:-1, 1:-1]
    n, s, w, e = y[:-2, 1:-1], y[2:, 1:-1], y[1:-1, :-2], y[1:-1, 2:]
    lap = np.abs(4 * c - n - s - w - e)
    dx = np.abs(e - c)
    dy = np.abs(s - c)
    step = np.maximum(dx, dy)
    hard = step > 48
    # ramp: for a strong horizontal step c->e, look one pixel further (e2) and one before (w): an anti-aliased edge
    # spreads the transition over two pixels, so one of them sits between the two plateaus
    e2 = y[1:-1, 3:]
    w1 = y[1:-1, :-3]
    cx, ex = c[:, :-1], e[:, :-1]
    mid = (cx + ex) * 0.5
    strong = dx[:, :-1] > 48
    inter = (np.abs(e2 - mid) < dx[:, :-1] * 0.25) | (np.abs(w1 - mid) < dx[:, :-1] * 0.25)
    ramp = 100.0 * (strong & inter).sum() / max(1, strong.sum())
    return {
        "lap": float(lap.mean()),
        "hard": float(100.0 * hard.mean()),
        "p99": float(np.percentile(step, 99)),
        "ramp": float(ramp),
    }


def stats(argv):
    out = argv[0]
    regions = []
    imgs = []
    i = 1
    while i < len(argv):
        if argv[i] == "--region":
            name, box = argv[i + 1].split("=", 1)
            regions.append((name, tuple(int(v) for v in box.split(","))))
            i += 2
        else:
            imgs.append(argv[i])
            i += 1
    rows = ["image\tregion\tlap\thard%\tp99\tramp%"]
    for path in imgs:
        y = luma(path)
        for name, box in [("full", None)] + regions:
            sub = y if box is None else y[box[1]:box[3], box[0]:box[2]]
            m = metrics(sub)
            rows.append("%s\t%s\t%.2f\t%.3f\t%.1f\t%.1f" % (path.replace("\\", "/").split("/")[-1], name, m["lap"],
                                                           m["hard"], m["p99"], m["ramp"]))
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(rows) + "\n")
    print("\n".join(rows))


def sheet(argv):
    out, box, scale = argv[0], tuple(int(v) for v in argv[1].split(",")), int(argv[2])
    tiles = []
    for spec in argv[3:]:
        label, path = spec.split("=", 1)
        im = Image.open(path).convert("RGB").crop(box)
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        canvas = Image.new("RGB", (im.width, im.height + 18), (0, 0, 0))
        canvas.paste(im, (0, 18))
        ImageDraw.Draw(canvas).text((4, 3), label, fill=(255, 255, 0))
        tiles.append(canvas)
    w = sum(t.width for t in tiles) + 6 * (len(tiles) - 1)
    sheet_img = Image.new("RGB", (w, max(t.height for t in tiles)), (40, 40, 40))
    x = 0
    for t in tiles:
        sheet_img.paste(t, (x, 0))
        x += t.width + 6
    sheet_img.save(out)
    print(out, sheet_img.size)


if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] not in ("stats", "sheet"):
        print(__doc__)
        sys.exit(2)
    (stats if sys.argv[1] == "stats" else sheet)(sys.argv[2:])
