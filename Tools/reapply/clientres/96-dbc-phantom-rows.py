# -*- coding: utf-8 -*-
"""[CYS-CLIENTRES 20/09/2026] Dong DBC MA: tro toi tep .path KHONG CO trong SceneFolder.

DAY LA MAY PHAT SINH CUA CA LOP BAY `clientres`, khong phai tung ca le:
  - canh 2220 tro `clientres=1053`; dong 1053 CO THAT trong DBC, "hop le" moi be ngoai,
    nhung `zijinkuafu_spring.*` co **0 tep** trong SceneFolder.
  - 2221/2222/2223 tro 1054/1055/1056 = ba ban do FengYun; SceneFolder co **0 tep** FengYun,
    trong khi server co du **26** tep. Tai nguyen chua bao gio duoc nhap sang client.
Moi dong MA la mot cai hom cho mot `clientres` nao do tro vao. Dem chung la dem san bay min,
thay vi doi tung qua min no.

Phep kiem `scene_install.py survey` cot `client` KHONG bat duoc lop nay: no hoi "co dong DBC
khong", va cau tra loi la CO. Phai hoi them "tep dong do tro toi co ton tai khong".

  python3 96-dbc-phantom-rows.py [--out F]
"""
import argparse
import hashlib
import json
import os
import struct
import sys
import time

MAGIC = b'\x00\xcc\xbb\xdd'
CYS = '/mnt/c/TLBB/085/CY-Source'
CLI_DBC = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'SceneDefineEx.txt')
CLI_SCENE = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'SceneFolder')
SRV_SCENE = '/home/ubuntu/cys-test-20260913/Game_2/Scene'
COL = {'ten': 1, 'wxobject': 4, 'region': 5, 'collision': 6, 'minimap': 7}


def dec(b):
    try:
        return b.decode('utf-8')
    except UnicodeDecodeError:
        return b.decode('gbk', 'replace')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dbc', default=CLI_DBC)
    ap.add_argument('--out', default='')
    a = ap.parse_args()
    b = open(a.dbc, 'rb').read()
    if b[:4] != MAGIC:
        sys.exit('khong phai DBC')
    nF, nR, ps = struct.unpack_from('<3I', b, 4)
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]

    def s(r, c):
        o = cells[r * nF + c]
        e = pool.find(b'\x00', o)
        return dec(pool[o:e if e >= 0 else len(pool)])

    co_cli = {n.lower() for n in os.listdir(CLI_SCENE)}
    co_srv = {n.lower() for n in os.listdir(SRV_SCENE)} if os.path.isdir(SRV_SCENE) else set()
    ma, that, rong = [], 0, 0
    for r in range(nR):
        sid = struct.unpack('<i', struct.pack('<I', cells[r * nF]))[0]
        reg = s(r, COL['region'])
        if not reg.strip():
            rong += 1
            continue
        if reg.lower() in co_cli:
            that += 1
            continue
        ma.append({'id': sid, 'ten': s(r, COL['ten']), 'region': reg,
                   'wxobject': s(r, COL['wxobject']), 'collision': s(r, COL['collision']),
                   'co_o_SERVER': reg.lower() in co_srv})
    co_srv_n = sum(1 for x in ma if x['co_o_SERVER'])
    out = {'dau': 'CYS-CLIENTRES', 'phep': 'dbc-phantom-rows',
           'luc': time.strftime('%Y-%m-%dT%H:%M:%S'), 'dbc': a.dbc,
           'dbc_sha256': hashlib.sha256(b).hexdigest(), 'so_dong': nR,
           'so_dong_co_tep': that, 'so_dong_o_region_rong': rong,
           'so_dong_MA': len(ma),
           'so_dong_MA_ma_SERVER_CO_TEP': co_srv_n,
           'y_nghia_MA_ma_server_co': 'tai nguyen ton tai phia server nhung CHUA NHAP sang client',
           'dong_ma': ma}
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        json.dump(out, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('DBC %s: %d dong | co tep %d | o region rong %d | **DONG MA %d** (server van co tep: %d)'
          % (out['dbc_sha256'][:12], nR, that, rong, len(ma), co_srv_n))
    for x in ma[:25]:
        print('   id %-6d %-26s %-34s server_co_tep=%s' % (
            x['id'], x['ten'][:26], x['region'], x['co_o_SERVER']))
    if len(ma) > 25:
        print('   ... con %d dong nua, xem --out' % (len(ma) - 25))
    return 0


sys.exit(main())
