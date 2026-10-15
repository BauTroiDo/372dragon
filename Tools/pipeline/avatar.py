#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Player-avatar composer (CY-Source).  Read-only on client_GL; writes composite LogicModel objects.

  compose   one look -> <out>.obj (AllObjects: root + derived objects) + resource list + validation
  gallery   the 2026 gallery -> Assets/Staging/avatars/*.obj + index.tsv, logs in Build/Logs/2026-09-12-avatar
  validate  check composite .obj files (or folders) against client_GL
  rules     print / write the assembly rules with evidence

Examples (PowerShell; Python 3.13, PYTHONUTF8=1):
  python avatar.py compose --gender f --costume 10126221 --hair-style 151 --weapon-skin 69 --name demo_f
  python avatar.py compose --gender m --mount 233 --costume 1016 --head 23 --back 22 --name demo_ride
  python avatar.py gallery
  python avatar.py validate C:\\TLBB\\085\\CY-Source\\Assets\\Staging\\avatars

The objects are for viewers and tests: they carry a DefaultAnimation (idle stance) which the game
never uses for characters.  Render with TlbbViewer once it can add an extra resource location
(see Build/Logs/2026-09-12-avatar/viewer_request.txt): --model <root object name>.
Rules: avatar/rules.py (R01..R15).
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

from avatar import data as D                  # noqa: E402
from avatar import compose as C               # noqa: E402
from avatar import validate as V              # noqa: E402
from avatar import gallery as G               # noqa: E402
from avatar import rules as R                 # noqa: E402
from avatar import objxml                     # noqa: E402
from avatar import gallery_cy as GC           # noqa: E402  CYS-AVATAR: CY 3.71 sect gallery + viewer render

VIEWER_DEFAULT = r'C:\TLBB\085\CY-Source\Build\wt-cy-avatar\Build\cmake\avatar-x64\bin\TlbbViewer.exe'

CUSTOM_DIR = os.path.join(G.OUT_DIR, 'custom')
PROTECTED = (r'C:\TLBB\085\client_GL', r'C:\TLBB\085\client', r'C:\TLBB\085\Tools',
             r'C:\TLBB\085\CY-Source\Reference')


def _guard(path):
    p = os.path.normcase(os.path.abspath(path))
    for root in PROTECTED:
        r = os.path.normcase(os.path.abspath(root))
        if p == r or p.startswith(r + os.sep):
            raise SystemExit('refusing to write under %s (read-only source)' % root)


def _spec(a):
    race = a.race if a.race is not None else (1 if a.gender == 'm' else 0)
    return C.AvatarSpec(race=race, model=a.model, outfit=a.outfit,
                        menpai=a.menpai, face=a.face, face_style=a.face_style, hair=a.hair,
                        hair_style=a.hair_style, no_hair=a.no_hair, costume=a.costume, dress_color=a.dress_color,
                        cap=a.cap, armor=a.armor, cuff=a.cuff, boot=a.boot, weapon=a.weapon,
                        weapon_skin=a.weapon_skin, weapon_level=a.weapon_level, weapon_ivl=a.weapon_ivl,
                        weapon_type=a.weapon_type, kfs_ivl=a.kfs, mount=a.mount, head=a.head, back=a.back,
                        head_iov=a.head_iov, back_iov=a.back_iov, aura=a.aura, anim=a.anim)


def cmd_compose(a):
    cd = D.ClientData(a.data)
    spec = _spec(a)
    name = a.name or ('avatar_custom_%s' % spec.key())
    if not name.lower().startswith('avatar_'):
        name = 'avatar_' + name
    comp = C.compose(cd, spec, name, a.ivc_materials)
    out = a.out or os.path.join(CUSTOM_DIR, comp.root)
    _guard(out)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    data = objxml.document_bytes(comp.elements, comment='CY-Source avatar composer: %s' % spec.describe()
                                 .encode('ascii', 'replace').decode('ascii'))
    with open(out, 'wb') as f:
        f.write(data)
    rep = V.validate_bytes(cd, data, out)
    print('written   %s' % out)
    print('model     %s   (objects in file: %s)' % (comp.root, ', '.join(objxml.name_of(e).decode('latin-1') for e in comp.elements)))
    print('spec      %s' % spec.describe())
    print('sources:')
    for s in comp.sources:
        print('  ' + s)
    if comp.notes:
        print('notes:')
        for s in comp.notes:
            print('  ' + s)
    print('validation %s (fail %d, warn %d)' % (rep.status, rep.count('FAIL'), rep.count('WARN')))
    for lv, where, msg in rep.issues:
        if lv != 'INFO':
            print('  %s %s: %s' % (lv, where, msg))
    print('resources:')
    for part in rep.resources_text(sep=', ').split('; '):
        print('  ' + part)
    return 1 if rep.status == 'FAIL' else 0


def cmd_gallery(a):
    cd = D.ClientData(a.data)
    _guard(a.out_dir)
    _guard(a.log_dir)
    os.makedirs(a.log_dir, exist_ok=True)
    R.write(os.path.join(a.log_dir, 'assembly_rules.txt'))
    logf = open(os.path.join(a.log_dir, 'gallery.log'), 'w', encoding='utf-8', newline='\r\n')

    def log(s):
        print(s)
        logf.write(s + '\n')
    rows, issues, summary = G.build(cd, a.out_dir, a.log_dir, tuple(a.sets.split(',')), log)
    log('files %d  by set %s  by status %s  issues %s' % (summary['files'], summary['by_set'],
                                                        summary['by_status'], summary['issue_levels']))
    stale = summary['stale_files_not_regenerated']
    if stale:                          # own, regenerable outputs of an earlier run (top level only)
        for n in stale:
            os.remove(os.path.join(a.out_dir, n))
        log('removed stale composites of earlier runs: %s' % ', '.join(stale))
    logf.close()
    return 1 if summary['by_status'].get('FAIL') or summary['by_status'].get('COMPOSE-ERROR') else 0


def cmd_gallery_cy(a):
    cd = D.ClientData(a.data)
    if cd.profile != 'cy':
        raise SystemExit('gallery-cy needs a CY 3.71 data set (CharModelEx 21 columns); got profile %s' % cd.profile)
    _guard(a.out_dir)
    os.makedirs(a.out_dir, exist_ok=True)
    R.write(os.path.join(a.out_dir, 'assembly_rules.txt'))
    logf = open(os.path.join(a.out_dir, 'gallery.log'), 'a', encoding='utf-8', newline='\r\n')

    def log(s):
        print(s)
        logf.write(s + '\n')
    rows, issues, summary = GC.build(cd, a.out_dir, tuple(a.sets.split(',')), log)
    log('profile %s files %d by set %s by status %s issues %s' % (cd.profile, summary['files'], summary['by_set'],
                                                                 summary['by_status'], summary['issue_levels']))
    rc = 1 if summary['by_status'].get('FAIL') or summary['by_status'].get('COMPOSE-ERROR') else 0
    if a.render:
        res = GC.render(cd, a.out_dir, a.viewer, rows, size=a.size, orbit=a.orbit, log=log)
        n_ok = sum(1 for _i, png, _rc in res if png)
        log('rendered %d/%d PNG' % (n_ok, len(res)))
        if n_ok != len(res):
            rc = 1
    logf.close()
    return rc


def cmd_render(a):
    cd = D.ClientData(a.data)
    _guard(a.out_dir)
    res = GC.render(cd, a.out_dir, a.viewer, size=a.size, orbit=a.orbit, only=set(a.only.split(',')) if a.only else None)
    n_ok = sum(1 for _i, png, _rc in res if png)
    print('rendered %d/%d PNG' % (n_ok, len(res)))
    return 0 if n_ok == len(res) else 1


def cmd_validate(a):
    cd = D.ClientData(a.data)
    files = []
    for p in a.paths:
        if os.path.isdir(p):
            for dp, dn, fn in os.walk(p):
                files += [os.path.join(dp, f) for f in sorted(fn) if f.lower().endswith('.obj')]
        else:
            files.append(p)
    worst = 0
    for f in files:
        rep = V.validate_file(cd, f)
        print('%-5s fail=%d warn=%d  %s' % (rep.status, rep.count('FAIL'), rep.count('WARN'), f))
        for lv, where, msg in rep.issues:
            if lv == 'FAIL' or (a.verbose and lv == 'WARN'):
                print('    %s %s: %s' % (lv, where, msg))
        worst = max(worst, 1 if rep.status == 'FAIL' else 0)
    return worst


def cmd_rules(a):
    if a.write:
        _guard(a.write)
        print('written %s' % R.write(a.write))
    else:
        print(R.render())
    return 0


def main(argv=None):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except (AttributeError, ValueError):
        pass
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--data', default=D.DATA_DIR,
                    help='client Data folder (read-only), default CanonicalCY (CY 3.71); client_GL: %s' % D.DATA_DIR_GL)
    sub = ap.add_subparsers(dest='cmd', required=True)

    p = sub.add_parser('compose', help='compose one look')
    p.add_argument('--gender', choices=('f', 'm'), default='f')
    p.add_argument('--race', type=int, help='CharRace id (overrides --gender; 2..7 = CY novice outfits)')
    p.add_argument('--model', type=int, help='CharModelEx id as base object (CY sect previews 4950..4979)')
    p.add_argument('--outfit', type=int, help='NewRoleEquipset id (creation starter set body/foot/arm)')
    p.add_argument('--menpai', type=int, help='sect id (metadata; --aura adds its aura effect)')
    p.add_argument('--aura', action='store_true', help='approximate the sect aura (aura_rune_projector<menpai>)')
    p.add_argument('--face', type=int, help='CharFaceGeo id')
    p.add_argument('--face-style', type=int, help='Exterior_Face id')
    p.add_argument('--hair', type=int, help='CharHairGeo id')
    p.add_argument('--hair-style', type=int, help='Exterior_Hair id')
    p.add_argument('--no-hair', action='store_true')
    p.add_argument('--costume', type=int, help='costume item id (EquipBase Type 25) or EquipDress index')
    p.add_argument('--dress-color', type=int, help='ItemVisualChar colour slot 1..10 (default: EquipDress col6)')
    p.add_argument('--cap', type=int, help='ItemVisualChar id (plain equipment, no costume)')
    p.add_argument('--armor', type=int)
    p.add_argument('--cuff', type=int)
    p.add_argument('--boot', type=int)
    p.add_argument('--weapon', type=int, help='weapon item id (EquipBase, col6 -> ItemVisualLocator)')
    p.add_argument('--weapon-skin', type=int, help='Exterior_Weapon id (weapon skin)')
    p.add_argument('--weapon-level', type=int, help='weapon skin level 1..4 (default highest)')
    p.add_argument('--weapon-ivl', type=int, help='ItemVisualLocator id')
    p.add_argument('--weapon-type', type=int, help='EquipBase Type for --weapon-ivl (stance)')
    p.add_argument('--kfs', type=int, help='武魂 ItemVisualLocator id (KFSObj)')
    p.add_argument('--mount', type=int, help='CharMount id or mount item id (EquipBase Type 41)')
    p.add_argument('--head', type=int, help='Exterior_TS id (head ornament)')
    p.add_argument('--back', type=int, help='Exterior_BG id (back ornament)')
    p.add_argument('--head-iov', type=int, help='ItemOrnamentsVisual id')
    p.add_argument('--back-iov', type=int, help='ItemOrnamentsVisual id')
    p.add_argument('--anim', help='DefaultAnimation of the root (default: idle from ActionSet; "" = none)')
    p.add_argument('--ivc-materials', choices=C.MATERIAL_MODES, default='gbk',
                   help='gbk (default): GBK spelling of UTF-8 material cells = designed look; '
                        'raw: cell bytes as the current Game.exe sees them')
    p.add_argument('--name', help='root object name (ASCII; "avatar_" is prefixed)')
    p.add_argument('--out', help='output .obj (default Assets/Staging/avatars/custom/<name>.obj)')
    p.set_defaults(func=cmd_compose)

    g = sub.add_parser('gallery', help='build the 2026 gallery')
    g.add_argument('--sets', default='costume,mount,weapon,hair')
    g.add_argument('--out-dir', default=G.OUT_DIR)
    g.add_argument('--log-dir', default=G.LOG_DIR)
    g.set_defaults(func=cmd_gallery)

    gc = sub.add_parser('gallery-cy', help='CY 3.71 gallery: 15 sects x f/m (previews + assembled) [+ render]')
    gc.add_argument('--sets', default='cy_sect,cy_menpai,cy_mount')
    gc.add_argument('--out-dir', default=GC.DEFAULT_OUT)
    gc.add_argument('--render', action='store_true', help='also render every object with TlbbViewer')
    gc.add_argument('--viewer', default=VIEWER_DEFAULT)
    gc.add_argument('--size', default='900x1100')
    gc.add_argument('--orbit', default='25,8')
    gc.set_defaults(func=cmd_gallery_cy)

    rd = sub.add_parser('render', help='render the objects of a gallery index.tsv with TlbbViewer')
    rd.add_argument('--out-dir', default=GC.DEFAULT_OUT)
    rd.add_argument('--viewer', default=VIEWER_DEFAULT)
    rd.add_argument('--size', default='900x1100')
    rd.add_argument('--orbit', default='25,8')
    rd.add_argument('--only', help='comma-separated entry ids')
    rd.set_defaults(func=cmd_render)

    v = sub.add_parser('validate', help='validate composite .obj files or folders')
    v.add_argument('paths', nargs='+')
    v.add_argument('-v', '--verbose', action='store_true', help='also print warnings')
    v.set_defaults(func=cmd_validate)

    r = sub.add_parser('rules', help='print or write the assembly rules')
    r.add_argument('--write')
    r.set_defaults(func=cmd_rules)

    a = ap.parse_args(argv)
    try:
        return a.func(a)
    except C.ComposeError as ex:
        print('compose error: %s' % ex)
        return 2


if __name__ == '__main__':
    sys.exit(main())
