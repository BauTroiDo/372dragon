# -*- coding: utf-8 -*-
"""fx-cy-2 (20/09/2026): CHAM NGHIEM THU A/B cho ban va decal Projector.

CHI SO: lech tam vet (centroid) giua mat na hieu ung cua CY va cua ta, do bang mat na held-out cua
`fxbase_compare` (da tu kiem 10/10 PASS). KHONG dung D: D tron dien tich/nang luong/mau/IoU va rat nhay
voi pha thoi gian, trong khi san nhieu CY<->CY cua chinh bo do la 0,71-2,23
(Build\\Logs\\2026-09-20-fx-cy-2\\repeat-floor.txt). Lech tam thi khong phai hien tuong pha.

NGUONG DA DANG KY TRUOC KHI CHAY (ghi trong Build\\game-slot-queue.txt, xem ban giao muc "du doan"):
  (1) canh CYS_FXPROJ=0 : A01-A04 lech ~198-223 px  (tai hien so cu tren binary MOI)
  (2) canh CYS_FXPROJ=1 : A01-A04 lech 2-14 px       (muc cua doi chung)
  (3) CA HAI canh       : REAL13 va Serg02 giu 2-3 px (neu chung cung doi => ban va dung nham thu khac)
Bat ky o nao khong dat => BAO SAI, khong dien giai lai.

DUNG:
  python -B Tools/fx/fxcy2_projector_ab.py --control-rep 2 --patched-rep 3
  python -B Tools/fx/fxcy2_projector_ab.py --selftest
"""
import argparse
import io
import json
import os
import statistics
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, '..', '..'))
CMP = os.path.join(CYS, 'Build', 'Logs', '2026-09-19-fx-cy-baseline', 'compare')

PROJECTORS = ('A01', 'A02', 'A03', 'A04')
CONTROLS = ('REAL13', 'Serg02')
MIN_PX = 1500           # chi lay cap co CA HAI mat na day, nhu phep do goc
BAND_OLD = (150.0, 260.0)   # (1) tai hien lech cu
BAND_FIX = (0.0, 20.0)      # (2) muc doi chung (2-14 px, cho bien do 20)
BAND_CTL = (0.0, 20.0)      # (3) doi chung phai dung yen


def offsets(path):
    """{fid: (|lech|, dx, dy, n)} tu mot compare.json."""
    d = json.load(io.open(path, encoding='utf-8'))
    out = {}
    for r in d['results']:
        det = [p for p in r.get('pairs_detail', [])
               if p['cy']['pixels'] > MIN_PX and p['ours']['pixels'] > MIN_PX]
        if not det:
            continue
        dx = statistics.median([p['ours']['centroid'][0] - p['cy']['centroid'][0] for p in det])
        dy = statistics.median([p['ours']['centroid'][1] - p['cy']['centroid'][1] for p in det])
        out[r['fid']] = ((dx * dx + dy * dy) ** 0.5, dx, dy, len(det))
    return out, d.get('register')


def band(v, lo, hi):
    return lo <= v <= hi


def selftest():
    """Doi chung cho chinh bo cham: no phai bao DAT/ KHONG DAT dung chieu."""
    ok = []
    ok.append(('trong dai cu', band(206.0, *BAND_OLD)))
    ok.append(('ngoai dai cu', not band(8.0, *BAND_OLD)))
    ok.append(('trong dai va', band(8.0, *BAND_FIX)))
    ok.append(('ngoai dai va', not band(206.0, *BAND_FIX)))
    ok.append(('bien duoi dai va', band(20.0, *BAND_FIX) and not band(20.1, *BAND_FIX)))
    for n, r in ok:
        print(('PASS  ' if r else 'FAIL  ') + n)
    return all(r for _, r in ok)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--control-rep', type=int)
    ap.add_argument('--patched-rep', type=int)
    ap.add_argument('--control-dir', default=None)
    ap.add_argument('--patched-dir', default=None)
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        sys.exit(0 if selftest() else 1)

    cdir = a.control_dir or os.path.join(CMP, 'b09-fxproj0')
    pdir = a.patched_dir or os.path.join(CMP, 'b09-fxproj1')
    out = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    rows = []
    for name, d in (('CYS_FXPROJ=0 (doi chung)', cdir), ('CYS_FXPROJ=1 (ban va)', pdir)):
        p = os.path.join(d, 'compare.json')
        if not os.path.exists(p):
            out.write('THIEU: %s\n' % p)
            out.flush()
            sys.exit(2)
        o, reg = offsets(p)
        rows.append((name, o, reg))

    out.write('fx-cy-2 / CYS-FXCY2 - CHAM A/B BAN VA PROJECTOR (lech tam vet, px)\n')
    out.write('So voi CUNG mot luot CY: cy\\b09-r1. Mat na held-out cua fxbase_compare (selftest 10/10).\n\n')
    out.write('%-8s %-26s %-26s\n' % ('fid', rows[0][0], rows[1][0]))
    verdict = []
    for fid in PROJECTORS + CONTROLS:
        cells = []
        for _, o, _ in rows:
            t = o.get(fid)
            cells.append('%7.0f px (dx%+5.0f dy%+4.0f) n=%d' % (t[0], t[1], t[2], t[3]) if t else '        (khong du cap)')
        out.write('%-8s %-26s %-26s\n' % (fid, cells[0], cells[1]))
        c = rows[0][1].get(fid)
        p = rows[1][1].get(fid)
        if c is None or p is None:
            verdict.append((fid, None, 'khong du cap co ca hai mat na day'))
            continue
        if fid in PROJECTORS:
            okc = band(c[0], *BAND_OLD)
            okp = band(p[0], *BAND_FIX)
            verdict.append((fid, okc and okp,
                            'doi chung %s dai cu, ban va %s dai doi chung' %
                            ('TRONG' if okc else 'NGOAI', 'TRONG' if okp else 'NGOAI')))
        else:
            okc = band(c[0], *BAND_CTL)
            okp = band(p[0], *BAND_CTL)
            verdict.append((fid, okc and okp,
                            'phai dung yen o ca hai canh: %s / %s' %
                            ('dat' if okc else 'KHONG', 'dat' if okp else 'KHONG')))
    out.write('\ndang ky anh (dx,dy): doi chung %s | ban va %s\n' % (rows[0][2], rows[1][2]))
    out.write('\n%-8s %-8s %s\n' % ('fid', 'ket qua', 'ly do'))
    for fid, ok, why in verdict:
        out.write('%-8s %-8s %s\n' % (fid, ('DAT' if ok else ('KHONG DAT' if ok is False else '--')), why))
    allok = all(v[1] for v in verdict)
    out.write('\nKET LUAN: %s\n' % ('NGHIEM THU DAT - du doan viet truoc khop tung o.'
                                    if allok else
                                    'KHONG DAT - bao SAI, khong dien giai lai nguong.'))
    out.flush()
    sys.exit(0 if allok else 1)


if __name__ == '__main__':
    main()
