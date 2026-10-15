"""extract_stmt.py - symbolic interpreter for the skynet packet codec DSL.

Runs a codec function (`bis` = decoder, `bos` = encoder) of a `packet.X = {...}`
table over symbolic values and records every stream operation in order,
nested under `if` / loop nodes.  See CODEC_DSL_vi.md for the DSL.
"""
import re

from luaparse import Node, to_lua
from luaconst import const_eval, NotConst, NOT_CONST
from extract_expr import ExprMixin, V, NIL, Loop, Scope, Frame

LIB_LOCALS = {'gbk': 'gbk', 'define': 'define', 'iostream': 'iostream', 'bistream': 'bistream',
              'bostream': 'bostream', 'packet': 'packet', 'crypt': 'crypt'}


class PacketTable(object):
    """One live `packet.Name = { ... }` definition."""

    def __init__(self, name, relpath, domain, line, end_line, order):
        self.name = name
        self.relpath = relpath
        self.domain = domain
        self.line = line
        self.end_line = end_line
        self.order = order            # global bind order (later wins)
        self.xy_expr = None
        self.consts = {}
        self.methods = {}
        self.scope = None


def _last_line(node):
    return getattr(node, 'end_line', None) or node.line


def collect_tables(chunk, relpath, domain, order_base, const_env):
    """Return (tables, module_locals) for one Lua file."""
    tables = []
    module_locals = []

    def visit(stmts, depth):
        for s in stmts:
            if s.kind == 'Assign':
                for tg, ex in zip(s.targets, s.exprs):
                    if (tg.kind == 'Index' and tg.obj.kind == 'Name' and tg.obj.id == 'packet'
                            and tg.key.kind == 'String' and ex.kind == 'Table'):
                        end = max([s.line] + [_last_line(v) for _, _, v in ex.items])
                        t = PacketTable(tg.key.value, relpath, domain, s.line, end,
                                        order_base + len(tables))
                        for kind, key, val in ex.items:
                            if kind != 'named':
                                continue
                            if val.kind == 'Function':
                                t.methods[key] = val
                            elif key == 'xy_id':
                                t.xy_expr = val
                            else:
                                try:
                                    t.consts[key] = const_eval(val, const_env)
                                except NotConst:
                                    t.consts[key] = NOT_CONST
                        tables.append(t)
            elif s.kind == 'FunctionStat' and depth == 0:
                visit(s.func.body, depth + 1)
            elif s.kind in ('Local', 'LocalFunction'):
                module_locals.append(s)
    visit(chunk.body, 0)
    return tables, module_locals


def build_module_scope(module_locals):
    sc = Scope(None)
    for name in ('packet', 'bistream', 'bostream', 'gbk', 'define'):
        sc.vars[name] = V('lib', name=name)
    for s in module_locals:
        if s.kind == 'LocalFunction':
            sc.vars[s.name] = V('func', func=s.func, scope=sc, name=s.name)
            continue
        for i, name in enumerate(s.names):
            if name in LIB_LOCALS:
                sc.vars[name] = V('lib', name=LIB_LOCALS[name])
                continue
            if i >= len(s.exprs):
                continue
            e = s.exprs[i]
            if e.kind == 'Function':
                sc.vars[name] = V('func', func=e, scope=sc, name=name)
                continue
            try:
                sc.vars[name] = V('const', value=const_eval(e, {}))
            except NotConst:
                sc.vars[name] = V('opq', text=name, name='module:' + name)
    return sc


