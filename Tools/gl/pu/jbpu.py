#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""jbpu.py - reader / dumper / validator for TLBB GL (天龙八部·归来, tlbbgl_x64.exe 1.0.190) binary
Particle-Universe scripts (*.pu, magic "JBPU").  Pure Python 3, no dependencies.

  jbpu.py dump FILE.pu [--json OUT.json] [--text OUT.txt] [--ids]   (no output option: PU text to stdout)
  jbpu.py dumpall SRC_DIR OUT_DIR [--workers 4]                       OUT_DIR/<rel>.json + <rel>.txt
  jbpu.py validate DIR [DIR ...] [--report R.md] [--stats S.json] [--workers 4]
  jbpu.py gen-keywords TLBBGL_X64_EXE [-o pu_keywords.py]              re-extract the keyword table
  jbpu.py format                                                      print the format description

Broken 2026-09-12 (CY-Source data track D3): all 8,015 GL files parse, consume every byte and
re-serialise byte-identically.
"""
FORMAT_DOC = r"""
JBPU binary Particle-Universe script (little endian)
  0x00  char[4] "JBPU"
  0x04  u32     nstr
  0x08  nstr x {u32 len; u32 hash}   hash = 32-bit string hash (seeded, "" -> 0x4006EB05); not needed to read
        string bytes (UTF-8, no terminators) concatenated, zero padded to a multiple of 4
        Node root  (class "system")
  Node  u16 kw     keyword id of the object class (system, technique, renderer, emitter, affector, observer,
                   handler, behaviour, extern) or of a property that carries a dynamic attribute
                   (e.g. "angle" with type dyn_random / dyn_curved_linear / dyn_curved_spline / dyn_oscillate)
        u16 flags  0 -> 1 string index follows, 5 -> 2 string indices follow (name, type)
        u32 str[]  flags 0: the object's name for system/technique, its type for every other class
        u32 nprop, Prop[nprop]
        u32 nchild, Node[nchild]
  Prop  u16 kw, u16 vtype, value
        vtype 0x01 float  f32              0x02 bool   u32 (0/1)      0x03 uint  u32
              0x04 int    s32              0x05 string u32 index      0x06 vec2  2 x f32
              0x07 vec3   3 x f32          0x08 vec4   4 x f32        0x09 colour r g b a (4 x f32)
              0x0A quaternion stored x y z w (4 x f32; the PU text dump prints Ogre order w x y z)
              0x0B enum   u32 keyword id (e.g. billboard_type oriented_self)
              0x0C enum+string: u32 keyword id, u32 string index  (emits emitter_particle NAME)
              0x0D string list: u32 n, n x u32 string index      (exclude_emitter A B ...)
              0x0E time_colour: 5 x f32  t r g b a                (affector Colour: time_colour ...)
              0x0F enum+string+bool: u32 keyword id, u32 string index, u32 bool
                            (handler DoEnableComponent: enable_component emitter_component NAME true)
              0x11 compare: u32 keyword id (less_than/greater_than/equals), f32 threshold
                            (observer thresholds: on_time, velocity_threshold, count_threshold ...)
  Keyword ids index the table {const char* name; u64 strlen; u64 id} at VA 0x141049870 in
  tlbbgl_x64.exe (1.0.190): 603 names, ids 0x000..0x25A -> pu_keywords.py (jbpu.py gen-keywords).
