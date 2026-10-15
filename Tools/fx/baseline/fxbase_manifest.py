#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CYS-FXBASE: (re)build manifest.json of a run directory: sha256 + size of every PNG, of the binaries and the override
table of the side that produced it, and the camera the run used. Determinism evidence for both sides.

usage: fxbase_manifest.py <run dir> [<run dir> ...]
"""
import hashlib
import json
import os
import re
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
CY = os.path.join(ROOT, 'Build', 're', 'fx-cy-baseline', 'CYGame')
STAGE = os.path.join(ROOT, 'Build', 'world-gui', 'stage-fxbase-3')


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def build(run_dir):
    run_dir = os.path.abspath(run_dir)
    side = 'cy' if os.path.basename(os.path.dirname(run_dir)) == 'cy' else 'ours'
    m = {'run': run_dir, 'side': side, 'shots': []}
    for f in sorted(os.listdir(run_dir)):
        if f.lower().endswith('.png'):
            p = os.path.join(run_dir, f)
            m['shots'].append({'name': f, 'sha256': sha(p), 'bytes': os.path.getsize(p)})
    if side == 'cy':
        for name in ('Bin64/Game.exe', 'Bin64/Render.dll', 'Bin64/OgreMain.dll', 'FxBase/ImpactSEData_V1.txt', 'Bin/FairyResources.cfg'):
            p = os.path.join(CY, name)
            if os.path.exists(p):
                m[name] = sha(p)
        cam = os.path.join(run_dir, 'cam-c0.json')
        if os.path.exists(cam):
            c = json.load(open(cam, encoding='utf-8')).get('candidates') or []
            if c:
                m['camera'] = {k: c[0][k] for k in ('eye', 'orbit_target', 'orbit_distance', 'pitch_down_deg', 'yaw_deg', 'proj_fovy_deg')}
    else:
        stage = STAGE
        rj = os.path.join(run_dir, 'run.json')
        if os.path.exists(rj):
            try:
                stage = os.path.dirname(os.path.dirname(json.load(open(rj, encoding='utf-8-sig'))['command'].split(' -fl')[0]))
            except Exception:  # noqa: BLE001
                pass
        m['stage'] = stage
        for name in ('Bin64/Game.exe', 'Bin64/Render.dll', 'Bin64/OgreMain.dll', 'Overlay/Post/ConfigFolder/ImpactSEData_V1.txt'):
            p = os.path.join(stage, name)
            if os.path.exists(p):
                m[name] = sha(p)
        log = os.path.join(run_dir, 'WXClient.log')
        if os.path.exists(log):
            for line in open(log, encoding='utf-8', errors='replace'):
                mm = re.search(r'CYS camera: scenario set .*dir_deg=([\d.\-]+) dist_m=([\d.]+) zoom=([\d.\-]+).*eye=\(([^)]*)\) look=\(([^)]*)\)', line)
                if mm:
                    m['camera'] = {'dir_deg': float(mm.group(1)), 'dist_m': float(mm.group(2)), 'zoom': float(mm.group(3)), 'eye': mm.group(4), 'look': mm.group(5)}
                    break
    with open(os.path.join(run_dir, 'manifest.json'), 'w', encoding='utf-8') as f:
        json.dump(m, f, ensure_ascii=False, indent=1)
    print('%s: %d PNG, %s' % (run_dir, len(m['shots']), 'camera ' + json.dumps(m.get('camera')) if m.get('camera') else 'no camera'))


if __name__ == '__main__':
    for d in sys.argv[1:]:
        build(d)
