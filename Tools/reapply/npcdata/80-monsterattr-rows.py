# -*- coding: utf-8 -*-
"""npc-data (19/09/2026): THEM 84 dong NPC doi thoai vao
`Assets/CanonicalCY/Data/ConfigFolder/MonsterAttrExTable.txt` (DBC 00CCBBDD, 73 cot).

VI SAO CAN
  84 race ma SERVER khai la NPC doi thoai (`是否可以交互 = 1`) khong co dong nao trong DBC client.
  `CObject_PlayerNPC::OnDataChanged_RaceID` tra `GetCreatureAtt() == NULL` => TAT `OSF_RAY_QUERY`
  => tia chuot khong bat duoc => KHONG bam duoc bang bat ky cach nao, ke ca sau ban va
  `5164e247` cua `npc-interact`. Do that trong luot live cua `npc-interact`:
      npc id=179 race=56007 ten=Duong Tiem camp=8 canHandle=-99 ray_query=0 left=1(MCT_PLAYER_MOVETO)
  Nguon goc: dot `cs3c-tables` 14/09 gop 1.015 dong chi-GL (`cys_gl_only`) vao BANG SERVER
  nhung KHONG gop vao DBC CLIENT; DBC client van la ban CY 3.71 nguyen xi (28.968 dong).

CACH LAM — CHEP BAN SINH DOI, KHONG DICH 71 COT GL SANG 73 COT CY
  82/84 race co dong CY CUNG TEN (vd 56011 黄时雨 -> 17033). Dong moi CHEP NGUYEN 73 o cua dong do,
  chi ghi de 3 o: [0] = id moi, [5] = 是否可以交互 cua server, [70] = 阵营 cua server.
  Hai ca khong co ban sinh doi (56003 唐昱, 56007 杨渐) chon tay trong cung mon phai, cung vai tro.
  => MOI o (nhat la o MODEL) chac chan hop le trong khong gian CanonicalCY, va
  => STRING POOL KHONG DOI MOT BYTE (o STRING chi la offset, chep nguyen offset cua ban sinh doi).

VI SAO KHONG DUNG TEN MOI TRONG POOL
  Ten hien thi lay TU DAY, khong tu DBC: luot live do duoc `race 56007 ... ten=Duong Tiem` trong khi
  race 56007 KHONG CO dong DBC nao. (Neu sau nay muon ten DBC dung, phai noi chuoi GBK vao pool —
  o ten cua bang nay la BYTE GBK, xem `12-name-match2.py`: 路原 = c2 b7 d4 ad, ma chuoi do lai la
  UTF-8 HOP LE nen phep tra theo ten UTF-8 truot mat mot dong.)

CACH DUNG
  80-monsterattr-rows.py plan   [--rows F] [--dbc F]
  80-monsterattr-rows.py apply  [--rows F] [--dbc F] [--bak DIR] [--out F]
  80-monsterattr-rows.py verify [--rows F] [--dbc F] [--manifest F] [--out F]
  80-monsterattr-rows.py undo   [--rows F] [--dbc F] [--bak DIR] [--out F]
  80-monsterattr-rows.py build-manifest [--rows F] [--dbc F] [--manifest F]

`verify` KHONG dua vao ban sao luu (ban sao luu het han khi dot sau ghi de). No doi chieu voi
BANG KE trong git (`data/npc-data-manifest.json`) — 73 o da giai ma cua tung dong — nen tra loi
duoc "cac dong con du khong?" tren BAT KY file DBC nao.
"""
import argparse
import hashlib
import json
import os
import shutil
import struct
import sys
import time

MAGIC = b'\x00\xcc\xbb\xdd'
HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
DBC = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'MonsterAttrExTable.txt')
ROWS = os.path.join(HERE, 'data', 'npc-data-rows.json')
MANIFEST = os.path.join(HERE, 'data', 'npc-data-manifest.json')
BAK = os.path.join(CYS, 'Build', 'reapply-bak', 'npc-data')
COL_CAN, COL_CAMP = 5, 70


def dbc_read(path):
    b = open(path, 'rb').read()
    if b[:4] != MAGIC:
        sys.exit('%s khong phai DBC 00CCBBDD' % path)
    nF, nR, poolsz = struct.unpack_from('<3I', b, 4)
    types = list(struct.unpack_from('<%dI' % nF, b, 16))
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + 4 * nF * nR: off + 4 * nF * nR + poolsz]
    if len(pool) != poolsz:
        sys.exit('pool cut ngan: %d != %d' % (len(pool), poolsz))
    rows = [cells[r * nF:(r + 1) * nF] for r in range(nR)]
    return dict(types=types, rows=rows, pool=pool, nF=nF, sha=hashlib.sha256(b).hexdigest(), bytes=len(b))


