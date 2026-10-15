# -*- coding: utf-8 -*-
"""[CYS-TANGMEN 20/09/2026] CHEN dong SceneDefineEx cho canh 2220 (Duong Mon) vao DBC client.

VI SAO: `maps-cy4` (17/09) them 2221/2222/2223 nhung BO SOT 2220. Khong co dong o cot 0 = 2220 thi
  Src/Client/WXClient/World/WorldManager.cpp:110-131
      pSceneDef = Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nSceneID);   // 2220 -> truot
      if(!pSceneDef && nResID > 0 && nResID != nSceneID)                        // CYS-SCENERES
          pSceneDef = Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nResID);  // = clientres
tra tiep bang `clientres` cua [scene2220]. Truoc dot nay clientres = 1053, ma dong 1053 la
`zijinkuafu_spring` => BAT CANH LEN MA KHONG THEM DONG NAY = NGUOI CHOI VAO NHAM BAN DO, khong co
mot thong bao loi nao.

CACH LAM: chep NGUYEN VAN 24 o sau cua mot dong CY THAT cua chinh ban do do (615), chi o 0 doi.
String pool KHONG bi cham mot byte (dong moi dung lai dung cac offset chuoi cua dong nguon) - cung
khuon voi 70-sect-scenedef-rows.py. 2220 < 2221 nen phai CHEN GIUA, khong noi duoi (rang buoc
`curIndex < lastIndex` cua DBC + Search_First_Column_Equ tra tren cot 0 da sap xep).

  90-scene2220-row.py plan|apply|verify|undo|build-manifest [--dbc F] [--bak D] [--rows F] [--out F]

`verify` KHONG dua vao ban sao luu: no doi chieu voi BANG KE trong git (data/tangmen-manifest.json),
nen khong het han sau khi dot khac ghi de. Xem Tools/reapply/README_vi.md.
"""
import argparse
import glob
import hashlib
import json
import os
import shutil
import struct
import sys
import time

MAGIC = b'\x00\xcc\xbb\xdd'
T_INT, T_FLOAT, T_STRING = 0, 1, 2
HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
DBC_MAC_DINH = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'SceneDefineEx.txt')
ROWS_MAC_DINH = os.path.join(HERE, 'data', 'tangmen-rows.json')
MANIFEST = os.path.join(HERE, 'data', 'tangmen-manifest.json')
BAK_MAC_DINH = os.path.join(CYS, 'Build', 'reapply-bak', 'tangmen')
TEN_COT = ['nServerID', 'szName', 'nXSize', 'nZSize', 'szWXObjectName', 'szRegionFile',
           'szCollisionfile', 'szMiniMap', 'nBackSound', 'nCol9', 'szSceneMap', 'wmapX', 'wmapY',
           'nameWmapX', 'nameWmapY', 'farClip', 'nearClip', 'szSceneType', 'cityNormalSet',
           'cityNormalImg', 'cityHoverSet', 'cityHoverImg', 'szDisplayName', 'szCol23', 'unk24']


def dbc_read(path):
    b = open(path, 'rb').read()
    if b[:4] != MAGIC:
        sys.exit('%s khong phai DBC 00CCBBDD' % path)
    nF, nR, pool_size = struct.unpack_from('<3I', b, 4)
    types = list(struct.unpack_from('<%dI' % nF, b, 16))
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]
    if len(pool) != pool_size:
        sys.exit('%s: pool %d byte != header %d' % (path, len(pool), pool_size))
    return {'path': path, 'nF': nF, 'nR': nR, 'types': types, 'cells': cells, 'pool': pool,
            'pool_goc': bytes(pool), 'sha256': hashlib.sha256(b).hexdigest(), 'byte': len(b)}


def dbc_write(path, d):
    assert d['pool'] == d['pool_goc'], 'pool da bi doi - tu choi ghi'
    out = bytearray(MAGIC)
    out += struct.pack('<3I', d['nF'], d['nR'], len(d['pool']))
    out += struct.pack('<%dI' % d['nF'], *d['types'])
    out += struct.pack('<%dI' % (d['nF'] * d['nR']), *d['cells'])
    out += d['pool']
    tmp = path + '.tangmen.tmp'
    open(tmp, 'wb').write(bytes(out))
    os.replace(tmp, path)


def sid(d, r):
    return struct.unpack('<i', struct.pack('<I', d['cells'][r * d['nF']]))[0]


def ids_of(d):
    return [sid(d, r) for r in range(d['nR'])]


def row_index(d, wanted):
    for r in range(d['nR']):
        if sid(d, r) == wanted:
            return r
    return None


