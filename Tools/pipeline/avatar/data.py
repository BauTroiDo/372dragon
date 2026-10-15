# -*- coding: utf-8 -*-
"""Read-only access to client_GL data for the avatar composer.

Tables
    DBC `00CCBBDD` and typed text tables.  The reader is adapted (copied, not imported) from
    Tools/add-phai/compare-cy-20260909/compare_tables.py::read_table and
    Tools/model-convert/dbc.py, with one deliberate change: STRING cells stay BYTES.  Key/path
    columns are GBK even inside UTF-8 tables (Docs/08 1.4, 1.5) and a "try UTF-8 first" decode
    mis-reads GBK names that happen to be valid UTF-8 (memory tlbb-cy4-rasoat).  text()/gbk()
    decode only for reports.
Files
    On-disk names are GBK bytes shown as cp1252 (Docs/08 1.3).  The engine opens them with
    CreateFileA under ACP 1252 and NTFS compares case-insensitively, so the key of a GBK name is
    its cp1252 rendering, lower-cased (disk_key).  Folders and their order follow TlbbViewer
    ViewerApp::addResourceLocations (resource group "General"; Ogre keeps the last location
    that indexes a name).
Scripts
    all.obj / all.material / all.effect / all.particle are read as bytes (Docs/08 1.2) with the
    walkers of Tools/pipeline/tlbbfmt.py.  Nothing is ever written by this module.
"""
import os
import re
import struct
import sys
import zipfile

_PIPELINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _PIPELINE not in sys.path:
    sys.path.insert(0, _PIPELINE)
import tlbbfmt  # noqa: E402

# CYS-AVATAR (14/09): the default data set is CanonicalCY (CY 3.71 tables, binary DBC); client_GL stays readable
# through --data (column profile 'gl'). Column meanings per profile: COLUMN_PROFILES below.
DATA_DIR = r'C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data'
DATA_DIR_GL = r'C:\TLBB\085\client_GL\Data'
DBC_MAGIC = b'\x00\xcc\xbb\xdd'

# Column profiles. 'cy' = CY 3.71 (Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4 + cy-avatar handoff);
# 'gl' = client_GL (Registry/abi/dbc_columns_gl.tsv, rules.py R01..R18). Column numbers are 0-based.
COLUMN_PROFILES = {
    'cy': {
        'cme_columns': 21,
        'cme_action_set': 20,            # CharModelEx: ActionSetFile row (CY Game.exe row+0x5c)
        'hair_mesh': 2, 'hair_mesh2': 4, 'hair_label': 6,   # CharHairGeo: [3]/[5] are the _iv variants
        'face_mesh': 2, 'face_label': 4,
        # ItemVisualLocator slot -> (object column, material column, tag). Evidence: value scan of DataCY
        # (right/left 2/5 hold weapon *.obj, 9 = psoul/武魂 objects, 13 = toy objects, 17/21/25 = CR_2021 大刀 /
        # 双刀右 / 双刀左 = back + two waist sheaths; slot names are the SlotCreate attributes of 男主角.obj and the
        # strings LeftWeaponObj/RightWeaponObj/FootWeaponObj/NewBackWeaponObj/WaistWeaponObj1/2 of CY Game.exe
        # FUN_1405e1f40 (Obj_Character.cpp:0x492)). Material columns are the following column ([SL]: empty in CY).
        'ivl_slots': ((b'RightWeaponObj', 2, 3, 'rw'), (b'LeftWeaponObj', 5, 6, 'lw'),
                      (b'FootWeaponObj', 13, 14, 'fw'), (b'NewBackWeaponObj', 17, 18, 'bw'),
                      (b'WaistWeaponObj1', 21, 22, 'w1'), (b'WaistWeaponObj2', 25, 26, 'w2')),
        'kfs_slot': (b'KFSObj', 9, 10, 'kfs'),
        # EquipBase Type % 30 -> ActionSetLine slot (CY Game.exe FUN_1405c6df0); column = slot + 1, bare hands = 1
        'type_slot': {0: 2, 1: 1, 2: 4, 3: 3, 4: 5, 5: 6, 6: 7, 7: 15, 8: 8, 9: 9, 10: 10, 16: 11, 17: 12},
        'shared_slot': 13,
        'mount_add_height': 22,          # CharMount camera add-height (client_GL col 14)
        'dress_colour': 5, 'dress_group': 6,    # EquipDress (7 columns) [SL]
        'exterior_weapon': None,         # CY Exterior_Weapon.txt (9 columns) is the skin catalogue, no IVL levels
        'sect_models': (4950, 4965),     # CharModelEx: 15 female / 15 male sect preview models (高模)
    },
    'gl': {
        'cme_columns': 10,
        'cme_action_set': 9,
        'hair_mesh': 2, 'hair_mesh2': 3, 'hair_label': 4,
        'face_mesh': 2, 'face_label': 3,
        'ivl_slots': ((b'RightWeaponObj', 2, 1, 'rw'), (b'LeftWeaponObj', 5, 6, 'lw'),
                      (b'FootWeaponObj', 11, 12, 'fw'), (b'BackWeaponObj', 15, 16, 'bw')),
        'kfs_slot': (b'KFSObj', 9, 10, 'kfs'),
        'type_slot': {0: 2, 1: 1, 2: 4, 3: 3, 4: 5, 5: 6, 6: 7, 7: 8, 8: 11, 9: 12, 16: 13, 17: 14},
        'shared_slot': 9,
        'mount_add_height': 14,
        'dress_colour': 6, 'dress_group': 7,
        'exterior_weapon': {'name': 1, 'type': 7, 'levels': (9, 10, 11, 12)},
        'sect_models': None,
    },
}

