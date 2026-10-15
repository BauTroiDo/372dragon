#!/usr/bin/env python3
# CY-Source sky-enscene: list the sky draws of a d3d9 trace frame (CysD3D9Trace events.jsonl) - the EnScene dome,
# cloud / ring cloud layers, sun / moon / flare and SkySphereLayer bands - with their shaders, named constants,
# textures, render states, pixel counts and position in the frame. Sky draws are recognised by shader constant names
# of EnScene.hlsl / SkySphereLayer.hlsl (both files are in MaterialTemplates.zip of CY 3.71).
# usage: sky_draws.py <frame dir> [--json out.json] [--all-consts]
#        sky_draws.py compare <cy frame dir> <proj frame dir>
import argparse
import json
import os
import sys

SKY_KEYS = {
    'EN_DOME_PARAM1': 'dome', 'EN_DOME_PARAM2': 'dome', 'SUN_POSITION': 'dome',
    'rimParam': 'cloud', 'windSpeed': 'cloud', 'textureTile': 'cloud', 'offsetParam': 'ring',
    'blendFactor': 'skysphere', 'blendColour': 'skysphere', 'texUWrap': 'skysphere',
    'intensity': 'flare?',
}
RS_KEYS = ('ZENABLE', 'ZWRITEENABLE', 'ZFUNC', 'ALPHABLENDENABLE', 'SRCBLEND', 'DESTBLEND', 'CULLMODE',
           'ALPHATESTENABLE', 'ALPHAREF', 'SEPARATEALPHABLENDENABLE', 'COLORWRITEENABLE')


def strip(name):
    return name[1:] if name.startswith('$') else name


def load_shaders(frame):
    out = {}
    for path in (os.path.join(frame, 'shaders.jsonl'), os.path.join(os.path.dirname(frame), 'shaders.jsonl')):
        if not os.path.exists(path):
            continue
        with open(path, encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line:
                    s = json.loads(line)
                    out.setdefault(s['hash'], s)
    return out


def load_textures(frame):
    out = {}
    path = os.path.join(frame, 'textures.jsonl')
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line:
                    t = json.loads(line)
                    out[t['id']] = t
    return out


def classify(draw, shaders):
    names = set()
    for key in ('vsc', 'psc'):
        for n in (draw.get(key) or {}):
            names.add(strip(n))
    for h in (draw.get('vs'), draw.get('ps')):
        s = shaders.get(h or '')
        if s:
            for c in s.get('consts', []):
                names.add(strip(c['name']))
    kinds = set(SKY_KEYS[n] for n in names if n in SKY_KEYS)
    if 'dome' in kinds:
        return 'dome'
    if 'ring' in kinds:
        return 'ringcloud'
    if 'cloud' in kinds:
        return 'cloud'
    if 'skysphere' in kinds:
        return 'skysphere'
    if 'ambientCol' in names and 'weight' in names:
        return 'dome'
    return None


def sky_draws(frame):
    shaders = load_shaders(frame)
    textures = load_textures(frame)
    draws = []
    total = 0
    pass_first = {}
    with open(os.path.join(frame, 'events.jsonl'), encoding='utf-8') as f:
        for line in f:
            if '"ev":"draw"' not in line:
                continue
            d = json.loads(line)
            total += 1
            pass_first.setdefault(d.get('pass'), d['n'])
            kind = classify(d, shaders)
            if not kind:
                continue
            consts = {}
            for key in ('vsc', 'psc'):
                for n, v in (d.get(key) or {}).items():
                    n = strip(n)
                    if n.endswith('matrix') or n.endswith('Matrix'):
                        continue
                    consts[key[:2] + ':' + n] = v
            tex = {}
            for s, ts in (d.get('tex') or {}).items():
                tid = ts.get('id') if isinstance(ts, dict) else ts
                t = textures.get(tid, {})
                addr = '%s/%s' % (ts.get('ADDRESSU'), ts.get('ADDRESSV')) if isinstance(ts, dict) else ''
                filt = '%s/%s/%s' % (ts.get('MINFILTER'), ts.get('MAGFILTER'), ts.get('MIPFILTER')) if isinstance(ts, dict) else ''
                tex[s] = '%s %sx%s %s lv%s hash %s addr %s filt %s' % (tid, t.get('w'), t.get('h'), t.get('fmt'),
                                                                     t.get('levels'), t.get('hash'), addr, filt)
            rs = d.get('rs') or {}
            draws.append({
                'n': d['n'], 'pass': d.get('pass'), 'kind': kind, 'vs': d.get('vs'), 'ps': d.get('ps'),
                'nv': d.get('nv'), 'pc': d.get('pc'), 'px': d.get('px'), 'rt': d.get('rt'),
                'rs': {k: rs.get(k) for k in RS_KEYS}, 'consts': consts, 'tex': tex, 'geom': d.get('geom'),
                'vsc_matrices': {strip(n): v for n, v in (d.get('vsc') or {}).items() if 'atrix' in n},
            })
    return {'frame': frame, 'draws_total': total, 'pass_first_draw': pass_first, 'sky': draws}


def fmt(v):
    if isinstance(v, list):
        return '(' + ', '.join('%.4g' % x for x in v) + ')'
    if isinstance(v, float):
        return '%.4g' % v
    return str(v)


def print_report(r, out=sys.stdout):
    out.write('frame %s: %d draws, sky draws %d\n' % (r['frame'], r['draws_total'], len(r['sky'])))
    for d in r['sky']:
        out.write('#%d pass %s %-9s vs %s ps %s nv %s pc %s px %s rs %s\n' % (
            d['n'], d['pass'], d['kind'], d['vs'], d['ps'], d['nv'], d['pc'], d['px'],
            ' '.join('%s=%s' % (k, v) for k, v in d['rs'].items())))
        for k in sorted(d['consts']):
            out.write('    %s = %s\n' % (k, fmt(d['consts'][k])))
        for s in sorted(d['tex']):
            out.write('    s%s: %s\n' % (s, d['tex'][s]))


def main():
    if len(sys.argv) > 1 and sys.argv[1] == 'compare':
        ap = argparse.ArgumentParser()
        ap.add_argument('cmd')
        ap.add_argument('cy')
        ap.add_argument('proj')
        a = ap.parse_args()
        rc, rp = sky_draws(a.cy), sky_draws(a.proj)
        for label, r in (('CY', rc), ('CY-Source', rp)):
            kinds = {}
            for d in r['sky']:
                kinds.setdefault(d['kind'], []).append(d)
            print('%s: %d sky draws of %d; ' % (label, len(r['sky']), r['draws_total']) + ', '.join(
                '%s %d (vs %s ps %s, px %d)' % (k, len(v), sorted(set(x['vs'] for x in v)), sorted(set(x['ps'] for x in v)),
                                             sum(x['px'] or 0 for x in v)) for k, v in sorted(kinds.items())))
            if r['sky']:
                print('   order in frame: first sky draw #%d, last #%d, pass first draws %s' % (
                    r['sky'][0]['n'], r['sky'][-1]['n'], r['pass_first_draw']))
        return
    ap = argparse.ArgumentParser()
    ap.add_argument('frame')
    ap.add_argument('--json')
    a = ap.parse_args()
    r = sky_draws(a.frame)
    print_report(r)
    if a.json:
        with open(a.json, 'w', encoding='utf-8') as f:
            json.dump(r, f, indent=1)


if __name__ == '__main__':
    main()
