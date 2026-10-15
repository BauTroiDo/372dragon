# CYS-MOVE2: recompute the `ours` column of CysHost_Accel_Table.inc from the NEW source of truth.
#
# Why this exists: host-plumbing's generator (Build/Logs/2026-09-17-host-plumbing/scripts/23-gen-accel-inc.py)
# decided `ours` by grepping `case KC_*:` out of GamePro_Main.cpp. move-2 replaced that switch with a table, so the
# grep now finds nothing and the generator would write ours=0 for all 79 rows - which makes SystemSetup:GetInputSetup
# answer "no key" for every row, i.e. an empty key-remap window. Use this instead.
#
# New rule, straight from the table: a row is dispatched by this build unless its action is ACT_NONE or
# ACT_CY_NOT_PORTED. Rows that CY itself leaves unbound (key1 == 0) can never fire, so they report 0 as well.
#
#   python Tools/game/accel_ours_scan.py              # print the column
#   python Tools/game/accel_ours_scan.py --check      # exit 1 if the .inc disagrees (for CI / the generator)
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CORE = os.path.join(ROOT, 'Src', 'Client', 'WXClient', 'Procedure', 'CysAccelCore.h')
INC = os.path.join(ROOT, 'Src', 'Client', 'LuaApiGen', 'CysHost_Accel_Table.inc')
NOT_DISPATCHED = ('ACT_NONE', 'ACT_CY_NOT_PORTED')
# CYS-HOST2 18/09: kRowMeta noi hang do DINH lam gi, con CysAccelTable.cpp moi noi no CO lam gi. Ba nhom duoi day
# co mat trong bang nhung than `case` KHONG lam gi ca, nen bao `ours = 1` la quang cao mot phim bam vao khong
# (dung cai loi "te hon stub" vua sua o CysHost_Accel.cpp). Doc tu CysAccelTable.cpp:365-373:
#   case ACT_DEBUG:        chi lam viec khi `row == 3` (Ctrl+G bat bang go do hoa, trong `#ifndef _FINAL`;
#                          _FINAL KHONG duoc dinh nghia trong cay nay - 0 lan trong build.ninja) => hang 2 va 6 vo tac dung
#   case ACT_SCREENSHOT:   `break;` nhung phim NAY VAN CHAY: CInputSystem::MessageProc bat VK_SNAPSHOT roi goi
#                          GfxSystem->PrintScreen (GMInputSystem.cpp:152-157) => VAN la 1
#   case ACT_SYSTEM_LOCKKEY: `break;` va khong co duong nao khac => CapsLock/ScrollLock/NumLock la 0
NOOP_ACTIONS = ('ACT_SYSTEM_LOCKKEY',)          # than case rong, khong co duong khac
DEBUG_ROWS_THAT_WORK = (3,)                     # ACT_DEBUG chi hang 3 lam viec that


def rows_from_core(path=CORE):
    """[(index, action, arg)] in table order, read from kRowMeta of CysAccelCore.h."""
    text = open(path, encoding='utf-8').read()
    start = text.index('kRowMeta[kRows] =')
    body = text[start:text.index('\n    };', start)]
    out = []
    for m in re.finditer(r'\{\s*(\d+),\s*(0x[0-9a-fA-F]+),\s*(ACT_[A-Z_]+),\s*(\d+),\s*"([^"]*)"', body):
        out.append(dict(id=int(m.group(1)), flags=int(m.group(2), 16), action=m.group(3),
                        has_up=int(m.group(4)), arg=m.group(5)))
    return out


def keys_from_inc(path=INC):
    """[(key1, mod1, key2, mod2, ours)] in table order, read from the generated .inc."""
    text = open(path, encoding='utf-8').read()
    out = []
    for m in re.finditer(r'\{\s*0x([0-9a-f]+),\s*(\d+),\s*0x([0-9a-f]+),\s*(\d+),\s*(\d+)\s*\}', text):
        out.append((int(m.group(1), 16), int(m.group(2)), int(m.group(3), 16), int(m.group(4)), int(m.group(5))))
    return out


def ours_column():
    meta, keys = rows_from_core(), keys_from_inc()
    if len(meta) != 79 or len(keys) != 79:
        raise SystemExit('expected 79 rows, got meta=%d inc=%d' % (len(meta), len(keys)))
    out = []
    for i, (m, k) in enumerate(zip(meta, keys)):
        bound = k[0] != 0 or k[2] != 0
        ok = bound and m['action'] not in NOT_DISPATCHED
        if ok and m['action'] in NOOP_ACTIONS:                       # CYS-HOST2: than case rong
            ok = False
        if ok and m['action'] == 'ACT_DEBUG' and i not in DEBUG_ROWS_THAT_WORK:
            ok = False                                               # CYS-HOST2: chi hang 3 lam viec
        out.append(1 if ok else 0)
    return out, meta, keys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    ours, meta, keys = ours_column()
    current = [k[4] for k in keys]
    print('rows dispatched by this build: %d / 79   (the .inc currently says %d)' % (sum(ours), sum(current)))
    diff = [i for i in range(79) if ours[i] != current[i]]
    for i in diff:
        print('  row %2d id=%-3d action=%-20s key1=0x%02x mod=%d   .inc says %d, should be %d'
              % (i, meta[i]['id'], meta[i]['action'], keys[i][0], keys[i][1], current[i], ours[i]))
    if not diff:
        print('  .inc agrees with the table.')
    if args.check and diff:
        return 1
    print('\ncolumn (one per row, table order):')
    print(' '.join(str(v) for v in ours))
    return 0


if __name__ == '__main__':
    sys.exit(main())
