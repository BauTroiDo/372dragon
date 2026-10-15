"""luaconst.py - constant folding over luaparse ASTs (define.lua, packet_ids.lua,
login ID constants, packet-table constant members)."""
import math


class NotConst(Exception):
    pass


def lua_idiv(a, b):
    if isinstance(a, int) and isinstance(b, int):
        return a // b
    return float(math.floor(a / b))


def fold(op, a, b):
    """Apply a Lua binary operator to constant operands (raises NotConst)."""
    try:
        if op == '+':
            return a + b
        if op == '-':
            return a - b
        if op == '*':
            return a * b
        if op == '/':
            return a / b
        if op == '//':
            return lua_idiv(a, b)
        if op == '%':
            return a % b
        if op == '^':
            return float(a) ** b
        if op == '..':
            return '%s%s' % (a, b)
        if op == '==':
            return a == b
        if op == '~=':
            return a != b
        if op == '<':
            return a < b
        if op == '<=':
            return a <= b
        if op == '>':
            return a > b
        if op == '>=':
            return a >= b
        if op == 'and':
            return b if (a is not None and a is not False) else a
        if op == 'or':
            return a if (a is not None and a is not False) else b
        if op == '&':
            return int(a) & int(b)
        if op == '|':
            return int(a) | int(b)
        if op == '~':
            return int(a) ^ int(b)
        if op == '<<':
            return (int(a) << int(b)) & 0xFFFFFFFFFFFFFFFF
        if op == '>>':
            return (int(a) & 0xFFFFFFFFFFFFFFFF) >> int(b)
    except (TypeError, ValueError, ZeroDivisionError, OverflowError):
        raise NotConst(op)
    raise NotConst(op)


def const_eval(e, env):
    """Evaluate a constant expression; `env` maps global/local names to values."""
    k = e.kind
    if k in ('Number', 'String'):
        return e.value
    if k == 'True':
        return True
    if k == 'False':
        return False
    if k == 'Nil':
        return None
    if k == 'Paren':
        return const_eval(e.expr, env)
    if k == 'UnOp':
        v = const_eval(e.operand, env)
        try:
            if e.op == '-':
                return -v
            if e.op == 'not':
                return v is None or v is False
            if e.op == '#':
                return len(v)
            if e.op == '~':
                return ~int(v)
        except TypeError:
            raise NotConst('unop')
        raise NotConst('unop')
    if k == 'BinOp':
        return fold(e.op, const_eval(e.left, env), const_eval(e.right, env))
    if k == 'Name':
        if e.id in env:
            return env[e.id]
        raise NotConst(e.id)
    if k == 'Index':
        base = const_eval(e.obj, env)
        key = e.key.value if e.key.kind == 'String' else const_eval(e.key, env)
        if isinstance(base, dict) and key in base:
            return base[key]
        raise NotConst('index')
    if k == 'Table':
        d = {}
        pos = 1
        for kind, key, val in e.items:
            try:
                v = const_eval(val, env)
            except NotConst:
                v = NOT_CONST
            if kind == 'named':
                d[key] = v
            elif kind == 'keyed':
                d[const_eval(key, env)] = v
            else:
                d[pos] = v
                pos += 1
        return d
    raise NotConst(k)


class _NotConstMarker(object):
    def __repr__(self):
        return '<not-const>'


NOT_CONST = _NotConstMarker()


def target_path(t):
    """Name / Index chain with constant string keys -> list of names, or None."""
    parts = []
    while t.kind == 'Index':
        if t.key.kind != 'String':
            return None
        parts.append(t.key.value)
        t = t.obj
    if t.kind != 'Name':
        return None
    parts.append(t.id)
    return parts[::-1]


def exec_const_chunk(stmts, env=None):
    """Run top-level `local x = const` / `a.b.c = const` statements.

    Returns (env, assignments) where assignments is a list of
    (dotted_name, value, line) in source order (NOT_CONST for non-constants)."""
    env = {} if env is None else env
    assigns = []
    for s in stmts:
        if s.kind == 'Local':
            for i, name in enumerate(s.names):
                if i < len(s.exprs):
                    try:
                        env[name] = const_eval(s.exprs[i], env)
                    except NotConst:
                        env[name] = NOT_CONST
        elif s.kind == 'Assign':
            for i, tg in enumerate(s.targets):
                if i >= len(s.exprs):
                    continue
                path = target_path(tg)
                if not path:
                    continue
                try:
                    v = const_eval(s.exprs[i], env)
                except NotConst:
                    v = NOT_CONST
                assigns.append(('.'.join(path), v, s.line))
                if len(path) == 1:
                    env[path[0]] = v
                    continue
                base = env.get(path[0])
                ok = isinstance(base, dict)
                for p in path[1:-1]:
                    if not ok:
                        break
                    base = base.get(p)
                    ok = isinstance(base, dict)
                if ok:
                    base[path[-1]] = v
    return env, assigns
