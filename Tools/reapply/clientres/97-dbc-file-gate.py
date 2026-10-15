# -*- coding: utf-8 -*-
"""[CYS-CLIENTRES 20/09/2026] CONG CHAN: mot dong DBC ĐẾN ĐƯỢC ma tro toi tep .path KHONG CO.

VI SAO CO CONG NAY, thay vi va tung canh:
  `scene_install.py survey` cot `client` bao **198/198 OK** cho `type=0` — KE CA bon canh FengYun
  dang no (814/818/819/1051). Khong mau thuan: no hoi *"co dong DBC o ID nay khong?"* va cau tra loi
  dung la CO. No **khong hoi tiep** *"tep ma dong do tro toi co ton tai khong?"*. Cot `nav_byte` cua
  no cung khong cuu duoc: no do tep o `Game_2/Scene` phia SERVER, ma van de nam o phia CLIENT.
  => Mot cong chay hoan hao tren mot dinh nghia thieu, va xanh mai mai (DIEU-PHOI-19-09 muc 17).

Do duoc: **53/803 dong DBC tro toi `.path` khong ton tai** (21 trong do server van co du tep).
Moi dong ma la mot cai hoc cho mot `clientres` tro vao. Ca BON lan bay can du an deu la hinh dang
nay (2220->1053 `zijinkuafu_spring` 0 tep; 2221/2222/2223->1054/1055/1056 ba ban do FengYun 0 tep).

BA TRUC DUOC KIEM — chi TRUC DEN DUOC MOI LAM CONG DO:
  A. canh `type=0` dang bat, duong `sceneid` (WorldManager.cpp:110)            -> DO neu thieu tep
  B. canh dang bat ma duong `sceneid` TRUOT, roi xuong `clientres` (:119-122)  -> DO neu thieu tep
  C. tri so `client_res` HANG SO trong `Game_2/Script/**` (duong DUY NHAT cua pho ban)
                                                                               -> DO neu thieu tep
  D. dong DBC "ma" KHONG ai tro toi  -> **chi CANH BAO + chot moc**, khong do. Chung vo hai cho toi
     khi co ai tro vao; nhung so luong chi duoc PHEP GIAM. Moc o `data/phantom-baseline.json`.
  E. VA CHAM ID: mot dong bang ke THEM VAO mang dung ID cua mot canh `type=0`/`type=4` DANG BAT
     ma canh do ve ban do KHAC HAN.  -> chot moc nhu D.
     Toi gay ra dung viec nay khi them dong 266/267 cho pho ban `xinsanhuan_2/3`: [scene266]
     辽西西北 va [scene267] 武夷正西 la THANH BANG HOI `type=4` dang bat. Truoc do chung khong co
     dong `sceneid` nen roi xuong `city_info` -> PCity (dung); sau do dong `sceneid` THANG ->
     ve dumuchang/huomuchang (SAI). Chua no vi chua bang hoi nao (`city scene startup done,
     total = 0`), nhung do la MOT QUA MIN, va no do chinh dot nay gai.
     Bo loc bat buoc: `shaolin_1.path` <-> `shaolin.path` la BAN SAO BIEN THE co y (pho ban dung
     lai hinh hoc ban do goc), KHONG phai va cham - bo hau to `_<so>` va tien to `cy4_` truoc khi
     so. Khong loc thi phep dem ra 56 thay vi 9, va con so do vo dung.

  python3 97-dbc-file-gate.py kiem      [--out F]          rc=1 neu co truc A/B/C thieu tep
  python3 97-dbc-file-gate.py doi-chung [--out F]          6 phep chung minh cong BIET TRUOT
  python3 97-dbc-file-gate.py ghi-moc                      chot lai moc so dong ma (chi khi GIAM)
  (chay TRONG WSL)
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import tempfile
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
MAGIC = b'\x00\xcc\xbb\xdd'
R_SRV = '/home/ubuntu/cys-test-20260913'
CYS = '/mnt/c/TLBB/085/CY-Source'
SCENEINFO = os.path.join(R_SRV, 'configs', 'SceneInfo.ini')
SCRIPT = os.path.join(R_SRV, 'Game_2', 'Script')
CLI_DBC = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'SceneDefineEx.txt')
CLI_SCENE = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'SceneFolder')
MOC = os.path.join(HERE, 'data', 'phantom-baseline.json')
MANIFEST_DBC = os.path.join(CYS, 'Tools', 'reapply', 'scenedef', 'data',
                            'scenedef-rows-manifest.json')
SRV_SCENE = os.path.join(R_SRV, 'Game_2', 'Scene')
COL_REGION = 5

RE_GAN_SO = re.compile(r'(?:^|[^\w.])((?:g_[Cc]lient_?[Rr]es|client_res|ClientRes))\s*=\s*(\d+)')
RE_GAN_BIEN = re.compile(r'(?:config|self)\.client_res\s*=\s*self\.(g_\w+)')
RE_KHAI_BIEN = re.compile(r'\.(g_\w*[Cc]lient_?[Rr]es\w*)\s*=\s*(\d+)')


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
                sv = dec(v).strip()
                kv[dec(k).strip()] = None if sv.startswith(';') else sv
        out[name] = kv
    return out


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


def lam_chi_muc_tep(thu_muc):
    return {n.lower() for n in os.listdir(thu_muc)}


def navmap_cua_scn(scn_name):
    """`.scn` phia SERVER -> `navmapname`. Ten tep tren dia khong phan biet hoa/thuong nen phai
    do tim khong phan biet hoa/thuong, dung tin `os.path.isfile` mot lan la du."""
    p = os.path.join(SRV_SCENE, scn_name)
    if not os.path.isfile(p):
        cand = [n for n in os.listdir(SRV_SCENE) if n.lower() == scn_name.lower()]
        if not cand:
            return None
        p = os.path.join(SRV_SCENE, cand[0])
    m = re.search(r'navmapname\s*=\s*([^\r\n;]+)', dec(open(p, 'rb').read()))
    return m.group(1).strip() if m else None


def quet_lua():
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
                    ra.setdefault(int(m.group(2)), []).append((os.path.relpath(p, SCRIPT), i))
                for m in RE_GAN_BIEN.finditer(line):
                    v = bien.get(m.group(1))
                    if v:
                        ra.setdefault(int(v), []).append((os.path.relpath(p, SCRIPT), i))
    return ra


def kiem(sceneinfo=SCENEINFO, dbcp=CLI_DBC, scenefolder=CLI_SCENE, bo_qua_lua=False):
    si = doc_sceneinfo(sceneinfo)
    dbc = doc_dbc(dbcp)
    co_tep = lam_chi_muc_tep(scenefolder)
    vi_pham = {'A_sceneid': [], 'B_clientres': [], 'C_lua': []}
    dem = {'canh_bat': 0, 'canh_type0_bat': 0, 'lua_tri_so': 0}

    def tep_cua_dong(r):
        reg = o_chuoi(dbc, r, COL_REGION)
        return reg, (reg.lower() in co_tep)

    for key, s in si.items():
        if not key.startswith('scene') or not key[5:].isdigit():
            continue
        if str(s.get('active')) != '1':
            continue
        n = int(key[5:])
        dem['canh_bat'] += 1
        la_t0 = str(s.get('type')) == '0'
        if la_t0:
            dem['canh_type0_bat'] += 1
        cr = s.get('clientres')
        cr = int(cr) if cr is not None and str(cr).lstrip('-').isdigit() else None
        ra = dbc['idx'].get(n)
        if ra is not None:
            # TRUC A chi la duong DEN DUOC voi type=0: type=1 nhan sceneid 10001..10020,
            # type=4 lay clientres tu bang city_info. Khong do tren hai loai do.
            if la_t0:
                reg, ok = tep_cua_dong(ra)
                if not ok:
                    vi_pham['A_sceneid'].append({'scene': n, 'type': s.get('type'),
                                                 'dbc_id': n, 'region': reg,
                                                 'ly_do': 'dong sceneid tro toi tep KHONG CO'})
            continue
        if cr is not None and cr > 0 and cr != n:
            rb = dbc['idx'].get(cr)
            if rb is None:
                vi_pham['B_clientres'].append({'scene': n, 'type': s.get('type'), 'clientres': cr,
                                               'ly_do': 'roi xuong clientres ma KHONG CO dong DBC'})
            else:
                reg, ok = tep_cua_dong(rb)
                if not ok:
                    vi_pham['B_clientres'].append({'scene': n, 'type': s.get('type'),
                                                   'clientres': cr, 'region': reg,
                                                   'ly_do': 'roi xuong clientres, tep KHONG CO'})
        else:
            vi_pham['B_clientres'].append({'scene': n, 'type': s.get('type'), 'clientres': cr,
                                           'ly_do': 'khong co dong sceneid VA khong co duong du phong'})

    if not bo_qua_lua:
        ra_lua = quet_lua()
        dem['lua_tri_so'] = len(ra_lua)
        for v in sorted(ra_lua):
            r = dbc['idx'].get(v)
            if r is None:
                vi_pham['C_lua'].append({'client_res': v, 'ly_do': 'KHONG CO dong DBC',
                                         'vi_du': '%s:%s' % ra_lua[v][0]})
            else:
                reg, ok = tep_cua_dong(r)
                if not ok:
                    vi_pham['C_lua'].append({'client_res': v, 'region': reg,
                                             'ly_do': 'dong co, tep KHONG CO',
                                             'vi_du': '%s:%s' % ra_lua[v][0]})

    ma = []
    for r in range(dbc['nR']):
        reg = o_chuoi(dbc, r, COL_REGION)
        if reg.strip() and reg.lower() not in co_tep:
            ma.append(struct.unpack('<i', struct.pack('<I', dbc['cells'][r * dbc['nF']]))[0])

    # --- TRUC E: va cham ID giua dong bang ke va canh dang bat
    def goc(n):
        n = re.sub(r'\.path$', '', n.lower().replace('cy4_', ''))
        return re.sub(r'_\d+$', '', n)

    va_cham = []
    try:
        man = json.load(open(MANIFEST_DBC, encoding='utf-8'))
    except (OSError, ValueError):
        man = None
    if man:
        for k, v in man['dong'].items():
            n = int(k)
            s = si.get('scene%d' % n)
            # `type=1`: client nhan sceneid 10001..10020 nen dong DBC o ID nay khong bao gio
            # duoc tra luc chay -> khong tinh la va cham.
            if not s or str(s.get('active')) != '1' or str(s.get('type')) not in ('0', '4'):
                continue
            nav = navmap_cua_scn(s['file']) if s.get('file') else None
            r = dbc['idx'].get(n)
            if not nav or r is None:
                continue
            reg = o_chuoi(dbc, r, COL_REGION)
            if goc(nav) != goc(reg):
                va_cham.append({'id': n, 'dot': v.get('dot') if isinstance(v, dict) else None,
                                'ten_canh': s.get('name'), 'type': s.get('type'),
                                'navmap_server': nav, 'dong_DBC_ve': reg})
    return {'dbc_sha256': dbc['sha256'], 'dbc_so_dong': dbc['nR'], 'dem': dem,
            'vi_pham': vi_pham,
            'so_vi_pham': sum(len(v) for v in vi_pham.values()),
            'so_dong_ma': len(ma), 'dong_ma_id': ma,
            'so_va_cham_id': len(va_cham), 'va_cham_id': va_cham}


def doc_moc():
    try:
        return json.load(open(MOC, encoding='utf-8'))
    except (OSError, ValueError):
        return None


def khoa_vi_pham(k):
    """Khoa on dinh cho mot vi pham, de so hai luot chay voi nhau."""
    ra = []
    for truc in ('A_sceneid', 'B_clientres', 'C_lua'):
        for x in k['vi_pham'][truc]:
            ra.append('%s:%s' % (truc, x.get('scene', x.get('client_res'))))
    return sorted(ra)


def cmd_kiem(a):
    k = kiem()
    moc = doc_moc()
    # CONG NAY DO NGAY NGAY DAU TIEN (4 canh FengYun + 7 tri so Lua la no THAT). Mot cong do san
    # thi se bi tat trong ba ngay. Nen no chay theo MOC: chi DO khi co vi pham MOI, hoac khi so
    # dong ma TANG. Moc chi duoc GIAM - `ghi-moc` tu choi noi long.
    hien = khoa_vi_pham(k)
    cu = set((moc or {}).get('vi_pham_da_biet') or [])
    k['vi_pham_hien'] = hien
    k['vi_pham_MOI'] = sorted(set(hien) - cu)
    k['vi_pham_DA_SUA'] = sorted(cu - set(hien))
    k['moc_dong_ma'] = (moc or {}).get('so_dong_ma')
    k['dong_ma_TANG'] = bool(moc and k['so_dong_ma'] > moc['so_dong_ma'])
    cu_vc = set((moc or {}).get('va_cham_da_biet') or [])
    k['va_cham_MOI'] = sorted(set(str(x['id']) for x in k['va_cham_id']) - cu_vc, key=int)
    k['moc_va_cham'] = (moc or {}).get('so_va_cham')
    k['co_moc'] = moc is not None
    k['luc'] = time.strftime('%Y-%m-%dT%H:%M:%S')
    k['dau'] = 'CYS-CLIENTRES'
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        json.dump(k, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('DBC %s (%d dong) | canh bat %d (type0 %d) | tri so Lua %d'
          % (k['dbc_sha256'][:12], k['dbc_so_dong'], k['dem']['canh_bat'],
             k['dem']['canh_type0_bat'], k['dem']['lua_tri_so']))
    for truc in ('A_sceneid', 'B_clientres', 'C_lua'):
        v = k['vi_pham'][truc]
        print('  %-12s VI PHAM %d' % (truc, len(v)))
        for x in v[:12]:
            print('      %s' % json.dumps(x, ensure_ascii=False))
        if len(v) > 12:
            print('      ... con %d, xem --out' % (len(v) - 12))
    print('  dong DBC MA (khong ai tro toi): %d  | moc: %s%s'
          % (k['so_dong_ma'], k['moc_dong_ma'], '  *** TANG ***' if k['dong_ma_TANG'] else ''))
    print('  VA CHAM ID (dong bang ke tren ID cua canh type=0/4 dang bat, ban do KHAC HAN): %d'
          ' | moc: %s' % (k['so_va_cham_id'], k['moc_va_cham']))
    for x in k['va_cham_id']:
        print('      id %-6d dot=%-18s type=%-2s server %-22s -> DBC ve %s'
              % (x['id'], x['dot'], x['type'], x['navmap_server'], x['dong_DBC_ve']))
    if k['va_cham_MOI']:
        print('      *** VA CHAM MOI: %s ***' % ', '.join(k['va_cham_MOI']))
    if k['vi_pham_DA_SUA']:
        print('  DA SUA tu lan chot moc: %s  -> chay `ghi-moc` de moc xuong theo'
              % ', '.join(k['vi_pham_DA_SUA']))
    if not k['co_moc']:
        print('CONG: CHUA CO MOC. Chay `ghi-moc` mot lan de chot %d vi pham dang no, roi tu lan sau'
              ' cong se DO khi co vi pham MOI.' % k['so_vi_pham'])
        return 1
    if k['vi_pham_MOI'] or k['dong_ma_TANG'] or k['va_cham_MOI']:
        ly_do = []
        if k['vi_pham_MOI']:
            ly_do.append('VI PHAM MOI: ' + ', '.join(k['vi_pham_MOI']))
        if k['va_cham_MOI']:
            ly_do.append('VA CHAM ID MOI: ' + ', '.join(k['va_cham_MOI']))
        if k['dong_ma_TANG']:
            ly_do.append('dong ma TANG %d -> %d' % (k['moc_dong_ma'], k['so_dong_ma']))
        print('CONG: DO. ' + ' | '.join(ly_do))
        print('  Dung ket luan "khong sao" - moi dong o tren la mot duong client DI TOI MOT TEP'
              ' KHONG CO, va khong phep kiem nao khac trong du an hoi cau do.')
        return 1
    print('CONG: XANH (khong co vi pham MOI; %d vi pham cu da chot moc, van con no).'
          % k['so_vi_pham'])
    return 0


def cmd_ghi_moc(a):
    k = kiem()
    moc = doc_moc()
    hien = khoa_vi_pham(k)
    if moc:
        if k['so_dong_ma'] > moc['so_dong_ma']:
            print('TU CHOI: moc chi duoc GIAM. dong ma hien %d > moc %d. Xoa dong ma truoc, dung'
                  ' noi long moc.' % (k['so_dong_ma'], moc['so_dong_ma']))
            return 1
        moi = sorted(set(hien) - set(moc.get('vi_pham_da_biet') or []))
        if moi:
            print('TU CHOI: co %d vi pham MOI chua duoc xu ly: %s' % (len(moi), ', '.join(moi)))
            print('  `ghi-moc` la de HA moc sau khi sua, khong phai de nuot mot vi pham moi.')
            return 1
        # Lo hong tu phat hien: lan dau them truc E, `ghi-moc` NUOT 7 va cham moi ma khong keu -
        # tuc ai gai mot qua min roi chay `ghi-moc` la no bien mat. Chi cho phep im lang o lan
        # chot DAU TIEN cua truc nay (khi bang moc chua he co truong `va_cham_da_biet`).
        if moc.get('va_cham_da_biet') is not None:
            vc_moi = sorted(set(str(x['id']) for x in k['va_cham_id'])
                            - set(moc['va_cham_da_biet']), key=int)
            if vc_moi:
                print('TU CHOI: co %d VA CHAM ID MOI: %s' % (len(vc_moi), ', '.join(vc_moi)))
                print('  Mot dong DBC vua duoc dat len ID cua mot canh dang bat ma ve ban do khac.')
                print('  Go dong do, hoac doi ID, hoac bao dieu phoi - dung chot no vao moc.')
                return 1
    os.makedirs(os.path.dirname(MOC), exist_ok=True)
    json.dump({'dau': 'CYS-CLIENTRES', 'luc': time.strftime('%Y-%m-%dT%H:%M:%S'),
               'so_dong_ma': k['so_dong_ma'], 'dbc_sha256': k['dbc_sha256'],
               'dbc_so_dong': k['dbc_so_dong'], 'so_vi_pham': len(hien),
               'vi_pham_da_biet': hien,
               'so_va_cham': k['so_va_cham_id'],
               'va_cham_da_biet': sorted((str(x['id']) for x in k['va_cham_id']), key=int),
               'ghi_chu': 'Moc no ky thuat DA BIET. CHI DUOC GIAM: `ghi-moc` tu choi khi co vi pham'
                          ' moi hoac khi so dong ma tang. Xem Timeline/handoff/clientres-sweep.md.'},
              open(MOC, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('da chot moc: %d vi pham dang no, %d dong ma (DBC %s)'
          % (len(hien), k['so_dong_ma'], k['dbc_sha256'][:12]))
    return 0


# ------------------------------------------------------------------ DOI CHUNG
# Dieu phoi doi: "kem doi chung chung minh biet truot". Mot cong chua bao gio DO thi khong co
# cach nao biet no dang do hay dang mu. Moi phep lam tren BAN SAO, khong cham du lieu song.
def sua_sceneinfo(src, dst, sua):
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


def dbc_tro_o_sang_dong_khac(src, dst, sid_sua, sid_nguon, cot):
    """Tro o `cot` cua dong sid_sua sang CHINH offset chuoi cua dong sid_nguon.
    String pool KHONG bi cham mot byte (khuon T5 cua `tangmen`) - nen cot duong dan GBK an toan."""
    b = open(src, 'rb').read()
    nF, nR, ps = struct.unpack_from('<3I', b, 4)
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]
    idx = {}
    for r in range(nR):
        idx.setdefault(struct.unpack('<i', struct.pack('<I', cells[r * nF]))[0], r)
    ra, rb = idx[sid_sua], idx[sid_nguon]
    cells[ra * nF + cot] = cells[rb * nF + cot]
    moi = b[:off] + b''.join(struct.pack('<%dI' % nF, *cells[r * nF:(r + 1) * nF])
                             for r in range(nR))
    open(dst, 'wb').write(moi + pool)


def cmd_doi_chung(a):
    tmp = tempfile.mkdtemp(prefix='clientres-gate-')
    phep = []

    def do(nhan, si, dbcp, truc, mong_doi_co_vi_pham, vi_sao, loc=None):
        k = kiem(sceneinfo=si, dbcp=dbcp, bo_qua_lua=(truc != 'C_lua'))
        v = k['vi_pham'][truc]
        if loc is not None:
            v = [x for x in v if x.get('scene') == loc or x.get('client_res') == loc]
        co = len(v) > 0
        ok = co == mong_doi_co_vi_pham
        phep.append({'phep': nhan, 'truc': truc, 'vi_sao': vi_sao,
                     'mong_doi_co_vi_pham': mong_doi_co_vi_pham, 'do_duoc_so_vi_pham': len(v),
                     'mau': v[:2], 'KEU_DUNG': ok})
        print('  %-4s %-12s mong=%-5s do=%-3d %s | %s' % (
            nhan, truc, mong_doi_co_vi_pham, len(v), 'OK' if ok else '*** TRUOT ***', vi_sao))

    si0, dbc0 = SCENEINFO, CLI_DBC
    # G1 hien trang: PHAI keu dung bon canh FengYun tren truc A
    do('G1', si0, dbc0, 'A_sceneid', True, 'hien trang: 4 canh FengYun co dong DBC nhung 0 tep client')
    # G2 BIET IM: tat bon canh FengYun tren ban sao -> truc A phai sach
    f = os.path.join(tmp, 'si-G2.ini')
    sua_sceneinfo(si0, f, {814: {'active': 0}, 818: {'active': 0},
                           819: {'active': 0}, 1051: {'active': 0}})
    do('G2', f, dbc0, 'A_sceneid', False, 'tat 4 canh do -> truc A phai IM (cong biet im)')
    # G3 mot canh binh thuong bi tro sang tep khong co -> phai keu
    d3 = os.path.join(tmp, 'dbc-G3.txt')
    dbc_tro_o_sang_dong_khac(dbc0, d3, 9, 1053, COL_REGION)   # canh 9 Thieu Lam -> zijinkuafu_spring
    do('G3', f, d3, 'A_sceneid', True, 'dong 9 (Thieu Lam) tro sang zijinkuafu_spring.path (0 tep)',
       loc=9)
    # G4 dung dbc G3 nhung hoi canh KHAC -> khong duoc keu bua
    do('G4', f, d3, 'A_sceneid', False, 'cung DBC hong, hoi canh 10 -> khong duoc keu bua', loc=10)
    # G5 truc C: hien trang phai keu 7 tri so Lua
    do('G5', si0, dbc0, 'C_lua', True, 'hien trang: 7 tri so client_res Lua khong co dong DBC')
    # G6 truc B: canh khong co dong sceneid, clientres tro vao dong MA
    f6 = os.path.join(tmp, 'si-G6.ini')
    sua_sceneinfo(si0, f6, {814: {'active': 0}, 818: {'active': 0}, 819: {'active': 0},
                            1051: {'active': 0}, 42: {'clientres': 1053}})
    do('G6', f6, dbc0, 'B_clientres', True, 'canh 42 (khong co dong sceneid) -> clientres=1053 = 0 tep',
       loc=42)
    dat = sum(1 for p in phep if p['KEU_DUNG'])
    out = {'dau': 'CYS-CLIENTRES', 'phep': 'cong-doi-chung', 'luc': time.strftime('%Y-%m-%dT%H:%M:%S'),
           'so_dat': dat, 'so_phep': len(phep), 'KET_LUAN': 'DAT %d/%d' % (dat, len(phep)),
           'chi_tiet': phep}
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        json.dump(out, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('DOI CHUNG CONG: %d/%d' % (dat, len(phep)))
    shutil.rmtree(tmp, ignore_errors=True)
    return 0 if dat == len(phep) else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('lenh', choices=['kiem', 'doi-chung', 'ghi-moc'])
    ap.add_argument('--out', default='')
    a = ap.parse_args()
    if a.lenh == 'kiem':
        return cmd_kiem(a)
    if a.lenh == 'ghi-moc':
        return cmd_ghi_moc(a)
    return cmd_doi_chung(a)


sys.exit(main())
