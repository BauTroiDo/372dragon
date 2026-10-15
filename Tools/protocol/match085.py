#!/usr/bin/env python3
"""match085.py - cross-reference every skynet packet (Registry/protocol/packets.json)
with the 0.85 C++ packet classes (Src/Shared/Common/Packets) and compare the
fixed-layout prefix of skynet's authoritative codec with 0.85 Read().

Output: Registry/protocol/match_085.tsv  (+ summary on stdout)
match_kind:
  exact         both layouts fully fixed, same size, every skynet field boundary = a 0.85 field
  prefix        all fields of the shorter fixed prefix line up (one side continues differently)
  partial       the first N >= 1 fields line up, then they diverge
  differ        the first field already differs
  both_empty    no payload on either side
  no_085_class  no 0.85 class with that name
  only_085      0.85 class without a skynet packet
Only `exact` / `prefix` / the aligned run of `partial` should be used to name unknow_N fields.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cpp085  # noqa: E402
from codec_post import is_unknow  # noqa: E402
from extract_expr import SIZES  # noqa: E402

REG = os.path.abspath(os.path.join(HERE, '..', '..', 'Registry', 'protocol'))


def norm(s):
    return re.sub(r'[^a-z0-9]', '', (s or '').lower())


KIND_085 = {'FLOAT': 'f', 'float': 'f', 'double': 'f'}


def kind_sk(t):
    if t == 'f32':
        return 'f'
    if t.startswith('bytes') or t in ('array<u8>', 'array<i8>'):
        return 'b'
    return 'i'


def kind_cc(typ, size):
    if typ in KIND_085:
        return 'f'
    if typ in ('CHAR', 'char', 'BYTE', 'UCHAR') and size and size > 1:
        return 'b'
    return 'i' if typ else '?'


def sk_prefix(fields, structs):
    """Leading fixed-size fields of a skynet spec -> ([(off, size, name)], complete?)."""
    out, off = [], 0
    for n in fields:
        if n.get('kind') is not None and not (n.get('kind') == 'array' and 'fields' not in n):
            return out, False
        t = n['type']
        name = n.get('name') or ('<const %s>' % n.get('const')) if 'const' in n else (n.get('name') or '<anon>')
        if t in SIZES:
            out.append((off, SIZES[t], name, kind_sk(t)))
            off += SIZES[t]
            continue
        m = re.match(r'bytes\[(\d+)\]$', t)
        if m:
            out.append((off, int(m.group(1)), name, 'b'))
            off += int(m.group(1))
            continue
        m = re.match(r'array<(\w+)>$', t)
        if m and 'count' in n and m.group(1) in SIZES:
            size = n['count'] * SIZES[m.group(1)]
            out.append((off, size, name + '[%d]' % n['count'], kind_sk(t)))
            off += size
            continue
        if t.startswith('struct '):
            sub = structs.get(t[7:], {}).get(n.get('codec') or 'bis') or structs.get(t[7:], {}).get('bos')
            if sub and sub['size']['min'] == sub['size']['max'] and sub['size']['max'] is not None:
                inner, ok = sk_prefix(sub['fields'], structs)
                if ok:
                    for o, s, nm, kd in inner:
                        out.append((off + o, s, '%s.%s' % (name, nm), kd))
                    off += sub['size']['max']
                    continue
        return out, False
    return out, True


def cc_prefix(cls, sizes):
    out, off = [], 0
    for op in cls.read or []:
        if op['k'] == 'f' and op['size'] is not None and not op.get('count'):
            typ = op.get('elem')
            typ = cls.members.get(typ, (typ, []))[0] if typ in cls.members else typ
            if typ in cpp085.STRUCTS and op['size'] == cpp085.STRUCTS[typ][0]:
                o2 = 0
                for nm, sz in cpp085.STRUCTS[typ][1]:
                    out.append((off + o2, sz, '%s.%s' % (op['target'], nm), 'f' if typ == 'WORLD_POS' else 'i'))
                    o2 += sz
            else:
                out.append((off, op['size'], op['target'], kind_cc(typ, op['size'])))
            off += op['size']
            continue
        return out, False
    return out, True


def compare(sk, cc):
    """Fields line up when offset, size and kind (int / float / bytes) agree."""
    cmap = {o: (s, n, k) for o, s, n, k in cc}
    lead, exact_names, covered = 0, [], []
    still = True
    for o, s, n, k in sk:
        hit = cmap.get(o)
        if hit and hit[0] == s and (hit[2] == k or '?' in (hit[2], k)):
            exact_names.append((n, hit[1], o))
            if still:
                lead += 1
        else:
            still = False
            for co, cs, cn, ck in cc:
                if co <= o and o + s <= co + cs:
                    covered.append((n, '%s+%d' % (cn, o - co), o))
                    break
    return lead, exact_names, covered


def main():
    with open(os.path.join(REG, 'packets.json'), encoding='utf-8') as f:
        doc = json.load(f)
    structs = {}
    for s in doc['structs']:
        structs[s['name']] = {k: s[k] for k in ('bis', 'bos') if k in s}
    for p in doc['packets']:
        structs.setdefault(p['name'], {'bis': {'fields': p['fields'], 'size': p['size']},
                                       'bos': {'fields': p['fields'], 'size': p['size']}})
    classes, sizes, macros, enum = cpp085.load_classes()
    index = {}
    for c in classes.values():
        index.setdefault(norm(c.name), c)
    for c in classes.values():
        if c.enum:
            index.setdefault(norm(c.enum.replace('PACKET_', '')), c)
    rows, used, stats = [], set(), {}
    for p in doc['packets']:
        cands = [norm(p['name']), norm((p.get('const') or '').replace('XYID_', ''))]
        c = next((index[k] for k in cands if k in index), None)
        sk, sk_full = sk_prefix(p['fields'], structs)
        unknow = p['unknow_fields']
        row = {'id': p['id'], 'name': p['name'], 'dir': p['dir'], 'proto': p['proto'], 'codec': p['codec'],
               'sk_fixed_fields': len(sk), 'sk_fixed_bytes': sk[-1][0] + sk[-1][1] if sk else 0,
               'sk_complete': sk_full, 'unknow': len(unknow)}
        if c is None:
            row.update({'kind': 'no_085_class'})
            rows.append(row)
            stats['no_085_class'] = stats.get('no_085_class', 0) + 1
            continue
        used.add(c.name)
        cc, cc_full = cc_prefix(c, sizes)
        lead, exact_names, covered = compare(sk, cc)
        if not sk and not cc and sk_full and cc_full:
            kind = 'both_empty'
        elif sk_full and cc_full and lead == len(sk) == len(cc) and \
                (sk[-1][0] + sk[-1][1]) == (cc[-1][0] + cc[-1][1]):
            kind = 'exact'
        elif sk and cc and lead == min(len(sk), len(cc)) and lead > 0:
            kind = 'prefix'
        elif lead > 0:
            kind = 'partial'
        else:
            kind = 'differ'
        stats[kind] = stats.get(kind, 0) + 1
        props = ['%s=%s' % (n, cn) for n, cn, o in exact_names[:lead] if is_unknow(n)]
        later = ['%s~%s' % (n, cn) for n, cn, o in exact_names[lead:] if is_unknow(n)]
        row.update({'kind': kind, 'class_085': c.name, 'enum_085': c.enum, 'id_085': c.id,
                    'read_src': c.read_src, 'c_fixed_fields': len(cc),
                    'c_fixed_bytes': cc[-1][0] + cc[-1][1] if cc else 0, 'c_complete': cc_full,
                    'lead': lead, 'proposals': '; '.join(props),
                    'weak_proposals': '; '.join(later[:12])})
        rows.append(row)
    for c in sorted(classes.values(), key=lambda x: x.name):
        if c.name not in used:
            rows.append({'kind': 'only_085', 'class_085': c.name, 'enum_085': c.enum, 'id_085': c.id,
                         'read_src': c.read_src})
            stats['only_085'] = stats.get('only_085', 0) + 1
    cols = ['id', 'name', 'dir', 'proto', 'codec', 'kind', 'class_085', 'enum_085', 'id_085', 'read_src',
            'lead', 'sk_fixed_fields', 'c_fixed_fields', 'sk_fixed_bytes', 'c_fixed_bytes', 'sk_complete',
            'c_complete', 'unknow', 'proposals', 'weak_proposals']
    out = os.path.join(REG, 'match_085.tsv')
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\t'.join(cols) + '\n')
        for r in rows:
            f.write('\t'.join('' if r.get(k) is None else str(r.get(k)) for k in cols) + '\n')
    n_props = sum(len(r['proposals'].split('; ')) for r in rows if r.get('proposals'))
    print('match_085: %d skynet packets, %d 0.85 classes; %s; %d unknow names proposed -> %s' % (
        len(doc['packets']), len(classes), stats, n_props, out))
    return 0


if __name__ == '__main__':
    sys.exit(main())