def s_at(pool, o):
    e = pool.find(b'\x00', o)
    raw = pool[o:e if e >= 0 else len(pool)]
    try:
        return raw.decode('utf-8')            # cot chu hien thi (du an chay UTF-8 tu 24/08)
    except UnicodeDecodeError:
        return raw.decode('gbk', 'replace')   # cot khoa tai nguyen co chu Han: BYTE GBK


def row_values(d, r):
    out = []
    for c in range(d['nF']):
        v = d['cells'][r * d['nF'] + c]
        if d['types'][c] == T_STRING:
            out.append(s_at(d['pool'], v))
        elif d['types'][c] == T_FLOAT:
            out.append(struct.unpack('<f', struct.pack('<I', v))[0])
        else:
            out.append(struct.unpack('<i', struct.pack('<I', v))[0])
    return out


def mota(d, r):
    return dict(zip(TEN_COT, row_values(d, r)))


def doc_chep(rows_file):
    k = json.load(open(rows_file, encoding='utf-8'))
    return {int(a): int(b) for a, b in k['chep'].items()}


def emit(rec, args):
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    if getattr(args, 'out', ''):
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        json.dump(rec, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)


def bat_bien(d):
    loi = []
    ids = ids_of(d)
    if d['nF'] != 25:
        loi.append('so cot = %d, phai la 25' % d['nF'])
    if ids != sorted(ids):
        loi.append('cot 0 khong tang dan')
    if len(ids) != len(set(ids)):
        loi.append('co ID trung')
    if not d['pool'] or d['pool'][-1:] != b'\x00':
        loi.append('pool khong ket thuc bang NUL')
    return loi


def cmd_plan(args):
    d = dbc_read(args.dbc)
    chep = doc_chep(args.rows)
    ids = ids_of(d)
    rec = {'lenh': 'plan', 'file': args.dbc, 'sha256': d['sha256'], 'so_dong': d['nR'],
           'bat_bien_vi_pham': bat_bien(d), 'se_chen': []}
    for moi, nguon in sorted(chep.items()):
        r = row_index(d, nguon)
        vt = sum(1 for i in ids if i < moi)
        rec['se_chen'].append({'ID_moi': moi, 'chep_tu_dong_CY': nguon,
                               'da_co_dong_dich': moi in ids, 'chen_vao_hang': vt,
                               'giua': [ids[vt - 1] if vt else None,
                                        ids[vt] if vt < len(ids) else None],
                               'noi_dung_nguon': mota(d, r) if r is not None else 'KHONG TIM THAY'})
    emit(rec, args)
    return 0


def cmd_apply(args):
    d = dbc_read(args.dbc)
    chep = doc_chep(args.rows)
    loi = bat_bien(d)
    if loi:
        sys.exit('DBC vi pham bat bien truoc khi ghi: %s' % loi)
    ids = ids_of(d)
    them = {k: v for k, v in chep.items() if k not in ids}
    if not them:
        emit({'lenh': 'apply', 'da_du': True, 'so_them': 0, 'so_dong': d['nR'],
              'sha256': d['sha256']}, args)
        return 0
    os.makedirs(args.bak, exist_ok=True)
    bak = os.path.join(args.bak, 'SceneDefineEx.txt.truoc-tangmen-'
                       + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()))
    shutil.copy2(args.dbc, bak)
    n = d['nF']
    cells_cu = list(d['cells'])
    ghi = []
    for moi in sorted(them):
        r = row_index(d, them[moi])
        if r is None:
            sys.exit('khong co dong nguon %d' % them[moi])
        row = list(d['cells'][r * n:(r + 1) * n])
        row[0] = struct.unpack('<I', struct.pack('<i', moi))[0]
        vt = sum(1 for i in ids_of(d) if i < moi)
        d['cells'][vt * n:vt * n] = row
        d['nR'] += 1
        ghi.append({'ID_moi': moi, 'chep_tu': them[moi], 'chen_vao_hang': vt})
    # BAT BIEN TRUOC KHI GHI: bo dung cac hang vua chen phai ra LAI mang cells cu, tung o mot.
    moi_ids = set(them)
    con_lai = []
    for r in range(d['nR']):
        if sid(d, r) not in moi_ids:
            con_lai.extend(d['cells'][r * n:(r + 1) * n])
    if con_lai != cells_cu:
        sys.exit('bat bien hong: bo cac hang moi khong ra lai mang cells cu - KHONG ghi')
    if len(d['cells']) != len(cells_cu) + len(them) * n:
        sys.exit('so o khong dung - KHONG ghi')
    loi = bat_bien(d)
    if loi:
        sys.exit('sau khi chen vi pham bat bien: %s - KHONG ghi' % loi)
    dbc_write(args.dbc, d)
    d2 = dbc_read(args.dbc)
    d0 = dbc_read(bak)
    emit({'lenh': 'apply', 'sao_luu': bak, 'so_them': len(ghi), 'da_them': ghi,
          'so_dong_truoc': d0['nR'], 'so_dong_sau': d2['nR'],
          'pool_khong_doi': d2['pool'] == d0['pool'],
          'pool_byte': len(d2['pool']),
          'sha256_truoc': d0['sha256'], 'sha256_sau': d2['sha256'],
          'kiem_lai': {str(k): mota(d2, row_index(d2, k)) for k in sorted(them)}}, args)
    return 0