# CY 3.71 sect order of the creation screen (CharModelEx 4950 + sex*15 + ordinal) and the weapon Type each sect
# holds in its 高模 preview object (entity names: 禅杖/棍 -> 长兵 1, 刀 -> 0, 剑 -> 2, 钩/刺 -> 双短 3, 扇 4, 环 5,
# 弩 6, 杖 7, 箫剑 8, 双刀 16, 镰 17; Types from the EquipBase novice weapons 1010xx00 of CY).
CY_SECTS = (('shaolin', '少林', 1), ('mingjiao', '明教', 0), ('gaibang', '丐帮', 1), ('wudang', '武当', 2),
            ('emei', '峨眉', 2), ('xingxiu', '星宿', 3), ('tianlong', '天龙', 5), ('tianshan', '天山', 3),
            ('xiaoyao', '逍遥', 4), ('murong', '慕容', 1), ('tangmen', '唐门', 6), ('guigu', '鬼谷', 7),
            ('taohuadao', '桃花岛', 8), ('juejinggu', '绝情谷', 16), ('erengu', '恶人谷', 17))

RESOURCE_FOLDERS = ('EffectFolder', 'ModelFolder', 'Model2Folder', 'Model3Folder', 'Model4Folder',
                    'Model5Folder', 'Model6Folder', 'Model7Folder', 'Model8Folder', 'InterfaceFolder',
                    'MaterialFolder', 'Material2Folder', 'Material3Folder', 'Material4Folder',
                    'Material5Folder', 'Material6Folder', 'Material7Folder', 'Material8Folder')

# Ogre built-ins (OgreCore / MaterialManager defaults); never in all.material.
BUILTIN_MATERIALS = frozenset([b'BaseWhite', b'BaseWhiteNoLighting'])

_INT_CELL = re.compile(rb'\s*-?\d+\s*$')
OBJ_BLOCK = re.compile(rb'<Object\s+name="([^"]*)"\s*>.*?</Object>', re.S)
_ANY_OBJ = re.compile(rb'<Object\b[^>]*>.*?</Object>', re.S)
_MAT_HDR = re.compile(rb'(?m)^\s*(?:abstract\s+)?material\s+([^\s:{]+)')
PARTICLE_REF = re.compile(rb'\bParticleSystem\s+(\S+)')


# ------------------------------------------------------------------ text helpers
def gbk(b):
    """GBK bytes -> str for reports (keys, paths, Chinese names)."""
    if isinstance(b, bytes):
        return b.decode('gbk', 'replace')
    return '' if b is None else str(b)


def text(b):
    """Display text of a name/description cell (UTF-8 in client_GL text tables, GBK or UTF-8 in
    DBC pools).  Never use for keys."""
    if not isinstance(b, bytes):
        return '' if b is None else str(b)
    try:
        return b.decode('utf-8')
    except UnicodeDecodeError:
        return b.decode('gb18030', 'replace')


_CP1252 = {}


def _cp1252(c):
    ch = _CP1252.get(c)
    if ch is None:
        try:
            ch = bytes([c]).decode('cp1252')
        except UnicodeDecodeError:      # 0x81 0x8D 0x8F 0x90 0x9D -> C1 control, as Windows does
            ch = chr(c)
        _CP1252[c] = ch
    return ch


