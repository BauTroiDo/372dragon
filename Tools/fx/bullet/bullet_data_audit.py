# -*- coding: utf-8 -*-
"""bullet-fx (19/09/2026): KIEM DU LIEU DAN — Bullet.txt x SkillTemplate_V1.txt x all.effect.

CAU HOI (de bai muc 3): "Du lieu dan co du khong? Hang nao tro toi hieu ung/model khong ton tai?"

CACH DOC (KHONG SUA GI — chi doc):
  - Bullet.txt   : DBC 00CCBBDD, 16 cot (_DBC_BULLET_DATA, Src/Shared/Common/GameStruct_Skill.h:90)
                   [0]ID [1]ContrailType [2]ContrailParam [3]FlyEffect [4]FlySound [5]Speed
                   [6]HitEffect [7]HitSound [8]HitEffectLocator [13]Desc [14]Flag
  - SkillTemplate_V1.txt: DBC 00CCBBDD, cot [31] = m_nBulletID, [32] = m_pszBulletSendLocator,
                   [0] ID, [2] ten, [22] SelectType
  - all.effect   : danh sach ten template hieu ung cua engine (GBK — doc o muc BYTE)

DINH NGHIA DUNG DE DEM (bat buoc neu ro, luat do dem cua du an):
  "skill co dan"      = SkillData[31] != -1 VA co dong Bullet.txt voi ID do
  "dan co hinh bay"   = Bullet.txt[3] (FlyEffect) khac rong
  "hinh bay ton tai"  = ten o [3] nam trong tap ten template doc tu all.effect
  Dan ContrailType=2 (NONE) KHONG bay -> khong can FlyEffect; dem rieng.

DUNG:
  python -B Tools/fx/bullet/bullet_data_audit.py --out <file>.json [--data <ConfigFolder>]
"""
import argparse
import hashlib
import json
import os
import struct
import sys

MAGIC = b'\x00\xcc\xbb\xdd'
T_INT, T_FLOAT, T_STRING = 0, 1, 2
HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
DATA = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder')

BULLET_COLS = ['ID', 'ContrailType', 'ContrailParam', 'FlyEffect', 'FlySound', 'Speed',
               'HitEffect', 'HitSound', 'HitEffectLocator', 'unk9', 'unk10', 'unk11', 'unk12',
               'Desc', 'Flag', 'unk15']
CONTRAIL = {0: 'BEELINE', 1: 'PARABOLA', 2: 'NONE'}
SKILL_BULLET_COL = 31
SKILL_LOCATOR_COL = 32
SKILL_NAME_COL = 2
SKILL_SELECT_COL = 22


def dbc_read(path):
    b = open(path, 'rb').read()
    if b[:4] != MAGIC:
        sys.exit('%s khong phai DBC 00CCBBDD' % path)
    nF, nR, pool_size = struct.unpack_from('<3I', b, 4)
    types = list(struct.unpack_from('<%dI' % nF, b, 16))
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]
    if len(pool) != pool_size:
        sys.exit('%s: pool %d byte != header %d' % (path, len(pool), pool_size))
    return {'nF': nF, 'nR': nR, 'types': types, 'cells': cells, 'pool': pool,
            'sha256': hashlib.sha256(b).hexdigest(), 'byte': len(b), 'path': path}


def s_at(pool, o):
    if o >= len(pool):
        o = 0
    e = pool.find(b'\0', o)
    return bytes(pool[o:e if e >= 0 else len(pool)])


def dec(bs):
    try:
        return bs.decode('utf-8')
    except UnicodeDecodeError:
        return bs.decode('gbk', 'replace')


def row(d, r):
    """Gia tri Python cua hang r theo kieu cot."""
    out = []
    for c in range(d['nF']):
        v = d['cells'][r * d['nF'] + c]
        t = d['types'][c]
        if t == T_INT:
            out.append(struct.unpack('<i', struct.pack('<I', v))[0])
        elif t == T_FLOAT:
            out.append(round(struct.unpack('<f', struct.pack('<I', v))[0], 4))
        else:
            out.append(dec(s_at(d['pool'], v)))
    return out


