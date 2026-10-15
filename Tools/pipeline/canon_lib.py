# -*- coding: utf-8 -*-
"""canon_lib.py - planning helpers of build_canonical.py (CY-Source data track D1, Docs/05 muc 5, 6.1-6.4, 9).

Turns the S1 mirror (client_GL\\Data) into the Canonical data root by switching selected objects to their
S2 (DataCY 3.71) or S3 (CYHJ) variant.

closure   for every switched object: the <Object> block of the source's all.obj (first occurrence), its meshes,
          skeletons (+ animation links), .dynbone, the materials the engine uses per submesh (review.plan_variant
          rule: entity material "a;b" -> sub-entity i gets name i, an undefined name keeps the .mesh material),
          <Material>/<Skeleton>/<Effect>/<Slot> references, materials of all.material with every parent defined
          there, textures (set_texture_alias / texture / anim_texture / cubic_texture), effects -> particle systems
          / sub-effects / materials, particle mesh_name meshes. Source files are found with the pipeline rule
          (index_sources.name_index through review.Source.resolve) and copied at their FORMAT length
          (fmt_len / sha256_content of Assets\\Staging\\index; an unknown longer tail is kept and noted).
decisions per name (files: case-insensitive base name, definitions: exact name):
          same     base content identical (files: sha256 of the format-length content; definitions: whitespace-
                   normalised hash)                                  -> nothing written
          new      name absent from the base                         -> file added / block appended
          replace  the base has exactly one copy and it is EXCLUSIVE: every reference to the name in the whole
                   base data (all.obj / all.material / all.effect / all.particle blocks, mesh skeleton links and
                   submesh materials, skeleton links, ConfigFolder tables, scene / interface / other text files)
                   lies inside definitions this batch replaces       -> overwritten in place / block replaced
          rename   otherwise                                         -> <stem>_hj / _cy (+ _<sha8> if taken); every
                   reference inside the closure is rewritten at byte level (obj attributes, material / effect /
                   particle lines, mesh skeleton link, submesh material name)
          Renames only ever add differences, so the loop (render -> classify -> exclusivity fixed point -> rename)
          converges.
scripts   byte-level edits of all.obj / all.material / all.effect / all.particle against the S1 bytes: the first
          occurrence is replaced (WXLogicModelManager keeps the first template of a name), new blocks are appended
          (all.obj: before </AllObjects>); the files are never re-encoded.
"""
import bisect
import collections
import concurrent.futures as cf
import hashlib
import os
import pickle
import re
import struct
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.dirname(os.path.dirname(HERE))
TESTS = os.path.join(CYS, 'Tests')
for _p in (HERE, TESTS):
    if _p not in sys.path:
        sys.path.insert(0, _p)
import tlbbfmt as F  # noqa: E402
import index_sources as IS  # noqa: E402
import review as RV  # noqa: E402
from validators import common as VC  # noqa: E402
from validators import v01_mesh, v02_skeleton, v04_material  # noqa: E402

SRC_TAG = {'S2': b'cy', 'S3': b'hj'}
SRC_RANK = {'S3': 0, 'S2': 1}
FILE_KINDS = ('texture', 'skeleton', 'dynbone', 'mesh')
DEF_KINDS = ('material', 'particle', 'effect')
KIND_RANK = {k: i for i, k in enumerate(('texture', 'skeleton', 'dynbone', 'mesh', 'material', 'particle', 'effect',
                                         'obj'))}
C1_RAW = frozenset((0x81, 0x8D, 0x8F, 0x90, 0x9D))
DELIM = frozenset(b'"\'<>=;,|:(){}[] \t\r\n\x00/\\')
TEXT_EXT = frozenset(('.txt', '.tab', '.lua', '.xml', '.scene', '.enscene', '.skysphere', '.terrain', '.region', '.esd',
                      '.tsd', '.fly', '.movie', '.material', '.program', '.cfg', '.ini', '.imageset', '.layout',
                      '.looknfeel', '.scheme', '.font', '.json', '.model', '.frame', '.dynbone', '.skill', '.obj',
                      '.effect', '.particle'))
SCRIPT_KINDS = ('obj', 'material', 'effect', 'particle')
SCRIPT_REL = {k: VC.SCRIPTS[k] for k in SCRIPT_KINDS}
SCRIPT_RELS_LOWER = {v.lower() for v in SCRIPT_REL.values()}
# Derived indexes: generated from the scripts above, they only drive preloading (Tools/model-convert/check_model.py:
# "chi anh huong preload, khong lam hong") and say nothing about which object uses a resource -> not a "use".
DERIVED_INDEXES = {'modelfolder\\filedep.xml'}


class PlanError(Exception):
    pass


def sha256(b):
    return hashlib.sha256(b).hexdigest()


def disp(b):
    return F.disp(b) if isinstance(b, bytes) else str(b)


def gbk_to_disk(b):
    """GBK bytes -> on-disk name in the client_GL convention: every byte shown as cp1252, the five bytes cp1252 leaves
    undefined kept as U+0081.. (what MultiByteToWideChar(1252) gives). Inverse of tlbbfmt.disk_name_bytes(.., True)."""
    return ''.join(chr(x) if x < 0x80 or x in C1_RAW else bytes([x]).decode('cp1252') for x in b)


def src_name_bytes(name):
    try:
        return name.encode('gbk')
    except UnicodeEncodeError:
        raise PlanError('source file name is not GBK-encodable: %r' % name)


_BAK_TAIL = re.compile(r'-bak\d*(-\w+)?$')


def is_backup(name):
    """Backup / scratch copies left in client_GL by manual edits: *.bak, *.bak-<tag>, *.pre-<tag>[.bak], *-bak,
    *.gfx-bak2-<date>, *.lolbak, *.mapbak-<tag>."""
    for comp in name.lower().split('.')[1:]:
        if comp == 'bak' or comp.startswith(('bak-', 'bak_')) or re.match(r'bak\d', comp):
            return True
        if comp == 'lolbak' or comp.startswith('mapbak') or comp.startswith('pre-'):
            return True
        if comp.endswith('-bak') or _BAK_TAIL.search(comp):
            return True
    return False


