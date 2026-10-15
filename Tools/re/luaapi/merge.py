# -*- coding: utf-8 -*-
"""Merge Ghidra extraction + script usage + 0.85 source + protocol spec into the Lua host-API catalog.

Inputs (produced by the other tools in this folder; sources are read-only):
  Build/re/luaapi/reg_Game.exe.jsonl, reg_UI_CEGUI.dll.jsonl   LuaApiDump.java reg
  Build/re/luaapi/script_calls.json                            scan_scripts.py
  Build/re/luaapi/reg085.json                                  parse_085.py
  Build/re/luaapi/decomp/<module>/<va-hex>.c                   LuaApiDump.java decomp (top-N, optional)
  Registry/protocol/packets_summary.tsv                        packet ids/names (skynet spec)
  Docs/evidence/lua_api_gap_methods.tsv                        the 2,185-name gap list (cross-check)
  client/Bin64 + client_GL/Bin64 binaries                      byte-identity check of every function

Outputs:
  Registry/luaapi/catalog.json, catalog.tsv (README in the TSV header comments)
  Build/re/luaapi/merge_report.txt  (+ copy in Build/Logs/2026-09-12-luaapi)
"""
import collections, hashlib, json, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pe_util import PE

CY = r'C:\TLBB\085\CY-Source'
B = os.path.join(CY, r'Build\re\luaapi')
REG = os.path.join(CY, r'Registry\luaapi')
LOGS = os.path.join(CY, r'Build\Logs\2026-09-12-luaapi')
MODULES = {
    'Game.exe': {'jsonl': os.path.join(B, 'reg_Game.exe.jsonl'),
                 'bins': {'client': r'C:\TLBB\085\client\Bin64\Game.exe', 'client_GL': r'C:\TLBB\085\client_GL\Bin64\Game.exe'}},
    'UI_CEGUI.dll': {'jsonl': os.path.join(B, 'reg_UI_CEGUI.dll.jsonl'),
                     'bins': {'client': r'C:\TLBB\085\client\Bin64\UI_CEGUI.dll', 'client_GL': r'C:\TLBB\085\client_GL\Bin64\UI_CEGUI.dll'}},
}

PUSH_TYPE = {
    'lua_pushnumber': 'number', 'LuaState::PushNumber': 'number', 'LuaState::PushInteger': 'number',
    'lua_pushstring': 'string', 'LuaState::PushString': 'string', 'lua_pushlstring': 'string', 'LuaState::PushLString': 'string',
    'lua_pushboolean': 'boolean', 'LuaState::PushBoolean': 'boolean',
    'lua_pushnil': 'nil', 'lua_newtable': 'table', 'LuaState::BoxPointer': 'object', 'lua_pushvalue': 'value',
    'LuaObject::PushStack': 'object', 'lua_pushlightuserdata': 'object', 'lua_pushcclosure': 'function',
}
LUA_T = {0: 'nil', 1: 'boolean', 2: 'lightuserdata', 3: 'number', 4: 'string', 5: 'table', 6: 'function', 7: 'userdata'}
NOISY_CLS = ('CEGUI::', 'std::', 'type_info', 'tNode', 'tActionReference')


def load_jsonl(p):
    return [json.loads(l) for l in open(p, encoding='utf-8')]


def ihex(s):
    return int(s, 16)


def norm(x):
    return (x or '').replace('MetaTable_Control_', '').replace('MetaTable', '').replace('Table', '').replace('(table)', '').replace('(env)', '').lower()


# ----------------------------------------------------------------------------- byte identity
class Ident:
    def __init__(self, bins):
        self.pes = {k: PE(v) for k, v in bins.items()}

    def check(self, idrec):
        if not idrec or not idrec.get('sha1'):
            return 'unknown'
        res = []
        for k, pe in self.pes.items():
            h = hashlib.sha1()
            ok = True
            for rva, ln in idrec['ranges']:
                b = pe.read(rva, ln)
                if b is None or len(b) != ln:
                    ok = False
                    break
                h.update(b)
            if ok and h.hexdigest() == idrec['sha1']:
                res.append(k)
        if len(res) == len(self.pes):
            return 'same'
        return ('only:' + '+'.join(res)) if res else 'differs'


# ----------------------------------------------------------------------------- receivers
def latest(defs, key, addr):
    best = None
    for a, n, how in defs.get(key, []):
        if a <= addr and (best is None or a >= best[0]):
            best = (a, n, how)
    return best


def earliest(defs, key):
    l = defs.get(key, [])
    return min(l) if l else None


