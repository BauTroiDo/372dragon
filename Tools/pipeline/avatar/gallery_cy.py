# -*- coding: utf-8 -*-
"""CYS-AVATAR (14/09): the CY 3.71 gallery - 15 sects x female/male on CanonicalCY.

Sets
  cy_sect    the 30 sect preview objects of the creation screen (CharModelEx 4950 + sex*15 + ordinal, the 高模
             objects with baked body/hair/face/artifact weapon; what Game.exe shows through ShowCySectPreview)
  cy_menpai  30 avatars ASSEMBLED from parts like a new character: 男主角.obj / 女主角.obj frame + CharRace default
             face/hair (CharFaceGeo / CharHairGeo) + NewRoleEquipset starter outfit (ItemVisualChar body/foot/arm)
             + the novice weapon of the sect's weapon Type (EquipBase Rule 2, level 1 -> ItemVisualLocator)
  cy_mount   6 CY mounts (highest CharMount ids with a complete model), rider = assembled avatar
Rendering
  render(...) runs TlbbViewer on every index row: --data <CanonicalCY> --res <obj dir> --model <root> --shot <png>.
"""
import datetime
import json
import os
import subprocess

from . import objxml
from . import validate as V
from .compose import AvatarSpec, compose, ComposeError, slot_label
from .data import gbk, text, CY_SECTS

G = {0: 'f', 1: 'm'}
GENDER = {0: 'female', 1: 'male'}
DEFAULT_OUT = r'C:\TLBB\085\CY-Source\Build\Logs\2026-09-14-cy-avatar\gallery'


class Entry(object):
    def __init__(self, eid, group, spec, desc, sect=None):
        self.id = eid
        self.group = group
        self.spec = spec
        self.desc = desc
        self.sect = sect


def sect_entries(cd):
    out = []
    for sex in (0, 1):
        for i, (key, han, wtype) in enumerate(CY_SECTS):
            mid = cd.col('sect_models')[sex] + i
            cme = cd.row('CharModelEx.txt', mid)
            if cme is None:
                continue
            out.append(Entry('sect_%02d_%s_%s' % (i, key, G[sex]), 'cy_sect',
                             AvatarSpec(race=sex, model=mid, menpai=i, weapon_type=wtype),
                             'CY creation preview sect %d %s (%s): CharModelEx %d %s' % (i, han, GENDER[sex], mid, gbk(cme[1])),
                             sect=i))
    return out


def menpai_entries(cd, outfit=0):
    out = []
    for sex in (0, 1):
        for i, (key, han, wtype) in enumerate(CY_SECTS):
            it = cd.novice_weapon(wtype)
            spec = AvatarSpec(race=sex, menpai=i, outfit=outfit, weapon=it[0] if it else None)
            desc = 'assembled new character of sect %d %s (%s): frame + default face/hair + NewRoleEquipset %d + %s' % (
                i, han, GENDER[sex], outfit,
                ('novice weapon Type %d item %d "%s"' % (wtype, it[0], text(it[10]))) if it else ('no novice weapon of Type %d' % wtype))
            out.append(Entry('menpai_%02d_%s_%s' % (i, key, G[sex]), 'cy_menpai', spec, desc, sect=i))
    return out


def mount_entries(cd, count=6):
    out = []
    rows = [r for r in cd.table('CharMount.txt').rows if cd.row('CharModelEx.txt', r[3]) is not None
            and cd.obj_block(cd.row('CharModelEx.txt', r[3])[1]) is not None]
    rows = sorted(rows, key=lambda r: -r[0])[:count]
    for n, r in enumerate(rows):
        sex = n % 2
        i = n % len(CY_SECTS)
        it = cd.novice_weapon(CY_SECTS[i][2])
        spec = AvatarSpec(race=sex, mount=r[0], outfit=0, weapon=it[0] if it else None, menpai=i)
        cme = cd.row('CharModelEx.txt', r[3])
        out.append(Entry('mount_%d_%s' % (r[0], G[sex]), 'cy_mount', spec,
                         'CY mount CharMount %d "%s" (%s, scale %g), %s rider (sect %s starter)' % (
                             r[0], text(r[1]), gbk(cme[1]), r[4], GENDER[sex], CY_SECTS[i][1])))
    return out


def _clean(s):
    return str(s).replace('\t', ' ').replace('\r', ' ').replace('\n', ' ')


