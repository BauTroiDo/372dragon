# -*- coding: utf-8 -*-
"""maps-cy4: THEM 3 dong vao SceneDefineEx (DBC 00CCBBDD) cua client cho 3 canh phai CY.

Vi sao: client CY-Source tra SceneDefineEx bang `packet.sceneid` (= ID canh SERVER) o cot 0
  - Src/Client/WXClient/Network/CysModernHandlers.cpp:211  SetSceneID((INT)packet.sceneid, ...)
  - Src/Client/WXClient/World/WorldManager.cpp:108          Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nSceneID)
  - Src/Engine/Interface/TDDBC_Struct.h:985                 SCENE_SERVER_ID_COLUMN = 0
Bang CY chi co ID 0..1079 -> khong co dong 2221/2222/2223 -> TDThrow "Invalid scene ID".
Cach chua it rui ro nhat: NOI THEM 3 dong o cuoi (2221 > 1079 nen cot 0 van tang dan,
khong pham rang buoc `curIndex < lastIndex` cua DBC), noi dung sao chep NGUYEN VAN
dong CY that cua chinh ban do do; KHONG sua bat ky dong nao dang co.

  70-client-scenedef-rows.py plan|apply|verify [--out F]

------------------------------------------------------------------------------------------
MO RONG 17/09 (maps-all): THEM DUOC CA KHA NANG **SUA** MOT DONG DA CO.
Hanh vi mac dinh KHONG DOI: khong truyen `--pairs-fix`/`--pairs-file`/`--zero-wmap` thi
script chay y het ban cu (chi THEM, va `verify` dung dung cac phep kiem cu).

Vi sao can SUA: 92 canh `type=0` cua server co dong DBC o dung ID nhung dong do tro tai
BAN DO KHAC (vd server 179 la `xuelanghu.scn` con DBC dong 179 ghi `emei_1.scene`).
DBC nay danh khoa theo ID CANH SERVER, nen dong o ID N chi phuc vu canh N cua server ta;
mot dong tro sai ban do la RAC cua nhanh khac, khong phai du lieu hop le. Sua cho khop la
dung theo cau truc. Van sao luu + chung minh moi dong ngoai danh sach giu nguyen tung byte.

  --pairs-fix "179:222,173:216"   SUA dong da co: chep 24 o sau cua dong nguon sang dong do
  --pairs-file ke-hoach.json      {"them": {"581": 295}, "sua": {"179": 222}} - dung khi nhieu
  --zero-wmap                     dat cot 11..14 (toa do ban do the gioi) = 0 tren dong vua ghi

Vi sao co `--zero-wmap`: `Worldmap::InitWorldMap` (Src/Client/CEGUISystem/UILuaControl.cpp:2144)
duyet MOI dong va dat bieu tuong thanh pho theo `nServerID` neu cot 11 va 12 deu khac 0. Chep
nguyen van mot dong co toa do sang ID khac se ve HAI bieu tuong chong khit len nhau. Dat 0 la
dung quy uoc cua chinh CY cho dong trung ban do (vd `erengu`: chi dong 987 co toa do, 990/1000/
1001/1005 deu 0) - khong phai che so.

------------------------------------------------------------------------------------------
MO RONG 17/09 (maps-instance): NGUON DOC TU MOT FILE DBC KHAC, va ba truong hop wmap.
Ba co nay mac dinh tat, nen moi lenh cu van chay y het.

  --ref-dbc <file>   Doc DONG NGUON tu file nay thay vi tu file dang sua.

Vi sao can: `maps-all` da ghi de 128 dong theo luat vang (dong o ID N phuc vu canh N cua server
ta). Nhieu dong bi ghi de tinh co lai la dong CY that cua cac ban do PHO BAN ma `maps-instance`
can lam nguon: DBC 126 tung la `muchang.scene` (nay `baozang_2`), 139 tung la `wushendong_1`
(nay `shaolin_2`), 173 tung la `shaolin_1` (nay `huanglongdong`), 181 tung la `tianshan_1`
(nay `qianzhuang`). Cac CHUOI do van con nguyen trong string pool, chi la khong con o nao tro
toi. Nen lay ban sao luu truoc luot ghi cua maps-all lam `--ref-dbc` la doc lai duoc dong CY goc.
BAT BUOC: `--ref-dbc` phai co string pool GIONG HET file dang sua tung byte, vi o trong bang chi
chua OFFSET vao pool chu khong chua chuoi. Script tu kiem va tu choi neu pool khac.

Ba truong hop toa do world map, khai bao trong `--pairs-file`:
  "zero_wmap": true       <=> co `--zero-wmap` (dat cot 11..14 = 0 tren dong vua ghi)
  "giu_wmap": [44, 45]    mien tru `zero_wmap` cho dung cac dong nay - dung khi dong o ID do la
                          dong DUY NHAT mang bieu tuong cua ban do do sau khi ghi (vd canh 45
                          la 水牢 that cua server ta, con dong 66 dang giu bieu tuong 水牢 thi
                          chinh no cung bi ghi de trong luot nay => bieu tuong DI CHUYEN, khong
                          nhan doi). Phai tu kiem khong co dong nao khac mang cung toa do.
  "wmap_tu": {"39": 112}  chi chep cot 11..14 tu dong nguon sang dong dich, KHONG dong toi 20 o
                          con lai - dung khi mot dong rac dang giu bieu tuong cua ban do X va
                          luot nay ghi de no, nen phai chuyen bieu tuong ve dong that su la X.
"""
import os, sys, json, struct, shutil, time, argparse, glob