def resolve_receivers(recs):
    """Name every registration's receiver key from the LuaPlus plumbing events (address order)."""
    evs = sorted([r for r in recs if r['t'] == 'ev'], key=lambda e: ihex(e['site']))
    regs = [r for r in recs if r['t'] == 'reg']
    # names passed in by callers (LuaExport<T>-style constructors: CreateTable(globals, name) / SetObject(name, obj)
    # with name = a parameter).  Build/re/luaapi/callargs_<module>.jsonl comes from LuaApiDump.java callargs.
    info = next(r for r in recs if r['t'] == 'info')
    cpath = os.path.join(B, 'callargs_%s.jsonl' % info['name'])
    callnames = collections.defaultdict(set)
    if os.path.isfile(cpath):
        for c in load_jsonl(cpath):
            for reg in ('rcx', 'rdx', 'r8', 'r9'):
                if c.get(reg + '_str'):
                    callnames[(c['callee'], reg.upper())].add(c[reg + '_str'])
    for e in evs:
        slot = 'r8_val' if e['op'] in ('LuaObject::CreateTable', 'LuaObject::GetByName') else 'rdx_val'
        if not e.get('str') and e.get(slot, '').startswith('param:') and e['op'] in ('LuaObject::CreateTable', 'LuaObject::SetObject'):
            ns = callnames.get((e['func'], e[slot].split(':')[1].split('+')[0]))
            if ns and len(ns) == 1:
                e['str'] = next(iter(ns))
                e['str_how'] = 'caller-arg'
    defs = collections.defaultdict(list)      # key -> [(addr, name, how)]
    for e in evs:
        a = ihex(e['site'])
        if e['op'] == 'LuaObject::CreateTable' and e.get('str'):
            defs[e['rdx']].append((a, e['str'], 'CreateTable@' + e['site']))
            defs['r:' + e['site']].append((a, e['str'], 'CreateTable@' + e['site']))
        elif e['op'] == 'LuaState::GetGlobals':
            defs[e['rdx']].append((a, '_G', 'GetGlobals@' + e['site']))
            defs['r:' + e['site']].append((a, '_G', 'GetGlobals@' + e['site']))
    for e in evs:                                # operator= : target := source
        if e['op'] == 'LuaObject::operator=':
            a = ihex(e['site'])
            src = latest(defs, e['rdx'], a)
            if src:
                defs[e['rcx']].append((a, src[1], 'assign@' + e['site'] + '<-' + src[2]))
    for e in evs:                                # GetByName: child tables
        if e['op'] == 'LuaObject::GetByName' and e.get('str'):
            a = ihex(e['site'])
            par = latest(defs, e['rcx'], a)
            nm = e['str'] if not par or par[1] == '_G' else par[1] + '.' + e['str']
            defs[e['rdx']].append((a, nm, 'GetByName@' + e['site']))
            defs['r:' + e['site']].append((a, nm, 'GetByName@' + e['site']))
    box_of = collections.defaultdict(list)       # BoxPointer retbuf / LuaObject(LuaStackObject) -> boxed object
    for e in evs:
        a = ihex(e['site'])
        if e['op'] == 'LuaState::BoxPointer' and e['r8_val'].startswith('addr:'):
            box_of[e['rdx']].append((a, e['r8_val'][5:], 'BoxPointer@' + e['site']))
            box_of['r:' + e['site']].append((a, e['r8_val'][5:], 'BoxPointer@' + e['site']))
        elif e['op'] == 'LuaObject::ctor':
            src = latest(box_of, e['rdx'], a)
            if src:
                box_of[e['rcx']].append((a, src[1], 'ctor@' + e['site']))
    meta_of = collections.defaultdict(list)
    globals_of = collections.defaultdict(list)   # metatable name -> global names (ordered)
    meta_box = collections.defaultdict(set)      # metatable name -> boxed objects
    for e in evs:
        a = ihex(e['site'])
        if e['op'] == 'LuaObject::SetMetaTable':
            m = latest(defs, e['rdx'], a) or earliest(defs, e['rdx'])
            meta_of[e['rcx']].append((a, m[1] if m else e['rdx'], e['rdx']))
            b = latest(box_of, e['rcx'], a)
            if b and m:
                meta_box[m[1]].add(b[1])
        elif e['op'] == 'LuaObject::SetObject' and e.get('str') and e['str'] != '__index':
            par = latest(defs, e['rcx'], a)
            pname = par[1] if par else '?'
            if pname == '_G':
                gname = e['str']
            elif pname == '?':
                gname = e['str'] + '(env)'      # key in a per-window script environment (e.g. "this")
            else:
                gname = pname + '.' + e['str']
            mo = latest(meta_of, e['r8'], a)
            if mo:
                if gname not in globals_of[mo[1]]:
                    globals_of[mo[1]].append(gname)
            else:
                t = latest(defs, e['r8'], a) or earliest(defs, e['r8'])
                if t and t[1] != '_G' and gname + '(table)' not in globals_of[t[1]]:
                    globals_of[t[1]].append(gname + '(table)')
    out = []
    for r in regs:
        a = ihex(r['site'])
        d = latest(defs, r['meta_key'], a) or earliest(defs, r['meta_key'])
        mname = d[1] if d else None
        out.append((r, mname, list(globals_of.get(mname, [])) if mname else [], d[2] if d else None))
    return out, globals_of, meta_box, defs


