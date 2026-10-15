#!/usr/bin/env python3
"""specgen.py - machine-readable protocol spec of the running skynet server.

Reads (read-only) the live Lua codecs under \\\\wsl.localhost\\TLBB\\home\\ubuntu\\GameServer
and writes to CY-Source/Registry/protocol/:
  packets.yaml         spec for humans / diffs (header carries sha256 of every input)
  packets.json         same document for tools (speccodec.py, codegen_cpp.py, ...)
  packets_summary.tsv  one row per packet
  fields_flat.tsv      one row per leaf field (with full condition path)
  unknow_fields.tsv    every field whose name is unknow/unknown/unk

Usage:  set PYTHONUTF8=1 & "C:\\Program Files\\Python313\\python.exe" specgen.py [--root DIR] [--out DIR]
"""
import argparse
import datetime
import hashlib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import srcload                         # noqa: E402
import codec_post                      # noqa: E402
import yamlout                         # noqa: E402
import annotations                     # noqa: E402
from extract_stmt import Extractor     # noqa: E402
from luaconst import NOT_CONST         # noqa: E402

CY_ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
DEFAULT_OUT = os.path.join(CY_ROOT, 'Registry', 'protocol')
TOOL_FILES = ['specgen.py', 'srcload.py', 'luaparse.py', 'luaconst.py', 'extract_expr.py',
              'extract_stmt.py', 'codec_post.py', 'yamlout.py', 'annotations.py']


def loosen(sh):
    """Shape with signedness ignored (i8/bool->u8, i16->u16, i32->u32)."""
    if isinstance(sh, tuple):
        return tuple(loosen(x) for x in sh)
    if isinstance(sh, str):
        return re.sub(r'\bi(8|16|32)\b', r'u\1', sh).replace('bool', 'u8')
    return sh
DIR_PREFIXES = ('CGW', 'WGC', 'CG', 'GC', 'CL', 'LC')
AUTH = {'CG': 'bis', 'CGW': 'bis', 'CL': 'bis', 'GC': 'bos', 'WGC': 'bos', 'LC': 'bos'}

FRAMING = {
    'header': 'u16 id, u16 size, u16 idx - little-endian, 6 bytes, then `size` body bytes',
    'max_body': 65535,
    'idx': 'sender sequence (seq & 0xFF) << 8, +1 per packet; server only logs gaps (net.lua check_is_record_xy)',
    'encryption': 'none on the stream; only CLAskLogin.encrypted_data is encrypted',
    'ports': {'login': 5733, 'game': 5734},
    'dispatch': 'net.lua register_packets: packets[xy_id] = table, iterated with pairs() -> '
                'if two live tables share an id the winner is undefined',
    'sources': ['lualib-src/lua-netpack.c', 'lualib/net.lua'],
}
WIRE = {
    'endianness': 'little',
    'string_charset': 'client_wire_encoding = utf8 (confs/publish_yu/server_conf.lua); outgoing strings go '
                      'through wire_charset.fromutf8 (identity + wire_names_vi translation)',
    'fixed_strings': 'bytes[N]: bostream.write(s, N) cuts at a UTF-8 boundary and pads with NUL; '
                     'readers keep all N bytes (cut at the first NUL when used as text)',
    'writer_clamps': 'writeshort clamps to [-32768, 32767], writeushort to [0, 65535]; '
                     'writeuint/writeint raise if the value does not fit (string.pack)',
}
TYPES = {
    'u8/i8/u16/i16/u32/i32/u64': 'little-endian integers (u64 = Lua "L", 8 bytes)',
    'f32': 'IEEE-754 float32',
    'bool': '1 byte; readbool() = (readuchar() == 1), writebool() writes int8 0/1',
    'bytes[N]': 'fixed N bytes',
    'bytes[]': 'variable bytes; length from len_field (an earlier field) or len_expr '
               '(len_on_wire: false = length not on the wire)',
    'str8/str16/str32': 'u8/u16/u32 byte count followed by that many bytes; len_name = name of the '
                        'count field in the Lua code; guard = condition under which the bytes are read; '
                        'min/max = limits implied by the guard',
    'array<T> / kind: array': 'repeated element: count (constant), count_field (earlier field) or '
                              'count_expr (count_on_wire: false = not on the wire); min/max from guards',
    'struct X': 'nested struct, layout in structs: (codec bis or bos)',
    'kind: blob': 'sub-stream serialized separately and embedded behind a len_type byte count',
    'kind: if': 'branches evaluated in order; `when` uses the condition syntax below',
    'kind: opaque': 'stream operation the extractor could not analyse (see note/error)',
}
CONDITIONS = ('C-like: == != < <= > >= && || ! & | ^(xor) ~(bnot) << >> + - * / // %; '
              '#x = byte length of a string / element count of an array; names are earlier fields '
              '(current array element first, then outer scopes); name[i] = element i of another array '
              'indexed by the current loop; $name = server-side local that is not on the wire; '
              'math.floor(...) etc. keep Lua semantics')
