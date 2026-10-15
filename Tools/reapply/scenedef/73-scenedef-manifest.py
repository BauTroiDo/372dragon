# -*- coding: utf-8 -*-
"""[reapply-guard 19/09/2026] BANG KE DONG DBC CANH — kiem ton tai + noi dung cua MOI dong ma cac dot
reapply ghi vao `Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt`.

TEN TEP KHONG MANG CON SO: so dong se con tang (19/09 da di 242 -> 243 trong mot buoi vi `maps-kho48`
them dong `client_res` 3079). Muon them mot dot: THEM DUNG MOT DONG vao bang `NGUON` ben duoi.

VI SAO CAN CONG CU NAY (khong cong cu nao trong thu muc nay lam duoc viec cua no)
  Cac cong cu 70-/72- deu la cong cu CUA MOT DOT: `verify` cua chung doi chieu voi BAN SAO LUU
  sinh ra ngay truoc lan `apply` cua chinh dot do. `Tools/reapply/README_vi.md` da ghi ro hau qua:
  "verify cua mot dot CU bao ok:false la DUNG THIET KE" - nghia la sau khi dot sau ghi de, khong
  con phep kiem nao con hieu luc cho dot truoc. Con `71-dbc-dupe-check.py` chi kiem 0 ID trung +
  cot 0 tang dan: **xoa sach 12 dong `client_res` van ra SO_ID_TRUNG = 0** (da do, xem mo ta duoi).
  => Truoc file nay, du an KHONG CO phep kiem nao tra loi duoc cau hoi "cac dong con du khong?".

  Cong cu nay giu mot BANG KE (manifest) day du 25 o da giai ma cua tung dong, va tra loi dung cau
  hoi do tren BAT KY file DBC nao (`--dbc`), khong can ban sao luu, khong phu thuoc thu tu dot.

SO DO 19/09: 3 (maps-cy4) + 10 (maps-sect) + 128 (maps-all) + 82 (maps-instance) + 19 (scenes-lo2)
  = 242, roi + 1 (maps-kho48, dong `client_res` 3079) = **243**.
  242 luot ghi dau = 242 ID KHAC NHAU (khong ID nao bi hai dot ghi; ngoai le duy nhat la cot 11..14
  cua dong 39, do `maps-instance.wmap_tu` doi sau `maps-all`, cung mot ID).
  113 dong THEM o bon buoc dau + 7 (scenes-lo2) + 1 (maps-kho48) = 121  =>  679 + 121 = 800. (Khop.)

DAT BIET: 15 DONG `client_res` (3079, 3080, 3081, 3170, 3173..3181, 3703, 3800) — KHOAN DAT NHAT
  `Tools/reapply/scenedef/66-move-clientres.py` doi 16 hang so `g_ClientRes` phia server sang
  `cu + 3000`; moi gia tri can mot dong DBC ben client (12 tu `maps-instance`, 2 tu `scenes-lo2`,
  1 tu `maps-kho48`). Duong ma:
    Src/Client/WXClient/World/WorldManager.cpp:110-131
      pSceneDef = Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nSceneID);
      if(!pSceneDef && nResID > 0 && nResID != nSceneID)                       // CYS-SCENERES
          pSceneDef = Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nResID);
      if(!pSceneDef) TDThrow("(CWorldManager::EnterScene) Invalid scene ID(%d,%d,res=%d)");
  Pho ban duoc cap sceneid 10001..10020 (`define.lua` COPY_SCENE_BEGIN=10000) — dai ma
  SceneDefineEx khong bao gio co dong — nen `client_res` la duong DUY NHAT con lai. Mat nhung dong do
  => ca hai lan tra deu truot => TDThrow => MOI PHO BAN DUNG. Vi vay chung co nhom rieng trong
  bang ke va `verify` bao rieng, bang chu to.

CACH DUNG
  73-scenedef-manifest.py build  --dbc <file DU MOI BUOC> [--manifest F] [--out F]
      Doc ID cua tung dot tu chinh cac tep ke hoach (bang `NGUON`) + hai bang CHEP cua 70-*.py,
      chup 25 o cua tung dong do tu `--dbc`, ghi bang ke. CHI ghi bang ke, KHONG dong toi DBC.
  73-scenedef-manifest.py verify [--dbc F] [--manifest F] [--out F] [--chi-mat]
      Doc `--dbc` (mac dinh: Assets/CanonicalCY) va kiem:
        MAT   = ID trong bang ke khong co dong nao  -> MAT DU LIEU, luon la hong
        LECH  = co dong nhung o khac bang ke        -> hong (dot sau ghi de / dung lai ban CY goc)
        + bat bien: 25 cot, cot 0 tang dan, 0 ID trung, pool ket thuc NUL
      `--chi-mat` ha LECH xuong muc ghi nhan (dung khi mot nhanh CO CHU DINH sua lai mot dong da
      co bang ke; khi ay phai chay `build` lai va noi ro trong handoff, dung de bang ke muc im).
  73-scenedef-manifest.py diff --dbc A --dbc2 B
      So hai DBC theo TUNG O DA GIAI MA (khong so sha256 - xem canh bao trong README).

THEM MOT DOT MOI: them mot dong vao `NGUON` roi chay lai `build` tren DBC da du moi buoc.

VI SAO KHONG CO `apply` / `undo`: file nay KHONG ghi du lieu game, no chi doc va ket luan. `build`
la lenh ghi duy nhat va dich cua no la bang ke trong git => "hoan tac" = `git checkout` bang ke.
"""
import argparse
import collections
import hashlib
import json
import os
import struct
import sys