class Extractor(ExprMixin):
    def __init__(self, ids, define_tree, tables):
        self.ids = ids
        self.define_tree = define_tree
        self.tables = tables
        self.pure = 0
        self._id = 0
        self.reset(None)

    def next_id(self):
        self._id += 1
        return self._id

    def reset(self, table):
        self.self_table = table
        self.frames = [Frame()]
        self.loop_stack = []
        self.cond_stack = []
        self.via_stack = []
        self.ret_stack = []
        self.keymap = {}
        self.values = {}
        self.streams = []
        self.notes = []
        self.errors = []
        self.cond_refs = None
        self.tmp_counter = 0
        self.last_stream = None
        self.cf_depths = []
        self.values_cond = {}
        self.values_selfref = {}
        self._vr_guard = set()

    # ------------------------------------------------------------ entry
    def run(self, table, kind):
        func = table.methods.get(kind)
        if func is None:
            return None
        self.reset(table)
        scope = Scope(table.scope)
        params = func.params
        struct_mode = len(params) >= 2 and params[1] != 'buffer'
        scope.vars[params[0] if params else 'self'] = V('path', root=('self',), path=())
        param_stream = None
        if len(params) >= 2:
            if struct_mode:
                param_stream = self.new_stream('param', params[1], func.line)
                scope.vars[params[1]] = V('stream', stream=param_stream)
            else:
                scope.vars[params[1]] = V('buffer')
        for p in params[2:]:
            scope.vars[p] = V('opq', text=p, name='param:' + p)
        self.exec_block(func.body, scope)
        root = self.pick_root(kind, param_stream)
        top = self.frames[0].out
        fields = top.get(root.sid, []) if root is not None else []
        others = [st for st in self.streams
                  if st is not root and not st.embedded and top.get(st.sid)]
        if others:
            self.notes.append('operations on %d stream(s) that are never sent' % len(others))
        if kind == 'bos' and root is not None and root.kind == 'out' and not root.returned:
            self.notes.append('bos() never returns stream:get() (returns nil)')
        if kind == 'bis' and root is not None and root.kind == 'in' and not root.attached:
            self.notes.append('bis() reads a stream that is not attached to the buffer')
        return {'fields': fields, 'notes': list(self.notes), 'errors': list(self.errors),
                'line': func.line, 'end_line': func.end_line,
                'mode': 'struct' if struct_mode else 'packet'}

    def pick_root(self, kind, param_stream):
        if param_stream is not None:
            return param_stream
        top = self.frames[0].out
        if kind == 'bis':
            for st in self.streams:
                if st.attached:
                    return st
        else:
            ret = [st for st in self.streams if st.returned]
            if ret:
                return ret[-1]
        for st in self.streams:
            if top.get(st.sid):
                return st
        return self.streams[0] if self.streams else None

    # ------------------------------------------------------------ blocks
    def terminates(self, block):
        if not block:
            return False
        last = block[-1]
        if last.kind in ('Return', 'Break'):
            return True
        if last.kind == 'If' and last.orelse is not None:
            return all(self.terminates(b) for _, b in last.tests) and self.terminates(last.orelse)
        return False

    def rewrite_early_exit(self, s, rest):
        """`if c then ...; return end; REST`  ==>  `if c then ... else REST end`."""
        term = [self.terminates(b) for _, b in s.tests]
        else_term = self.terminates(s.orelse) if s.orelse is not None else False
        if not any(term) and not else_term:
            return None
        tests = [(c, b if t else b + rest) for (c, b), t in zip(s.tests, term)]
        orelse = list(s.orelse or [])
        if not else_term:
            orelse = orelse + rest
        return Node('If', s.line, tests=tests, orelse=orelse)

    def exec_block(self, stmts, scope):
        n = len(stmts)
        for i, s in enumerate(stmts):
            if s.kind == 'If' and i < n - 1:
                s2 = self.rewrite_early_exit(s, list(stmts[i + 1:]))
                if s2 is not None:
                    return self.exec_stmt(s2, scope)
            r = self.exec_stmt(s, scope)
            if r in ('return', 'break'):
                return r
        return None

    def exec_stmt(self, s, scope):
        k = s.kind
        if k == 'Local':
            vals = [self.ev(s.exprs[i], scope, V('path', root=('tmp', name), path=()))
                    if i < len(s.exprs) else NIL for i, name in enumerate(s.names)]
            for name, v in zip(s.names, vals):
                if v.kind == 'expr' and not v.see and v.name is None:
                    v = V('expr', inner=v.inner, text=v.text, see=False, default=v.default,
                          is_text=v.is_text, name=name)
                scope.vars[name] = v
            return None
        if k == 'LocalFunction':
            scope.vars[s.name] = V('func', func=s.func, scope=scope, name=s.name)
            return None
        if k == 'Assign':
            for i, tg in enumerate(s.targets):
                if i >= len(s.exprs):
                    break
                if tg.kind == 'Name':
                    v = self.ev(s.exprs[i], scope, V('path', root=('tmp', tg.id), path=()))
                    b, sc = scope.lookup(tg.id)
                    if sc is None:
                        continue
                    if self.cf_depths and sc.depth < self.cf_depths[-1]:
                        # assignment under a condition / inside a loop to an outer local
                        if b is not None and (b.kind in ('node', 'path') or (b.kind == 'expr' and b.see)):
                            continue        # clamp of a wire value: keep the original binding
                        v = V('opq', text=tg.id, name='%s@%d' % (tg.id, sc.id))
                    sc.vars[tg.id] = v
                    continue
                tv = self.ev(tg, scope)
                v = self.ev(s.exprs[i], scope, tv if tv.kind == 'path' else None)
                if tv.kind == 'path':
                    key = self.vkey(tv)
                    self.values[key] = v
                    self.values_cond[key] = bool(self.cf_depths)
                    tgt = to_lua(tg)
                    self.values_selfref[key] = re.search(r'(?<![\w.])%s(?!\w)' % re.escape(tgt),
                                                         to_lua(s.exprs[i])) is not None
                    if v.kind == 'node':
                        self.keymap[key] = v.node
            return None
        if k == 'CallStat':
            self.ev(s.call, scope)
            return None
        if k == 'If':
            return self.exec_if(s, scope)
        if k == 'NumFor':
            self.exec_numfor(s, scope)
            return None
        if k == 'GenFor':
            self.exec_genfor(s, scope)
            return None
        if k == 'While':
            self.exec_while(s, scope)
            return None
        if k == 'Repeat':
            loop = Loop('while', s.line)
            loop.count_text = 'repeat ... until ' + self.render(s.cond, scope)
            loop.notes.append('repeat-until loop: iteration count not encoded explicitly')
            self.run_loop(loop, s.body, Scope(scope))
            return None
        if k == 'Do':
            return self.exec_block(s.body, Scope(scope))
        if k == 'Return':
            vals = [self.ev(x, scope) for x in s.exprs]
            for v in vals:
                if v.kind == 'blob':
                    v.stream.returned = True
            if self.ret_stack:
                self.ret_stack[-1].extend(vals)
            return 'return'
        if k == 'Break':
            return 'break'
        self.notes.append('L%d: statement %s ignored' % (s.line, k))
        return None

    def exec_if(self, s, scope):
        branches = []
        for cond, body in s.tests:
            self.ev(cond, scope)
            text, refs = self.render_cond(cond, scope)
            branches.append((text, self.run_branch(body, scope, cond), refs))
        if s.orelse is not None:
            branches.append(('else', self.run_branch(s.orelse, scope, None), []))
        uniq_refs = []
        for _, _, refs in branches:
            uniq = list({id(x): x for x in refs}.values())
            for n in uniq:
                n['_crefs'] = n.get('_crefs', 0) + 1
            uniq_refs.append(uniq)
        sids = []
        for _, fr, _ in branches:
            for sid in fr.out:
                if sid not in sids:
                    sids.append(sid)
        for sid in sids:
            node = {'k': 'if', 'line': s.line, '_id': self.next_id(),
                    'branches': [{'when': t, 'fields': fr.out.get(sid, []), '_refs': uniq_refs[i]}
                                 for i, (t, fr, _) in enumerate(branches)]}
            self.frames[-1].out.setdefault(sid, []).append(node)
        if s.orelse is not None and all(fr.status == 'return' for _, fr, _ in branches):
            return 'return'
        return None

    def run_branch(self, body, scope, cond):
        fr = Frame()
        self.frames.append(fr)
        bs = Scope(scope)
        self.cf_depths.append(bs.depth)
        if cond is not None:
            self.cond_stack.append((cond, scope))
        try:
            fr.status = self.exec_block(body, bs)
        finally:
            if cond is not None:
                self.cond_stack.pop()
            self.cf_depths.pop()
            self.frames.pop()
        return fr

    # ------------------------------------------------------------ loops
    def set_count(self, loop, v):
        loop.count_key = self.vkey(v)
        loop.count_text = self.vtext(v)
        node = v.node if v.kind == 'node' else self.keymap.get(loop.count_key)
        loop.count_node = node
        loop.count_wire = self.is_wire(v)
        if node is not None:
            node['_refs'] = node.get('_refs', 0) + 1
        loop.bounds = self.bounds_for(loop.count_key)

    def exec_numfor(self, s, scope, note=None):
        loop = Loop('for', s.line, s.var)
        if note:
            loop.notes.append(note)
        start = self.ev(s.start, scope)
        stop = self.ev(s.stop, scope)
        step = self.ev(s.step, scope) if s.step is not None else V('const', value=1)
        consts = [x for x in (start, stop, step) if x.kind == 'const' and isinstance(x.value, int)
                  and not isinstance(x.value, bool)]
        if len(consts) == 3:
            loop.count = max(0, (stop.value - start.value) // step.value + 1) if step.value else 0
        elif start.kind == 'const' and start.value == 1 and step.kind == 'const' and step.value == 1:
            self.set_count(loop, stop)
        else:
            loop.count_text = '%s..%s' % (self.vtext(start), self.vtext(stop))
            loop.notes.append('loop with non-unit start/step')
        body = Scope(scope)
        body.vars[s.var] = V('index', loop=loop)
        self.run_loop(loop, s.body, body)
        return loop

    def exec_genfor(self, s, scope):
        it = s.exprs[0] if s.exprs else None
        kind = 'pairs'
        target = None
        if (it is not None and it.kind == 'Call' and it.func.kind == 'Name'
                and it.func.id in ('ipairs', 'pairs') and it.args):
            kind = it.func.id
            target = self.ev(it.args[0], scope)
        loop = Loop(kind, s.line, s.names[0])
        if target is not None:
            base = target
            while base.kind == 'expr' and base.see and base.inner is not None:
                base = base.inner
            if base.kind == 'path':
                loop.array = (base.root, base.path)
            self.set_count(loop, V('len', inner=target))
        else:
            loop.count_text = 'iterator %s' % (to_lua(it) if it is not None else '?')
        if kind == 'pairs':
            loop.notes.append('pairs(): iteration order is undefined')
        body = Scope(scope)
        body.vars[s.names[0]] = V('index', loop=loop)
        if len(s.names) > 1:
            body.vars[s.names[1]] = V('path', root=('elem', loop), path=())
        self.run_loop(loop, s.body, body)

    def while_idiom(self, s, scope):
        """`local i=1; while true do BODY; i=i+1; if i > N then return end end`."""
        if s.cond.kind != 'True' or len(s.body) < 2:
            return None
        last, inc = s.body[-1], s.body[-2]
        if last.kind != 'If' or len(last.tests) != 1 or last.orelse is not None:
            return None
        cond, blk = last.tests[0]
        if not blk or blk[-1].kind not in ('Return', 'Break'):
            return None
        if inc.kind != 'Assign' or len(inc.targets) != 1 or inc.targets[0].kind != 'Name':
            return None
        var = inc.targets[0].id
        e = inc.exprs[0]
        if not (e.kind == 'BinOp' and e.op == '+' and e.left.kind == 'Name' and e.left.id == var
                and e.right.kind == 'Number' and e.right.value == 1):
            return None
        if not (cond.kind == 'BinOp' and cond.op in ('>', '>=') and cond.left.kind == 'Name'
                and cond.left.id == var):
            return None
        b, _ = scope.lookup(var)
        if b is None or b.kind != 'const' or not isinstance(b.value, int):
            return None
        stop = cond.right
        if cond.op == '>=':
            stop = Node('BinOp', cond.line, op='-', left=cond.right,
                        right=Node('Number', cond.line, value=1, raw='1'))
        fornode = Node('NumFor', s.line, var=var,
                       start=Node('Number', s.line, value=b.value, raw=str(b.value)),
                       stop=stop, step=None, body=s.body[:-2])
        note = 'while-true loop (exit via %s when %s) read as for %s = %d, %s' % (
            blk[-1].kind.lower(), to_lua(cond), var, b.value, to_lua(stop))
        return fornode, note, blk

    def exec_while(self, s, scope):
        idiom = self.while_idiom(s, scope)
        if idiom is not None:
            fornode, note, blk = idiom
            self.exec_numfor(fornode, scope, note)
            for st in blk:
                if st.kind == 'Return':
                    for x in st.exprs:
                        v = self.ev(x, scope)
                        if v.kind == 'blob':
                            v.stream.returned = True
            return
        loop = Loop('while', s.line)
        loop.count_text = 'while ' + self.render(s.cond, scope)
        loop.notes.append('while-loop: iteration count not encoded explicitly')
        self.run_loop(loop, s.body, Scope(scope))

    def run_loop(self, loop, body_stmts, body_scope):
        fr = Frame()
        self.frames.append(fr)
        self.loop_stack.append(loop)
        loop.scope_depth = body_scope.depth
        self.cf_depths.append(body_scope.depth)
        try:
            self.exec_block(body_stmts, body_scope)
        finally:
            self.cf_depths.pop()
            self.loop_stack.pop()
            self.frames.pop()
        if loop.array is None and loop.cands:
            loop.array = max(loop.cands.items(), key=lambda kv: kv[1])[0]
        if loop.array is not None:
            loop.name = self.disp(V('path', root=loop.array[0], path=loop.array[1]))
        for sid, ops in fr.out.items():
            self.frames[-1].out.setdefault(sid, []).append(
                {'k': 'loop', 'line': loop.line, '_id': self.next_id(), 'loop': loop, 'fields': ops})

    # ------------------------------------------------------------ helpers
    def inline(self, fv, args, line, via, table):
        if self.pure:
            return NIL
        if len(self.via_stack) >= 8:
            self.notes.append('L%d: helper nesting too deep (%s)' % (line, via))
            return NIL
        func = fv.func
        sc = Scope(fv.scope)
        for i, p in enumerate(func.params):
            a = args[i] if i < len(args) else NIL
            if p == 'stream' and a.kind != 'stream':
                msg = ('helper %s receives a %s value as its "stream" argument; '
                       'this call raises at run time' % (via, a.kind))
                self.errors.append('L%d: %s' % (line, msg))
                st = self.last_stream or (self.streams[-1] if self.streams else None)
                if st is not None:
                    self.emit(st, {'k': 'x', 'line': line, '_id': self.next_id(),
                                   'expr': 'call ' + via, 'error': msg})
                    a = V('stream', stream=st)
            sc.vars[p] = a
        saved = self.self_table
        if table is not None:
            self.self_table = table
        self.via_stack.append(via)
        self.ret_stack.append([])
        try:
            self.exec_block(func.body, sc)
        finally:
            rets = self.ret_stack.pop()
            self.via_stack.pop()
            self.self_table = saved
        return rets[0] if rets else NIL