def pick_box_class(cands, mname, gl):
    parsed = [c.split('@') for c in cands]
    sb = [c for c in parsed if c[0].startswith(('SCRIPT_SANDBOX::', 'LUA_CONTROL::'))]
    if not sb:
        return None
    keys = {norm(mname)} | {norm(g) for g in gl}
    for c in sb:
        if c[0].split('::')[-1].lower() in keys:
            return c[0], 'boxed-object(name-match)'
    d0 = [c for c in sb if c[2] == 'd0'] or sb
    return d0[0][0], 'boxed-object(first vftable written)'


# ----------------------------------------------------------------------------- impl semantics
RE_READ = re.compile(r'^(?P<fn>[\w:]+)\((?P<idx>[^)]*)\)(?P<extra>[=:][\w-]+)?@(?P<at>[0-9a-f]+)$')


def arg_types(impl, is_method):
    per = collections.OrderedDict()
    for r in impl.get('reads', []):
        m = RE_READ.match(r)
        if not m:
            continue
        fn, idx, extra = m.group('fn'), m.group('idx'), m.group('extra') or ''
        if not idx.lstrip('-').isdigit():
            continue
        i = int(idx)
        if i < 0:
            continue
        t = None
        if fn == 'lua_tonumber':
            t = 'int' if extra == ':int' else 'number'
        elif fn in ('lua_tostring', 'LuaStackObject::GetString'):
            t = 'string'
        elif fn in ('lua_isstring', 'LuaStackObject::IsString'):
            t = 'string?'
        elif fn in ('lua_isnumber', 'LuaStackObject::IsInteger'):
            t = 'number?'
        elif fn == 'LuaStackObject::GetInteger':
            t = 'int'
        elif fn in ('LuaStackObject::GetBoolean', 'lua_toboolean'):
            t = 'boolean'
        elif fn in ('lua_touserdata', 'lua_isuserdata'):
            t = 'userdata'
        elif fn == 'lua_type':
            t = (LUA_T.get(int(extra[1:]), 'any') + '?') if extra.startswith('=') and extra[1:].lstrip('-').isdigit() else 'any?'
        elif fn == 'LuaStackObject':
            t = 'any?'
        if t is None:
            continue
        prev = per.get(i)
        if prev is None or (prev.endswith('?') and not t.endswith('?')) or (prev == 'number' and t == 'int'):
            per[i] = t
    res = []
    for i in sorted(per):
        pos = i - 1 if is_method else i
        if pos >= 1:
            res.append((pos, per[i]))
    return res


def helper_kinds(impl):
    kinds = collections.Counter()
    for h in impl.get('helper_pushes', []):
        body = h.split(':', 1)[1].strip().strip('{}') if ':' in h else ''
        for kv in body.split(','):
            if '=' in kv:
                k, v = kv.strip().rsplit('=', 1)
                kinds[PUSH_TYPE.get(k.strip(), 'value')] += int(v)
    return kinds


RE_C_RETVAL = re.compile(r'return\s+(-?\d+|\w+)\s*;')
RE_C_PUSH = re.compile(r'\b(lua_push\w+|lua_newtable|Push(?:Number|Integer|String|LString|Boolean|Stack)|BoxPointer)\s*\(')


def c_push_type(p):
    if p.startswith('lua_'):
        return PUSH_TYPE.get(p, 'value')
    return {'PushNumber': 'number', 'PushInteger': 'number', 'PushString': 'string', 'PushLString': 'string',
            'PushBoolean': 'boolean', 'PushStack': 'object', 'BoxPointer': 'object'}.get(p, 'value')


