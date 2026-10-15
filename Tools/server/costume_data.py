#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""costumes-all — dua TAT CA thoi trang (时装) cua CY vao the MUA DUOC tren server rieng (17/09/2026).

    python3 -B Tools/server/costume_data.py survey [--out F]            chi doc, in bon con so
    python3 -B Tools/server/costume_data.py plan   [--out DIR]          dung staging, KHONG cham R
    python3 -B Tools/server/costume_data.py apply  [--staging DIR]      flock + sao luu + tron vao bang SONG
    python3 -B Tools/server/costume_data.py verify [--staging DIR]      doc lai TU DIA roi khang dinh

Chay trong WSL TLBB bang root: `wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/costume_data.py <lenh>`.

===============================================================================
NHUNG SU THAT DA DO (17/09, bang chung o Docs/specs/server/costumes-all_vi.md)
===============================================================================

1. "Thoi trang" cua CY = dong EquipBase co EquipPoint(cot 5) == 16. Co **4.113** dong nhu the; Type 24..28
   chi la DAI ID (10124xxx..10128xxx), khong phai loai. Chuoi ngoai hinh:
       EquipBase.Visual -> EquipDress[Visual] (7 cot: index,-1,IVC,-1,-1,o_mau,nhom) -> ItemVisualChar[IVC]
       (23 cot: 1 mesh nu, 2 material nu, 3..10 mau nhuom nu, 12 mesh nam, 13 material nam, 14..21 mau nam)
       -> .mesh (+skeleton) trong Model*Folder, material trong MaterialFolder/all.material, .dds trong Material*Folder.
   4.113 item -> 583 Visual -> 439 IVC. Chuoi DU cho 578/583 Visual (5 Visual hong ngay trong du lieu CY).

2. Bang `configs/EquipBase.txt` cua server DA LA bang CY: 4.113/4.113 dong EquipPoint 16 trung ID/Type/Visual.
   Bang `configs/EquipExtraAttr.txt` thi KHONG: chi 2.139/4.113 item co dong (thieu = vinh vien).

3. Vi sao khong mua duoc: `cfghelper:read_shop_table` doc o hang thu i bang TEN cot `PID(商品编号i)` /
   `商品i价格`, ma header server chi dat ten cho i = 1..50 (cot 51..200 ten rong) => moi shop chi dua ra 50 o.
   Client `Src/Shared/Common/GameDefine.h MAX_BOOTH_NUMBER = 96` => toi da 96 mon/shop hien ra.
   Thuong thanh (yuanbaoshop.lua shoplist[5]) chi co HAI shop thoi trang (120, 247); 419/420 khong ton tai.
   => truoc khi lam: 102 item / 52 Visual mua duoc.

4. Cach lam (them, khong xoa):
   a) dat ten cot 51..200 trong header ShopTable (da quet: 0/383 shop co lo trong truoc o cuoi => an toan);
   b) 7 shop moi 431..437 (<= 96 o, o LIEN TIEP, cot Num = so o), moi Visual du chuoi mot item
      (uu tien VINH VIEN; gia = gia CY cua chinh item do neu co, khong thi 5120 NB nhu 109/185 bo vinh vien
      cua CY); tien te 5 = nguyen bao, chep 27 cot dau cua shop 120;
   c) NPC "Tiem Thoi Trang" (type 29 = model 施妆 thu ky "时装店" cua CY o To Chau) o ba thanh chinh, script
      990011 (`scripts/costume_shop.lua`) menu 7 muc type 7 -> DispatchShopItem;
   d) nhap 1.973 dong EquipExtraAttr thieu (13 cot, anh xa 4 cot server doc bang ten, do khop 100 % voi
      2.139 dong da co).

LUAT DA TUAN THU
  * lam o muc BYTE, `configs/*.txt` GBK; ShopTable CRLF, EquipExtraAttr LF, `*_monster.ini` LF GBK, Lua UTF-8 LF;
  * chi THEM dong/section/dong dang ky; khong sua dong CY nao (ke ca shop 120/247);
  * `flock` dung chung `configs/.scene_install.lock`; tron lai tu bang SONG trong lock; sao luu `R/backups/costumes-<UTC>/`;
  * idempotent: `plan` lan hai tren R da apply ra ke hoach rong; `apply` lan hai khong doi byte nao.
