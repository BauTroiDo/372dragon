#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ride-finish (17/09/2026) — dua TRUC ID thu cuoi (坐骑) cua server rieng ve TRUC CY.

    python3 -B Tools/reapply/ride/ride_axis.py survey                  chi doc: cac con so hien tai
    python3 -B Tools/reapply/ride/ride_axis.py plan   [--out DIR]      dung staging + bao cao, KHONG cham R
    python3 -B Tools/reapply/ride/ride_axis.py apply  [--staging DIR]  flock + sao luu + ghi 5 bang vao R
    python3 -B Tools/reapply/ride/ride_axis.py verify                  doc lai TU DIA, khang dinh bat bien

Chay trong WSL TLBB bang root:
    wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/reapply/ride/ride_axis.py plan --out /tmp/ride-axis

===============================================================================
QUYET DINH DA CHOT (MOC-17-09 muc 7, khong hoi lai): SERVER DOI THEO CY, client la diem co dinh.
===============================================================================

Vi sao (do duoc): client CY tra `Exterior_Ride`/`CharMount` bang chinh ID; bang item cua server DA la bang CY
(tap `Visual` trung khit); Mongo 16 nhan vat, chi test09 so huu ride 1 (陆行雕, cung ID cung mesh o ca hai
nhanh) => doi bay gio khong can migration.

BA DAI ID cua `Exterior_Ride.txt` moi (mot dong = mot ride):

  1..297      DUNG dong cua CY (297 dong DBC `Assets/CanonicalCY/.../Exterior_Ride.txt`), 模型索引 la chi so
              CharMount CY, ten/icon/mo ta/门派/速度索引 lay nguyen byte GBK tu DBC.
  400 + c     "LAP CHO": CharMount CY dong c (khong phai 附件, co chuoi mesh) ma CY KHONG phat hanh dong ride.
              Uu tien lay noi dung tu dong ride GL cung MESH (neu co), khong thi nhan ban dong ride CY cung TEN,
              khong nua thi dong mau chung (門派 -1, bac 80). Vi du 551 = 大风 (10 item 飞龙：大风 dang dung khong len).
  1000 + r    "DO XE": ride GL r ma mesh KHONG co ben CY (53 dong theo mesh_match). Giu nguyen noi dung GL,
              nhung 模型索引 doi thanh 1000 + g de KHONG trung voi bat ky chi so CharMount CY nao — neu de nguyen,
              `LuaFnGetExteriorRideIDByVisual` (pairs()) co the tra ride GL cho item CY, va client CY se ve con
              vat KHAC ten. Client CY khong ve duoc chung (giong 31 "ghost" 101–134/227 truoc day). Khong item nao
              tro toi. Muon dung: nhap mesh vao CanonicalCY roi them dong CharMount o dung chi so 1000+g.

  Ride GL con lai (148 dong co ban tuong duong ben CY theo mesh, trong do CY da phat hanh ride) => BO, vi dong CY
  cung con vat da co o dung ID CY. Anh xa cu->moi ghi o `axis-map.tsv` (dung cho RideCollection/define.lua).

BAC TOC DO: CY co 10 bac 10/20/40/55/70/75/80/85/95/125 (doc tu mo ta SE `坐骑：X。…+N%` trong ImpactSEData_V1).
Server doc 8 cot ten `速度10..速度90`; cong cu THEM cot `速度125` o CUOI (an toan voi txtreader, `cfghelper` doc
theo ten — can 1 dong vao `read_exterior_ride`, xem ride_server_patch.py). Khong them 55/95 vi khong ride nao co
速度索引 do va `get_riders_max_speed_up` chi tra 速度索引 cua ride so huu. Giu cot 速度90 (chi ride GL do xe dung).

IMPACT (StandardImpact): moi (模型索引, bac) can mot dong logic 14 voi `骑乘ID == 模型索引` va
`移动速度修正% == bac`. Tim dong SONG thoa ca ba (va dung SE mong muon) thi dung lai, khong thi DUC MOI (ban sao
dong mau cung bac, chi doi Data_Index / 效果名称 / SE / 骑乘ID / 移动速度修正% / 装备 = 0). SE cua dong duc cho
ride CY = dong SE CY cung (ten, icon, bac) — dung icon + dung chu "+N%" nhu CY; bac 90 (khong co o CY) => -1.
ID moi cap trong [48000, 62999] tranh 63000–64099 (dai rieng cua server-impact) va KHONG BAO GIO >= 65536.
Chi THEM dong, khong xoa: dong impact cu cua ride GL bo/do xe tro thanh mo coi (dem o verify), vo hai.

BANG KHAC:
  CharMount.txt (server, bang CHET — khong ma nao doc): 353 dong CY chieu ve 15 cot GL
      [0..11] = CY[0..11], [12] = CY[16], [13] = CY[17], [14] = CY[22] (do cao bay). Kiem: 53 dong bay = CY.
  RideSeries.txt: 8 dong CY, BO cot thu 6 cua CY (gia tri 1/5/30, chua ro nghia) vi `ride_huayu_bonus.load_series`
      doc theo VI TRI (ints[5..] = ride id); giu cot do thi no bi doc thanh ride id 1/5/30. Ghi lai o plan.json.
  RideCollection.txt: 8 dong CY (cung 5 cot). 14 dong GL cu (ride id GL) => thay, anh xa ghi o bao cao.
  EquipBase.txt: KHONG cham (da la CY).

