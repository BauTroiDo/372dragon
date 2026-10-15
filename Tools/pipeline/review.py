# -*- coding: utf-8 -*-
"""review.py - CY-Source: variant review sheet ("bang chon ban", Docs/05 muc 3.3).

For every selected object that exists in several sources with different content, the
variant of each source (S1 client_GL, S2 DataCY 3.71, S3 CYHJ) is gathered (mesh ->
skeleton -> material -> texture closure), converted to glTF with the existing converter
C:\\TLBB\\085\\Tools\\model-convert\\tlbb2gltf.py (imported, never modified) and rendered by
Blender headless with one camera/light rule for all variants of an object. The result is
Assets\\Staging\\review\\<batch>\\index.html (local, self-contained, no external URL) where the
user picks one source per object; the page writes YAML for Registry\\selections\\<batch>.yaml.

Inputs  Assets\\Staging\\index\\models_cross.tsv, models_S1..S3.tsv, sha256_S1..S3.tsv
        (produced by index_sources.py) + the read-only sources themselves.
Outputs <out>\\index.html, <out>\\img\\<oid>\\*.jpg, <out>\\data.json, <out>\\summary.json/.txt
        work files in Assets\\Staging\\review\\_work\\<batch> (GLB, raw renders, logs).

Selection (models_cross.tsv):
  batch 1 = objects present in S1,S2,S3,S4 with mesh=diff or tex_dims=diff   (355 on 12/09)
  batch 2 = other objects present in >= 2 of S1-S3 with mesh=diff or tex_dims=diff (33)
Identical variants (same mesh/skeleton/material/texture content, same pose) render once.

Rules kept from Docs/08: all.obj / all.material are handled as GBK bytes; S1 file names
are GBK shown as cp1252 (tlbbfmt.disk_name_bytes); files with 1-12 padding bytes are
staged truncated to the format-derived length (sha256_S*.tsv fmt_len). Nothing is
written outside CY-Source\\Assets\\Staging\\review.

Run (PowerShell):
  $env:PYTHONUTF8="1"; & "C:\\Program Files\\Python313\\python.exe" C:\\TLBB\\085\\CY-Source\\Tools\\pipeline\\review.py
Options: --batch 1|2|all  --objs FILE  --limit N  --jobs N(<=4 Blender)  --convert-jobs N
         --chunk N  --force  --html-only  --keep-work  --out DIR  --blender EXE
"""
import argparse
import collections
import concurrent.futures as cf
import contextlib
import csv
import datetime
import hashlib
import html
import io
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import time
import traceback

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import tlbbfmt as F  # noqa: E402
import index_sources as IS  # noqa: E402

TOOL_VERSION = '1.0 (2026-09-12)'
CYS = r'C:\TLBB\085\CY-Source'
IDX_DIR = os.path.join(CYS, 'Assets', 'Staging', 'index')
REVIEW_ROOT = os.path.join(CYS, 'Assets', 'Staging', 'review')
BATCH_NAME = '2026-09-12-variants'
OUT_DEFAULT = os.path.join(REVIEW_ROOT, BATCH_NAME)
CONVERTER_DIR = r'C:\TLBB\085\Tools\model-convert'
CONVERTER = os.path.join(CONVERTER_DIR, 'tlbb2gltf.py')
BLENDER_DEFAULT = r'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe'
BLENDER_SCRIPT = os.path.join(HERE, 'blender', 'render_variants.py')
SELECTION_YAML = r'C:\TLBB\085\CY-Source\Registry\selections\%s.yaml' % BATCH_NAME
SRCS = ('S1', 'S2', 'S3')
SRC_LABEL = {'S1': 'S1 client_GL', 'S2': 'S2 DataCY 3.71 (CY)', 'S3': 'S3 CYHJ (HJ)'}
MAX_BLENDER = 4          # other agents compile C++ at the same time (task rule)
TEX_CAP = 1024           # textures are downscaled to this size inside the GLB (512 px renders)
RENDER_SIZE = 512
BG_RGB = (128, 128, 128)  # neutral grey (sRGB 0.5)
VIEWS = (('f', 35.0, 15.0), ('b', 215.0, 15.0))   # (tag, azimuth from the model front, elevation)
CUTOUT_TEMPLATES = {b'WeaponTemplateAlpha', b'Mtl_Character_FlowLight', b'Mtl_Char_FLTrans'}
NON_DIFFUSE = re.compile(rb'ctl|reflect|scroll|outline|laser|dissolve|env|mask|normal|bump|spec|light|flow|noise|'
                         rb'detail|dn?texture\d', re.I)

LOGF = None


def log(*a):
    s = time.strftime('%H:%M:%S ') + ' '.join(str(x) for x in a)
    print(s, flush=True)
    if LOGF:
        LOGF.write(s + '\n')
        LOGF.flush()


def load_tsv(path):
    with open(path, encoding='utf-8-sig', newline='') as f:
        rd = csv.reader(f, delimiter='\t', quoting=csv.QUOTE_NONE)
        hdr = next(rd)
        return [dict(zip(hdr, r)) for r in rd]


def oid_of(name):
    return 'o' + hashlib.sha1(name.encode('utf-8', 'surrogatepass')).hexdigest()[:10]


def ival(x, d=0):
    try:
        return int(float(x))
    except (TypeError, ValueError):
        return d


def sha_json(obj):
    return hashlib.sha256(json.dumps(obj, sort_keys=True, ensure_ascii=False).encode('utf-8')).hexdigest()


# ------------------------------------------------------------------ selection
def present_of(row):
    return [s for s in row['sources'].split(',') if s in SRCS]


def select_objects(cross, batch, objs_file=None):
    diff = [r for r in cross if r['mesh'] == 'diff' or r['tex_dims'] == 'diff']
    b1 = [r for r in diff if r['sources'] == 'S1,S2,S3,S4']
    n1 = {r['obj'] for r in b1}
    b2 = [r for r in diff if r['obj'] not in n1 and len(present_of(r)) >= 2]
    for r in b1:
        r['_batch'] = 1
    for r in b2:
        r['_batch'] = 2
    rows = b1 if batch == '1' else b2 if batch == '2' else b1 + b2
    if objs_file:
        with open(objs_file, encoding='utf-8-sig') as f:
            want = [ln.strip() for ln in f if ln.strip() and not ln.startswith('#')]
        by = {r['obj']: r for r in cross}
        rows = []
        for w in want:
            r = by.get(w)
            if r is None:
                log('  ! --objs: not in models_cross:', w)
                continue
            r.setdefault('_batch', 0)
            rows.append(r)
    return rows


# ------------------------------------------------------------------ one source (read-only)
class Source:
    """File manifest + all.obj + all.material of one loose source (S1/S2/S3)."""

    def __init__(self, S):
        self.S = S
        cfg = IS.SOURCES[S]
        self.root = cfg['root']
        self.moj = cfg['mojibake']
        self.files = {}
        walked = []
        for r in load_tsv(os.path.join(IDX_DIR, 'sha256_%s.tsv' % S)):
            rel = r['relpath']
            size = ival(r['size'], -1)
            fl = ival(r['fmt_len'], size) if r['fmt_len'] else size
            self.files[rel] = (size, fl, r['sha256_content'] or r['sha256'], r['info'])
            walked.append((rel, size, 0))
        self.idx, _dup = IS.name_index(S, walked)
        objs, _ = F.parse_all_obj(IS.read_src(S, 'obj'))
        self.objs = {}
        for o in objs:
            self.objs.setdefault(F.disp(o['name']), o)
        mdata = IS.read_src(S, 'material')
        self.mats, _ = F.material_defs(mdata)
        self.mbody = {}
        blocks, _ = F.iter_blocks(mdata)
        for hdr, body in blocks:
            toks = hdr.split(None, 1)
            if toks and toks[0] == b'material' and len(toks) > 1 and toks[1].strip():
                self.mbody.setdefault(toks[1].split(b':')[0].strip().split()[0], body)
        self.models = {r['obj']: r for r in load_tsv(os.path.join(IDX_DIR, 'models_%s.tsv' % S))}

    def resolve(self, name_bytes):
        """GBK name (any folder prefix) -> (relpath, abspath) using the indexer's rule."""
        rel = self.idx.get(F.key_of(F.base_of(name_bytes)))
        return (rel, os.path.join(self.root, rel)) if rel else (None, None)

    def disp_rel(self, rel):
        return IS.disp_rel(rel, self.moj) if rel else ''

    def chain(self, name):
        """[material, parent, ...] defined in all.material + first undefined parent (template)."""
        out = []
        cur = name
        tmpl = b''
        for _ in range(9):
            m = self.mats.get(cur)
            if m is None:
                break
            out.append(cur)
            p = m['parent']
            if not p or p == cur or p in out:
                break
            if p not in self.mats:
                tmpl = p
                break
            cur = p
        return out, tmpl

    def material_info(self, name):
        """-> dict(tex=name bytes|None, alpha=OPAQUE|MASK|BLEND, cutoff, template, defined)."""
        ch, tmpl = self.chain(name)
        if not ch:
            return {'tex': None, 'alpha': 'OPAQUE', 'cutoff': None, 'template': '', 'defined': False}
        alias = {}
        for m in reversed(ch):
            alias.update(self.mats[m]['alias'])
        explicit = []
        for m in ch:
            explicit.extend(t for t in self.mats[m]['tex'] if b'.' in t and b'<' not in t)
        tex = None
        for k, v in alias.items():
            if k.lower() == b'<basetexture>' and b'<' not in v:
                tex = v
                break
        if tex is None and explicit:
            tex = explicit[0]
        if tex is None:
            for k, v in alias.items():
                if b'<' not in v and not NON_DIFFUSE.search(k):
                    tex = v
                    break
        if tex is None:
            vals = [v for v in alias.values() if b'<' not in v]
            tex = vals[0] if vals else None
        text = b'\n'.join(self.mbody.get(m, b'') for m in ch)
        text = re.sub(rb'//[^\n]*', b'', text)
        mr = re.search(rb'alpha_rejection\s+(\w+)\s+(\d+)', text)
        if mr:
            alpha, cutoff = 'MASK', min(1.0, max(0.0, int(mr.group(2)) / 255.0))
        elif re.search(rb'scene_blend\s+(alpha_blend|add|src_alpha)', text):
            alpha, cutoff = 'BLEND', None
        elif tmpl in CUTOUT_TEMPLATES or tmpl.startswith(b'Transparent/'):
            alpha, cutoff = 'MASK', 0.5
        else:
            alpha, cutoff = 'OPAQUE', None
        return {'tex': tex, 'alpha': alpha, 'cutoff': cutoff, 'template': F.disp(tmpl or self.mats[ch[-1]]['parent']),
                'defined': True}


