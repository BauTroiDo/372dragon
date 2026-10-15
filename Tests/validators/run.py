# -*- coding: utf-8 -*-
"""Runner for the CY-Source data validators on a "touched set" (what a batch changed).

  $env:PYTHONUTF8="1"
  & "C:\\Program Files\\Python313\\python.exe" -m validators.run --data <Data root> --touched <touched.json>
        [--base <base Data root for V13/V06 stray baseline>] [--out <dir>]
  (run from C:\\TLBB\\085\\CY-Source\\Tests, or add that folder to sys.path)

touched.json (written by Tools\\pipeline\\build_canonical.py; names are GBK bytes as hex):
  {"files": ["Model3Folder\\\\x.mesh", ...],             # data-root relative on-disk paths
   "objects": [{"hex": "...", "name": "..."}, ...],      # all.obj objects to run V03 on
   "materials": [...], "effects": [...], "particles": [...],
   "scripts": [{"file": "ModelFolder\\\\all.obj", "edits": [ ... V13 edit records ... ]}]}
Cascade: objects -> their meshes/skeletons (V01/V02), materials (V04) and effects (V06); effects -> particle
systems / sub-effects / materials; materials -> texture files (V05).
Writes validate.json and validate.txt into --out; exit code 1 when any error.
"""
import argparse
import json
import os
import sys

if __package__ in (None, ''):
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    __package__ = 'validators'

from . import v01_mesh, v02_skeleton, v03_obj, v04_material, v05_dds, v06_effect, v13_gbk  # noqa: E402
from .common import DataRoot, Report, ERROR, WARN, INFO, disp, ext_of  # noqa: E402


def _name(x):
    if isinstance(x, dict):
        if x.get('hex'):
            return bytes.fromhex(x['hex'])
        return x['name'].encode('gbk')
    if isinstance(x, bytes):
        return x
    return x.encode('gbk')


def run_all(data_root, touched, base_root=None, report=None):
    rep = report if report is not None else Report()
    root = data_root if isinstance(data_root, DataRoot) else DataRoot(data_root)
    base = None
    if base_root is not None:
        base = base_root if isinstance(base_root, DataRoot) else DataRoot(base_root)
    files = list(dict.fromkeys(touched.get('files', [])))
    materials = [_name(x) for x in touched.get('materials', [])]
    effects = [_name(x) for x in touched.get('effects', [])]
    particles = [_name(x) for x in touched.get('particles', [])]
    extra_files = []
    stats = {'objects': 0, 'materials': 0, 'effects': 0, 'particles': 0, 'meshes': 0, 'skeletons': 0,
             'textures': 0, 'scripts': 0}
    # V03 (+ V02 bones per submesh) on objects
    for o in touched.get('objects', []):
        nm = _name(o)
        _r, out = v03_obj.check_object(root, nm, report=rep)
        stats['objects'] += 1
        extra_files += out['meshes'] + out['skeletons']
        materials += [m for m in out['materials'] if m not in materials]
        effects += [e for e in out['effects'] if e not in effects]
    # V06 on effects (recursive) and particles
    seen_e = set()
    i = 0
    while i < len(effects):
        e = effects[i]
        i += 1
        if e in seen_e:
            continue
        seen_e.add(e)
        _r, refs = v06_effect.check_effect(root, e, report=rep)
        stats['effects'] += 1
        effects += [x for x in refs['effects'] if x not in seen_e]
        particles += [x for x in refs['particles'] if x not in particles]
        materials += [x for x in refs['materials'] if x not in materials]
    for p in dict.fromkeys(particles):
        _r, refs = v06_effect.check_particle(root, p, report=rep)
        stats['particles'] += 1
        materials += [x for x in refs['materials'] if x not in materials]
        extra_files += refs['files']
    # V04 on materials -> textures
    for m in dict.fromkeys(materials):
        _r, texs = v04_material.check_material(root, m, report=rep)
        stats['materials'] += 1
        extra_files += texs
    # V01 / V02 / V05 on files
    for rel in dict.fromkeys(files + extra_files):
        p = root.path(rel)
        if not os.path.exists(p):
            rep.add('V03', ERROR, rel, 'touched file missing in the data root')
            continue
        ext = ext_of(rel)
        with open(p, 'rb') as f:
            data = f.read()
        if ext == '.mesh':
            v01_mesh.check(data, rel, report=rep)
            stats['meshes'] += 1
        elif ext == '.skeleton':
            v02_skeleton.check(data, rel, report=rep)
            stats['skeletons'] += 1
        elif ext in ('.dds',):
            v05_dds.check(data, rel, report=rep)
            stats['textures'] += 1
    # V13 on script edits, V06 whole-file strays
    for sc in touched.get('scripts', []):
        if base is None:
            rep.add('V13', ERROR, sc['file'], 'no base data root given')
            continue
        with open(root.path(sc['file']), 'rb') as f:
            edited = f.read()
        with open(base.path(sc['file']), 'rb') as f:
            original = f.read()
        v13_gbk.check(original, edited, sc['edits'], subject=sc['file'], report=rep)
        stats['scripts'] += 1
    for kind in ('material', 'effect', 'particle'):
        v06_effect.check_file(root, kind, base_root=base, report=rep)
    return rep, stats