def map_top_folder(top):
    """Source top folder (S2/S3 layout) -> client_GL *Folder (only folders client_GL's FairyResources.cfg reads)."""
    m = re.match(r'^(model|material)(\d*)$', top, re.I)
    if m:
        n = int(m.group(2) or 1)
        if m.group(1).lower() == 'model':
            n = min(n, 3)
            return 'ModelFolder' if n == 1 else 'Model%dFolder' % n
        n = min(n, 5)
        return 'MaterialFolder' if n == 1 else 'Material%dFolder' % n
    return {'effect': 'EffectFolder', 'sound': 'SoundFolder', 'interface': 'InterfaceFolder',
            'config': 'ConfigFolder', 'brushes': 'BrushesFolder', 'scene': 'SceneFolder',
            'scene2': 'SceneFolder'}.get(top.lower(), top + 'Folder')


# ------------------------------------------------------------------ sources
class SourceView:
    """One read-only loose source (S2 DataCY / S3 CYHJ) plus its D0 index rows (Assets\\Staging\\index)."""

    def __init__(self, S):
        self.S = S
        self.rs = RV.Source(S)
        self.root = self.rs.root
        self.rows = {}
        for r in RV.load_tsv(os.path.join(RV.IDX_DIR, 'sha256_%s.tsv' % S)):
            size = RV.ival(r['size'], -1)
            fl = RV.ival(r['fmt_len'], size) if r['fmt_len'] else size
            self.rows[r['relpath']] = (size, r['sha256'], fl, r['tail'], r['sha256_content'])
        self.obj_data = IS.read_src(S, 'obj')
        self.obj_first = {}
        for nm, s, e in VC.obj_spans(self.obj_data):
            self.obj_first.setdefault(nm, (s, e))
        self.obj_lower = {}
        for nm in self.obj_first:
            self.obj_lower.setdefault(nm.lower(), nm)
        self.defs = {}
        for kind in DEF_KINDS:
            data = IS.read_src(S, kind)
            blocks, _stray = VC.script_spans(data)
            first, parents = {}, {}
            for hdr, s, e in blocks:
                nm, parent = VC.def_name(kind, hdr)
                if nm and nm not in first:
                    first[nm] = (s, e)
                    parents[nm] = parent or b''
            self.defs[kind] = (data, first, parents)

    def resolve(self, name):
        rel, _path = self.rs.resolve(name)
        return rel

    def file_bytes(self, rel):
        """-> (content, trimmed byte count, note)."""
        size, sha, fl, tail, sha_c = self.rows[rel]
        with open(os.path.join(self.root, rel), 'rb') as f:
            data = f.read()
        if len(data) != size or sha256(data) != sha:
            raise PlanError('%s: %s changed since the D0 index (re-run index_sources.py)' % (self.S, rel))
        if tail in ('zero', 'nonzero') and 0 < fl < size:
            cut = data[:fl]
            if sha_c and sha256(cut) != sha_c:
                raise PlanError('%s: %s format-length hash differs from the index' % (self.S, rel))
            return cut, size - fl, ''
        if tail == 'extra':
            return data, 0, 'unknown tail of %d bytes after the format end kept' % (size - fl)
        if tail.startswith('ERR'):
            raise PlanError('%s: %s unreadable in the index (%s)' % (self.S, rel, tail))
        return data, 0, ''

    def obj_block(self, name):
        nm = name if name in self.obj_first else self.obj_lower.get(name.lower())
        if nm is None:
            return None, None
        s, e = self.obj_first[nm]
        return nm, self.obj_data[s:e]

    def def_block(self, kind, name):
        data, first, _parents = self.defs[kind]
        se = first.get(name)
        return data[se[0]:se[1]] if se else None

    def has_def(self, kind, name):
        return name in self.defs[kind][1]


# ------------------------------------------------------------------ base binary references (S1 meshes / skeletons)
_LINK_RE = re.compile(rb'\x00\x50[\x00-\xff]{4}([^\n\x00]{1,255}?\.skeleton)\n', re.I)


def _binref_batch(items):
    out = []
    for rel, path in items:
        try:
            with open(path, 'rb') as f:
                data = f.read()
        except OSError:
            out.append((rel, b'', (), ()))
            continue
        if rel.lower().endswith('.mesh'):
            mi = F.mesh_info(data)
            out.append((rel, mi.get('skel') or b'', tuple(mi.get('mats') or ()), ()))
        else:
            out.append((rel, b'', (), tuple(m.group(1) for m in _LINK_RE.finditer(data))))
    return out


def scan_binrefs(root, files, cache_path, jobs=6, log=print):
    """Skeleton link + submesh material names of every .mesh, skeleton links of every .skeleton of the base.
    files = [(rel, size, mtime_ns)]; results cached by (size, mtime) in cache_path."""
    try:
        with open(cache_path, 'rb') as f:
            cache = pickle.load(f)
        if not isinstance(cache, dict):
            cache = {}
    except (OSError, pickle.PickleError, EOFError, ValueError, AttributeError):
        cache = {}
    res, todo = {}, []
    for rel, size, mt in files:
        low = rel.lower()
        if not (low.endswith('.mesh') or low.endswith('.skeleton')):
            continue
        c = cache.get(rel)
        if c and c[0] == size and c[1] == mt:
            res[rel] = c[2]
        else:
            todo.append((rel, size, mt))
    t0 = time.time()
    if todo:
        meta = {rel: (size, mt) for rel, size, mt in todo}
        batches = [todo[i:i + 300] for i in range(0, len(todo), 300)]
        with cf.ProcessPoolExecutor(max_workers=max(1, jobs)) as ex:
            futs = [ex.submit(_binref_batch, [(rel, os.path.join(root, rel)) for rel, _s, _m in b]) for b in batches]
            for fu in cf.as_completed(futs):
                for rel, skel, mats, links in fu.result():
                    res[rel] = (skel, mats, links)
                    cache[rel] = (meta[rel][0], meta[rel][1], res[rel])
        cache = {k: v for k, v in cache.items() if k in res}
        os.makedirs(os.path.dirname(cache_path), exist_ok=True)
        with open(cache_path + '.tmp', 'wb') as f:
            pickle.dump(cache, f, protocol=pickle.HIGHEST_PROTOCOL)
        os.replace(cache_path + '.tmp', cache_path)
    log('binrefs: %d mesh/skeleton files, %d parsed now (%.1fs)' % (len(res), len(todo), time.time() - t0))
    return res


