"""extract_expr.py - value model + expression evaluation for the symbolic codec
extractor (see extract_stmt.py).  CY-Source/Tools/protocol."""
import json

from luaparse import BINPRI, to_lua
from luaconst import fold, NotConst, NOT_CONST

READ_TYPES = {
    'readuchar': 'u8', 'readchar': 'i8', 'readbool': 'bool', 'readushort': 'u16',
    'readshort': 'i16', 'readuint': 'u32', 'readint': 'i32', 'readfloat': 'f32',
    'readulong': 'u64', 'readuint8': 'u64'}
WRITE_TYPES = {
    'writeuchar': 'u8', 'writechar': 'i8', 'writebool': 'bool', 'writeushort': 'u16',
    'writeshort': 'i16', 'writeuint': 'u32', 'writeint': 'i32', 'writefloat': 'f32',
    'writeulong': 'u64', 'writehex': 'i16'}
# methods that do not exist on bistream (they raise at run time)
TYPOS = {'readuhcar': ('u8', 'readuchar'), 'readlfoat': ('f32', 'readfloat')}
SIZES = {'u8': 1, 'i8': 1, 'bool': 1, 'u16': 2, 'i16': 2, 'u32': 4, 'i32': 4,
         'f32': 4, 'u64': 8}
INT_TYPES = frozenset(('u8', 'i8', 'u16', 'i16', 'u32', 'i32'))

TEXT_FUNCS = frozenset(('gbk.fromutf8', 'gbk.toutf8', 'gbk.truncate_utf8_bytes'))
LEN_FUNCS = frozenset(('string.len', 'utf8.len', 'gbk.len'))
TRANSFORMS = frozenset((
    'tonumber', 'tostring', 'math.floor', 'math.ceil', 'math.max', 'math.min', 'math.abs',
    'math.tointeger', 'math.fmod', 'string.sub', 'string.char', 'string.byte',
    'string.format', 'string.match', 'string.gsub', 'string.lower', 'string.upper',
    'table.concat', 'table.unpack', 'assert', 'type', 'select', 'rawget', 'next',
    'gbk.byte', 'gbk.char'))
LIB_ALIAS = {'iostream.bistream': 'bistream', 'iostream.bostream': 'bostream'}
C_OP = {'and': '&&', 'or': '||', '~=': '!=', '~': '^', '^': '**'}
BITWISE = frozenset(('&', '|', '~', '<<', '>>'))
CMP = frozenset(('<', '<=', '>', '>=', '==', '~='))
FLIP = {'<': '>', '<=': '>=', '>': '<', '>=': '<=', '==': '==', '~=': '~='}


def const_text(v):
    if v is True:
        return 'true'
    if v is False:
        return 'false'
    if v is None:
        return 'nil'
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        return repr(v)
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    return '{...}'


