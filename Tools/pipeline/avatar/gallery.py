# -*- coding: utf-8 -*-
"""2026 gallery set -> Assets/Staging/avatars/avatar_*.obj + index.tsv (logs: Build/Logs/2026-09-12-avatar).

Sets
  costume  every ItemVisualChar row whose female or male mesh name contains 2026 that is worn as a
           costume (has an EquipDress row; colour slot 1), x both genders; the hairstyle whose mesh
           stem equals the costume stem (same set, e.g. W_cloth_2026琼珍阁 / W_hair_2026琼珍阁) is
           worn with it, otherwise the race default hair
  mount    every CharMount whose model object name contains 2026, one rider each (female/male
           alternating) wearing a 2026 costume from the costume set
  weapon   20 representative weapons in hand: 14 2026 weapon skins (Exterior_Weapon, highest level)
           + a back-slot qin + a foot-slot weapon + the 4 CY sect weapon lines (Types 8/9/16/17),
           wearers alternate female/male and wear a 2026 costume
  hair     Exterior_Hair 141-160 (the 20 styles imported 2026-09-10) x both genders, with the
           costume of the same stem when one exists, otherwise the race default outfit
"""
import datetime
import json
import os

from . import objxml
from . import validate as V
from .compose import AvatarSpec, compose, ComposeError, SLOT_LABEL
from .data import gbk, text

OUT_DIR = r'C:\TLBB\085\CY-Source\Assets\Staging\avatars'
LOG_DIR = r'C:\TLBB\085\CY-Source\Build\Logs\2026-09-12-avatar'
Y = b'2026'
G = {0: 'f', 1: 'm'}
GENDER = {0: 'female', 1: 'male'}

WEAPON_SKINS = (60, 61, 64, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77)
SPECIAL_IVL = ((829, 'BackWeaponObj example (IVL col15 qin on the back)'),
               (1326, 'FootWeaponObj example (IVL col11)'))
SECT_TYPES = ((8, 'CY sect weapon Type 8 (刀组, Tuyet Tinh Coc)'), (9, 'CY sect weapon Type 9 (长杖, Quy Coc)'),
              (16, 'CY sect weapon Type 16 (弩, Duong Mon)'), (17, 'CY sect weapon Type 17 (箫剑, Dao Hoa Dao)'))
HAIR_RANGE = range(141, 161)


class Entry(object):
    def __init__(self, eid, group, spec, desc):
        self.id = eid
        self.group = group
        self.spec = spec
        self.desc = desc


def _stem(mesh, markers):
    if not mesh:
        return None
    for mk in markers:
        i = mesh.find(mk)
        if i >= 0:
            s = mesh[i + len(mk):]
            return s[:-5] if s.lower().endswith(b'.mesh') else s
    return None


def _hair_by_stem(cd):
    out = {}
    for eh in cd.table('Exterior_Hair.txt').rows:
        for race in (0, 1):
            geo = cd.row('CharHairGeo.txt', eh[1 + race])
            if geo is None:
                continue
            st = _stem(geo[2], (b'hair_',)) or _stem(geo[3], (b'hair01_', b'hair_'))
            if st:
                out.setdefault((race, st), eh[0])
    return out


def _costume_items(cd):
    items = {}
    for r in cd.table('EquipBase.txt').rows:
        if len(r) > 10 and r[5] == 16 and r[6] not in items:
            items[r[6]] = r
    return items


def _dress_of_ivc(cd):
    by = {}
    for e in cd.table('EquipDress.txt').rows:
        by.setdefault(e[2], []).append(e)
    return dict((k, sorted(v, key=lambda e: (e[6] != 1, e[0]))[0]) for k, v in by.items())


def _costume_by_stem(cd):
    dress = _dress_of_ivc(cd)
    items = _costume_items(cd)
    out = {}
    for r in cd.table('ItemVisualChar.txt').rows:
        d = dress.get(r[0])
        if d is None:
            continue
        for race in (0, 1):
            st = _stem(r[1 + 11 * race], (b'cloth_',))
            if st:
                it = items.get(d[0])
                out.setdefault((race, st), it[0] if it else d[0])
    return out


def costume_entries(cd, hair_by_stem):
    dress = _dress_of_ivc(cd)
    items = _costume_items(cd)
    out = []
    for r in cd.table('ItemVisualChar.txt').rows:
        if not (Y in r[1] or Y in r[12]):
            continue
        d = dress.get(r[0])
        if d is None:
            continue
        item = items.get(d[0])
        for race in (0, 1):
            mesh = r[1 + 11 * race]
            if not mesh:
                continue
            st = _stem(mesh, (b'cloth_',))
            hs = hair_by_stem.get((race, st)) if st else None
            spec = AvatarSpec(race=race, costume=item[0] if item else d[0], hair_style=hs)
            who = ('item %d "%s"' % (item[0], text(item[10]))) if item else ('EquipDress %d' % d[0])
            desc = '2026 costume %s, %s, %s; %s' % (gbk(mesh), GENDER[race], who,
                                                   ('matching hairstyle Exterior_Hair %d' % hs) if hs else 'race default hair')
            out.append(Entry('costume_%d_%s' % (r[0], G[race]), 'costume', spec, desc))
    return out


