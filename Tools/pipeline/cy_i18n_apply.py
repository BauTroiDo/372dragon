"""cy_i18n_apply.py - re-apply the i18n-cy text layers of agent i18n-cy (17/09/2026) without a full rebuild.

Why this exists
---------------
build_canonical_cy.py --apply rebuilds the whole CanonicalCY tree (and, as of 17/09, throws away the scene DBC rows
other agents apply by hand). This tool touches ONLY the files the i18n layer owns, so a translation batch can be put
in front of Game.exe in seconds and, just as importantly, can be replayed after somebody else runs the full builder.

Everything it writes is derived, exactly as build_canonical_cy.cy_gui_generate derives it:
  ConfigFolder/StrDictionary.txt   cy_gui_dict.build()           layer cy-gui-dict-vi
  ConfigFolder/XiuLianMiJi.txt     cy_item_text.convert_table()  layer cy-item-text-vi  (columns 2 name, 4 desc)
  ConfigFolder/XiuLianBook.txt     cy_item_text.convert_table()  layer cy-item-text-vi  (columns 1 name, 3 desc)
The source of truth is never this file: it is the CY 3.71 Config.axp plus the registry dictionaries
Registry/i18n/*.tsv.  Running `build_canonical_cy.py --apply --gui cy` produces byte-identical output, because it
calls the same two functions - this tool is the fast path, not a second implementation.

Safety rules kept from cy_item_text.py
  * only the DISPLAY columns of a table are rewritten; every other cell (numbers and the resource-key STRING columns
    such as the Xiulian icon names) must come out byte-identical, and verify() raises on the first one that does not.
  * a display cell that looks like a resource (file extension, backslash) is left alone.
  * the on-disk file is replaced through a .part file, and the previous content is copied to
    Build/Logs/2026-09-17-i18n-cy/backup/<stamp>/... first (NOT next to the table: Data/ConfigFolder is junctioned
    into every stage, and a 27 MB StrDictionary.bak would ride along into all of them).

usage:  python -B cy_i18n_apply.py plan            what would change, byte counts, no writes
        python -B cy_i18n_apply.py apply           write GEN + Data (backup first), then verify from disk
        python -B cy_i18n_apply.py verify          read the files back from disk and re-check them
"""
import argparse
import collections
import datetime
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(REPO, 'Docs', 'evidence', 'assetinv'))
import cy_gui_dict as GDICT      # noqa: E402
import cy_item_text as ITX       # noqa: E402

S4_CONFIG = os.path.join(ITX.S4, 'Config.axp')
ASSETS = os.path.join(ITX.REPO_MAIN, 'Assets', 'CanonicalCY')
GEN = os.path.join(ASSETS, '_generated', 'gui-cy')
DATA = os.path.join(ASSETS, 'Data')
GL_DICT = os.path.join(ITX.REPO_MAIN, 'Assets', 'Canonical', 'Data', 'ConfigFolder', 'StrDictionary.txt')
BACKUP = os.path.join(ITX.REPO_MAIN, 'Build', 'Logs', '2026-09-17-i18n-cy', 'backup')
TABLES = ('XiuLianMiJi.txt', 'XiuLianBook.txt',     # the tables this layer added; the item tables stay with the builder
          # CYS-I18N (i18n-2 17/09): tables added to ITX.DISPLAY this round (see cy_item_text.py DISPLAY comment for
          # the per-column evidence and the forbidden/dead columns ruled out alongside them).
          'MonsterPaoPao.txt', 'ImpactSEData_V1.txt', 'CharTitle.txt', 'Ability.txt', 'ChatMood.txt',
          'CharHairGeo.txt', 'CharFaceGeo.txt', 'ScenePosDefine.txt')
HAN = GDICT.HAN
BRACE = re.compile(r'#\{[^}]*\}')


def open_config():
    import axp_index as AX
    return AX.Axp(S4_CONFIG)


def build_all():
    """-> {rel: (bytes, note)} for every file this layer owns."""
    ax = open_config()
    out = {}
    _, raw = ax.payload_full('StrDictionary.txt', 256 << 20)
    text, dstats, _rows, untr = GDICT.build(raw, GL_DICT)
    out['ConfigFolder\\StrDictionary.txt'] = (text, 'keys %d, untranslated %d, override-key %d'
                                              % (dstats['keys'], len(untr), dstats.get('override-key', 0)))
    names = {n.lower(): n for n, _ in ax.file_list()}
    look = ITX.Lookup()
    for table in TABLES:
        entry = names.get(table.lower())
        if entry is None:
            raise SystemExit('%s is not in %s' % (table, S4_CONFIG))
        _, src = ax.payload_full(entry, 64 << 20)
        data, rows = ITX.convert_table(table, src, look)
        v = ITX.verify(table, src, data)            # raises when a key/number cell moved
        note = ('display changed %d, key cells same %d, number cells same %d'
                % (v['display_changed'], v['key_string_cells_same'], v['number_cells_same']))
        note += ' | ' + ', '.join('c%d %s %s' % (c, m, dict(cnt)) for _t, c, m, cnt in rows)
        out['ConfigFolder\\' + table] = (data, note)
    ax.f.close()
    return out


