"""res_compare_cy.py - resources of CanonicalCY (CY 3.71.9609 + GL GUI) against Canonical (client_GL), by NAME.

Read only. Compares:
  * all.obj objects, all.material materials, all.effect / all.particle / all.skill definitions
    (name + whitespace-normalised block hash, Tools/pipeline/tlbbfmt.py)
  * files by lower-case base name per kind (mesh, skeleton, texture, scene files, sound, other) with sha256
    (Canonical: _manifest/mirror.tsv; CanonicalCY: _manifest/files.tsv). S1 files may carry 1-12 bytes of extractor
    padding (sources.yaml), so 'differs' for textures/meshes includes padding-only differences: 'differs_same_prefix'
    counts pairs whose shorter file is a prefix of the longer one (checked on disk for those pairs).
  * scene 2 (Dai Ly): SceneDefineEx rows and the files the rows name.
Usage: res_compare_cy.py --out <dir>
"""
import argparse
import collections
import csv
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(REPO, 'Tools', 'game'))
import tlbbfmt as F  # noqa: E402
import dbc_inventory as INV  # noqa: E402

CYS = r'C:\TLBB\085\CY-Source'
GL = os.path.join(CYS, 'Assets', 'Canonical')
CY = os.path.join(CYS, 'Assets', 'CanonicalCY')
KIND = {'.mesh': 'mesh', '.skeleton': 'skeleton', '.dds': 'texture', '.tga': 'texture', '.png': 'texture',
        '.jpg': 'texture', '.bmp': 'texture', '.scene': 'scene', '.terrain': 'scene', '.heightmap': 'scene',
        '.gridinfo': 'scene', '.lightmap': 'scene', '.path': 'scene', '.region': 'scene', '.wcollision': 'scene',
        '.esd': 'scene', '.nav': 'scene', '.ogg': 'sound', '.wav': 'sound', '.mp3': 'sound', '.lua': 'lua',
        '.xml': 'xml', '.txt': 'table', '.dynbone': 'dynbone', '.sdt': 'other'}


def lp(p):
    return '\\\\?\\' + os.path.abspath(p)


def read(root, rel):
    with open(lp(os.path.join(root, 'Data', rel)), 'rb') as f:
        return f.read()


def cmp_defs(a, b, same):
    ka, kb = set(a), set(b)
    both = ka & kb
    eq = sum(1 for k in both if same(a[k], b[k]))
    return {'cy': len(ka), 'gl': len(kb), 'both': len(both), 'both_identical': eq, 'both_differ': len(both) - eq,
            'cy_only': len(ka - kb), 'gl_only': len(kb - ka)}


def load_manifest(path, cols):
    out = {}
    with open(lp(path), encoding='utf-8-sig') as f:
        r = csv.reader(f, delimiter='\t', quoting=csv.QUOTE_NONE)
        hdr = next(r)
        ix = [hdr.index(c) for c in cols]
        for row in r:
            if len(row) <= max(ix):
                continue
            out[row[ix[0]]] = tuple(row[i] for i in ix[1:])
    return out


