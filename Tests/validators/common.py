# -*- coding: utf-8 -*-
"""Shared helpers for the CY-Source data validators (Docs/05-QUY-TRINH-TAI-SAN_vi.md muc 7).

Data root = a client Data folder in the client_GL layout (EffectFolder, ModelFolder..Model3Folder,
MaterialFolder..Material5Folder, ...; Model4-8 / Material6-8 are read when present, like the B engine).
Names are GBK BYTES everywhere (Docs/08 muc 1.2 / 1.3): on disk they appear as cp1252 mojibake and are
mapped back with tlbbfmt.disk_name_bytes; lookups are case-insensitive like the engine's resource index.

Which copy of a duplicated base name does the engine open?  CY-Source OGRE
ResourceGroupManager::addResourceLocation stores resourceIndexCaseSensitive[name] = archive, so the LAST
location wins; TlbbViewer adds one location per folder and per sub-folder (folder first, then its sorted
sub-folders, depth first) in the order of client_GL Bin\\FairyResources.cfg. DataRoot.resolve() follows
that rule, and the validators also warn whenever a referenced name has several copies with different
content, so no verdict depends on the rule alone.

Read-only: nothing in this package writes into a data root.
"""
import collections
import hashlib
import json
import os
import re
import sys
import zipfile

PIPELINE_DIR = r'C:\TLBB\085\CY-Source\Tools\pipeline'
if PIPELINE_DIR not in sys.path:
    sys.path.insert(0, PIPELINE_DIR)
import tlbbfmt as F  # noqa: E402  (read-only format helpers of the pipeline)

GENERAL_FOLDERS = ('EffectFolder', 'ModelFolder', 'Model2Folder', 'Model3Folder', 'Model4Folder', 'Model5Folder',
                   'Model6Folder', 'Model7Folder', 'Model8Folder', 'InterfaceFolder', 'MaterialFolder',
                   'Material2Folder', 'Material3Folder', 'Material4Folder', 'Material5Folder', 'Material6Folder',
                   'Material7Folder', 'Material8Folder', 'SoundFolder', 'ConfigFolder')
SCRIPTS = {'obj': r'ModelFolder\all.obj', 'material': r'MaterialFolder\all.material',
           'effect': r'EffectFolder\all.effect', 'particle': r'EffectFolder\all.particle',
           'skill': r'EffectFolder\all.skill'}
TEMPLATES_ZIP = 'MaterialTemplates.zip'
BUILTIN_MATS = {b'BaseWhite', b'BaseWhiteNoLighting'}
NULL_NAMES = {b'', b'NullEffect', b'none', b'None', b'NULL', b'null'}
ERROR, WARN, INFO = 'error', 'warn', 'info'
LEVELS = (ERROR, WARN, INFO)
PAD_MAX = 16


# ------------------------------------------------------------------ names
def gbk_name(disk_name):
    """On-disk name (cp1252 mojibake of GBK, or plain ASCII) -> GBK bytes."""
    return F.disk_name_bytes(disk_name, True)


def key(name_bytes):
    """Case-insensitive lookup key of a (possibly path-prefixed) GBK name."""
    return F.key_of(F.base_of(name_bytes))


def disp(x):
    if isinstance(x, bytes):
        return F.disp(x)
    return '' if x is None else str(x)


def sha256(b):
    return hashlib.sha256(b).hexdigest()


def ext_of(name):
    if isinstance(name, bytes):
        name = name.decode('latin-1')
    return os.path.splitext(name)[1].lower()


def content_len(ext, data):
    """Length of the file content without extractor padding (Docs/08 muc 2.16): the format-derived end when
    the rest is all zero or at most PAD_MAX bytes, else the full length (unknown tail = real data)."""
    info = F.analyze(ext, data)
    if not info:
        return len(data)
    end = min(info.get('end', len(data)), len(data))
    tail = data[end:]
    if not tail:
        return len(data)
    if not tail.strip(b'\x00') or len(tail) <= PAD_MAX:
        return end
    return len(data)


