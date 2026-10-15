# -*- coding: utf-8 -*-
"""NOI MUC VAT LIEU GL -> CY `all.material` (+ chep texture kem theo) O MUC BYTE.

VI SAO CO CONG CU NAY
  `Tools/game/scene_import_gl.py` co chu dich TU CHOI moi ban do con thieu muc trong
  `all.material` / `all.particle` (nhom `kho`, 48 ban do). Do la quyet dinh dung o thoi diem do:
  hai tep ay tung pha 60.161 vat lieu khi bi doc bang errors='replace' roi ghi de.
  Cong cu nay mo dung canh cua ay va CHI canh cua ay, voi rang buoc chat hon ban da lam hong:

  R1. KHONG BAO GIO giai ma roi ghi lai ca tep. Doc `rb`, noi BYTE, ghi `wb`. Het.
  R2. KHONG BAO GIO sua/xoa mot khoi da co. Chi NOI VAO CUOI. Ten da co => BO QUA.
  R3. Sao luu truoc khi ghi. Sau khi ghi, DOC LAI TU DIA va kiem 6 dieu; truot mot dieu =>
      tra lai ban sao luu ngay trong cung lan chay.
  R4. Nhanh GL (`Assets/Canonical`) CHI DOC.
  R5. Moi tep/khoi nhap deu ghi ke khai (nguon, sha256, ngay) — dieu kien nguoi dung dat ra 17/09.

CACH DUNG
  80-mat-append.py plan   --rows data/<ten>.json
  80-mat-append.py apply  --rows data/<ten>.json --bak Build/reapply-bak/maps-kho48 [--that]
  80-mat-append.py verify --rows data/<ten>.json
  80-mat-append.py undo   --rows data/<ten>.json --bak <thu muc sao luu> [--that]

`--that` moi thuc su ghi; khong co `--that` la chay kho (in ra se lam gi).

DINH DANG data/<ten>.json
  {"dot": "...", "muc": [{"map": "songliao",
                          "material": ["<ten GBK>", ...],
                          "nguon": "GL"}]}
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import time

CYS = os.path.join('C:' + os.sep, 'TLBB', '085', 'CY-Source')
CY_DATA = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data')
GL_DATA = os.path.join(CYS, 'Assets', 'Canonical', 'Data')
CY_MAT = os.path.join(CY_DATA, 'MaterialFolder', 'all.material')
GL_MAT = os.path.join(GL_DATA, 'MaterialFolder', 'all.material')
MAT_DIRS = ['MaterialFolder'] + ['Material%dFolder' % i for i in range(2, 9)]
LOGDIR = os.path.join(CYS, 'Build', 'Logs', '2026-09-19-maps-kho48')
MANIFEST = os.path.join(LOGDIR, 'manifest-material.jsonl')
BS = chr(92)

RE_HEAD = re.compile(br'(?m)^material[ \t]+([^\r\n]*?)[ \t]*(?:\r?\n|$)')
RE_TEX = re.compile(br'(?m)^[ \t]*texture[ \t]+([^\r\n]+?)[ \t\r]*$')
RE_ALIAS = re.compile(br'(?m)^[ \t]*set_texture_alias[ \t]+<[^>]*>[ \t]+([^\r\n]+?)[ \t\r]*$')


# ------------------------------------------------------------------ ten tep GBK-as-cp1252
def ten_that(n):
    try:
        return n.encode('cp1252').decode('gbk')
    except (UnicodeEncodeError, UnicodeDecodeError):
        return None


def ten_dia(t):
    try:
        return t.encode('gbk').decode('cp1252')
    except (UnicodeEncodeError, UnicodeDecodeError):
        return None


def rec_index(bases):
    out = {}
    for base in bases:
        if not os.path.isdir(base):
            continue
        for dp, dn, fn in os.walk(base):
            rel = os.path.relpath(dp, base)
            parts = [] if rel == '.' else rel.split(os.sep)
            tp, ok = [], True
            for p in parts:
                t = ten_that(p)
                if t is None:
                    ok = False
                    break
                tp.append(t)
            if not ok:
                continue
            pre = ('/'.join(tp) + '/') if tp else ''
            for f in fn:
                t = ten_that(f)
                if t is not None:
                    out.setdefault((pre + t).lower(), os.path.join(dp, f))
    return out


def sha256b(b):
    return hashlib.sha256(b).hexdigest()


def sha256f(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


# ------------------------------------------------------------------ doc khoi o muc byte
def khoi(path):
    """[(ten, start, end, bytes)] — end la start cua khoi ke tiep (giu nguyen byte phan cach)."""
    b = open(path, 'rb').read()
    heads = [(m.start(), m.group(1)) for m in RE_HEAD.finditer(b)]
    out = []
    for i, (s, raw) in enumerate(heads):
        e = heads[i + 1][0] if i + 1 < len(heads) else len(b)
        ten = raw.split(b':', 1)[0].strip()
        out.append((ten, s, e, b[s:e]))
    return b, out


def bang_ten(ks):
    d = {}
    for (ten, s, e, blk) in ks:
        d.setdefault(ten, []).append(blk)
    return d


def tex_cua_khoi(blk):
    """Ten tep texture that (cu phap Ogre `texture <ten> [kieu] [mipmap]`)."""
    out = set()
    raw = [m.group(1) for m in RE_TEX.finditer(blk)]
    raw += [m.group(1) for m in RE_ALIAS.finditer(blk)]
    for x in raw:
        if not x.split():
            continue
        t = x.decode('gbk', 'replace').split()[0]
        if not t or t.startswith('<') or '.' not in t.rsplit('/', 1)[-1]:
            continue
        out.add(t)
    return out


# ------------------------------------------------------------------ ke hoach
def lam_ke_hoach(rows):
    gl_b, gl_ks = khoi(GL_MAT)
    cy_b, cy_ks = khoi(CY_MAT)
    gl_t, cy_t = bang_ten(gl_ks), bang_ten(cy_ks)
    cy_tep = rec_index([os.path.join(CY_DATA, d) for d in MAT_DIRS])
    gl_tep = rec_index([os.path.join(GL_DATA, d) for d in MAT_DIRS])

    kh = {'CY_truoc': {'byte': len(cy_b), 'sha256': sha256b(cy_b), 'so_khoi': len(cy_ks),
                       'so_ten': len(cy_t)},
          'GL': {'byte': len(gl_b), 'sha256': sha256b(gl_b), 'so_khoi': len(gl_ks)},
          'muc': [], 'noi': [], 'tep': [], 'loi': []}
    da_xep = set()
    for m in rows['muc']:
        r = {'map': m['map'], 'them_material': [], 'da_co': [], 'khong_co_o_GL': [],
             'them_texture': [], 'texture_da_co': [], 'texture_khong_co_o_GL': []}
        for ten_u in m['material']:
            tb = ten_u.encode('gbk')
            if tb in cy_t:
                r['da_co'].append(ten_u)
                continue
            if tb not in gl_t:
                r['khong_co_o_GL'].append(ten_u)
                kh['loi'].append('GL khong co material %s' % ten_u)
                continue
            if tb in da_xep:
                r['da_co'].append(ten_u)
                continue
            if len(gl_t[tb]) != 1:
                kh['loi'].append('GL co %d khoi trung ten %s' % (len(gl_t[tb]), ten_u))
                continue
            blk = gl_t[tb][0]
            da_xep.add(tb)
            r['them_material'].append(ten_u)
            kh['noi'].append({'map': m['map'], 'ten': ten_u, 'byte': len(blk),
                              'sha256_khoi': sha256b(blk), 'blk': blk})
            for t in sorted(tex_cua_khoi(blk)):
                k = t.replace(BS, '/').lower()
                if k in cy_tep:
                    r['texture_da_co'].append(t)
                    continue
                src = gl_tep.get(k)
                if not src:
                    r['texture_khong_co_o_GL'].append(t)
                    kh['loi'].append('GL khong co texture %s (material %s)' % (t, ten_u))
                    continue
                tag = os.path.relpath(src, GL_DATA).split(os.sep)[0]
                rel = os.path.dirname(k)
                dia_rel = os.sep.join(filter(None, [ten_dia(p) or p for p in rel.split('/')]))
                dst = os.path.join(CY_DATA, tag, dia_rel, os.path.basename(src))
                if os.path.exists(dst):
                    r['texture_da_co'].append(t)
                    continue
                r['them_texture'].append(t)
                kh['tep'].append({'map': m['map'], 'ten': t, 'nguon_GL': src, 'dich_CY': dst,
                                  'material': ten_u})
        kh['muc'].append(r)
    kh['so_noi'] = len(kh['noi'])
    kh['so_tep'] = len(kh['tep'])
    kh['byte_noi'] = sum(x['byte'] for x in kh['noi'])
    return kh


def in_ke_hoach(kh):
    d = dict(kh)
    d['noi'] = [{k: v for k, v in x.items() if k != 'blk'} for x in kh['noi']]
    return d


# ------------------------------------------------------------------ ghi
def ap_dung(kh, bak_dir, that_su):
    ket = {'that_su': that_su, 'so_noi': kh['so_noi'], 'so_tep': kh['so_tep']}
    if kh['loi']:
        ket['dung_vi_loi'] = kh['loi']
        return ket
    if not kh['so_noi'] and not kh['so_tep']:
        ket['ghi_chu'] = 'khong co gi de lam (da ap dung roi) - idempotent'
        return ket
    if not that_su:
        ket['ghi_chu'] = 'chay kho, khong ghi gi'
        return ket

    os.makedirs(bak_dir, exist_ok=True)
    stamp = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
    bak = os.path.join(bak_dir, 'all.material.truoc-maps-kho48-%s' % stamp)
    cu = open(CY_MAT, 'rb').read()
    with open(bak, 'wb') as f:
        f.write(cu)
    if sha256f(bak) != sha256b(cu):
        ket['loi'] = 'sao luu khong khop - DUNG'
        return ket
    ket['sao_luu'] = bak
    ket['sha256_truoc'] = sha256b(cu)

    them = b''.join(x['blk'] for x in kh['noi'])
    tmp = CY_MAT + '.tmp-maps-kho48'
    with open(tmp, 'wb') as f:
        f.write(cu)
        f.write(them)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, CY_MAT)

    # --- SAU KHI GHI: doc lai tu dia, 6 phep kiem; truot mot cai la tra lai ban sao luu ---
    moi = open(CY_MAT, 'rb').read()
    kiem = {}
    kiem['1_kich_thuoc'] = (len(moi) == len(cu) + len(them))
    kiem['2_phan_dau_nguyen_ven'] = (moi[:len(cu)] == cu)
    _, ks = khoi(CY_MAT)
    kiem['3_so_khoi'] = (len(ks) == kh['CY_truoc']['so_khoi'] + kh['so_noi'])
    bt = bang_ten(ks)
    kiem['4_moi_ten_moi_co_mat'] = all(x['ten'].encode('gbk') in bt for x in kh['noi'])
    kiem['5_khoi_moi_khop_sha256_GL'] = all(
        any(sha256b(b) == x['sha256_khoi'] for b in bt.get(x['ten'].encode('gbk'), []))
        for x in kh['noi'])
    kiem['6_khong_ten_trung_moi'] = all(
        len(bt.get(x['ten'].encode('gbk'), [])) == 1 for x in kh['noi'])
    ket['kiem'] = kiem
    ket['sha256_sau'] = sha256b(moi)
    ket['byte_sau'] = len(moi)
    if not all(kiem.values()):
        shutil.copy2(bak, CY_MAT)
        ket['da_tra_ban_sao_luu'] = True
        ket['loi'] = 'phep kiem sau ghi TRUOT - da tra lai ban sao luu'
        return ket

    # --- texture ---
    n_tep = 0
    recs = []
    now = time.strftime('%Y-%m-%dT%H:%M:%S')
    for t in kh['tep']:
        if os.path.exists(t['dich_CY']):
            continue
        os.makedirs(os.path.dirname(t['dich_CY']), exist_ok=True)
        shutil.copy2(t['nguon_GL'], t['dich_CY'])
        n_tep += 1
        recs.append({'ngay': now, 'dot': '2026-09-19-maps-kho48', 'map': t['map'],
                     'loai': 'material_texture', 'nguon_GL': t['nguon_GL'],
                     'dich_CY': t['dich_CY'], 'sha256': sha256f(t['nguon_GL']),
                     'kich_thuoc': os.path.getsize(t['nguon_GL']),
                     'material': t['material'],
                     'the': 'NGUON=GL (Assets/Canonical) - CHO BAN CY THAT'})
    for x in kh['noi']:
        recs.append({'ngay': now, 'dot': '2026-09-19-maps-kho48', 'map': x['map'],
                     'loai': 'material_block', 'nguon_GL': GL_MAT,
                     'dich_CY': CY_MAT, 'sha256': x['sha256_khoi'], 'kich_thuoc': x['byte'],
                     'material': x['ten'],
                     'the': 'NGUON=GL (Assets/Canonical) - CHO BAN CY THAT'})
    os.makedirs(os.path.dirname(MANIFEST), exist_ok=True)
    with open(MANIFEST, 'a', encoding='utf-8') as f:
        for r in recs:
            f.write(json.dumps(r, ensure_ascii=False) + '\n')
    ket['da_chep_texture'] = n_tep
    ket['so_muc_ke_khai'] = len(recs)
    ket['ok'] = True
    return ket


def kiem_tra(rows):
    """DOC LAI TU DIA: moi ten trong `rows` co mat dung 1 lan, va texture cua no co tren dia."""
    _, ks = khoi(CY_MAT)
    bt = bang_ten(ks)
    cy_tep = rec_index([os.path.join(CY_DATA, d) for d in MAT_DIRS])
    out = []
    for m in rows['muc']:
        r = {'map': m['map'], 'thieu_material': [], 'ten_trung': [], 'thieu_texture': []}
        for ten_u in m['material']:
            tb = ten_u.encode('gbk')
            blks = bt.get(tb, [])
            if not blks:
                r['thieu_material'].append(ten_u)
                continue
            if len(blks) > 1:
                r['ten_trung'].append(ten_u)
            for blk in blks:
                for t in tex_cua_khoi(blk):
                    if t.replace(BS, '/').lower() not in cy_tep:
                        r['thieu_texture'].append(t)
        r['thieu_texture'] = sorted(set(r['thieu_texture']))
        r['ok'] = not r['thieu_material'] and not r['thieu_texture'] and not r['ten_trung']
        out.append(r)
    return {'ket_qua': out, 'ok': all(x['ok'] for x in out),
            'CY': {'byte': os.path.getsize(CY_MAT), 'sha256': sha256f(CY_MAT),
                   'so_khoi': len(ks), 'so_ten': len(bt)}}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('lenh', choices=['plan', 'apply', 'verify', 'undo'])
    ap.add_argument('--rows', required=True)
    ap.add_argument('--bak', default=os.path.join(CYS, 'Build', 'reapply-bak', 'maps-kho48'))
    ap.add_argument('--that', action='store_true')
    ap.add_argument('--out', default='')
    a = ap.parse_args()
    rows = json.load(open(a.rows, encoding='utf-8'))

    if a.lenh == 'verify':
        rec = {'lenh': 'verify'}
        rec.update(kiem_tra(rows))
    elif a.lenh == 'undo':
        bs = sorted(x for x in os.listdir(a.bak)
                    if x.startswith('all.material.truoc-maps-kho48-')) if os.path.isdir(a.bak) else []
        rec = {'lenh': 'undo', 'ban_sao_luu': bs}
        if not bs:
            rec['loi'] = 'khong co ban sao luu trong %s' % a.bak
        elif a.that:
            src = os.path.join(a.bak, bs[0])   # ban SOM NHAT = truoc moi thay doi cua dot nay
            shutil.copy2(src, CY_MAT)
            rec['da_tra'] = src
            rec['sha256_sau'] = sha256f(CY_MAT)
            rec['ghi_chu'] = 'texture da chep KHONG bi xoa (khong ghi de tep CY nao) - xoa tay theo manifest neu muon'
        else:
            rec['ghi_chu'] = 'chay kho; them --that de thuc su tra ban som nhat'
    else:
        kh = lam_ke_hoach(rows)
        rec = {'lenh': a.lenh, 'ke_hoach': in_ke_hoach(kh)}
        if a.lenh == 'apply':
            rec['ket_qua'] = ap_dung(kh, a.bak, a.that)
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        json.dump(rec, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    kq = rec.get('ket_qua')
    if (isinstance(kq, dict) and kq.get('loi')) or (a.lenh == 'verify' and not rec.get('ok')):
        sys.exit(1)


if __name__ == '__main__':
    main()
