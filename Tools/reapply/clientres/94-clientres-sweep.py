# -*- coding: utf-8 -*-
"""[CYS-CLIENTRES 20/09/2026] Quet `clientres` TOAN BO canh - phan ba nhom, do bang BYTE va bang O DBC.

BAY NAY DA CAN DU AN BON LAN:
  1. `huashan` != `huashan_10` - ten nghe giong, tai nguyen khac (phai so sha256 tep .path).
  2. Canh 2220 tro `zijinkuafu_spring`, ma bo tep do KHONG TON TAI (0 tep).
  3. 2221/2222/2223 tro 1054/1055/1056 (FengYun) - min CHUA NO vi dong DBC cua chung con song.
  4. `build_canonical_cy.py --apply` xoa 245 dong DBC => moi duong tra `sceneid` bien mat cung luc,
     va khi ay `clientres` la thu DUY NHAT con lai.

HAI DUONG TRA cua client (Src/Client/WXClient/World/WorldManager.cpp:110-131):
    A. pSceneDef = Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nSceneID)   # cot0 == sceneid
    B. neu truot VA nResID>0 VA nResID!=nSceneID:                              # CYS-SCENERES
       pSceneDef = Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nResID)     # cot0 == clientres
    C. truot ca hai  -> TDThrow "Invalid scene ID"
`nResID` den tu goi vao canh (`packet.client_res`) = khoa `clientres` cua [sceneN] trong SceneInfo.ini.

=> `clientres` SAI khong phai luc nao cung NO. No no khi duong A khong con. Vi the phai phan BA nhom:

  NHOM 1 "DUNG"          duong dang chay OK, va duong du phong cung ve DUNG BAN DO do (hoac khong co
                         duong du phong rieng vi clientres == sceneid / <=0).
  NHOM 2 "SAI CHUA NO"   duong dang chay la `sceneid` va OK, nhung neu dong do bien mat thi `clientres`
                         dan sang BAN DO KHAC (hoac sang tep khong ton tai, hoac khong co dong nao).
                         => min. Khong co trieu chung nao hom nay.
  NHOM 3 "SAI DANG NO"   duong dang chay HONG ngay bay gio: khong tra duoc dong nao (TDThrow), hoac
                         dong tra duoc tro toi tep .path KHONG TON TAI, hoac ve mot navmesh khac byte
                         voi navmesh SERVER dang dung.

HAI TIEU CHI DOC LAP - khong tieu chi nao du mot minh (bai hoc `tangmen` muc 6):
  (a) `khop_byte`: sha256(navmesh SERVER) == sha256(tep .path CLIENT). **DU, khong CAN.**
      Do duoc tren 197 canh type=0: 52 DAT / 141 LECH_HASH / 4 THIEU. 141 KHONG phai "141 canh hong":
      49 la server v0x1000 <-> client v0x2000 (hai PHIEN BAN dinh dang), 92 la cung v0x2000 khac byte.
      Dung tieu chi nay mot minh se bao dong gia gan ba phan tu so canh.
  (b) `khop_o`: so TUNG O cua dong DBC duong A voi dong DBC duong B. Tieu chi nay so CLIENT voi CLIENT
      nen MIEN NHIEM voi lech phien ban navmesh, va no bat duoc thu (a) khong bat duoc: 615 vs 628
      deu tro `tangmen.path` (hash giong het) nhung khac `szSceneMap`/`wmapX/Y`/`MiniMap_Icon`.
  Nguoc lai (b) mu voi truong hop client va server cam hai ban do khac han nhau - do la viec cua (a).

`nBackSound` (o 8) duoc tach rieng: `tangmen` dung NHAC NEN lam kenh xac nhan DOC LAP khi dung trong
canh. O nay nam trong chinh dong DBC nen doi nhac = doi dong = bang chung nghe duoc.

  python3 94-clientres-sweep.py sweep [--all|--scenes 1,2] [--out F] [--txt F]
  python3 94-clientres-sweep.py hieu-chuan [--out F]      # chay lai tren 4 canh DA BIET DAP AN
  python3 94-clientres-sweep.py doi-chung-am [--out F]    # 8 phep pha hoai tren BAN SAO
  (chay TRONG WSL: can doc ca /home/ubuntu/... lan /mnt/c/...)
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import sys
import tempfile
import time

MAGIC = b'\x00\xcc\xbb\xdd'
R_SRV = '/home/ubuntu/cys-test-20260913'
CYS = '/mnt/c/TLBB/085/CY-Source'
SCENEINFO = os.path.join(R_SRV, 'configs', 'SceneInfo.ini')
SRV_SCENE = os.path.join(R_SRV, 'Game_2', 'Scene')
CLI_DBC = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'SceneDefineEx.txt')
CLI_SCENE = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'SceneFolder')
MANIFEST_DBC = os.path.join(CYS, 'Tools', 'reapply', 'scenedef', 'data',
                            'scenedef-rows-manifest.json')
# bang tra cua client 0.85 goc (TSV/GBK, 24 cot) - dung DOI CHIEU TRUC ID, khong phai de sua
CLI_085 = '/mnt/c/TLBB/085/client/Data/ConfigFolder/SceneDefineEx.txt'

TEN_COT = ['nServerID', 'szName', 'nXSize', 'nZSize', 'szWXObjectName', 'szRegionFile',
           'szCollisionfile', 'szMiniMap', 'nBackSound', 'nCol9', 'szSceneMap', 'wmapX', 'wmapY',
           'nameWmapX', 'nameWmapY', 'farClip', 'nearClip', 'szSceneType', 'cityNormalSet',
           'cityNormalImg', 'cityHoverSet', 'cityHoverImg', 'szDisplayName', 'szCol23', 'unk24']
# o quyet dinh HINH HOC thuc su duoc ve / di duoc: khac o day = VAO NHAM BAN DO
O_HINH_HOC = [2, 3, 4, 5, 6]          # nXSize nZSize szWXObjectName szRegionFile szCollisionfile
# o quyet dinh thu nguoi choi NHIN/NGHE thay ma khong doi hinh hoc
O_HIEN_THI = [7, 8, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 21]
COL_REGION = 5


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
                # BAY `inireader.lua:31`: gia tri bat dau bang `;` bi LOAI -> khoa khong bao gio
                # duoc dat. Giu lai gia tri None de phan biet voi "khong co khoa".
                sv = dec(v).strip()
                kv[dec(k).strip()] = None if sv.startswith(';') else sv
        out[name] = kv
    return out


def doc_dbc(path):
    b = open(path, 'rb').read()
    if b[:4] != MAGIC:
        sys.exit('%s khong phai DBC 00CCBBDD' % path)
    nF, nR, pool_size = struct.unpack_from('<3I', b, 4)
    types = list(struct.unpack_from('<%dI' % nF, b, 16))
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]
    idx, trung = {}, {}
    for r in range(nR):
        i = struct.unpack('<i', struct.pack('<I', cells[r * nF]))[0]
        if i in idx:
            trung.setdefault(i, []).append(r)
        else:
            idx[i] = r
    return {'nF': nF, 'nR': nR, 'types': types, 'cells': cells, 'pool': pool, 'idx': idx,
            'id_trung': trung, 'sha256': hashlib.sha256(b).hexdigest(), 'byte': len(b)}


def o(d, r, c):
    """Gia tri o (r,c) theo KIEU cot - chuoi tra str, int tra int, float tra float."""
    v = d['cells'][r * d['nF'] + c]
    t = d['types'][c]
    if t == 2:
        e = d['pool'].find(b'\x00', v)
        return dec(d['pool'][v:e if e >= 0 else len(d['pool'])])
    if t == 1:
        return struct.unpack('<f', struct.pack('<I', v))[0]
    return struct.unpack('<i', struct.pack('<I', v))[0]


def hang(d, r):
    return [o(d, r, c) for c in range(d['nF'])]


_cache_hash = {}


def hash_tep(p):
    """sha256 + so byte + the phien ban 4 byte dau. Tra (None,None,None) neu khong co tep."""
    if p in _cache_hash:
        return _cache_hash[p]
    q = p
    if not os.path.isfile(q):
        dd, tt = os.path.dirname(q), os.path.basename(q).lower()
        cand = [n for n in os.listdir(dd) if n.lower() == tt] if os.path.isdir(dd) else []
        if not cand:
            _cache_hash[p] = (None, None, None)
            return _cache_hash[p]
        q = os.path.join(dd, cand[0])
    b = open(q, 'rb').read()
    # 4 byte dau = <so diem 16 bit cao> | <the phien ban 16 bit thap> (0x1000 / 0x2000).
    # Doc ca u32 la SAI: no tron so diem vao the, nen moi tep ra mot "phien ban" khac nhau.
    ver = '0x%04x' % (struct.unpack_from('<I', b, 0)[0] & 0xFFFF) if len(b) >= 4 else None
    _cache_hash[p] = (hashlib.sha256(b).hexdigest(), len(b), ver)
    return _cache_hash[p]


def navmap_cua_scn(scn_name, thu_muc=None):
    thu_muc = thu_muc or SRV_SCENE
    p = os.path.join(thu_muc, scn_name)
    if not os.path.isfile(p):
        cand = [n for n in os.listdir(thu_muc) if n.lower() == scn_name.lower()]
        if not cand:
            return None
        p = os.path.join(thu_muc, cand[0])
    txt = dec(open(p, 'rb').read())
    m = re.search(r'navmapname\s*=\s*([^\r\n;]+)', txt)
    return m.group(1).strip() if m else None


def chi_muc_hash_client(thu_muc=None):
    """sha256 -> [ten tep .path] cho TOAN BO SceneFolder. Dung de DE XUAT gia tri dung,
    khong phai de ket luan - hai tep khac ten van co the trung byte (tangmen: 4 tep)."""
    thu_muc = thu_muc or CLI_SCENE
    out = {}
    for n in os.listdir(thu_muc):
        if n.lower().endswith('.path'):
            h, b, v = hash_tep(os.path.join(thu_muc, n))
            if h:
                out.setdefault(h, []).append(n)
    return out


def so_hang(d, ra, rb):
    """So tung o hai dong DBC. Tra (lech_hinh_hoc, lech_hien_thi, lech_khac)."""
    hh, ht, kh = [], [], []
    for c in range(d['nF']):
        if c == 0:
            continue
        va, vb = o(d, ra, c), o(d, rb, c)
        if va == vb:
            continue
        m = (TEN_COT[c] if c < len(TEN_COT) else 'col%d' % c, va, vb)
        (hh if c in O_HINH_HOC else ht if c in O_HIEN_THI else kh).append(m)
    return hh, ht, kh


def kiem(si, dbc, n, hidx):
    key = 'scene%d' % n
    s = si.get(key) or {}
    rec = {'scene': n, 'active': s.get('active'), 'type': s.get('type'),
           'file': s.get('file'), 'clientres': s.get('clientres')}
    if not s:
        rec['nhom'] = '3-DANG-NO'
        rec['ket_qua'] = 'KHONG CO [sceneN]'
        return rec

    # --- ve SERVER: .scn -> navmapname -> sha256
    nav = navmap_cua_scn(s['file']) if s.get('file') else None
    rec['server_navmap'] = nav
    if nav:
        rec['server_sha256'], rec['server_byte'], rec['server_ver'] = hash_tep(
            os.path.join(SRV_SCENE, nav))
    else:
        rec['server_sha256'] = rec['server_byte'] = rec['server_ver'] = None

    # --- ve CLIENT: hai duong tra
    cr_raw = s.get('clientres')
    cr = int(cr_raw) if cr_raw is not None and str(cr_raw).lstrip('-').isdigit() else None
    rec['clientres_so'] = cr
    ra = dbc['idx'].get(n)
    rb = dbc['idx'].get(cr) if (cr is not None and cr > 0 and cr != n) else None
    rec['co_dong_sceneid'] = ra is not None
    rec['co_duong_du_phong'] = (cr is not None and cr > 0 and cr != n)
    rec['co_dong_clientres'] = rb is not None
    rec['duong_dang_chay'] = 'sceneid' if ra is not None else (
        'client_res' if rb is not None else 'KHONG TRA DUOC')

    def ve(r):
        if r is None:
            return {}
        reg = o(dbc, r, COL_REGION)
        h, b, v = hash_tep(os.path.join(CLI_SCENE, reg))
        return {'dbc_hang': r, 'dbc_id': o(dbc, r, 0), 'ten': o(dbc, r, 1),
                'wxobject': o(dbc, r, 4), 'region': reg, 'collision': o(dbc, r, 6),
                'minimap': o(dbc, r, 7), 'nBackSound': o(dbc, r, 8), 'szSceneMap': o(dbc, r, 10),
                'wmapXY': [o(dbc, r, 11), o(dbc, r, 12)],
                'tep_ton_tai': h is not None, 'sha256': h, 'byte': b, 'ver': v,
                'khop_byte_voi_server': (h is not None and h == rec['server_sha256'])}

    A, B = ve(ra), ve(rb)
    rec['A_sceneid'] = A
    rec['B_clientres'] = B

    # --- tieu chi (b): hai dong DBC co ve CUNG MOT ban do khong
    if ra is not None and rb is not None:
        hh, ht, kh = so_hang(dbc, ra, rb)
        rec['lech_o_hinh_hoc'] = hh
        rec['lech_o_hien_thi'] = ht
        rec['lech_o_khac'] = [x[0] for x in kh]
        rec['du_phong_ve_dung_ban_do'] = (len(hh) == 0)
    else:
        rec['du_phong_ve_dung_ban_do'] = None

    # --- DE XUAT: dong DBC nao tro toi tep .path TRUNG BYTE voi navmesh server
    de_xuat = []
    if rec['server_sha256']:
        for ten in hidx.get(rec['server_sha256'], []):
            for rr in range(dbc['nR']):
                if o(dbc, rr, COL_REGION).lower() == ten.lower():
                    de_xuat.append({'id': o(dbc, rr, 0), 'region': ten,
                                    'szSceneMap': o(dbc, rr, 10),
                                    'wmapXY': [o(dbc, rr, 11), o(dbc, rr, 12)]})
    # neu co dong A, uu tien dong nao GIONG HET dong A o cac o hinh hoc + hien thi
    if ra is not None:
        for c in de_xuat:
            rr = dbc['idx'].get(c['id'])
            if rr is None or rr == ra:
                c['giong_dong_A'] = (rr == ra)
                continue
            hh, ht, _ = so_hang(dbc, ra, rr)
            c['giong_dong_A'] = (len(hh) == 0 and len(ht) == 0)
    rec['de_xuat_clientres'] = de_xuat

    # --- HAI TRUC DOC LAP, giu RIENG. Ep chung vao mot nhan la tu lam mu chinh minh:
    #     mot canh vua lech byte VUA la min thi nhan nao cung che mat nua kia.
    # TRUC A = duong client DANG DI hom nay.
    live = A if ra is not None else B
    if not live:
        rec['truc_A'] = 'KHONG_TRA_DUOC'
        rec['ket_qua'] = 'KHONG TRA DUOC DONG DBC NAO -> TDThrow "Invalid scene ID"'
    elif not live['tep_ton_tai']:
        rec['truc_A'] = 'THIEU_TEP'
        rec['ket_qua'] = 'THIEU TEP navmesh CLIENT: %s' % live['region']
    elif rec['server_sha256'] is None:
        rec['truc_A'] = 'KHONG_DOC_DUOC_SERVER'
        rec['ket_qua'] = 'KHONG DOC DUOC navmesh SERVER (file=%s navmap=%s)' % (s.get('file'), nav)
    else:
        rec['truc_A'] = 'OK'
        rec['ket_qua'] = 'DAT'
    # bang chung BO SUNG, KHONG dung de phan nhom: byte-giong-het la DU chu khong CAN.
    rec['khop_byte'] = live.get('khop_byte_voi_server') if live else None
    if live and rec['server_sha256'] and not live.get('khop_byte_voi_server'):
        rec['lech_byte'] = 'server %s.. (%s) != client %s.. (%s)' % (
            rec['server_sha256'][:10], rec['server_ver'], (live['sha256'] or '')[:10], live['ver'])

    # TRUC B = duong DU PHONG (`clientres`), thu se duoc dung khi dong `sceneid` bien mat.
    if not rec['co_duong_du_phong']:
        rec['truc_B'] = 'KHONG_CO_DUONG_RIENG'
    elif rb is None:
        rec['truc_B'] = 'KHONG_CO_DONG'
        rec['min'] = 'clientres=%s KHONG CO dong DBC -> mat dong %d se thanh TDThrow' % (cr, n)
    elif not B['tep_ton_tai']:
        rec['truc_B'] = 'THIEU_TEP'
        rec['min'] = 'clientres=%s -> %s: TEP KHONG TON TAI' % (cr, B['region'])
    elif ra is None:
        rec['truc_B'] = 'DANG_LA_DUONG_CHINH'
    elif rec['lech_o_hinh_hoc']:
        rec['truc_B'] = 'KHAC_HINH_HOC'
        rec['min'] = 'clientres=%s -> BAN DO KHAC (%s) o lech: %s' % (
            cr, B['region'], ','.join(x[0] for x in rec['lech_o_hinh_hoc']))
    elif rec['lech_o_hien_thi']:
        rec['truc_B'] = 'KHAC_HIEN_THI'
        rec['min'] = 'clientres=%s cung hinh hoc nhung lech %s' % (
            cr, ','.join(x[0] for x in rec['lech_o_hien_thi']))
    else:
        rec['truc_B'] = 'OK'

    # --- BA NHOM: truc A quyet dinh "dang no", truc B quyet dinh "min chua no".
    if rec['truc_A'] != 'OK':
        rec['nhom'] = '3-DANG-NO'
    elif rec['truc_B'] in ('KHONG_CO_DONG', 'THIEU_TEP', 'KHAC_HINH_HOC'):
        rec['nhom'] = '2-SAI-CHUA-NO'
    elif rec['truc_B'] == 'KHAC_HIEN_THI':
        rec['nhom'] = '2b-SAI-NHE'
    else:
        rec['nhom'] = '1-DUNG'
    return rec


def chay_sweep(a):
    si = doc_sceneinfo(a.sceneinfo)
    dbc = doc_dbc(a.dbc)
    hidx = chi_muc_hash_client()
    if a.scenes:
        ns = [int(x) for x in a.scenes.split(',') if x.strip()]
    else:
        ns = sorted(int(k[5:]) for k in si if k.startswith('scene') and k[5:].isdigit()
                    and (a.moi_canh or str(si[k].get('active')) == '1'))
    # 245 dong DBC do cac dot CY-Source THEM VAO - dung la nhung dong `build_canonical_cy.py
    # --apply` se xoa. Min o nhom 2 chi co NGOI NO khi dong A cua no nam trong danh sach nay.
    # build_canonical_cy.py:116-117 noi ro no lam GI: "XOA 121 dong da noi them va TRA 122 dong
    # da sua ve ban CY goc". Hai viec do KHAC NHAU ve hau qua:
    #   `:them`  -> dong BIEN MAT  => client roi xuong `clientres` => MIN NO.
    #   `:sua`   -> dong VAN CON (noi dung CY goc) => duong `sceneid` van tra duoc => MIN KHONG NO.
    # Dem ca 245 dong nhu nhau se thoi phong so min len gan gap doi.
    bao_ve, dot_cua_dong = set(), {}
    try:
        mf = json.load(open(MANIFEST_DBC, encoding='utf-8'))
        bao_ve = set(int(x) for x in mf['dong'])
        for k, v in mf['dong'].items():
            dot_cua_dong[int(k)] = v.get('dot') if isinstance(v, dict) else None
    except Exception as e:
        print('CANH BAO: khong doc duoc bang ke 245 dong (%s) - bo cot min_da_gai_ngoi' % e)
    rows = [kiem(si, dbc, n, hidx) for n in ns]
    dem, demA, demB, dem_type = {}, {}, {}, {}
    for r in rows:
        r['dong_A_do_CYS_ghi'] = r['scene'] in bao_ve if bao_ve else None
        r['dot_reapply'] = dot_cua_dong.get(r['scene'])
        them = bool(r['dot_reapply']) and not str(r['dot_reapply']).endswith(':sua')
        r['dong_A_se_BIEN_MAT_khi_rebuild'] = them
        r['min_da_gai_ngoi'] = bool(r['nhom'].startswith('2') and them)
        dem[r['nhom']] = dem.get(r['nhom'], 0) + 1
        demA[r.get('truc_A')] = demA.get(r.get('truc_A'), 0) + 1
        demB[r.get('truc_B')] = demB.get(r.get('truc_B'), 0) + 1
        k = '%s/type%s' % (r['nhom'], r.get('type'))
        dem_type[k] = dem_type.get(k, 0) + 1
    kb = {'khop': sum(1 for r in rows if r.get('khop_byte') is True),
          'lech': sum(1 for r in rows if r.get('khop_byte') is False),
          'khong_do_duoc': sum(1 for r in rows if r.get('khop_byte') is None)}
    out = {'dau': 'CYS-CLIENTRES', 'luc': time.strftime('%Y-%m-%dT%H:%M:%S'),
           'sceneinfo': a.sceneinfo, 'dbc': a.dbc, 'dbc_sha256': dbc['sha256'],
           'dbc_so_dong': dbc['nR'], 'dbc_id_trung': len(dbc['id_trung']),
           'so_dong_bao_ve': len(bao_ve),
           'so_canh_kiem': len(rows), 'thong_ke_nhom': dem,
           'thong_ke_truc_A_dang_chay': demA, 'thong_ke_truc_B_du_phong': demB,
           'thong_ke_khop_byte_DU_KHONG_CAN': kb,
           'so_min_da_gai_ngoi': sum(1 for r in rows if r['min_da_gai_ngoi']),
           'thong_ke_nhom_type': dem_type, 'canh': rows}
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        json.dump(out, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('DBC %s (%d dong, %d ID trung)  kiem %d canh  bang ke bao ve %d dong' % (
        dbc['sha256'][:12], dbc['nR'], len(dbc['id_trung']), len(rows), len(bao_ve)))
    print(' BA NHOM:')
    for k in sorted(dem):
        print('   %-18s %d' % (k, dem[k]))
    print('   -> min DA GAI NGOI (nhom 2* + dong A nam trong %d dong se bi xoa): %d'
          % (len(bao_ve), out['so_min_da_gai_ngoi']))
    print(' TRUC A (duong dang chay):  %s' % demA)
    print(' TRUC B (duong du phong):   %s' % demB)
    print(' khop byte navmesh (DU, KHONG CAN - dung mot minh se bao dong gia): %s' % kb)
    if a.txt:
        with open(a.txt, 'w', encoding='utf-8') as f:
            for r in rows:
                f.write('scene %-6s type=%-3s clientres=%-7s duong=%-12s nhom=%-14s A=%-22s '
                        'B=%-22s byte=%-5s ngoi_no=%-5s | %s | %s\n' % (
                            r['scene'], r.get('type'), r.get('clientres'),
                            r.get('duong_dang_chay'), r.get('nhom'), r.get('truc_A'),
                            r.get('truc_B'), r.get('khop_byte'), r.get('min_da_gai_ngoi'),
                            r.get('ket_qua'), r.get('min', '')))
    return 0 if not [r for r in rows if r['nhom'].startswith(('2', '3'))] else 1


# ---------------------------------------------------------------- HIEU CHUAN
# `tangmen` da chung minh dap an cua BON canh bang sha256 + bang ke 25 o:
#   2220 <- 615 (tangmen.path) · 2221 <- 678 (guigu) · 2222 <- 731 (taohuadao) · 2223 <- 824 (congren)
# Phep do cua toi phai RA LAI dung bon so do. Khong co buoc nay thi ket qua chi la mot khang dinh.
DAP_AN = {2220: 615, 2221: 678, 2222: 731, 2223: 824}


def chay_hieu_chuan(a):
    si = doc_sceneinfo(a.sceneinfo)
    dbc = doc_dbc(a.dbc)
    hidx = chi_muc_hash_client()
    kq = []
    for n, dung in sorted(DAP_AN.items()):
        r = kiem(si, dbc, n, hidx)
        uu_tien = [c for c in r.get('de_xuat_clientres', []) if c.get('giong_dong_A')]
        ids = [c['id'] for c in uu_tien]
        kq.append({'scene': n, 'dap_an_tangmen': dung,
                   'de_xuat_tat_ca': [c['id'] for c in r.get('de_xuat_clientres', [])],
                   'de_xuat_giong_dong_A': ids,
                   'RA_LAI_DUOC': dung in ids,
                   'clientres_hien_tai': r.get('clientres'), 'nhom': r.get('nhom')})
    dat = sum(1 for x in kq if x['RA_LAI_DUOC'])
    out = {'dau': 'CYS-CLIENTRES', 'phep': 'hieu-chuan', 'luc': time.strftime('%Y-%m-%dT%H:%M:%S'),
           'dbc_sha256': dbc['sha256'], 'so_dat': dat, 'so_phep': len(kq),
           'KET_LUAN': 'DAT %d/%d' % (dat, len(kq)), 'chi_tiet': kq}
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        json.dump(out, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    for x in kq:
        print('  scene %-5d dap_an=%-5d de_xuat_giong_A=%-14s RA_LAI=%s  (clientres hien tai=%s, %s)'
              % (x['scene'], x['dap_an_tangmen'], x['de_xuat_giong_dong_A'], x['RA_LAI_DUOC'],
                 x['clientres_hien_tai'], x['nhom']))
    print('HIEU CHUAN: %d/%d' % (dat, len(kq)))
    return 0 if dat == len(kq) else 1


# ------------------------------------------------------------ DOI CHUNG AM
def sua_sceneinfo(src, dst, sua):
    """sua = {sceneN: {khoa: gia_tri}}. Lam o muc BYTE, khong giai ma/ma hoa lai (giu GBK)."""
    raw = open(src, 'rb').read()
    for n, kv in sua.items():
        m = re.search((r'^\[scene%d\]' % n).encode(), raw, re.M)
        if not m:
            raise SystemExit('khong thay [scene%d]' % n)
        m2 = re.search(rb'^\[', raw[m.end():], re.M)
        en = m.end() + (m2.start() if m2 else len(raw) - m.end())
        khuc = raw[m.start():en]
        for k, v in kv.items():
            pat = (r'^%s\s*=.*$' % re.escape(k)).encode()
            thay = ('%s=%s' % (k, v)).encode()
            if re.search(pat, khuc, re.M):
                khuc = re.sub(pat, thay, khuc, count=1, flags=re.M)
            else:
                khuc = khuc.rstrip(b'\r\n') + b'\n' + thay + b'\n'
        raw = raw[:m.start()] + khuc + raw[en:]
    open(dst, 'wb').write(raw)


def dbc_xoa_dong(src, dst, sid):
    """Xoa dong co cot0 == sid. String pool GIU NGUYEN (chuoi mo coi vo hai) - dung khuon
    70-sect-scenedef-rows.py de khong dung toi cot duong dan GBK."""
    b = open(src, 'rb').read()
    nF, nR, ps = struct.unpack_from('<3I', b, 4)
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]
    giu = [r for r in range(nR)
           if struct.unpack('<i', struct.pack('<I', cells[r * nF]))[0] != sid]
    if len(giu) == nR:
        raise SystemExit('khong thay dong %d' % sid)
    moi = b[:4] + struct.pack('<3I', nF, len(giu), ps) + b[16:off]
    moi += b''.join(struct.pack('<%dI' % nF, *cells[r * nF:(r + 1) * nF]) for r in giu)
    open(dst, 'wb').write(moi + pool)


def chay_doi_chung_am(a):
    tmp = tempfile.mkdtemp(prefix='clientres-dca-')
    si0, dbc0 = a.sceneinfo, a.dbc
    hidx = chi_muc_hash_client()
    phep = []

    def do(nhan, sceneinfo, dbcp, n, mong_doi_nhom, vi_sao):
        si = doc_sceneinfo(sceneinfo)
        d = doc_dbc(dbcp)
        r = kiem(si, d, n, hidx)
        ok = r['nhom'] == mong_doi_nhom
        phep.append({'phep': nhan, 'scene': n, 'vi_sao': vi_sao, 'mong_doi': mong_doi_nhom,
                     'do_duoc': r['nhom'], 'ket_qua_chi_tiet': r.get('ket_qua'),
                     'min': r.get('min'), 'KEU_DUNG': ok})
        print('  %-5s scene %-5d mong=%-14s do=%-14s %s  | %s' % (
            nhan, n, mong_doi_nhom, r['nhom'], 'OK' if ok else '*** TRUOT ***',
            r.get('min') or r.get('ket_qua')))

    # N1 canh 2221 mang `clientres=1054` (FengYun) - PHAI keu la min chua no.
    # KHONG doc thang du lieu song: luot dau toi viet N1/N7 doc `SceneInfo.ini` hien trang, va
    # ngay sau khi chinh toi sua 2221 thanh 678 thi bo doi chung am tut tu 8/8 xuong 6/8 - MOT
    # phep tu kiem bam trang thai se tu muc rong theo dung cai no vua giup sua. Nay dung san.
    f = os.path.join(tmp, 'si-N1.ini')
    sua_sceneinfo(si0, f, {2221: {'clientres': 1054}})
    do('N1', f, dbc0, 2221, '2-SAI-CHUA-NO', 'clientres tro ban do FengYun (trang thai truoc khi sua)')
    # N2 sua dung -> phai IM
    f = os.path.join(tmp, 'si-N2.ini')
    sua_sceneinfo(si0, f, {2221: {'clientres': 678}})
    do('N2', f, dbc0, 2221, '1-DUNG', 'dat dung 678 -> phep kiem phai IM')
    # N3 gia tri TRUNG BYTE nhung KHAC dong (615 vs 628) - tieu chi hash MU o day
    f = os.path.join(tmp, 'si-N3.ini')
    sua_sceneinfo(si0, f, {2220: {'clientres': 628}})
    do('N3', f, dbc0, 2220, '2b-SAI-NHE', '628 cung tro tangmen.path (hash GIONG HET) nhung khac o')
    # N4 dat dung 615
    f = os.path.join(tmp, 'si-N4.ini')
    sua_sceneinfo(si0, f, {2220: {'clientres': 615}})
    do('N4', f, dbc0, 2220, '1-DUNG', 'hien trang dung')
    # N5 ID khong ton tai trong DBC
    f = os.path.join(tmp, 'si-N5.ini')
    sua_sceneinfo(si0, f, {2222: {'clientres': 999999}})
    do('N5', f, dbc0, 2222, '2-SAI-CHUA-NO', 'clientres tro ID khong co dong DBC')
    # N6 tro toi dong CO THAT nhung TEP khong ton tai (1053 zijinkuafu_spring)
    f = os.path.join(tmp, 'si-N6.ini')
    sua_sceneinfo(si0, f, {2223: {'clientres': 1053}})
    do('N6', f, dbc0, 2223, '2-SAI-CHUA-NO', '1053 co dong DBC nhung bo tep .path = 0 tep')
    # N7 CHO MIN NO: xoa dong DBC 2221 -> duong A mat, client roi xuong clientres=1054.
    # TOI DOAN SAI o luot dau: viet mong doi `X-LECH-BYTE` (= ve ban do khac). Do ra `3-DANG-NO`
    # vi `FengYun_lingyunku.path` KHONG CO trong SceneFolder. Cong cu dung, du doan cua toi sai;
    # min cua 2221 nang HON canh bao cua dieu phoi chu khong nhe hon. Da sua mong doi cho khop
    # phep do, VA ghi lai cho sai - khong xoa dau vet.
    dn = os.path.join(tmp, 'SceneDefineEx-xoa2221.txt')
    dbc_xoa_dong(dbc0, dn, 2221)
    f = os.path.join(tmp, 'si-N7.ini')
    sua_sceneinfo(si0, f, {2221: {'clientres': 1054}})
    do('N7', f, dn, 2221, '3-DANG-NO', 'xoa dong 2221 khi clientres=1054 -> TEP KHONG TON TAI')
    # N8 xoa dong 2220 khi clientres da dung 615 -> duong du phong VAN dung
    f = os.path.join(tmp, 'si-N8.ini')
    sua_sceneinfo(si0, f, {2220: {'clientres': 615}})
    dn2 = os.path.join(tmp, 'SceneDefineEx-xoa2220.txt')
    dbc_xoa_dong(dbc0, dn2, 2220)
    do('N8', f, dn2, 2220, '1-DUNG', 'mat dong 2220 ma clientres=615 -> van ve dung Duong Mon')

    dat = sum(1 for p in phep if p['KEU_DUNG'])
    out = {'dau': 'CYS-CLIENTRES', 'phep': 'doi-chung-am', 'tmp': tmp,
           'luc': time.strftime('%Y-%m-%dT%H:%M:%S'),
           'so_dat': dat, 'so_phep': len(phep), 'KET_LUAN': 'DAT %d/%d' % (dat, len(phep)),
           'chi_tiet': phep}
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        json.dump(out, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('DOI CHUNG AM: %d/%d' % (dat, len(phep)))
    if not a.giu_tmp:
        shutil.rmtree(tmp, ignore_errors=True)
    return 0 if dat == len(phep) else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('lenh', choices=['sweep', 'hieu-chuan', 'doi-chung-am'])
    ap.add_argument('--scenes', default='')
    ap.add_argument('--all', action='store_true')
    ap.add_argument('--moi-canh', action='store_true', help='ke ca canh active=0')
    ap.add_argument('--sceneinfo', default=SCENEINFO)
    ap.add_argument('--dbc', default=CLI_DBC)
    ap.add_argument('--out', default='')
    ap.add_argument('--txt', default='')
    ap.add_argument('--giu-tmp', action='store_true')
    a = ap.parse_args()
    if a.lenh == 'sweep':
        return chay_sweep(a)
    if a.lenh == 'hieu-chuan':
        return chay_hieu_chuan(a)
    return chay_doi_chung_am(a)


sys.exit(main())
