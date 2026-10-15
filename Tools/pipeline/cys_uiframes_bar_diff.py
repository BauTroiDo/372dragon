# -*- coding: utf-8 -*-
r"""CYS-UIFRAMES: so DAI THANH CHINH cua hai luot de xem o so 9 co icon moi khong.

Vi sao khong dem diem anh toan man hinh: hai luot o hai canh khac nhau, nen nen
khac han. Thanh chinh la lop giao dien, VI TRI CO DINH => chi cat dung dai do.
Bay da ghi cua wardrobe-2: dung dem diem anh tren khung co nhan vat (hoat anh dung
yen gay nhieu). Thanh chinh khong co nhan vat nen phep dem nay sach.

    python 80-bar-diff.py <anh-truoc.png> <anh-sau.png> --out <ket-qua.json>

Doi chung am: --self-test cat cung MOT anh lam ca hai ve => moi o phai ra 0.
"""
import argparse, io, json, os, sys

try:
    from PIL import Image
except ImportError:
    print('CAN Pillow (PIL). Bo do KHONG chay - khong duoc ghi ket qua nao.')
    sys.exit(2)

# Dai thanh chinh, do tu anh 1024x768 cua rig.
BAR_TOP, BAR_BOT = 706, 748
SLOT0_X, SLOT_W, NSLOT = 338, 33, 12


def slots(img):
    out = []
    for i in range(NSLOT):
        x0 = SLOT0_X + i * SLOT_W
        out.append(img.crop((x0, BAR_TOP, x0 + SLOT_W, BAR_BOT)).convert('RGB'))
    return out


def mean(im):
    px = list(im.getdata())
    n = len(px)
    return tuple(sum(p[c] for p in px) / float(n) for c in range(3))


def compare(pa, pb):
    a, b = slots(Image.open(pa)), slots(Image.open(pb))
    rows = []
    for i, (x, y) in enumerate(zip(a, b)):
        ma, mb = mean(x), mean(y)
        d = sum(abs(ma[c] - mb[c]) for c in range(3)) / 3.0
        px = sum(1 for p, q in zip(x.getdata(), y.getdata())
                 if sum(abs(p[c] - q[c]) for c in range(3)) > 60)
        rows.append({'slot': i, 'mean_delta': round(d, 2), 'pixels_changed': px,
                     'mean_before': [round(v, 1) for v in ma],
                     'mean_after': [round(v, 1) for v in mb]})
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('before', nargs='?')
    ap.add_argument('after', nargs='?')
    ap.add_argument('--out')
    ap.add_argument('--crop-out')
    ap.add_argument('--self-test', action='store_true')
    a = ap.parse_args()
    if a.self_test:
        if not a.before:
            print('can mot anh de tu kiem'); sys.exit(2)
        rows = compare(a.before, a.before)
        bad = [r for r in rows if r['mean_delta'] != 0 or r['pixels_changed'] != 0]
        print('DINH NGHIA DEM: 1 o = mot o vuong %dx%d tren dai thanh chinh; '
              'mean_delta = lech mau trung binh; pixels_changed = so diem lech > 60/3 kenh'
              % (SLOT_W, BAR_BOT - BAR_TOP))
        print(('PASS ' if not bad else 'FAIL ') + 'same_image_gives_zero_delta (%d o lech)' % len(bad))
        sys.exit(0 if not bad else 1)
    if not (a.before and a.after and a.out):
        ap.error('can <truoc> <sau> --out')
    rows = compare(a.before, a.after)
    out = {'counting_definition': '1 o = o vuong %dx%d tren dai thanh chinh (y %d-%d, x tu %d buoc %d)'
                                  % (SLOT_W, BAR_BOT - BAR_TOP, BAR_TOP, BAR_BOT, SLOT0_X, SLOT_W),
           'before': a.before, 'after': a.after, 'slots': rows,
           'max_delta_slot': max(rows, key=lambda r: r['mean_delta'])['slot']}
    json.dump(out, io.open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    for r in rows:
        print('o %-2d mean_delta=%-7s pixels=%s' % (r['slot'], r['mean_delta'], r['pixels_changed']))
    print('-> o lech nhieu nhat:', out['max_delta_slot'])
    if a.crop_out:
        for name, p in (('truoc', a.before), ('sau', a.after)):
            im = Image.open(p).crop((SLOT0_X, BAR_TOP, SLOT0_X + NSLOT * SLOT_W, BAR_BOT))
            im = im.resize((im.width * 4, im.height * 4), Image.NEAREST)
            im.save(os.path.join(a.crop_out, 'bar-%s.png' % name))
        print('da ghi anh cat vao', a.crop_out)


if __name__ == '__main__':
    main()
