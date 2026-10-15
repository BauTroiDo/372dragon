# -*- coding: utf-8 -*-
"""Read-only dump/validator for .dynbone files (CY-Source, dynbone agent, 2026-09-12).

Format: XML <EntityDynamicBones> read by client_GL Render.dll (B). RVA evidence and the simulation are in
Docs/specs/render/06-dynbone_vi.md. What B's reader does (VA, image base 0x180000000):
  FUN_1801ce6e0  after every entity is created: "<mesh name up to the last '.'>.dynbone" in the default
                 resource group (resourceExists -> parse, cached per LogicModel)
  FUN_180230940  RootElement (name not checked) -> FIRST <DynamicBones> -> every <DynamicBone>,
                 FIRST <Colliders> -> every <CapsuleCollider>, optional <Effects> -> every <Effect>.
                 <DynamicBones> and <Colliders> are dereferenced without a NULL check.
  FUN_18022f210  DynamicBone: Bone (string) -> FUN_18022ebd0 floats UpdateRate Damping Elasticity Stiffness
                 Inert Friction Radius (missing -> 0.0), Force = Vector3 (missing -> uninitialised stack)
  FUN_1802306f0  CurveParams: DampingACParam ElasticityACParam StiffnessACParam InertACParam FrictionACParam
  FUN_18022ecd0  CapsuleCollider: Center (Vector3), Orientation ("w x y z", missing -> identity), Radius,
                 Height (floats), Invert (bool)
Numbers go through Ogre::StringConverter (parseReal / parseVector3 needs exactly 3 tokens, else ZERO /
parseQuaternion needs 4, else IDENTITY / parseBool).

Sources (never written): loose *.dynbone under the roots, and *.dynbone members of *.axp archives found under
them (one "source" per directory of archives). Each file is cross-checked against the skeleton linked by the
mesh of the same base name (the lookup B does), found in the same source.

Outputs (default Build/Logs/2026-09-12-dynbone):
  dynbone_files.tsv     one row per file: status OK/WARN/FAIL, mesh, skeleton, bone coverage, issues
  dynbone_dump.tsv      one row per element (DynamicBone / CapsuleCollider / Effect), every attribute
  dynbone_summary.json  counts, parameter ranges, issue totals
Exit code: 0 when no file is FAIL, 1 otherwise (not parseable, or would break B's reader).

Usage: py -3 dynbone.py [--out DIR] [--no-axp] [ROOT ...]
"""
import argparse
import collections
import hashlib
import json
import os
import re
import struct
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import tlbbfmt  # noqa: E402  (mesh walk, cp1252 mojibake names, AXP reader)

DEFAULT_ROOTS = [r'C:\TLBB\085\client_GL\Data', r'C:\TLBB\085\Tools\DATA NEW']
DEFAULT_OUT = r'C:\TLBB\085\CY-Source\Build\Logs\2026-09-12-dynbone'
RACE_BONES = 56          # 女主角/男主角.skeleton

BONE_FLOATS = ('UpdateRate', 'Damping', 'Elasticity', 'Stiffness', 'Inert', 'Friction', 'Radius')
BONE_ATTRS = ('Bone',) + BONE_FLOATS + ('Force',)
CURVE_ATTRS = ('DampingACParam', 'ElasticityACParam', 'StiffnessACParam', 'InertACParam', 'FrictionACParam')
CAPS_FLOATS = ('Radius', 'Height')
CAPS_ATTRS = ('Bone', 'Center', 'Orientation') + CAPS_FLOATS + ('Invert',)
ROOT_CHILDREN = ('DynamicBones', 'Colliders', 'Effects')
UNIT_RANGE = ('Damping', 'Elasticity', 'Stiffness', 'Inert', 'Friction')

DUMP_COLS = (('source', 'file', 'kind', 'idx', 'bone', 'bone_in_skeleton', 'chain_bones', 'chain_depth')
             + BONE_FLOATS + ('Force',) + CURVE_ATTRS + ('Center', 'Orientation', 'Height', 'Invert', 'other'))
FILE_COLS = ('source', 'file', 'size', 'sha256', 'status', 'mesh', 'skeleton', 'skel_bones', 'extra_bones',
             'simulated_bones', 'extra_not_simulated', 'dynamic_bones', 'colliders', 'effects', 'issues')

_CJK = re.compile('[\u3000-\u9fff\uf900-\ufaff\uff00-\uffef]')