DSL = {
    'table': 'packet.<Name> = { xy_id = packet.XYID_<...>, new, ctor, bis, bos, [helpers], [constants] } '
             'inside M.bind(packet, bistream, bostream, gbk, define) of each packet_types/*.lua and '
             'packet_domains/*.lua file (login: top level of services/login/packet.lua)',
    'bis(self, buffer)': 'decoder used by the server for packets it RECEIVES (CG/CL/CGW): '
                         'local stream = bistream.new(); stream:attach(buffer); self.f = stream:readT() ...',
    'bos(self)': 'encoder used by the server for packets it SENDS (GC/LC/WGC): local stream = bostream.new(); '
                 'stream:writeT(self.f) ...; return stream:get()',
    'struct codecs': 'types/*.lua: bis(self, stream) / bos(self, stream) work on the caller stream; '
                     'called as packet.X.bos(obj, stream) or obj:bis(stream) after obj = packet.X.new()',
    'primitives': 'read/write + uchar(u8) char(i8) ushort(u16) short(i16) uint(u32) int(i32) float(f32) '
                  'ulong(u64) bool; read(n)/write(s, n) = n raw bytes; writeff(n) = n x 0xFF',
    'arrays': 'for i = 1, N do ... end (N constant or earlier field), for _, v in ipairs(t) (count = #t '
              'written before), while-true loops with i = i + 1 / if i > N then return end',
    'conditions': 'if/elseif/else on earlier fields; early `return` ends the packet',
    'strings': 'u8/u16/u32 length + read(len) (-> strN); fixed read(0x1E)/write(s, 0x1E) (-> bytes[N])',
    'helpers': 'self:read_x(stream)/self:write_x(stream, v) methods of the same table are inlined '
               '(fields carry `via`)',
    'blobs': 'local inner = bostream.new() ... stream:writeint(#inner:get()); stream:write(inner:get(), n)',
    'ids': 'services/game/packet_ids.lua (generated by split_packet.py, which is not on the server) and '
           'packet.XYID_* at the top of services/login/packet.lua',
}


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        h.update(f.read())
    return h.hexdigest()


def name_dir(name):
    for p in DIR_PREFIXES:
        if name.startswith(p) and len(name) > len(p):
            c = name[len(p)]
            if c.isupper() or c == '_' or c.isdigit():
                return p
    return None


def const_dir(const):
    m = re.match(r'XYID_(CGW|WGC|CG|GC|CL|LC)(?=[_A-Z])', const or '')
    return m.group(1) if m else None


def direction(t, has_bis, has_bos):
    nd, cd = name_dir(t.name), const_dir(t.xy_const)
    notes = []
    d = nd or cd
    if d is None:
        if has_bis and not has_bos:
            d = 'CL' if t.proto == 'login' else 'CG'
        elif has_bos and not has_bis:
            d = 'LC' if t.proto == 'login' else 'GC'
        notes.append('direction %s inferred from the codecs (no CG/GC prefix in the name)' % d)
    elif nd and cd and nd != cd:
        notes.append('class prefix %s but id constant %s' % (nd, t.xy_const))
    return d, notes


def walk(nodes):
    for n in nodes:
        yield n
        if n.get('kind') == 'if':
            for br in n['branches']:
                for x in walk(br['fields']):
                    yield x
        elif 'fields' in n:
            for x in walk(n['fields']):
                yield x


