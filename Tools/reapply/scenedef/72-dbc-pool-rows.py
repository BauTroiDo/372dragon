# -*- coding: utf-8 -*-
"""scenes-lo2 (17/09/2026): THEM / SUA dong SceneDefineEx.txt (DBC 00CCBBDD) KEM NOI STRING POOL.

VI SAO CAN CONG CU NAY (khac 70-client-scenedef-rows.py o dung mot diem)
  70-* chi CHEP O (offset vao string pool) tu mot dong nguon da co, va tu chot
  `assert pool == pool_goc`. Vi vay no KHONG the tao dong cho ban do ma pool chua co chuoi
  `<map>.Scene` - dung truong hop 17 ban do nhap tu GL (huashan, shengsileitai, zhulin, yewai,
  jiaofei, yanziwu, PhoenixMaze, bianguan_1..4, huanjing_1..4, dumuchang, huomuchang):
  `Build/Logs/2026-09-17-scene-import-gl/15-pool.json` do: 0/68 ban do co chuoi trong pool.
  Cong cu nay NOI CHUOI MOI VAO CUOI POOL roi cap nhat `poolSize` trong header.

VI SAO NOI POOL LA AN TOAN (Src/Shared/Common/DataBase/TLBB_DBC.cpp OpenFromMemoryImpl_Binary)
  - poolSize doc TU HEADER, cap phat dung bay nhieu roi memcpy; kiem tong kich thuoc tep cung
    tinh theo header  -> khong co hang so kich thuoc o noi khac.
  - O STRING = offset; `pString = pool + (off < size ? off : 0)`  -> offset cu KHONG xe dich khi
    noi them o cuoi; khong noi nao danh chi muc pool theo SO chuoi.
  - `pool[size-1] = 0` bi ep -> pool PHAI ket thuc bang NUL (cong cu bao dam).
  - CreateIndex(0) doi cot 0 tang dan va khong trung (`Multi index at line N`).

QUY UOC MA HOA TRONG POOL CUA CanonicalCY (do that, 17/09: 792 dong)
  - Cot chu hien thi [1] szName, [22] szDisplayName: UTF-8 (du an chay UTF-8 tu 24/08).
  - Cot KHOA TAI NGUYEN [4][5][6][7][10][17..21][23]: ASCII; 35 o co chu Han thi la BYTE GBK
    (vd `\xc8\xfb\xcd\xe2 1.Scene` = 塞外 1.Scene). => chuoi tai nguyen khong-ASCII ghi bang GBK.
    Dot nay moi ten tep deu ASCII nen quy uoc do chi la hang rao.

CACH DUNG
  72-dbc-pool-rows.py plan   --rows data/scenes-lo2-rows.json [--dbc F]
  72-dbc-pool-rows.py apply  --rows data/scenes-lo2-rows.json [--dbc F] [--bak DIR] [--out F]
  72-dbc-pool-rows.py verify --rows data/scenes-lo2-rows.json [--dbc F] [--out F]
  72-dbc-pool-rows.py undo   --rows data/scenes-lo2-rows.json [--dbc F] [--bak DIR] [--out F]
      (reapply-guard 19/09, cho du khuon `plan/apply/verify/undo` cua Tools/reapply/host-2)
      Chi tra lai ban sao luu NAO ma "ban sao luu + ke hoach nay = file hien tai TUNG BYTE".
      Khong ban nao thoa => TU CHOI, khong ghi gi (file da bi dot khac ghi de sau lan apply;
      luc ay hoan tac dung cach la ap lai tu dau theo README, khong phai de mot ban cu len).

  rows JSON: {"schema": 1, "dot": "...", "zero_wmap": true,
              "rows": [{"id": 125, "cells": [25 gia tri], "nguon": "..."}]}
  Moi dong PHAI du 25 o dung kieu cot cua DBC (INT -> so nguyen, STRING -> chuoi).
  - ID da co dong  -> SUA: thay 24 o sau cot 0 (khong doi thu tu dong).
  - ID chua co     -> THEM: chen dung cho de cot 0 van tang dan.
  - Dong da dung y ke hoach -> BO-QUA (idempotent; chay hai lan khong doi mot byte).
  Sau khi ghi: DOC LAI TU DIA va kiem: (1) tung o cua tung dong ke hoach giai ma dung y
  ke hoach; (2) MOI dong ngoai ke hoach giu nguyen tung o; (3) pool cu la TIEN TO cua pool moi;
  (4) cot 0 tang dan, 0 ID trung; (5) pool ket thuc bang NUL; (6) Tools/game/dbc_inventory.Table
  (mo phong TLBB_DBC.cpp) doc lai duoc. Sai bat ky diem nao -> TRA LAI BAN SAO LUU, thoat ma 1.
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
DBC = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'SceneDefineEx.txt')
BAK = os.path.join(CYS, 'Build', 'reapply-bak', 'scenes-lo2')
TEXT_COLS = {1, 22}          # UTF-8 (chu hien thi)
WMAP_COLS = (11, 12, 13, 14)  # toa do ban do the gioi: 0 = khong ve bieu tuong (luat --zero-wmap)
TEN_COT = ['nServerID', 'szName', 'nXSize', 'nZSize', 'szWXObjectName', 'szRegionFile',
           'szCollisionfile', 'szMiniMap', 'nBackSound', 'nCol9', 'szSceneMap', 'wmapX', 'wmapY',
           'nameWmapX', 'nameWmapY', 'farClip', 'nearClip', 'szSceneType', 'cityNormalSet',
           'cityNormalImg', 'cityHoverSet', 'cityHoverImg', 'szDisplayName', 'szCol23', 'unk24']


# ------------------------------------------------------------------ doc / ghi DBC

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
    return {'nF': nF, 'nR': nR, 'types': types, 'cells': cells, 'pool': bytearray(pool),
            'sha256': hashlib.sha256(b).hexdigest(), 'byte': len(b)}


def dbc_bytes(d):
    out = bytearray(MAGIC)
    out += struct.pack('<3I', d['nF'], d['nR'], len(d['pool']))
    out += struct.pack('<%dI' % d['nF'], *d['types'])
    out += struct.pack('<%dI' % (d['nF'] * d['nR']), *d['cells'])
    out += bytes(d['pool'])
    return bytes(out)


def sid(d, r):
    return struct.unpack('<i', struct.pack('<I', d['cells'][r * d['nF']]))[0]


def u32(v):
    return struct.unpack('<I', struct.pack('<i', int(v)))[0]


def s_at(pool, o):
    e = pool.find(b'\0', o)
    return bytes(pool[o:e if e >= 0 else len(pool)])


def decode_cell(b):
    """Giai ma de SO SANH voi ke hoach: UTF-8 truoc, GBK sau (dung quy uoc pool)."""
    try:
        return b.decode('utf-8')
    except UnicodeDecodeError:
        return b.decode('gbk', 'replace')


def encode_cell(col, s):
    if col in TEXT_COLS:
        return s.encode('utf-8')
    try:
        return s.encode('ascii')
    except UnicodeEncodeError:
        return s.encode('gbk')


def row_values(d, r):
    """25 gia tri Python cua hang r (INT -> int, STRING -> str)."""
    out = []
    for c in range(d['nF']):
        v = d['cells'][r * d['nF'] + c]
        if d['types'][c] == T_STRING:
            out.append(decode_cell(s_at(d['pool'], v)))
        elif d['types'][c] == T_FLOAT:
            out.append(struct.unpack('<f', struct.pack('<I', v))[0])
        else:
            out.append(struct.unpack('<i', struct.pack('<I', v))[0])
    return out


def row_index(d, wanted):
    for r in range(d['nR']):
        if sid(d, r) == wanted:
            return r
    return None


def mota(vals):
    return {'id': vals[0], 'ten': vals[1], 'kich_thuoc': '%sx%s' % (vals[2], vals[3]),
            'scene': vals[4], 'path': vals[5], 'wcol': vals[6], 'map': vals[10], 'hien_thi': vals[22]}


class Pool(object):
    """Chi muc {bytes: offset} cua moi doan ket thuc NUL, va noi them o cuoi."""

    def __init__(self, pool):
        self.pool = pool
        self.idx = {}
        i = 0
        n = len(pool)
        while i < n:
            j = pool.find(b'\0', i)
            if j < 0:
                break
            self.idx.setdefault(bytes(pool[i:j]), i)
            i = j + 1
        self.moi = []

    def offset(self, b):
        if b in self.idx:
            return self.idx[b]
        if len(self.pool) and self.pool[-1:] != b'\0':
            self.pool += b'\0'   # bao dam doan truoc ket thuc NUL (khong xay ra voi CanonicalCY)
        o = len(self.pool)
        self.pool += b + b'\0'
        self.idx[b] = o
        self.moi.append((b, o))
        return o


# ------------------------------------------------------------------ ke hoach

def doc_rows(path, nF, types):
    kh = json.load(open(path, encoding='utf-8'))
    rows = kh.get('rows') or []
    if not rows:
        sys.exit('--rows rong')
    ids = [int(r['id']) for r in rows]
    if len(ids) != len(set(ids)):
        sys.exit('--rows co ID trung: %s' % sorted(set(i for i in ids if ids.count(i) > 1)))
    for r in rows:
        cells = r.get('cells')
        if not isinstance(cells, list) or len(cells) != nF:
            sys.exit('dong %s: can dung %d o, co %s' % (r.get('id'), nF, len(cells) if isinstance(cells, list) else cells))
        if int(cells[0]) != int(r['id']):
            sys.exit('dong %s: o [0] (%s) phai bang id' % (r['id'], cells[0]))
        for c, v in enumerate(cells):
            if types[c] == T_STRING and not isinstance(v, str):
                sys.exit('dong %s cot %d (%s) phai la chuoi' % (r['id'], c, TEN_COT[c]))
            if types[c] != T_STRING and not isinstance(v, int):
                sys.exit('dong %s cot %d (%s) phai la so nguyen' % (r['id'], c, TEN_COT[c]))
        if kh.get('zero_wmap', True):
            for c in WMAP_COLS:
                if cells[c] != 0:
                    sys.exit('dong %s: cot %d (%s) phai = 0 theo luat zero_wmap' % (r['id'], c, TEN_COT[c]))
    return kh, rows


def ap_dung(d, rows):
    """Ap ke hoach len bang d (trong bo nho). Tra ve nhat ky + danh sach chuoi moi noi vao pool."""
    P = Pool(d['pool'])
    ghi = []
    for r in sorted(rows, key=lambda x: int(x['id'])):
        moi = int(r['id'])
        vals = r['cells']
        cells = []
        for c, v in enumerate(vals):
            if d['types'][c] == T_STRING:
                cells.append(P.offset(encode_cell(c, v)))
            else:
                cells.append(u32(v))
        ri = row_index(d, moi)
        if ri is not None:
            truoc = row_values(d, ri)
            if truoc == vals:
                ghi.append({'viec': 'BO-QUA', 'ID': moi, 'ly_do': 'da dung y ke hoach', 'hang': ri})
                continue
            d['cells'][ri * d['nF'] + 1:(ri + 1) * d['nF']] = cells[1:]
            ghi.append({'viec': 'SUA', 'ID': moi, 'hang': ri, 'truoc': mota(truoc), 'sau': mota(vals)})
        else:
            hang = next((i for i in range(d['nR']) if sid(d, i) > moi), d['nR'])
            d['cells'][hang * d['nF']:hang * d['nF']] = cells
            d['nR'] += 1
            ghi.append({'viec': 'THEM', 'ID': moi, 'chen_o_hang': hang, 'sau': mota(vals)})
    d['pool'] = P.pool
    return ghi, [(b.decode('utf-8', 'replace'), o) for b, o in P.moi]


def kiem_bat_bien(d):
    ids = [sid(d, r) for r in range(d['nR'])]
    loi = []
    if ids != sorted(ids):
        loi.append('cot 0 khong tang dan')
    if len(ids) != len(set(ids)):
        loi.append('co ID trung')
    if not d['pool'] or d['pool'][-1:] != b'\0':
        loi.append('pool khong ket thuc bang NUL')
    return loi


def so_voi_ke_hoach(d, rows):
    """Tung o cua tung dong ke hoach, doc lai tu bang d, phai giai ma dung y ke hoach."""
    loi = []
    for r in rows:
        ri = row_index(d, int(r['id']))
        if ri is None:
            loi.append('thieu dong %s' % r['id'])
            continue
        thuc = row_values(d, ri)
        for c, (a, b) in enumerate(zip(thuc, r['cells'])):
            if a != b:
                loi.append('dong %s cot %d (%s): tren dia %r, ke hoach %r' % (r['id'], c, TEN_COT[c], a, b))
                break
    return loi


def emit(rec, args):
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    if getattr(args, 'out', ''):
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        json.dump(rec, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)


# ------------------------------------------------------------------ lenh

def cmd_plan(args):
    d = dbc_read(args.dbc)
    kh, rows = doc_rows(args.rows, d['nF'], d['types'])
    truoc = {'so_dong': d['nR'], 'pool_byte': len(d['pool']), 'sha256': d['sha256']}
    ghi, chuoi_moi = ap_dung(d, rows)
    rec = {'lenh': 'plan', 'file': args.dbc, 'rows': args.rows, 'dot': kh.get('dot'),
           'truoc': truoc,
           'sau_du_kien': {'so_dong': d['nR'], 'pool_byte': len(d['pool'])},
           'so_them': sum(1 for g in ghi if g['viec'] == 'THEM'),
           'so_sua': sum(1 for g in ghi if g['viec'] == 'SUA'),
           'so_bo_qua': sum(1 for g in ghi if g['viec'] == 'BO-QUA'),
           'chuoi_noi_vao_pool': [{'chuoi': s, 'offset': o} for s, o in chuoi_moi],
           'bat_bien_sau': kiem_bat_bien(d), 'ke_hoach': ghi}
    emit(rec, args)
    return 0 if not rec['bat_bien_sau'] else 1


def cmd_apply(args):
    d = dbc_read(args.dbc)
    kh, rows = doc_rows(args.rows, d['nF'], d['types'])
    goc = dbc_read(args.dbc)
    loi0 = kiem_bat_bien(d)
    if loi0:
        sys.exit('bang hien tai da hong: %s - KHONG ghi' % loi0)
    ghi, chuoi_moi = ap_dung(d, rows)
    if all(g['viec'] == 'BO-QUA' for g in ghi):
        emit({'lenh': 'apply', 'da_du': True, 'so_dong': d['nR'], 'sha256': goc['sha256'],
              'ke_hoach': ghi}, args)
        return 0
    loi = kiem_bat_bien(d)
    if loi:
        sys.exit('sau khi ap ke hoach (trong bo nho): %s - KHONG ghi' % loi)
    os.makedirs(args.bak, exist_ok=True)
    bak = os.path.join(args.bak, 'SceneDefineEx.txt.truoc-scenes-lo2-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()))
    shutil.copy2(args.dbc, bak)
    tmp = args.dbc + '.scenes-lo2.tmp'
    open(tmp, 'wb').write(dbc_bytes(d))
    os.replace(tmp, args.dbc)
    # ---- DOC LAI TU DIA va kiem 6 dieu
    d2 = dbc_read(args.dbc)
    loi = kiem_bat_bien(d2)
    loi += so_voi_ke_hoach(d2, rows)
    if bytes(d2['pool'][:len(goc['pool'])]) != bytes(goc['pool']):
        loi.append('pool cu KHONG con la tien to cua pool moi')
    ke = {int(r['id']) for r in rows}
    cu = {sid(goc, r): goc['cells'][r * goc['nF']:(r + 1) * goc['nF']] for r in range(goc['nR'])}
    for r in range(d2['nR']):
        i = sid(d2, r)
        if i in ke:
            continue
        if i not in cu:
            loi.append('dong %d xuat hien ma khong co trong ke hoach' % i)
        elif d2['cells'][r * d2['nF']:(r + 1) * d2['nF']] != cu[i]:
            loi.append('dong %d ngoai ke hoach bi doi' % i)
    if d2['nR'] != goc['nR'] + sum(1 for g in ghi if g['viec'] == 'THEM'):
        loi.append('so dong sau khi ghi (%d) != truoc (%d) + THEM' % (d2['nR'], goc['nR']))
    try:
        sys.path.insert(0, os.path.join(CYS, 'Tools', 'game'))
        from dbc_inventory import Table
        t = Table(args.dbc)
        if t.records != d2['nR'] or len(t.types) != d2['nF']:
            loi.append('dbc_inventory doc ra %d dong x %d cot' % (t.records, len(t.types)))
        for r in rows:
            m = [x for x in t.rows if x[0] == int(r['id'])]
            if not m or str(m[0][4]) != r['cells'][4]:
                loi.append('dbc_inventory: dong %s khong tro %s' % (r['id'], r['cells'][4]))
    except ImportError:
        loi.append('khong nap duoc Tools/game/dbc_inventory.py de doi chieu')
    if loi:
        shutil.copy2(bak, args.dbc)
        emit({'lenh': 'apply', 'ok': False, 'loi': loi, 'da_tra_lai_ban_sao_luu': bak}, args)
        return 1
    emit({'lenh': 'apply', 'ok': True, 'file': args.dbc, 'sao_luu': bak,
          'truoc': {'so_dong': goc['nR'], 'pool_byte': len(goc['pool']), 'sha256': goc['sha256'], 'byte': goc['byte']},
          'sau': {'so_dong': d2['nR'], 'pool_byte': len(d2['pool']), 'sha256': d2['sha256'], 'byte': d2['byte']},
          'so_them': sum(1 for g in ghi if g['viec'] == 'THEM'),
          'so_sua': sum(1 for g in ghi if g['viec'] == 'SUA'),
          'so_bo_qua': sum(1 for g in ghi if g['viec'] == 'BO-QUA'),
          'chuoi_noi_vao_pool': [{'chuoi': s, 'offset': o} for s, o in chuoi_moi],
          'da_ghi': ghi,
          'kiem_lai': [mota(row_values(d2, row_index(d2, int(r['id'])))) for r in rows]}, args)
    return 0


def cmd_verify(args):
    d = dbc_read(args.dbc)
    kh, rows = doc_rows(args.rows, d['nF'], d['types'])
    loi = kiem_bat_bien(d) + so_voi_ke_hoach(d, rows)
    try:
        sys.path.insert(0, os.path.join(CYS, 'Tools', 'game'))
        from dbc_inventory import Table
        t = Table(args.dbc)
        if t.records != d['nR']:
            loi.append('dbc_inventory doc ra %d dong, header %d' % (t.records, d['nR']))
    except ImportError:
        loi.append('khong nap duoc dbc_inventory')
    rec = {'lenh': 'verify', 'file': args.dbc, 'ok': not loi, 'loi': loi, 'so_dong': d['nR'],
           'pool_byte': len(d['pool']), 'sha256': d['sha256'], 'byte': d['byte'],
           'dong_ke_hoach': [mota(row_values(d, row_index(d, int(r['id'])))) for r in rows
                             if row_index(d, int(r['id'])) is not None]}
    emit(rec, args)
    return 0 if not loi else 1


def cmd_undo(args):
    """Tra file ve trang thai TRUOC lan `apply` cua chinh dot nay.

    Bang chung duy nhat duoc chap nhan: co mot ban sao luu B trong `--bak` sao cho
    `B + ke hoach == file hien tai` TUNG BYTE. Khi ay B chac chan la trang thai truoc lan apply
    cua dot nay tren dung file nay. Neu khong co B nao thoa (vi du dot khac da ghi tiep sau do),
    script TU CHOI - de mot ban sao luu cu len se xoa luon viec cua dot khac.
    """
    hien = dbc_read(args.dbc)
    _, rows = doc_rows(args.rows, hien['nF'], hien['types'])
    hien_byte = open(args.dbc, 'rb').read()
    ung_vien = sorted(glob.glob(os.path.join(args.bak, 'SceneDefineEx.txt.truoc-scenes-lo2-*')))
    hop = None
    da_xet = []
    for b in reversed(ung_vien):          # moi nhat truoc
        try:
            e = dbc_read(b)
        except SystemExit:
            da_xet.append({'file': os.path.basename(b), 'ket_qua': 'khong doc duoc'})
            continue
        if e['nF'] != hien['nF']:
            da_xet.append({'file': os.path.basename(b), 'ket_qua': 'khac so cot'})
            continue
        ap_dung(e, rows)
        if dbc_bytes(e) == hien_byte:
            hop = b
            da_xet.append({'file': os.path.basename(b), 'ket_qua': 'KHOP'})
            break
        da_xet.append({'file': os.path.basename(b), 'ket_qua': 'ban sao luu + ke hoach != file hien tai'})
    if hop is None:
        emit({'lenh': 'undo', 'ok': False, 'da_ghi': False,
              'ly_do': 'khong ban sao luu nao thoa "ban sao luu + ke hoach = file hien tai" '
                       '=> file da doi sau lan apply cua dot nay; hoan tac dung cach la ap lai '
                       'ca 5 buoc theo Tools/reapply/README_vi.md',
              'thu_muc_bak': args.bak, 'so_ung_vien': len(ung_vien), 'da_xet': da_xet}, args)
        return 1
    os.makedirs(args.bak, exist_ok=True)
    giu = os.path.join(args.bak, 'SceneDefineEx.txt.truoc-undo-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()))
    shutil.copy2(args.dbc, giu)
    shutil.copy2(hop, args.dbc)
    d2 = dbc_read(args.dbc)
    loi = kiem_bat_bien(d2)
    con = [int(r['id']) for r in rows if row_index(d2, int(r['id'])) is not None]
    emit({'lenh': 'undo', 'ok': not loi, 'da_ghi': True, 'file': args.dbc,
          'tra_ve_tu': hop, 'giu_ban_truoc_undo': giu,
          'truoc': {'so_dong': hien['nR'], 'pool_byte': len(hien['pool']), 'sha256': hien['sha256']},
          'sau': {'so_dong': d2['nR'], 'pool_byte': len(d2['pool']), 'sha256': d2['sha256']},
          'bat_bien_vi_pham': loi,
          'so_dong_ke_hoach_con_lai': len(con), 'dong_con_lai': con,
          'ghi_chu': 'sau `undo`, `verify` PHAI bao ok:false - do la bang chung undo da lam viec'}, args)
    return 0 if not loi else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd')
    for n in ('plan', 'apply', 'verify', 'undo'):
        a = sub.add_parser(n)
        a.add_argument('--rows', required=True, help='JSON ke hoach (data/scenes-lo2-rows.json)')
        a.add_argument('--dbc', default=DBC, help='file DBC (mac dinh CanonicalCY; tro ban sao de thu)')
        a.add_argument('--bak', default=BAK, help='thu muc sao luu truoc khi ghi')
        a.add_argument('--out', default='')
    args = ap.parse_args()
    fn = {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify, 'undo': cmd_undo}.get(args.cmd)
    if not fn:
        ap.print_help()
        return 2
    return fn(args)


if __name__ == '__main__':
    sys.exit(main())
