# -*- coding: utf-8 -*-
"""fx-cy-2 (20/09/2026): khe `Game.exe` co THAT SU rong khong?

VI SAO CAN: dem tien trinh `Game.exe` la CHUA DU. Giua hai luot cua mot nhanh dang giu khe van thay
0 `Game.exe`, nhung KHE VAN BAN (bay da ghi cua `crash-anim`: "Giua hai luot co the thay 0 Game.exe
nhung KHE VAN BAN"). Toi suyt chiem khe cua `scenemap-api` dung kieu do luc 08:30.

LUAT: khe rong <=> (a) 0 tien trinh Game.exe, VA (b) trong `Build\\game-slot-queue.txt`, KHONG nhanh nao
co su kien cuoi cung la `NHAN khe` (moi `NHAN` phai co mot `TRA` sau no, HOAC mot dong `HUY`).

BA DANG SU KIEN CO THAT TRONG SO (dem tren so ngay 19-20/09):
  "<nhanh> | NHAN khe (..)"          -> nhan khe
  "<nhanh> | TRA khe (..)" / "TRA KHE HAN" / "TRA KHE sau luot .." -> tra khe
  "<nhanh> | HUY dong NHAN khe 08:33 - TOI GHI SOM, khe KHONG trong"  -> HUY: dong NHAN truoc do
                                       coi nhu khong ton tai, KHONG can mot dong TRA.
BAY DA SAP (20/09, chinh toi): ban dau bo do khong hieu `HUY` nen van ke `crt-guard` la "dang giu khe"
sau khi ho da tu huy => toi cho mot nhanh KHONG giu khe. Mot cong CHAT QUA cung sai, chi sai theo
huong khac: no chan viec that. Dang `HUY` phai nhan dien, va phai co ca m.

BAY DOC TEP (da ghi trong log hang doi 21:24): doc hang doi PHAI dung split(chr(10)) sau khi bo CR,
KHONG dung splitlines() — splitlines() cat doi dong tai mot ky tu CR nam giua dong va lam mat noi dung.

DUNG:
  python -B Tools/fx/fxcy2_slot_free.py            # in trang thai; ma thoat 0 = rong, 1 = ban
  python -B Tools/fx/fxcy2_slot_free.py --selftest
"""
import argparse
import io
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, '..', '..'))
QUEUE = os.path.join(CYS, 'Build', 'game-slot-queue.txt')
# "<nhanh> | NHAN khe ..." / "<nhanh> | TRA khe ..." / "<nhanh> | HUY dong NHAN khe ..." / "<nhanh>: NHAN khe ..."
# HUY phai duoc thu TRUOC vi chinh no cung chua chuoi "NHAN khe".
EV = re.compile(r'^\s*([A-Za-z0-9._-]+)\s*[|:]\s*'
                r'(HUY[^|]{0,40}?NHAN\s+khe|NHAN\s+KHE|NHAN\s+khe|TRA\s+KHE\s+HAN|TRA\s+KHE|TRA\s+khe)', re.I)


def queue_holders(text):
    """Nhanh nao co su kien cuoi cung la NHAN (dang giu khe)."""
    last = {}
    for raw in text.replace('\r\n', '\n').replace('\r', '\n').split(chr(10)):
        m = EV.match(raw)
        if not m:
            continue
        who, ev = m.group(1), m.group(2).upper()
        if ev.startswith('HUY'):
            last[who] = 'TRA'          # nhanh tu huy dong NHAN cua minh: khong giu khe
        elif ev.startswith('NHAN'):
            last[who] = 'NHAN'
        else:
            last[who] = 'TRA'
    return sorted(w for w, e in last.items() if e == 'NHAN')


def game_exe_count():
    try:
        out = subprocess.run(['tasklist'], capture_output=True, text=True, errors='replace').stdout
    except Exception:
        return -1
    return sum(1 for l in out.split(chr(10)) if l.lower().startswith('game.exe'))


def selftest():
    t = chr(10).join([
        'aa | NHAN khe (01:00) | ...',
        'aa | TRA khe (01:05) | ...',
        'bb | NHAN khe (02:00) | ...',
        'cc | uu tien 5 | SAN SANG, CHO KHE | ...',
        'dd | NHAN khe (03:00) | ...',
        'dd | TRA KHE HAN | ...',
        'ee | NHAN khe (08:33) | uu tien 4 ...',
        'ee | HUY dong NHAN khe 08:33 - TOI GHI SOM, khe KHONG trong | ...',
        'ff | NHAN khe (09:00) | ...',
    ])
    ok = []
    h = queue_holders(t)
    ok.append(('bb va ff dang giu', h == ['bb', 'ff']))
    ok.append(('aa da tra thi khong tinh', 'aa' not in h))
    ok.append(('dd TRA KHE HAN thi khong tinh', 'dd' not in h))
    ok.append(('dong CHO KHE khong phai NHAN', 'cc' not in h))
    # ca quyet dinh: HUY phai go NHAN, va KHONG duoc go nham cua nhanh khac
    ok.append(('ee tu HUY thi khong tinh la dang giu', 'ee' not in h))
    ok.append(('HUY cua ee KHONG go nham ff', 'ff' in h))
    ok.append(('hang doi rong => khong ai giu', queue_holders('') == []))
    ok.append(('bo do doc duoc tep that', isinstance(queue_holders(io.open(QUEUE, encoding='utf-8', errors='replace').read()), list)))
    for n, r in ok:
        print(('PASS  ' if r else 'FAIL  ') + n)
    return all(r for _, r in ok)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--quiet', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        sys.exit(0 if selftest() else 1)
    holders = queue_holders(io.open(QUEUE, encoding='utf-8', errors='replace').read())
    n = game_exe_count()
    free = (n == 0 and not holders)
    if not a.quiet:
        out = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
        out.write('Game.exe = %d | nhanh dang giu khe: %s | KHE %s\n'
                  % (n, ', '.join(holders) if holders else '(khong ai)', 'RONG' if free else 'BAN'))
        out.flush()
    sys.exit(0 if free else 1)


if __name__ == '__main__':
    main()