MAGIC = b'\x00\xcc\xbb\xdd'
T_INT, T_FLOAT, T_STRING = 0, 1, 2
HERE = os.path.dirname(os.path.abspath(__file__))
REAPPLY = os.path.abspath(os.path.join(HERE, '..'))
CYS = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
DBC = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'SceneDefineEx.txt')
MANIFEST = os.path.join(HERE, 'data', 'scenedef-rows-manifest.json')

# Dai ID cua dong `client_res` = ID canh cu + 3000 (66-move-clientres.py:32 OFFSET = 3000), nam gon
# trong dai 2224..4510 von rong cua DBC. CAN BIEN TREN: dong 4511 KHONG phai client_res - do la ID canh
# cua server CY cho 汴京 ma `maps-all` da them (canh that cua du an la 755, clientres 1074;
# Timeline/handoff/map-bianjing.md:26-30). Lay >= 3000 khong thoi la dan nham no vao nhom nay.
CLIENTRES_MIN, CLIENTRES_MAX = 3000, 4510

# ------------------------------------------------------------------------------------------------
# BANG NGUON — THEM MOT DOT = THEM MOT DONG O DAY (duong dan tinh tu Tools/reapply/).
#   'const' : ID viet thang trong script cua dot (hang so CHEP) - ghi kem file:dong de doi chieu
#   'pairs' : JSON {"them": {...}, "sua": {...}} cua 70-client-scenedef-rows.py
#   'rows'  : JSON {"rows": [{"id":..,"cells":[25 o]}]} cua 72-dbc-pool-rows.py
#   'chep'  : JSON {"chep": {"<ID moi>": <ID CY nguon>}} cua tangmen/90-scene2220-row.py
# UU TIEN dang doc tu TEP (pairs/rows/chep) hon 'const': `verify` bam sha256 tung TEP ke hoach va
# keu khi tep moi hon bang ke; mot dot 'const' chi bam chinh danh sach hang so nen khong bao gio
# phat hien duoc "ke hoach da doi" o noi khac.
# ------------------------------------------------------------------------------------------------
NGUON = [
    ('maps-cy4', 'const', [2221, 2222, 2223],
     'scenedef/70-client-scenedef-rows.py: CHEP (3 canh phai CY)'),
    ('maps-sect', 'const', [495, 1311, 1312, 1315, 1316, 1320, 1321, 1358, 1500, 2218],
     'scenedef/70-sect-scenedef-rows.py:45 CHEP (2 canh phai + 8 canh phan tuyen)'),
    ('maps-all', 'pairs', 'scenedef/data/maps-all-30-pairs.json', 'dot mo the gioi'),
    ('maps-instance', 'pairs', 'scenedef/data/maps-instance-62-pairs-all.json', 'dot pho ban'),
    ('scenes-lo2', 'rows', 'scenedef/data/scenes-lo2-rows.json', 'Buoc 5 - 17 ban do nhap tu GL'),
    ('maps-kho48', 'rows', 'material/data/maps-kho48-dbc-rows.json', 'Buoc 6 - client_res nhom `kho`'),
    ('tangmen', 'chep', 'tangmen/data/tangmen-rows.json',
     'Buoc 7 - canh phai CY4 thu tu (2220 <- 615), maps-cy4 bo sot'),
    ('clientres-sweep', 'rows', 'clientres/data/clientres-rows.json',
     'Buoc 8 - ba tri so `client_res` cua PHO BAN khong co dong DBC: 546<-410 (sinh tu leitai; '
     'dong nay va CA canh 410 type=0 vi no cung tro clientres=546), 266<-404, 267<-405'),
]