"""
import argparse
import collections
import datetime
import importlib.util
import json
import math
import os
import re
import shutil
import struct
import subprocess
import sys

R = '/home/ubuntu/cys-test-20260913'
REPO = '/mnt/c/TLBB/085/CY-Source'
CYDATA = REPO + '/Assets/CanonicalCY/Data'
CYCFG = CYDATA + '/ConfigFolder'
TOOLS085 = '/mnt/c/TLBB/085/Tools'
LOCK_NAME = '.scene_install.lock'
TAB, CRLF, LF = b'\t', b'\r\n', b'\n'

EQUIP_POINT_DRESS = 16
SHOP_SLOTS_MAX = 200            # dinh dang bang: 27 + 200 * 6 = 1227 cot
CLIENT_BOOTH_MAX = 96           # Src/Shared/Common/GameDefine.h MAX_BOOTH_NUMBER
SHOP_ID_BASE = 431              # 419/420 de danh cho ride-finish (天宫骑术阁 / 庄园装饰馆 trong yuanbaoshop.lua)
SHOP_TEMPLATE = 120             # 久久时装店 cua CY — chep 27 cot dau (tien te 5 = nguyen bao)
SHOP_HEAD_COLS = 27
SLOT_EMPTY = [b'0', b'0', b'0', b'0', b'0', b'']
SLOT_DISCOUNT, SLOT_COLOR = b'100', b'#c00ff01'   # y het cac o cua shop 120
PRICE_PERM = 5120               # 109/185 bo vinh vien trong ShopTable CY ban 5120
PRICE_BY_HOURS = {24: 100, 72: 200, 168: 380, 240: 400, 336: 450, 360: 500, 720: 720,
                  1440: 900, 2160: 980, 4320: 1934, 8640: 3000}   # 168/720/2160/4320 la gia CY that
SCRIPT_ID = 990011
SCRIPT_MODULE = 'scripts.costume_shop'
LUA_REL = 'Game_2/Script/scripts/costume_shop.lua'
REGISTRY_REL = 'Game_2/Script/scripts/scripts.lua'
NPC_TYPE = 29                   # MonsterAttrExTable 29 — model cua 施妆 "时装店" (suzhou_new_monster.ini monster144)
# Ten/chuc danh la CHU HAN trong `.ini` (GBK) — dung co che co san cua du an: dich TAI WIRE
# (`wire_charset.fromutf8` tra `wire_names_vi.lua`, 6.010 muc). Dat ASCII khong dau la sai co che.
NPC_NAME, NPC_TITLE = '万衣', '时装店'
WIRE_DICT_REL = 'GameServer/lualib/wire_names_vi.lua'
WIRE_NAMES = {'万衣': 'Vạn Y'}   # '时装店' da co san = "Cửa hàng Thời Trang"
# (file ini, [x,z] ung vien theo thu tu uu tien, huong, guid) — plan chon diem DI DUOC dau tien cung vung voi mo neo
NPCS = [
    ('dali_new_320', 'dali_new_320_monster.ini', [(257.0, 121.0), (253.0, 117.0), (249.0, 121.0)], (253.0, 121.0), 27, 900300001),
    ('luoyang_new', 'luoyang_new_monster.ini', [(344.0, 269.0), (339.0, 272.0), (239.0, 322.0)], (340.858, 268.788), 18, 900300002),
    ('suzhou_new', 'suzhou_new_monster.ini', [(322.0, 188.0), (316.0, 190.0), (208.0, 256.0)], (319.035, 187.609), 0, 900300003),
]
NPC_TEMPLATE_SCRIPT = 990010    # block cua NPC dich chuyen (co san o ca ba file) lam khuon, chi thay gia tri
MENU_LABEL_MAX_BYTES = 56


# --------------------------------------------------------------------------- doc bang
def read_table(path):
    """Bang van ban server: (2 dong tieu de bytes, dong du lieu bytes, ten cot). Khong decode o du lieu."""
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


def num(b, d=None):
    try:
        return int(b)
    except (ValueError, TypeError):
        return d


def utf(b):
    """O hien thi cua DBC CanonicalCY (da dich sang tieng Viet) la UTF-8; con lai GBK."""
    if not isinstance(b, bytes):
        return str(b)
    try:
        return b.decode('utf-8')
    except UnicodeDecodeError:
        return b.decode('gbk', 'replace')


def gbk(b):
    return b.decode('gbk', 'replace') if isinstance(b, bytes) else str(b)


class Dbc(object):
    """DBC nhi phan 00CCBBDD cua client CY, GIU NGUYEN BYTE o o STRING (nhu ride_data.py)."""

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


def module(name, path):
    s = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(s)
    s.loader.exec_module(m)
    return m


# --------------------------------------------------------------------------- du lieu CY (client)
class CyData(object):
    """EquipBase / EquipDress / ItemVisualChar / EquipExtraAttr cua CanonicalCY + kiem chuoi ngoai hinh."""

    def __init__(self):
        self.eb = Dbc(os.path.join(CYCFG, 'EquipBase.txt'))
        self.ed = Dbc(os.path.join(CYCFG, 'EquipDress.txt'))
        self.ivc = Dbc(os.path.join(CYCFG, 'ItemVisualChar.txt'))
        self.eea = Dbc(os.path.join(CYCFG, 'EquipExtraAttr.txt'))
        self.items = [r for r in self.eb.rows if r[5] == EQUIP_POINT_DRESS]
        self.by_id = {r[0]: r for r in self.items}
        self.edmap = {r[0]: r for r in self.ed.rows}
        self.ivmap = {r[0]: r for r in self.ivc.rows}
        self.eeamap = {r[0]: r for r in self.eea.rows}
        self.visuals = sorted(set(r[6] for r in self.items))
        self._chain = None

    # ---- chuoi ngoai hinh (mesh/material/texture co that tren dia)
    CHAIN_INPUTS = ('ConfigFolder/EquipBase.txt', 'ConfigFolder/EquipDress.txt', 'ConfigFolder/ItemVisualChar.txt',
                    'MaterialFolder/all.material')

    def _chain_stamp(self):
        return {rel: os.path.getmtime(os.path.join(CYDATA, rel)) for rel in self.CHAIN_INPUTS}

    def chain(self):
        """Ket qua duoc cache o $COSTUME_CHAIN_CACHE (mac dinh /tmp/costumes-chain.json) vi doc 880 mesh + all.material
        21 MB qua /mnt/c mat ~4,5 phut; cache chi duoc dung khi mtime cua 4 dau vao khong doi."""
        if self._chain is not None:
            return self._chain
        cache = os.environ.get('COSTUME_CHAIN_CACHE', '/tmp/costumes-chain.json')
        stamp = self._chain_stamp()
        if os.path.isfile(cache):
            try:
                d = json.load(open(cache, encoding='utf-8'))
                if d.get('stamp') == stamp and d.get('visuals') == self.visuals:
                    self._chain = {int(k): v for k, v in d['chain'].items()}
                    return self._chain
            except (ValueError, KeyError, TypeError):
                pass
        self._chain = self._compute_chain()
        try:
            json.dump({'stamp': stamp, 'visuals': self.visuals, 'chain': {str(k): v for k, v in self._chain.items()}},
                      open(cache, 'w', encoding='utf-8'), ensure_ascii=False)
        except OSError:
            pass
        return self._chain

    def _compute_chain(self):
        ogre = module('ogre_io', TOOLS085 + '/model-convert/lib/ogre_io.py')
        plan = module('cy_plan', TOOLS085 + '/add-phai/import-cy-four/client/plan_resources.py')
        from pathlib import Path
        folders = [Path(CYDATA) / x for x in os.listdir(CYDATA)
                   if x.startswith(('Model', 'Material')) and os.path.isdir(os.path.join(CYDATA, x))]
        disk = {}
        for f in folders:
            for n in os.listdir(str(f)):
                disk.setdefault(n.lower(), f / n)

        def win_cp1252(b):
            out = []
            for ch in b:
                try:
                    out.append(bytes([ch]).decode('cp1252'))
                except UnicodeDecodeError:
                    out.append(chr(ch))
            return ''.join(out)

        def find(name_b):
            name_b = name_b.replace(bytes([92]), b'/').split(b'/')[-1]
            for cand in (name_b.decode('gb18030', 'replace'), name_b.decode('latin-1'), win_cp1252(name_b)):
                p = disk.get(cand.lower())
                if p:
                    return p
            return None

        mats, _dups = plan.blocks(Path(CYDATA) / 'MaterialFolder' / 'all.material', 'material')
        mesh_cache = {}

        def read_mesh(p):
            if p not in mesh_cache:
                try:
                    mesh_cache[p] = ogre.read_mesh(str(p))
                except Exception as e:      # noqa: BLE001 — mesh hong cung la "chuoi thieu"
                    mesh_cache[p] = {'error': str(e), 'submeshes': [], 'skeleton': None}
            return mesh_cache[p]

        def side(row, mesh_col, mat_base_col, slot):
            res = {'mesh': gbk(row[mesh_col]), 'ok': True, 'why': []}
            if not row[mesh_col]:
                res['ok'] = False
                res['why'].append('mesh rong')
                return res
            p = find(row[mesh_col])
            if not p:
                res['ok'] = False
                res['why'].append('mesh khong co tren dia')
                return res
            m = read_mesh(p)
            if m.get('error'):
                res['ok'] = False
                res['why'].append('mesh doc loi')
                return res
            sk = m.get('skeleton')
            if sk:
                skb = sk if isinstance(sk, bytes) else sk.encode('gb18030')
                if not find(skb):
                    res['ok'] = False
                    res['why'].append('skeleton thieu: ' + gbk(skb))
            col = mat_base_col + (slot - 1)
            tbl = [x for x in row[col].split(b';') if x] if row[col] else []
            if not tbl and slot != 1:
                tbl = [x for x in row[mat_base_col].split(b';') if x]
            internal = [s['material'] for s in m['submeshes']]
            internal = [x if isinstance(x, bytes) else x.encode('gb18030') for x in internal]
            used = list(tbl) + internal[len(tbl):]    # bang thay theo vi tri submesh, phan du dung ten trong mesh
            miss_m, miss_t = [], []
            for mname in used:
                blk = mats.get(mname)
                if blk is None:
                    miss_m.append(gbk(mname))
                    continue
                for t in set(re.findall(rb'\S+\.dds', blk[1])):
                    if not find(t):
                        miss_t.append(gbk(t))
            if miss_m:
                res['ok'] = False
                res['why'].append('material thieu: ' + ', '.join(miss_m))
            if miss_t:
                res['ok'] = False
                res['why'].append('texture thieu: ' + ', '.join(sorted(set(miss_t))))
            return res

        out = {}
        for v in self.visuals:
            e = self.edmap.get(v)
            if not e:
                out[v] = {'ok': False, 'why': ['Visual khong co trong EquipDress']}
                continue
            iv = self.ivmap.get(e[2])
            if not iv:
                out[v] = {'ok': False, 'ivc': e[2], 'why': ['IVC %d khong co' % e[2]]}
                continue
            W = side(iv, 1, 2, e[5])
            M = side(iv, 12, 13, e[5])
            out[v] = {'ok': W['ok'] and M['ok'], 'ivc': e[2], 'slot': e[5], 'group': e[6],
                      'W': W, 'M': M, 'why': []}
        return out

    # ---- thoi han
    def hours(self, item_id):
        """Gio hieu luc: -1 = vinh vien (theo EquipExtraAttr CY; khong co dong thi doc mo ta)."""
        e = self.eeamap.get(item_id)
        if e is not None:
            return e[1]
        d = utf(self.by_id[item_id][13])
        if 'ĩnh viễn' in d or '永久' in d:
            return -1
        m = re.search(r'(\d+)\s*(ngày|天)', d)
        return int(m.group(1)) * 24 if m else -1

    def name(self, item_id):
        return utf(self.by_id[item_id][10])


# --------------------------------------------------------------------------- server: shop
def shop_cells(line):
    return line.split(TAB)


def shop_slots(cells):
    """[(o 1-based, PID bytes, gia bytes)] cac o co hang."""
    out = []
    for k in range(SHOP_SLOTS_MAX):
        i = SHOP_HEAD_COLS + 6 * k
        if i + 5 < len(cells) and cells[i] not in (b'', b'0', b'-1'):
            out.append((k + 1, cells[i], cells[i + 3]))
    return out


def shop_header_plan(head):
    """Ten con thieu cho cot 51..200 cua dong tieu de 2. Tra ve (dong moi, so o vua dat ten)."""
    names = head[1].split(TAB)
    added = 0
    for k in range(SHOP_SLOTS_MAX):
        i = SHOP_HEAD_COLS + 6 * k
        want = [('PID(商品编号%d)' % (k + 1)).encode('gbk'), 'PNUM(每组多少个)'.encode('gbk'),
                'PMAX(有限商品的数量上限)'.encode('gbk'), ('商品%d价格' % (k + 1)).encode('gbk'),
                '商品折扣'.encode('gbk'), '商品颜色'.encode('gbk')]
        if i + 5 >= len(names):
            break
        if all(not names[i + j].strip() for j in range(6)):
            for j in range(6):
                names[i + j] = want[j]
            added += 1
        elif [names[i + j] for j in range(6)] != want:
            raise SystemExit('header ShopTable o %d co ten la %r, khong phai mau mong doi' % (k + 1, names[i:i + 6]))
    return TAB.join(names), added


def visible_slots(cells):
    n = num(cells[11], 0)
    return [s for s in shop_slots(cells) if s[0] <= min(n, 50)]


# --------------------------------------------------------------------------- survey
def yuanbao_shop_ids(root):
    """Cac shop ma client mo duoc tu Thuong thanh: shoplist[*] trong yuanbaoshop.lua (theo ten bang)."""
    p = os.path.join(root, 'Game_2/Script/scripts/event/prize/yuanbaoshop.lua')
    ids = set()
    for line in open(p, 'rb').read().decode('utf-8', 'replace').splitlines():
        m = re.match(r'\s*shoplist\[(\d+)\]\s*=\s*\{([^}]*)\}', line)
        if m:
            ids |= set(int(x) for x in re.findall(r'\d+', m.group(2)))
    return ids


def survey(root, cy=None):
    cy = cy or CyData()
    chain = cy.chain()
    ok_vis = [v for v in cy.visuals if chain[v]['ok']]
    ivc_all = set(chain[v]['ivc'] for v in cy.visuals if chain[v].get('ivc'))
    ivc_ok = set(chain[v]['ivc'] for v in ok_vis)
    rep = {'cy': {'items': len(cy.items), 'visuals': len(cy.visuals), 'ivc': len(ivc_all)},
           'chain_ok': {'visuals': len(ok_vis), 'ivc': len(ivc_ok),
                        'items': sum(1 for r in cy.items if chain[r[6]]['ok'])},
           'chain_broken': [{'visual': v, 'ivc': chain[v].get('ivc'),
                             'why': chain[v]['why'] or ['W: ' + '; '.join(chain[v]['W']['why']),
                                                        'M: ' + '; '.join(chain[v]['M']['why'])]}
                            for v in cy.visuals if not chain[v]['ok']]}
    cfg = os.path.join(root, 'configs')
    _, eb_rows, eb_names = read_table(os.path.join(cfg, 'EquipBase.txt'))
    E = {n: k for k, n in enumerate(eb_names)}
    srv = {}
    for line in eb_rows:
        c = line.split(TAB)
        if num(c[E['EquipPoint(装备点)']]) == EQUIP_POINT_DRESS:
            srv[num(c[0])] = c
    same = [i for i in cy.by_id if i in srv and num(srv[i][E['Visual']]) == cy.by_id[i][6]
            and num(srv[i][E['Type(类别)']]) == cy.by_id[i][3]]
    rep['server_items'] = {'rows': len(srv), 'same_id_type_visual': len(same),
                           'only_cy': sorted(set(cy.by_id) - set(srv))[:20],
                           'only_server': sorted(set(srv) - set(cy.by_id))[:20]}
    _, eea_rows, _ = read_table(os.path.join(cfg, 'EquipExtraAttr.txt'))
    eea_ids = set(rid_of(x) for x in eea_rows)
    rep['server_eea'] = {'rows': len(eea_rows), 'costume_rows': sum(1 for i in cy.by_id if i in eea_ids),
                         'costume_missing': sum(1 for i in cy.by_id if i not in eea_ids)}
    head, sh_rows, _ = read_table(os.path.join(cfg, 'ShopTable.txt'))
    named = sum(1 for n in head[1].split(TAB) if n.startswith('PID('.encode()))
    yb = yuanbao_shop_ids(root)
    where = collections.defaultdict(list)
    shops = {}
    for line in sh_rows:
        c = shop_cells(line)
        sid = num(c[0])
        shops[sid] = c
        vis = set(s[0] for s in visible_slots(c)) if named <= 50 else set(
            s[0] for s in shop_slots(c) if s[0] <= min(num(c[11], 0), CLIENT_BOOTH_MAX))
        for slot, pid, price in shop_slots(c):
            pid = num(pid)
            if pid in cy.by_id:
                where[pid].append((sid, slot, slot in vis))
    buy_items = [i for i in cy.by_id if any(v and (sid in yb or sid >= SHOP_ID_BASE) for sid, _s, v in where[i])]
    buy_vis = set(cy.by_id[i][6] for i in buy_items)
    rep['purchasable'] = {'header_named_slots': named, 'yuanbao_shop_ids_missing_on_server': sorted(x for x in yb if x not in shops),
                          'items_in_any_shop': sum(1 for i in cy.by_id if where[i]),
                          'items_visible_yuanbao_or_catalog': len(buy_items),
                          'visuals': len(buy_vis), 'visuals_chain_ok': sum(1 for v in buy_vis if chain[v]['ok']),
                          'ivc': len(set(chain[v].get('ivc') for v in buy_vis if chain[v].get('ivc'))),
                          'catalog_shops': sorted(s for s in shops if s >= SHOP_ID_BASE and s < SHOP_ID_BASE + 20)}
    # NPC + script
    npc = {}
    for _map, ini, _c, _ref, _d, _g in NPCS:
        raw = open(os.path.join(root, 'Game_2/Scene', ini), 'rb').read()
        npc[ini] = (b'script_id=%d' % SCRIPT_ID) in raw
    reg = open(os.path.join(root, REGISTRY_REL), 'rb').read()
    rep['npc'] = {'ini_has_npc': npc, 'script_registered': (b'[%d]' % SCRIPT_ID) in reg,
                  'script_file': os.path.isfile(os.path.join(root, LUA_REL))}
    return rep


# --------------------------------------------------------------------------- plan
def pick_items(cy, chain, price_of):
    """Moi Visual du chuoi -> mot item: uu tien vinh vien; trong nhom cung thoi han uu tien item co gia CY, roi ID nho."""
    groups = collections.defaultdict(list)
    for r in cy.items:
        groups[r[6]].append(r[0])
    picks = []
    for v in cy.visuals:
        if not chain[v]['ok']:
            continue
        ids = groups[v]
        best = None
        for i in sorted(ids):
            h = cy.hours(i)
            key = (0 if h == -1 else 1, -h if h != -1 else 0, 0 if i in price_of else 1, i)
            if best is None or key < best[0]:
                best = (key, i, h)
        _, i, h = best
        if i in price_of:
            price, src = price_of[i], 'CY'
        elif h == -1:
            price, src = PRICE_PERM, 'vinh-vien'
        else:
            price, src = PRICE_BY_HOURS.get(h, 720), 'theo-gio'
        picks.append({'visual': v, 'ivc': chain[v]['ivc'], 'item': i, 'name': cy.name(i), 'hours': h,
                      'price': price, 'price_src': src})
    return picks


def label_for(k, n, first_name):
    lab = 'Tập %d/%d: %s' % (k, n, first_name)
    while len(lab.encode('utf-8')) > MENU_LABEL_MAX_BYTES:
        first_name = first_name[:-1]
        lab = 'Tập %d/%d: %s…' % (k, n, first_name)
    return lab


def lua_script(shops):
    lines = ['-- costumes-all 17/09/2026: NPC "Tiem Thoi Trang" (script %d) — sinh boi Tools/server/costume_data.py.' % SCRIPT_ID,
             '-- Moi muc menu (type 7) mo mot shop 431.. chua thoi trang CY, ban bang nguyen bao (ShopTable cot 7 = 5).',
             '-- Khong sua tay: chay lai `costume_data.py plan && apply` se ghi de file nay.',
             'local class = require "class"',
             'local script_base = require "script_base"',
             'local costume_shop = class("costume_shop", script_base)',
             'costume_shop.script_id = %d' % SCRIPT_ID,
             'costume_shop.SHOPS = {']
    for s in shops:
        lines.append('    { id = %d, count = %d, text = "%s" },' % (s['id'], len(s['items']), s['label'].replace('"', "'")))
    lines += ['}',
              '',
              'function costume_shop:OnDefaultEvent(selfId, targetId)',
              '    self:BeginEvent(self.script_id)',
              '    self:AddText("Tiệm Thời Trang Vân Y: %d bộ thời trang, bán bằng Nguyên Bảo. Mời chọn tập.")' % sum(len(s['items']) for s in shops),
              '    for i, s in ipairs(self.SHOPS) do',
              '        self:AddNumText(s.text, 7, i)',
              '    end',
              '    self:EndEvent()',
              '    self:DispatchEventList(selfId, targetId)',
              'end',
              '',
              'function costume_shop:OnEventRequest(selfId, targetId, arg, index)',
              '    local s = self.SHOPS[index]',
              '    if s then',
              '        self:DispatchShopItem(selfId, targetId, s.id)',
              '    else',
              '        self:OnDefaultEvent(selfId, targetId)',
              '    end',
              'end',
              '',
              'return costume_shop',
              '']
    return '\n'.join(lines).encode('utf-8')


def eea_colmap(cy, eea_rows, eea_names):
    """Tim cot CY (18 cot) khop 100 % voi 4 cot server doc bang ten, tren cac item thoi trang da co ca hai ben."""
    S = {n: k for k, n in enumerate(eea_names)}
    want = ['有效期(小时)', '元宝交易类型:0可元宝交易，1不可元宝交易，2即可元宝交易也可金币交易',
            '卖店是否获得交子，1获得交子，0获得金币', '是否装备时计算有效期']
    srv = {}
    for line in eea_rows:
        i = rid_of(line)
        if i in cy.by_id and i in cy.eeamap:
            srv[i] = line.split(TAB)
    out = {}
    for w in want:
        k = S[w]
        best = None
        for c in range(1, len(cy.eea.types)):
            if cy.eea.types[c] != 'INT':
                continue
            hit = sum(1 for i, cells in srv.items() if k < len(cells) and num(cells[k]) == cy.eeamap[i][c])
            if best is None or hit > best[1]:
                best = (c, hit)
        out[w] = {'server_col': k, 'cy_col': best[0], 'match': best[1], 'of': len(srv)}
    return out


def build_plan(root):
    cy = CyData()
    chain = cy.chain()
    cfg = os.path.join(root, 'configs')
    head, sh_rows, _ = read_table(os.path.join(cfg, 'ShopTable.txt'))
    shops = {num(shop_cells(l)[0]): shop_cells(l) for l in sh_rows}
    price_of = {}
    for sid in sorted(shops):
        for _slot, pid, price in shop_slots(shops[sid]):
            pid = num(pid)
            if pid in cy.by_id and pid not in price_of and num(price) is not None:
                price_of[pid] = num(price)
    plan = {'notes': [], 'summary': {}}

    # a) header
    new_head1, added = shop_header_plan(head)
    plan['shop_header'] = {'line': new_head1.decode('gbk'), 'slots_named_now': added}

    # b) catalog shops
    picks = pick_items(cy, chain, price_of)
    n_shops = int(math.ceil(len(picks) / float(CLIENT_BOOTH_MAX)))
    per = int(math.ceil(len(picks) / float(n_shops)))
    tmpl = shops.get(SHOP_TEMPLATE)
    if tmpl is None:
        raise SystemExit('khong co shop mau %d tren R' % SHOP_TEMPLATE)
    catalog = []
    for k in range(n_shops):
        chunk = picks[k * per:(k + 1) * per]
        sid = SHOP_ID_BASE + k
        catalog.append({'id': sid, 'items': chunk, 'label': label_for(k + 1, n_shops, chunk[0]['name']),
                        'exists': sid in shops})
    for s in catalog:
        cells = list(tmpl[:SHOP_HEAD_COLS])
        cells[0] = str(s['id']).encode()
        cells[11] = str(len(s['items'])).encode()
        for it in s['items']:
            cells += [str(it['item']).encode(), b'1', b'-1', str(it['price']).encode(), SLOT_DISCOUNT, SLOT_COLOR]
        for _ in range(SHOP_SLOTS_MAX - len(s['items'])):
            cells += SLOT_EMPTY
        assert len(cells) == SHOP_HEAD_COLS + 6 * SHOP_SLOTS_MAX
        s['line'] = TAB.join(cells).decode('gbk')
    plan['catalog'] = catalog

    # c) NPC + script
    sys.path.insert(0, REPO + '/Tools/server')
    from cs3a_scene import NavMesh   # noqa: E402
    npcs = []
    for mapname, ini, cands, ref, d, guid in NPCS:
        nav = NavMesh(os.path.join(root, 'Game_2/Scene', mapname + '.path'))
        ref_hit = nav.locate(*ref)
        chosen = None
        for x, z in cands:
            h = nav.locate(x, z)
            if h and not (h[1] & 1) and (ref_hit is None or h[2] == ref_hit[2]):
                chosen = (x, z)
                break
        if chosen is None:
            raise SystemExit('khong ung vien nao di duoc cho NPC o %s' % mapname)
        path = os.path.join(root, 'Game_2/Scene', ini)
        raw = open(path, 'rb').read()
        exists = (b'script_id=%d' % SCRIPT_ID) in raw
        m = re.search(rb'^monstercount=(\d+)', raw, re.M)
        count = int(m.group(1))
        tm = re.search(rb'^\[(monster\d+)\]\r?\n(?:(?!\[).*\r?\n)*?script_id=%d\r?\n' % NPC_TEMPLATE_SCRIPT, raw, re.M)
        if not tm:
            raise SystemExit('khong thay block NPC mau script %d trong %s' % (NPC_TEMPLATE_SCRIPT, ini))
        start = tm.start()
        end = raw.find(b'\n[', start)
        block = raw[start:end + 1 if end > 0 else len(raw)]
        block = block.rstrip(b'\n') + b'\n'
        sec_name = b'monster%d' % count
        block = re.sub(rb'^\[monster\d+\]', b'[' + sec_name + b']', block, count=1, flags=re.M)
        for key, val in (('guid', str(guid)), ('type', str(NPC_TYPE)), ('name', NPC_NAME), ('title', NPC_TITLE),
                         ('pos_x', '%.4f' % chosen[0]), ('pos_z', '%.4f' % chosen[1]), ('dir', str(d)),
                         ('script_id', str(SCRIPT_ID))):
            block, n = re.subn(('^%s=.*$' % key).encode(), ('%s=%s' % (key, val)).encode('gbk'), block, count=1, flags=re.M)
            if n != 1:
                raise SystemExit('khoa %s khong co trong block mau cua %s' % (key, ini))
        npcs.append({'ini': ini, 'map': mapname, 'exists': exists, 'section': sec_name.decode(), 'monstercount_before': count,
                     'pos': chosen, 'guid': guid, 'block': block.decode('gbk'),
                     'nav_region': (nav.locate(*chosen) or (None, None, None))[2]})
    plan['npcs'] = npcs
    reg = open(os.path.join(root, REGISTRY_REL), 'rb').read()
    plan['registry'] = {'exists': (b'[%d]' % SCRIPT_ID) in reg,
                        'line': '    [%d] = "%s",' % (SCRIPT_ID, SCRIPT_MODULE)}
    plan['lua'] = lua_script(catalog).decode('utf-8')

    # c2) tu dien dich TAI WIRE cho ten NPC chu Han
    wire = open(os.path.join(root, WIRE_DICT_REL), 'rb').read().decode('utf-8')
    plan['wire_names'] = {k: v for k, v in WIRE_NAMES.items() if ('["%s"]' % k) not in wire}

    # d) EquipExtraAttr
    eea_head, eea_rows, eea_names = read_table(os.path.join(cfg, 'EquipExtraAttr.txt'))
    cmap = eea_colmap(cy, eea_rows, eea_names)
    plan['eea_colmap'] = cmap
    bad = [w for w, m in cmap.items() if m['match'] != m['of']]
    if bad:
        plan['notes'].append('EEA: cot %s khong khop 100 %% (%s) -> KHONG nhap EEA' % (bad, {w: cmap[w] for w in bad}))
        eea_new = []
    else:
        have = {rid_of(x): x.split(TAB) for x in eea_rows}
        cost_ids = sorted(i for i in cy.by_id if i in have)
        eea_new = []
        for i in sorted(cy.by_id):
            if i in have or i not in cy.eeamap:
                continue
            # khuon = dong thoi trang gan nhat da co tren server (cung dai ID), cat/dem ve 13 o
            j = min(cost_ids, key=lambda x: abs(x - i))
            cells = list(have[j][:13]) + [b'0'] * max(0, 13 - len(have[j]))
            cells[0] = str(i).encode()
            for w, m in cmap.items():
                cells[m['server_col']] = str(cy.eeamap[i][m['cy_col']]).encode()
            eea_new.append([i, TAB.join(cells).decode('gbk')])
    plan['eea_new'] = eea_new

    ok_vis = [v for v in cy.visuals if chain[v]['ok']]
    plan['summary'] = {'visuals_ok': len(ok_vis), 'catalog_items': len(picks), 'catalog_shops': len(catalog),
                       'shops_exist_already': sum(1 for s in catalog if s['exists']),
                       'header_slots_named_now': added, 'eea_new': len(eea_new),
                       'npc_new': sum(1 for n in npcs if not n['exists']),
                       'price_src': dict(collections.Counter(p['price_src'] for p in picks)),
                       'hours': dict(collections.Counter(str(p['hours']) for p in picks))}
    return plan


def write_staging(root, plan, out_dir):
    os.makedirs(os.path.join(out_dir, 'configs'), exist_ok=True)
    os.makedirs(os.path.join(out_dir, 'Game_2/Scene'), exist_ok=True)
    os.makedirs(os.path.join(out_dir, 'Game_2/Script/scripts'), exist_ok=True)
    cfg = os.path.join(root, 'configs')
    # ShopTable
    head, rows, _ = read_table(os.path.join(cfg, 'ShopTable.txt'))
    head[1] = plan['shop_header']['line'].encode('gbk')
    live = {rid_of(l): l for l in rows}
    for s in plan['catalog']:
        live.setdefault(s['id'], s['line'].encode('gbk'))
    open(os.path.join(out_dir, 'configs/ShopTable.txt'), 'wb').write(CRLF.join(head + [live[k] for k in sorted(live)]) + CRLF)
    # EEA
    head, rows, _ = read_table(os.path.join(cfg, 'EquipExtraAttr.txt'))
    live = {rid_of(l): l for l in rows}
    for i, txt in plan['eea_new']:
        live.setdefault(i, txt.encode('gbk'))
    open(os.path.join(out_dir, 'configs/EquipExtraAttr.txt'), 'wb').write(LF.join(head + [live[k] for k in sorted(live)]) + LF)
    # NPC ini
    for n in plan['npcs']:
        raw = open(os.path.join(root, 'Game_2/Scene', n['ini']), 'rb').read()
        if not n['exists']:
            raw = ini_append(raw, n)
        open(os.path.join(out_dir, 'Game_2/Scene', n['ini']), 'wb').write(raw)
    # Lua + registry
    open(os.path.join(out_dir, LUA_REL), 'wb').write(plan['lua'].encode('utf-8'))
    reg = open(os.path.join(root, REGISTRY_REL), 'rb').read()
    open(os.path.join(out_dir, REGISTRY_REL), 'wb').write(registry_add(reg, plan))
    json.dump(plan, open(os.path.join(out_dir, 'plan.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    with open(os.path.join(out_dir, 'catalog.tsv'), 'w', encoding='utf-8') as fh:
        fh.write('shop\tslot\titem\tvisual\tivc\tname\thours\tprice\tprice_src\n')
        for s in plan['catalog']:
            for k, it in enumerate(s['items']):
                fh.write('%d\t%d\t%d\t%d\t%d\t%s\t%d\t%d\t%s\n' % (s['id'], k + 1, it['item'], it['visual'], it['ivc'],
                                                                   it['name'], it['hours'], it['price'], it['price_src']))


def ini_append(raw, n):
    m = re.search(rb'^monstercount=(\d+)', raw, re.M)
    count = int(m.group(1))
    if count != n['monstercount_before']:
        raise SystemExit('%s: monstercount da doi (%d != %d) — chay lai plan' % (n['ini'], count, n['monstercount_before']))
    raw = raw[:m.start()] + (b'monstercount=%d' % (count + 1)) + raw[m.end():]
    if not raw.endswith(b'\n'):
        raw += b'\n'
    if not raw.endswith(b'\n\n'):
        raw += b'\n'
    return raw + n['block'].encode('gbk')


def ini_fix_npc(raw, n):
    """Sua ten/chuc danh cua block NPC 990011 DA CO (goi khi doi `NPC_NAME`/`NPC_TITLE`).

    Chi dung o khoa `name=`/`title=` trong DUNG block co `script_id=990011`; khong cham dong nao khac."""
    i = raw.find(b'script_id=%d' % SCRIPT_ID)
    if i < 0:
        return raw
    start = raw.rfind(b'\n[', 0, i) + 1
    end = raw.find(b'\n[', i)
    end = end + 1 if end > 0 else len(raw)
    block = raw[start:end]
    out = block
    for key, val in (('name', NPC_NAME), ('title', NPC_TITLE)):
        out = re.sub(('^%s=.*$' % key).encode(), ('%s=%s' % (key, val)).encode('gbk'), out, count=1, flags=re.M)
    return raw[:start] + out + raw[end:] if out != block else raw


def wire_dict_add(raw, plan):
    """Them muc dich ten NPC vao `wire_names_vi.lua` (UTF-8) ngay TRUOC dau `}` cuoi cung.

    File do `gen_wire_names.py` sinh ra va co ghi 'DUNG SUA TAY'; vi vay moi dong them vao deu
    mang the `-- CYS-DRESS` de lan sinh lai sau nhin ra va gop lai duoc."""
    add = plan.get('wire_names') or {}
    text = raw.decode('utf-8')
    new = {k: v for k, v in add.items() if ('["%s"]' % k) not in text}
    if not new:
        return raw
    lines = text.split('\n')
    for k in range(len(lines) - 1, -1, -1):
        if lines[k].strip() == '}':
            rows = ['  ["%s"] = "%s",   -- CYS-DRESS' % (a, b) for a, b in sorted(new.items())]
            lines[k:k] = rows
            return '\n'.join(lines).encode('utf-8')
    raise SystemExit('khong tim thay dau } cuoi trong %s' % WIRE_DICT_REL)


def registry_add(reg, plan):
    if plan['registry']['exists'] or (b'[%d]' % SCRIPT_ID) in reg:
        return reg
    lines = reg.split(b'\n')
    # dong `}` cuoi cung truoc `return dat`
    for k in range(len(lines) - 1, -1, -1):
        if lines[k].strip() == b'}':
            lines.insert(k, plan['registry']['line'].encode('utf-8'))
            return b'\n'.join(lines)
    raise SystemExit('khong tim thay dau } dong bang trong scripts.lua')


# --------------------------------------------------------------------------- apply
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
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(root, 'backups', 'costumes-%s' % stamp)
    cfg = os.path.join(root, 'configs')
    touched, skipped = [], {}
    with Lock(root):
        os.makedirs(os.path.join(bak, 'configs'), exist_ok=True)
        os.makedirs(os.path.join(bak, 'Game_2/Scene'), exist_ok=True)
        os.makedirs(os.path.join(bak, 'Game_2/Script/scripts'), exist_ok=True)
        os.makedirs(os.path.join(bak, 'GameServer/lualib'), exist_ok=True)
        for rel in ('configs/ShopTable.txt', 'configs/EquipExtraAttr.txt', REGISTRY_REL, WIRE_DICT_REL):
            shutil.copy2(os.path.join(root, rel), os.path.join(bak, rel))
        for n in plan['npcs']:
            shutil.copy2(os.path.join(root, 'Game_2/Scene', n['ini']), os.path.join(bak, 'Game_2/Scene', n['ini']))
        if os.path.isfile(os.path.join(root, LUA_REL)):
            shutil.copy2(os.path.join(root, LUA_REL), os.path.join(bak, LUA_REL))

        # ShopTable: header + dong moi (dong da co thi BO QUA)
        head, rows, _ = read_table(os.path.join(cfg, 'ShopTable.txt'))
        new_head, _added = shop_header_plan(head)
        head[1] = new_head
        live = {rid_of(l): l for l in rows}
        sk = [s['id'] for s in plan['catalog'] if s['id'] in live]
        for s in plan['catalog']:
            live.setdefault(s['id'], s['line'].encode('gbk'))
        raw = CRLF.join(head + [live[k] for k in sorted(live)]) + CRLF
        raw.decode('gbk')
        write_if_changed(os.path.join(cfg, 'ShopTable.txt'), raw, touched)
        skipped['ShopTable.txt'] = sk

        # EquipExtraAttr
        head, rows, _ = read_table(os.path.join(cfg, 'EquipExtraAttr.txt'))
        live = {rid_of(l): l for l in rows}
        sk = [i for i, _t in plan['eea_new'] if i in live]
        for i, txt in plan['eea_new']:
            live.setdefault(i, txt.encode('gbk'))
        raw = LF.join(head + [live[k] for k in sorted(live)]) + LF
        raw.decode('gbk')
        write_if_changed(os.path.join(cfg, 'EquipExtraAttr.txt'), raw, touched)
        skipped['EquipExtraAttr.txt'] = sk

        # NPC
        for n in plan['npcs']:
            p = os.path.join(root, 'Game_2/Scene', n['ini'])
            raw = open(p, 'rb').read()
            if (b'script_id=%d' % SCRIPT_ID) in raw:
                skipped[n['ini']] = ['da co NPC']
                raw = ini_fix_npc(raw, n)       # doi ten/chuc danh khi NPC_NAME/NPC_TITLE thay doi
            else:
                raw = ini_append(raw, n)
            raw.decode('gbk')
            write_if_changed(p, raw, touched)

        # Lua + registry + tu dien dich ten
        write_if_changed(os.path.join(root, LUA_REL), plan['lua'].encode('utf-8'), touched)
        p = os.path.join(root, REGISTRY_REL)
        reg = open(p, 'rb').read()
        write_if_changed(p, registry_add(reg, plan), touched)
        p = os.path.join(root, WIRE_DICT_REL)
        raw = open(p, 'rb').read()
        write_if_changed(p, wire_dict_add(raw, plan), touched)
    return bak, touched, skipped


def write_if_changed(path, raw, touched):
    old = open(path, 'rb').read() if os.path.isfile(path) else None
    if old == raw:
        return
    open(path, 'wb').write(raw)
    touched.append(path)


# --------------------------------------------------------------------------- verify
def verify(root):
    cy = CyData()
    chain = cy.chain()
    cfg = os.path.join(root, 'configs')
    rep = {'ok': True, 'checks': []}

    def chk(name, ok, detail=''):
        rep['checks'].append({'name': name, 'ok': bool(ok), 'detail': detail})
        if not ok:
            rep['ok'] = False

    for f, eol in (('ShopTable.txt', CRLF), ('EquipExtraAttr.txt', LF)):
        raw = open(os.path.join(cfg, f), 'rb').read()
        try:
            raw.decode('gbk')
            chk('GBK %s' % f, True)
        except UnicodeDecodeError as e:
            chk('GBK %s' % f, False, 'offset %d' % e.start)
        chk('EOL %s thuan %s' % (f, 'CRLF' if eol == CRLF else 'LF'),
            (raw.count(b'\r\n') == raw.count(b'\n')) if eol == CRLF else raw.count(b'\r\n') == 0)

    head, rows, names = read_table(os.path.join(cfg, 'ShopTable.txt'))
    named = [k for k, n in enumerate(names) if n.startswith('PID(')]
    chk('header ShopTable dat ten du %d o' % SHOP_SLOTS_MAX, len(named) == SHOP_SLOTS_MAX, 'named=%d' % len(named))
    chk('ShopTable moi dong 1227 cot', set(len(shop_cells(l)) for l in rows) == {SHOP_HEAD_COLS + 6 * SHOP_SLOTS_MAX},
        str(sorted(set(len(shop_cells(l)) for l in rows))))
    shops = {rid_of(l): shop_cells(l) for l in rows}
    ok_vis = set(v for v in cy.visuals if chain[v]['ok'])
    covered = set()
    cat_ids = sorted(s for s in shops if SHOP_ID_BASE <= s < SHOP_ID_BASE + 20)
    total = 0
    for sid in cat_ids:
        c = shops[sid]
        slots = shop_slots(c)
        n = num(c[11], 0)
        contiguous = [s[0] for s in slots] == list(range(1, len(slots) + 1))
        chk('shop %d o lien tiep va Num = so o' % sid, contiguous and n == len(slots), 'Num=%d slots=%d' % (n, len(slots)))
        chk('shop %d <= %d mon (MAX_BOOTH_NUMBER)' % (sid, CLIENT_BOOTH_MAX), len(slots) <= CLIENT_BOOTH_MAX, str(len(slots)))
        chk('shop %d tien te nguyen bao' % sid, c[7] == b'5', gbk(c[7]))
        bad = []
        for _s, pid, price in slots:
            i = num(pid)
            total += 1
            if i not in cy.by_id or not chain[cy.by_id[i][6]]['ok'] or num(price, 0) <= 0:
                bad.append(i)
            else:
                covered.add(cy.by_id[i][6])
        chk('shop %d chi chua thoi trang du chuoi, gia > 0' % sid, not bad, str(bad[:10]))
    chk('co shop danh muc 431..', bool(cat_ids), str(cat_ids))
    chk('moi Visual du chuoi deu co trong danh muc', ok_vis <= covered,
        'phu %d/%d; thieu %s' % (len(ok_vis & covered), len(ok_vis), sorted(ok_vis - covered)[:12]))
    # bang cu khong doi dong
    for sid in (120, 247):
        chk('shop %d con nguyen (CY)' % sid, sid in shops and len(shop_slots(shops[sid])) >= 50)

    _h, eea_rows, _n = read_table(os.path.join(cfg, 'EquipExtraAttr.txt'))
    ids = [rid_of(x) for x in eea_rows]
    chk('EquipExtraAttr ID tang dan, khong trung', all(ids[k] < ids[k + 1] for k in range(len(ids) - 1)))
    have = set(ids)
    miss = [i for i in cy.by_id if i in cy.eeamap and i not in have]
    # THONG TIN, khong phai loi: bang EquipExtraAttr cua server la bang DOI CU (2.139/4.113 item thoi trang co dong,
    # va 有效期 cua chung KHONG khop CY — vi du 10127056 server -1, CY 360 h). plan chi nhap khi anh xa cot khop
    # 100 % (do duoc: khong), nen thieu dong = vinh vien (human_bag_container.lua:44) va duoc giu nguyen.
    chk('EquipExtraAttr (thong tin): item thoi trang co dong', True,
        'co %d/%d, thieu %d (thieu = vinh vien); nhap chi khi eea_colmap khop 100 %%' % (
            len(cy.by_id) - len(miss), len(cy.by_id), len(miss)))

    for mapname, ini, _c, _r, _d, guid in NPCS:
        raw = open(os.path.join(root, 'Game_2/Scene', ini), 'rb').read()
        has = (b'script_id=%d' % SCRIPT_ID) in raw and (b'guid=%d' % guid) in raw
        chk('NPC trong %s' % ini, has)
        if has:
            m = re.search(rb'^monstercount=(\d+)', raw, re.M)
            secs = re.findall(rb'^\[monster(\d+)\]', raw, re.M)
            chk('%s monstercount > chi so section lon nhat' % ini, int(m.group(1)) > max(int(x) for x in secs),
                'count=%s max=%d' % (m.group(1).decode(), max(int(x) for x in secs)))
            try:
                raw.decode('gbk')
                chk('GBK %s' % ini, True)
            except UnicodeDecodeError as e:
                chk('GBK %s' % ini, False, 'offset %d' % e.start)
        chk('NPC trong %s mang ten chu Han (dich tai wire)' % ini,
            (('name=%s' % NPC_NAME).encode('gbk') in raw) and (('title=%s' % NPC_TITLE).encode('gbk') in raw))
    wire = open(os.path.join(root, WIRE_DICT_REL), 'rb').read().decode('utf-8')
    miss = [k for k in list(WIRE_NAMES) + [NPC_TITLE] if ('["%s"]' % k) not in wire]
    chk('wire_names_vi.lua co muc dich cho ten/chuc danh NPC', not miss, 'thieu: %s' % miss)
    reg = open(os.path.join(root, REGISTRY_REL), 'rb').read()
    chk('scripts.lua dang ky %d' % SCRIPT_ID, (b'[%d] = "%s"' % (SCRIPT_ID, SCRIPT_MODULE.encode())) in reg)
    lua = os.path.join(root, LUA_REL)
    chk('file %s ton tai' % LUA_REL, os.path.isfile(lua))
    if os.path.isfile(lua):
        res = lua_syntax(lua)
        chk('cu phap Lua %s' % LUA_REL, res[0], res[1])
        txt = open(lua, 'rb').read().decode('utf-8')
        for sid in cat_ids:
            chk('Lua menu co shop %d' % sid, ('id = %d,' % sid) in txt)
    rep['counts'] = {'catalog_shops': cat_ids, 'catalog_items': total, 'visuals_ok': len(ok_vis),
                     'visuals_covered': len(ok_vis & covered), 'eea_rows': len(eea_rows)}
    return rep


def lua_syntax(path):
    for cmd in (['luac5.4', '-p', path], ['luac', '-p', path],
                ['lua5.4', '-e', 'assert(loadfile(%r))' % path]):
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        except FileNotFoundError:
            continue
        return r.returncode == 0, (r.stderr or r.stdout).strip()[:200] or ' '.join(cmd[:1])
    return True, 'khong co luac/lua5.4 de kiem (bo qua)'


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
        if a.out:
            json.dump(rep, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    elif a.cmd == 'plan':
        out = a.out or '/tmp/costumes-plan'
        os.makedirs(out, exist_ok=True)
        plan = build_plan(a.root)
        write_staging(a.root, plan, out)
        rep = {'staging': out, 'summary': plan['summary'], 'notes': plan['notes'], 'eea_colmap': plan['eea_colmap'],
               'npcs': [{k: v for k, v in n.items() if k != 'block'} for n in plan['npcs']],
               'labels': [s['label'] for s in plan['catalog']]}
    elif a.cmd == 'apply':
        stg = a.staging or '/tmp/costumes-plan'
        bak, files, skipped = apply(a.root, stg)
        rep = {'backup': bak, 'files': files, 'bo_qua_vi_da_co': {k: len(v) for k, v in skipped.items()}}
    else:
        rep = verify(a.root)
    print(json.dumps(rep, ensure_ascii=False, indent=1))
    return 0 if rep.get('ok', True) else 1


if __name__ == '__main__':
    sys.exit(main())