# ------------------------------------------------------------------ names
def name_bytes(name):
    """On-disk name -> resource-name bytes (GBK). client_GL names are GBK shown as cp1252 mojibake; the
    extracted archives in Tools/DATA NEW hold real Unicode names."""
    return tlbbfmt.disk_name_bytes(name, not _CJK.search(name))


def disp(b):
    return tlbbfmt.disp(b)


def key(b):
    return tlbbfmt.key_of(tlbbfmt.base_of(b))


def clean(s):
    return str(s).replace('\t', ' ').replace('\r', ' ').replace('\n', ' ')


# ------------------------------------------------------------------ skeleton
def skel_bones(data):
    """Ogre/Fairy .skeleton -> ({handle: name bytes}, {handle: parent handle}). Bones and parents come before
    the animations, so the walk stops at the first other chunk."""
    if len(data) < 8 or data[:2] != b'\x00\x10':
        raise ValueError('not an Ogre skeleton')
    e = data.find(b'\n', 2, 80)
    if e < 0:
        raise ValueError('no version line')
    p = e + 1
    n = len(data)
    names = {}
    parents = {}
    while p + 6 <= n:
        cid, sz = struct.unpack_from('<HI', data, p)
        q = p + 6
        if cid == 0x1010:
            p = q + 2
        elif cid == 0x2000:
            k = data.index(b'\n', q, min(n, q + 1024))
            names[struct.unpack_from('<H', data, k + 1)[0]] = data[q:k]
            p = k + 1 + 2 + 28 + (12 if sz > 36 else 0)
        elif cid == 0x3000:
            h, ph = struct.unpack_from('<HH', data, q)
            parents[h] = ph
            p = q + 4
        else:
            break
    return names, parents


def chain_of(root, parents):
    """Descendants of `root` (root included) and the depth of the deepest one."""
    kids = collections.defaultdict(list)
    for h, ph in parents.items():
        kids[ph].append(h)
    out = []
    depth = 0
    stack = [(root, 1)]
    while stack:
        h, d = stack.pop()
        out.append(h)
        depth = max(depth, d)
        stack.extend((c, d + 1) for c in kids.get(h, ()))
    return out, depth


# ------------------------------------------------------------------ sources
class Source:
    """One place B-style resource lookups resolve in: a loose folder tree or a directory of .axp archives."""

    def __init__(self, label):
        self.label = label
        self.dynbones = []      # (display path, reader)
        self.files = {}         # key -> reader for .mesh / .skeleton

    def add(self, name_b, reader, is_dyn):
        if is_dyn:
            self.dynbones.append((name_b, reader))
        else:
            self.files.setdefault(key(name_b), reader)

    def read(self, name_b):
        r = self.files.get(key(name_b))
        return r() if r else None


def _file_reader(path):
    def rd():
        with open(path, 'rb') as f:
            return f.read()
    return rd


def _axp_reader(axp, name):
    def rd():
        r = axp.payload_full(name, 64 << 20)
        if r is None:
            return None
        alg, payload = r
        return payload
    return rd


def collect(roots, use_axp):
    sources = []
    for root in roots:
        loose = Source(os.path.basename(root.rstrip('\\/')) or root)
        axp_dirs = collections.defaultdict(list)
        for dp, dns, fns in os.walk(root):
            for fn in fns:
                low = fn.lower()
                path = os.path.join(dp, fn)
                if low.endswith('.axp'):
                    axp_dirs[dp].append(path)
                    continue
                if not low.endswith(('.dynbone', '.mesh', '.skeleton')):
                    continue
                rel = os.path.relpath(path, root)
                nb = name_bytes(fn)
                if low.endswith('.dynbone'):
                    loose.add(name_bytes(rel), _file_reader(path), True)
                else:
                    loose.add(nb, _file_reader(path), False)
        sources.append(loose)
        if not use_axp:
            continue
        for dp, paths in sorted(axp_dirs.items()):
            src = Source(os.path.relpath(dp, os.path.dirname(root.rstrip('\\/'))) + ' [axp]')
            for p in sorted(paths):
                try:
                    axp = tlbbfmt.Axp(p)
                    lst = axp.file_list() or []
                except (OSError, struct.error, ValueError) as ex:
                    print('  cannot read %s: %s' % (p, ex), file=sys.stderr)
                    continue
                for nm, _ in lst:
                    low = nm.lower()
                    if not low.endswith(('.dynbone', '.mesh', '.skeleton')):
                        continue
                    nb = nm.encode('gbk', 'replace')
                    shown = (os.path.basename(p) + '/' + nm).encode('gbk', 'replace')
                    src.add(shown if low.endswith('.dynbone') else nb, _axp_reader(axp, nm), low.endswith('.dynbone'))
            if src.dynbones:
                sources.append(src)
    return sources


