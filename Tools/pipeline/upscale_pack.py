# -*- coding: utf-8 -*-
"""upscale_pack.py - CY-Source STAGING: 2x high-resolution texture pack (nothing is installed anywhere).

Source  : C:\\TLBB\\085\\client_GL\\Data (S1), read-only. Model closures come from the D0 index
          (Assets\\Staging\\index\\sha256_S1.tsv + all.obj/all.material parsed with tlbbfmt).
Output  : Assets\\Staging\\upscale\\<date>\\ = mirror of the Data folder paths (same GBK/mojibake names) holding
          ONLY textures whose chosen variant passed every check, plus manifest.tsv (append-only, last row per
          texture wins), selection.tsv, run.log, runs.json, verify.txt, overlay_manifest.tsv (PASS rows with
          their Data-relative paths, for a later overlay into Assets\\Canonical) and a compact review
          (index.html + per-category contact sheets in review\\).
          Work files: Assets\\Staging\\upscale\\_work-<date>\\ (per-texture crops, temp files).

v1 (2026-09-12) logic was copied from C:\\TLBB\\085\\analysis\\graphics-overhaul\\upscale_tex.py (2026-09-03) and
hardened with the 03/09 14:07 incident (Docs\\08 muc 3.4, 3.5); v2 (2026-09-13) adds the variant cascade.
  * Real-ESRGAN ncnn-vulkan 20220424 runs PER FILE with -j 1:1:1, one GPU process at a time (directory mode
    returned mis-named images: 133/651 broken). Every output is size-checked. Tile size stays automatic
    (2026-09-12: -t 512 silently returned garbage and coincided with an nvlddmkm driver reset).
  * realesrgan-x4plus always with -s 4, then Lanczos down to exactly 2x (-s 2 with x4plus breaks images).
    realesr-animevideov3 has native x2/x3/x4 models (ANIME_SCALE below).
  * Alpha goes separately through the same model as the RGB of that variant (grey image); interiors whose
    3x3 source alpha is constant are snapped back to the exact source value. Black fill under fully
    transparent texels is replaced by a push-pull fill before upscaling (dark fringes otherwise).
  * Checks on every candidate and again on the DECODED OUTPUT DDS: MAD vs the original (2x result
    Lanczos-reduced back) on opaque texels <= 25, no broken/black tiles, mean colour shift <= 4 levels (sRGB
    trap), alpha coverage within 2 %, local alpha change, period-2 lattice detector (grid <= 0.40), exact 2x,
    legacy DX9 header, full mip chain.
  * Variant cascade per texture: x4plus -> animevideov3 -> x4plus on a Gaussian-blurred input (0.6, 1.0).
    The cascade stops at the first variant that passes with grid <= 0.30; texture sets marked t1 (the
    2026-09-12 failures and 'look here' cards) try every variant. Among passing variants the lowest risk
    (worst check / its limit) wins; the earliest cascade entry wins ties within 0.05. No passing variant =
    the original stays (status fail, nothing in the mirror).
  * UI textures (MaterialFolder\\Common, any name referenced by InterfaceFolder xml/lua) are never selected;
    terrain, effect cards and mask/flow/rim maps are not selected; only diffuse slots of model materials.
  * Encoding: texconv x64, -dx9, -m 0, BC1 when the source is DXT1 or has no alpha, BC3 when a DXT3/DXT5
    source has alpha, 32-bit uncompressed stays uncompressed. texconv input is an uncompressed A8R8G8B8 DDS
    (UNORM), so no PNG gamma metadata can trigger an sRGB conversion. No BC7.
  * Watchdog: realesrgan runs at normal priority with a 4-logical-core affinity; a pass that exceeds 6x the
    measured GPU time or prints no '[0 NVIDIA' device line raises GpuFallback; two in a row stop the run
    (resumable: rerun the same command).

Usage (PowerShell, $env:PYTHONUTF8="1"; & "C:\\Program Files\\Python313\\python.exe" upscale_pack.py ...):
  select  --date 2026-09-13 --scope full --t1-from 2026-09-12      (build selection.tsv)
  run     --date 2026-09-13 --seed-from 2026-09-12                  (resumable; --limit N, --cats, --retry-failed)
  sheets  --date 2026-09-13          compact review: index.html + review\\*.jpg contact sheets
  overlay --date 2026-09-13          overlay_manifest.tsv (PASS rows, Data-relative paths)
  verify  --date 2026-09-13          re-check the mirror against the manifest
  (v1 batch 2026-09-12: select/run/grade/review with the default --scope batch1)
"""
import argparse
import base64
import collections
import concurrent.futures as cf
import ctypes
import datetime
import glob
import hashlib
import io
import json
import math
import os
import random
import re
import shutil
import struct
import subprocess
import sys
import threading
import time

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import tlbbfmt as F  # noqa: E402  read-only format helpers of this pipeline (all.obj / all.material / mesh)

TOOL_VERSION = '2.0 (2026-09-13)'
S1 = r'C:\TLBB\085\client_GL\Data'
CFG = os.path.join(S1, 'ConfigFolder')
IDX = r'C:\TLBB\085\CY-Source\Assets\Staging\index'
UP = r'C:\TLBB\085\CY-Source\Assets\Staging\upscale'
TOOLS = r'C:\TLBB\085\Tools\texture-upscale'
ESRGAN = os.path.join(TOOLS, 'realesrgan', 'realesrgan-ncnn-vulkan.exe')
ESRGAN_MODELS = os.path.join(TOOLS, 'realesrgan', 'models')
TEXCONV = os.path.join(TOOLS, 'texconv.exe')
SCN = r'\\wsl.localhost\TLBB\home\ubuntu\Game_2\Scene'
CJK_FONT = r'C:\Windows\Fonts\msyh.ttc'

MAX_SRC = 1024          # only originals <= 1024 px on the long side
MIN_SRC = 32            # shortest side
MIN_LONG = 64           # scope 'full': long side below this is not worth it
HAIR_RE = re.compile(r'头发|发型|hair', re.I)    # scope 'full': hair textures <= 64 px are skipped
MAD_MAX = 25.0          # Docs/08 3.5
TILE_MAD_MAX = 60.0
MEAN_SHIFT_MAX = 4.0    # levels (0-255) per channel, opaque texels
COV_TOL = 0.02          # alpha coverage (alpha >= 128), absolute fraction
ALPHA_TILE_MAX = 48.0   # local alpha change: max per-tile mean |alpha| difference (2x reduced back vs source)
GRID_ATTN = 0.30        # 'look here': p99 tile score of the period-2 lattice detector (cascade continues)
GRID_FAIL = 0.40        # fail: 2026-09-12 median 0.16; every score > 0.40 was a visible woven-grid artefact on
                        # DXT1-dithered cloth (e.g. jpg_女主角高模3少林高级100.dds), hair/lace stayed < 0.36
RISK_TIE = 0.05
CROP = 128              # review crop size in original pixels
SHEET_CROP = 64         # contact-sheet crop size in original pixels
LOW_PRIO = getattr(subprocess, 'BELOW_NORMAL_PRIORITY_CLASS', 0) | getattr(subprocess, 'CREATE_NO_WINDOW', 0)

# Upscale variants tried per texture, in cascade order.
ANIME_SCALE = 2
VARIANTS = collections.OrderedDict([
    ('x4plus', {'model': 'realesrgan-x4plus', 'scale': 4, 'blur': 0.0}),
    ('anime', {'model': 'realesr-animevideov3', 'scale': ANIME_SCALE, 'blur': 0.0}),
    ('x4plus-b06', {'model': 'realesrgan-x4plus', 'scale': 4, 'blur': 0.6}),
    ('x4plus-b10', {'model': 'realesrgan-x4plus', 'scale': 4, 'blur': 1.0}),
])
CASCADE = list(VARIANTS)

DIFFUSE_ALIASES = {b'<baseTexture>', b'<BaseTexture>', b'<albedoTexture>'}
NON_DIFFUSE_NAME = re.compile(r'遮罩|流光|边缘光|法线|高光|特效|mask|flow|rim|normal|_n$|_nm$', re.I)
UI_NAME_EXT = ('.xml', '.lua', '.imageset', '.scheme', '.looknfeel', '.layout')

CATS = collections.OrderedDict([          # v1 batch (2026-09-12)
    ('a1', 'HD player sect display sets (body, face, hair, sect weapon) - female/male'),
    ('a2', 'HD player races 2-7 (novice sets) + default HD face/hair'),
    ('a3', 'Base races 0/1: default equipment, creation faces, base hairs'),
    ('a4', 'Base-model sect uniforms, top tiers of every sect (高级 / 高手)'),
    ('b1', '2026 costumes (ItemVisualChar)'),
    ('b2', '2026 mounts'),
    ('b3', '2026 pets'),
    ('b4', '2026 weapon skins (幻饰)'),
    ('b5', '2026 head/back ornaments'),
    ('c1', '20 most-used NPC models (server placements)'),
])
CATS2 = collections.OrderedDict([         # scope 'full' (2026-09-13)
    ('pet', 'Pets: every model PetAttrTable points at + pet_* objects'),
    ('mount', 'Mounts: CharMount models + ride_* objects'),
    ('weapon', 'Weapons and weapon skins: ItemVisualLocator objects + dweapon_*/weapon* objects'),
    ('ornament', 'Head/back ornaments: top_*/back_* objects'),
    ('player', 'Player characters: ItemVisualChar (equipment, costumes), faces, hair, *主角* objects'),
    ('npc', '20 most-used NPC models (server placements)'),
])
# Fallback when the WSL scene folder is not reachable (ranking computed 2026-09-12 from Game_2\Scene\*_monster.ini).
NPC_FALLBACK = ['宋兵.obj', '杨文广.obj', '奸商.obj', '客栈老板.obj', '酒店老板3.obj', '郎中1.obj', '单正.obj',
                '商人.obj', '林和靖.obj', '胖一般商人.obj', '白苗卫兵.obj', '胖大商人.obj', '张耒.obj', '石清露.obj',
                '宋大官员3.obj', '洛阳兵2.obj', '苏辙B.obj', '小贩.obj', '郎中2.obj', '程景.obj']

LOCK = threading.Lock()
LOGF = None


def log(*a):
    s = time.strftime('%H:%M:%S ') + ' '.join(str(x) for x in a)
    with LOCK:
        print(s, flush=True)
        if LOGF:
            LOGF.write(s + '\n')
            LOGF.flush()


def out_dirs(date):
    out = os.path.join(UP, date)
    work = os.path.join(UP, '_work-' + date)
    return out, work


def guard(path):
    """Every write goes through here: only Assets\\Staging\\upscale\\** is writable."""
    p = os.path.abspath(path)
    if not p.lower().startswith(UP.lower() + os.sep):
        raise RuntimeError('refusing to write outside %s: %s' % (UP, p))
    return p


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def gbk_rel(rel):
    """On-disk mojibake relpath -> readable GBK-decoded relpath."""
    return '\\'.join(F.disp(F.disk_name_bytes(p, True)) for p in rel.split('\\'))


# ====================================================================== tables (read-only)
def _dec(b):
    for e in ('utf-8', 'gbk'):
        try:
            return b.decode(e)
        except UnicodeDecodeError:
            pass
    return b.decode('gbk', 'replace')


def read_table(name):
    """ConfigFolder table -> list of rows (DBC 00CCBBDD binary or TAB text; text rows keep strings)."""
    with open(os.path.join(CFG, name), 'rb') as f:
        d = f.read()
    if d[:4] in (b'\x00\xcc\xbb\xdd', b'\xdd\xbb\xcc\x00'):
        nf, nr, _sp = struct.unpack_from('<III', d, 4)
        types = struct.unpack_from('<%dI' % nf, d, 16)
        off = 16 + 4 * nf
        cells = struct.unpack_from('<%dI' % (nf * nr), d, off)
        pool = d[off + 4 * nf * nr:]
        rows = []
        for r in range(nr):
            row = []
            for c in range(nf):
                v = cells[r * nf + c]
                t = types[c]
                if t == 0:
                    v = struct.unpack('<i', struct.pack('<I', v))[0]
                elif t == 1:
                    v = struct.unpack('<f', struct.pack('<I', v))[0]
                else:
                    e = pool.find(b'\x00', v)
                    v = _dec(pool[v:e])
                row.append(v)
            rows.append(row)
        return rows
    rows = []
    for ln in d.split(b'\n'):
        ln = ln.rstrip(b'\r')
        if ln.strip():
            rows.append([_dec(x) for x in ln.split(b'\t')])
    return [r for r in rows if r and r[0].lstrip('-').isdigit()]


def ival(x, default=-1):
    try:
        return int(x)
    except (TypeError, ValueError):
        try:
            return int(float(x))
        except (TypeError, ValueError):
            return default


def gb(s):
    """Display string -> GBK bytes (keys of all.material / all.obj)."""
    try:
        return s.encode('gbk')
    except UnicodeEncodeError:
        return s.encode('utf-8', 'surrogateescape')


# ====================================================================== source data model
FOLDER_RE = re.compile(r'^(model|material)(\d*)(folder)?$', re.I)
INFO_RE = re.compile(r'^(\S+) (\d+)x(\d+)(?: m(\d+))?')


def folder_rank(top):
    m = FOLDER_RE.match(top)
    if not m:
        return (2, 0, top.lower())
    return (0 if m.group(1).lower() == 'model' else 1, int(m.group(2) or 1), '')


class Source:
    """S1 file list + name index (same resolution rule as index_sources.name_index) + material/obj parsers."""

    def __init__(self):
        t0 = time.time()
        self.info = {}
        self.sha = {}
        ents = []
        with open(os.path.join(IDX, 'sha256_S1.tsv'), encoding='utf-8-sig') as f:
            hdr = f.readline().rstrip('\n').split('\t')
            ix = {h: i for i, h in enumerate(hdr)}
            for ln in f:
                r = ln.rstrip('\n').split('\t')
                rel = r[ix['relpath']]
                self.sha[rel] = r[ix['sha256']]
                m = INFO_RE.match(r[ix['info']])
                if m:
                    self.info[rel] = (m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4) or 0))
                parts = rel.split('\\')
                top = parts[0] if len(parts) > 1 else ''
                ents.append((folder_rank(top), rel, F.key_of(F.disk_name_bytes(parts[-1], True))))
        ents.sort()
        self.idx = {}
        for rk, rel, k in ents:
            self.idx.setdefault(k, rel)
        with open(os.path.join(S1, 'MaterialFolder', 'all.material'), 'rb') as f:
            self.mats, _ = F.material_defs(f.read())
        with open(os.path.join(S1, 'ModelFolder', 'all.obj'), 'rb') as f:
            objs, _ = F.parse_all_obj(f.read())
        self.objs = {o['name']: o for o in objs}
        self.obj_by_disp = {F.disp(o['name']): o['name'] for o in objs}
        self._mesh_cache = {}
        log('source: %d files, %d materials, %d objects (%.1fs)' % (len(self.sha), len(self.mats), len(self.objs),
                                                                    time.time() - t0))

    def resolve(self, name_b):
        return self.idx.get(F.key_of(F.base_of(name_b)))

    def mesh_mats(self, mesh_b):
        if mesh_b in self._mesh_cache:
            return self._mesh_cache[mesh_b]
        rel = self.resolve(mesh_b)
        out = ()
        if rel:
            try:
                with open(os.path.join(S1, rel), 'rb') as f:
                    out = tuple(x for x in F.mesh_info(f.read()).get('mats', ()) if x)
            except OSError:
                out = ()
        self._mesh_cache[mesh_b] = out
        return out

    def obj_materials(self, name_b):
        o = self.objs.get(name_b)
        if o is None:
            return None
        mused = []
        for e in o['entities']:
            m = e.get(b'material', b'')
            if m.strip():
                mused.extend(x.strip() for x in m.split(b';') if x.strip())
            elif e.get(b'file', b'').strip():
                mused.extend(self.mesh_mats(F.base_of(e[b'file'])))
        for ml in o['matlist']:
            if ml.get(b'material', b'').strip():
                mused.append(ml[b'material'].strip())
        return list(dict.fromkeys(mused))

    def _chain(self, name, depth=0):
        m = self.mats.get(name)
        if m is None or depth > 8:
            return {}, []
        alias, tex = {}, []
        p = m['parent']
        if p and p in self.mats and p != name:
            a2, t2 = self._chain(p, depth + 1)
            alias.update(a2)
            tex.extend(t2)
        alias.update(m['alias'])
        tex.extend(m['tex'])
        return alias, tex

    def mat_textures(self, mat_b):
        """[(role, texture_bytes)] for a material, following parents inside all.material."""
        alias, tex = self._chain(mat_b)
        out = [(k, v) for k, v in alias.items() if b'.' in v]
        out += [(b'texture', t) for t in tex if b'.' in t]
        return out


