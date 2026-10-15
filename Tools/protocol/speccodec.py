"""speccodec.py - reference decoder / encoder driven by Registry/protocol/packets.json.

Interprets the spec tree directly (no code generation), so it is the oracle for
generated codecs and for byte-exact round trips on captured traffic:

    spec = Spec()                          # loads packets.json
    vals, used = spec.decode('CGCharMove', body)
    assert spec.encode('CGCharMove', vals) == body
"""
import json
import os
import re
import struct

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_JSON = os.path.abspath(os.path.join(HERE, '..', '..', 'Registry', 'protocol', 'packets.json'))
FMT = {'u8': '<B', 'i8': '<b', 'bool': '<B', 'u16': '<H', 'i16': '<h', 'u32': '<I', 'i32': '<i',
       'f32': '<f', 'u64': '<Q'}
PREFIX = {'str8': 'u8', 'str16': 'u16', 'str32': 'u32'}


class DecodeError(Exception):
    pass


class Unsupported(DecodeError):
    pass


# ------------------------------------------------------------------ conditions
_TOK = re.compile(r'\s*(?:(0[xX][0-9a-fA-F]+|\d+\.\d*(?:[eE][+-]?\d+)?|\d+)|("(?:[^"\\]|\\.)*")|'
                  r'(\$?[A-Za-z_][A-Za-z0-9_]*)|(==|!=|<=|>=|<<|>>|&&|\|\||//|\*\*|\.\.|[-+*/%<>!&|^~#()\[\],.]))')
_BIN = {'||': (1, 1), '&&': (2, 2), '==': (3, 3), '!=': (3, 3), '<': (3, 3), '<=': (3, 3), '>': (3, 3),
        '>=': (3, 3), '|': (4, 4), '^': (5, 5), '&': (6, 6), '<<': (7, 7), '>>': (7, 7), '..': (9, 8),
        '+': (10, 10), '-': (10, 10), '*': (11, 11), '/': (11, 11), '//': (11, 11), '%': (11, 11),
        '**': (14, 13)}
_CACHE = {}


def _tokens(s):
    out, pos = [], 0
    while pos < len(s):
        m = _TOK.match(s, pos)
        if not m or m.end() == pos:
            if s[pos:].strip() == '':
                break
            raise Unsupported('cannot parse condition %r at %d' % (s, pos))
        pos = m.end()
        if m.group(1):
            t = m.group(1)
            out.append(('num', int(t, 0) if not ('.' in t or 'e' in t.lower() and not t.lower().startswith('0x'))
                        else float(t)))
        elif m.group(2):
            out.append(('str', json.loads(m.group(2))))
        elif m.group(3):
            out.append(('name', m.group(3)))
        else:
            out.append(('op', m.group(4)))
    out.append(('end', None))
    return out


class _P(object):
    def __init__(self, toks):
        self.t, self.i = toks, 0

    def peek(self):
        return self.t[self.i]

    def take(self):
        tok = self.t[self.i]
        self.i += 1
        return tok

    def expr(self, limit=0):
        k, v = self.peek()
        if k == 'op' and v in ('!', '-', '#', '~'):
            self.take()
            left = ('un', v, self.expr(12))
        else:
            left = self.primary()
        while True:
            k, v = self.peek()
            if k != 'op' or v not in _BIN or _BIN[v][0] <= limit:
                return left
            self.take()
            left = ('bin', v, left, self.expr(_BIN[v][1]))

    def primary(self):
        k, v = self.take()
        if k == 'num' or k == 'str':
            node = ('lit', v)
        elif k == 'name':
            if v in ('nil', 'true', 'false'):
                return ('lit', {'nil': None, 'true': True, 'false': False}[v])
            node = ('ref', [('name', v)])
        elif k == 'op' and v == '(':
            node = self.expr()
            if self.take() != ('op', ')'):
                raise Unsupported('missing )')
        else:
            raise Unsupported('unexpected %r' % (v,))
        while True:
            k, v = self.peek()
            if k == 'op' and v == '.':
                self.take()
                k2, v2 = self.take()
                node = ('ref', (node[1] if node[0] == 'ref' else [('val', node)]) + [('name', v2)])
            elif k == 'op' and v == '[':
                self.take()
                idx = self.expr()
                self.take()
                node = ('ref', (node[1] if node[0] == 'ref' else [('val', node)]) + [('idx', idx)])
            elif k == 'op' and v == '(':
                self.take()
                args = []
                if self.peek() != ('op', ')'):
                    while True:
                        args.append(self.expr())
                        if self.peek() == ('op', ','):
                            self.take()
                            continue
                        break
                self.take()
                node = ('call', node, args)
            else:
                return node


