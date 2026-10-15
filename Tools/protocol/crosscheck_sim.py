#!/usr/bin/env python3
"""crosscheck_sim.py - compare Registry/protocol/packets.json with the Python bot
client (Tools/stress-test/tlbb_sim) and with Tools/stress-test/PROTOCOL_SPEC_vi.md.

Checks
  const    ID constants in tlbb_sim/packets.py vs the spec
  builder  every body the bot sends (send_game/send_login in client.py) is decoded
           with the spec: must consume exactly and round-trip
  parser   every parse_* function is run on a spec-encoded body; each read it makes
           (offset, width) must coincide with a spec field
  doc_id   ID tables of PROTOCOL_SPEC_vi.md
  doc_off  offset tables of PROTOCOL_SPEC_vi.md (fixed prefix only)
Output: Registry/protocol/crosscheck_tlbb_sim.tsv
"""
import ast
import inspect
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import speccodec  # noqa: E402
from match085 import sk_prefix  # noqa: E402

SIM_ROOT = r'C:\TLBB\085\Tools\stress-test'
SPEC_MD = os.path.join(SIM_ROOT, 'PROTOCOL_SPEC_vi.md')
OUT = os.path.abspath(os.path.join(HERE, '..', '..', 'Registry', 'protocol', 'crosscheck_tlbb_sim.tsv'))
sys.path.insert(0, SIM_ROOT)
from tlbb_sim import codec as sim_codec, packets as P, perception  # noqa: E402

# parser -> (packet, sample values used to build the test body)
PARSERS = {
    (P, 'parse_lc_ret_login'): ('LCRetLogin', {'flag': 0}),
    (P, 'parse_lc_ret_charlist'): ('LCRetCharList', {'unknow': 0, 'charnum': 1, 'charlist': [{}]}),
    (P, 'parse_lc_ret_charlogin'): ('LCRetCharLogin', {'result': 1}),
    (P, 'parse_gc_connect'): ('GCConnect', {}),
    (P, 'parse_gc_enter_scene'): ('GCEnterScene', {}),
    (P, 'parse_script_command'): ('GCScriptCommand', {'m_nCmdID': 5, 'event.len': 3, 'event.str': b'abc'}),
    (P, 'parse_script_dialog'): ('GCScriptCommand', {'m_nCmdID': 0, 'size': 1,
                                                    'event': [{'flag': 1, 'str': b'abc'}]}),
    (P, 'parse_gc_chat'): ('GCChat', {}),
    (P, 'parse_gc_team_ask_invite'): ('GCTeamAskInvite', {}),
    (P, 'parse_gc_challenge'): ('GCChallenge', {'type': 1}),
    (P, 'parse_gc_notify_change_scene'): ('GCNotifyChangeScene', {}),
    (P, 'parse_gc_ret_change_scene'): ('GCRetChangeScene', {'result': 1}),
    (P, 'parse_gc_player_die'): ('GCPlayerDie', {}),
    (P, 'parse_gc_team_list'): ('GCTeamList', {'member_size': 1, 'member_list': [{'name_size': 3, 'name': b'abc'}]}),
    (perception, 'parse_new_player'): ('GCNewPlayer', {}),
    (perception, 'parse_new_monster'): ('GCNewMonster', {}),
    (perception, 'parse_new_player_move'): ('GCNewPlayer_Move', {'#path': 1, 'path': [{}]}),
    (perception, 'parse_char_move'): ('GCCharMove', {'flag': 4, 'size': 1, 'path': [{}]}),
    (perception, 'parse_char_base_attrib'): ('GCCharBaseAttrib', {'new_flags': [3] + [0] * 13, 'm_uFlags': [3] + [0] * 10,
                                                                   'm_byNameSize': 3, 'm_szName': b'abc'}),
    (perception, 'parse_del_object'): ('GCDelObject', {}),
}
ARG_SAMPLES = {'account': 'bot001', 'password': 'pw', 'mac': b'', 'text': 'hello', 'target': None,
               'pos': (1.5, 2.5), 'waypoints': [(3.0, 4.0), (5.0, 6.0)], 'direction': 0.5,
               'dest_name': 'abc', 'begin': True, 'accept': 1}
