#!/usr/bin/env python3
"""codegen_cpp.py - generate the ProtocolGen C++ codec library from Registry/protocol/packets.json.

Writes CY-Source/Src/Shared/ProtocolGen (fully regenerated - never edit the output):
  PgRuntime.h/.cpp            Reader / Writer / Packet runtime            (copied from cpp_templates/)
  PgFactory.h/.cpp            factory and decode / encode API             (copied from cpp_templates/)
  PgIds.h                     packet id enums (class names and the server's XYID_* names)
  PgStructs.h/.cpp            the shared structs (one class per distinct bis/bos layout)
  PgPackets_<domain>.h/.cpp   one class per packet, grouped by the server's packet_domains file
  PgFactoryTable.cpp          (proto, id) -> name / constructor table
  ProtocolGen.h               umbrella header
  PgCoverage.tsv              per class: branch selectors, merged branches, undecodable points

The codecs follow the reference decoder speccodec.py (same spec tree, same Lua condition semantics:
numbers are truthy, `(x && 1) || 0` fields are booleans, t[i] out of range is nil).  Conditions on
server-side state that is not on the wire become explicit selector members (decode rule from
codegen_cpp_rules.py or a documented default); if/else branches with an identical wire layout are
merged.  read() never reads out of bounds and returns false on bad input; write() never fails and cuts
over-long strings at a UTF-8 boundary to the spec limit (the server's own cut).

Usage: codegen_cpp.py [--spec packets.json] [--out DIR] [--quiet]
"""
import argparse
import hashlib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CY = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import speccodec  # noqa: E402  (condition parser shared with the reference decoder)
import codegen_cpp_rules as RULES  # noqa: E402

SPEC = os.path.join(CY, 'Registry', 'protocol', 'packets.json')
OUT = os.path.join(CY, 'Src', 'Shared', 'ProtocolGen')
TEMPLATES = os.path.join(HERE, 'cpp_templates')
TEMPLATE_FILES = ('PgRuntime.h', 'PgRuntime.cpp', 'PgFactory.h', 'PgFactory.cpp')

# spec type -> (C++ type, Reader/Writer method, wire size)
PRIM = {
    'u8': ('uint8_t', 'u8', 1), 'i8': ('int8_t', 'i8', 1), 'bool': ('uint8_t', 'b8', 1),
    'u16': ('uint16_t', 'u16', 2), 'i16': ('int16_t', 'i16', 2),
    'u32': ('uint32_t', 'u32', 4), 'i32': ('int32_t', 'i32', 4), 'f32': ('float', 'f32', 4),
    'u64': ('uint64_t', 'u64', 8),
}
RANGE = {'u8': (0, 0xFF), 'bool': (0, 0xFF), 'i8': (-0x80, 0x7F), 'u16': (0, 0xFFFF), 'i16': (-0x8000, 0x7FFF),
         'u32': (0, 0xFFFFFFFF), 'i32': (-0x80000000, 0x7FFFFFFF), 'u64': (0, 0xFFFFFFFFFFFFFFFF)}
STR_PREFIX = {'str8': 'u8', 'str16': 'u16', 'str32': 'u32'}
RE_FIXED = re.compile(r'^bytes\[(\d+)\]$')
SCALARS = {'uint8_t', 'int8_t', 'uint16_t', 'int16_t', 'uint32_t', 'int32_t', 'uint64_t', 'int64_t', 'float', 'bool'}
RESERVED = set('''
alignas alignof and and_eq asm auto bitand bitor bool break case catch char char16_t char32_t class compl
const constexpr const_cast continue decltype default delete do double dynamic_cast else enum explicit export
extern false float for friend goto if inline int long mutable namespace new noexcept not not_eq nullptr
operator or or_eq private protected public register reinterpret_cast return short signed sizeof static
static_assert static_cast struct switch template this thread_local throw true try typedef typeid typename
union unsigned using virtual void volatile wchar_t while xor xor_eq
min max near far small interface IN OUT OPTIONAL ERROR DELETE TRUE FALSE NULL BOOL BYTE WORD DWORD INT UINT
CHAR VOID LONG ULONG USHORT FLOAT PVOID HANDLE pascal cdecl hyper boolean errno assert offsetof pg std
read write wireSize packetId packetName packetProto packetDir PACKET_ID
'''.split())
LEAF_PREFIX = re.compile(r'^(.+?\[[^\]]*\])\.(.+)$')


class GenError(Exception):
    pass


class Unresolved(Exception):
    """A condition / length / count that cannot be computed from the members in scope."""

    def __init__(self, msg, kind='server'):
        Exception.__init__(self, msg)
        self.kind = kind            # server | self-presence | body | parse | type
        self.wire_count = False


# ------------------------------------------------------------------ small helpers
def stable(obj):
    """JSON of a spec subtree without source positions (structural comparisons)."""
    def clean(o):
        if isinstance(o, dict):
            return {k: clean(v) for k, v in o.items() if k not in ('line', 'line_data', 'via', 'note', 'notes')}
        if isinstance(o, list):
            return [clean(v) for v in o]
        return o
    return json.dumps(clean(obj), sort_keys=True, ensure_ascii=True)


def exclusive(p1, p2):
    """True when two branch paths ((if-uid, branch), ...) can never both be on the wire."""
    d1 = dict(p1)
    for uid, b in p2:
        if uid in d1 and d1[uid] != b:
            return True
    return False


def flatkey(parts):
    """Reference parts of the condition parser -> the flat field name used in the spec."""
    out = ''
    for kind, arg in parts:
        if kind == 'name':
            out += ('.' if out else '') + arg
        elif kind == 'idx':
            if arg[0] == 'lit' and isinstance(arg[1], int) and not isinstance(arg[1], bool):
                out += '[%d]' % arg[1]
            elif arg[0] == 'ref' and len(arg[1]) == 1 and arg[1][0][0] == 'name':
                out += '[%s]' % arg[1][0][1]
            else:
                return None
        else:
            return None
    return out


def is_name(node, var):
    return var is not None and node[0] == 'ref' and len(node[1]) == 1 and node[1][0] == ('name', var)


def strip_index(name):
    if not name:
        return name
    return re.sub(r'\[[^\]]*\]$', '', name)


def leaf_names(fields):
    out = []
    for n in fields:
        if n.get('kind') == 'if':
            for b in n['branches']:
                out += leaf_names(b['fields'])
        elif n.get('kind') is None and n.get('name'):
            out.append(n['name'])
    return out


def common_prefix(fields):
    """Anonymous arrays whose element fields are all named `P[i].x` -> ('P', 'P[i].')."""
    names = leaf_names(fields)
    if not names:
        return None
    pre = set()
    for nm in names:
        m = LEAF_PREFIX.match(nm)
        if not m:
            return None
        pre.add(m.group(1))
    if len(pre) != 1:
        return None
    p = pre.pop()
    return strip_index(p), p + '.'


def ident(name, strip=None):
    if not name:
        return None
    s = name
    if strip and s.startswith(strip) and len(s) > len(strip):
        s = s[len(strip):]
    s = s.replace('#', 'n_')
    s = re.sub(r'\[(\d+)\]', r'_\1', s)
    s = re.sub(r'\[[A-Za-z_]\w*\]', '', s)
    s = re.sub(r'\[[^\]]*\]', '_x', s)
    s = re.sub(r'[^A-Za-z0-9_]', '_', s)
    s = s.strip('_')
    if not s:
        return None
    if s[0].isdigit():
        s = 'f_' + s
    if s in RESERVED or s.startswith('pg_'):
        s += '_'
    return s


def cstr(s):
    out = []
    for ch in s:
        o = ord(ch)
        if ch == '\\':
            out.append('\\\\')
        elif ch == '"':
            out.append('\\"')
        elif 32 <= o < 127:
            out.append(ch)
        else:
            out.append('?')
    return '"' + ''.join(out) + '"'


def asc(s):
    s = str(s).replace('\r', ' ').replace('\n', ' ').replace('*/', '* /')
    s = s.encode('ascii', 'backslashreplace').decode('ascii')
    return s.rstrip('\\ ')


def intlit(v):
    if v < 0:
        if v == -2 ** 63:
            return '(-9223372036854775807LL - 1)'
        return '(%dLL)' % v
    if v <= 0x7FFFFFFFFFFFFFFF:
        return '%dLL' % v
    return '%dULL' % v


def init_lit(t, v):
    if t == 'f32':
        return repr(float(v)) + 'f'
    v = int(v)
    lo, hi = RANGE[t]
    if not lo <= v <= hi:
        span = hi - lo + 1
        v = (v - lo) % span + lo
    if t == 'u64':
        return '%dULL' % v
    if t == 'u32' and v > 0x7FFFFFFF:
        return '%dU' % v
    if t == 'i32' and v == -0x80000000:
        return '(-2147483647 - 1)'
    return str(v)


def wire_sig(fields):
    """Wire layout of a field list, ignoring names and values (branch merging)."""
    out = []
    for n in fields:
        k = n.get('kind')
        if k is None:
            t = n.get('type', '')
            if t == 'bool':
                t = 'u8'
            if t == 'bytes[]':
                out.append('var(%s|%s|%s)' % (n.get('len_field'), n.get('len_expr'), n.get('clamp')))
            elif t in STR_PREFIX:
                out.append('%s(%s|%s|%s)' % (t, n.get('guard'), n.get('clamp'), n.get('len_signed')))
            elif t.startswith('struct '):
                out.append('%s|%s' % (t, n.get('codec')))
            else:
                out.append(t)
        elif k == 'if':
            out.append('if[' + ';'.join('%s:%s' % (b['when'], wire_sig(b['fields'])) for b in n['branches']) + ']')
        elif k == 'array':
            if 'fields' not in n and n.get('type') == 'array<u8>' and 'count_field' in n:
                out.append('var(%s|None|None)' % n['count_field'])
            else:
                cnt = n.get('count', n.get('count_field', n.get('count_expr')))
                inner = wire_sig(n['fields']) if 'fields' in n else '%s|%s' % (n.get('type'), stable(n.get('element')))
                out.append('arr(%s:%s)' % (cnt, inner))
        elif k == 'blob':
            out.append('blob(%s:%s)' % (n.get('len_type'), wire_sig(n['fields'])))
        else:
            out.append('?%s' % k)
    return ','.join(out)