LUAT: lam o muc BYTE (GBK), sao luu truoc khi ghi, flock `.scene_install.lock` dung chung, apply tu choi neu
bang song khac luc plan (sha256), idempotent (plan lan 2 tren R da apply => 0 dong moi).
"""
import argparse
import collections
import datetime
import hashlib
import json
import os
import re
import shutil
import struct
import sys

R = '/home/ubuntu/cys-test-20260913'
CYD = '/mnt/c/TLBB/085/CY-Source/Assets/CanonicalCY/Data'
GLD = '/mnt/c/TLBB/085/client_GL/Data'
HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, 'data')
LOCK_NAME = '.scene_install.lock'
TAB, CRLF = b'\t', b'\r\n'

TIERS = (10, 20, 40, 70, 75, 80, 85, 90, 125)
CY_TIERS = (10, 20, 40, 55, 70, 75, 80, 85, 95, 125)          # 10 cot [18..27] cua DBC CY, theo thu tu
SPEED_COL = dict((t, '速度%d' % t) for t in TIERS)
P_RIDE = '骑乘ID(-1为无效)'
P_SPEED = '移动速度修正%（0为无效）'
SI_COLS = 81
ER_COLS = 27                       # 26 cot GL + 速度125
GAP_BASE = 400
PARK_BASE = 1000
IMPACT_ID_LO, IMPACT_ID_HI = 48000, 62999
IMPACT_ID_FORBID = (63000, 64099)  # server-impact: dai rieng cys_gl_impact_remap
FUJIAN = '附件'.encode('gbk')
ER_HEAD_26 = ('index\tINT\tINT\tINT\tINT\tINT\t门派\t名字\t图标\t描述\t模型索引\t速度索引\tINT\t取出ID\tINT\t'
              '速度10\t速度20\t速度40\tINT\t速度70\t速度75\t速度80\t速度85\t速度90\tINT\tINT')
FILES = ('Exterior_Ride.txt', 'StandardImpact.txt', 'CharMount.txt', 'RideSeries.txt', 'RideCollection.txt')


# --------------------------------------------------------------------------- doc
def read_table(path):
    """Bang van ban server: (2 dong tieu de byte, dong du lieu byte, ten cot str). Chiu EOL tron."""
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


def sha(path):
    return hashlib.sha256(open(path, 'rb').read()).hexdigest()


def fnum(v):
    """FLOAT DBC -> chu nhu bang GL ('0.5', '4', '0')."""
    s = ('%g' % v)
    return s.encode('ascii')


class Dbc(object):
    """DBC nhi phan 00CCBBDD, GIU NGUYEN BYTE o STRING (chuoi GBK)."""
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
    out, k = [], 27
    while k + 1 < len(names):
        if names[k].startswith('参数') and names[k].endswith('说明'):
            out.append((k, k + 1))
            k += 3
        else:
            k += 1
    return out


def si_params(cells, slots):
    out = {}
    for lc, vc in slots:
        if lc < len(cells) and vc < len(cells) and cells[lc].strip():
            out[gbk(cells[lc]).strip().strip('"')] = num(cells[vc])
    return out


def si_fit(cells):
    if len(cells) > SI_COLS:
        return cells[:SI_COLS]
    return cells + [b''] * (SI_COLS - len(cells))


def si_set_param(cells, slots, label, value):
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


# --------------------------------------------------------------------------- chuoi mesh
def objs_of(alldotobj):
    raw = open(alldotobj, 'rb').read()
    out, cur = {}, None
    for m in re.finditer(rb'<Object name="([^"]*)"|<Entity[^>]*file="([^"]*)"', raw):
        if m.group(1) is not None:
            cur = m.group(1).lower()
            out.setdefault(cur, [])
        elif cur is not None:
            out[cur].append(m.group(2).lower())
    return out


def mesh_of(model_id, cme, objs):
    obj = cme.get(model_id)
    return frozenset(objs.get(obj.lower(), [])) if obj else frozenset()


def load_sources():
    """Moi dau vao chi doc: CY (DBC), GL (client_GL), anh chup bang GL cua server (data/)."""
    S = {}
    S['cy_cm'] = Dbc(os.path.join(CYD, 'ConfigFolder', 'CharMount.txt')).rows
    S['cy_er'] = Dbc(os.path.join(CYD, 'ConfigFolder', 'Exterior_Ride.txt')).rows
    S['cy_rs'] = Dbc(os.path.join(CYD, 'ConfigFolder', 'RideSeries.txt')).rows
    S['cy_rc'] = Dbc(os.path.join(CYD, 'ConfigFolder', 'RideCollection.txt')).rows
    S['cy_se'] = Dbc(os.path.join(CYD, 'ConfigFolder', 'ImpactSEData_V1.txt')).rows
    cy_cme = dict((r[0], r[1]) for r in Dbc(os.path.join(CYD, 'ConfigFolder', 'CharModelEx.txt')).rows)
    cy_objs = objs_of(os.path.join(CYD, 'ModelFolder', 'all.obj'))
    gl_cme = {}
    for line in read_table(os.path.join(GLD, 'ConfigFolder', 'CharModelEx.txt'))[1]:
        c = line.split(TAB)
        if num(c[0]) is not None and len(c) > 1:
            gl_cme[num(c[0])] = c[1]
    gl_objs = objs_of(os.path.join(GLD, 'ModelFolder', 'all.obj'))
    _, gl_cm_rows, _ = read_table(os.path.join(GLD, 'ConfigFolder', 'CharMount.txt'))
    S['gl_cm'] = {}
    for line in gl_cm_rows:
        c = line.split(TAB)
        if num(c[0]) is None:
            continue
        S['gl_cm'][num(c[0])] = {'name': c[1], 'mesh': mesh_of(num(c[3]), gl_cme, gl_objs), 'cells': c}
    S['cy_cmb'] = {}
    for r in S['cy_cm']:
        S['cy_cmb'][r[0]] = {'name': r[1], 'mesh': mesh_of(r[3], cy_cme, cy_objs), 'row': r,
                             'fujian': FUJIAN in r[1], 'fly': r[22], 'riders': r[2], 'model_ok': r[3] in cy_cme}
    _, S['gl_er'], S['gl_er_names'] = read_table(os.path.join(DATA, 'server-exterior-ride-gl-198.txt'))
    return S


def map_gl_to_cy(S, gl_ride_names=None):
    """GL CharMount id -> CY CharMount id theo MESH (nhieu dong CY dung chung mot mesh: 附件, bien the mau).

    Tie-break: bo 附件 -> CharMount CY cung TEN voi ride GL (vd 曙光荧翼 -> 341, khong phai 339 夜霞赤羽)
    -> CharMount CY cung ten voi CharMount GL -> cung id -> id nho nhat."""
    by_mesh = collections.defaultdict(list)
    for c, d in S['cy_cmb'].items():
        if d['mesh']:
            by_mesh[d['mesh']].append(c)
    out, cands = {}, {}
    for g, d in S['gl_cm'].items():
        hits = by_mesh.get(d['mesh']) if d['mesh'] else None
        if not hits:
            continue
        cands[g] = sorted(hits)
        pool = [c for c in hits if not S['cy_cmb'][c]['fujian']] or list(hits)
        ride_names = (gl_ride_names or {}).get(g, [])
        by_ride = [c for c in pool if S['cy_cmb'][c]['name'] in ride_names]
        same_name = [c for c in pool if S['cy_cmb'][c]['name'] == d['name']]
        if by_ride:
            pool = by_ride
        elif same_name:
            pool = same_name
        out[g] = g if g in pool else min(pool)
    return out, cands


# --------------------------------------------------------------------------- ke hoach
def build_plan(root):
    S = load_sources()
    cfg = os.path.join(root, 'configs')
    plan = {'utc': datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ'), 'live_sha': {},
            'rides': [], 'new_impacts': [], 'axis_map': [], 'notes': [], 'dropped_series_col': []}
    for f in FILES:
        plan['live_sha'][f] = sha(os.path.join(cfg, f))

    # ---- bang song
    er_head, er_rows, er_names = read_table(os.path.join(cfg, 'Exterior_Ride.txt'))
    head26 = er_head[1].decode('gbk')
    if head26 == ER_HEAD_26:
        new_head = [er_head[0] + b'\tINT', er_head[1] + '\t速度125'.encode('gbk')]
    elif head26 == ER_HEAD_26 + '\t速度125':
        new_head = list(er_head)
    else:
        raise SystemExit('Exterior_Ride: tieu de la, dung lai: %r' % head26)
    si_head, si_rows, si_names = read_table(os.path.join(cfg, 'StandardImpact.txt'))
    slots = si_param_slots(si_names)
    if len(slots) < 9:
        raise SystemExit('StandardImpact: thieu khoi tham so')
    si_by = {}
    for line in si_rows:
        k = rid_of(line)
        if k is not None:
            si_by[k] = line
    cy_se_ids = set(r[0] for r in S['cy_se'])

    # ---- SE CY theo (icon, bac). Mo ta SE cua CanonicalCY da duoc DICH mot phan (UTF-8 "Tọa kỵ: Lục Hành Điêu.
    # … +95%") nen KHONG so ten; icon (RideHeaderX_Y) la khoa on dinh, "+N%" doc thang tren byte.
    # Uu tien khoi SE "hien dai" cua CY 3.71: 10 bac x 207 dong, id 4978..7047 (moi ride mot dong moi bac, buoc 207);
    # cac id nho hon (251..299) la dong cu (vd 258 "坐骑：雕 +40%" dung chung icon RideHeader1_9 voi 陆行雕).
    pat = re.compile(rb'\+(\d+)%')
    se_by_icon = {}
    for r in S['cy_se']:
        if r[1] != 99 or r[2] != 52200:
            continue
        m = pat.search(r[16])
        if not m:
            continue
        key = (r[3], int(m.group(1)))
        modern = 4978 <= r[0] < 4978 + 10 * 207
        cur = se_by_icon.get(key)
        if cur is None or (modern and not cur[1]) or (modern == cur[1] and r[0] < cur[0]):
            se_by_icon[key] = (r[0], modern)
    se_by_icon = dict((k, v[0]) for k, v in se_by_icon.items())
    if len(se_by_icon) < 2000:
        raise SystemExit('ImpactSEData_V1 CY: chi tim thay %d SE (icon, bac) — bang doi?' % len(se_by_icon))

    # ---- index dong impact song: (model, tier) -> [(id, se)]
    live_idx = collections.defaultdict(list)
    for k, line in si_by.items():
        c = line.split(TAB)
        if len(c) < 30 or c[2] != b'14':
            continue
        p = si_params(c, slots)
        m, t = p.get(P_RIDE), p.get(P_SPEED)
        if m is not None and m >= 0 and t is not None:
            live_idx[(m, t)].append((k, num(c[5], -1)))
    for v in live_idx.values():
        v.sort()

    # ---- mau impact cho tung bac (dong THAT cua 0.85, phan loai 99)
    tpl = {}
    for k in sorted(si_by):
        c = si_by[k].split(TAB)
        if len(c) < 30 or c[2] != b'14' or c[6] != b'99':
            continue
        p = si_params(c, slots)
        t = p.get(P_SPEED)
        if p.get(P_RIDE, -1) >= 0 and t in TIERS and t not in tpl:
            tpl[t] = si_fit(c)
    if 125 not in tpl:
        tpl[125] = list(tpl[90])
    missing_t = [t for t in TIERS if t not in tpl]
    if missing_t:
        raise SystemExit('thieu mau impact cho bac: %s' % missing_t)

    used_imp = set(si_by)
    alloc = {'next': IMPACT_ID_LO}

    def new_impact_id():
        k = alloc['next']
        while k in used_imp or IMPACT_ID_FORBID[0] <= k <= IMPACT_ID_FORBID[1]:
            k += 1
        if k > IMPACT_ID_HI:
            raise SystemExit('het ID impact trong [%d, %d]' % (IMPACT_ID_LO, IMPACT_ID_HI))
        used_imp.add(k)
        alloc['next'] = k + 1
        return k

    def want_se(name, icon, t, gl_se):
        """SE mong muon cho (ride, bac): CY (icon, bac) -> SE cu cua GL neu CY co dong do -> -1.
        Bac 90 khong ton tai o CY (CY: 10/20/40/55/70/75/80/85/95/125) => khong co icon dung chu."""
        k = se_by_icon.get((icon, t)) if t != 90 else None
        if k is None and gl_se is not None and gl_se >= 0 and gl_se in cy_se_ids:
            k = gl_se
        return k if k is not None else -1

    def impacts_for(model, name, icon, gl_ses):
        """{bac: impact id} cho mot ride; dung lai dong song neu (model, bac, SE) trung, khong thi duc."""
        out = {}
        for t in TIERS:
            se = want_se(name, icon, t, gl_ses.get(t))
            hit = [k for k, s in live_idx.get((model, t), []) if s == se]
            if hit:
                out[t] = hit[0]
                continue
            iid = new_impact_id()
            c = list(tpl[t])
            c[0] = str(iid).encode('ascii')
            c[1] = '坐骑：'.encode('gbk') + name
            c[5] = str(se).encode('ascii')
            c[23] = b'0'                      # 是否需要装备支持: khong doi item (khong noi nao ep)
            c[24] = b'0'                      # 装备的ItemIndex
            if not si_set_param(c, slots, P_RIDE, model) or not si_set_param(c, slots, P_SPEED, t):
                raise SystemExit('khong dat duoc tham so cho impact %d' % iid)
            if len(c) != SI_COLS:
                raise SystemExit('impact moi %d co %d cot' % (iid, len(c)))
            plan['new_impacts'].append([iid, TAB.join(c).decode('latin-1')])
            live_idx[(model, t)].append((iid, se))
            out[t] = iid
        return out

    def er_row(rid, c1_5, menpai, name, icon, desc, model, tier, c12, c13, c14, imps):
        row = [b''] * ER_COLS
        row[0] = str(rid).encode('ascii')
        for k in range(5):
            row[1 + k] = str(c1_5[k]).encode('ascii')
        row[6] = str(menpai).encode('ascii')
        row[7], row[8], row[9] = name, icon, desc
        row[10] = str(model).encode('ascii')
        row[11] = str(tier).encode('ascii')
        row[12], row[13], row[14] = str(c12).encode('ascii'), str(c13).encode('ascii'), str(c14).encode('ascii')
        row[15], row[16], row[17] = (str(imps[10]).encode(), str(imps[20]).encode(), str(imps[40]).encode())
        row[18] = b'-1'
        row[19], row[20], row[21] = (str(imps[70]).encode(), str(imps[75]).encode(), str(imps[80]).encode())
        row[22], row[23] = str(imps[85]).encode(), str(imps[90]).encode()
        row[24], row[25] = b'-1', b'-1'
        row[26] = str(imps[125]).encode()
        if any(x == b'' for x in row):
            raise SystemExit('dong ride %d con o trong' % rid)
        return row

    # ---- GL server rows (198) -> phan loai
    G = dict((n, k) for k, n in enumerate(S['gl_er_names']))
    # Anh chup GL (data/) la ban TRUOC ride-data: dong 180 (越南黑水牛, them 06/09) con mo ta tieng Viet ma hoa
    # GB18030 4 byte — txtreader chi hieu GBK. ride-data da doi o do sang ASCII tren bang song; lam y het o day.
    GL_ENC_FIX = {180: {G['描述']: b'#GTrau Den lang que Viet Nam.'}}
    gl_rows = {}
    for line in S['gl_er']:
        c = line.split(TAB)
        rid = num(c[0])
        if rid is None:
            continue
        for k, v in GL_ENC_FIX.get(rid, {}).items():
            c[k] = v
        try:
            TAB.join(c).decode('gbk')
        except UnicodeDecodeError as e:
            raise SystemExit('dong GL %d khong phai GBK (byte %r) — them vao GL_ENC_FIX' % (rid, e.object[e.start:e.start + 4]))
        ses = {}
        for t in (10, 20, 40, 70, 75, 80, 85, 90):
            x = num(c[G[SPEED_COL[t]]])
            src = si_by.get(x)
            ses[t] = num(src.split(TAB)[5], -1) if src else -1
        gl_rows[rid] = {'cells': c, 'model': num(c[G['模型索引']]), 'name': c[G['名字']], 'icon': c[G['图标']],
                        'desc': c[G['描述']], 'menpai': num(c[G['门派']]), 'tier': num(c[G['速度索引']]),
                        'c1_5': [num(c[k]) for k in range(1, 6)], 'c12': num(c[12]), 'c13': num(c[13]),
                        'c14': num(c[14]), 'ses': ses}

    gl_ride_names = collections.defaultdict(list)
    for d in gl_rows.values():
        gl_ride_names[d['model']].append(d['name'])
    gl2cy, cands = map_gl_to_cy(S, gl_ride_names)
    cy_models = collections.defaultdict(list)             # CY 模型索引 -> [ride id]
    for r in S['cy_er']:
        cy_models[r[10]].append(r[0])
    cy_er_by = dict((r[0], r) for r in S['cy_er'])

    def cy_ride_for_model(m):
        """Ride CY dai dien cho mot 模型索引 (uu tien 门派 -1, roi id nho nhat) — cung luat voi
        LuaFnGetExteriorRideIDByVisual sau khi va."""
        ids = cy_models.get(m, [])
        pref = [i for i in ids if cy_er_by[i][6] == -1]
        return min(pref) if pref else (min(ids) if ids else None)

    rides = {}       # id -> (row, provenance dict)
    # (1) 297 dong CY
    for r in S['cy_er']:
        imps = impacts_for(r[10], r[7], r[8], {})
        row = er_row(r[0], r[1:6], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], imps)
        rides[r[0]] = (row, {'src': 'CY', 'cy_id': r[0], 'model': r[10], 'name': gbk(r[7]), 'tier': r[11]})

    # (2) 198 dong GL: bo / lap cho / do xe
    filled_gap = {}
    for rid in sorted(gl_rows):
        d = gl_rows[rid]
        g = d['model']
        c = gl2cy.get(g)
        rec = {'gl_id': rid, 'gl_model': g, 'gl_name': gbk(d['name']), 'cy_model': c,
               'cy_model_name': gbk(S['cy_cmb'][c]['name']) if c is not None else '',
               'candidates': cands.get(g, [])}
        if c is not None and c in cy_models:
            rec['action'] = 'BO (CY da co ride cung con)'
            rec['new_id'] = cy_ride_for_model(c)
        elif c is not None:
            nid = GAP_BASE + c
            if nid in rides:
                rec['action'] = 'BO (dong GL khac cung mesh da lap cho %d)' % nid
                rec['new_id'] = nid
            else:
                imps = impacts_for(c, S['cy_cmb'][c]['name'], d['icon'], d['ses'])
                row = er_row(nid, d['c1_5'], d['menpai'], S['cy_cmb'][c]['name'], d['icon'], d['desc'], c,
                             d['tier'], d['c12'], d['c13'], d['c14'], imps)
                rides[nid] = (row, {'src': 'GAP-GL', 'gl_id': rid, 'model': c,
                                    'name': gbk(S['cy_cmb'][c]['name']), 'tier': d['tier']})
                filled_gap[c] = nid
                rec['action'] = 'LAP CHO (CharMount CY %d khong co ride CY)' % c
                rec['new_id'] = nid
        else:
            nid = PARK_BASE + rid
            pm = PARK_BASE + g
            imps = impacts_for(pm, d['name'], d['icon'], d['ses'])
            row = er_row(nid, d['c1_5'], d['menpai'], d['name'], d['icon'], d['desc'], pm, d['tier'],
                         d['c12'], d['c13'], d['c14'], imps)
            rides[nid] = (row, {'src': 'DO-XE-GL', 'gl_id': rid, 'model': pm, 'gl_model': g,
                                'name': gbk(d['name']), 'tier': d['tier']})
            rec['action'] = 'DO XE (mesh khong co ben CY)'
            rec['new_id'] = nid
        plan['axis_map'].append(rec)

    # (3) CharMount CY khong 附件, co chuoi mesh, chua co ride nao -> duc.
    #     Them: dong 附件 ma co ITEM Type 41 tro toi (Visual 95 金翅附件, 97 烟雨清荷附件, 152 大风附件 — CY ban item
    #     nhung khong phat hanh ride cho chung): duc theo ride cua con chinh (cung ModelID, ten bo 附件),
    #     de item dung duoc va ve dung con vat.
    _, eb_rows, eb_names = read_table(os.path.join(cfg, 'EquipBase.txt'))
    E = dict((n, k) for k, n in enumerate(eb_names))
    item_visuals = set(num(cell(x, E['Visual']), -1) for x in eb_rows if num(cell(x, E['Type(类别)'])) == 41)
    #     Bo qua CharMount CY ma mot ride da len ke hoach dang tro toi (vd 1220 越南黑水牛 = Trau Den nguoi dung tu lam,
    #     nhap vao CanonicalCY 18/09 boi trau_den_import.py; ride 1180 do xe da tro 模型索引 1220) — khong duc dong thu hai.
    models_planned = set(num(row[10]) for row, _ in rides.values())
    for c in sorted(S['cy_cmb']):
        d = S['cy_cmb'][c]
        if not d['mesh'] or not d['model_ok'] or c in cy_models or c in filled_gap or c in models_planned:
            continue
        if d['fujian'] and c not in item_visuals:
            continue
        nid = GAP_BASE + c
        twin = [r for r in S['cy_er'] if r[7] == d['name']]
        if d['fujian'] and not twin:
            main_name = d['name'].replace(FUJIAN, b'')
            main_ids = [m for m, md in S['cy_cmb'].items() if md['name'] == main_name and md['row'][3] == d['row'][3]]
            twin = [r for r in S['cy_er'] if r[10] in main_ids]
            if not twin and main_ids and (GAP_BASE + main_ids[0]) in rides:
                trow, tprov = rides[GAP_BASE + main_ids[0]]
                twin = [[num(trow[0])] + [num(trow[k]) for k in range(1, 6)] + [num(trow[6]), trow[7], trow[8],
                        trow[9], num(trow[10]), num(trow[11]), num(trow[12]), num(trow[13]), num(trow[14])]]
        if twin:
            src = twin[0]
            c1_5, menpai, icon, desc, tier = src[1:6], src[6], src[8], src[9], src[11]
            c12, c13, c14 = src[12], src[13], src[14]
            how = 'nhan ban ride CY cung ten %d' % src[0]
        else:
            base = cy_er_by[1]
            c1_5, menpai, icon, desc, tier = base[1:6], -1, base[8], b'#G', 80
            c12, c13, c14 = 0, -1, 0
            how = 'mau chung (icon cua ride 1, bac 80)'
        if d['fly'] > 0 and tier < 80:
            # moi ride CY co model bay deu bac 80 (20 dong) hoac 85 (6 dong); khong dong nao duoi 80
            tier = 80
            how += '; model bay => bac 80'
        imps = impacts_for(c, d['name'], icon, {})
        row = er_row(nid, c1_5, menpai, d['name'], icon, desc, c, tier, c12, c13, c14, imps)
        rides[nid] = (row, {'src': 'DUC', 'model': c, 'name': gbk(d['name']), 'tier': tier, 'how': how,
                            'fly': d['fly'], 'riders': d['riders']})
        plan['notes'].append('duc ride %d cho CharMount CY %d %s (%s)' % (nid, c, gbk(d['name']), how))

    for rid in sorted(rides):
        row, prov = rides[rid]
        plan['rides'].append([rid, TAB.join(row).decode('latin-1'), prov])
    plan['er_head'] = [h.decode('latin-1') for h in new_head]

    # ---- dong impact do ride-data (17/09) duc trong dai 64100..65571 ma bang ride MOI khong con tro toi:
    # chi la dong thu cuoi (logic 14, ten 坐骑：…, co 骑乘ID), do chinh nhanh nay tao hom qua, 36 dong >= 65536.
    # Xoa de bang khong mang 1.472 dong chet; dong 0.85 goc (id < 64100) van GIU (chi them, khong xoa).
    referenced = set()
    for _, txt, _ in plan['rides']:
        c = txt.encode('latin-1').split(TAB)
        for k in (15, 16, 17, 19, 20, 21, 22, 23, 26):
            referenced.add(num(c[k]))
    dels = []
    for k in sorted(si_by):
        if 64100 <= k <= 65571 and k not in referenced:
            c = si_by[k].split(TAB)
            if len(c) > 30 and c[2] == b'14' and c[1].startswith('坐骑：'.encode('gbk')) \
                    and si_params(c, slots).get(P_RIDE, -1) >= 0:
                dels.append(k)
    plan['delete_impacts'] = dels

    # ---- CharMount server = CY chieu 15 cot
    cm_head, _, _ = read_table(os.path.join(cfg, 'CharMount.txt'))
    cm_rows = []
    for r in S['cy_cm']:
        c = [str(r[0]).encode(), r[1], str(r[2]).encode(), str(r[3]).encode(), fnum(r[4]), str(r[5]).encode(),
             str(r[6]).encode(), str(r[7]).encode(), r[8], str(r[9]).encode(), str(r[10]).encode(), r[11],
             str(r[16]).encode(), str(r[17]).encode(), fnum(r[22])]
        cm_rows.append(TAB.join(c).decode('latin-1'))
    plan['charmount'] = {'head': [h.decode('latin-1') for h in cm_head], 'rows': cm_rows}

    # ---- RideSeries / RideCollection = CY
    maxr = 0
    series = []
    for r in S['cy_rs']:
        ids = [x for x in r[6:] if isinstance(x, int) and x > 0]
        maxr = max(maxr, len(ids))
        series.append((r, ids))
        plan['dropped_series_col'].append([r[0], gbk(r[1]), r[5]])
    width = max(maxr, 10)
    rs_head = [TAB.join([b'INT', b'STRING'] + [b'INT'] * (3 + width))] * 2
    rs_rows = []
    for r, ids in series:
        c = [str(r[0]).encode(), r[1], str(r[2]).encode(), str(r[3]).encode(), str(r[4]).encode()]
        c += [str(x).encode() for x in ids] + [b'-1'] * (width - len(ids))
        rs_rows.append(TAB.join(c).decode('latin-1'))
    plan['rideseries'] = {'head': [h.decode('latin-1') for h in rs_head], 'rows': rs_rows}
    rc_head, _, _ = read_table(os.path.join(cfg, 'RideCollection.txt'))
    rc_rows = []
    for r in S['cy_rc']:
        c = [str(r[0]).encode(), str(r[1]).encode(), str(r[2]).encode(), str(r[3]).encode(), r[4]]
        rc_rows.append(TAB.join(c).decode('latin-1'))
    plan['ridecollection'] = {'head': [h.decode('latin-1') for h in rc_head], 'rows': rc_rows}

    # ---- define.lua: ADD_EQUIP_BUFF HEQUIP_RIDER MINID/MAXID = 174 (GL 飒露紫) -> id moi
    rec174 = [x for x in plan['axis_map'] if x['gl_id'] == 174]
    plan['define_ride_range'] = {'gl_id': 174, 'new_id': rec174[0]['new_id'] if rec174 else None,
                                 'note': rec174[0]['action'] if rec174 else 'khong co dong GL 174'}

    srcs = collections.Counter(p['src'] for _, _, p in plan['rides'])
    acts = collections.Counter(x['action'].split(' (')[0] for x in plan['axis_map'])
    plan['summary'] = {'rides': len(plan['rides']), 'by_src': dict(srcs), 'gl_actions': dict(acts),
                       'new_impacts': len(plan['new_impacts']), 'delete_impacts': len(plan['delete_impacts']),
                       'series_width': width,
                       'define_ride_range': plan['define_ride_range']}
    return plan


def write_staging(root, plan, out_dir):
    cfg = os.path.join(root, 'configs')
    stage = os.path.join(out_dir, 'configs')
    os.makedirs(stage, exist_ok=True)
    head = [h.encode('latin-1') for h in plan['er_head']]
    body = [txt.encode('latin-1') for _, txt, _ in plan['rides']]
    open(os.path.join(stage, 'Exterior_Ride.txt'), 'wb').write(CRLF.join(head + body) + CRLF)

    si_head, si_rows, _ = read_table(os.path.join(cfg, 'StandardImpact.txt'))
    merged = dict((rid_of(l), l) for l in si_rows)
    for k in plan.get('delete_impacts', []):
        merged.pop(k, None)
    for iid, txt in plan['new_impacts']:
        if iid in merged:
            raise SystemExit('impact %d da co tren R — ke hoach cu, chay plan lai' % iid)
        merged[iid] = txt.encode('latin-1')
    open(os.path.join(stage, 'StandardImpact.txt'), 'wb').write(
        CRLF.join(si_head + [merged[k] for k in sorted(merged)]) + CRLF)

    for name, key in (('CharMount.txt', 'charmount'), ('RideSeries.txt', 'rideseries'),
                      ('RideCollection.txt', 'ridecollection')):
        d = plan[key]
        open(os.path.join(stage, name), 'wb').write(
            CRLF.join([h.encode('latin-1') for h in d['head']] + [r.encode('latin-1') for r in d['rows']]) + CRLF)
    for f in FILES:
        open(os.path.join(stage, f), 'rb').read().decode('gbk')

    json.dump(plan, open(os.path.join(out_dir, 'plan.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    with open(os.path.join(out_dir, 'axis-map.tsv'), 'w', encoding='utf-8') as fh:
        fh.write('gl_ride\tgl_model\tgl_name\tcy_model\tcy_model_name\tcandidates\taction\tnew_id\n')
        for x in plan['axis_map']:
            fh.write('%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\n' % (x['gl_id'], x['gl_model'], x['gl_name'],
                     x['cy_model'], x['cy_model_name'], ','.join(str(c) for c in x['candidates']),
                     x['action'], x['new_id']))
    with open(os.path.join(out_dir, 'rides.tsv'), 'w', encoding='utf-8') as fh:
        fh.write('ride_id\tsrc\tmodel\tname\ttier\tghi_chu\n')
        for rid, _, p in plan['rides']:
            extra = p.get('how', '') or ('gl_id=%s' % p.get('gl_id', '') if 'gl_id' in p else '')
            fh.write('%d\t%s\t%d\t%s\t%s\t%s\n' % (rid, p['src'], p['model'], p['name'], p['tier'], extra))
    return stage


class Lock(object):
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


def apply(root, staging):
    plan = json.load(open(os.path.join(staging, 'plan.json'), encoding='utf-8'))
    cfg = os.path.join(root, 'configs')
    stage = os.path.join(staging, 'configs')
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(root, 'backups', 'ride-finish-%s' % stamp)
    rep = {'backup': bak, 'written': [], 'unchanged': [], 'impacts_added': 0, 'impacts_skipped_same': 0}
    with Lock(root):
        # bang song phai dung nhu luc plan (hoac da la ket qua cua plan nay) — khong thi ghi de viec nguoi khac
        for f in ('Exterior_Ride.txt', 'CharMount.txt', 'RideSeries.txt', 'RideCollection.txt'):
            live = sha(os.path.join(cfg, f))
            if live != plan['live_sha'][f] and live != sha(os.path.join(stage, f)):
                raise SystemExit('%s tren R da doi tu luc plan — chay plan lai' % f)
        os.makedirs(bak, exist_ok=True)
        for f in FILES:
            shutil.copy2(os.path.join(cfg, f), os.path.join(bak, f))

        # StandardImpact: TRON tu bang song (server-data cung ghi bang nay): them dong moi, bo dong ride-data mo coi
        head, rows, _ = read_table(os.path.join(cfg, 'StandardImpact.txt'))
        live = dict((rid_of(l), l) for l in rows)
        rep['impacts_deleted'] = 0
        for k in plan.get('delete_impacts', []):
            if k in live and live[k].split(TAB)[2] == b'14' and live[k].split(TAB)[1].startswith('坐骑：'.encode('gbk')):
                del live[k]
                rep['impacts_deleted'] += 1
        for iid, txt in plan['new_impacts']:
            b = txt.encode('latin-1')
            if iid in live:
                if live[iid] == b:
                    rep['impacts_skipped_same'] += 1
                    continue
                raise SystemExit('impact %d da co tren R voi noi dung KHAC — xung dot, chay plan lai' % iid)
            live[iid] = b
            rep['impacts_added'] += 1
        raw = CRLF.join(head + [live[k] for k in sorted(live)]) + CRLF
        raw.decode('gbk')
        if rep['impacts_added'] or rep['impacts_deleted']:
            atomic_write(os.path.join(cfg, 'StandardImpact.txt'), raw)
            rep['written'].append('StandardImpact.txt')
        else:
            rep['unchanged'].append('StandardImpact.txt')

        for f in ('Exterior_Ride.txt', 'CharMount.txt', 'RideSeries.txt', 'RideCollection.txt'):
            raw = open(os.path.join(stage, f), 'rb').read()
            raw.decode('gbk')
            if open(os.path.join(cfg, f), 'rb').read() == raw:
                rep['unchanged'].append(f)
                continue
            atomic_write(os.path.join(cfg, f), raw)
            rep['written'].append(f)
    return rep


def atomic_write(path, raw):
    """Ghi qua file tam roi os.replace: server dang khoi dong (nap bang) khong bao gio doc duoc file nua chung."""
    tmp = path + '.cys-tmp'
    with open(tmp, 'wb') as fh:
        fh.write(raw)
        fh.flush()
        os.fsync(fh.fileno())
    shutil.copymode(path, tmp)
    os.replace(tmp, path)


# --------------------------------------------------------------------------- do / kiem
def measure(root):
    """Cac con so dung chung cho survey va verify — doc TU DIA."""
    S = load_sources()
    cfg = os.path.join(root, 'configs')
    M = {}
    er_head, er_rows, er_names = read_table(os.path.join(cfg, 'Exterior_Ride.txt'))
    C = dict((n, k) for k, n in enumerate(er_names))
    tiers = [t for t in TIERS if SPEED_COL[t] in C]
    si_head, si_rows, si_names = read_table(os.path.join(cfg, 'StandardImpact.txt'))
    slots = si_param_slots(si_names)
    si_by = dict((rid_of(l), l) for l in si_rows)
    cy_er_by = dict((r[0], r) for r in S['cy_er'])
    cmb = S['cy_cmb']

    rows = []
    for line in er_rows:
        c = line.split(TAB)
        rows.append({'id': num(c[0]), 'model': num(c[C['模型索引']]), 'name': c[C['名字']],
                     'tier': num(c[C['速度索引']]), 'menpai': num(c[C['门派']]),
                     'imps': dict((t, num(c[C[SPEED_COL[t]]])) for t in tiers), 'ncols': len(c)})
    M['rides'] = len(rows)
    M['cols'] = sorted(set(r['ncols'] for r in rows))
    M['has_125'] = '速度125' in C
    ids = [r['id'] for r in rows]
    M['ids_sorted_unique'] = all(ids[k] < ids[k + 1] for k in range(len(ids) - 1))

    # 4 con so cua ride-data
    sv_models = set(r['model'] for r in rows)
    drawable = [c for c, d in cmb.items() if not d['fujian'] and d['mesh']]
    M['cy_visible'] = '%d/%d' % (sum(1 for c in drawable if c in sv_models),
                                  sum(1 for c in cmb if not cmb[c]['fujian']))
    dead = total = 0
    model_ok = 0
    bad = []
    for r in rows:
        got = set()
        for t, x in r['imps'].items():
            if x is None or x < 0:
                continue
            total += 1
            src = si_by.get(x)
            if src is None:
                dead += 1
                continue
            v = si_params(src.split(TAB), slots)
            if v.get(P_RIDE, -1) >= 0:
                got.add(v[P_RIDE])
            if v.get(P_SPEED) != t or src.split(TAB)[2] != b'14':
                bad.append([r['id'], t, x, 'speed/logic sai'])
        if got == set([r['model']]):
            model_ok += 1
        else:
            bad.append([r['id'], 'model', r['model'], sorted(got)])
    M['impact_cells'] = '%d/%d chet' % (dead, total)
    M['rides_model_ok'] = '%d/%d' % (model_ok, len(rows))
    M['impact_bad'] = bad[:10]
    M['impact_bad_n'] = len(bad)

    _, eb_rows, eb_names = read_table(os.path.join(cfg, 'EquipBase.txt'))
    E = dict((n, k) for k, n in enumerate(eb_names))
    mounts = [x for x in eb_rows if num(cell(x, E['Type(类别)'])) == 41 and num(cell(x, E['Visual']), -1) >= 0]
    usable = [x for x in mounts if num(cell(x, E['Visual'])) in sv_models]
    M['items_usable'] = '%d/%d' % (len(usable), len(mounts))
    M['items_orphan_visuals'] = sorted(set(num(cell(x, E['Visual'])) for x in mounts) - sv_models)
    M['items_visual_not_in_cy_charmount'] = sorted(set(num(cell(x, E['Visual'])) for x in mounts) - set(cmb))

    # truc CY
    same = diff = 0
    diffs = []
    for r in rows:
        if r['id'] in cy_er_by:
            cy = cy_er_by[r['id']]
            if cy[10] == r['model'] and cy[7] == r['name']:
                same += 1
            else:
                diff += 1
                diffs.append([r['id'], r['model'], gbk(r['name']), cy[10], gbk(cy[7])])
    M['cy_rows_same'] = '%d/%d' % (same, len(cy_er_by))
    M['cy_rows_diff'] = diffs[:10]
    M['cy_rows_missing'] = sorted(set(cy_er_by) - set(ids))[:20]
    # dong co model < PARK_BASE ma model khong phai CharMount CY, hoac ten khac ten CharMount CY
    wrong = []
    for r in rows:
        if r['model'] >= PARK_BASE:
            continue
        d = cmb.get(r['model'])
        if d is None:
            wrong.append([r['id'], r['model'], gbk(r['name']), 'khong co CharMount CY'])
        elif r['id'] >= GAP_BASE and r['id'] < PARK_BASE and r['id'] != GAP_BASE + r['model']:
            wrong.append([r['id'], r['model'], gbk(r['name']), 'id lap cho sai'])
    M['model_not_cy'] = wrong[:10]
    M['model_not_cy_n'] = len(wrong)
    M['parked'] = sum(1 for r in rows if r['id'] >= PARK_BASE)
    M['gap'] = sum(1 for r in rows if GAP_BASE <= r['id'] < PARK_BASE)
    # trung 模型索引 (LuaFnGetExteriorRideIDByVisual)
    cnt = collections.Counter(r['model'] for r in rows)
    M['models_shared'] = sorted((m, n) for m, n in cnt.items() if n > 1)
    # dong impact ride mo coi
    used = set(x for r in rows for x in r['imps'].values() if x is not None and x >= 0)
    orphan = 0
    for k, l in si_by.items():
        c = l.split(TAB)
        if len(c) > 30 and c[2] == b'14' and k not in used:
            if si_params(c, slots).get(P_RIDE, -1) >= 0:
                orphan += 1
    M['orphan_ride_impacts'] = orphan
    M['impact_ids_ge_65536_used'] = sorted(x for x in used if x >= 65536)

    # CharMount server
    _, cm_rows, _ = read_table(os.path.join(cfg, 'CharMount.txt'))
    fly = [num(l.split(TAB)[0]) for l in cm_rows if len(l.split(TAB)) > 14 and float(l.split(TAB)[14] or 0) > 0]
    M['charmount_rows'] = len(cm_rows)
    M['charmount_fly'] = len(fly)
    M['charmount_fly_eq_cy'] = sorted(fly) == sorted(c for c, d in cmb.items() if d['fly'] > 0)

    # RideSeries / RideCollection
    _, rs_rows, _ = read_table(os.path.join(cfg, 'RideSeries.txt'))
    rs_bad = []
    for l in rs_rows:
        c = l.split(TAB)
        for x in c[5:]:
            v = num(x)
            if v is not None and v > 0 and v not in set(ids):
                rs_bad.append([num(c[0]), v])
    M['rideseries_rows'] = len(rs_rows)
    M['rideseries_bad_ids'] = rs_bad[:10]
    _, rc_rows, _ = read_table(os.path.join(cfg, 'RideCollection.txt'))
    rc_bad = []
    for l in rc_rows:
        c = l.split(TAB)
        if num(c[2]) == 0 and num(c[1]) not in set(ids):
            rc_bad.append([num(c[0]), num(c[1])])
    M['ridecollection_rows'] = len(rc_rows)
    M['ridecollection_bad_ids'] = rc_bad

    # ma hoa: GBK giai ma duoc, CRLF thuan, va KHONG co dong UTF-8 that (cung phep thu voi
    # Tools/rasoat-4phai/fix_server_utf8_rows.py check: dong co byte >= 0x80 giai ma UTF-8 hop le ra chu that)
    enc = {}
    for f in FILES:
        raw = open(os.path.join(cfg, f), 'rb').read()
        try:
            raw.decode('gbk')
            ok = True
        except UnicodeDecodeError:
            ok = False
        utf8_rows = 0
        for line in raw.split(b'\n'):
            if max(line or b'\0') < 0x80:
                continue
            try:
                s = line.decode('utf-8')
            except UnicodeDecodeError:
                continue
            # "chu that": CJK hoac chu Viet co dau; GBK tinh co hop le UTF-8 ra Hy Lap/Kirin (犀牛 -> 'Ϭţ',
            # 驯鹿 -> 'ѱ¹') thi KHONG tinh — cung bo loc voi fix_server_utf8_rows.py
            real = sum(1 for ch in s if ('一' <= ch <= '鿿') or ('À' <= ch <= 'ɏ')
                       or ('Ạ' <= ch <= 'ỹ'))
            odd = sum(1 for ch in s if 'Ͱ' <= ch <= 'ԯ')
            if real >= 2 and odd == 0:
                utf8_rows += 1
        enc[f] = {'gbk': ok, 'crlf': raw.count(b'\n') == raw.count(b'\r\n'), 'utf8_rows': utf8_rows}
    M['encoding'] = enc
    return M


def verify(root):
    M = measure(root)
    rep = {'ok': True, 'checks': [], 'measure': M}

    def chk(name, ok, detail=''):
        rep['checks'].append({'name': name, 'ok': bool(ok), 'detail': detail})
        if not ok:
            rep['ok'] = False

    for f, e in M['encoding'].items():
        chk('GBK + CRLF + 0 dong UTF-8 %s' % f, e['gbk'] and e['crlf'] and e['utf8_rows'] == 0, str(e))
    chk('Exterior_Ride %d cot, co 速度125' % ER_COLS, M['cols'] == [ER_COLS] and M['has_125'], str(M['cols']))
    chk('Exterior_Ride ID tang dan, khong trung', M['ids_sorted_unique'])
    chk('297 dong CY o dung ID, dung model, dung ten', M['cy_rows_same'].startswith('297/') and not M['cy_rows_missing'],
        '%s thieu=%s lech=%s' % (M['cy_rows_same'], M['cy_rows_missing'], M['cy_rows_diff']))
    chk('0 dong (model < 1000) tro ngoai CharMount CY', M['model_not_cy_n'] == 0, str(M['model_not_cy']))
    chk('moi o impact co dong that, logic 14, dung bac, 骑乘ID == 模型索引',
        M['impact_cells'].startswith('0/') and M['impact_bad_n'] == 0,
        '%s; %s; loi=%s' % (M['impact_cells'], M['rides_model_ok'], M['impact_bad']))
    chk('khong dung impact id >= 65536', not M['impact_ids_ge_65536_used'], str(M['impact_ids_ge_65536_used']))
    chk('moi item thu cuoi (Type 41, Visual >= 0) co ride', not M['items_orphan_visuals'],
        '%s mo coi=%s' % (M['items_usable'], M['items_orphan_visuals']))
    chk('CharMount server = 353 dong CY, 53 dong bay dung dong', M['charmount_rows'] == 353 and M['charmount_fly_eq_cy'],
        'rows=%d fly=%d' % (M['charmount_rows'], M['charmount_fly']))
    chk('RideSeries 8 dong CY, moi ride id co that', M['rideseries_rows'] == 8 and not M['rideseries_bad_ids'],
        str(M['rideseries_bad_ids']))
    chk('RideCollection 8 dong CY, moi ride id co that', M['ridecollection_rows'] == 8 and not M['ridecollection_bad_ids'],
        str(M['ridecollection_bad_ids']))
    return rep


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('survey', 'plan', 'apply', 'verify'))
    ap.add_argument('--root', default=R)
    ap.add_argument('--out')
    ap.add_argument('--staging')
    a = ap.parse_args()
    if a.cmd == 'survey':
        rep = measure(a.root)
    elif a.cmd == 'plan':
        out = a.out or '/tmp/ride-axis'
        os.makedirs(out, exist_ok=True)
        plan = build_plan(a.root)
        write_staging(a.root, plan, out)
        rep = {'staging': out, 'summary': plan['summary'], 'notes': plan['notes']}
    elif a.cmd == 'apply':
        rep = apply(a.root, a.staging or '/tmp/ride-axis')
    else:
        rep = verify(a.root)
    print(json.dumps(rep, ensure_ascii=False, indent=1, default=str))
    return 0 if rep.get('ok', True) else 1


if __name__ == '__main__':
    sys.exit(main())
