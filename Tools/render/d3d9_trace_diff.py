# CY-Source Tools/render/d3d9_trace_diff.py - compare two frames captured by the d3d9 trace proxy
# (Src/Tools/CysD3D9Trace) draw for draw: CY 3.71 (reference) against CY-Source.
#
#   python d3d9_trace_diff.py summary CAPDIR
#   python d3d9_trace_diff.py sheet CAPDIR OUT.png            (contact sheet of rt/*.png)
#   python d3d9_trace_diff.py diff CYCAP PROJCAP --out DIR [--top 30]
#
# A capture dir is <trace dir>\f<frame>_<label> (events.jsonl, textures.jsonl, shaders.jsonl); shader .asm files are in
# <trace dir>\shaders. The diff:
#   1. classifies every pass by role (shadow / depth / scene / post / final) from its render target and draw count;
#   2. pairs draws of the same role in tiers: (geometry hash, texture set) -> geometry -> (index hash, texture set) ->
#      (texture set, primitive count) -> shader pair frequency; every tier pairs in submission order;
#   3. compares each pair on the EFFECTIVE state only (blend states only while blending, fog only while fog is on, fixed
#      function stages only without shaders), samplers of the textures both sides sample, shader hashes, shader constants
#      by name, texture format/mips, viewport;
#   4. aggregates every difference into a key and ranks keys by the screen area of the draws concerned (occlusion query
#      pixels / render-target area, overdraw counts again); unmatched draws, passes and render targets are structural
#      differences ranked the same way; render-queue order is compared by rank correlation per shader.
# Output: DIR\diff.txt (ranked list), diff.json, pairs.tsv, unmatched.tsv, shaderdiff\*.diff (unified asm diffs).
import argparse
import collections
import difflib
import json
import math
import os
import sys

FIXED_FUNCTION_RS = {'LIGHTING', 'AMBIENT', 'COLORVERTEX', 'LOCALVIEWER', 'NORMALIZENORMALS', 'DIFFUSEMATERIALSOURCE',
                     'AMBIENTMATERIALSOURCE', 'VERTEXBLEND', 'INDEXEDVERTEXBLENDENABLE', 'SPECULARENABLE', 'FOGVERTEXMODE',
                     'RANGEFOGENABLE', 'TEXTUREFACTOR', 'SHADEMODE', 'POINTSIZE', 'POINTSPRITEENABLE'}
IGNORED_RS = {'LASTPIXEL', 'DITHERENABLE', 'CLIPPING', 'MULTISAMPLEANTIALIAS', 'MULTISAMPLEMASK', 'ANTIALIASEDLINEENABLE',
              'WRAP0', 'CLIPPLANEENABLE', 'COLORWRITEENABLE1', 'COLORWRITEENABLE2', 'COLORWRITEENABLE3', 'BLENDFACTOR'}
RS_NAMES = {
    'SRCBLEND': {1: 'ZERO', 2: 'ONE', 3: 'SRCCOLOR', 4: 'INVSRCCOLOR', 5: 'SRCALPHA', 6: 'INVSRCALPHA', 7: 'DESTALPHA',
                 8: 'INVDESTALPHA', 9: 'DESTCOLOR', 10: 'INVDESTCOLOR', 11: 'SRCALPHASAT'},
    'CULLMODE': {1: 'NONE', 2: 'CW', 3: 'CCW'},
    'ZFUNC': {1: 'NEVER', 2: 'LESS', 3: 'EQUAL', 4: 'LESSEQUAL', 5: 'GREATER', 6: 'NOTEQUAL', 7: 'GREATEREQUAL', 8: 'ALWAYS'},
    'FOGTABLEMODE': {0: 'NONE', 1: 'EXP', 2: 'EXP2', 3: 'LINEAR'},
    'BLENDOP': {1: 'ADD', 2: 'SUBTRACT', 3: 'REVSUBTRACT', 4: 'MIN', 5: 'MAX'},
}
RS_NAMES['DESTBLEND'] = RS_NAMES['SRCBLEND']
RS_NAMES['SRCBLENDALPHA'] = RS_NAMES['SRCBLEND']
RS_NAMES['DESTBLENDALPHA'] = RS_NAMES['SRCBLEND']
RS_NAMES['ALPHAFUNC'] = RS_NAMES['ZFUNC']
RS_NAMES['BLENDOPALPHA'] = RS_NAMES['BLENDOP']
FILTER = {0: 'NONE', 1: 'POINT', 2: 'LINEAR', 3: 'ANISOTROPIC'}
ADDRESS = {1: 'WRAP', 2: 'MIRROR', 3: 'CLAMP', 4: 'BORDER', 5: 'MIRRORONCE'}
SAMP_NAMES = {'MAGFILTER': FILTER, 'MINFILTER': FILTER, 'MIPFILTER': FILTER, 'ADDRESSU': ADDRESS, 'ADDRESSV': ADDRESS,
              'ADDRESSW': ADDRESS}
