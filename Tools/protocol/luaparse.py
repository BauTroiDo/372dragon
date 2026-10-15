"""luaparse.py - Lua 5.4 lexer + parser (syntax only) used by specgen.py.

Pure Python, no dependencies.  Produces a small AST of `Node` objects
(kind + line + attributes).  Comments are returned separately as
(line, text, is_block) tuples so callers can detect commented-out code.

Node kinds
  statements : Local LocalFunction FunctionStat Assign CallStat Do While
               Repeat If NumFor GenFor Return Break Goto Label
  expressions: Nil True False Vararg Number String Function Table BinOp
               UnOp Name Index Call MethodCall Paren
"""
import re

__all__ = ['Node', 'LuaSyntaxError', 'tokenize', 'parse', 'to_lua']

KEYWORDS = frozenset((
    'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
    'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then',
    'true', 'until', 'while'))

_NAME_RE = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')
_HEX_RE = re.compile(r'0[xX]([0-9a-fA-F]*)(?:\.([0-9a-fA-F]*))?(?:[pP]([+-]?\d+))?')
_DEC_RE = re.compile(r'(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?')
_DIG3_RE = re.compile(r'\d{1,3}')
_OPS2 = frozenset(('..', '==', '~=', '<=', '>=', '<<', '>>', '//', '::'))
_OPS1 = frozenset('+-*/%^#&~|<>=(){}[];:,.')
_BLOCK_END = frozenset(('end', 'else', 'elseif', 'until'))

# binary operator priorities (left, right) as in lparser.c
BINPRI = {
    'or': (1, 1), 'and': (2, 2),
    '<': (3, 3), '>': (3, 3), '<=': (3, 3), '>=': (3, 3), '~=': (3, 3), '==': (3, 3),
    '|': (4, 4), '~': (5, 5), '&': (6, 6), '<<': (7, 7), '>>': (7, 7),
    '..': (9, 8), '+': (10, 10), '-': (10, 10),
    '*': (11, 11), '/': (11, 11), '//': (11, 11), '%': (11, 11),
    '^': (14, 13),
}
UNARY_PRI = 12


class LuaSyntaxError(Exception):
    pass


class Token(object):
    __slots__ = ('type', 'value', 'line', 'raw')

    def __init__(self, type_, value, line, raw):
        self.type = type_          # name kw num str op eof
        self.value = value
        self.line = line
        self.raw = raw

    def __repr__(self):
        return 'Token(%s,%r,L%d)' % (self.type, self.value, self.line)


class Node(object):
    """Generic AST node: `kind`, `line` and free-form attributes."""

    def __init__(self, kind, line, **kw):
        self.kind = kind
        self.line = line
        self.__dict__.update(kw)

    def __repr__(self):
        attrs = ', '.join('%s=%r' % (k, v) for k, v in self.__dict__.items()
                          if k not in ('kind', 'line', 'body'))
        return '%s@%d(%s)' % (self.kind, self.line, attrs)


# ---------------------------------------------------------------- lexer
def _long_level(src, i):
    """src[i] == '['.  Level of a long bracket opening here, or -1."""
    j = i + 1
    n = len(src)
    while j < n and src[j] == '=':
        j += 1
    if j < n and src[j] == '[':
        return j - i - 1
    return -1


def _read_long(src, i, level, line, what):
    close = ']' + '=' * level + ']'
    k = src.find(close, i + level + 2)
    if k < 0:
        raise LuaSyntaxError('unfinished long %s starting at line %d' % (what, line))
    text = src[i + level + 2:k]
    if text.startswith('\r\n'):
        text = text[2:]
    elif text[:1] in ('\n', '\r'):
        text = text[1:]
    return text, k + len(close), line + src.count('\n', i, k + len(close))


_ESC = {'n': '\n', 't': '\t', 'r': '\r', 'a': '\a', 'b': '\b', 'f': '\f',
        'v': '\v', '\\': '\\', '"': '"', "'": "'"}


