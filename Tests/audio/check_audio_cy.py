"""CYS-AUDIO (audio-cy 15/09/2026): offline check of the CY 3.71 sound data the client plays
(Docs/specs/game/audio-cy_vi.md).

- SoundInfo.txt / SoundUI.txt are CY binary DBC (00CCBBDD) with the column types the client assumes (I S S / I I S).
- every SoundUI row names a SoundInfo id; the login music 2110 and the background music of the scenes the replay and
  the user visit (0 Lac Duong, 1 To Chau, 2 Dai Ly, 6 Vo Luong Son) exist in SoundInfo and as files in SoundFolder;
- the <scene>.esd of those scenes have >= 20 columns (CY throws below) and every sound id of them resolves to a file;
- Src carries the CYS-AUDIO hooks the spec lists.
File names in SoundInfo are GBK bytes; on disk they are the same bytes read as cp1252 (Assets were copied that way),
so both spellings are tried. A file that is absent is reported (the client logs and skips it); the check fails only
for the ids above.
usage: python Tests/audio/check_audio_cy.py [--data Assets/CanonicalCY/Data] [--src Src]
"""
import argparse
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))


def load_dbc(path):
    b = open(path, 'rb').read()
    magic, nf, nr, ss = struct.unpack_from('<IIII', b, 0)
    if magic != 0xDDBBCC00:
        raise ValueError('%s: not a binary DBC (magic %08x)' % (path, magic))
    types = struct.unpack_from('<%dI' % nf, b, 16)
    off = 16 + 4 * nf
    cells = struct.unpack_from('<%di' % (nf * nr), b, off)
    sb = b[off + 4 * nf * nr:off + 4 * nf * nr + ss]
    rows = []
    for r in range(nr):
        row = []
        for c in range(nf):
            v = cells[r * nf + c]
            if types[c] == 2:
                e = sb.find(b'\0', v)
                row.append(sb[v:e])
            else:
                row.append(v)
        rows.append(row)
    return list(types), rows


def index_folder(folder):
    idx = {}
    for dp, _, files in os.walk(folder):
        for f in files:
            rel = os.path.relpath(os.path.join(dp, f), folder).replace('/', '\\').lower()
            idx[rel] = True
    return idx


def sound_file_exists(idx, raw):
    names = []
    for enc in ('cp1252', 'gbk', 'latin-1'):
        try:
            names.append(raw.decode(enc).lower())
        except UnicodeDecodeError:
            pass
    return any(n in idx for n in names)