def assess(r, used, auth, fields, agrees):
    level, reasons = 3, []

    def lower(to, why):
        nonlocal level
        level = min(level, to)
        if why not in reasons:
            reasons.append(why)
    if r is None:
        lower(0, 'no codec')
    elif used != auth:
        lower(1, 'authoritative %s() missing' % auth)
    if r is not None and r['errors']:
        lower(1, 'codec contains run-time errors')
    for n in walk(fields):
        kind, t = n.get('kind'), n.get('type', '')
        if kind == 'opaque':
            lower(1, 'opaque stream call')
        if n.get('len_on_wire') is False:
            lower(1, 'a byte length is not on the wire')
        if n.get('count_on_wire') is False:
            lower(1, 'an array count is not on the wire')
        if n.get('loop') == 'while':
            lower(2, 'while-loop')
        if n.get('loop') == 'pairs':
            lower(2, 'pairs() order')
        if (t in ('bytes[]', 'str8', 'str16', 'str32') or kind == 'array') and 'count' not in n \
                and n.get('max') is None and n.get('len_on_wire') is not False \
                and n.get('count_on_wire') is not False:
            lower(2, 'length/count without an upper bound')
    if agrees is False:
        lower(2, 'bis() and bos() differ structurally')
    return ('none', 'low', 'medium', 'high')[level], reasons


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--root', default=srcload.DEFAULT_ROOT, help='GameServer directory (read-only)')
    ap.add_argument('--out', default=DEFAULT_OUT, help='output directory')
    args = ap.parse_args(argv)
    R = srcload.load(args.root)
    generated = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S')

    ext = {}
    for proto in ('game', 'login'):
        ids = R['ids'] if proto == 'game' else R['login_ids']
        ex = Extractor(ids, R['define_tree'], R['winners'][proto])
        for name, t in R['winners'][proto].items():
            res = {}
            for kind in ('bis', 'bos'):
                r = ex.run(t, kind)
                if r is not None:
                    r['spec'] = [codec_post.to_spec(x) for x in codec_post.sugar(r['fields'])]
                    res[kind] = r
            ext[(proto, name)] = (t, res)

    cache = {}

    def struct_size(name, codec):
        key = (name, codec)
        if key not in cache:
            cache[key] = (0, None)
            hit = ext.get(('game', name)) or ext.get(('login', name))
            val = (0, None)
            if hit is not None:
                res = hit[1]
                r = res.get(codec) or res.get('bos' if codec == 'bis' else 'bis')
                if r is not None:
                    val = codec_post.size_of(r['spec'], struct_size)
            cache[key] = val
        return cache[key]

    packets, structs, flat_rows, unk_rows = [], [], [], []
    issues = {'codec_errors': [], 'direction_notes': [], 'missing_id_constants': []}
    for (proto, name), (t, res) in sorted(ext.items(), key=lambda kv: (kv[0][0] != 'login', kv[0][1])):
        src = '%s:%d' % (t.relpath, t.line)
        if t.xy_id is NOT_CONST:
            issues['missing_id_constants'].append({'name': name, 'const': t.xy_const, 'source': src})
        is_packet = isinstance(t.xy_id, int) and t.xy_id > 0
        if not is_packet and t.xy_id is not NOT_CONST:
            s = {'name': name, 'source': src, 'domain': t.domain}
            for kind in ('bis', 'bos'):
                if kind in res:
                    r = res[kind]
                    lo, hi = codec_post.size_of(r['spec'], struct_size)
                    s[kind] = {'line': r['line'], 'size': {'min': lo, 'max': hi}, 'fields': r['spec']}
                    if r['errors']:
                        s[kind]['errors'] = r['errors']
                        for e in r['errors']:
                            issues['codec_errors'].append({'table': name, 'codec': kind, 'error': e})
            structs.append(s)
            continue
        d, dnotes = direction(t, 'bis' in res, 'bos' in res)
        ann = annotations.PACKETS.get(name, {})
        if 'dir' in ann:
            dnotes = ['direction %s from annotations.py' % ann['dir']]
            d = ann['dir']
        auth = AUTH.get(d)
        used = auth if auth in res else None
        notes = list(dnotes)
        if used is None:
            other = 'bos' if auth == 'bis' else 'bis'
            if other in res:
                used = other
                notes.append('server has no %s() for this %s packet; layout taken from %s()' % (auth, d, other))
        r = res.get(used)
        fields = r['spec'] if r is not None else []
        errors = list(r['errors']) if r is not None else []
        if r is not None:
            notes += r['notes']
        other_kind = ([k for k in ('bis', 'bos') if k in res and k != used] or [None])[0]
        agrees = None
        other_info = None
        if other_kind is not None:
            ro = res[other_kind]
            other_info = {'kind': other_kind, 'line': ro['line']}
            if not ro['spec']:
                other_info['empty'] = True
            elif r is not None:
                s1, s2 = codec_post.shape(fields), codec_post.shape(ro['spec'])
                agrees = True if s1 == s2 else ('sign-only' if loosen(s1) == loosen(s2) else False)
            other_info['agrees'] = agrees
            if ro['errors']:
                other_info['errors'] = ro['errors']
                for e in ro['errors']:
                    issues['codec_errors'].append({'table': name, 'codec': other_kind,
                                                   'side': 'non-authoritative', 'error': e})
        for e in errors:
            issues['codec_errors'].append({'table': name, 'codec': used, 'error': e})
        for n in dnotes:
            issues['direction_notes'].append({'packet': name, 'note': n})
        rows = codec_post.flatten(fields)
        unknow = [row['path'] for row in rows if codec_post.is_unknow(row['path'])]
        lo, hi = codec_post.size_of(fields, struct_size)
        conf, why = assess(r, used, auth, fields, agrees)
        entry = {'id': t.xy_id if is_packet else None, 'name': name, 'dir': d, 'proto': proto,
                 'const': t.xy_const, 'domain': t.domain, 'source': src,
                 'codec': used, 'codec_line': r['line'] if r is not None else None,
                 'other_codec': other_info, 'size': {'min': lo, 'max': hi},
                 'confidence': conf}
        if why:
            entry['confidence_reasons'] = why
        if 'derive' in ann:
            entry['derive'] = ann['derive']
        if 'note' in ann:
            entry['annotation'] = ann['note']
        entry['unknow_fields'] = unknow
        if notes:
            entry['notes'] = notes
        if errors:
            entry['errors'] = errors
        entry['fields'] = fields
        if other_info is not None and agrees is False and r is not None:
            entry['other_fields'] = res[other_kind]['spec']
        packets.append(entry)
        for row in rows:
            n = row['node']
            flags = [k for k in ('text', 'default', 'const', 'expr', 'derived', 'via', 'error') if k in n]
            flat_rows.append([entry['id'], name, d, row['path'], row['type'], row['cond'], row['array'],
                              row['line'], ','.join('%s=%s' % (k, n[k]) if k != 'text' else k for k in flags)])
            if codec_post.is_unknow(row['path']):
                unk_rows.append([entry['id'], name, d, row['path'], row['type'], t.relpath, row['line']])

    packets.sort(key=lambda p: (p['proto'] != 'login', p['id'] if p['id'] is not None else 1 << 30, p['name']))
    structs.sort(key=lambda s: s['name'])

    by_id = {}
    for p in packets:
        by_id.setdefault((p['proto'], p['id']), []).append(p['name'])
    issues['id_collisions'] = [{'proto': k[0], 'id': k[1], 'names': v} for k, v in sorted(by_id.items(), key=str)
                               if len(v) > 1]
    by_val = {}
    for n, v, line in R['id_defs']:
        by_val.setdefault(v, []).append(n)
    issues['id_constant_aliases'] = [{'id': v, 'constants': ns} for v, ns in sorted(by_val.items(), key=str)
                                     if len(ns) > 1]
    used_consts = {t.xy_const for (proto, _), (t, _) in ext.items()}
    issues['ids_without_codec'] = [{'const': n, 'id': v, 'line': line} for n, v, line in R['id_defs']
                                   if n not in used_consts and v not in (0,)]
    shadow = []
    for proto in ('game', 'login'):
        seen = {}
        for t in R['all_defs'][proto]:
            seen.setdefault(t.name, []).append('%s:%d' % (t.relpath, t.line))
        for n, locs in seen.items():
            if len(locs) > 1:
                shadow.append({'name': n, 'winner': locs[-1], 'shadowed': locs[:-1], 'status': 'live duplicate'})
    for c in R['commented_defs']:
        live = R['winners']['game'].get(c['name']) or R['winners']['login'].get(c['name'])
        shadow.append({'name': c['name'], 'winner': ('%s:%d' % (live.relpath, live.line)) if live else None,
                       'shadowed': ['%s:%d' % (c['file'], c['line'])],
                       'status': 'commented out (--[[ ]] block)' if c['block_comment'] else 'commented out'})
    issues['duplicate_definitions'] = shadow
    issues['id_constant_redefinitions'] = R['id_redefs']
    issues['ignored_files'] = R['ignored_files']

    conf_count, dir_count = {}, {}
    for p in packets:
        conf_count[p['confidence']] = conf_count.get(p['confidence'], 0) + 1
        key = '%s/%s' % (p['proto'], p['dir'])
        dir_count[key] = dir_count.get(key, 0) + 1
    stats = {'packets': len(packets), 'packets_by_dir': dir_count, 'structs': len(structs),
             'game_id_constants': len(R['ids']), 'login_id_constants': len(R['login_ids']),
             'live_tables': sum(len(v) for v in R['winners'].values()),
             'leaf_fields': len(flat_rows), 'unknow_fields': len(unk_rows),
             'anonymous_const_fields': sum(1 for row in flat_rows if row[3].startswith('<const') or '.<const' in row[3]),
             'confidence': conf_count, 'id_collisions': len(issues['id_collisions']),
             'ids_without_codec': len(issues['ids_without_codec']),
             'codec_errors': len(issues['codec_errors'])}

    tools = {}
    for fn in TOOL_FILES:
        p = os.path.join(HERE, fn)
        if os.path.exists(p):
            tools[fn] = sha256_file(p)
    doc = {'spec': 'tlbb-skynet-protocol', 'spec_version': 1, 'generated': generated,
           'generator': {'script': 'CY-Source/Tools/protocol/specgen.py', 'sha256': tools},
           'source_root': args.root, 'inputs': [s.info() for s in R['sources']],
           'bind_order': ['%s/%s' % bo for bo in R['bind_order']],
           'framing': FRAMING, 'wire': WIRE, 'types': TYPES, 'conditions': CONDITIONS, 'dsl': DSL,
           'stats': stats, 'issues': issues, 'structs': structs, 'packets': packets}

    os.makedirs(args.out, exist_ok=True)
    header = ('packets.yaml - GENERATED by CY-Source/Tools/protocol/specgen.py; do not edit by hand.\n'
              'Source of truth: live skynet Lua codecs (read-only).  Regenerate and diff after any server codec change.')
    with open(os.path.join(args.out, 'packets.yaml'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(yamlout.dump(doc, header=header))
    with open(os.path.join(args.out, 'packets.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(doc, f, ensure_ascii=False, indent=1)
        f.write('\n')

    def tsv(path, head, rows):
        with open(os.path.join(args.out, path), 'w', encoding='utf-8', newline='\n') as f:
            f.write('\t'.join(head) + '\n')
            for row in rows:
                f.write('\t'.join('' if v is None else re.sub(r'[\t\r\n]+', ' ', str(v)) for v in row) + '\n')
    tsv('packets_summary.tsv',
        ['id', 'name', 'dir', 'proto', 'domain', 'source', 'codec', 'other_codec', 'other_agrees',
         'leaf_fields', 'unknow_fields', 'size_min', 'size_max', 'has_if', 'has_array', 'confidence', 'notes'],
        [[p['id'], p['name'], p['dir'], p['proto'], p['domain'], p['source'], p['codec'],
          (p['other_codec'] or {}).get('kind'), (p['other_codec'] or {}).get('agrees'),
          sum(1 for row in flat_rows if row[1] == p['name']), len(p['unknow_fields']),
          p['size']['min'], p['size']['max'],
          any(n.get('kind') == 'if' for n in walk(p['fields'])),
          any(n.get('kind') == 'array' for n in walk(p['fields'])),
          p['confidence'], '; '.join(p.get('confidence_reasons', []) + p.get('notes', []))] for p in packets])
    tsv('fields_flat.tsv', ['id', 'packet', 'dir', 'path', 'type', 'condition', 'array', 'line', 'flags'], flat_rows)
    tsv('unknow_fields.tsv', ['id', 'packet', 'dir', 'path', 'type', 'file', 'line'], unk_rows)
    print('specgen: %d packets (%s), %d structs, %d leaf fields, %d unknow, confidence %s -> %s' % (
        len(packets), ', '.join('%s=%d' % kv for kv in sorted(dir_count.items())), len(structs),
        len(flat_rows), len(unk_rows), conf_count, args.out))
    return 0


if __name__ == '__main__':
    sys.exit(main())