def parse_cond(s):
    if s not in _CACHE:
        p = _P(_tokens(s))
        _CACHE[s] = p.expr()
    return _CACHE[s]


class WireBool(int):
    """A wire value that carries a server-side boolean: type `bool` (writebool writes 0/1) or a field
    written as `(x and 1) or 0`. The server's conditions test the boolean, so 0 is false here, while
    every other number stays truthy as in Lua."""


_BOOLIZED = re.compile(r'^\(\s*([A-Za-z_][\w.]*)\s*&&\s*1\s*\)\s*\|\|\s*0$')


def _is_wire_bool(n):
    if n.get('type') == 'bool':
        return True
    m = _BOOLIZED.match((n.get('expr') or '').strip())
    return bool(m) and m.group(1) == n.get('name')


def _flatkey(parts):
    """Reference parts -> flat display name of fields / length variables, indices kept (x[i].y)."""
    out = ''
    for kind, arg in parts:
        if kind == 'name':
            out += ('.' if out else '') + arg
        elif kind == 'idx' and arg[0] == 'lit' and isinstance(arg[1], int) and not isinstance(arg[1], bool):
            out += '[%d]' % arg[1]
        elif kind == 'idx' and arg[0] == 'ref' and len(arg[1]) == 1 and arg[1][0][0] == 'name':
            out += '[%s]' % arg[1][0][1]
        else:
            return None
    return out


def _truthy(v):
    if isinstance(v, WireBool):
        return v != 0
    return v is not None and v is not False


class Env(object):
    def __init__(self, parent=None, lenient=None):
        self.parent = parent
        self.vars = {}
        # lenient: unknown names read as 0 (used to synthesise test bodies)
        self.lenient = parent.lenient if (lenient is None and parent is not None) else bool(lenient)

    def find(self, name):
        e = self
        while e is not None:
            if name in e.vars:
                return True, e.vars[name]
            e = e.parent
        return False, None

    def get(self, name):
        ok, v = self.find(name)
        if not ok:
            if self.lenient:
                return 0
            raise Unsupported('unknown name %r' % name)
        return v


def _ref(parts, env):
    head = parts[0]
    if head[0] == 'val':
        cur, i = evaluate(head[1], env), 1
    else:
        name = head[1]
        if name.startswith('$'):
            raise Unsupported('server-side local %s' % name)
        i = 1
        ok, cur = env.find(name)
        # greedy dotted names (fields are stored under their dotted display name)
        while i < len(parts) and parts[i][0] == 'name':
            ok2, v2 = env.find(name + '.' + parts[i][1])
            if not ok2:
                break
            name += '.' + parts[i][1]
            ok, cur = ok2, v2
            i += 1
        if not ok:
            if env.lenient:
                return 0
            raise Unsupported('unknown name %r' % name)
    for kind, arg in parts[i:]:
        if kind == 'name':
            if not isinstance(cur, dict):
                raise Unsupported('field %s of non-struct' % arg)
            cur = cur.get(arg)
        else:
            idx = evaluate(arg, env)
            if not isinstance(cur, list) or not isinstance(idx, int) or not 1 <= idx <= len(cur):
                return None
            cur = cur[idx - 1]
    return cur


