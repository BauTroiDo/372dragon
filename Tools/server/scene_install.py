# -*- coding: utf-8 -*-
"""Bật / thêm cảnh trên server riêng, an toàn khi NHIỀU AGENT chạy cùng lúc.

Vì sao có công cụ này: đợt thêm bản đồ 17/09 có 4 agent cùng sửa `configs/SceneInfo.ini` và
`configs/SceneDefineEx.txt`. Bài học 16/09 (hai agent cùng "nối vào cuối" một file làm mất một mục)
nói rõ: KHÔNG được để agent tự sửa tay. Mọi thay đổi đi qua đây, và đây dùng `flock` nên hai tiến
trình chạy song song vẫn an toàn.

Nguồn sự thật:
  - `configs/SceneInfo.ini`   — 789 section `[sceneN]`, N = ID cảnh phía SERVER (ID trong DB nhân vật).
  - **DBC client `Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt`** (682 dòng x 25 cột) —
    ĐÂY MỚI LÀ BẢNG QUYẾT ĐỊNH client vẽ bản đồ nào, và nó tra bằng **ID CẢNH SERVER ở CỘT 0**:
        CysModernHandlers.cpp:211  SetSceneID((INT)packet.sceneid, ...)   <- dùng sceneid
        WorldManager.cpp:96-110    Search_First_Column_Equ(SCENE_SERVER_ID_COLUMN, nSceneID)
        TDDBC_Struct.h:985         SCENE_SERVER_ID_COLUMN = 0
    Không có dòng khớp ⇒ client thử tiếp `client_res`, hết cả hai mới ném
    `TDThrow("(CWorldManager::EnterScene) Invalid scene ID")`.

  [CYS-CLIENTRES 20/09/2026] ĐÍNH CHÍNH — câu cũ ở đây viết *"`packet.client_res` chỉ được GHI LOG,
  client KHÔNG dùng"*. Câu đó ĐÚNG với 0.85 gốc và SAI từ khi có bản vá `CYS-SCENERES`:
        WorldManager.cpp:119-122   if(!pSceneDef && nResID > 0 && nResID != nSceneID)
                                       pSceneDef = Search_First_Column_Equ(..., nResID);
  Tức `clientres` LÀ đường tra dự phòng, và với **phó bản thì nó là đường DUY NHẤT** (xem mục
  `type=1` bên dưới: client nhận sceneid 10001..10020, không dòng DBC nào mang số đó). Mất 15 dòng
  `client_res` của bảng kê = mọi phó bản đứng, chính vì thế.

  - `configs/SceneDefineEx.txt` (547 dòng x 24 cột) — bảng phía SERVER, dòng dõi GL.
    **`clientres` được VIẾT theo trục ID của bảng này**, nhưng client lại tra nó trong DBC CY.
    HAI TRỤC KHÁC NHAU, đã đo: cùng ID mà khác `szRegionFile` **270** lần; chỉ **168** lần trùng
    (`Build/Logs/2026-09-20-clientres-sweep/30-truc-id-085-vs-CY.txt`). Ví dụ 1053/1054/1055/1056 =
    `cy4_tangmen/guigu/taohuadao/congren` ở bảng server, nhưng = `zijinkuafu_spring` + ba bản đồ
    FengYun ở DBC CY. Nên `clientres` "hợp lệ theo bảng server" KHÔNG chứng minh được gì về client.
    Phía server chỉ còn đúng MỘT chỗ tra bảng bằng giá trị này: `copyscenecore:get_name()` lấy
    `scene_define_ex[client_res].name` — chuỗi TÊN cho log của phó bản. `type=0` không dùng tới,
    nên đổi `clientres` của cảnh `type=0` sang trục DBC client là **không mất gì phía server**.
    Bằng chứng cũ vẫn đúng: cảnh 490 冰雪不夜城 có `clientres=728` "hợp lệ" ở bảng server, nhưng DBC
    client KHÔNG có dòng 490 nào ⇒ vào là ném "Invalid scene ID". ID đúng cho bản đồ đó là **1007**.
    Công cụ quét cả hai trục: `Tools/reapply/clientres/94-clientres-sweep.py` (SceneInfo.ini) và
    `95-lua-clientres-sweep.py` (hằng số `client_res` trong `Game_2/Script/**` — đường của phó bản).
  - `Game_2/Scene/<map>_monster.ini`, `<map>.path`, … — nội dung đặt quái/NPC/nav của từng bản đồ.

CỘT `client` CHỈ CÓ NGHĨA VỚI `type=0` — đo ngày 17/09 (maps-instance), đừng suy rộng:
  - `type=0`: `scenemanager_core:createScenes` (`R/GameServer/lualib/scenemanager_core.lua:177-204`)
    tạo dịch vụ lúc khởi động và `scenecore:load` đặt `self.id = conf.id`, nên `GCEnterScene.sceneid`
    ĐÚNG BẰNG ID `[sceneN]`. Cột `client` ở đây là tiêu chí đúng.
  - `type=1` (phó bản): KHÔNG có dịch vụ nào mang ID đó. Cảnh do `Copyscenemanager` cấp phát từ
    một hồ dựng sẵn, `copyscenemanager_core.lua:29` đăng ký `.SCENE_<index + define.COPY_SCENE_BEGIN>`
    (`COPY_SCENE_BEGIN = 10000`, `MAX_COPY_SCENE = 20`), và `scenecore:send_enter_scene` gửi
    `ret.sceneid = self.id` ⇒ client nhận **10001..10020**, không bao giờ nhận ID `[sceneN]`.
    Nên dòng DBC ở ID của một cảnh `type=1` KHÔNG quyết định được gì lúc chạy; nó chỉ là dữ liệu
    đúng-theo-cấu-trúc để dành. Đã đo: đặt nhân vật vào cảnh 130 thì server cho rơi về cảnh 2
    (`msgagent.lua:984-992` → `ensure_scene` trả false vì `scene_info_cache` chỉ có `type=0`).
  - `type=4` (thành bang hội): tạo động bởi `dynamicscenemanager_core:run_city_scene`, `self.id`
    VẪN bằng ID `[sceneN]`, nhưng cần một bản ghi `city` trong MongoDB; hiện chưa có bang hội nào
    nên chưa cảnh nào từng được tạo. Chi tiết: `Docs/specs/server/maps-instance_vi.md`.

  scene_install.py survey  [--out F]                      in bảng trạng thái, KHÔNG ghi gì
  scene_install.py enable  --scenes 9,10,11 [--out F]     đặt active=1 (bỏ qua cảnh đã bật)
  scene_install.py disable --scenes 9,10    [--out F]     đặt active=0
  scene_install.py set     --scene N --key clientres --value M
  scene_install.py add     --id N --name TEN --file X.scn --clientres M [--type 0] [--threadindex T]
  scene_install.py verify  --scenes 9,10,11               khẳng định đúng trạng thái mong muốn

Mọi lệnh ghi đều: giữ `flock`, sao lưu vào `backups/scene-install-<UTC>/`, giữ nguyên GBK + CRLF/LF
như file gốc, và chỉ chạm ĐÚNG section được nêu.
"""
import argparse
import json
import os
import re
import shutil
import sys
import time