MAGIC = b'\x00\xcc\xbb\xdd'
T_STRING = 2
DBC = r'C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ConfigFolder\SceneDefineEx.txt'
BAK = r'C:\TLBB\085\CY-Source\Build\Logs\2026-09-17-maps-cy4\backup-client'
# ID canh server  ->  dong CY that cua ban do do
CHEP = {2221: 678, 2222: 731, 2223: 824}
SUA = {}            # ID canh server da co dong -> dong CY that de chep noi dung sang
DICH = {}           # ID -> ten .Scene dong do PHAI mang sau khi ghi (chot chan idempotent)
ZERO_WMAP = False   # dat cot 11..14 = 0 tren dong vua ghi
WMAP_COLS = (11, 12, 13, 14)
GIU_WMAP = set()    # ID duoc mien tru ZERO_WMAP (bieu tuong DI CHUYEN sang dong dung)
WMAP_TU = {}        # ID dich -> ID nguon; CHI chep cot 11..14, khong dong 20 o con lai
REF = ''            # file DBC de doc DONG NGUON (mac dinh: chinh file dang sua)
_REF_D = None       # bang da doc tu REF (nap tre, mot lan)


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
    return {'nF': nF, 'nR': nR, 'types': types, 'cells': cells, 'pool': pool, 'pool_goc': pool}


def dbc_write(path, d):
    out = bytearray(MAGIC)
    out += struct.pack('<3I', d['nF'], d['nR'], len(d['pool']))
    out += struct.pack('<%dI' % d['nF'], *d['types'])
    out += struct.pack('<%dI' % (d['nF'] * d['nR']), *d['cells'])
    out += d['pool']
    # pool KHONG bao gio bi sua (chi noi them o cells), nen bat bien la "pool y nguyen".
    # Chu y: pool cua CanonicalCY la UTF-8 (du an da chuyen 24/08), KHONG phai GBK.
    assert d['pool'] == d['pool_goc'], 'pool da bi doi - tu choi ghi'
    tmp = path + '.maps-cy4.tmp'
    open(tmp, 'wb').write(bytes(out))
    os.replace(tmp, path)


def sid(d, r):
    return struct.unpack('<i', struct.pack('<I', d['cells'][r * d['nF']]))[0]


def s(d, o):
    e = d['pool'].find(b'\0', o)
    return d['pool'][o:e if e >= 0 else len(d['pool'])].decode('utf-8', 'replace')


def row_index(d, wanted):
    for r in range(d['nR']):
        if sid(d, r) == wanted:
            return r
    return None