EXTRA_BUILDER_CALLS = [('cg_chat', ('hi', 3, 'abc')), ('cg_challenge', (1, 7))]


def norm(s):
    return re.sub(r'[^a-z0-9]', '', (s or '').lower())


class Row(object):
    rows = []

    @classmethod
    def add(cls, kind, item, packet, spec_id, sim_value, status, detail=''):
        cls.rows.append([kind, item, packet or '', spec_id if spec_id is not None else '',
                         sim_value if sim_value is not None else '', status, detail])


def index_spec(spec):
    idx = {}
    for p in spec.doc['packets']:
        for k in (norm(p['name']), norm((p.get('const') or '').replace('XYID_', ''))):
            idx.setdefault(k, p)
    return idx


def check_consts(spec, idx):
    tree = ast.parse(open(inspect.getsourcefile(P), encoding='utf-8').read())
    consts = {}
    for node in tree.body:
        if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
            name = node.targets[0].id
            if re.match(r'^(CG|GC|CL|LC)_[A-Z0-9_]+$|^KEY_EXCHANGE$', name) and isinstance(node.value, ast.Constant):
                consts[name] = node.value.value
    for name, val in consts.items():
        proto = 'login' if name[:2] in ('CL', 'LC') else 'game'
        p = idx.get(norm(name))
        by_val = spec.by_id.get((proto, val)) if isinstance(val, int) else None
        if p is None and by_val is not None:
            Row.add('const', name, by_val['name'], by_val['id'], val, 'OK_OTHER_NAME',
                    'no spec packet named like %s; id %s is %s' % (name, val, by_val['name']))
        elif p is None:
            Row.add('const', name, '', None, val, 'NOT_IN_SPEC', 'no packet with this name or id')
        elif val is None:
            Row.add('const', name, p['name'], p['id'], 'None', 'MISSING', 'sim leaves it None; spec id %s' % p['id'])
        elif p['id'] != val:
            other = spec.by_id.get((proto, val))
            Row.add('const', name, p['name'], p['id'], val, 'ID_MISMATCH',
                    'spec %s = %s; sim value %s is %s' % (p['name'], p['id'], val,
                                                         other['name'] if other else 'not a server packet id'))
        else:
            Row.add('const', name, p['name'], p['id'], val, 'OK')
    return consts


def sample_args(fn):
    args = []
    for pname, par in inspect.signature(fn).parameters.items():
        if par.default is not inspect.Parameter.empty:
            args.append(ARG_SAMPLES.get(pname, par.default))
        else:
            args.append(ARG_SAMPLES.get(pname, 7))
    return args


def decode_check(spec, p, body):
    try:
        vals, used = spec.decode(p, body)
    except speccodec.DecodeError as e:
        return 'MISMATCH', 'spec decoder: %s (body %d bytes)' % (e, len(body))
    if used != len(body):
        return 'MISMATCH', 'spec layout covers %d of %d bytes' % (used, len(body))
    if spec.encode(p, vals) != body:
        return 'ROUNDTRIP_DIFF', 're-encoding differs'
    return 'OK', '%d bytes' % len(body)