def disk_key(name):
    """Lookup key of a resource file name.  bytes = engine name (GBK) -> cp1252 characters;
    str = name as returned by the file system.  Lower-cased like NTFS compares."""
    if isinstance(name, bytes):
        name = ''.join(chr(c) if c < 0x80 else _cp1252(c) for c in tlbbfmt.base_of(name))
    return name.lower()


# ------------------------------------------------------------------ tables
class Table(object):
    """Rows are lists: int for INT, float for FLOAT, bytes for STRING cells (padded to the
    declared column count)."""

    def __init__(self, name, fmt, types, rows):
        self.name = name
        self.fmt = fmt
        self.types = types
        self.rows = rows
        self.by_id = {}
        for r in rows:
            if r and isinstance(r[0], int) and r[0] not in self.by_id:
                self.by_id[r[0]] = r

    def get(self, rid):
        return self.by_id.get(rid)


def read_table(path):
    with open(path, 'rb') as f:
        raw = f.read()
    name = os.path.basename(path)
    if raw[:4] == DBC_MAGIC:
        nf, nr = struct.unpack_from('<2I', raw, 4)
        codes = struct.unpack_from('<%dI' % nf, raw, 16)
        start = 16 + 4 * nf
        pool = raw[start + 4 * nf * nr:]
        vals = struct.unpack_from('<%di' % (nf * nr), raw, start)
        rows = []
        for r in range(nr):
            base = r * nf
            row = []
            for c in range(nf):
                v = vals[base + c]
                t = codes[c]
                if t == 2:
                    off = v & 0xFFFFFFFF
                    if off >= len(pool):
                        row.append(b'')
                    else:
                        e = pool.find(b'\x00', off)
                        row.append(pool[off:e] if e >= 0 else pool[off:])
                elif t == 1:
                    row.append(struct.unpack('<f', struct.pack('<i', v))[0])
                else:
                    row.append(v)
            rows.append(row)
        types = ['STRING' if t == 2 else ('FLOAT' if t == 1 else 'INT') for t in codes]
        return Table(name, 'dbc', types, rows)
    lines = raw.split(b'\n')
    types = [t.strip().upper().decode('ascii', 'replace') for t in lines[0].rstrip(b'\r').split(b'\t')]
    rows = []
    for ln in lines[1:]:
        ln = ln.rstrip(b'\r')
        if not ln:
            continue
        cells = ln.split(b'\t')
        if not _INT_CELL.match(cells[0]):
            continue                     # header / column-name lines
        row = []
        for c, t in enumerate(types):
            v = cells[c] if c < len(cells) else b''
            if t == 'INT':
                try:
                    row.append(int(v))
                except ValueError:
                    row.append(-1 if not v.strip() else 0)
            elif t == 'FLOAT':
                try:
                    row.append(float(v))
                except ValueError:
                    row.append(0.0)
            else:
                row.append(v)
        rows.append(row)
    return Table(name, 'text', types, rows)


# ------------------------------------------------------------------ skeleton
def skeleton_names(data):
    """Bone and animation names of an Ogre/Fairy .skeleton (chunk walk copied from
    tlbbfmt.skel_info, which only counts them).  Returns {'bones', 'anims', 'err'}."""
    out = {'bones': [], 'anims': [], 'err': ''}
    n = len(data)
    if n < 8 or data[:2] != b'\x00\x10':
        out['err'] = 'not-ogre'
        return out
    e = data.find(b'\n', 2, 80)
    if e < 0:
        out['err'] = 'no-version'
        return out
    p = e + 1
    try:
        while p + 6 <= n:
            cid, sz = struct.unpack_from('<HI', data, p)
            q = p + 6
            if cid == 0x1010:
                p = q + 2
            elif cid == 0x2000:
                k = data.index(b'\n', q, min(n, q + 1024))
                out['bones'].append(data[q:k])
                p = k + 1 + 2 + 28 + (12 if sz > 36 else 0)
            elif cid == 0x3000:
                p = q + 4
            elif cid == 0x4000:
                k = data.index(b'\n', q, min(n, q + 1024))
                out['anims'].append(data[q:k])
                p = k + 1 + 4
            elif cid == 0x4010:
                k = data.index(b'\n', q, min(n, q + 1024))
                p = k + 1 + 4
            elif cid == 0x4100:
                p = q + 2
            elif cid == 0x4120:
                cnt, fl = struct.unpack_from('<HH', data, q)
                p = q + 4 + cnt * (4 + (16 if fl & 1 else 0) + (12 if fl & 2 else 0) + (12 if fl & 4 else 0))
            elif cid == 0x4110:
                p = q + 32 + (12 if sz > 38 else 0)
            elif cid == 0x5000:
                k = data.index(b'\n', q, min(n, q + 1024))
                p = k + 1 + 4
            else:
                break
    except (ValueError, IndexError, struct.error) as ex:
        out['err'] = type(ex).__name__
    return out


