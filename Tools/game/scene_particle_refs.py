# -*- coding: utf-8 -*-
"""CYS-PARTICLE: moi hieu ung hat ma mot `.Scene` yeu cau PHAI co trong `EffectFolder`.

Vi sao can: `Ogre::ParticleSystemManager::createSystem` NEM khi khong tim thay template
(`OgreParticleSystemManager.cpp:335`, `ERR_INVALIDPARAMS`). Truoc ban va `CYS-PARTICLE` trong
`WXSceneInfo.cpp`, mot cai ten sai trong mot tep canh = client CHET. Sau ban va, no chi con mat
mot hieu ung - nhung van la du lieu hong, va van phai bat duoc TRUOC khi nhap ban do.

    python Tools/game/scene_particle_refs.py                      # bang tom tat
    python Tools/game/scene_particle_refs.py --json out.json      # so lieu de doc bang may
    python Tools/game/scene_particle_refs.py --selftest           # phep kiem BIET TRUOT
    python Tools/game/scene_particle_refs.py --scene tangmen.Scene --scene gusu.scene

BA BAY DA SAP THAT, dung go bo:
 1. Ten trong `.Scene` la UTF-8, con `all.particle` la GBK. Khong chuyen ma thi bao THIEU ca 28.000
    tham chieu.
 2. CO HAI thuoc tinh, khong phai mot: `particle system name` (doi tuong `ParticleSystem`) va
    `weather.particle system name` (doi tuong `Enviroment`). Quet thieu ve thu hai bo sot 17 tep -
    dung nua nguy hiem hon, vi `Enviroment` duoc tao NGAY luc nap canh, truoc khung hinh dau tien.
 3. So khop phai la TEN KHOI day du, khong phai `in` tren van ban: `yanhuo_五周年彩炮` KHONG ton tai,
    chi co `yanhuo_五周年彩炮_01/_03/_06`; `boss_白帝_寒冰彻骨_陷阱_03` chi co ban `..._031` va mot
    dong `material` trung ten. Phep so long se bao ca ba la "CO".
"""
from __future__ import print_function

import argparse
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, '..', '..'))
DATA = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data')

# Doi chung DUONG / AM: phep kiem nao khong tra dung hai dong nay la phep kiem hong.
SELFTEST_PRESENT = 'cj_pubuB03'          # longta_0 cung yeu cau cai nay, va no CO that
SELFTEST_MISSING = 'cj_妖塔_方向雾_黄'   # cj_妖塔_方向雾_黄, da giet client that

RE_REF = re.compile(r'<Property\s+name="(weather\.particle system name|particle system name)"\s+value="([^"]*)"')
RE_OBJ = re.compile(r'<Object\b[^>]*type="([^"]+)"')
RE_TOKEN = re.compile(r'<Object\b[^>]*>|</Object>|' + RE_REF.pattern)


def read_templates(path):
    """Ten khoi cap cao nhat cua mot script Ogre particle/effect (tep luu GBK)."""
    txt = open(path, 'rb').read().decode('gbk', 'replace')
    names, pending, depth = set(), None, 0
    for line in txt.replace('\r\n', '\n').replace('\r', '\n').split('\n'):
        s = line.strip()
        if not s or s.startswith('//'):
            continue
        if s.startswith('{'):
            if depth == 0 and pending:
                names.add(pending)
            depth += s.count('{') - s.count('}')
            pending = None
            continue
        if s.startswith('}'):
            depth -= 1
            pending = None
            continue
        depth += s.count('{') - s.count('}')
        if depth == 0:
            n = s
            if n.startswith('particle_system '):
                n = n[len('particle_system '):].strip()
            pending = n
    return names


def load_templates(data_dir):
    eff = os.path.join(data_dir, 'EffectFolder')
    out, per_file = set(), {}
    for fn in sorted(os.listdir(eff)):
        p = os.path.join(eff, fn)
        if os.path.isfile(p):
            t = read_templates(p)
            per_file[fn] = len(t)
            out |= t
    return out, per_file


def scan_scene(path, templates):
    raw = open(path, 'rb').read()
    try:
        txt = raw.decode('utf-8')
    except UnicodeDecodeError:
        txt = raw.decode('gbk', 'replace')
    refs, missing, cur, idx = 0, {}, None, 0
    for m in RE_TOKEN.finditer(txt):
        s = m.group(0)
        if s.startswith('</Object'):
            cur = None
            continue
        if s.startswith('<Object'):
            idx += 1
            mm = RE_OBJ.match(s)
            cur = mm.group(1) if mm else '?'
            continue
        mm = RE_REF.match(s)
        if not mm or not mm.group(2):
            continue
        refs += 1
        if mm.group(2) not in templates:
            missing.setdefault(mm.group(2), []).append(
                {'objtype': cur, 'prop': mm.group(1), 'obj_index': idx})
    return refs, missing


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--data', default=DATA, help='thu muc Data cua client (mac dinh: Assets/CanonicalCY/Data)')
    ap.add_argument('--scene', action='append', default=[], help='chi quet nhung tep nay (lap lai duoc)')
    ap.add_argument('--json', help='ghi ket qua day du ra tep JSON')
    ap.add_argument('--selftest', action='store_true', help='chay doi chung duong/am roi thoat')
    a = ap.parse_args(argv)

    templates, per_file = load_templates(a.data)
    scene_dir = os.path.join(a.data, 'SceneFolder')
    names = a.scene or sorted(f for f in os.listdir(scene_dir) if f.lower().endswith('.scene'))

    if a.selftest:
        ok = True
        if SELFTEST_PRESENT not in templates:
            print('SELFTEST FAIL: %s phai CO trong EffectFolder' % SELFTEST_PRESENT); ok = False
        if SELFTEST_MISSING in templates:
            print('SELFTEST FAIL: %s phai THIEU' % SELFTEST_MISSING); ok = False
        # doi chung 3: ten la tien to cua mot template khac PHAI bi tinh la thieu
        prefix = 'yanhuo_五周年彩炮'   # chi co ..._01/_03/_06
        if prefix in templates:
            print('SELFTEST FAIL: so khop dang long - %s khong phai mot template' % prefix); ok = False
        print('SELFTEST %s (%d template tu %s)' % ('OK' if ok else 'FAIL', len(templates), per_file))
        return 0 if ok else 1

    rows, total_refs = [], 0
    for fn in names:
        p = os.path.join(scene_dir, fn)
        if not os.path.isfile(p):
            print('bo qua (khong co tep): %s' % fn, file=sys.stderr)
            continue
        refs, missing = scan_scene(p, templates)
        total_refs += refs
        if missing:
            rows.append({'file': fn, 'refs': refs,
                         'missing': {k: len(v) for k, v in missing.items()},
                         'detail': missing})

    res = {'templates': len(templates), 'effect_folder': per_file,
           'scenes_scanned': len(names), 'refs_total': total_refs,
           'scenes_with_missing': rows}
    if a.json:
        with io.open(a.json, 'w', encoding='utf-8') as f:
            json.dump(res, f, ensure_ascii=False, indent=1)
        print('-> %s' % a.json)

    print('%d template - %d tep canh - %d tham chieu - %d tep THIEU'
          % (len(templates), len(names), total_refs, len(rows)))
    for r in rows:
        kinds = sorted({d['objtype'] for v in r['detail'].values() for d in v})
        print('  %-34s %-16s %s' % (r['file'], '/'.join(kinds), r['missing']))
    return 1 if rows else 0


if __name__ == '__main__':
    sys.exit(main())
