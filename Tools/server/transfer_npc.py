# -*- coding: utf-8 -*-
"""NPC dịch chuyển nối các thành + mở 冰雪不夜城 Bất Dạ Thành đúng **ID cảnh 1007**.

## ID cảnh: 1007, KHÔNG phải 490

Client CY-Source tra bản đồ bằng **ID cảnh SERVER** (`packet.sceneid`), không phải `clientres`:
`Src/Client/WXClient/Network/CysModernHandlers.cpp:210` gọi `SetSceneID((INT)packet.sceneid, …)`
(còn `packet.client_res` chỉ được ghi log), rồi `Src/Client/WXClient/World/WorldManager.cpp:107`
tra `Search_First_Column_Equ(_DBC_SCENE_DEFINE::SCENE_SERVER_ID_COLUMN = 0, nSceneID)`; không có
dòng thì `TDThrow("(CWorldManager::EnterScene) Invalid scene ID")`.

Bảng client là DBC `Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt` (682 dòng × 25 cột,
cột 0 = ID cảnh server). Đo được: **1007 = "Băng Tuyết Bất Dạ Thành", 320×320, `SnowWorld2024.Scene`**;
**không có dòng 490** ⇒ bật cảnh 490 thì server chạy nhưng client ném "Invalid scene ID".
Vì vậy công cụ này dựng cảnh **1007**, trả `buyecheng.*` (cảnh 490) về đúng như bản phát hành và
để 490 `active=0`.

## Navmesh

`SceneDefineEx` phía SERVER dòng 728 và DBC client dòng 1007 đều trỏ `SnowWorld2024.path` (320×320).
`buyecheng.path` đời GL là **địa hình khác** (256×256, trùng ô đi được 51,6 % trên vùng chung) — số
đo ở `Docs/specs/server/transfer-npc_vi.md` mục 2. Nên nội dung cảnh 1007 mang tên `SnowWorld2024.*`
để tên bản đồ phía server trùng tên tài nguyên phía client, đúng như `cs3a` đã làm cho
`luoyang_new` / `suzhou_new` / `dali_new_320`.

  transfer_npc.py plan   [--out F]      in kế hoạch, KHÔNG ghi gì
  transfer_npc.py apply  [--out F]      sao lưu rồi ghi (idempotent)
  transfer_npc.py verify [--out F]      khẳng định trạng thái mong muốn, mã thoát 0/1
  transfer_npc.py set-city --index N --scene S [--x X --z Z] [--skip TEN]
                                        điền một dòng `g_Cities` trong bản Lua NGUỒN
                                        (dùng cho 汴京 index 1020 = cảnh 755 khi map-bianjing xong)

`apply` làm đúng bốn việc:
  1. Trả `Game_2/Scene/buyecheng.path` + `buyecheng_monster.ini` về **bản phát hành** (nếu đợt trước
     đã lỡ sửa); cảnh 490 do `scene_install.py disable --scenes 490` lo.
  2. Dựng bộ nội dung `Game_2/Scene/SnowWorld2024.*` cho cảnh 1007:
       - `.path`            <- `Assets/CanonicalCY/Data/SceneFolder/SnowWorld2024.path` nguyên byte;
       - `.scn`             <- khuôn `buyecheng.scn`, đổi tên file thành phần;
       - `_monster.ini`     <- một mục `[monster0]` là NPC dịch chuyển, mọi số chép từ dòng THẬT:
           * khuôn mục : `dali_new_320_monster.ini` `[monster0]` (驿站老板 崔逢九, script 990010);
           * tên+vị trí: `configs/TransportDefine.txt` dòng 939 `冰雪不夜城 1335 冰小舞 0 160 290`
                         (cột 5 = chỉ số `monsterN` của bản đồ gốc → NPC này vốn là `[monster0]`);
           * type      : `configs/MonsterAttrExTable.txt` dòng 52273 = 冰小舞 (base_ai 3, 阵营 8,
                         可交互 1 — cùng bộ với 193 驿站老板) ⇒ không sinh MONSTER_CFG_FAIL;
       - `_area.ini` / `_platform.ini` / `_patrolpoint.ini` / `_growpoint.txt` / `_growpointsetup.txt`
         <- chép y nguyên bản rỗng của `buyecheng_*`.
  3. `Game_2/Script/scripts/chuan_song_system.lua` <- `transfer_npc_lua/Game_2/…` (script 990010).
     Trước khi chép: `luac5.4 -p` + `transfer_npc_tests.lua` phải xanh.
     **Server chỉ nạp script khi khởi động lại** (`scriptenginer` cache theo id; `reload_scripts`
     không có chỗ gọi) ⇒ sau `apply` phải xin người điều phối một cửa sổ restart.
  4. Không đụng `SceneInfo.ini`. Bật/tắt cảnh đi qua `scene_install.py` (giữ `flock`).

Sao lưu: `R/backups/transfer-npc-<UTC>/` + `sha256.txt`. Hoàn tác = chép ngược từ thư mục đó.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
R = '/home/ubuntu/cys-test-20260913'
REPO = '/mnt/c/TLBB/085/CY-Source'
SCENE_DIR = os.path.join(R, 'Game_2', 'Scene')
CONFIGS = os.path.join(R, 'configs')

MAP = 'SnowWorld2024'          # tên bản đồ phía server = tên tài nguyên phía client
OLD_MAP = 'buyecheng'          # bộ nội dung đời GL của cảnh 490, trả về nguyên trạng
SCENE_ID = 1007                # ID cảnh server ĐÚNG (DBC client cột 0)
OLD_SCENE_ID = 490
CLIENTRES = 728                # dòng bảng SERVER configs/SceneDefineEx.txt

CY_NAV = os.path.join(REPO, 'Assets', 'CanonicalCY', 'Data', 'SceneFolder', MAP + '.path')
MON_SRC = os.path.join(SCENE_DIR, 'dali_new_320_monster.ini')
LUA_REL = os.path.join('Game_2', 'Script', 'scripts', 'chuan_song_system.lua')
LUA_SRC = os.path.join(HERE, 'transfer_npc_lua', LUA_REL)
LUA_DST = os.path.join(R, LUA_REL)
LUA_TESTS = os.path.join(HERE, 'transfer_npc_tests.lua')
ENC = 'gbk'

# sha256 của hai file `buyecheng.*` ĐÚNG NHƯ BẢN PHÁT HÀNH (đo 17/09 trước khi đụng vào;
# giống hệt bản ở /home/ubuntu/Game_2 và wsl/source-snapshot).
SHIPPED = {
    'buyecheng.path': '676a00528ef4afad6ac9f9252c72c9b36d2cdf8d1636b666e9737a06c284c40e',
    'buyecheng_monster.ini': 'd252eddc7df705cf28e513f397454e8615aa83cbdefa43e16cd4ce1f19a0bf60',
}

# Phần đuôi của bộ nội dung một bản đồ: (đuôi, chép-từ-buyecheng?)
CONTENT = [('.path', False), ('.scn', False), ('_monster.ini', False),
           ('_area.ini', True), ('_platform.ini', True), ('_patrolpoint.ini', True),
           ('_growpoint.txt', True), ('_growpointsetup.txt', True)]

# NPC dịch chuyển của 冰雪不夜城 — nguồn của từng giá trị xem docstring.
NPC = {
    'name': '冰小舞',      # 冰小舞
    'type': 52273,
    'pos_x': '160.0000',
    'pos_z': '290.0000',
    'script_id': 990010,
}

# ------------------------------------------------------------------ 汴京 Biện Kinh (cảnh 755)
# NPC dịch chuyển của 汴京. CY `TransportDefine.txt` có SÁU 传送NPC cho 汴京 (dòng 1034-1039):
#   金阅楼 idx3 (752,435) | 余繁 idx4 (688,752) | 梁民 idx5 (347,353) | 许行之 idx6 (360,724)
#   唐松  idx0 (530,937) | 杨中川 idx7 (542,554)
# Nhưng `configs/MonsterAttrExTable.txt` của server **chỉ có 唐松 = 49068**; năm cái kia không có
# dòng nào ⇒ dùng chúng sẽ ra MONSTER_CFG_FAIL. 唐松 cũng là cái đứng gần điểm-đứng của 汴京 nhất
# ((530,937) cách (512,942) 18,7 ô, đường thẳng sạch) nên chọn 唐松.
BJ_MAP = 'bianjing'
BJ_SCENE_ID = 755
BJ_NPC = {
    'name': '唐松',            # 唐松  (CY TransportDefine dòng 1038, chỉ số monster 0)
    'type': 49068,                     # MonsterAttrExTable 49068 = 唐松 (base_ai 3, 阵营 8, 可交互 1)
    'pos_x': '530.0000',
    'pos_z': '937.0000',
    'script_id': 990010,
}

# ------------------------------------------------------------------ SceneAttr: chỉ ô tên của 1007
# `configs/SceneAttr.txt` dòng 1007 đang mang tên của cảnh khác (`武当山洞天`) vì ID này trước đây
# thuộc bản đồ khác. Server đọc `scene_attr[sceneid].name` (`cfghelper.lua:736` → `script_base.lua:1546`)
# nên tên cảnh hiện sai trong game. Giá trị mới lấy từ HAI dòng server cùng nói về bản đồ này:
# `SceneAttr` dòng 1335 và `SceneDefineEx` dòng 728, cả hai đều ghi `冰雪不夜城`.
# CHỈ đổi ô tên. Ô `安全级别` giữ nguyên 0 vì dòng nguồn 1335 cũng là 0 — muốn thành vùng an toàn
# là quyết định thiết kế, không phải dữ liệu, nên không tự đổi.
SCENEATTR = os.path.join(CONFIGS, 'SceneAttr.txt')
SCENEATTR_FIX = {1007: {1: '冰雪不夜城'}}   # {dòng: {chỉ số cột: giá trị mới}}


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as fh:
        for blk in iter(lambda: fh.read(1 << 20), b''):
            h.update(blk)
    return h.hexdigest()


def read_gbk(p):
    return open(p, 'rb').read().decode(ENC, 'replace')


def block_of(path, section):
    raw = open(path, 'rb').read()
    i = raw.find(('[%s]' % section).encode('ascii'))
    if i < 0:
        raise SystemExit('khong tim thay [%s] trong %s' % (section, path))
    j = raw.find(b'\n[', i)
    return raw[i:(j + 1 if j > 0 else len(raw))]


def set_key_bytes(block, key, value):
    pat = re.compile(('^%s=.*$' % re.escape(key)).encode('ascii'), re.M)
    new = ('%s=%s' % (key, value)).encode(ENC)
    out, n = pat.subn(new, block)
    if n != 1:
        raise SystemExit('khoa %s xuat hien %d lan trong khuon mau' % (key, n))
    return out


def build_monster_ini(npc=None):
    """`<map>_monster.ini` mong muốn (bytes GBK, xuống dòng LF) — 1 NPC dịch chuyển."""
    npc = npc or NPC
    blk = block_of(MON_SRC, 'monster0')
    blk = set_key_bytes(blk, 'type', npc['type'])
    blk = set_key_bytes(blk, 'name', npc['name'])
    blk = set_key_bytes(blk, 'pos_x', npc['pos_x'])
    blk = set_key_bytes(blk, 'pos_z', npc['pos_z'])
    if b'script_id=%d' % npc['script_id'] not in blk:
        raise SystemExit('khuon mau khong phai NPC script %d' % npc['script_id'])
    if not blk.endswith(b'\n\n'):
        blk = blk.rstrip(b'\n') + b'\n\n'
    return b'[info]\nmonstercount=1\n\n' + blk


# ---------------------------------------------------------------- SceneAttr: sửa ĐÚNG một ô
def _split_lines(raw):
    """Giữ nguyên `\\r` nếu có: tách theo b'\\n', phần tử cuối có thể rỗng."""
    return raw.split(b'\n')


def sceneattr_plan():
    """[(dòng, cột, cũ, mới)] — chỉ những ô thực sự khác."""
    raw = open(SCENEATTR, 'rb').read()
    out = []
    for i, line in enumerate(_split_lines(raw)):
        if not line:
            continue
        cols = line.split(b'\t')
        if not cols[0].strip().isdigit():
            continue
        rid = int(cols[0].strip())
        if rid not in SCENEATTR_FIX:
            continue
        for ci, val in SCENEATTR_FIX[rid].items():
            new = val.encode(ENC)
            if ci < len(cols) and cols[ci] != new:
                out.append((rid, ci, cols[ci].decode(ENC, 'replace'), val))
    return out


def sceneattr_apply(bak_dir):
    """Ghi các ô trong SCENEATTR_FIX rồi CHỨNG MINH phần còn lại giống từng byte."""
    raw = open(SCENEATTR, 'rb').read()
    shutil.copy2(SCENEATTR, os.path.join(bak_dir, 'SceneAttr.txt'))
    lines = _split_lines(raw)
    touched = []
    for i, line in enumerate(lines):
        if not line:
            continue
        cols = line.split(b'\t')
        if not cols[0].strip().isdigit():
            continue
        rid = int(cols[0].strip())
        if rid not in SCENEATTR_FIX:
            continue
        for ci, val in SCENEATTR_FIX[rid].items():
            if ci >= len(cols):
                raise SystemExit('dong %d khong co cot %d' % (rid, ci))
            cols[ci] = val.encode(ENC)
        lines[i] = b'\t'.join(cols)
        touched.append(i)
    if len(touched) != len(SCENEATTR_FIX):
        raise SystemExit('tim thay %d dong can sua, mong doi %d' % (len(touched), len(SCENEATTR_FIX)))
    open(SCENEATTR, 'wb').write(b'\n'.join(lines))
    # chứng minh: mọi dòng khác giống hệt; dòng đã sửa chỉ khác đúng các cột đã nêu
    old = _split_lines(open(os.path.join(bak_dir, 'SceneAttr.txt'), 'rb').read())
    new = _split_lines(open(SCENEATTR, 'rb').read())
    if len(old) != len(new):
        raise SystemExit('so dong doi: %d -> %d' % (len(old), len(new)))
    khac = [i for i in range(len(old)) if old[i] != new[i]]
    if khac != touched:
        raise SystemExit('dong bi doi khong dung mong doi: %s vs %s' % (khac, touched))
    for i in touched:
        oc, nc = old[i].split(b'\t'), new[i].split(b'\t')
        if len(oc) != len(nc):
            raise SystemExit('so cot cua dong %d doi' % i)
        rid = int(oc[0].strip())
        for ci in range(len(oc)):
            if oc[ci] != nc[ci] and ci not in SCENEATTR_FIX[rid]:
                raise SystemExit('cot %d cua dong %d bi doi ngoai y muon' % (ci, rid))
    return {'so_dong': len(new), 'dong_doi': touched,
            'byte_truoc': len(raw), 'byte_sau': os.path.getsize(SCENEATTR)}


# ---------------------------------------- bật lại NPC cổng đang tắt trong `<map>_monster.ini`
# Quy ước tắt của cs3a2: đổi tên section `[monsterN]` -> `[monsterN_off]`; một số mục đời cũ còn
# chú thích luôn `pos_x=;<số>`. Bật lại = bỏ hậu tố `_off` và bỏ dấu `;`, KHÔNG đụng gì khác.
#
# 杨渐 "鬼谷接引使" (Đại Lý 154,139.5) là lối vào 鬼谷 duy nhất cho người chơi thật — `maps-cy4` vào
# được 2221 nhưng phải dời nhân vật bằng Mongo. Bật được vì đã kiểm đủ bốn điều:
#   1. type 56007 CÓ trong `configs/MonsterAttrExTable.txt` (杨渐, base_ai 3, 阵营 8, 可交互 1);
#   2. script 980003/980007 có trong `scripts.lua` (`scripts.obj.cy4.cy4_guigu_hub`);
#   3. `cy4_guigu_hub.cfg.destination_scene = 2221` — cảnh đang `active=1` VÀ có dòng trong DBC client;
#   4. đích (86,147) đi được trên `cy4_guigu.path` (vùng 1) và chỗ NPC đứng (154,139.5) đi được
#      trên `dali_new_320.path` (vùng 5).
#
# 唐昱 "唐门接引使" (monster212_off, script 980003) **CỐ Ý KHÔNG BẬT**: `cy4_tangmen_hub` trỏ
# `destination_scene = 2220`, mà 2220 đang `active=0`, **không có dòng trong DBC client**, và bản đồ
# của nó là `cy4_tangmen.scn` — KHÁC hẳn `tangmen.scn` của cảnh 495 — nên đổi 2220 thành 495 cũng sai
# (toạ độ (129,71) thuộc bản đồ khác). Người chơi đã có đường tới 唐家堡 qua 驿站 (mục menu 1022).
MONSTER_ON = [(os.path.join(SCENE_DIR, 'dali_new_320_monster.ini'), 'monster213')]


def monster_on_plan():
    out = []
    for path, sec in MONSTER_ON:
        if not os.path.isfile(path):
            continue
        raw = open(path, 'rb').read()
        if ('[%s]\n' % sec).encode('ascii') in raw:
            continue                      # đã bật rồi
        if ('[%s_off]' % sec).encode('ascii') in raw:
            out.append((path, sec))
    return out


def monster_on_apply(bak_dir):
    proofs = []
    for path, sec in monster_on_plan():
        raw = open(path, 'rb').read()     # đọc lại NGAY trước khi ghi
        shutil.copy2(path, os.path.join(bak_dir, os.path.basename(path) + '.pre-' + sec))
        lines = raw.split(b'\n')
        start = None
        for i, l in enumerate(lines):
            if l.strip() == ('[%s_off]' % sec).encode('ascii'):
                start = i
                break
        if start is None:
            raise SystemExit('khong tim thay [%s_off] trong %s' % (sec, path))
        end = len(lines)
        for i in range(start + 1, len(lines)):
            if re.match(rb'^\[[A-Za-z0-9_]+\]\s*$', lines[i].strip()):
                end = i
                break
        doi = [(start, lines[start], ('[%s]' % sec).encode('ascii'))]
        lines[start] = ('[%s]' % sec).encode('ascii')
        for i in range(start + 1, end):
            m = re.match(rb'^(pos_[xz])=;(.*)$', lines[i])
            if m:
                doi.append((i, lines[i], m.group(1) + b'=' + m.group(2)))
                lines[i] = m.group(1) + b'=' + m.group(2)
        open(path, 'wb').write(b'\n'.join(lines))
        # chứng minh: đúng những dòng đó đổi, không dòng nào khác
        old = raw.split(b'\n')
        new = open(path, 'rb').read().split(b'\n')
        if len(old) != len(new):
            raise SystemExit('so dong doi trong %s' % path)
        khac = [i for i in range(len(old)) if old[i] != new[i]]
        if khac != [d[0] for d in doi]:
            raise SystemExit('dong bi doi khong dung mong doi: %s' % khac)
        proofs.append({'file': os.path.basename(path), 'section': sec, 'so_dong': len(new),
                       'o_da_doi': ['dong %d: "%s" -> "%s"'
                                    % (i, o.decode(ENC, 'replace'), n.decode(ENC, 'replace'))
                                    for i, o, n in doi]})
    return proofs


# ------------------------------------------- bianjing.scn: THÊM đúng một dòng `monsterfile=`
# File này là của agent `map-bianjing`; hiện chỉ có `navmapname=`. `scenecore:load` chỉ gọi
# `init_monster` khi `.scn` khai `monsterfile=` (`scenecore.lua:142`) nên không có dòng này thì
# NPC dịch chuyển của 汴京 KHÔNG BAO GIỜ được tạo, và người chơi đi tới 汴京 sẽ mắc kẹt.
# Vì vậy chỉ THÊM một dòng, không sửa/không xoá dòng nào; đọc lại file ngay trước khi ghi.
BJ_SCN = os.path.join(SCENE_DIR, BJ_MAP + '.scn')
BJ_SCN_LINE = b'monsterfile=' + (BJ_MAP + '_monster.ini').encode('ascii')


def bianjing_scn_need():
    if not os.path.isfile(BJ_SCN):
        return False
    raw = open(BJ_SCN, 'rb').read()
    return BJ_SCN_LINE not in raw


def bianjing_scn_apply(bak_dir):
    raw = open(BJ_SCN, 'rb').read()          # đọc lại NGAY trước khi ghi
    if BJ_SCN_LINE in raw:
        return {'bo_qua': 'da co dong monsterfile='}
    shutil.copy2(BJ_SCN, os.path.join(bak_dir, BJ_MAP + '.scn'))
    eol = b'\r\n' if b'\r\n' in raw else b'\n'
    new = raw if raw.endswith(eol) else raw + eol
    new = new + BJ_SCN_LINE + eol
    open(BJ_SCN, 'wb').write(new)
    cur = open(BJ_SCN, 'rb').read()
    if not cur.startswith(raw.rstrip(eol)):
        raise SystemExit('bianjing.scn: phan cu khong con nguyen ven')
    return {'byte_truoc': len(raw), 'byte_sau': len(cur),
            'da_them': BJ_SCN_LINE.decode('ascii'),
            'noi_dung_sau': cur.decode('gbk', 'replace')}


def build_scn():
    """`SnowWorld2024.scn` = khuôn `buyecheng.scn`, đổi mọi `buyecheng` -> `SnowWorld2024`."""
    raw = open(os.path.join(SCENE_DIR, OLD_MAP + '.scn'), 'rb').read()
    return raw.replace(OLD_MAP.encode('ascii'), MAP.encode('ascii'))


def want_bytes(suffix, copy_from_old):
    if suffix == '.path':
        return open(CY_NAV, 'rb').read()
    if suffix == '.scn':
        return build_scn()
    if suffix == '_monster.ini':
        return build_monster_ini()
    if copy_from_old:
        return open(os.path.join(SCENE_DIR, OLD_MAP + suffix), 'rb').read()
    raise SystemExit('khong biet dung %s' % suffix)


def scene_keys(sid):
    txt = read_gbk(os.path.join(CONFIGS, 'SceneInfo.ini')).replace('\r\n', '\n')
    cur, keys = None, {}
    for line in txt.split('\n'):
        m = re.match(r'^\[scene(\d+)\]$', line.strip())
        if m:
            cur = int(m.group(1))
            continue
        if cur == sid and '=' in line:
            k, v = line.split('=', 1)
            keys[k.strip().lower()] = v.split(';')[0].strip()
    return keys


def lua_check():
    if not os.path.isfile(LUA_SRC):
        return False, 'thieu %s' % LUA_SRC
    p = subprocess.run(['luac5.4', '-p', LUA_SRC], capture_output=True, text=True)
    if p.returncode != 0:
        return False, 'luac -p FAIL: %s' % (p.stderr or p.stdout).strip()[:300]
    t = subprocess.run(['lua5.4', LUA_TESTS, LUA_SRC], capture_output=True, text=True)
    dong = [l for l in (t.stdout or '').strip().split('\n') if l.strip()]
    tom = dong[-1].strip() if dong else ''
    if t.returncode != 0:
        return False, 'transfer_npc_tests FAIL (%s): %s' % (
            tom, ' | '.join(l for l in dong if l.startswith('FAIL'))[:300])
    return True, 'luac -p OK; transfer_npc_tests %s' % tom


def state():
    st = {'noi_dung_%s' % MAP: {}, 'buyecheng': {},
          'scene%d' % SCENE_ID: scene_keys(SCENE_ID),
          'scene%d' % OLD_SCENE_ID: scene_keys(OLD_SCENE_ID)}
    for suf, _ in CONTENT:
        p = os.path.join(SCENE_DIR, MAP + suf)
        st['noi_dung_%s' % MAP][MAP + suf] = os.path.getsize(p) if os.path.isfile(p) else None
    for n, want in SHIPPED.items():
        p = os.path.join(SCENE_DIR, n)
        st['buyecheng'][n] = ('nhu ban phat hanh' if os.path.isfile(p) and sha256(p) == want
                              else ('DA BI SUA' if os.path.isfile(p) else 'THIEU'))
    for k, p in (('lua_src', LUA_SRC), ('lua_dst', LUA_DST)):
        st[k] = ({'byte': os.path.getsize(p), 'sha256': sha256(p)} if os.path.isfile(p)
                 else {'ton_tai': False})
    return st


def diff():
    """[(tên việc, cần làm?, mô tả)]"""
    out = []
    if not os.path.isfile(CY_NAV):
        return [('nav_nguon', True, 'THIEU nguon %s' % CY_NAV)]
    for n, want in SHIPPED.items():
        p = os.path.join(SCENE_DIR, n)
        can = not (os.path.isfile(p) and sha256(p) == want)
        out.append(('tra_lai_' + n, can,
                    'tra %s ve ban phat hanh' % n if can else '%s dung ban phat hanh' % n))
    for suf, cp in CONTENT:
        p = os.path.join(SCENE_DIR, MAP + suf)
        w = want_bytes(suf, cp)
        cur = open(p, 'rb').read() if os.path.isfile(p) else b''
        out.append(('noi_dung' + suf, cur != w,
                    'ghi %s (%d B)' % (MAP + suf, len(w)) if cur != w else '%s dung roi' % (MAP + suf)))
    bj = os.path.join(SCENE_DIR, BJ_MAP + '_monster.ini')
    bjw = build_monster_ini(BJ_NPC)
    bjc = open(bj, 'rb').read() if os.path.isfile(bj) else b''
    out.append(('bianjing_monster', bjc != bjw,
                'ghi %s_monster.ini (%d B, 1 NPC %s type %d tai %s,%s)'
                % (BJ_MAP, len(bjw), BJ_NPC['name'], BJ_NPC['type'], BJ_NPC['pos_x'], BJ_NPC['pos_z'])
                if bjc != bjw else '%s_monster.ini dung roi' % BJ_MAP))
    out.append(('bianjing_scn', bianjing_scn_need(),
                'THEM dong `%s` vao %s.scn (file cua map-bianjing; chi them, khong sua dong nao) — '
                'khong co dong nay thi scenecore khong goi init_monster va NPC 汴京 khong bao gio duoc tao'
                % (BJ_SCN_LINE.decode('ascii'), BJ_MAP)
                if bianjing_scn_need() else '%s.scn da khai monsterfile' % BJ_MAP))
    mon = monster_on_plan()
    out.append(('npc_cong', bool(mon),
                'bat lai NPC cong: %s' % '; '.join('%s [%s]' % (os.path.basename(p), sc) for p, sc in mon)
                if mon else 'NPC cong da bat'))
    sa = sceneattr_plan()
    out.append(('sceneattr', bool(sa),
                'sua %d o: %s' % (len(sa), '; '.join('dong %d cot %d "%s" -> "%s"' % r for r in sa))
                if sa else 'SceneAttr da dung'))
    dat, note = lua_check()
    same_lua = (os.path.isfile(LUA_DST) and sha256(LUA_SRC) == sha256(LUA_DST))
    out.append(('lua', not same_lua,
                ('chep chuan_song_system.lua (%s) -> server; CAN RESTART de nap' % note)
                if not same_lua else 'da trung byte; %s' % note))
    if not dat:
        out.append(('lua_kiem', True, 'KIEM LUA KHONG DAT: %s' % note))
    k = scene_keys(SCENE_ID)
    if not k:
        out.append(('scene_add', True,
                    'CHAY TAY: scene_install.py add --id %d --name 冰雪不夜城 --file %s.scn '
                    '--clientres %d --type 0 --threadindex 91 --active 1' % (SCENE_ID, MAP, CLIENTRES)))
    elif k.get('active') != '1':
        out.append(('scene_enable', True,
                    'CHAY TAY: scene_install.py enable --scenes %d' % SCENE_ID))
    ko = scene_keys(OLD_SCENE_ID)
    if ko.get('active') == '1':
        out.append(('scene_disable_490', True,
                    'CHAY TAY: scene_install.py disable --scenes %d '
                    '(DBC client khong co dong 490 -> client nem "Invalid scene ID")' % OLD_SCENE_ID))
    return out


def cmd_plan(args):
    _emit({'lenh': 'plan', 'trang_thai': state(),
           'viec': [{'ten': t, 'can_lam': n, 'mo_ta': d} for t, n, d in diff()]}, args)
    return 0


def cmd_apply(args):
    todo = diff()
    if any('THIEU nguon' in d for _, n, d in todo if n):
        sys.exit('thieu navmesh nguon, dung lai')
    dat, note = lua_check()
    if not dat:
        sys.exit('kiem Lua khong dat, KHONG chep: %s' % note)
    lam = [t for t, n, _ in todo if n and not t.startswith('scene_') and t != 'lua_kiem']
    bak = None
    if lam:
        bak = os.path.join(R, 'backups', 'transfer-npc-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()))
        os.makedirs(bak, exist_ok=True)
        lines = []
        paths = [os.path.join(SCENE_DIR, n) for n in SHIPPED]
        paths += [os.path.join(SCENE_DIR, MAP + s) for s, _ in CONTENT] + [LUA_DST]
        paths += [os.path.join(SCENE_DIR, BJ_MAP + '_monster.ini'), BJ_SCN, SCENEATTR]
        for p in paths:
            if os.path.isfile(p):
                shutil.copy2(p, os.path.join(bak, os.path.basename(p)))
                lines.append('%s  %s' % (sha256(p), os.path.basename(p)))
        open(os.path.join(bak, 'sha256.txt'), 'w').write('\n'.join(lines) + '\n')
    for t in lam:
        if t.startswith('tra_lai_'):
            n = t[len('tra_lai_'):]
            src = os.path.join(bak, n)
            if os.path.isfile(src) and sha256(src) == SHIPPED[n]:
                continue                      # bản trên đĩa đã đúng, không cần làm gì
            # tìm bản phát hành trong các backup cũ của chính công cụ này
            found = None
            for d in sorted(os.listdir(os.path.join(R, 'backups')), reverse=True):
                p = os.path.join(R, 'backups', d, n)
                if os.path.isfile(p) and sha256(p) == SHIPPED[n]:
                    found = p
                    break
            if not found:
                sys.exit('khong tim thay ban phat hanh cua %s trong backups; dung lai' % n)
            shutil.copyfile(found, os.path.join(SCENE_DIR, n))
        elif t.startswith('noi_dung'):
            suf = t[len('noi_dung'):]
            cp = dict(CONTENT)[suf]
            open(os.path.join(SCENE_DIR, MAP + suf), 'wb').write(want_bytes(suf, cp))
        elif t == 'lua':
            shutil.copyfile(LUA_SRC, LUA_DST)
        elif t == 'bianjing_monster':
            open(os.path.join(SCENE_DIR, BJ_MAP + '_monster.ini'), 'wb').write(build_monster_ini(BJ_NPC))
        elif t == 'sceneattr':
            truoc = sceneattr_plan()
            sa_proof = sceneattr_apply(bak)
            sa_proof['o_da_doi'] = ['dong %d cot %d "%s" -> "%s"' % r for r in truoc]
        elif t == 'bianjing_scn':
            bj_proof = bianjing_scn_apply(bak)
        elif t == 'npc_cong':
            npc_proof = monster_on_apply(bak)
    rec = {'lenh': 'apply', 'da_lam': lam, 'sao_luu': bak, 'kiem_lua': note,
           'trang_thai': state(), 'con_lai': [d for _, n, d in diff() if n]}
    if 'sceneattr' in lam:
        rec['sceneattr'] = sa_proof
    if 'bianjing_scn' in lam:
        rec['bianjing_scn'] = bj_proof
    if 'npc_cong' in lam:
        rec['npc_cong'] = npc_proof
        rec['CAN_RESTART'] = (rec.get('CAN_RESTART', '') +
                              ' NPC doc luc khoi dong canh -> 杨渐 chi xuat hien o restart ke.')
    if 'lua' in lam:
        rec['CAN_RESTART'] = ('scriptenginer cache script theo id; khong co cho nao goi reload_scripts '
                              '-> phai restart server thi chuan_song_system moi doi.')
    _emit(rec, args)
    return 0


def cmd_verify(args):
    loi = []
    for n, want in SHIPPED.items():
        p = os.path.join(SCENE_DIR, n)
        if not os.path.isfile(p) or sha256(p) != want:
            loi.append('%s khong con dung ban phat hanh' % n)
    for suf, cp in CONTENT:
        p = os.path.join(SCENE_DIR, MAP + suf)
        if not os.path.isfile(p) or open(p, 'rb').read() != want_bytes(suf, cp):
            loi.append('%s%s sai noi dung' % (MAP, suf))
    if monster_on_plan():
        loi.append('NPC cong chua bat: %s' % monster_on_plan())
    dat, note = lua_check()
    if not dat:
        loi.append('kiem Lua: %s' % note)
    if not os.path.isfile(LUA_DST) or sha256(LUA_DST) != sha256(LUA_SRC):
        loi.append('chuan_song_system.lua tren server khong trung ban nguon')
    k = scene_keys(SCENE_ID)
    if not k:
        loi.append('chua co [scene%d] trong SceneInfo.ini' % SCENE_ID)
    else:
        if k.get('active') != '1':
            loi.append('scene%d active=%s (can 1)' % (SCENE_ID, k.get('active')))
        if k.get('clientres') != str(CLIENTRES):
            loi.append('scene%d clientres=%s (can %d)' % (SCENE_ID, k.get('clientres'), CLIENTRES))
        if k.get('file') != MAP + '.scn':
            loi.append('scene%d file=%s (can %s.scn)' % (SCENE_ID, k.get('file'), MAP))
        if k.get('type') != '0':
            loi.append('scene%d type=%s (can 0)' % (SCENE_ID, k.get('type')))
    if scene_keys(OLD_SCENE_ID).get('active') == '1':
        loi.append('scene%d van active=1 (DBC client khong co dong nay)' % OLD_SCENE_ID)
    _emit({'lenh': 'verify', 'dat': not loi, 'loi': loi, 'kiem_lua': note, 'trang_thai': state()}, args)
    return 0 if not loi else 1


CITY_LINE = re.compile(
    r'(\{\s*index\s*=\s*(-?\d+),.*?scene\s*=\s*)(-?\d+)(\s*,\s*x\s*=\s*)(-?\d+)(\s*,\s*z\s*=\s*)(-?\d+)',
    re.S)


def cmd_set_city(args):
    """Điền cảnh/toạ độ cho một dòng `g_Cities` trong bản Lua NGUỒN (không chạm server)."""
    txt = open(LUA_SRC, encoding='utf-8', newline='').read()
    hit = [m for m in CITY_LINE.finditer(txt) if int(m.group(2)) == args.index]
    if len(hit) != 1:
        sys.exit('tim thay %d dong index=%d trong g_Cities' % (len(hit), args.index))
    m = hit[0]
    x = args.x if args.x is not None else int(m.group(5))
    z = args.z if args.z is not None else int(m.group(7))
    new = '%s%d%s%d%s%d' % (m.group(1), args.scene, m.group(4), x, m.group(6), z)
    txt2 = txt[:m.start()] + new + txt[m.end():]
    if args.skip:
        seg_end = txt2.find('},', txt2.find(new))
        seg = txt2[m.start():seg_end]
        if 'skip = {}' not in seg:
            sys.exit('dong %d da co skip, sua tay cho chac' % args.index)
        txt2 = txt2[:m.start()] + seg.replace('skip = {}', 'skip = { ["%s"] = true }' % args.skip) + txt2[seg_end:]
    open(LUA_SRC, 'w', encoding='utf-8', newline='').write(txt2)
    dat, note = lua_check()
    _emit({'lenh': 'set-city', 'index': args.index, 'scene': args.scene, 'x': x, 'z': z,
           'skip': args.skip, 'kiem_lua': note, 'dat': dat,
           'buoc_ke': 'transfer_npc.py apply  (roi xin restart)'}, args)
    return 0 if dat else 1


def _emit(rec, args):
    s = json.dumps(rec, ensure_ascii=False, indent=1)
    print(s)
    if getattr(args, 'out', None):
        open(args.out, 'w', encoding='utf-8').write(s + '\n')


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('plan', 'apply', 'verify'):
        p = sub.add_parser(name)
        p.add_argument('--out')
    p = sub.add_parser('set-city')
    p.add_argument('--index', type=int, required=True)
    p.add_argument('--scene', type=int, required=True)
    p.add_argument('--x', type=int)
    p.add_argument('--z', type=int)
    p.add_argument('--skip')
    p.add_argument('--out')
    args = ap.parse_args()
    return {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify,
            'set-city': cmd_set_city}[args.cmd](args)


if __name__ == '__main__':
    sys.exit(main())
