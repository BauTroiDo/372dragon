# -*- coding: utf-8 -*-
"""maps-sect: CHEN 2 dong vao SceneDefineEx (DBC 00CCBBDD) cua client cho 唐家堡 va 慕容山庄.

Cung khuon voi Build/Logs/2026-09-17-maps-cy4/scripts/70-client-scenedef-rows.py (maps-cy4), CHI KHAC
mot diem: hai ID cua maps-sect (495, 1358) NHO HON ID lon nhat dang co (2223) nen KHONG the noi vao
cuoi - phai CHEN dung vi tri de cot 0 van tang dan (rang buoc `curIndex < lastIndex` cua DBC).
Ban cua maps-cy4 tu choi truong hop nay (`min(them) <= max(ids)` -> exit), vi vay co file nay.

Vi sao phai them dong: client CY-Source tra SceneDefineEx bang `packet.sceneid` (= ID canh SERVER) o cot 0
  - Src/Client/WXClient/Network/CysModernHandlers.cpp:211  SetSceneID((INT)packet.sceneid, ...)
  - Src/Client/WXClient/World/WorldManager.cpp:96-110       Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nSceneID)
  - Src/Engine/Interface/TDDBC_Struct.h:985                 SCENE_SERVER_ID_COLUMN = 0
Khong co dong -> TDThrow "(CWorldManager::EnterScene) Invalid scene ID" -> client KHONG vao duoc.
Cac ID CO dong dung ban do (615/628 cho tangmen, 284/288/289/561/593 cho gusu) deu DA BI section khac
chiem o phia server (phan lon la canh PCity type=4 dang bat), nen doi ID canh server la khong duoc.

Noi dung dong moi = SAO CHEP NGUYEN VAN 24 o sau cua mot dong CY THAT cua chinh ban do do; chi o 0 doi.
String pool KHONG bi cham mot byte (dong moi dung lai dung cac offset chuoi cua dong nguon).

  70-client-scenedef-rows.py plan|apply|verify [--out F]
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
DBC = r'C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ConfigFolder\SceneDefineEx.txt'
BAK = r'C:\TLBB\085\CY-Source\Build\Logs\2026-09-17-maps-sect\backup-client'
STAGE = r'C:\TLBB\085\CY-Source\Build\world-gui\stage-fps-daiviet\Data\ConfigFolder\SceneDefineEx.txt'
# ID canh server  ->  dong CY that cua ban do do
#   495  唐家堡      <- 615 tangmen.Scene      (canh mon phai cua maps-sect)
#   1358 慕容山庄     <- 284 gusu.scene         (canh mon phai cua maps-sect)
# Tam cai duoi la canh PHAN TUYEN do dot cs3a2 14/09 tu dat ID, DANG BAT ma DBC khong co dong ->
# nguoi choi bi bo phan tuyen day sang tuyen 2 se lam client nem "Invalid scene ID" (dieu phoi 17/09).
#   1311/1315/1316 洛阳-2/3/4 <- 0  luoyang_new.Scene
#   1312 苏州-2               <- 1  suzhou_new.scene
#   1320/1321 大理4/5         <- 2  dali_new_320.Scene
#   1500/2218 地府-2/3        <- 77 siwang.scene
CHEP = {495: 615, 1311: 0, 1312: 1, 1315: 0, 1316: 0, 1320: 2, 1321: 2, 1358: 284, 1500: 77, 2218: 77}


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
        sys.exit('pool %d != header %d' % (len(pool), pool_size))
    return {'nF': nF, 'nR': nR, 'types': types, 'cells': cells, 'pool': pool, 'pool_goc': pool,
            'sha256': hashlib.sha256(b).hexdigest(), 'byte': len(b)}


def dbc_write(path, d):
    assert d['pool'] == d['pool_goc'], 'pool da bi doi - tu choi ghi'
    out = bytearray(MAGIC)
    out += struct.pack('<3I', d['nF'], d['nR'], len(d['pool']))
    out += struct.pack('<%dI' % d['nF'], *d['types'])
    out += struct.pack('<%dI' % (d['nF'] * d['nR']), *d['cells'])
    out += d['pool']
    tmp = path + '.maps-sect.tmp'
    open(tmp, 'wb').write(bytes(out))
    os.replace(tmp, path)


def sid(d, r):
    return struct.unpack('<i', struct.pack('<I', d['cells'][r * d['nF']]))[0]


def s(d, o):
    e = d['pool'].find(b'\0', o)
    return d['pool'][o:e if e >= 0 else len(d['pool'])].decode('utf-8', 'replace')


def ids_of(d):
    return [sid(d, r) for r in range(d['nR'])]


def row_index(d, wanted):
    for r in range(d['nR']):
        if sid(d, r) == wanted:
            return r
    return None


def mota(d, r):
    n = d['nF']
    return {'id': sid(d, r), 'ten': s(d, d['cells'][r * n + 1]),
            'kich_thuoc': '%dx%d' % (d['cells'][r * n + 2], d['cells'][r * n + 3]),
            'scene': s(d, d['cells'][r * n + 4]), 'path': s(d, d['cells'][r * n + 5])}


def emit(rec, args):
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    if getattr(args, 'out', ''):
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        json.dump(rec, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)


def cmd_plan(args):
    d = dbc_read(DBC)
    ids = ids_of(d)
    rec = {'lenh': 'plan', 'file': DBC, 'sha256': d['sha256'], 'so_cot': d['nF'], 'so_dong': d['nR'],
           'cot0_tang_dan': ids == sorted(ids), 'co_ID_trung': len(ids) != len(set(ids)),
           'ID_lon_nhat': max(ids), 'da_co_dong_dich': [k for k in sorted(CHEP) if k in ids],
           'se_chen': []}
    for moi, nguon in sorted(CHEP.items()):
        r = row_index(d, nguon)
        vt = sum(1 for i in ids if i < moi)
        rec['se_chen'].append({'ID_moi': moi, 'chep_tu_dong_CY': nguon,
                               'chen_vao_hang': vt, 'giua': [ids[vt - 1] if vt else None,
                                                             ids[vt] if vt < len(ids) else None],
                               'noi_dung': mota(d, r) if r is not None else 'KHONG TIM THAY'})
    emit(rec, args)
    return 0


def cmd_apply(args):
    d = dbc_read(DBC)
    ids = ids_of(d)
    if ids != sorted(ids):
        sys.exit('cot 0 chua tang dan, khong chen')
    if len(ids) != len(set(ids)):
        sys.exit('DBC dang co ID trung, khong chen')
    them = {k: v for k, v in CHEP.items() if k not in ids}
    if not them:
        emit({'lenh': 'apply', 'da_du': True, 'so_them': 0, 'so_dong': d['nR']}, args)
        return 0
    os.makedirs(BAK, exist_ok=True)
    bak = os.path.join(BAK, 'SceneDefineEx.txt.truoc-maps-sect-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()))
    shutil.copy2(DBC, bak)
    n = d['nF']
    cells_cu = list(d['cells'])
    ghi = []
    for moi in sorted(them):
        r = row_index(d, CHEP[moi])
        if r is None:
            sys.exit('khong co dong CY %d' % CHEP[moi])
        row = list(d['cells'][r * n:(r + 1) * n])
        row[0] = struct.unpack('<I', struct.pack('<i', moi))[0]
        vt = sum(1 for i in ids_of(d) if i < moi)          # chen ngay truoc ID dau tien lon hon
        d['cells'][vt * n:vt * n] = row
        d['nR'] += 1
        ghi.append({'ID_moi': moi, 'chep_tu': CHEP[moi], 'chen_vao_hang': vt})
    # Bat bien truoc khi ghi: bo dung cac hang vua chen thi phai ra LAI mang cells cu, tung o mot.
    moi_ids = set(them)
    con_lai = []
    for r in range(d['nR']):
        if sid(d, r) not in moi_ids:
            con_lai.extend(d['cells'][r * n:(r + 1) * n])
    if con_lai != cells_cu:
        sys.exit('bat bien hong: bo cac hang moi khong ra lai mang cells cu - KHONG ghi')
    if len(d['cells']) != len(cells_cu) + len(them) * n:
        sys.exit('so o khong dung - KHONG ghi')
    ids_moi = ids_of(d)
    if ids_moi != sorted(ids_moi) or len(ids_moi) != len(set(ids_moi)):
        sys.exit('sau khi chen, cot 0 khong tang dan hoac co ID trung - KHONG ghi')
    dbc_write(DBC, d)
    d2 = dbc_read(DBC)
    emit({'lenh': 'apply', 'sao_luu': bak, 'so_them': len(ghi), 'da_them': ghi,
          'so_dong_truoc': d2['nR'] - len(ghi), 'so_dong_sau': d2['nR'], 'sha256_sau': d2['sha256'],
          'kiem_lai': [mota(d2, row_index(d2, k)) for k in sorted(them)]}, args)
    return 0


def cmd_verify(args):
    d = dbc_read(DBC)
    ids = ids_of(d)
    n = d['nF']
    loi = []
    if ids != sorted(ids):
        loi.append('cot 0 khong con tang dan')
    if len(ids) != len(set(ids)):
        loi.append('co ID trung: %s' % sorted({i for i in ids if ids.count(i) > 1}))
    for moi, nguon in sorted(CHEP.items()):
        a, b = row_index(d, moi), row_index(d, nguon)
        if a is None:
            loi.append('thieu dong %d' % moi); continue
        if b is None:
            loi.append('mat dong nguon %d' % nguon); continue
        if d['cells'][a * n + 1:(a + 1) * n] != d['cells'][b * n + 1:(b + 1) * n]:
            loi.append('dong %d khac dong nguon %d' % (moi, nguon))
    bs = sorted(glob.glob(os.path.join(BAK, 'SceneDefineEx.txt.truoc-maps-sect-*')))
    if not bs:
        loi.append('khong tim thay ban sao luu de doi chieu pool')
    else:
        d0 = dbc_read(bs[0])
        if d0['pool'] != d['pool']:
            loi.append('pool da doi so voi ban sao luu %s' % bs[0])
        if d0['nR'] + len(CHEP) != d['nR']:
            loi.append('so dong lech: sao luu %d + %d != %d' % (d0['nR'], len(CHEP), d['nR']))
        moi_ids = set(CHEP)
        giu = []
        for r in range(d['nR']):
            if sid(d, r) not in moi_ids:
                giu.extend(d['cells'][r * n:(r + 1) * n])
        if giu != d0['cells']:
            loi.append('bo 2 hang moi khong ra lai mang cells cua ban sao luu')
    rec = {'lenh': 'verify', 'so_dong': d['nR'], 'sha256': d['sha256'], 'ok': not loi, 'loi': loi,
           'dong_moi': [mota(d, row_index(d, k)) for k in sorted(CHEP) if row_index(d, k) is not None]}
    if os.path.exists(STAGE):
        st = dbc_read(STAGE)
        rec['stage_fps_daiviet'] = {'so_dong': st['nR'], 'sha256': st['sha256'],
                                    'giong_CanonicalCY': st['sha256'] == d['sha256']}
        if st['sha256'] != d['sha256']:
            rec['loi'].append('stage-fps-daiviet dung DBC KHAC CanonicalCY')
            rec['ok'] = False
    else:
        rec['stage_fps_daiviet'] = 'khong co file rieng'
    emit(rec, args)
    return 0 if rec['ok'] else 1


ap = argparse.ArgumentParser()
sub = ap.add_subparsers(dest='cmd')
for _n in ('plan', 'apply', 'verify'):
    _a = sub.add_parser(_n); _a.add_argument('--out', default='')
    # CYS-REVIEW 18/09: README_vi.md goi buoc nay voi `--bak Build/reapply-bak` nhung script khong nhan tham so
    # do -> argparse "unrecognized arguments" -> ca chuoi ap lai 4 buoc dung o buoc 2. Them --bak (thu muc sao
    # luu) va --dbc (file DBC dich, de chay thu tren BAN SAO), mac dinh giu nguyen hanh vi cu.
    _a.add_argument('--bak', default='', help='thu muc giu ban sao luu (mac dinh: maps-sect backup-client)')
    _a.add_argument('--dbc', default='', help='file DBC can sua (mac dinh: CanonicalCY; dat ban sao de tu kiem)')
_args = ap.parse_args()
if getattr(_args, 'bak', ''):
    BAK = _args.bak
if getattr(_args, 'dbc', ''):
    DBC = _args.dbc
    STAGE = ''   # so voi stage-fps-daiviet chi co nghia khi sua dung file CanonicalCY
sys.exit({'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify}.get(_args.cmd, lambda a: ap.print_help() or 2)(_args))
