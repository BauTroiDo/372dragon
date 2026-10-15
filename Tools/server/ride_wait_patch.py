#!/usr/bin/env python3
r"""[host-power 17/09/2026] Va cuoc dua 1600 ms / 3000 ms cua duong cuoi thu tren server rieng.

VAN DE (do duoc, khong doan):
  scenecore.lua:6207  push_command_use_skill(21, ...)          -- ky nang 21 "chuan tu khi cuoi thu"
  configs/SkillData_V1.txt dong ID 21: `聚气时间(ms) = 3000`   -- niem 3000 ms
  scenecore.lua:6210  wait_ride_ready(retry): `if retry > 15`  -- bo cuoc sau 16 lan
  scenecore.lua:6221  skynet.timeout(10, ...)                  -- moi lan cho 10 tick = 100 ms
  => cua so cho toi da 1600 ms, trong khi mo hinh cuoi thu chi co the xuat hien sau 3000 ms.
  => server LUON bo cuoc truoc, ghi "[DIAG_RIDE_PK] RIDE_TIMEOUT" va KHONG tra GCCharAutoRide.

BAN VA: nang tran tu 15 len 45 (4,5 giay), du cho 3000 ms cong do tre. Khong doi gi khac.

LUU Y: lualib/services chi nap luc khoi dong skynet, nen ban va chi co hieu luc SAU lan restart ke tiep.
Cong cu nay KHONG restart.

  ride_wait_patch.py audit                 # chi doc: in trang thai hien tai
  ride_wait_patch.py apply [--retries 45]  # sao luu roi va
  ride_wait_patch.py revert --backup DIR   # hoan tac
"""
import argparse
import os
import shutil
import subprocess
import sys
import time

ROOT = '/home/ubuntu/cys-test-20260913'
TARGET = os.path.join(ROOT, 'GameServer/services/scene/scenecore.lua')
OLD = b'        if retry > 15 then'
TAG = b'        if retry > %d then    -- CYS-RIDE: 15 (1600 ms) < 3000 ms niem cua ky nang 21'


def read():
    with open(TARGET, 'rb') as f:
        return f.read()


def audit():
    data = read()
    n_old = data.count(OLD)
    patched = b'CYS-RIDE' in data and b'if retry > 15 then' not in data
    print('file      :', TARGET)
    print('bytes     :', len(data))
    print('dong goc  : %d lan `if retry > 15 then`' % n_old)
    print('da va     :', 'CO' if patched else 'CHUA')
    for line in data.split(b'\n'):
        if b'retry >' in line:
            print('hien tai  :', line.decode('utf-8', 'replace').rstrip())
    return 0 if (n_old == 1 or patched) else 1


def luac_ok(path):
    for exe in ('luac5.4', 'luac5.3', 'luac'):
        try:
            r = subprocess.run([exe, '-p', path], capture_output=True)
            return r.returncode == 0, '%s rc=%d %s' % (exe, r.returncode, r.stderr.decode('utf-8', 'replace')[:200])
        except FileNotFoundError:
            continue
    return True, 'khong co luac de kiem (bo qua)'


def apply(retries):
    data = read()
    if b'CYS-RIDE' in data:
        print('da va tu truoc, khong lam gi (idempotent)')
        return 0
    if data.count(OLD) != 1:
        print('KHONG va: tim thay %d lan `if retry > 15 then`, mong doi dung 1' % data.count(OLD))
        return 2
    stamp = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
    backup = os.path.join(ROOT, 'backups', 'ride-wait-' + stamp)
    os.makedirs(backup, exist_ok=True)
    shutil.copy2(TARGET, os.path.join(backup, 'scenecore.lua'))
    new = data.replace(OLD, TAG % retries, 1)
    tmp = TARGET + '.cys-tmp'
    with open(tmp, 'wb') as f:
        f.write(new)
    ok, note = luac_ok(tmp)
    if not ok:
        os.remove(tmp)
        print('KHONG va: cu phap hong ->', note)
        return 3
    os.replace(tmp, TARGET)
    print('sao luu   :', backup)
    print('luac      :', note)
    print('da va     : retry > 15  ->  retry > %d  (%d ms cho)' % (retries, retries * 100 + 100))
    print('CHUA co hieu luc: phai restart skynet.')
    return 0


def revert(backup):
    src = os.path.join(backup, 'scenecore.lua')
    if not os.path.isfile(src):
        print('khong thay', src)
        return 2
    shutil.copy2(src, TARGET)
    print('da hoan tac tu', backup)
    return 0


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('audit')
    p = sub.add_parser('apply')
    p.add_argument('--retries', type=int, default=45)
    p = sub.add_parser('revert')
    p.add_argument('--backup', required=True)
    a = ap.parse_args()
    if a.cmd == 'audit':
        return audit()
    if a.cmd == 'apply':
        return apply(a.retries)
    return revert(a.backup)


if __name__ == '__main__':
    sys.exit(main())