# ------------------------------------------------------------------ model
class Sym(object):
    """A name visible to conditions / counts / lengths.

    kind  num      scalar: member (`lv` + spec type `t`) or computed (`code`)
          bool     boolean C++ expression (`code`)
          str      std::string member (`lv`)
          fixbytes std::array<uint8_t, n> member (`lv`)
          array    container `lv`; elem = num | fixbytes | struct | scope; `count` = C++ count
          struct   struct / packet member `lv` of class `cls`
          darr     int64_t C array `lv` of length `n` (derived state)"""

    def __init__(self, kind, **kw):
        self.kind = kind
        self.code = None
        self.lv = None
        self.ident = None
        self.t = None
        self.boolish = False
        self.used = False
        self.enclosing = False
        self.loopvar = None
        self.elem = None
        self.elem_scope = None
        self.cls = None
        self.fixed = None
        self.count = None
        self.n = None
        self.__dict__.update(kw)

    def value(self):
        if self.code is not None:
            return self.code
        return ('(double)%s' if self.t == 'f32' else '(int64_t)%s') % self.lv

    def vtype(self):
        if self.boolish:
            return 'bint'
        return 'float' if self.t == 'f32' else 'int'


class Member(object):
    def __init__(self, ident_, decl, init, comment, shape, path, specname, kind):
        self.ident = ident_
        self.decl = decl
        self.init = init
        self.comment = comment
        self.shape = shape
        self.paths = [path]
        self.specname = specname
        self.kind = kind
        self.wirelen = None
        self.limit = None


class Scope(object):
    """Members of one C++ class (packet, struct or array element)."""

    def __init__(self, cname, kind, strip=None):
        self.cname = cname
        self.kind = kind
        self.strip = strip
        self.members = []
        self.by_spec = {}
        self.idents = set()
        self.type_names = set()
        self.syms = {}
        self.nested = []
        self.nested_sig = {}
        self.ctor = []
        self.anon = 0

    def add(self, specname, decl, path, init=None, comment='', shape=None, force_share=False, base=None,
            kind='field'):
        key = '%s|%s' % (kind, specname) if specname else None
        if key is not None:
            for m in self.by_spec.get(key, []):
                if m.shape == shape and (force_share or all(exclusive(path, p) for p in m.paths)):
                    m.paths.append(path)
                    return m, False
        b = base or ident(specname, self.strip)
        if not b:
            self.anon += 1
            b = 'anon%d' % self.anon
        name, k = b, 2
        while name in self.idents or name in self.type_names:
            name = '%s_%d' % (b, k)
            k += 1
        self.idents.add(name)
        m = Member(name, decl, init, comment, shape, path, specname, kind)
        self.members.append(m)
        if key is not None:
            self.by_spec.setdefault(key, []).append(m)
        return m, True


class Ctx(object):
    def __init__(self, **kw):
        self.__dict__.update(kw)

    def sub(self, **kw):
        c = Ctx(**self.__dict__)
        c.__dict__.update(kw)
        return c

    def r(self, s):
        self.R.append('    ' * self.ind + s)

    def w(self, s):
        self.W.append('    ' * self.ind + s)

    def fld(self, name):
        return '%s.%s' % (self.cls, name)

    def fail(self, why, name):
        f, y = cstr(self.fld(name)), cstr(why)
        if self.rd == self.top:
            return 'return %s.fail(%s, %s);' % (self.rd, y, f)
        return '{ %s.fail(%s, %s); return %s.failFrom(%s); }' % (self.rd, y, f, self.top, self.rd)

    def failpass(self):
        return 'return false;' if self.rd == self.top else 'return %s.failFrom(%s);' % (self.top, self.rd)


class ClassInfo(object):
    def __init__(self, cname, kind, spec, codec, owner):
        self.cname = cname
        self.kind = kind          # packet | struct
        self.spec = spec
        self.codec = codec
        self.owner = owner        # rule key
        self.scope = None
        self.R = None
        self.W = None
        self.deps = set()
        self.cov = {'selectors': [], 'merged': [], 'undecodable': [], 'notes': [], 'default_sel': 0,
                    'unconditional_fail': False}


DERIVE = {
    'char_base_attrib_flags': {
        'trigger': 'new_flags',
        'decl': ['int64_t pg_uFlags[11];', 'int64_t pg_dfeng1 = 0, pg_dfeng2 = 0;'],
        'call': 'pg::deriveCharBaseAttribFlags(%s.data(), pg_uFlags, &pg_dfeng1, &pg_dfeng2);',
        'syms': lambda: {'m_uFlags': Sym('darr', lv='pg_uFlags', n=11),
                         'dfeng_base_flags': Sym('num', code='pg_dfeng1'),
                         'dfeng_base_flags2': Sym('num', code='pg_dfeng2')},
    },
    'detail_attrib_pet_flags': {
        'trigger': '_nf',
        'decl': ['int64_t pg_mFlags[11];', 'bool pg_hasRage = false, pg_hasRageMax = false, pg_elf = false;'],
        'call': 'pg::deriveDetailAttribPetFlags(%s.data(), pg_mFlags, &pg_hasRage, &pg_hasRageMax, &pg_elf);',
        'syms': lambda: {'m_Flags': Sym('darr', lv='pg_mFlags', n=11),
                         '_has_rage': Sym('bool', code='pg_hasRage'),
                         '_has_rage_max': Sym('bool', code='pg_hasRageMax'),
                         '_elf_flag': Sym('bool', code='pg_elf'),
                         'elf_slots': Sym('bool', code='pg_elf')},
    },
}