CYS = '/mnt/c/TLBB/085/CY-Source'
DBC = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'SceneDefineEx.txt')
R = '/home/ubuntu/cys-test-20260913'
INI = os.path.join(R, 'configs', 'SceneInfo.ini')
SDE = os.path.join(R, 'configs', 'SceneDefineEx.txt')
SCENE_DIR = os.path.join(R, 'Game_2', 'Scene')
LOCK = os.path.join(R, 'configs', '.scene_install.lock')
ENC = 'gbk'


def read_ini():
    raw = open(INI, 'rb').read()
    return raw.decode(ENC, 'replace')


def parse_ini(txt):
    """{id: {'start': dòng bắt đầu, 'end': dòng kết thúc, 'keys': {...}}} theo THỨ TỰ file."""
    lines = txt.split('\n')
    out, cur, start = {}, None, None
    for i, line in enumerate(lines):
        m = re.match(r'^\[scene(\d+)\]\s*$', line.strip())
        if m:
            if cur is not None:
                out[cur]['end'] = i
            cur = int(m.group(1))
            out[cur] = {'start': i, 'end': len(lines), 'keys': {}}
            continue
        if cur is None:
            continue
        if '=' in line:
            k = line.split('=', 1)[0].strip().lower()
            v = line.split('=', 1)[1].split(';')[0].strip()
            out[cur]['keys'][k] = v
    return lines, out


