# -*- coding: utf-8 -*-
"""[CYS-TANGMEN 20/09/2026] Canh <N> co tro dung TAI NGUYEN CLIENT khong - do bang sha256, KHONG bang ten.

BAY DA CAN DU AN BON LAN (`clientres` / `huashan` vs `huashan_10`): hai ban do TEN GIONG NHAU van
la hai hinh hoc khac nhau. Phep kiem duy nhat dung duoc la so BYTE cua navmesh hai phia.

Duong do (dung dung thu tu client that chay):
  1. server  configs/SceneInfo.ini      [sceneN] -> file=<X>.scn, clientres=R, active
  2. server  Game_2/Scene/<X>.scn       -> navmapname=<Y>.path          (navmesh SERVER dung)
  3. client  SceneDefineEx.txt          dong cot0 == N   (WorldManager.cpp:110)
             khong co thi dong cot0 == R (CYS-SCENERES, WorldManager.cpp:119-122)
             khong co ca hai -> client nem TDThrow "Invalid scene ID"
  4. client  SceneFolder/<szRegionFile> (navmesh CLIENT se ve)
  DAT khi sha256(2) == sha256(4).   LECH_HASH khi hai ben khac byte (= sai ban do, im lang).

PHEP KIEM NAY CO CACH DE TRUOT: chay `--all` tren toan bo canh `type=0` dang bat se ra ca DAT lan
LECH_HASH tren du lieu that (vd canh 495 唐家堡). Mot phep kiem ma moi thu deu "dat" thi dang nghi
chinh no, khong phai tin ket qua (DIEU-PHOI-19-09 muc 17).

  python3 92-scene-res-check.py --scenes 2220,2221,2222,2223 [--out F]
  python3 92-scene-res-check.py --all [--out F]
  (chay TRONG WSL: can doc ca /home/ubuntu/... lan /mnt/c/...)
"""
import argparse
import hashlib
import json
import os
import re
import struct
import sys

MAGIC = b'\x00\xcc\xbb\xdd'
R = '/home/ubuntu/cys-test-20260913'
CYS = '/mnt/c/TLBB/085/CY-Source'
SCENEINFO = os.path.join(R, 'configs', 'SceneInfo.ini')
SRV_SCENE = os.path.join(R, 'Game_2', 'Scene')
CLI_DBC = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'SceneDefineEx.txt')
CLI_SCENE = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'SceneFolder')
COL_REGION = 5           # szRegionFile
COL_OBJ = 4              # szWXObjectName


def dec(b):
    try:
        return b.decode('utf-8')
    except UnicodeDecodeError:
        return b.decode('gbk', 'replace')


def doc_sceneinfo(path):
    raw = open(path, 'rb').read()
    poss = [(m.start(), dec(m.group(1))) for m in re.finditer(rb'^\[([^\]\r\n]+)\]', raw, re.M)]
    out = {}
    for i, (st, name) in enumerate(poss):
        en = poss[i + 1][0] if i + 1 < len(poss) else len(raw)
        kv = {}
        for line in raw[st:en].split(b'\n'):
            line = line.strip(b'\r')
            if b'=' in line and not line.startswith(b'['):
                k, v = line.split(b'=', 1)
                kv[dec(k).strip()] = dec(v).strip()
        out[name] = kv
    return out


def doc_dbc(path):
    b = open(path, 'rb').read()
    if b[:4] != MAGIC:
        sys.exit('%s khong phai DBC' % path)
    nF, nR, pool_size = struct.unpack_from('<3I', b, 4)
    types = list(struct.unpack_from('<%dI' % nF, b, 16))
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]
    idx = {}
    for r in range(nR):
        i = struct.unpack('<i', struct.pack('<I', cells[r * nF]))[0]
        idx.setdefault(i, r)
    return {'nF': nF, 'nR': nR, 'types': types, 'cells': cells, 'pool': pool, 'idx': idx,
            'sha256': hashlib.sha256(b).hexdigest()}


def o_chuoi(d, r, c):
    off = d['cells'][r * d['nF'] + c]
    e = d['pool'].find(b'\x00', off)
    return dec(d['pool'][off:e if e >= 0 else len(d['pool'])])


def hash_file(p):
    if not os.path.isfile(p):
        d = os.path.dirname(p)
        t = os.path.basename(p).lower()
        cand = [n for n in os.listdir(d) if n.lower() == t] if os.path.isdir(d) else []
        if not cand:
            return None, None
        p = os.path.join(d, cand[0])
    b = open(p, 'rb').read()
    return hashlib.sha256(b).hexdigest(), len(b)