def effect_names(data_dir):
    """Ten template hieu ung tu all.effect (doc BYTE, khong ghi gi).

    Dinh dang: cac khoi `<ten>\n{ ... }`. Chi lay dong dau moi khoi o muc goc.
    """
    path = None
    for cand in (os.path.join(data_dir, '..', 'EffectFolder', 'all.effect'),
                 os.path.join(data_dir, 'all.effect')):
        if os.path.isfile(cand):
            path = os.path.abspath(cand)
            break
    if path is None:
        return None, set()
    raw = open(path, 'rb').read()
    # Dinh dang that (do 19/09): khoi goc mo bang dong `effect <ten>` roi `{ ... }`.
    # Ten co the co chu Han => pool all.effect la GBK, giai ma theo dec().
    names = set()
    for line in raw.split(b'\n'):
        s = line.strip()
        if s.startswith(b'effect ') or s.startswith(b'effect\t'):
            nm = s[7:].split(b'{')[0].strip()
            if nm:
                names.add(dec(nm))
    return path, names


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--data', default=DATA)
    ap.add_argument('--out', required=True)
    a = ap.parse_args()

    bullets = dbc_read(os.path.join(a.data, 'Bullet.txt'))
    skills = dbc_read(os.path.join(a.data, 'SkillTemplate_V1.txt'))
    eff_path, eff_names = effect_names(a.data)

    brows = {}
    for r in range(bullets['nR']):
        v = row(bullets, r)
        brows[v[0]] = dict(zip(BULLET_COLS, v))

    # --- skills that reference a bullet
    skill_ref = []
    for r in range(skills['nR']):
        v = row(skills, r)
        bid = v[SKILL_BULLET_COL]
        if bid == -1:
            continue
        skill_ref.append({'skill': v[0], 'name': v[SKILL_NAME_COL], 'bullet': bid,
                          'select_type': v[SKILL_SELECT_COL],
                          'send_locator': v[SKILL_LOCATOR_COL],
                          'bullet_row_exists': bid in brows})

    used = sorted({s['bullet'] for s in skill_ref})
    missing_rows = sorted({s['bullet'] for s in skill_ref if not s['bullet_row_exists']})

    # --- per-bullet effect health
    def eff_ok(name):
        if not name:
            return None          # o rong
        if eff_names is None:
            return 'unknown'     # khong doc duoc all.effect
        return name in eff_names

    audit = []
    for bid, b in sorted(brows.items()):
        audit.append({
            'id': bid,
            'contrail': CONTRAIL.get(b['ContrailType'], 'INVALID:%d' % b['ContrailType']),
            'speed': b['Speed'],
            'fly_effect': b['FlyEffect'], 'fly_effect_found': eff_ok(b['FlyEffect']),
            'hit_effect': b['HitEffect'], 'hit_effect_found': eff_ok(b['HitEffect']),
            'fly_sound': b['FlySound'], 'hit_sound': b['HitSound'],
            'hit_locator': b['HitEffectLocator'], 'desc': b['Desc'],
            'used_by_skills': sum(1 for s in skill_ref if s['bullet'] == bid),
        })

    flies = [x for x in audit if x['contrail'] in ('BEELINE', 'PARABOLA')]
    flies_used = [x for x in flies if x['used_by_skills'] > 0]
    out = {
        'schema': 1,
        'nguon': {
            'bullet': {'path': bullets['path'], 'sha256': bullets['sha256'],
                       'cols': bullets['nF'], 'rows': bullets['nR']},
            'skill': {'path': skills['path'], 'sha256': skills['sha256'],
                      'cols': skills['nF'], 'rows': skills['nR']},
            'all_effect': {'path': eff_path,
                           'templates': (len(eff_names) if eff_names is not None else None)},
        },
        'tong': {
            'bullet_rows': len(brows),
            'skills_with_bullet': len(skill_ref),
            'distinct_bullets_used': len(used),
            'bullet_ids_missing_row': missing_rows,
            'bullets_contrail_fly': len(flies),
            'bullets_contrail_fly_used_by_skill': len(flies_used),
            'bullets_contrail_none': len([x for x in audit if x['contrail'] == 'NONE']),
            'fly_rows_with_empty_flyeffect': len([x for x in flies if not x['fly_effect']]),
            'fly_rows_flyeffect_missing_template':
                len([x for x in flies if x['fly_effect'] and x['fly_effect_found'] is False]),
            'rows_hiteffect_missing_template':
                len([x for x in audit if x['hit_effect'] and x['hit_effect_found'] is False]),
        },
        'skills': skill_ref,
        'bullets': audit,
    }
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    with open(a.out, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print(json.dumps(out['tong'], ensure_ascii=False, indent=1))
    print('-> %s' % a.out)


if __name__ == '__main__':
    main()
