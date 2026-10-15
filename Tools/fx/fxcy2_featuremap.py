# -*- coding: utf-8 -*-
"""fx-cy-2 (20/09/2026): ban do TINH NANG cho tung hieu ung trong bo 146 dong gia cua fx-cy-baseline.

CAU HOI NO TRA LOI: mot hieu ung lech so voi CY 3.71 la do DU LIEU hay do MA?
  - Du lieu: `all.effect` / `all.particle` / `all.skill` cua ta va cua CY la MOT (da kiem sha256 o
    `Build\\Logs\\2026-09-20-fx-cy-2\\data-identity.txt`) => du lieu KHONG the la nguyen nhan.
  - Ma: 0.85 khong co mot so loai element/affector; CY-Source dung lai chung tu TEN THAM SO
    (`Docs\\specs\\render\\04-effects-particles.md`, cot "In 0.85 src" = no). Cong cu nay dem xem moi
    hieu ung dung bao nhieu loai "dung lai theo suy luan" (SUY LUAN) va bao nhieu loai co san 0.85 (GOC).

DAU RA: TSV mot dong moi hieu ung + bang cheo voi phan quyet cua fx-cy-baseline (neu truyen --verdicts).

DUNG:
  python -B Tools/fx/fxcy2_featuremap.py --out Build/Logs/2026-09-20-fx-cy-2/featuremap.tsv \
      --verdicts Build/Logs/2026-09-19-fx-cy-baseline/compare/all/table.tsv
  python -B Tools/fx/fxcy2_featuremap.py --selftest      # doi chung: bo do co biet truot khong

BAY DA BIET (giu nguyen van de nguoi sau khong sap lai):
  * `all.effect` / `all.particle` la GBK, KHONG phai UTF-8. Tim ten phai ma hoa GBK truoc.
  * `parseEffectFile` cua engine RETURN giua chung khi gap dong hong => dem tho `grep -c` co the
    dem ca template ma engine khong bao gio thay. O day chi doc de lap ban do, khong ket luan
    "engine co template nay" — viec do da co `Tools/fx/bullet/effect_parse_sim.py`.
"""
import argparse
import collections
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, '..', '..'))
EFFECT = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'EffectFolder', 'all.effect')
PARTICLE = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'EffectFolder', 'all.particle')

# Docs/specs/render/04-effects-particles.md muc 1, cot "In 0.85 src" = no  => CY-Source dung lai
# tu ten tham so (INF), khong phai tu ma CY.
INFERRED_ELEMENTS = {'NewRibbonTrail', 'UIParticle'}
INFERRED_AFFECTORS = {'RevoluMove', 'SequenceFrame', 'Dissolve', 'RotationCurve', 'PolarMove'}
# 0.85 co san (FACT, cung muc 1 cua spec)
NATIVE_ELEMENTS = {'Particle', 'Mesh', 'Beam', 'Projector', 'PointLight', 'BillboardSet', 'RibbonTrail'}


def dec(b):
    try:
        return b.decode('utf-8')
    except UnicodeDecodeError:
        return b.decode('gbk', 'replace')


def enc_variants(name):
    out = []
    for e in ('gbk', 'utf-8'):
        try:
            out.append(name.encode(e))
        except Exception:
            pass
    return out


def _blocks(path, head_kw):
    """Tra ve {ten -> [dong da giai ma]} cho moi khoi goc `<head_kw> <ten>` (all.effect)
    hoac `<ten>` (all.particle, khoi goc khong co tu khoa)."""
    raw = open(path, 'rb').read()
    lines = raw.split(b'\n')
    out = {}
    i = 0
    n = len(lines)
    while i < n:
        s = lines[i].strip(b'\r\n \t')
        name = None
        if not s or s.startswith(b'//'):
            i += 1
            continue
        if head_kw:
            p = s.split()
            if len(p) == 2 and p[0] == head_kw:
                name = p[1]
        else:
            # all.particle: dong goc la ten he hat, dong sau la '{'
            if i + 1 < n and lines[i + 1].strip(b'\r\n \t') == b'{':
                name = s
        if name is None:
            i += 1
            continue
        depth = 0
        started = False
        body = []
        j = i + 1
        while j < n:
            t = lines[j].strip(b'\r\n \t')
            if t == b'{':
                depth += 1
                started = True
            elif t == b'}':
                depth -= 1
                if started and depth == 0:
                    break
            else:
                body.append(t)
            j += 1
        out.setdefault(name, []).append(body)
        i = j + 1
    return out


def load():
    eff = _blocks(EFFECT, b'effect')
    par = _blocks(PARTICLE, None)
    return eff, par


