"""codec_post.py - raw extractor trees -> spec nodes (sugar, sizes, flattening)."""
import re

from extract_expr import SIZES

STR_TYPES = {'u8': 'str8', 'i8': 'str8', 'u16': 'str16', 'i16': 'str16',
             'u32': 'str32', 'i32': 'str32'}
UNKNOW_RE = re.compile(r'(?i)(^|[._])(unknow|unknown|unk)(_|\d|$)')


def _single_ref_ok(n, allow_guard):
    return n.get('_refs', 0) == 1 and n.get('_crefs', 0) <= (1 if allow_guard else 0)


def _make_str(n, b, guard):
    node = {'k': 'str', 'type': STR_TYPES[n['type']], 'name': b.get('name'),
            'len_name': n.get('name'), 'len_type': n['type'], 'line': n['line']}
    for key in ('clamp', 'min', 'max', 'text', 'const', 'default', 'expr', 'via'):
        if key in b:
            node[key] = b[key]
    if guard:
        node['guard'] = guard
    if b['line'] != n['line']:
        node['line_data'] = b['line']
    return node


def sugar(lst):
    """Collapse `len` + bytes[len] into strN and `len` + blob into a sized blob."""
    out = []
    i = 0
    while i < len(lst):
        n = lst[i]
        k = n['k']
        if k == 'if':
            for br in n['branches']:
                br['fields'] = sugar(br['fields'])
        elif k in ('loop', 'blob'):
            n['fields'] = sugar(n['fields'])
        nxt = lst[i + 1] if i + 1 < len(lst) else None
        if k == 'f' and n['type'] in STR_TYPES and nxt is not None and 'const' not in n:
            if nxt['k'] == 'b' and nxt.get('_len_node') is n and _single_ref_ok(n, False):
                out.append(_make_str(n, nxt, None))
                i += 2
                continue
            if nxt['k'] == 'blob' and nxt.get('_len_node') is n and _single_ref_ok(n, False):
                nxt['len_type'] = n['type']
                nxt['len_name'] = n.get('name')
                out.append(nxt)
                i += 2
                continue
            if nxt['k'] == 'if' and len(nxt['branches']) == 1:
                br = nxt['branches'][0]
                bf = br['fields']
                if (len(bf) == 1 and bf[0]['k'] == 'b' and bf[0].get('_len_node') is n
                        and _single_ref_ok(n, True) and all(r is n for r in br.get('_refs', []))):
                    out.append(_make_str(n, bf[0], br['when']))
                    i += 2
                    continue
        out.append(n)
        i += 1
    return out


def _copy(src, dst, keys):
    for key in keys:
        if key in src:
            dst[key] = src[key]


def to_spec(n):
    """Raw node -> ordered plain dict for YAML/JSON."""
    k = n['k']
    if k == 'f':
        d = {'name': n.get('name'), 'type': n['type']}
        _copy(n, d, ('const', 'default', 'expr', 'text', 'derived', 'error', 'via'))
        d['line'] = n['line']
        return d
    if k == 'b':
        d = {'name': n.get('name')}
        if 'len' in n:
            d['type'] = 'bytes[%d]' % n['len']
        else:
            d['type'] = 'bytes[]'
            ref = n.get('_len_node')
            if ref is not None:
                d['len_field'] = ref.get('name')
            else:
                d['len_expr'] = n.get('len_expr')
                if not n.get('_len_wire'):
                    d['len_on_wire'] = False
        _copy(n, d, ('clamp', 'min', 'max', 'const', 'fill', 'skip', 'default', 'text', 'expr', 'via'))
        d['line'] = n['line']
        return d
    if k == 'str':
        d = {'name': n.get('name'), 'type': n['type'], 'len_name': n.get('len_name')}
        if n['len_type'][0] == 'i':
            d['len_signed'] = True
        _copy(n, d, ('clamp', 'min', 'max', 'guard', 'text', 'const', 'default', 'expr', 'via', 'line',
                     'line_data'))
        return d
    if k == 's':
        d = {'name': n.get('name'), 'type': 'struct %s' % n['struct'], 'codec': n['codec']}
        _copy(n, d, ('note', 'via', 'line'))
        return d
    if k == 'blob':
        d = {'kind': 'blob', 'name': n.get('name')}
        if 'len_type' in n:
            d['len_type'] = n['len_type']
            d['len_name'] = n.get('len_name')
        elif n.get('_len_node') is not None:
            d['len_field'] = n['_len_node'].get('name')
        else:
            d['len_expr'] = n.get('len_expr')
        _copy(n, d, ('via', 'line'))
        d['fields'] = [to_spec(x) for x in n['fields']]
        return d
    if k == 'x':
        d = {'kind': 'opaque'}
        _copy(n, d, ('expr', 'note', 'error', 'via', 'line'))
        return d
    if k == 'if':
        return {'kind': 'if', 'line': n['line'],
                'branches': [{'when': br['when'], 'fields': [to_spec(x) for x in br['fields']]}
                             for br in n['branches']]}
    if k == 'loop':
        L = n['loop']
        els = [to_spec(x) for x in n['fields']]
        d = {'kind': 'array', 'name': L.name}
        if L.count is not None:
            d['count'] = L.count
        elif L.count_node is not None:
            d['count_field'] = L.count_node.get('name')
        else:
            d['count_expr'] = L.count_text
            if not L.count_wire:
                d['count_on_wire'] = False
        lo, hi = L.bounds
        if L.count is None and lo is not None:
            d['min'] = lo
        if L.count is None and hi is not None:
            d['max'] = hi
        if L.kind != 'for':
            d['loop'] = L.kind
        if L.var and L.var != '_':
            d['var'] = L.var
        if L.notes:
            d['notes'] = list(L.notes)
        d['line'] = L.line
        if len(els) == 1 and 'kind' not in els[0] and not els[0].get('name'):
            el = els[0]
            d['type'] = 'array<%s>' % el['type']
            extra = {x: el[x] for x in el if x not in ('name', 'type', 'line')}
            if extra:
                d['element'] = extra
        else:
            d['fields'] = els
        return d
    raise ValueError('unknown node kind %r' % k)


