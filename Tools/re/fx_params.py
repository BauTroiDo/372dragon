# -*- coding: utf-8 -*-
"""fx_params.py - parameter inventory of effect / particle / skill blocks (all.effect, all.particle, all.skill).

Read-only: client_GL/Data/EffectFolder (S1) and Tools/DATA NEW/DataCY31-08-26/Effect (S2, for curve/dissolveBox).
For every block type (element:X, emitter:X, affector:X, skill sub-block) and key: uses, coverage, numeric
component ranges, top categorical values; whether the type/key string exists in the 0.85 source tree and in
which B binary it appears (NUL-terminated string).
Outputs: Tools/re/out/fx_params.tsv, fx_types.tsv, fx_params.json
"""
import collections
import glob
import json
import os
import re

R = r'C:\TLBB\085'
S1 = R + r'\client_GL\Data\EffectFolder'
S2 = R + r'\Tools\DATA NEW\DataCY31-08-26\Effect'
SRC = R + r'\CY-Source\Src'
BIN = R + r'\client_GL\Bin64'
OUT = R + r'\CY-Source\Tools\re\out'
NEW = ['element:NewRibbonTrail', 'element:UIParticle', 'affector:RevoluMove', 'affector:SequenceFrame',
       'affector:Dissolve', 'affector:RotationCurve', 'affector:PolarMove', 'CameraShake', 'ComplexBlur',
       'emitter:Cylinder']
BINS = ['Render.dll', 'OgreMain.dll', 'Plugin_ParticleFX.dll', 'Plugin_ParticleFX2.dll']


def gbk(s):
    return s.encode('latin-1').decode('gbk', 'replace')


def pieces(text):
    for ln, raw in enumerate(text.split('\n'), 1):
        s = raw.strip()
        if not s or s.startswith('//'):
            continue
        for p in re.split(r'([{}])', s):
            p = p.strip()
            if p:
                yield ln, p


def parse(path, kind, acc, src):
    text = open(path, 'rb').read().decode('latin-1').replace('\r\n', '\n').replace('\r', '\n')
    P = list(pieces(text))
    stack = []
    cur = None
    i = 0
    n = len(P)
    while i < n:
        ln, p = P[i]
        if p == '{':
            stack.append(cur or ('?', {}))
            cur = None
            i += 1
            continue
        if p == '}':
            if stack:
                lab, keys = stack.pop()
                acc['blocks'][(src, kind, lab)] += 1
                for k in keys:
                    acc['cover'][(src, kind, lab, k)] += 1
            i += 1
            continue
        toks = p.split()
        if i + 1 < n and P[i + 1][1] == '{':
            if not stack:
                lab = {'effect': 'effect', 'skill': 'skill'}.get(kind, 'particle_system') if toks[0] in ('effect', 'skill') or kind == 'particle' else toks[0]
            elif toks[0] in ('element', 'emitter', 'affector') and len(toks) > 1:
                lab = toks[0] + ':' + toks[1]
            else:
                lab = toks[0]
            cur = (lab, set())
            i += 1
            continue
        lab, keys = stack[-1] if stack else ('top', set())
        key = toks[0]
        keys.add(key)
        vals = toks[1:]
        st = acc['stats'][(src, kind, lab, key)]
        st['n'] += 1
        if len(st['ex']) < 1:
            st['ex'].append('%s:%d' % (os.path.basename(path), ln))
        nums = []
        for v in vals:
            try:
                nums.append(float(v))
            except ValueError:
                nums = None
                break
        if nums is not None and nums:
            st['arity'][len(nums)] += 1
            for j, x in enumerate(nums[:16]):
                lo, hi = st['rng'].get(j, (x, x))
                st['rng'][j] = (min(lo, x), max(hi, x))
        else:
            st['cat'][gbk(' '.join(vals))[:60]] += 1
        i += 1