def cmd_build_manifest(args):
    d = dbc_read(args.dbc)
    chep = doc_chep(args.rows)
    bk = {'dau': 'CYS-TANGMEN', 'ngay': time.strftime('%Y-%m-%d'), 'ten_cot': TEN_COT, 'dong': {}}
    for moi, nguon in sorted(chep.items()):
        r = row_index(d, moi)
        if r is None:
            sys.exit('DBC chua co dong %d - chay apply truoc' % moi)
        bk['dong'][str(moi)] = {'chep_tu': nguon, 'o': row_values(d, r)}
    json.dump(bk, open(MANIFEST, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    emit({'lenh': 'build-manifest', 'bang_ke': MANIFEST, 'so_dong': len(bk['dong'])}, args)
    return 0


def cmd_verify(args):
    d = dbc_read(args.dbc)
    chep = doc_chep(args.rows)
    n = d['nF']
    loi = bat_bien(d)
    chi_tiet = {}
    for moi, nguon in sorted(chep.items()):
        a = row_index(d, moi)
        b = row_index(d, nguon)
        if a is None:
            loi.append('MAT dong %d' % moi)
            continue
        if b is None:
            loi.append('mat dong nguon %d' % nguon)
        elif d['cells'][a * n + 1:(a + 1) * n] != d['cells'][b * n + 1:(b + 1) * n]:
            loi.append('dong %d khac dong nguon %d (24 o sau)' % (moi, nguon))
        chi_tiet[str(moi)] = mota(d, a)
    # doi chieu bang ke trong git (khong dua vao ban sao luu)
    if os.path.exists(MANIFEST):
        bk = json.load(open(MANIFEST, encoding='utf-8'))
        for moi, m in bk['dong'].items():
            r = row_index(d, int(moi))
            if r is None:
                loi.append('bang ke: MAT dong %s' % moi)
                continue
            v = row_values(d, r)
            khac = [(TEN_COT[i], m['o'][i], v[i]) for i in range(len(v)) if m['o'][i] != v[i]]
            if khac:
                loi.append('bang ke: dong %s LECH o %s' % (moi, khac))
    else:
        loi.append('chua co bang ke %s - chay build-manifest' % MANIFEST)
    rec = {'lenh': 'verify', 'file': args.dbc, 'so_dong': d['nR'], 'so_cot': d['nF'],
           'sha256': d['sha256'], 'ok': not loi, 'loi': loi, 'dong': chi_tiet}
    emit(rec, args)
    return 0 if rec['ok'] else 1


def cmd_undo(args):
    bs = sorted(glob.glob(os.path.join(args.bak, 'SceneDefineEx.txt.truoc-tangmen-*')))
    if not bs:
        sys.exit('khong co ban sao luu trong %s' % args.bak)
    shutil.copy2(bs[-1], args.dbc)
    d = dbc_read(args.dbc)
    emit({'lenh': 'undo', 'tu': bs[-1], 'so_dong': d['nR'], 'sha256': d['sha256']}, args)
    return 0


ap = argparse.ArgumentParser()
sub = ap.add_subparsers(dest='cmd')
for _n in ('plan', 'apply', 'verify', 'undo', 'build-manifest'):
    _a = sub.add_parser(_n)
    _a.add_argument('--dbc', default=DBC_MAC_DINH)
    _a.add_argument('--rows', default=ROWS_MAC_DINH)
    _a.add_argument('--bak', default=BAK_MAC_DINH)
    _a.add_argument('--out', default='')
_args = ap.parse_args()
_f = {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify, 'undo': cmd_undo,
      'build-manifest': cmd_build_manifest}.get(_args.cmd)
sys.exit(_f(_args) if _f else (ap.print_help() or 2))