def check_builders(spec, consts):
    tree = ast.parse(open(os.path.join(SIM_ROOT, 'tlbb_sim', 'client.py'), encoding='utf-8').read())
    seen = set()
    for node in ast.walk(tree):
        if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
                and node.func.attr in ('send_game', 'send_login') and len(node.args) >= 2):
            continue
        a0, a1 = node.args[0], node.args[1]
        if not (isinstance(a0, ast.Attribute) and isinstance(a0.value, ast.Name) and a0.value.id == 'P'):
            continue
        cname = a0.attr
        val = consts.get(cname)
        proto = 'login' if cname[:2] in ('CL', 'LC') else 'game'
        p = spec.by_id.get((proto, val))
        if isinstance(a1, ast.Call) and isinstance(a1.func, ast.Attribute) and isinstance(a1.func.value, ast.Name) \
                and a1.func.value.id == 'P' and a1.func.attr not in ('Writer',):
            fname = a1.func.attr
            calls = [(fname, None)] + [(f, a) for f, a in EXTRA_BUILDER_CALLS if f == fname]
        else:
            fname, calls = None, [(None, None)]
        for f, args in calls:
            key = (cname, f, args)
            if key in seen:
                continue
            seen.add(key)
            item = '%s <- %s%s' % (cname, f or ast.unparse(a1)[:60], '' if args is None else repr(args))
            try:
                if f is None:
                    body = eval(compile(ast.Expression(a1), 'client.py', 'eval'),
                                {'P': P}, {'self': type('S', (), {'__getattr__': lambda s, n: 7})()})
                else:
                    fn = getattr(P, f)
                    body = fn(*(args if args is not None else sample_args(fn)))
            except Exception as e:  # noqa: BLE001
                Row.add('builder', item, p and p['name'], p and p['id'], val, 'SIM_ERROR', repr(e))
                continue
            if p is None:
                Row.add('builder', item, '', None, val, 'NO_SPEC', 'id %s has no server codec' % val)
                continue
            st, detail = decode_check(spec, p, body)
            Row.add('builder', item, p['name'], p['id'], val, st, detail)


class TracingReader(sim_codec.Reader):
    LOG = None

    def _take(self, n):
        if TracingReader.LOG is not None:
            TracingReader.LOG.append((self.pos, n))
        return sim_codec.Reader._take(self, n)


def check_parsers(spec, consts):
    P.Reader = TracingReader
    perception.Reader = TracingReader
    for (mod, fname), (pname, values) in PARSERS.items():
        p = spec.by_name.get(pname)
        fn = getattr(mod, fname, None)
        item = '%s.%s' % (mod.__name__.split('.')[-1], fname)
        if p is None or fn is None:
            Row.add('parser', item, pname, None, None, 'SKIPPED', 'packet or function missing')
            continue
        trace = []
        try:
            body = spec.encode(p, values, trace, lenient=True)
        except speccodec.DecodeError as e:
            Row.add('parser', item, pname, p['id'], None, 'SKIPPED', 'spec encoder: %s' % e)
            continue
        fields = {o: (s, n, t) for o, s, n, t in trace}
        ends = {o + s for o, s, n, t in trace}
        TracingReader.LOG = []
        try:
            res = fn(body)
            err = None
        except Exception as e:  # noqa: BLE001
            res, err = None, repr(e)
        log, TracingReader.LOG = TracingReader.LOG, None
        bad = []
        for off, width in log:
            hit = fields.get(off)
            if width == 0 or (hit is not None and off + width in ends):
                continue          # empty read, or a read covering whole consecutive spec fields
            if hit is None:
                cover = next(((o, s, n, t) for o, s, n, t in trace if o < off < o + s), None)
                if off >= len(body):
                    bad.append('read %d bytes at %d beyond the %d-byte body' % (width, off, len(body)))
                elif cover:
                    bad.append('read %d@%d inside spec field %s(%s)@%d' % (width, off, cover[2], cover[3], cover[0]))
            elif hit[0] != width:
                size, fname, ftype = hit
                if not str(ftype).startswith('bytes'):
                    bad.append('read %d@%d but spec field %s is %s' % (width, off, fname, ftype))
                elif width > size:
                    bad.append('read %d@%d but spec bytes field %s has %d' % (width, off, fname, size))
        sim_id = None
        for cname, v in consts.items():
            if norm(cname) in (norm(p['name']), norm((p.get('const') or '').replace('XYID_', ''))):
                sim_id = v
        status = 'OK' if not bad and err is None and res is not None else ('MISMATCH' if bad else 'PARSER_FAILED')
        detail = '; '.join(bad[:3]) or (err or ('parser returned None' if res is None else '%d reads' % len(log)))
        if sim_id is not None and sim_id != p['id']:
            detail += ' | dispatched on sim id %s' % sim_id
        Row.add('parser', item, pname, p['id'], sim_id, status, detail)