TEN_COT = ['nServerID', 'szName', 'nXSize', 'nZSize', 'szWXObjectName', 'szRegionFile',
           'szCollisionfile', 'szMiniMap', 'nBackSound', 'nCol9', 'szSceneMap', 'wmapX', 'wmapY',
           'nameWmapX', 'nameWmapY', 'farClip', 'nearClip', 'szSceneType', 'cityNormalSet',
           'cityNormalImg', 'cityHoverSet', 'cityHoverImg', 'szDisplayName', 'szCol23', 'unk24']


# ------------------------------------------------------------------ doc DBC

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
            'sha256': hashlib.sha256(b).hexdigest(), 'byte': len(b)}


def s_at(pool, o):
    e = pool.find(b'\x00', o)
    raw = pool[o:e if e >= 0 else len(pool)]
    try:
        return raw.decode('utf-8')          # cot chu hien thi (du an chay UTF-8 tu 24/08)
    except UnicodeDecodeError:
        return raw.decode('gbk', 'replace')  # cot khoa tai nguyen co chu Han: BYTE GBK


def sid(d, r):
    return struct.unpack('<i', struct.pack('<I', d['cells'][r * d['nF']]))[0]


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


def chi_muc(d):
    """{id -> hang}. Neu co ID trung thi giu hang dau (bat bien se bao rieng)."""
    m = {}
    for r in range(d['nR']):
        m.setdefault(sid(d, r), r)
    return m


def bat_bien(d):
    loi = []
    ids = [sid(d, r) for r in range(d['nR'])]
    if d['nF'] != 25:
        loi.append('so cot = %d, phai la 25' % d['nF'])
    if ids != sorted(ids):
        loi.append('cot 0 khong tang dan')
    dup = {k: v for k, v in collections.Counter(ids).items() if v > 1}
    if dup:
        loi.append('ID trung: %s' % dup)
    if not d['pool'] or d['pool'][-1:] != b'\x00':
        loi.append('pool khong ket thuc bang NUL')
    return loi


# ------------------------------------------------------------------ bang ke

