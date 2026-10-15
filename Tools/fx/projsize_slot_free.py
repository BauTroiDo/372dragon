# -*- coding: utf-8 -*-
"""CYS-PROJSIZE: cong khe `Game.exe`, VA them mot dang dong ma cong chung con mu.

Cong chung `fxcy2_slot_free.py` chi hieu ba dang su kien `NHAN khe` / `TRA khe` / `HUY dong NHAN khe`.
Trong so that con MOT dang nua, `auraring` da va vao luc 10:04 (bay so 7 cua ho):

    relive-point | RESTART SERVER 10:03:57 (lan 2) ... | DA NHAN
    relive-point | RESTART SERVER 10:03:57 (lan 2) ... | DA TRA

`DA NHAN` cua dong RESTART cung la MOT NGUOI DANG GIU KHE - va con nguy hiem hon `NHAN khe` thuong,
vi trong luc do may chu dang khoi dong lai: dang nhap vao do thi luot hong ma loi se bi do cho ban va.
Cong chung KHONG khop dong nay (regex cua no doi `NHAN`/`TRA` dung sau dau `|` dau tien), nen no bao
"khong ai dang giu khe".

Bo do nay KHONG sua tep cua nguoi khac (ba nhanh dang chay tren no ngay luc nay). No goi cong chung
roi CONG THEM luat RESTART. Khe rong <=> cong chung noi rong VA khong co RESTART nao dang mo.

    python -B Tools/fx/projsize_slot_free.py             # ma thoat 0 = rong, 1 = ban
    python -B Tools/fx/projsize_slot_free.py --selftest
"""
import argparse
import io
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
# BAY DA SAP NGAY KHI VIET BO DO NAY: trong mot WORKTREE, `Build/game-slot-queue.txt` KHONG TON TAI
# (so nam o CAY CHINH, khong duoc theo doi boi git). Neu bo do tu suy duong tu vi tri tep cua no thi
# no doc so CUA WORKTREE => khong co ai giu khe => bao RONG oan. Lan dau chay no NEM (tep khong co),
# tuc no bao to chu khong bao xanh - dung hanh vi can co. So khe la TAI NGUYEN CHUNG, ghim cung.
CYS = os.path.join('C:' + os.sep, 'TLBB', '085', 'CY-Source')
QUEUE = os.path.join(CYS, 'Build', 'game-slot-queue.txt')
SHARED = os.path.join(CYS, 'Tools', 'fx', 'fxcy2_slot_free.py')

# "<nhanh> | RESTART SERVER <gio> ... | DA NHAN"  /  "... | DA TRA"
RESTART = re.compile(r'^\s*([A-Za-z0-9._-]+)\s*[|:]\s*RESTART\s+SERVER\b.*\|\s*DA\s+(NHAN|TRA)\b', re.I)


def restart_holders(text):
    """Nhanh nao co su kien RESTART cuoi cung la DA NHAN (may chu co the dang khoi dong lai)."""
    last = {}
    for raw in text.replace('\r\n', '\n').replace('\r', '\n').split(chr(10)):
        m = RESTART.match(raw)
        if not m:
            continue
        last[m.group(1)] = m.group(2).upper()
    return sorted(w for w, e in last.items() if e == 'NHAN')


def shared_gate():
    """(ma thoat, dong trang thai) cua cong chung."""
    p = subprocess.run([sys.executable, '-B', SHARED], capture_output=True, text=True, errors='replace')
    return p.returncode, (p.stdout or '').strip()


def selftest():
    t = chr(10).join([
        'aa | RESTART SERVER 10:00:00 (lan 1) | ... | DA NHAN',
        'aa | RESTART SERVER 10:00:00 (lan 1) | ... | DA TRA',
        'bb | RESTART SERVER 11:00:00 (lan 2) | ... | DA NHAN',
        'cc | NHAN khe (09:00) | ...',
        'dd | RESTART SERVER sap toi | SE XIN | chua co DA NHAN',
    ])
    ok = []
    h = restart_holders(t)
    ok.append(('bb dang giu (RESTART mo)', h == ['bb']))
    ok.append(('aa da tra thi khong tinh', 'aa' not in h))
    ok.append(('dong NHAN khe thuong khong lot vao luat nay', 'cc' not in h))
    ok.append(('dong RESTART chua co DA NHAN thi khong tinh', 'dd' not in h))
    ok.append(('so rong => khong ai giu', restart_holders('') == []))
    ok.append(('doc duoc so that', isinstance(
        restart_holders(io.open(QUEUE, encoding='utf-8', errors='replace').read()), list)))
    rc, line = shared_gate()
    ok.append(('goi duoc cong chung', rc in (0, 1) and 'Game.exe' in line))
    for n, r in ok:
        print(('PASS  ' if r else 'FAIL  ') + n)
    return all(r for _, r in ok)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    out = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    if a.selftest:
        sys.exit(0 if selftest() else 1)
    rc, line = shared_gate()
    rs = restart_holders(io.open(QUEUE, encoding='utf-8', errors='replace').read())
    out.write('cong chung: %s (rc=%d)\n' % (line, rc))
    out.write('RESTART SERVER dang mo: %s\n' % (', '.join(rs) if rs else '(khong ai)'))
    free = (rc == 0 and not rs)
    out.write('KHE %s\n' % ('RONG' if free else 'BAN'))
    out.flush()
    sys.exit(0 if free else 1)


if __name__ == '__main__':
    main()
