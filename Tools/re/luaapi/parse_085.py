# -*- coding: utf-8 -*-
"""Parse the LuaPlus registrations of the 0.85 source (read-only reference).

Scans CY-Source/Src/Client/{WXClient,CEGUISystem} (UTF-8 copies of the 0.85 tree; falls back to
Reference if Src is missing) for
    <obj>.Register("Name", Func)                     -> global / table function
    <meta>->RegisterObjectFunctor("Name", &Cls::Fn)  -> method on a metatable
and resolves each metatable variable to its CreateTable("...") name and to the global names
under which boxed objects with that metatable are published (objGlobal.SetObject("X", obj)).

Output: CY-Source/Build/re/luaapi/reg085.json
  [{"file","line","table","globals":[...],"name","impl","cls"}...]
"""
import json, os, re

ROOTS = [r'C:\TLBB\085\CY-Source\Src\Client\WXClient', r'C:\TLBB\085\CY-Source\Src\Client\CEGUISystem']
REF = r'C:\TLBB\085\CY-Source\Reference\tlbb085\085\SourceCode\Client\天龙八部客户端\Client'
OUT = r'C:\TLBB\085\CY-Source\Build\re\luaapi\reg085.json'

RE_CREATE = re.compile(r'(?:\*\s*)?([\w:]+(?:->|\.)?[\w]*)\s*=\s*[^;]*?CreateTable\(\s*"([^"]+)"')
RE_CREATE_LOCAL = re.compile(r'LuaObject\s+(\w+)\s*=\s*[^;]*?CreateTable\(\s*"([^"]+)"')
RE_REG = re.compile(r'([\w:\->\.\*\(\)]+?)\s*(?:->|\.)\s*(RegisterObjectFunctor|RegisterDirect|RegisterObjectDirect|Register)\s*\(\s*"([^"]+)"\s*,\s*([^;]*?)\)\s*;')
RE_SETMETA = re.compile(r'(\w+)\s*\.\s*SetMetaTable\(\s*\*?\s*([\w:]+(?:->|\.)?\w*)\s*\)')
RE_SETOBJ = re.compile(r'([\w:\(\)\.\->]+?)\s*(?:->|\.)\s*SetObject\(\s*"([^"]+)"\s*,\s*\*?\s*([\w:]+(?:->|\.)?\w*)\s*\)')


def norm_var(v):
    v = v.strip().lstrip('*').strip()
    v = re.sub(r'\s+', '', v)
    return v


def read(p):
    b = open(p, 'rb').read()
    for enc in ('utf-8-sig', 'gb18030', 'gbk', 'cp1252'):
        try:
            return b.decode(enc)
        except UnicodeDecodeError:
            pass
    return b.decode('latin-1')


def strip_comments(t):
    t = re.sub(r'/\*.*?\*/', lambda m: '\n' * m.group(0).count('\n'), t, flags=re.S)
    t = re.sub(r'//[^\n]*', '', t)
    return t


def main():
    roots = [r for r in ROOTS if os.path.isdir(r)] or [os.path.join(REF, 'WXClient'), os.path.join(REF, 'CEGUISystem')]
    res = []
    for root in roots:
        for dp, _, fs in os.walk(root):
            for f in fs:
                if not f.lower().endswith(('.cpp', '.h', '.inl')):
                    continue
                p = os.path.join(dp, f)
                t = strip_comments(read(p))
                if 'Register' not in t:
                    continue
                meta_name = {}      # var -> CreateTable name
                meta_globals = {}   # table name -> [global names]
                obj_meta = {}       # local obj -> table name
                lines = t.split('\n')
                pending = []
                for ln, line in enumerate(lines, 1):
                    # *(g_theUIEventArg.m_pMetaTable) -> *g_theUIEventArg.m_pMetaTable   (UIScript.cpp style)
                    line = re.sub(r'\*\s*\(\s*([\w:\.]+(?:->[\w]+)?)\s*\)', r'*\1', line)
                    for m in RE_CREATE_LOCAL.finditer(line):
                        meta_name[m.group(1)] = m.group(2)
                    for m in RE_CREATE.finditer(line):
                        meta_name[norm_var(m.group(1))] = m.group(2)
                    for m in RE_SETMETA.finditer(line):
                        tv = norm_var(m.group(2))
                        obj_meta[m.group(1)] = meta_name.get(tv, tv)
                    for m in RE_SETOBJ.finditer(line):
                        name, val = m.group(2), norm_var(m.group(3))
                        if name == '__index':
                            continue
                        tn = obj_meta.get(val) or meta_name.get(val)
                        if tn:
                            meta_globals.setdefault(tn, [])
                            if name not in meta_globals[tn]:
                                meta_globals[tn].append(name)
                    for m in RE_REG.finditer(line):
                        var, how, name, rest = norm_var(m.group(1)), m.group(2), m.group(3), m.group(4)
                        impl = rest.split(',')[-1].strip().lstrip('&').strip() if how != 'Register' else rest.split(',')[0].strip().lstrip('&').strip()
                        if how == 'Register' and ',' in rest:
                            impl = rest.split(',')[0].strip().lstrip('&').strip()
                        table = meta_name.get(var)
                        if table is None:
                            if var in ('objGlobal', 'objGlobals') or 'GetGlobals()' in var:
                                table = '_G'
                            else:
                                table = '?' + var
                        cls = impl.rsplit('::', 1)[0] if '::' in impl else ''
                        pending.append({'file': os.path.relpath(p, r'C:\TLBB\085\CY-Source'), 'line': ln, 'var': var,
                                        'table': table, 'name': name, 'impl': impl, 'cls': cls, 'how': how})
                for e in pending:
                    e['globals'] = meta_globals.get(e['table'], ['_G'] if e['table'] == '_G' else [])
                res.extend(pending)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(res, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    tabs = {}
    for e in res:
        tabs.setdefault((e['table'], tuple(e['globals'])), 0)
        tabs[(e['table'], tuple(e['globals']))] += 1
    print('registrations', len(res), 'distinct names', len({e['name'] for e in res}))
    for (t, g), c in sorted(tabs.items(), key=lambda x: -x[1])[:60]:
        print('  %-40s %-40s %d' % (t, ','.join(g), c))


if __name__ == '__main__':
    main()