# ------------------------------------------------------------------ skeleton animation names
def skel_anim_names(data):
    """Sequential walk (same layout rules as tlbbfmt.skel_info) collecting animation names."""
    n = len(data)
    names = []
    if n < 8 or data[:2] != b'\x00\x10':
        return names
    e = data.find(b'\n', 2, 80)
    if e < 0:
        return names
    p = e + 1
    try:
        while p + 6 <= n:
            cid, sz = struct.unpack_from('<HI', data, p)
            q = p + 6
            if cid == 0x1010:
                p = q + 2
            elif cid == 0x2000:
                k = data.index(b'\n', q, min(n, q + 1024))
                p = k + 1 + 2 + 28 + (12 if sz > 36 else 0)
            elif cid == 0x3000:
                p = q + 4
            elif cid == 0x4000:
                k = data.index(b'\n', q, min(n, q + 1024))
                names.append(data[q:k])
                p = k + 1 + 4
            elif cid in (0x4010, 0x5000):
                k = data.index(b'\n', q, min(n, q + 1024))
                p = k + 1 + 4
            elif cid == 0x4100:
                p = q + 2
            elif cid == 0x4120:
                cnt, fl = struct.unpack_from('<HH', data, q)
                p = q + 4 + cnt * (4 + (16 if fl & 1 else 0) + (12 if fl & 2 else 0) + (12 if fl & 4 else 0))
            elif cid == 0x4110:
                p = q + 32 + (12 if sz > 38 else 0)
            else:
                break
    except (ValueError, IndexError, struct.error):
        pass
    return names


def choose_anim(names, default_anim):
    dn = [F.disp(x) for x in names]
    if default_anim and default_anim in dn:
        return default_anim, 'DefaultAnimation'
    for pat in ('站立', '休闲'):
        if pat in dn:
            return pat, pat
        c = sorted((x for x in dn if pat in x), key=len)
        if c:
            return c[0], pat + '*'
    for x in dn:
        if re.search(r'stand|idle', x, re.I):
            return x, 'stand/idle'
    return '', 'bind pose'


# ------------------------------------------------------------------ closure of one variant
def read_trunc(path, length):
    with open(path, 'rb') as f:
        data = f.read()
    if 0 < length < len(data):
        data = data[:length]          # drop extractor padding (Docs/08 2.16)
    return data


def plan_variant(src, name):
    """Object `name` in source `src` -> JSON-able plan with a render key. Mirrors the engine
    (WXLogicModel.cpp ~2630): entity material "a;b" -> sub-entity i gets name i (else the
    first); a name that is not defined keeps the material stored in the .mesh."""
    o = src.objs.get(name)
    if o is None:
        return {'S': src.S, 'obj': name, 'error': 'object not in all.obj', 'problems': []}
    problems = []
    ents = []
    mats = {}
    skel = None
    anim, anim_rule = '', 'bind pose'
    default_anim = ''
    for an, av, ah in o['attributes']:
        if an == b'DefaultAnimation' and av.strip():
            default_anim = F.disp(av.strip())
    for e in o['entities']:
        fb = e.get(b'file', b'').strip()
        if not fb:
            continue
        rel, path = src.resolve(fb)
        if not rel:
            problems.append('mesh missing: ' + F.disp(fb))
            continue
        size, fl, sha, info = src.files.get(rel, (-1, -1, '', ''))
        mi = F.mesh_info(read_trunc(path, fl))
        if not mi['subs']:
            problems.append('mesh unreadable (%s): %s' % (mi['err'] or 'no submesh', F.disp(fb)))
            continue
        attr = e.get(b'material', b'').strip()
        names = [x.strip() for x in attr.split(b';')] if attr else []
        sub = []
        for si, internal in enumerate(mi['mats']):
            cand = (names[si] if si < len(names) else names[0]) if len(names) > 1 else (names[0] if names else b'')
            mn = cand if cand and (cand in src.mats or cand in IS.BUILTIN_MATS) else internal
            if cand and mn != cand:
                problems.append('entity material undefined, mesh material kept: ' + F.disp(cand))
            sub.append(mn)
            dn = F.disp(mn)
            if dn in mats:
                continue
            mi2 = src.material_info(mn)
            rec = {'alpha': mi2['alpha'], 'cutoff': mi2['cutoff'], 'template': mi2['template'],
                   'tex': F.disp(mi2['tex']) if mi2['tex'] else '', 'tex_path': '', 'tex_rel': '', 'tex_sha': '',
                   'tex_info': '', 'tex_len': 0}
            if not mi2['defined'] and mn not in IS.BUILTIN_MATS:
                problems.append('material undefined: ' + dn)
            if mi2['tex']:
                trel, tpath = src.resolve(mi2['tex'])
                if trel:
                    tsz, tfl, tsha, tinfo = src.files.get(trel, (-1, -1, '', ''))
                    rec.update(tex_path=tpath, tex_rel=src.disp_rel(trel), tex_sha=tsha, tex_info=tinfo, tex_len=tfl)
                else:
                    problems.append('texture missing: ' + rec['tex'])
            mats[dn] = rec
        link = mi['skel']
        if link and skel is None:
            srel, spath = src.resolve(link)
            if srel:
                ssz, sfl, ssha, sinfo = src.files.get(srel, (-1, -1, '', ''))
                names_a = skel_anim_names(read_trunc(spath, sfl))
                anim, anim_rule = choose_anim(names_a, default_anim)
                skel = {'name': F.disp(link), 'key': F.key_of(F.base_of(link)), 'path': spath,
                        'rel': src.disp_rel(srel), 'len': sfl, 'sha': ssha, 'n_anims': len(names_a), 'info': sinfo}
            else:
                problems.append('skeleton missing: ' + F.disp(link))
        ents.append({'name': F.disp(e.get(b'name', b'') or fb), 'file': F.disp(fb), 'rel': src.disp_rel(rel),
                     'path': path, 'len': fl, 'sha': sha, 'verts': mi['verts'], 'subs': mi['subs'],
                     'submats': [F.disp(x) for x in sub]})
    plan = {'S': src.S, 'obj': name, 'ents': ents, 'mats': mats, 'skel': skel, 'anim': anim,
            'anim_rule': anim_rule, 'default_anim': default_anim, 'problems': list(dict.fromkeys(problems))}
    if not ents:
        plan['error'] = 'no readable mesh'
        return plan
    plan['key'] = sha_json({'e': [[e['sha'], [[m, mats[m]['tex_sha'], mats[m]['alpha'], mats[m]['cutoff']]
                                               for m in e['submats']]] for e in ents],
                            's': skel['sha'] if skel else '', 'a': anim})
    return plan


# ------------------------------------------------------------------ conversion worker (process pool)
_T = None
_CUR = {}
_ORIG = {}


def _conv_setup():
    """Import tlbb2gltf.py unchanged and redirect its lookups to the current plan."""
    global _T
    if _T is not None:
        return _T
    if CONVERTER_DIR not in sys.path:
        sys.path.insert(0, CONVERTER_DIR)
    import tlbb2gltf as T
    _ORIG.update(read_mesh=T.read_mesh, read_skel=T.read_skel, material=T._material,
                 decode=T.ddsmod.decode, to_png=T.ddsmod.to_png)
    T.find = _p_find
    T.material_texture = _p_material_texture
    T.read_mesh = _p_read_mesh
    T.read_skel = _p_read_skel
    T._material = _p_material
    T.ddsmod.decode = _p_decode
    T.ddsmod.to_png = _p_to_png
    _T = T
    return T