# ------------------------------------------------------------------ XML
class Node:
    def __init__(self, tag, attrib):
        self.tag = tag
        self.attrib = attrib
        self.children = []


_TAG = re.compile(r'<(/?)([A-Za-z_][\w.:-]*)((?:\s+[\w.:-]+\s*=\s*"[^"]*")*)\s*(/?)>|<!--.*?-->|<\?.*?\?>', re.S)
_ATT = re.compile(r'([\w.:-]+)\s*=\s*"([^"]*)"')


def _from_et(e):
    n = Node(e.tag, dict(e.attrib))
    n.children = [_from_et(c) for c in e]
    return n


def _lenient(text):
    """Tag soup reader close to TinyXML's tolerance: returns the root Node or None."""
    root = None
    stack = []
    for m in _TAG.finditer(text):
        if m.group(2) is None:
            continue
        close, tag, atts, selfclose = m.group(1), m.group(2), m.group(3), m.group(4)
        if close:
            while stack and stack[-1].tag != tag:
                stack.pop()
            if stack:
                stack.pop()
            continue
        n = Node(tag, dict(_ATT.findall(atts or '')))
        if stack:
            stack[-1].children.append(n)
        elif root is None:
            root = n
        else:
            continue
        if not selfclose:
            stack.append(n)
    return root


def parse_xml(data, issues):
    if data[:3] == b'\xef\xbb\xbf':
        data = data[3:]
    body = data.rstrip(b'\x00 \t\r\n')
    if len(body) < len(data.rstrip(b' \t\r\n')):
        issues.append(('INFO', 'trailing NUL padding'))
    for enc in ('utf-8', 'gbk', 'latin-1'):
        try:
            text = body.decode(enc)
            break
        except UnicodeDecodeError:
            continue
    try:
        return _from_et(ET.fromstring(text))
    except ET.ParseError as ex:
        root = _lenient(text)
        if root is None:
            issues.append(('FAIL', 'not XML (%s)' % ex))
            return None
        issues.append(('WARN', 'not well-formed XML (%s); read leniently like TinyXML' % ex))
        return root


# ------------------------------------------------------------------ values (Ogre::StringConverter semantics)
def ogre_real(s):
    try:
        return float(s.split()[0]) if s.strip() else 0.0
    except (ValueError, IndexError):
        return None


def ogre_vec(s, n):
    t = s.split()
    if len(t) != n:
        return None
    try:
        return tuple(float(x) for x in t)
    except ValueError:
        return None


def fmt_num(v):
    return ('%g' % v) if isinstance(v, float) else str(v)


