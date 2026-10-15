#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ride-data — dong bo DU LIEU THU CUOI (坐骑) tu CY sang server rieng (17/09/2026).

    python3 -B Tools/server/ride_data.py survey [--out F]           chi doc, in bang do
    python3 -B Tools/server/ride_data.py plan   [--out DIR]         dung staging, KHONG cham R
    python3 -B Tools/server/ride_data.py apply  [--staging DIR]     flock + sao luu + ghi vao R
    python3 -B Tools/server/ride_data.py verify [--staging DIR]     doc lai TU DIA roi khang dinh

Chay trong WSL TLBB bang root: `wsl -d TLBB -u root -- python3 -B /mnt/c/.../ride_data.py <lenh>`.

===============================================================================
BON SU THAT PHAI BIET TRUOC KHI DOC MA (do 17/09, bang chung o Docs/specs/server/ride-data_vi.md)
===============================================================================

1. **`configs/CharMount.txt` cua server la file CHET.** `grep -rni charmount` toan bo
   `cys-test-20260913/{GameServer,Game_2,configs}` khong ra MOT dong ma nao; `configenginer.lua`
   khong co muc `char_mount`. Bang nay chi CLIENT doc (`GMDataBase.cpp:153`, 24 cot
   `ISIIFIIISIISSSSSIIIIIIFI`) va client doc ban CY o `Assets/CanonicalCY`, khong doc ban server.
   Noi dung file tren server **la ban cua `client_GL`**: 201 dong x **15 cot**, khop tung byte
   (da doi chieu dong 0, 94, 203, 211, 215); cot **14** cua no = **do cao bay**, tuong ung cot 22
   cua ban CY. => Chenh 353 vs 201 dong la **viec thuan client, da du san o ban CY**. Cong cu nay
   KHONG noi bang server len 24 cot: nong mot bang chet chi tao rui ro. Chi sua ma hoa (xem 4).
   **CANH BAO TRUC ID:** `CharMount` cua GL/server va cua CY la HAI KHONG GIAN ID KHAC NHAU —
   so theo MESH thi chi 76/201 dong vua cung ID vua cung con vat; 72 dong co ban tuong duong ben CY
   nhung o ID KHAC; 53 dong CY khong co. Dung bao gio doi chieu hai bang nay theo so hieu.
   Bang anh xa theo mesh: `Build/Logs/2026-09-17-ride-data/do-dac/mesh_match.json`.

2. **Bang QUYET DINH la `Exterior_Ride.txt`.** `cfghelper:read_exterior_ride` doc theo TEN cot:
   `index 门派 名字 图标 描述 模型索引 速度索引 速度10/20/40/70/75/80/85/90`. Duong lay thu cuoi:
       item `EquipBase` Type 41 (script 999801) -> `LuaFnGetEquipVisual` -> cot `Visual`
       -> `LuaFnGetExteriorRideIDByVisual(visual)` quet `exterior_ride` tim `模型索引 == visual`
       -> ride id -> `LuaFnAddRideRxpirationTime` + `ChangePlayerRide`.
   Nghia la **`Visual` cua item = `模型索引` cua ride = chi so `CharMount`** — mot truc duy nhat.

3. **Model khi cuoi den tu `StandardImpact`, khong tu `模型索引`.** `skill_14.lua` lay
   `exterior_ride[ride].impacts[max_speed_up]` roi `register_impact`; `std_impact_014` doc tham so
   `骑乘ID(-1为无效)` de dat thuoc tinh `ride_model`, va `ride_model` la thuoc tinh kieu "refix"
   (`lualib/db/human_attrib.lua` 170/240/350) — KHONG co nguon nao khac.
   **Hong dang ton tai:** commit `ed09b4f` (CS3c) thay ca bang `StandardImpact` sang truc ID CY
   nhung KHONG doi `Exterior_Ride`, nen 1.099/1.433 ID impact ma bang ride tro toi **khong con
   dong nao**. Do live: 1.584 o impact khac -1, chi 357 o (22,5 %) con dong; **6/28.006 dong dat
   `骑乘ID`**; 0/198 ride co `骑乘ID` khop `模型索引`. Tuc la HOM NAY khong thu cuoi nao doi model
   hay cong toc do. Buoc `repair` cua cong cu nay chep lai 1.097 dong do tu server GOC
   `/home/ubuntu/configs/StandardImpact.txt` (cung 81 cot, cung tieu de) — nguon THAT, khong bia.

4. **`configs/*.txt` PHAI la GBK.** `txtreader.readline` goi `gbk.toutf8` len CA DONG vo dieu kien.
   Do live tim ra hai dong da vi pham tu 06/09: `Exterior_Ride` dong 182 (ride 180 越南黑水牛) va
   `CharMount` dong 185 (220) chua tieng Viet UTF-8; `CharMount.txt` con tron 183 dong LF voi 20
   dong CRLF. Cong cu nay chuyen hai o do ve ASCII va tra CharMount ve CRLF thuan.