def read_dbc():
    """DBC client: {ID cảnh server -> {'ten','w','h','file'}}. Đây là bảng client thật sự dùng."""
    try:
        sys.path.insert(0, os.path.join(CYS, 'Tools', 'game'))
        from dbc_inventory import Table
        t = Table(DBC)
    except Exception as e:                                   # noqa: BLE001
        print('CANH BAO: khong doc duoc DBC client (%s): %s' % (DBC, e), file=sys.stderr)
        return {}
    out = {}
    for r in t.rows:
        try:
            out[int(r[0])] = {'ten': str(r[1]), 'w': str(r[2]), 'h': str(r[3]), 'file': str(r[4]),
                              # [CYS-CLIENTRES 20/09] cot 5 `szRegionFile` = navmesh CLIENT se ve.
                              # Truoc day khong ai doc cot nay o day, nen `survey` khong co cach
                              # nao biet mot dong DBC dang tro toi mot tep KHONG TON TAI.
                              'region': str(r[5])}
        except (ValueError, IndexError):
            continue
    return out


def read_sde():
    s = open(SDE, 'rb').read().decode(ENC, 'replace')
    rows = {}
    for line in s.split('\n'):
        c = line.split('\t')
        if len(c) >= 5 and c[0].strip().isdigit():
            rows[int(c[0].strip())] = {'ten': c[1], 'w': c[2], 'h': c[3], 'file': c[4]}
    return rows


def map_name_of(scn):
    """`shaolin.scn` -> `shaolin` (tên gốc dùng cho các file nội dung trong Game_2/Scene)."""
    return os.path.splitext(os.path.basename(scn or ''))[0]


def same_map(server_scn, dbc_file):
    """Hai bên có phải CÙNG một bản đồ không.

    Server đôi khi giữ bản sao riêng với tiền tố `cy4_` (vd `cy4_guigu.scn` trong khi nghệ thuật
    client là `guigu.Scene`). Client KHÔNG đọc tên `.scn` của server, nên chênh tiền tố này là
    BÌNH THƯỜNG, không phải sai bản đồ. Bỏ tiền tố rồi mới so.
    """
    def norm(x):
        n = map_name_of(x).lower()
        return n[4:] if n.startswith('cy4_') else n
    return norm(server_scn) == norm(dbc_file)


CLI_SCENE_DIR = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'SceneFolder')
_cli_scene_index = None


def tep_client_co(region):
    """`szRegionFile` cua dong DBC co that su nam trong SceneFolder cua CLIENT khong.
    KHAC voi `content_of`: ham do do `Game_2/Scene` phia SERVER."""
    global _cli_scene_index
    if not region:
        return None
    if _cli_scene_index is None:
        try:
            _cli_scene_index = {n.lower() for n in os.listdir(CLI_SCENE_DIR)}
        except OSError:
            _cli_scene_index = set()
    return region.lower() in _cli_scene_index


