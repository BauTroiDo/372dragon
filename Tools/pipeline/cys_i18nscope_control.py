# -*- coding: utf-8 -*-
"""CYS-I18NSCOPE: doi chung tren DU LIEU THAT cho `cys_i18nscope_rescue.analyse`.

Luat cua du an (DIEU-PHOI muc 17 + yeu cau cua dieu phoi): mot phep quet chua chung minh duoc
no PHAT HIEN DUOC loi khi loi con do thi moi con so no in ra deu vo nghia. Selftest bang du lieu
gia da co trong cong cu; day la ban chay tren chinh hai tep do that.

Cach lam: chon mot khoa CHUA HE bi rut (khong co ghi de), duoc >=3 khung tham chieu, va moi o
deu dang vua. Bom mot ghi de GIA cho no voi ngan sach = MOT khung. Phep quet PHAI:
  DUONG : tim ra khoa, dem dung so khung con lai va dung so o con lai;
  AM 1  : neu coi MOI khung deu thuoc ngan sach thi KHONG duoc bao ro ri;
  AM 2  : neu ban "rut gon" TRUNG ban day du thi khong co gi de cuu.

AM 2 da BAT DUOC mot lo hong that trong ban dau cua `analyse` (dem ca ghi de khong lam doi gia
tri). Da vá; giu phep kiem nay de no khong quay lai.

BAY DA SAP khi viet phep kiem nay: ten khung cua cong cu la ten TEP layout (`GMMark`), khong
phai ten THU MUC (`GMChat`). Dung `R.frame_of` chu dung tu tach chuoi.

usage: python -B cys_i18nscope_control.py [--short <csv>] [--full <csv>]
(ban sao chay duoc cua Build/Logs/2026-09-19-i18n-scope/90-control-real-data.py - Build/ bi gitignore)
"""
import argparse
import collections
import json
import os
import re
import sys

CYS = r'C:\TLBB\085\CY-Source'
sys.path.insert(0, os.path.join(CYS, 'Tools', 'pipeline'))
import cys_i18nscope_leak as L      # noqa: E402
import cys_i18nscope_rescue as R    # noqa: E402

B = os.path.join(CYS, 'Build', 'Logs', '2026-09-19-i18n-scope')
RX = re.compile(r'^#\{([^}]+)\}$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--short', default=os.path.join(B, 'm-short', 'overflow.csv'))
    ap.add_argument('--full', default=os.path.join(B, 'm-full', 'overflow.csv'))
    ap.add_argument('--out', default=os.path.join(B, 'control-real-data.json'))
    a = ap.parse_args()
    short, full = R.read_rows(a.short), R.read_rows(a.full)
    bud = L.load_budget()
    _bk, _lr, known, dirs, _st = L.scan_layouts()
    per = collections.defaultdict(list)
    for _k, r in short.items():
        m = RX.match((r['raw'] or '').strip())
        if m and m.group(1) not in bud:
            per[m.group(1)].append(r)
    cand = [(k, v) for k, v in per.items()
            if len({R.frame_of(r['layout']) for r in v}) >= 3
            and all(float(r['over_px']) <= 0.5 for r in v)]
    if not cand:
        print('FAIL khong tim duoc khoa doi chung')
        return 1
    cand.sort(key=lambda t: (-len({R.frame_of(r['layout']) for r in t[1]}), t[0]))
    key, rows = cand[0]
    frames = sorted({R.frame_of(r['layout']) for r in rows})
    fake = frames[0]
    nb = sum(1 for r in rows if R.frame_of(r['layout']) == fake)
    ok = True

    def chk(name, cond, detail=''):
        nonlocal ok
        print(('PASS ' if cond else 'FAIL ') + name + (' | ' + detail if detail else ''))
        ok = ok and cond

    print('khoa doi chung: %s | khung: %d | o: %d | khung ngan sach gia: %s'
          % (key, len(frames), len(rows), fake))
    pos, _t, _s = R.analyse(short, full, {key: (10, fake)}, known, dirs,
                            {key: 'XX'}, {key: 'ban day du gia dinh'}, {})
    chk('DUONG phep quet tim ra khoa bi rut nham, dem dung khung va o',
        pos['rescued_keys'] == 1 and pos['rescued_frames'] == len(frames) - 1
        and pos['rescued_slots'] == len(rows) - nb,
        'keys=%d frames=%d/%d slots=%d/%d' % (pos['rescued_keys'], pos['rescued_frames'],
                                              len(frames) - 1, pos['rescued_slots'], len(rows) - nb))
    neg1, _t1, _s1 = R.analyse(short, full, {key: (10, fake)}, known,
                               dict(dirs, **{fake: set(frames)}), {key: 'XX'},
                               {key: 'ban day du gia dinh'}, {})
    chk('AM1 moi khung deu thuoc ngan sach => khong bao ro ri',
        neg1['rescued_keys'] == 0, 'keys=%d' % neg1['rescued_keys'])
    neg2, _t2, _s2 = R.analyse(short, full, {key: (10, fake)}, known, dirs,
                               {key: 'y het'}, {key: 'y het'}, {})
    chk('AM2 ghi de khong lam doi gia tri => khong co gi de cuu',
        neg2['rescued_keys'] == 0, 'keys=%d' % neg2['rescued_keys'])
    with open(a.out, 'w', encoding='utf-8') as f:
        json.dump({'key': key, 'frames': len(frames), 'slots': len(rows),
                   'positive': pos, 'neg_all_budget': neg1, 'neg_no_change': neg2}, f,
                  ensure_ascii=False, indent=1)
    print('DOI CHUNG TREN DU LIEU THAT:', 'OK' if ok else 'FAILED')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
