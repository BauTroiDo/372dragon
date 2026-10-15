# -*- coding: utf-8 -*-
"""bullet-fx (19/09/2026): dan co THAT SU HIEN RA MAN HINH khong — do bang diem anh, co san nhieu HELD-OUT.

VI SAO PHAI CAN THAN O DAY: canh bao cua de bai (wardrobe-2) — **dung dem diem anh tren khung co nhan vat**:
hoat anh dung yen mot mình da gay 8.616 px nhieu, gan bang thay doi that 10.820 px. Cach chong o day:

  1. Moi tag co 4 anh cung mot may quay, cung vi tri NPC: `-a` (+600 ms, dan dang bay), ... `-d` (+2400 ms,
     dan da trung va bien mat). Tin hieu dan = |a - d|.
  2. Hai tag DOI CHUNG AM (NA-s281, NB-s999999) **khong co dan** nhung co y HET hoat anh dung yen. Chung cho
     ra dung phan nhieu can tru.
  3. MAT NA NHIEU hoc tu MOT tag doi chung, roi do tren tag doi chung CON LAI (**held-out**) => san nhieu
     khong the bang 0 mot cach gia tao. Tag duong chi duoc coi la "co dan" khi vuot san held-out do.
  4. Vung HUD (day man hinh, 18 %) bi loai — khung chat/hanh trang nhap nhay khong lien quan.

DINH NGHIA DEM: "px_dan" = so diem anh co |a - d| > NGUONG tren cac kenh, NAM NGOAI mat na nhieu va ngoai HUD.

DUNG:
  python -B Tools/fx/bullet/bullet_pixels.py --shots <thu muc ScreenShots> --meta <run1.meta.json> --out <json>
"""
import argparse
import json
import os
import re

import numpy as np
from PIL import Image

THR = 24            # chenh lech tren mot kenh de tinh la "doi" (0..255)
HUD_BOTTOM = 0.18   # bo 18 % duoi (thanh ky nang / chat)
DILATE = 2          # no mat na nhieu ra vai px de bat vien mo hinh


def load(path):
    return np.asarray(Image.open(path).convert('RGB'), dtype=np.int16)


def changed(a, b):
    return (np.abs(a - b).max(axis=2) > THR)