def mota(d, r):
    return {'id': sid(d, r), 'ten': s(d, d['cells'][r * d['nF'] + 1]),
            'kich_thuoc': '%dx%d' % (d['cells'][r * d['nF'] + 2], d['cells'][r * d['nF'] + 3]),
            'scene': s(d, d['cells'][r * d['nF'] + 4]), 'path': s(d, d['cells'][r * d['nF'] + 5])}


def emit(rec, args):
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    if getattr(args, 'out', ''):
        json.dump(rec, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)


def kiem_tang(d):
    ids = [sid(d, r) for r in range(d['nR'])]
    return ids == sorted(ids), ids


def _zero_wmap(d, r):
    """Cot 11..14 = 0 -> Worldmap::InitWorldMap bo qua dong nay (khong ve bieu tuong trung)."""
    for c in WMAP_COLS:
        d['cells'][r * d['nF'] + c] = 0


def bang_nguon(d):
    """Bang de doc DONG NGUON: `--ref-dbc` neu co, khong thi chinh `d` (hanh vi cu).

    Bat buoc pool giong het: o trong bang chi chua OFFSET vao string pool, nen chep o giua hai
    file co pool khac nhau se tro vao chuoi khac ma khong he bao loi.
    """
    global _REF_D
    if not REF:
        return d
    if _REF_D is None:
        _REF_D = dbc_read(REF)
    if _REF_D['pool'] != d['pool']:
        sys.exit('--ref-dbc co string pool khac file dang sua (%d vs %d byte) - TU CHOI'
                 % (len(_REF_D['pool']), len(d['pool'])))
    if _REF_D['nF'] != d['nF']:
        sys.exit('--ref-dbc co %d cot, file dang sua co %d cot - TU CHOI' % (_REF_D['nF'], d['nF']))
    return _REF_D


def da_dung(d, r, moi):
    """Dong `r` da mang dung `.Scene` ma ke hoach muon chua? (chot chan idempotent)"""
    if moi not in DICH:
        return False
    return s(d, d['cells'][r * d['nF'] + 4]).lower() == DICH[moi].lower()


