#!/usr/bin/env python3
# CYS: Tests/abi/gen_abi_types.py - generates the input lists of Tests/abi/dump_sizes.cpp (Docs/04 section 6).
#
#   abi_headers.txt  every Src/Shared/Common header used by the WXNetPackets build (from `ninja -t deps`)
#   abi_headers.inc  #include lines for those headers
#   abi_types.inc    CYS_ABI_TYPE_BEGIN/CYS_ABI_FIELD/CYS_ABI_TYPE_END for every struct/class/union they define
#
# Usage:
#   python gen_abi_types.py --deps <ninja -t deps output of a tree that built cys_wxnetpackets>
#   python gen_abi_types.py            (reuses abi_headers.txt)
#
# The C++ scanner is deliberately small: it strips comments, evaluates #if/#ifdef with the WXNetPackets defines,
# tracks namespace/record/block scopes and reads data-member declarations (skipping functions, statics, bit-fields
# and references). Templates are skipped. Members of a `class` that precede the first access specifier cannot be
# reached from outside even with the private->public hack of dump_sizes.cpp, so they are listed but not dumped.
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
COMMON = os.path.join(ROOT, 'Src', 'Shared', 'Common')

# Preprocessor state of the WXNetPackets / Game.exe build (cys_common_headers + CYSCommon.cmake).
PREDEF = {
    '__WINDOWS__': '1', '_FOX_CLIENT': '1', '_FOX_SERVER': '1', '_FOX_LOGIN': '1', 'GAME_CLIENT': '1',
    'WIN32': '1', '_WIN32': '1', '_WINDOWS': '1', '_MSC_VER': '1944', 'NDEBUG': '1', '_MBCS': '1', '_LIB': '1',
    '__cplusplus': '201402',
}

# Types the scanner finds but that cannot be dumped (filled in from compile errors; keep the reason).
EXCLUDE_TYPES = {
}

KEYWORDS = set('''alignas alignof asm auto bool break case catch char char16_t char32_t class const constexpr const_cast
continue decltype default delete do double dynamic_cast else enum explicit export extern false float for friend goto if
inline int long mutable namespace new noexcept nullptr operator private protected public register reinterpret_cast
return short signed sizeof static static_assert static_cast struct switch template this thread_local throw true try
typedef typeid typename union unsigned using virtual void volatile wchar_t while __int64 __int32 __int16 __int8
__declspec __cdecl __stdcall __fastcall'''.split())

TOKEN_RE = re.compile(r'''
     (?P<nl>\n)
    |(?P<ws>[ \t\r\f\v]+)
    |(?P<id>[A-Za-z_]\w*)
    |(?P<num>\.?\d[\w.]*)
    |(?P<str>L?"(?:\\.|[^"\\\n])*")
    |(?P<chr>L?'(?:\\.|[^'\\\n])*')
    |(?P<op>::|->|\.\.\.|<<=|>>=|<<|>>|<=|>=|==|!=|&&|\|\||\+\+|--|[-+*/%&|^~!=<>?:;,.(){}\[\]#@$\\`])
    |(?P<other>.)
''', re.X)


def strip_comments(text):
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == '/' and i + 1 < n and text[i + 1] == '/':
            j = text.find('\n', i)
            if j < 0:
                break
            i = j
            continue
        if c == '/' and i + 1 < n and text[i + 1] == '*':
            j = text.find('*/', i + 2)
            if j < 0:
                break
            out.append('\n' * text.count('\n', i, j + 2))
            i = j + 2
            continue
        if c in '"\'':
            j = i + 1
            while j < n and text[j] != c and text[j] != '\n':
                j += 2 if text[j] == '\\' else 1
            out.append(text[i:j + 1])
            i = j + 1
            continue
        out.append(c)
        i += 1
    return ''.join(out)


def join_continuations(text):
    lines = text.split('\n')
    out, carry, pending = [], '', 0
    for ln in lines:
        if ln.endswith('\\'):
            carry += ln[:-1] + ' '
            pending += 1
            continue
        out.append(carry + ln)
        out.extend([''] * pending)
        carry, pending = '', 0
    if carry:
        out.append(carry)
    return '\n'.join(out)


