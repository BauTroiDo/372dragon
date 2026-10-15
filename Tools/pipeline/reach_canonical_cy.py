"""reach_canonical_cy.py - name reachability of Assets/CanonicalCY/Data with the engine's resource index rules.

Uses Tools/game/stage_game.py (Location, check_references: OGRE index simulation, GBK bytes read as cp1252). Resource
layout = the viewer/game layout extended to the CY folders (Model1-8, Material1-8, Scene + Scene2).
Output: <out>/reach_canonical_cy.json (counts, per-extension, examples; the per-name status table is dropped).
Usage: reach_canonical_cy.py --out <dir>
"""
import argparse
import json
import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[0] / 'game'))
import stage_game as SG  # noqa: E402

DATA = Path(r'C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data')


def layout():
    rows = [('Bootstrap', 'OgreCore.zip', 'Zip'), ('Bootstrap', 'MaterialTemplates.zip', 'Zip'),
            ('General', 'EffectFolder', 'FileSystem')]
    rows += [('General', f'Model{n}Folder', 'FileSystem') for n in ('', 2, 3, 4, 5, 6, 7, 8)]
    rows += [('General', 'InterfaceFolder', 'FileSystem')]
    rows += [('General', f'Material{n}Folder', 'FileSystem') for n in ('', 2, 3, 4, 5, 6, 7, 8)]
    rows += [('General', 'SoundFolder', 'FileSystem'), ('General', 'ConfigFolder', 'FileSystem'),
             ('Brushes', 'BrushesFolder', 'FileSystem'), ('Scene', 'SceneFolder', 'FileSystem'),
             ('Scene', 'Scene2Folder', 'FileSystem')]
    return [SG.Location(g, t, DATA / p, t == 'FileSystem', 'CanonicalCY/Data/' + p) for g, p, t in rows
            if (DATA / p).exists()]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    args = ap.parse_args()
    res = SG.check_references(layout())
    res.pop('status', None)
    os.makedirs(args.out, exist_ok=True)
    with open(os.path.join(args.out, 'reach_canonical_cy.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: res[k] for k in ('names', 'cjk_files_on_disk', 'source_files')}, ensure_ascii=False, indent=1))


if __name__ == '__main__':
    main()