def dbc_write(path, t):
    nF, nR = t['nF'], len(t['rows'])
    out = bytearray(MAGIC)
    out += struct.pack('<3I', nF, nR, len(t['pool']))
    out += struct.pack('<%dI' % nF, *t['types'])
    flat = []
    for r in t['rows']:
        flat.extend(r)
    out += struct.pack('<%dI' % (nF * nR), *flat)
    out += t['pool']
    tmp = path + '.tmp-npcdata'
    open(tmp, 'wb').write(bytes(out))
    os.replace(tmp, path)


def S(v):
    return struct.unpack('<i', struct.pack('<I', v))[0]


def U(v):
    return struct.unpack('<I', struct.pack('<i', v))[0]


def load_rows(p):
    d = json.load(open(p, encoding='utf-8'))
    if d.get('schema') != 1:
        sys.exit('rows JSON: schema != 1')
    return d


def expected_cells(t, plan_row):
    """73 o mong doi cho mot dong ke hoach, tinh tu ban sinh doi TRONG FILE DANG XET."""
    idx = {S(r[0]): i for i, r in enumerate(t['rows'])}
    src = plan_row['copy_from']
    if src not in idx:
        return None, 'khong tim thay ban sinh doi id=%d' % src
    cells = list(t['rows'][idx[src]])
    cells[0] = U(plan_row['id'])
    for k, v in (plan_row.get('set') or {}).items():
        cells[int(k)] = U(int(v))
    return cells, None


def cmd_plan(a):
    t, d = dbc_read(a.dbc), load_rows(a.rows)
    idx = {S(r[0]): i for i, r in enumerate(t['rows'])}
    them, sua, bo_qua, loi = [], [], [], []
    for pr in d['rows']:
        exp, err = expected_cells(t, pr)
        if err:
            loi.append((pr['id'], err)); continue
        if pr['id'] not in idx:
            them.append(pr['id'])
        elif t['rows'][idx[pr['id']]] == exp:
            bo_qua.append(pr['id'])
        else:
            sua.append(pr['id'])
    res = dict(dbc=a.dbc, sha_truoc=t['sha'], so_dong_truoc=len(t['rows']), pool=len(t['pool']),
               them=them, sua=sua, bo_qua=bo_qua, loi=loi,
               so_dong_sau=len(t['rows']) + len(them), pool_sau=len(t['pool']))
    print(json.dumps(res, indent=1, ensure_ascii=False))
    return res