# ------------------------------------------------------------------ report
class Report:
    def __init__(self):
        self.items = []

    def add(self, vid, level, subject, message, **extra):
        rec = {'vid': vid, 'level': level, 'subject': disp(subject), 'message': message}
        for k, v in extra.items():
            rec[k] = disp(v) if isinstance(v, bytes) else v
        self.items.append(rec)

    def extend(self, other):
        self.items.extend(other.items)

    def count(self, level=None, vid=None):
        return sum(1 for r in self.items if (level is None or r['level'] == level) and (vid is None or r['vid'] == vid))

    def summary(self):
        out = collections.OrderedDict()
        for r in sorted(self.items, key=lambda r: r['vid']):
            d = out.setdefault(r['vid'], {ERROR: 0, WARN: 0, INFO: 0})
            d[r['level']] = d.get(r['level'], 0) + 1
        return out

    def text(self, max_info=0):
        lines = []
        for vid, d in self.summary().items():
            lines.append('%s  error %d  warn %d  info %d' % (vid, d[ERROR], d[WARN], d[INFO]))
        shown_info = 0
        for r in self.items:
            if r['level'] == INFO:
                if shown_info >= max_info:
                    continue
                shown_info += 1
            lines.append('  [%s %-5s] %s: %s' % (r['vid'], r['level'], r['subject'], r['message']))
        return '\n'.join(lines)

    def to_json(self):
        return {'summary': self.summary(), 'errors': self.count(ERROR), 'warnings': self.count(WARN),
                'items': self.items}


# ------------------------------------------------------------------ script parsing (independent of the builder)
_COMMENT = re.compile(rb'<!--.*?-->', re.S)
_OBJ_OPEN = re.compile(rb'<Object\s+name="([^"]*)"\s*>')
_ATTR = re.compile(rb'([A-Za-z_]\w*)\s*=\s*"([^"]*)"')


def obj_spans(data):
    """all.obj -> [(name, start, end)] in file order; data[start:end] runs from '<Object' to the end of the
    matching '</Object>'. Objects inside XML comments are skipped."""
    comments = [(m.start(), m.end()) for m in _COMMENT.finditer(data)]
    out = []
    last_end = 0
    for m in _OBJ_OPEN.finditer(data):
        s = m.start()
        if s < last_end or any(a <= s < b for a, b in comments):
            continue
        e = data.find(b'</Object>', m.end())
        if e < 0:
            break
        e += len(b'</Object>')
        out.append((m.group(1), s, e))
        last_end = e
    return out


def tags(body, tag):
    """Attribute dicts of every <tag ...> element of an object block (comments removed)."""
    body = _COMMENT.sub(b'', body)
    return [dict(_ATTR.findall(a)) for a in re.findall(rb'<' + tag + rb'\b([^>]*?)/?>', body, re.S)]


def script_spans(data):
    """Top-level blocks of an Ogre-style script (all.material / all.effect / all.particle / all.skill).
    Returns (blocks, stray): blocks = [(header, start, end)], data[start:end] = header line .. line of the
    closing brace (terminator included); stray = depth-0 lines that do not open a block (Docs/08 muc 4.1).
    Same rules as tlbbfmt.iter_blocks, with offsets."""
    blocks = []
    stray = 0
    depth = 0
    header = None
    start = 0
    opened = False
    pos = 0
    for line in data.splitlines(True):
        ln = len(line)
        s = line.split(b'//', 1)[0].strip()
        if not opened:
            if s:
                if s[:1] == b'{':
                    if header is None:
                        stray += 1
                        header = b''
                        start = pos
                    opened = True
                elif s[:1] == b'}':
                    stray += 1
                else:
                    if header is not None:
                        stray += 1
                    i = s.find(b'{')
                    header = (s if i < 0 else s[:i]).strip()
                    start = pos
                    if i >= 0:
                        opened = True
                if opened:
                    depth = s.count(b'{') - s.count(b'}')
                    pos += ln
                    if depth <= 0:
                        blocks.append((header, start, pos))
                        header = None
                        opened = False
                        depth = 0
                    continue
            pos += ln
            continue
        depth += s.count(b'{') - s.count(b'}')
        pos += ln
        if depth <= 0:
            blocks.append((header, start, pos))
            header = None
            opened = False
            depth = 0
    if header is not None:
        stray += 1
    return blocks, stray


def def_name(kind, header):
    """Block header -> (name, parent). parent is only meaningful for materials."""
    toks = header.split(None, 1)
    if kind == 'material':
        if not toks or toks[0] != b'material' or len(toks) < 2:
            return None, None
        rest = toks[1].strip()
        if b':' in rest:
            nm, parent = rest.split(b':', 1)
            nm = nm.strip()
            parent = parent.strip().split()[0] if parent.strip() else b''
        else:
            nm = rest.split()[0] if rest.split() else b''
            parent = b''
        return nm, parent
    if kind == 'particle':
        if toks and toks[0] == b'particle_system' and len(toks) > 1:
            return toks[1].strip(), None
        return header.strip(), None
    if not toks or toks[0] != kind.encode('ascii') or len(toks) < 2:
        return None, None
    return toks[1].strip(), None


def kv_lines(block):
    """(key, value) of every 'key<ws>value' line of a block (first token, rest stripped)."""
    out = []
    for ln in block.splitlines():
        s = ln.split(b'//', 1)[0].strip()
        if not s or s in (b'{', b'}'):
            continue
        t = s.split(None, 1)
        out.append((t[0], t[1].strip() if len(t) > 1 else b''))
    return out