def dilate(mask, r):
    out = mask.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            out |= np.roll(np.roll(mask, dy, axis=0), dx, axis=1)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--shots', required=True)
    ap.add_argument('--meta', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--report', help='07-report-*.json: lay moc TRUNG (ms) cua tung tag de tach pha bay')
    a = ap.parse_args()
    meta = json.load(open(a.meta, encoding='utf-8'))
    shot_ms = [int(x) for x in str(meta['shot_ms']).split(',')]
    hit_ms = {}
    if a.report:
        rep = json.load(open(a.report, encoding='utf-8'))
        for r in rep['rows']:
            # `hit.ms` la thoi gian BAY (tinh tu luc dan sinh ra), con moc chup tinh tu luc thay TAG.
            # Hai moc goc nay CHI trung nhau o pha A (dan sinh ngay tai giay cua tag). O pha B/C dan sinh
            # muon hon (goi toi sau tag 400 ms, roi con cho khung "hit" cua hoat anh), nen cua so bay bi
            # dich va phep loc "ca hai anh truoc luc trung" KHONG con dung. => chi tinh px_bay cho pha A;
            # pha B/C dua vao LOG (so khung bay + quang duong) chu khong dua vao diem anh.
            if r.get('hit') and r.get('phase') == 'A':
                hit_ms[r['tag']] = r['hit']['ms']

    # gom anh theo tag: <prefix>-<started>-<tag>-<a..d>.png
    by_tag = {}
    for name in sorted(os.listdir(a.shots)):
        if not name.lower().endswith('.png'):
            continue
        m = re.match(r'.*?-(\d+)-(.+)-([a-h])\.png$', name)
        if not m:
            continue
        by_tag.setdefault(m.group(2), {})[m.group(3)] = os.path.join(a.shots, name)

    tags = [t['tag'] for t in meta['tags']]
    negs = [t for t in tags if '-NA-' in t or '-NB-' in t]
    if len(negs) < 2:
        raise SystemExit('can it nhat 2 tag doi chung am de co san nhieu held-out')

    # So MOI CAP anh cua cung mot tag, khong chi (a,d): dan o pha B/C xuat phat muon 400 ms nen cap (a,d)
    # co the roi dung vao luc dan chua ra hoac da trung. Lay MAX tren moi cap — va ap DUNG QUY TAC AY cho ca
    # tag doi chung am, de san nhieu duoc tinh cung cach (neu chi noi long cho ben duong thi la gian lan).
    PAIRS = [('a', 'b'), ('a', 'c'), ('a', 'd'), ('b', 'c'), ('b', 'd'), ('c', 'd')]

    LETTER_MS = {c: shot_ms[i] for i, c in enumerate('abcdefgh') if i < len(shot_ms)}

    def pairs_of(tag, before_hit=False):
        d = by_tag.get(tag, {})
        out = []
        for x, y in PAIRS:
            if not (d.get(x) and d.get(y)):
                continue
            if before_hit:
                h = hit_ms.get(tag)
                # chi giu cap ma CA HAI anh chup TRUOC luc dan trung: khi ay thay doi tren man hinh
                # chi co the do DAN DANG BAY, khong the do vu no luc trung.
                if h is None or LETTER_MS.get(x, 1 << 30) >= h or LETTER_MS.get(y, 1 << 30) >= h:
                    continue
            out.append((d[x], d[y]))
        return out

    # mat na nhieu: hoc tu tung tag doi chung rieng biet
    masks = {}
    for t in negs:
        ps = pairs_of(t)
        if not ps:
            continue
        mk = None
        for pa, pb in ps:
            c = changed(load(pa), load(pb))
            mk = c if mk is None else (mk | c)
        masks[t] = dilate(mk, DILATE)
    if len(masks) < 2:
        raise SystemExit('thieu anh cua tag doi chung am; khong dung duoc san held-out')

    shape = next(iter(masks.values())).shape
    hud = np.zeros(shape, dtype=bool)
    hud[int(shape[0] * (1 - HUD_BOTTOM)):, :] = True

    def count(tag, mask, before_hit=False):
        ps = pairs_of(tag, before_hit)
        if not ps:
            return None
        return max(int((changed(load(pa), load(pb)) & ~mask & ~hud).sum()) for pa, pb in ps)

    # SAN NHIEU HELD-OUT: do tag doi chung X bang mat na hoc tu tag doi chung Y != X
    floor = []
    for x in negs:
        for y in negs:
            if x == y or y not in masks:
                continue
            c = count(x, masks[y])
            if c is not None:
                floor.append({'do_tren': x, 'mat_na_tu': y, 'px': c})
    floor_px = max(f['px'] for f in floor) if floor else 0

    # mat na chung cho cac tag duong = hop cua moi mat na doi chung
    union = np.zeros(shape, dtype=bool)
    for mk in masks.values():
        union |= mk

    rows = []
    for t in tags:
        # Tag doi chung am KHONG duoc do bang mat na co chinh no trong do — nhu the la vong tron, ket qua se
        # luon ra 0 px va khong chung minh dieu gi. Do chung bang mat na HELD-OUT (hoc tu tag doi chung kia).
        if t in negs:
            other = [y for y in negs if y != t and y in masks]
            mask = masks[other[0]] if other else union
            held_out = True
        else:
            mask = union
            held_out = False
        c = count(t, mask)
        cb = count(t, mask, before_hit=True)
        thr = max(3 * floor_px, 200)
        rows.append({'tag': t,
                     # px_toan_man: MOI cap anh — chung minh "chuoi hieu ung co ve ra man hinh gi do"
                     #              (gom ca vu no luc trung), KHONG tach duoc bay voi trung.
                     'px_toan_man': c,
                     # px_bay: chi cap ma ca hai anh chup TRUOC luc trung — day moi la "co thay DAN DANG BAY".
                     #         None = luot chup khong co du 2 moc nam trong thoi gian bay (khong ket luan duoc).
                     'px_bay': cb,
                     'mat_na': 'held-out' if held_out else 'hop cua 2 tag doi chung',
                     'co_anh': bool(by_tag.get(t)),
                     'ket_luan_toan_man': None if c is None else ('CO-VE-GI-DO' if c > thr else 'KHONG-THAY'),
                     'ket_luan_bay': None if cb is None else ('THAY-DAN-BAY' if cb > thr else 'KHONG-THAY-DAN-BAY')})

    out = {'schema': 1, 'shots': os.path.abspath(a.shots), 'nguong_kenh': THR, 'hud_bo_duoi': HUD_BOTTOM,
           'san_nhieu_held_out_px': floor_px, 'san_chi_tiet': floor,
           'nguong_thay_dan_px': max(3 * floor_px, 200),
           'so_tag_co_anh': sum(1 for r in rows if r['co_anh']), 'rows': rows}
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    json.dump(out, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('san nhieu HELD-OUT = %d px ; nguong "thay dan" = %d px' % (floor_px, out['nguong_thay_dan_px']))
    for r in rows:
        print('  %-18s toan_man=%-8s %-12s | bay=%-8s %s' % (
            r['tag'], r['px_toan_man'], r['ket_luan_toan_man'] or '-', r['px_bay'], r['ket_luan_bay'] or 'khong du moc'))
    print('-> %s' % a.out)


if __name__ == '__main__':
    main()