class RefDB:
    """Who references a name in the base data: text corpus (all.* with block offsets, tables, scene / interface
    / other text files) and binary links (mesh skeleton link, submesh materials, skeleton animation links)."""

    def __init__(self, base, files, binrefs, log=print):
        t0 = time.time()
        self.base = base
        self.docs = []
        spans, _first = base.objects()
        self._struct('obj', base.script('obj'), [(s, e) for _n, s, e in spans])
        for kind in DEF_KINDS:
            d = base.defs(kind)
            self._struct(kind, base.script(kind), [(s, e) for _n, s, e in d['spans']])
        nbytes = 0
        for rel, _size, _mt in files:
            low = rel.lower()
            if low in SCRIPT_RELS_LOWER or low in DERIVED_INDEXES:
                continue
            ext = os.path.splitext(low)[1]
            if not (low.startswith('configfolder\\') or ext in TEXT_EXT):
                continue
            try:
                with open(os.path.join(base.root, rel), 'rb') as f:
                    data = f.read()
            except OSError:
                continue
            self.docs.append(('ext', rel, data.lower(), None, None))
            nbytes += len(data)
        self.skel_users = collections.defaultdict(set)
        self.link_users = collections.defaultdict(set)
        self.mat_users = collections.defaultdict(set)
        for rel, (skel, mats, links) in binrefs.items():
            if skel:
                self.skel_users[F.key_of(F.base_of(skel))].add(rel)
            for m in mats:
                self.mat_users[m].add(rel)
            for ln in links:
                self.link_users[F.key_of(F.base_of(ln))].add(rel)
        self._cache = {}
        self.text_docs = len(self.docs)
        self.text_bytes = nbytes
        log('refdb: %d text documents (%.0f MB besides all.*), %d binary files, %.1fs' % (
            len(self.docs), nbytes / 1e6, len(binrefs), time.time() - t0))

    def _struct(self, label, data, spans):
        self.docs.append((label, SCRIPT_REL[label], data.lower(), [s for s, e in spans], [e for s, e in spans]))

    def refs(self, kind, name):
        k = (kind, name)
        if k in self._cache:
            return self._cache[k]
        pat = name.lower()
        n = len(pat)
        locs = set()
        if n:
            for label, rel, doc, starts, ends in self.docs:
                i = doc.find(pat)
                while i >= 0:
                    j = i + n
                    if (i == 0 or doc[i - 1] in DELIM) and (j == len(doc) or doc[j] in DELIM):
                        if starts is None:
                            locs.add(('ext', rel))
                            break
                        b = bisect.bisect_right(starts, i) - 1
                        if b >= 0 and i < ends[b]:
                            locs.add((label, b))
                        else:
                            locs.add(('ext', '%s@%d' % (rel, i)))
                    i = doc.find(pat, i + 1)
        if kind == 'skeleton':
            kk = F.key_of(F.base_of(name))
            locs |= {('file', r) for r in self.skel_users.get(kk, ())}
            locs |= {('file', r) for r in self.link_users.get(kk, ())}
        elif kind == 'material':
            locs |= {('file', r) for r in self.mat_users.get(name, ())}
        self._cache[k] = locs
        return locs


# ------------------------------------------------------------------ byte-level rewriting
def _replace_chunk_string(data, p, q, k, new):
    """Replace the '\\n'-terminated string data[q:k] of the chunk starting at p; keep the chunk size field consistent
    (old size + delta, whatever convention the file used)."""
    out = bytearray(data[:q]) + new + data[k:]
    size = struct.unpack_from('<I', data, p + 2)[0]
    struct.pack_into('<I', out, p + 2, max(6, size + len(new) - (k - q)))
    return bytes(out)


def mesh_set_skeleton(data, new_link):
    mw = v01_mesh.walk_mesh(data)
    if not mw['skel_span']:
        raise PlanError('mesh has no skeleton link to rewrite')
    p, q, k = mw['skel_span']
    return _replace_chunk_string(data, p, q, k, new_link)


def mesh_set_submat(data, old, new):
    mw = v01_mesh.walk_mesh(data)
    for s in reversed(mw['subs']):
        if s['mat'] == old:
            _after_indices, q, k = s['span']
            # walk_mesh records its advanced cursor after the index buffer in
            # span[0]. The material starts immediately after the 6-byte SUBMESH
            # header; using the advanced cursor overwrites the geometry chunk.
            p = q - 6
            data = _replace_chunk_string(data, p, q, k, new)
    return data


def skel_set_link(data, old, new):
    sw = v02_skeleton.walk_skeleton(data)
    ok = F.key_of(F.base_of(old))
    for name, (q, k) in reversed(sw['links']):
        if F.key_of(F.base_of(name)) == ok:
            data = _replace_chunk_string(data, q - 6, q, k, new)
    return data


def _fm(fmap, name):
    return fmap.get(F.key_of(F.base_of(name)), name) if name else name


def _map_lines(block, header_fn, line_fn):
    out = []
    done = False
    for ln in block.split(b'\n'):
        cr = ln.endswith(b'\r')
        body = ln[:-1] if cr else ln
        if not done and body.strip():
            body = header_fn(body)
            done = True
        else:
            body = line_fn(body)
        out.append(body + (b'\r' if cr else b''))
    return b'\n'.join(out)


