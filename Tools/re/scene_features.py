# -*- coding: utf-8 -*-
"""scene_features.py - inventory of per-scene beauty data in client_GL (read-only).

Binary: .hfog (floats), .hdr (floats), .newhdrbloom (4f+2B+4f), .godrays/.bloom (if any)
XML-ish: .skysphere, .EnScene, .dynbone (tag/attribute/leaf inventory with numeric ranges)
.Scene: Object type counts + property names/values for beauty-related types (TerrainLiquid, lights, fog, sky...)
Outputs: Tools/re/out/scene_features.json, scene_xml_inventory.tsv, scene_objects.tsv, scene_binfields.tsv
"""
import collections
import glob
import json
import os
import re
import struct

R = r'C:\TLBB\085'
D = R + r'\client_GL\Data'
SF = D + r'\SceneFolder'
OUT = R + r'\CY-Source\Tools\re\out'


def gbk(b):
    return b.decode('gbk', 'replace')


def binstats():
    res = {}
    rows = []
    for ext, fmt in (('.hfog', None), ('.hdr', None), ('.newhdrbloom', '<4f2B4f'), ('.godrays', None), ('.bloom', None)):
        files = [p for p in glob.glob(SF + r'\*') if p.lower().endswith(ext)]
        sizes = collections.Counter(os.path.getsize(p) for p in files)
        fields = collections.defaultdict(list)
        for p in files:
            b = open(p, 'rb').read()
            if fmt and len(b) == struct.calcsize(fmt):
                vals = struct.unpack(fmt, b)
            elif len(b) % 4 == 0:
                vals = struct.unpack('<%df' % (len(b) // 4), b)
            else:
                continue
            for i, v in enumerate(vals):
                fields[i].append(v)
        res[ext] = {'files': len(files), 'sizes': dict(sizes), 'names': sorted(os.path.basename(p) for p in files)[:12]}
        for i, vs in sorted(fields.items()):
            c = collections.Counter(round(v, 4) for v in vs)
            rows.append([ext, str(i), str(len(vs)), '%g' % min(vs), '%g' % max(vs),
                         ' '.join('%g=%d' % kv for kv in c.most_common(4))])
    with open(OUT + r'\scene_binfields.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('ext\tfield(float idx; newhdrbloom: 0-3 f,4-5 byte,6-9 f)\tn\tmin\tmax\ttop_values\n')
        for r in rows:
            f.write('\t'.join(r) + '\n')
    return res


TAG = re.compile(rb'<([A-Za-z_][\w.]*)((?:\s+[\w.:]+\s*=\s*"[^"]*")*)\s*(/?)>')
ATTR = re.compile(rb'([\w.:]+)\s*=\s*"([^"]*)"')
LEAF = re.compile(rb'<([A-Za-z_][\w.]*)>([^<]*)</\1>')


def xml_inventory(files, label, rows):
    tags = collections.Counter()
    attrs = collections.defaultdict(lambda: {'n': 0, 'num': [], 'cat': collections.Counter()})
    leaves = collections.defaultdict(lambda: {'n': 0, 'num': [], 'cat': collections.Counter()})
    parent_of = collections.defaultdict(collections.Counter)
    for p in files:
        b = open(p, 'rb').read()
        stack = []
        for m in re.finditer(rb'<(/?)([A-Za-z_][\w.]*)([^>]*?)(/?)>', b):
            close, name, rest, selfc = m.group(1), m.group(2).decode('latin-1'), m.group(3), m.group(4)
            if close:
                if stack and stack[-1] == name:
                    stack.pop()
                continue
            tags[name] += 1
            parent_of[name][stack[-1] if stack else '<root>'] += 1
            for a, v in ATTR.findall(rest):
                k = name + '@' + a.decode('latin-1')
                st = attrs[k]
                st['n'] += 1
                vv = v.decode('latin-1')
                try:
                    st['num'].append([float(x) for x in vv.split()] or [0.0])
                except ValueError:
                    st['cat'][gbk(v)[:40]] += 1
            if not selfc and not rest.strip().endswith(b'/'):
                stack.append(name)
        for name, v in LEAF.findall(b):
            k = name.decode('latin-1')
            st = leaves[k]
            st['n'] += 1
            vv = v.decode('latin-1').strip()
            try:
                st['num'].append([float(x) for x in vv.split()] or [0.0])
            except ValueError:
                st['cat'][gbk(v.strip())[:40]] += 1

    def rng(nums):
        if not nums:
            return ''
        w = max(len(x) for x in nums)
        out = []
        for j in range(min(w, 6)):
            col = [x[j] for x in nums if len(x) > j]
            out.append('%d:%g..%g' % (j, min(col), max(col)))
        return ' '.join(out)
    for k, st in sorted(attrs.items()):
        rows.append([label, 'attr', k, str(st['n']), rng(st['num']), '; '.join('%s=%d' % kv for kv in st['cat'].most_common(5))])
    for k, st in sorted(leaves.items()):
        rows.append([label, 'leaf', k, str(st['n']), rng(st['num']), '; '.join('%s=%d' % kv for kv in st['cat'].most_common(5))])
    for k, n in sorted(tags.items()):
        rows.append([label, 'tag', k, str(n), 'parents: ' + ' '.join('%s=%d' % kv for kv in parent_of[k].most_common(3)), ''])
    return {'files': len(files), 'tags': len(tags)}


def scene_objects():
    types = collections.Counter()
    props = collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
    scenes_with = collections.Counter()
    roots = collections.Counter()
    for p in glob.glob(SF + r'\*.Scene'):
        b = open(p, 'rb').read()
        seen = set()
        for m in re.finditer(rb'<Object\s+type="([^"]+)"[^>]*>(.*?)</Object>', b, re.S):
            t = m.group(1).decode('latin-1')
            types[t] += 1
            seen.add(t)
            for a, v in re.findall(rb'<Property\s+name="([^"]+)"\s+value="([^"]*)"', m.group(2)):
                props[t][a.decode('latin-1')][gbk(v)[:40]] += 1
        for t in seen:
            scenes_with[t] += 1
        for m in re.finditer(rb'<([A-Za-z]+)[\s>]', b[:4000]):
            roots[m.group(1).decode('latin-1')] += 1
    rows = []
    for t, n in types.most_common():
        for a, c in sorted(props[t].items()):
            rows.append([t, str(n), str(scenes_with[t]), a, str(sum(c.values())), '; '.join('%s=%d' % kv for kv in c.most_common(4))])
    with open(OUT + r'\scene_objects.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('object_type\tobjects\tscenes_with_type\tproperty\tuses\ttop_values\n')
        for r in rows:
            f.write('\t'.join(r) + '\n')
    return {'object_types': dict(types.most_common()), 'scene_header_tags': dict(roots.most_common(15))}


def main():
    os.makedirs(OUT, exist_ok=True)
    res = {'bin': binstats()}
    rows = []
    sky = [p for p in glob.glob(SF + r'\*') if p.lower().endswith('.skysphere')]
    ens = [p for p in glob.glob(SF + r'\*') if p.lower().endswith('.enscene')]
    dyn = [p for p in glob.glob(D + r'\Model*Folder\*') if p.lower().endswith('.dynbone')]
    res['skysphere'] = xml_inventory(sky, 'skysphere', rows)
    res['enscene'] = xml_inventory(ens, 'EnScene', rows)
    res['dynbone'] = xml_inventory(dyn, 'dynbone', rows)
    with open(OUT + r'\scene_xml_inventory.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('file_type\tkind\tname\tn\tnumeric_ranges / parents\ttop_values\n')
        for r in rows:
            f.write('\t'.join(r) + '\n')
    res['scene'] = scene_objects()
    # co-occurrence of per-scene files
    base = collections.defaultdict(set)
    for p in glob.glob(SF + r'\*'):
        nm, ext = os.path.splitext(os.path.basename(p))
        base[nm.lower()].add(ext.lower())
    combos = collections.Counter()
    for nm, exts in base.items():
        if '.scene' in exts:
            combos[' '.join(sorted(e for e in exts if e in ('.hfog', '.hdr', '.newhdrbloom', '.skysphere', '.enscene', '.godrays', '.bloom')))] += 1
    res['per_scene_file_combos'] = dict(combos.most_common(20))
    json.dump(res, open(OUT + r'\scene_features.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps(res, ensure_ascii=False, indent=1)[:5000])


if __name__ == '__main__':
    main()