SAMPLER_KEYS = ['ADDRESSU', 'ADDRESSV', 'MAGFILTER', 'MINFILTER', 'MIPFILTER', 'MIPMAPLODBIAS', 'MAXMIPLEVEL',
                'MAXANISOTROPY', 'SRGBTEXTURE']


def vname(key, v, table=RS_NAMES):
    t = table.get(key)
    if t and isinstance(v, int) and v in t:
        return '%s(%d)' % (t[v], v)
    return str(v)


class Capture:
    def __init__(self, path):
        self.path = os.path.abspath(path)
        self.name = os.path.basename(self.path.rstrip('\\/'))
        self.events = [json.loads(l) for l in open(os.path.join(self.path, 'events.jsonl'), encoding='utf-8') if l.strip()]
        self.textures = {}
        for l in open(os.path.join(self.path, 'textures.jsonl'), encoding='utf-8'):
            if l.strip():
                j = json.loads(l)
                self.textures[j['id']] = j
        self.shaders = {}
        for l in open(os.path.join(self.path, 'shaders.jsonl'), encoding='utf-8'):
            if l.strip():
                j = json.loads(l)
                self.shaders[(j['kind'], j['hash'])] = j
        cj = os.path.join(self.path, 'capture.json')
        self.info = json.load(open(cj, encoding='utf-8')) if os.path.exists(cj) else {}
        self.trace_dir = os.path.dirname(self.path)
        self.device = ''
        log = os.path.join(self.trace_dir, 'trace.log')
        if os.path.exists(log):
            for l in open(log, encoding='utf-8', errors='replace'):
                if 'CreateDevice' in l:
                    self.device = l.strip().split(' ', 1)[1]
        self.draws = [e for e in self.events if e['ev'] == 'draw']
        self.passes = self._passes()
        for d in self.draws:
            p = self.passes[d['pass']]
            d['role'] = p['role']
            rt = self.textures.get(p['rt'], {})
            area = max(1, rt.get('w', 1) * rt.get('h', 1))
            vp = d.get('vp') or [0, 0, 0, 0]
            if vp[2] and vp[3]:
                area = min(area, vp[2] * vp[3])
            d['area'] = d.get('px', 0) / float(area)
            d['texset'] = tuple(sorted(t['id'] for t in d['tex'].values() if t['id'].startswith('t')))
            d['rtsamp'] = tuple(sorted(self.textures.get(t['id'], {}).get('fmt', t['id'])
                                       for t in d['tex'].values() if t['id'].startswith('rt') or t['id'] == 'bb'))

    def _passes(self):
        passes = collections.OrderedDict()
        cur = None
        for e in self.events:
            if e['ev'] == 'setrt' and e.get('idx', 0) == 0:
                cur = e['pass']
                passes.setdefault(cur, {'pass': cur, 'rt': e['rt'], 'draws': 0, 'px': 0, 'clears': [], 'ds': None})
            if e['ev'] in ('draw', 'clear', 'setds', 'stretchrect'):
                p = passes.setdefault(e['pass'], {'pass': e['pass'], 'rt': (e.get('rt') or ['?'])[0] if e['ev'] == 'draw' else e.get('rt', '?'),
                                                  'draws': 0, 'px': 0, 'clears': [], 'ds': None})
                if e['ev'] == 'draw':
                    p['draws'] += 1
                    p['px'] += e.get('px', 0)
                elif e['ev'] == 'clear':
                    p['clears'].append('flags=%d color=%s vp=%s' % (e['flags'], e['color'], e['vp']))
                elif e['ev'] == 'setds':
                    p['ds'] = e['ds']
        bb = self.textures.get('bb', {})
        for p in passes.values():
            rt = self.textures.get(p['rt'], {})
            fmt = rt.get('fmt', '')
            same = rt.get('w') == bb.get('w') and rt.get('h') == bb.get('h')
            if p['rt'] == 'bb':
                role = 'final'
            elif fmt in ('R32F', 'R16F') and not same:
                role = 'shadow'
            elif fmt in ('R32F', 'R16F'):
                role = 'depth'
            elif p['draws'] <= 2:
                role = 'post'
            else:
                role = 'scene'
            p['role'] = role
            p['rtdesc'] = '%s %sx%s %s' % (p['rt'], rt.get('w'), rt.get('h'), fmt)
        return passes

    def asm(self, kind, h):
        f = os.path.join(self.trace_dir, 'shaders', '%s.%s.asm' % (h, kind))
        if os.path.exists(f):
            return open(f, encoding='latin-1').read().splitlines()
        return []