def _read_short_string(src, i, line):
    q = src[i]
    j = i + 1
    n = len(src)
    out = []
    while True:
        if j >= n:
            raise LuaSyntaxError('unfinished string at line %d' % line)
        c = src[j]
        if c == q:
            return ''.join(out), j + 1, line
        if c == '\n':
            raise LuaSyntaxError('unfinished string at line %d' % line)
        if c != '\\':
            out.append(c)
            j += 1
            continue
        j += 1
        e = src[j] if j < n else ''
        if e in _ESC:
            out.append(_ESC[e])
            j += 1
        elif e == '\n':
            out.append('\n')
            line += 1
            j += 1
        elif e == '\r':
            out.append('\n')
            line += 1
            j += 1
            if j < n and src[j] == '\n':
                j += 1
        elif e == 'x':
            out.append(chr(int(src[j + 1:j + 3], 16)))
            j += 3
        elif e == 'z':
            j += 1
            while j < n and src[j] in ' \t\r\n\f\v':
                if src[j] == '\n':
                    line += 1
                j += 1
        elif e.isdigit():
            m = _DIG3_RE.match(src, j)
            out.append(chr(int(m.group(0))))
            j = m.end()
        elif e == 'u':
            k = src.index('}', j)
            out.append(chr(int(src[j + 2:k], 16)))
            j = k + 1
        else:
            raise LuaSyntaxError('invalid escape \\%s at line %d' % (e, line))


def tokenize(src):
    """Return (tokens, comments)."""
    toks = []
    comments = []
    i = 0
    n = len(src)
    line = 1
    if src.startswith('#'):
        k = src.find('\n')
        i = n if k < 0 else k
    while i < n:
        c = src[i]
        if c == '\n':
            line += 1
            i += 1
            continue
        if c in ' \t\r\f\v':
            i += 1
            continue
        if c == '-' and src.startswith('--', i):
            start = line
            j = i + 2
            if j < n and src[j] == '[':
                lvl = _long_level(src, j)
                if lvl >= 0:
                    text, i, line = _read_long(src, j, lvl, line, 'comment')
                    comments.append((start, text, True))
                    continue
            k = src.find('\n', j)
            if k < 0:
                k = n
            comments.append((start, src[j:k], False))
            i = k
            continue
        m = _NAME_RE.match(src, i)
        if m:
            w = m.group(0)
            toks.append(Token('kw' if w in KEYWORDS else 'name', w, line, w))
            i = m.end()
            continue
        if ('0' <= c <= '9') or (c == '.' and i + 1 < n and '0' <= src[i + 1] <= '9'):
            if c == '0' and i + 1 < n and src[i + 1] in 'xX':
                m = _HEX_RE.match(src, i)
                ip, fp, ex = m.group(1), m.group(2), m.group(3)
                if fp is None and ex is None:
                    val = int(ip or '0', 16)
                    if val >= 1 << 63:          # Lua wraps hex integers
                        val = ((val + (1 << 63)) % (1 << 64)) - (1 << 63)
                else:
                    val = float.fromhex('0x%s.%sp%s' % (ip or '0', fp or '', ex or '0'))
            else:
                m = _DEC_RE.match(src, i)
                raw = m.group(0)
                val = float(raw) if any(ch in raw for ch in '.eE') else int(raw)
            toks.append(Token('num', val, line, m.group(0)))
            i = m.end()
            continue
        if c == '"' or c == "'":
            s, j, nl = _read_short_string(src, i, line)
            toks.append(Token('str', s, line, src[i:j]))
            line = nl
            i = j
            continue
        if c == '[':
            lvl = _long_level(src, i)
            if lvl >= 0:
                start = line
                text, i, line = _read_long(src, i, lvl, line, 'string')
                toks.append(Token('str', text, start, None))
                continue
        if src.startswith('...', i):
            toks.append(Token('op', '...', line, '...'))
            i += 3
            continue
        two = src[i:i + 2]
        if two in _OPS2:
            toks.append(Token('op', two, line, two))
            i += 2
            continue
        if c in _OPS1:
            toks.append(Token('op', c, line, c))
            i += 1
            continue
        raise LuaSyntaxError('unexpected character %r at line %d' % (c, line))
    toks.append(Token('eof', None, line, ''))
    return toks, comments