def eval_cond(expr, defines):
    e = re.sub(r'defined\s*\(\s*(\w+)\s*\)', lambda m: '1' if m.group(1) in defines else '0', expr)
    e = re.sub(r'defined\s+(\w+)', lambda m: '1' if m.group(1) in defines else '0', e)

    def ident(m):
        v = defines.get(m.group(0))
        if v is None:
            return '0'
        v = v.strip()
        mm = re.fullmatch(r'\(?\s*(0[xX][0-9a-fA-F]+|\d+)[uUlL]*\s*\)?', v)
        return mm.group(1) if mm else '1'

    e = re.sub(r'\b[A-Za-z_]\w*\b', ident, e)
    e = re.sub(r'\b(0[xX][0-9a-fA-F]+|\d+)[uUlL]+\b', r'\1', e)
    e = e.replace('&&', ' and ').replace('||', ' or ')
    e = re.sub(r'!(?!=)', ' not ', e)
    try:
        return bool(eval(e, {'__builtins__': {}}, {}))
    except Exception:
        return False


def preprocess(text, defines):
    out, stack, active = [], [], True
    for ln in text.split('\n'):
        s = ln.strip()
        if s.startswith('#'):
            m = re.match(r'#\s*(\w+)\s*(.*)', s)
            kw, rest = (m.group(1), m.group(2).strip()) if m else ('', '')
            words = rest.split()
            if kw in ('if', 'ifdef', 'ifndef'):
                if kw == 'ifdef':
                    cond = bool(words) and words[0] in defines
                elif kw == 'ifndef':
                    cond = not (bool(words) and words[0] in defines)
                else:
                    cond = eval_cond(rest, defines)
                stack.append([active, cond])
                active = active and cond
            elif kw == 'elif' and stack:
                parent, taken = stack[-1]
                cond = (not taken) and eval_cond(rest, defines)
                stack[-1][1] = taken or cond
                active = parent and cond
            elif kw == 'else' and stack:
                parent, taken = stack[-1]
                stack[-1][1] = True
                active = parent and not taken
            elif kw == 'endif' and stack:
                active = stack.pop()[0]
            elif active and kw == 'define':
                m2 = re.match(r'(\w+)(\([^)]*\))?\s*(.*)', rest)
                if m2:
                    defines[m2.group(1)] = m2.group(3).strip() or '1'
            elif active and kw == 'undef' and words:
                defines.pop(words[0], None)
            out.append('')
        else:
            out.append(ln if active else '')
    return '\n'.join(out)


def tokenize(text):
    toks, line = [], 1
    for m in TOKEN_RE.finditer(text):
        k = m.lastgroup
        if k == 'nl':
            line += 1
        elif k != 'ws':
            toks.append((m.group(0), line))
    return toks


def strip_attrs(st):
    """Drop __declspec(...), alignas(...), __cdecl-like tokens from a statement."""
    out, i = [], 0
    while i < len(st):
        if st[i] in ('__declspec', 'alignas', '__attribute__') and i + 1 < len(st) and st[i + 1] == '(':
            depth, j = 0, i + 1
            while j < len(st):
                if st[j] == '(':
                    depth += 1
                elif st[j] == ')':
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            i = j + 1
            continue
        if st[i] in ('__cdecl', '__stdcall', '__fastcall', 'final'):
            i += 1
            continue
        out.append(st[i])
        i += 1
    return out


def strip_template_prefix(st):
    if not st or st[0] != 'template':
        return st, False
    depth, i = 0, 1
    while i < len(st):
        if st[i] == '<':
            depth += 1
        elif st[i] == '>':
            depth -= 1
            if depth == 0:
                return st[i + 1:], True
        elif st[i] == '>>':
            depth -= 2
            if depth <= 0:
                return st[i + 1:], True
        i += 1
    return [], True


def is_ident(t):
    return bool(re.fullmatch(r'[A-Za-z_]\w*', t))


def split_declarators(st):
    out, cur, depth = [], [], 0
    for t in st:
        if t in ('(', '[', '<', '{'):
            depth += 1
        elif t in (')', ']', '>', '}'):
            depth -= 1
        elif t == '>>':
            depth -= 2
        if t == ',' and depth == 0:
            out.append(cur)
            cur = []
        else:
            cur.append(t)
    if cur:
        out.append(cur)
    return out


def declarator_name(d):
    b = d.index('[') if '[' in d else len(d)
    for i in range(b - 1, -1, -1):
        t = d[i]
        if is_ident(t) and t not in KEYWORDS:
            return i
    return None


class Scope:
    def __init__(self, kind, name='', rkind='', template=False, typedef=False, line=0, hidden=False):
        self.kind = kind          # ns, xc (extern "C"), rec, blk, enum
        self.name = name
        self.rkind = rkind        # struct / class / union
        self.template = template
        self.typedef = typedef
        self.line = line
        self.hidden = hidden      # declared in the implicit-private part of a class (cannot be named)
        self.members = []         # (name, type text, accessible)
        self.access_seen = False
        self.stmt = []
        self.pending = None