def decomp_c_ret(c):
    """Largest result count returned (return N; or X = N; ... return X;) and the pushes textually preceding it."""
    points = []                                  # (text position, value)
    for m in RE_C_RETVAL.finditer(c):
        v = m.group(1)
        if v.lstrip('-').isdigit():
            points.append((m.start(), int(v)))
        else:
            for a in re.finditer(r'\b%s\s*=\s*(-?\d+)\s*;' % re.escape(v), c):
                points.append((a.start(), int(a.group(1))))
    points = sorted(p for p in points if 0 <= p[1] <= 64)
    if not points:
        return None
    n = max(v for _, v in points)
    if n == 0:
        return 0, [], 'decomp'
    best = None
    for i, (pos, v) in enumerate(points):
        if v != n:
            continue
        start = points[i - 1][0] if i > 0 else 0
        pushes = [c_push_type(m.group(1)) for m in RE_C_PUSH.finditer(c[start:pos])]
        if best is None or abs(len(pushes) - n) < abs(len(best) - n):
            best = pushes
    if best is None:
        return None
    if len(best) == n:
        return n, best, 'decomp'
    if len(best) > n and len(best) % n == 0 and best[:n] * (len(best) // n) == best:
        return n, best[:n], 'decomp(branches)'
    if best and len(set(best)) == 1:
        return n, [best[0]] * n, 'decomp-uniform'
    return None


def ret_info(impl, decomp_c=None):
    rets = impl.get('rets', [])
    ints = []
    for x in rets:
        x2 = x[5:] if x.startswith('addr:') else x
        if x2.lstrip('-').isdigit() and 0 <= int(x2) <= 64:
            ints.append(int(x2))
    kinds = [PUSH_TYPE.get(p.split('@')[0], 'value') for p in impl.get('pushes', [])]
    if decomp_c:
        c = decomp_c_ret(decomp_c)
        if c and (not ints or c[0] == max(ints)):
            return c
    if not ints:
        return (None, [], 'tail-call') if impl.get('tail') else (None, [], 'unknown')
    n = max(ints)
    if n == 0:
        return 0, [], 'const'
    if len(kinds) == n:
        return n, kinds, 'pushes==ret'
    if kinds and len(set(kinds)) == 1:
        return n, [kinds[0]] * n, 'uniform-push'
    if len(kinds) > n:
        if len(kinds) % n == 0 and kinds[:n] * (len(kinds) // n) == kinds:
            return n, kinds[:n], 'pushes(branches)'
        return n, kinds[:n], 'first-pushes(heuristic)'
    hk = helper_kinds(impl)
    if hk:
        fill = hk.most_common(1)[0][0]
        return n, kinds + [fill] * (n - len(kinds)), 'pushes-in-helper(INFERENCE)'
    return n, kinds + ['?'] * (n - len(kinds)), 'partial'


RE_CLS = re.compile(r'\b(C[A-Z][A-Za-z0-9_]+|SCRIPT_SANDBOX::\w+|LUA_CONTROL::\w+)::(\w+)')


def subsystem(entry, impl):
    ev = []
    for s in (impl.get('strings') or []) + (impl.get('strings_d1') or []):
        m = RE_CLS.search(s)
        if m:
            ev.append(m.group(1))
    pk = [p.split('@')[0].replace('Packets::', '') for p in impl.get('packets', [])]
    cls = [c.replace('#rtti', '') for c in impl.get('classes', [])
           if not c.startswith('Packets::') and not c.startswith(NOISY_CLS) and '<' not in c and '?$' not in c]
    if ev:
        return collections.Counter(ev).most_common(1)[0][0], 'string-literal'
    if pk:
        pre = collections.Counter(re.sub(r'^(CG|GC|CW|WC|CL|LC)', '', p)[:10] for p in pk).most_common(1)[0][0]
        return 'packets:' + pre, 'packets'
    if cls:
        return cls[0], 'rtti-class'
    if entry['module'] == 'UI_CEGUI.dll':
        return 'UI:' + entry['receiver'].replace('MetaTable_Control_', ''), 'receiver'
    return entry['receiver'], 'receiver'


# ----------------------------------------------------------------------------- main
def main():
    script = json.load(open(os.path.join(B, 'script_calls.json'), encoding='utf-8'))
    reg085 = json.load(open(os.path.join(B, 'reg085.json'), encoding='utf-8'))
    names085 = collections.defaultdict(list)
    for e in reg085:
        names085[e['name']].append(e)
    gap = {}
    for line in open(os.path.join(CY, r'Docs\evidence\lua_api_gap_methods.tsv'), encoding='utf-8'):
        p = line.rstrip('\n').split('\t')
        if p[0] != 'method':
            gap[p[0]] = int(p[1])
    pk_id = {}
    for line in open(os.path.join(CY, r'Registry\protocol\packets_summary.tsv'), encoding='utf-8'):
        p = line.rstrip('\n').split('\t')
        if p[0] != 'id':
            pk_id[p[1]] = (int(p[0]), p[2])
    defined_lua = set(script['defined_in_lua'])
    rep, catalog, stats = [], [], {}
    for mod, cfg in MODULES.items():
        recs = load_jsonl(cfg['jsonl'])
        info = next(r for r in recs if r['t'] == 'info')
        base = int(info['image_base'], 16)
        ident = Ident(cfg['bins'])
        impls = {r['addr']: r for r in recs if r['t'] == 'impl'}
        vft = {r['cls']: r for r in recs if r['t'] == 'vft'}
        vslot = collections.defaultdict(dict)
        for r in recs:
            if r['t'] == 'vslot':
                vslot[r['thunk']][r['cls'].split('@')[0]] = r['target']
        boxcls = {r['obj']: r['cands'] for r in recs if r['t'] == 'boxcls'}
        resolved, globals_of, meta_box, defs = resolve_receivers(recs)
        # class <-> metatable links (evidence)
        meta_cls = collections.defaultdict(set)
        for cls, r in vft.items():            # virtual GetMetaTable(): mov rax,[s_pMetaTable]; ret
            for s in r['slots']:
                if '=g:' in s:
                    d = earliest(defs, 'g:' + s.split('=g:')[1])
                    if d:
                        meta_cls[d[1]].add((cls, 'GetMetaTable-slot ' + s.split('=')[0]))
        for mname, objs in meta_box.items():
            for o in sorted(objs):
                pc = pick_box_class(boxcls.get(o, []), mname, globals_of.get(mname, []))
                if pc:
                    meta_cls[mname].add((pc[0], pc[1] + '@' + o))
        # best global per metatable by script usage
        meta_names = collections.defaultdict(set)
        for r, mname, gl, how in resolved:
            meta_names[mname].add(r['name'])
        best_global = {}
        for mname, names in meta_names.items():
            gls = [g for g in globals_of.get(mname, []) if '.' not in g]
            if not gls:
                continue
            score = {g: sum(script['methods'].get(n, {}).get('receivers', {}).get(g.replace('(table)', '').replace('(env)', ''), 0) for n in names) for g in gls}
            best_global[mname] = max(sorted(gls), key=lambda g: score[g])
        ddir = os.path.join(B, 'decomp', mod)
        dec = {}
        if os.path.isdir(ddir):
            for f in os.listdir(ddir):
                if f.endswith('.c'):
                    dec[f[:-2].lower()] = open(os.path.join(ddir, f), encoding='utf-8', errors='replace').read()
        by_key = collections.OrderedDict()
        dup = collections.Counter()
        for r, mname, gl, how in sorted(resolved, key=lambda x: ihex(x[0]['site'])):
            k = (mname or r['meta_key'], r['name'])
            if k in by_key:
                dup[k] += 1
            by_key[k] = (r, mname, gl, how)
        mod_entries = []
        for (mk, name), (r, mname, gl, how) in by_key.items():
            receiver = best_global.get(mname) or (gl[0] if gl else (mname or '?'))
            receiver = receiver.replace('(table)', '').replace('(env)', '')
            e = {'module': mod, 'name': name, 'receiver': receiver, 'metatable': mname, 'globals': gl,
                 'meta_key': r['meta_key'], 'meta_how': how, 'site': r['site'], 'reg_func': r['func'],
                 'reg_kind': r['kind'], 'impl_va': r['impl'], 'dup_registrations': dup.get((mk, name), 0)}
            impl = impls.get(r['impl']) if r['impl'] else None
            e['impl_kind'] = 'unresolved' if not r['impl'] else 'function'
            if impl and impl.get('vcall_off') is not None:
                e['impl_kind'] = 'vcall+0x%x' % impl['vcall_off']
                e['vcall_thunk'] = r['impl']
                tgt = None
                for cls, ev in sorted(meta_cls.get(mname, set())):
                    t = vslot.get(r['impl'], {}).get(cls)
                    if t:
                        tgt, e['vcall_class'], e['vcall_evidence'] = t, cls, ev
                        break
                if tgt is None:
                    for cls in vslot.get(r['impl'], {}):
                        if cls.split('::')[-1].lower() == norm(mname):
                            tgt, e['vcall_class'], e['vcall_evidence'] = vslot[r['impl']][cls], cls, 'INFERENCE:name-match'
                            break
                if tgt:
                    e['impl_va'] = tgt
                    impl = impls.get(tgt)
                else:
                    impl = None
            elif impl and impl.get('pseudo'):
                e['impl_kind'] = 'function(no Ghidra function; flood-filled)'
            e['rva'] = ('0x%x' % (ihex(e['impl_va']) - base)) if e['impl_va'] else None
            e['impl_bytes'] = ident.check(impl.get('id')) if impl else 'n/a'
            is_method = receiver != '_G'
            if impl and not impl.get('err'):
                at = arg_types(impl, is_method)
                e['args'] = ', '.join('a%d:%s' % (p, t) for p, t in at)
                e['nargs_read'] = len(at)
                c = dec.get(e['impl_va'].lower()) if e['impl_va'] else None
                n, kinds, rhow = ret_info(impl, c)
                e['returns_n'] = n
                e['returns'] = ('%d: %s' % (n, ', '.join(kinds))) if n else ('0' if n == 0 else '?')
                e['returns_types'] = kinds
                e['returns_how'] = rhow
                e['pushes'] = [p.split('@')[0] for p in impl.get('pushes', [])]
                e['rets_raw'] = impl.get('rets', [])
                # packet classes seen only at depth>=2 in >20% of packet-bearing functions are built inside the common
                # send path (Game.exe: CGSendClientThreadInfo, 418/461, never at depth 0/1) -> "send-path" flag, not a packet
                if 'generic_pk' not in cfg:
                    cnt = collections.defaultdict(collections.Counter)
                    for r2 in impls.values():
                        for p2 in r2.get('packets', []):
                            a2, d2 = p2.split('@')
                            cnt[a2.replace('Packets::', '')][d2] += 1
                    npk = sum(1 for r2 in impls.values() if r2.get('packets')) or 1
                    cfg['generic_pk'] = {k for k, c in cnt.items() if c['d0'] == 0 and c['d1'] == 0 and sum(c.values()) > 0.2 * npk}
                    rep.append('  generic send-path packets (%s): %s' % (mod, ', '.join(sorted(cfg['generic_pk'])) or '-'))
                e['packets'] = []
                gen_hit = None
                for p in impl.get('packets', []):
                    pn, d = p.split('@')
                    pn = pn.replace('Packets::', '')
                    if pn in cfg['generic_pk']:
                        gen_hit = (pn, int(d[1:]))
                        continue
                    pid = pk_id.get(pn)
                    e['packets'].append({'class': pn, 'depth': int(d[1:]), 'id': pid[0] if pid else None, 'dir': pid[1] if pid else None})
                if gen_hit:
                    e['net_send'] = 'reaches the common send path (%s@d%d built there; INFERENCE)' % gen_hit
                    e['packets'].append({'class': 'send-path', 'depth': gen_hit[1], 'id': None, 'dir': 'CG'})
                impl['packets'] = [p for p in impl.get('packets', []) if p.split('@')[0].replace('Packets::', '') not in cfg['generic_pk']]
                e['strings'] = impl.get('strings', [])[:8]
                e['rtti_classes'] = impl.get('classes', [])[:8]
                e['impl_size'] = impl.get('size')
                e['impl_imports'] = impl.get('imports', [])
                e['helper_pushes'] = impl.get('helper_pushes', [])
                e['decompiled'] = bool(c)
                sub, subhow = subsystem(e, impl)
                e['subsystem'] = sub
                e['subsystem_how'] = 'INFERENCE:' + subhow
            else:
                e.update({'args': '', 'nargs_read': 0, 'returns_n': None, 'returns': '?', 'returns_types': [], 'returns_how': 'no-impl',
                          'packets': [], 'strings': [], 'rtti_classes': [], 'subsystem': receiver, 'subsystem_how': 'INFERENCE:receiver',
                          'decompiled': False})
            mrec = script['methods'].get(name, {'calls': 0, 'receivers': {}})
            if is_method:
                e['calls_exact'] = sum(c for rv, c in mrec['receivers'].items() if rv in [g.replace('(table)', '').replace('(env)', '') for g in gl] or rv == receiver)
                e['calls_any'] = mrec['calls']
                e['script_receivers'] = sorted(mrec['receivers'], key=lambda x: -mrec['receivers'][x])[:6]
            else:
                g = script['globals'].get(name, {'calls': 0})
                e['calls_exact'] = g['calls'] if name not in defined_lua else 0
                e['calls_any'] = g['calls']
                e['script_receivers'] = []
            e['defined_in_lua_too'] = name in defined_lua
            l85 = names085.get(name, [])
            e['in_085'] = bool(l85)
            same = [x for x in l85 if (x['table'] == mname) or (set(x['globals']) & set(gl)) or (x['table'] == '_G' and receiver == '_G')]
            e['in_085_same_receiver'] = bool(same)
            pick = (same or l85)[0] if l85 else None
            e['impl_085'] = ('%s (%s:%d)' % (pick['impl'], pick['file'], pick['line'])) if pick else None
            e['in_gap_list'] = name in gap
            conf = 'low'
            if impl and not impl.get('err'):
                good_bytes = e['impl_bytes'] in ('same', 'only:client', 'only:client_GL')
                solid_ret = e.get('returns_n') is not None and e['returns_how'] in (
                    'const', 'pushes==ret', 'uniform-push', 'pushes(branches)', 'decomp', 'decomp(branches)', 'decomp-uniform')
                conf = 'high' if (good_bytes and solid_ret) else 'medium'
            if e['impl_kind'].startswith('vcall') and 'INFERENCE' in e.get('vcall_evidence', 'INFERENCE') and conf == 'high':
                conf = 'medium'
            e['confidence'] = conf
            mod_entries.append(e)
        catalog.extend(mod_entries)
        st = {
            'registrations': sum(1 for r in recs if r['t'] == 'reg'),
            'unique_entries': len(mod_entries),
            'impl_mapped': sum(1 for e in mod_entries if e['impl_va'] and e['impl_bytes'] != 'n/a'),
            'vcall_resolved': sum(1 for e in mod_entries if e['impl_kind'].startswith('vcall') and e.get('vcall_class')),
            'vcall_total': sum(1 for e in mod_entries if e['impl_kind'].startswith('vcall')),
            'patterns_recovered': sum(1 for e in mod_entries if e.get('returns_n') is not None),
            'decompiled': sum(1 for e in mod_entries if e.get('decompiled')),
            'bytes_same_in_both': sum(1 for e in mod_entries if e['impl_bytes'] == 'same'),
            'bytes_other': dict(collections.Counter(e['impl_bytes'] for e in mod_entries if e['impl_bytes'] != 'same')),
            'confidence': dict(collections.Counter(e['confidence'] for e in mod_entries)),
            'receivers': collections.Counter(e['receiver'] for e in mod_entries).most_common(),
            'missing_on_receiver_vs_085': sum(1 for e in mod_entries if not e['in_085_same_receiver']),
            'duplicates': sum(dup.values()),
        }
        stats[mod] = st
        rep.append('== %s  (Ghidra copy of %s, sha256 %s)' % (mod, info['exe_path'], info['exe_sha256']))
        for k, v in st.items():
            rep.append('  %s: %s' % (k, v if k != 'receivers' else ', '.join('%s=%d' % x for x in v)))
        rep.append('  class<->metatable links: ' + '; '.join('%s->%s' % (m, ','.join(sorted('%s[%s]' % (c, w) for c, w in s))) for m, s in sorted(meta_cls.items())))
    host_names = {e['name'] for e in catalog}
    gap_in_cat = sum(1 for g in gap if g in host_names)
    rep.append('== gap cross-check: %d/%d names of Docs/evidence/lua_api_gap_methods.tsv are registered by B (Game.exe+UI_CEGUI.dll)' % (gap_in_cat, len(gap)))
    nr = sorted((g for g in gap if g not in host_names), key=lambda g: -gap[g])
    rep.append('   gap names NOT registered by B: %d (%s)' % (len(nr), ', '.join(nr[:30])))
    os.makedirs(REG, exist_ok=True)
    catalog.sort(key=lambda e: (-(e['calls_exact'] or 0), -(e['calls_any'] or 0), e['module'], e['receiver'], e['name']))
    for i, e in enumerate(catalog):
        e['rank'] = i + 1
    json.dump({'generated_by': 'CY-Source/Tools/re/luaapi/merge.py',
               'sources': {m: MODULES[m]['bins'] for m in MODULES},
               'stats': {m: {k: v for k, v in s.items()} for m, s in stats.items()},
               'entries': catalog}, open(os.path.join(REG, 'catalog.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    write_tsv(catalog, stats)
    txt = '\n'.join(rep) + '\n'
    open(os.path.join(B, 'merge_report.txt'), 'w', encoding='utf-8').write(txt)
    os.makedirs(LOGS, exist_ok=True)
    open(os.path.join(LOGS, 'merge_report.txt'), 'w', encoding='utf-8').write(txt)
    print(txt)


def write_tsv(catalog, stats):
    cols = ['name', 'receiver', 'metatable', 'module', 'rva', 'impl_kind', 'args', 'returns', 'subsystem', 'packets',
            'in_085', 'in_085_same_receiver', 'call_count_in_scripts', 'calls_any_receiver', 'confidence',
            'impl_bytes', 'returns_how', 'impl_085', 'site', 'reg_kind', 'globals']
    hdr = [
        '# CY-Source Registry/luaapi/catalog.tsv - Lua host API of the modern TLBB client (B = client\\Bin64; the same code is in client_GL\\Bin64)',
        '# GENERATED by Tools/re/luaapi/merge.py from Ghidra (LuaApiDump.java on the read-only project copy in Build/re/luaapi) - do not edit by hand.',
        '# README',
        '#  Registration (Game.exe RVAs): LuaPlus 5.0 exactly as in 0.85 GMScriptSystm.cpp. Global functions: objGlobal.Register(name, int(*)(LuaState*))',
        '#   (import ?Register@LuaObject@LuaPlus@@QEAAXPEBDP6AHPEAVLuaState@2@@ZH@Z, IAT RVA 0x6df590). Methods: RegisterObjectFunctor<Callee> is NOT inlined -',
        '#   one ICF-folded instantiation at RVA 0x45aaf0 (+ per-metatable copies 0x45aa30 / 0x45aa90 with the metatable global baked in) does',
        '#   lua_newuserdata(L,8), stores the member-function pointer (R8) and tail-calls Register(name, dispatcher RVA 0x45a9e0, nup+1).',
        '#   Metatables are static LuaObject* (s_pMetaTable) set by CreateTable("<X>MetaTable") + operator=, published as BoxPointer(&s_obj)',
        '#   + SetMetaTable + objGlobal.SetObject("<Global>"). UI_CEGUI.dll inlines the functor (lua_newuserdata + Register, dispatcher RVA 0x290f0).',
        '#   Virtual members are registered through vcall thunks (mov rax,[rcx]; jmp [rax+off]); impl_kind vcall+off(Class) gives the slot target',
        '#   resolved with RTTI vftables (GetMetaTable() slot for LUA_CONTROL::*, static boxed object for SCRIPT_SANDBOX::*).',
        '#  Columns: name | receiver = Lua global the UI scripts call it on (_G = global function, MetaTable_Control_* = UI control type,',
        '#   ActionButtonMetaTable = action-item objects) | metatable = CreateTable name | module | rva = implementing function RVA in B',
        '#   (image base 0x140000000 Game.exe / 0x180000000 UI_CEGUI.dll) | impl_kind | args = Lua stack reads mapped to script argument',
        '#   positions (methods: stack index-1) with type int/number/string/boolean (suffix ? = only type-checked) | returns = "N: types"',
        '#   (N = constant returned to Lua; types from push calls, see returns_how; object = userdata/LuaObject) | subsystem = INFERENCE',
        '#   (class named in the function\'s own error strings > packet family > RTTI class > receiver) | packets = RTTI Packets::* vftables',
        '#   referenced at call depth 0..2 (@dN), CG* = client->server, #id = skynet id from Registry/protocol; "send-path@d2" = the function',
        '#   reaches the common packet-send path (Game.exe builds CGSendClientThreadInfo there; the packet class itself is not statically',
        '#   visible, e.g. created through the packet factory) - INFERENCE | in_085 = name registered',
        '#   anywhere in the 0.85 source, in_085_same_receiver = on the same table/global (else it is MISSING and gets a stub) |',
        '#   call_count_in_scripts = calls on that receiver in client_GL Data/InterfaceFolder (1,201 .lua) | calls_any_receiver |',
        '#   confidence high/medium/low | impl_bytes = function bytes identical in client+client_GL (same) | impl_085 = 0.85 starting point.',
        '#  Caveats: types come from LuaPlus import calls (helpers pushing on the callee side are INFERENCE); subsystem is INFERENCE;',
        '#   first-pushes(heuristic)/partial returns are medium confidence; decompiled C of the top-300/120 impls is in Build/re/luaapi/decomp.',
        '#  Stubs: python Tools/re/luaapi/gen_stubs.py -> Src/Client/LuaApiGen (one file per receiver, missing names only).',
    ]
    for m, s in stats.items():
        hdr.append('#  %s: %d registrations, %d unique (receiver,name), %d mapped to a function, %d with return pattern, %d decompiled, %d/%d vcall resolved, %d missing vs 0.85' % (
            m, s['registrations'], s['unique_entries'], s['impl_mapped'], s['patterns_recovered'], s['decompiled'], s['vcall_resolved'], s['vcall_total'], s['missing_on_receiver_vs_085']))
    with open(os.path.join(REG, 'catalog.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(hdr) + '\n')
        f.write('\t'.join(cols) + '\n')
        for e in catalog:
            row = {
                'name': e['name'], 'receiver': e['receiver'], 'metatable': e['metatable'] or '', 'module': e['module'],
                'rva': e['rva'] or '', 'impl_kind': e['impl_kind'] + ('(' + e['vcall_class'] + ')' if e.get('vcall_class') else ''),
                'args': e['args'], 'returns': e['returns'], 'subsystem': e['subsystem'],
                'packets': ','.join('%s%s' % (p['class'], ('#%d' % p['id']) if p['id'] is not None else '') + ('' if p['depth'] == 0 else '@d%d' % p['depth']) for p in e['packets']),
                'in_085': int(e['in_085']), 'in_085_same_receiver': int(e['in_085_same_receiver']),
                'call_count_in_scripts': e['calls_exact'], 'calls_any_receiver': e['calls_any'], 'confidence': e['confidence'],
                'impl_bytes': e['impl_bytes'], 'returns_how': e['returns_how'], 'impl_085': e['impl_085'] or '',
                'site': e['site'], 'reg_kind': e['reg_kind'], 'globals': ','.join(e['globals']),
            }
            f.write('\t'.join(str(row[c]).replace('\t', ' ').replace('\n', ' ') for c in cols) + '\n')


if __name__ == '__main__':
    main()