def effective_rs(d, other=None):
    rs = d['rs']
    out = {}
    # fixed-function states only count when neither side uses shaders (a shader/FF mismatch is reported as a shader diff)
    shader = d['vs'] is not None or d['ps'] is not None or (other is not None and (other['vs'] is not None or other['ps'] is not None))
    for k, v in rs.items():
        if k in IGNORED_RS:
            continue
        if shader and k in FIXED_FUNCTION_RS:
            continue
        if k in ('SRCBLEND', 'DESTBLEND', 'BLENDOP', 'SEPARATEALPHABLENDENABLE') and not rs.get('ALPHABLENDENABLE'):
            continue
        if k in ('SRCBLENDALPHA', 'DESTBLENDALPHA', 'BLENDOPALPHA') and not (rs.get('ALPHABLENDENABLE') and rs.get('SEPARATEALPHABLENDENABLE')):
            continue
        if k in ('ALPHAREF', 'ALPHAFUNC') and not rs.get('ALPHATESTENABLE'):
            continue
        if k in ('ZFUNC', 'ZWRITEENABLE') and not rs.get('ZENABLE'):
            continue
        if k.startswith('STENCIL') or k in ('TWOSIDEDSTENCILMODE', 'CCW_STENCILFUNC'):
            if not rs.get('STENCILENABLE'):
                continue
        if k in ('FOGCOLOR', 'FOGTABLEMODE', 'FOGSTART', 'FOGEND', 'FOGDENSITY') and not rs.get('FOGENABLE'):
            continue
        if k in ('FOGENABLE', 'FOGCOLOR', 'FOGTABLEMODE', 'FOGSTART', 'FOGEND', 'FOGDENSITY') and d['ps'] is not None:
            # D3D9 fixed fog does not apply to ps_3_0 and is computed by the shader otherwise - keep only as info
            continue
        out[k] = v
    return out


def translation(d):
    """World translation of a draw from its VS constants (world_matrix / worldMatrix / world...), None if absent."""
    if '_tr' in d:
        return d['_tr']
    tr = None
    for name, v in (d.get('vsc') or {}).items():
        low = name.lower()
        if 'world' in low and 'view' not in low and 'shadow' not in low:
            head = v.get('head') if isinstance(v, dict) else v
            if isinstance(head, list) and len(head) >= 12 and all(isinstance(x, (int, float)) for x in head[:12]):
                tr = (head[3], head[7], head[11])
                break
    d['_tr'] = tr
    return tr


def pair_draws(a, b):
    """Returns list of (da, db, tier) and leftovers per side."""
    pairs = []
    left_a = list(a.draws)
    left_b = list(b.draws)
    tiers = [
        ('geom+tex', lambda d: (d['role'], d['geom'], d['texset'], d['rtsamp']) if d['geom'] else None),
        ('geom', lambda d: (d['role'], d['geom']) if d['geom'] else None),
        ('ib+tex', lambda d: (d['role'], (d.get('ib') or {}).get('hash'), d['texset'], d['pc']) if (d.get('ib') or {}).get('hash') else None),
        ('tex+pc', lambda d: (d['role'], d['texset'], d['pc'], d['nv']) if d['texset'] else None),
        ('tex', lambda d: (d['role'], d['texset'], d['rtsamp']) if d['texset'] else None),
        ('fullscreen', lambda d: (d['role'], d['pc'], d['rtsamp']) if d['role'] in ('post', 'final') and d['pc'] <= 2 else None),
    ]
    for name, keyf in tiers:
        ga = collections.OrderedDict()
        for d in left_a:
            k = keyf(d)
            if k is not None:
                ga.setdefault(k, []).append(d)
        used_a, used_b = set(), set()
        for d in left_b:
            k = keyf(d)
            if k is None or not ga.get(k):
                continue
            # instances of one mesh: take the CY draw with the nearest world translation, else submission order
            cand = ga[k]
            tb = translation(d)
            best = 0
            if tb is not None and len(cand) > 1:
                dist = [sum((p - q) ** 2 for p, q in zip(translation(c), tb)) if translation(c) is not None else 1e30 for c in cand]
                best = min(range(len(cand)), key=lambda i: dist[i])
            m = cand.pop(best)
            pairs.append((m, d, name))
            used_a.add(id(m))
            used_b.add(id(d))
        left_a = [d for d in left_a if id(d) not in used_a]
        left_b = [d for d in left_b if id(d) not in used_b]
    return pairs, left_a, left_b