def cmd_apply(a):
    t, d = dbc_read(a.dbc), load_rows(a.rows)
    os.makedirs(a.bak, exist_ok=True)
    stamp = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
    bakf = os.path.join(a.bak, 'MonsterAttrExTable.%s.bak' % stamp)
    shutil.copy2(a.dbc, bakf)
    idx = {S(r[0]): i for i, r in enumerate(t['rows'])}
    them = sua = bo_qua = 0
    for pr in d['rows']:
        exp, err = expected_cells(t, pr)
        if err:
            sys.exit('DUNG, khong ghi gi: %s' % err)
        if pr['id'] in idx:
            if t['rows'][idx[pr['id']]] == exp:
                bo_qua += 1
            else:
                t['rows'][idx[pr['id']]] = exp; sua += 1
        else:
            t['rows'].append(exp); them += 1
            idx[pr['id']] = len(t['rows']) - 1
    t['rows'].sort(key=lambda r: S(r[0]))
    pool_truoc = t['pool']
    dbc_write(a.dbc, t)
    t2 = dbc_read(a.dbc)
    ok = t2['pool'] == pool_truoc
    res = dict(backup=bakf, them=them, sua=sua, bo_qua=bo_qua,
               so_dong=len(t2['rows']), pool_khong_doi=ok, sha_sau=t2['sha'])
    if not ok:
        shutil.copy2(bakf, a.dbc)
        sys.exit('POOL BI DOI -> da tra lai ban sao luu. %s' % json.dumps(res))
    if a.out:
        json.dump(res, open(a.out, 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
    print(json.dumps(res, indent=1, ensure_ascii=False))
    return res


def cmd_build_manifest(a):
    t, d = dbc_read(a.dbc), load_rows(a.rows)
    idx = {S(r[0]): i for i, r in enumerate(t['rows'])}
    man = dict(schema=1, dot=d.get('dot'), bang=d.get('bang'), nF=t['nF'], rows={})
    thieu = []
    for pr in d['rows']:
        if pr['id'] not in idx:
            thieu.append(pr['id']); continue
        man['rows'][str(pr['id'])] = [S(v) for v in t['rows'][idx[pr['id']]]]
    if thieu:
        sys.exit('DBC chua co cac dong %s -> chay `apply` truoc khi `build-manifest`' % thieu[:5])
    os.makedirs(os.path.dirname(a.manifest), exist_ok=True)
    json.dump(man, open(a.manifest, 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
    print('bang ke: %d dong x %d o -> %s' % (len(man['rows']), t['nF'], a.manifest))


def cmd_verify(a):
    t, d = dbc_read(a.dbc), load_rows(a.rows)
    idx = {S(r[0]): i for i, r in enumerate(t['rows'])}
    ids = [S(r[0]) for r in t['rows']]
    inv = dict(so_cot=t['nF'], cot0_tang_dan=all(ids[i] < ids[i + 1] for i in range(len(ids) - 1)),
               so_id_trung=len(ids) - len(set(ids)), pool_ket_thuc_NUL=(t['pool'][-1:] == b'\0'))
    mat, lech = [], []
    man = None
    if os.path.exists(a.manifest):
        man = json.load(open(a.manifest, encoding='utf-8'))
    for pr in d['rows']:
        i = pr['id']
        if i not in idx:
            mat.append(i); continue
        got = [S(v) for v in t['rows'][idx[i]]]
        if man and str(i) in man['rows']:
            want = man['rows'][str(i)]
        else:
            exp, err = expected_cells(t, pr)
            want = [S(v) for v in exp] if exp else None
        if want is not None and got != want:
            lech.append(dict(id=i, khac=[(k, want[k], got[k]) for k in range(len(want)) if want[k] != got[k]][:8]))
    # doc lai bang bo doc doc lap (mo phong TLBB_DBC.cpp)
    sys.path.insert(0, os.path.join(CYS, 'Tools', 'game'))
    from dbc_inventory import Table
    tb = Table(a.dbc)
    doc_lai = dict(records=tb.records, fields=len(tb.types))
    res = dict(dbc=a.dbc, sha=t['sha'], so_dong=len(t['rows']), pool=len(t['pool']),
               bang_ke=('co' if man else 'CHUA CO (so voi ban sinh doi trong chinh file)'),
               so_MAT=len(mat), mat=mat, so_LECH=len(lech), lech=lech,
               bat_bien=inv, doc_lai=doc_lai,
               ket_luan='DAT' if not mat and not lech and inv['cot0_tang_dan']
                        and inv['so_id_trung'] == 0 and inv['pool_ket_thuc_NUL'] else 'HONG')
    if a.out:
        json.dump(res, open(a.out, 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
    print(json.dumps(res, indent=1, ensure_ascii=False))
    return 0 if res['ket_luan'] == 'DAT' else 1


def cmd_undo(a):
    """Chi tra lai ban sao luu NAO ma 'ban sao luu + ke hoach nay' = file hien tai TUNG BYTE."""
    d = load_rows(a.rows)
    cur = open(a.dbc, 'rb').read()
    cands = sorted(os.listdir(a.bak)) if os.path.isdir(a.bak) else []
    for name in reversed(cands):
        p = os.path.join(a.bak, name)
        t = dbc_read(p)
        idx = {S(r[0]): i for i, r in enumerate(t['rows'])}
        okplan = True
        for pr in d['rows']:
            exp, err = expected_cells(t, pr)
            if err:
                okplan = False; break
            if pr['id'] in idx:
                t['rows'][idx[pr['id']]] = exp
            else:
                t['rows'].append(exp); idx[pr['id']] = len(t['rows']) - 1
        if not okplan:
            continue
        t['rows'].sort(key=lambda r: S(r[0]))
        tmp = a.dbc + '.chk-npcdata'
        dbc_write(tmp, t)
        same = open(tmp, 'rb').read() == cur
        os.remove(tmp)
        if same:
            shutil.copy2(p, a.dbc)
            print(json.dumps(dict(hoan_tac='DA', tu=p), indent=1, ensure_ascii=False))
            return 0
    print(json.dumps(dict(hoan_tac='TU CHOI',
                          ly_do='khong ban sao luu nao + ke hoach = file hien tai; file da bi dot khac ghi de',
                          da_thu=cands), indent=1, ensure_ascii=False))
    return 1


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('plan', 'apply', 'verify', 'undo', 'build-manifest'):
        p = sub.add_parser(name)
        p.add_argument('--dbc', default=DBC)
        p.add_argument('--rows', default=ROWS)
        p.add_argument('--bak', default=BAK)
        p.add_argument('--manifest', default=MANIFEST)
        p.add_argument('--out')
    a = ap.parse_args()
    fn = {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify, 'undo': cmd_undo,
          'build-manifest': cmd_build_manifest}[a.cmd]
    r = fn(a)
    sys.exit(r if isinstance(r, int) else 0)


if __name__ == '__main__':
    main()