def is_diffuse(role, name_b):
    stem = os.path.splitext(F.disp(F.base_of(name_b)))[0]
    if role in DIFFUSE_ALIASES:
        return not NON_DIFFUSE_NAME.search(stem)
    if role == b'texture':
        return not NON_DIFFUSE_NAME.search(stem)
    return False


# ====================================================================== selection
def npc_top20(cme, mae):
    kv = re.compile(r'^(\w+)=(.*)$')
    pl = collections.Counter()
    names = collections.defaultdict(set)
    scenes = collections.defaultdict(set)
    files = glob.glob(os.path.join(SCN, '*_monster.ini'))
    if not files:
        log('WARN: %s not reachable -> NPC fallback list' % SCN)
        return [(o, 0, 0, 0) for o in NPC_FALLBACK]
    for fn in files:
        with open(fn, 'rb') as f:
            t = f.read().decode('gbk', 'replace')
        cur = None
        ents = []
        for line in t.splitlines():
            line = line.strip()
            if line.startswith('['):
                cur = {}
                ents.append(cur)
                continue
            m = kv.match(line)
            if m and cur is not None:
                cur[m.group(1)] = m.group(2)
        for e in ents:
            r = mae.get(ival(e.get('type')))
            if not r or len(r) < 45:
                continue
            nm = (e.get('name', '') or '').strip()
            if ival(r[13]) != 1 or not nm or e.get('script_id', '-1').strip() in ('-1', ''):
                continue
            obj = cme.get(ival(r[44]))
            if not obj or obj.startswith('npc怪'):
                continue
            pl[obj] += 1
            names[obj].add(nm)
            scenes[obj].add(os.path.basename(fn))
    rank = sorted(pl, key=lambda o: (-pl[o], -len(names[o]), o))[:20]
    return [(o, pl[o], len(names[o]), len(scenes[o])) for o in rank]


def load_tables():
    return dict(ivc={r[0]: r for r in read_table('ItemVisualChar.txt')},
                race=read_table('CharRace.txt'),
                face={r[0]: r for r in read_table('CharFaceGeo.txt')},
                head=read_table('CharHeadGeo.txt'),
                hair={r[0]: r for r in read_table('CharHairGeo.txt')},
                cme={ival(r[0]): r[1] for r in read_table('CharModelEx.txt') if len(r) > 1},
                mae={ival(r[0]): r for r in read_table('MonsterAttrExTable.txt')},
                ew=read_table('Exterior_Weapon.txt'),
                ivl={ival(r[0]): r for r in read_table('ItemVisualLocator.txt')})


class GroupBuilder:
    def __init__(self, src, T):
        self.src = src
        self.T = T
        self.groups = []

    def obj(self, cat, disp_name, label=None, warn=True):
        nb = self.src.obj_by_disp.get(disp_name)
        if nb is None:
            if warn:
                log('WARN: object not in all.obj:', disp_name)
            return
        self.groups.append((cat, label or disp_name, self.src.obj_materials(nb) or []))

    def mats_of(self, mesh, matcol):
        mats = [gb(x.strip()) for x in (matcol or '').split(';') if x.strip()]
        if not mats and mesh:
            mats = list(self.src.mesh_mats(gb(mesh)))
        return mats

    def ivc(self, cat, rid, genders='FM'):
        r = self.T['ivc'].get(rid)
        if not r:
            return
        if 'F' in genders and r[1]:
            self.groups.append((cat, 'IVC %d F %s' % (rid, r[1]), self.mats_of(r[1], r[2])))
        if 'M' in genders and r[12]:
            self.groups.append((cat, 'IVC %d M %s' % (rid, r[12]), self.mats_of(r[12], r[13])))

    def face(self, cat, fid):
        r = self.T['face'].get(fid)
        if r:
            self.groups.append((cat, 'Face %d %s' % (fid, r[2]), self.mats_of(r[2], r[4])))

    def hair(self, cat, hid):
        r = self.T['hair'].get(hid)
        if r:
            self.groups.append((cat, 'Hair %d %s' % (hid, r[2]),
                                self.mats_of(r[2], r[5]) + (self.mats_of(r[3], r[6]) if r[3] else [])))


def build_groups(src):
    """v1 batch 2026-09-12: ordered list of (cat, label, [material bytes])."""
    T = load_tables()
    B = GroupBuilder(src, T)
    ivc, race, face, head, hair, cme = T['ivc'], T['race'], T['face'], T['head'], T['hair'], T['cme']
    face_by_mesh = {r[2]: r for r in face.values()}
    a1 = sorted(n for n in src.obj_by_disp if re.match(r'^(npc)?(女|男)主角', n) and '高模' in n
                and not re.search(r'雕塑|雕像|变身', n))
    a1.sort(key=lambda n: (0 if ('头发' not in n and '脸' not in n) else 1, n))
    for n in a1:
        B.obj('a1', n)
    for r in race:
        if r[0] >= 2 and r[3] in cme:
            B.obj('a2', cme[r[3]], 'Race %d %s' % (r[0], cme[r[3]]))
    for r in race:
        if r[0] >= 2:
            B.face('a2', r[4])
            B.hair('a2', r[5])
    for r in race:
        if r[0] in (0, 1):
            gender = 'F' if cme.get(r[3], '').startswith('女') else 'M'
            for c in (6, 7, 8):
                B.ivc('a3', r[c], gender)
            B.face('a3', r[4])
            B.hair('a3', r[5])
    for r in head:
        fr = face_by_mesh.get(r[2])
        if fr:
            B.face('a3', fr[0])
        else:
            B.groups.append(('a3', 'Head %d %s' % (r[0], r[2]), list(src.mesh_mats(gb(r[2])))))
    for hid, r in sorted(hair.items()):
        if 20307101 <= ival(r[7]) <= 20307110:
            B.hair('a3', hid)
    for rid, r in sorted(ivc.items()):
        if re.match(r'^(女|男)主角.*(高手|高级|高级套装)\.mesh$', r[1] or '') and '雕' not in (r[1] or ''):
            B.ivc('a4', rid)
    for rid, r in sorted(ivc.items()):
        if any('2026' in (r[c] or '') for c in (1, 2, 12, 13)):
            B.ivc('b1', rid)
    for pre, cat in (('ride_2026', 'b2'), ('pet_2026', 'b3')):
        for n in sorted(x for x in src.obj_by_disp if x.startswith(pre)):
            B.obj(cat, n)
    wset = [x for x in src.obj_by_disp if x.startswith(('dweapon_2026', 'dweapon_hj2026'))]
    for r in T['ew']:
        if ival(r[0]) >= 69:
            for c in (9, 10, 11, 12):
                lr = T['ivl'].get(ival(r[c]))
                if lr:
                    for cc in (2, 5):
                        if cc < len(lr) and lr[cc].endswith('.obj') and lr[cc] not in wset:
                            wset.append(lr[cc])
    for n in sorted(wset):
        B.obj('b4', n)
    for n in sorted(x for x in src.obj_by_disp if x.startswith(('top_2026', 'back_2026'))):
        B.obj('b5', n)
    npcs = npc_top20(cme, T['mae'])
    for o, n, nn, ns in npcs:
        B.obj('c1', o, '%s (%d NPC placements, %d names, %d scenes)' % (o, n, nn, ns))
    return B.groups, npcs, T


def build_groups_full(src):
    """Scope 'full' (2026-09-13): every pet / mount / weapon / ornament / player-character model + top-20 NPCs."""
    T = load_tables()
    B = GroupBuilder(src, T)
    cme, mae = T['cme'], T['mae']
    pets = set(n for n in src.obj_by_disp if n.startswith('pet_'))
    for r in read_table('PetAttrTable.txt'):
        m = mae.get(ival(r[0]))
        if m and len(m) > 44 and cme.get(ival(m[44])):
            pets.add(cme[ival(m[44])])
    mounts = set(n for n in src.obj_by_disp if n.startswith('ride_'))
    for r in read_table('CharMount.txt'):
        if len(r) > 3 and cme.get(ival(r[3])):
            mounts.add(cme[ival(r[3])])
    weapons = set(n for n in src.obj_by_disp if n.lower().startswith(('dweapon_', 'weapon')))
    for r in T['ivl'].values():
        for x in r[1:20]:
            if x.endswith('.obj'):
                weapons.add(x)
    ornaments = set(n for n in src.obj_by_disp if n.startswith(('top_', 'back_')))
    players = set(n for n in src.obj_by_disp if '主角' in n and not re.search(r'雕塑|雕像', n))
    for cat, names in (('pet', pets), ('mount', mounts), ('weapon', weapons), ('ornament', ornaments)):
        for n in sorted(names):
            B.obj(cat, n, warn=False)
    for n in sorted(players):
        B.obj('player', n, warn=False)
    for rid in sorted(T['ivc']):
        B.ivc('player', rid)
    for fid in sorted(T['face']):
        B.face('player', fid)
    for hid in sorted(T['hair']):
        B.hair('player', hid)
    npcs = npc_top20(cme, mae)
    for o, n, nn, ns in npcs:
        B.obj('npc', o, '%s (%d NPC placements, %d names, %d scenes)' % (o, n, nn, ns))
    return B.groups, npcs, T


UI_TOKEN = re.compile(rb'[^\x00-\x20"\'<>=:;,()\[\]{}|*?/\\]+\.(?:dds|tga|png|jpg|jpeg|bmp)(?![a-z0-9])', re.I)


def ui_tokens():
    """Every texture-like file name referenced by InterfaceFolder xml/lua/imageset/... (lower-case bytes),
    with and without extension. Names are taken both as GBK bytes and as UTF-8 text (files are mixed)."""
    toks = set()
    for dp, dn, fn in os.walk(os.path.join(S1, 'InterfaceFolder')):
        for f in fn:
            if f.lower().endswith(UI_NAME_EXT):
                with open(os.path.join(dp, f), 'rb') as fh:
                    for m in UI_TOKEN.finditer(fh.read()):
                        t = m.group(0).lower()
                        toks.add(t)
                        toks.add(t.rsplit(b'.', 1)[0])
    return toks


def ui_reason(rel, toks):
    rl = rel.replace('\\', '/').lower()
    if rl.startswith('materialfolder/common/') or '/common/' in '/' + rl:
        return 'UI (MaterialFolder\\Common)'
    if 'screensplit' in rl or 'oceanwaves' in rl or rl.startswith(('interfacefolder/', 'brushesfolder/')):
        return 'UI/terrain folder'
    gbk = F.disk_name_bytes(rel.split('\\')[-1], True).lower()
    forms = set()
    for b in (gbk, F.disp(gbk).encode('utf-8')):
        stem = b.rsplit(b'.', 1)[0]
        forms.update((b, stem))
        m = re.match(rb'^(jpg|tga|png|bmp)_(.+)$', stem)
        if m:                                   # tga_X.dds may be referenced as X.tga
            forms.update((m.group(2), m.group(2) + b'.' + m.group(1)))
    if any(len(f) >= 5 and f in toks for f in forms):
        return 'UI (name referenced by InterfaceFolder)'
    return ''


SEL_HDR = ['order', 'status', 'reason', 'category', 'group', 'texture', 'role', 'relpath', 'fmt', 'w', 'h', 'mips',
           'groups_all', 't1', 'fmt_class']


def t1_set(prev_date):
    """Textures of an earlier batch that failed, needed the blur pre-filter, or were 'look here' (grid > 0.30)."""
    if not prev_date:
        return set()
    pout, _ = out_dirs(prev_date)
    s = set()
    for r in read_manifest(pout):
        g = r.get('grid')
        if r['status'] != 'pass' or r.get('prefilter') or (g not in ('', None) and float(g) > GRID_ATTN):
            s.add(r['source_path'])
    return s