def build(cd, out_dir=DEFAULT_OUT, sets=('cy_sect', 'cy_menpai', 'cy_mount'), log=print, ivc_materials='gbk'):
    obj_dir = os.path.join(out_dir, 'obj')
    os.makedirs(obj_dir, exist_ok=True)
    entries = []
    if 'cy_sect' in sets:
        entries += sect_entries(cd)
    if 'cy_menpai' in sets:
        entries += menpai_entries(cd)
    if 'cy_mount' in sets:
        entries += mount_entries(cd)
    stamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
    rows, issues = [], []
    for e in entries:
        fname = 'avatar_%s.obj' % e.id
        try:
            comp = compose(cd, e.spec, fname, ivc_materials)
        except (ComposeError, KeyError) as ex:
            log('COMPOSE-ERROR %s: %s' % (e.id, ex))
            rows.append(dict(id=e.id, set=e.group, file=fname, root='', race=e.spec.race, gender=G[e.spec.race % 2],
                             desc=e.desc, spec=e.spec.describe(), sources='', anim='', status='COMPOSE-ERROR',
                             fail=1, warn=0, notes=str(ex), resources='', objects=0))
            continue
        data = objxml.document_bytes(comp.elements, comment='CY-Source avatar composer (CY 3.71): %s (set %s), %s'
                                     % (e.id, e.group, stamp))
        path = os.path.join(obj_dir, fname)
        with open(path, 'wb') as f:
            f.write(data)
        rep = V.validate_bytes(cd, data, path)
        anims = [comp.info.get(k) for k in ('mount_anim', 'avatar_anim', 'rider_anim') if comp.info.get(k)]
        slot = comp.info.get('stance_slot')
        rows.append(dict(id=e.id, set=e.group, file=fname, root=comp.root, race=e.spec.race, gender=G[e.spec.race % 2],
                         desc=e.desc + ('; stance column %d %s' % (slot, slot_label(cd, slot)) if slot else ''),
                         spec=e.spec.describe(), sources=' | '.join(comp.sources), anim=' + '.join(anims),
                         status=rep.status, fail=rep.count('FAIL'), warn=rep.count('WARN'),
                         notes=' | '.join(comp.notes), resources=rep.resources_text(), objects=len(comp.elements)))
        for lv, where, msg in rep.issues:
            issues.append((e.id, lv, where, msg))
        log('%-28s %-5s fail=%d warn=%d objects=%d anim=%s' % (e.id, rep.status, rep.count('FAIL'), rep.count('WARN'),
                                                             len(comp.elements), ' + '.join(anims)))
    cols = ('id', 'set', 'file', 'root', 'race', 'gender', 'desc', 'spec', 'sources', 'anim', 'status',
            'fail', 'warn', 'notes', 'resources')
    with open(os.path.join(out_dir, 'index.tsv'), 'w', encoding='utf-8', newline='\r\n') as f:
        f.write('\t'.join(cols) + '\n')
        for r in rows:
            f.write('\t'.join(_clean(r[c]) for c in cols) + '\n')
    with open(os.path.join(out_dir, 'validate.tsv'), 'w', encoding='utf-8', newline='\r\n') as f:
        f.write('id\tlevel\tobject\tmessage\n')
        for i in issues:
            f.write('\t'.join(_clean(x) for x in i) + '\n')
    summary = {'generated': stamp, 'data': cd.dir, 'profile': cd.profile, 'out_dir': out_dir,
               'files': sum(1 for r in rows if r['root']), 'by_set': {}, 'by_status': {},
               'issue_levels': dict((lv, sum(1 for i in issues if i[1] == lv)) for lv in ('FAIL', 'WARN', 'INFO'))}
    for r in rows:
        summary['by_set'][r['set']] = summary['by_set'].get(r['set'], 0) + 1
        summary['by_status'][r['status']] = summary['by_status'].get(r['status'], 0) + 1
    with open(os.path.join(out_dir, 'summary.json'), 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)
    return rows, issues, summary


def render(cd, out_dir, viewer, rows=None, size='900x1100', orbit='25,8', log=print, only=None, timeout=420):
    """TlbbViewer --model <root> for every composed object -> <out_dir>/png/<id>.png; returns [(id, png, rc)].
    Strictly one viewer at a time (all.material of CanonicalCY takes ~5 s alone, >70 s when viewers overlap);
    a timed-out viewer is killed with its tree before the next one starts."""
    png_dir = os.path.join(out_dir, 'png')
    os.makedirs(png_dir, exist_ok=True)
    if rows is None:
        rows = []
        with open(os.path.join(out_dir, 'index.tsv'), encoding='utf-8') as f:
            heads = f.readline().rstrip('\r\n').split('\t')
            for ln in f:
                rows.append(dict(zip(heads, ln.rstrip('\r\n').split('\t'))))
    res = []
    for r in rows:
        if not r.get('root') or (only and r['id'] not in only):
            continue
        png = os.path.join(png_dir, r['id'] + '.png')
        logf = os.path.join(png_dir, r['id'] + '.log')
        cmd = [viewer, '--data', cd.dir, '--res', os.path.join(out_dir, 'obj'), '--model', r['root'],
               '--lights', 'scene', '--orbit', orbit, '--size', size, '--shot', png, '--log', logf]
        if os.path.isfile(png) and os.path.getsize(png) > 10000 and not only:
            log('%-28s cached PNG' % r['id'])
            res.append((r['id'], png, 0))
            continue
        t0 = datetime.datetime.now()
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        try:
            out, _ = p.communicate(timeout=timeout)
            rc = p.returncode
            tail = out.decode('utf-8', 'replace').strip().splitlines()[-1:] if out else []
        except subprocess.TimeoutExpired:
            subprocess.run(['taskkill', '/F', '/T', '/PID', str(p.pid)], capture_output=True)
            p.communicate()
            rc, tail = -1, ['timeout %ds' % timeout]
        ok = rc == 0 and os.path.isfile(png) and os.path.getsize(png) > 10000
        secs = (datetime.datetime.now() - t0).total_seconds()
        log('%-28s rc=%d %s %.0fs %s' % (r['id'], rc, 'PNG' if ok else 'NO-PNG', secs, ' '.join(tail)[:120]))
        res.append((r['id'], png if ok else '', rc))
    with open(os.path.join(out_dir, 'render.tsv'), 'w', encoding='utf-8', newline='\r\n') as f:
        f.write('id\tpng\trc\n')
        for i, png, rc in res:
            f.write('%s\t%s\t%d\n' % (i, png, rc))
    return res