class Scanner:
    def __init__(self):
        self.types = []
        self.anon = {}            # '<anon@file:line>' -> members of an unnamed struct/union used by a declarator

    def qualify(self, scopes, name):
        parts = [s.name for s in scopes if s.kind in ('ns', 'rec') and s.name]
        return '::' + '::'.join(parts + [name])

    def accessible(self, rec):
        return rec.rkind != 'class' or rec.access_seen

    def in_template(self, scopes):
        return any(s.kind == 'rec' and (s.template or s.hidden) for s in scopes)

    def add_type(self, scopes, name, rec, relpath):
        if rec.template or rec.hidden or self.in_template(scopes):
            return
        self.types.append({'name': self.qualify(scopes, name), 'file': relpath, 'line': rec.line,
                           'kind': rec.rkind, 'members': list(rec.members)})

    def member(self, rec, st):
        st = strip_attrs(st)
        if not st or st[0] in ('typedef', 'using', 'friend', 'static', 'template', 'public', 'private', 'protected',
                               'virtual', 'explicit', 'inline', 'static_assert', 'operator', 'constexpr', '~'):
            return
        if any(t in ('(', ')', 'operator', 'static', ':') for t in st):
            return
        while st and st[0] in ('struct', 'class', 'union', 'enum', 'mutable', 'typename'):
            st = st[1:]
        if '=' in st:
            st = st[:st.index('=')]
        decls = split_declarators(st)
        if not decls:
            return
        acc = self.accessible(rec)
        first = decls[0]
        ni = declarator_name(first)
        if ni is None or ni == 0 or '&' in first or '&&' in first:
            return
        base = first[:ni]
        suffix = first[ni + 1:]
        rec.members.append((first[ni], ' '.join(base + suffix), acc))
        base_nostar = [t for t in base if t != '*']
        for d in decls[1:]:
            ni = declarator_name(d)
            if ni is None or '&' in d:
                continue
            stars = [t for t in d[:ni] if t == '*']
            rec.members.append((d[ni], ' '.join(base_nostar + stars + d[ni + 1:]), acc))

    def scan(self, toks, relpath):
        scopes = [Scope('ns')]
        for t, line in toks:
            top = scopes[-1]
            if top.kind in ('blk', 'enum'):
                if t == '{':
                    scopes.append(Scope('blk'))
                elif t == '}':
                    closed = scopes.pop()
                    parent = scopes[-1]
                    if parent.kind not in ('blk', 'enum'):
                        parent.stmt = ['<SKIP>'] if closed.kind == 'enum' else []
                continue
            if t == '{':
                st = strip_attrs(top.stmt)
                if st and st[0] == 'namespace':
                    scopes.append(Scope('ns', name=st[1] if len(st) > 1 and is_ident(st[1]) else ''))
                elif len(st) >= 2 and st[0] == 'extern' and st[1].startswith('"'):
                    scopes.append(Scope('xc'))
                else:
                    core, tmpl = strip_template_prefix(st)
                    kinds = [i for i, x in enumerate(core) if x in ('struct', 'class', 'union')]
                    enum_i = core.index('enum') if 'enum' in core else None
                    if '(' in core or (not kinds and enum_i is None):
                        scopes.append(Scope('blk'))
                    elif enum_i is not None and (not kinds or enum_i < kinds[0]):
                        scopes.append(Scope('enum'))
                    else:
                        k = kinds[0]
                        name = core[k + 1] if (k + 1 < len(core) and is_ident(core[k + 1])
                                               and core[k + 1] not in KEYWORDS) else ''
                        hidden = top.kind == 'rec' and not self.accessible(top)
                        scopes.append(Scope('rec', name=name, rkind=core[k], template=tmpl,
                                            typedef=bool(core) and core[0] == 'typedef', line=line, hidden=hidden))
                continue
            if t == '}':
                if len(scopes) == 1:
                    continue
                closed = scopes.pop()
                parent = scopes[-1]
                if closed.kind == 'rec':
                    if closed.name:
                        self.add_type(scopes, closed.name, closed, relpath)
                    parent.stmt = ['<REC>']
                    parent.pending = closed
                else:
                    parent.stmt = []
                continue
            if t == ';':
                st = top.stmt
                if st and st[0] == '<REC>' and top.pending is not None:
                    rec = top.pending
                    decls = split_declarators(st[1:])
                    names = []
                    for d in decls:
                        ni = declarator_name(d)
                        if ni is not None and '*' not in d[:ni] and '[' not in d:
                            names.append(d[ni])
                        elif ni is not None:
                            names.append(None)
                    if rec.typedef:
                        if not rec.name and names and names[0]:
                            self.add_type(scopes, names[0], rec, relpath)
                    elif top.kind == 'rec':
                        dnames = [d[declarator_name(d)] for d in decls if declarator_name(d) is not None]
                        if dnames:
                            acc = self.accessible(top)
                            tname = rec.name
                            if not tname:
                                tname = '<anon@%s:%d>' % (relpath, rec.line)
                                self.anon[tname] = list(rec.members)
                            for d in decls:
                                ni = declarator_name(d)
                                if ni is None:
                                    continue
                                tt = tname + ' ' + ' '.join(
                                    [x for x in d[:ni] if x == '*'] + d[ni + 1:])
                                top.members.append((d[ni], tt.strip(), acc and not rec.hidden))
                        elif not rec.name:
                            acc = self.accessible(top)
                            for (mn, mt, ma) in rec.members:
                                top.members.append((mn, mt, ma and acc))
                elif st and st[0] == '<SKIP>':
                    pass
                elif top.kind == 'rec':
                    self.member(top, st)
                top.stmt = []
                top.pending = None
                continue
            if t == ':' and top.kind == 'rec' and top.stmt in (['public'], ['private'], ['protected']):
                top.access_seen = True
                top.stmt = []
                continue
            top.stmt.append(t)