_HDR_MAT = re.compile(rb'^(\s*material\s+)([^\s:]+)(.*)$', re.S)
_PARENT = re.compile(rb'(:\s*)(\S+)')
_HDR_EFF = re.compile(rb'^(\s*effect\s+)(\S+)(.*)$', re.S)
_HDR_PAR = re.compile(rb'^(\s*(?:particle_system\s+)?)(\S+)(.*)$', re.S)
_KV = re.compile(rb'^(\s*)(\S+)(\s+)(\S+)(.*)$', re.S)
_ALIAS = re.compile(rb'^(\s*set_texture_alias\s+\S+\s+)(\S+)(.*)$', re.S)


def rewrite_material(block, self_name, mmap, fmap):
    def hdr(b):
        m = _HDR_MAT.match(b)
        if not m:
            return b
        rest = m.group(3)
        if mmap:
            rest = _PARENT.sub(lambda p: p.group(1) + mmap.get(p.group(2), p.group(2)), rest, count=1)
        return m.group(1) + (self_name or m.group(2)) + rest

    def line(b):
        if not fmap:
            return b
        m = _ALIAS.match(b)
        if m:
            return m.group(1) + _fm(fmap, m.group(2)) + m.group(3)
        m = _KV.match(b)
        if not m:
            return b
        key = m.group(2)
        if key in (b'texture', b'cubic_texture'):
            toks = b.split()
            if key == b'cubic_texture' and len(toks) >= 8:
                return m.group(1) + b' '.join([toks[0]] + [_fm(fmap, t) for t in toks[1:7]] + toks[7:])
            return m.group(1) + key + m.group(3) + _fm(fmap, m.group(4)) + m.group(5)
        if key == b'anim_texture':
            toks = b.split()
            if len(toks) == 4 and toks[2].isdigit():
                stem, ext = os.path.splitext(toks[1])
                frames = [stem + b'_%d' % i + ext for i in range(int(toks[2]))]
                if any(_fm(fmap, f) != f for f in frames):
                    raise PlanError('anim_texture short form with renamed frames: ' + disp(toks[1]))
                return b
            return m.group(1) + b' '.join([toks[0]] + [_fm(fmap, t) for t in toks[1:-1]] + [toks[-1]])
        return b
    return _map_lines(block, hdr, line)


def rewrite_effect(block, self_name, pmap, emap, mmap):
    def hdr(b):
        m = _HDR_EFF.match(b)
        return (m.group(1) + (self_name or m.group(2)) + m.group(3)) if m else b

    def line(b):
        m = _KV.match(b)
        if not m:
            return b
        k, v = m.group(2), m.group(4)
        mp = (pmap if k == b'ParticleSystem' else emap if k in (b'ParEffectName', b'ColEffectName')
              else mmap if k == b'Material' else None)
        if mp and v in mp:
            return m.group(1) + k + m.group(3) + mp[v] + m.group(5)
        return b
    return _map_lines(block, hdr, line)


def rewrite_particle(block, self_name, mmap, fmap):
    def hdr(b):
        m = _HDR_PAR.match(b)
        return (m.group(1) + (self_name or m.group(2)) + m.group(3)) if m else b

    def line(b):
        m = _KV.match(b)
        if not m:
            return b
        k, v = m.group(2), m.group(4)
        if k == b'material' and v in mmap:
            return m.group(1) + k + m.group(3) + mmap[v] + m.group(5)
        if k == b'mesh_name' and fmap:
            return m.group(1) + k + m.group(3) + _fm(fmap, v) + m.group(5)
        return b
    return _map_lines(block, hdr, line)


_TAG_RE = re.compile(rb'<(Object|Entity|Material|Skeleton|Effect|Slot|Mesh)\b([^>]*?)(/?>)', re.S)
_XML_COMMENT = re.compile(rb'<!--.*?-->', re.S)


def _set_attr(attrs, name, fn):
    rx = re.compile(rb'(\b' + name + rb'\s*=\s*")([^"]*)(")')
    return rx.sub(lambda a: a.group(1) + fn(a.group(2)) + a.group(3), attrs, count=1)


def rewrite_obj(it, fmap, mmap, emap, omap):
    block = it.data0
    comments = [(m.start(), m.end()) for m in _XML_COMMENT.finditer(block)]
    counter = [0]

    def repl(m):
        if any(a <= m.start() < b for a, b in comments):
            return m.group(0)
        tag, attrs, close = m.group(1), m.group(2), m.group(3)
        if tag == b'Object':
            if it.final_name != it.name:
                attrs = _set_attr(attrs, b'name', lambda v: it.final_name)
        elif tag == b'Entity':
            i = counter[0]
            counter[0] += 1
            ent = it.entities[i] if i < len(it.entities) else None
            if fmap:
                attrs = _set_attr(attrs, b'file', lambda v: _fm(fmap, v))
            if ent and any(mi is not None and mi.final_name != mi.name for _u, mi in ent['subs']):
                new = b';'.join((mi.final_name if mi is not None else used) for used, mi in ent['subs'])
                if re.search(rb'\bmaterial\s*=\s*"', attrs):
                    attrs = _set_attr(attrs, b'material', lambda v: new)
                else:
                    attrs = attrs.rstrip() + b' material="' + new + b'" '
        elif tag == b'Material':
            if mmap:
                attrs = _set_attr(attrs, b'material', lambda v: mmap.get(v.strip(), v))
        elif tag == b'Skeleton':
            if fmap:
                attrs = _set_attr(attrs, b'skeleton', lambda v: _fm(fmap, v))
        elif tag == b'Effect':
            if emap:
                attrs = _set_attr(attrs, b'effect', lambda v: emap.get(v.strip(), v))
        elif tag == b'Slot':
            if omap:
                attrs = _set_attr(attrs, b'object', lambda v: omap.get(v.strip().lower(), v))
        elif tag == b'Mesh':
            if fmap:
                attrs = _set_attr(attrs, b'meshname', lambda v: _fm(fmap, v))
        return b'<' + tag + attrs + close
    return _TAG_RE.sub(repl, block)


