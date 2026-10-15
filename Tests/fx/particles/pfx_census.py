# -*- coding: utf-8 -*-
"""pfx_census.py - key census of all.particle files (read-only; bytes kept as latin-1 so GBK names survive).

For every (source, context, type, key): uses, distinct values, arity histogram, top values.
Contexts: sys[<renderer>] (system-level lines, attributed to the renderer the system uses),
          emitter:<Type>, affector:<Type>.
The OGRE script parser lower-cases emitter/affector attribute names; system attribute names are kept as written.
Usage: py -3 pfx_census.py <outDir> [name=path ...]
"""
import collections
import json
import os
import sys

DEFAULT = {
    'canon': r'C:\TLBB\085\CY-Source\Assets\Canonical\Data\EffectFolder\all.particle',
    's2': r'C:\TLBB\085\Tools\DATA NEW\DataCY31-08-26\Effect\all.particle',
}


def parse(path):
    """Yield (system, renderer, ctx, type, key, value, line) for every attribute line."""
    raw = open(path, 'rb').read().decode('latin-1')
    lines = raw.replace('\r\n', '\n').replace('\r', '\n').split('\n')
    depth = 0
    sysname = None
    pending = None          # ('emitter'|'affector', Type) waiting for '{'
    cur = None              # ('emitter'|'affector', Type) inside a sub block
    sysattrs = []           # buffered system lines (renderer known at the end)
    out = []
    renderer = 'billboard'

    def flush_sys():
        for (k, v, ln) in sysattrs:
            out.append((sysname, renderer, 'sys', renderer, k, v, ln))

    for ln, s in enumerate(lines, 1):
        s = s.strip()
        if not s or s.startswith('//'):
            continue
        # OGRE splits "{" / "}" only when they are the whole line; tolerate "name {" too
        if s == '{':
            depth += 1
            if depth == 2:
                cur, pending = pending, None
            continue
        if s == '}':
            if depth == 2:
                cur = None
            elif depth == 1:
                flush_sys()
                sysattrs = []
                renderer = 'billboard'
                sysname = None
            depth = max(0, depth - 1)
            continue
        if depth == 0:
            sysname = s.split()[0] if s.split() else s
            if s.endswith('{'):
                depth = 1
            continue
        parts = s.split(None, 1)
        key = parts[0]
        val = parts[1].strip() if len(parts) > 1 else ''
        if depth == 1:
            if key in ('emitter', 'affector'):
                pending = (key, val.split()[0] if val else '?')
                if s.endswith('{'):
                    depth = 2
                    cur, pending = pending, None
                continue
            if key == 'renderer':
                renderer = val
            sysattrs.append((key, val, ln))
        elif depth == 2 and cur:
            out.append((sysname, renderer, cur[0], cur[1], key.lower(), val, ln))
    return out


def main():
    od = sys.argv[1] if len(sys.argv) > 1 else '.'
    srcs = dict(DEFAULT)
    for a in sys.argv[2:]:
        n, p = a.split('=', 1)
        srcs[n] = p
    os.makedirs(od, exist_ok=True)
    rows = []
    summary = {}
    for name, path in srcs.items():
        if not os.path.exists(path):
            summary[name] = 'missing ' + path
            continue
        recs = parse(path)
        acc = collections.OrderedDict()
        systems = set()
        for (sysn, rend, ctx, typ, key, val, ln) in recs:
            systems.add(sysn)
            k = (ctx, typ, key)
            e = acc.get(k)
            if e is None:
                e = acc[k] = {'uses': 0, 'vals': collections.Counter(), 'arity': collections.Counter(), 'first': ln}
            e['uses'] += 1
            e['vals'][val] += 1
            e['arity'][len(val.split())] += 1
        summary[name] = {'path': path, 'systems': len(systems), 'attr_lines': len(recs), 'keys': len(acc)}
        for (ctx, typ, key), e in sorted(acc.items(), key=lambda kv: (kv[0][0], kv[0][1], -kv[1]['uses'])):
            top = ' | '.join('%s x%d' % (v[:60], c) for v, c in e['vals'].most_common(5))
            ar = ','.join('%d:%d' % (a, c) for a, c in sorted(e['arity'].items()))
            rows.append((name, ctx, typ, key, e['uses'], len(e['vals']), ar, e['first'], top))
    with open(os.path.join(od, 'pfx_keys.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('src\tctx\ttype\tkey\tuses\tdistinct\tarity\tfirst_line\ttop_values(latin1)\n')
        for r in rows:
            f.write('\t'.join(str(x) for x in r) + '\n')
    with open(os.path.join(od, 'pfx_summary.json'), 'w', encoding='utf-8') as f:
        json.dump(summary, f, indent=1)
    print(json.dumps(summary, indent=1))


if __name__ == '__main__':
    main()