def doc_ke_hoach():
    """{id -> nhan dot}, doc TU CHINH cac tep ke hoach cua cac dot (khong chep tay ID).

    Tra ve (dot, tong_luot, nguon) — `tong_luot` dem theo LUOT GHI (mot ID bi hai dot ghi thi tinh
    hai luot), `len(dot)` dem theo ID KHAC NHAU. Hai so nay co the khac nhau; dung lan.
    """
    dot = collections.OrderedDict()
    tong_luot = 0
    nguon = []
    for ten, kieu, duong, ghi_chu in NGUON:
        ids = []
        if kieu == 'const':
            ids = [('them', int(i)) for i in duong]
            # `sha256` cua mot dot `const` = van cua chinh danh sach hang so (khong co tep de bam).
            ke_sha = hashlib.sha256(repr(sorted(int(i) for i in duong)).encode()).hexdigest()
            nguon.append({'dot': ten, 'kieu': kieu, 'nguon': ghi_chu, 'so_dong': len(ids),
                          'sha256': ke_sha})
        else:
            p = os.path.join(REAPPLY, duong.replace('/', os.sep))
            if not os.path.exists(p):
                sys.exit('bang NGUON tro toi tep khong co: %s (dot %s)' % (p, ten))
            raw = open(p, 'rb').read()
            k = json.loads(raw.decode('utf-8'))
            if kieu == 'pairs':
                ids = ([('them', int(x)) for x in k.get('them', {})]
                       + [('sua', int(x)) for x in k.get('sua', {})])
            elif kieu == 'chep':
                # {"chep": {"<ID moi>": <ID dong CY nguon>}} - dang cua Tools/reapply/tangmen
                ids = [('them', int(x)) for x in k.get('chep', {})]
            else:
                ids = [('rows', int(r['id'])) for r in k.get('rows', [])]
            if not ids:
                sys.exit('tep ke hoach rong: %s' % p)
            nguon.append({'dot': ten, 'kieu': kieu, 'nguon': duong, 'so_dong': len(ids),
                          'sha256': hashlib.sha256(raw).hexdigest(), 'ghi_chu': ghi_chu})
        for viec, i in ids:
            if CLIENTRES_MIN <= i <= CLIENTRES_MAX:
                nhan = '%s:client_res' % ten
            elif kieu in ('const', 'rows'):
                nhan = ten if kieu == 'rows' else '%s:them' % ten
            else:
                nhan = '%s:%s' % (ten, viec)
            # mot ID bi dot sau ghi de => nhan cua dot SAU thang (no la noi dung cuoi cung tren dia)
            dot[i] = nhan
        tong_luot += len(ids)
    return dot, tong_luot, nguon


def nhom(dot):
    g = collections.OrderedDict()
    for i, n in dot.items():
        g.setdefault(n, []).append(i)
    for k in g:
        g[k].sort()
    return g


def emit(rec, args):
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    if getattr(args, 'out', ''):
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        json.dump(rec, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)


# ------------------------------------------------------------------ lenh

def cmd_build(args):
    d = dbc_read(args.dbc)
    loi = bat_bien(d)
    if loi:
        sys.exit('nguon %s vi pham bat bien: %s - KHONG lam bang ke tu file hong' % (args.dbc, loi))
    dot, tong_luot, nguon = doc_ke_hoach()
    idx = chi_muc(d)
    thieu = [i for i in dot if i not in idx]
    if thieu:
        sys.exit('--dbc thieu %d ID cua ke hoach (%s...) - `build` can file DU MOI BUOC'
                 % (len(thieu), thieu[:10]))
    man = {
        'schema': 1,
        'mo_ta': 'Bang ke cac dong DBC canh do cac dot reapply ghi vao SceneDefineEx.txt. '
                 'Sinh boi Tools/reapply/scenedef/73-scenedef-manifest.py build.',
        'nguon_ke_hoach': nguon,
        'nguon_dbc': {'duong_dan': os.path.relpath(args.dbc, CYS) if args.dbc.startswith(CYS) else args.dbc,
                      'so_dong': d['nR'], 'so_cot': d['nF'], 'pool_byte': len(d['pool']),
                      'byte': d['byte'], 'sha256': d['sha256']},
        'tong_luot_ghi': tong_luot,
        'so_ID': len(dot),
        'ten_cot': TEN_COT,
        'nhom': {k: {'so_dong': len(v), 'ids': v} for k, v in nhom(dot).items()},
        'dong': collections.OrderedDict(
            (str(i), {'dot': dot[i], 'cells': row_values(d, idx[i])}) for i in sorted(dot)),
    }
    os.makedirs(os.path.dirname(os.path.abspath(args.manifest)), exist_ok=True)
    with open(args.manifest, 'w', encoding='utf-8') as f:
        json.dump(man, f, ensure_ascii=False, indent=1)
        f.write('\n')
    emit({'lenh': 'build', 'bang_ke': args.manifest, 'tong_luot_ghi': tong_luot, 'so_ID': len(dot),
          'nguon': man['nguon_dbc'],
          'nhom': {k: len(v) for k, v in nhom(dot).items()}}, args)
    return 0