# ------------------------------------------------------------------ analysis
def analyze_file(src, name_b, data, stats):
    issues = []
    rows = []
    root = parse_xml(data, issues)
    info = {'mesh': '', 'skeleton': '', 'skel_bones': '', 'extra_bones': '', 'simulated_bones': '',
            'extra_not_simulated': '', 'dynamic_bones': 0, 'colliders': 0, 'effects': 0}
    if root is None:
        return issues, rows, info

    # skeleton linked by the mesh of the same base name (B: <mesh up to last '.'> + ".dynbone")
    base = tlbbfmt.base_of(name_b)
    stem = base[:base.rfind(b'.')] if b'.' in base else base
    names = parents = None
    mesh = src.read(stem + b'.mesh')
    if mesh is None:
        issues.append(('WARN', 'no %s.mesh in this source: B never loads this file' % disp(stem)))
    else:
        info['mesh'] = disp(stem + b'.mesh')
        skel = tlbbfmt.mesh_info(mesh).get('skel') or b''
        if not skel:
            issues.append(('WARN', 'mesh has no skeleton link'))
        else:
            info['skeleton'] = disp(tlbbfmt.base_of(skel))
            sd = src.read(tlbbfmt.base_of(skel))
            if sd is None:
                issues.append(('WARN', 'linked skeleton %s not found in this source' % disp(skel)))
            else:
                try:
                    names, parents = skel_bones(sd)
                except (ValueError, struct.error) as ex:
                    issues.append(('WARN', 'linked skeleton unreadable (%s)' % ex))
    by_name = {v: h for h, v in names.items()} if names else {}

    if root.tag != 'EntityDynamicBones':
        issues.append(('WARN', 'root <%s> is not <EntityDynamicBones> (B does not check the name)' % root.tag))
    tags = collections.Counter(c.tag for c in root.children)
    for t in sorted(tags):
        if t not in ROOT_CHILDREN:
            issues.append(('WARN', 'unknown root child <%s> ignored by B' % t))
    for t in ('DynamicBones', 'Colliders'):
        if tags[t] == 0:
            issues.append(('FAIL', 'no <%s>: B calls FirstChildElement on its NULL result (inferred crash)' % t))
        elif tags[t] > 1:
            issues.append(('WARN', 'only the first <%s> is read by B' % t))
    if tags['Effects'] > 1:
        issues.append(('WARN', 'only the first <Effects> is read by B'))

    def first(tag):
        for c in root.children:
            if c.tag == tag:
                return c
        return None

    simulated = set()

    def bone_check(el_kind, bone, idx, is_chain):
        bb = bone.encode('gbk', 'replace')
        if names is None:
            return '', '', ''
        if bb not in by_name:
            issues.append(('WARN', '%s#%d bone %s not in the linked skeleton' % (el_kind, idx, bone)))
            return 'no', '', ''
        if not is_chain:
            return 'yes', '', ''
        ch, depth = chain_of(by_name[bb], parents)
        simulated.update(ch)
        if len(ch) < 2:
            issues.append(('WARN', '%s#%d bone %s has no child bone: nothing to swing' % (el_kind, idx, bone)))
        return 'yes', str(len(ch)), str(depth)

    db = first('DynamicBones')
    if db is not None:
        for c in db.children:
            if c.tag != 'DynamicBone':
                issues.append(('WARN', 'unknown <DynamicBones>/<%s> ignored by B' % c.tag))
        els = [c for c in db.children if c.tag == 'DynamicBone']
        info['dynamic_bones'] = len(els)
        for i, el in enumerate(els):
            a = el.attrib
            row = dict.fromkeys(DUMP_COLS, '')
            row.update(source=src.label, file=disp(name_b), kind='DynamicBone', idx=i, bone=a.get('Bone', ''))
            other = []
            for k, v in a.items():
                if k not in BONE_ATTRS:
                    other.append('%s=%s' % (k, v))
                    issues.append(('WARN', 'DynamicBone#%d unknown attribute %s ignored by B' % (i, k)))
            if not a.get('Bone'):
                issues.append(('FAIL', 'DynamicBone#%d has no Bone' % i))
            for k in BONE_FLOATS:
                if k not in a:
                    issues.append(('WARN', 'DynamicBone#%d %s missing -> 0 in B' % (i, k)))
                    v = 0.0
                else:
                    v = ogre_real(a[k])
                    if v is None:
                        issues.append(('WARN', 'DynamicBone#%d %s="%s" is not a number -> 0 in B' % (i, k, a[k])))
                        v = 0.0
                row[k] = fmt_num(v)
                stats[('DynamicBone', k)].append(v)
                if k in UNIT_RANGE and not 0.0 <= v <= 1.0:
                    issues.append(('WARN', 'DynamicBone#%d %s=%g outside [0,1]' % (i, k, v)))
            if row['UpdateRate'] and float(row['UpdateRate']) <= 0:
                issues.append(('WARN', 'DynamicBone#%d UpdateRate <= 0' % i))
            if 'Force' not in a:
                issues.append(('WARN', 'DynamicBone#%d Force missing -> B reads uninitialised memory' % i))
            else:
                f = ogre_vec(a['Force'], 3)
                if f is None:
                    issues.append(('WARN', 'DynamicBone#%d Force="%s" is not 3 numbers -> ZERO in B' % (i, a['Force'])))
                    f = (0.0, 0.0, 0.0)
                row['Force'] = ' '.join(fmt_num(x) for x in f)
                stats[('DynamicBone', 'Force.y')].append(f[1])
            curves = [c for c in el.children if c.tag == 'CurveParams']
            for c in el.children:
                if c.tag != 'CurveParams':
                    issues.append(('WARN', 'DynamicBone#%d unknown child <%s> ignored by B' % (i, c.tag)))
            if curves:
                for k, v in curves[0].attrib.items():
                    if k in CURVE_ATTRS:
                        row[k] = v
                        if v.strip():
                            issues.append(('INFO', 'DynamicBone#%d %s is set (curve, see spec)' % (i, k)))
                    else:
                        other.append('CurveParams.%s=%s' % (k, v))
                        issues.append(('WARN', 'DynamicBone#%d unknown CurveParams attribute %s' % (i, k)))
            row['bone_in_skeleton'], row['chain_bones'], row['chain_depth'] = bone_check(
                'DynamicBone', a.get('Bone', ''), i, True)
            row['other'] = '; '.join(other)
            rows.append(row)

    co = first('Colliders')
    if co is not None:
        for c in co.children:
            if c.tag != 'CapsuleCollider':
                issues.append(('WARN', 'unknown <Colliders>/<%s> ignored by B' % c.tag))
        els = [c for c in co.children if c.tag == 'CapsuleCollider']
        info['colliders'] = len(els)
        for i, el in enumerate(els):
            a = el.attrib
            row = dict.fromkeys(DUMP_COLS, '')
            row.update(source=src.label, file=disp(name_b), kind='CapsuleCollider', idx=i, bone=a.get('Bone', ''))
            other = []
            for k, v in a.items():
                if k not in CAPS_ATTRS:
                    other.append('%s=%s' % (k, v))
                    issues.append(('WARN', 'CapsuleCollider#%d unknown attribute %s ignored by B' % (i, k)))
            if not a.get('Bone'):
                issues.append(('FAIL', 'CapsuleCollider#%d has no Bone' % i))
            for k in CAPS_FLOATS:
                v = ogre_real(a[k]) if k in a else 0.0
                if k not in a or v is None:
                    issues.append(('WARN', 'CapsuleCollider#%d %s missing or not a number -> 0 in B' % (i, k)))
                    v = 0.0
                row[k] = fmt_num(v)
                stats[('CapsuleCollider', k)].append(v)
            if 'Center' not in a:
                issues.append(('WARN', 'CapsuleCollider#%d Center missing -> B reads uninitialised memory' % i))
            else:
                v = ogre_vec(a['Center'], 3)
                if v is None:
                    issues.append(('WARN', 'CapsuleCollider#%d Center is not 3 numbers -> ZERO in B' % i))
                    v = (0.0, 0.0, 0.0)
                row['Center'] = ' '.join(fmt_num(x) for x in v)
            q = ogre_vec(a['Orientation'], 4) if 'Orientation' in a else (1.0, 0.0, 0.0, 0.0)
            if q is None:
                issues.append(('WARN', 'CapsuleCollider#%d Orientation is not 4 numbers -> identity in B' % i))
                q = (1.0, 0.0, 0.0, 0.0)
            row['Orientation'] = ' '.join(fmt_num(x) for x in q)
            if q != (1.0, 0.0, 0.0, 0.0):
                stats[('CapsuleCollider', 'non-identity Orientation')].append(1.0)
            inv = a.get('Invert', 'false')
            row['Invert'] = inv
            if inv.strip().lower() not in ('true', 'false'):
                issues.append(('WARN', 'CapsuleCollider#%d Invert="%s" is not true/false' % (i, inv)))
            if row['Height'] and float(row['Height']) < 2 * float(row['Radius'] or 0):
                issues.append(('INFO', 'CapsuleCollider#%d Height < 2*Radius: sphere' % i))
            row['bone_in_skeleton'] = bone_check('CapsuleCollider', a.get('Bone', ''), i, False)[0]
            row['other'] = '; '.join(other)
            rows.append(row)

    ef = first('Effects')
    if ef is not None:
        els = [c for c in ef.children if c.tag == 'Effect']
        info['effects'] = len(els)
        for i, el in enumerate(els):
            row = dict.fromkeys(DUMP_COLS, '')
            row.update(source=src.label, file=disp(name_b), kind='Effect', idx=i, bone=el.attrib.get('Bone', ''))
            row['other'] = '; '.join('%s=%s' % kv for kv in el.attrib.items() if kv[0] != 'Bone')
            row['bone_in_skeleton'] = bone_check('Effect', el.attrib.get('Bone', ''), i, False)[0]
            issues.append(('INFO', 'Effect#%d present' % i))
            rows.append(row)

    if names is not None:
        info['skel_bones'] = len(names)
        extra = max(0, len(names) - RACE_BONES)
        info['extra_bones'] = extra
        info['simulated_bones'] = len(simulated)
        # extra bones no chain reaches stay at their bind pose relative to their parent (approximation:
        # the chains only cover extra bones in the 2024-2026 data)
        info['extra_not_simulated'] = max(0, extra - len(simulated)) if extra else 0
    return issues, rows, info