def read_esd(path):
    lines = open(path, 'rb').read().decode('gbk', 'replace').splitlines()
    types = lines[0].split('\t')
    rows = []
    for ln in lines[2:]:
        cells = ln.split('\t')
        if not cells or not cells[0].strip().lstrip('-').isdigit():
            continue
        rows.append(cells)
    return types, rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--data', default=os.path.join(ROOT, 'Assets', 'CanonicalCY', 'Data'))
    ap.add_argument('--src', default=os.path.join(ROOT, 'Src'))
    a = ap.parse_args()
    if not os.path.isdir(a.data):
        a.data = r'C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data'
    fails = []
    cfg = os.path.join(a.data, 'ConfigFolder')
    sfolder = os.path.join(a.data, 'SoundFolder')
    idx = index_folder(sfolder)

    t_info, info = load_dbc(os.path.join(cfg, 'SoundInfo.txt'))
    t_ui, ui = load_dbc(os.path.join(cfg, 'SoundUI.txt'))
    if t_info != [0, 2, 2]:
        fails.append('SoundInfo column types %s != I S S' % t_info)
    if t_ui != [0, 0, 2]:
        fails.append('SoundUI column types %s != I I S' % t_ui)
    by_id = {r[0]: r[1] for r in info}
    present = sum(1 for r in info if sound_file_exists(idx, r[1]))
    print('SoundInfo rows=%d files present=%d absent=%d; SoundUI rows=%d; SoundFolder files=%d' % (
        len(info), present, len(info) - present, len(ui), len(idx)))

    for r in ui:
        if r[1] not in by_id:
            fails.append('SoundUI row %d -> SoundInfo id %d missing' % (r[0], r[1]))
        elif not sound_file_exists(idx, by_id[r[1]]):
            print('  note: SoundUI row %d id %d file absent: %r' % (r[0], r[1], by_id[r[1]]))

    must = {2110: 'login music'}
    t_sc, scenes = load_dbc(os.path.join(cfg, 'SceneDefineEx.txt'))
    wanted_scenes = {0: 'Lac Duong', 1: 'To Chau', 2: 'Dai Ly', 6: 'Vo Luong Son'}
    esd_names = {}
    for r in scenes:
        if r[0] in wanted_scenes:
            must[r[8]] = 'scene %d %s background music' % (r[0], wanted_scenes[r[0]])
            esd_names[r[0]] = os.path.splitext(r[4].decode('ascii', 'replace'))[0] + '.esd'
    for sid, what in sorted(must.items()):
        if sid not in by_id:
            fails.append('%s: id %d not in SoundInfo' % (what, sid))
        elif not sound_file_exists(idx, by_id[sid]):
            fails.append('%s: id %d file %r absent' % (what, sid, by_id[sid]))
        else:
            print('OK %s id=%d file=%s' % (what, sid, by_id[sid].decode('gbk', 'replace')))

    for scene, name in sorted(esd_names.items()):
        path = None
        for sub in ('SceneFolder', 'Scene2Folder'):
            p = os.path.join(a.data, sub, name)
            if os.path.isfile(p):
                path = p
        if not path:
            print('  note: scene %d has no %s (no environment sounds)' % (scene, name))
            continue
        types, rows = read_esd(path)
        if len(types) < 20:
            fails.append('%s: %d columns < 20' % (name, len(types)))
            continue
        ids = set()
        region = {}
        for c in rows:
            for k in range(1, 5):
                if k < len(c) and c[k].strip() and int(c[k]) > 0:
                    ids.add(int(c[k]))
            rt = c[5].strip() if len(c) > 5 else ''
            region[rt] = region.get(rt, 0) + 1
        bad = [i for i in sorted(ids) if i not in by_id]
        absent = [i for i in sorted(ids) if i in by_id and not sound_file_exists(idx, by_id[i])]
        if bad:
            fails.append('%s: sound ids not in SoundInfo: %s' % (name, bad))
        print('OK scene %d %s rows=%d region_types=%s sound_ids=%d absent_files=%s' % (
            scene, name, len(rows), region, len(ids), absent))

    hooks = {
        os.path.join('Client', 'WXClient', 'Sound', 'CysAudio.cpp'): 'CYS-AUDIO',
        os.path.join('Client', 'WXClient', 'Sound', 'GMSoundSystem.cpp'): 'CYS-AUDIO',
        os.path.join('Client', 'WXClient', 'World', 'CysSceneAudio.cpp'): 'CYS-AUDIO',
        os.path.join('Client', 'WXClient', 'Object', 'Surface', 'Obj_Bullet.cpp'): 'CYS-AUDIO',
        os.path.join('Client', 'WXClient', 'Object', 'Surface', 'Obj_Special.cpp'): 'CYS-AUDIO',
        os.path.join('Client', 'WXClient', 'Procedure', 'GameProcedure.cpp'): '_PlayUISoundIndexFunc',
    }
    for rel, needle in hooks.items():
        p = os.path.join(a.src, rel)
        if not os.path.isfile(p) or needle.encode() not in open(p, 'rb').read():
            fails.append('hook %s missing in %s' % (needle, rel))

    if fails:
        for f in fails:
            print('FAIL ' + f)
        return 1
    print('PASS audio-cy data + hooks')
    return 0


if __name__ == '__main__':
    sys.exit(main())