# ---------------------------------------------------------------- parser
class _Parser(object):
    def __init__(self, toks):
        self.toks = toks
        self.p = 0

    # token helpers
    @property
    def tok(self):
        return self.toks[self.p]

    def peek(self, k=1):
        return self.toks[min(self.p + k, len(self.toks) - 1)]

    def next(self):
        t = self.toks[self.p]
        if t.type != 'eof':
            self.p += 1
        return t

    def is_op(self, v):
        t = self.toks[self.p]
        return t.type == 'op' and t.value == v

    def is_kw(self, v):
        t = self.toks[self.p]
        return t.type == 'kw' and t.value == v

    def accept_op(self, v):
        if self.is_op(v):
            self.p += 1
            return True
        return False

    def accept_kw(self, v):
        if self.is_kw(v):
            self.p += 1
            return True
        return False

    def error(self, msg):
        t = self.tok
        raise LuaSyntaxError('%s near %r at line %d' % (msg, t.raw if t.raw else t.value, t.line))

    def expect_op(self, v):
        if not self.accept_op(v):
            self.error("'%s' expected" % v)

    def expect_kw(self, v, what=None, line=None):
        if not self.accept_kw(v):
            if what:
                self.error("'%s' expected (to close '%s' at line %d)" % (v, what, line))
            self.error("'%s' expected" % v)

    def expect_name(self):
        t = self.tok
        if t.type != 'name':
            self.error('<name> expected')
        self.p += 1
        return t.value

    def block_follow(self):
        t = self.tok
        return t.type == 'eof' or (t.type == 'kw' and t.value in _BLOCK_END)

    # blocks / statements
    def block(self):
        stmts = []
        while not self.block_follow():
            if self.is_kw('return'):
                stmts.append(self.retstat())
                break
            s = self.statement()
            if s is not None:
                stmts.append(s)
        return stmts

    def retstat(self):
        line = self.next().line
        exprs = []
        if not self.block_follow() and not self.is_op(';'):
            exprs = self.exprlist()
        self.accept_op(';')
        return Node('Return', line, exprs=exprs)

    def statement(self):
        t = self.tok
        line = t.line
        if t.type == 'op':
            if t.value == ';':
                self.next()
                return None
            if t.value == '::':
                self.next()
                name = self.expect_name()
                self.expect_op('::')
                return Node('Label', line, name=name)
        elif t.type == 'kw':
            v = t.value
            if v == 'if':
                return self.ifstat()
            if v == 'while':
                self.next()
                cond = self.expr()
                self.expect_kw('do')
                body = self.block()
                self.expect_kw('end', 'while', line)
                return Node('While', line, cond=cond, body=body)
            if v == 'do':
                self.next()
                body = self.block()
                self.expect_kw('end', 'do', line)
                return Node('Do', line, body=body)
            if v == 'for':
                return self.forstat()
            if v == 'repeat':
                self.next()
                body = self.block()
                self.expect_kw('until', 'repeat', line)
                return Node('Repeat', line, body=body, cond=self.expr())
            if v == 'function':
                self.next()
                names = [self.expect_name()]
                method = None
                while self.accept_op('.'):
                    names.append(self.expect_name())
                if self.accept_op(':'):
                    method = self.expect_name()
                func = self.funcbody(line, method is not None)
                return Node('FunctionStat', line, names=names, method=method, func=func)
            if v == 'local':
                self.next()
                if self.accept_kw('function'):
                    name = self.expect_name()
                    return Node('LocalFunction', line, name=name, func=self.funcbody(line, False))
                names, attribs = [], []
                while True:
                    names.append(self.expect_name())
                    if self.accept_op('<'):
                        attribs.append(self.expect_name())
                        self.expect_op('>')
                    else:
                        attribs.append(None)
                    if not self.accept_op(','):
                        break
                exprs = self.exprlist() if self.accept_op('=') else []
                return Node('Local', line, names=names, attribs=attribs, exprs=exprs)
            if v == 'break':
                self.next()
                return Node('Break', line)
            if v == 'goto':
                self.next()
                return Node('Goto', line, label=self.expect_name())
        e = self.suffixedexp()
        if self.is_op('=') or self.is_op(','):
            targets = [e]
            while self.accept_op(','):
                targets.append(self.suffixedexp())
            self.expect_op('=')
            exprs = self.exprlist()
            for tg in targets:
                if tg.kind not in ('Name', 'Index'):
                    raise LuaSyntaxError('cannot assign to %s at line %d' % (tg.kind, line))
            return Node('Assign', line, targets=targets, exprs=exprs)
        if e.kind not in ('Call', 'MethodCall'):
            raise LuaSyntaxError('syntax error at line %d (expression statement is not a call)' % line)
        return Node('CallStat', line, call=e)

    def ifstat(self):
        line = self.next().line
        tests = []
        cond = self.expr()
        self.expect_kw('then')
        tests.append((cond, self.block()))
        orelse = None
        while True:
            if self.is_kw('elseif'):
                self.next()
                c = self.expr()
                self.expect_kw('then')
                tests.append((c, self.block()))
            elif self.is_kw('else'):
                self.next()
                orelse = self.block()
                self.expect_kw('end', 'if', line)
                break
            else:
                self.expect_kw('end', 'if', line)
                break
        return Node('If', line, tests=tests, orelse=orelse)

    def forstat(self):
        line = self.next().line
        n1 = self.expect_name()
        if self.accept_op('='):
            start = self.expr()
            self.expect_op(',')
            stop = self.expr()
            step = self.expr() if self.accept_op(',') else None
            self.expect_kw('do')
            body = self.block()
            self.expect_kw('end', 'for', line)
            return Node('NumFor', line, var=n1, start=start, stop=stop, step=step, body=body)
        names = [n1]
        while self.accept_op(','):
            names.append(self.expect_name())
        self.expect_kw('in')
        exprs = self.exprlist()
        self.expect_kw('do')
        body = self.block()
        self.expect_kw('end', 'for', line)
        return Node('GenFor', line, names=names, exprs=exprs, body=body)

    def funcbody(self, line, is_method):
        self.expect_op('(')
        params = ['self'] if is_method else []
        vararg = False
        if not self.is_op(')'):
            while True:
                if self.accept_op('...'):
                    vararg = True
                    break
                params.append(self.expect_name())
                if not self.accept_op(','):
                    break
        self.expect_op(')')
        body = self.block()
        end_line = self.tok.line
        self.expect_kw('end', 'function', line)
        return Node('Function', line, params=params, vararg=vararg, body=body, end_line=end_line)

    # expressions
    def exprlist(self):
        out = [self.expr()]
        while self.accept_op(','):
            out.append(self.expr())
        return out

    def expr(self, limit=0):
        t = self.tok
        if (t.type == 'kw' and t.value == 'not') or (t.type == 'op' and t.value in ('-', '#', '~')):
            self.next()
            operand = self.expr(UNARY_PRI)
            e = Node('UnOp', t.line, op=t.value, operand=operand)
        else:
            e = self.simpleexp()
        while True:
            t = self.tok
            op = t.value if t.type in ('op', 'kw') else None
            pri = BINPRI.get(op) if op is not None else None
            if pri is None or pri[0] <= limit:
                break
            self.next()
            right = self.expr(pri[1])
            e = Node('BinOp', t.line, op=op, left=e, right=right)
        return e

    def simpleexp(self):
        t = self.tok
        if t.type == 'num':
            self.next()
            return Node('Number', t.line, value=t.value, raw=t.raw)
        if t.type == 'str':
            self.next()
            return Node('String', t.line, value=t.value)
        if t.type == 'kw':
            if t.value == 'nil':
                self.next()
                return Node('Nil', t.line)
            if t.value == 'true':
                self.next()
                return Node('True', t.line)
            if t.value == 'false':
                self.next()
                return Node('False', t.line)
            if t.value == 'function':
                self.next()
                return self.funcbody(t.line, False)
        if t.type == 'op':
            if t.value == '...':
                self.next()
                return Node('Vararg', t.line)
            if t.value == '{':
                return self.table()
        return self.suffixedexp()

    def primaryexp(self):
        t = self.tok
        if t.type == 'name':
            self.next()
            return Node('Name', t.line, id=t.value)
        if self.is_op('('):
            self.next()
            e = self.expr()
            self.expect_op(')')
            return Node('Paren', t.line, expr=e)
        self.error('unexpected symbol')

    def suffixedexp(self):
        e = self.primaryexp()
        while True:
            t = self.tok
            if t.type == 'op':
                if t.value == '.':
                    self.next()
                    name_tok = self.tok
                    name = self.expect_name()
                    e = Node('Index', t.line, obj=e,
                             key=Node('String', name_tok.line, value=name), dot=True)
                    continue
                if t.value == '[':
                    self.next()
                    k = self.expr()
                    self.expect_op(']')
                    e = Node('Index', t.line, obj=e, key=k, dot=False)
                    continue
                if t.value == ':':
                    self.next()
                    name = self.expect_name()
                    e = Node('MethodCall', t.line, obj=e, method=name, args=self.callargs())
                    continue
                if t.value in ('(', '{'):
                    e = Node('Call', t.line, func=e, args=self.callargs())
                    continue
            elif t.type == 'str':
                e = Node('Call', t.line, func=e, args=self.callargs())
                continue
            return e

    def callargs(self):
        t = self.tok
        if t.type == 'str':
            self.next()
            return [Node('String', t.line, value=t.value)]
        if self.is_op('{'):
            return [self.table()]
        self.expect_op('(')
        if self.accept_op(')'):
            return []
        args = self.exprlist()
        self.expect_op(')')
        return args

    def table(self):
        line = self.tok.line
        self.expect_op('{')
        items = []
        while not self.is_op('}'):
            if self.is_op('['):
                self.next()
                k = self.expr()
                self.expect_op(']')
                self.expect_op('=')
                items.append(('keyed', k, self.expr()))
            elif self.tok.type == 'name' and self.peek().type == 'op' and self.peek().value == '=':
                k = self.next().value
                self.next()
                items.append(('named', k, self.expr()))
            else:
                items.append(('pos', None, self.expr()))
            if not (self.accept_op(',') or self.accept_op(';')):
                break
        self.expect_op('}')
        return Node('Table', line, items=items)