# ------------------------------------------------------------------ plan items
class Item(object):
    def __init__(self, kind, src, name, src_rel=None, data0=b''):
        self.kind = kind
        self.src = src
        self.name = name              # GBK bytes: file base name (as in the source) / definition / object name
        self.src_rel = src_rel
        self.data0 = data0            # source content (files trimmed to the format length; blocks as in the source)
        self.data = data0             # content after reference rewrites
        self.deps = []                # [(role, reference name, Item)]
        self.notes = []
        self.trimmed = 0
        self.final_name = name
        self.status = ''              # same | new | replace | rename | twin  (switched objects: same | new | replace)
        self.twin = None
        self.target_rel = None
        self.entities = []            # obj: [{'file', 'mesh', 'attr', 'subs': [(material name used, Item|None)]}]
        self.walk = None
        self.follows = None           # dynbone -> its mesh item
        self.switched = False
        self.reason = ''
        self.rename_reason = ''
        self.layer = ''               # roots only: 'variants' (selection switch) | 'fixes' (fill / patch)
        self.fill = ''                # fill root: why the file is added

    @property
    def gkey(self):
        if self.kind in FILE_KINDS:
            return (self.kind, F.key_of(self.name))
        if self.kind == 'obj':
            return ('obj', self.name.lower())
        return (self.kind, self.name)

    def content_key(self):
        if self.kind in FILE_KINDS:
            return sha256(self.data)
        return F.norm_hash(self.data)

    def label(self):
        return '%s %s (%s)' % (self.kind, disp(self.name), self.src)