def ap_dung(d):
    """Thuc hien ke hoach (THEM + SUA + zero-wmap) len mot bang DBC da doc.

    Dung CHUNG cho `apply` (ghi that) va `verify` (dung lai tu ban sao luu roi so sanh),
    nen bang chung cua verify la: "ban sao luu + dung ke hoach nay = file hien tai, tung o".
    Idempotent: chay hai lan cho ket qua nhu nhau.
    """
    ghi = []
    ids = [sid(d, r) for r in range(d['nR'])]
    # 0. CHUP NOI DUNG DONG NGUON TRUOC KHI SUA BAT KY THU GI.
    #    Bat buoc: mot dong nguon co the CHINH LA dong sap bi SUA (vd dong 122 hien la
    #    `newbie_1.scene` va vua la nguon cho canh 50/61/81, vua bi doi thanh `cangjing`).
    #    Neu khong chup truoc thi ket qua phu thuoc thu tu - mot lop loi rat kho lan.
    goc = {}
    dn = bang_nguon(d)
    for nguon_id in set(list(CHEP.values()) + list(SUA.values()) + list(WMAP_TU.values())):
        rn = row_index(dn, nguon_id)
        if rn is None:
            sys.exit('khong co dong nguon %d trong DBC nguon' % nguon_id)
        goc[nguon_id] = list(dn['cells'][rn * dn['nF']:(rn + 1) * dn['nF']])
    # 1. SUA dong da co (khong doi so dong, khong doi thu tu)
    for moi in sorted(SUA):
        r = row_index(d, moi)
        if r is None:
            sys.exit('--pairs-fix: khong co dong %d de sua' % moi)
        if da_dung(d, r, moi):
            ghi.append({'viec': 'BO-QUA', 'ID': moi, 'ly_do': 'da tro dung %s' % DICH[moi]})
            continue
        d['cells'][r * d['nF'] + 1:(r + 1) * d['nF']] = goc[SUA[moi]][1:]
        if ZERO_WMAP and moi not in GIU_WMAP:
            _zero_wmap(d, r)
        ghi.append({'viec': 'SUA', 'ID': moi, 'chep_tu': SUA[moi], 'hang': r,
                    'giu_wmap': moi in GIU_WMAP})
    # 2. THEM dong con thieu, CHEN DUNG CHO de cot 0 van tang dan
    for moi in sorted(k for k in CHEP if k not in ids):
        row = list(goc[CHEP[moi]])
        row[0] = struct.unpack('<I', struct.pack('<i', moi))[0]
        hang = next((i for i in range(d['nR']) if sid(d, i) > moi), d['nR'])
        d['cells'][hang * d['nF']:hang * d['nF']] = row
        d['nR'] += 1
        if ZERO_WMAP and moi not in GIU_WMAP:
            _zero_wmap(d, hang)
        ghi.append({'viec': 'THEM', 'ID': moi, 'ID_moi': moi, 'chep_tu': CHEP[moi],
                    'chen_o_hang': hang, 'giu_wmap': moi in GIU_WMAP})
    # 3. CHUYEN bieu tuong world map: chi 4 o 11..14, 20 o con lai cua dong dich giu nguyen.
    #    Chay SAU cung de neu dong dich cung nam trong SUA/CHEP thi ket qua van la gia tri chuyen.
    for moi in sorted(WMAP_TU):
        r = row_index(d, moi)
        if r is None:
            sys.exit('wmap_tu: khong co dong %d de dat toa do' % moi)
        cu = [d['cells'][r * d['nF'] + c] for c in WMAP_COLS]
        for c in WMAP_COLS:
            d['cells'][r * d['nF'] + c] = goc[WMAP_TU[moi]][c]
        ghi.append({'viec': 'WMAP', 'ID': moi, 'chep_tu': WMAP_TU[moi], 'hang': r,
                    'truoc': cu, 'sau': [goc[WMAP_TU[moi]][c] for c in WMAP_COLS]})
    return ghi


def cmd_plan(args):
    d = dbc_read(DBC)
    dn = bang_nguon(d)
    tang, ids = kiem_tang(d)
    rec = {'lenh': 'plan', 'file': DBC, 'so_cot': d['nF'], 'so_dong': d['nR'],
           'cot0_tang_dan': tang, 'ID_lon_nhat': max(ids),
           'nguon_doc_tu': REF or '(chinh file nay)',
           'da_co_dong_dich': [k for k in CHEP if k in ids],
           'se_them': []}
    for moi, nguon in sorted(CHEP.items()):
        r = row_index(dn, nguon)
        rec['se_them'].append({'ID_moi': moi, 'chep_tu_dong_CY': nguon,
                               'noi_dung': mota(dn, r) if r is not None else 'KHONG TIM THAY'})
    if SUA:
        # Bang TRUOC -> SAU cho tung dong bi sua. Day la thu phai doc ky truoc khi `apply`.
        rec['zero_wmap'] = ZERO_WMAP
        rec['giu_wmap'] = sorted(GIU_WMAP)
        rec['se_sua'] = []
        for moi, nguon in sorted(SUA.items()):
            a, b = row_index(d, moi), row_index(dn, nguon)
            rec['se_sua'].append({'ID': moi,
                                  'truoc': mota(d, a) if a is not None else 'KHONG CO DONG',
                                  'sau': mota(dn, b) if b is not None else 'KHONG TIM THAY NGUON',
                                  'chep_tu_dong_CY': nguon})
    if WMAP_TU:
        rec['se_chuyen_wmap'] = []
        for moi, nguon in sorted(WMAP_TU.items()):
            a, b = row_index(d, moi), row_index(dn, nguon)
            rec['se_chuyen_wmap'].append({
                'ID': moi, 'chep_cot_11_14_tu': nguon,
                'dong_dich_hien_tai': mota(d, a) if a is not None else 'KHONG CO DONG',
                'truoc': [d['cells'][a * d['nF'] + c] for c in WMAP_COLS] if a is not None else None,
                'sau': [dn['cells'][b * dn['nF'] + c] for c in WMAP_COLS] if b is not None else None})
    emit(rec, args)
    return 0