LUAT DA TUAN THU
  * lam o muc BYTE, khong decode/encode ca dong; chuoi CY lay thang tu string pool cua DBC (GBK);
  * chi THEM dong, khong xoa dong nao — 35 chi so CharMount chi co o server (101–134, 227) la di san
    085/GL (co y nguyen trong `C:\TLBB\085\client` va `client_GL`), cong cu KHONG dung toi;
  * dong impact moi la BAN SAO cua mot dong THAT cung bac toc do, chi doi `Data_Index`, `效果名称`,
    `骑乘ID(-1为无效)`, `移动速度修正%（0为无效）` va SE khi SE do khong co o client CY (dat -1);
  * `StandardImpact` giu ID TANG DAN (tron theo thu tu, khong noi duoi);
  * `flock` dung chung `configs/.scene_install.lock` voi `scene_install.py`/`map_bianjing.py`;
  * sao luu vao `R/backups/ride-data-<UTC>/` truoc moi lan ghi; `plan` khong cham R;
  * idempotent: chay `plan` lan hai tren R da apply se ra ke hoach rong.
"""
import argparse
import collections
import datetime
import json
import os
import shutil
import struct
import sys

R = '/home/ubuntu/cys-test-20260913'
OLD = '/home/ubuntu/configs'                       # server GOC, CHI DOC — nguon dong impact that
CY = '/mnt/c/TLBB/085/CY-Source/Assets/CanonicalCY/Data/ConfigFolder'
LOCK_NAME = '.scene_install.lock'
TAB, CRLF = b'\t', b'\r\n'

SPEED_COLS = ('速度10', '速度20', '速度40', '速度70', '速度75', '速度80', '速度85', '速度90')
TIERS = (10, 20, 40, 70, 75, 80, 85, 90)
P_RIDE = '骑乘ID(-1为无效)'
P_SPEED = '移动速度修正%（0为无效）'
SI_COLS = 81
ER_COLS = 26
NEW_IMPACT_BASE = 64100        # dai trong: R max = 64033
NEW_RIDE_BASE = 300            # khi ID cua CY da bi chiem tren server

# vi tri cot trong Exterior_Ride cua server (kiem lai bang ten luc chay)
ER_MODEL, ER_SPEED, ER_NAME, ER_ICON, ER_DESC, ER_MENPAI = 10, 11, 7, 8, 9, 6


# --------------------------------------------------------------------------- doc bang
def read_table(path):
    """Bang van ban server: (2 dong tieu de dang byte, cac dong du lieu dang byte, ten cot).

    Chiu duoc EOL tron LF/CRLF (CharMount.txt dang tron) va KHONG decode o du lieu."""
    raw = open(path, 'rb').read()
    parts = [p.rstrip(b'\r') for p in raw.split(b'\n')]
    while parts and not parts[-1].strip():
        parts.pop()
    head = parts[:2]
    rows = [p for p in parts[2:] if p.strip() and not p.startswith(b'#')]
    names = [c.decode('gbk', 'replace') for c in head[1].split(TAB)]
    return head, rows, names


def rid_of(line):
    try:
        return int(line.split(TAB, 1)[0])
    except ValueError:
        return None


def cell(line, k):
    c = line.split(TAB)
    return c[k] if k < len(c) else b''


def num(b, d=None):
    try:
        return int(b)
    except (ValueError, TypeError):
        return d


def gbk(b):
    return b.decode('gbk', 'replace') if isinstance(b, bytes) else str(b)


class Dbc(object):
    """DBC nhi phan 00CCBBDD cua client CY, GIU NGUYEN BYTE o o STRING.

    Khong dung Tools/game/dbc_inventory.Table o day vi decode() cua no thu UTF-8 TRUOC roi moi GBK,
    nen mot so ten GBK that lot qua cua UTF-8 va ra chu Kirin (CharMount 233 ten that la GBK
    D1A9 D1B1 C2B9 = 雪驯鹿 nhung decode() tra ve "ѩѱ¹"). Bang thu cuoi toan tieng Trung."""

    NAMES = ('INT', 'FLOAT', 'STRING', 'UINT', 'DWORDTIME')

    def __init__(self, path):
        raw = open(path, 'rb').read()
        if raw[:4] != b'\x00\xcc\xbb\xdd':
            raise ValueError('khong phai DBC nhi phan: %s' % path)
        _, fields, records, strings = struct.unpack_from('<Iiii', raw, 0)
        kinds = struct.unpack_from('<%dI' % fields, raw, 16)
        self.types = [self.NAMES[k] if k < len(self.NAMES) else 'T%d' % k for k in kinds]
        base = 16 + 4 * fields
        cells = struct.unpack_from('<%dI' % (fields * records), raw, base)
        pool = raw[base + 4 * fields * records: base + 4 * fields * records + strings]
        self.rows = []
        for r in range(records):
            row = []
            for c in range(fields):
                v = cells[r * fields + c]
                t = self.types[c]
                if t == 'FLOAT':
                    row.append(round(struct.unpack('<f', struct.pack('<I', v))[0], 6))
                elif t == 'STRING':
                    end = pool.find(b'\0', v) if v < len(pool) else -1
                    row.append(pool[v:end] if end >= 0 else b'')
                elif t == 'INT':
                    row.append(struct.unpack('<i', struct.pack('<I', v))[0])
                else:
                    row.append(v)
            self.rows.append(row)


# --------------------------------------------------------------------------- StandardImpact
def si_param_slots(names):
    """Cac cap (cot nhan, cot gia tri) cua khoi '参数N说明 / 参数值 / 修正步长'."""
    out, k = [], 27
    while k + 1 < len(names):
        if names[k].startswith('参数') and names[k].endswith('说明'):
            out.append((k, k + 1))
            k += 3
        else:
            k += 1
    return out


def si_params(line, slots):
    cells = line.split(TAB)
    out = {}
    for lc, vc in slots:
        if lc < len(cells) and vc < len(cells) and cells[lc].strip():
            out[gbk(cells[lc]).strip().strip('"')] = num(cells[vc])
    return out


def si_fit(cells):
    """Ep dong ve dung SI_COLS o.

    Bang cua server GOC khong sach: co dong 93/144/79/1 o (khoi tham so thua dinh o duoi, tieu de
    chi ten 81 cot). `cfghelper` chi doc theo TEN cot nen o thu 81 tro di khong bao gio duoc doc —
    cat bo la khong mat gi ma giu duoc bat bien '81 cot' cua bang tren R."""
    if len(cells) > SI_COLS:
        return cells[:SI_COLS]
    return cells + [b''] * (SI_COLS - len(cells))


def si_set_param(cells, slots, label, value):
    """Dat gia tri cho nhan da co; neu chua co thi dung o tham so con TRONG dau tien."""
    for lc, vc in slots:
        if lc < len(cells) and cells[lc].strip().strip(b'"').decode('gbk', 'replace') == label:
            cells[vc] = str(value).encode('ascii')
            return True
    for lc, vc in slots:
        if lc < len(cells) and not cells[lc].strip():
            cells[lc] = label.encode('gbk')
            cells[vc] = str(value).encode('ascii')
            return True
    return False


# --------------------------------------------------------------------------- do dem
def survey(root):
    cfg = os.path.join(root, 'configs')
    out = {}

    _, er_rows, er_names = read_table(os.path.join(cfg, 'Exterior_Ride.txt'))
    C = {n: k for k, n in enumerate(er_names)}
    _, si_rows, si_names = read_table(os.path.join(cfg, 'StandardImpact.txt'))
    slots = si_param_slots(si_names)
    si_by = {}
    for line in si_rows:
        k = rid_of(line)
        if k is not None:
            si_by[k] = line

    cy_er = Dbc(os.path.join(CY, 'Exterior_Ride.txt'))
    cy_cm = Dbc(os.path.join(CY, 'CharMount.txt'))
    _, cm_rows, _ = read_table(os.path.join(cfg, 'CharMount.txt'))
    _, eb_rows, eb_names = read_table(os.path.join(cfg, 'EquipBase.txt'))
    E = {n: k for k, n in enumerate(eb_names)}

    sv_model = {}
    cells_ok = 0
    cells_total = 0
    ride_model_ok = 0
    for line in er_rows:
        rid = rid_of(line)
        model = num(cell(line, C['模型索引']))
        sv_model.setdefault(model, []).append(rid)
        got = set()
        for s in SPEED_COLS:
            x = num(cell(line, C[s]))
            if x is None or x < 0:
                continue
            cells_total += 1
            row = si_by.get(x)
            if row is None:
                continue
            cells_ok += 1
            v = si_params(row, slots).get(P_RIDE)
            if v is not None and v >= 0:
                got.add(v)
        if got == {model}:
            ride_model_ok += 1

    cy_models = set(r[ER_MODEL] for r in cy_er.rows)
    t41 = [line for line in eb_rows if num(cell(line, E['Type(类别)'])) == 41]
    vis = collections.Counter(num(cell(line, E['Visual'])) for line in t41)
    item_usable = [line for line in t41 if num(cell(line, E['Visual'])) in sv_model]

    out['exterior_ride'] = {'server': len(er_rows), 'cy': len(cy_er.rows),
                            'server_models': len(sv_model), 'cy_models': len(cy_models),
                            'cy_models_missing': sorted(cy_models - set(sv_model))}
    out['impact'] = {'cells': cells_total, 'cells_alive': cells_ok,
                     'rides_model_ok': ride_model_ok, 'rides': len(er_rows),
                     'rows': len(si_rows)}
    out['charmount'] = {'server_rows': len(cm_rows), 'cy_rows': len(cy_cm.rows),
                        'note': 'bang CHET tren server: khong ma nao doc'}
    out['item41'] = {'items': len(t41), 'visuals': len(vis),
                     'usable': len(item_usable),
                     'orphan_visuals': sorted(v for v in vis if v not in sv_model)}
    return out


# --------------------------------------------------------------------------- ke hoach
def build_plan(root):
    cfg = os.path.join(root, 'configs')
    plan = {'utc': datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ'),
            'repair_impacts': [], 'new_rides': [], 'new_impacts': [],
            'repoint_rides': [], 'encoding_fixes': [], 'notes': []}

    er_head, er_rows, er_names = read_table(os.path.join(cfg, 'Exterior_Ride.txt'))
    C = {n: k for k, n in enumerate(er_names)}
    for s in SPEED_COLS + ('模型索引', '速度索引', '名字', '图标', '描述', '门派', 'index'):
        if s not in C:
            raise SystemExit('Exterior_Ride thieu cot %r — bo cot da doi, dung lai' % s)
    if '速度125' in C:
        # ride-finish 18/09: bang da o TRUC CY (27 cot, co 速度125). plan/apply cua cong cu nay la lich su
        # (no cap ride id theo truc GL va duc impact 8 bac) — dung Tools/reapply/ride/ride_axis.py.
        raise SystemExit('Exterior_Ride da o truc CY (co cot 速度125): dung Tools/reapply/ride/ride_axis.py; '
                         'ride_data.py chi con survey/verify')

    si_head, si_rows, si_names = read_table(os.path.join(cfg, 'StandardImpact.txt'))
    slots = si_param_slots(si_names)
    si_by = {}
    for line in si_rows:
        k = rid_of(line)
        if k is not None:
            si_by[k] = line

    old_head, old_rows, old_names = read_table(os.path.join(OLD, 'StandardImpact.txt'))
    if old_names != si_names:
        raise SystemExit('StandardImpact cua server GOC lech tieu de — khong dung lam nguon')
    old_by = {}
    for line in old_rows:
        k = rid_of(line)
        if k is not None:
            old_by[k] = line

    # SE hop le = co o client CY (luat cua impact_data.py verify)
    cy_se = set(r[0] for r in Dbc(os.path.join(CY, 'ImpactSEData_V1.txt')).rows)

    # ---------- 1. repair: chep dong impact ma bang ride dang tro hut ----------
    want = set()
    for line in er_rows:
        for s in SPEED_COLS:
            x = num(cell(line, C[s]))
            if x is not None and x >= 0:
                want.add(x)
    missing = sorted(x for x in want if x not in si_by)
    for x in missing:
        src = old_by.get(x)
        if src is None:
            plan['notes'].append('impact %d: ca server GOC cung khong co, bo qua' % x)
            continue
        cells = src.split(TAB)
        if len(cells) < 27:
            plan['notes'].append('impact %d: dong nguon chi %d o, bo qua' % (x, len(cells)))
            continue
        if len(cells) != SI_COLS:
            plan['notes'].append('impact %d: dong nguon %d o -> ep ve %d' % (x, len(cells), SI_COLS))
        cells = si_fit(cells)
        se = num(cells[5])
        if se is not None and se >= 0 and se not in cy_se:
            cells[5] = b'-1'          # SE khong co o client CY -> -1 (luat impact_data)
        plan['repair_impacts'].append([x, TAB.join(cells).decode('latin-1')])

    # ---------- 2. them ride cho cac model CY con thieu ----------
    cy_er = Dbc(os.path.join(CY, 'Exterior_Ride.txt'))
    cy_first = {}
    for r in cy_er.rows:
        cy_first.setdefault(r[ER_MODEL], r)
    sv_models = set(num(cell(line, C['模型索引'])) for line in er_rows)
    used_ride = set(rid_of(line) for line in er_rows)
    used_imp = set(si_by) | set(x for x, _ in [(a, b) for a, b in plan['repair_impacts']])

    # mau impact cho tung bac toc do: lay dong THAT dang duoc chinh bang ride nay dung
    tpl = {}
    for line in er_rows:
        for s, t in zip(SPEED_COLS, TIERS):
            x = num(cell(line, C[s]))
            src = si_by.get(x) or old_by.get(x)
            if src is None or t in tpl:
                continue
            p = si_params(src, slots)
            if p.get(P_SPEED) == t and p.get(P_RIDE, -1) >= 0:
                tpl[t] = src
    if len(tpl) != len(TIERS):
        raise SystemExit('thieu mau impact cho bac toc do: %s' % sorted(set(TIERS) - set(tpl)))

    next_imp = NEW_IMPACT_BASE
    next_ride = NEW_RIDE_BASE

    def mint(model, name_bytes):
        """8 dong impact moi (mot bac toc do mot dong) cho mot 模型索引. Tra danh sach ID."""
        out = []
        for t in TIERS:
            iid = mint.next
            while iid in used_imp:
                iid += 1
            mint.next = iid + 1
            used_imp.add(iid)
            cells = si_fit(tpl[t].split(TAB))
            cells[0] = str(iid).encode('ascii')
            cells[1] = b'\xd7\xf8\xc6\xef\xa3\xba' + name_bytes      # "坐骑：" + ten (GBK)
            se = num(cells[5])
            if se is not None and se >= 0 and se not in cy_se:
                cells[5] = b'-1'
            if not si_set_param(cells, slots, P_RIDE, model):
                raise SystemExit('khong dat duoc %s cho impact %d' % (P_RIDE, iid))
            if not si_set_param(cells, slots, P_SPEED, t):
                raise SystemExit('khong dat duoc %s cho impact %d' % (P_SPEED, iid))
            if len(cells) != SI_COLS:
                raise SystemExit('dong impact moi %d co %d cot' % (iid, len(cells)))
            plan['new_impacts'].append([iid, TAB.join(cells).decode('latin-1')])
            out.append(iid)
        return out
    mint.next = NEW_IMPACT_BASE

    # ---------- 2a. chinh lai ride CU dang tro toi impact SAI ----------
    # Sau `repair`, mot so ride van khong ra dung model: ID impact cua chung bi CS3c gan cho thu
    # khac tren truc CY (vd ride 144 扶摇苍龙 dang dang ky '魂飞目断（CY推导属性）' len nguoi choi,
    # ride 39 陆吾 nhan 骑乘ID 27 = 木牛流马). KHONG sua dong impact dang co (dong do co the dang
    # phuc vu mot chieu that) — thay vao do duc 8 dong MOI va tro lai 8 cot toc do cua ride do.
    merged_si = dict(si_by)
    for x, txt in plan['repair_impacts']:
        merged_si[x] = txt.encode('latin-1')
    for line in er_rows:
        rid = rid_of(line)
        model = num(cell(line, C['模型索引']))
        got, dead = set(), []
        for s in SPEED_COLS:
            x = num(cell(line, C[s]))
            if x is None or x < 0:
                continue
            row = merged_si.get(x)
            if row is None:
                dead.append(x)           # ID khong con dong nao (vd 5766/5767 mat ca o server GOC)
                continue
            v = si_params(row, slots).get(P_RIDE)
            if v is not None and v >= 0:
                got.add(v)
        if got == {model} and not dead:
            continue
        name = cell(line, C['名字'])
        imps = mint(model, name)
        cells = line.split(TAB)
        for s, iid in zip(SPEED_COLS, imps):
            cells[C[s]] = str(iid).encode('ascii')
        plan['repoint_rides'].append([rid, model, gbk(name), sorted(got),
                                      TAB.join(cells).decode('latin-1')])

    # ---------- 2b. them ride cho cac model CY con thieu ----------
    for model in sorted(set(cy_first) - sv_models):
        src = cy_first[model]
        rid = src[0]
        if rid in used_ride:
            while next_ride in used_ride:
                next_ride += 1
            rid = next_ride
        used_ride.add(rid)

        speed = src[ER_SPEED]
        clamp = ''
        if speed not in TIERS:
            clamp = 'bac %d khong co cot tren server -> ep ve 90' % speed
            speed = 90

        imps = mint(model, src[ER_NAME])

        row = [b''] * ER_COLS
        row[0] = str(rid).encode('ascii')
        row[1] = str(src[1]).encode('ascii')
        row[2] = str(src[2]).encode('ascii')
        row[3] = str(src[3]).encode('ascii')
        row[4] = str(src[4]).encode('ascii')
        row[5] = str(model).encode('ascii')          # theo dung cach 6 toa ky 2026 da lam
        row[C['门派']] = str(src[ER_MENPAI]).encode('ascii')
        row[C['名字']] = src[ER_NAME]
        row[C['图标']] = src[ER_ICON]
        row[C['描述']] = src[ER_DESC]
        row[C['模型索引']] = str(model).encode('ascii')
        row[C['速度索引']] = str(speed).encode('ascii')
        row[12] = b'0'
        row[13] = b'0'
        row[14] = b'0'
        for s, iid in zip(SPEED_COLS, imps):
            row[C[s]] = str(iid).encode('ascii')
        row[18] = b'-1'
        row[24] = b'-1'
        row[25] = b'-1'
        if any(c == b'' for c in row):
            raise SystemExit('dong ride moi %d con o trong' % rid)
        plan['new_rides'].append([rid, model, gbk(src[ER_NAME]), src[0], speed, clamp,
                                  TAB.join(row).decode('latin-1')])

    # ---------- 3. sua ma hoa: o UTF-8 lot vao file GBK ----------
    for fn, fixes in (('Exterior_Ride.txt', {180: {C['名字']: None,
                                                   C['描述']: b'#GTrau Den lang que Viet Nam.'}}),
                      ('CharMount.txt', {220: {1: b'Trau Den'}})):
        _, rows, _ = read_table(os.path.join(cfg, fn))
        for line in rows:
            k = rid_of(line)
            if k not in fixes:
                continue
            try:
                line.decode('gbk')
                continue                 # dong nay da GBK hop le
            except UnicodeDecodeError:
                pass
            cells = line.split(TAB)
            for col, val in fixes[k].items():
                if val is not None:
                    cells[col] = val
            new = TAB.join(cells)
            new.decode('gbk')            # phai GBK hop le sau khi sua
            plan['encoding_fixes'].append([fn, k, new.decode('latin-1')])

    plan['summary'] = {
        'repair_impacts': len(plan['repair_impacts']),
        'repoint_rides': len(plan['repoint_rides']),
        'new_rides': len(plan['new_rides']),
        'new_impacts': len(plan['new_impacts']),
        'encoding_fixes': len(plan['encoding_fixes']),
    }
    return plan


def write_staging(root, plan, out_dir):
    cfg = os.path.join(root, 'configs')
    stage = os.path.join(out_dir, 'configs')
    os.makedirs(stage, exist_ok=True)

    # StandardImpact: tron theo ID tang dan
    head, rows, _ = read_table(os.path.join(cfg, 'StandardImpact.txt'))
    add = {}
    for iid, txt in plan['repair_impacts'] + plan['new_impacts']:
        add[iid] = txt.encode('latin-1')
    merged = {}
    for line in rows:
        merged[rid_of(line)] = line
    for k, v in add.items():
        if k in merged:
            raise SystemExit('impact %d da co tren R — ke hoach cu' % k)
        merged[k] = v
    body = [merged[k] for k in sorted(merged)]
    open(os.path.join(stage, 'StandardImpact.txt'), 'wb').write(
        CRLF.join(head + body) + CRLF)

    # Exterior_Ride: them dong + sua ma hoa, giu ID tang dan
    head, rows, _ = read_table(os.path.join(cfg, 'Exterior_Ride.txt'))
    merged = {}
    for line in rows:
        merged[rid_of(line)] = line
    for fn, k, txt in plan['encoding_fixes']:
        if fn == 'Exterior_Ride.txt':
            merged[k] = txt.encode('latin-1')
    for rid, _m, _n, _g, txt in plan['repoint_rides']:
        merged[rid] = txt.encode('latin-1')
    for rid, _m, _n, _cy, _s, _c, txt in plan['new_rides']:
        if rid in merged:
            raise SystemExit('ride %d da co tren R — ke hoach cu' % rid)
        merged[rid] = txt.encode('latin-1')
    open(os.path.join(stage, 'Exterior_Ride.txt'), 'wb').write(
        CRLF.join(head + [merged[k] for k in sorted(merged)]) + CRLF)

    # CharMount: chi sua ma hoa + tra ve CRLF thuan (bang CHET, khong doi cau truc)
    head, rows, _ = read_table(os.path.join(cfg, 'CharMount.txt'))
    fix = {k: txt.encode('latin-1') for fn, k, txt in plan['encoding_fixes'] if fn == 'CharMount.txt'}
    body = [fix.get(rid_of(line), line) for line in rows]
    open(os.path.join(stage, 'CharMount.txt'), 'wb').write(CRLF.join(head + body) + CRLF)

    json.dump(plan, open(os.path.join(out_dir, 'plan.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    with open(os.path.join(out_dir, 'ride_data.tsv'), 'w', encoding='utf-8') as fh:
        fh.write('ride_id\tmodel\tten\tride_id_CY\tbac_toc_do\tghi_chu\n')
        for rid, model, name, cyid, speed, clamp, _ in plan['new_rides']:
            fh.write('%d\t%d\t%s\t%d\t%d\t%s\n' % (rid, model, name, cyid, speed, clamp))
    return stage


class Lock(object):
    """flock dung chung voi scene_install.py / map_bianjing.py."""

    def __init__(self, root):
        self.path = os.path.join(root, 'configs', LOCK_NAME)

    def __enter__(self):
        import fcntl
        self.fh = open(self.path, 'a+')
        fcntl.flock(self.fh, fcntl.LOCK_EX)
        return self

    def __exit__(self, *a):
        import fcntl
        fcntl.flock(self.fh, fcntl.LOCK_UN)
        self.fh.close()
        return False


def merge_rows(head, rows, add, fix):
    """Tron dong moi vao bang song theo ID TANG DAN. `add` = {id: byte}, `fix` = {id: byte}.

    ID da co tren bang song thi BO QUA (idempotent + khong de len viec cua agent khac)."""
    live = {}
    for line in rows:
        live[rid_of(line)] = line
    skipped = [k for k in add if k in live]
    for k, v in add.items():
        if k not in live:
            live[k] = v
    for k, v in fix.items():
        if k in live:
            live[k] = v
    return CRLF.join(head + [live[k] for k in sorted(live)]) + CRLF, skipped


def apply(root, staging):
    """Tron LAI tu bang SONG ngay trong lock.

    Khong chep de file staging: luc do bang co the da doi (co agent khac dang sua StandardImpact —
    `impact_recollide` chay cung buoi 17/09). Staging chi de xem truoc; nguon su that la plan.json."""
    plan = json.load(open(os.path.join(staging, 'plan.json'), encoding='utf-8'))
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(root, 'backups', 'ride-data-%s' % stamp)
    cfg = os.path.join(root, 'configs')
    touched, skipped = [], {}
    with Lock(root):
        os.makedirs(bak, exist_ok=True)
        for f in ('StandardImpact.txt', 'Exterior_Ride.txt', 'CharMount.txt'):
            shutil.copy2(os.path.join(cfg, f), os.path.join(bak, f))

        head, rows, _ = read_table(os.path.join(cfg, 'StandardImpact.txt'))
        add = {k: t.encode('latin-1') for k, t in plan['repair_impacts'] + plan['new_impacts']}
        raw, sk = merge_rows(head, rows, add, {})
        raw.decode('gbk')
        open(os.path.join(cfg, 'StandardImpact.txt'), 'wb').write(raw)
        touched.append('StandardImpact.txt')
        skipped['StandardImpact.txt'] = sk

        head, rows, _ = read_table(os.path.join(cfg, 'Exterior_Ride.txt'))
        add = {r[0]: r[6].encode('latin-1') for r in plan['new_rides']}
        fix = {k: t.encode('latin-1') for fn, k, t in plan['encoding_fixes']
               if fn == 'Exterior_Ride.txt'}
        fix.update({r[0]: r[4].encode('latin-1') for r in plan['repoint_rides']})
        raw, sk = merge_rows(head, rows, add, fix)
        raw.decode('gbk')
        open(os.path.join(cfg, 'Exterior_Ride.txt'), 'wb').write(raw)
        touched.append('Exterior_Ride.txt')
        skipped['Exterior_Ride.txt'] = sk

        head, rows, _ = read_table(os.path.join(cfg, 'CharMount.txt'))
        fix = {k: t.encode('latin-1') for fn, k, t in plan['encoding_fixes']
               if fn == 'CharMount.txt'}
        raw, sk = merge_rows(head, rows, {}, fix)
        raw.decode('gbk')
        open(os.path.join(cfg, 'CharMount.txt'), 'wb').write(raw)
        touched.append('CharMount.txt')
    return bak, touched, skipped


# --------------------------------------------------------------------------- verify
def verify(root):
    """Doc lai TU DIA. Khong tin mot bien nao con trong bo nho."""
    cfg = os.path.join(root, 'configs')
    rep = {'ok': True, 'checks': []}

    def chk(name, ok, detail=''):
        rep['checks'].append({'name': name, 'ok': bool(ok), 'detail': detail})
        if not ok:
            rep['ok'] = False

    for f in ('StandardImpact.txt', 'Exterior_Ride.txt', 'CharMount.txt',
              'RideSeries.txt', 'RideCollection.txt', 'RideCollectionEffect.txt'):
        raw = open(os.path.join(cfg, f), 'rb').read()
        try:
            raw.decode('gbk')
            chk('GBK %s' % f, True)
        except UnicodeDecodeError as e:
            chk('GBK %s' % f, False, 'byte khong phai GBK tai offset %d' % e.start)
        chk('CRLF thuan %s' % f, raw.count(b'\n') == raw.count(b'\r\n'),
            'LF=%d CRLF=%d' % (raw.count(b'\n'), raw.count(b'\r\n')))

    si_head, si_rows, si_names = read_table(os.path.join(cfg, 'StandardImpact.txt'))
    ids = [rid_of(x) for x in si_rows]
    chk('StandardImpact ID tang dan', all(ids[k] < ids[k + 1] for k in range(len(ids) - 1)))
    widths = set(len(x.split(TAB)) for x in si_rows)
    chk('StandardImpact du %d cot' % SI_COLS, widths == {SI_COLS}, 'rong: %s' % sorted(widths))
    slots = si_param_slots(si_names)
    si_by = {rid_of(x): x for x in si_rows}

    er_head, er_rows, er_names = read_table(os.path.join(cfg, 'Exterior_Ride.txt'))
    C = {n: k for k, n in enumerate(er_names)}
    widths = set(len(x.split(TAB)) for x in er_rows)
    er_cols = len(er_names)        # ride-finish 18/09: 27 cot khi da co 速度125 (truc CY), 26 truoc do
    chk('Exterior_Ride du %d cot' % er_cols, widths == {er_cols}, 'rong: %s' % sorted(widths))
    rids = [rid_of(x) for x in er_rows]
    chk('Exterior_Ride ID tang dan va khong trung',
        all(rids[k] < rids[k + 1] for k in range(len(rids) - 1)))

    dead, model_ok, model_bad, no_ride = 0, 0, [], []
    total = 0
    for line in er_rows:
        rid = rid_of(line)
        model = num(cell(line, C['模型索引']))
        got = set()
        for s in SPEED_COLS:
            x = num(cell(line, C[s]))
            if x is None or x < 0:
                continue
            total += 1
            row = si_by.get(x)
            if row is None:
                dead += 1
                continue
            v = si_params(row, slots).get(P_RIDE)
            if v is not None and v >= 0:
                got.add(v)
        if not got:
            no_ride.append(rid)
        elif got == {model}:
            model_ok += 1
        else:
            model_bad.append([rid, model, sorted(got)])
    chk('moi o impact cua Exterior_Ride deu co dong that', dead == 0,
        '%d/%d o tro hut' % (dead, total))
    chk('moi ride co 骑乘ID khop 模型索引',
        len(no_ride) == 0 and len(model_bad) == 0,
        'khop %d/%d; khong co 骑乘ID: %s; lech: %s'
        % (model_ok, len(er_rows), no_ride[:12], model_bad[:12]))

    # item Type 41 dung duoc
    _, eb_rows, eb_names = read_table(os.path.join(cfg, 'EquipBase.txt'))
    E = {n: k for k, n in enumerate(eb_names)}
    sv_model = set(num(cell(x, C['模型索引'])) for x in er_rows)
    t41 = [x for x in eb_rows if num(cell(x, E['Type(类别)'])) == 41]
    # Visual < 0 = dong Type 41 KHONG phai thu cuoi (30 dong tui do 小/中/大行囊) -> khong tinh
    mounts = [x for x in t41 if num(cell(x, E['Visual']), -1) >= 0]
    usable = [x for x in mounts if num(cell(x, E['Visual'])) in sv_model]
    orphan = sorted(set(num(cell(x, E['Visual'])) for x in mounts
                        if num(cell(x, E['Visual'])) not in sv_model))
    rep['counts'] = {'exterior_ride': len(er_rows), 'models': len(sv_model),
                     'standard_impact': len(si_rows),
                     'item41': len(t41), 'item41_mounts': len(mounts),
                     'item41_usable': len(usable), 'rides_model_ok': model_ok,
                     'orphan_visuals': orphan}
    chk('moi item thu cuoi (Type 41, Visual >= 0) deu co ride',
        not orphan, '%d/%d dung duoc; Visual con mo coi: %s' % (len(usable), len(mounts), orphan))
    return rep


# --------------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('survey', 'plan', 'apply', 'verify'))
    ap.add_argument('--root', default=R)
    ap.add_argument('--out')
    ap.add_argument('--staging')
    a = ap.parse_args()

    if a.cmd == 'survey':
        rep = survey(a.root)
    elif a.cmd == 'plan':
        out = a.out or '/tmp/ride-data-plan'
        os.makedirs(out, exist_ok=True)
        plan = build_plan(a.root)
        write_staging(a.root, plan, out)
        rep = {'staging': out, 'summary': plan['summary'], 'notes': plan['notes'][:20]}
    elif a.cmd == 'apply':
        stg = a.staging or '/tmp/ride-data-plan'
        bak, files, skipped = apply(a.root, stg)
        rep = {'backup': bak, 'files': files,
               'bo_qua_vi_da_co': {k: len(v) for k, v in skipped.items()}}
    else:
        rep = verify(a.root)
    print(json.dumps(rep, ensure_ascii=False, indent=1))
    return 0 if rep.get('ok', True) else 1


if __name__ == '__main__':
    sys.exit(main())