def _key_any(name):
    if isinstance(name, bytes):
        return F.key_of(F.base_of(name))
    try:
        return F.key_of(F.base_of(name.encode('gbk')))
    except UnicodeEncodeError:
        return name.lower()


def _p_find(name):
    if isinstance(name, str) and name in _CUR['tokens']:
        return _CUR['tokens'][name]
    if _CUR.get('no_skel'):
        return None
    return _CUR['bykey'].get(_key_any(name))


def _p_material_texture(matname):
    rec = _CUR['mats'].get(matname if isinstance(matname, str) else F.disp(matname))
    return rec.get('token') if rec else None


def _p_read_mesh(path):
    m = _ORIG['read_mesh'](path)
    subs = _CUR['submats'].get(os.path.normcase(path))
    if subs:
        for i, s in enumerate(m['submeshes']):
            if i < len(subs):
                s['material'] = subs[i].encode('gb18030')
    return m


def _p_read_skel(path):
    sk = _ORIG['read_skel'](path)
    keep = _CUR.get('anim') or ''
    sk['anims'] = [a for a in sk['anims'] if keep and _T.dec(a['name']) == keep][:1]
    _CUR['anim_used'] = _T.dec(sk['anims'][0]['name']) if sk['anims'] else ''
    _CUR['bones'] = len(sk['bones'])
    return sk


def _p_decode(p):
    from PIL import Image
    try:
        im = Image.open(p)
        im.load()
        how = 'PIL'
    except Exception as ex:                     # unusual DDS layout -> converter's own decoder
        w, h, rgba = _ORIG['decode'](p)
        im = Image.frombytes('RGBA', (w, h), bytes(rgba))
        how = 'tlbb2gltf.dds (%s)' % type(ex).__name__
    im = im.convert('RGBA')
    src_size = im.size
    if max(im.size) > TEX_CAP:
        im.thumbnail((TEX_CAP, TEX_CAP), Image.LANCZOS)
    th = im.copy()
    th.thumbnail((128, 128), Image.LANCZOS)
    _CUR['thumbs'][os.path.normcase(p)] = (th, src_size, how)
    return im.size[0], im.size[1], im.tobytes()


def _p_to_png(w, h, rgba):
    from PIL import Image
    buf = io.BytesIO()
    Image.frombytes('RGBA', (w, h), rgba).save(buf, 'PNG', compress_level=1)
    return buf.getvalue()


def _p_material(gl, matname, no_texture):
    mi = _ORIG['material'](gl, matname, no_texture)
    rec = _CUR['mats'].get(matname) or {}
    m = gl.g['materials'][mi]
    m['doubleSided'] = True                   # review renders show every face (no culling surprises)
    if 'baseColorTexture' in m.get('pbrMetallicRoughness', {}):
        mode = rec.get('alpha', 'OPAQUE')
        m.pop('alphaCutoff', None)
        if mode == 'OPAQUE':
            m.pop('alphaMode', None)
        else:
            m['alphaMode'] = mode
            if mode == 'MASK':
                m['alphaCutoff'] = rec.get('cutoff') or 0.5
    return mi