def parse(src):
    """Parse Lua source text; return Node('Chunk') with .body and .comments."""
    toks, comments = tokenize(src)
    p = _Parser(toks)
    body = p.block()
    if p.tok.type != 'eof':
        p.error("'<eof>' expected")
    return Node('Chunk', 1, body=body, comments=comments)


# ---------------------------------------------------------------- unparser
def _lua_str(s):
    out = []
    for ch in s:
        o = ord(ch)
        if ch == '"':
            out.append('\\"')
        elif ch == '\\':
            out.append('\\\\')
        elif ch == '\n':
            out.append('\\n')
        elif o < 32 or o == 127:
            out.append('\\%d' % o)
        else:
            out.append(ch)
    return '"%s"' % ''.join(out)


def to_lua(e):
    """Render an expression back to (normalised) Lua source text."""
    k = e.kind
    if k == 'Name':
        return e.id
    if k == 'Number':
        return e.raw if getattr(e, 'raw', None) else repr(e.value)
    if k == 'String':
        return _lua_str(e.value)
    if k in ('Nil', 'True', 'False'):
        return k.lower()
    if k == 'Vararg':
        return '...'
    if k == 'Paren':
        return '(%s)' % to_lua(e.expr)
    if k == 'Index':
        if e.key.kind == 'String' and getattr(e, 'dot', False):
            return '%s.%s' % (to_lua(e.obj), e.key.value)
        return '%s[%s]' % (to_lua(e.obj), to_lua(e.key))
    if k == 'Call':
        return '%s(%s)' % (to_lua(e.func), ', '.join(to_lua(a) for a in e.args))
    if k == 'MethodCall':
        return '%s:%s(%s)' % (to_lua(e.obj), e.method, ', '.join(to_lua(a) for a in e.args))
    if k == 'BinOp':
        return '%s %s %s' % (_wrap(e.left, e.op, False), e.op, _wrap(e.right, e.op, True))
    if k == 'UnOp':
        sep = ' ' if e.op == 'not' else ''
        inner = to_lua(e.operand)
        if e.operand.kind == 'BinOp':
            inner = '(%s)' % inner
        return '%s%s%s' % (e.op, sep, inner)
    if k == 'Table':
        parts = []
        for kind, key, val in e.items:
            if kind == 'keyed':
                parts.append('[%s] = %s' % (to_lua(key), to_lua(val)))
            elif kind == 'named':
                parts.append('%s = %s' % (key, to_lua(val)))
            else:
                parts.append(to_lua(val))
        return '{%s}' % ', '.join(parts)
    if k == 'Function':
        return 'function(%s) ... end' % ', '.join(e.params)
    return '<%s>' % k


def _wrap(sub, op, is_right):
    s = to_lua(sub)
    if sub.kind == 'BinOp':
        mine = BINPRI[op][0]
        theirs = BINPRI[sub.op][0]
        if theirs < mine or (theirs == mine and is_right != (BINPRI[op][1] < BINPRI[op][0])):
            s = '(%s)' % s
    return s