def headers_from_deps(deps_path):
    hdrs = set()
    prefix = 'src/shared/common/'
    for raw in open(deps_path, encoding='utf-8-sig', errors='replace'):
        s = raw.strip().replace('\\', '/')
        if not raw.startswith((' ', '\t')) or not s.lower().endswith('.h'):
            continue
        low = s.lower()
        k = low.find(prefix)
        if k < 0:
            continue
        rel = s[k + len(prefix):]
        full = os.path.join(COMMON, rel)
        if os.path.isfile(full):
            hdrs.add(rel)
    return sorted(hdrs, key=str.lower)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--deps', help='output of `ninja -t deps` for a tree that built cys_wxnetpackets')
    args = ap.parse_args()
    list_path = os.path.join(HERE, 'abi_headers.txt')
    if args.deps:
        headers = headers_from_deps(args.deps)
        with open(list_path, 'w', encoding='utf-8', newline='\n') as f:
            f.write('# CYS: Src/Shared/Common headers used by cys_wxnetpackets (gen_abi_types.py --deps)\n')
            f.write('\n'.join(headers) + '\n')
    else:
        headers = [l.strip() for l in open(list_path, encoding='utf-8') if l.strip() and not l.startswith('#')]

    scanner = Scanner()
    defines = dict(PREDEF)
    for rel in headers:
        text = open(os.path.join(COMMON, rel), 'rb').read().decode('utf-8-sig', errors='replace')
        text = preprocess(join_continuations(strip_comments(text)), defines)
        scanner.scan(tokenize(text), rel)

    seen, types = set(), []
    for t in scanner.types:
        if t['name'] in seen or t['name'].lstrip(':') in EXCLUDE_TYPES:
            continue
        seen.add(t['name'])
        types.append(t)

    with open(os.path.join(HERE, 'abi_headers.inc'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('// Generated by Tests/abi/gen_abi_types.py - do not edit.\n')
        for rel in headers:
            f.write('#include "%s"\n' % rel)

    nfields = 0
    with open(os.path.join(HERE, 'abi_types.inc'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('// Generated by Tests/abi/gen_abi_types.py - do not edit.\n')
        by_file = {}
        for t in types:
            by_file.setdefault(t['file'], []).append(t)
        for rel in headers:
            if rel not in by_file:
                continue
            hid = re.sub(r'\W', '_', rel)
            f.write('CYS_ABI_HEADER_BEGIN(%s)\n' % hid)
            for t in by_file[rel]:
                f.write('CYS_ABI_TYPE_BEGIN(%s, "%s", "%s", %d)\n' % (t['name'], t['name'][2:], rel, t['line']))
                for (mn, mt, acc) in t['members']:
                    mt = mt.replace('\\', '/').replace('"', "'")
                    if acc:
                        f.write('CYS_ABI_FIELD(%s, "%s")\n' % (mn, mt))
                        nfields += 1
                    else:
                        f.write('// implicit-private: %s %s\n' % (mt, mn))
                f.write('CYS_ABI_TYPE_END()\n')
            f.write('CYS_ABI_HEADER_END()\n')
    print('headers %d, types %d, fields %d' % (len(headers), len(types), nfields))


if __name__ == '__main__':
    main()