def features_of(effect_name, eff, par, seen=None):
    """Tra ve (elements, affectors, emitters, renderers, psnames, missing)."""
    if seen is None:
        seen = set()
    els = collections.Counter()
    affs = collections.Counter()
    emis = collections.Counter()
    rens = collections.Counter()
    psn = []
    missing = []
    body = None
    for v in enc_variants(effect_name):
        if v in eff:
            body = eff[v][0]
            break
    if body is None:
        return els, affs, emis, rens, psn, ['effect:' + effect_name]
    subs = []
    for ln in body:
        p = ln.split()
        if len(p) >= 2 and p[0] == b'element':
            els[dec(p[1])] += 1
        elif len(p) >= 2 and p[0] == b'ParticleSystem':
            psn.append(dec(p[1]))
        elif len(p) >= 2 and p[0] in (b'ParEffectName', b'ColEffectName', b'SubEffectName'):
            nm = dec(p[1])
            if nm and nm != 'NullEffect':
                subs.append(nm)
    for name in psn:
        pb = None
        for v in enc_variants(name):
            if v in par:
                pb = par[v][0]
                break
        if pb is None:
            missing.append('particle:' + name)
            continue
        for ln in pb:
            p = ln.split()
            if len(p) >= 2 and p[0] == b'affector':
                affs[dec(p[1])] += 1
            elif len(p) >= 2 and p[0] == b'emitter':
                emis[dec(p[1])] += 1
            elif len(p) >= 2 and p[0] == b'renderer':
                rens[dec(p[1])] += 1
    for s in subs:
        if s in seen:
            continue
        seen.add(s)
        a, b, c, d, e, f = features_of(s, eff, par, seen)
        els.update(a); affs.update(b); emis.update(c); rens.update(d)
        psn.extend(e); missing.extend(f)
    return els, affs, emis, rens, psn, missing


def selftest():
    """Doi chung: bo do phai phan biet duoc hieu ung CO va KHONG CO loai suy luan."""
    eff, par = load()
    ok = []
    # (a) aura_rune_projector0: chi element Projector (GOC), khong he hat
    e, a, m, r, ps, miss = features_of('aura_rune_projector0', eff, par)
    ok.append(('projector0 chi co element Projector', list(e) == ['Projector'] and not a and not ps))
    # (b) UI_PVE_2024: hai element UIParticle (SUY LUAN)
    e, a, m, r, ps, miss = features_of('UI_PVE_2024', eff, par)
    ok.append(('UI_PVE_2024 co UIParticle', e.get('UIParticle') == 2))
    ok.append(('UI_PVE_2024 co 2 he hat', len(ps) == 2))
    # (c) ten khong ton tai phai bao thieu, khong im lang
    e, a, m, r, ps, miss = features_of('khong_ton_tai_xyz', eff, par)
    ok.append(('ten la bao thieu', miss == ['effect:khong_ton_tai_xyz']))
    # (d) mot hieu ung dung RevoluMove phai bi danh dau SUY LUAN
    hit = None
    for nm in ('m01_erg_单体BUFF', 'buff_大话西游主线任务三_全景风沙'):
        e, a, m, r, ps, miss = features_of(nm, eff, par)
        if a:
            hit = (nm, sorted(a))
            break
    ok.append(('doc duoc affector cua he hat', hit is not None and len(hit[1]) > 0))
    for name, res in ok:
        print(('PASS  ' if res else 'FAIL  ') + name)
    return all(r for _, r in ok)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--plan', default=os.path.join(CYS, 'Build', 're', 'fx-cy-baseline', 'tables', 'plan.json'))
    ap.add_argument('--verdicts', default=None)
    ap.add_argument('--out', default=None)
    ap.add_argument('--selftest', action='store_true')
    args = ap.parse_args()
    if args.selftest:
        sys.exit(0 if selftest() else 1)

    import json
    plan = json.load(io.open(args.plan, encoding='utf-8'))
    eff, par = load()
    verdict = {}
    if args.verdicts:
        with io.open(args.verdicts, encoding='utf-8') as f:
            hdr = f.readline().rstrip('\n').split('\t')
            ix = {k: i for i, k in enumerate(hdr)}
            for line in f:
                c = line.rstrip('\n').split('\t')
                if len(c) > ix['verdict']:
                    verdict[c[ix['fid']]] = (c[ix['verdict']], c[ix['D']])
    rows = []
    for row in plan:
        fid, name = row['fid'], row['effect']
        els, affs, emis, rens, psn, miss = features_of(name, eff, par)
        inf_e = sorted(k for k in els if k in INFERRED_ELEMENTS)
        inf_a = sorted(k for k in affs if k in INFERRED_AFFECTORS)
        v, d = verdict.get(fid, ('', ''))
        rows.append(dict(
            fid=fid, effect=name, verdict=v, D=d,
            elements=','.join('%s*%d' % (k, n) for k, n in sorted(els.items())),
            affectors=','.join('%s*%d' % (k, n) for k, n in sorted(affs.items())),
            emitters=','.join('%s*%d' % (k, n) for k, n in sorted(emis.items())),
            renderers=','.join('%s*%d' % (k, n) for k, n in sorted(rens.items())),
            n_ps=len(psn),
            inferred_elements=','.join(inf_e),
            inferred_affectors=','.join(inf_a),
            inferred=('yes' if (inf_e or inf_a) else 'no'),
            missing=','.join(miss)))
    cols = ['fid', 'effect', 'verdict', 'D', 'inferred', 'inferred_elements', 'inferred_affectors',
            'elements', 'affectors', 'emitters', 'renderers', 'n_ps', 'missing']
    out = io.open(args.out, 'w', encoding='utf-8', newline='\n') if args.out else \
        io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    out.write('\t'.join(cols) + '\n')
    for r in rows:
        out.write('\t'.join(str(r[c]) for c in cols) + '\n')
    out.flush()
    if args.out:
        out.close()
        print('wrote %s (%d rows)' % (args.out, len(rows)))


if __name__ == '__main__':
    main()