# ------------------------------------------------------------------ the data set
class ClientData(object):
    """Lazy, cached, read-only view of one client Data folder (default client_GL)."""

    def __init__(self, data_dir=DATA_DIR):
        self.dir = data_dir
        self._tables = {}
        self._files = None
        self._objs = None
        self._loose = None
        self._mats = None
        self._templates = None
        self._effects = None
        self._particles = None
        self._mesh = {}
        self._skel = {}
        self._aset = None
        self._mtex = {}
        self._wtype = None
        self._profile = None
        self.obj_dups = 0

    def path(self, *parts):
        return os.path.join(self.dir, *parts)

    # ---- column profile (CYS-AVATAR)
    @property
    def profile(self):
        """'cy' when CharModelEx has the 21 CY 3.71 columns, else 'gl'."""
        if self._profile is None:
            n = len(self.table('CharModelEx.txt').types)
            self._profile = 'cy' if n == COLUMN_PROFILES['cy']['cme_columns'] else 'gl'
        return self._profile

    def col(self, key):
        return COLUMN_PROFILES[self.profile][key]

    def cme_action_set(self, row):
        c = self.col('cme_action_set')
        return row[c] if row is not None and len(row) > c else -1

    def hair_meshes(self, row):
        """CharHairGeo row -> (HairMesh, HairMesh2) bytes."""
        return row[self.col('hair_mesh')], row[self.col('hair_mesh2')]

    def stance_column(self, wtype):
        """EquipBase weapon Type -> ActionSetLine column (1 = bare hands)."""
        if wtype is None or wtype < 0:
            return 1
        return self.col('type_slot').get(wtype % 30, 0) + 1

    def sect_model_ids(self, sex):
        base = self.col('sect_models')
        if base is None:
            return []
        return [base[sex] + i for i in range(len(CY_SECTS))]

    # ---- tables
    def table(self, name):
        t = self._tables.get(name)
        if t is None:
            t = read_table(self.path('ConfigFolder', *name.split('/')))
            self._tables[name] = t
        return t

    def row(self, table, rid):
        if rid is None:
            return None
        return self.table(table).by_id.get(rid)

    # ---- files
    def files(self):
        if self._files is None:
            idx = {}
            for fold in RESOURCE_FOLDERS:
                root = self.path(fold)
                if not os.path.isdir(root):
                    continue
                for dp, dn, fn in os.walk(root):
                    dn.sort()
                    for f in fn:
                        idx[f.lower()] = os.path.join(dp, f)   # later location wins, as in Ogre
            self._files = idx
        return self._files

    def find_file(self, name):
        if not name:
            return None
        return self.files().get(disk_key(name))

    # ---- all.obj (+ loose *.obj templates)
    def objects(self):
        if self._objs is None:
            with open(self.path('ModelFolder', 'all.obj'), 'rb') as f:
                data = f.read()
            clean = tlbbfmt._COMMENT.sub(b'', data)
            idx = {}
            dups = 0
            for m in OBJ_BLOCK.finditer(clean):
                k = m.group(1).lower()
                if k in idx:            # LogicModelManager keeps the first definition
                    dups += 1
                    continue
                idx[k] = (m.group(1), m.group(0))
            self._objs = idx
            self.obj_dups = dups
        return self._objs

    def loose_objs(self):
        if self._loose is None:
            self._loose = dict((k, p) for k, p in self.files().items()
                               if k.endswith('.obj') and k != 'all.obj')
        return self._loose

    def obj_block(self, name):
        """Template <Object> block bytes for an object name (all.obj first, then a loose
        single-object file whose file name is the object name), or None."""
        if not name:
            return None
        v = self.objects().get(name.lower())
        if v:
            return v[1]
        p = self.loose_objs().get(disk_key(name))
        if p:
            with open(p, 'rb') as f:
                data = tlbbfmt._COMMENT.sub(b'', f.read())
            m = OBJ_BLOCK.search(data) or _ANY_OBJ.search(data)
            if m:
                return m.group(0)
        return None

    # ---- materials
    def materials(self):
        if self._mats is None:
            with open(self.path('MaterialFolder', 'all.material'), 'rb') as f:
                self._mats, self.mat_stats = tlbbfmt.material_defs(f.read())
        return self._mats

    def templates(self):
        """Material names defined in Data/MaterialTemplates.zip (the template parents)."""
        if self._templates is None:
            names = set()
            zp = self.path('MaterialTemplates.zip')
            if os.path.isfile(zp):
                with zipfile.ZipFile(zp) as z:
                    for n in z.namelist():
                        if n.lower().endswith('.material'):
                            for m in _MAT_HDR.finditer(z.read(n)):
                                names.add(m.group(1))
            self._templates = names
        return self._templates

    def material_known(self, name):
        return bool(name) and (name in BUILTIN_MATERIALS or name in self.materials() or name in self.templates())

    def material_textures(self, name):
        return tlbbfmt.material_textures(name, self.materials(), self._mtex)

    # ---- effects / particles
    def effects(self):
        if self._effects is None:
            with open(self.path('EffectFolder', 'all.effect'), 'rb') as f:
                blocks, stray = tlbbfmt.iter_blocks(f.read())
            eff = {}
            for hdr, body in blocks:
                t = hdr.split(None, 1)
                if len(t) == 2 and t[0] == b'effect':
                    eff.setdefault(t[1].strip(), body)
            self._effects = eff
            self.effect_stray = stray
        return self._effects

    def particles(self):
        if self._particles is None:
            with open(self.path('EffectFolder', 'all.particle'), 'rb') as f:
                defs, _ = tlbbfmt.script_defs(f.read(), 'particle')
            self._particles = set(defs)
        return self._particles

    # ---- meshes / skeletons
    def mesh(self, name):
        key = disk_key(name)
        if key not in self._mesh:
            p = self.files().get(key)
            info = None
            if p:
                with open(p, 'rb') as f:
                    info = tlbbfmt.mesh_info(f.read())
                info['path'] = p
            self._mesh[key] = info
        return self._mesh[key]

    def skeleton(self, name):
        key = disk_key(name)
        if key not in self._skel:
            p = self.files().get(key)
            info = None
            if p:
                with open(p, 'rb') as f:
                    info = skeleton_names(f.read())
                info['path'] = p
            self._skel[key] = info
        return self._skel[key]

    # ---- ActionSet chain (CharModelEx col 9 (GL) / col 20 (CY) -> ActionSet.txt -> ActionSetLine -> ActionSetKV)
    def action_sets(self):
        if self._aset is None:
            idx = {}
            for r in self.table('ActionSet/ActionSet.txt').rows:
                if len(r) >= 4:
                    idx.setdefault(r[1], {}).setdefault(r[2], r[3])
            self._aset = idx
        return self._aset

    def action_line(self, set_id, action):
        line_id = self.action_sets().get(set_id, {}).get(action)
        if line_id is None:
            return None, None
        return line_id, self.row('ActionSet/ActionSetLine.txt', line_id)

    def kv(self, kid):
        r = self.row('ActionSet/ActionSetKV.txt', kid)
        return r[1] if r and len(r) > 1 else None

    # ---- weapon type of an ItemVisualLocator id (EquipBase weapon rows: EquipPoint 0)
    def weapon_type_of_ivl(self, ivl):
        if self._wtype is None:
            m = {}
            for r in self.table('EquipBase.txt').rows:
                if len(r) > 6 and r[5] == 0 and r[6] not in m:
                    m[r[6]] = r[3]
            self._wtype = m
        return self._wtype.get(ivl)

    def novice_weapon(self, wtype):
        """Lowest (level, quality, id) general-rule weapon item (EquipPoint 0, Rule 2) of a Type whose
        ItemVisualLocator row names a hand object: what a new CY character of that sect holds."""
        best = None
        for r in self.table('EquipBase.txt').rows:
            if len(r) > 11 and r[3] == wtype and r[5] == 0 and r[6] > 0 and r[7] == 2:
                iv = self.row('ItemVisualLocator.txt', r[6])
                if iv is None or not (iv[2] or iv[5]):
                    continue
                k = (r[11], r[2], r[0])
                if best is None or k < best[0]:
                    best = (k, r)
        return best[1] if best else None