def evaluate(node, env):
    k = node[0]
    if k == 'lit':
        return node[1]
    if k == 'ref':
        return _ref(node[1], env)
    if k == 'call':
        fn = node[1]
        fname = '.'.join(p[1] for p in fn[1]) if fn[0] == 'ref' else '?'
        args = [evaluate(a, env) for a in node[2]]
        f = {'math.floor': lambda x: int(x // 1), 'math.ceil': lambda x: -int(-x // 1), 'math.max': max,
             'math.min': min, 'math.abs': abs, 'tonumber': lambda x: x}.get(fname)
        if f is None:
            raise Unsupported('function %s' % fname)
        return f(*args)
    if k == 'un':
        op, a = node[1], node[2]
        if op == '#':
            if a[0] == 'ref' and a[1][0][0] == 'name':
                key = _flatkey(a[1])            # '#event[i].str' is the name the len variable is stored under
                ok, v = env.find('#' + key) if key else (False, None)
                if not ok:
                    ok, v = env.find('#' + '.'.join(p[1] for p in a[1] if p[0] == 'name'))
                if ok:
                    return v
            v = evaluate(a, env)
            if isinstance(v, (bytes, bytearray, str, list, dict)):
                return len(v)
            if v is None or (env.lenient and isinstance(v, int)):
                return 0
            raise Unsupported('length of %r' % (v,))
        v = evaluate(a, env)
        if op == '!':
            return not _truthy(v)
        if op == '-':
            return -v
        return ~v
    op, a = node[1], node[2]
    if op == '&&':
        x = evaluate(a, env)
        return evaluate(node[3], env) if _truthy(x) else x
    if op == '||':
        x = evaluate(a, env)
        return x if _truthy(x) else evaluate(node[3], env)
    x, y = evaluate(a, env), evaluate(node[3], env)
    try:
        return {'==': lambda: x == y, '!=': lambda: x != y, '<': lambda: x < y, '<=': lambda: x <= y,
                '>': lambda: x > y, '>=': lambda: x >= y, '|': lambda: x | y, '^': lambda: x ^ y,
                '&': lambda: x & y, '<<': lambda: x << y, '>>': lambda: x >> y, '+': lambda: x + y,
                '-': lambda: x - y, '*': lambda: x * y, '/': lambda: x / y, '//': lambda: x // y,
                '%': lambda: x % y, '**': lambda: x ** y, '..': lambda: '%s%s' % (x, y)}[op]()
    except TypeError:
        raise Unsupported('bad operands for %s: %r %r' % (op, x, y))


def cond_true(text, env):
    return text == 'else' or _truthy(evaluate(parse_cond(text), env))


# ------------------------------------------------------------------ derived server state
def _char_base_attrib_flags(env):
    """GCCharBaseAttrib: rebuild server-side m_uFlags[1..11] from the 14 wire bytes new_flags
    (combat.lua bos: bit 7 onwards is shifted up by one bit)."""
    nf = list(env.get('new_flags')) + [0] * 14
    m = [(nf[0] & 0x7F) | ((nf[1] & 1) << 7)]
    for i in range(1, 11):
        m.append((nf[i] >> 1) | ((nf[i + 1] & 1) << 7))
    env.vars['m_uFlags'] = m
    env.vars['dfeng_base_flags'] = nf[12]
    env.vars['dfeng_base_flags2'] = nf[13]


def _detail_attrib_pet_flags(env):
    """GCDetailAttrib_Pet: rebuild server-side m_Flags[1..11] (old 83-bit layout) from the 12
    wire bytes _nf (pet_detail_types.lua bos lines 791-810)."""
    nf = list(env.get('_nf')) + [0] * 12

    def bit(b):
        return (nf[b >> 3] >> (b & 7)) & 1
    m = [0] * 11
    for nb in range(96):
        if not bit(nb):
            continue
        if nb <= 1:
            ob = nb
        elif 3 <= nb <= 8:
            ob = nb - 1
        elif nb in (9, 10):
            ob = nb - 1              # hp / hp_max mirrors of old bits 8 / 9
        elif nb >= 13:
            ob = nb - 3
        else:
            continue
        if ob < 88:
            m[ob >> 3] |= 1 << (ob & 7)
    env.vars['m_Flags'] = m
    env.vars['_has_rage'] = bool(bit(11))
    env.vars['_has_rage_max'] = bool(bit(12))
    env.vars['_elf_flag'] = bool(bit(90))
    env.vars['elf_slots'] = bool(bit(90))
    # optional stall/exchange view tail: only present when the server attached extra_data
    env.vars.setdefault('extra_data', None)


DERIVE = {'char_base_attrib_flags': ('new_flags', _char_base_attrib_flags),
          'detail_attrib_pet_flags': ('_nf', _detail_attrib_pet_flags)}


# ------------------------------------------------------------------ codec
class _R(object):
    def __init__(self, buf):
        self.buf, self.pos = buf, 0

    def take(self, n):
        if n < 0 or self.pos + n > len(self.buf):
            raise DecodeError('short read: need %d at %d, have %d' % (n, self.pos, len(self.buf) - self.pos))
        b = self.buf[self.pos:self.pos + n]
        self.pos += n
        return b


class Spec(object):
    def __init__(self, path=DEFAULT_JSON):
        with open(path, encoding='utf-8') as f:
            self.doc = json.load(f)
        self._derive = None
        self._trace = None
        self.by_name = {p['name']: p for p in self.doc['packets']}
        self.by_id = {}
        for p in self.doc['packets']:
            self.by_id.setdefault((p['proto'], p['id']), p)
        self.structs = {s['name']: s for s in self.doc['structs']}

    def packet(self, name_or_id, proto='game'):
        if isinstance(name_or_id, int):
            return self.by_id.get((proto, name_or_id))
        return self.by_name.get(name_or_id)

    def struct_fields(self, name, codec):
        s = self.structs.get(name)
        if s is not None:
            v = s.get(codec) or s.get('bos' if codec == 'bis' else 'bis')
            return v['fields'] if v else []
        p = self.by_name.get(name)
        if p is not None:
            return p['fields']
        raise Unsupported('unknown struct %s' % name)

    # ---------------- decode
    def decode(self, packet, body):
        p = packet if isinstance(packet, dict) else self.by_name[packet]
        env = Env()
        env.vars['#__body__'] = len(body)
        self._derive = DERIVE.get(p.get('derive'))
        rd = _R(body)
        try:
            self._dec(p['fields'], env, rd)
        finally:
            self._derive = None
        return env.vars, rd.pos

    def _count(self, n, env):
        if 'count' in n:
            return n['count']
        if 'count_field' in n:
            v = env.get(n['count_field'])
        else:
            v = evaluate(parse_cond(n['count_expr']), env)
        if not isinstance(v, int):
            raise Unsupported('array count %r' % (v,))
        return v

    def _len(self, n, env):
        if 'len_field' in n:
            v = env.get(n['len_field'])
        else:
            v = evaluate(parse_cond(n.get('len_expr') or '?'), env)
        if not isinstance(v, int):
            raise Unsupported('byte length %r' % (v,))
        return v

    def _dec_value(self, t, n, env, rd):
        if t in FMT:
            return struct.unpack(FMT[t], rd.take(struct.calcsize(FMT[t])))[0]
        m = re.match(r'bytes\[(\d+)\]$', t)
        if m:
            return rd.take(int(m.group(1)))
        if t == 'bytes[]':
            ln = self._len(n, env)
            return rd.take(min(ln, n['clamp']) if 'clamp' in n else ln)
        if t in PREFIX:
            pt = PREFIX[t] if not n.get('len_signed') else 'i' + PREFIX[t][1:]
            ln = struct.unpack(FMT[pt], rd.take(struct.calcsize(FMT[pt])))[0]
            if n.get('len_name'):
                env.vars[n['len_name']] = ln
            if 'guard' in n and not cond_true(n['guard'], env):
                return b''
            return rd.take(min(ln, n['clamp']) if 'clamp' in n else ln)
        if t.startswith('struct '):
            sub = Env(env)
            self._dec(self.struct_fields(t[7:], n.get('codec', 'bis')), sub, rd)
            return sub.vars
        raise Unsupported('type %s' % t)

    def _dec(self, fields, env, rd):
        for n in fields:
            kind = n.get('kind')
            if kind is None:
                t = n['type']
                if t.startswith('array<'):
                    cnt = self._count(n, env)
                    env.vars[n.get('name') or ''] = [self._dec_value(t[6:-1], n, env, rd) for _ in range(cnt)]
                else:
                    v = self._dec_value(t, n, env, rd)
                    if isinstance(v, int) and _is_wire_bool(n):
                        v = WireBool(v)
                    if n.get('name') is not None:
                        env.vars[n['name']] = v
                        if self._derive is not None and n['name'] == self._derive[0]:
                            self._derive[1](env)
            elif kind == 'if':
                for br in n['branches']:
                    if cond_true(br['when'], env):
                        self._dec(br['fields'], env, rd)
                        break
            elif kind == 'array' and 'fields' not in n:
                cnt = self._count(n, env)
                el_t = n['type'][6:-1]
                vals = [self._dec_value(el_t, n, env, rd) for _ in range(cnt)]
                if n.get('name'):
                    env.vars[n['name']] = vals
                if self._derive is not None and n.get('name') == self._derive[0]:
                    self._derive[1](env)
            elif kind == 'array':
                cnt = self._count(n, env)
                items = []
                if n.get('name'):
                    env.vars[n['name']] = items
                for i in range(1, cnt + 1):
                    el = Env(env)
                    if n.get('var'):
                        el.vars[n['var']] = i
                    self._dec(n['fields'], el, rd)
                    el.vars.pop(n.get('var'), None)
                    items.append(el.vars)
            elif kind == 'blob':
                if 'len_type' in n:
                    ln = struct.unpack(FMT[n['len_type']], rd.take(struct.calcsize(FMT[n['len_type']])))[0]
                    if n.get('len_name'):
                        env.vars[n['len_name']] = ln
                else:
                    ln = self._len(n, env)
                sub = _R(rd.take(ln))
                inner = Env(env)
                self._dec(n['fields'], inner, sub)
                if sub.pos != len(sub.buf):
                    raise DecodeError('blob %s: %d trailing bytes' % (n.get('name'), len(sub.buf) - sub.pos))
                env.vars[n.get('name') or 'blob'] = inner.vars
            else:
                raise Unsupported('%s node at line %s' % (kind, n.get('line')))

    # ---------------- encode
    def encode(self, packet, values, trace=None, lenient=False):
        """values -> body.  `trace` (list) receives (offset, size, name, type) per primitive;
        lenient=True treats missing values/condition names as 0 (synthetic test bodies)."""
        p = packet if isinstance(packet, dict) else self.by_name[packet]
        env = Env(lenient=lenient)
        env.vars.update(values)
        out = bytearray()
        self._trace = trace
        try:
            self._enc(p['fields'], env, out)
        finally:
            self._trace = None
        return bytes(out)

    def _tr(self, start, out, n, t):
        if getattr(self, '_trace', None) is not None and len(out) > start:
            self._trace.append((start, len(out) - start, n.get('name'), t))

    def _enc_value(self, t, n, v, env, out):
        start = len(out)
        try:
            self._enc_value2(t, n, v, env, out)
        finally:
            if t in FMT or t.startswith('bytes'):
                self._tr(start, out, n, t)

    def _enc_value2(self, t, n, v, env, out):
        if t in FMT:
            if 'const' in n and not isinstance(n['const'], str):
                v = n['const']
            elif v is None:
                v = n.get('default', 0)
            if isinstance(v, bool):
                v = int(v)
            if isinstance(v, str):
                v = 0
            out += struct.pack(FMT[t], v)
            return
        m = re.match(r'bytes\[(\d+)\]$', t)
        if m:
            b = v if isinstance(v, (bytes, bytearray)) else (v or '').encode('utf-8')
            size = int(m.group(1))
            out += bytes(b[:size]).ljust(size, b'\0')
            return
        if t == 'bytes[]':
            b = v if isinstance(v, (bytes, bytearray)) else (v or '').encode('utf-8')
            ln = self._len(n, env)
            ln = min(ln, n['clamp']) if 'clamp' in n else ln
            out += bytes(b[:ln]).ljust(ln, b'\0')
            return
        if t in PREFIX:
            b = v if isinstance(v, (bytes, bytearray)) else (v or '').encode('utf-8')
            known = n.get('len_name') and env.find(n['len_name'])[0]
            ln = env.find(n['len_name'])[1] if known else len(b)
            pt = PREFIX[t] if not n.get('len_signed') else 'i' + PREFIX[t][1:]
            s0 = len(out)
            out += struct.pack(FMT[pt], ln)
            self._tr(s0, out, {'name': n.get('len_name')}, pt)
            if n.get('len_name'):
                env.vars[n['len_name']] = ln
            if 'guard' not in n or cond_true(n['guard'], env):
                s1 = len(out)
                take = min(ln, n['clamp']) if 'clamp' in n else ln
                out += bytes(b[:take]).ljust(take, b'\0')
                self._tr(s1, out, n, 'bytes')
            return
        if t.startswith('struct '):
            sub = Env(env)
            sub.vars.update(v or {})
            self._enc(self.struct_fields(t[7:], n.get('codec', 'bis')), sub, out)
            return
        raise Unsupported('type %s' % t)

    def _enc(self, fields, env, out):
        for n in fields:
            kind = n.get('kind')
            if kind is None:
                t = n['type']
                name = n.get('name')
                v = env.find(name)[1] if name is not None else None
                if t.startswith('array<'):
                    items = v or []
                    cnt = self._count(n, env) if ('count' in n or 'count_field' in n) else len(items)
                    for i in range(cnt):
                        self._enc_value(t[6:-1], n, items[i] if i < len(items) else None, env, out)
                else:
                    self._enc_value(t, n, v, env, out)
                    if name is not None and _is_wire_bool(n) and not isinstance(v, WireBool):
                        # later conditions test the server-side boolean that went out as 0/1
                        env.vars[name] = WireBool(int(v) if isinstance(v, (int, bool)) else int(n.get('default') or 0))
            elif kind == 'if':
                for br in n['branches']:
                    if cond_true(br['when'], env):
                        self._enc(br['fields'], env, out)
                        break
            elif kind == 'array' and 'fields' not in n:
                items = env.find(n.get('name') or '')[1] or []
                cnt = self._count(n, env)
                el = dict(n.get('element') or {})
                el.update({'type': n['type'][6:-1], 'codec': n.get('codec')})
                for i in range(cnt):
                    self._enc_value(el['type'], el, items[i] if i < len(items) else None, env, out)
            elif kind == 'array':
                items = env.find(n.get('name') or '')[1] or []
                cnt = self._count(n, env)
                for i in range(1, cnt + 1):
                    el = Env(env)
                    el.vars.update(items[i - 1] if i - 1 < len(items) else {})
                    if n.get('var'):
                        el.vars[n['var']] = i
                    self._enc(n['fields'], el, out)
            elif kind == 'blob':
                inner = Env(env)
                inner.vars.update(env.find(n.get('name') or 'blob')[1] or {})
                sub = bytearray()
                t0 = len(self._trace) if self._trace is not None else 0
                self._enc(n['fields'], inner, sub)
                s0 = len(out)
                if 'len_type' in n:
                    out += struct.pack(FMT[n['len_type']], len(sub))
                if self._trace is not None:
                    base = len(out)
                    for k in range(t0, len(self._trace)):
                        o, s, nm, ty = self._trace[k]
                        self._trace[k] = (o + base, s, nm, ty)
                    if 'len_type' in n:
                        self._trace.insert(t0, (s0, base - s0, n.get('len_name'), n['len_type']))
                out += sub
            else:
                raise Unsupported('%s node' % kind)
