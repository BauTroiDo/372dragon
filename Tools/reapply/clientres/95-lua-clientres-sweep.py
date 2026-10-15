# -*- coding: utf-8 -*-
"""[CYS-CLIENTRES 20/09/2026] Quet `client_res` o LOP THU HAI: cac tri so trong Lua cua PHO BAN.

VI SAO CAN TOOL RIENG: `94-clientres-sweep.py` quet khoa `clientres` cua `configs/SceneInfo.ini`.
Do KHONG phai duong duy nhat, va voi pho ban thi no con KHONG phai duong dung:

  scenecore.lua:2031-2033   ret.client_res = self.client_res ; ret.sceneid = self.id
  copyscenemanager_core:29  skynet.call(handle,"lua","register", index + define.COPY_SCENE_BEGIN)
  copyscenecore.lua:113     self.client_res = conf.client_res

=> Canh `type=1` (pho ban) duoc cap phat tu ho dung san, `self.id` = 10001..10020, nen `sceneid`
   client nhan duoc **khong bao gio** la ID `[sceneN]`; trong DBC khong co dong nao mang so do.
   Duong `sceneid` TRUOT MAC DINH voi moi pho ban ⇒ `client_res` la duong DUY NHAT.
   Va `conf.client_res` do **script Lua** dat (`self.g_client_res` / `config.client_res = ...`),
   KHONG doc tu `SceneInfo.ini`.

Do la ly do co **15 dong `client_res`** trong bang ke DBC va vi sao mat chung = "moi pho ban dung".
Mot tri so Lua tro vao ID khong co dong DBC ⇒ `TDThrow "Invalid scene ID"` ⇒ nguoi choi KHONG vao
duoc pho ban do, trong khi server van bao "da vao canh" binh thuong.

  python3 95-lua-clientres-sweep.py [--out F]
  (chay TRONG WSL)
"""
import argparse
import hashlib
import json
import os
import re
import struct
import sys
import time

MAGIC = b'\x00\xcc\xbb\xdd'
R_SRV = '/home/ubuntu/cys-test-20260913'
CYS = '/mnt/c/TLBB/085/CY-Source'
SCRIPT = os.path.join(R_SRV, 'Game_2', 'Script')
CLI_DBC = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'SceneDefineEx.txt')
CLI_SCENE = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'SceneFolder')
MANIFEST_DBC = os.path.join(CYS, 'Tools', 'reapply', 'scenedef', 'data',
                            'scenedef-rows-manifest.json')
COL_REGION = 5

# Chi bat tri so HANG SO. `config.client_res = self.g_client_res` la mot BIEN - khong ket luan gi
# tu no; no duoc lan nguoc ve khai bao `g_client_res = <so>` trong cung tep.
RE_GAN_SO = re.compile(r'(?:^|[^\w.])((?:g_[Cc]lient_?[Rr]es|client_res|ClientRes))\s*=\s*(\d+)')
RE_GAN_BIEN = re.compile(r'(?:config|self)\.client_res\s*=\s*self\.(g_\w+)')
RE_KHAI_BIEN = re.compile(r'\.(g_\w*[Cc]lient_?[Rr]es\w*)\s*=\s*(\d+)')


def dec(b):
    try:
        return b.decode('utf-8')
    except UnicodeDecodeError:
        return b.decode('gbk', 'replace')


def doc_dbc(path):
    b = open(path, 'rb').read()
    if b[:4] != MAGIC:
        sys.exit('%s khong phai DBC' % path)
    nF, nR, ps = struct.unpack_from('<3I', b, 4)
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]
    idx = {}
    for r in range(nR):
        idx.setdefault(struct.unpack('<i', struct.pack('<I', cells[r * nF]))[0], r)
    return {'nF': nF, 'nR': nR, 'cells': cells, 'pool': pool, 'idx': idx,
            'sha256': hashlib.sha256(b).hexdigest()}


def o_chuoi(d, r, c):
    off = d['cells'][r * d['nF'] + c]
    e = d['pool'].find(b'\x00', off)
    return dec(d['pool'][off:e if e >= 0 else len(d['pool'])])


