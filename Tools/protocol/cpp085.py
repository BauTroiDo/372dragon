"""cpp085.py - read the 0.85 C++ packet classes (Src/Shared/Common/Packets) and
extract, per class: packet enum/id, member declarations and the ordered field
sequence of Read( SocketInputStream& ).  Static text analysis only."""
import os
import re

SRC_COMMON = r'C:\TLBB\085\CY-Source\Src\Shared\Common'
PRIM = {'BYTE': 1, 'UCHAR': 1, 'CHAR': 1, 'char': 1, 'uchar': 1, 'bool': 1, 'BOOL': 4,
        'INT': 4, 'int': 4, 'UINT': 4, 'uint': 4, 'DWORD': 4, 'ULONG': 4, 'LONG': 4,
        'FLOAT': 4, 'float': 4, 'WORD': 2, 'USHORT': 2, 'SHORT': 2, 'short': 2,
        'ushort': 2, '__int64': 8, 'MODEL_PART': 8, 'double': 8}
# structs read with one sizeof(); layout checked by hand in GameStruct*.h / DB_Struct.h
STRUCTS = {'WORLD_POS': (8, [('m_fX', 4), ('m_fZ', 4)]),
           '_ITEM_GUID': (8, [('m_World', 1), ('m_Server', 1), ('<pad>', 2), ('m_Serial', 4)]),
           'PET_GUID_t': (8, [('m_uHighSection', 4), ('m_uLowSection', 4)]),
           '_PLAYERSHOP_GUID': (12, [('m_World', 2), ('m_Server', 2), ('m_Scene', 2),
                                     ('<pad>', 2), ('m_PoolPos', 4)])}


def read_text(path):
    b = open(path, 'rb').read()
    for enc in ('utf-8-sig', 'gb18030'):
        try:
            return b.decode(enc)
        except UnicodeDecodeError:
            pass
    return b.decode('latin-1')


def strip_comments(s):
    return re.sub(r'//[^\n]*|/\*.*?\*/', ' ', s, flags=re.S)


def match_brace(s, i):
    """s[i] == '{' -> index of the matching '}'."""
    depth = 0
    for j in range(i, len(s)):
        c = s[j]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return j
    return len(s) - 1


def load_types(common=SRC_COMMON):
    sizes = dict(PRIM)
    macros = {}
    typedefs = []
    headers = [os.path.join(common, fn) for fn in os.listdir(common) if fn.endswith('.h')]
    pdir = os.path.join(common, 'Packets')
    headers += [os.path.join(pdir, fn) for fn in os.listdir(pdir) if fn.endswith('.h')]
    for path in headers:
        t = strip_comments(read_text(path))
        typedefs += re.findall(r'typedef\s+(?:unsigned\s+)?(\w+)\s+(\w+)\s*;', t)
        for en in re.findall(r'\benum\s+(\w+)\s*\{', t):
            sizes.setdefault(en, 4)          # MSVC enums are int-sized
        for name, val in re.findall(r'^\s*#define\s+(\w+)\s+([^\n]+)$', t, flags=re.M):
            macros[name] = val.strip()
    for _ in range(5):
        for base, name in typedefs:
            if base in sizes and name not in sizes:
                sizes[name] = sizes[base]
    for k, (sz, _) in STRUCTS.items():
        sizes[k] = sz
    return sizes, macros


def eval_int(expr, macros, depth=0):
    expr = expr.strip()
    if depth > 8:
        return None
    if re.match(r'^(0[xX][0-9a-fA-F]+|\d+)[uUlL]*$', expr):
        return int(re.sub(r'[uUlL]+$', '', expr), 0)
    if expr in macros:
        return eval_int(macros[expr], macros, depth + 1)
    m = re.match(r'^\((.*)\)$', expr)
    if m:
        return eval_int(m.group(1), macros, depth + 1)
    parts = re.split(r'(\+|\*|-)', expr)
    if len(parts) == 3:
        a, op, b = eval_int(parts[0], macros, depth + 1), parts[1], eval_int(parts[2], macros, depth + 1)
        if a is not None and b is not None:
            return a + b if op == '+' else a * b if op == '*' else a - b
    return None


def parse_enum(common=SRC_COMMON):
    t = strip_comments(read_text(os.path.join(common, 'PacketDefine.h')))
    body = t[t.index('{', t.index('enum PACKET_DEFINE')) + 1:]
    body = body[:body.index('}')]
    vals, cur = {}, -1
    for item in body.split(','):
        item = item.strip()
        if not item:
            continue
        m = re.match(r'^(\w+)\s*(?:=\s*(\w+))?$', item)
        if not m:
            continue
        cur = int(m.group(2), 0) if m.group(2) else cur + 1
        vals[m.group(1)] = cur
    return vals