# ------------------------------------------------------------------ generator
class Gen(object):
    def __init__(self, doc):
        self.doc = doc
        self.packets = {p['name']: p for p in doc['packets']}
        self.structs = {s['name']: s for s in doc['structs']}
        self.uid = 0
        self.classes = {}
        self.order = []
        self.in_progress = set()
        self.struct_names = {}
        self.minmemo = {}
        self.unresolved_log = []
        for s in doc['structs']:
            codecs = [c for c in ('bis', 'bos') if s.get(c)]
            if len(codecs) == 2 and stable(s['bis']['fields']) != stable(s['bos']['fields']):
                self.struct_names[(s['name'], 'bis')] = s['name'] + '_bis'
                self.struct_names[(s['name'], 'bos')] = s['name'] + '_bos'
            else:
                for c in codecs:
                    self.struct_names[(s['name'], c)] = s['name']
        clash = set(self.struct_names.values()) & set(self.packets)
        if clash:
            raise GenError('struct / packet class name clash: %s' % sorted(clash))

    # ---------------- classes
    def run(self):
        for s in self.doc['structs']:
            for c in ('bis', 'bos'):
                if s.get(c):
                    self.struct_class(s['name'], c, None)
        for p in self.doc['packets']:
            self.ensure_packet(p['name'])

    def struct_class(self, name, codec, ctx):
        if name in self.structs:
            s = self.structs[name]
            c = codec if s.get(codec) else ('bos' if codec == 'bis' else 'bis')
            cls = self.struct_names[(name, c)]
            if cls not in self.classes:
                if cls in self.in_progress:
                    raise GenError('recursive struct %s' % cls)
                self.in_progress.add(cls)
                ci = ClassInfo(cls, 'struct', s, c, 'struct:' + name)
                self.gen_body(ci, s[c]['fields'], None)
                self.classes[cls] = ci
                self.order.append(cls)
                self.in_progress.discard(cls)
            if ctx is not None:
                ctx.ci.deps.add(cls)
            return cls
        if name in self.packets:
            self.ensure_packet(name)
            if ctx is not None:
                ctx.ci.deps.add(name)
            return name
        return None

    def ensure_packet(self, name):
        if name in self.classes:
            return
        if name in self.in_progress:
            raise GenError('recursive packet reference %s' % name)
        self.in_progress.add(name)
        p = self.packets[name]
        ci = ClassInfo(name, 'packet', p, p['codec'], name)
        self.gen_body(ci, p['fields'], p.get('derive'))
        self.classes[name] = ci
        self.order.append(name)
        self.in_progress.discard(name)

    def gen_body(self, ci, fields, derive):
        scope = Scope(ci.cname, ci.kind)
        dv = DERIVE.get(derive) if derive else None
        if derive and dv is None:
            raise GenError('%s: unknown derive plugin %s' % (ci.cname, derive))
        ctx = Ctx(ci=ci, owner=ci.owner, cls=ci.cname, scope=scope, chain=[scope.syms], obj='this->', rd='r',
                  wr='w', top='r', ind=1, path=(), depth=0, R=[], W=[], derive=dv, blob=[0])
        self.emit_fields(fields, ctx)
        self.fix_nested_names(scope, {scope.cname})
        ci.scope, ci.R, ci.W = scope, ctx.R, ctx.W

    def fix_nested_names(self, scope, ancestors):
        """C++ forbids a nested class named like an enclosing class (nested anonymous arrays are all
        E_elem): rename top-down and patch the member declarations of the parent. The generated code
        itself never names element types (auto& / decltype)."""
        for sub in scope.nested:
            if sub.cname in ancestors:
                old, k = sub.cname, 2
                new = '%s_%d' % (old, k)
                while new in ancestors or new in scope.type_names or new in scope.idents:
                    k += 1
                    new = '%s_%d' % (old, k)
                scope.type_names.discard(old)
                scope.type_names.add(new)
                sub.cname = new
                pat = re.compile(r'\b%s\b' % re.escape(old))
                for m in scope.members:
                    if m.decl:
                        m.decl = pat.sub(new, m.decl)
            self.fix_nested_names(sub, ancestors | {sub.cname})

    # ---------------- report helpers
    def undecodable(self, ctx, name, why):
        ci = ctx.ci
        uncond = ctx.path == () and ctx.depth == 0
        ci.cov['undecodable'].append('%s(%s%s)' % (name, 'always: ' if uncond else '', asc(why or '')[:80]))
        if uncond:
            ci.cov['unconditional_fail'] = True

    def comment(self, n):
        bits = []
        t = n.get('type') or n.get('kind')
        if t:
            bits.append(str(t))
        if n.get('line') is not None:
            bits.append('L%s' % n['line'])
        for k in ('len_name', 'len_field', 'len_expr', 'count_field', 'count_expr', 'guard', 'clamp', 'max',
                  'min', 'const', 'default', 'expr', 'derived', 'via', 'error'):
            v = n.get(k)
            if v is None or v == '':
                continue
            if isinstance(v, str) and k in ('const', 'default'):
                v = '<%d bytes>' % len(v.encode('utf-8'))
            elif isinstance(v, str) and len(v) > 70:
                v = v[:67] + '...'
            bits.append('%s=%s' % (k, v))
        if n.get('text'):
            bits.append('text')
        return asc(' '.join(bits))

    def boolized(self, n):
        e = n.get('expr')
        name = n.get('name')
        if not e or not name:
            return False
        return re.match(r'^\(\s*%s\s*&&\s*1\s*\)\s*\|\|\s*0$' % re.escape(name), e.strip()) is not None

    def init_of(self, n, t):
        v = n.get('const') if n.get('const') is not None else n.get('default')
        if isinstance(v, bool):
            v = int(v)
        if not isinstance(v, (int, float)) or v == 0:
            return None
        return init_lit(t, v)

    def set_decl(self, m, decl):
        if m.decl is None:
            m.decl = decl
        elif m.decl != decl:
            raise GenError('member %s changes type %s -> %s' % (m.ident, m.decl, decl))

    # ---------------- sizes
    def min_size(self, fields):
        total = 0
        for n in fields:
            k = n.get('kind')
            if k is None:
                t = n.get('type', '')
                if t in PRIM:
                    total += PRIM[t][2]
                elif RE_FIXED.match(t):
                    total += int(RE_FIXED.match(t).group(1))
                elif t in STR_PREFIX:
                    total += PRIM[STR_PREFIX[t]][2]
                elif t.startswith('struct '):
                    total += self.struct_min(t[7:].strip(), n.get('codec'))
            elif k == 'if':
                if any(b['when'] == 'else' for b in n['branches']):
                    total += min(self.min_size(b['fields']) for b in n['branches'])
            elif k == 'array':
                if isinstance(n.get('count'), int):
                    if 'fields' in n:
                        total += n['count'] * self.min_size(n['fields'])
                    else:
                        el = dict(n.get('element') or {})
                        el['type'] = n['type'][6:-1]
                        total += n['count'] * self.min_size([el])
            elif k == 'blob':
                total += PRIM[n.get('len_type') or 'i32'][2]
        return total

    def struct_min(self, name, codec):
        key = (name, codec)
        if key in self.minmemo:
            return self.minmemo[key]
        self.minmemo[key] = 0
        v = 0
        if name in self.structs:
            s = self.structs[name]
            c = s.get(codec or 'bos') or s.get('bis') or s.get('bos')
            v = self.min_size(c['fields'])
        elif name in self.packets:
            v = self.min_size(self.packets[name]['fields'])
        self.minmemo[key] = v
        return v

    # ---------------- expressions
    def parse(self, text):
        if not isinstance(text, str) or not text.strip():
            raise Unresolved('empty expression', kind='parse')
        try:
            return speccodec.parse_cond(text)
        except Exception as e:  # speccodec.Unsupported, IndexError ... on malformed text
            raise Unresolved('cannot parse %r (%s)' % (text, e), kind='parse')

    def cond(self, text, ctx, mode):
        c, t = self.cx(self.parse(text), ctx, mode)
        return self.truth(c, t)

    def num_expr(self, text, ctx, mode):
        c, t = self.cx(self.parse(text), ctx, mode)
        if t in ('int', 'bint'):
            return c
        if t == 'float':
            return 'pg::lfloor(%s)' % c
        raise Unresolved('%r is not a number' % text, kind='type')

    def truth(self, c, t):
        if t == 'bool':
            return c
        if t == 'bint':
            return '(%s != 0)' % c
        if t in ('int', 'float'):
            return 'true'           # Lua: every number is truthy
        if isinstance(t, tuple):
            return c[0]             # (cond and number) -> cond
        raise Unresolved('truth value of %s' % (t,), kind='type')

    def numeric(self, c, t):
        if t in ('int', 'float'):
            return c, t
        if t == 'bint':
            return c, 'int'
        if t == 'bool':
            return '((int64_t)(%s))' % c, 'int'
        raise Unresolved('not a number', kind='type')

    def cx(self, node, ctx, mode):
        k = node[0]
        if k == 'lit':
            v = node[1]
            if isinstance(v, bool):
                return ('true' if v else 'false'), 'bool'
            if isinstance(v, int):
                return intlit(v), 'int'
            if isinstance(v, float):
                return repr(v), 'float'
            raise Unresolved('literal %r (server-side value)' % (v,), kind='server')
        if k == 'ref':
            sym, rest = self.lookup(node[1], ctx)
            return self.apply(sym, rest, ctx, mode, 'value')
        if k == 'call':
            return self.call(node, ctx, mode)
        if k == 'un':
            op, a = node[1], node[2]
            if op == '#':
                return self.length_of(a, ctx, mode), 'int'
            c, t = self.cx(a, ctx, mode)
            if op == '!':
                if t in ('bool', 'bint') or isinstance(t, tuple):
                    return '(!%s)' % self.truth(c, t), 'bool'
                return 'false', 'bool'
            c, t = self.numeric(c, t)
            if op == '-':
                return ('pg::lneg(%s)' % c, 'int') if t == 'int' else ('(-%s)' % c, 'float')
            if op == '~' and t == 'int':
                return '(~%s)' % c, 'int'
            raise Unresolved('unary %s' % op, kind='type')
        if k == 'bin':
            return self.binop(node, ctx, mode)
        raise Unresolved('expression node %s' % k, kind='parse')

    def binop(self, node, ctx, mode):
        op = node[1]
        if op in ('&&', '||'):
            return self.logic(op, node[2], node[3], ctx, mode)
        a, ta = self.numeric(*self.cx(node[2], ctx, mode))
        b, tb = self.numeric(*self.cx(node[3], ctx, mode))
        fl = 'float' in (ta, tb)
        if op in ('==', '!=', '<', '<=', '>', '>='):
            return '(%s %s %s)' % (a, op, b), 'bool'
        if op in ('&', '|', '^'):
            if fl:
                raise Unresolved('bitwise operator on a float', kind='type')
            return '(%s %s %s)' % (a, op, b), 'int'
        if op in ('<<', '>>'):
            if fl:
                raise Unresolved('shift of a float', kind='type')
            return 'pg::%s(%s, %s)' % ('lshl' if op == '<<' else 'lshr', a, b), 'int'
        if op in ('+', '-', '*'):
            if fl:
                return '(%s %s %s)' % (a, op, b), 'float'
            return 'pg::%s(%s, %s)' % ({'+': 'ladd', '-': 'lsub', '*': 'lmul'}[op], a, b), 'int'
        if op == '/':
            return 'pg::ldiv((double)(%s), (double)(%s))' % (a, b), 'float'
        if op == '//':
            if fl:
                return 'pg::lfloor(pg::ldiv((double)(%s), (double)(%s)))' % (a, b), 'int'
            return 'pg::lidiv(%s, %s)' % (a, b), 'int'
        if op == '%' and not fl:
            return 'pg::lmod(%s, %s)' % (a, b), 'int'
        raise Unresolved('operator %s' % op, kind='server')

    def logic(self, op, an, bn, ctx, mode):
        a, ta = self.cx(an, ctx, mode)
        b, tb = self.cx(bn, ctx, mode)

        def boolish(t):
            return t in ('bool', 'bint') or isinstance(t, tuple)
        if op == '&&':
            if ta in ('int', 'float'):
                return b, tb                                   # Lua: number and x -> x
            if isinstance(ta, tuple):
                raise Unresolved('nested and-value', kind='type')
            ca = self.truth(a, ta)
            if boolish(tb):
                return '(%s && %s)' % (ca, self.truth(b, tb)), 'bool'
            if tb in ('int', 'float'):
                return (ca, b), ('andval', tb)                 # Lua: c and number
            raise Unresolved('and', kind='type')
        if ta in ('int', 'float'):
            return a, ta                                       # Lua: number or x -> number
        if isinstance(ta, tuple):
            c, v = a
            vb, tbn = self.numeric(b, tb)
            return '(%s ? %s : %s)' % (c, v, vb), ('float' if 'float' in (ta[1], tbn) else 'int')
        ca = self.truth(a, ta)
        if boolish(tb):
            return '(%s || %s)' % (ca, self.truth(b, tb)), 'bool'
        raise Unresolved('or of a boolean and a number', kind='type')

    def call(self, node, ctx, mode):
        fn = node[1]
        if fn[0] != 'ref' or any(p[0] != 'name' for p in fn[1]):
            raise Unresolved('computed function call', kind='parse')
        fname = '.'.join(p[1] for p in fn[1])
        if fname not in ('math.floor', 'math.ceil', 'math.min', 'math.max', 'math.abs', 'tonumber'):
            raise Unresolved('function %s (server-side)' % fname, kind='server')
        args = [self.numeric(*self.cx(a, ctx, mode)) for a in node[2]]
        if not args:
            raise Unresolved('call without arguments', kind='parse')
        if fname in ('math.floor', 'math.ceil'):
            c, t = args[0]
            return (c, 'int') if t == 'int' else ('pg::l%s(%s)' % (fname[5:], c), 'int')
        if fname in ('math.min', 'math.max'):
            fl = any(t == 'float' for _, t in args)
            f = 'pg::lmin' if fname == 'math.min' else 'pg::lmax'
            conv = [('(double)(%s)' % c) if fl else c for c, _ in args]
            code = conv[0]
            for c in conv[1:]:
                code = '%s(%s, %s)' % (f, code, c)
            return code, ('float' if fl else 'int')
        if fname == 'math.abs':
            return 'pg::labs(%s)' % args[0][0], args[0][1]
        return args[0]

    def lookup(self, parts, ctx):
        if parts[0][0] != 'name':
            raise Unresolved('computed reference', kind='parse')
        head = parts[0][1]
        if head.startswith('$'):
            raise Unresolved('server-side local %s' % head, kind='server')
        return self.lookup_chain(parts, ctx.chain, head)

    def lookup_chain(self, parts, chain, what):
        for j in range(len(parts), 0, -1):
            key = flatkey(parts[:j])
            if key is None:
                continue
            for d in chain:
                s = d.get(key)
                if s is not None:
                    return s, parts[j:]
        raise Unresolved('%s is not on the wire here' % (flatkey(parts[:1]) or what), kind='server')

    def elem_syms(self, sym):
        if sym.elem == 'scope':
            return sym.elem_scope.syms
        if sym.elem == 'struct':
            return self.classes[sym.cls].scope.syms
        return None

    def apply(self, sym, rest, ctx, mode, want):
        sym.used = True
        while rest:
            kind, arg = rest[0]
            if sym.kind == 'array' and kind == 'idx':
                if sym.enclosing and is_name(arg, sym.loopvar):
                    rest = rest[1:]
                    if not rest:
                        e = Unresolved('presence of the current %s element (server-side table)' % sym.lv,
                                       kind='self-presence')
                        e.wire_count = sym.fixed is None
                        raise e
                    # names relative to the current element: its scope plus anything stacked on top of it
                    # (the temporary length symbols of a string guard)
                    ch = []
                    for dd in ctx.chain:
                        ch.append(dd)
                        if dd is sym.elem_scope.syms:
                            break
                    else:
                        ch = [sym.elem_scope.syms]
                    if want == 'len':
                        rk = flatkey(rest)
                        for dd in (ch if rk is not None else ()):
                            hs = dd.get('#' + rk)
                            if hs is not None and hs.kind == 'num':
                                hs.used = True
                                return Sym('num', code=hs.value(), lenval=True)
                    sym, rest = self.lookup_chain(rest, ch, 'element field')
                    sym.used = True
                    continue
                idx, _ = self.numeric(*self.cx(arg, ctx, mode))
                rest = rest[1:]
                if not rest:
                    if sym.elem != 'num' or sym.t == 'f32':
                        raise Unresolved('element value of %s' % sym.lv, kind='type')
                    return 'pg::at1(%s, %s)' % (sym.lv, idx), 'int'
                esyms = self.elem_syms(sym)
                if esyms is None:
                    raise Unresolved('field of a %s element' % sym.elem, kind='type')
                fsym, rest2 = self.lookup_chain(rest, [esyms], 'element field')
                if fsym.kind != 'num' or rest2 or fsym.ident is None:
                    raise Unresolved('element field access', kind='type')
                inner = '%s[(size_t)(%s) - 1].%s' % (sym.lv, idx, fsym.ident)
                cast = '(double)' if fsym.t == 'f32' else '(int64_t)'
                return ('(pg::inRange(%s, %s) ? %s%s : 0)' % (sym.lv, idx, cast, inner),
                        'float' if fsym.t == 'f32' else 'int')
            if sym.kind == 'darr' and kind == 'idx':
                idx, _ = self.numeric(*self.cx(arg, ctx, mode))
                rest = rest[1:]
                if rest:
                    raise Unresolved('field of derived state', kind='type')
                return 'pg::at1(%s, %d, %s)' % (sym.lv, sym.n, idx), 'int'
            if sym.kind == 'struct' and kind == 'name':
                fsym, rest = self.lookup_chain(rest, [self.classes[sym.cls].scope.syms], 'struct field')
                sym = self.rebase(fsym, sym.lv + '.')
                sym.used = True
                continue
            raise Unresolved('cannot apply %s to %s' % (kind, sym.kind), kind='type')
        if want == 'value':
            if sym.kind == 'num':
                return sym.value(), sym.vtype()
            if sym.kind == 'bool':
                return sym.code, 'bool'
            raise Unresolved('value of a %s' % sym.kind, kind='type')
        return sym

    def rebase(self, fsym, prefix):
        if fsym.ident is None:
            raise Unresolved('computed struct field', kind='type')
        s = Sym(fsym.kind)
        s.__dict__.update(fsym.__dict__)
        s.code = None
        s.lv = prefix + fsym.ident
        return s

    def length_of(self, a, ctx, mode):
        if a[0] != 'ref':
            raise Unresolved('length of an expression', kind='type')
        parts = a[1]
        if len(parts) == 1 and parts[0] == ('name', '__body__'):
            if mode == 'read':
                return '(int64_t)%s.bodySize()' % ctx.top
            raise Unresolved('#__body__ is not known while encoding', kind='body')
        key = flatkey(parts)
        if key is not None:
            for d in ctx.chain:
                s = d.get('#' + key)
                if s is not None:
                    s.used = True
                    if s.kind != 'num':
                        raise Unresolved('#%s is not a number' % key, kind='type')
                    return s.value()
        sym, rest = self.lookup(parts, ctx)
        sym = self.apply(sym, rest, ctx, mode, 'len')
        if getattr(sym, 'lenval', False):
            return sym.code
        if sym.kind == 'str':
            return '(int64_t)%s.size()' % sym.lv
        if sym.kind == 'fixbytes':
            return '%dLL' % sym.n
        if sym.kind == 'array':
            return sym.count
        raise Unresolved('length of a %s' % sym.kind, kind='type')

    # ---------------- nodes
    def emit_fields(self, fields, ctx):
        for n in fields:
            self.emit_node(n, ctx)

    def patched(self, ctx, n):
        p = RULES.NODE_PATCHES.get((ctx.owner, n.get('line')))
        if not p:
            return n
        n = dict(n)
        for k in p.get('_drop', ()):
            n.pop(k, None)
        n.update({k: v for k, v in p.items() if not k.startswith('_')})
        ctx.ci.cov['notes'].append('L%s patched (codegen_cpp_rules)' % n.get('line'))
        return n

    def emit_node(self, n, ctx):
        n = self.patched(ctx, n)
        kind = n.get('kind')
        if kind is None:
            t = n.get('type', '')
            if t.startswith('array<'):
                return self.emit_array(dict(n, kind='array'), ctx)
            if t in PRIM:
                return self.emit_prim(n, ctx)
            if RE_FIXED.match(t):
                return self.emit_fixed(n, ctx)
            if t == 'bytes[]':
                return self.emit_varbytes(n, ctx)
            if t in STR_PREFIX:
                return self.emit_str(n, ctx)
            if t.startswith('struct '):
                return self.emit_struct(n, ctx)
            return self.emit_opaque(n, ctx, 'type %s' % t)
        if kind == 'if':
            return self.emit_if(n, ctx)
        if kind == 'array':
            return self.emit_array(n, ctx)
        if kind == 'blob':
            return self.emit_blob(n, ctx)
        return self.emit_opaque(n, ctx, 'kind %s' % kind)

    def emit_opaque(self, n, ctx, why):
        nm = ident(n.get('name')) or 'opaque'
        ctx.r(ctx.fail('spec node not decodable', nm))
        self.undecodable(ctx, nm, why)

    def emit_prim(self, n, ctx):
        t = n['type']
        ctype, meth, _ = PRIM[t]
        name = n.get('name') or None
        init = self.init_of(n, t)
        m, _ = ctx.scope.add(name, ctype, ctx.path, init=init, comment=self.comment(n),
                             shape='prim:%s:%s' % (t, init))
        lv = ctx.obj + m.ident
        ctx.r('if (!%s.%s(%s)) %s' % (ctx.rd, meth, lv, ctx.fail('short read', m.ident)))
        ctx.w('%s.%s(%s);' % (ctx.wr, meth, lv))
        if name:
            ctx.scope.syms[name] = Sym('num', lv=lv, ident=m.ident, t=t, boolish=(t == 'bool' or self.boolized(n)))

    def emit_fixed(self, n, ctx):
        size = int(RE_FIXED.match(n['type']).group(1))
        name = n.get('name') or None
        fill = None
        c = n.get('const')
        if isinstance(c, str) and c.strip('\x00'):
            fill = c.encode('utf-8')[:size]
        elif isinstance(n.get('fill'), int):
            fill = int(n['fill'])
        m, created = ctx.scope.add(name, 'std::array<uint8_t, %d>' % size, ctx.path, comment=self.comment(n),
                                   shape='fix:%d:%r' % (size, fill), kind='fixbytes')
        if created and fill is not None:
            if isinstance(fill, int):
                ctx.scope.ctor.append('%s.fill(%d);' % (m.ident, fill & 0xFF))
            else:
                lit = ''.join('\\%03o' % b for b in fill)
                ctx.scope.ctor.append('std::memcpy(%s.data(), "%s", %d);' % (m.ident, lit, len(fill)))
        lv = ctx.obj + m.ident
        ctx.r('if (!%s.fixed(%s)) %s' % (ctx.rd, lv, ctx.fail('short read', m.ident)))
        ctx.w('%s.fixed(%s);' % (ctx.wr, lv))
        if name:
            ctx.scope.syms[name] = Sym('fixbytes', lv=lv, ident=m.ident, n=size)

    def emit_varbytes(self, n, ctx):
        name = n.get('name') or None
        m, _ = ctx.scope.add(name, 'std::string', ctx.path, comment=self.comment(n), shape='var:' + stable(n),
                             kind='bytes')
        lv = ctx.obj + m.ident
        clamp = n.get('clamp')
        text = n.get('len_field') or n.get('len_expr')
        rl, why = None, 'no length in the spec'
        if text:
            try:
                rl = self.num_expr(text, ctx, 'read')
            except Unresolved as e:
                why = str(e)
        wl = None
        if text:
            selfd = {name: Sym('str', lv=lv, ident=m.ident)} if name else {}
            try:
                wl = self.num_expr(text, ctx.sub(chain=[selfd] + ctx.chain), 'write')
            except Unresolved:
                wl = None
        if wl is None:
            wl = '(int64_t)%s.size()' % lv
        take = 'pg_len' if not isinstance(clamp, int) else '(pg_len > %d ? %d : pg_len)' % (clamp, clamp)
        if rl is None:
            ctx.r(ctx.fail('byte length not derivable from the wire', m.ident))
            self.undecodable(ctx, m.ident, why)
        else:
            ctx.r('{')
            ctx.r('    const int64_t pg_len = %s;' % rl)
            ctx.r('    if (pg_len < 0) %s' % ctx.fail('negative length', m.ident))
            ctx.r('    if (!%s.str(%s, (size_t)%s)) %s' % (ctx.rd, lv, take, ctx.fail('short read', m.ident)))
            ctx.r('}')
        ctx.w('{')
        ctx.w('    int64_t pg_len = %s;' % wl)
        ctx.w('    if (pg_len < 0) pg_len = 0;')
        ctx.w('    %s.padded(%s, (size_t)%s);' % (ctx.wr, lv, take))
        ctx.w('}')
        if name:
            ctx.scope.syms[name] = Sym('str', lv=lv, ident=m.ident)

    def emit_str(self, n, ctx):
        t = n['type']
        pt = STR_PREFIX[t]
        if n.get('len_signed'):
            pt = 'i' + pt[1:]
        pctype, pmeth, _ = PRIM[pt]
        name = n.get('name') or None
        limit = RANGE[pt][1]
        for k in ('max', 'clamp'):
            if isinstance(n.get(k), int) and n[k] >= 0:
                limit = min(limit, n[k])
        m, created = ctx.scope.add(name, 'std::string', ctx.path, comment=self.comment(n), shape='str:' + stable(n),
                                   kind='str')
        if created:
            wm, _ = ctx.scope.add(None, 'int64_t', ctx.path, init='pg::kAutoLen', base=m.ident + '_wirelen',
                                  kind='wirelen',
                                  comment='decoded %s prefix of %s when it differs from its size; kAutoLen = size'
                                          % (pt, m.ident))
            m.wirelen, m.limit = wm.ident, limit
        lv, wv = ctx.obj + m.ident, ctx.obj + m.wirelen
        guard = n.get('guard')
        tmp = {}
        ln = n.get('len_name')
        if ln:
            tmp[ln] = Sym('num', code='pg_len')
        if name:
            tmp['#' + name] = Sym('num', code='pg_len')
        gr = gw = None
        if guard:
            gctx = ctx.sub(chain=[tmp] + ctx.chain)
            try:
                gr = self.cond(guard, gctx, 'read')
                gw = self.cond(guard, gctx, 'write')
            except Unresolved as e:
                # server-side guard: a selector member says whether the bytes follow the length prefix
                sm, _ = ctx.scope.add('$guard:%s' % (name or m.ident), 'bool', ctx.path, init='true',
                                      shape='sel:bool:true', force_share=True, base=m.ident + '_has_data',
                                      kind='selector',
                                      comment=asc('guard %s is server state (%s); decode assumes the bytes follow'
                                                  % (guard, e)))
                gr = gw = ctx.obj + sm.ident
                ctx.r('%s = true;' % gr)
                ctx.ci.cov['selectors'].append('%s(L%s,default=true)' % (sm.ident, n.get('line')))
                ctx.ci.cov['default_sel'] += 1
                self.unresolved_log.append((ctx.cls, n.get('line'), sm.ident, 'default=true', guard, asc(str(e))))
        clamp = n.get('clamp')
        take = 'pg_len' if not isinstance(clamp, int) else '(pg_len > %d ? %d : pg_len)' % (clamp, clamp)
        ctx.r('{')
        ctx.r('    %s pg_n = 0;' % pctype)
        ctx.r('    if (!%s.%s(pg_n)) %s' % (ctx.rd, pmeth, ctx.fail('short read', m.ident)))
        ctx.r('    const int64_t pg_len = pg_n;')
        body = ['const int64_t pg_take = %s;' % take,
                'if (pg_take < 0) %s' % ctx.fail('negative length', m.ident),
                'if (!%s.str(%s, (size_t)pg_take)) %s' % (ctx.rd, lv, ctx.fail('short read', m.ident)),
                '%s = (pg_take == pg_len) ? pg::kAutoLen : pg_len;' % wv]
        if guard:
            ctx.r('    if (%s) {' % gr)
            for b in body:
                ctx.r('        ' + b)
            ctx.r('    } else {')
            ctx.r('        %s.clear();' % lv)
            ctx.r('        %s = (pg_len == 0) ? pg::kAutoLen : pg_len;' % wv)
            ctx.r('    }')
        else:
            for b in body:
                ctx.r('    ' + b)
        ctx.r('}')
        ctx.w('{')
        ctx.w('    const std::string* pg_s = &%s;' % lv)
        ctx.w('    std::string pg_cut;')
        ctx.w('    int64_t pg_len = %s;' % wv)
        ctx.w('    if (pg_len == pg::kAutoLen) {')
        ctx.w('        pg_len = (int64_t)pg_s->size();')
        ctx.w('        if (pg_len > %dLL) {' % limit)
        ctx.w('            pg_cut = *pg_s;')
        ctx.w('            pg::truncateUtf8(pg_cut, %dU);' % limit)
        ctx.w('            pg_s = &pg_cut;')
        ctx.w('            pg_len = (int64_t)pg_cut.size();')
        ctx.w('            pg::logf("%s: string cut to %%u bytes (limit %d)", (unsigned)pg_len);'
              % (ctx.fld(m.ident), limit))
        ctx.w('        }')
        ctx.w('    }')
        ctx.w('    %s.%s((%s)pg_len);' % (ctx.wr, pmeth, pctype))
        wbody = 'int64_t pg_take = %s; if (pg_take < 0) pg_take = 0; %s.padded(*pg_s, (size_t)pg_take);' % (
            take, ctx.wr)
        if guard:
            ctx.w('    if (%s) { %s }' % (gw, wbody))
        else:
            ctx.w('    { %s }' % wbody)
        ctx.w('}')
        if name:
            ctx.scope.syms[name] = Sym('str', lv=lv, ident=m.ident)
        if ln:
            ctx.scope.syms[ln] = Sym('num', code='pg::wlen(%s, %s)' % (lv, wv))

    def emit_struct(self, n, ctx):
        x = n['type'][7:].strip()
        cls = self.struct_class(x, n.get('codec') or 'bos', ctx)
        if cls is None:
            return self.emit_opaque(n, ctx, 'unknown struct %s' % x)
        name = n.get('name') or None
        m, _ = ctx.scope.add(name, cls, ctx.path, comment=self.comment(n), shape='struct:' + cls, kind='struct')
        lv = ctx.obj + m.ident
        ctx.r('if (!%s.read(%s)) %s' % (lv, ctx.rd, ctx.failpass()))
        ctx.w('%s.write(%s);' % (lv, ctx.wr))
        if name:
            ctx.scope.syms[name] = Sym('struct', lv=lv, ident=m.ident, cls=cls)

    def emit_blob(self, n, ctx):
        lt = n.get('len_type') or 'i32'
        pctype, pmeth, _ = PRIM[lt]
        ctx.blob[0] += 1
        k = ctx.blob[0]
        rv, wv = 'pg_r%d' % k, 'pg_w%d' % k
        nm = ident(n.get('name')) or 'blob'
        ctx.r('{')
        ctx.r('    %s pg_bl = 0;' % pctype)
        ctx.r('    if (!%s.%s(pg_bl)) %s' % (ctx.rd, pmeth, ctx.fail('short read', nm)))
        ctx.r('    if ((int64_t)pg_bl < 0) %s' % ctx.fail('negative blob length', nm))
        ctx.r('    pg::Reader %s;' % rv)
        ctx.r('    if (!%s.sub((size_t)pg_bl, %s)) %s' % (ctx.rd, rv, ctx.fail('short read', nm)))
        ictx = ctx.sub(rd=rv, wr=wv, ind=ctx.ind + 1, R=[], W=[])
        self.emit_fields(n['fields'], ictx)
        ctx.R.extend(ictx.R)
        ctx.r('    if (%s.remaining() != 0) %s' % (rv, ctx.fail('trailing bytes in blob', nm)))
        ctx.r('}')
        ctx.w('{')
        ctx.w('    pg::Writer %s;' % wv)
        ctx.W.extend(ictx.W)
        ctx.w('    %s.%s((%s)%s.size());' % (ctx.wr, pmeth, pctype, wv))
        ctx.w('    %s.bytes(%s.buffer().data(), %s.size());' % (ctx.wr, wv, wv))
        ctx.w('}')

    # ---------------- if / else
    def mergeable(self, branches):
        if len(branches) < 2 or branches[-1]['when'] != 'else':
            return False
        s0 = wire_sig(branches[0]['fields'])
        return all(wire_sig(b['fields']) == s0 for b in branches[1:])

    def auto_selname(self, whens, line):
        real = [w for w in whens if w != 'else']
        if len(real) == 1:
            w = real[0].strip()
            m = re.match(r'^([A-Za-z_][\w.]*)(\[\w+\])?$', w)
            if m:
                return 'has_' + (ident(m.group(1)) or 'x')
            if '__body__' in w:
                return 'cond_body_L%s' % line
        return 'sel_L%s' % line

    def emit_if(self, n, ctx):
        self.uid += 1
        uid = self.uid
        line = n.get('line')
        branches = n['branches']
        whens = [b['when'] if b['when'] == 'else' else RULES.COND_PATCHES.get((ctx.owner, line, b['when']), b['when'])
                 for b in branches]
        rule = RULES.SELECTORS.get((ctx.owner, line))
        rc, wc, errs = [], [], []
        for w in whens:
            if w == 'else':
                rc.append('else')
                wc.append('else')
                continue
            for mode, out in (('read', rc), ('write', wc)):
                try:
                    out.append(self.cond(w, ctx, mode))
                except Unresolved as e:
                    out.append(None)
                    errs.append(e)
        if rule is None and None not in rc and None not in wc:
            self.emit_branches(branches, ctx, uid, rc, wc)
            return
        if rule is None and self.mergeable(branches):
            ctx.ci.cov['merged'].append('L%s' % line)
            self.emit_fields(branches[0]['fields'], ctx.sub(path=ctx.path + ((uid, 0),)))
            return
        rule = rule or {}
        single = len(branches) == 1 or (len(branches) == 2 and whens[1] == 'else')
        selname = rule.get('name') or self.auto_selname(whens, line)
        rdec = rule.get('decode')
        dec, k = [], 0
        for bi, w in enumerate(whens):
            if w == 'else':
                dec.append('else')
                continue
            if rdec is not None:
                try:
                    dec.append(self.cond(rdec[k], ctx, 'read'))
                except Unresolved as e:
                    raise GenError('%s L%s: decode rule %r does not compile: %s' % (ctx.cls, line, rdec[k], e))
            else:
                dec.append(rc[bi])
            k += 1
        if 'default' in rule:
            default = rule['default']
        elif errs and all(e.kind == 'self-presence' and e.wire_count for e in errs):
            default = True if single else 0
        else:
            default = False if single else (whens.index('else') if 'else' in whens else -1)
        if single:
            decl, init = 'bool', ('true' if default else 'false')
        else:
            decl, init = 'int8_t', str(int(default))
        why = rule.get('why') or '; '.join(sorted(set(asc(str(e)) for e in errs)))[:160]
        m, created = ctx.scope.add('$sel:' + selname, decl, ctx.path, init=init, shape='sel:%s:%s' % (decl, init),
                                   force_share=True, base=ident(selname) or 'sel', kind='selector',
                                   comment=asc('branch selector for L%s if %s | %s' % (
                                       line, ' / '.join(w for w in whens if w != 'else')[:120], why)))
        lv = ctx.obj + m.ident
        decodable = [d for d in dec if d not in (None, 'else')]
        if single:
            ctx.r('%s = %s;' % (lv, dec[0] if dec[0] not in (None, 'else') else init))
            conds = [lv, 'else'][:len(branches)]
        else:
            expr = str(int(default))
            for bi in range(len(dec) - 1, -1, -1):
                if dec[bi] not in (None, 'else'):
                    expr = '(%s) ? %d : %s' % (dec[bi], bi, expr)
            ctx.r('%s = (int8_t)(%s);' % (lv, expr))
            conds = ['else' if w == 'else' else '%s == %d' % (lv, bi) for bi, w in enumerate(whens)]
        self.emit_branches(branches, ctx, uid, conds, conds)
        if rdec is not None:
            source = 'rule'
        elif len(decodable) == len([w for w in whens if w != 'else']):
            source = 'wire'
        else:
            source = 'default=%s' % init
            ctx.ci.cov['default_sel'] += 1
        ctx.ci.cov['selectors'].append('%s(L%s,%s)' % (m.ident, line, source))
        self.unresolved_log.append((ctx.cls, line, m.ident, source, ' | '.join(w for w in whens), why))

    def emit_branches(self, branches, ctx, uid, rconds, wconds):
        rparts, wparts = [], []
        for bi, br in enumerate(branches):
            bctx = ctx.sub(path=ctx.path + ((uid, bi),), ind=ctx.ind + 1, R=[], W=[])
            self.emit_fields(br['fields'], bctx)
            rparts.append((rconds[bi], bctx.R))
            wparts.append((wconds[bi], bctx.W))
        self.splice(ctx, ctx.R, rparts)
        self.splice(ctx, ctx.W, wparts)

    def splice(self, ctx, out, parts):
        pad = '    ' * ctx.ind
        first = True
        for cond, body in parts:
            if cond == 'else':
                head = '{' if first else '} else {'
            else:
                head = ('if (%s) {' if first else '} else if (%s) {') % cond
            out.append(pad + head)
            out.extend(body)
            first = False
        if parts:
            out.append(pad + '}')

    # ---------------- arrays
    def simple_node(self, n):
        if n.get('kind') is not None:
            return False
        t = n.get('type', '')
        return t in PRIM or bool(RE_FIXED.match(t)) or t.startswith('struct ')

    def emit_array(self, n, ctx):
        line = n.get('line')
        name = n.get('name') or None
        fields = n.get('fields')
        start = RULES.LOOP_START.get((ctx.owner, line), 1)
        el = None
        strip = None
        if fields is None:
            el = dict(n.get('element') or {})
            el['type'] = n['type'][6:-1]
            if el['type'].startswith('struct ') and not el.get('codec'):
                el['codec'] = n.get('codec') or 'bos'
            if not self.simple_node(el):
                fields, el = [dict(el, name='value')], None
        elif len(fields) == 1 and self.simple_node(fields[0]):
            el = dict(fields[0])
            if not name:
                name = strip_index(el.get('name')) or None
        if fields is not None and el is None:
            cp = common_prefix(fields)
            if cp:
                strip = cp[1]
                if not name:
                    name = cp[0]
        d = ctx.depth
        cvar, kvar, evar, ivar, dvar = ['pg_%s%d' % (c, d) for c in 'ckeid']
        fixed = n['count'] if isinstance(n.get('count'), int) else None
        # The member is chosen once the element type is known (members are shared between exclusive
        # branches only when spec shape and C++ type agree); until then the code uses a placeholder.
        self.uid += 1
        ph = '@@ARRAY%d@@' % self.uid
        lv = ctx.obj + ph
        cnt_r = cnt_w = None
        why = None
        if fixed is None:
            text = n.get('count_field') or n.get('count_expr')
            if text:
                try:
                    cnt_r = self.num_expr(text, ctx, 'read')
                except Unresolved as e:
                    why = str(e)
                selfd = {name: Sym('array', lv=lv, elem='?', count='(int64_t)%s.size()' % lv)} if name else {}
                try:
                    cnt_w = self.num_expr(text, ctx.sub(chain=[selfd] + ctx.chain), 'write')
                except Unresolved:
                    cnt_w = None
            else:
                why = 'no element count in the spec'
            if cnt_w is None:
                cnt_w = '(int64_t)%s.size()' % lv
        count_here = ('%dLL' % fixed) if fixed is not None else cvar
        R, W = [], []
        pad = '    ' * ctx.ind
        fld = cstr(ctx.fld(ph))
        undecodable = False
        if el is None:
            es = Scope(None, 'elem', strip=strip)
            loopd = {}
            ivsym = Sym('num', code=ivar)
            if n.get('var'):
                loopd[n['var']] = ivsym
            if name:
                loopd[name] = Sym('array', lv=lv, enclosing=True, loopvar=n.get('var'), elem='scope', elem_scope=es,
                                  fixed=fixed, count=count_here)
            ectx = ctx.sub(scope=es, chain=[es.syms, loopd] + ctx.chain, obj=evar + '.', ind=ctx.ind + 2, path=(),
                           depth=d + 1, R=[], W=[])
            self.emit_fields(fields, ectx)
            etype = self.nest(ctx.scope, es, 'E_' + (ident(name) or 'elem'))
            decl = ('std::array<%s, %d>' % (etype, fixed)) if fixed is not None else ('std::vector<%s>' % etype)
            emin = self.min_size(fields)
            R.append(pad + '{')
            ok = True
            if fixed is None:
                if cnt_r is None:
                    R.append(pad + '    ' + ctx.fail('element count not derivable from the wire', ph))
                    undecodable, ok = True, False
                else:
                    R.append(pad + '    int64_t %s = %s;' % (cvar, cnt_r))
                    R.append(pad + '    if (%s < 0) %s = 0;' % (cvar, cvar))
                    R.append(pad + '    if (!%s.checkCount((uint64_t)%s, %d, %s)) %s' % (
                        ctx.rd, cvar, emin, fld, ctx.failpass()))
                    R.append(pad + '    %s.resize((size_t)%s);' % (lv, cvar))
                    R.append(pad + '    for (size_t %s = 0; %s < (size_t)%s; ++%s) {' % (kvar, kvar, cvar, kvar))
            else:
                R.append(pad + '    for (size_t %s = 0; %s < %d; ++%s) {' % (kvar, kvar, fixed, kvar))
            if ok:
                R.append(pad + '        auto& %s = %s[%s];' % (evar, lv, kvar))
                if ivsym.used:
                    R.append(pad + '        const int64_t %s = (int64_t)%s + %d;' % (ivar, kvar, start))
                R.extend(ectx.R)
                R.append(pad + '    }')
            R.append(pad + '}')
            W.append(pad + '{')
            if fixed is None:
                W.append(pad + '    int64_t %s = %s;' % (cvar, cnt_w))
                W.append(pad + '    if (%s < 0) %s = 0;' % (cvar, cvar))
                W.append(pad + '    const decltype(%s)::value_type %s{};' % (lv, dvar))
                W.append(pad + '    for (size_t %s = 0; %s < (size_t)%s; ++%s) {' % (kvar, kvar, cvar, kvar))
                W.append(pad + '        const auto& %s = %s < %s.size() ? %s[%s] : %s;' % (evar, kvar, lv, lv, kvar, dvar))
            else:
                W.append(pad + '    for (size_t %s = 0; %s < %d; ++%s) {' % (kvar, kvar, fixed, kvar))
                W.append(pad + '        const auto& %s = %s[%s];' % (evar, lv, kvar))
            if ivsym.used:
                W.append(pad + '        const int64_t %s = (int64_t)%s + %d;' % (ivar, kvar, start))
            W.extend(ectx.W)
            W.append(pad + '    }')
            W.append(pad + '}')
            m, created = self.array_member(n, ctx, name, decl)
            self.flush_array(ctx, R, W, ph, m.ident)
            lv = ctx.obj + m.ident
            if undecodable:
                self.undecodable(ctx, m.ident, why)
            if name:
                ctx.scope.syms[name] = Sym('array', lv=lv, ident=m.ident, elem='scope', elem_scope=es, fixed=fixed,
                                           count=('%dLL' % fixed) if fixed is not None else '(int64_t)%s.size()' % lv)
            return
        # element is a primitive, fixed bytes or a struct
        t = el['type']
        if t in PRIM:
            ctype, meth, esize = PRIM[t]
            ekind = 'num'
            dflt = self.init_of(el, t) or '0'
        elif RE_FIXED.match(t):
            esize = int(RE_FIXED.match(t).group(1))
            ctype, meth, ekind, dflt = 'std::array<uint8_t, %d>' % esize, 'fixed', 'fixbytes', None
        else:
            cls = self.struct_class(t[7:].strip(), el.get('codec') or 'bos', ctx)
            if cls is None:
                return self.emit_opaque(n, ctx, 'unknown struct %s' % t)
            ctype, meth, ekind, dflt = cls, None, 'struct', None
            esize = self.struct_min(t[7:].strip(), el.get('codec') or 'bos')
        decl = ('std::array<%s, %d>' % (ctype, fixed)) if fixed is not None else ('std::vector<%s>' % ctype)
        cnt = str(fixed) if fixed is not None else '(size_t)%s' % cvar
        # read
        R.append(pad + '{')
        body_ok = True
        if fixed is None:
            if cnt_r is None:
                R.append(pad + '    ' + ctx.fail('element count not derivable from the wire', ph))
                undecodable, body_ok = True, False
            else:
                R.append(pad + '    int64_t %s = %s;' % (cvar, cnt_r))
                R.append(pad + '    if (%s < 0) %s = 0;' % (cvar, cvar))
                R.append(pad + '    if (!%s.checkCount((uint64_t)%s, %d, %s)) %s' % (
                    ctx.rd, cvar, esize, fld, ctx.failpass()))
                R.append(pad + '    %s.resize((size_t)%s);' % (lv, cvar))
        if body_ok:
            if ekind == 'num' and esize == 1:
                R.append(pad + '    if (!%s.bytes(%s.data(), %s)) %s' % (ctx.rd, lv, cnt, ctx.fail('short read', ph)))
            elif ekind == 'num':
                R.append(pad + '    for (size_t %s = 0; %s < %s; ++%s)' % (kvar, kvar, cnt, kvar))
                R.append(pad + '        if (!%s.%s(%s[%s])) %s' % (ctx.rd, meth, lv, kvar, ctx.fail('short read', ph)))
            elif ekind == 'fixbytes':
                R.append(pad + '    for (size_t %s = 0; %s < %s; ++%s)' % (kvar, kvar, cnt, kvar))
                R.append(pad + '        if (!%s.fixed(%s[%s])) %s' % (ctx.rd, lv, kvar, ctx.fail('short read', ph)))
            else:
                R.append(pad + '    for (size_t %s = 0; %s < %s; ++%s)' % (kvar, kvar, cnt, kvar))
                R.append(pad + '        if (!%s[%s].read(%s)) %s' % (lv, kvar, ctx.rd, ctx.failpass()))
        R.append(pad + '}')
        # write
        W.append(pad + '{')
        if fixed is None:
            W.append(pad + '    int64_t %s = %s;' % (cvar, cnt_w))
            W.append(pad + '    if (%s < 0) %s = 0;' % (cvar, cvar))
            if ekind == 'struct':
                W.append(pad + '    const %s %s{};' % (ctype, dvar))
            W.append(pad + '    for (size_t %s = 0; %s < %s; ++%s) {' % (kvar, kvar, cnt, kvar))
            if ekind == 'num':
                W.append(pad + '        %s.%s(%s < %s.size() ? %s[%s] : (%s)(%s));' % (
                    ctx.wr, meth, kvar, lv, lv, kvar, ctype, dflt))
            elif ekind == 'fixbytes':
                W.append(pad + '        if (%s < %s.size()) %s.fixed(%s[%s]); else %s.fill(0, %d);' % (
                    kvar, lv, ctx.wr, lv, kvar, ctx.wr, esize))
            else:
                W.append(pad + '        (%s < %s.size() ? %s[%s] : %s).write(%s);' % (kvar, lv, lv, kvar, dvar, ctx.wr))
            W.append(pad + '    }')
        else:
            if ekind == 'num' and esize == 1:
                W.append(pad + '    %s.bytes(%s.data(), %d);' % (ctx.wr, lv, fixed))
            else:
                W.append(pad + '    for (size_t %s = 0; %s < %d; ++%s)' % (kvar, kvar, fixed, kvar))
                if ekind == 'num':
                    W.append(pad + '        %s.%s(%s[%s]);' % (ctx.wr, meth, lv, kvar))
                elif ekind == 'fixbytes':
                    W.append(pad + '        %s.fixed(%s[%s]);' % (ctx.wr, lv, kvar))
                else:
                    W.append(pad + '        %s[%s].write(%s);' % (lv, kvar, ctx.wr))
        W.append(pad + '}')
        m, created = self.array_member(n, ctx, name, decl)
        self.flush_array(ctx, R, W, ph, m.ident)
        lv = ctx.obj + m.ident
        if undecodable:
            self.undecodable(ctx, m.ident, why)
        if created and fixed is not None and ekind == 'num' and dflt != '0':
            ctx.scope.ctor.append('%s.fill(%s);' % (m.ident, dflt))
        if name:
            ctx.scope.syms[name] = Sym('array', lv=lv, ident=m.ident, elem=ekind, t=t,
                                       cls=(ctype if ekind == 'struct' else None), fixed=fixed,
                                       count=('%dLL' % fixed) if fixed is not None else '(int64_t)%s.size()' % lv)
        dv = ctx.derive
        if dv and name == dv['trigger']:
            if ekind != 'num' or esize != 1 or fixed is None:
                raise GenError('%s: derive trigger %s is not a fixed byte array' % (ctx.cls, name))
            for s in dv['decl']:
                ctx.r(s)
                ctx.w(s)
            call = dv['call'] % lv
            ctx.r(call)
            ctx.w(call)
            ctx.scope.syms.update(dv['syms']())
            ctx.ci.cov['notes'].append('derive %s after %s' % ([k for k, v in DERIVE.items() if v is dv][0], name))

    def array_member(self, n, ctx, name, decl):
        return ctx.scope.add(name, decl, ctx.path, comment=self.comment(n), shape='arr:%s|%s' % (stable(n), decl),
                             kind='array')

    def flush_array(self, ctx, R, W, ph, member):
        ctx.R.extend(x.replace(ph, member) for x in R)
        ctx.W.extend(x.replace(ph, member) for x in W)

    def nest(self, parent, es, base):
        """Declare element struct `es` inside `parent`, reusing an identical one (comments ignored)."""
        saved = []

        def blank(sc):
            for mm in sc.members:
                saved.append((mm, mm.comment))
                mm.comment = ''
            for sub in sc.nested:
                blank(sub)
        es.cname = '@'
        blank(es)
        sig = '\n'.join(self.decl_elem(es, ''))
        for mm, c in saved:
            mm.comment = c
        t = parent.nested_sig.get(sig)
        if t is None:
            t, k = base, 2
            while t in parent.type_names or t in parent.idents:
                t = '%s_%d' % (base, k)
                k += 1
            parent.type_names.add(t)
            parent.nested_sig[sig] = t
            parent.nested.append(es)
        es.cname = t
        return t

    # ---------------- declarations
    def member_lines(self, scope, pad):
        out = []
        for m in scope.members:
            decl = m.decl
            if decl is None:
                raise GenError('%s.%s has no type' % (scope.cname, m.ident))
            if decl in SCALARS:
                init = m.init if m.init is not None else ('false' if decl == 'bool' else '0')
                s = '%s %s = %s;' % (decl, m.ident, init)
            elif decl.startswith('std::array<'):
                s = '%s %s{};' % (decl, m.ident)
            else:
                s = '%s %s;' % (decl, m.ident)
            if m.comment:
                s += '  // ' + m.comment
            out.append(pad + s)
        return out

    def setter_lines(self, scope, pad):
        out = []
        names = set(m.ident for m in scope.members) | scope.type_names
        for m in scope.members:
            if m.kind == 'str':
                s = 'set_' + m.ident
                if s in names:
                    continue
                out.append(pad + 'void %s(const std::string& v) { %s = v; pg::truncateUtf8(%s, %dU); %s = pg::kAutoLen; }'
                           % (s, m.ident, m.ident, m.limit, m.wirelen))
            elif m.kind == 'fixbytes':
                s, g = 'set_' + m.ident, m.ident + '_text'
                if s in names or g in names:
                    continue
                out.append(pad + 'void %s(const std::string& v) { pg::setText(%s, v); }' % (s, m.ident))
                out.append(pad + 'std::string %s() const { return pg::getText(%s); }' % (g, m.ident))
        return out

    def body_lines(self, scope, pad):
        lines = []
        for sub in scope.nested:
            lines += self.decl_elem(sub, pad)
        lines += self.member_lines(scope, pad)
        if scope.ctor:
            lines.append(pad + '%s() {' % scope.cname)
            for s in scope.ctor:
                lines.append(pad + '    ' + s)
            lines.append(pad + '}')
        lines += self.setter_lines(scope, pad)
        return lines

    def decl_elem(self, es, pad):
        return [pad + 'struct %s {' % es.cname] + self.body_lines(es, pad + '    ') + [pad + '};']

    def spec_comment(self, ci):
        s = ci.spec
        out = []
        if ci.kind == 'packet':
            size = s.get('size') or {}
            out.append('// %s: skynet %s id %d (%s), %s, domain %s' % (
                ci.cname, s['proto'], s['id'], s['const'], s['dir'], s['domain']))
            out.append('// %s %s() line %s; body %s..%s bytes; confidence %s%s' % (
                s['source'], s['codec'], s.get('codec_line'), size.get('min'),
                size.get('max') if size.get('max') is not None else 'unbounded', s['confidence'],
                (' (' + '; '.join(s.get('confidence_reasons') or []) + ')') if s.get('confidence_reasons') else ''))
            if s.get('annotation'):
                out += wrap_comment('annotation: ' + s['annotation'])
        else:
            out.append('// struct %s (%s() codec) - %s' % (s['name'], ci.codec, s['source']))
        cov = ci.cov
        if cov['selectors']:
            out += wrap_comment('selectors: ' + ', '.join(cov['selectors']))
        if cov['merged']:
            out += wrap_comment('merged server-state branches with identical wire layout: ' + ', '.join(cov['merged']))
        if cov['undecodable']:
            out += wrap_comment('not decodable from the wire: ' + ', '.join(cov['undecodable']))
        return [asc(x) for x in out]

    def decl_class(self, ci):
        sc = ci.scope
        lines = self.spec_comment(ci)
        if ci.kind == 'packet':
            p = ci.spec
            lines.append('class %s : public Packet {' % ci.cname)
            lines.append('public:')
            lines.append('    enum : uint16_t { PACKET_ID = %d };' % p['id'])
            lines += self.body_lines(sc, '    ')
            lines.append('    uint16_t packetId() const override { return PACKET_ID; }')
            lines.append('    Proto packetProto() const override { return Proto::%s; }'
                         % ('Login' if p['proto'] == 'login' else 'Game'))
            lines.append('    Dir packetDir() const override { return Dir::%s; }' % p['dir'])
            lines.append('    const char* packetName() const override { return "%s"; }' % ci.cname)
            lines.append('    bool read(Reader& r) override;')
            lines.append('    void write(Writer& w) const override;')
            lines.append('};')
        else:
            lines.append('struct %s {' % ci.cname)
            lines += self.body_lines(sc, '    ')
            lines.append('    bool read(Reader& r);')
            lines.append('    void write(Writer& w) const;')
            lines.append('};')
        return lines

    def def_class(self, ci):
        out = ['bool %s::read(Reader& r) {' % ci.cname]
        override = os.path.join(os.path.dirname(__file__), 'overrides', ci.cname + '.read.cpp')
        if os.path.isfile(override):
            with open(override, encoding='ascii') as f:
                out += f.read().splitlines()
        else:
            out += ci.R if ci.R else ['    (void)r;']
        out.append('    return true;')
        out.append('}')
        out.append('')
        out.append('void %s::write(Writer& w) const {' % ci.cname)
        out += ci.W if ci.W else ['    (void)w;']
        out.append('}')
        out.append('')
        return out

    # ---------------- verdicts
    def decodability(self, name, memo=None):
        if name == 'GCRaidList':
            return 2  # Explicit bounded decoder for the flattened squad records.
        memo = {} if memo is None else memo
        if name in memo:
            return memo[name]
        memo[name] = 2
        ci = self.classes[name]
        v = 2
        if ci.cov['unconditional_fail']:
            v = 0
        elif ci.cov['undecodable'] or ci.cov['default_sel']:
            v = 1
        for d in ci.deps:
            dv = self.decodability(d, memo)
            if dv < 2:
                v = min(v, 1)
        memo[name] = v
        return v


