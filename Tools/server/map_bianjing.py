# -*- coding: utf-8 -*-
"""Cài bản đồ 汴京 (Biện Kinh) lên server riêng `R` — plan | apply | verify | navcost | move-char.

Vì sao có công cụ này: 汴京 là bản đồ CY **chưa có gì** ở phía server (không dòng `SceneDefineEx`,
không section `[sceneN]`, không file trong `Game_2/Scene`). Công cụ dựng cả ba tầng, idempotent, và
KHÔNG bao giờ sửa/đè một dòng bảng đang có — chỉ THÊM dòng mới.

Quyết định ID (đo trong `Build/Logs/2026-09-17-map-bianjing/survey/`):
  - scene ID phía server = **755**. Client CY-Source tra bản đồ bằng `packet.sceneid` (ID cảnh
    SERVER), KHÔNG phải `clientres`: `Src/Client/WXClient/Network/CysModernHandlers.cpp:211`
    `SetSceneID((INT)packet.sceneid, …)`, rồi `World/WorldManager.cpp:96-110`
    `Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN=0, nSceneID)` trên DBC
    `Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt`. DBC đó ĐÃ CÓ dòng **755 = "Biện Kinh",
    1024×1024, `bianjing.Scene`** nên chọn 755 là cách duy nhất để client không ném
    `TDThrow("Invalid scene ID")`. 755 chưa có section trong `SceneInfo.ini` → thêm mới, không đè ai.
  - `clientres` = **1074** = dòng MỚI trong bảng mirror phía server `configs/SceneDefineEx.txt`.
    Trường này client KHÔNG dùng (chỉ ghi log), nhưng `scene_install.py` bắt buộc nó phải có thật
    trong bảng server, và `verify` đòi tên file khớp. Dòng 755 của bảng mirror đang là 寒雪灵境
    (`HJZBS_BaiXiHuGameArea`) nên không được đè; 1074 trống ở CẢ bảng mirror (hết ở 1056) lẫn bảng
    thô DataCY (nhảy 1073 → 1075), nên thêm mới là sạch nhất.
  - 5 tuyến phụ **775/776/779/780/785** (client DBC gọi "Biện Kinh 2–6 tuyến", cùng `bianjing.Scene`)
    được thêm section nhưng để `active=0`: chúng dùng chung file, nhưng mỗi cảnh sống tốn thêm ~32 s
    nạp navmesh lúc khởi động (xem `navcost`). Bật bằng `scene_install.py enable --scenes 775,...`.

Nội dung dòng `SceneDefineEx` mới = **đúng 23 ô sau của dòng CY 755**, chỉ đổi ô 0 (Index) thành 1074;
bảng server 24 cột nên bỏ ô 25 của CY (giá trị "0"). Bảng là GBK, ghi ở mức byte.

Navmesh `bianjing.path` chép **nguyên byte** từ `Assets/CanonicalCY/Data/SceneFolder/bianjing.path`.

Mọi thay đổi `configs/SceneInfo.ini` đi qua `Tools/server/scene_install.py` (giữ `flock`, an toàn khi
nhiều agent chạy song song). Công cụ này cũng giữ CÙNG một `flock` khi ghi `SceneDefineEx.txt`.

  map_bianjing.py plan      [--out F]
  map_bianjing.py apply     [--out F]
  map_bianjing.py verify    [--out F]
  map_bianjing.py navcost   [--out F]      đo thời gian nạp navmesh bằng chính pathparser/lnavmesh của server
  map_bianjing.py sceneattr [--apply] [--out F]   sửa ĐÚNG 4 ô của ĐÚNG dòng 755 trong configs/SceneAttr.txt
  map_bianjing.py move-char --guid 200006 --out F [--scene 755 --x 512 --z 942]
"""
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
R = '/home/ubuntu/cys-test-20260913'
CFG = os.path.join(R, 'configs')
SDE = os.path.join(CFG, 'SceneDefineEx.txt')
INI = os.path.join(CFG, 'SceneInfo.ini')
SCENE_DIR = os.path.join(R, 'Game_2', 'Scene')
LOCK = os.path.join(CFG, '.scene_install.lock')
SCENE_INSTALL = os.path.join(HERE, 'scene_install.py')

CY_CFG = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
S4_SCENE = '/mnt/c/TLBB/085/CY-Source/Assets/CanonicalCY/Data/SceneFolder'

