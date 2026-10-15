"""So ảnh đối chứng: ảnh client_GL (B) và ảnh engine mới (ours).

In ra SSIM (trung bình trên vùng so), PSNR và ghi ảnh hiệu dạng bản đồ nhiệt.

Chạy:
  python compare.py B.png ours.png [--mask auto|none] [--out diff.png]

--mask auto: bỏ những điểm ảnh cùng là màu nền ở cả hai ảnh (dùng cho ảnh chụp model
trên nền đồng màu); màu nền lấy theo góc trên-trái của ảnh B.
Ngưỡng đạt (Docs/07 mục 2): model/effect SSIM >= 0.95; cảnh >= 0.90.
"""
import argparse
import sys

import numpy as np
from PIL import Image


def load(p):
    return np.asarray(Image.open(p).convert('RGB'), dtype=np.float64)


def box(a, r):
    # Trung bình trượt (2r+1)x(2r+1) bằng ảnh tích luỹ.
    k = 2 * r + 1
    p = np.pad(a, ((r + 1, r), (r + 1, r)), mode='edge')
    c = p.cumsum(0).cumsum(1)
    return (c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]) / (k * k)


def ssim_map(x, y, r=4):
    c1, c2 = (0.01 * 255) ** 2, (0.03 * 255) ** 2
    mx, my = box(x, r), box(y, r)
    sxx = box(x * x, r) - mx * mx
    syy = box(y * y, r) - my * my
    sxy = box(x * y, r) - mx * my
    return ((2 * mx * my + c1) * (2 * sxy + c2)) / ((mx * mx + my * my + c1) * (sxx + syy + c2))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('b')
    ap.add_argument('ours')
    ap.add_argument('--mask', default='none', choices=('auto', 'none'))
    ap.add_argument('--out')
    a = ap.parse_args()
    B, O = load(a.b), load(a.ours)
    if B.shape != O.shape:
        O = np.asarray(Image.fromarray(O.astype(np.uint8)).resize((B.shape[1], B.shape[0]), Image.LANCZOS), dtype=np.float64)
    gb = B @ [0.299, 0.587, 0.114]
    go = O @ [0.299, 0.587, 0.114]
    m = ssim_map(gb, go)
    mask = np.ones(gb.shape, bool)
    if a.mask == 'auto':
        bg = B[0, 0]
        mask = ~((np.abs(B - bg).sum(2) < 6) & (np.abs(O - bg).sum(2) < 6))
    s = float(m[mask].mean()) if mask.any() else 1.0
    mse = float(((B - O) ** 2).mean())
    psnr = 99.0 if mse == 0 else 10 * np.log10(255 ** 2 / mse)
    print('SSIM=%.4f PSNR=%.2fdB pixels=%d' % (s, psnr, int(mask.sum())))
    if a.out:
        d = np.clip((1 - m) * 4, 0, 1)
        heat = np.stack([d, 1 - np.abs(d - 0.5) * 2, 1 - d], 2) * 255
        heat[~mask] = heat[~mask] * 0.25
        Image.fromarray(heat.astype(np.uint8)).save(a.out)
    return 0


if __name__ == '__main__':
    sys.exit(main())