def src_literals():
    lit = set()
    for p in glob.glob(SRC + r'\**\*.*', recursive=True):
        if not re.search(r'\.(cpp|h|hpp|inl|c)$', p, re.I):
            continue
        if '\\ThirdParty\\' in p:
            continue
        try:
            t = open(p, 'rb').read().decode('latin-1')
        except OSError:
            continue
        lit.update(re.findall(r'"([A-Za-z0-9_ .]+)"', t))
    return lit


def main():
    acc = {'blocks': collections.Counter(), 'cover': collections.Counter(),
           'stats': collections.defaultdict(lambda: {'n': 0, 'arity': collections.Counter(), 'rng': {},
                                                     'cat': collections.Counter(), 'ex': []})}
    for src, root in (('S1', S1), ('S2', S2)):
        for kind in ('effect', 'particle', 'skill'):
            p = os.path.join(root, 'all.' + kind)
            if os.path.exists(p):
                parse(p, kind, acc, src)
    lit = src_literals()
    bins = {b: open(os.path.join(BIN, b), 'rb').read() for b in BINS}

    def inb(s):
        k = b'\x00' + s.encode('latin-1') + b'\x00'
        return ','.join(b for b, d in bins.items() if k in d) or '-'
    with open(OUT + r'\fx_types.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('kind\tblock_type\tS1_blocks\tS2_blocks\tnew_vs_0.85\ttype_literal_in_0.85_src\ttype_string_in_B_bin\n')
        labs = sorted(set((k, l) for (_, k, l) in acc['blocks']))
        for kind, lab in labs:
            t = lab.split(':', 1)[-1]
            f.write('%s\t%s\t%d\t%d\t%s\t%s\t%s\n' % (kind, lab, acc['blocks'].get(('S1', kind, lab), 0),
                                                      acc['blocks'].get(('S2', kind, lab), 0),
                                                      'NEW' if lab in NEW else '', 'Y' if t in lit else 'N', inb(t)))
    js = {}
    with open(OUT + r'\fx_params.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('src\tkind\tblock_type\tkey\tuses\tblocks_with_key/blocks\tarity\tnumeric_ranges(comp:min..max)\t'
                'top_values\tkey_literal_in_0.85_src\tkey_string_in_B_bin\texample\n')
        for (src, kind, lab, key), st in sorted(acc['stats'].items()):
            if lab not in NEW and not (lab.startswith('particle_system') and key in ('renderer',)) and not (src == 'S2' and key in ('curve', 'dissolveBox')):
                if lab not in NEW:
                    continue
            nb = acc['blocks'].get((src, kind, lab), 0)
            cov = acc['cover'].get((src, kind, lab, key), 0)
            rng = ' '.join('%d:%g..%g' % (j, lo, hi) for j, (lo, hi) in sorted(st['rng'].items()))
            cat = '; '.join('%s=%d' % (v, c) for v, c in st['cat'].most_common(8))
            ar = ','.join('%d' % a for a in sorted(st['arity']))
            row = [src, kind, lab, key, str(st['n']), '%d/%d' % (cov, nb), ar, rng, cat,
                   'Y' if key in lit else 'N', inb(key), st['ex'][0] if st['ex'] else '']
            f.write('\t'.join(row) + '\n')
            js.setdefault(lab, {})['%s/%s' % (src, key)] = {'uses': st['n'], 'cov': '%d/%d' % (cov, nb), 'rng': rng, 'cat': cat}
    # special keys anywhere (S1 and S2)
    special = {}
    for (src, kind, lab, key), st in acc['stats'].items():
        if key in ('curve', 'dissolveBox', 'dissolve_box') or (lab == 'emitter:Cylinder'):
            special['%s|%s|%s' % (src, lab, key)] = {'uses': st['n'], 'rng': ' '.join('%d:%g..%g' % (j, lo, hi) for j, (lo, hi) in sorted(st['rng'].items())), 'cat': dict(st['cat'].most_common(5)), 'ex': st['ex']}
    js['_special'] = special
    json.dump(js, open(OUT + r'\fx_params.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(open(OUT + r'\fx_types.tsv', encoding='utf-8').read())
    print(json.dumps(special, ensure_ascii=False, indent=1)[:3000])


if __name__ == '__main__':
    main()