def content_of(mapname):
    """Nội dung đặt sẵn của một bản đồ: navmesh và số quái."""
    p = os.path.join(SCENE_DIR, mapname + '.path')
    mi = os.path.join(SCENE_DIR, mapname + '_monster.ini')
    nav = os.path.getsize(p) if os.path.isfile(p) else 0
    quai = None
    if os.path.isfile(mi):
        for line in open(mi, 'rb').read().decode(ENC, 'replace').split('\n'):
            if line.strip().lower().startswith('monstercount'):
                try:
                    quai = int(line.split('=', 1)[1].split(';')[0].strip())
                except ValueError:
                    quai = -1
                break
    return {'nav_byte': nav, 'so_quai': quai}


def backup(nhan):
    d = os.path.join(R, 'backups', 'scene-install-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()) + '-' + nhan)
    os.makedirs(d, exist_ok=True)
    for f in (INI, SDE):
        if os.path.isfile(f):
            shutil.copy2(f, os.path.join(d, os.path.basename(f)))
    return d


class Lock(object):
    """flock quanh đọc-sửa-ghi, để hai agent chạy song song không đè nhau."""

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


def write_ini(lines):
    open(INI, 'wb').write('\n'.join(lines).encode(ENC, 'replace'))


def set_key(lines, sec, key, value):
    """Sửa `key=` trong ĐÚNG section; giữ nguyên chú thích phía sau dấu `;`.

    BẪY ĐÃ SẬP THẬT (agent transfer-npc, 17/09): khoá trong file viết hoa-thường lẫn lộn
    (`PvpRuler`, `threadindex`, `clientres`). Bản đầu so `line_key.lower() != key` mà KHÔNG hạ
    `key` của người gọi, nên `--key PvpRuler` không khớp dòng nào và rơi xuống nhánh `insert`
    => section có HAI dòng `PvpRuler`, mà lệnh vẫn báo `"cu": null, "moi": null` như thành công.
    Nay hạ cả hai phía; `cmd_set` cũng đọc lại bằng khoá đã hạ.
    """
    key = key.lower()
    for i in range(sec['start'] + 1, sec['end']):
        line = lines[i]
        if '=' not in line:
            continue
        if line.split('=', 1)[0].strip().lower() != key:
            continue
        rest = line.split('=', 1)[1]
        cmt = ('\t;' + rest.split(';', 1)[1]) if ';' in rest else ''
        lines[i] = '%s=%s%s' % (line.split('=', 1)[0], value, cmt)
        return True
    lines.insert(sec['start'] + 1, '%s=%s' % (key, value))
    return True


def cmd_survey(args):
    txt = read_ini()
    _, sec = parse_ini(txt)
    dbc = read_dbc()
    out = []
    for sid in sorted(sec):
        k = sec[sid]['keys']
        scn = k.get('file', '')
        mp = map_name_of(scn)
        d = dbc.get(sid)
        # CỘT QUYẾT ĐỊNH: client tra DBC bằng ID CẢNH SERVER (cột 0). Không có dòng -> "Invalid scene ID".
        if not d:
            client = 'THIEU'
        elif same_map(scn, d['file']):
            client = 'OK'
        else:
            client = 'SAI:' + map_name_of(d['file'])[:12]
        row = {'scene': sid, 'ten': k.get('name'), 'active': k.get('active'), 'type': k.get('type'),
               'file': scn, 'map': mp, 'clientres': k.get('clientres'),
               'dbc_ten': (d or {}).get('ten'), 'dbc_file': (d or {}).get('file'), 'client': client}
        row.update(content_of(mp))
        # [CYS-CLIENTRES 20/09] CAU HOI THU HAI, truoc day khong ai hoi. Cot `client` o tren chi
        # hoi "co dong DBC o ID nay khong" - va voi 4 canh FengYun dang HONG no van tra loi OK.
        # Cot `nav_byte` cung khong cuu duoc: no do tep phia SERVER (`Game_2/Scene`), con van de
        # nam o phia CLIENT. Hai o duoi la THEM MOI, khong doi hanh vi cot nao dang co.
        row['client_region'] = (d or {}).get('region')
        row['client_tep_ton_tai'] = tep_client_co(row['client_region'])
        out.append(row)
    if args.scenes:
        want = {int(x) for x in args.scenes.split(',') if x.strip()}
        out = [r for r in out if r['scene'] in want]
    elif not args.all:
        out = [r for r in out if r['active'] == '1' or r['so_quai']]
    print('%-6s %-14s %-3s %-4s %-18s %-22s %-16s %-9s %s'
          % ('scene', 'ten', 'act', 'type', 'file', 'DBC client (cot 0 = scene)', 'client ve duoc?',
             'nav', 'quai'))
    for r in out:
        print('%-6d %-14s %-3s %-4s %-18s %-22s %-16s %-9s %s'
              % (r['scene'], (r['ten'] or '')[:14], r['active'], r['type'], (r['file'] or '')[:18],
                 (r['dbc_file'] or '(khong co dong)')[:22], r['client'],
                 r['nav_byte'] or '-', r['so_quai'] if r['so_quai'] is not None else '-'))
    # [CYS-CLIENTRES 20/09] Dong tong ket THEM MOI o cuoi - khong dong nao o tren bi doi.
    hong = [r for r in out if r['active'] == '1' and r['type'] == '0'
            and r['client'] == 'OK' and r['client_tep_ton_tai'] is False]
    if hong:
        print()
        print('*** %d canh type=0 dang bat co cot `client`=OK NHUNG tep navmesh CLIENT KHONG TON'
              ' TAI: %s' % (len(hong), ', '.join('%s(%s)' % (r['scene'], r['client_region'])
                                                 for r in hong[:8])))
        print('    Cot `client` khong bat duoc lop nay (no chi hoi "co dong DBC khong").')
        print('    Cong day du + doi chung: Tools/reapply/clientres/97-dbc-file-gate.py')
    if args.out:
        json.dump(out, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    return 0


def _flip(args, value):
    want = [int(x) for x in args.scenes.split(',') if x.strip()]
    with Lock():
        txt = read_ini()
        lines, sec = parse_ini(txt)
        thieu = [s for s in want if s not in sec]
        if thieu:
            sys.exit('khong co section cho scene %s; dung lenh `add` truoc' % thieu)
        doi = [s for s in want if sec[s]['keys'].get('active') != value]
        if doi:
            bak = backup('active')
            for s in doi:
                set_key(lines, sec[s], 'active', value)
            write_ini(lines)
        else:
            bak = None
        _, sec2 = parse_ini(read_ini())
        rec = {'lenh': 'enable' if value == '1' else 'disable', 'yeu_cau': want, 'da_doi': doi,
               'bo_qua_vi_da_dung': [s for s in want if s not in doi], 'sao_luu': bak,
               'kiem_lai': {s: sec2[s]['keys'].get('active') for s in want}}
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    if args.out:
        json.dump(rec, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    return 0 if all(v == value for v in rec['kiem_lai'].values()) else 1


def cmd_set(args):
    with Lock():
        txt = read_ini()
        lines, sec = parse_ini(txt)
        if args.scene not in sec:
            sys.exit('khong co section scene%d' % args.scene)
        cu = sec[args.scene]['keys'].get(args.key.lower())
        if cu == args.value:
            rec = {'lenh': 'set', 'scene': args.scene, 'khoa': args.key.lower(), 'da_dung_san': cu}
        else:
            bak = backup('set')
            set_key(lines, sec[args.scene], args.key, args.value)
            write_ini(lines)
            _, sec2 = parse_ini(read_ini())
            rec = {'lenh': 'set', 'scene': args.scene, 'khoa': args.key, 'cu': cu,
                   'moi': sec2[args.scene]['keys'].get(args.key.lower()), 'sao_luu': bak}
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    return 0


def cmd_add(args):
    with Lock():
        txt = read_ini()
        lines, sec = parse_ini(txt)
        if args.id in sec:
            sys.exit('scene%d DA CO; dung `set`/`enable` thay vi `add` (khong ghi de mot muc san co)'
                     % args.id)
        sde = read_sde()
        if args.clientres not in sde:
            sys.exit('clientres %d khong co trong configs/SceneDefineEx.txt cua SERVER; tu choi'
                     % args.clientres)
        bak = backup('add')
        block = ['[scene%d]' % args.id,
                 'threadindex=%d' % args.threadindex,
                 'clientres=%d' % args.clientres,
                 'name=%s' % args.name,
                 'active=%d' % args.active,
                 'file=%s' % args.file,
                 'serverid=0',
                 'type=%d' % args.type,
                 'PvpRuler=0',
                 '']
        lines = lines + block
        write_ini(lines)
        _, sec2 = parse_ini(read_ini())
        rec = {'lenh': 'add', 'scene': args.id, 'sao_luu': bak,
               'kiem_lai': sec2.get(args.id, {}).get('keys'),
               'clientres_tro_toi': sde[args.clientres]}
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    return 0 if args.id in sec2 else 1


def cmd_verify(args):
    txt = read_ini()
    _, sec = parse_ini(txt)
    dbc = read_dbc()
    want = [int(x) for x in args.scenes.split(',') if x.strip()]
    loi = []
    for s in want:
        if s not in sec:
            loi.append({'scene': s, 'loi': 'khong co section'}); continue
        k = sec[s]['keys']
        mp = map_name_of(k.get('file', ''))
        if k.get('active') != '1':
            loi.append({'scene': s, 'loi': 'active=%s' % k.get('active')})
        # Tiêu chí THẬT: client tra DBC bằng ID CẢNH SERVER (cột 0), không phải clientres.
        d = dbc.get(s)
        if not d:
            loi.append({'scene': s, 'loi': 'DBC client KHONG co dong nao cho scene %d'
                                           ' -> client nem "Invalid scene ID"' % s})
        elif not same_map(k.get('file', ''), d['file']):
            loi.append({'scene': s, 'loi': 'SAI BAN DO: server file=%s nhung DBC client dong %d la %s'
                                           % (k.get('file'), s, d['file'])})
        c = content_of(mp)
        if not c['nav_byte']:
            loi.append({'scene': s, 'loi': 'thieu navmesh %s.path' % mp})
    rec = {'lenh': 'verify', 'so_canh': len(want), 'ok': not loi, 'loi': loi}
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    if args.out:
        json.dump(rec, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    return 0 if not loi else 1


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd')
    a = sub.add_parser('survey'); a.add_argument('--out', default=''); a.add_argument('--scenes', default='')
    a.add_argument('--all', action='store_true')
    for n in ('enable', 'disable'):
        a = sub.add_parser(n); a.add_argument('--scenes', required=True); a.add_argument('--out', default='')
    a = sub.add_parser('set'); a.add_argument('--scene', type=int, required=True)
    a.add_argument('--key', required=True); a.add_argument('--value', required=True)
    a = sub.add_parser('add'); a.add_argument('--id', type=int, required=True)
    a.add_argument('--name', required=True); a.add_argument('--file', required=True)
    a.add_argument('--clientres', type=int, required=True); a.add_argument('--type', type=int, default=0)
    a.add_argument('--active', type=int, default=0); a.add_argument('--threadindex', type=int, default=30)
    a = sub.add_parser('verify'); a.add_argument('--scenes', required=True); a.add_argument('--out', default='')
    args = ap.parse_args()
    if args.cmd == 'survey':
        return cmd_survey(args)
    if args.cmd == 'enable':
        return _flip(args, '1')
    if args.cmd == 'disable':
        return _flip(args, '0')
    if args.cmd == 'set':
        return cmd_set(args)
    if args.cmd == 'add':
        return cmd_add(args)
    if args.cmd == 'verify':
        return cmd_verify(args)
    ap.print_help()
    return 2


if __name__ == '__main__':
    sys.exit(main())