def _outfit(outfits, race, i):
    lst = outfits.get(race) or []
    return lst[i % len(lst)] if lst else None


def mount_entries(cd, outfits):
    out = []
    i = 0
    for r in cd.table('CharMount.txt').rows:
        cme = cd.row('CharModelEx.txt', r[3])
        if cme is None or Y not in cme[1]:
            continue
        race = i % 2
        o = _outfit(outfits, race, i // 2)
        spec = AvatarSpec(race=race, mount=r[0], costume=o.costume if o else None,
                          hair_style=o.hair_style if o else None)
        desc = '2026 mount CharMount %d "%s" (%s, scale %g), %s rider%s' % (
            r[0], text(r[1]), gbk(cme[1]), r[4], GENDER[race],
            (' in costume %d' % o.costume) if o else '')
        out.append(Entry('mount_%d_%s' % (r[0], G[race]), 'mount', spec, desc))
        i += 1
    return out


def _weapon_complete(cd, ivl):
    """True when every weapon object of the IVL row exists and its meshes and skeletons exist."""
    import re
    for oc in (2, 5, 11, 15):
        o = ivl[oc] if oc < len(ivl) else b''
        if not o:
            continue
        blk = cd.obj_block(o)
        if blk is None:
            return False
        for f in re.findall(rb'file="([^"]+)"', blk):
            mi = cd.mesh(f)
            if mi is None or (mi.get('skel') and cd.skeleton(mi['skel']) is None):
                return False
    return True


_PLACEHOLDER_NAMES = ('Chưa Sử Dụng', '未使用')


def _best_item_of_type(cd, wtype):
    """Highest (quality, level, id) weapon item of a Type whose visual resources are complete
    (placeholder rows such as "Chưa Sử Dụng" / 未使用 are skipped)."""
    best = None
    for r in cd.table('EquipBase.txt').rows:
        if len(r) > 11 and r[3] == wtype and r[5] == 0 and r[6] > 0:
            nm = text(r[10])
            if not nm.strip() or any(p in nm for p in _PLACEHOLDER_NAMES):
                continue
            ivl = cd.row('ItemVisualLocator.txt', r[6])
            if ivl is None or not (ivl[2] or ivl[5]):
                continue
            k = (r[2], r[11], r[0])
            if best is not None and k <= best[0]:
                continue
            if _weapon_complete(cd, ivl):
                best = (k, r)
    return best[1] if best else None


def weapon_entries(cd, outfits):
    out = []
    n = 0

    def add(eid, spec_kw, desc):
        nonlocal n
        race = n % 2
        o = _outfit(outfits, race, n // 2 + 3)
        spec = AvatarSpec(race=race, costume=o.costume if o else None,
                          hair_style=o.hair_style if o else None, **spec_kw)
        out.append(Entry('%s_%s' % (eid, G[race]), 'weapon', spec, '%s, %s' % (desc, GENDER[race])))
        n += 1

    for ew in WEAPON_SKINS:
        row = cd.row('Exterior_Weapon.txt', ew)
        if row is None:
            continue
        add('weapon_skin%d' % ew, dict(weapon_skin=ew),
            '2026 weapon skin Exterior_Weapon %d "%s" (Type %d, highest level)' % (ew, text(row[1]), row[7]))
    for ivl, what in SPECIAL_IVL:
        if cd.row('ItemVisualLocator.txt', ivl) is not None:
            add('weapon_ivl%d' % ivl, dict(weapon_ivl=ivl), what + ', IVL %d' % ivl)
    for t, what in SECT_TYPES:
        it = _best_item_of_type(cd, t)
        if it is not None:
            add('weapon_item%d' % it[0], dict(weapon=it[0]), '%s: item %d "%s"' % (what, it[0], text(it[10])))
    return out


def hair_entries(cd, costume_by_stem):
    out = []
    for hid in HAIR_RANGE:
        eh = cd.row('Exterior_Hair.txt', hid)
        if eh is None:
            continue
        for race in (0, 1):
            geo = cd.row('CharHairGeo.txt', eh[1 + race])
            st = None
            if geo is not None:
                st = _stem(geo[2], (b'hair_',)) or _stem(geo[3], (b'hair01_', b'hair_'))
            cos = costume_by_stem.get((race, st)) if st else None
            spec = AvatarSpec(race=race, hair_style=hid, costume=cos)
            desc = 'hairstyle Exterior_Hair %d "%s" (CharHairGeo %d, %s); %s' % (
                hid, text(eh[8]) if len(eh) > 8 else '', eh[1 + race], GENDER[race],
                ('with the same-set costume %d' % cos) if cos else 'race default outfit')
            out.append(Entry('hair_%d_%s' % (hid, G[race]), 'hair', spec, desc))
    return out


def _clean(s):
    return str(s).replace('\t', ' ').replace('\r', ' ').replace('\n', ' ')


def build(cd, out_dir=OUT_DIR, log_dir=LOG_DIR, sets=('costume', 'mount', 'weapon', 'hair'), log=print,
          ivc_materials='gbk'):
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(log_dir, exist_ok=True)
    hair_by_stem = _hair_by_stem(cd)
    costumes = costume_entries(cd, hair_by_stem)
    outfits = {0: [e.spec for e in costumes if e.spec.race == 0],
               1: [e.spec for e in costumes if e.spec.race == 1]}
    entries = []
    if 'costume' in sets:
        entries += costumes
    if 'mount' in sets:
        entries += mount_entries(cd, outfits)
    if 'weapon' in sets:
        entries += weapon_entries(cd, outfits)
    if 'hair' in sets:
        entries += hair_entries(cd, _costume_by_stem(cd))

    stamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
    rows, issues, written = [], [], set()
    for e in entries:
        fname = 'avatar_%s.obj' % e.id
        try:
            comp = compose(cd, e.spec, fname, ivc_materials)
        except (ComposeError, KeyError) as ex:
            log('COMPOSE-ERROR %s: %s' % (e.id, ex))
            rows.append(dict(id=e.id, set=e.group, file=fname, root='', race=e.spec.race, gender=G.get(e.spec.race % 2),
                             desc=e.desc, spec=e.spec.describe(), sources='', anim='', status='COMPOSE-ERROR',
                             fail=1, warn=0, notes=str(ex), resources='', utf8=0, objects=0))
            continue
        data = objxml.document_bytes(comp.elements, comment='CY-Source avatar composer: %s (set %s), %s; see index.tsv'
                                     % (e.id, e.group, stamp))
        path = os.path.join(out_dir, fname)
        with open(path, 'wb') as f:
            f.write(data)
        written.add(fname.lower())
        rep = V.validate_bytes(cd, data, path)
        anims = [comp.info.get(k) for k in ('mount_anim', 'avatar_anim', 'rider_anim') if comp.info.get(k)]
        slot = comp.info.get('stance_slot')
        rows.append(dict(id=e.id, set=e.group, file=fname, root=comp.root, race=e.spec.race, gender=G[e.spec.race % 2],
                         desc=e.desc + ('; stance column %d %s' % (slot, SLOT_LABEL.get(slot, '')) if slot else ''),
                         spec=e.spec.describe(), sources=' | '.join(comp.sources), anim=' + '.join(anims),
                         status=rep.status, fail=rep.count('FAIL'), warn=rep.count('WARN'),
                         notes=' | '.join(comp.notes), resources=rep.resources_text(),
                         utf8=comp.info.get('utf8_cells', 0), objects=len(comp.elements)))
        for lv, where, msg in rep.issues:
            issues.append((e.id, lv, where, msg))
        log('%-28s %-5s fail=%d warn=%d objects=%d utf8-cells=%d' % (
            e.id, rep.status, rep.count('FAIL'), rep.count('WARN'), len(comp.elements), comp.info.get('utf8_cells', 0)))

    cols = ('id', 'set', 'file', 'root', 'race', 'gender', 'desc', 'spec', 'sources', 'anim', 'status',
            'fail', 'warn', 'notes', 'resources')
    heads = ('id', 'set', 'file', 'root_object', 'race', 'gender', 'description', 'spec', 'source_rows',
             'default_anim', 'validation', 'fail', 'warn', 'notes', 'resources')
    with open(os.path.join(out_dir, 'index.tsv'), 'w', encoding='utf-8', newline='\r\n') as f:
        f.write('\t'.join(heads) + '\n')
        for r in rows:
            f.write('\t'.join(_clean(r[c]) for c in cols) + '\n')
    with open(os.path.join(log_dir, 'validate.tsv'), 'w', encoding='utf-8', newline='\r\n') as f:
        f.write('id\tlevel\tobject\tmessage\n')
        for i in issues:
            f.write('\t'.join(_clean(x) for x in i) + '\n')
    stale = sorted(n for n in os.listdir(out_dir)
                   if n.lower().startswith('avatar_') and n.lower().endswith('.obj') and n.lower() not in written)
    summary = {
        'generated': stamp, 'data': cd.dir, 'out_dir': out_dir, 'files': len(written),
        'ivc_materials': ivc_materials,
        'utf8_material_cells_rewritten_to_gbk': sum(r['utf8'] for r in rows),
        'objects_written': sum(r['objects'] for r in rows),
        'by_set': {}, 'by_status': {}, 'stale_files_not_regenerated': stale,
        'issue_levels': dict((lv, sum(1 for i in issues if i[1] == lv)) for lv in ('FAIL', 'WARN', 'INFO')),
    }
    for r in rows:
        summary['by_set'][r['set']] = summary['by_set'].get(r['set'], 0) + 1
        summary['by_status'][r['status']] = summary['by_status'].get(r['status'], 0) + 1
    with open(os.path.join(log_dir, 'summary.json'), 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)
    return rows, issues, summary