def cmd_select(args):
    out, work = out_dirs(args.date)
    os.makedirs(guard(out), exist_ok=True)
    src = Source()
    full = args.scope == 'full'
    cats = CATS2 if full else CATS
    groups, npcs, T = build_groups_full(src) if full else build_groups(src)
    t1 = t1_set(args.t1_from)
    entries = collections.OrderedDict()   # rel -> entry
    missing = []
    nondiff = collections.Counter()
    for gi, (cat, label, mats) in enumerate(groups):
        for m in mats:
            if m not in src.mats:
                missing.append((cat, label, 'material?', F.disp(m)))
                continue
            for role, t in src.mat_textures(m):
                rel = src.resolve(t)
                if rel is None:
                    missing.append((cat, label, 'texture?', F.disp(t)))
                    continue
                diff = is_diffuse(role, t)
                e = entries.get(rel)
                if e is None:
                    e = entries[rel] = {'rel': rel, 'name': F.disp(F.base_of(t)), 'roles': [], 'groups': [],
                                        'diffuse': False, 'first': None}
                if role.decode('latin-1') not in e['roles']:
                    e['roles'].append(role.decode('latin-1'))
                if diff:
                    e['diffuse'] = True
                    if e['first'] is None:
                        e['first'] = (list(cats).index(cat), gi, cat, label)
                if (cat, label) not in e['groups']:
                    e['groups'].append((cat, label))
                if not diff:
                    nondiff[role.decode('latin-1')] += 1
    blob = ui_tokens()
    rows = []
    counts = collections.Counter()
    for e in entries.values():
        inf = src.info.get(e['rel'])
        fmt, w, h, mips = inf if inf else ('?', 0, 0, 0)
        reason = ''
        if not e['diffuse']:
            reason = 'not a diffuse slot (%s)' % ','.join(e['roles'])
        elif not e['rel'].lower().endswith('.dds') or fmt.startswith('NOT-'):
            reason = 'not a DDS (%s)' % fmt
        elif fmt not in ('DXT1', 'DXT3', 'DXT5', 'A8R8G8B8', 'X8R8G8B8'):
            reason = 'format %s not handled' % fmt
        elif max(w, h) > MAX_SRC:
            reason = 'larger than %d px (%dx%d)' % (MAX_SRC, w, h)
        elif min(w, h) < MIN_SRC:
            reason = 'tiny (%dx%d)' % (w, h)
        elif full and max(w, h) < MIN_LONG:
            reason = 'smaller than %d px (%dx%d)' % (MIN_LONG, w, h)
        elif full and max(w, h) <= 64 and HAIR_RE.search(e['name']):
            reason = 'hair <= 64 px (%dx%d)' % (w, h)
        else:
            reason = ui_reason(e['rel'], blob)
        first = e['first'] or (99, 0, e['groups'][0][0], e['groups'][0][1])
        is_t1 = os.path.join(S1, e['rel']) in t1
        fcls = 0 if fmt != 'DXT1' else (1 if max(w, h) <= 256 else 2)
        e.update(fmt=fmt, w=w, h=h, mips=mips, status='skip' if reason else 'todo', reason=reason, sort=first,
                 t1=1 if is_t1 else 0, fcls=fcls)
        counts[(first[2], e['status'])] += 1
        rows.append(e)
    if full:
        rows.sort(key=lambda e: (e['status'] != 'todo', -e['t1'], e['fcls'], e['sort'][0], e['sort'][1], e['rel']))
    else:
        rows.sort(key=lambda e: (e['status'] != 'todo', e['sort'][0], e['sort'][1], e['rel']))
    path = guard(os.path.join(out, 'selection.tsv'))
    with open(path, 'w', encoding='utf-8-sig', newline='\n') as f:
        f.write('\t'.join(SEL_HDR) + '\n')
        for i, e in enumerate(rows):
            f.write('\t'.join(str(x) for x in (
                i, e['status'], e['reason'], e['sort'][2], e['sort'][3], e['name'], ','.join(e['roles']), e['rel'],
                e['fmt'], e['w'], e['h'], e['mips'], ' | '.join('%s:%s' % g for g in e['groups']), e['t1'],
                e['fcls'])) + '\n')
    todo = [e for e in rows if e['status'] == 'todo']
    summ = {'tool': 'upscale_pack.py ' + TOOL_VERSION, 'date': args.date, 'scope': args.scope,
            't1_from': args.t1_from, 'selected_todo': len(todo), 't1_todo': sum(e['t1'] for e in todo),
            'todo_mpx': round(sum(e['w'] * e['h'] for e in todo) / 1e6, 1),
            'todo_by_format': dict(collections.Counter(e['fmt'] for e in todo)),
            'todo_by_class': dict(collections.Counter(('DXT3/5/ARGB', 'DXT1<=256', 'DXT1>256')[e['fcls']] for e in todo)),
            'skipped': dict(collections.Counter(re.sub(r' \(.*', '', e['reason']) for e in rows if e['status'] == 'skip')),
            'by_category': {c: {s: counts[(c, s)] for s in ('todo', 'skip')} for c in cats},
            'non_diffuse_role_refs': dict(nondiff), 'unresolved': len(missing), 'npc_top20': npcs}
    if not full:
        summ['estimate_sets'] = estimate_sets(src, T)
    with open(guard(os.path.join(out, 'selection_summary.json')), 'w', encoding='utf-8') as f:
        json.dump(summ, f, ensure_ascii=False, indent=1)
    if missing:
        with open(guard(os.path.join(out, 'selection_unresolved.tsv')), 'w', encoding='utf-8-sig', newline='\n') as f:
            f.write('category\tgroup\tkind\tname\n')
            for m in missing:
                f.write('\t'.join(m) + '\n')
    log('selection (%s): %d todo (%d t1, %.0f Mpx), %d skipped -> %s' % (
        args.scope, len(todo), summ['t1_todo'], summ['todo_mpx'], len(rows) - len(todo), path))
    for c in cats:
        log('  %-8s %-5d todo %-5d skip  %s' % (c, counts[(c, 'todo')], counts[(c, 'skip')], cats[c]))
    log('  by class: %s  formats: %s' % (summ['todo_by_class'], summ['todo_by_format']))
    log('  skipped by reason: %s' % summ['skipped'])


def estimate_sets(src, T):
    """Whole-category counts (diffuse textures) for the throughput estimate: player / mount / pet / weapon."""
    sets = collections.OrderedDict((k, set()) for k in ('player', 'mount', 'pet', 'weapon'))
    objs = collections.defaultdict(set)
    for n in src.obj_by_disp:
        if '主角' in n and not re.search(r'雕塑|雕像', n):
            objs['player'].add(n)
        if n.startswith('ride_'):
            objs['mount'].add(n)
        if n.startswith('pet_'):
            objs['pet'].add(n)
        if n.lower().startswith(('dweapon_', 'weapon')):
            objs['weapon'].add(n)
    for r in read_table('CharMount.txt'):
        if len(r) > 3 and T['cme'].get(ival(r[3])):
            objs['mount'].add(T['cme'][ival(r[3])])
    for r in read_table('PetAttrTable.txt'):
        m = T['mae'].get(ival(r[0]))
        if m and len(m) > 44 and T['cme'].get(ival(m[44])):
            objs['pet'].add(T['cme'][ival(m[44])])
    for r in T['ivl'].values():
        for x in r[1:20]:
            if x.endswith('.obj'):
                objs['weapon'].add(x)
    mats = collections.defaultdict(list)
    for k, names in objs.items():
        for n in names:
            nb = src.obj_by_disp.get(n)
            if nb is not None:
                mats[k].extend(src.obj_materials(nb) or [])
    for r in T['ivc'].values():
        for mesh, mc in ((r[1], r[2]), (r[12], r[13])):
            if mesh:
                mats['player'].extend(gb(x.strip()) for x in (mc or '').split(';') if x.strip())
    for r in T['face'].values():
        mats['player'].append(gb(r[4]))
    for r in T['hair'].values():
        mats['player'].extend(gb(x) for x in (r[5], r[6]) if x)
    for k, ml in mats.items():
        for m in set(ml):
            for role, t in src.mat_textures(m):
                if is_diffuse(role, t):
                    rel = src.resolve(t)
                    if rel:
                        sets[k].add(rel)
    out = collections.OrderedDict()
    allset = set()
    for k, s in list(sets.items()) + [('ALL', None)]:
        s = allset if s is None else s
        if k != 'ALL':
            allset |= s
        fm = collections.Counter()
        n_in = 0
        mpx = 0.0
        big = 0
        for rel in s:
            inf = src.info.get(rel)
            if not inf:
                continue
            fmt, w, h, mips = inf
            if fmt in ('DXT1', 'DXT3', 'DXT5', 'A8R8G8B8', 'X8R8G8B8') and MIN_SRC <= min(w, h) and max(w, h) <= MAX_SRC:
                n_in += 1
                mpx += w * h / 1e6
                fm[fmt] += 1
            elif max(w, h) > MAX_SRC:
                big += 1
        out[k] = {'textures': len(s), 'in_scope': n_in, 'mpx': round(mpx, 1), 'over_1024': big, 'formats': dict(fm)}
    return out


def read_selection(out):
    rows = []
    with open(os.path.join(out, 'selection.tsv'), encoding='utf-8-sig') as f:
        hdr = f.readline().rstrip('\n').split('\t')
        for ln in f:
            r = dict(zip(hdr, ln.rstrip('\n').split('\t')))
            rows.append(r)
    return rows


# ====================================================================== DDS decode / encode (numpy)
class Unsupported(Exception):
    pass


def dds_header(data):
    if len(data) < 128 or data[:4] != b'DDS ':
        raise Unsupported('not a DDS')
    flags, h, w, pitch, depth, mips = struct.unpack_from('<6I', data, 8)
    pf_flags = struct.unpack_from('<I', data, 80)[0]
    fourcc = data[84:88]
    bits, rm, gm, bm, am = struct.unpack_from('<5I', data, 88)
    caps2 = struct.unpack_from('<I', data, 112)[0]
    return dict(flags=flags, h=h, w=w, pitch=pitch, mips=mips, pf_flags=pf_flags, fourcc=fourcc, bits=bits,
                masks=(rm, gm, bm, am), caps2=caps2)


def fmt_name(H):
    if H['pf_flags'] & 4:
        return H['fourcc'].decode('latin-1')
    if H['bits'] == 32:
        if H['masks'][0] == 0xFF0000:
            return 'A8R8G8B8' if (H['pf_flags'] & 1 and H['masks'][3]) else 'X8R8G8B8'
        return 'A8B8G8R8' if (H['pf_flags'] & 1 and H['masks'][3]) else 'X8B8G8R8'
    return 'RGB%d' % H['bits']


def _bits_idx(blk, start, nbytes, nbits):
    v = np.zeros(len(blk), np.uint64)
    for k in range(nbytes):
        v |= blk[:, start + k].astype(np.uint64) << np.uint64(8 * k)
    sh = np.arange(16, dtype=np.uint64) * np.uint64(nbits)
    return ((v[:, None] >> sh[None, :]) & np.uint64((1 << nbits) - 1)).astype(np.intp)