def han_report(rel, data):
    """Chinese left in the produced file, split by 'inside a #{...} argument' (never displayed, keep) and 'visible'."""
    if rel.endswith('StrDictionary.txt'):
        vis = arg = 0
        for ln in data.split(b'\n')[2:]:
            ln = ln.rstrip(b'\r')
            if b'\t' not in ln:
                continue
            v = ln.split(b'\t', 1)[1].decode('utf-8', 'replace')
            if not HAN.search(v):
                continue
            if HAN.search(BRACE.sub('', v)):
                vis += 1
            else:
                arg += 1
        return 'rows with visible Han %d, rows whose Han is only a #{...} argument %d' % (vis, arg)
    nf, nr, kinds, cells, strings = ITX.parse(data)
    spec = ITX.DISPLAY[rel.split('\\')[-1]]
    vis = sum(1 for (r, c), b in strings.items() if c in spec and HAN.search(b.decode('utf-8', 'replace')))
    return 'display cells with Han %d of %d' % (vis, nr * len(spec))


def targets(rel):
    return [os.path.join(GEN, rel), os.path.join(DATA, rel)]


def cmd_plan(_args):
    built = build_all()
    for rel in sorted(built):
        data, note = built[rel]
        print('%s\n    %s\n    %s' % (rel, note, han_report(rel, data)))
        for p in targets(rel):
            old = open(p, 'rb').read() if os.path.exists(p) else None
            state = 'MISSING' if old is None else ('same' if old == data else 'differs (%d -> %d bytes)'
                                                   % (len(old), len(data)))
            print('    %-62s %s' % (os.path.relpath(p, ITX.REPO_MAIN), state))
    return built


def cmd_apply(args):
    built = build_all()
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    wrote = collections.Counter()
    for rel in sorted(built):
        data, note = built[rel]
        for p in targets(rel):
            if os.path.exists(p) and open(p, 'rb').read() == data:
                wrote['unchanged'] += 1
                continue
            os.makedirs(os.path.dirname(p), exist_ok=True)
            if os.path.exists(p) and not args.no_backup:
                bak = os.path.join(BACKUP, stamp, os.path.relpath(p, ASSETS))
                os.makedirs(os.path.dirname(bak), exist_ok=True)
                shutil.copy2(p, bak)
                wrote['backup'] += 1
            with open(p + '.part', 'wb') as f:
                f.write(data)
            os.replace(p + '.part', p)
            wrote['written'] += 1
            print('wrote %s (%d bytes)' % (os.path.relpath(p, ITX.REPO_MAIN), len(data)))
    print('apply: %s  backup suffix .bak-i18n-cy-%s' % (dict(wrote), stamp))
    cmd_verify(args, built)


def cmd_verify(_args, built=None):
    """Read every target back from disk and check it against a freshly derived build."""
    built = built or build_all()
    ax = open_config()
    names = {n.lower(): n for n, _ in ax.file_list()}
    bad = 0
    for rel in sorted(built):
        data, _note = built[rel]
        for p in targets(rel):
            disk = open(p, 'rb').read() if os.path.exists(p) else None
            ok = disk == data
            bad += 0 if ok else 1
            print('%-64s %s' % (os.path.relpath(p, ITX.REPO_MAIN), 'OK' if ok else 'MISMATCH'))
        table = rel.split('\\')[-1]
        if table in ITX.DISPLAY:
            _, src = ax.payload_full(names[table.lower()], 64 << 20)
            disk = open(os.path.join(DATA, rel), 'rb').read()
            v = ITX.verify(table, src, disk)     # raises on a changed key/number cell
            print('    vs CY 3.71 original: key-string cells same %d, number cells same %d, display changed %d, '
                  'display still GBK %d' % (v['key_string_cells_same'], v['number_cells_same'],
                                            v['display_changed'], v['display_kept_gbk']))
        print('    %s' % han_report(rel, open(os.path.join(DATA, rel), 'rb').read()))
    ax.f.close()
    print('verify: %s' % ('OK - every target matches the derived build' if not bad else '%d MISMATCH' % bad))
    if bad:
        raise SystemExit(1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('mode', choices=('plan', 'apply', 'verify'))
    ap.add_argument('--no-backup', action='store_true')
    args = ap.parse_args()
    {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify}[args.mode](args)


if __name__ == '__main__':
    main()