def quet_lua():
    """Tra ve {gia_tri: [(tep, dong, nhan)]} - moi tri so client_res hang so tim duoc."""
    ra = {}
    for root, _, files in os.walk(SCRIPT):
        for fn in files:
            if not fn.endswith('.lua'):
                continue
            p = os.path.join(root, fn)
            try:
                txt = dec(open(p, 'rb').read())
            except OSError:
                continue
            if 'client_res' not in txt and 'ClientRes' not in txt:
                continue
            bien = dict(RE_KHAI_BIEN.findall(txt))
            for i, line in enumerate(txt.split('\n'), 1):
                for m in RE_GAN_SO.finditer(line):
                    ra.setdefault(int(m.group(2)), []).append(
                        (os.path.relpath(p, SCRIPT), i, m.group(1)))
                for m in RE_GAN_BIEN.finditer(line):
                    v = bien.get(m.group(1))
                    if v:
                        ra.setdefault(int(v), []).append(
                            (os.path.relpath(p, SCRIPT), i, m.group(1) + '(lan nguoc)'))
    return ra


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dbc', default=CLI_DBC)
    ap.add_argument('--out', default='')
    a = ap.parse_args()
    dbc = doc_dbc(a.dbc)
    bao_ve = {}
    try:
        mf = json.load(open(MANIFEST_DBC, encoding='utf-8'))
        bao_ve = {int(k): (v.get('dot') if isinstance(v, dict) else None)
                  for k, v in mf['dong'].items()}
    except Exception as e:
        print('CANH BAO: khong doc duoc bang ke (%s)' % e)
    ra = quet_lua()
    rows, dem = [], {}
    for val in sorted(ra):
        r = dbc['idx'].get(val)
        rec = {'client_res': val, 'so_cho_dat': len(ra[val]),
               'cho_dat': [{'tep': t, 'dong': d, 'khoa': k} for t, d, k in ra[val][:8]],
               'co_dong_DBC': r is not None,
               'dot_reapply': bao_ve.get(val),
               'dong_do_CYS_them': val in bao_ve}
        if r is None:
            rec['ket_qua'] = 'KHONG CO DONG DBC -> TDThrow "Invalid scene ID", pho ban DUNG'
        else:
            reg = o_chuoi(dbc, r, COL_REGION)
            rec['region'] = reg
            rec['ten'] = o_chuoi(dbc, r, 1)
            p = os.path.join(CLI_SCENE, reg)
            ok = os.path.isfile(p) or any(
                n.lower() == reg.lower() for n in os.listdir(CLI_SCENE))
            rec['tep_ton_tai'] = ok
            rec['ket_qua'] = 'DAT' if ok else 'THIEU TEP navmesh CLIENT: %s' % reg
        k = rec['ket_qua'].split(' ->')[0].split(':')[0]
        dem[k] = dem.get(k, 0) + 1
        rows.append(rec)
    out = {'dau': 'CYS-CLIENTRES', 'phep': 'lua-client_res', 'luc': time.strftime('%Y-%m-%dT%H:%M:%S'),
           'script': SCRIPT, 'dbc': a.dbc, 'dbc_sha256': dbc['sha256'],
           'so_tri_so': len(rows), 'thong_ke': dem,
           'so_tri_so_do_CYS_them_dong': sum(1 for r in rows if r['dong_do_CYS_them']),
           'tri_so': rows}
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        json.dump(out, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('DBC %s  %d tri so client_res hang so trong Game_2/Script  => %s'
          % (dbc['sha256'][:12], len(rows), dem))
    print('  trong do %d tri so dua vao dong DBC do CY-Source THEM (bang ke reapply)'
          % out['so_tri_so_do_CYS_them_dong'])
    for r in rows:
        if r['ket_qua'] != 'DAT':
            print('  *** %-7s %-2d cho dat  %-46s  vd %s:%s'
                  % (r['client_res'], r['so_cho_dat'], r['ket_qua'],
                     r['cho_dat'][0]['tep'], r['cho_dat'][0]['dong']))
    return 0 if all(r['ket_qua'] == 'DAT' for r in rows) else 1


sys.exit(main())