MAP = 'bianjing'
SCENE_ID = 755             # ID cảnh SERVER = dòng DBC client (cột 0) "Biện Kinh" / bianjing.Scene
SHARDS = [775, 776, 779, 780, 785]   # "Biện Kinh 2–6 tuyến" trong DBC client, cùng bianjing.Scene
OLD_SCENE_ID = 4511        # lần thử đầu dùng ID cảnh của server CY (SceneAttr 4511) — SAI TRỤC, đã tắt
CLIENTRES = 1074           # dòng MỚI trong bảng mirror phía server; client KHÔNG dùng trường này
CY_SDE_ROW = 755           # dòng 汴京 trong bảng thô CY (nguồn nội dung 23 ô cho dòng mirror)
THREADINDEX = 32           # khoá này KHÔNG được mã skynet đọc (grep 0 kết quả) — đặt giá trị chưa ai dùng
NAME = '汴京'
SCN = MAP + '.scn'
STAND = (512, 942)         # SceneAttr CY dòng 4511 cột 4/5 "可以站立的位置X/Z" (KHÔNG phải kích thước:
                           # bản đồ là 1024×1024, đo bằng bianjing.Heightmap = (1024+1)^2*4 + 16 byte)
# Điểm CY đáng tin trong 汴京 (ScenePosDefineEx / TransportDefine), dùng để kiểm đi được:
CY_POINTS = {
    'diem_dung_SceneAttr': (512, 942),
    'den_tu_洛阳': (757, 435),          # ScenePosDefineEx: 洛阳 (195,269) -> 汴京 (757,435)
    'npc_金阅楼': (752, 435),
    'npc_余繁': (688, 752),
    'npc_梁民': (347, 353),
    'npc_许行之': (360, 724),
    'npc_唐松': (530, 937),
    'npc_杨中川': (542, 554),
}

# `.scn` chỉ do CÔNG CỤ NÀY tạo lần đầu. Sau đó agent khác (NPC/cổng) được phép thêm khoá
# `monsterfile=`, `eventfile=`, … vào đúng file này — 17/09 agent NPC đã thêm `monsterfile=bianjing_monster.ini`.
# Vì vậy `apply` KHÔNG BAO GIỜ ghi đè `.scn` đã có: chỉ tạo khi thiếu, và chỉ sửa đúng dòng `navmapname`
# nếu nó sai. `verify` cũng chỉ đòi `navmapname` đúng, các khoá khác là của người khác.
SCN_BODY = '[System]\nnavmapname=%s.path\n' % MAP
SCN_NAVKEY = 'navmapname=%s.path' % MAP


def scn_doc(path):
    """Đọc `.scn` thành (danh sách dòng, giá trị navmapname)."""
    if not os.path.isfile(path):
        return None, None
    txt = open(path, 'rb').read().decode('ascii', 'replace')
    nav = None
    for ln in txt.split('\n'):
        if ln.strip().lower().startswith('navmapname'):
            nav = ln.split('=', 1)[1].split(';')[0].strip() if '=' in ln else ''
    return txt, nav


# ---------------------------------------------------------------- tiện ích

def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for blk in iter(lambda: f.read(1 << 20), b''):
            h.update(blk)
    return h.hexdigest()


class Lock(object):
    """Cùng flock với scene_install.py, để hai agent ghi song song không đè nhau."""

    def __enter__(self):
        import fcntl
        self.fh = open(LOCK, 'a+')
        fcntl.flock(self.fh, fcntl.LOCK_EX)
        return self

    def __exit__(self, *a):
        import fcntl
        fcntl.flock(self.fh, fcntl.LOCK_UN)
        self.fh.close()
        return False


def read_rows(path, enc='gbk'):
    raw = open(path, 'rb').read().decode(enc, 'replace')
    rows = {}
    for i, line in enumerate(raw.split('\n')):
        c = line.rstrip('\r').split('\t')
        if len(c) >= 5 and c[0].strip().isdigit():
            rows[int(c[0])] = {'dong': i, 'cols': c}
    return rows


def sde_rows():
    return read_rows(SDE)


def cy_sde_rows():
    return read_rows(os.path.join(CY_CFG, 'SceneDefineEx.txt'))


def ini_sections():
    import re
    raw = open(INI, 'rb').read().decode('gbk', 'replace')
    out, cur = {}, None
    for line in raw.split('\n'):
        m = re.match(r'^\[scene(\d+)\]\s*$', line.strip())
        if m:
            cur = int(m.group(1))
            out[cur] = {}
            continue
        if cur is not None and '=' in line:
            k, v = line.split('=', 1)
            out[cur][k.strip().lower()] = v.split(';')[0].strip()
    return out


def new_sde_line():
    """Dòng SceneDefineEx mới: ô 0 = CLIENTRES, 23 ô còn lại COPY NGUYÊN từ dòng CY 755."""
    cy = cy_sde_rows()[CY_SDE_ROW]['cols']
    cols = [str(CLIENTRES)] + cy[1:24]      # bảng server 24 cột; CY có 25, bỏ ô cuối
    assert len(cols) == 24, len(cols)
    return '\t'.join(cols)