def fnum(v):
    if isinstance(v, str):
        return float('nan')
    return float(v)


def close(x, y, tol=2e-3):
    if isinstance(x, dict) or isinstance(y, dict):
        return (x.get('hash') if isinstance(x, dict) else None) == (y.get('hash') if isinstance(y, dict) else None)
    if len(x) != len(y):
        return False
    for p, q in zip(x, y):
        p, q = fnum(p), fnum(q)
        if math.isnan(p) and math.isnan(q):
            continue
        if not abs(p - q) <= tol * max(1.0, abs(p), abs(q)):
            return False
    return True


def first_diff(x, y):
    hx = x.get('head', []) if isinstance(x, dict) else x
    hy = y.get('head', []) if isinstance(y, dict) else y
    for i, (p, q) in enumerate(zip(hx, hy)):
        if not close([p], [q]):
            return i
    return min(len(hx), len(hy))


def short(v, n=8, start=0):
    if isinstance(v, dict):
        return 'n=%s hash=%s head=%s' % (v.get('n'), v.get('hash', '')[:8], short(v.get('head', []), n, start))
    if start:
        v = v[start:]
        return '@%d[' % start + ','.join(('%.4g' % x) if isinstance(x, (int, float)) else str(x) for x in v[:n]) + (',..' if len(v) > n else '') + ']'

    s = ','.join(('%.4g' % x) if isinstance(x, (int, float)) else str(x) for x in v[:n])
    return '[' + s + (',..' if len(v) > n else '') + ']'