def wrap_comment(text, width=112):
    words = asc(text).split(' ')
    out, cur = [], '//'
    for wd in words:
        if len(cur) + 1 + len(wd) > width and cur != '//':
            out.append(cur)
            cur = '//  '
        cur += ' ' + wd
    if cur.strip('/ '):
        out.append(cur)
    return out


def topo(names, deps):
    out, seen, stack = [], set(), set()
    names_set = set(names)

    def visit(n):
        if n in seen:
            return
        if n in stack:
            raise GenError('dependency cycle at %s' % n)
        stack.add(n)
        for dep in sorted(deps.get(n, ())):
            if dep in names_set:
                visit(dep)
        stack.discard(n)
        seen.add(n)
        out.append(n)
    for n in names:
        visit(n)
    return out


# ------------------------------------------------------------------ output
def write_text(path, lines, created):
    text = '\n'.join(lines) + '\n'
    bad = [i for i, ch in enumerate(text) if ord(ch) > 126 or (ord(ch) < 32 and ch not in '\n\t')]
    if bad:
        raise GenError('%s: non-ASCII output at offset %d' % (path, bad[0]))
    created.append(os.path.basename(path))
    if os.path.exists(path):
        with open(path, 'rb') as f:
            if f.read() == text.encode('ascii'):
                return          # unchanged: keep the timestamp so the build stays incremental
    with open(path, 'w', encoding='ascii', newline='\n') as f:
        f.write(text)