def run_scene_install(args, check=True):
    cmd = [sys.executable, '-B', SCENE_INSTALL] + args
    p = subprocess.run(cmd, capture_output=True, text=True)
    rec = {'lenh': ' '.join(args), 'rc': p.returncode, 'out': p.stdout.strip(), 'err': p.stderr.strip()}
    if check and p.returncode != 0:
        rec['LOI'] = True
    return rec


# ---------------------------------------------------------------- các lệnh

def trang_thai():
    sde = sde_rows()
    sec = ini_sections()
    src = os.path.join(S4_SCENE, MAP + '.path')
    dst = os.path.join(SCENE_DIR, MAP + '.path')
    scn = os.path.join(SCENE_DIR, SCN)
    st = {
        'scene_id': SCENE_ID, 'clientres': CLIENTRES, 'map': MAP,
        'sde_co_dong_clientres': CLIENTRES in sde,
        'sde_dong_clientres': sde.get(CLIENTRES, {}).get('cols', [])[:6],
        'sde_so_dong': len(sde), 'sde_id_lon_nhat': max(sde) if sde else None,
        'sde_mirror_755_la': sde.get(755, {}).get('cols', [])[:5],
        'sde_co_bianjing_o_dong_khac': [i for i, r in sde.items() if MAP in r['cols'][4].lower()],
        'ini_co_section': SCENE_ID in sec,
        'ini_section': sec.get(SCENE_ID),
        'ini_shard': {s: sec.get(s) for s in SHARDS},
        'ini_section_4511_cu': sec.get(OLD_SCENE_ID),
        'ini_id_lon_nhat': max(sec) if sec else None,
        'nguon_path_ton_tai': os.path.isfile(src),
        'nguon_path_byte': os.path.getsize(src) if os.path.isfile(src) else 0,
        'dich_path_ton_tai': os.path.isfile(dst),
        'dich_path_byte': os.path.getsize(dst) if os.path.isfile(dst) else 0,
        'scn_ton_tai': os.path.isfile(scn),
        'scn_noi_dung': scn_doc(scn)[0],
        'scn_navmapname': scn_doc(scn)[1],
        'scn_khoa_cua_agent_khac': [ln.split('=', 1)[0].strip()
                                    for ln in (scn_doc(scn)[0] or '').split('\n')
                                    if '=' in ln and not ln.strip().lower().startswith('navmapname')],
    }
    if st['dich_path_ton_tai']:
        st['dich_path_sha256'] = sha256(dst)
    if st['nguon_path_ton_tai']:
        st['nguon_path_sha256'] = sha256(src)
    return st


def cmd_plan(args):
    st = trang_thai()
    st['dong_sde_se_them'] = new_sde_line().split('\t')
    st['scn_se_ghi'] = SCN_BODY
    st['viec'] = []
    if not st['dich_path_ton_tai'] or st.get('dich_path_sha256') != st.get('nguon_path_sha256'):
        st['viec'].append('chep %s.path nguyen byte' % MAP)
    if not st['scn_ton_tai']:
        st['viec'].append('tao %s' % SCN)
    elif st['scn_navmapname'] != MAP + '.path':
        st['viec'].append('sua dong navmapname trong %s (giu nguyen khoa khac)' % SCN)
    if not st['sde_co_dong_clientres']:
        st['viec'].append('them dong SceneDefineEx mirror id=%d' % CLIENTRES)
    if not st['ini_co_section']:
        st['viec'].append('scene_install.py add --id %d' % SCENE_ID)
    elif (st['ini_section'] or {}).get('active') != '1':
        st['viec'].append('scene_install.py enable --scenes %d' % SCENE_ID)
    for s in SHARDS:
        if not st['ini_shard'].get(s):
            st['viec'].append('scene_install.py add --id %d (tuyen phu, active=0)' % s)
    if st['ini_section_4511_cu'] and st['ini_section_4511_cu'].get('active') == '1':
        st['viec'].append('scene_install.py disable --scenes %d (ID cu sai truc)' % OLD_SCENE_ID)
    xuat(st, args)
    return 0