def navmap_cua_scn(scn_name):
    p = os.path.join(SRV_SCENE, scn_name)
    if not os.path.isfile(p):
        cand = [n for n in os.listdir(SRV_SCENE) if n.lower() == scn_name.lower()]
        if not cand:
            return None
        p = os.path.join(SRV_SCENE, cand[0])
    txt = dec(open(p, 'rb').read())
    m = re.search(r'navmapname\s*=\s*([^\r\n;]+)', txt)
    return m.group(1).strip() if m else None


def kiem(si, dbc, n):
    key = 'scene%d' % n
    s = si.get(key)
    rec = {'scene': n}
    if not s:
        rec['ket_qua'] = 'KHONG CO [sceneN]'
        return rec
    rec['active'] = s.get('active')
    rec['type'] = s.get('type')
    rec['file'] = s.get('file')
    rec['clientres'] = s.get('clientres')
    nav = navmap_cua_scn(s.get('file', '')) if s.get('file') else None
    rec['server_navmap'] = nav
    if nav:
        h, b = hash_file(os.path.join(SRV_SCENE, nav))
        rec['server_sha256'], rec['server_byte'] = h, b
    else:
        rec['server_sha256'] = None
    # tra dong DBC dung THU TU CUA CLIENT
    r = dbc['idx'].get(n)
    duong = 'sceneid'
    if r is None:
        cr = int(s['clientres']) if str(s.get('clientres', '')).lstrip('-').isdigit() else -1
        if cr > 0 and cr != n:
            r = dbc['idx'].get(cr)
            duong = 'client_res'
    rec['duong_tra_DBC'] = duong if r is not None else 'KHONG TRA DUOC'
    if r is None:
        rec['ket_qua'] = 'KHONG CO DONG DBC -> client nem TDThrow "Invalid scene ID"'
        return rec
    rec['dbc_hang'] = r
    rec['dbc_id'] = struct.unpack('<i', struct.pack('<I', dbc['cells'][r * dbc['nF']]))[0]
    rec['client_obj'] = o_chuoi(dbc, r, COL_OBJ)
    rec['client_region'] = o_chuoi(dbc, r, COL_REGION)
    h, b = hash_file(os.path.join(CLI_SCENE, rec['client_region']))
    rec['client_sha256'], rec['client_byte'] = h, b
    if rec['server_sha256'] is None:
        rec['ket_qua'] = 'KHONG DOC DUOC navmesh SERVER'
    elif h is None:
        rec['ket_qua'] = 'THIEU TEP navmesh CLIENT: %s' % rec['client_region']
    elif h == rec['server_sha256']:
        rec['ket_qua'] = 'DAT'
    else:
        rec['ket_qua'] = 'LECH_HASH (server %s... != client %s...)' % (
            rec['server_sha256'][:10], h[:10])
    return rec


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scenes', default='')
    ap.add_argument('--all', action='store_true')
    ap.add_argument('--sceneinfo', default=SCENEINFO)
    ap.add_argument('--dbc', default=CLI_DBC)
    ap.add_argument('--out', default='')
    a = ap.parse_args()
    si = doc_sceneinfo(a.sceneinfo)
    dbc = doc_dbc(a.dbc)
    if a.all:
        ns = sorted(int(k[5:]) for k in si
                    if k.startswith('scene') and k[5:].isdigit()
                    and str(si[k].get('active')) == '1' and str(si[k].get('type')) == '0')
    else:
        ns = [int(x) for x in a.scenes.split(',') if x.strip()]
    rows = [kiem(si, dbc, n) for n in ns]
    dem = {}
    for r in rows:
        k = r['ket_qua'].split(' ')[0]
        dem[k] = dem.get(k, 0) + 1
    out = {'dau': 'CYS-TANGMEN', 'sceneinfo': a.sceneinfo, 'dbc': a.dbc,
           'dbc_sha256': dbc['sha256'], 'dbc_so_dong': dbc['nR'],
           'so_canh_kiem': len(rows), 'thong_ke': dem, 'canh': rows}
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        json.dump(out, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('DBC %s (%d dong)  kiem %d canh  => %s' % (dbc['sha256'][:12], dbc['nR'], len(rows), dem))
    for r in rows:
        print('  scene %-6s active=%-3s type=%-3s file=%-26s clientres=%-6s duong=%-12s '
              'dbc_id=%-6s region=%-24s  %s'
              % (r['scene'], r.get('active'), r.get('type'), r.get('file'), r.get('clientres'),
                 r.get('duong_tra_DBC'), r.get('dbc_id'), r.get('client_region'), r['ket_qua']))
    return 0 if all(r['ket_qua'] == 'DAT' for r in rows) else 1


sys.exit(main())