def compare_pair(a, b, da, db, add):
    w = max(da['area'], db['area'])
    role = da['role']
    ra, rb = effective_rs(da, db), effective_rs(db, da)
    for k in sorted(set(ra) | set(rb)):
        va, vb = ra.get(k, '-'), rb.get(k, '-')
        if va != vb:
            add('state', '%s rs %s: CY=%s proj=%s' % (role, k, vname(k, va), vname(k, vb)), w, da, db)
    # samplers of textures sampled on both sides (by texture id), then render-target samplers by stage
    sa = {t['id']: (s, t) for s, t in da['tex'].items() if t['id'].startswith('t')}
    sb = {t['id']: (s, t) for s, t in db['tex'].items() if t['id'].startswith('t')}
    for tid in sorted(set(sa) & set(sb)):
        ta, tb = sa[tid][1], sb[tid][1]
        for k in SAMPLER_KEYS:
            va, vb = ta.get(k), tb.get(k)
            if k == 'MAXANISOTROPY' and ta.get('MINFILTER') != 3 and tb.get('MINFILTER') != 3:
                continue
            if va != vb:
                tx = a.textures.get(tid, {})
                add('sampler', '%s sampler %s: CY=%s proj=%s' % (role, k, vname(k, va, SAMP_NAMES), vname(k, vb, SAMP_NAMES)), w, da, db,
                    detail='tex %s %sx%s %s' % (tid, tx.get('w'), tx.get('h'), tx.get('fmt')))
    for tid in sorted(set(sa) ^ set(sb)):
        side = 'CY' if tid in sa else 'proj'
        tx = (a if tid in sa else b).textures.get(tid, {})
        add('texture', '%s texture only in %s: %sx%s %s levels=%s' % (role, side, tx.get('w'), tx.get('h'), tx.get('fmt'), tx.get('levels')),
            w, da, db, detail=tid)
    for tid in sorted(set(sa) & set(sb)):
        xa, xb = a.textures.get(tid, {}), b.textures.get(tid, {})
        if xa.get('levels') != xb.get('levels'):
            add('texture', '%s texture mip levels: CY=%s proj=%s (%sx%s %s)' % (role, xa.get('levels'), xb.get('levels'), xa.get('w'), xa.get('h'), xa.get('fmt')),
                w, da, db, detail=tid)
    ra_s = [(s, t) for s, t in sorted(da['tex'].items()) if not t['id'].startswith('t') and t['id'] != 'null']
    rb_s = [(s, t) for s, t in sorted(db['tex'].items()) if not t['id'].startswith('t') and t['id'] != 'null']
    fa = sorted(a.textures.get(t['id'], {}).get('fmt', '?') for s, t in ra_s)
    fb = sorted(b.textures.get(t['id'], {}).get('fmt', '?') for s, t in rb_s)
    if fa != fb:
        add('texture', '%s render-target inputs: CY=%s proj=%s' % (role, fa, fb), w, da, db)
    # shaders
    for kind in ('vs', 'ps'):
        ha, hb = da[kind], db[kind]
        if ha != hb:
            add('shader', '%s %s differs' % (role, kind), w, da, db, detail='%s->%s' % (ha, hb), shader=(kind, ha, hb))
        ca, cb = da.get(kind + 'c', {}), db.get(kind + 'c', {})
        for name in sorted(set(ca) & set(cb)):
            if not close(ca[name], cb[name]):
                i = first_diff(ca[name], cb[name])
                i = (i // 4) * 4
                add('const', '%s %s const %s differs' % (role, kind, name), w, da, db,
                    detail='CY=%s proj=%s' % (short(ca[name], 8, i), short(cb[name], 8, i)))
        if ha != hb:
            only_a = sorted(set(ca) - set(cb))
            only_b = sorted(set(cb) - set(ca))
            if only_a:
                add('const', '%s %s consts only in CY: %s' % (role, kind, ','.join(only_a[:12])), w, da, db)
            if only_b:
                add('const', '%s %s consts only in proj: %s' % (role, kind, ','.join(only_b[:12])), w, da, db)
    if da['decl'] != db['decl']:
        add('vertex', '%s vertex layout differs' % role, w, da, db, detail='CY=%s | proj=%s' % (da['decl'], db['decl']))
    if (da['vp'][2], da['vp'][3]) != (db['vp'][2], db['vp'][3]):
        add('target', '%s viewport size CY=%sx%s proj=%sx%s' % (role, da['vp'][2], da['vp'][3], db['vp'][2], db['vp'][3]), w, da, db)
    fa_rt = a.textures.get((da['rt'] or ['?'])[0], {}).get('fmt')
    fb_rt = b.textures.get((db['rt'] or ['?'])[0], {}).get('fmt')
    if fa_rt != fb_rt:
        add('target', '%s render target format CY=%s proj=%s' % (role, fa_rt, fb_rt), w, da, db)


def spearman(xs, ys):
    n = len(xs)
    if n < 3:
        return 1.0

    def ranks(v):
        order = sorted(range(n), key=lambda i: v[i])
        r = [0] * n
        for k, i in enumerate(order):
            r[i] = k
        return r
    rx, ry = ranks(xs), ranks(ys)
    d2 = sum((p - q) ** 2 for p, q in zip(rx, ry))
    return 1 - 6.0 * d2 / (n * (n * n - 1))


def cmd_summary(args):
    c = Capture(args.cap)
    print('capture', c.path, c.info)
    print('device', c.device)
    for p in c.passes.values():
        print('pass %2d %-6s %-32s ds=%-20s draws=%5d px=%9d clears=%s' % (p['pass'], p['role'], p['rtdesc'], p['ds'], p['draws'], p['px'], p['clears']))
    for e in c.events:
        if e['ev'] in ('stretchrect', 'readback', 'colorfill', 'updatetexture'):
            print('  ', e)
    ps = collections.Counter((d['role'], d['ps']) for d in c.draws)
    for (role, h), n in ps.most_common(20):
        s = c.shaders.get(('ps', h), {})
        print('  %-6s ps %s draws=%4d consts=%s' % (role, h, n, ','.join(x['name'] for x in s.get('consts', [])[:10])))


def cmd_sheet(args):
    from PIL import Image, ImageDraw
    files = sorted(f for f in os.listdir(os.path.join(args.cap, 'rt')) if f.endswith('.png'))
    thumbs = []
    width = args.width
    for f in files:
        im = Image.open(os.path.join(args.cap, 'rt', f)).convert('RGB')
        thumbs.append((f, im.resize((width, max(1, int(im.height * width / im.width))))))
    h = max(t.height for _, t in thumbs)
    cols = min(len(thumbs), args.cols)
    rows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new('RGB', (width * cols, (h + 14) * rows))
    dr = ImageDraw.Draw(sheet)
    for i, (f, t) in enumerate(thumbs):
        x, y = (i % cols) * width, (i // cols) * (h + 14)
        sheet.paste(t, (x, y + 14))
        dr.text((x + 2, y + 1), f, fill=(255, 255, 0))
    sheet.save(args.out)
    print('sheet', args.out, sheet.size)


def cmd_diff(args):
    a, b = Capture(args.cy), Capture(args.proj)
    os.makedirs(args.out, exist_ok=True)
    agg = collections.OrderedDict()

    def add(cat, key, w, da, db, detail=None, shader=None):
        e = agg.get(key)
        if e is None:
            e = agg[key] = {'cat': cat, 'key': key, 'draws': 0, 'area': 0.0, 'examples': [], 'details': collections.Counter(), 'shaders': collections.Counter()}
        e['draws'] += 1
        e['area'] += w
        if len(e['examples']) < 4:
            e['examples'].append('CY#%s/proj#%s' % (da['n'] if da else '-', db['n'] if db else '-'))
        if detail:
            e['details'][detail] += 1
        if shader:
            e['shaders'][shader] += 1

    # structural: device, passes
    lines = []
    lines.append('CY   : %s  %s' % (a.path, a.info))
    lines.append('proj : %s  %s' % (b.path, b.info))
    lines.append('CY   device: %s' % a.device)
    lines.append('proj device: %s' % b.device)
    for tag, c in (('CY', a), ('proj', b)):
        lines.append('%s passes:' % tag)
        for p in c.passes.values():
            lines.append('  pass %2d %-6s %-34s ds=%-20s draws=%5d px=%9d clears=%s' % (p['pass'], p['role'], p['rtdesc'], p['ds'], p['draws'], p['px'], p['clears']))
        for e in c.events:
            if e['ev'] in ('stretchrect', 'readback', 'colorfill'):
                lines.append('  %s' % json.dumps(e))
    roles_a = collections.defaultdict(list)
    roles_b = collections.defaultdict(list)
    for p in a.passes.values():
        roles_a[p['role']].append(p)
    for p in b.passes.values():
        roles_b[p['role']].append(p)
    for role in ('shadow', 'depth', 'scene', 'post', 'final'):
        pa, pb = roles_a.get(role, []), roles_b.get(role, [])
        fa = sorted(set(a.passes[p['pass']]['rtdesc'].split(' ', 1)[1] for p in pa))
        fb = sorted(set(b.passes[p['pass']]['rtdesc'].split(' ', 1)[1] for p in pb))
        if len(pa) != len(pb) or fa != fb:
            key = 'pass %s: CY %d pass(es) %s, proj %d pass(es) %s' % (role, len(pa), fa, len(pb), fb)
            area = max(sum(p['px'] for p in pa), sum(p['px'] for p in pb)) / (1280.0 * 720.0)
            agg[key] = {'cat': 'pass', 'key': key, 'draws': sum(p['draws'] for p in pa) + sum(p['draws'] for p in pb), 'area': area,
                        'examples': [], 'details': collections.Counter(), 'shaders': collections.Counter()}
    if a.device and b.device:
        def field(s, name):
            i = s.find(name + ' ')
            return s[i + len(name) + 1:].split(' ')[0] if i >= 0 else '?'
        for name in ('interval', 'count', 'msaa', 'backbuffer', 'fmt', 'swap'):
            if field(a.device, name) != field(b.device, name):
                key = 'device %s: CY=%s proj=%s' % (name, field(a.device, name), field(b.device, name))
                agg[key] = {'cat': 'device', 'key': key, 'draws': 0, 'area': 1.0, 'examples': [], 'details': collections.Counter(), 'shaders': collections.Counter()}

    pairs, left_a, left_b = pair_draws(a, b)
    for da, db, tier in pairs:
        compare_pair(a, b, da, db, add)
    for side, left, c in (('CY', left_a, a), ('proj', left_b, b)):
        for d in left:
            tx = ' '.join('%sx%s:%s' % (c.textures.get(t, {}).get('w'), c.textures.get(t, {}).get('h'), c.textures.get(t, {}).get('fmt')) for t in d['texset'][:3])
            add('unmatched', '%s draws only in %s (ps %s)' % (d['role'], side, d['ps']), d['area'], d if side == 'CY' else None,
                d if side == 'proj' else None, detail='pc=%s tex=%s' % (d['pc'], tx))
    # render-queue order per role: rank correlation of the matched pairs, and shaders whose mean position moved most
    order_lines = []
    for role in ('shadow', 'depth', 'scene', 'post', 'final'):
        rp = [(da, db) for da, db, _ in pairs if da['role'] == role]
        if len(rp) < 3:
            continue
        rho = spearman([p[0]['n'] for p in rp], [p[1]['n'] for p in rp])
        na, nb = float(len([d for d in a.draws if d['role'] == role])), float(len([d for d in b.draws if d['role'] == role]))
        ia = sorted(p[0]['n'] for p in rp)
        ib = sorted(p[1]['n'] for p in rp)
        rank_a = {n: i for i, n in enumerate(ia)}
        rank_b = {n: i for i, n in enumerate(ib)}
        moves = collections.defaultdict(list)
        for da, db in rp:
            moves[da['ps']].append((rank_b[db['n']] - rank_a[da['n']]) / float(len(rp)))
        order_lines.append('order %s: %d pairs, spearman=%.3f' % (role, len(rp), rho))
        worst = sorted(moves.items(), key=lambda kv: -abs(sum(kv[1]) / len(kv[1])))[:6]
        for h, mv in worst:
            m = sum(mv) / len(mv)
            if abs(m) > 0.05:
                order_lines.append('   CY ps %s (%d draws): mean queue position shift %+.0f%% in proj' % (h, len(mv), 100 * m))
        if rho < 0.95:
            key = 'order %s: render queue order differs (spearman %.3f over %d pairs)' % (role, rho, len(rp))
            agg[key] = {'cat': 'order', 'key': key, 'draws': len(rp), 'area': sum(max(x['area'], y['area']) for x, y in rp) * (1 - rho),
                        'examples': [], 'details': collections.Counter(), 'shaders': collections.Counter()}
    ranked = sorted(agg.values(), key=lambda e: -e['area'])
    # shader diffs
    sd = os.path.join(args.out, 'shaderdiff')
    os.makedirs(sd, exist_ok=True)
    written = 0
    for e in ranked:
        for (kind, ha, hb), n in e['shaders'].most_common(3):
            if written >= 40 or not ha or not hb:
                continue
            f = os.path.join(sd, '%s_%s_%s.diff' % (kind, ha[:8], hb[:8]))
            if os.path.exists(f):
                continue
            ud = difflib.unified_diff(a.asm(kind, ha), b.asm(kind, hb), 'CY/%s.%s.asm' % (ha, kind), 'proj/%s.%s.asm' % (hb, kind), lineterm='', n=2)
            open(f, 'w', encoding='utf-8').write('\n'.join(ud) + '\n')
            written += 1
    tiers = collections.Counter(t for _, _, t in pairs)
    lines.append('pairs: %d (%s); unmatched CY %d, proj %d' % (len(pairs), dict(tiers), len(left_a), len(left_b)))
    lines += order_lines
    lines.append('')
    lines.append('RANKED DIFFERENCES (area = sum of visible pixels / render-target area over the draws concerned)')
    for i, e in enumerate(ranked[:args.top]):
        lines.append('%2d. [%s] %s  | area %.3f, draws %d, e.g. %s' % (i + 1, e['cat'], e['key'], e['area'], e['draws'], ' '.join(e['examples'][:3])))
        for d, n in e['details'].most_common(3):
            lines.append('      %s  (x%d)' % (d[:220], n))
    if len(ranked) > args.top:
        lines.append('... %d more in diff.json' % (len(ranked) - args.top))
    txt = '\n'.join(lines) + '\n'
    open(os.path.join(args.out, 'diff.txt'), 'w', encoding='utf-8').write(txt)
    js = [{k: (dict(v) if isinstance(v, collections.Counter) else v) for k, v in e.items() if k != 'shaders'} for e in ranked]
    for e, r in zip(js, ranked):
        e['shaders'] = ['%s %s->%s x%d' % (k[0], k[1], k[2], n) for k, n in r['shaders'].most_common(5)]
    json.dump({'cy': a.path, 'proj': b.path, 'pairs': len(pairs), 'unmatched_cy': len(left_a), 'unmatched_proj': len(left_b),
               'differences': js}, open(os.path.join(args.out, 'diff.json'), 'w', encoding='utf-8'), indent=1)
    with open(os.path.join(args.out, 'pairs.tsv'), 'w', encoding='utf-8') as f:
        f.write('tier\trole\tcy_n\tproj_n\tcy_px\tproj_px\tpc\tcy_ps\tproj_ps\ttex\n')
        for da, db, t in pairs:
            f.write('%s\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%s\t%s\n' % (t, da['role'], da['n'], db['n'], da.get('px', 0), db.get('px', 0), da['pc'], da['ps'], db['ps'], ','.join(da['texset'])))
    with open(os.path.join(args.out, 'unmatched.tsv'), 'w', encoding='utf-8') as f:
        f.write('side\trole\tn\tpx\tpc\tps\ttex\n')
        for side, left in (('CY', left_a), ('proj', left_b)):
            for d in left:
                f.write('%s\t%s\t%d\t%d\t%d\t%s\t%s\n' % (side, d['role'], d['n'], d.get('px', 0), d['pc'], d['ps'], ','.join(d['texset'])))
    sys.stdout.write(txt)


def cmd_camera(args):
    """Main-camera eye / target / vertical fov of a capture from the constants of its scene draws (camera_position,
    view_matrix, projection_matrix; row-major as the traces store them), printed as TlbbViewer --camera x,y,z,tx,ty,tz,fov."""
    c = Capture(args.cap)
    for d in c.draws:
        if d['role'] not in ('scene',):
            continue
        consts = {}
        consts.update({k.lstrip('$'): v for k, v in (d.get('vsc') or {}).items()})
        consts.update({k.lstrip('$'): v for k, v in (d.get('psc') or {}).items()})
        view = consts.get('view_matrix')
        proj = consts.get('projection_matrix')
        if not (isinstance(view, list) and len(view) >= 12 and isinstance(proj, list) and len(proj) >= 6):
            continue
        # rows of the view rotation are the camera axes in world space; forward = -row 2
        r = [view[0:3], view[4:7], view[8:11]]
        t = [view[3], view[7], view[11]]
        eye = [-(r[0][i] * t[0] + r[1][i] * t[1] + r[2][i] * t[2]) for i in range(3)]
        cp = consts.get('camera_position')
        if isinstance(cp, list) and len(cp) >= 3:
            eye = cp[:3]
        fwd = [-r[2][i] for i in range(3)]
        target = [eye[i] + 1000.0 * fwd[i] for i in range(3)]
        fov = 2.0 * math.degrees(math.atan(1.0 / proj[5]))
        aspect = proj[5] / proj[0]
        print('draw #%d ps %s' % (d['n'], d['ps']))
        print('eye %s forward %s fovY %.2f aspect %.3f' % (['%.2f' % x for x in eye], ['%.4f' % x for x in fwd], fov, aspect))
        print('--camera %s' % ','.join('%.2f' % x for x in eye + target + [fov]))
        return
    print('no scene draw with view_matrix + projection_matrix')


def main():
    ap = argparse.ArgumentParser(description='compare two d3d9 trace captures draw for draw (CY vs CY-Source)')
    sub = ap.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('summary')
    s.add_argument('cap')
    s.set_defaults(func=cmd_summary)
    s = sub.add_parser('sheet')
    s.add_argument('cap')
    s.add_argument('out')
    s.add_argument('--width', type=int, default=320)
    s.add_argument('--cols', type=int, default=4)
    s.set_defaults(func=cmd_sheet)
    s = sub.add_parser('camera')
    s.add_argument('cap')
    s.set_defaults(func=cmd_camera)
    s = sub.add_parser('diff')
    s.add_argument('cy')
    s.add_argument('proj')
    s.add_argument('--out', required=True)
    s.add_argument('--top', type=int, default=40)
    s.set_defaults(func=cmd_diff)
    args = ap.parse_args()
    args.func(args)


if __name__ == '__main__':
    main()