def object_issues(data_root, names=None):
    """V03 on every object of all.obj (first occurrences) or on `names` -> {name: sorted [(level, message)]}
    (errors and warnings only). Used for the full-catalogue regression check (--all-objects)."""
    root = data_root if isinstance(data_root, DataRoot) else DataRoot(data_root)
    spans, first = root.objects()
    out = {}
    for nm in (names if names is not None else list(first)):
        rep = Report()
        try:
            v03_obj.check_object(root, nm, report=rep)
        except Exception as ex:                       # a broken file must not stop the sweep
            rep.add('V03', ERROR, nm, 'validator exception %s: %s' % (type(ex).__name__, ex))
        out[nm] = sorted({(r['level'], r['message']) for r in rep.items if r['level'] in (ERROR, WARN)})
    return out


def compare_catalogue(data_root, base_root, out_dir, skip=()):
    """Regression check: objects whose V03 errors in data_root are not already errors in base_root."""
    cur = object_issues(data_root)
    base = object_issues(base_root)
    skip = set(skip)
    reg, fixed = {}, {}
    for nm, items in cur.items():
        if nm in skip:
            continue
        e_cur = {m for lv, m in items if lv == ERROR}
        e_base = {m for lv, m in base.get(nm, []) if lv == ERROR}
        if e_cur - e_base:
            reg[disp(nm)] = sorted(e_cur - e_base)
        if e_base - e_cur:
            fixed[disp(nm)] = sorted(e_base - e_cur)
    res = {'objects_checked': len(cur), 'objects_in_base': len(base), 'skipped': len(skip),
           'objects_with_errors': sum(1 for v in cur.values() if any(lv == ERROR for lv, m in v)),
           'objects_with_errors_in_base': sum(1 for v in base.values() if any(lv == ERROR for lv, m in v)),
           'regressions': reg, 'fixed': fixed}
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, 'objects_all.json'), 'w', encoding='utf-8') as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    return res


def write_outputs(rep, stats, out_dir, header=''):
    os.makedirs(out_dir, exist_ok=True)
    js = rep.to_json()
    js['checked'] = stats
    with open(os.path.join(out_dir, 'validate.json'), 'w', encoding='utf-8') as f:
        json.dump(js, f, ensure_ascii=False, indent=1)
    with open(os.path.join(out_dir, 'validate.txt'), 'w', encoding='utf-8-sig', newline='\r\n') as f:
        if header:
            f.write(header.rstrip('\n') + '\n\n')
        f.write('checked: %s\n' % json.dumps(stats))
        f.write('errors %d, warnings %d\n\n' % (rep.count(ERROR), rep.count(WARN)))
        f.write(rep.text(max_info=100000) + '\n')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--data', required=True)
    ap.add_argument('--touched')
    ap.add_argument('--base')
    ap.add_argument('--out', default='.')
    ap.add_argument('--all-objects', action='store_true',
                    help='V03 on every all.obj object of --data and --base; report objects with new errors')
    ap.add_argument('--skip', help='--all-objects: JSON list or touched.json whose objects are skipped')
    a = ap.parse_args()
    if a.all_objects:
        if not a.base:
            ap.error('--all-objects needs --base')
        skip = []
        if a.skip:
            with open(a.skip, encoding='utf-8') as f:
                js = json.load(f)
            skip = [_name(x) for x in (js.get('objects', []) if isinstance(js, dict) else js)]
        res = compare_catalogue(a.data, a.base, a.out, skip)
        print('objects %d (base %d), with errors %d (base %d), regressions %d, fixed %d -> %s' % (
            res['objects_checked'], res['objects_in_base'], res['objects_with_errors'],
            res['objects_with_errors_in_base'], len(res['regressions']), len(res['fixed']),
            os.path.join(a.out, 'objects_all.json')))
        sys.exit(1 if res['regressions'] else 0)
    if not a.touched:
        ap.error('--touched is required (or --all-objects)')
    with open(a.touched, encoding='utf-8') as f:
        touched = json.load(f)
    rep, stats = run_all(a.data, touched, a.base)
    write_outputs(rep, stats, a.out)
    print('checked', stats, 'errors', rep.count(ERROR), 'warnings', rep.count(WARN))
    sys.exit(1 if rep.count(ERROR) else 0)


if __name__ == '__main__':
    main()