def cmd_verify(args):
    d = dbc_read(args.dbc)
    if not os.path.exists(args.manifest):
        sys.exit('khong co bang ke %s - chay `build` truoc' % args.manifest)
    man = json.load(open(args.manifest, encoding='utf-8'))
    idx = chi_muc(d)
    mat, lech = [], []
    for k, v in man['dong'].items():
        i = int(k)
        r = idx.get(i)
        if r is None:
            mat.append({'id': i, 'dot': v['dot'], 'scene': v['cells'][4], 'ten': v['cells'][1]})
            continue
        thuc = row_values(d, r)
        khac = [{'cot': c, 'ten_cot': TEN_COT[c] if c < len(TEN_COT) else c,
                 'tren_dia': thuc[c], 'bang_ke': v['cells'][c]}
                for c in range(min(len(thuc), len(v['cells']))) if thuc[c] != v['cells'][c]]
        if khac:
            lech.append({'id': i, 'dot': v['dot'], 'so_o_khac': len(khac), 'o': khac[:4]})

    g_mat = collections.Counter(x['dot'] for x in mat)
    g_lech = collections.Counter(x['dot'] for x in lech)
    # Nhom `client_res` gop TU MOI DOT (ten nhom la '<dot>:client_res'), khong khoa cung mot dot.
    cr_ids = sorted(i for k, v in man['nhom'].items() if k.endswith(':client_res') for i in v['ids'])
    cr_mat = [x for x in mat if x['id'] in cr_ids]
    cr_lech = [x for x in lech if x['id'] in cr_ids]

    # CYS-TANGMEN 20/09: BANG KE CO THE CU HON KE HOACH, va truoc hom nay khong gi phat hien duoc.
    # Do that: `maps-kho48` them ID 1350 vao tep ke hoach luc 08:13 ngay 19/09, bang ke duoc `build`
    # luc 07:39 => dong 1350 NAM NGOAI bang ke 16 tieng, `verify` van bao ok. Day dung la benh
    # DIEU-PHOI-19-09 muc 17: phep do chay hoan hao tren MOT DINH NGHIA THIEU. Gio bam tung tep
    # ke hoach va bat khi chung moi hon bang ke.
    ke_lech = []
    try:
        _, _, nguon_bh = doc_ke_hoach()
    except SystemExit:
        nguon_bh = None
    if nguon_bh is not None:
        cu = {x['dot']: x for x in man.get('nguon_ke_hoach', [])}
        for x in nguon_bh:
            c = cu.get(x['dot'])
            if c is None:
                ke_lech.append({'dot': x['dot'], 'viec': 'DOT MOI chua co trong bang ke',
                                'so_dong_ke_hoach': x['so_dong']})
            elif 'sha256' not in c:
                ke_lech.append({'dot': x['dot'], 'viec': 'bang ke cu chua ghi sha256 ke hoach'})
            elif c['sha256'] != x['sha256']:
                ke_lech.append({'dot': x['dot'], 'viec': 'KE HOACH DA DOI sau lan build cuoi',
                                'so_dong_bang_ke': c.get('so_dong'),
                                'so_dong_ke_hoach': x['so_dong'],
                                'sha256_bang_ke': c['sha256'], 'sha256_ke_hoach': x['sha256']})

    bb = bat_bien(d)
    hong = bool(mat) or bool(bb) or bool(ke_lech) or (bool(lech) and not args.chi_mat)
    rec = {
        'lenh': 'verify', 'file': args.dbc, 'ok': not hong,
        'so_dong': d['nR'], 'so_cot': d['nF'], 'pool_byte': len(d['pool']),
        'byte': d['byte'], 'sha256': d['sha256'],
        'bang_ke': {'duong_dan': args.manifest, 'tong_luot_ghi': man['tong_luot_ghi'],
                    'so_ID': man['so_ID'], 'nguon_sha256': man['nguon_dbc']['sha256']},
        'bat_bien_vi_pham': bb,
        'KE_HOACH_LECH': ke_lech,
        'KE_HOACH_canh_bao': ('BANG KE CU HON KE HOACH o %d dot: %s. Cac dong moi cua chung KHONG '
                              'duoc bang ke bao ve => `verify` khong the bao MAT cho chung. Sua: '
                              'chay `73-scenedef-manifest.py build --dbc <file du moi buoc>`.'
                              % (len(ke_lech), [x['dot'] for x in ke_lech])) if ke_lech else 'khop',
        'SO_DONG_MAT': len(mat), 'SO_DONG_LECH': len(lech),
        'mat_theo_dot': dict(g_mat), 'lech_theo_dot': dict(g_lech),
        'CLIENT_RES': {
            'so_dong_phai_co': len(cr_ids), 'ids': cr_ids,
            'so_MAT': len(cr_mat), 'so_LECH': len(cr_lech),
            'canh_bao': ('MAT %d/%d DONG client_res => client se nem TDThrow '
                         '"(CWorldManager::EnterScene) Invalid scene ID" va MOI PHO BAN DUNG '
                         '(WorldManager.cpp:118-131). Ap lai NGAY dung cac dot: %s '
                         '(xem Tools/reapply/README_vi.md).'
                         % (len(cr_mat), len(cr_ids),
                            sorted({x['dot'].split(':')[0] for x in cr_mat}))
                         ) if cr_mat else 'du %d/%d' % (len(cr_ids), len(cr_ids)),
            'mat': cr_mat,
        },
        'mat': mat[:40], 'lech': lech[:40],
        'chi_mat': bool(args.chi_mat),
    }
    if len(mat) > 40:
        rec['mat_con_lai_khong_liet_ke'] = len(mat) - 40
    if len(lech) > 40:
        rec['lech_con_lai_khong_liet_ke'] = len(lech) - 40
    emit(rec, args)
    return 0 if not hong else 1