# ------------------------------------------------------------------ sizes
def _add(a, b):
    return None if a is None or b is None else a + b


def size_of(nodes, struct_size):
    lo, hi = 0, 0
    for n in nodes:
        a, b = size_node(n, struct_size)
        lo += a
        hi = _add(hi, b)
    return lo, hi


def size_node(n, struct_size):
    """Spec node -> (min, max) bytes; max None = unbounded/unknown."""
    kind = n.get('kind')
    t = n.get('type', '')
    if kind is None:
        if t in SIZES:
            return SIZES[t], SIZES[t]
        m = re.match(r'bytes\[(\d+)\]$', t)
        if m:
            return int(m.group(1)), int(m.group(1))
        if t == 'bytes[]':
            return 0, n.get('max')
        if t in ('str8', 'str16', 'str32'):
            p = SIZES[{'str8': 'u8', 'str16': 'u16', 'str32': 'u32'}[t]]
            mx = n.get('max')
            return p, (p + mx if mx is not None else None)
        if t.startswith('struct '):
            return struct_size(t[7:], n.get('codec'))
        return 0, None
    if kind == 'blob':
        p = SIZES.get(n.get('len_type'), 0)
        lo, hi = size_of(n['fields'], struct_size)
        return p + lo, _add(p, hi)
    if kind == 'opaque':
        return 0, None
    if kind == 'if':
        los, his = [], []
        for br in n['branches']:
            a, b = size_of(br['fields'], struct_size)
            los.append(a)
            his.append(b)
        if not any(br['when'] == 'else' for br in n['branches']):
            los.append(0)
        return min(los), (None if any(h is None for h in his) else max(his + [0]))
    if kind == 'array':
        if 'fields' in n:
            elo, ehi = size_of(n['fields'], struct_size)
        else:
            elo, ehi = size_node({'type': t[6:-1], 'codec': n.get('codec')}, struct_size)
        if 'count' in n:
            c = n['count']
            return c * elo, (c * ehi if ehi is not None else None)
        cmin = n.get('min') or 0
        cmax = n.get('max')
        return cmin * elo, (cmax * ehi if cmax is not None and ehi is not None else None)
    return 0, None


# ------------------------------------------------------------------ flatten
def flatten(nodes, prefix='', conds=(), out=None, array_ctx=''):
    """Leaf rows: dict(path, type, cond, array, line, extra...)."""
    out = [] if out is None else out
    for n in nodes:
        kind = n.get('kind')
        if kind is None:
            name = n.get('name')
            path = prefix + (name if name else ('<const %r>' % (n['const'],) if 'const' in n else '<anon>'))
            out.append({'path': path, 'type': n['type'], 'cond': ' && '.join('(%s)' % c for c in conds),
                        'array': array_ctx, 'line': n.get('line'), 'node': n})
        elif kind == 'if':
            prev = []
            for br in n['branches']:
                if br['when'] == 'else':
                    c = ' && '.join('!(%s)' % p for p in prev) or 'else'
                else:
                    c = br['when']
                    prev.append(br['when'])
                flatten(br['fields'], prefix, conds + (c,), out, array_ctx)
        elif kind == 'array':
            nm = n.get('name') or '<array@%s>' % n.get('line')
            cnt = n.get('count', n.get('count_field', n.get('count_expr')))
            ctx = (array_ctx + ' / ' if array_ctx else '') + '%s[%s]' % (nm, cnt)
            if 'fields' in n:
                flatten(n['fields'], prefix + nm + '[].', conds, out, ctx)
            else:
                out.append({'path': prefix + nm + '[]', 'type': n['type'][6:-1],
                            'cond': ' && '.join('(%s)' % c for c in conds), 'array': ctx,
                            'line': n.get('line'), 'node': n})
        elif kind == 'blob':
            out.append({'path': prefix + (n.get('name') or 'blob') + '.<len>', 'type': n.get('len_type', '?'),
                        'cond': ' && '.join('(%s)' % c for c in conds), 'array': array_ctx,
                        'line': n.get('line'), 'node': n})
            flatten(n['fields'], prefix + (n.get('name') or 'blob') + '.', conds, out, array_ctx)
        elif kind == 'opaque':
            out.append({'path': prefix + '<opaque>', 'type': 'opaque',
                        'cond': ' && '.join('(%s)' % c for c in conds), 'array': array_ctx,
                        'line': n.get('line'), 'node': n})
    return out


def is_unknow(path):
    last = path.split('.')[-1].replace('[]', '')
    return bool(UNKNOW_RE.search(last))


def shape(nodes):
    """Name-free structural signature (used to compare bis vs bos)."""
    out = []
    for n in nodes:
        kind = n.get('kind')
        if kind is None:
            out.append(n['type'])
        elif kind == 'if':
            out.append(('if', tuple(shape(br['fields']) for br in n['branches'])))
        elif kind == 'array':
            out.append(('array', n.get('count', '*'), n.get('type') or shape(n['fields'])))
        elif kind == 'blob':
            out.append(('blob', n.get('len_type'), shape(n['fields'])))
        else:
            out.append(kind)
    return tuple(out)