def check_doc(spec, idx):
    text = open(SPEC_MD, encoding='utf-8').read()
    for m in re.finditer(r'^\|\s*([A-Z][A-Za-z_]+)\s*\|\s*\**(\d+)\**\s*\|', text, flags=re.M):
        name, val = m.group(1), int(m.group(2))
        if not re.match(r'^(CGW|WGC|CG|GC|CL|LC)[A-Z]', name):
            continue          # constant tables (HEQUIP_TOTAL, ...) are not packets
        p = spec.by_name.get(name) or idx.get(norm(name))
        line = text.count('\n', 0, m.start()) + 1
        if p is None:
            Row.add('doc_id', '%s (md:%d)' % (name, line), '', None, val, 'NOT_IN_SPEC')
        elif p['id'] != val:
            Row.add('doc_id', '%s (md:%d)' % (name, line), p['name'], p['id'], val, 'ID_MISMATCH',
                    'document says %d, server %d' % (val, p['id']))
        else:
            Row.add('doc_id', '%s (md:%d)' % (name, line), p['name'], p['id'], val, 'OK')
    structs = {s['name']: {k: s[k] for k in ('bis', 'bos') if k in s} for s in spec.doc['structs']}
    for m in re.finditer(r'^###\s+[\d.]+\s+(\w+)\s+\((\d+)\)[^\n]*\n(.*?)(?=^###|\Z)', text, flags=re.M | re.S):
        name, sect = m.group(1), m.group(3)
        p = spec.by_name.get(name)
        rows = re.findall(r'^\|\s*(\d+)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|', sect, flags=re.M)
        if p is None or not rows:
            continue
        sk, _ = sk_prefix(p['fields'], structs)
        spec_off = {o: (s, n) for o, s, n, _kind in sk}
        issues = []
        for off, typ, field in rows:
            off = int(off)
            t = typ.replace('`', '').strip()
            size = None
            mm = re.match(r'^c(\d+)$', t)
            if mm:
                size = int(mm.group(1))
            elif t in ('u32', 'i4', 'f', 'i32'):
                size = 4
            elif t == 'u16':
                size = 2
            elif t in ('u8', 'i8'):
                size = 1
            if size is None:
                continue
            hit = spec_off.get(off)
            if hit is None and sk and off < sk[-1][0] + sk[-1][1]:
                issues.append('%s@%d not a spec field boundary' % (field, off))
            elif hit is not None and hit[0] != size:
                issues.append('%s@%d is %d bytes, spec %s is %d' % (field, off, size, hit[1], hit[0]))
        Row.add('doc_off', '%s section' % name, name, p['id'], len(rows), 'OK' if not issues else 'MISMATCH',
                '; '.join(issues[:4]))


def main():
    spec = speccodec.Spec()
    idx = index_spec(spec)
    consts = check_consts(spec, idx)
    check_builders(spec, consts)
    check_parsers(spec, consts)
    check_doc(spec, idx)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write('kind\titem\tpacket\tspec_id\tsim_value\tstatus\tdetail\n')
        for r in Row.rows:
            f.write('\t'.join(re.sub(r'[\t\r\n]+', ' ', str(x)) for x in r) + '\n')
    summary = {}
    for r in Row.rows:
        summary.setdefault(r[0], {}).setdefault(r[5], 0)
        summary[r[0]][r[5]] += 1
    print('crosscheck_tlbb_sim: %s -> %s' % (summary, OUT))
    for r in Row.rows:
        if not r[5].startswith('OK'):
            print('  %-8s %-58s %-22s spec=%-5s sim=%-6s %-14s %s' % tuple(str(x) for x in r))
    return 0


if __name__ == '__main__':
    sys.exit(main())