# ------------------------------------------------------------------ data root
class DataRoot:
    """Read-only view of a client Data folder."""

    def __init__(self, root):
        self.root = os.path.abspath(root)
        self._by_key = None
        self._cache = {}
        self._csha = {}

    # -- files
    def index(self):
        if self._by_key is None:
            by = collections.OrderedDict()
            for folder in GENERAL_FOLDERS:
                if os.path.isdir(os.path.join(self.root, folder)):
                    self._walk(folder, by)
            self._by_key = by
        return self._by_key

    def _walk(self, rel_dir, by):
        files, subs = [], []
        with os.scandir(os.path.join(self.root, rel_dir)) as it:
            for e in it:
                if e.is_dir(follow_symlinks=False):
                    subs.append(e.name)
                elif e.is_file(follow_symlinks=False):
                    files.append(e.name)
        for f in files:
            by.setdefault(F.key_of(gbk_name(f)), []).append(rel_dir + '\\' + f)
        for s in sorted(subs, key=gbk_name):
            self._walk(rel_dir + '\\' + s, by)

    def copies(self, name_bytes):
        return self.index().get(key(name_bytes), [])

    def resolve(self, name_bytes):
        c = self.copies(name_bytes)
        return c[-1] if c else None

    def path(self, rel):
        return os.path.join(self.root, rel)

    def read(self, rel):
        with open(self.path(rel), 'rb') as f:
            return f.read()

    def content_sha(self, rel):
        if rel not in self._csha:
            data = self.read(rel)
            self._csha[rel] = sha256(data[:content_len(ext_of(rel), data)])
        return self._csha[rel]

    def ambiguity(self, name_bytes):
        """[] when the name has one copy or all copies have the same content, else the copies."""
        c = self.copies(name_bytes)
        if len(c) < 2:
            return []
        return c if len({self.content_sha(r) for r in c}) > 1 else []

    # -- scripts
    def script(self, kind):
        k = ('script', kind)
        if k not in self._cache:
            p = self.path(SCRIPTS[kind])
            with open(p, 'rb') as f:
                self._cache[k] = f.read()
        return self._cache[k]

    def objects(self):
        """-> (spans, first) with first = {name: index into spans} (the engine uses the first occurrence)."""
        k = ('objects',)
        if k not in self._cache:
            spans = obj_spans(self.script('obj'))
            first = {}
            for i, (nm, s, e) in enumerate(spans):
                first.setdefault(nm, i)
            self._cache[k] = (spans, first)
        return self._cache[k]

    def object_block(self, name):
        spans, first = self.objects()
        i = first.get(name)
        if i is None:
            return None
        nm, s, e = spans[i]
        return self.script('obj')[s:e]

    def defs(self, kind):
        """-> dict(spans, first {name: idx}, dup {name: count}, stray, parents {name: parent})."""
        k = ('defs', kind)
        if k not in self._cache:
            data = self.script(kind)
            blocks, stray = script_spans(data)
            first, cnt, parents = {}, collections.Counter(), {}
            spans = []
            for hdr, s, e in blocks:
                nm, parent = def_name(kind, hdr)
                spans.append((nm, s, e))
                if nm is None:
                    continue
                cnt[nm] += 1
                if nm not in first:
                    first[nm] = len(spans) - 1
                    parents[nm] = parent
            self._cache[k] = {'spans': spans, 'first': first, 'dup': {n: c for n, c in cnt.items() if c > 1},
                              'stray': stray, 'parents': parents}
        return self._cache[k]

    def def_block(self, kind, name):
        d = self.defs(kind)
        i = d['first'].get(name)
        if i is None:
            return None
        nm, s, e = d['spans'][i]
        return self.script(kind)[s:e]

    # -- material templates (MaterialTemplates.zip)
    def templates(self):
        k = ('templates',)
        if k not in self._cache:
            out = {}
            zp = self.path(TEMPLATES_ZIP)
            if os.path.exists(zp):
                with zipfile.ZipFile(zp) as z:
                    for n in z.namelist():
                        if not n.lower().endswith('.material'):
                            continue
                        data = z.read(n)
                        blocks, _ = script_spans(data)
                        for hdr, s, e in blocks:
                            h = hdr[len(b'abstract '):].strip() if hdr.startswith(b'abstract ') else hdr
                            nm, parent = def_name('material', h)
                            if not nm or nm in out:
                                continue
                            body = data[s:e]
                            out[nm] = {'parent': parent or b'', 'file': n,
                                       'aliases': set(re.findall(rb'texture_alias\s+(\S+)', body))}
            self._cache[k] = out
        return self._cache[k]


def load_json(path):
    with open(path, encoding='utf-8') as f:
        return json.load(f)
