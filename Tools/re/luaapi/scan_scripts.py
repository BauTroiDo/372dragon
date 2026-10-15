# -*- coding: utf-8 -*-
"""Count host-API calls in the client_GL UI scripts (read-only).

Same tokenizer/rules as Docs/evidence/lua_api_gap.py (so numbers stay comparable),
but keeps per-(receiver, method) counts for ALL methods and global calls, plus
the set of names defined in Lua (those are not host functions).

Output: CY-Source/Build/re/luaapi/script_calls.json
"""
import collections, json, os, re

GL = r'C:\TLBB\085\client_GL'
OUT = r'C:\TLBB\085\CY-Source\Build\re\luaapi\script_calls.json'
KW = set('if then else elseif end while do for in repeat until function local return break and or not nil true false goto'.split())


def strip_lua(code):
    code = re.sub(r'--\[(=*)\[.*?\]\1\]', ' ', code, flags=re.S)
    code = re.sub(r'--[^\n]*', ' ', code)
    code = re.sub(r'\[(=*)\[.*?\]\1\]', '""', code, flags=re.S)
    code = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', code)
    code = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", code)
    return code


def lua_files():
    for sub in ('InterfaceFolder', 'Interface'):
        d = os.path.join(GL, 'Data', sub)
        if os.path.isdir(d):
            base = d
            break
    else:
        base = os.path.join(GL, 'Data')
    for r, _, fs in os.walk(base):
        for f in fs:
            if f.lower().endswith('.lua'):
                yield os.path.join(r, f)


def main():
    pairs = collections.Counter()
    files_per_method = collections.defaultdict(set)
    globals_called = collections.Counter()
    files_per_global = collections.defaultdict(set)
    defined = set()
    nfiles = 0
    for p in lua_files():
        nfiles += 1
        raw = open(p, 'rb').read()
        try:
            code = raw.decode('utf-8')
        except UnicodeDecodeError:
            code = raw.decode('gbk', errors='replace')
        code = strip_lua(code)
        rel = os.path.relpath(p, GL)
        for m in re.finditer(r'function\s+([A-Za-z_][\w\.:]*)\s*\(', code):
            defined.add(re.split(r'[.:]', m.group(1))[-1])
        for m in re.finditer(r'([A-Za-z_]\w*)\s*=\s*function\b', code):
            defined.add(m.group(1))
        for m in re.finditer(r'([A-Za-z_]\w*)\s*:\s*([A-Za-z_]\w*)\s*\(', code):
            pairs[(m.group(1), m.group(2))] += 1
            files_per_method[m.group(2)].add(rel)
        for m in re.finditer(r'(?<![\w\.:])([A-Za-z_]\w*)\s*\(', code):
            n = m.group(1)
            if n not in KW:
                globals_called[n] += 1
                files_per_global[n].add(rel)
    methods = {}
    for (rcv, meth), c in pairs.items():
        e = methods.setdefault(meth, {'calls': 0, 'receivers': {}, 'files': 0})
        e['calls'] += c
        e['receivers'][rcv] = e['receivers'].get(rcv, 0) + c
    for meth, e in methods.items():
        e['files'] = len(files_per_method[meth])
    res = {
        'source': os.path.join(GL, 'Data', 'InterfaceFolder'),
        'lua_files_scanned': nfiles,
        'methods': methods,
        'globals': {g: {'calls': c, 'files': len(files_per_global[g])} for g, c in globals_called.items()},
        'defined_in_lua': sorted(defined),
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(res, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    print('files', nfiles, 'methods', len(methods), 'globals', len(globals_called), 'defined', len(defined))


if __name__ == '__main__':
    main()