def cmd_diff(args):
    a, b = dbc_read(args.dbc), dbc_read(args.dbc2)
    ia, ib = chi_muc(a), chi_muc(b)
    chi_a = sorted(set(ia) - set(ib))
    chi_b = sorted(set(ib) - set(ia))
    lech = []
    for i in sorted(set(ia) & set(ib)):
        ra, rb = row_values(a, ia[i]), row_values(b, ib[i])
        if ra != rb:
            lech.append({'id': i, 'o': [{'cot': c, 'A': ra[c], 'B': rb[c]}
                                        for c in range(min(len(ra), len(rb))) if ra[c] != rb[c]][:4]})
    pa, pb = a['pool'], b['pool']
    n = min(len(pa), len(pb))
    k = 0
    while k < n and pa[k] == pb[k]:
        k += 1
    emit({'lenh': 'diff',
          'A': {'file': a['path'], 'so_dong': a['nR'], 'pool_byte': len(pa), 'sha256': a['sha256']},
          'B': {'file': b['path'], 'so_dong': b['nR'], 'pool_byte': len(pb), 'sha256': b['sha256']},
          'cung_tap_ID': sorted(ia) == sorted(ib),
          'chi_co_o_A': chi_a[:40], 'chi_co_o_B': chi_b[:40],
          'SO_DONG_LECH_TUNG_O': len(lech), 'lech': lech[:20],
          'pool_byte_dau_giong_het': k,
          'ghi_chu': 'sha256 khac ma 0 dong lech la DUNG: thu tu chuoi moi trong pool phu thuoc '
                     'so dot noi (README_vi.md muc "DOC TRUOC KHI CHAY").'}, args)
    return 0 if not lech and sorted(ia) == sorted(ib) else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd')
    for n in ('build', 'verify', 'diff'):
        a = sub.add_parser(n)
        a.add_argument('--dbc', default=DBC, help='file DBC (mac dinh: Assets/CanonicalCY)')
        a.add_argument('--manifest', default=MANIFEST, help='bang ke 242 dong')
        a.add_argument('--out', default='', help='ghi ket qua JSON ra day')
        if n == 'verify':
            a.add_argument('--chi-mat', action='store_true',
                           help='chi bao hong khi dong BI MAT; LECH chi ghi nhan')
        if n == 'diff':
            a.add_argument('--dbc2', required=True, help='file DBC thu hai')
    args = ap.parse_args()
    fn = {'build': cmd_build, 'verify': cmd_verify, 'diff': cmd_diff}.get(args.cmd)
    if not fn:
        ap.print_help()
        return 2
    return fn(args)


if __name__ == '__main__':
    sys.exit(main())
