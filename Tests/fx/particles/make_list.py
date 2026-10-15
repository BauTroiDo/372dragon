# -*- coding: utf-8 -*-
"""make_list.py - render list for the fx-particles before/after comparison (read-only on the data).

Picks particle templates of Canonical all.particle that exercise the behaviour changed by the fx-particles work
(client_GL parity, Docs/specs/render/07b-particles_vi.md) and appends effects of the fx-audit frontend list
(creation scene, sect weapons). Output: Tests/fx/particles/lists/particles.tsv in the fx_sheet.py format
  id<TAB>particle|effect<TAB>name
Usage: py -3 make_list.py [--per 3] [--data <all.particle>] [--frontend <tsv>] [--out <tsv>]
"""
import argparse
import collections
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
DATA = os.path.join(ROOT, r'Assets\Canonical\Data\EffectFolder\all.particle')
FRONTEND = os.path.join(ROOT, r'Tests\fx\audit\lists\frontend.tsv')
OUT = os.path.join(HERE, 'lists', 'particles.tsv')


def templates(path):
    """yield (name_bytes, sys_attrs{key:val}, blocks[(kind, type, {key:val})]) - raw latin-1 text"""
    raw = open(path, 'rb').read().decode('latin-1').replace('\r\n', '\n').split('\n')
    depth = 0
    name = None
    sysattrs = {}
    blocks = []
    cur = None
    pending = None
    for s in raw:
        s = s.strip()
        if not s or s.startswith('//'):
            continue
        if s == '{':
            depth += 1
            if depth == 2:
                cur = (pending[0], pending[1], {})
                pending = None
            continue
        if s == '}':
            if depth == 2 and cur:
                blocks.append(cur)
                cur = None
            elif depth == 1 and name is not None:
                yield name, sysattrs, blocks
                name, sysattrs, blocks = None, {}, []
            depth = max(0, depth - 1)
            continue
        if depth == 0:
            name = s
            continue
        parts = s.split(None, 1)
        k = parts[0]
        v = parts[1] if len(parts) > 1 else ''
        if depth == 1:
            if k in ('emitter', 'affector'):
                pending = (k, v.split()[0] if v else '?')
            else:
                sysattrs[k] = v
        elif depth == 2 and cur is not None:
            cur[2][k.lower()] = v


def features(sysattrs, blocks):
    f = set()
    rend = sysattrs.get('renderer', 'billboard')
    if 'local_space' not in sysattrs:
        f.add('local_space_default')
    for kind, typ, keys in blocks:
        if kind == 'affector' and typ == 'ColourFading':
            if 'time0' not in keys:
                f.add('colourfading_no_time0')
            if any(k.startswith('opacity') and k != 'opacity' for k in keys):
                f.add('colourfading_opacityN')
        if kind == 'affector' and typ == 'ScaleInterpolator':
            if 'use_interpolated_scale' not in keys and any(k.startswith('scale') for k in keys):
                f.add('scale_default_interpolated')
            if keys.get('use_interpolated_increment') == 'true':
                f.add('scale_increment')
        if kind == 'affector' and typ == 'Movement' and 'use_start_velocity' not in keys:
            f.add('movement_default_start_velocity')
        if kind == 'affector' and typ == 'Revolution':
            f.add('revolution')
        if kind == 'affector' and typ == 'Rotator':
            if sysattrs.get('billboard_rotation_type') is None and rend in ('billboard', 'texcoord_billboard'):
                f.add('rotator_vertex_default')
        if kind == 'emitter' and typ == 'Ellipsoid' and any(k in keys for k in ('inner_width', 'angle_range', 'height_range')):
            f.add('ellipsoid_b_keys')
        if kind == 'emitter' and typ == 'Ring' and keys.get('inner_width', '').strip() in ('0', '0.0'):
            f.add('ring_inner0')
        if kind == 'emitter' and typ == 'PolarEmitter' and 'use_polar_step' not in keys:
            f.add('polar_step_default')
        if kind == 'emitter' and typ in ('Box', 'Cylinder', 'Ellipsoid', 'HollowEllipsoid', 'Ring') and 'direction' not in keys:
            f.add('area_default_direction')
        if kind == 'emitter' and not any(k.startswith('time_to_live') for k in keys):
            f.add('emitter_default_ttl')
    if rend == 'mesh':
        if sysattrs.get('orientation_type') in ('oriented_camera', 'oriented_common', 'perpendicular_common',
                                                'perpendicular_self', 'oriented_self'):
            f.add('mesh_orientation')
        if 'local_rotation' in sysattrs or 'local_position' in sysattrs:
            f.add('mesh_local_transform')
        if 'particle_depth' not in sysattrs:
            f.add('mesh_depth_default')
    if rend == 'texcoord_billboard' and 'stacks' in sysattrs:
        f.add('texcoord_flipbook')
    return f


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--data', default=DATA)
    ap.add_argument('--frontend', default=FRONTEND)
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--per', type=int, default=3, help='templates per feature')
    a = ap.parse_args()

    chosen = collections.OrderedDict()   # name -> set(features)
    per = collections.Counter()
    order = ['colourfading_no_time0', 'colourfading_opacityN', 'scale_default_interpolated', 'scale_increment',
             'movement_default_start_velocity', 'revolution', 'rotator_vertex_default', 'ellipsoid_b_keys',
             'ring_inner0', 'polar_step_default', 'area_default_direction', 'emitter_default_ttl', 'mesh_orientation',
             'mesh_local_transform', 'mesh_depth_default', 'texcoord_flipbook', 'local_space_default']
    for name, sysattrs, blocks in templates(a.data):
        f = features(sysattrs, blocks)
        for feat in order:
            if feat in f and per[feat] < a.per and name not in chosen:
                chosen[name] = f
                per[feat] += 1
                break
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    rows = []
    for i, (name, f) in enumerate(chosen.items()):
        rows.append(('Q%03d' % (i + 1), 'particle', name, ','.join(sorted(f))))
    # creation scene + sect weapon effects of the fx-audit frontend list
    if os.path.exists(a.frontend):
        with open(a.frontend, 'rb') as fh:
            for ln in fh.read().split(b'\n')[1:]:
                cols = ln.rstrip(b'\r').split(b'\t')
                if len(cols) >= 3 and cols[1] in (b'effect', b'particle'):
                    rows.append(('F' + cols[0].decode('latin-1'), cols[1].decode(), cols[2].decode('latin-1'), 'frontend'))
    with open(a.out, 'wb') as out:
        out.write(b'id\tkind\tname\tfeatures\n')
        for r in rows:
            out.write(('%s\t%s\t%s\t%s\n' % r).encode('latin-1'))
    print('templates by feature:', dict(per))
    print('rows:', len(rows), '->', a.out)


if __name__ == '__main__':
    main()
