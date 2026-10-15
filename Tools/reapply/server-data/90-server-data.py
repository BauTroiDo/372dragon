#!/usr/bin/env python3
"""90-server-data.py - ap lai TOAN BO thay doi cua nhanh `server-data` len server rieng.

Ba thay doi, ba cong cu, mot lenh. Tat ca deu **idempotent**: chay lai khong them gi.

  1. `impact_map.py`      329 ID impact vat pham -> truc CY (`ID + 30000`), 341 o trong 341 file
                          `Game_2/Script/scripts/**`. Sua o SCRIPT, khong sua bang.
  2. `enhance_rate.py`    `LuaFnEquipEnhance` quay MOT lan (dung cot `ItemEnhance.成功率`) thay vi
                          hai lan (= binh phuong cot). Them mot dong log `[CYS-ENH]`.
  3. `zongmen_tables.py`  them ba bang CY con thieu vao `configs/`: `TalentInfo.txt`,
                          `ZongmenTalent.txt`, `TalentLayerLevel.txt`.
  4. `impact_map.py copy85`  chep nguyen 14 dong tu bang 0.85 vao `configs/StandardImpact.txt` cho
                          cac ID ma script tro toi nhung bang CY khong co (ID dang TRONG ben CY).
                          Luat KHAC voi buoc 1: khong doi o nao, chi them dong. Chay trong `flock`
                          `.scene_install.lock` va tron lai tu bang SONG ngay truoc khi ghi.

Vi sao can thu muc nay (xem `Tools/reapply/README_vi.md`): ba cong cu o `Tools/server/` DUOC git
theo doi, nhung **cay server rieng `/home/ubuntu/cys-test-20260913` thi khong nam trong repo nay**.
Neu ai do dung lai server tu ban goc / tu `git checkout` cua cay R, ba thay doi tren bien mat ma
**khong co gi trong CY-Source bao rang chung tung ton tai**. File nay la cong thuc lam lai.

CHAY (trong WSL TLBB, bang root):

    python3 -B Tools/reapply/server-data/90-server-data.py plan
    python3 -B Tools/reapply/server-data/90-server-data.py apply
    python3 -B Tools/reapply/server-data/90-server-data.py verify

`apply` **khong restart** - `Game_2/Script/**`, `lualib/*.lua` va `configs/*.txt` deu chi duoc nap
luc khoi dong skynet. Sau khi ap xong phai co MOT lan restart thi moi co tac dung.

HOAN TAC (moi cong cu co lenh rieng, deu chep nguoc tu thu muc sao luu trong `R/backups/`):

    python3 -B Tools/server/impact_map.py     revert --backup R/backups/impact-map-<UTC>
    python3 -B Tools/server/enhance_rate.py   revert --backup R/backups/enhance-rate-<UTC>
    python3 -B Tools/server/zongmen_tables.py revert            # ba bang la file MOI -> xoa
"""
import argparse
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
TOOLS = os.path.join(ROOT, 'Tools', 'server')
STAGING = '/tmp/reapply-server-data'

STEPS = (
    ('impact_map', 'impact_map.py', os.path.join(STAGING, 'impact-map')),
    ('zongmen_tables', 'zongmen_tables.py', os.path.join(STAGING, 'zongmen')),
    ('enhance_rate', 'enhance_rate.py', None),          # khong co plan/staging
)


def run(tool, *args):
    cmd = [sys.executable, '-B', os.path.join(TOOLS, tool)] + list(args)
    print('\n$ ' + ' '.join(cmd))
    r = subprocess.run(cmd, env={**os.environ, 'PYTHONIOENCODING': 'utf-8'})
    return r.returncode


def cmd_plan(_a):
    rc = 0
    for name, tool, stage in STEPS:
        if stage is None:
            rc |= run(tool, 'audit')
        else:
            os.makedirs(stage, exist_ok=True)
            rc |= run(tool, 'plan', '--out', stage)
    return rc


def cmd_apply(_a):
    rc = 0
    for name, tool, stage in STEPS:
        if stage is None:
            rc |= run(tool, 'apply', '--stage', 'fix')
        else:
            if not os.path.exists(os.path.join(stage, 'plan.json')):
                os.makedirs(stage, exist_ok=True)
                rc |= run(tool, 'plan', '--out', stage)
            rc |= run(tool, 'apply', '--staging', stage)
    # buoc 4: chep 14 dong 0.85 con thieu vao bang CY (luat KHAC - chep dong, khong doi truc).
    # Tu chay trong `flock` va tron lai tu bang SONG, nen an toan khi nhanh khac cung ghi bang.
    rc |= run('impact_map.py', 'copy85')
    print('\n*** DA AP XONG - CAN MOT LAN RESTART SERVER thi cac thay doi moi co tac dung ***')
    return rc


def cmd_verify(_a):
    rc = 0
    for name, tool, _stage in STEPS:
        rc |= run(tool, 'verify')
    return rc


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('plan').set_defaults(fn=cmd_plan)
    sub.add_parser('apply').set_defaults(fn=cmd_apply)
    sub.add_parser('verify').set_defaults(fn=cmd_verify)
    a = ap.parse_args()
    sys.exit(a.fn(a))


if __name__ == '__main__':
    main()
