#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""[host-2 18/09/2026] Nhap hai bang tong mon CHI CO O SERVER vao ConfigFolder cua client CY, dung dinh dang
DBC nhi phan 00CCBBDD ma cac bang cung ho (TalentInfo/ZongmenTalent/TalentLayerLevel) dang dung.

Vi sao: DataPool:Lua_GetSectDesc (client_GL 0x14025a9b0) doc bang SectDesc (DBC id 0x126) va ZongMenSkill.lua goi no
112 lan, nhung Assets/CanonicalCY/Data/ConfigFolder KHONG co SectDesc.txt / SectInfo.txt - chung chi nam o server
(/home/ubuntu/cys-test-20260913/configs/, GBK text, 986 dong moi bang). Dieu phoi cap quyen 18/09: chi THEM MOI,
ghi nguon + sha256 (Registry/batches/2026-09-18-host-2-sect-tables.yaml), cong thuc ap lai o day.

Quy tac chuyen (doi chieu bang dbc_inventory.Table tren TalentInfo.txt cua client):
  * dong 0 = kieu cot (INT/FLOAT/STRING), dong 1 = ten cot (bo qua), tu dong 2 = du lieu; dong rong / bat dau '#' bo qua.
  * kieu cot: INT=0, FLOAT=1, STRING=2 (TYPE_NAMES cua Tools/game/dbc_inventory.py).
  * o STRING = offset vao pool; pool bat dau bang NUL (offset 0 = chuoi rong), chuoi trung nhau dung chung mot offset.
  * O STRING GIU NGUYEN BYTE (GBK) - y nhu pool cua TalentInfo.txt (bat dau b'\\x00\\xce\\xe4...'); chuyen sang UTF-8 la
    viec cua nhanh i18n, khong lam o day (bay all.material: doc errors='replace' roi ghi lai da pha 60.161 vat lieu).
  * khong bao gio ghi de mot tep dich da co (khac noi dung) - "chi them moi".

  70-sect-tables.py plan            : in ra se lam gi
  70-sect-tables.py apply [--force] : ghi (idempotent: tep dich giong het thi bo qua)
  70-sect-tables.py verify          : doc lai bang dbc_inventory.Table, doi chieu so dong / id / sha256 nguon
  70-sect-tables.py undo            : xoa hai tep dich (chi khi sha256 dung bang ban do script nay ghi)
"""
import argparse
import hashlib
import io
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
DATA = os.path.join(HERE, 'data')
DEST = os.path.join(ROOT, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder')
MAGIC = b'\x00\xcc\xbb\xdd'
TYPE_ID = {'INT': 0, 'FLOAT': 1, 'STRING': 2}
# sha256 cua nguon (R/configs, 29/04 04:46) - script tu choi nguon khac.
SOURCES = {
    'SectDesc.txt': '4cc95e8d1c0b6052106f18bd3e91e31b991ec2b310299e70fe4ebf7be75c1caf',
    'SectInfo.txt': '9725f499e14bdf87ec30bd0e35d254bd1c542e39e97f17aba2b82a5dbf300591',
}


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def parse_text(raw):
    lines = raw.split(b'\n')
    types = [c.decode('ascii') for c in lines[0].rstrip(b'\r').split(b'\t')]
    for t in types:
        if t not in TYPE_ID:
            raise SystemExit('kieu cot la: %r' % t)
    rows = []
    for ln in lines[2:]:
        ln = ln.rstrip(b'\r')
        if not ln.strip() or ln.startswith(b'#'):
            continue
        f = ln.split(b'\t')
        if not f[0].strip():
            continue
        # tab thua cuoi dong (SectInfo dong 683 co 27 o, o thu 27 rong): chi cat o RONG vuot qua so cot
        while len(f) > len(types) and not f[-1].strip():
            f.pop()
        if len(f) < len(types):
            f += [b''] * (len(types) - len(f))
        elif len(f) > len(types):
            raise SystemExit('dong %r co %d cot > %d, o thua co noi dung %r' % (f[0], len(f), len(types), f[len(types):]))
        rows.append(f)
    return types, rows


def to_dbc(types, rows):
    pool = bytearray(b'\x00')
    offsets = {b'': 0}
    cells = []
    for r in rows:
        for t, v in zip(types, r):
            v = v.strip() if t != 'STRING' else v
            if t == 'INT':
                cells.append(int(v) & 0xffffffff if v else 0)
            elif t == 'FLOAT':
                cells.append(struct.unpack('<I', struct.pack('<f', float(v) if v else 0.0))[0])
            else:
                if v not in offsets:
                    offsets[v] = len(pool)
                    pool += v + b'\x00'
                cells.append(offsets[v])
    out = bytearray(MAGIC)
    out += struct.pack('<iii', len(types), len(rows), len(pool))
    out += struct.pack('<%dI' % len(types), *[TYPE_ID[t] for t in types])
    out += struct.pack('<%dI' % len(cells), *cells)
    out += pool
    return bytes(out)


def build(name):
    src = os.path.join(DATA, name)
    got = sha(src)
    if got != SOURCES[name]:
        raise SystemExit('nguon %s sha256 %s != %s (khong phai ban da kiem)' % (name, got, SOURCES[name]))
    types, rows = parse_text(open(src, 'rb').read())
    return types, rows, to_dbc(types, rows)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('plan', 'apply', 'verify', 'undo'))
    ap.add_argument('--force', action='store_true', help='apply: ghi de tep dich khac noi dung (mac dinh tu choi)')
    a = ap.parse_args()
    sys.path.insert(0, os.path.join(ROOT, 'Tools', 'game'))
    rc = 0
    for name in SOURCES:
        dst = os.path.join(DEST, name)
        types, rows, blob = build(name)
        ids = [int(r[0]) for r in rows]
        exists = os.path.exists(dst)
        same = exists and sha(dst) == hashlib.sha256(blob).hexdigest()
        line = '%s: %d cot x %d dong, id %d..%d, %d byte, dich %s' % (
            name, len(types), len(rows), min(ids), max(ids), len(blob), 'GIONG-HET' if same else ('DA-CO-KHAC' if exists else 'chua-co'))
        if a.cmd == 'plan':
            print('PLAN', line)
        elif a.cmd == 'apply':
            if same:
                print('BO-QUA', line); continue
            if exists and not a.force:
                print('TU-CHOI (tep dich da co, khac noi dung; --force de ghi de)', line); rc = 1; continue
            tmp = dst + '.host-2.tmp'
            with open(tmp, 'wb') as f:
                f.write(blob)
            os.replace(tmp, dst)
            print('GHI', line, 'sha256', hashlib.sha256(blob).hexdigest()[:16])
        elif a.cmd == 'verify':
            import dbc_inventory as d
            if not exists:
                print('THIEU', line); rc = 1; continue
            t = d.Table(dst)
            ok = t.format == 'binary' and t.records == len(rows) and len(t.types) == len(types) and [r[0] for r in t.rows] == ids
            print('OK' if ok else 'SAI', line, '| doc lai: %s %dx%d' % (t.format, len(t.types), t.records), '| sha256-nguon dung')
            if not ok: rc = 1
        elif a.cmd == 'undo':
            if not exists:
                print('KHONG-CO', name); continue
            if not same:
                print('GIU (tep dich khong phai ban cua script nay)', name); rc = 1; continue
            os.remove(dst); print('XOA', dst)
    sys.exit(rc)


if __name__ == '__main__':
    main()