def is_num(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


class V(object):
    """Symbolic value.  kinds: const path node len stream blob buffer struct_new
    struct_blob func lib pkt pktm define index expr opq"""
    __slots__ = ('kind', 'root', 'path', 'value', 'node', 'stream', 'inner', 'text',
                 'default', 'is_text', 'func', 'scope', 'name', 'see', 'loop', 'struct', 'wire')

    def __init__(self, kind, **kw):
        for s in V.__slots__:
            object.__setattr__(self, s, None)
        self.kind = kind
        for k, v in kw.items():
            object.__setattr__(self, k, v)


NIL = V('const', value=None)


class Loop(object):
    _next = [0]

    def __init__(self, kind, line, var=None):
        Loop._next[0] += 1
        self.id = Loop._next[0]
        self.kind = kind          # for ipairs pairs while
        self.line = line
        self.var = var
        self.array = None         # (root, segs)
        self.count = None
        self.count_key = None
        self.count_text = None
        self.count_node = None
        self.count_wire = None
        self.bounds = (None, None)
        self.notes = []
        self.scope_depth = 0
        self.name = None
        self.cands = {}           # (root, segs) -> references, used when nothing is emitted


class Stream(object):
    def __init__(self, sid, kind, name, line):
        self.sid = sid
        self.kind = kind          # in out param
        self.name = name
        self.line = line
        self.attached = False
        self.returned = False
        self.embedded = False


class Scope(object):
    _next = [0]

    def __init__(self, parent=None):
        Scope._next[0] += 1
        self.id = Scope._next[0]
        self.parent = parent
        self.vars = {}
        self.depth = parent.depth + 1 if parent is not None else 0

    def lookup(self, name):
        s = self
        while s is not None:
            if name in s.vars:
                return s.vars[name], s
            s = s.parent
        return None, None


class Frame(object):
    __slots__ = ('out', 'status')

    def __init__(self):
        self.out = {}
        self.status = None


class ExprMixin(object):
    """Needs: ids, define_tree, tables, self_table, frames, loop_stack, cond_stack,
    via_stack, keymap, values, streams, notes, errors, pure, cond_refs, tmp_counter."""

    # ------------------------------------------------------------ naming
    def seg_text(self, s):
        if isinstance(s, tuple):
            return '[%s]' % (s[1].var or 'i')
        return s

    def join_segs(self, segs):
        out = ''
        for s in segs:
            t = self.seg_text(s)
            if t.startswith('['):
                out += t
            elif out:
                out += '.' + t
            else:
                out = t
        return out

    def disp(self, v):
        """Field name of a value, relative to the innermost active array element."""
        if v is None:
            return None
        k = v.kind
        if k == 'path':
            segs = list(v.path)
            if v.root[0] == 'elem':
                return self.join_segs(segs)
            for j in range(len(segs) - 1, -1, -1):
                s = segs[j]
                if isinstance(s, tuple) and s[1] in self.loop_stack:
                    L = s[1]
                    if L.array is not None and L.array == (v.root, tuple(segs[:j])):
                        return self.join_segs(segs[j + 1:])
            if v.root[0] in ('tmp', 'param'):
                return self.join_segs([v.root[1]] + segs)
            return self.join_segs(segs)
        if k == 'node':
            return v.node.get('name')
        if k == 'len':
            n = self.disp(v.inner)
            return '#' + n if n else None
        if k == 'expr':
            if v.name and not v.see:
                return v.name
            return self.disp(v.inner) if v.inner is not None else None
        if k == 'blob':
            return v.stream.name
        if k == 'opq':
            return v.text
        if k == 'buffer':
            return '__body__'
        return None

    def is_wire(self, v):
        """True if the value can be computed by the receiver from earlier wire fields."""
        if v is None:
            return False
        k = v.kind
        if k in ('const', 'node', 'buffer', 'index'):
            return True
        if self.keymap.get(self.vkey(v)) is not None:
            return True
        if k == 'len':
            return self.is_wire(v.inner)
        if k == 'expr':
            if v.wire is not None:
                return v.wire
            return v.see and v.inner is not None and self.is_wire(v.inner)
        return False

    def vkey(self, v):
        """Identity key used to link a length/count to the field that carries it."""
        if v is None:
            return None
        k = v.kind
        if k == 'const':
            return 'c:%r' % (v.value,)
        if k == 'path':
            r = v.root
            if r[0] == 'self':
                rt = 'self'
            elif r[0] == 'elem':
                rt = 'elem%d' % r[1].id
            else:
                rt = '%s:%s' % r
            return rt + '/' + '/'.join('[]' if isinstance(s, tuple) else s for s in v.path)
        if k == 'node':
            return 'n#%d' % v.node['_id']
        if k == 'len':
            return '#' + (self.vkey(v.inner) or '?')
        if k in ('blob', 'stream'):
            return '%s#%d' % (k[0], v.stream.sid)
        if k == 'expr':
            if v.see and v.inner is not None:
                return self.vkey(v.inner)
            return 'x:%s' % v.text
        if k == 'index':
            return 'i#%d' % v.loop.id
        if k == 'opq':
            return 'o:%s' % v.name
        if k == 'buffer':
            return 'buffer'
        return '%s:%d' % (k, id(v))

    def vtext(self, v):
        if v is None:
            return '?'
        k = v.kind
        if k == 'const':
            return v.text or const_text(v.value)
        if k in ('path', 'node', 'len', 'blob'):
            d = self.disp(v)
            return d if d else '[]'
        if k == 'expr':
            if v.text:
                return v.text
            return self.vtext(v.inner) if v.inner is not None else '?'
        if k == 'index':
            return v.loop.var or 'i'
        if k == 'opq':
            return '$' + v.text
        return '?'

    # ------------------------------------------------------------ rendering (C-like)
    def render(self, e, scope):
        k = e.kind
        if k == 'Number':
            return e.raw or repr(e.value)
        if k == 'String':
            return json.dumps(e.value, ensure_ascii=False)
        if k in ('Nil', 'True', 'False'):
            return k.lower()
        if k == 'Paren':
            return '(%s)' % self.render(e.expr, scope)
        if k == 'UnOp':
            inner = self.render(e.operand, scope)
            if e.operand.kind == 'BinOp':
                inner = '(%s)' % inner
            return {'not': '!', '#': '#', '-': '-', '~': '~'}[e.op] + inner
        if k == 'BinOp':
            left = self.render(e.left, scope)
            right = self.render(e.right, scope)
            if self._paren(e.left, e.op, False):
                left = '(%s)' % left
            if self._paren(e.right, e.op, True):
                right = '(%s)' % right
            return '%s %s %s' % (left, C_OP.get(e.op, e.op), right)
        if k in ('Name', 'Index'):
            return self.vrender(self.ev_pure(e, scope), e)
        if k == 'Call':
            fname = to_lua(e.func)
            args = [self.render(a, scope) for a in e.args]
            if fname in LEN_FUNCS and args:
                return '#' + args[0]
            if (fname in ('tonumber', 'tostring') or fname in TEXT_FUNCS) and args:
                return args[0]
            return '%s(%s)' % (fname, ', '.join(args))
        if k == 'MethodCall':
            return '%s:%s(%s)' % (self.render(e.obj, scope), e.method,
                                  ', '.join(self.render(a, scope) for a in e.args))
        return to_lua(e)

    def vrender(self, v, e=None):
        k = v.kind
        if k == 'const':
            if v.text:
                return v.text
            if v.value is None or isinstance(v.value, (int, float, bool, str)):
                return const_text(v.value)
        if k in ('path', 'node', 'len', 'blob', 'expr', 'opq'):
            node = v.node if k == 'node' else self.keymap.get(self.vkey(v))
            if node is not None and node.get('name'):
                if self.cond_refs is not None:
                    self.cond_refs.append(node)
                return node['name']
        if k == 'path':
            key = self.vkey(v)
            val = self.values.get(key)
            fresh_table = (val is not None and val.kind == 'path' and val.root[0] in ('tmp', 'elem')
                           and not val.path)
            if (val is not None and val is not v and not fresh_table and key not in self._vr_guard
                    and not self.values_selfref.get(key) and val.kind in ('expr', 'len', 'const', 'path')):
                # server-side value computed in the codec (not on the wire): show how it is derived
                if self.values_cond.get(key):
                    return '$' + (self.disp(v) or '?')
                self._vr_guard.add(key)
                try:
                    return '(%s)' % self.vrender(val)
                finally:
                    self._vr_guard.discard(key)
        if k in ('path', 'node', 'len', 'blob'):
            self.note_ref(v)
            d = self.disp(v)
            if d is not None:
                return d if d != '' else '[]'
        if k == 'buffer':
            return '__body__'
        if k == 'expr':
            if v.text:
                return '(%s)' % v.text
            if v.see and v.inner is not None:
                return self.vrender(v.inner)
        if k == 'index':
            return v.loop.var or 'i'
        if k == 'opq':
            return '$' + v.text
        return to_lua(e) if e is not None else '?'

    def _paren(self, child, op, is_right):
        if child.kind != 'BinOp':
            return False
        c = child.op
        if c in BITWISE or op in BITWISE:
            return c != op or is_right
        if op in ('and', 'or') and c in ('and', 'or'):
            return c != op
        cp, pp = BINPRI[c][0], BINPRI[op][0]
        if cp != pp:
            return cp < pp
        return is_right != (BINPRI[op][1] < BINPRI[op][0])

    def note_ref(self, v):
        if self.cond_refs is None:
            return
        node = v.node if v.kind == 'node' else self.keymap.get(self.vkey(v))
        if node is not None:
            self.cond_refs.append(node)

    def render_cond(self, cond, scope):
        self.cond_refs = []
        try:
            text = self.render(cond, scope)
            refs = self.cond_refs
        finally:
            self.cond_refs = None
        return text, refs

    # ------------------------------------------------------------ evaluation
    def ev_pure(self, e, scope):
        self.pure += 1
        try:
            return self.ev(e, scope)
        finally:
            self.pure -= 1

    def ev(self, e, scope, hint=None):
        k = e.kind
        if k == 'Number':
            return V('const', value=e.value, text=e.raw)
        if k == 'String':
            return V('const', value=e.value)
        if k == 'Nil':
            return NIL
        if k == 'True':
            return V('const', value=True)
        if k == 'False':
            return V('const', value=False)
        if k == 'Vararg':
            return V('expr', text='...')
        if k == 'Paren':
            return self.ev(e.expr, scope, hint)
        if k == 'Function':
            return V('func', func=e, scope=scope, name='<anon>')
        if k == 'Table':
            return self.ev_table(e, scope, hint)
        if k == 'Name':
            b, _ = scope.lookup(e.id)
            return b if b is not None else V('lib', name=e.id)
        if k == 'Index':
            o = self.ev(e.obj, scope)
            if e.key.kind == 'String':
                return self.index_value(o, e.key.value, None, e, scope)
            return self.index_value(o, None, self.ev(e.key, scope), e, scope)
        if k == 'Call':
            return self.ev_call(e, scope, hint)
        if k == 'MethodCall':
            return self.ev_method(e, scope, hint)
        if k == 'UnOp':
            inner = self.ev(e.operand, scope)
            if e.op == '#':
                return V('len', inner=inner)
            if inner.kind == 'const':
                try:
                    if e.op == '-':
                        return V('const', value=-inner.value)
                    if e.op == 'not':
                        return V('const', value=inner.value is None or inner.value is False)
                except TypeError:
                    pass
            return V('expr', inner=inner, text=self.render(e, scope), see=False)
        if k == 'BinOp':
            if e.op == 'or' and e.left.kind == 'BinOp' and e.left.op == 'and':
                # ternary idiom  a and b or c
                a_ast = e.left.left
                a = self.ev(a_ast, scope)
                b = self.ev(e.left.right, scope, hint)
                c = self.ev(e.right, scope)
                wire = self.is_wire(a) and self.is_wire(b) and self.is_wire(c)
                if (b.kind == 'const' and is_num(b.value) and c.kind != 'const' and a_ast.kind == 'BinOp'
                        and a_ast.op in ('>', '>=')):
                    ax, an = self.ev_pure(a_ast.left, scope), self.ev_pure(a_ast.right, scope)
                    if self.vkey(ax) == self.vkey(c) and an.kind == 'const' and an.value == b.value:
                        # clamp idiom  (x > N and N or x)  ==  min(x, N)
                        return V('expr', inner=c, see=True, text=self.render(e, scope),
                                 value=('clamp', b.value), wire=self.is_wire(c))
                if b.kind != 'const':
                    out = V('expr', inner=b, see=True, is_text=b.is_text)
                    if c.kind == 'const' and not isinstance(c.value, dict):
                        out.default = c.value
                    return out
                return V('expr', inner=a if a.kind != 'const' else None, see=False,
                         text=self.render(e, scope), wire=wire)
            if e.op == 'or':
                left = self.ev(e.left, scope, hint)
                right = self.ev(e.right, scope)
                if left.kind == 'const':
                    return right if (left.value is None or left.value is False) else left
                out = V('expr', inner=left, see=True, is_text=left.is_text)
                if right.kind == 'const' and not isinstance(right.value, dict):
                    out.default = right.value
                return out
            left = self.ev(e.left, scope, hint if e.op == 'and' else None)
            right = self.ev(e.right, scope)
            if left.kind == 'const' and right.kind == 'const':
                try:
                    return V('const', value=fold(e.op, left.value, right.value))
                except NotConst:
                    pass
            inner = None
            for cand in (left, right):
                if cand.kind in ('path', 'node', 'len', 'opq') or (
                        cand.kind == 'expr' and cand.inner is not None):
                    inner = cand
                    break
            return V('expr', inner=inner, text=self.render(e, scope), see=False,
                     wire=self.is_wire(left) and self.is_wire(right))
        return V('expr', text=to_lua(e))

    def index_value(self, o, kname, kv, e, scope):
        ok = o.kind
        if ok == 'expr' and o.see and o.inner is not None:
            return self.index_value(o.inner, kname, kv, e, scope)
        if ok == 'lib':
            if kname is None:
                return V('expr', text=to_lua(e))
            if o.name == 'packet':
                if kname in self.ids:
                    return V('const', value=self.ids[kname])
                return V('pkt', name=kname)
            if o.name == 'define':
                return self.define_lookup((kname,))
            full = o.name + '.' + kname
            return V('lib', name=LIB_ALIAS.get(full, full))
        if ok == 'define':
            return self.define_lookup(o.path + ((kname if kname is not None else self.vtext(kv)),))
        if ok == 'pkt':
            return V('pktm', name=o.name, value=kname)
        if ok == 'const':
            if isinstance(o.value, dict):
                key = kname if kname is not None else (kv.value if kv.kind == 'const' else None)
                if key in o.value and o.value[key] is not NOT_CONST:
                    return V('const', value=o.value[key])
            return V('expr', text=to_lua(e))
        if ok == 'path':
            if kname is not None:
                if o.root == ('self',) and not o.path and self.self_table is not None:
                    m = self.table_member(self.self_table, kname)
                    if m is not None:
                        return m
                return V('path', root=o.root, path=o.path + (kname,))
            if kv.kind == 'index':
                if not self.pure:
                    ck = (o.root, tuple(o.path))
                    kv.loop.cands[ck] = kv.loop.cands.get(ck, 0) + 1
                return V('path', root=o.root, path=o.path + (('[]', kv.loop),))
            if kv.kind == 'const' and is_num(kv.value):
                return V('path', root=o.root, path=o.path + ('[%d]' % int(kv.value),))
            return V('path', root=o.root, path=o.path + ('[%s]' % self.vtext(kv),))
        if ok in ('node', 'blob', 'len', 'opq', 'expr'):
            return V('expr', inner=o, text=to_lua(e), see=False)
        return V('expr', text=to_lua(e))

    def register_arrays(self, v):
        """Bind loops to the array whose element an emitted value belongs to."""
        while v is not None and v.kind == 'expr':
            v = v.inner
        if v is None or v.kind != 'path' or self.pure:
            return
        segs = v.path
        for j, s in enumerate(segs):
            if isinstance(s, tuple) and s[1] in self.loop_stack and s[1].array is None:
                s[1].array = (v.root, tuple(segs[:j]))

    def table_member(self, table, name):
        if name in table.methods:
            return V('func', func=table.methods[name], scope=table.scope, name=name)
        if name in table.consts and table.consts[name] is not NOT_CONST:
            return V('const', value=table.consts[name])
        return None

    def define_lookup(self, path):
        cur = self.define_tree
        for p in path:
            if isinstance(cur, dict) and p in cur:
                cur = cur[p]
            else:
                return V('expr', text='define.' + '.'.join(str(x) for x in path))
        if isinstance(cur, dict):
            return V('define', path=tuple(path))
        if cur is NOT_CONST:
            return V('expr', text='define.' + '.'.join(str(x) for x in path))
        return V('const', value=cur)

    def ev_table(self, e, scope, hint):
        if self.loop_stack:
            root = ('elem', self.loop_stack[-1])
        else:
            self.tmp_counter += 1
            nm = 'tbl%d' % self.tmp_counter
            if hint is not None and hint.kind == 'path' and hint.root[0] == 'tmp' and not hint.path:
                nm = hint.root[1]
            root = ('tmp', nm)
        for kind, key, val in e.items:
            if kind == 'named':
                self.ev(val, scope, V('path', root=root, path=(key,)))
            elif kind == 'keyed':
                self.ev(key, scope)
                self.ev(val, scope)
            else:
                self.ev(val, scope)
        return V('path', root=root, path=())

    def ev_call(self, e, scope, hint):
        f = self.ev(e.func, scope)
        fk = f.kind
        if fk == 'lib':
            fn = f.name
            if fn in ('bistream.new', 'bostream.new'):
                if self.pure:
                    return V('expr', text=fn)
                name = 'stream'
                if hint is not None and hint.kind == 'path' and hint.root[0] == 'tmp' and not hint.path:
                    name = hint.root[1]
                return V('stream', stream=self.new_stream('in' if fn[1] == 'i' else 'out', name, e.line))
            if fn == 'table.insert':
                return self.do_table_insert(e, scope)
            if fn == 'setmetatable':
                return self.ev(e.args[0], scope) if e.args else NIL
            if fn in TEXT_FUNCS and e.args:
                a = self.ev(e.args[0], scope, hint)
                for x in e.args[1:]:
                    self.ev(x, scope)
                if a.kind == 'node' and not self.pure:
                    a.node['text'] = True
                return V('expr', inner=a, see=True, is_text=True,
                         default=a.default if a.kind == 'expr' else None)
            if fn in LEN_FUNCS and e.args:
                return V('len', inner=self.ev(e.args[0], scope))
            if fn == 'string.rep' and len(e.args) >= 2:
                s = self.ev(e.args[0], scope)
                n = self.ev(e.args[1], scope)
                if s.kind == 'const' and n.kind == 'const' and isinstance(s.value, str) and is_num(n.value):
                    return V('const', value=s.value * int(n.value))
                return V('expr', text=self.render(e, scope), see=False)
            args = [self.ev(a, scope, hint if i == 0 else None) for i, a in enumerate(e.args)]
            if fn in TRANSFORMS:
                inner = next((a for a in args if a.kind != 'const'), None)
                return V('expr', inner=inner, see=True, text=self.render(e, scope),
                         wire=all(self.is_wire(a) for a in args))
            self.opaque_if_stream(args, e)
            return V('expr', text=self.render(e, scope), see=False,
                     inner=next((a for a in args if a.kind in ('path', 'node')), None))
        if fk == 'pktm':
            name, m = f.name, f.value
            args = [self.ev(a, scope) for a in e.args]
            if m == 'new':
                return V('struct_new', struct=name)
            if m in ('bis', 'bos'):
                if len(args) >= 2 and args[1].kind == 'stream':
                    self.emit_struct(args[1].stream, name, m, args[0], e.line)
                    return NIL
                if m == 'bos' and len(args) == 1:
                    return V('struct_blob', struct=name, inner=args[0])
            tbl = self.tables.get(name)
            if tbl is not None and m in tbl.methods:
                fv = V('func', func=tbl.methods[m], scope=tbl.scope, name=m)
                return self.inline(fv, args, e.line, '%s.%s' % (name, m), tbl)
            self.opaque_if_stream(args, e)
            return V('expr', text=self.render(e, scope))
        args = [self.ev(a, scope) for a in e.args]
        if fk == 'func':
            if any(a.kind == 'stream' for a in args):
                return self.inline(f, args, e.line, f.name or '<fn>', None)
            inner = next((a for a in args if a.kind != 'const'), None)
            return V('expr', inner=inner, see=True, text=self.render(e, scope))
        self.opaque_if_stream(args, e)
        return V('expr', text=self.render(e, scope))

    def ev_method(self, e, scope, hint):
        o = self.ev(e.obj, scope)
        m = e.method
        if o.kind == 'stream':
            return self.stream_op(o.stream, m, e, scope, hint)
        args = [self.ev(a, scope) for a in e.args]
        if m == 'bos' and not args:
            st = o.struct if o.kind == 'struct_new' else None
            if st is None:
                sv = self.values.get(self.vkey(o))
                st = sv.struct if sv is not None and sv.kind == 'struct_new' else None
            if st is not None:
                return V('struct_blob', struct=st, inner=o)
        if m in ('bis', 'bos') and args and args[0].kind == 'stream':
            st = None
            name_v = o
            if o.kind == 'struct_new':
                st = o.struct
                name_v = V('path', root=('tmp', e.obj.id), path=()) if e.obj.kind == 'Name' else None
            else:
                sv = self.values.get(self.vkey(o))
                if sv is not None and sv.kind == 'struct_new':
                    st = sv.struct
            self.emit_struct(args[0].stream, st or '?', m, name_v, e.line)
            return NIL
        if o.kind == 'path' and o.root == ('self',) and not o.path and self.self_table is not None:
            fn = self.self_table.methods.get(m)
            if fn is not None:
                fv = V('func', func=fn, scope=self.self_table.scope, name=m)
                return self.inline(fv, [o] + args, e.line, m, self.self_table)
        if m == 'ctor':
            return NIL
        self.opaque_if_stream(args, e)
        return V('expr', inner=o if o.kind in ('path', 'node') else None, see=False,
                 text=self.render(e, scope))

    def do_table_insert(self, e, scope):
        if not e.args:
            return NIL
        t = self.ev(e.args[0], scope)
        loop = self.loop_stack[-1] if self.loop_stack else None
        hint = None
        if t.kind == 'path' and loop is not None:
            hint = V('path', root=t.root, path=t.path + (('[]', loop),))
        v = self.ev(e.args[-1], scope, hint) if len(e.args) >= 2 else NIL
        if loop is not None and t.kind == 'path' and not self.pure and loop.array is None:
            if (v.kind == 'path' and v.root[0] == 'elem' and v.root[1] is loop and not v.path) \
                    or v.kind == 'node':
                loop.array = (t.root, t.path)
        return NIL

    # ------------------------------------------------------------ stream ops
    def stream_op(self, st, m, e, scope, hint):
        line = e.line
        args = e.args
        if self.pure:
            return V('expr', text=to_lua(e))
        if m in READ_TYPES or m in TYPOS:
            node = self.new_field(READ_TYPES.get(m) or TYPOS[m][0], hint, line)
            if m in TYPOS:
                msg = "bistream has no method '%s' (typo of %s); this read raises at run time" % (m, TYPOS[m][1])
                node['error'] = msg
                self.errors.append('L%d: %s' % (line, msg))
            self.emit(st, node)
            return V('node', node=node)
        if m == 'read':
            node = self.new_bytes(self.ev(args[0], scope) if args else None, hint, line)
            self.emit(st, node)
            return V('node', node=node)
        if m in WRITE_TYPES:
            a = self.ev(args[0], scope) if args else NIL
            self.emit(st, self.new_field(WRITE_TYPES[m], None, line, src=a))
            return V('stream', stream=st)
        if m == 'write':
            data = self.ev(args[0], scope) if args else NIL
            ln = self.ev(args[1], scope) if len(args) > 1 else None
            if data.kind == 'blob':
                node = self.new_blob(data.stream, ln, line)
            elif data.kind == 'struct_blob':
                node = self.new_struct_node(data.struct, 'bos', data.inner, line)
                node['note'] = 'embedded via write(%s.bos(obj), %s)' % (data.struct, self.vtext(ln))
            else:
                node = self.new_bytes(ln, None, line, src=data)
            self.emit(st, node)
            return V('stream', stream=st)
        if m in ('writeff', 'skip'):
            node = self.new_bytes(self.ev(args[0], scope) if args else None, None, line)
            node['fill' if m == 'writeff' else 'skip'] = 255 if m == 'writeff' else True
            self.emit(st, node)
            return V('stream', stream=st)
        if m == 'attach':
            a = self.ev(args[0], scope) if args else NIL
            if a.kind == 'buffer':
                st.attached = True
            else:
                self.notes.append('L%d: attach() of a value that is not the packet buffer' % line)
            return NIL
        if m == 'get':
            return V('blob', stream=st)
        msg = "unknown stream method '%s'" % m
        self.errors.append('L%d: %s' % (line, msg))
        self.emit(st, {'k': 'x', 'line': line, '_id': self.next_id(), 'expr': to_lua(e), 'error': msg})
        return V('expr', text=to_lua(e))

    def new_stream(self, kind, name, line):
        st = Stream(len(self.streams) + 1, kind, name, line)
        self.streams.append(st)
        return st

    def new_field(self, t, hint, line, src=None):
        node = {'k': 'f', 'type': t, 'line': line, '_id': self.next_id(), 'name': None}
        if hint is not None:
            self.register_arrays(hint)
            node['name'] = self.disp(hint)
            self.keymap[self.vkey(hint)] = node
        if src is not None:
            self.describe_src(node, src)
        self.keymap['n#%d' % node['_id']] = node
        return node

    def describe_src(self, node, src):
        self.register_arrays(src)
        if src.kind == 'const':
            val = src.value
            node['const'] = int(val) if isinstance(val, bool) else val
            return
        node['name'] = self.disp(src)
        key = self.vkey(src)
        if key and not key.startswith('c:'):
            self.keymap[key] = node
            node['_src_key'] = key
        if src.kind == 'expr':
            if src.default is not None:
                node['default'] = src.default
            if src.text:
                node['expr'] = src.text
        if src.is_text:
            node['text'] = True
        if src.kind == 'len':
            node['derived'] = 'len'

    def attach_len(self, node, ln):
        if ln is None:
            node['len_expr'] = '?'
            return
        if ln.kind == 'const' and is_num(ln.value):
            node['len'] = int(ln.value)
            return
        if ln.kind == 'expr' and isinstance(ln.value, tuple) and ln.value[0] == 'clamp':
            node['clamp'] = ln.value[1]
            ln = ln.inner
        node['_len_wire'] = self.is_wire(ln)
        key = self.vkey(ln)
        ref = ln.node if ln.kind == 'node' else self.keymap.get(key)
        node['_len_key'] = key
        node['_len_node'] = ref
        node['len_expr'] = self.vtext(ln)
        if ref is not None:
            ref['_refs'] = ref.get('_refs', 0) + 1
        lo, hi = self.bounds_for(key)
        if lo is not None:
            node['min'] = lo
        if hi is not None:
            node['max'] = hi

    def new_bytes(self, ln, hint, line, src=None):
        node = {'k': 'b', 'line': line, '_id': self.next_id(), 'name': None}
        if hint is not None:
            self.register_arrays(hint)
            node['name'] = self.disp(hint)
            self.keymap[self.vkey(hint)] = node
        if src is not None:
            self.describe_src(node, src)
        self.keymap['n#%d' % node['_id']] = node
        self.attach_len(node, ln)
        return node

    def new_blob(self, inner, ln, line):
        fields = []
        for fr in self.frames:
            fields.extend(fr.out.get(inner.sid, []))
        inner.embedded = True
        node = {'k': 'blob', 'line': line, '_id': self.next_id(), 'name': inner.name, 'fields': fields}
        self.attach_len(node, ln)
        return node

    def new_struct_node(self, struct, codec, obj, line):
        if obj is not None:
            self.register_arrays(obj)
        return {'k': 's', 'struct': struct, 'codec': codec, 'line': line, '_id': self.next_id(),
                'name': self.disp(obj) if obj is not None else None}

    def emit_struct(self, st, struct, codec, obj, line):
        if not self.pure:
            self.emit(st, self.new_struct_node(struct, codec, obj, line))

    def opaque_if_stream(self, args, e):
        if self.pure:
            return
        for a in args:
            if a.kind == 'stream':
                self.emit(a.stream, {'k': 'x', 'line': e.line, '_id': self.next_id(),
                                     'expr': to_lua(e), 'note': 'stream passed to a call that is not analysed'})
                return

    def emit(self, st, node):
        if self.pure:
            return
        if self.via_stack:
            node['via'] = '/'.join(self.via_stack)
        self.frames[-1].out.setdefault(st.sid, []).append(node)
        self.last_stream = st

    # ------------------------------------------------------------ guards
    def conj(self, e):
        if e.kind == 'BinOp' and e.op == 'and':
            return self.conj(e.left) + self.conj(e.right)
        if e.kind == 'Paren':
            return self.conj(e.expr)
        return [e]

    def bounds_for(self, key):
        lo = hi = None
        for cond, scope in self.cond_stack:
            for c in self.conj(cond):
                if c.kind != 'BinOp' or c.op not in CMP:
                    continue
                a = self.ev_pure(c.left, scope)
                b = self.ev_pure(c.right, scope)
                op = c.op
                if self.vkey(a) == key and b.kind == 'const' and is_num(b.value):
                    val = b.value
                elif self.vkey(b) == key and a.kind == 'const' and is_num(a.value):
                    val = a.value
                    op = FLIP[op]
                else:
                    continue
                if op == '<':
                    hi = val - 1 if hi is None else min(hi, val - 1)
                elif op == '<=':
                    hi = val if hi is None else min(hi, val)
                elif op == '>':
                    lo = val + 1 if lo is None else max(lo, val + 1)
                elif op == '>=':
                    lo = val if lo is None else max(lo, val)
                elif op == '==':
                    lo = val if lo is None else max(lo, val)
                    hi = val if hi is None else min(hi, val)
                elif op == '~=' and val == 0:
                    lo = 1 if lo is None else max(lo, 1)
        return lo, hi