def _tex_strip(plan, thumbs, out_path):
    from PIL import Image, ImageDraw
    seen = []
    for dn, rec in plan['mats'].items():
        p = rec.get('tex_path')
        if p and os.path.normcase(p) not in [os.path.normcase(x[0]) for x in seen]:
            seen.append((p, rec))
    tiles = []
    order = []
    for p, rec in seen[:8]:
        t = thumbs.get(os.path.normcase(p))
        if not t:
            continue
        th = t[0]
        tile = Image.new('RGB', (128, 128), (96, 96, 96))
        if rec['alpha'] != 'OPAQUE':
            d = ImageDraw.Draw(tile)
            for y in range(0, 128, 16):
                for x in range(0, 128, 16):
                    if (x // 16 + y // 16) % 2:
                        d.rectangle([x, y, x + 15, y + 15], fill=(150, 150, 150))
            tile.paste(th, ((128 - th.size[0]) // 2, (128 - th.size[1]) // 2), th)
        else:
            tile.paste(th.convert('RGB'), ((128 - th.size[0]) // 2, (128 - th.size[1]) // 2))
        tiles.append(tile)
        order.append({'tex': rec['tex'], 'info': rec['tex_info'], 'len': rec['tex_len'], 'alpha': rec['alpha'],
                      'decoded': '%dx%d' % t[1], 'decoder': t[2]})
    if not tiles:
        return []
    strip = Image.new('RGB', (130 * len(tiles) - 2, 128), (255, 255, 255))
    for i, t in enumerate(tiles):
        strip.paste(t, (130 * i, 0))
    strip.save(out_path, 'JPEG', quality=88)
    return order


def convert_unit(task):
    """task = dict(plan, glb, work) -> result dict. Runs in a worker process."""
    t0 = time.time()
    res = {'oid': task['oid'], 'vid': task['vid'], 'ok': False, 'warnings': [], 'glb': task['glb']}
    try:
        T = _conv_setup()
        plan = task['plan']
        work = task['work']
        os.makedirs(work, exist_ok=True)
        tokens, submats = {}, {}
        ents = []
        for i, e in enumerate(plan['ents']):
            sp = os.path.join(work, 'ent%d.mesh' % i)
            with open(sp, 'wb') as f:
                f.write(read_trunc(e['path'], e['len']))
            tokens['ENT%d' % i] = sp
            submats[os.path.normcase(sp)] = e['submats']
            ents.append({'name': e['name'], 'file': 'ENT%d' % i, 'material': ''})
        bykey = {}
        if plan.get('skel'):
            sp = os.path.join(work, 'skel.skeleton')
            with open(sp, 'wb') as f:
                f.write(read_trunc(plan['skel']['path'], plan['skel']['len']))
            bykey[plan['skel']['key']] = sp
        mats = {}
        for j, (dn, rec) in enumerate(plan['mats'].items()):
            rec = dict(rec)
            if rec.get('tex_path'):
                rec['token'] = 'TEX%d' % j
                tokens[rec['token']] = rec['tex_path']
            mats[dn] = rec
        for attempt in (0, 1):
            _CUR.clear()
            _CUR.update(tokens=tokens, submats=submats, bykey=bykey, mats=mats, anim=plan.get('anim', ''),
                        thumbs={}, no_skel=(attempt == 1))
            T._MATCACHE.clear()
            buf = io.StringIO()
            try:
                with contextlib.redirect_stdout(buf):
                    T.export(ents, task['glb'], None, False, verbose=True)
                break
            except BaseException as ex:          # tlbb2gltf raises SystemExit on "no mesh"
                if attempt == 0 and plan.get('skel'):
                    res['warnings'].append('skeleton/animation failed (%s: %s) -> static bind pose'
                                           % (type(ex).__name__, str(ex)[:160]))
                    continue
                raise
        out = buf.getvalue()
        res['warnings'].extend(ln.strip() for ln in out.splitlines() if ln.strip().startswith('!'))
        res['anim_used'] = _CUR.get('anim_used', '')
        res['bones'] = _CUR.get('bones', 0)
        res['static'] = bool(_CUR.get('no_skel'))
        res['glb_bytes'] = os.path.getsize(task['glb'])
        strip = os.path.join(work, 'tex.jpg')
        res['tex_order'] = _tex_strip(plan, _CUR['thumbs'], strip)
        res['texstrip'] = strip if res['tex_order'] else ''
        res['ok'] = True
    except BaseException as ex:
        res['error'] = '%s: %s' % (type(ex).__name__, str(ex)[:300])
        res['trace'] = traceback.format_exc()[-1500:]
    res['time'] = round(time.time() - t0, 2)
    return res


# ------------------------------------------------------------------ images
def composite(png, jpg):
    from PIL import Image
    im = Image.open(png).convert('RGBA')
    bg = Image.new('RGBA', im.size, BG_RGB + (255,))
    bg.alpha_composite(im)
    bg.convert('RGB').save(jpg, 'JPEG', quality=90, optimize=True)


def below_normal_priority():
    """Other agents compile C++ on this machine: run this tool and its children politely."""
    if os.name == 'nt':
        try:
            import ctypes
            k = ctypes.windll.kernel32
            k.SetPriorityClass(k.GetCurrentProcess(), 0x00004000)   # BELOW_NORMAL_PRIORITY_CLASS
        except Exception:
            pass


# ------------------------------------------------------------------ pipeline
class Run:
    def __init__(self, args):
        self.args = args
        self.out = os.path.abspath(args.out)
        self.img = os.path.join(self.out, 'img')
        self.work = os.path.join(REVIEW_ROOT, '_work', os.path.basename(self.out.rstrip('\\/')))
        self.objs = []            # object records (see plan_all)
        self.by_oid = {}
        self.failures = []        # (obj, source/vid, stage, reason)
        self.t = {}

    # ---- planning
    def plan_all(self, rows, srcs):
        for r in rows:
            name = r['obj']
            oid = oid_of(name)
            rec = {'obj': name, 'oid': oid, 'row': r, 'batch': r.get('_batch', 0), 'plans': {}, 'vid_of': {},
                   'units': {}, 'conv': {}, 'render': {}, 'status': 'planned'}
            for S in present_of(r):
                p = plan_variant(srcs[S], name)
                rec['plans'][S] = p
                if p.get('error'):
                    self.failures.append((name, S, 'plan', p['error']))
                    continue
                vid = 'v' + p['key'][:10]
                rec['vid_of'][S] = vid
                rec['units'].setdefault(vid, {'plan': p, 'sources': []})['sources'].append(S)
            self.objs.append(rec)
            self.by_oid[oid] = rec

    def unit_done(self, rec, vid):
        d = os.path.join(self.img, rec['oid'])
        return all(os.path.exists(os.path.join(d, '%s_%s.jpg' % (vid, tag))) for tag, _a, _e in VIEWS) and \
            os.path.exists(os.path.join(d, vid + '.json'))

    # ---- conversion + rendering
    def execute(self):
        a = self.args
        todo = []
        for rec in self.objs:
            if not rec['units']:
                rec['status'] = 'failed'
                continue
            if not a.force and all(self.unit_done(rec, vid) for vid in rec['units']):
                rec['status'] = 'cached'
                continue
            todo.append(rec)
        log('render: %d objects to do, %d cached, %d without any usable variant' % (
            len(todo), sum(r['status'] == 'cached' for r in self.objs), sum(r['status'] == 'failed' for r in self.objs)))
        if not todo:
            return
        os.makedirs(os.path.join(self.work, 'jobs'), exist_ok=True)
        t0 = time.time()
        futs = {}
        left = {}
        ready = collections.deque()
        retry = collections.deque()
        running = []
        chunk_no = 0
        n_done = 0
        with cf.ProcessPoolExecutor(max_workers=max(1, a.convert_jobs)) as ex:
            for rec in todo:
                left[rec['oid']] = set(rec['units'])
                for vid, u in rec['units'].items():
                    wdir = os.path.join(self.work, rec['oid'], vid)
                    task = {'oid': rec['oid'], 'vid': vid, 'plan': u['plan'], 'work': wdir,
                            'glb': os.path.join(self.work, rec['oid'], vid + '.glb')}
                    futs[ex.submit(convert_unit, task)] = (rec['oid'], vid)
            last = 0
            while futs or ready or retry or running:
                for fu in [f for f in futs if f.done()]:
                    oid, vid = futs.pop(fu)
                    rec = self.by_oid[oid]
                    try:
                        res = fu.result()
                    except BaseException as e:           # worker died
                        res = {'ok': False, 'error': 'worker: %s: %s' % (type(e).__name__, e), 'warnings': []}
                    rec['conv'][vid] = res
                    if not res.get('ok'):
                        self.failures.append((rec['obj'], '/'.join(rec['units'][vid]['sources']), 'convert',
                                              res.get('error', '?')))
                    left[oid].discard(vid)
                    if not left[oid]:
                        if any(c.get('ok') for c in rec['conv'].values()):
                            ready.append(oid)
                        else:
                            rec['status'] = 'failed'
                while len(running) < min(MAX_BLENDER, max(1, a.jobs)) and (retry or ready):
                    if retry:
                        chunk, single = [retry.popleft()], True
                    elif len(ready) >= a.chunk or not futs:
                        chunk, single = [ready.popleft() for _ in range(min(a.chunk, len(ready)))], False
                    else:
                        break
                    chunk_no += 1
                    running.append(self.launch(chunk, chunk_no, single))
                for item in list(running):
                    p, chunk, t_start, limit, jpath, single = item
                    code = p.poll()
                    timed_out = code is None and time.time() - t_start > limit
                    if code is None and not timed_out:
                        continue
                    if timed_out:
                        p.kill()
                        p.wait()
                    running.remove(item)
                    for oid in chunk:
                        rec = self.by_oid[oid]
                        rj = os.path.join(self.work, oid, 'render', 'result.json')
                        if os.path.exists(rj):
                            self.finish_object(rec, rj)
                            n_done += 1
                        elif not single:
                            retry.append(oid)
                        else:
                            why = ('timeout %ds' % limit) if timed_out else ('blender exit %s' % code)
                            rec['status'] = 'failed'
                            rec['render_error'] = why + ': ' + tail(jpath[:-5] + '.log')
                            self.failures.append((rec['obj'], '*', 'render', rec['render_error']))
                if time.time() - last > 20:
                    last = time.time()
                    log('  progress: %d/%d objects rendered, %d converting, %d ready, %d blender running, %.0fs'
                        % (n_done, len(todo), len(futs), len(ready), len(running), time.time() - t0))
                time.sleep(0.3)
        log('render done: %d objects in %.0fs' % (n_done, time.time() - t0))

    def launch(self, chunk, no, single):
        a = self.args
        objs = []
        for oid in chunk:
            rec = self.by_oid[oid]
            rdir = os.path.join(self.work, oid, 'render')
            os.makedirs(rdir, exist_ok=True)
            rj = os.path.join(rdir, 'result.json')
            if os.path.exists(rj):
                os.remove(rj)
            objs.append({'oid': oid, 'out': rdir,
                         'variants': [{'vid': vid, 'glb': c['glb']} for vid, c in rec['conv'].items() if c.get('ok')]})
        job = {'size': RENDER_SIZE, 'samples': a.samples, 'front': list(FRONT), 'ambient': LIGHTS['ambient'],
               'key': LIGHTS['key'], 'fill': LIGHTS['fill'], 'rim': LIGHTS['rim'],
               'views': [[t, az, el] for t, az, el in VIEWS], 'objects': objs}
        jpath = os.path.join(self.work, 'jobs', 'chunk%04d%s.json' % (no, 's' if single else ''))
        with open(jpath, 'w', encoding='utf-8') as f:
            json.dump(job, f, ensure_ascii=False, indent=1)
        logf = open(jpath[:-5] + '.log', 'w', encoding='utf-8', errors='replace')
        cmd = [a.blender, '-b', '--factory-startup', '-noaudio', '-P', BLENDER_SCRIPT, '--', jpath]
        flags = getattr(subprocess, 'BELOW_NORMAL_PRIORITY_CLASS', 0)
        p = subprocess.Popen(cmd, stdout=logf, stderr=subprocess.STDOUT, creationflags=flags)
        logf.close()
        nvar = sum(len(o['variants']) for o in objs)
        return (p, chunk, time.time(), 90 + 45 * nvar, jpath, single)

    def finish_object(self, rec, rj):
        with open(rj, encoding='utf-8') as f:
            res = json.load(f)
        rec['render'] = res
        d = os.path.join(self.img, rec['oid'])
        os.makedirs(d, exist_ok=True)
        ok_any = False
        for vid, u in rec['units'].items():
            conv = rec['conv'].get(vid, {})
            vr = res.get('variants', {}).get(vid, {})
            meta = {'vid': vid, 'sources': u['sources'], 'conv': {k: v for k, v in conv.items() if k not in ('trace',)},
                    'render': vr, 'engine': res.get('engine'), 'blender': res.get('blender'),
                    'union_bbox': res.get('union_bbox')}
            if conv.get('ok') and vr.get('ok'):
                try:
                    for tag, path in vr['images'].items():
                        composite(path, os.path.join(d, '%s_%s.jpg' % (vid, tag)))
                    if conv.get('texstrip') and os.path.exists(conv['texstrip']):
                        shutil.copyfile(conv['texstrip'], os.path.join(d, vid + '_tex.jpg'))
                    ok_any = True
                except Exception as ex:
                    vr['ok'] = False
                    vr['error'] = 'composite: %s: %s' % (type(ex).__name__, ex)
            if conv.get('ok') and not vr.get('ok'):
                self.failures.append((rec['obj'], '/'.join(u['sources']), 'render',
                                      vr.get('error') or res.get('error') or 'no image'))
            with open(os.path.join(d, vid + '.json'), 'w', encoding='utf-8') as f:
                json.dump(meta, f, ensure_ascii=False, indent=1)
        rec['status'] = 'rendered' if ok_any else 'failed'


def tail(path, n=600):
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            s = f.read()
        lines = [ln for ln in s.splitlines() if ln.strip()]
        return ' | '.join(lines[-4:])[-n:]
    except OSError:
        return '(no log)'


# ------------------------------------------------------------------ page data
FRONT = (0.0, -1.0, 0.0)      # model front after glTF import (Ogre +Z -> Blender -Y)
LIGHTS = {'ambient': 0.45, 'key': 3.0, 'fill': 1.0, 'rim': 1.8}
METRICS = (('verts', 'đỉnh'), ('tris', 'tam giác'), ('subs', 'submesh'), ('sub_bones', 'xương/submesh'),
           ('skel_bones', 'xương'), ('anims', 'animation'), ('n_tex', 'texture'), ('max_tex_px', 'tex lớn nhất'),
           ('tex_formats', 'định dạng'), ('tex_kb', 'texture KB'), ('mesh_kb', 'mesh KB'), ('complete', 'đủ file'))


def split_sum(s):
    return sum(ival(x) for x in (s or '').split(';') if x.strip() and x.strip() != '-')


def hint_source(hint, present):
    m = re.match(r'\s*(S[123])', hint or '')
    if m and m.group(1) in present:
        return m.group(1)
    for S in ('S1', 'S3', 'S2'):
        if S in present:
            return S
    return ''


def s4_note(row):
    known, _, unk = (row.get('mesh_groups') or '').partition(' ')
    groups = [g.split('=') for g in known.split('|') if g]
    for g in groups:
        if 'S4' in g and 'S2' not in g and row.get('in_S4') == 'y':
            others = [x for x in g if x != 'S4']
            return ('S4 (CY Game 3.71.9609, AXP) có mesh %s, KHÁC file S2 đã giải (DataCY)'
                    % ('giống ' + '='.join(others) if others else 'riêng'))
    if 'S4?' in unk:
        return 'S4: mesh bọc AXP kiểu 1–18, chỉ S2 có bản giải (không kiểm được S4)'
    return ''


def load_meta(img_dir, oid, vid):
    p = os.path.join(img_dir, oid, vid + '.json')
    try:
        with open(p, encoding='utf-8') as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def image_coverage(path):
    """Share of pixels that differ from the grey background (0 = empty render)."""
    try:
        import numpy as np
        from PIL import Image
        a = np.asarray(Image.open(path).convert('RGB').resize((128, 128)), dtype=np.int16)
        return round(float((np.abs(a - np.array(BG_RGB, dtype=np.int16)).max(axis=2) > 10).mean()), 4)
    except Exception:
        return None


def build_data(run, srcs):
    data = []
    for rec in run.objs:
        r = rec['row']
        name, oid = rec['obj'], rec['oid']
        present = [S for S in SRCS if S in rec['plans']]
        cols = {}
        for S in SRCS:
            p = rec['plans'].get(S)
            if p is None:
                cols[S] = {'present': False}
                continue
            m = srcs[S].models.get(name, {})
            vid = rec['vid_of'].get(S)
            same_as = next((T for T in SRCS if T != S and SRCS.index(T) < SRCS.index(S)
                            and vid and rec['vid_of'].get(T) == vid), '')
            meta = load_meta(run.img, oid, vid) if vid else None
            conv = (meta or {}).get('conv') or rec['conv'].get(vid) or {}
            rend = (meta or {}).get('render') or {}
            imgs = {}
            for tag, _a, _e in VIEWS:
                f = os.path.join(run.img, oid, '%s_%s.jpg' % (vid, tag))
                if vid and os.path.exists(f):
                    imgs[tag] = 'img/%s/%s_%s.jpg' % (oid, vid, tag)
            texstrip = 'img/%s/%s_tex.jpg' % (oid, vid) if vid and os.path.exists(
                os.path.join(run.img, oid, vid + '_tex.jpg')) else ''
            texs = []
            seen = set()
            for dn, t in p.get('mats', {}).items():
                key = t.get('tex') or ('(no texture) ' + dn)
                if key in seen:
                    continue
                seen.add(key)
                texs.append({'mat': dn, 'tex': t.get('tex', ''), 'info': t.get('tex_info', ''),
                             'kb': round(t.get('tex_len', 0) / 1024.0, 1), 'alpha': t.get('alpha', ''),
                             'template': t.get('template', ''), 'found': bool(t.get('tex_path'))})
            metrics = {'verts': ival(m.get('verts')), 'tris': ival(m.get('tris')), 'subs': ival(m.get('submeshes')),
                       'sub_bones': ival(m.get('max_sub_bones')), 'skel_bones': ival(m.get('skel_bones')),
                       'anims': ival(m.get('anims')), 'n_tex': len([x for x in (m.get('textures') or '').split(';') if x]),
                       'max_tex_px': ival(m.get('max_tex_px')), 'tex_formats': m.get('tex_formats', ''),
                       'tex_kb': round(ival(m.get('tex_bytes')) / 1024.0, 1),
                       'mesh_kb': round(split_sum(m.get('mesh_bytes')) / 1024.0, 1), 'complete': m.get('complete', '')}
            err = p.get('error') or ''
            if not err and vid and not imgs:
                err = rend.get('error') or conv.get('error') or rec.get('render_error') or 'chưa render'
            cols[S] = {'present': True, 'vid': vid or '', 'same_as': same_as, 'images': imgs, 'texstrip': texstrip,
                       'tex_order': conv.get('tex_order') or [], 'textures': texs, 'metrics': metrics,
                       'meshes': [{'file': e['file'], 'rel': e['rel'], 'verts': e['verts'], 'subs': e['subs']}
                                  for e in p.get('ents', [])],
                       'skeleton': ({'name': p['skel']['name'], 'rel': p['skel']['rel'], 'anims': p['skel']['n_anims']}
                                    if p.get('skel') else None),
                       'pose': p.get('anim') or '', 'pose_rule': p.get('anim_rule', ''),
                       'static': conv.get('static', False), 'effects': m.get('effects', ''),
                       'locators': ival(m.get('locators')), 'problems': p.get('problems', []),
                       'warnings': conv.get('warnings', []), 'error': err,
                       'render': dict({k: rend.get(k) for k in ('nverts', 'dropped', 'frame', 'actions')},
                                      coverage=image_coverage(os.path.join(run.img, oid, '%s_f.jpg' % vid))
                                      if imgs.get('f') else None)}
        diffs = []
        for k, lab in METRICS:
            vals = {S: cols[S]['metrics'][k] for S in present if cols[S].get('present')}
            if len(set(map(str, vals.values()))) > 1:
                diffs.append(k)
        mesh_sets = {S: tuple(sorted(e['file'].lower() for e in cols[S]['meshes'])) for S in present}
        if len(set(mesh_sets.values())) > 1:
            diffs.append('mesh_files')
        data.append({'obj': name, 'oid': oid, 'batch': rec['batch'], 'hint': r.get('hint', ''),
                     'default': hint_source(r.get('hint', ''), present), 'present': present,
                     'groups': {k: r.get(k + '_groups', '') for k in ('objdef', 'mesh', 'tex', 'tex_dims', 'matdef')},
                     'state': {k: r.get(k, '') for k in ('objdef', 'mesh', 'tex', 'tex_dims', 'matdef')},
                     's4': s4_note(r), 'diffs': diffs, 'cols': cols, 'status': rec['status']})
    return data


# ------------------------------------------------------------------ summary
def write_summary(run, data, t_start, timings, blender_ver):
    fails = [{'obj': o, 'sources': s, 'stage': st, 'reason': why} for o, s, st, why in run.failures]
    n_cols = sum(len(d['present']) for d in data)
    units = sum(len({c['vid'] for c in d['cols'].values() if c.get('present') and c.get('vid')}) for d in data)
    units_img = sum(len({c['vid'] for c in d['cols'].values() if c.get('present') and c.get('images')}) for d in data)
    cols_img = sum(1 for d in data for c in d['cols'].values() if c.get('present') and c.get('images'))
    objs_ok = sum(1 for d in data if all(d['cols'][S].get('images') for S in d['present']))
    objs_part = sum(1 for d in data if any(d['cols'][S].get('images') for S in d['present'])) - objs_ok
    by_reason = collections.Counter(re.sub(r'[:(].*', '', f['reason']).strip() or '?' for f in fails)
    with open(CONVERTER, 'rb') as f:
        conv_sha = hashlib.sha256(f.read()).hexdigest()
    s = {'tool': 'review.py ' + TOOL_VERSION, 'started': datetime.datetime.fromtimestamp(t_start).isoformat(timespec='seconds'),
         'finished': datetime.datetime.now().isoformat(timespec='seconds'), 'elapsed_s': round(time.time() - t_start, 1),
         'timings_s': timings, 'command': ' '.join(sys.argv), 'out': run.out, 'batch': run.args.batch,
         'blender': blender_ver, 'converter': {'path': CONVERTER, 'sha256': conv_sha},
         'render': {'size': RENDER_SIZE, 'samples': run.args.samples, 'views': VIEWS, 'front': FRONT, 'lights': LIGHTS,
                    'texture_cap_px': TEX_CAP, 'background_rgb': BG_RGB},
         'objects': len(data), 'objects_all_variants_rendered': objs_ok, 'objects_partly_rendered': objs_part,
         'objects_not_rendered': len(data) - objs_ok - objs_part,
         'source_columns': n_cols, 'source_columns_with_image': cols_img,
         'distinct_variants': units, 'distinct_variants_rendered': units_img,
         'failures': fails, 'failure_reasons': dict(by_reason),
         'selection_yaml_target': SELECTION_YAML}
    s.update(getattr(run, 'extra', None) or {})
    with open(os.path.join(run.out, 'summary.json'), 'w', encoding='utf-8') as f:
        json.dump(s, f, ensure_ascii=False, indent=1)
    L = ['review.py %s - variant review sheet %s' % (TOOL_VERSION, os.path.basename(run.out)),
         'started %s, finished %s, elapsed %.0f s' % (s['started'], s['finished'], s['elapsed_s']),
         'timings (s): %s' % timings, 'blender: %s   converter: %s (sha256 %s)' % (blender_ver, CONVERTER, conv_sha[:16]),
         '', 'objects: %d  (all variants rendered %d, partly %d, none %d)' % (
             len(data), objs_ok, objs_part, s['objects_not_rendered']),
         'source columns: %d (with image %d); distinct variants: %d (rendered %d)' % (n_cols, cols_img, units, units_img),
         '', 'failures: %d' % len(fails)]
    for k, v in by_reason.most_common():
        L.append('  %-40s %d' % (k, v))
    for f in fails:
        L.append('  - %s [%s] %s: %s' % (f['obj'], f['sources'], f['stage'], f['reason'][:300]))
    L += ['', 'page: ' + os.path.join(run.out, 'index.html'),
          'selections go to: ' + SELECTION_YAML + ' (copy the YAML from the page; this tool never writes it)']
    with open(os.path.join(run.out, 'summary.txt'), 'w', encoding='utf-8-sig', newline='\r\n') as f:
        f.write('\n'.join(L) + '\n')
    return s


def blender_version(exe):
    try:
        out = subprocess.run([exe, '-b', '--factory-startup', '--version'], capture_output=True, text=True,
                             timeout=120, errors='replace').stdout
        m = re.search(r'Blender\s+(\d+\.\d+(?:\.\d+)?(?:\s+LTS)?)', out)
        return m.group(1).strip() if m else '?'
    except Exception as ex:
        return '? (%s)' % type(ex).__name__


def cleanup_work(run):
    """Drop bulky work files (GLB, raw PNG, staged mesh copies); keep job JSON + logs."""
    n = 0
    for rec in run.objs:
        d = os.path.join(run.work, rec['oid'])
        if os.path.isdir(d):
            shutil.rmtree(d, ignore_errors=True)
            n += 1
    return n


# ------------------------------------------------------------------ HTML (single local file, no external URL)
CSS = r"""
:root{--bg:#f4f4f2;--card:#fff;--ink:#1d1d1f;--mute:#6b6b70;--line:#dcdcd8;--acc:#1f6feb;--sel:#e3efff;--diff:#fff3c4;
--bad:#b42318;--ok:#1a7f37;--im:220px;--chip:#eceae4}
@media (prefers-color-scheme:dark){:root{--bg:#161618;--card:#1f1f22;--ink:#e8e8ea;--mute:#9a9aa1;--line:#34343a;
--acc:#6aa6ff;--sel:#1e2c44;--diff:#3a3217;--bad:#ff8a80;--ok:#7ee2a8;--chip:#2a2a2e}}
body[data-sz=s]{--im:150px} body[data-sz=l]{--im:300px}
*{box-sizing:border-box} body{margin:0;background:var(--bg);color:var(--ink);font:13px/1.45 "Segoe UI",system-ui,sans-serif}
header{padding:14px 18px 6px} h1{font-size:19px;margin:0 0 6px} .lead{color:var(--mute);max-width:1200px;margin:4px 0}
.lead b{color:var(--ink)} code{font:12px Consolas,monospace;background:var(--chip);padding:0 3px;border-radius:3px}
.bar{position:sticky;top:0;z-index:5;background:var(--bg);border-bottom:1px solid var(--line);padding:8px 18px;
display:flex;flex-wrap:wrap;gap:8px;align-items:center}
.bar input[type=search]{width:280px;padding:5px 8px;border:1px solid var(--line);border-radius:6px;background:var(--card);color:var(--ink)}
.bar select,.bar button{padding:5px 9px;border:1px solid var(--line);border-radius:6px;background:var(--card);color:var(--ink);cursor:pointer}
.bar button.pri{background:var(--acc);color:#fff;border-color:var(--acc)} .cnt{color:var(--mute)}
#yaml{display:block;width:calc(100% - 36px);margin:8px 18px;height:220px;font:12px Consolas,monospace;
background:var(--card);color:var(--ink);border:1px solid var(--line);border-radius:6px;padding:8px}
.wrap{overflow-x:auto;padding:0 18px 30px}
table.t{border-collapse:separate;border-spacing:0 10px;min-width:calc(var(--im)*6 + 430px);width:100%}
tr.obj>td{background:var(--card);vertical-align:top;padding:8px 10px;border-top:1px solid var(--line);border-bottom:1px solid var(--line)}
tr.obj>td:first-child{border-left:1px solid var(--line);border-radius:8px 0 0 8px;width:300px;min-width:300px;max-width:340px}
tr.obj>td:last-child{border-right:1px solid var(--line);border-radius:0 8px 8px 0}
tr.obj.chg>td:first-child{box-shadow:inset 4px 0 0 var(--acc)}
.nm{font-size:16px;font-weight:600;word-break:break-all} .sub,.grp,.note{color:var(--mute);font-size:12px}
.hint{margin:6px 0} .hint b{color:var(--ink)} .grp b{color:var(--ink);font-weight:600}
.note{color:var(--bad)} .dl{margin-top:6px} .chip{display:inline-block;background:var(--chip);border-radius:9px;padding:0 7px;margin:1px 2px 1px 0;font-size:11px}
.pick{margin-top:8px;font-weight:600} .pick .chg{color:var(--acc);display:none} tr.chg .pick .chg{display:inline}
td.v{min-width:calc(var(--im)*2 + 30px)} td.v.sel{background:var(--sel)!important}
td.v label.r{display:flex;gap:6px;align-items:center;font-size:14px;cursor:pointer;margin-bottom:6px}
td.v label.r b{font-size:15px} .badge{font-size:11px;border-radius:9px;padding:0 7px;background:var(--chip);color:var(--mute)}
.badge.h{background:var(--acc);color:#fff} .badge.same{background:#d8f5e1;color:#135d2c}
@media (prefers-color-scheme:dark){.badge.same{background:#173d25;color:#9be8b6}}
.imgs{display:flex;gap:4px} .imgs img{width:var(--im);height:var(--im);display:block;border-radius:4px;background:#808080}
.tex img{height:calc(var(--im)*0.42);max-width:calc(var(--im)*2 + 4px);object-fit:contain;display:block;margin-top:4px;border-radius:3px}
.none{color:var(--mute);padding:30px 0;text-align:center}
table.m{border-collapse:collapse;margin-top:6px;font-size:12px} table.m td{padding:1px 8px 1px 0;border:0}
table.m td.k{color:var(--mute)} table.m tr.d td.x{background:var(--diff)} table.m tr.d td.x.top{font-weight:700}
details{margin-top:4px;font-size:12px} summary{cursor:pointer;color:var(--acc)} details ul{margin:4px 0 0 16px;padding:0}
details li{word-break:break-all} .w{color:var(--bad);font-size:12px;margin-top:4px} .muted{color:var(--mute)}
footer{padding:0 18px 40px;color:var(--mute)} footer li{word-break:break-all}
"""

JS = r"""
const KEY='cysrc-review-__BATCH__', TARGET=__TARGET__, VER=__VER__;
const rows=[...document.querySelectorAll('tr.obj')];
let saved={}; try{saved=JSON.parse(localStorage.getItem(KEY)||'{}')||{}}catch(e){saved={}}
function cur(tr){const r=tr.querySelector('input[type=radio]:checked');return r?r.value:''}
function mark(tr){const v=cur(tr);tr.querySelectorAll('td.v').forEach(td=>td.classList.toggle('sel',td.dataset.src===v));
 tr.classList.toggle('chg',v!==tr.dataset.def);tr.querySelector('.cur').textContent=v||'-'}
function counts(){let c=0,s=0;rows.forEach(tr=>{if(tr.classList.contains('chg'))c++;if(!tr.hidden)s++});
 document.getElementById('nchg').textContent=c;document.getElementById('nshow').textContent=s}
rows.forEach(tr=>{const v=saved[tr.id];if(v){const r=tr.querySelector('input[value="'+v+'"]');if(r&&!r.disabled)r.checked=true}mark(tr)});
document.addEventListener('change',e=>{const t=e.target;if(t.type!=='radio')return;const tr=t.closest('tr.obj');
 saved[tr.id]=t.value;try{localStorage.setItem(KEY,JSON.stringify(saved))}catch(err){}mark(tr);counts()});
function applyFilter(){const q=document.getElementById('q').value.toLowerCase().trim();const f=document.getElementById('f').value;
 rows.forEach(tr=>{let ok=!q||tr.dataset.s.includes(q);if(ok&&f!=='all'){if(f==='b1')ok=tr.dataset.b==='1';else if(f==='b2')ok=tr.dataset.b==='2';
 else if(f==='chg')ok=tr.classList.contains('chg');else ok=tr.dataset.f.includes(f)}tr.hidden=!ok});counts()}
document.getElementById('q').addEventListener('input',applyFilter);document.getElementById('f').addEventListener('change',applyFilter);
document.getElementById('sz').addEventListener('change',e=>{document.body.dataset.sz=e.target.value});
function yaml(){const d=new Date().toISOString().slice(0,10);let n=0,c=0;const L=[];
 rows.forEach(tr=>{const v=cur(tr);if(!v)return;n++;if(v!==tr.dataset.def)c++;L.push(JSON.stringify(tr.dataset.obj)+': '+v)});
 const head=['# '+TARGET,'# written from review index.html ('+VER+') on '+d+': '+n+' objects, '+c+' changed from the hint',
 '# format: "<obj name in all.obj>": S1|S2|S3   (S1 client_GL, S2 DataCY 3.71, S3 CYHJ)'];
 const ta=document.getElementById('yaml');ta.value=head.concat(L).join('\n')+'\n';ta.hidden=false;ta.focus();ta.select()}
document.getElementById('bY').addEventListener('click',yaml);
document.getElementById('bC').addEventListener('click',()=>{yaml();const ta=document.getElementById('yaml');
 const done=()=>{document.getElementById('bC').textContent='Đã chép';setTimeout(()=>{document.getElementById('bC').textContent='Chép YAML'},1500)};
 if(navigator.clipboard&&window.isSecureContext){navigator.clipboard.writeText(ta.value).then(done,()=>{document.execCommand('copy');done()})}
 else{document.execCommand('copy');done()}});
document.getElementById('bR').addEventListener('click',()=>{if(!confirm('Đặt lại mọi lựa chọn theo gợi ý?'))return;saved={};
 try{localStorage.removeItem(KEY)}catch(e){}rows.forEach(tr=>{const r=tr.querySelector('input[value="'+tr.dataset.def+'"]');if(r)r.checked=true;mark(tr)});counts()});
counts();
"""

FLAG_OPTS = (('all', 'Tất cả'), ('b1', 'Đợt 1 (có ở S1–S4)'), ('b2', 'Đợt 2 (còn lại)'), ('m', 'Mesh khác nhau'),
             ('t', 'Kích thước texture khác'), ('f', 'Danh sách file mesh khác'), ('a', 'Số animation khác'),
             ('x', 'Có lỗi / thiếu ảnh'), ('n', 'Ghi chú S4'), ('chg', 'Đã đổi so với gợi ý'))
MLABEL = dict(METRICS)
NUMERIC = {'verts', 'tris', 'subs', 'sub_bones', 'skel_bones', 'anims', 'n_tex', 'max_tex_px', 'tex_kb', 'mesh_kb'}


def esc(x):
    return html.escape('' if x is None else str(x), quote=True)


def fmt_num(k, v):
    if k in ('tex_kb', 'mesh_kb'):
        return '{:,.1f}'.format(v)
    return '{:,}'.format(v) if isinstance(v, int) else esc(v)


def cell_html(d, S):
    c = d['cols'][S]
    oid = d['oid']
    if not c.get('present'):
        return ('<td class="v" data-src="%s"><label class="r"><input type="radio" name="%s" value="%s" disabled>'
                '<b>%s</b></label><div class="none">không có trong nguồn này</div></td>' % (S, oid, S, S))
    badges = []
    if S == d['default']:
        badges.append('<span class="badge h">gợi ý</span>')
    if c['same_as']:
        badges.append('<span class="badge same">giống hệt %s</span>' % c['same_as'])
    h = ['<td class="v" data-src="%s"><label class="r"><input type="radio" name="%s" value="%s"%s><b>%s</b>'
         '<span class="muted">%s</span>%s</label>' % (S, oid, S, ' checked' if S == d['default'] else '', S,
                                                     esc(SRC_LABEL[S][3:]), ''.join(badges))]
    if c['images']:
        h.append('<div class="imgs">')
        for tag, lab in (('f', '3/4 trước'), ('b', '3/4 sau')):
            if tag in c['images']:
                h.append('<a href="%s" target="_blank" title="%s %s"><img loading="lazy" src="%s" alt="%s %s"></a>'
                         % (esc(c['images'][tag]), S, lab, esc(c['images'][tag]), S, lab))
        h.append('</div>')
    else:
        h.append('<div class="none w">không có ảnh: %s</div>' % esc(c['error'] or '?'))
    if c['texstrip']:
        h.append('<div class="tex"><a href="%s" target="_blank"><img loading="lazy" src="%s" alt="texture %s" '
                 'title="%s"></a></div>' % (esc(c['texstrip']), esc(c['texstrip']), S,
                                            esc(' | '.join('%s %s' % (t['tex'], t['info']) for t in c['tex_order']))))
    others = [T for T in d['present'] if T != S]
    h.append('<table class="m">')
    for k, lab in METRICS:
        v = c['metrics'][k]
        vals = [d['cols'][T]['metrics'][k] for T in d['present']]
        differ = len(set(map(str, vals))) > 1
        top = differ and k in NUMERIC and v == max(vals)
        h.append('<tr%s><td class="k">%s</td><td class="x%s">%s</td></tr>' % (
            ' class="d"' if differ else '', lab, ' top' if top else '', fmt_num(k, v) if v != '' else '-'))
    pose = c['pose'] + (' (%s)' % c['pose_rule'] if c['pose'] else '') if c['pose'] else 'bind pose'
    if c['static']:
        pose += ' - skeleton lỗi, dựng tĩnh'
    h.append('<tr><td class="k">tư thế</td><td>%s</td></tr></table>' % esc(pose))
    fl = ['<li>mesh <b>%s</b> <span class="muted">%s · %s đỉnh · %s sub</span></li>' % (
        esc(m['file']), esc(m['rel']), '{:,}'.format(m['verts']), m['subs']) for m in c['meshes']]
    if c['skeleton']:
        fl.append('<li>skeleton <b>%s</b> <span class="muted">%s · %d animation</span></li>' % (
            esc(c['skeleton']['name']), esc(c['skeleton']['rel']), c['skeleton']['anims']))
    for t in c['textures']:
        fl.append('<li>texture <b>%s</b> <span class="muted">%s · %s KB · %s · material %s%s</span></li>' % (
            esc(t['tex'] or '(không)'), esc(t['info']), t['kb'], esc(t['alpha']), esc(t['mat']),
            '' if t['found'] or not t['tex'] else ' · <span class="w">THIẾU FILE</span>'))
    if c['effects']:
        fl.append('<li>effect <span class="muted">%s</span></li>' % esc(c['effects']))
    h.append('<details><summary>file: %d mesh, %s, %d texture</summary><ul>%s</ul></details>' % (
        len(c['meshes']), 'có skeleton' if c['skeleton'] else 'không skeleton', len(c['textures']), ''.join(fl)))
    notes = list(c['problems']) + list(c['warnings'])
    if c['render'].get('dropped'):
        notes.append('%d đỉnh bị animation dời ra rất xa (bộ phận giấu) không tính khi đặt khung hình'
                     % c['render']['dropped'])
    cov = c['render'].get('coverage')
    if cov is not None and cov < 0.002:
        notes.append('ảnh gần như trống: model rỗng hoặc trong suốt (vật mốc hiệu ứng / 空物体)')
    if notes:
        h.append('<div class="w">%s</div>' % '<br>'.join(esc(x) for x in notes[:6]))
    if others:
        pass
    h.append('</td>')
    return ''.join(h)


def row_html(d):
    flags = ''
    if d['state']['mesh'] == 'diff':
        flags += 'm'
    if d['state']['tex_dims'] == 'diff':
        flags += 't'
    if 'mesh_files' in d['diffs']:
        flags += 'f'
    if 'anims' in d['diffs']:
        flags += 'a'
    if any(d['cols'][S].get('present') and (not d['cols'][S].get('images') or d['cols'][S].get('error'))
           for S in d['present']):
        flags += 'x'
    if d['s4']:
        flags += 'n'
    words = [d['obj'], d['hint'], d['oid']]
    for S in d['present']:
        c = d['cols'][S]
        words += [m['file'] for m in c['meshes']] + [t['tex'] for t in c['textures']]
    g = d['groups']
    diffs = ''.join('<span class="chip">%s</span>' % esc(MLABEL.get(k, 'file mesh' if k == 'mesh_files' else k))
                    for k in d['diffs']) or '<span class="muted">(chỉ khác nội dung byte)</span>'
    info = ('<td><div class="nm">%s</div><div class="sub">đợt %s · <code>%s</code></div>'
            '<div class="hint">gợi ý (models_cross): <b>%s</b></div>'
            '<div class="grp">mesh: <b>%s</b> (%s)</div><div class="grp">texture byte: <b>%s</b> (%s)</div>'
            '<div class="grp">texture W×H/định dạng: <b>%s</b> (%s)</div>'
            '<div class="grp">material: <b>%s</b> · obj: <b>%s</b></div>'
            '<div class="dl">khác nhau: %s</div>%s'
            '<div class="pick">đang chọn: <span class="cur">-</span> <span class="chg">(đã đổi so với gợi ý)</span></div></td>'
            % (esc(d['obj']), d['batch'], d['oid'], esc(d['hint']), esc(g['mesh']), esc(d['state']['mesh']),
               esc(g['tex']), esc(d['state']['tex']), esc(g['tex_dims']), esc(d['state']['tex_dims']),
               esc(g['matdef']), esc(g['objdef']), diffs,
               ('<div class="note">%s</div>' % esc(d['s4'])) if d['s4'] else ''))
    return ('<tr class="obj" id="%s" data-obj="%s" data-def="%s" data-b="%s" data-f="%s" data-s="%s">%s%s</tr>'
            % (d['oid'], esc(d['obj']), d['default'], d['batch'], flags, esc(' '.join(words).lower()), info,
               ''.join(cell_html(d, S) for S in SRCS)))


def build_html(data, summ):
    fails = summ['failures']
    head = ('<title>Bảng chọn bản %s</title><meta name="color-scheme" content="light dark"><style>%s</style>'
            % (esc(BATCH_NAME), CSS))
    lead = (
        '<p class="lead">Mỗi hàng là một object của <code>all.obj</code> có ở nhiều nguồn với <b>mesh</b> hoặc '
        '<b>kích thước/định dạng texture</b> khác nhau. Mỗi cột là bản của một nguồn: <b>S1</b> client_GL (bản đang chơi), '
        '<b>S2</b> DataCY 3.71 (nhánh CY; S4 AXP cùng nội dung trừ khi có ghi chú), <b>S3</b> CYHJ (HJ chính thức).</p>'
        '<p class="lead">Ảnh: <code>tlbb2gltf.py</code> → glTF → Blender %s (Eevee) %d×%d, nền xám trung tính, '
        '3 đèn mềm (key/fill/rim) cộng ánh sáng môi trường; tư thế là khung đầu của animation mặc định '
        '(DefaultAnimation, 站立 hoặc 休闲), không có thì bind pose. Camera 3/4 trước và 3/4 sau; <b>mọi bản của một object '
        'dùng chung một khung hình</b> (vừa hộp bao hợp của các bản) nên so được cả kích thước. Mặt nào cũng vẽ hai phía; '
        'texture thu về ≤ %d px khi dựng ảnh, còn số liệu trong bảng là của file gốc. Ô vàng là chỉ số khác nhau giữa các bản '
        '(chữ đậm là giá trị lớn nhất).</p>'
        '<p class="lead">Mặc định chọn theo <b>gợi ý</b> của <code>models_cross.tsv</code>. Lựa chọn được nhớ trong trình duyệt. '
        'Chọn xong bấm <b>Xuất YAML</b> rồi chép vào <code>%s</code> (công cụ không tự ghi file này).</p>'
        '<p class="lead">%d object · %d cột nguồn · %d bản khác nhau đã dựng %d · lỗi %d (xem <code>summary.txt</code>).</p>'
        % (esc(summ['blender']), RENDER_SIZE, RENDER_SIZE, TEX_CAP, esc(SELECTION_YAML), summ['objects'],
           summ['source_columns'], summ['distinct_variants'], summ['distinct_variants_rendered'], len(fails)))
    bar = ('<div class="bar"><input id="q" type="search" placeholder="Lọc theo tên object / file / gợi ý…">'
           '<select id="f">%s</select><select id="sz" title="cỡ ảnh"><option value="s">ảnh nhỏ</option>'
           '<option value="m" selected>ảnh vừa</option><option value="l">ảnh lớn</option></select>'
           '<button class="pri" id="bY">Xuất YAML</button><button id="bC">Chép YAML</button>'
           '<button id="bR">Đặt lại theo gợi ý</button><span class="cnt">hiện <b id="nshow">0</b> / %d · đã đổi '
           '<b id="nchg">0</b></span></div><textarea id="yaml" hidden spellcheck="false"></textarea>'
           % (''.join('<option value="%s">%s</option>' % (k, esc(v)) for k, v in FLAG_OPTS), len(data)))
    body = ''.join(row_html(d) for d in data)
    foot = ['<footer><h3>Lỗi (%d)</h3><ul>' % len(fails)]
    for f in fails[:500]:
        foot.append('<li><b>%s</b> [%s] %s: %s</li>' % (esc(f['obj']), esc(f['sources']), esc(f['stage']),
                                                      esc(f['reason'][:300])))
    foot.append('</ul><p>review.py %s · sinh lúc %s · dữ liệu: <code>data.json</code>, <code>summary.json</code></p>'
                '</footer>' % (esc(TOOL_VERSION), esc(summ['finished'])))
    js = (JS.replace('__BATCH__', BATCH_NAME).replace('__TARGET__', json.dumps(SELECTION_YAML))
          .replace('__VER__', json.dumps('review.py ' + TOOL_VERSION)))
    return ('<!doctype html><html lang="vi"><head><meta charset="utf-8">%s</head><body data-sz="m"><header>'
            '<h1>Bảng chọn bản · model nhiều nguồn · %s</h1>%s</header>%s<div class="wrap"><table class="t"><tbody>%s'
            '</tbody></table></div>%s<script>%s</script></body></html>'
            % (head, esc(BATCH_NAME), lead, bar, body, ''.join(foot), js))


# ------------------------------------------------------------------ main
def main():
    global LOGF
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--batch', default='all', choices=('1', '2', 'all'))
    ap.add_argument('--objs', help='text file, one obj name per line (overrides --batch)')
    ap.add_argument('--limit', type=int, default=0)
    ap.add_argument('--out', default=OUT_DEFAULT)
    ap.add_argument('--jobs', type=int, default=MAX_BLENDER, help='Blender processes (capped at %d)' % MAX_BLENDER)
    ap.add_argument('--convert-jobs', type=int, default=3)
    ap.add_argument('--chunk', type=int, default=12, help='objects per Blender process')
    ap.add_argument('--samples', type=int, default=32)
    ap.add_argument('--force', action='store_true', help='re-render objects that already have images')
    ap.add_argument('--html-only', action='store_true', help='rebuild index.html/data.json from existing images')
    ap.add_argument('--keep-work', action='store_true', help='keep GLB / raw PNG work files')
    ap.add_argument('--blender', default=BLENDER_DEFAULT)
    args = ap.parse_args()
    out = os.path.abspath(args.out)
    if not out.lower().startswith(REVIEW_ROOT.lower() + os.sep):
        sys.exit('refusing to write outside ' + REVIEW_ROOT)
    args.out = out
    os.makedirs(out, exist_ok=True)
    LOGF = open(os.path.join(out, 'review.log'), 'a', encoding='utf-8')
    below_normal_priority()
    t_start = time.time()
    T = {}
    log('=== review.py %s out=%s args=%s' % (TOOL_VERSION, out, vars(args)))
    t = time.time()
    rows = select_objects(load_tsv(os.path.join(IDX_DIR, 'models_cross.tsv')), args.batch, args.objs)
    if args.limit:
        rows = rows[:args.limit]
    log('selected %d objects (batch %s: %d in batch 1, %d in batch 2)' % (
        len(rows), args.batch, sum(r.get('_batch') == 1 for r in rows), sum(r.get('_batch') == 2 for r in rows)))
    srcs = {S: Source(S) for S in SRCS}
    T['load_sources'] = round(time.time() - t, 1)
    t = time.time()
    run = Run(args)
    run.plan_all(rows, srcs)
    T['plan'] = round(time.time() - t, 1)
    if args.html_only:           # keep what the last render run found (no rendering happens now)
        try:
            with open(os.path.join(out, 'summary.json'), encoding='utf-8') as f:
                prev = json.load(f)
        except (OSError, ValueError):
            prev = {}
        for fl in prev.get('failures', []):
            if fl.get('stage') in ('convert', 'render'):
                run.failures.append((fl['obj'], fl['sources'], fl['stage'], fl['reason']))
        if 'convert_render' in prev.get('timings_s', {}):
            T['convert_render_previous_run'] = prev['timings_s']['convert_render']
        run.extra = {'mode': 'html-only rebuild',
                     'render_run': (prev.get('render_run') if prev.get('mode') == 'html-only rebuild' else
                                    {k: prev.get(k) for k in ('started', 'finished', 'elapsed_s', 'command')})}
    log('planned: %d objects, %d source columns, %d distinct variants' % (
        len(run.objs), sum(len(r['plans']) for r in run.objs), sum(len(r['units']) for r in run.objs)))
    bver = blender_version(args.blender)
    t = time.time()
    if not args.html_only:
        run.execute()
    T['convert_render'] = round(time.time() - t, 1)
    t = time.time()
    data = build_data(run, srcs)
    with open(os.path.join(out, 'data.json'), 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=0)
    summ = write_summary(run, data, t_start, T, bver)
    with open(os.path.join(out, 'index.html'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(build_html(data, summ))
    T['page'] = round(time.time() - t, 1)
    if not args.keep_work and not args.html_only:
        log('work cleanup: %d object folders removed' % cleanup_work(run))
    summ = write_summary(run, data, t_start, T, bver)
    log('done: %d objects, %d/%d distinct variants rendered, %d failures, %.0fs -> %s' % (
        summ['objects'], summ['distinct_variants_rendered'], summ['distinct_variants'], len(summ['failures']),
        time.time() - t_start, os.path.join(out, 'index.html')))
    LOGF.close()


if __name__ == '__main__':
    main()