def _split_args(s):
    out, depth, cur = [], 0, ''
    for c in s:
        if c in '([':
            depth += 1
        elif c in ')]':
            depth -= 1
        if c == ',' and depth == 0:
            out.append(cur)
            cur = ''
        else:
            cur += c
    out.append(cur)
    return [x.strip() for x in out]


class Cls(object):
    def __init__(self, name, header):
        self.name = name
        self.header = header
        self.enum = None
        self.id = None
        self.members = {}        # name -> (type, [dims])
        self.read = None         # list of ops
        self.read_src = None


def parse_members(body):
    members = {}
    # drop nested blocks (method bodies, enums, nested structs)
    flat, i = '', 0
    while i < len(body):
        if body[i] == '{':
            i = match_brace(body, i) + 1
            flat += ';'
            continue
        flat += body[i]
        i += 1
    flat = re.sub(r'\b(public|private|protected)\s*:', ' ', flat)
    for decl in flat.split(';'):
        if '(' in decl or 'typedef' in decl or 'enum' in decl or 'friend' in decl:
            continue
        m = re.match(r'^\s*(?:(?:mutable|const|unsigned|signed|struct|class)\s+)*([A-Za-z_][\w:]*)\s*\*?\s*'
                     r'([A-Za-z_]\w*)\s*((?:\[[^\]]*\])*)\s*$', decl)
        if m:
            dims = re.findall(r'\[([^\]]*)\]', m.group(3))
            members[m.group(2)] = (m.group(1), dims)
    return members


class ReadParser(object):
    def __init__(self, cls, sizes, macros):
        self.cls, self.sizes, self.macros = cls, sizes, macros

    def member_size(self, name):
        base = re.split(r'[.\[\-]', name.strip())[0]
        if base not in self.cls.members:
            return None, None
        typ, dims = self.cls.members[base]
        sz = self.sizes.get(typ)
        if sz is None:
            return typ, None
        if name.strip() == base:
            for d in dims:
                n = eval_int(d, self.macros)
                if n is None:
                    return typ, None
                sz *= n
        return typ, sz

    def size_expr(self, s):
        s = s.replace(' ', '')
        m = re.match(r'^sizeof\(([^()]+)\)(?:\*(.+))?$', s) or re.match(r'^(.+?)\*sizeof\(([^()]+)\)$', s)
        if m and s.startswith('sizeof'):
            inner, mult = m.group(1), m.group(2)
        elif m:
            mult, inner = m.group(1), m.group(2)
        else:
            n = eval_int(s, self.macros)
            return (n, None, None) if n is not None else (None, None, s)
        t = inner
        esz = self.sizes.get(t)
        if esz is None:
            _, esz = self.member_size(t)
        if mult is None:
            return esz, t, None
        n = eval_int(mult, self.macros)
        if n is not None and esz is not None:
            return esz * n, t, None
        return None, t, mult

    def classify(self, stmt):
        m = re.search(r'\w+\s*\.\s*Read\s*\((.*)\)\s*$', stmt, flags=re.S)
        if m and re.search(r'\biStream\s*\.\s*Read\s*\(', stmt):
            a = _split_args(re.search(r'\biStream\s*\.\s*Read\s*\((.*)\)\s*$', stmt, flags=re.S).group(1))
            if len(a) < 2:
                return None
            target = re.sub(r'\(\s*(?:const\s+)?(?:CHAR|char|BYTE|UCHAR|VOID|void)\s*\*\s*\)', '', a[0])
            target = target.replace('&', '').replace('(', '').replace(')', '').strip()
            size, etype, dyn = self.size_expr(a[1])
            op = {'k': 'f', 'target': target, 'size': size, 'size_expr': a[1].strip()}
            if etype:
                op['elem'] = etype
            if dyn:
                op['count'] = dyn
            return op
        m = re.search(r'([A-Za-z_][\w\.\[\]\->]*)\s*(?:\.|->)\s*(Read\w*)\s*\(\s*iStream\s*\)', stmt)
        if m:
            return {'k': 's', 'target': m.group(1), 'method': m.group(2)}
        m = re.search(r'\biStream\s*\.\s*Skip\s*\((.*)\)', stmt)
        if m:
            size, _, dyn = self.size_expr(m.group(1))
            return {'k': 'f', 'target': '<skip>', 'size': size, 'size_expr': m.group(1)}
        return None

    def parse(self, s):
        ops, i, n = [], 0, len(s)
        while i < n:
            while i < n and s[i] in ' \t\r\n;':
                i += 1
            if i >= n:
                break
            m = re.match(r'(if|for|while|switch)\s*\(', s[i:])
            if m:
                kw = m.group(1)
                j = i + m.end() - 1
                depth, k = 0, j
                while k < n:
                    if s[k] == '(':
                        depth += 1
                    elif s[k] == ')':
                        depth -= 1
                        if depth == 0:
                            break
                    k += 1
                head = s[j + 1:k]
                body, i = self.stmt_or_block(s, k + 1)
                op = {'k': 'loop' if kw in ('for', 'while') else kw, 'head': ' '.join(head.split()),
                      'body': self.parse(body)}
                if kw == 'if':
                    rest = s[i:].lstrip()
                    if rest.startswith('else') and not re.match(r'else\w', rest):
                        i = n - len(rest) + 4
                        eb, i = self.stmt_or_block(s, i)
                        op['else'] = self.parse(eb)
                ops.append(op)
                continue
            if s[i] == '{':
                j = match_brace(s, i)
                ops.extend(self.parse(s[i + 1:j]))
                i = j + 1
                continue
            j, depth = i, 0
            while j < n and not (s[j] == ';' and depth == 0):
                if s[j] in '({':
                    depth += 1
                elif s[j] in ')}':
                    depth -= 1
                j += 1
            op = self.classify(s[i:j])
            if op:
                ops.append(op)
            i = j + 1
        return ops

    def stmt_or_block(self, s, i):
        while i < len(s) and s[i] in ' \t\r\n':
            i += 1
        if i < len(s) and s[i] == '{':
            j = match_brace(s, i)
            return s[i + 1:j], j + 1
        m = re.match(r'(if|for|while)\s*\(', s[i:])
        if m:
            # nested control statement without braces: take up to its end
            sub = ReadParser(self.cls, self.sizes, self.macros)
            k = i + m.end() - 1
            depth = 0
            while k < len(s):
                if s[k] == '(':
                    depth += 1
                elif s[k] == ')':
                    depth -= 1
                    if depth == 0:
                        break
                k += 1
            inner, end = sub.stmt_or_block(s, k + 1)
            return s[i:end], end
        j, depth = i, 0
        while j < len(s) and not (s[j] == ';' and depth == 0):
            if s[j] in '({':
                depth += 1
            elif s[j] in ')}':
                depth -= 1
            j += 1
        return s[i:j + 1], j + 1