class Planner:
    def __init__(self, base, refdb, sources, log=print):
        self.base = base              # validators.common.DataRoot of S1
        self.refdb = refdb
        self.src = sources            # {'S2': SourceView, 'S3': SourceView}
        self.log = log
        self.items = {}               # (kind, S, key) -> Item | None
        self.switched = []            # [Item]
        self.fills = []               # [Item] fill roots (layer 'fixes')
        self.problems = []            # [(object, message)]
        self.claims = {}              # (kind, name key) -> Item
        self._bi = {}
        self._ctx = b''
        self._def_idx = {}
        self.base_obj_lower = {}
        for nm in base.objects()[1]:
            self.base_obj_lower.setdefault(nm.lower(), nm)
        self.rounds = 0

    # -------------------------------------------------------------- closure
    def problem(self, msg):
        self.problems.append((disp(self._ctx), msg))

    def item_file(self, kind, S, name):
        k = (kind, S, F.key_of(F.base_of(name)))
        if k in self.items:
            return self.items[k]
        src = self.src[S]
        rel = src.resolve(name)
        if not rel:
            self.items[k] = None
            self.problem('%s missing in %s: %s' % (kind, S, disp(name)))
            return None
        data, trimmed, note = src.file_bytes(rel)
        it = Item(kind, S, src_name_bytes(rel.split('\\')[-1]), rel, data)
        it.trimmed = trimmed
        if note:
            it.notes.append(note)
        self.items[k] = it
        if kind == 'mesh':
            it.walk = v01_mesh.walk_mesh(data)
            if it.walk['err']:
                self.problem('mesh %s does not walk: %s' % (rel, it.walk['err']))
            if it.walk['skel']:
                sk = self.item_file('skeleton', S, it.walk['skel'])
                if sk:
                    it.deps.append(('skeleton', it.walk['skel'], sk))
            dyn_name = os.path.splitext(it.name)[0] + b'.dynbone'
            if src.resolve(dyn_name):
                di = self.item_file('dynbone', S, dyn_name)
                if di:
                    di.follows = it
                    it.deps.append(('dynbone', dyn_name, di))
        elif kind == 'skeleton':
            sw = v02_skeleton.walk_skeleton(data)
            if sw['err']:
                self.problem('skeleton %s does not walk: %s' % (rel, sw['err']))
            for ln, _span in sw['links']:
                li = self.item_file('skeleton', S, ln)
                if li:
                    it.deps.append(('link', ln, li))
        return it

    def _base_has_material(self, name):
        return name in self.base.defs('material')['first'] or name in VC.BUILTIN_MATS

    def item_def(self, kind, S, name):
        if kind == 'material' and name in VC.BUILTIN_MATS:
            return None
        k = (kind, S, name)
        if k in self.items:
            return self.items[k]
        src = self.src[S]
        block = src.def_block(kind, name)
        if block is None:
            self.items[k] = None
            if kind == 'material' and name in self.base.templates():
                return None
            if kind == 'material' and self._base_has_material(name):
                self.problem('material "%s" not in %s all.material; the base definition is used' % (disp(name), S))
            else:
                self.problem('%s "%s" not defined in %s nor in the base' % (kind, disp(name), S))
            return None
        it = Item(kind, S, name, None, block)
        self.items[k] = it
        if kind == 'material':
            parent = src.defs['material'][2].get(name, b'')
            if parent and src.has_def('material', parent):
                pi = self.item_def('material', S, parent)
                if pi:
                    it.deps.append(('parent', parent, pi))
            for t in v04_material.texture_refs(block):
                ti = self.item_file('texture', S, t)
                if ti:
                    it.deps.append(('texture', t, ti))
        elif kind == 'particle':
            for kk, v in VC.kv_lines(block):
                if kk == b'material' and v:
                    mi = self.item_def('material', S, v)
                    if mi:
                        it.deps.append(('material', v, mi))
                elif kk == b'mesh_name' and v:
                    me = self.item_file('mesh', S, v)
                    if me:
                        it.deps.append(('mesh', v, me))
                        for s in (me.walk or {}).get('subs', []):
                            if s['mat'] and not any(r == 'submat' and x == s['mat'] for r, x, _d in me.deps):
                                sm = self.item_def('material', S, s['mat'])
                                if sm:
                                    me.deps.append(('submat', s['mat'], sm))
        elif kind == 'effect':
            for kk, v in VC.kv_lines(block):
                if kk == b'ParticleSystem' and v:
                    pi = self.item_def('particle', S, v)
                    if pi:
                        it.deps.append(('particle', v, pi))
                elif kk in (b'ParEffectName', b'ColEffectName') and v not in VC.NULL_NAMES:
                    ei = self.item_def('effect', S, v)
                    if ei:
                        it.deps.append(('effect', v, ei))
                elif kk == b'Material' and v not in VC.NULL_NAMES:
                    mi = self.item_def('material', S, v)
                    if mi:
                        it.deps.append(('material', v, mi))
        return it

    def item_obj(self, S, name, switched=False, reason=''):
        k = ('obj', S, name.lower())
        if k in self.items and not switched:
            return self.items[k]
        src = self.src[S]
        nm, block = src.obj_block(name)
        if block is None:
            self.problem('object %s not in %s all.obj' % (disp(name), S))
            self.items[k] = None
            return None
        it = Item('obj', S, nm, None, block)
        it.switched = switched
        it.reason = reason
        self.items[k] = it
        mats_src = src.defs['material'][1]
        for e in VC.tags(block, b'Entity'):
            f = e.get(b'file', b'').strip()
            attr = e.get(b'material', b'').strip()
            ent = {'file': f, 'mesh': None, 'attr': attr, 'subs': []}
            it.entities.append(ent)
            if not f:
                continue
            mi = self.item_file('mesh', S, f)
            ent['mesh'] = mi
            if mi is None:
                continue
            it.deps.append(('entity', f, mi))
            names = [x.strip() for x in attr.split(b';')] if attr else []
            for si, s in enumerate(mi.walk['subs']):
                if len(names) > 1:
                    cand = names[si] if si < len(names) else names[0]
                else:
                    cand = names[0] if names else b''
                used = s['mat']
                if cand:
                    if cand in VC.BUILTIN_MATS or cand in mats_src:
                        used = cand
                    elif self._base_has_material(cand):
                        used = cand
                        self.problem('entity material "%s" only defined in the base' % disp(cand))
                mat_it = self.item_def('material', S, used)
                ent['subs'].append((used, mat_it))
                if mat_it is not None:
                    it.deps.append(('entity_mat', used, mat_it))
        for m in VC.tags(block, b'Material'):
            mn = m.get(b'material', b'').strip()
            if mn:
                mi = self.item_def('material', S, mn)
                if mi:
                    it.deps.append(('mat_tag', mn, mi))
        for sk in VC.tags(block, b'Skeleton'):
            sn = sk.get(b'skeleton', b'').strip()
            if sn:
                si = self.item_file('skeleton', S, sn)
                if si:
                    it.deps.append(('skeleton_tag', sn, si))
        for ef in VC.tags(block, b'Effect'):
            en = ef.get(b'effect', b'').strip()
            if en:
                ei = self.item_def('effect', S, en)
                if ei:
                    it.deps.append(('effect', en, ei))
        for sl in VC.tags(block, b'Slot'):
            on = sl.get(b'object', b'').strip()
            if on and on.lower() not in self.base_obj_lower:
                oi = self.item_obj(S, on)
                if oi:
                    it.deps.append(('slot', on, oi))
        return it

    def add_switched(self, name, S, reason, layer='variants'):
        self._ctx = name
        it = self.item_obj(S, name, switched=True, reason=reason)
        if it is not None:
            it.layer = layer
            self.switched.append(it)
        self._ctx = b''
        return it

    def add_fill_file(self, kind, S, name, reason, layer='fixes'):
        """A file the base references but does not have, taken from source S (and its own closure)."""
        self._ctx = name
        it = self.item_file(kind, S, name)
        if it is not None:
            it.fill = reason
            it.layer = layer
            self.fills.append(it)
        self._ctx = b''
        return it

    def add_block_patch(self, name, new_block, reason, layer='fixes'):
        """An S1 object block replaced by a byte-patched copy of itself (no closure: it references only base
        names). Decided and emitted like a switched object."""
        it = Item('obj', 'S1', name, None, new_block)
        it.switched = True
        it.reason = reason
        it.layer = layer
        self.items[('obj', 'S1', name.lower())] = it
        self.switched.append(it)
        return it

    # -------------------------------------------------------------- order / rendering
    def all_items(self):
        seen, out = set(), []

        def visit(it):
            if it is None or id(it) in seen:
                return
            seen.add(id(it))
            for _r, _x, d in it.deps:
                visit(d)
            out.append(it)
        for it in sorted((i for i in self.items.values() if i is not None),
                         key=lambda i: (KIND_RANK[i.kind], i.src, i.name)):
            visit(it)
        return out

    def render(self, it):
        fmap, mmap, emap, pmap, omap = {}, {}, {}, {}, {}
        changed = it.final_name != it.name
        for _role, _ref, d in it.deps:
            if d is None or d.final_name == d.name:
                continue
            changed = True
            if d.kind in FILE_KINDS:
                fmap[F.key_of(d.name)] = d.final_name
            elif d.kind == 'material':
                mmap[d.name] = d.final_name
            elif d.kind == 'effect':
                emap[d.name] = d.final_name
            elif d.kind == 'particle':
                pmap[d.name] = d.final_name
            elif d.kind == 'obj':
                omap[d.name.lower()] = d.final_name
        if not changed:
            it.data = it.data0
            return
        selfname = it.final_name if it.final_name != it.name else None
        if it.kind == 'mesh':
            data = it.data0
            for role, ref, d in it.deps:
                if d is None or d.final_name == d.name:
                    continue
                if role == 'skeleton':
                    data = mesh_set_skeleton(data, d.final_name)
                elif role == 'submat':
                    data = mesh_set_submat(data, ref, d.final_name)
            it.data = data
        elif it.kind == 'skeleton':
            data = it.data0
            for role, ref, d in it.deps:
                if role == 'link' and d is not None and d.final_name != d.name:
                    data = skel_set_link(data, ref, d.final_name)
            it.data = data
        elif it.kind == 'material':
            it.data = rewrite_material(it.data0, selfname, mmap, fmap)
        elif it.kind == 'particle':
            it.data = rewrite_particle(it.data0, selfname, mmap, fmap)
        elif it.kind == 'effect':
            it.data = rewrite_effect(it.data0, selfname, pmap, emap, mmap)
        elif it.kind == 'obj':
            it.data = rewrite_obj(it, fmap, mmap, emap, omap)
        else:
            it.data = it.data0

    # -------------------------------------------------------------- base facts
    def _def_indices(self, kind, name):
        if kind not in self._def_idx:
            m = collections.defaultdict(list)
            for i, (nm, _s, _e) in enumerate(self.base.defs(kind)['spans']):
                if nm is not None:
                    m[nm].append(i)
            self._def_idx[kind] = m
        return self._def_idx[kind].get(name, [])

    def base_info(self, it):
        g = it.gkey
        if g in self._bi:
            return self._bi[g]
        b = self.base
        info = {'exists': False, 'unique': False, 'contents': set(), 'rels': [], 'locs': set(), 'idx': None,
                'count': 0}
        if it.kind in FILE_KINDS:
            rels = b.copies(it.name)
            info.update(exists=bool(rels), unique=len(rels) == 1, rels=rels, count=len(rels),
                        contents={b.content_sha(r) for r in rels}, locs={('file', r) for r in rels})
        elif it.kind in DEF_KINDS:
            idxs = self._def_indices(it.kind, it.name)
            if idxs:
                nm, s, e = b.defs(it.kind)['spans'][idxs[0]]
                info.update(exists=True, unique=len(idxs) == 1, idx=idxs[0], count=len(idxs),
                            contents={F.norm_hash(b.script(it.kind)[s:e])},
                            locs={(it.kind, i) for i in idxs})
        elif it.kind == 'obj':
            spans, _first = b.objects()
            low = it.name.lower()
            idxs = [i for i, (nm, _s, _e) in enumerate(spans) if nm.lower() == low]
            if idxs:
                nm, s, e = spans[idxs[0]]
                info.update(exists=True, unique=len(idxs) == 1, idx=idxs[0], count=len(idxs),
                            contents={F.norm_hash(b.script('obj')[s:e])}, locs={('obj', i) for i in idxs})
        self._bi[g] = info
        return info

    def referrers(self, it):
        info = self.base_info(it)
        locs = set(self.refdb.refs(it.kind, it.name))
        if it.kind in DEF_KINDS or it.kind == 'obj':
            locs -= info['locs']
        return locs

    def inside(self, loc, R, depth=0):
        """A base referrer is harmless when it is replaced by the batch (in R) or when it is a mesh / skeleton file
        that nothing outside R uses any more (orphaned by the batch or already unused): its binary links then
        point at nothing that renders."""
        if loc in R:
            return True
        if loc[0] != 'file' or depth > 2:
            return False
        rel = loc[1]
        low = rel.lower()
        kind = 'mesh' if low.endswith('.mesh') else 'skeleton' if low.endswith('.skeleton') else None
        if kind is None:
            return False
        refs = self.refdb.refs(kind, VC.gbk_name(rel.split('\\')[-1]))
        return all(self.inside(x, R, depth + 1) for x in refs if x != loc)

    def outside(self, it, R):
        return sorted(x for x in self.referrers(it) if not self.inside(x, R))

    def _base_has_name(self, kind, name):
        if kind in FILE_KINDS:
            return bool(self.base.copies(name))
        if kind == 'obj':
            return name.lower() in self.base_obj_lower
        return bool(self._def_indices(kind, name))

    def _ck(self, kind, name):
        if kind in FILE_KINDS:
            return (kind, F.key_of(name))
        return (kind, name.lower() if kind == 'obj' else name)

    def new_name(self, it):
        tag = SRC_TAG[it.src]
        h = sha256(it.data0)[:8].encode('ascii')
        if it.kind == 'dynbone' and it.follows is not None and it.follows.final_name != it.follows.name:
            cands = [os.path.splitext(it.follows.final_name)[0] + b'.dynbone']
        elif it.kind in FILE_KINDS:
            stem, ext = os.path.splitext(it.name)
            cands = [stem + b'_' + tag + ext, stem + b'_' + tag + b'_' + h + ext]
        elif it.kind == 'obj':
            stem, ext = os.path.splitext(it.name)
            cands = [stem + b'_' + tag + ext, stem + b'_' + tag + b'_' + h + ext]
        else:
            cands = [it.name + b'_' + tag, it.name + b'_' + tag + b'_' + h]
        for c in cands:
            ck = self._ck(it.kind, c)
            if self._base_has_name(it.kind, c) or self.claims.get(ck, it) is not it:
                continue
            self.claims[ck] = it
            return c
        raise PlanError('no free name for %s' % it.label())

    # -------------------------------------------------------------- decisions
    def decide(self):
        self.order = self.all_items()
        sw_ids = {id(it) for it in self.switched}
        self.switched_locs = set()
        for it in self.switched:
            self.switched_locs |= self.base_info(it)['locs']
        members = collections.defaultdict(list)
        for it in self.order:
            if id(it) not in sw_ids:
                members[it.gkey].append(it)
        for g in members:
            members[g].sort(key=lambda i: (SRC_RANK[i.src], i.src_rel or '', i.name))
        forced = set()
        O, cand = set(), {}
        for rnd in range(1, 201):
            self.rounds = rnd
            for it in self.order:
                if id(it) in forced and it.final_name == it.name:
                    it.final_name = self.new_name(it)
            for it in self.order:
                self.render(it)
            newly = []
            cand = {}
            for g, its in members.items():
                info = self.base_info(its[0])
                prims = collections.OrderedDict()
                for it in its:
                    it.twin = None
                    if id(it) in forced:
                        it.status = 'rename'
                        continue
                    ck = it.content_key()
                    if ck in prims:
                        it.twin = prims[ck]
                        it.status = 'twin'
                        continue
                    prims[ck] = it
                plist = list(prims.values())
                if not info['exists']:
                    for i, it in enumerate(plist):
                        ck = self._ck(it.kind, it.name)
                        if i == 0 and self.claims.get(ck, it) is it:
                            self.claims[ck] = it
                            it.status = 'new'
                        else:
                            it.rename_reason = 'another source needs different content under the same new name'
                            newly.append(it)
                    continue
                base_same = len(info['contents']) == 1
                if info['unique'] and len(plist) == 1:
                    cand[g] = plist[0]
                    continue
                for it in plist:
                    if base_same and it.content_key() in info['contents']:
                        it.status = 'same'
                    else:
                        it.rename_reason = ('base has %d copies/definitions of the name' % info['count']
                                            if not info['unique'] else 'several variants of the name are needed')
                        newly.append(it)
            O = set(cand)
            while True:
                R = set(self.switched_locs)
                for g in O:
                    R |= self.base_info(cand[g])['locs']
                O2 = {g for g in O if not self.outside(cand[g], R)}
                if O2 == O:
                    break
                O = O2
            self.R = R
            for g, it in cand.items():
                info = self.base_info(it)
                if it.content_key() in info['contents']:
                    it.status = 'same'
                elif g in O:
                    it.status = 'replace'
                else:
                    outside = self.outside(it, R)
                    it.rename_reason = 'base copy shared: %d reference(s) outside this batch, e.g. %s' % (
                        len(outside), '; '.join(self.loc_text(x) for x in outside[:3]))
                    newly.append(it)
            if not newly:
                break
            for it in newly:
                forced.add(id(it))
        else:
            raise PlanError('decisions did not converge in 200 rounds')
        for it in self.order:
            if it.twin is not None:
                it.final_name = it.twin.final_name
        for it in self.switched:
            info = self.base_info(it)
            if not info['exists']:
                it.status = 'new'
            elif it.content_key() in info['contents']:
                it.status = 'same'
            else:
                it.status = 'replace'
        self.exclusive = {g for g in O if cand[g].status in ('replace', 'same')}

    def loc_text(self, loc):
        kind, x = loc
        if kind == 'obj':
            return 'all.obj <Object %s>' % disp(self.base.objects()[0][x][0])
        if kind in DEF_KINDS:
            return 'all.%s %s' % (kind, disp(self.base.defs(kind)['spans'][x][0] or b'?'))
        if kind == 'file':
            return 'binary link in ' + disp(VC.gbk_name(x)) if isinstance(x, str) else str(x)
        return '%s %s' % (kind, disp(VC.gbk_name(x)) if isinstance(x, str) else x)

    # -------------------------------------------------------------- outputs
    def target_rel(self, it):
        parts = it.src_rel.split('\\')
        folder = map_top_folder(parts[0])
        mids = [gbk_to_disk(src_name_bytes(p)) for p in parts[1:-1]]
        return '\\'.join([folder] + mids + [gbk_to_disk(it.final_name)])

    def emit(self, s1_scripts):
        """-> dict(files=[...], edits={kind: [...]}, objects=[...]) ; edits carry 'bytes' (not serialised)."""
        writes = []
        for it in self.order:
            if it.kind not in FILE_KINDS or it.status not in ('new', 'rename', 'replace'):
                continue
            if it.status == 'replace':
                rel = self.base_info(it)['rels'][0]
            else:
                rel = self.target_rel(it)
                if os.path.exists(os.path.join(self.base.root, rel)):
                    raise PlanError('target path already exists in the base: ' + rel)
            it.target_rel = rel
            writes.append({'rel': rel, 'data': it.data, 'item': it})
        edits = {k: [] for k in SCRIPT_KINDS}
        seq = [0]

        def rec(kind, op, it, s, e, new, old=b''):
            seq[0] += 1
            edits[kind].append({'op': op, 'kind': kind, 'name': disp(it.final_name), 'name_hex': it.final_name.hex(),
                                'orig_name': disp(it.name), 's1_start': s, 's1_end': e,
                                'old_sha256': sha256(old), 'new_sha256': sha256(new), 'new_len': len(new),
                                'seq': seq[0], 'bytes': new, 'item': it})
        for kind in DEF_KINDS:
            data = s1_scripts[kind]
            spans = self.base.defs(kind)['spans']
            pos = len(data)
            prefix = b'' if data.endswith(b'\n') else b'\r\n'
            for it in self.order:
                if it.kind != kind:
                    continue
                if it.status == 'replace':
                    nm, s, e = spans[self.base_info(it)['idx']]
                    old = data[s:e]
                    term = old[len(old.rstrip(b'\r\n')):]
                    rec(kind, 'replace', it, s, e, it.data.rstrip(b'\r\n') + term, old)
                elif it.status in ('new', 'rename'):
                    new = prefix + it.data.rstrip(b'\r\n') + b'\r\n'
                    prefix = b''
                    rec(kind, 'insert', it, pos, pos, new)
        data = s1_scripts['obj']
        spans = self.base.objects()[0]
        ins = data.rfind(b'</AllObjects>')
        if ins < 0:
            raise PlanError('all.obj of the base has no </AllObjects>')
        deps = [it for it in self.order if it.kind == 'obj' and not it.switched]
        for it in sorted(self.switched, key=lambda i: i.name) + deps:
            if it.status == 'replace':
                nm, s, e = spans[self.base_info(it)['idx']]
                rec('obj', 'replace', it, s, e, it.data, data[s:e])
            elif it.status in ('new', 'rename'):
                rec('obj', 'insert', it, ins, ins, it.data + b'\r\n')
        return {'files': writes, 'edits': edits}

    def closure_of(self, root_item):
        seen, out = set(), []

        def visit(it):
            if it is None or id(it) in seen:
                return
            seen.add(id(it))
            for _r, _x, d in it.deps:
                visit(d)
            if it is not root_item:
                out.append(it)
        visit(root_item)
        return out


def apply_edits(base, edits):
    out = []
    pos = 0
    for e in sorted(edits, key=lambda e: (e['s1_start'], e['s1_end'], e['seq'])):
        out.append(base[pos:e['s1_start']])
        out.append(e['bytes'])
        pos = e['s1_end']
    out.append(base[pos:])
    return b''.join(out)
