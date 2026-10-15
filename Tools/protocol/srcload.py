"""srcload.py - read (read-only) and parse the live skynet protocol sources.

Bind order is taken from services/game/packet.lua itself (types first, then
domains), so a later definition of the same `packet.X` wins exactly as at
run time.
"""
import datetime
import hashlib
import os
import re

import luaparse
from luaconst import exec_const_chunk, const_eval, NotConst, NOT_CONST
from extract_stmt import collect_tables, build_module_scope

DEFAULT_ROOT = r'\\wsl.localhost\TLBB\home\ubuntu\GameServer'
PACKET_LUA = 'services/game/packet.lua'
IDS_LUA = 'services/game/packet_ids.lua'
LOGIN_LUA = 'services/login/packet.lua'
EXTRA_INPUTS = ['lualib/iostream.lua', 'lualib/wire_charset.lua', 'lualib/net.lua',
                'lualib/define.lua', 'lualib-src/lua-netpack.c']


class Source(object):
    def __init__(self, root, relpath):
        self.relpath = relpath
        self.path = os.path.join(root, *relpath.split('/'))
        data = open(self.path, 'rb').read()
        st = os.stat(self.path)
        self.size = len(data)
        self.sha256 = hashlib.sha256(data).hexdigest()
        self.mtime = datetime.datetime.fromtimestamp(st.st_mtime).strftime('%Y-%m-%dT%H:%M:%S')
        try:
            self.text = data.decode('utf-8')
            self.encoding = 'utf-8'
        except UnicodeDecodeError:
            self.text = data.decode('gb18030')
            self.encoding = 'gb18030'
        if self.text.startswith('\ufeff'):
            self.text = self.text[1:]
        self.chunk = None

    def parse(self):
        if self.chunk is None:
            self.chunk = luaparse.parse(self.text)
        return self.chunk

    def info(self):
        return {'path': self.relpath, 'sha256': self.sha256, 'bytes': self.size,
                'mtime': self.mtime, 'encoding': self.encoding}


def bind_order(chunk):
    """[(kind, module)] from require("game.packet_types.X").bind(...) calls."""
    out = []

    def scan(e):
        if e.kind == 'Call' and e.func.kind == 'Name' and e.func.id == 'require' and e.args \
                and e.args[0].kind == 'String':
            m = re.match(r'game\.(packet_types|packet_domains)\.(\w+)$', e.args[0].value)
            if m:
                out.append((m.group(1), m.group(2)))
        for attr in ('func', 'obj', 'left', 'right', 'operand', 'expr'):
            sub = getattr(e, attr, None)
            if sub is not None and hasattr(sub, 'kind'):
                scan(sub)
        for a in getattr(e, 'args', []) or []:
            scan(a)
    for s in chunk.body:
        if s.kind == 'CallStat':
            scan(s.call)
    return out


def commented_defs(src):
    out = []
    for line, text, is_block in src.parse().comments:
        for m in re.finditer(r'packet\.([A-Za-z_]\w*)\s*=\s*\{', text):
            out.append({'file': src.relpath, 'line': line + text.count('\n', 0, m.start()),
                        'name': m.group(1), 'block_comment': bool(is_block)})
    return out


def load(root=DEFAULT_ROOT):
    r = {'root': root, 'sources': [], 'errors': []}
    pkt = Source(root, PACKET_LUA)
    order = bind_order(pkt.parse())
    ids_src = Source(root, IDS_LUA)
    _, assigns = exec_const_chunk(ids_src.parse().body)
    ids, id_defs, id_redefs = {}, [], []
    for name, val, line in assigns:
        if not name.startswith('M.'):
            continue
        n = name[2:]
        if n in ids:
            id_redefs.append({'name': n, 'old': ids[n], 'new': val, 'line': line})
        ids[n] = val
        id_defs.append((n, val, line))
    define_src = Source(root, 'lualib/define.lua')
    define_env, _ = exec_const_chunk(define_src.parse().body)
    define_tree = define_env.get('define') if isinstance(define_env.get('define'), dict) else {}
    login = Source(root, LOGIN_LUA)
    _, lassigns = exec_const_chunk(login.parse().body)
    login_ids, login_id_defs = {}, []
    for name, val, line in lassigns:
        if name.startswith('packet.XYID_'):
            n = name[len('packet.'):]
            login_ids[n] = val
            login_id_defs.append((n, val, line))

    groups = []
    sources = [ids_src, pkt]
    for kind, mod in order:
        s = Source(root, 'services/game/%s/%s.lua' % (kind, mod))
        sources.append(s)
        groups.append(('game', kind, mod, s))
    sources.append(login)
    groups.append(('login', 'login', 'login', login))
    for rel in EXTRA_INPUTS:
        if rel == 'lualib/define.lua':
            sources.append(define_src)
        else:
            sources.append(Source(root, rel))

    all_defs = {'game': [], 'login': []}
    comm = []
    for proto, kind, mod, s in groups:
        env = {'packet': ids if proto == 'game' else login_ids, 'define': define_tree}
        tables, mlocals = collect_tables(s.parse(), s.relpath, mod, len(all_defs[proto]), env)
        scope = build_module_scope(mlocals)
        for t in tables:
            t.scope = scope
            t.proto = proto
            t.file_kind = kind
            if t.xy_expr is None:
                t.xy_id = None
                t.xy_const = None
            else:
                t.xy_const = (t.xy_expr.key.value if t.xy_expr.kind == 'Index'
                              and t.xy_expr.key.kind == 'String' else luaparse.to_lua(t.xy_expr))
                try:
                    t.xy_id = const_eval(t.xy_expr, env)
                except NotConst:
                    t.xy_id = NOT_CONST
        all_defs[proto].extend(tables)
        comm.extend(commented_defs(s))

    winners = {}
    for proto in ('game', 'login'):
        w = {}
        for t in all_defs[proto]:
            w[t.name] = t
        winners[proto] = w
    ignored = []
    try:
        for d in ('services/game/packet_domains', 'services/game/packet_types'):
            for fn in sorted(os.listdir(os.path.join(root, *d.split('/')))):
                rel = d + '/' + fn
                if not any(s.relpath == rel for s in sources):
                    ignored.append(rel)
    except OSError:
        pass
    r.update({'sources': sources, 'bind_order': order, 'ids': ids, 'id_defs': id_defs,
              'id_redefs': id_redefs, 'login_ids': login_ids, 'login_id_defs': login_id_defs,
              'define_tree': define_tree, 'all_defs': all_defs, 'winners': winners,
              'commented_defs': comm, 'ignored_files': ignored})
    return r