def cmd_apply(args):
    d = dbc_read(DBC)
    tang, ids = kiem_tang(d)
    if not tang:
        sys.exit('cot 0 chua tang dan, khong noi them')
    them = {k: v for k, v in CHEP.items() if k not in ids}
    if not them and not SUA and not WMAP_TU:
        emit({'lenh': 'apply', 'da_du': True, 'so_them': 0}, args)
        return 0
    os.makedirs(BAK, exist_ok=True)
    bak = os.path.join(BAK, 'SceneDefineEx.txt.truoc-maps-cy4-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()))
    shutil.copy2(DBC, bak)
    # CHEN DUNG CHO, khong noi duoi: cot 0 phai tang dan (DBC assert `curIndex < lastIndex`,
    # va Search_First_Column_Equ tim tren cot da sap xep). ID cua maps-cy4 (2221-2223) lon hon
    # moi ID cu nen roi vao cuoi; ID cua agent khac (vd 495, 1358) thi chen vao giua.
    ghi = ap_dung(d)
    ids2 = [sid(d, i) for i in range(d['nR'])]
    if ids2 != sorted(ids2) or len(ids2) != len(set(ids2)):
        sys.exit('sau khi chen, cot 0 khong con tang dan hoac co ID trung - KHONG ghi')
    dbc_write(DBC, d)
    d2 = dbc_read(DBC)
    kiem = sorted(set(list(them) + list(SUA)))
    emit({'lenh': 'apply', 'sao_luu': bak, 'nguon_doc_tu': REF or '(chinh file nay)',
          'so_them': sum(1 for g in ghi if g['viec'] == 'THEM'),
          'so_sua': sum(1 for g in ghi if g['viec'] == 'SUA'),
          'so_wmap': sum(1 for g in ghi if g['viec'] == 'WMAP'),
          'zero_wmap': ZERO_WMAP, 'giu_wmap': sorted(GIU_WMAP), 'da_ghi': ghi,
          'da_them': [g for g in ghi if g['viec'] == 'THEM'],
          'da_sua': [g for g in ghi if g['viec'] == 'SUA'], 'so_dong_sau': d2['nR'],
          'kiem_lai': [mota(d2, row_index(d2, k)) for k in kiem]}, args)
    return 0


def cmd_verify_tong_quat(args):
    """Kiem cho che do co SUA / zero-wmap: DUNG LAI file tu ban sao luu roi so TUNG O.

    Bat bien manh nhat co the phat bieu: **ban sao luu + dung ke hoach nay = file hien tai**.
    No bao trum ca hai bat bien cu (dong moi giong dong nguon; moi dong khac giu nguyen),
    va con bat duoc ca truong hop mot dong bi sua ngoai y muon.
    """
    d = dbc_read(DBC)
    tang, ids = kiem_tang(d)
    loi = []
    if not tang:
        loi.append('cot 0 khong con tang dan')
    if len(ids) != len(set(ids)):
        loi.append('co ID trung')
    for moi in sorted(list(CHEP) + list(SUA)):
        if row_index(d, moi) is None:
            loi.append('thieu dong %d' % moi)
    hop = None
    bs = sorted(glob.glob(os.path.join(BAK, 'SceneDefineEx.txt.truoc-maps-cy4-*')))
    for b in bs:
        try:
            e = dbc_read(b)
        except SystemExit:
            continue
        if e['pool'] != d['pool']:
            continue
        ap_dung(e)
        if e['cells'] == d['cells'] and e['nR'] == d['nR']:
            hop = (b, dbc_read(b))
    if not bs:
        loi.append('khong tim thay ban sao luu de doi chieu')
    elif hop is None:
        loi.append('KHONG ban sao luu nao + ke hoach = file hien tai'
                   ' (pool doi, hoac co dong bi sua ngoai ke hoach)')
    # Dong vua ghi phai giong dong nguon o moi cot TRU cot 0 (va tru 11..14 neu zero-wmap).
    # PHAI so voi noi dung dong nguon TRONG BAN SAO LUU: mot so dong vua la nguon vua la dich
    # (dong 129 la nguon cua canh 86 `shandong_1` roi chinh no bi doi thanh `cangjing_2`), nen
    # so voi dong nguon o file HIEN TAI se bao sai.
    if hop:
        # Dong nguon lay o dau: `--ref-dbc` neu co (khi ay noi dung nguon KHONG nam trong ban sao
        # luu - do chinh la ly do phai co --ref-dbc), khong thi lay trong ban sao luu nhu cu.
        d0 = dbc_read(REF) if REF else hop[1]
        for bang in (CHEP, SUA):
            for moi, nguon in sorted(bang.items()):
                bo_qua = {0} | (set(WMAP_COLS) if (ZERO_WMAP and moi not in GIU_WMAP) else set())
                if moi in WMAP_TU:
                    bo_qua |= set(WMAP_COLS)
                a, b2 = row_index(d, moi), row_index(d0, nguon)
                if a is None or b2 is None:
                    continue
                for c in range(d['nF']):
                    if c in bo_qua:
                        continue
                    if d['cells'][a * d['nF'] + c] != d0['cells'][b2 * d0['nF'] + c]:
                        loi.append('dong %d lech dong nguon %d (%s) o cot %d'
                                   % (moi, nguon, 'ref-dbc' if REF else 'ban sao luu', c))
                        break
        # Bieu tuong world map da chuyen dung chua
        for moi, nguon in sorted(WMAP_TU.items()):
            a, b2 = row_index(d, moi), row_index(d0, nguon)
            if a is None or b2 is None:
                loi.append('wmap_tu %d:%d thieu dong' % (moi, nguon))
                continue
            for c in WMAP_COLS:
                if d['cells'][a * d['nF'] + c] != d0['cells'][b2 * d0['nF'] + c]:
                    loi.append('dong %d chua nhan toa do world map cua dong %d (cot %d)'
                               % (moi, nguon, c))
                    break
    # Khang dinh doc duoc: dong o ID nay tro dung tep .Scene nao.
    for moi, ten in sorted(DICH.items()):
        r = row_index(d, moi)
        if r is None:
            continue
        thuc = s(d, d['cells'][r * d['nF'] + 4])
        if thuc.lower() != ten.lower():
            loi.append('dong %d tro toi %s, ke hoach doi %s' % (moi, thuc, ten))
    if ZERO_WMAP:
        for moi in sorted(list(CHEP) + list(SUA)):
            if moi in GIU_WMAP or moi in WMAP_TU:
                continue
            r = row_index(d, moi)
            if r is not None and any(d['cells'][r * d['nF'] + c] for c in WMAP_COLS):
                loi.append('dong %d con toa do world map khac 0' % moi)
    # Bat bien cua chinh `Worldmap::InitWorldMap`: KHONG hai dong nao cung toa do (11,12) khac 0
    # trong so cac dong luot nay dung toi. (Cac cap trung co tu truoc thi khong phai viec o day,
    # nen chi bao cao chu khong bao loi.)
    cua_toi = set(CHEP) | set(SUA) | set(WMAP_TU)
    toa_do = {}
    trung_moi = []
    for r in range(d['nR']):
        x, y = d['cells'][r * d['nF'] + 11], d['cells'][r * d['nF'] + 12]
        if x and y:
            toa_do.setdefault((x, y), []).append(sid(d, r))
    for k, v in toa_do.items():
        if len(v) > 1 and any(i in cua_toi for i in v):
            trung_moi.append({'toa_do': list(k), 'dong': v})
            loi.append('toa do world map %s bi nhieu dong dung: %s' % (list(k), v))
    emit({'lenh': 'verify', 'che_do': 'tong quat (co SUA / zero-wmap)', 'so_dong': d['nR'],
          'ok': not loi, 'loi': loi, 'so_them': len(CHEP), 'so_sua': len(SUA),
          'zero_wmap': ZERO_WMAP, 'giu_wmap': sorted(GIU_WMAP),
          'nguon_doc_tu': REF or '(chinh file nay)',
          'wmap_trung_lien_quan': trung_moi,
          'doi_chieu': ({'ban_sao_luu': os.path.basename(hop[0]), 'so_dong_luc_do': hop[1]['nR']}
                        if hop else None)}, args)
    return 0 if not loi else 1


def cmd_verify(args):
    if SUA or ZERO_WMAP:
        return cmd_verify_tong_quat(args)
    d = dbc_read(DBC)
    tang, ids = kiem_tang(d)
    loi = []
    if not tang:
        loi.append('cot 0 khong con tang dan')
    if len(ids) != len(set(ids)):
        loi.append('co ID trung')
    for moi, nguon in sorted(CHEP.items()):
        a, b = row_index(d, moi), row_index(d, nguon)
        if a is None:
            loi.append('thieu dong %d' % moi); continue
        ra = d['cells'][a * d['nF'] + 1:(a + 1) * d['nF']]
        rb = d['cells'][b * d['nF'] + 1:(b + 1) * d['nF']]
        if ra != rb:
            loi.append('dong %d khac dong nguon %d' % (moi, nguon))
    # Bat bien dung: pool KHONG doi mot byte so voi ban sao luu truoc khi noi them.
    # (Pool cua CanonicalCY tron UTF-8 va GBK - cot khoa tai nguyen phai giu GBK - nen
    #  KHONG duoc kiem bang mot bang ma hoa duy nhat.)
    # NHIEU AGENT: tu 17/09 co hon mot agent noi dong vao CUNG file nay. Vi vay KHONG lay
    # "ban sao luu moi nhat" (co the la cua agent khac, sinh ra sau lan ghi cua minh) ma lay
    # ban sao luu moi nhat NAO con la TIEN TO dung cua file hien tai - do la trang thai truoc
    # mot lan ghi nao do, khong phu thuoc ai ghi.
    # Bo cac dong MINH them ra khoi bang hien tai; phan con lai phai GIONG HET ban sao luu.
    # (Kiem kieu "tien to" chi dung khi noi duoi; tu khi apply biet chen vao giua thi phai kiem the nay.)
    con_lai = []
    for i in range(d['nR']):
        if sid(d, i) not in CHEP:
            con_lai.extend(d['cells'][i * d['nF']:(i + 1) * d['nF']])
    bs = sorted(glob.glob(os.path.join(BAK, 'SceneDefineEx.txt.truoc-maps-cy4-*')))
    hop = []
    for b in bs:
        try:
            e = dbc_read(b)
        except SystemExit:
            continue
        if e['pool'] == d['pool'] and con_lai == e['cells']:
            hop.append((b, e))
    if not bs:
        loi.append('khong tim thay ban sao luu de doi chieu pool')
    elif not hop:
        loi.append('khong ban sao luu nao la tien to cua file hien tai (pool hoac dong cu da bi doi)')
    else:
        b, d0 = hop[-1]
        rec_bak = {'ban_sao_luu_doi_chieu': os.path.basename(b), 'so_dong_luc_do': d0['nR']}
        if d0['nR'] + len(CHEP) > d['nR']:
            loi.append('so dong lech: sao luu %d + %d > %d' % (d0['nR'], len(CHEP), d['nR']))
        args._bak = rec_bak
    emit({'lenh': 'verify', 'so_dong': d['nR'], 'ok': not loi, 'loi': loi,
          'cap_ID': {str(k): v for k, v in sorted(CHEP.items())},
          'doi_chieu': getattr(args, '_bak', None),
          'dong_moi': [mota(d, row_index(d, k)) for k in sorted(CHEP) if row_index(d, k) is not None]}, args)
    return 0 if not loi else 1


ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
sub = ap.add_subparsers(dest='cmd')
for n in ('plan', 'apply', 'verify'):
    a = sub.add_parser(n)
    a.add_argument('--out', default='')
    # DUNG LAI CHO AGENT KHAC (maps-sect 17/09, ID 1358 va 495): dua cap ID qua dong lenh thay vi
    # sua hang so CHEP trong file. Mac dinh giu nguyen ba cap cua maps-cy4 nen moi lenh da ghi
    # trong tai lieu van chay y het.
    a.add_argument('--pairs', default='',
                   help='ID_moi:dong_CY_nguon, cach nhau bang dau phay, vd "1358:236,495:615". '
                        'Bo trong = 2221:678,2222:731,2223:824 (maps-cy4)')
    # Moi agent nen tro --bak vao THU MUC BANG CHUNG CUA MINH: verify doi chieu pool voi ban sao luu
    # trong thu muc nay, tron ban sao luu cua hai agent vao mot cho la tu lam kho minh.
    a.add_argument('--bak', default=BAK, help='thu muc giu ban sao luu truoc khi ghi (mac dinh: maps-cy4)')
    a.add_argument('--dbc', default=DBC, help='file DBC can sua (mac dinh: CanonicalCY; dat ban sao de tu kiem)')
    # MO RONG 17/09 (maps-all). Khong truyen ba co nay thi moi thu chay y het ban cu.
    a.add_argument('--pairs-fix', default='',
                   help='SUA dong DA CO: "ID:dong_CY_nguon,...". Chep 24 o sau cua dong nguon '
                        'sang dong o ID do (dong o ID N chi phuc vu canh N cua server ta).')
    a.add_argument('--pairs-file', default='',
                   help='JSON {"them": {"581": 295}, "sua": {"179": 222}} - dung khi co nhieu cap. '
                        'Neu co, no THAY cho --pairs/--pairs-fix.')
    a.add_argument('--zero-wmap', action='store_true',
                   help='dat cot 11..14 = 0 tren dong vua ghi, de Worldmap::InitWorldMap khong ve '
                        'hai bieu tuong thanh pho chong khit len nhau')
    # MO RONG 17/09 (maps-instance). Khong truyen thi moi thu chay y het ban cu.
    a.add_argument('--ref-dbc', default='',
                   help='doc DONG NGUON tu file DBC nay thay vi tu file dang sua (phai cung '
                        'string pool tung byte). Dung khi dong CY goc da bi luot ghi truoc do de len.')


def _cap(txt, ten):
    try:
        return {int(p.split(':')[0]): int(p.split(':')[1]) for p in txt.split(',') if p.strip()}
    except (ValueError, IndexError):
        sys.exit('%s sai khuon; can dang "ID:dong_nguon,ID:dong_nguon"' % ten)


args = ap.parse_args()
if getattr(args, 'dbc', ''):
    DBC = args.dbc
if getattr(args, 'pairs_file', ''):
    _kh = json.load(open(args.pairs_file, encoding='utf-8'))
    CHEP = {int(k): int(v) for k, v in _kh.get('them', {}).items()}
    SUA = {int(k): int(v) for k, v in _kh.get('sua', {}).items()}
    DICH = {int(k): str(v) for k, v in _kh.get('dich', {}).items()}
    GIU_WMAP = {int(x) for x in _kh.get('giu_wmap', [])}
    WMAP_TU = {int(k): int(v) for k, v in _kh.get('wmap_tu', {}).items()}
    if _kh.get('zero_wmap'):
        ZERO_WMAP = True
    if not CHEP and not SUA and not WMAP_TU:
        sys.exit('--pairs-file rong')
    _chung = set(CHEP) & set(SUA)
    if _chung:
        sys.exit('mot ID vua o "them" vua o "sua": %s' % sorted(_chung))
else:
    if getattr(args, 'pairs', ''):
        CHEP = _cap(args.pairs, '--pairs')
        if not CHEP:
            sys.exit('--pairs rong')
    if getattr(args, 'pairs_fix', ''):
        SUA = _cap(args.pairs_fix, '--pairs-fix')
if getattr(args, 'zero_wmap', False):
    ZERO_WMAP = True
if getattr(args, 'bak', ''):
    BAK = args.bak
if getattr(args, 'ref_dbc', ''):
    REF = args.ref_dbc
sys.exit({'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify}.get(args.cmd, lambda a: ap.print_help() or 2)(args))