def _colour_block(blk, off, allow3):
    c0 = blk[:, off].astype(np.int32) | (blk[:, off + 1].astype(np.int32) << 8)
    c1 = blk[:, off + 2].astype(np.int32) | (blk[:, off + 3].astype(np.int32) << 8)

    def ex(c):
        r = (c >> 11) & 31
        g = (c >> 5) & 63
        b = c & 31
        return np.stack([(r << 3) | (r >> 2), (g << 2) | (g >> 4), (b << 3) | (b >> 2)], 1)
    p0, p1 = ex(c0), ex(c1)
    four = (c0 > c1) if allow3 else np.ones(len(blk), bool)
    f = four[:, None]
    p2 = np.where(f, (2 * p0 + p1 + 1) // 3, (p0 + p1 + 1) // 2)
    p3 = np.where(f, (p0 + 2 * p1 + 1) // 3, 0)
    pal = np.stack([p0, p1, p2, p3], 1)
    idx = _bits_idx(blk, off + 4, 4, 2)
    rgb = pal[np.arange(len(blk))[:, None], idx]
    a = np.full(idx.shape, 255, np.int32)
    if allow3:
        a[(~four)[:, None] & (idx == 3)] = 0
    return rgb, a


def _alpha_bc2(blk):
    nib = np.empty((len(blk), 16), np.int32)
    for k in range(8):
        b = blk[:, k].astype(np.int32)
        nib[:, 2 * k] = b & 15
        nib[:, 2 * k + 1] = b >> 4
    return nib * 17


def _alpha_bc3(blk):
    a0 = blk[:, 0].astype(np.int32)
    a1 = blk[:, 1].astype(np.int32)
    p8 = [((7 - j) * a0 + j * a1 + 3) // 7 for j in range(1, 7)]
    p6 = [((5 - j) * a0 + j * a1 + 2) // 5 for j in range(1, 5)]
    pal8 = np.stack([a0, a1] + p8, 1)
    pal6 = np.stack([a0, a1] + p6 + [np.zeros_like(a0), np.full_like(a0, 255)], 1)
    pal = np.where((a0 > a1)[:, None], pal8, pal6)
    idx = _bits_idx(blk, 2, 6, 3)
    return pal[np.arange(len(blk))[:, None], idx]


def decode_dds(data):
    """Top mip level -> (RGBA uint8 HxWx4, header dict, format name)."""
    H = dds_header(data)
    w, h = H['w'], H['h']
    if H['caps2'] & 0x200 or H['caps2'] & 0x200000:
        raise Unsupported('cubemap/volume')
    fmt = fmt_name(H)
    if H['pf_flags'] & 4:
        bw, bh = max(1, (w + 3) // 4), max(1, (h + 3) // 4)
        n = bw * bh
        if fmt == 'DXT1':
            blk = np.frombuffer(data, np.uint8, n * 8, 128).reshape(n, 8)
            rgb, a = _colour_block(blk, 0, True)
        elif fmt in ('DXT3', 'DXT5'):
            blk = np.frombuffer(data, np.uint8, n * 16, 128).reshape(n, 16)
            a = _alpha_bc2(blk) if fmt == 'DXT3' else _alpha_bc3(blk)
            rgb, _ = _colour_block(blk, 8, False)
        else:
            raise Unsupported('fourcc ' + fmt)
        px = np.concatenate([rgb, a[:, :, None]], 2).astype(np.uint8)
        px = px.reshape(bh, bw, 4, 4, 4).transpose(0, 2, 1, 3, 4).reshape(bh * 4, bw * 4, 4)
        return np.ascontiguousarray(px[:h, :w]), H, fmt
    if H['bits'] != 32 or not (H['pf_flags'] & 0x40):
        raise Unsupported('uncompressed layout ' + fmt)
    v = np.frombuffer(data, '<u4', w * h, 128).reshape(h, w)
    out = np.empty((h, w, 4), np.uint8)
    for i, m in enumerate(H['masks']):
        if i == 3 and not (H['pf_flags'] & 1 and m):
            out[..., 3] = 255
            continue
        sh = (m & -m).bit_length() - 1 if m else 0
        width = bin(m).count('1')
        ch = (v & m) >> sh if m else np.zeros_like(v)
        out[..., i] = ch if width == 8 else (ch * 255 // max(1, (1 << width) - 1))
    return out, H, fmt


def write_dds_bgra(path, rgba):
    """Uncompressed legacy A8R8G8B8 DDS (UNORM) - texconv input without any colour-space metadata."""
    h, w = rgba.shape[:2]
    hdr = bytearray(128)
    struct.pack_into('<4s7I', hdr, 0, b'DDS ', 124, 0x100F, h, w, w * 4, 0, 1)
    struct.pack_into('<8I', hdr, 76, 32, 0x41, 0, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
    struct.pack_into('<I', hdr, 108, 0x1000)
    with open(guard(path), 'wb') as f:
        f.write(hdr)
        f.write(np.ascontiguousarray(rgba[..., [2, 1, 0, 3]]).tobytes())


def pushpull_fill(rgb, valid):
    """Fill texels where valid==False from valid neighbours (multi-scale push-pull). float32 in/out."""
    levels = []
    c = rgb * valid[..., None]
    wgt = valid.astype(np.float32)
    while True:
        levels.append((c, wgt))
        h, w = wgt.shape
        if h == 1 and w == 1:
            break
        ph, pw = h + (h & 1), w + (w & 1)
        if (ph, pw) != (h, w):
            c = np.pad(c, ((0, ph - h), (0, pw - w), (0, 0)))
            wgt = np.pad(wgt, ((0, ph - h), (0, pw - w)))
        c = c.reshape(ph // 2, 2, pw // 2, 2, 3).sum((1, 3))
        wgt = wgt.reshape(ph // 2, 2, pw // 2, 2).sum((1, 3))
    c, wgt = levels[-1]
    col = c / np.maximum(wgt, 1e-8)[..., None]
    for c, wgt in reversed(levels[:-1]):
        h, w = wgt.shape
        up = np.repeat(np.repeat(col, 2, 0), 2, 1)[:h, :w]
        cur = c / np.maximum(wgt, 1e-8)[..., None]
        col = np.where((wgt > 0)[..., None], cur, up)
    return col


def snap_alpha(a, a2):
    """Where the source alpha is constant over the 3x3 neighbourhood keep the source value exactly (2026-09-12
    pilot: otherwise 80-97 % of transparent interiors came back as alpha 1..11 = a veil on alpha-blended hair)."""
    h, w = a.shape
    pad = np.pad(a, 1, mode='edge')
    nb = [pad[dy:dy + h, dx:dx + w] for dy in range(3) for dx in range(3)]
    flat = np.minimum.reduce(nb) == np.maximum.reduce(nb)
    flat2 = np.repeat(np.repeat(flat, 2, 0), 2, 1)
    return np.where(flat2, np.repeat(np.repeat(a, 2, 0), 2, 1), a2).astype(np.uint8), float(flat.mean())


# ====================================================================== checks
def lanczos(arr, size):
    return np.asarray(Image.fromarray(arr).resize(size, Image.LANCZOS))


def run_checks(orig, out, has_alpha, filled):
    h, w = orig.shape[:2]
    res = {'notes': []}
    red = lanczos(np.ascontiguousarray(out[..., :3]), (w, h)).astype(np.float32)
    if not np.isfinite(red).all():
        return dict(res, fail=['NaN in output'])
    o = orig[..., :3].astype(np.float32)
    diff = np.abs(red - o).mean(axis=2)
    opq = orig[..., 3] >= 128 if has_alpha else np.ones((h, w), bool)
    if opq.mean() < 0.02:
        opq = np.ones((h, w), bool)
        res['notes'].append('few opaque texels: checks over all texels')
    res['mad'] = float(diff[opq].mean())
    res['mad_all'] = float(diff.mean())
    ts = max(8, min(32, w // 8, h // 8))
    th, tw = h // ts, w // ts
    d_t = diff[:th * ts, :tw * ts].reshape(th, ts, tw, ts)
    m_t = opq[:th * ts, :tw * ts].reshape(th, ts, tw, ts)
    n_t = m_t.sum((1, 3))
    s_t = (d_t * m_t).sum((1, 3))
    ok = n_t >= 0.25 * ts * ts
    tile = np.where(ok, s_t / np.maximum(n_t, 1), 0)
    res['tile_max'] = float(tile.max()) if tile.size else 0.0
    lum_o = (o @ np.array([.299, .587, .114], np.float32))[:th * ts, :tw * ts].reshape(th, ts, tw, ts).mean((1, 3))
    lum_n = (red @ np.array([.299, .587, .114], np.float32))[:th * ts, :tw * ts].reshape(th, ts, tw, ts).mean((1, 3))
    black = int(((lum_n < 4) & (lum_o > 24) & ok).sum())
    mo = o[opq].mean(0)
    mn = red[opq].mean(0)
    res['mean_shift'] = float(np.abs(mn - mo).max())
    res['mean_src'] = [round(float(x), 1) for x in mo]
    res['mean_out'] = [round(float(x), 1) for x in mn]
    res['cov_src'] = float((orig[..., 3] >= 128).mean())
    res['cov_out'] = float((out[..., 3] >= 128).mean())
    res['alpha_mad'] = 0.0
    res['alpha_tile_max'] = 0.0
    if has_alpha:
        ared = lanczos(np.ascontiguousarray(out[..., 3]), (w, h)).astype(np.float32)
        ad = np.abs(ared - orig[..., 3].astype(np.float32))
        res['alpha_mad'] = float(ad.mean())
        at = ad[:th * ts, :tw * ts].reshape(th, ts, tw, ts).mean((1, 3))
        res['alpha_tile_max'] = float(at.max()) if at.size else 0.0
    fail = []
    if res['mad'] > MAD_MAX:
        fail.append('MAD %.1f > %g' % (res['mad'], MAD_MAX))
    if has_alpha and not filled and res['mad_all'] > MAD_MAX:
        fail.append('MAD(all texels) %.1f > %g' % (res['mad_all'], MAD_MAX))
    if res['tile_max'] > TILE_MAD_MAX:
        fail.append('broken tile (MAD %.0f)' % res['tile_max'])
    if black:
        fail.append('%d black tile(s)' % black)
    if res['mean_shift'] > MEAN_SHIFT_MAX:
        fail.append('mean colour shift %.1f' % res['mean_shift'])
    if abs(res['cov_out'] - res['cov_src']) > COV_TOL:
        fail.append('alpha coverage %.3f -> %.3f' % (res['cov_src'], res['cov_out']))
    if res['alpha_tile_max'] > ALPHA_TILE_MAX:
        fail.append('local alpha change (tile MAD %.0f)' % res['alpha_tile_max'])
    res['fail'] = fail
    return res


def grid_score(src, dst):
    """Period-2 lattice artefact score (ESRGAN can turn DXT1 dither into a visible grid; the MAD check cannot see
    it because the lattice vanishes when the 2x result is reduced back). Per 2x2 output block (both alignments)
    the checkerboard response |a-b-c+d|/4 of luminance; per 16x16-source-texel tile: mean response divided by
    (mean source gradient + 2). Returns the 99th-percentile tile score."""
    h, w = src.shape[:2]
    wv = np.array([.299, .587, .114], np.float32)
    lum = dst[..., :3].astype(np.float32) @ wv
    best = np.zeros((h, w), np.float32)
    for oy in (0, 1):
        for ox in (0, 1):
            L = lum[oy:2 * h - oy, ox:2 * w - ox]
            hh, ww = L.shape[0] // 2, L.shape[1] // 2
            b = L[:2 * hh, :2 * ww].reshape(hh, 2, ww, 2)
            c = np.abs(b[:, 0, :, 0] - b[:, 0, :, 1] - b[:, 1, :, 0] + b[:, 1, :, 1]) / 4
            best[:hh, :ww] = np.maximum(best[:hh, :ww], c)
    sl = src[..., :3].astype(np.float32) @ wv
    g = np.zeros_like(sl)
    g[:, 1:] += np.abs(np.diff(sl, axis=1))
    g[1:, :] += np.abs(np.diff(sl, axis=0))
    opq = src[..., 3] >= 128
    ts = 16
    th, tw = h // ts, w // ts
    if th == 0 or tw == 0:
        return 0.0
    R = (best * opq)[:th * ts, :tw * ts].reshape(th, ts, tw, ts).sum((1, 3))
    G = (g * opq)[:th * ts, :tw * ts].reshape(th, ts, tw, ts).sum((1, 3))
    N = opq[:th * ts, :tw * ts].reshape(th, ts, tw, ts).sum((1, 3))
    ok = N > ts * ts * 0.5
    if not ok.any():
        return 0.0
    s = (R / np.maximum(N, 1)) / (G / np.maximum(N, 1) + 2.0)
    return float(np.percentile(s[ok], 99))


def risk_of(chk, g):
    """Worst check relative to its limit (< 1 for a passing candidate); used to rank passing variants."""
    return max(chk.get('mad', 99) / MAD_MAX, chk.get('tile_max', 999) / TILE_MAD_MAX,
               chk.get('mean_shift', 99) / MEAN_SHIFT_MAX,
               abs(chk.get('cov_out', 0) - chk.get('cov_src', 0)) / COV_TOL,
               chk.get('alpha_tile_max', 0) / ALPHA_TILE_MAX, g / GRID_FAIL)


def pick_crop(img, size):
    h, w = img.shape[:2]
    s = min(size, h, w)
    lum = img[..., :3].astype(np.float32) @ np.array([.299, .587, .114], np.float32)
    e = np.zeros_like(lum)
    e[:, 1:] += np.abs(np.diff(lum, axis=1))
    e[1:, :] += np.abs(np.diff(lum, axis=0))
    e *= (img[..., 3] >= 128)
    ii = np.pad(e, ((1, 0), (1, 0))).cumsum(0).cumsum(1)
    best, bx, by = -1.0, 0, 0
    step = max(8, s // 4)
    for y in list(range(0, h - s + 1, step)) + [h - s]:
        for x in list(range(0, w - s + 1, step)) + [w - s]:
            v = ii[y + s, x + s] - ii[y, x + s] - ii[y + s, x] + ii[y, x]
            if v > best:
                best, bx, by = v, x, y
    return bx, by, s


def save_webp(arr, path, q=95):
    Image.fromarray(np.ascontiguousarray(arr)).save(guard(path), 'WEBP', quality=q, method=4)


# ====================================================================== manifest
MAN_HDR = ['order', 'category', 'group', 'texture', 'source_path', 'source_sha256', 'output_path', 'output_sha256',
           'src_w', 'src_h', 'out_w', 'out_h', 'src_fmt', 'out_fmt', 'src_mips', 'out_mips', 'alpha', 'fill',
           'mad', 'mad_all', 'tile_mad_max', 'mean_shift', 'mean_src', 'mean_out', 'alpha_cov_src', 'alpha_cov_out',
           'alpha_mad', 'alpha_tile_max', 'alpha_snapped', 'grid', 'prefilter',
           'status', 'reason', 't_prep', 't_gpu', 't_post', 'bytes_src', 'bytes_out', 'tid', 'groups_all',
           'variant', 'variants_tried', 'risk', 'batch_src', 't_eval', 't1']


def read_manifest(out):
    """Rows of <out>\\manifest.tsv, one per texture (append-only log: the LAST row of a texture wins). Rows are
    mapped by their own width, so files whose header predates a newer MAN_HDR still read correctly."""
    p = os.path.join(out, 'manifest.tsv')
    rows = []
    if os.path.exists(p):
        with open(p, encoding='utf-8-sig') as f:
            hdr = f.readline().rstrip('\n').split('\t')
            for ln in f:
                if not ln.endswith('\n'):          # ignore a line still being written
                    continue
                cells = ln.rstrip('\n').split('\t')
                if len(cells) == len(hdr):
                    r = dict(zip(hdr, cells))
                elif len(cells) == len(MAN_HDR):
                    r = dict(zip(MAN_HDR, cells))
                else:
                    continue
                for k in MAN_HDR:
                    r.setdefault(k, '')
                rows.append(r)
    last = {r['source_path']: r for r in rows}
    seen = set()
    uniq = []
    for r in rows:
        if r['source_path'] not in seen:
            seen.add(r['source_path'])
            uniq.append(last[r['source_path']])
    return uniq


def append_rows(path, rows):
    with LOCK:
        new = not os.path.exists(path)
        with open(guard(path), 'a', encoding='utf-8-sig' if new else 'utf-8', newline='\n') as f:
            if new:
                f.write('\t'.join(MAN_HDR) + '\n')
            for row in rows:
                f.write('\t'.join(str(row.get(k, '')).replace('\t', ' ').replace('\n', ' ') for k in MAN_HDR) + '\n')


# ====================================================================== GPU (realesrgan), watched
class GpuFallback(RuntimeError):
    """realesrgan did not run on the GPU (see watchdog in esrgan())."""


_K32 = ctypes.WinDLL('kernel32', use_last_error=True) if os.name == 'nt' else None
ESRGAN_AFFINITY = 0xF                      # 4 logical cores: even a CPU fallback can never flood the machine
PASS_BASE_S, PASS_PER_MPX_S = 4.4, 7.3     # one x4plus pass on the RTX 2060 (auto tile), measured 2026-09-12


def esrgan(inp, outp, mpx, model='realesrgan-x4plus', scale=4):
    """One Real-ESRGAN pass, one process, watched. 2026-09-12 15:17 the ncnn process silently ran the model on
    the CPU (~30 logical cores busy, GPU idle at 300 MHz); 18:00 it was starved at BelowNormal priority while
    other agents compiled C++. Guards: normal priority + 4-core affinity, a per-pass limit of 6x the measured
    x4plus time (>= 45 s) and the ncnn device line '[0 NVIDIA ...]'. Violations raise GpuFallback."""
    if os.path.exists(outp):
        os.remove(guard(outp))
    limit = max(45.0, 6.0 * (PASS_BASE_S + PASS_PER_MPX_S * mpx))
    p = subprocess.Popen([ESRGAN, '-i', inp, '-o', guard(outp), '-s', str(scale), '-n', model,
                          '-m', ESRGAN_MODELS, '-j', '1:1:1', '-g', '0', '-f', 'png'],
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                         creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
    if _K32 is not None:
        _K32.SetProcessAffinityMask(ctypes.c_void_p(int(p._handle)), ctypes.c_size_t(ESRGAN_AFFINITY))
    buf = []
    reader = threading.Thread(target=lambda: buf.append(p.stdout.read()), daemon=True)
    reader.start()
    t0 = time.time()
    while p.poll() is None:
        if time.time() - t0 > limit:
            p.kill()
            p.wait()
            reader.join(5)
            raise GpuFallback('pass exceeded %.0f s (x4plus GPU model %.1f s): realesrgan CPU-starved or on the CPU'
                              % (limit, limit / 6))
        time.sleep(0.1)
    reader.join(10)
    txt = (buf[0] if buf else b'').decode('utf-8', 'replace')
    if '[0 NVIDIA' not in txt:
        raise GpuFallback('no GPU device line in realesrgan output: %r' % txt[-160:])
    if p.returncode != 0 or not os.path.exists(outp):
        raise RuntimeError('realesrgan rc=%s %s' % (p.returncode, txt[-300:].strip()))


# ====================================================================== per-texture job + cascade
class Job:
    def __init__(self, sel, out, work):
        self.sel = sel
        self.rel = sel['relpath']
        self.tid = hashlib.sha1(self.rel.encode('utf-8', 'surrogatepass')).hexdigest()[:12]
        self.src_path = os.path.join(S1, self.rel)
        self.out_path = os.path.join(out, self.rel)
        self.work = work
        self.row = {k: '' for k in MAN_HDR}
        self.full_cascade = sel.get('t1') == '1'
        self.row.update(order=sel['order'], category=sel['category'], group=sel['group'], texture=sel['texture'],
                        source_path=self.src_path, tid=self.tid, groups_all=sel['groups_all'],
                        t1='1' if self.full_cascade else '')
        self.err = None
        self.t = {'prep': 0.0, 'gpu': 0.0, 'eval': 0.0, 'post': 0.0}
        self.results = collections.OrderedDict()
        self.merged = {}
        self.alpha_done = set()
        self.orig = self.rgb_base = self.alpha = None

    def p(self, suffix):
        return os.path.join(self.work, 'tmp', self.tid + suffix)


def prep(job):
    t0 = time.time()
    try:
        with open(job.src_path, 'rb') as f:
            data = f.read()
        job.row['source_sha256'] = hashlib.sha256(data).hexdigest()
        job.row['bytes_src'] = len(data)
        rgba, H, fmt = decode_dds(data)
        job.orig = rgba
        h, w = rgba.shape[:2]
        job.row.update(src_w=w, src_h=h, src_fmt=fmt, src_mips=H['mips'])
        a = rgba[..., 3]
        job.has_alpha = bool(a.min() < 255)
        uniq = np.unique(a)
        job.alpha_kind = 'none' if not job.has_alpha else ('1bit' if set(uniq.tolist()) <= {0, 255} else 'full')
        rgb = rgba[..., :3]
        job.filled = False
        zero = a == 0
        if job.has_alpha and zero.any() and zero.mean() < 0.98:
            blackish = float((rgb[zero].max(1) <= 12).mean())
            if blackish >= 0.9:
                filled = pushpull_fill(rgb.astype(np.float32), ~zero)
                rgb = np.where(zero[..., None], np.clip(np.rint(filled), 0, 255).astype(np.uint8), rgb)
                job.filled = True
        job.rgb_base = np.ascontiguousarray(rgb)
        job.alpha = np.ascontiguousarray(a)
        job.row.update(alpha=job.alpha_kind, fill='y' if job.filled else '')
        if fmt == 'DXT1':
            job.enc = 'BC1_UNORM'
        elif fmt in ('DXT3', 'DXT5'):
            job.enc = 'BC3_UNORM' if job.has_alpha else 'BC1_UNORM'
        elif fmt == 'A8R8G8B8':
            job.enc = 'B8G8R8A8_UNORM'
        elif fmt == 'X8R8G8B8':
            job.enc = 'B8G8R8X8_UNORM'
        else:
            raise Unsupported('format ' + fmt)
    except Exception as ex:  # noqa: BLE001
        job.err = 'prep: %s: %s' % (type(ex).__name__, ex)
    job.t['prep'] = time.time() - t0
    return job


def _akey(spec):
    return '%s-x%d' % (spec['model'], spec['scale'])


def gpu_variant(job, v):
    """RGB (and, once per model, alpha) of one variant through realesrgan. GpuFallback propagates."""
    spec = VARIANTS[v]
    t0 = time.time()
    h, w = job.orig.shape[:2]
    mpx = w * h / 1e6
    try:
        rgb = job.rgb_base
        if spec['blur']:
            rgb = np.asarray(Image.fromarray(rgb).filter(ImageFilter.GaussianBlur(spec['blur'])))
        pin = job.p('_%s_rgb.png' % v)
        Image.fromarray(np.ascontiguousarray(rgb)).save(guard(pin))
        esrgan(pin, job.p('_%s_rgb_x.png' % v), mpx, spec['model'], spec['scale'])
        if job.has_alpha and _akey(spec) not in job.alpha_done:
            pa = job.p('_a.png')
            if not os.path.exists(pa):
                Image.fromarray(np.ascontiguousarray(np.repeat(job.alpha[..., None], 3, 2))).save(guard(pa))
            esrgan(pa, job.p('_%s_a_x.png' % _akey(spec)), mpx, spec['model'], spec['scale'])
            job.alpha_done.add(_akey(spec))
    finally:
        job.t['gpu'] += time.time() - t0


def eval_variant(job, v):
    """Build the 2x RGBA candidate of variant v and run every check on it (pre-encode)."""
    spec = VARIANTS[v]
    s = spec['scale']
    t0 = time.time()
    h, w = job.orig.shape[:2]
    try:
        with Image.open(job.p('_%s_rgb_x.png' % v)) as im:
            if im.size != (s * w, s * h):
                raise RuntimeError('%s output %dx%d, expected %dx%d' % (v, im.size[0], im.size[1], s * w, s * h))
            im2 = im.convert('RGB')
            rgb2 = np.asarray(im2 if s == 2 else im2.resize((2 * w, 2 * h), Image.LANCZOS))
        snapped = ''
        if job.has_alpha:
            with Image.open(job.p('_%s_a_x.png' % _akey(spec))) as ima:
                if ima.size != (s * w, s * h):
                    raise RuntimeError('%s alpha output %dx%d' % (v, ima.size[0], ima.size[1]))
                ima2 = ima.convert('L')
                a2 = np.asarray(ima2 if s == 2 else ima2.resize((2 * w, 2 * h), Image.LANCZOS))
            a2, snapped = snap_alpha(job.alpha, a2)
        else:
            a2 = np.full((2 * h, 2 * w), 255, np.uint8)
        merged = np.ascontiguousarray(np.dstack([rgb2, a2]))
        chk = run_checks(job.orig, merged, job.has_alpha, job.filled)
        g = grid_score(job.orig, merged)
        fails = list(chk['fail'])
        if g > GRID_FAIL:
            fails.append('lattice artefact (grid %.2f > %.2f)' % (g, GRID_FAIL))
        job.results[v] = dict(chk, grid=g, fails=fails, ok=not fails, risk=risk_of(chk, g), snapped=snapped)
        job.merged[v] = merged
    except Exception as ex:  # noqa: BLE001
        job.results[v] = {'ok': False, 'fails': ['%s: %s' % (type(ex).__name__, ex)], 'risk': 99.0, 'grid': -1.0}
    finally:
        for suf in ('_%s_rgb.png' % v, '_%s_rgb_x.png' % v):
            try:
                os.remove(guard(job.p(suf)))
            except OSError:
                pass
        job.t['eval'] += time.time() - t0


def ranked_variants(job):
    ok = [(res['risk'], CASCADE.index(v), v) for v, res in job.results.items() if res.get('ok')]
    if not ok:
        return []
    best = min(r for r, _, _ in ok)
    first = min((i, v) for r, i, v in ok if r <= best + RISK_TIE)[1]
    return [first] + [v for r, i, v in sorted(ok) if v != first]


def tried_summary(job):
    return ';'.join('%s:%s:r%.2f:g%.2f' % (v, 'P' if res.get('ok') else 'F', res.get('risk', 99), res.get('grid', -1))
                    for v, res in job.results.items())


def encode(job, merged, work):
    """texconv the 2x candidate; returns (enc_path, decoded top level, header, fourcc, header problems)."""
    h, w = job.orig.shape[:2]
    src_dds = job.p('_2x.dds')
    write_dds_bgra(src_dds, merged)
    encdir = os.path.join(work, 'enc')
    enc = os.path.join(encdir, job.tid + '_2x.dds')
    if os.path.exists(enc):
        os.remove(guard(enc))
    try:
        r = subprocess.run([TEXCONV, '-nologo', '-y', '-nogpu', '--single-proc', '-dx9', '-m', '0', '-f', job.enc,
                            '-o', guard(encdir), src_dds],
                           capture_output=True, text=True, errors='replace', timeout=600, creationflags=LOW_PRIO)
    finally:
        try:
            os.remove(guard(src_dds))
        except OSError:
            pass
    if r.returncode != 0 or not os.path.exists(enc):
        raise RuntimeError('texconv rc=%s %s' % (r.returncode, (r.stdout + r.stderr)[-300:].strip()))
    with open(enc, 'rb') as f:
        ed = f.read()
    eo, EH, efmt = decode_dds(ed)
    full = int(math.floor(math.log2(max(2 * w, 2 * h)))) + 1
    want = {'BC1_UNORM': 'DXT1', 'BC3_UNORM': 'DXT5', 'B8G8R8A8_UNORM': 'A8R8G8B8', 'B8G8R8X8_UNORM': 'X8R8G8B8'}[job.enc]
    probs = []
    if (EH['w'], EH['h']) != (2 * w, 2 * h):
        probs.append('output size %dx%d' % (EH['w'], EH['h']))
    if efmt != want:
        probs.append('output format %s != %s' % (efmt, want))
    if EH['mips'] != full:
        probs.append('mip chain %d != %d' % (EH['mips'], full))
    return enc, eo, EH, efmt, len(ed), probs


def _row_metrics(row, chk, g):
    row.update(mad='%.2f' % chk.get('mad', -1), mad_all='%.2f' % chk.get('mad_all', -1),
               tile_mad_max='%.1f' % chk.get('tile_max', -1), mean_shift='%.2f' % chk.get('mean_shift', -1),
               mean_src=','.join(str(x) for x in chk.get('mean_src', [])),
               mean_out=','.join(str(x) for x in chk.get('mean_out', [])),
               alpha_cov_src='%.4f' % chk.get('cov_src', 0), alpha_cov_out='%.4f' % chk.get('cov_out', 0),
               alpha_mad='%.2f' % chk.get('alpha_mad', 0), alpha_tile_max='%.1f' % chk.get('alpha_tile_max', 0),
               grid='%.3f' % g)


def _crops(job, work, img2x, sheet=True):
    rv = os.path.join(work, 'review')
    cx, cy, s = pick_crop(job.orig, CROP)
    save_webp(job.orig[cy:cy + s, cx:cx + s], os.path.join(rv, job.tid + '_o.webp'))
    if img2x is not None:
        save_webp(img2x[2 * cy:2 * cy + 2 * s, 2 * cx:2 * cx + 2 * s], os.path.join(rv, job.tid + '_n.webp'))
    th = Image.fromarray(job.orig)
    th.thumbnail((192, 192), Image.LANCZOS)
    save_webp(np.asarray(th), os.path.join(rv, job.tid + '_t.webp'), q=88)
    if sheet and len(job.results) > 1:      # small crops of every evaluated variant for the cascade sheet
        cx, cy, s = pick_crop(job.orig, SHEET_CROP)
        save_webp(job.orig[cy:cy + s, cx:cx + s], os.path.join(rv, job.tid + '_o64.webp'), q=90)
        for v, m in job.merged.items():
            save_webp(m[2 * cy:2 * cy + 2 * s, 2 * cx:2 * cx + 2 * s], os.path.join(rv, '%s_%s_64.webp' % (job.tid, v)), q=90)


def finalize(job, out, work, stats):
    """Encode the best passing variant (next best if the encoded file fails), write mirror + manifest row."""
    t0 = time.time()
    chosen = None
    try:
        if job.err:
            raise RuntimeError(job.err)
        after = []
        for v in ranked_variants(job):
            enc, eo, EH, efmt, nbytes, probs = encode(job, job.merged[v], work)
            chk = run_checks(job.orig, eo, job.has_alpha, job.filled)
            g = grid_score(job.orig, eo)
            fails = probs + chk['fail'] + (['lattice artefact (grid %.2f > %.2f)' % (g, GRID_FAIL)] if g > GRID_FAIL else [])
            if fails:
                after.append('%s after encoding: %s' % (v, '; '.join(fails)))
                os.remove(guard(enc))
                continue
            chosen = v
            _row_metrics(job.row, chk, g)
            os.makedirs(guard(os.path.dirname(job.out_path)), exist_ok=True)
            shutil.copyfile(enc, guard(job.out_path))
            os.remove(guard(enc))
            spec = VARIANTS[v]
            job.row.update(status='pass', reason='; '.join(chk['notes'] + after), output_path=job.rel,
                           output_sha256=sha256_file(job.out_path), out_w=EH['w'], out_h=EH['h'], out_fmt=efmt,
                           out_mips=EH['mips'], bytes_out=nbytes, variant=v, risk='%.3f' % job.results[v]['risk'],
                           prefilter='gauss%.1f' % spec['blur'] if spec['blur'] else '',
                           alpha_snapped='%.3f' % job.results[v]['snapped'] if job.results[v]['snapped'] != '' else '')
            _crops(job, work, eo)
            break
        if chosen is None:
            if os.path.exists(job.out_path):     # mirror = textures whose LAST attempt passed
                os.remove(guard(job.out_path))
            best = min(job.results.items(), key=lambda kv: kv[1].get('risk', 99)) if job.results else None
            if best and 'mad' in best[1]:
                _row_metrics(job.row, best[1], best[1]['grid'])
                job.row['risk'] = '%.3f' % best[1]['risk']
            why = ('best %s: %s' % (best[0], '; '.join(best[1].get('fails', [])))) if best else 'no variant produced'
            job.row.update(status='fail', reason='; '.join([why] + after), output_path='', output_sha256='',
                           variant='')
            _crops(job, work, job.merged.get(best[0]) if best else None)
    except Exception as ex:  # noqa: BLE001
        job.row.update(status='fail', reason=(str(ex) if job.err else 'finalize: %s: %s' % (type(ex).__name__, ex))[:300])
    finally:
        for fp in glob.glob(os.path.join(work, 'tmp', job.tid + '_*')):
            try:
                os.remove(guard(fp))
            except OSError:
                pass
        job.orig = job.rgb_base = job.alpha = None
        job.merged = {}
    job.t['post'] = time.time() - t0
    job.row.update(variants_tried=tried_summary(job), t_prep='%.2f' % job.t['prep'], t_gpu='%.2f' % job.t['gpu'],
                   t_eval='%.2f' % job.t['eval'], t_post='%.2f' % job.t['post'])
    append_rows(stats['manifest'], [job.row])
    with LOCK:
        stats['done'] += 1
        stats[job.row['status']] += 1
        stats['v:' + (job.row['variant'] or 'original')] += 1
        n = stats['done']
    log('[%d/%d] %s %-4s %s %sx%s %s->%s var=%s MAD=%s grid=%s gpu=%.1fs eval=%.1fs %s | %s' % (
        n, stats['total'], job.row['category'], job.row['status'].upper(), job.row['texture'], job.row['src_w'],
        job.row['src_h'], job.row['src_fmt'], job.row['out_fmt'] or '-', job.row['variant'] or '-', job.row['mad'] or '-',
        job.row['grid'] or '-', job.t['gpu'], job.t['eval'], job.row['variants_tried'], job.row['reason'][:120]))
    return job


def run_gpu(job, v):
    """'ok' | 'error: ...' | 'abort: ...' (two watchdog trips in a row)."""
    for attempt in (1, 2):
        try:
            gpu_variant(job, v)
            return 'ok'
        except GpuFallback as ex:
            log('GPU WATCHDOG (%s %s, attempt %d): %s' % (job.row['texture'], v, attempt, ex))
            if attempt == 2:
                return 'abort: %s' % ex
            time.sleep(60)
        except Exception as ex:  # noqa: BLE001
            return 'error: %s: %s' % (type(ex).__name__, ex)


def seed_from(prev_date, out, work, sel, manifest):
    """Reuse clean x4plus passes (grid <= GRID_ATTN, no pre-filter) of an earlier batch for unchanged sources."""
    pout, pwork = out_dirs(prev_date)
    prev = {r['source_path']: r for r in read_manifest(pout)}
    have = {r['source_path'] for r in read_manifest(out)}
    rows = []
    for s in sel:
        sp = os.path.join(S1, s['relpath'])
        r = prev.get(sp)
        if sp in have or not r or r['status'] != 'pass' or r.get('prefilter') or r.get('variant') not in ('', 'x4plus'):
            continue
        if r.get('grid') in ('', None) or float(r['grid']) > GRID_ATTN:
            continue
        src_file = os.path.join(pout, r['output_path'])
        if not os.path.exists(src_file) or sha256_file(sp) != r['source_sha256']:
            continue
        dst = os.path.join(out, s['relpath'])
        os.makedirs(guard(os.path.dirname(dst)), exist_ok=True)
        shutil.copyfile(src_file, guard(dst))
        if sha256_file(dst) != r['output_sha256']:
            os.remove(guard(dst))
            continue
        tid = r.get('tid') or hashlib.sha1(s['relpath'].encode('utf-8', 'surrogatepass')).hexdigest()[:12]
        for suf in ('_o.webp', '_n.webp', '_t.webp'):
            fp = os.path.join(pwork, 'review', tid + suf)
            if os.path.exists(fp):
                shutil.copyfile(fp, guard(os.path.join(work, 'review', tid + suf)))
        row = {k: r.get(k, '') for k in MAN_HDR}
        row.update(order=s['order'], category=s['category'], group=s['group'], groups_all=s['groups_all'],
                   output_path=s['relpath'], variant='x4plus', batch_src=prev_date, t1='',
                   variants_tried='x4plus:P:r-:g%.2f' % float(r['grid']))
        rows.append(row)
    if rows:
        append_rows(manifest, rows)
    return len(rows)


def _pid_alive(pid):
    if _K32 is None or pid <= 0:
        return False
    h = _K32.OpenProcess(0x1000, False, pid)          # PROCESS_QUERY_LIMITED_INFORMATION
    if not h:
        return False
    code = ctypes.c_ulong()
    ok = _K32.GetExitCodeProcess(h, ctypes.byref(code))
    _K32.CloseHandle(h)
    return bool(ok) and code.value == 259             # STILL_ACTIVE


def clean_orphans(out, work):
    """After an interrupted run: delete mirror files without a PASS row (written just before a kill), temp files
    and a stale run.lock. Finished textures keep their manifest rows, so a resumed run skips them."""
    lock = os.path.join(out, 'run.lock')
    if os.path.exists(lock):
        try:
            pid = int(open(lock).read().strip() or 0)
        except (OSError, ValueError):
            pid = 0
        if _pid_alive(pid) and pid != os.getpid():
            sys.exit('run.lock held by live process %d - stop it (or create %s) first' % (pid, os.path.join(out, 'STOP')))
        os.remove(guard(lock))
    passed = {r['output_path'] for r in read_manifest(out) if r['status'] == 'pass'}
    removed = 0
    for dp, dn, fn in os.walk(out):
        for f in fn:
            p = os.path.join(dp, f)
            rel = os.path.relpath(p, out)
            if os.path.dirname(rel) == '' or rel.split('\\', 1)[0].lower() == 'review':
                continue
            if rel not in passed:
                os.remove(guard(p))
                removed += 1
    for d in ('tmp', 'enc'):
        shutil.rmtree(os.path.join(work, d), ignore_errors=True)
    log('cleanup: %d orphan mirror file(s) removed, temp folders cleared, %d PASS rows kept' % (removed, len(passed)))


def cmd_run(args):
    out, work = out_dirs(args.date)
    if args.resume:
        clean_orphans(out, work)
    for d in (out, work, os.path.join(work, 'tmp'), os.path.join(work, 'enc'), os.path.join(work, 'review')):
        os.makedirs(guard(d), exist_ok=True)
    manifest = os.path.join(out, 'manifest.tsv')
    sel = [r for r in read_selection(out) if r['status'] == 'todo']
    if args.cats:
        keep = set(args.cats.split(','))
        sel = [r for r in sel if r['category'] in keep]
    if args.seed_from:
        n = seed_from(args.seed_from, out, work, sel, manifest)
        log('seeded %d clean x4plus passes from batch %s' % (n, args.seed_from))
    done = {r['source_path']: r for r in read_manifest(out)}
    if args.retry_failed:
        todo = [dict(r, t1='1') for r in sel if done.get(os.path.join(S1, r['relpath']), {}).get('status') == 'fail']
    else:
        todo = [r for r in sel if os.path.join(S1, r['relpath']) not in done or args.redo]
    if args.limit:
        todo = todo[:args.limit]
    stats = collections.Counter()
    stats['manifest'] = manifest
    stats['total'] = len(todo)
    log('=== run %s: %d textures (selection %d, done %d, t1 %d) cascade=%s' % (
        TOOL_VERSION, len(todo), len(sel), len(done), sum(1 for r in todo if r.get('t1') == '1'), ','.join(CASCADE)))
    t_start = time.time()
    gpu_total = 0.0
    jobs = [Job(r, out, work) for r in todo]
    aborted = ''
    with cf.ThreadPoolExecutor(max_workers=1) as prep_ex, cf.ThreadPoolExecutor(max_workers=args.post_workers) as post_ex:
        pf = {}
        ahead = 2
        for i in range(min(ahead, len(jobs))):
            pf[i] = prep_ex.submit(prep, jobs[i])
        post_f = []
        for i, job in enumerate(jobs):
            if os.path.exists(os.path.join(out, 'STOP')):
                aborted = 'paused by STOP file'
                log('=== STOP file found: pausing at a clean boundary (textures in flight are finished first). '
                    'Delete %s and rerun with --resume to continue.' % os.path.join(out, 'STOP'))
                break
            if i + ahead < len(jobs):
                pf[i + ahead] = prep_ex.submit(prep, jobs[i + ahead])
            pf.pop(i).result()
            if not job.err:
                for v in CASCADE:          # one GPU process at a time (this thread only)
                    st = run_gpu(job, v)
                    if st.startswith('abort'):
                        aborted = st
                        break
                    if st == 'ok':
                        eval_variant(job, v)
                    else:
                        job.results[v] = {'ok': False, 'fails': [st], 'risk': 99.0, 'grid': -1.0}
                    res = job.results[v]
                    if not job.full_cascade and res.get('ok') and res.get('grid', 9) <= GRID_ATTN:
                        break
                if aborted:
                    for fp in glob.glob(os.path.join(work, 'tmp', job.tid + '_*')):
                        try:
                            os.remove(guard(fp))
                        except OSError:
                            pass
                    log('=== run STOPPED: %s. Nothing was written for %s; rerun the same command to resume.' % (
                        aborted, job.row['texture']))
                    break
                gpu_total += job.t['gpu']
            post_f.append(post_ex.submit(finalize, job, out, work, stats))
            while len([f for f in post_f if not f.done()]) > args.post_workers * 2:
                time.sleep(0.2)
        for f in post_f:
            f.result()
    wall = time.time() - t_start
    ndone = stats['done']
    vc = {k[2:]: v for k, v in stats.items() if isinstance(k, str) and k.startswith('v:')}
    log('=== run done: %d/%d textures in %.1f min (%.2f textures/min), GPU busy %.1f min, pass %d, fail %d, '
        'chosen %s%s' % (ndone, len(jobs), wall / 60, ndone / max(wall / 60, 1e-6), gpu_total / 60, stats['pass'],
                         stats['fail'], vc, ' - STOPPED' if aborted else ''))
    runs_p = os.path.join(out, 'runs.json')
    runs = []
    if os.path.exists(runs_p):
        with open(runs_p, encoding='utf-8') as f:
            runs = json.load(f)
    runs.append({'started': datetime.datetime.fromtimestamp(t_start).isoformat(timespec='seconds'), 'textures': ndone,
                 'queued': len(jobs), 'wall_s': round(wall, 1), 'gpu_s': round(gpu_total, 1), 'pass': stats['pass'],
                 'fail': stats['fail'], 'chosen': vc, 'stopped': aborted, 'post_workers': args.post_workers})
    with open(guard(runs_p), 'w', encoding='utf-8') as f:
        json.dump(runs, f, indent=1)
    shutil.rmtree(os.path.join(work, 'enc'), ignore_errors=True)
    return aborted


# ====================================================================== compact review: contact sheets
def _font(size):
    try:
        return ImageFont.truetype(CJK_FONT, size)
    except OSError:
        return ImageFont.load_default()


def _load_cell(path, size):
    try:
        with Image.open(path) as im:
            im = im.convert('RGBA').resize((size, size), Image.BILINEAR)
    except (OSError, ValueError):
        return None
    bg = Image.new('RGBA', (size, size), (118, 118, 118, 255))
    for y in range(0, size, 16):             # light checkerboard behind transparent texels
        for x in range(0, size, 16):
            if (x // 16 + y // 16) % 2:
                bg.paste((150, 150, 150, 255), (x, y, x + 16, y + 16))
    bg.alpha_composite(im)
    return bg.convert('RGB')


def _sheet(cells, cols, cell_w, cell_h, title, path):
    """cells: list of (list of (image or None, border colour), caption lines). Writes a JPEG contact sheet."""
    font = _font(12)
    tfont = _font(16)
    n_img = max(len(c[0]) for c in cells)
    block_w = n_img * (cell_w + 4) + 6
    block_h = cell_h + 36
    rows = (len(cells) + cols - 1) // cols
    W, Hh = cols * block_w + 10, rows * block_h + 34
    sheet = Image.new('RGB', (W, Hh), (34, 34, 38))
    d = ImageDraw.Draw(sheet)
    d.text((10, 8), title, fill=(235, 235, 235), font=tfont)
    for k, (imgs, caption) in enumerate(cells):
        x0 = 8 + (k % cols) * block_w
        y0 = 32 + (k // cols) * block_h
        for j, (im, col) in enumerate(imgs):
            x = x0 + j * (cell_w + 4)
            d.rectangle((x - 2, y0 - 2, x + cell_w + 1, y0 + cell_h + 1), outline=col, width=2)
            if im is not None:
                sheet.paste(im, (x, y0))
            else:
                d.text((x + cell_w // 2 - 4, y0 + cell_h // 2 - 6), '-', fill=(160, 160, 160), font=font)
        for li, line in enumerate(caption[:2]):
            d.text((x0, y0 + cell_h + 4 + li * 14), line, fill=(215, 215, 215), font=font)
    sheet.save(guard(path), 'JPEG', quality=82, optimize=True)
    return os.path.getsize(path)


def _cap(name, n=38):
    return name if len(name) <= n else name[:n - 1] + '…'


def cmd_sheets(args):
    """Compact review: per-category contact sheets (JPEG) + a small index.html. Cells show the original crop
    magnified 2x (bilinear) next to the delivered 2x crop; cascade sheets show every variant that was tried."""
    out, work = out_dirs(args.date)
    rv = os.path.join(work, 'review')
    dst = os.path.join(out, 'review')
    shutil.rmtree(dst, ignore_errors=True)
    os.makedirs(guard(dst), exist_ok=True)
    rows = sorted(read_manifest(out), key=lambda r: int(r['order']))
    GREEN, RED, GREY, AMBER = (60, 200, 110), (230, 70, 60), (110, 110, 110), (240, 190, 60)
    legend = []
    sheets = collections.OrderedDict()
    rnd = random.Random(20260913)

    def add(kind, cat, cells, title_base, per):
        for k in range(0, len(cells), per):
            name = '%s_%s_%02d.jpg' % (kind, cat, k // per + 1)
            chunk = cells[k:k + per]
            size = _sheet([c[0] for c in chunk], 6 if kind != 'cascade' else 2, 128 if kind != 'cascade' else 120,
                          128 if kind != 'cascade' else 120, '%s  (%d-%d of %d)' % (title_base, k + 1, k + len(chunk), len(cells)),
                          os.path.join(dst, name))
            sheets.setdefault(cat, []).append((name, kind, len(chunk), size))
            for j, c in enumerate(chunk):
                legend.append((name, j + 1) + c[1])

    cats = list(dict.fromkeys(r['category'] for r in rows))
    for cat in cats:
        rr = [r for r in rows if r['category'] == cat]
        # 1) cascade decisions: every texture where more than one variant was evaluated
        casc = []
        for r in rr:
            tried = [x.split(':') for x in r['variants_tried'].split(';') if x]
            if len(tried) < 2:
                continue
            imgs = [(_load_cell(os.path.join(rv, r['tid'] + '_o64.webp'), 120), GREY)]
            for v in CASCADE:
                t = next((x for x in tried if x[0] == v), None)
                col = GREEN if v == r['variant'] else (RED if (t and t[1] == 'F') else (GREY if t else (34, 34, 38)))
                imgs.append((_load_cell(os.path.join(rv, '%s_%s_64.webp' % (r['tid'], v)), 120) if t else None, col))
            caption = ['%d %s' % (len(casc) + 1, _cap(r['texture'], 44)),
                       'chosen: %s  %s' % (r['variant'] or 'original', ' '.join('%s%s' % (x[0].replace('x4plus', 'x4'), x[1]) for x in tried))]
            casc.append(((imgs, caption), (r['texture'], gbk_rel(r['source_path'].replace(S1 + '\\', '')), r['status'],
                                           r['variant'] or 'original', r['mad'], r['grid'], r['variants_tried'], r['reason'][:160])))
        if casc:
            add('cascade', cat, casc, '%s - cascade (columns: original x2 | %s; green = chosen, red = failed)' % (
                cat, ' | '.join(CASCADE)), 30)
        # 2) failures (original kept)
        fl = []
        for r in rr:
            if r['status'] != 'fail':
                continue
            imgs = [(_load_cell(os.path.join(rv, r['tid'] + '_o.webp'), 128), GREY),
                    (_load_cell(os.path.join(rv, r['tid'] + '_n.webp'), 128), RED)]
            fl.append(((imgs, ['%d %s' % (len(fl) + 1, _cap(r['texture'], 18)), _cap(r['reason'], 22)]),
                       (r['texture'], gbk_rel(r['source_path'].replace(S1 + '\\', '')), r['status'], 'original', r['mad'],
                        r['grid'], r['variants_tried'], r['reason'][:160])))
        if fl:
            add('fail', cat, fl, '%s - not upscaled (original kept): original x2 | best attempt' % cat, 48)
        # 3) sample of passes, stratified by size
        ps = [r for r in rr if r['status'] == 'pass']
        by_size = collections.defaultdict(list)
        for r in ps:
            by_size[max(ival(r['src_w']), ival(r['src_h']))].append(r)
        pick = []
        quota = max(1, 48 // max(1, len(by_size)))
        for sz in sorted(by_size):
            lst = by_size[sz][:]
            rnd.shuffle(lst)
            pick.extend(lst[:quota])
        pick = sorted(pick[:48], key=lambda r: int(r['order']))
        cells = []
        for r in pick:
            col = AMBER if (r['grid'] not in ('', None) and float(r['grid']) > GRID_ATTN) else GREEN
            imgs = [(_load_cell(os.path.join(rv, r['tid'] + '_o.webp'), 128), GREY),
                    (_load_cell(os.path.join(rv, r['tid'] + '_n.webp'), 128), col)]
            cells.append(((imgs, ['%d %s' % (len(cells) + 1, _cap(r['texture'], 18)),
                                  '%sx%s %s %s' % (r['src_w'], r['src_h'], r['src_fmt'], r['variant'])]),
                          (r['texture'], gbk_rel(r['source_path'].replace(S1 + '\\', '')), r['status'], r['variant'],
                           r['mad'], r['grid'], r['variants_tried'], '')))
        if cells:
            add('sample', cat, cells, '%s - sample of %d passes of %d (original x2 | delivered 2x)' % (cat, len(cells), len(ps)), 48)
    with open(guard(os.path.join(dst, 'sheets.tsv')), 'w', encoding='utf-8-sig', newline='\n') as f:
        f.write('sheet\tcell\ttexture\tdata_relpath_gbk\tstatus\tvariant\tmad\tgrid\tvariants_tried\treason\n')
        for row in legend:
            f.write('\t'.join(str(x).replace('\t', ' ') for x in row) + '\n')
    summ = build_summary2(out, rows)
    H = ['<title>TLBB 2x pack %s</title><meta charset="utf-8"><style>%s</style>' % (esc(args.date), CSS2)]
    w = H.append
    w('<h1>2× texture pack — %s (staging, nothing installed)</h1>' % esc(args.date))
    w('<p class="sub">%d processed · <b>%d pass</b> · %d fail (original kept) · pack %.0f MB from %.0f MB source · '
      '%.2f textures/min · GPU %.1f h. Variants chosen: %s.</p>' % (
          summ['processed'], summ['pass'], summ['fail'], summ['bytes_out'] / 1e6, summ['bytes_src'] / 1e6,
          summ['textures_per_min'], summ['gpu_h'], ', '.join('%s %d' % kv for kv in summ['chosen'].items())))
    w('<table><tr><th>category</th><th>processed</th><th>pass</th><th>fail</th><th>chosen variants</th><th>median MAD</th></tr>')
    for c, v in summ['categories'].items():
        w('<tr><td>%s</td><td>%d</td><td>%d</td><td>%d</td><td>%s</td><td>%s</td></tr>' % (
            esc(c), v['processed'], v['pass'], v['fail'], esc(', '.join('%s %d' % kv for kv in v['chosen'].items())), v['mad_median']))
    w('</table><p class="sub">Fail reasons (best attempt): %s</p>' % esc(', '.join('%s ×%d' % kv for kv in summ['fail_reasons'].items())))
    w('<p class="sub">Contact sheets are JPEG files in <code>review\\</code>; cell numbers are listed in '
      '<code>review\\sheets.tsv</code>. Green frame = delivered / chosen, amber = passed with grid &gt; %.2f, '
      'red = failed.</p>' % GRID_ATTN)
    for c, lst in sheets.items():
        w('<h2>%s</h2><div class="g">' % esc(c))
        for name, kind, n, size in lst:
            w('<a href="review/%s"><figure><img loading="lazy" src="review/%s"><figcaption>%s · %d · %.0f KB</figcaption>'
              '</figure></a>' % (name, name, kind, n, size / 1024))
        w('</div>')
    with open(guard(os.path.join(out, 'index.html')), 'w', encoding='utf-8') as f:
        f.write('\n'.join(H))
    total = sum(s[3] for lst in sheets.values() for s in lst)
    log('sheets: %d contact sheets (%.1f MB) + index.html; %s' % (sum(len(v) for v in sheets.values()), total / 1e6,
                                                                  json.dumps(summ['chosen'])))


CSS2 = """
:root{--bg:#f6f5f2;--ink:#1d1d1f;--mute:#6b6b70;--line:#e3e1dc;--card:#fff}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#17171a;--ink:#ececef;--mute:#9a9aa2;--line:#34343a;--card:#212125}}
:root[data-theme="dark"]{--bg:#17171a;--ink:#ececef;--mute:#9a9aa2;--line:#34343a;--card:#212125}
body{margin:0;padding:24px 32px;background:var(--bg);color:var(--ink);font:14px/1.45 system-ui,"Segoe UI",sans-serif;max-width:1500px}
h1{font-size:21px}h2{font-size:16px;margin-top:28px}.sub{color:var(--mute)}
table{border-collapse:collapse;background:var(--card)}td,th{border-bottom:1px solid var(--line);padding:4px 10px;text-align:left;font-size:13px}
.g{display:flex;flex-wrap:wrap;gap:12px}figure{margin:0;background:var(--card);border:1px solid var(--line);border-radius:8px;padding:6px}
figure img{width:280px;height:auto;display:block}figcaption{font-size:12px;color:var(--mute);margin-top:4px}
a{color:inherit;text-decoration:none}code{font-size:12px}
"""


def build_summary2(out, rows=None):
    rows = rows if rows is not None else read_manifest(out)
    runs = []
    if os.path.exists(os.path.join(out, 'runs.json')):
        with open(os.path.join(out, 'runs.json'), encoding='utf-8') as f:
            runs = json.load(f)
    reasons = collections.Counter()
    for r in rows:
        if r['status'] == 'fail':
            for x in r['reason'].replace('best ', '').split('; '):
                x = re.sub(r'^[\w-]+: ', '', x)
                reasons[re.sub(r'[\d.]+', 'N', x)] += 1
    cats = collections.OrderedDict()
    for c in dict.fromkeys(r['category'] for r in rows):
        rr = [r for r in rows if r['category'] == c]
        cats[c] = {'processed': len(rr), 'pass': sum(1 for r in rr if r['status'] == 'pass'),
                   'fail': sum(1 for r in rr if r['status'] == 'fail'),
                   'chosen': dict(collections.Counter(r['variant'] or 'original' for r in rr)),
                   'mad_median': round(float(np.median([float(r['mad']) for r in rr if r['mad'] not in ('', '-1.00')] or [0])), 2)}
    wall = sum(x['wall_s'] for x in runs)
    ntex = sum(x['textures'] for x in runs)
    t1 = [r for r in rows if r.get('t1') == '1']
    summ = {'tool': 'upscale_pack.py ' + TOOL_VERSION, 'generated': datetime.datetime.now().isoformat(timespec='seconds'),
            'processed': len(rows), 'pass': sum(1 for r in rows if r['status'] == 'pass'),
            'fail': sum(1 for r in rows if r['status'] == 'fail'),
            'chosen': dict(collections.Counter(r['variant'] or 'original' for r in rows)),
            'seeded': sum(1 for r in rows if r.get('batch_src')),
            't1': {'n': len(t1), 'chosen': dict(collections.Counter(r['variant'] or 'original' for r in t1))},
            'fail_reasons': dict(reasons.most_common(12)), 'categories': cats, 'runs': runs,
            'wall_h': round(wall / 3600, 2), 'gpu_h': round(sum(x['gpu_s'] for x in runs) / 3600, 2),
            'textures_per_min': round(ntex / max(wall / 60, 1e-6), 2) if wall else 0,
            'bytes_src': sum(int(r['bytes_src'] or 0) for r in rows if r['status'] == 'pass'),
            'bytes_out': sum(int(r['bytes_out'] or 0) for r in rows if r['status'] == 'pass')}
    with open(guard(os.path.join(out, 'summary.json')), 'w', encoding='utf-8') as f:
        json.dump(summ, f, ensure_ascii=False, indent=1)
    return summ


def cmd_overlay(args):
    """overlay_manifest.tsv: PASS textures only, keyed by their Data-relative path (on-disk GBK/mojibake name,
    plus the readable GBK form). The staging file sits at <batch>\\<data_relpath>."""
    out, work = out_dirs(args.date)
    rows = sorted((r for r in read_manifest(out) if r['status'] == 'pass'), key=lambda r: r['output_path'].lower())
    hdr = ['data_relpath', 'data_relpath_gbk', 'staging_file', 'source_sha256', 'output_sha256', 'bytes_out', 'src_w',
           'src_h', 'out_w', 'out_h', 'src_fmt', 'out_fmt', 'variant', 'risk', 'mad', 'grid', 'category', 'batch_src']
    missing = 0
    with open(guard(os.path.join(out, 'overlay_manifest.tsv')), 'w', encoding='utf-8-sig', newline='\n') as f:
        f.write('\t'.join(hdr) + '\n')
        for r in rows:
            sf = os.path.join(out, r['output_path'])
            if not os.path.exists(sf):
                missing += 1
                continue
            f.write('\t'.join(str(x) for x in (
                r['output_path'], gbk_rel(r['output_path']), sf, r['source_sha256'], r['output_sha256'], r['bytes_out'],
                r['src_w'], r['src_h'], r['out_w'], r['out_h'], r['src_fmt'], r['out_fmt'], r['variant'] or 'x4plus',
                r['risk'], r['mad'], r['grid'], r['category'], r['batch_src'] or args.date)) + '\n')
    log('overlay: %d PASS textures listed (%.0f MB), %d missing files' % (
        len(rows) - missing, sum(int(r['bytes_out'] or 0) for r in rows) / 1e6, missing))


# ====================================================================== v1 review page (2026-09-12) + summary
def b64(path, thumb=False):
    try:
        if thumb:
            im = Image.open(path)
            im.thumbnail((128, 128), Image.LANCZOS)
            buf = io.BytesIO()
            im.save(buf, 'WEBP', quality=70, method=4)
            data = buf.getvalue()
        else:
            with open(path, 'rb') as f:
                data = f.read()
        return 'data:image/webp;base64,' + base64.b64encode(data).decode('ascii')
    except OSError:
        return ''


def esc(s):
    return (str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;'))


def grid_scores(out, rows):
    """Cached per output sha256 in <batch>/grid_scores.json."""
    p = os.path.join(out, 'grid_scores.json')
    cache = {}
    if os.path.exists(p):
        with open(p, encoding='utf-8') as f:
            cache = json.load(f)
    for r in rows:
        if r['status'] != 'pass' or r['output_sha256'] in cache:
            continue
        try:
            with open(r['source_path'], 'rb') as f:
                src, _, _ = decode_dds(f.read())
            with open(os.path.join(out, r['output_path']), 'rb') as f:
                dst, _, _ = decode_dds(f.read())
            cache[r['output_sha256']] = round(grid_score(src, dst), 3)
        except (OSError, Unsupported, ValueError) as ex:
            log('grid score failed', r['texture'], ex)
    with open(guard(p), 'w', encoding='utf-8') as f:
        json.dump(cache, f, indent=0)
    return cache


def fit_time_model(rows):
    """t_gpu ~ a*passes + b*Mpx_processed (passes = 1 or 2 with alpha)."""
    X, y = [], []
    for r in rows:
        try:
            tg = float(r['t_gpu'])
            w, h = int(r['src_w']), int(r['src_h'])
        except (ValueError, KeyError):
            continue
        if tg <= 0:
            continue
        p = 2 if r['alpha'] in ('1bit', 'full') else 1
        X.append([p, p * w * h / 1e6])
        y.append(tg)
    if len(X) < 5:
        return None
    X, y = np.array(X), np.array(y)
    coef, *_ = np.linalg.lstsq(X, y, rcond=None)
    res = np.abs(X @ coef - y)
    keep = res <= max(3.0, 4 * float(np.median(res)))
    if keep.sum() >= 5:
        coef, *_ = np.linalg.lstsq(X[keep], y[keep], rcond=None)
    return [float(coef[0]), float(coef[1])]


def size_class_times(rows):
    g = collections.defaultdict(list)
    for r in rows:
        try:
            g[(max(int(r['src_w']), int(r['src_h'])), 2 if r['alpha'] in ('1bit', 'full') else 1)].append(float(r['t_gpu']))
        except (ValueError, KeyError):
            continue
    return {'%dpx x%d pass' % k: {'n': len(v), 'median_gpu_s': round(float(np.median(v)), 1)} for k, v in sorted(g.items())}


def build_summary(out):
    rows = read_manifest(out)
    sel = read_selection(out)
    with open(os.path.join(out, 'selection_summary.json'), encoding='utf-8') as f:
        ssum = json.load(f)
    runs = []
    if os.path.exists(os.path.join(out, 'runs.json')):
        with open(os.path.join(out, 'runs.json'), encoding='utf-8') as f:
            runs = json.load(f)
    npass = sum(1 for r in rows if r['status'] == 'pass')
    nfail = sum(1 for r in rows if r['status'] == 'fail')
    reasons = collections.Counter()
    for r in rows:
        if r['status'] == 'fail':
            for x in r['reason'].split('; '):
                reasons[re.sub(r'[\d.]+', 'N', x)] += 1
    wall = sum(x['wall_s'] for x in runs)
    gpu_s = sum(x['gpu_s'] for x in runs)
    ntex = sum(x['textures'] for x in runs)
    model = fit_time_model(rows)
    alpha_rate = collections.defaultdict(lambda: [0, 0])
    for r in rows:
        alpha_rate[r['src_fmt']][0] += 1
        alpha_rate[r['src_fmt']][1] += r['alpha'] in ('1bit', 'full')
    est = {}
    if model and gpu_s > 0 and 'estimate_sets' in ssum:
        ratio = wall / gpu_s
        for k, v in ssum['estimate_sets'].items():
            n = v['in_scope']
            passes = sum(c * (1 + alpha_rate[f][1] / max(1, alpha_rate[f][0]) if f in alpha_rate else 1.5)
                         for f, c in v['formats'].items())
            mean_mpx = v['mpx'] / max(1, n)
            g = model[0] * passes + model[1] * passes * mean_mpx
            est[k] = {'textures': n, 'gpu_h': round(g / 3600, 1), 'wall_h': round(g * ratio / 3600, 1),
                      'input_mpx': v['mpx'], 'over_1024_skipped': v['over_1024']}
    cat_stats = {}
    for c in CATS:
        rr = [r for r in rows if r['category'] == c]
        cat_stats[c] = {'processed': len(rr), 'pass': sum(1 for r in rr if r['status'] == 'pass'),
                        'fail': sum(1 for r in rr if r['status'] == 'fail'),
                        'selected': sum(1 for r in sel if r['category'] == c and r['status'] == 'todo'),
                        'mad_median': round(float(np.median([float(r['mad']) for r in rr if r['mad'] not in ('', '-1.00')] or [0])), 2)}
    summ = {'tool': 'upscale_pack.py ' + TOOL_VERSION, 'generated': datetime.datetime.now().isoformat(timespec='seconds'),
            'processed': len(rows), 'pass': npass, 'fail': nfail, 'fail_reasons': dict(reasons),
            'selected_todo': ssum['selected_todo'], 'skipped': ssum['skipped'], 'runs': runs,
            'wall_min': round(wall / 60, 1), 'gpu_min': round(gpu_s / 60, 1),
            'textures_per_min': round(ntex / max(wall / 60, 1e-6), 2) if wall else 0,
            'gpu_time_model_s': model, 'gpu_seconds_by_size': size_class_times(rows),
            'estimate_full_categories': est, 'categories': cat_stats,
            'bytes_src': sum(int(r['bytes_src'] or 0) for r in rows if r['status'] == 'pass'),
            'bytes_out': sum(int(r['bytes_out'] or 0) for r in rows if r['status'] == 'pass'),
            'npc_top20': ssum.get('npc_top20')}
    with open(guard(os.path.join(out, 'summary.json')), 'w', encoding='utf-8') as f:
        json.dump(summ, f, ensure_ascii=False, indent=1)
    return summ, rows


CSS = """
:root{--bg:#f6f5f2;--card:#fff;--ink:#1d1d1f;--mute:#6b6b70;--line:#e3e1dc;--pass:#1f7a4d;--passbg:#e3f4ea;
--fail:#b3261e;--failbg:#fbe4e2;--chip:#efede8;--accent:#3d5a80}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#17171a;--card:#212125;--ink:#ececef;
--mute:#9a9aa2;--line:#34343a;--pass:#6fd39c;--passbg:#1d3528;--fail:#ff8a80;--failbg:#3a1f1d;--chip:#2c2c31;--accent:#8fb3e0}}
:root[data-theme="dark"]{--bg:#17171a;--card:#212125;--ink:#ececef;--mute:#9a9aa2;--line:#34343a;--pass:#6fd39c;
--passbg:#1d3528;--fail:#ff8a80;--failbg:#3a1f1d;--chip:#2c2c31;--accent:#8fb3e0}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:14px/1.45 system-ui,"Segoe UI",sans-serif}
header{padding:28px 32px 12px;max-width:1500px;margin:auto}h1{font-size:22px;margin:0 0 6px}
.sub{color:var(--mute)}.kpis{display:flex;flex-wrap:wrap;gap:12px;margin:18px 0}
.kpi{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:10px 14px;min-width:130px}
.kpi b{display:block;font-size:20px}.kpi span{color:var(--mute);font-size:12px}
table{border-collapse:collapse;background:var(--card);border:1px solid var(--line);border-radius:8px;overflow:hidden}
td,th{padding:5px 10px;border-bottom:1px solid var(--line);text-align:left;font-size:13px}th{color:var(--mute);font-weight:600}
.tw{overflow-x:auto;margin:10px 0}
nav{position:sticky;top:0;z-index:5;background:var(--bg);border-bottom:1px solid var(--line);padding:10px 32px}
nav .in{max-width:1500px;margin:auto;display:flex;flex-wrap:wrap;gap:6px;align-items:center}
nav button{border:1px solid var(--line);background:var(--chip);color:var(--ink);border-radius:999px;padding:4px 12px;cursor:pointer;font:inherit;font-size:12px}
nav button.on{background:var(--accent);color:#fff;border-color:var(--accent)}
main{max-width:1500px;margin:auto;padding:8px 32px 60px}h2{font-size:18px;margin:34px 0 4px}
h3{font-size:14px;margin:22px 0 8px;color:var(--mute);font-weight:600}
.grid{display:flex;flex-wrap:wrap;gap:14px}
.card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:12px;max-width:100%}
.card .t{font-weight:600;word-break:break-all}.card .m{color:var(--mute);font-size:12px;margin:3px 0 8px;word-break:break-all}
.badge{display:inline-block;border-radius:6px;padding:1px 7px;font-size:11px;font-weight:700;margin-left:6px}
.pass .badge{background:var(--passbg);color:var(--pass)}.fail .badge{background:var(--failbg);color:var(--fail)}
.badge.look{background:#fff1c7;color:#8a5a00}
.fail{border-color:var(--fail)}.why{color:var(--fail);font-size:12px;margin-bottom:6px}
.row{display:flex;gap:10px;flex-wrap:wrap;margin-top:6px}figure{margin:0}
figcaption{font-size:11px;color:var(--mute);margin-bottom:2px}
.ck{background-color:#bbb;background-image:linear-gradient(45deg,#999 25%,transparent 25%,transparent 75%,#999 75%),
linear-gradient(45deg,#999 25%,transparent 25%,transparent 75%,#999 75%);background-size:16px 16px;background-position:0 0,8px 8px;line-height:0}
.v{background-size:100% 100%;background-repeat:no-repeat}.px{image-rendering:pixelated}
.card{overflow-x:auto}details{margin-top:6px;font-size:12px;color:var(--mute)}
.also{font-size:11px;color:var(--mute);margin-top:4px}
"""

JS = """
const st={s:'all',c:'all'};
function ap(){document.querySelectorAll('.card').forEach(e=>{const ok=(st.s=='all'||e.dataset.s==st.s||(st.s=='attn'&&e.dataset.a=='y'))&&(st.c=='all'||e.dataset.c==st.c);e.hidden=!ok});
document.querySelectorAll('section.cat').forEach(s=>{s.hidden=!s.querySelector('.card:not([hidden])')});
document.querySelectorAll('.grp').forEach(g=>{g.hidden=!g.querySelector('.card:not([hidden])')});}
document.querySelectorAll('nav button').forEach(b=>b.onclick=()=>{const k=b.dataset.k;st[k]=b.dataset.v;
document.querySelectorAll('nav button[data-k="'+k+'"]').forEach(x=>x.classList.toggle('on',x==b));ap();});
"""


def cmd_review(args):
    """v1 single-page review (2026-09-12 batch)."""
    out, work = out_dirs(args.date)
    summ, rows = build_summary(out)
    if args.limit:
        rows = sorted(rows, key=lambda r: int(r['order']))[:args.limit]
    gs = grid_scores(out, rows)
    for r in rows:
        g = r.get('grid') or gs.get(r['output_sha256'], '')
        r['grid'] = float(g) if g not in ('', None) else ''
        r['attn'] = 'y' if (r['status'] == 'pass' and r['grid'] != '' and r['grid'] > GRID_ATTN) else ''
    rv = os.path.join(work, 'review')
    by_cat = collections.OrderedDict((c, collections.OrderedDict()) for c in CATS)
    for r in sorted(rows, key=lambda r: int(r['order'])):
        by_cat.setdefault(r['category'], collections.OrderedDict()).setdefault(r['group'], []).append(r)
    H = []
    w = H.append
    w('<title>TLBB 2x texture review %s</title><meta charset="utf-8"><style>%s</style>' % (esc(args.date), CSS))
    w('<header><h1>2× texture pack — staging review (%s)</h1>' % esc(args.date))
    w('<div class="sub">Source: client_GL\\Data (read-only). Real-ESRGAN x4plus (-s 4, per file, -j 1:1:1) → Lanczos to 2× → '
      'texconv x64 (-dx9, full mips, BC1/BC3, UNORM). Only passing textures are in the mirror folder. Nothing is installed.</div>')
    w('<div class="kpis">')
    for label, val in (('processed', summ['processed']), ('passed', summ['pass']), ('failed', summ['fail']),
                       ('textures / min', summ['textures_per_min']), ('wall time (min)', summ['wall_min']),
                       ('GPU busy (min)', summ['gpu_min']),
                       ('pack size', '%.0f MB' % (summ['bytes_out'] / 1e6)),
                       ('source size', '%.0f MB' % (summ['bytes_src'] / 1e6))):
        w('<div class="kpi"><b>%s</b><span>%s</span></div>' % (esc(val), esc(label)))
    w('</div><div class="tw"><table><tr><th>cat</th><th>what</th><th>selected</th><th>processed</th><th>pass</th>'
      '<th>fail</th><th>median MAD</th></tr>')
    for c, v in summ['categories'].items():
        w('<tr><td>%s</td><td>%s</td><td>%d</td><td>%d</td><td>%d</td><td>%d</td><td>%s</td></tr>' % (
            c, esc(CATS[c]), v['selected'], v['processed'], v['pass'], v['fail'], v['mad_median']))
    w('</table></div>')
    if summ['fail_reasons']:
        w('<div class="sub">Fail reasons: %s</div>' % esc(', '.join('%s ×%d' % kv for kv in summ['fail_reasons'].items())))
    if summ['estimate_full_categories']:
        w('<div class="tw"><table><tr><th>whole category (diffuse, ≤1024 px)</th><th>textures</th><th>input Mpx</th>'
          '<th>est. GPU h</th><th>est. wall h</th><th>&gt;1024 px (not upscaled)</th></tr>')
        for k, v in summ['estimate_full_categories'].items():
            w('<tr><td>%s</td><td>%d</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>' % (
                esc(k), v['textures'], v['input_mpx'], v['gpu_h'], v['wall_h'], v['over_1024_skipped']))
        w('</table></div>')
    w('<div class="sub">Views: <b>100%</b> = the 2× texture at native pixels; the original is magnified 2× with bilinear '
      'filtering (what the GPU shows today). <b>200%</b> = both magnified again with nearest-neighbour to inspect detail. '
      'Crops are the most detailed ' + '%d×%d' % (CROP, CROP) + ' region of the original (decoded DDS; the 2× side is '
      'decoded from the delivered, re-encoded DDS).</div></header>')
    w('<nav><div class="in"><button data-k="s" data-v="all" class="on">all</button><button data-k="s" data-v="pass">pass</button>'
      '<button data-k="s" data-v="fail">fail</button><button data-k="s" data-v="attn">look here (grid &gt; %.2f)</button>'
      '<span style="width:14px"></span><button data-k="c" data-v="all" class="on">all categories</button>' % GRID_ATTN)
    for c in CATS:
        w('<button data-k="c" data-v="%s">%s</button>' % (c, c))
    w('</div></nav><main>')
    for c, groups in by_cat.items():
        if not groups:
            continue
        w('<section class="cat"><h2>%s — %s</h2>' % (c, esc(CATS.get(c, c))))
        for g, rr in groups.items():
            w('<div class="grp"><h3>%s</h3><div class="grid">' % esc(g))
            for r in rr:
                o = b64(os.path.join(rv, r['tid'] + '_o.webp'))
                n = b64(os.path.join(rv, r['tid'] + '_n.webp'))
                t = b64(os.path.join(rv, r['tid'] + '_t.webp'), thumb=True)
                try:
                    cw = min(CROP, int(r['src_w']), int(r['src_h']))
                except ValueError:
                    cw = CROP
                w('<article class="card %s" data-s="%s" data-c="%s" data-a="%s">' % (r['status'], r['status'], r['category'], r['attn']))
                w('<div class="t">%s<span class="badge">%s</span>%s</div>' % (
                    esc(r['texture']), r['status'].upper(), '<span class="badge look">LOOK</span>' if r['attn'] else ''))
                w('<div class="m">%s×%s %s → %s×%s %s · alpha %s%s%s · MAD %s · tile max %s · Δmean %s · α-cov %s→%s · grid %s · %s</div>' % (
                    r['src_w'], r['src_h'], r['src_fmt'], r['out_w'] or '?', r['out_h'] or '?', r['out_fmt'] or '?',
                    r['alpha'], ' (filled)' if r['fill'] else '', ' · prefilter ' + r['prefilter'] if r.get('prefilter') else '',
                    r['mad'] or '-', r['tile_mad_max'] or '-',
                    r['mean_shift'] or '-', r['alpha_cov_src'] or '-', r['alpha_cov_out'] or '-',
                    '%.2f' % r['grid'] if r['grid'] != '' else '-',
                    esc(gbk_rel(r['source_path'].replace(S1 + '\\', '')))))
                if r['reason']:
                    w('<div class="why">%s</div>' % esc(r['reason']))
                if o and n:
                    tid = r['tid']
                    w('<style>.o-%s{background-image:url(%s)}.n-%s{background-image:url(%s)}</style>' % (tid, o, tid, n))
                    for label, d, cls, cap_o, cap_n in (('100%', cw * 2, '', 'original ×2 bilinear', '2× native'),
                                                         ('200%', cw * 4, ' px', 'original ×4 nearest', '2× ×2 nearest')):
                        w('<div class="row"><figure><figcaption>%s — %s</figcaption><div class="ck"><div class="v o-%s%s" '
                          'style="width:%dpx;height:%dpx"></div></div></figure>' % (cap_o, label, tid, cls, d, d))
                        w('<figure><figcaption>%s — %s</figcaption><div class="ck"><div class="v n-%s%s" '
                          'style="width:%dpx;height:%dpx"></div></div></figure></div>' % (cap_n, label, tid, cls, d, d))
                if t:
                    w('<details><summary>whole original texture</summary><div class="ck" style="display:inline-block"><img src="%s"></div></details>' % t)
                others = [x for x in r['groups_all'].split(' | ') if x and not x.endswith(':' + r['group'])]
                if others:
                    w('<div class="also">also used by: %s</div>' % esc('; '.join(others[:6]) + (' …' if len(others) > 6 else '')))
                w('</article>')
            w('</div></div>')
        w('</section>')
    w('</main><script>%s</script>' % JS)
    path = guard(os.path.join(work, 'review_test.html') if args.limit else os.path.join(out, 'review.html'))
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(H))
    log('review: %s (%.1f MB), processed %d, pass %d, fail %d, %.2f textures/min' % (
        path, os.path.getsize(path) / 1e6, summ['processed'], summ['pass'], summ['fail'], summ['textures_per_min']))


def cmd_grade(args):
    """v1: post-hoc lattice grading of a manifest written before the detector existed. Pass rows scoring
    > GRID_FAIL are moved from the mirror to _work\\rejected and marked fail; manifest rewritten (compacted)."""
    out, work = out_dirs(args.date)
    if os.path.exists(os.path.join(out, 'run.lock')):
        sys.exit('a run is active (run.lock) - grade after it finishes')
    rows = read_manifest(out)
    gs = grid_scores(out, rows)
    moved = 0
    for r in rows:
        if r['status'] == 'pass':
            g = gs.get(r['output_sha256'])
            if g is None:
                continue
            r['grid'] = '%.3f' % g
            if g > GRID_FAIL:
                src = os.path.join(out, r['output_path'])
                dst = os.path.join(work, 'rejected', r['output_path'])
                os.makedirs(guard(os.path.dirname(dst)), exist_ok=True)
                if os.path.exists(src):
                    shutil.move(guard(src), guard(dst))
                r['status'] = 'fail'
                r['reason'] = '; '.join(x for x in (r.get('reason', ''), 'lattice artefact (grid %.2f > %.2f)' % (g, GRID_FAIL)) if x)
                r['output_path'] = ''
                moved += 1
    tmp = os.path.join(out, 'manifest.tsv.tmp')
    with open(guard(tmp), 'w', encoding='utf-8-sig', newline='\n') as f:
        f.write('\t'.join(MAN_HDR) + '\n')
        for r in sorted(rows, key=lambda r: int(r['order'])):
            f.write('\t'.join(str(r.get(k, '')).replace('\t', ' ') for k in MAN_HDR) + '\n')
    os.replace(tmp, guard(os.path.join(out, 'manifest.tsv')))
    for dp, dn, fn in sorted(os.walk(out), reverse=True):
        if dp != out and not dn and not fn:
            os.rmdir(guard(dp))
    log('grade: %d rows, %d moved to rejected for lattice artefacts (grid > %.2f)' % (len(rows), moved, GRID_FAIL))


def cmd_verify(args):
    """Re-check the delivered mirror from disk: every file is listed as 'pass' in the manifest with the same
    sha256, maps 1:1 to an existing S1 path (identical name), has a legacy DX9 header with an allowed FourCC,
    exactly 2x the source size, a full mip chain and a file length equal to the size the header implies."""
    out, work = out_dirs(args.date)
    rows = {r['output_path']: r for r in read_manifest(out) if r['status'] == 'pass'}
    problems = []
    seen = set()
    for dp, dn, fn in os.walk(out):
        for f in fn:
            p = os.path.join(dp, f)
            rel = os.path.relpath(p, out)
            top = rel.split('\\', 1)[0]
            if os.path.dirname(rel) == '' or top.lower() == 'review':
                continue            # manifest.tsv, index.html, review\*.jpg ...
            seen.add(rel)
            r = rows.get(rel)
            if r is None:
                problems.append((rel, 'not listed as pass in manifest'))
                continue
            if not os.path.exists(os.path.join(S1, rel)):
                problems.append((rel, 'no source file with this exact name'))
            with open(p, 'rb') as fh:
                d = fh.read()
            if hashlib.sha256(d).hexdigest() != r['output_sha256']:
                problems.append((rel, 'sha256 differs from manifest'))
            try:
                H = dds_header(d)
            except Unsupported as ex:
                problems.append((rel, str(ex)))
                continue
            fmt = fmt_name(H)
            info = F.dds_info(d)
            full = int(math.floor(math.log2(max(H['w'], H['h'])))) + 1
            if fmt not in ('DXT1', 'DXT5', 'A8R8G8B8', 'X8R8G8B8'):
                problems.append((rel, 'format ' + fmt))
            if (H['w'], H['h']) != (2 * int(r['src_w']), 2 * int(r['src_h'])):
                problems.append((rel, 'size %dx%d' % (H['w'], H['h'])))
            if H['mips'] != full or not (H['flags'] & 0x20000):
                problems.append((rel, 'mips %d (flags %x), expected %d' % (H['mips'], H['flags'], full)))
            if info.get('err') or info.get('end') != len(d):
                problems.append((rel, 'length %d vs header-implied %s %s' % (len(d), info.get('end'), info.get('err', ''))))
    for rel in rows:
        if rel not in seen:
            problems.append((rel, 'manifest pass row without file'))
    log('verify: %d mirror files, %d manifest pass rows, %d problem(s)' % (len(seen), len(rows), len(problems)))
    for p in problems[:50]:
        log('  VERIFY', p[0], '-', p[1])
    with open(guard(os.path.join(out, 'verify.txt')), 'w', encoding='utf-8') as f:
        f.write('verify %s: %d files, %d pass rows, %d problems\n' % (datetime.datetime.now().isoformat(timespec='seconds'),
                                                                     len(seen), len(rows), len(problems)))
        for p in problems:
            f.write('%s\t%s\n' % p)
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('cmd', choices=['select', 'run', 'cleanup', 'grade', 'review', 'sheets', 'overlay', 'verify', 'all'])
    ap.add_argument('--resume', action='store_true',
                    help='run: clean orphans/temp/stale lock of an interrupted run first, then continue the queue')
    ap.add_argument('--date', default='2026-09-12')
    ap.add_argument('--scope', choices=['batch1', 'full'], default='batch1')
    ap.add_argument('--t1-from', default='', help='earlier batch whose failures / look-here cards try every variant')
    ap.add_argument('--seed-from', default='', help='earlier batch whose clean x4plus passes are reused')
    ap.add_argument('--limit', type=int, default=0)
    ap.add_argument('--cats', default='')
    ap.add_argument('--redo', action='store_true')
    ap.add_argument('--retry-failed', action='store_true', help='re-run current failures with the full cascade')
    ap.add_argument('--post-workers', type=int, default=2)
    args = ap.parse_args()
    args.post_workers = max(1, min(2, args.post_workers))   # python + esrgan + <= 2 texconv = 4 processes
    for exe in (ESRGAN, TEXCONV):
        if not os.path.exists(exe):
            sys.exit('missing tool: ' + exe)
    global LOGF
    out, work = out_dirs(args.date)
    os.makedirs(guard(out), exist_ok=True)
    LOGF = open(guard(os.path.join(out, 'run.log')), 'a', encoding='utf-8')
    if args.cmd == 'cleanup':
        clean_orphans(out, work)
    if args.cmd in ('select', 'all'):
        cmd_select(args)
    if args.cmd in ('run', 'all'):
        if args.resume:
            clean_orphans(out, work)      # before our own lock is written
            args.resume = False
        lock = guard(os.path.join(out, 'run.lock'))
        with open(lock, 'w') as f:
            f.write(str(os.getpid()))
        try:
            cmd_run(args)
        finally:
            os.remove(lock)
    if args.cmd == 'grade':
        cmd_grade(args)
    if args.cmd == 'review':
        cmd_review(args)
    if args.cmd in ('sheets', 'all'):
        cmd_sheets(args)
    if args.cmd in ('overlay', 'all'):
        cmd_overlay(args)
    if args.cmd in ('verify', 'all'):
        cmd_verify(args)


if __name__ == '__main__':
    main()