def prefix_equal(rel_a, rel_b):
    pa, pb = os.path.join(CY, 'Data', rel_a), os.path.join(GL, 'Data', rel_b)
    sa, sb = os.path.getsize(lp(pa)), os.path.getsize(lp(pb))
    n = min(sa, sb)
    if abs(sa - sb) > 16:
        return False
    ha, hb = hashlib.sha256(), hashlib.sha256()
    with open(lp(pa), 'rb') as f:
        ha.update(f.read(n))
    with open(lp(pb), 'rb') as f:
        hb.update(f.read(n))
    return ha.digest() == hb.digest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    res = {}

    # scripts
    oc, _ = F.parse_all_obj(read(CY, r'ModelFolder\all.obj'))
    og, _ = F.parse_all_obj(read(GL, r'ModelFolder\all.obj'))
    res['all.obj'] = cmp_defs({o['name']: o['sha'] for o in oc}, {o['name']: o['sha'] for o in og},
                              lambda x, y: x == y)
    mc, _ = F.material_defs(read(CY, r'MaterialFolder\all.material'))
    mg, _ = F.material_defs(read(GL, r'MaterialFolder\all.material'))
    res['all.material'] = cmp_defs(mc, mg, lambda x, y: x['sha'] == y['sha'])
    for kind in ('effect', 'particle', 'skill'):
        dc, _ = F.script_defs(read(CY, 'EffectFolder\\all.' + kind), kind)
        dg, _ = F.script_defs(read(GL, 'EffectFolder\\all.' + kind), kind)
        res['all.' + kind] = cmp_defs(dc, dg, lambda x, y: x[0] == y[0])

    # files by base name
    gl_files = load_manifest(os.path.join(GL, '_manifest', 'mirror.tsv'), ['relpath', 'size', 'sha256'])
    cy_files = load_manifest(os.path.join(CY, '_manifest', 'files.tsv'), ['relpath', 'size', 'sha256', 'layer'])
    cy_files = {k: v for k, v in cy_files.items() if v[0] != '-1' and not v[2].startswith('gl-')}

    def by_base(files):
        d = {}
        for rel, v in files.items():
            base = rel.split('\\')[-1].lower()
            ext = os.path.splitext(base)[1]
            d.setdefault((KIND.get(ext, 'other'), base), (rel, v))
        return d
    bc, bg = by_base(cy_files), by_base(gl_files)
    kinds = collections.defaultdict(collections.Counter)
    diff_rows = []
    for key in set(bc) | set(bg):
        k = key[0]
        if key in bc and key in bg:
            (ra, va), (rb, vb) = bc[key], bg[key]
            if va[1] == vb[1]:
                kinds[k]['both_identical'] += 1
            else:
                kinds[k]['both_differ'] += 1
                if k in ('mesh', 'skeleton', 'texture', 'scene') and abs(int(va[0]) - int(vb[0])) <= 16:
                    diff_rows.append((k, ra, rb))
        elif key in bc:
            kinds[k]['cy_only'] += 1
        else:
            kinds[k]['gl_only'] += 1
    # padding-only differences (checked on a bounded sample per kind to keep I/O reasonable)
    samp = collections.Counter()
    for k, ra, rb in diff_rows:
        if samp[k] >= 3000:
            continue
        samp[k] += 1
        if prefix_equal(ra, rb):
            kinds[k]['differ_prefix_equal_in_sample'] += 1
        kinds[k]['differ_sampled'] += 1
    res['files_by_basename'] = {k: dict(v) for k, v in sorted(kinds.items())}

    # scene 2
    def scene_rows(root):
        t = INV.Table(os.path.join(root, 'Data', 'ConfigFolder', 'SceneDefineEx.txt'))
        return t, {r[0]: r for r in t.rows}
    tc, rc = scene_rows(CY)
    tg, rg = scene_rows(GL)
    s2c, s2g = rc.get(2), rg.get(2)
    scene = {'cy_types': tc.types, 'gl_types': tg.types, 'cy_row': s2c, 'gl_row': s2g, 'files': []}
    names = set()
    for row in (s2c or []), (s2g or []):
        for v in row:
            if isinstance(v, str) and '.' in v and len(v) < 120:
                names.add(v.replace('/', '\\').split('\\')[-1].lower())
    for n in sorted(names):
        ext = os.path.splitext(n)[1]
        key = (KIND.get(ext, 'other'), F.disp(n.encode('gbk', 'replace')).lower() if False else n)
        a, b = bc.get(key), bg.get(key)
        scene['files'].append({'name': n, 'cy': a[0] if a else None, 'gl': b[0] if b else None,
                               'cy_size': int(a[1][0]) if a else None, 'gl_size': int(b[1][0]) if b else None,
                               'identical': bool(a and b and a[1][1] == b[1][1])})
    # every file of the dali scene folder by base name (terrain, heightmap, lightmap, gridinfo, region, path, ...)
    dali = collections.Counter()
    for (k, base), (rel, v) in bc.items():
        if base.startswith('dali.') or base.startswith('dali_'):
            other = bg.get((k, base))
            dali['cy'] += 1
            if other:
                dali['both'] += 1
                dali['identical'] += int(other[1][1] == v[1])
            else:
                dali['cy_only'] += 1
    for (k, base), (rel, v) in bg.items():
        if (base.startswith('dali.') or base.startswith('dali_')) and (k, base) not in bc:
            dali['gl_only'] += 1
    scene['dali_basename_files'] = dict(dali)
    res['scene2'] = scene
    with open(os.path.join(args.out, 'res_compare_cy.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(res, f, ensure_ascii=False, indent=1, default=str)
    brief = {k: v for k, v in res.items() if k != 'scene2'}
    brief['scene2_files'] = scene['files']
    brief['scene2_dali'] = scene['dali_basename_files']
    print(json.dumps(brief, ensure_ascii=False, indent=1, default=str))


if __name__ == '__main__':
    main()