def load_classes(common=SRC_COMMON):
    sizes, macros = load_types(common)
    enum = parse_enum(common)
    pdir = os.path.join(common, 'Packets')
    texts = {}
    for fn in sorted(os.listdir(pdir)):
        if fn.endswith(('.h', '.cpp', '.inl')):
            texts[fn] = strip_comments(read_text(os.path.join(pdir, fn)))
    classes = {}
    for fn, t in texts.items():
        if not fn.endswith('.h'):
            continue
        for m in re.finditer(r'class\s+(\w+)\s*:\s*public\s+Packet\b[^{]*\{', t):
            c = Cls(m.group(1), fn)
            j = match_brace(t, m.end() - 1)
            body = t[m.end():j]
            pm = re.search(r'GetPacketID\s*\(\s*\)\s*const\s*\{\s*return\s+(\w+)\s*;', body)
            if pm:
                c.enum = pm.group(1)
                c.id = enum.get(c.enum)
            c.members = parse_members(body)
            classes[c.name] = (c, body)
    out = {}
    for name, (c, body) in classes.items():
        src = None
        for fn, t in texts.items():
            m = re.search(r'\b%s\s*::\s*Read\s*\(\s*SocketInputStream\s*&\s*\w+\s*\)\s*\{' % re.escape(name), t)
            if m:
                src = (fn, t, m.end() - 1)
                break
        if src is None:
            m = re.search(r'\bRead\s*\(\s*SocketInputStream\s*&\s*\w+\s*\)\s*\{', body)
            if m:
                src = (c.header, body, m.end() - 1)
        if src is not None:
            fn, t, i = src
            j = match_brace(t, i)
            c.read_src = fn
            c.read = ReadParser(c, sizes, macros).parse(t[i + 1:j])
        out[name] = c
    return out, sizes, macros, enum