def generate(spec_path, out_dir, quiet=False):
    raw = open(spec_path, 'rb').read()
    sha = hashlib.sha256(raw).hexdigest()
    doc = json.loads(raw.decode('utf-8'))
    gen = Gen(doc)
    gen.run()
    stamp = 'spec generated %s, packets.json sha256 %s' % (doc.get('generated'), sha[:16])
    banner = ['// GENERATED by CY-Source/Tools/protocol/codegen_cpp.py from Registry/protocol/packets.json',
              '// (%s). Do not edit: regenerate.' % stamp]
    os.makedirs(out_dir, exist_ok=True)
    for fn in os.listdir(out_dir):
        if (fn.startswith('Pg') or fn == 'ProtocolGen.h') and os.path.splitext(fn)[1] in ('.h', '.cpp', '.tsv'):
            os.remove(os.path.join(out_dir, fn))
    created = []
    for fn in TEMPLATE_FILES:
        with open(os.path.join(TEMPLATES, fn), encoding='ascii') as f:
            write_text(os.path.join(out_dir, fn), f.read().rstrip('\n').split('\n'), created)

    structs = [c for c in gen.order if gen.classes[c].kind == 'struct']
    for c in structs:
        for dep in gen.classes[c].deps:
            if gen.classes[dep].kind == 'packet':
                raise GenError('struct %s embeds packet %s (unsupported)' % (c, dep))
    structs = topo(sorted(structs), {c: gen.classes[c].deps for c in structs})
    hdr = banner + ['#ifndef CYS_PROTOCOLGEN_PGSTRUCTS_H', '#define CYS_PROTOCOLGEN_PGSTRUCTS_H', '',
                    '#include "PgRuntime.h"', '', 'namespace pg {', '']
    cpp = banner + ['#include "PgStructs.h"', '', 'namespace pg {', '']
    for c in structs:
        hdr += gen.decl_class(gen.classes[c]) + ['']
        cpp += gen.def_class(gen.classes[c])
    hdr += ['}  // namespace pg', '', '#endif', '']
    cpp += ['}  // namespace pg']
    write_text(os.path.join(out_dir, 'PgStructs.h'), hdr, created)
    write_text(os.path.join(out_dir, 'PgStructs.cpp'), cpp, created)

    packets = doc['packets']
    by_domain = {}
    for p in packets:
        by_domain.setdefault(p['domain'], []).append(p['name'])
    dom_of = {p['name']: p['domain'] for p in packets}
    dom_deps = {}
    for dom, names in by_domain.items():
        dd = set()
        for nm in names:
            for dep in gen.classes[nm].deps:
                if gen.classes[dep].kind == 'packet' and dom_of[dep] != dom:
                    dd.add(dom_of[dep])
        dom_deps[dom] = dd
    dom_order = topo(sorted(by_domain), dom_deps)
    for dom in dom_order:
        names = sorted(by_domain[dom], key=lambda nm: (gen.packets[nm]['proto'], gen.packets[nm]['id']))
        names = topo(names, {nm: gen.classes[nm].deps for nm in names})
        guard = 'CYS_PROTOCOLGEN_PGPACKETS_%s_H' % dom.upper()
        hdr = banner + ['#ifndef ' + guard, '#define ' + guard, '', '#include "PgStructs.h"']
        hdr += ['#include "PgPackets_%s.h"' % d for d in sorted(dom_deps[dom])]
        hdr += ['', 'namespace pg {', '']
        cpp = banner + ['#include "PgPackets_%s.h"' % dom, '', 'namespace pg {', '']
        for nm in names:
            hdr += gen.decl_class(gen.classes[nm]) + ['']
            cpp += gen.def_class(gen.classes[nm])
        hdr += ['}  // namespace pg', '', '#endif', '']
        cpp += ['}  // namespace pg']
        write_text(os.path.join(out_dir, 'PgPackets_%s.h' % dom), hdr, created)
        write_text(os.path.join(out_dir, 'PgPackets_%s.cpp' % dom), cpp, created)

    # ids
    ids = banner + ['#ifndef CYS_PROTOCOLGEN_PGIDS_H', '#define CYS_PROTOCOLGEN_PGIDS_H', '', '#include <cstdint>', '',
                    'namespace pg {', 'namespace id {', '// Packet class name -> skynet id (game port 5734).',
                    'enum Game : uint16_t {']
    game = sorted([p for p in packets if p['proto'] == 'game'], key=lambda p: p['id'])
    login = sorted([p for p in packets if p['proto'] == 'login'], key=lambda p: p['id'])
    ids += ['    %s = %d,  // %s %s' % (p['name'], p['id'], p['dir'], p['const']) for p in game]
    ids += ['};', '// Login protocol (port 5733).', 'enum Login : uint16_t {']
    ids += ['    %s = %d,  // %s %s' % (p['name'], p['id'], p['dir'], p['const']) for p in login]
    ids += ['};', '}  // namespace id', '', 'namespace xyid {',
            '// Server constant names (services/game/packet_ids.lua, services/login/packet.lua).', 'enum Game : uint16_t {']
    seen = set()
    for p in game:
        if p['const'] not in seen:
            seen.add(p['const'])
            ids.append('    %s = %d,' % (p['const'], p['id']))
    for miss in (doc.get('issues') or {}).get('ids_without_codec', []):
        if miss['const'] not in seen:
            seen.add(miss['const'])
            ids.append('    %s = %d,  // no codec on the server' % (miss['const'], miss['id']))
    ids += ['};', 'enum Login : uint16_t {']
    seen = set()
    for p in login:
        if p['const'] not in seen:
            seen.add(p['const'])
            ids.append('    %s = %d,' % (p['const'], p['id']))
    ids += ['};', '}  // namespace xyid', '}  // namespace pg', '', '#endif', '']
    write_text(os.path.join(out_dir, 'PgIds.h'), ids, created)

    # factory table
    memo = {}
    conf = {'high': 'ConfHigh', 'medium': 'ConfMedium', 'low': 'ConfLow'}
    dec_name = {2: 'DecFull', 1: 'DecPartial', 0: 'DecNone'}
    rows = sorted(packets, key=lambda p: (0 if p['proto'] == 'game' else 1, p['id']))
    tab = banner + ['#include "PgFactory.h"', '']
    tab += ['#include "PgPackets_%s.h"' % d for d in dom_order]
    tab += ['', 'namespace pg {', 'namespace detail {', 'namespace {', 'template <class T>',
            'Packet* make() { return new T(); }', 'const PacketInfo kPackets[] = {']
    for p in rows:
        ci = gen.classes[p['name']]
        size = p.get('size') or {}
        mx = size.get('max')
        tab.append('    {%d, Proto::%s, Dir::%s, %s, %s, %d, %uu, %su, "%s", "%s", "%s", &make<%s>},' % (
            p['id'], 'Login' if p['proto'] == 'login' else 'Game', p['dir'], conf[p['confidence']],
            dec_name[gen.decodability(p['name'], memo)], len(ci.cov['selectors']), size.get('min') or 0,
            str(mx) if mx is not None else '0xFFFFFFFF', p['name'], p['const'], p['domain'], p['name']))
    tab += ['};', '}  // namespace', '',
            'const PacketInfo* tableData(size_t* count) {',
            '    if (count) *count = sizeof(kPackets) / sizeof(kPackets[0]);',
            '    return kPackets;', '}', '}  // namespace detail', '}  // namespace pg']
    write_text(os.path.join(out_dir, 'PgFactoryTable.cpp'), tab, created)

    # umbrella
    counts = {}
    for p in packets:
        k = dec_name[gen.decodability(p['name'], memo)]
        counts[k] = counts.get(k, 0) + 1
    um = banner + ['// Umbrella header of the ProtocolGen library (target cys_protocolgen).',
                   '#ifndef CYS_PROTOCOLGEN_PROTOCOLGEN_H', '#define CYS_PROTOCOLGEN_PROTOCOLGEN_H', '',
                   '#include "PgRuntime.h"', '#include "PgIds.h"', '#include "PgStructs.h"']
    um += ['#include "PgPackets_%s.h"' % d for d in dom_order]
    um += ['#include "PgFactory.h"', '', 'namespace pg {',
           'const char* const kSpecGenerated = "%s";' % asc(doc.get('generated')),
           'const char* const kSpecSha256 = "%s";' % sha,
           'const unsigned kPacketCount = %d;' % len(packets),
           'const unsigned kStructClassCount = %d;' % len(structs),
           '}  // namespace pg', '', '#endif', '']
    write_text(os.path.join(out_dir, 'ProtocolGen.h'), um, created)

    # coverage
    cov = ['kind\tproto\tdir\tid\tname\tdomain\tconfidence\tdecodability\tselectors\tmerged\tundecodable\tnotes']
    for p in rows:
        ci = gen.classes[p['name']]
        cov.append('\t'.join(asc(x) for x in (
            'packet', p['proto'], p['dir'], str(p['id']), p['name'], p['domain'], p['confidence'],
            dec_name[gen.decodability(p['name'], memo)], ', '.join(ci.cov['selectors']), ', '.join(ci.cov['merged']),
            ', '.join(ci.cov['undecodable']), '; '.join(ci.cov['notes']))))
    for c in structs:
        ci = gen.classes[c]
        cov.append('\t'.join(asc(x) for x in (
            'struct', '', '', '', c, ci.spec.get('domain', ''), '', dec_name[gen.decodability(c, memo)],
            ', '.join(ci.cov['selectors']), ', '.join(ci.cov['merged']), ', '.join(ci.cov['undecodable']),
            '; '.join(ci.cov['notes']))))
    write_text(os.path.join(out_dir, 'PgCoverage.tsv'), cov, created)

    nsel = sum(len(gen.classes[c].cov['selectors']) for c in gen.classes)
    nmerge = sum(len(gen.classes[c].cov['merged']) for c in gen.classes)
    nundec = sum(len(gen.classes[c].cov['undecodable']) for c in gen.classes)
    summary = ('codegen_cpp: %d packets + %d struct classes (%d spec structs) -> %s; %d files; selectors %d, '
               'merged %d, undecodable points %d; packets %s' % (
                   len(packets), len(structs), len(doc['structs']), out_dir, len(created), nsel, nmerge, nundec,
                   ', '.join('%s %d' % kv for kv in sorted(counts.items()))))
    if not quiet:
        print(summary)
        for cls, line, sel, source, whens, why in gen.unresolved_log:
            print('  selector %-28s L%-5s %-24s %-18s %s' % (cls, line, sel, source, asc(whens)[:90]))
    return gen, summary


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--spec', default=SPEC)
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--quiet', action='store_true')
    a = ap.parse_args(argv)
    generate(a.spec, a.out, a.quiet)
    return 0


if __name__ == '__main__':
    sys.exit(main())