"""
import argparse
import collections
import json
import os
import re
import struct
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

MAGIC = b'JBPU'
VT = {1: 'float', 2: 'bool', 3: 'uint', 4: 'int', 5: 'string', 6: 'vec2', 7: 'vec3', 8: 'vec4',
      9: 'colour', 0xA: 'quat_xyzw', 0xB: 'enum', 0xC: 'enum_string', 0xD: 'string_list',
      0xE: 'time_colour', 0xF: 'enum_string_bool', 0x11: 'compare'}
FIXED = {1: '<f', 2: '<I', 3: '<I', 4: '<i', 5: '<I', 6: '<2f', 7: '<3f', 8: '<4f', 9: '<4f',
         0xA: '<4f', 0xB: '<I', 0xC: '<2I', 0xE: '<5f', 0xF: '<3I', 0x11: '<If'}
OBJECT_CLASSES = ('system', 'technique', 'renderer', 'emitter', 'affector', 'observer', 'handler',
                  'behaviour', 'extern')
NAMED_CLASSES = ('system', 'technique')

_KW = None


def keywords():
    global _KW
    if _KW is None:
        from pu_keywords import KEYWORDS
        _KW = KEYWORDS
    return _KW


def kwname(i):
    n = keywords().get(i)
    return n.strip() if n is not None else 'kw_%03x' % i


class JBPUError(Exception):
    pass


def fmt_float(x):
    """Shortest decimal string that round-trips to the same float32."""
    if x != x:
        return 'nan'
    if x in (float('inf'), float('-inf')):
        return 'inf' if x > 0 else '-inf'
    b = struct.pack('<f', x)
    s = repr(x)
    for p in range(1, 10):
        s = '%.*g' % (p, x)
        if struct.pack('<f', float(s)) == b:
            break
    if 'e' in s:
        f = float(s)
        if 1e-5 <= abs(f) < 1e9:
            for dec in range(0, 13):
                t = '%.*f' % (dec, f)
                if struct.pack('<f', float(t)) == b:
                    s = t
                    break
    return s


def jfloat(x):
    if x != x or x in (float('inf'), float('-inf')):
        return fmt_float(x)
    return float(fmt_float(x))


class Prop:
    __slots__ = ('kw', 'vt', 'val', 'off')

    def __init__(self, kw, vt, val, off):
        self.kw, self.vt, self.val, self.off = kw, vt, val, off

    @property
    def key(self):
        return kwname(self.kw)


class Node:
    __slots__ = ('kw', 'flags', 'sidx', 'props', 'children', 'off', 'cls', 'name', 'type')

    def __init__(self, kw, flags, sidx, off):
        self.kw, self.flags, self.sidx, self.off = kw, flags, sidx, off
        self.props = []
        self.children = []
        self.cls = self.name = self.type = None

    def prop(self, key, default=None):
        for p in self.props:
            if p.key == key:
                return p
        return default

    def child(self, cls):
        return [c for c in self.children if c.cls == cls]


class PUFile:
    """Parsed JBPU file.  .root is the system Node; node.cls/.name/.type are resolved strings."""

    def __init__(self, data, path=''):
        self.path = path
        self.data = data
        self.strings, self.hashes, self.raw_strings = [], [], []
        self.root = None
        self._parse()

    @classmethod
    def load(cls, path):
        with open(path, 'rb') as f:
            return cls(f.read(), path)

    # ---------------------------------------------------------------- parse
    def _u32(self, off):
        if off + 4 > len(self.data):
            raise JBPUError('truncated at 0x%x' % off)
        return struct.unpack_from('<I', self.data, off)[0]

    def _chk(self, i, where):
        if i >= len(self.strings):
            raise JBPUError('string index %d out of range (%d strings) at 0x%x' % (i, len(self.strings), where))
        return i

    def _parse(self):
        d = self.data
        n = len(d)
        if n < 8 or d[:4] != MAGIC:
            raise JBPUError('bad magic %r' % d[:4])
        nstr = struct.unpack_from('<I', d, 4)[0]
        if 8 + 8 * nstr > n:
            raise JBPUError('string table overruns file (nstr=%d)' % nstr)
        lens = []
        for i in range(nstr):
            ln, h = struct.unpack_from('<II', d, 8 + 8 * i)
            lens.append(ln)
            self.hashes.append(h)
        off = 8 + 8 * nstr
        for ln in lens:
            if off + ln > n:
                raise JBPUError('string pool overruns file')
            b = d[off:off + ln]
            self.raw_strings.append(b)
            self.strings.append(b.decode('utf-8', 'surrogateescape'))
            off += ln
        pad = (-off) & 3
        if d[off:off + pad].strip(b'\0'):
            raise JBPUError('non-zero string padding')
        off += pad
        self.body_off = off
        self.root, off = self._node(off, 0)
        if off != n:
            raise JBPUError('%d trailing bytes after the root node' % (n - off))

    def _node(self, off, depth):
        d = self.data
        if depth > 64:
            raise JBPUError('nesting deeper than 64')
        if off + 4 > len(d):
            raise JBPUError('truncated node at 0x%x' % off)
        kw, flags = struct.unpack_from('<HH', d, off)
        if flags not in (0, 5):
            raise JBPUError('unknown node flags %d at 0x%x' % (flags, off))
        ns = 2 if flags & 4 else 1
        sidx = tuple(self._chk(self._u32(off + 4 + 4 * k), off) for k in range(ns))
        node = Node(kw, flags, sidx, off)
        node.cls = kwname(kw)
        st = [self.strings[i] for i in sidx]
        if flags & 4:
            node.name, node.type = st[0], st[1]
        elif node.cls in NAMED_CLASSES:
            node.name = st[0]
        else:
            node.type = st[0]
        p = off + 4 + 4 * ns
        nprop = self._u32(p)
        p += 4
        if nprop > 100000:
            raise JBPUError('absurd property count %d at 0x%x' % (nprop, off))
        for _ in range(nprop):
            if p + 4 > len(d):
                raise JBPUError('truncated property at 0x%x' % p)
            pk, vt = struct.unpack_from('<HH', d, p)
            q = p + 4
            if vt == 0xD:
                cnt = self._u32(q)
                q += 4
                if q + 4 * cnt > len(d):
                    raise JBPUError('truncated string list at 0x%x' % p)
                val = tuple(self._chk(x, p) for x in struct.unpack_from('<%dI' % cnt, d, q))
                q += 4 * cnt
            elif vt in FIXED:
                fmt = FIXED[vt]
                sz = struct.calcsize(fmt)
                if q + sz > len(d):
                    raise JBPUError('truncated value at 0x%x' % q)
                val = struct.unpack_from(fmt, d, q)
                q += sz
                if vt == 5:
                    self._chk(val[0], p)
                elif vt in (0xC, 0xF):
                    self._chk(val[1], p)
            else:
                raise JBPUError('unknown value type 0x%x (key %s) at 0x%x' % (vt, kwname(pk), p))
            node.props.append(Prop(pk, vt, val, p))
            p = q
        nch = self._u32(p)
        p += 4
        if nch > 100000:
            raise JBPUError('absurd child count %d at 0x%x' % (nch, off))
        for _ in range(nch):
            c, p = self._node(p, depth + 1)
            node.children.append(c)
        return node, p

    # ------------------------------------------------------------ serialise
    def to_bytes(self):
        out = bytearray(MAGIC)
        out += struct.pack('<I', len(self.raw_strings))
        for b, h in zip(self.raw_strings, self.hashes):
            out += struct.pack('<II', len(b), h)
        for b in self.raw_strings:
            out += b
        out += b'\0' * ((-len(out)) & 3)

        def wn(n):
            out.extend(struct.pack('<HH', n.kw, n.flags))
            for i in n.sidx:
                out.extend(struct.pack('<I', i))
            out.extend(struct.pack('<I', len(n.props)))
            for p in n.props:
                out.extend(struct.pack('<HH', p.kw, p.vt))
                if p.vt == 0xD:
                    out.extend(struct.pack('<I%dI' % len(p.val), len(p.val), *p.val))
                else:
                    out.extend(struct.pack(FIXED[p.vt], *p.val))
            out.extend(struct.pack('<I', len(n.children)))
            for c in n.children:
                wn(c)
        wn(self.root)
        return bytes(out)

    # ---------------------------------------------------------------- values
    def value(self, p):
        """Decoded python value of a property (floats are float32 values)."""
        v, vt = p.val, p.vt
        if vt == 1:
            return v[0]
        if vt == 2:
            return bool(v[0]) if v[0] in (0, 1) else v[0]
        if vt in (3, 4):
            return v[0]
        if vt == 5:
            return self.strings[v[0]]
        if vt in (6, 7, 8, 9, 0xA, 0xE):
            return list(v)
        if vt == 0xB:
            return kwname(v[0])
        if vt == 0xC:
            return [kwname(v[0]), self.strings[v[1]]]
        if vt == 0xD:
            return [self.strings[i] for i in v]
        if vt == 0xF:
            return [kwname(v[0]), self.strings[v[1]], bool(v[2]) if v[2] in (0, 1) else v[2]]
        if vt == 0x11:
            return [kwname(v[0]), v[1]]
        raise JBPUError('vt %x' % vt)

    def text_value(self, p):
        v, vt = p.val, p.vt
        if vt == 1:
            return fmt_float(v[0])
        if vt == 2:
            return ('true' if v[0] else 'false') if v[0] in (0, 1) else str(v[0])
        if vt in (3, 4):
            return str(v[0])
        if vt == 5:
            return _tok(self.strings[v[0]])
        if vt == 0xA:   # stored x y z w; PU / Ogre script text order is w x y z
            return ' '.join(fmt_float(x) for x in (v[3], v[0], v[1], v[2]))
        if vt in (6, 7, 8, 9, 0xE):
            return ' '.join(fmt_float(x) for x in v)
        if vt == 0xB:
            return kwname(v[0])
        if vt == 0xC:
            return kwname(v[0]) + ' ' + _tok(self.strings[v[1]])
        if vt == 0xD:
            return ' '.join(_tok(self.strings[i]) for i in v)
        if vt == 0xF:
            return '%s %s %s' % (kwname(v[0]), _tok(self.strings[v[1]]),
                                 ('true' if v[2] else 'false') if v[2] in (0, 1) else v[2])
        if vt == 0x11:
            return kwname(v[0]) + ' ' + fmt_float(v[1])
        raise JBPUError('vt %x' % vt)

    # ------------------------------------------------------------ JSON/text
    def to_json(self, ids=False):
        return {'format': 'JBPU', 'file': self.path.replace('\\', '/'), 'size': len(self.data),
                'strings': self.strings, 'system': self._jnode(self.root, ids)}

    def _jnode(self, n, ids):
        d = {'class': n.cls}
        if n.type is not None:
            d['type'] = n.type
        if n.name is not None:
            d['name'] = n.name
        if ids:
            d['kw'] = n.kw
            d['flags'] = n.flags
        if n.props:
            lst = []
            for p in n.props:
                e = {'key': p.key, 'vt': VT[p.vt], 'value': _jv(self.value(p))}
                if ids:
                    e['kw'] = p.kw
                lst.append(e)
            d['props'] = lst
        if n.children:
            d['children'] = [self._jnode(c, ids) for c in n.children]
        return d

    def to_text(self):
        out = ['// %s  (JBPU -> Particle Universe script, jbpu.py)' % os.path.basename(self.path)]
        self._tnode(self.root, 0, out)
        return '\n'.join(out) + '\n'

    def _tnode(self, n, ind, out):
        pad = '    ' * ind
        head = [n.cls]
        if n.type is not None:
            head.append(_tok(n.type))
        if n.name:
            head.append(_tok(n.name))
        out.append(pad + ' '.join(head))
        out.append(pad + '{')
        for p in n.props:
            out.append('%s    %-30s %s' % (pad, p.key, self.text_value(p)))
        for c in n.children:
            self._tnode(c, ind + 1, out)
        out.append(pad + '}')

    def walk(self, n=None, parent=None, depth=0):
        """Yield (node, parent, depth) for every node."""
        if n is None:
            n = self.root
        yield n, parent, depth
        for c in n.children:
            yield from self.walk(c, n, depth + 1)


def _tok(s):
    if s == '':
        return '""'
    if re.search(r'[\s{}"]', s):
        return '"%s"' % s.replace('"', '\\"')
    return s


def _jv(v):
    if isinstance(v, float):
        return jfloat(v)
    if isinstance(v, list):
        return [_jv(x) for x in v]
    return v


# ================================================================== validation
def owner_key(n):
    if n.cls in OBJECT_CLASSES:
        return '%s:%s' % (n.cls, n.type) if n.type is not None else n.cls
    return 'dyn'


def _stats_for(path, root_dir):
    st = {'ok': 0, 'err': [], 'classes': collections.Counter(), 'props': collections.Counter(),
          'dyn': collections.Counter(), 'enum': collections.Counter(), 'strv': collections.Counter(),
          'num': {}, 'flags': collections.Counter(), 'odd_bool': collections.Counter(),
          'sys_scale': collections.Counter(), 'roundtrip_fail': 0, 'unknown_kw': collections.Counter(),
          'cmp_raw': collections.Counter(), 'bytes': 0, 'nodes': 0, 'propn': 0, 'files': []}
    rel = os.path.relpath(path, root_dir).replace('\\', '/')
    try:
        with open(path, 'rb') as f:
            data = f.read()
        pu = PUFile(data, path)
    except (JBPUError, struct.error, OSError) as e:
        st['err'].append((rel, str(e)))
        return st
    st['ok'] = 1
    st['bytes'] = len(data)
    if pu.to_bytes() != data:
        st['roundtrip_fail'] = 1
    kws = keywords()
    ntech = nemit = naff = nobs = 0
    for n, parent, depth in pu.walk():
        st['nodes'] += 1
        if n.kw not in kws:
            st['unknown_kw']['node:%x' % n.kw] += 1
        st['flags']['%s:%d' % (n.cls if n.cls in OBJECT_CLASSES else 'dyn', n.flags)] += 1
        if n.cls in OBJECT_CLASSES:
            ok = owner_key(n)
            st['classes'][ok] += 1
            ntech += n.cls == 'technique'
            nemit += n.cls == 'emitter'
            naff += n.cls == 'affector'
            nobs += n.cls == 'observer'
        else:
            ok = owner_key(parent) + '/' + n.cls if parent is not None else n.cls
            st['dyn'][(owner_key(parent) if parent is not None else '-', n.cls, n.type)] += 1
        for p in n.props:
            st['propn'] += 1
            if p.kw not in kws:
                st['unknown_kw']['prop:%x' % p.kw] += 1
            st['props'][(ok, p.key, VT[p.vt])] += 1
            v = p.val
            if p.vt == 2 and v[0] not in (0, 1):
                st['odd_bool'][(ok, p.key, v[0])] += 1
            if p.vt in (0xB, 0xC, 0xF):
                if v[0] not in kws:
                    st['unknown_kw']['enum:%x' % v[0]] += 1
                st['enum'][(ok, p.key, kwname(v[0]))] += 1
            if p.vt == 0x11:
                if v[0] not in kws:
                    st['unknown_kw']['cmp:%x' % v[0]] += 1
                raw = struct.unpack('<I', struct.pack('<f', v[1]))[0]
                st['cmp_raw'][(p.key, kwname(v[0]), 'smallint' if raw < 0x10000 else 'float')] += 1
            if p.vt == 5:
                s = pu.strings[v[0]]
                if p.key in ('material', 'texture', 'disslove_texture', 'distort_texture', 'mesh_name',
                             'entity_renderer_mesh_name'):
                    s = os.path.splitext(s)[1] or '(noext)'
                st['strv'][(ok, p.key, s[:60])] += 1
            if p.vt in (1, 3, 4, 6, 7, 8, 9):
                x = v[0]
                k = (ok, p.key)
                a = st['num'].get(k)
                if a is None:
                    st['num'][k] = [x, x]
                else:
                    if x < a[0]:
                        a[0] = x
                    if x > a[1]:
                        a[1] = x
        if n.cls == 'system':
            sc = n.prop('scale')
            st['sys_scale'][tuple(round(x, 4) for x in sc.val) if sc else 'none'] += 1
    st['files'].append((rel, len(data), ntech, nemit, naff, nobs))
    return st


def _merge(a, b):
    a['ok'] += b['ok']
    a['err'] += b['err']
    a['roundtrip_fail'] += b['roundtrip_fail']
    a['bytes'] += b['bytes']
    a['nodes'] += b['nodes']
    a['propn'] += b['propn']
    a['files'] += b['files']
    for k in ('classes', 'props', 'dyn', 'enum', 'strv', 'flags', 'odd_bool', 'sys_scale', 'unknown_kw',
              'cmp_raw'):
        a[k].update(b[k])
    for k, v in b['num'].items():
        x = a['num'].get(k)
        if x is None:
            a['num'][k] = list(v)
        else:
            x[0] = min(x[0], v[0])
            x[1] = max(x[1], v[1])
    return a


def _chunk_stats(args):
    paths, root = args
    acc = None
    for p in paths:
        s = _stats_for(p, root)
        acc = s if acc is None else _merge(acc, s)
    return acc


def find_pu(dirs):
    out = []
    for d in dirs:
        if os.path.isfile(d):
            out.append((d, os.path.dirname(d)))
            continue
        for r, _, fs in os.walk(d):
            for f in fs:
                if f.lower().endswith('.pu'):
                    out.append((os.path.join(r, f), d))
    return sorted(out)


def validate(dirs, report=None, stats_path=None, workers=4):
    t0 = time.time()
    files = find_pu(dirs)
    groups = collections.defaultdict(list)
    for p, root in files:
        groups[root].append(p)
    jobs = []
    for root, ps in groups.items():
        step = max(1, len(ps) // (workers * 8) + 1)
        for i in range(0, len(ps), step):
            jobs.append((ps[i:i + step], root))
    total = None
    if workers > 1 and len(jobs) > 1:
        from concurrent.futures import ProcessPoolExecutor
        with ProcessPoolExecutor(max_workers=workers) as ex:
            for s in ex.map(_chunk_stats, jobs):
                total = s if total is None else _merge(total, s)
    else:
        for j in jobs:
            s = _chunk_stats(j)
            total = s if total is None else _merge(total, s)
    if total is None:
        print('no .pu files found')
        return 1
    dt = time.time() - t0
    nfiles = len(files)
    print('files %d  parsed %d  errors %d  roundtrip-mismatch %d  nodes %d  props %d  bytes %d  (%.1fs)' % (
        nfiles, total['ok'], len(total['err']), total['roundtrip_fail'], total['nodes'], total['propn'],
        total['bytes'], dt))
    if total['unknown_kw']:
        print('UNKNOWN keyword ids:', dict(total['unknown_kw']))
    for e in total['err'][:30]:
        print('  ERR', e)
    if stats_path:
        js = {
            'files': nfiles, 'parsed': total['ok'], 'errors': total['err'], 'roundtrip_fail': total['roundtrip_fail'],
            'nodes': total['nodes'], 'props': total['propn'], 'bytes': total['bytes'],
            'classes': dict(total['classes'].most_common()),
            'flags': dict(total['flags']),
            'unknown_kw': dict(total['unknown_kw']),
            'odd_bool': ['%s %s %s' % k for k in total['odd_bool']],
            'system_scale': {str(k): v for k, v in total['sys_scale'].most_common()},
            'compare_raw': {'|'.join(k): v for k, v in total['cmp_raw'].items()},
            'props': ['%s\t%s\t%s\t%d' % (k[0], k[1], k[2], v) for k, v in sorted(total['props'].items())],
            'dynamic_attributes': ['%s\t%s\t%s\t%d' % (k[0], k[1], k[2], v) for k, v in sorted(total['dyn'].items())],
            'enum_values': ['%s\t%s\t%s\t%d' % (k[0], k[1], k[2], v) for k, v in sorted(total['enum'].items())],
            'string_values': ['%s\t%s\t%s\t%d' % (k[0], k[1], k[2], v) for k, v in
                              sorted(total['strv'].items(), key=lambda kv: (kv[0][0], kv[0][1], -kv[1]))],
            'numeric_ranges': ['%s\t%s\t%s\t%s' % (k[0], k[1], fmt_float(v[0]), fmt_float(v[1])) for k, v in
                               sorted(total['num'].items())],
            'per_file': [list(x) for x in sorted(total['files'])],
        }
        os.makedirs(os.path.dirname(os.path.abspath(stats_path)), exist_ok=True)
        with open(stats_path, 'w', encoding='utf-8') as f:
            json.dump(js, f, ensure_ascii=False, indent=1)
    if report:
        write_report(report, dirs, nfiles, total, dt)
    return 0 if not total['err'] and not total['roundtrip_fail'] and not total['unknown_kw'] else 2


def write_report(path, dirs, nfiles, t, dt):
    L = ['# JBPU validation report', '',
         'Generated by `jbpu.py validate` on %s (%.1f s).' % (time.strftime('%Y-%m-%d %H:%M'), dt), '',
         'Inputs: ' + ', '.join('`%s`' % d for d in dirs), '',
         '| Metric | Value |', '|---|---|',
         '| .pu files | %d |' % nfiles,
         '| parsed without error | %d |' % t['ok'],
         '| parse errors | %d |' % len(t['err']),
         '| byte-identical re-serialisation failures | %d |' % t['roundtrip_fail'],
         '| unknown keyword ids (node/prop/enum) | %d |' % sum(t['unknown_kw'].values()),
         '| nodes / properties | %d / %d |' % (t['nodes'], t['propn']),
         '| bytes | %d |' % t['bytes'], '']
    if t['err']:
        L += ['## Errors', ''] + ['- `%s`: %s' % e for e in t['err']] + ['']
    L += ['## Object classes and types', '', '| class:type | count |', '|---|---|']
    L += ['| %s | %d |' % (k, v) for k, v in t['classes'].most_common()]
    L += ['', '## Node flags', '', '| class:flags | count |', '|---|---|']
    L += ['| %s | %d |' % (k, v) for k, v in sorted(t['flags'].items())]
    L += ['', '## Dynamic attribute objects (owner, property, dyn type)', '', '| owner | property | type | count |',
          '|---|---|---|---|']
    L += ['| %s | %s | %s | %d |' % (k[0], k[1], k[2], v) for k, v in sorted(t['dyn'].items(), key=lambda kv: -kv[1])]
    L += ['', '## System scale values', '']
    L += ['- %s: %d' % (k, v) for k, v in t['sys_scale'].most_common(12)]
    L += ['', 'Full property/enum/string/range tables: see the stats JSON.', '']
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(L))


# ===================================================================== dumping
def dump_one(src, json_out=None, text_out=None, ids=False):
    pu = PUFile.load(src)
    if json_out:
        os.makedirs(os.path.dirname(os.path.abspath(json_out)), exist_ok=True)
        with open(json_out, 'w', encoding='utf-8', errors='surrogateescape') as f:
            json.dump(pu.to_json(ids), f, ensure_ascii=False, indent=1)
    if text_out:
        os.makedirs(os.path.dirname(os.path.abspath(text_out)), exist_ok=True)
        with open(text_out, 'w', encoding='utf-8', errors='surrogateescape') as f:
            f.write(pu.to_text())
    return pu


def _dump_chunk(args):
    items, out_dir = args
    n = 0
    errs = []
    for src, root in items:
        rel = os.path.relpath(src, root)
        base = os.path.join(out_dir, rel)
        try:
            dump_one(src, base + '.json', base + '.txt')
            n += 1
        except (JBPUError, struct.error) as e:
            errs.append((rel, str(e)))
    return n, errs


def dumpall(src_dirs, out_dir, workers=4):
    files = find_pu(src_dirs)
    step = max(1, len(files) // (workers * 8) + 1)
    jobs = [(files[i:i + step], out_dir) for i in range(0, len(files), step)]
    n = 0
    errs = []
    if workers > 1 and len(jobs) > 1:
        from concurrent.futures import ProcessPoolExecutor
        with ProcessPoolExecutor(max_workers=workers) as ex:
            for a, e in ex.map(_dump_chunk, jobs):
                n += a
                errs += e
    else:
        for j in jobs:
            a, e = _dump_chunk(j)
            n += a
            errs += e
    print('dumped %d/%d files to %s, %d errors' % (n, len(files), out_dir, len(errs)))
    for e in errs[:20]:
        print('  ERR', e)
    return 0 if not errs else 2


# ============================================================ keyword table
def gen_keywords(exe, out):
    import hashlib
    d = open(exe, 'rb').read()
    pe = struct.unpack_from('<I', d, 0x3c)[0]
    nsec = struct.unpack_from('<H', d, pe + 6)[0]
    optsz = struct.unpack_from('<H', d, pe + 20)[0]
    base = struct.unpack_from('<Q', d, pe + 24 + 24)[0]
    secs = []
    so = pe + 24 + optsz
    for _ in range(nsec):
        vsz, va, rsz, rp = struct.unpack_from('<IIII', d, so + 8)
        secs.append((base + va, rsz, rp))
        so += 40

    def off2va(o):
        for va, rsz, rp in secs:
            if rp <= o < rp + rsz:
                return va + o - rp

    def va2off(v):
        for va, rsz, rp in secs:
            if va <= v < va + rsz:
                return rp + v - va

    table = None
    for m in re.finditer(rb'\0system\0', d):
        va = off2va(m.start() + 1)
        k = d.find(struct.pack('<QQQ', va, 6, 0x32))
        if k >= 0:
            table = k - 0x32 * 24
            break
    if table is None:
        raise SystemExit('keyword table not found (anchor {"system", 6, 0x32})')
    kw = {}
    i = 0
    while True:
        ptr, ln, idx = struct.unpack_from('<QQQ', d, table + 24 * i)
        o = va2off(ptr) if ptr else None
        if o is None or idx != i:
            break
        name = d[o:o + ln]
        if not name or b'\0' in name:
            break
        kw[idx] = name.decode('latin1')
        i += 1
    sha = hashlib.sha256(d).hexdigest()
    lines = ['# -*- coding: utf-8 -*-',
             '# Generated by jbpu.py gen-keywords from %s' % os.path.basename(exe),
             '# exe sha256 %s' % sha,
             '# table at VA 0x%x: %d entries of {const char* name; u64 strlen; u64 id}' % (off2va(table), len(kw)),
             '# NOTE: 0x0ae "sphere_collider " has a trailing space and 0x0af "ortex" lacks its "v" in the exe.',
             'KEYWORDS = {']
    for k in sorted(kw):
        lines.append('    0x%03x: %r,' % (k, kw[k]))
    lines.append('}')
    with open(out, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print('wrote %d keywords (0x000..0x%03x) to %s' % (len(kw), max(kw), out))


def main(argv=None):
    ap = argparse.ArgumentParser(description='TLBB GL JBPU (.pu) reader')
    sub = ap.add_subparsers(dest='cmd')
    a = sub.add_parser('dump')
    a.add_argument('file')
    a.add_argument('--json')
    a.add_argument('--text')
    a.add_argument('--ids', action='store_true')
    a = sub.add_parser('dumpall')
    a.add_argument('src', nargs='+')
    a.add_argument('out')
    a.add_argument('--workers', type=int, default=4)
    a = sub.add_parser('validate')
    a.add_argument('dirs', nargs='+')
    a.add_argument('--report')
    a.add_argument('--stats')
    a.add_argument('--workers', type=int, default=4)
    a = sub.add_parser('gen-keywords')
    a.add_argument('exe')
    a.add_argument('-o', default=os.path.join(HERE, 'pu_keywords.py'))
    sub.add_parser('format')
    args = ap.parse_args(argv)
    if args.cmd == 'dump':
        if not args.json and not args.text:
            sys.stdout.write(PUFile.load(args.file).to_text())
            return 0
        dump_one(args.file, args.json, args.text, args.ids)
        return 0
    if args.cmd == 'dumpall':
        return dumpall(args.src, args.out, min(4, max(1, args.workers)))
    if args.cmd == 'validate':
        return validate(args.dirs, args.report, args.stats, min(4, max(1, args.workers)))
    if args.cmd == 'gen-keywords':
        gen_keywords(args.exe, args.o)
        return 0
    if args.cmd == 'format':
        print(FORMAT_DOC)
        return 0
    ap.print_help()
    return 1


if __name__ == '__main__':
    sys.exit(main())