def cmd_apply(args):
    rec = {'buoc': [], 'truoc': trang_thai()}
    src = os.path.join(S4_SCENE, MAP + '.path')
    dst = os.path.join(SCENE_DIR, MAP + '.path')
    scn = os.path.join(SCENE_DIR, SCN)
    if not os.path.isfile(src):
        sys.exit('khong co nguon navmesh: %s' % src)

    # 1. navmesh nguyen byte
    if os.path.isfile(dst) and sha256(dst) == sha256(src):
        rec['buoc'].append({'viec': 'path', 'ket_qua': 'da dung san (sha256 trung)'})
    else:
        if os.path.isfile(dst):
            shutil.copy2(dst, dst + '.truoc-map-bianjing')
        shutil.copyfile(src, dst)
        rec['buoc'].append({'viec': 'path', 'ket_qua': 'da chep', 'byte': os.path.getsize(dst),
                            'sha256': sha256(dst), 'nguon': src})

    # 2. .scn — KHONG BAO GIO ghi de file da co (agent khac them monsterfile/eventfile vao day)
    cu, nav = scn_doc(scn)
    if cu is None:
        open(scn, 'wb').write(SCN_BODY.encode('ascii'))
        rec['buoc'].append({'viec': 'scn', 'ket_qua': 'da tao moi', 'noi_dung': SCN_BODY})
    elif nav == MAP + '.path':
        rec['buoc'].append({'viec': 'scn', 'ket_qua': 'da co, navmapname dung — GIU NGUYEN',
                            'khoa_khac': [ln.split('=', 1)[0].strip() for ln in cu.split('\n')
                                          if '=' in ln and not ln.strip().lower().startswith('navmapname')]})
    else:
        shutil.copy2(scn, scn + '.truoc-map-bianjing')
        moi = '\n'.join((SCN_NAVKEY if ln.strip().lower().startswith('navmapname') else ln)
                        for ln in cu.split('\n'))
        open(scn, 'wb').write(moi.encode('ascii'))
        rec['buoc'].append({'viec': 'scn', 'ket_qua': 'chi sua dong navmapname', 'cu': nav, 'moi': MAP + '.path'})

    # 3. dong SceneDefineEx (THEM, khong bao gio sua dong san co)
    with Lock():
        sde = sde_rows()
        if CLIENTRES in sde:
            rec['buoc'].append({'viec': 'sde', 'ket_qua': 'dong %d da co' % CLIENTRES,
                                'cols': sde[CLIENTRES]['cols'][:6]})
        else:
            bak = os.path.join(R, 'backups', 'map-bianjing-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()))
            os.makedirs(bak, exist_ok=True)
            shutil.copy2(SDE, os.path.join(bak, 'SceneDefineEx.txt'))
            raw = open(SDE, 'rb').read()
            if not raw.endswith(b'\n'):
                raw += b'\r\n'
            them = (new_sde_line() + '\r\n').encode('gbk')
            open(SDE, 'wb').write(raw + them)
            sde2 = sde_rows()
            rec['buoc'].append({'viec': 'sde', 'ket_qua': 'da them dong %d' % CLIENTRES,
                                'sao_luu': bak, 'so_dong_truoc': len(sde), 'so_dong_sau': len(sde2),
                                'cols': sde2[CLIENTRES]['cols']})

    # 4. SceneInfo qua scene_install.py (giu flock cua chinh no)
    sec = ini_sections()
    if SCENE_ID not in sec:
        rec['buoc'].append(run_scene_install(['add', '--id', str(SCENE_ID), '--name', NAME,
                                              '--file', SCN, '--clientres', str(CLIENTRES),
                                              '--type', '0', '--threadindex', str(THREADINDEX),
                                              '--active', '0']))
    else:
        rec['buoc'].append({'lenh': 'add', 'rc': 0, 'out': 'section scene%d da co, bo qua' % SCENE_ID})
    rec['buoc'].append(run_scene_install(['enable', '--scenes', str(SCENE_ID)]))

    # 5. Tuyen phu 775/776/779/780/785: them nhung DE active=0 (moi canh song ton them ~32 s nap nav)
    for i, s in enumerate(SHARDS):
        if s in sec:
            rec['buoc'].append({'lenh': 'add shard %d' % s, 'rc': 0, 'out': 'da co, bo qua'})
            continue
        rec['buoc'].append(run_scene_install(['add', '--id', str(s), '--name', '%s%d线' % (NAME, i + 2),
                                              '--file', SCN, '--clientres', str(CLIENTRES),
                                              '--type', '0', '--threadindex', str(THREADINDEX + 1 + i),
                                              '--active', '0']))

    # 6. Don lan thu dau: scene 4511 (ID canh cua server CY) KHONG co dong DBC client -> tat han
    if OLD_SCENE_ID in ini_sections():
        rec['buoc'].append(run_scene_install(['disable', '--scenes', str(OLD_SCENE_ID)]))

    rec['buoc'].append(run_scene_install(['verify', '--scenes', str(SCENE_ID)]))
    rec['sau'] = trang_thai()
    xuat(rec, args)
    return 0 if all(b.get('rc', 0) == 0 for b in rec['buoc']) else 1


def cmd_verify(args):
    st = trang_thai()
    loi = []
    src = os.path.join(S4_SCENE, MAP + '.path')
    dst = os.path.join(SCENE_DIR, MAP + '.path')
    if not st['dich_path_ton_tai']:
        loi.append('thieu %s' % dst)
    elif st.get('dich_path_sha256') != st.get('nguon_path_sha256'):
        loi.append('navmesh KHAC nguon CY (sha256 lech)')
    if not st['scn_ton_tai']:
        loi.append('thieu %s' % SCN)
    elif st['scn_navmapname'] != MAP + '.path':
        loi.append('%s co navmapname=%r, phai la %s.path' % (SCN, st['scn_navmapname'], MAP))
    # Các khoá khác trong .scn (monsterfile/eventfile/…) là của agent NPC/cổng — chỉ ghi nhận, không phán.
    if not st['sde_co_dong_clientres']:
        loi.append('thieu dong SceneDefineEx %d' % CLIENTRES)
    else:
        cols = sde_rows()[CLIENTRES]['cols']
        cy = cy_sde_rows()[CY_SDE_ROW]['cols']
        if cols[1:24] != cy[1:24]:
            loi.append('dong %d KHAC 23 o cua CY 755' % CLIENTRES)
    si = run_scene_install(['verify', '--scenes', str(SCENE_ID)])
    try:
        si_json = json.loads(si['out'])
    except Exception:
        si_json = {'ok': False, 'raw': si['out']}
    if not si_json.get('ok'):
        loi.append('scene_install verify: %s' % si_json.get('loi'))

    # DBC client: client tra bang ID CANH SERVER (cot 0). Khong co dong -> "Invalid scene ID".
    dbc = {}
    try:
        sys.path.insert(0, os.path.join('/mnt/c/TLBB/085/CY-Source', 'Tools', 'game'))
        from dbc_inventory import Table
        t = Table('/mnt/c/TLBB/085/CY-Source/Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt')
        for r in t.rows:
            try:
                dbc[int(r[0])] = [str(r[1]), str(r[2]), str(r[3]), str(r[4])]
            except (ValueError, IndexError):
                continue
    except Exception as e:                                     # noqa: BLE001
        loi.append('khong doc duoc DBC client: %s' % e)
    if dbc:
        d = dbc.get(SCENE_ID)
        if not d:
            loi.append('DBC client KHONG co dong %d -> client nem "Invalid scene ID"' % SCENE_ID)
        elif not d[3].lower().startswith(MAP):
            loi.append('DBC client dong %d tro toi %s, khong phai %s' % (SCENE_ID, d[3], MAP))
        st['dbc_client_dong_%d' % SCENE_ID] = d
        st['dbc_client_tuyen_phu'] = {s: dbc.get(s) for s in SHARDS}

    # Kich thuoc that cua ban do: (W+1)^2 * 4 float + 16 byte dau cua .Heightmap
    hm = os.path.join(S4_SCENE, MAP + '.Heightmap')
    if os.path.isfile(hm):
        n = os.path.getsize(hm)
        w = [k for k in (64, 128, 256, 320, 512, 768, 1024, 2048) if (k + 1) ** 2 * 4 + 16 == n]
        st['heightmap_byte'] = n
        st['heightmap_suy_ra_kich_thuoc'] = (w[0] if w else None)
        if dbc and dbc.get(SCENE_ID) and w and str(w[0]) != dbc[SCENE_ID][1]:
            loi.append('kich thuoc lech: Heightmap => %d nhung DBC ghi %s' % (w[0], dbc[SCENE_ID][1]))

    # navmesh: doc bang chinh parser cua cs3a_scene + kiem diem CY
    nav = {}
    if st['dich_path_ton_tai']:
        p = subprocess.run([sys.executable, '-B', os.path.join(HERE, 'cs3a_scene.py'), 'query', dst]
                           + ['%d,%d' % v for v in CY_POINTS.values()], capture_output=True, text=True)
        ten = list(CY_POINTS)
        for i, line in enumerate([l for l in p.stdout.split('\n') if l.strip()]):
            if i < len(ten):
                nav[ten[i]] = line.strip()
        # dòng có dạng "512,942 (57769, 0, 2)" = (tam giác, cờ, vùng); cờ bit0 = bị chặn
        chan = [k for k, v in nav.items() if v.split('(')[-1].split(',')[1].strip() == '1']
        if STAND and nav.get('diem_dung_SceneAttr', '').split('(')[-1].split(',')[1].strip() == '1':
            loi.append('diem dung CY (%d,%d) BI CHAN tren navmesh' % STAND)
        nav['_bi_chan'] = chan
    rec = {'lenh': 'verify', 'ok': not loi, 'loi': loi, 'scene_install': si_json,
           'navmesh_diem_CY': nav, 'trang_thai': st}
    xuat(rec, args)
    return 0 if not loi else 1


def cmd_navcost(args):
    """Đo thời gian pathparser + lnavmesh của CHÍNH server nạp bianjing.path đã cài."""
    gs = os.path.join(R, 'GameServer')
    lua_sc = os.path.join(os.path.dirname(os.path.dirname(HERE)),
                          'Build', 'Logs', '2026-09-17-map-bianjing', 'scripts', '10-navbuild.lua')
    env = dict(os.environ)
    env['LUA_PATH'] = '%s/lualib/?.lua;%s/framework/lualib/?.lua;;' % (gs, gs)
    env['LUA_CPATH'] = '%s/luaclib/?.so;%s/framework/luaclib/?.so;;' % (gs, gs)
    out = {}
    for ten, f in (('dali_new_320', os.path.join(SCENE_DIR, 'dali_new_320.path')),
                   (MAP, os.path.join(SCENE_DIR, MAP + '.path'))):
        if not os.path.isfile(f):
            out[ten] = 'khong co file'
            continue
        t0 = time.time()
        p = subprocess.run(['/usr/bin/lua5.4', lua_sc, f], capture_output=True, text=True, env=env)
        out[ten] = {'stdout': p.stdout.strip().split('\n')[0] if p.stdout.strip() else '',
                    'wall_s': round(time.time() - t0, 2)}
    xuat(out, args)
    return 0


SA = os.path.join(CFG, 'SceneAttr.txt')
CY_SA_ROW = 4511           # dòng 汴京 trong SceneAttr của CY (ID cảnh phía server CY) — nguồn giá trị mới
# Ô cần sửa của dòng 755 trong SceneAttr phía server -> lấy từ cùng ô của dòng CY 4511.
# Tên cột lấy ở dòng 2 (dòng tên) của chính bảng server:
#   0 ID | 1 Name$1$ | 2 类型 | 3 安全级别 | 4 可以站立的位置X | 5 可以站立的位置Z | ...
SA_CELLS = {1: 'Name$1$', 3: '安全级别', 4: '可以站立的位置X', 5: '可以站立的位置Z'}


def _sa_lines():
    raw = open(SA, 'rb').read()
    return raw, raw.split(b'\n')


def _sa_find(lines, sid):
    for i, ln in enumerate(lines):
        c = ln.rstrip(b'\r').split(b'\t')
        if c and c[0] == str(sid).encode('ascii'):
            return i
    return None


def cmd_sceneattr(args):
    """Sửa ĐÚNG dòng 755 của configs/SceneAttr.txt, ĐÚNG 4 ô, ở mức BYTE, giữ GBK và số tab.

    Vì sao phải sửa: bảng này đánh chỉ số theo ID CẢNH SERVER (`cfghelper.lua:736-749`,
    `script_base.lua:1536/1546`), dày đặc 0..19092 không hở ID nên KHÔNG thêm dòng được. Dòng 755
    đang là 副本 (rác của cảnh khác) ⇒ `scene_attr[755].safe_level = 0` (PK mở trong thành) và
    `.name = 副本`. Giá trị mới lấy nguyên từ dòng CY 4511 (汴京), không tự nghĩ số.
    """
    cy = {}
    for ln in open(os.path.join(CY_CFG, 'SceneAttr.txt'), 'rb').read().decode('gbk', 'replace').split('\n'):
        c = ln.rstrip('\r').split('\t')
        if len(c) > 5 and c[0].strip().isdigit():
            cy[int(c[0])] = c
    src = cy.get(CY_SA_ROW)
    if not src:
        sys.exit('khong thay dong CY SceneAttr %d' % CY_SA_ROW)

    raw, lines = _sa_lines()
    i = _sa_find(lines, SCENE_ID)
    if i is None:
        sys.exit('khong thay dong %d trong %s' % (SCENE_ID, SA))
    eol = b'\r' if lines[i].endswith(b'\r') else b''
    cols = lines[i].rstrip(b'\r').split(b'\t')
    hdr = lines[1].rstrip(b'\r').split(b'\t') if len(lines) > 1 else []

    bang = []
    moi = list(cols)
    for ci, ten in sorted(SA_CELLS.items()):
        cu_b = cols[ci]
        moi_b = src[ci].encode('gbk')
        bang.append({'cot': ci, 'ten_cot': (hdr[ci].decode('gbk', 'replace') if ci < len(hdr) else '?'),
                     'ten_cot_mong_doi': ten,
                     'truoc': cu_b.decode('gbk', 'replace'), 'sau': src[ci],
                     'nguon': 'SceneAttr CY dong %d cot %d' % (CY_SA_ROW, ci),
                     'doi': cu_b != moi_b})
        moi[ci] = moi_b

    rec = {'lenh': 'sceneattr', 'file': SA, 'dong_file': i, 'scene': SCENE_ID,
           'so_cot_dong_755': len(cols), 'so_cot_dong_CY_4511': len(src),
           'ket_thuc_dong': 'CRLF' if eol else 'LF',
           'dong_truoc': [c.decode('gbk', 'replace') for c in cols[:8]],
           'bang_o': bang,
           'da_ap': False}

    if not args.apply:
        rec['ghi_chu'] = 'CHUA GHI GI (them --apply de ghi)'
        xuat(rec, args)
        return 0

    if not any(b['doi'] for b in bang):
        rec['ghi_chu'] = 'moi o da dung san, khong ghi'
        xuat(rec, args)
        return 0

    with Lock():
        raw, lines = _sa_lines()                       # đọc lại trong lock
        i = _sa_find(lines, SCENE_ID)
        cols = lines[i].rstrip(b'\r').split(b'\t')
        bak = os.path.join(R, 'backups',
                           'map-bianjing-sceneattr-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()))
        os.makedirs(bak, exist_ok=True)
        shutil.copy2(SA, os.path.join(bak, 'SceneAttr.txt'))
        moi = list(cols)
        for ci in SA_CELLS:
            moi[ci] = src[ci].encode('gbk')
        assert len(moi) == len(cols), 'so cot doi!'
        lines[i] = b'\t'.join(moi) + eol
        open(SA, 'wb').write(b'\n'.join(lines))
        rec['sao_luu'] = bak
        rec['da_ap'] = True

    # CHUNG MINH: moi dong khac giong TUNG BYTE, va trong dong 755 chi 4 o doi
    old_raw = open(os.path.join(rec['sao_luu'], 'SceneAttr.txt'), 'rb').read()
    new_raw = open(SA, 'rb').read()
    ol, nl = old_raw.split(b'\n'), new_raw.split(b'\n')
    khac = [k for k in range(max(len(ol), len(nl)))
            if (ol[k] if k < len(ol) else None) != (nl[k] if k < len(nl) else None)]
    oc = ol[i].rstrip(b'\r').split(b'\t')
    nc = nl[i].rstrip(b'\r').split(b'\t')
    o_khac = [k for k in range(max(len(oc), len(nc)))
              if (oc[k] if k < len(oc) else None) != (nc[k] if k < len(nc) else None)]
    try:
        new_raw.decode('gbk')
        gbk = 'OK'
    except UnicodeDecodeError as e:                    # noqa: BLE001
        gbk = 'LOI: %s' % e
    rec['chung_minh'] = {
        'so_dong_truoc': len(ol), 'so_dong_sau': len(nl),
        'dong_khac_nhau': khac, 'chi_dung_dong_755': khac == [i],
        'o_khac_trong_dong_755': o_khac, 'dung_4_o_da_neu': sorted(o_khac) == sorted(SA_CELLS),
        'so_cot_truoc': len(oc), 'so_cot_sau': len(nc),
        'byte_truoc': len(old_raw), 'byte_sau': len(new_raw),
        'toan_file_giai_ma_GBK': gbk,
        'dong_755_sau': b'\t'.join(nc[:8]).decode('gbk', 'replace'),
    }
    rec['ok'] = (khac == [i] and sorted(o_khac) == sorted(SA_CELLS)
                 and len(oc) == len(nc) and gbk == 'OK')
    xuat(rec, args)
    return 0 if rec['ok'] else 1


def guid_online(guid):
    """Nhân vật này có ĐANG online không, đọc từ log skynet đang chạy.

    `[CLIENT_LINK] connected/disconnected guid= N` — đếm chênh lệch. Dùng khi server ĐANG CHẠY:
    hiểm hoạ thật của việc ghi Mongo là ghi đè bản ghi mà server đang giữ trong bộ nhớ cho CHÍNH
    nhân vật đó; các nhân vật khác đang online không liên quan.
    """
    import glob
    import re
    logs = sorted(glob.glob(os.path.join(R, 'log', '2026*', 'Game2_*.log')), key=os.path.getmtime)
    if not logs:
        return None, {'loi': 'khong thay log'}
    p = logs[-1]
    txt = open(p, 'rb').read().decode('utf-8', 'replace')
    con = dis = 0
    for m in re.finditer(r'CLIENT_LINK\] (dis)?connected guid= (\d+)', txt):
        if int(m.group(2)) == guid:
            if m.group(1):
                dis += 1
            else:
                con += 1
    nhac = len([1 for _ in re.finditer(r'\b%d\b' % guid, txt)])
    return con > dis, {'log': p, 'connected': con, 'disconnected': dis, 'so_lan_nhac_guid': nhac}


def cmd_move_char(args):
    """Dời nhân vật test sang cảnh 汴京.

    Mặc định (cửa sổ restart): từ chối nếu CÓ BẤT KỲ client nào nối 15733/15734 — an toàn nhất vì
    lúc đó skynet đã dừng. Với `--server-running` (server đang chạy, agent khác đang đo): chỉ từ chối
    nếu CHÍNH nhân vật này đang online, và ghi bằng chứng vào kết quả.
    """
    spec_path = os.path.join(HERE, 'provision_test_wsl.py')
    import importlib.util
    spec = importlib.util.spec_from_file_location('private_server', spec_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    def clients():
        n = 0
        for name in ('/proc/net/tcp', '/proc/net/tcp6'):
            for line in open(name).read().splitlines()[1:]:
                parts = line.split()
                port = int(parts[1].split(':')[1], 16)
                if port in (15733, 15734) and parts[3] == '01':
                    n += 1
        return n

    with module.database() as client:
        col = client['tlbb']['character']
        docs = list(col.find({'attrib.guid': args.guid}, {'_id': 0, 'attrib': 1}))
        if len(docs) != 1:
            sys.exit('can dung 1 nhan vat guid=%d, tim thay %d' % (args.guid, len(docs)))
        at = docs[0].get('attrib') or {}
        truoc = {'guid': at.get('guid'), 'sceneid': at.get('sceneid'),
                 'world_pos': {k: v for k, v in (at.get('world_pos') or {}).items()
                               if isinstance(v, (int, float))}}
        rec = {'guid': args.guid, 'truoc': truoc}
        if args.server_running:
            online, bang_chung = guid_online(args.guid)
            rec['kiem_online'] = bang_chung
            rec['dang_online'] = online
            if online:
                sys.exit('guid %d DANG ONLINE (%s); tu choi ghi' % (args.guid, bang_chung))
        if args.dry_run:
            xuat(rec, args)
            return 0
        if not args.server_running and clients():
            sys.exit('con client noi 15733/15734; tu choi ghi (them --server-running neu co y '
                     'ghi luc server dang chay va nhan vat nay offline)')
        if args.out and os.path.exists(args.out):
            sys.exit('file out da ton tai: ' + args.out)
        if args.out:
            json.dump(rec, open(args.out, 'x', encoding='utf-8'), ensure_ascii=False, indent=1)
        r = col.update_one({'attrib.guid': args.guid},
                           {'$set': {'attrib.world_pos.x': float(args.x),
                                     'attrib.world_pos.y': float(args.z),
                                     'attrib.sceneid': args.scene}})
        sau = col.find_one({'attrib.guid': args.guid}, {'_id': 0, 'attrib': 1}).get('attrib') or {}
        rec.update({'dat': {'sceneid': args.scene, 'x': args.x, 'z': args.z},
                    'matched': r.matched_count, 'modified': r.modified_count,
                    'sau': {'sceneid': sau.get('sceneid'),
                            'world_pos': {k: v for k, v in (sau.get('world_pos') or {}).items()
                                          if isinstance(v, (int, float))}}})
        xuat(rec, args)
    return 0


def xuat(obj, args):
    s = json.dumps(obj, ensure_ascii=False, indent=1)
    print(s)
    if getattr(args, 'out', None):
        with open(args.out, 'w', encoding='utf-8') as f:
            f.write(s)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd')
    for n in ('plan', 'apply', 'verify', 'navcost'):
        a = sub.add_parser(n)
        a.add_argument('--out', default='')
    a = sub.add_parser('sceneattr')
    a.add_argument('--apply', action='store_true', help='mac dinh CHI XEM; co co nay moi ghi')
    a.add_argument('--out', default='')
    a = sub.add_parser('move-char')
    a.add_argument('--guid', type=int, required=True)
    a.add_argument('--scene', type=int, default=SCENE_ID)
    a.add_argument('--x', type=float, default=STAND[0])
    a.add_argument('--z', type=float, default=STAND[1])
    a.add_argument('--dry-run', action='store_true')
    a.add_argument('--server-running', action='store_true',
                   help='server DANG CHAY: chi tu choi neu CHINH nhan vat nay online (doc log CLIENT_LINK)')
    a.add_argument('--out', default='')
    args = ap.parse_args()
    fn = {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify,
          'navcost': cmd_navcost, 'sceneattr': cmd_sceneattr,
          'move-char': cmd_move_char}.get(args.cmd)
    if not fn:
        ap.print_help()
        return 2
    return fn(args)


if __name__ == '__main__':
    sys.exit(main())