def status_of(issues):
    lv = {l for l, _ in issues}
    return 'FAIL' if 'FAIL' in lv else ('WARN' if 'WARN' in lv else 'OK')


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('roots', nargs='*', default=DEFAULT_ROOTS)
    ap.add_argument('--out', default=DEFAULT_OUT)
    ap.add_argument('--no-axp', action='store_true', help='skip *.axp archives')
    args = ap.parse_args(argv)
    os.makedirs(args.out, exist_ok=True)

    sources = collect(args.roots, not args.no_axp)
    stats = collections.defaultdict(list)
    file_rows = []
    dump_rows = []
    shas = collections.Counter()
    issue_count = collections.Counter()
    for src in sources:
        for name_b, rd in sorted(src.dynbones, key=lambda x: x[0]):
            try:
                data = rd()
            except OSError as ex:
                data = None
                err = 'cannot read (%s)' % ex
            else:
                err = 'cannot read or decrypt' if data is None else ''
            if data is None:
                issues, rows, info = [('FAIL', err)], [], {}
                sha = ''
                size = ''
            else:
                sha = hashlib.sha256(data).hexdigest()
                size = len(data)
                issues, rows, info = analyze_file(src, name_b, data, stats)
            shas[sha] += 1
            st = status_of(issues)
            for l, m in issues:
                issue_count[(l, re.sub(r'#\d+', '#n', re.sub(r'"[^"]*"', '"..."', m)))] += 1
            fr = dict.fromkeys(FILE_COLS, '')
            fr.update(info)
            fr.update(source=src.label, file=disp(name_b), size=size, sha256=sha[:16], status=st,
                      issues=' | '.join('%s: %s' % x for x in issues))
            file_rows.append(fr)
            dump_rows.extend(rows)

    with open(os.path.join(args.out, 'dynbone_files.tsv'), 'w', encoding='utf-8', newline='') as f:
        f.write('\t'.join(FILE_COLS) + '\n')
        for r in file_rows:
            f.write('\t'.join(clean(r.get(c, '')) for c in FILE_COLS) + '\n')
    with open(os.path.join(args.out, 'dynbone_dump.tsv'), 'w', encoding='utf-8', newline='') as f:
        f.write('\t'.join(DUMP_COLS) + '\n')
        for r in dump_rows:
            f.write('\t'.join(clean(r.get(c, '')) for c in DUMP_COLS) + '\n')

    by_status = collections.Counter(r['status'] for r in file_rows)
    ranges = {}
    for (kind, k), vals in sorted(stats.items()):
        vals = [v for v in vals if v is not None]
        if vals:
            ranges['%s.%s' % (kind, k)] = {'min': min(vals), 'max': max(vals), 'n': len(vals),
                                           'distinct': sorted(set(vals))[:12]}
    summary = {
        'generated_by': 'Tools/pipeline/dynbone.py',
        'roots': args.roots,
        'axp': not args.no_axp,
        'files': len(file_rows),
        'unique_contents': len([s for s in shas if s]),
        'by_status': dict(by_status),
        'by_source': dict(collections.Counter(r['source'] for r in file_rows)),
        'elements': dict(collections.Counter(r['kind'] for r in dump_rows)),
        'ranges': ranges,
        'issues': {'%s: %s' % k: v for k, v in sorted(issue_count.items(), key=lambda x: (-x[1], x[0]))},
    }
    with open(os.path.join(args.out, 'dynbone_summary.json'), 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)
    print('dynbone: %d files (%d unique) %s -> %s' % (len(file_rows), summary['unique_contents'],
                                                      dict(by_status), args.out))
    for r in file_rows:
        if r['status'] == 'FAIL':
            print('  FAIL %s | %s | %s' % (r['source'], r['file'], r['issues']))
    return 1 if by_status.get('FAIL') else 0


if __name__ == '__main__':
    sys.exit(main())
