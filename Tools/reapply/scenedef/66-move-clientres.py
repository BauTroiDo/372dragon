# -*- coding: utf-8 -*-
"""maps-instance buoc 2b: doi 16 hang so `g_ClientRes` sang dai ID TRONG (cu + 3000),
va them dong tuong ung vao bang `configs/SceneDefineEx.txt` PHIA SERVER.

Vi sao doi hang so: `client_res` dung chung khong gian ID voi "ID canh server", nen dong DBC o ID
173 phai phuc vu canh 173 (黄龙洞) va KHONG the dong thoi mo ta 少林寺 pho ban. Dai 2224..4510
cua DBC hoan toan trong, nen `moi = cu + 3000` la khong gian rieng, khong dung do ai.

Vi sao them dong vao bang SERVER: `copyscenecore:get_name`
(`R/GameServer/services/scene/copyscenecore.lua:31-36`) tra `scene_define_ex[client_res].name`
trong bang cua SERVER; `cfghelper:read_scene_define_ex` (`lualib/cfghelper.lua:4452-4466`) danh
khoa theo cot `Index`. Ten canh do hien ra cho NGUOI CHOI (vd thong bao rot do:
`services/scene/obj/itembox.lua:237` thay `&S` bang `scene:get_name()`), nen khong duoc de thanh
"未知场景".

BAY GBK: `txtreader` doi ca dong bang `gbk.toutf8` vo dieu kien, mot o UTF-8 le byte se nuot tab
va lech cot IM LANG. Nen o day CHEP NGUYEN BYTE dong nguon va chi thay o dau (chu so ASCII).

  python3 -B 66-move-clientres.py plan|apply|verify --map <43-clientres-map.json> --out-dir <thu muc>
"""
import argparse
import json
import os
import re
import shutil
import sys
import time

R = '/home/ubuntu/cys-test-20260913'
SCRIPT_DIR = os.path.join(R, 'Game_2', 'Script')
SDE = os.path.join(R, 'configs', 'SceneDefineEx.txt')
OFFSET = 3000
PAT = re.compile(rb'(g_ClientRes[ \t]*=[ \t]*)(\d+)')


def tim_kich_ban():
    """{duong dan tep -> gia tri g_ClientRes}; chi lay dong DINH NGHIA (`= <so>`)."""
    out = {}
    for root, _, files in os.walk(SCRIPT_DIR):
        for f in files:
            if not f.endswith('.lua'):
                continue
            p = os.path.join(root, f)
            b = open(p, 'rb').read()
            m = PAT.findall(b)
            if not m:
                continue
            if len(m) != 1:
                sys.exit('%s co %d dong dinh nghia g_ClientRes - dung lai' % (p, len(m)))
            out[p] = int(m[0][1])
    return out


def doc_sde():
    raw = open(SDE, 'rb').read()
    nl = b'\r\n' if raw.count(b'\r\n') > raw.count(b'\n') // 2 else b'\n'
    dong = raw.split(b'\n')
    idx = {}
    for i, ln in enumerate(dong):
        c = ln.split(b'\t')
        if c and c[0].strip().lstrip(b'-').isdigit():
            idx[int(c[0])] = i
    return raw, dong, idx, nl


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=['plan', 'apply', 'verify'])
    ap.add_argument('--out-dir', required=True)
    ap.add_argument('--only', default='', help='chi lam cac gia tri cu nay (phay), de trong = tat ca')
    a = ap.parse_args()
    os.makedirs(a.out_dir, exist_ok=True)

    kb = tim_kich_ban()
    raw, dong, idx, nl = doc_sde()
    chi = {int(x) for x in a.only.split(',') if x.strip()} if a.only else None

    rec = {'lenh': a.cmd, 'offset': OFFSET, 'kich_ban': [], 'sde': []}
    can_doi, can_them = [], []
    for p, cu in sorted(kb.items(), key=lambda t: t[1]):
        moi = cu + OFFSET
        if chi and cu not in chi:
            continue
        r = {'tep': p.replace(R + '/', ''), 'cu': cu, 'moi': moi,
             'da_doi': cu >= OFFSET}
        rec['kich_ban'].append(r)
        if not r['da_doi']:
            can_doi.append((p, cu, moi))
        goc = cu - OFFSET if r['da_doi'] else cu
        r['dong_sde_goc'] = goc
        r['dong_sde_moi_da_co'] = (goc + OFFSET) in idx
        if goc in idx and (goc + OFFSET) not in idx:
            can_them.append((goc, goc + OFFSET))
        elif goc not in idx:
            r['canh_bao'] = 'bang server khong co dong %d' % goc

    if a.cmd == 'plan':
        rec['se_doi_hang_so'] = [{'tep': p.replace(R + '/', ''), 'cu': c, 'moi': m} for p, c, m in can_doi]
        rec['se_them_dong_sde'] = []
        for cu, moi in can_them:
            c = dong[idx[cu]].split(b'\t')
            rec['se_them_dong_sde'].append({'moi': moi, 'chep_tu': cu,
                                            'ten': c[1].decode('gbk', 'replace'),
                                            'scene': c[4].decode('gbk', 'replace') if len(c) > 4 else ''})
        print(json.dumps(rec, ensure_ascii=False, indent=1))
        json.dump(rec, open(os.path.join(a.out_dir, '66-plan.json'), 'w', encoding='utf-8'),
                  ensure_ascii=False, indent=1)
        return 0

    if a.cmd == 'apply':
        stamp = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
        bak = os.path.join(a.out_dir, 'backup-server-' + stamp)
        os.makedirs(bak, exist_ok=True)
        # 1) hang so trong kich ban
        da_doi = []
        for p, cu, moi in can_doi:
            shutil.copy2(p, os.path.join(bak, os.path.basename(p)))
            b = open(p, 'rb').read()
            b2, n = PAT.subn(lambda m: m.group(1) + str(int(m.group(2)) + OFFSET).encode(), b, count=1)
            if n != 1 or len(b2) - len(b) != len(str(moi)) - len(str(cu)):
                sys.exit('%s: thay the khong nhu mong doi' % p)
            open(p, 'wb').write(b2)
            da_doi.append({'tep': p.replace(R + '/', ''), 'cu': cu, 'moi': moi})
        # 2) dong moi trong bang SceneDefineEx cua server (CHEP NGUYEN BYTE, chi doi o dau)
        da_them = []
        if can_them:
            shutil.copy2(SDE, os.path.join(bak, 'SceneDefineEx.txt'))
            raw2, dong2, idx2, nl2 = doc_sde()
            them_byte = []
            for cu, moi in can_them:
                ln = dong2[idx2[cu]]
                if ln.endswith(b'\r'):
                    ln = ln[:-1]
                c = ln.split(b'\t')
                c[0] = str(moi).encode()
                them_byte.append(b'\t'.join(c))
                da_them.append({'moi': moi, 'chep_tu': cu})
            duoi = raw2
            if not duoi.endswith(b'\n'):
                duoi += b'\r\n'
            duoi += b'\r\n'.join(them_byte) + b'\r\n'
            tmp = SDE + '.maps-instance.tmp'
            open(tmp, 'wb').write(duoi)
            os.replace(tmp, SDE)
        rec.update({'sao_luu': bak, 'da_doi_hang_so': da_doi, 'da_them_dong_sde': da_them})
        print(json.dumps(rec, ensure_ascii=False, indent=1))
        json.dump(rec, open(os.path.join(a.out_dir, '66-apply.json'), 'w', encoding='utf-8'),
                  ensure_ascii=False, indent=1)
        return 0

    # verify
    loi = []
    raw3, dong3, idx3, _ = doc_sde()
    for p, cu in sorted(kb.items(), key=lambda t: t[1]):
        if cu < OFFSET:
            loi.append('%s con g_ClientRes = %d (chua doi)' % (p.replace(R + '/', ''), cu))
            continue
        if cu not in idx3:
            loi.append('bang server thieu dong %d' % cu)
            continue
        goc, moi = cu - OFFSET, cu
        if goc in idx3:
            a1 = dong3[idx3[goc]].rstrip(b'\r').split(b'\t')
            a2 = dong3[idx3[moi]].rstrip(b'\r').split(b'\t')
            if a1[1:] != a2[1:]:
                loi.append('dong %d khong giong dong %d (tru cot 0)' % (moi, goc))
    ids = sorted(idx3)
    if ids != sorted(set(ids)):
        loi.append('bang server co Index trung')
    tang = ids == sorted(ids)
    rec.update({'ok': not loi, 'loi': loi, 'so_dong_sde': len(idx3), 'index_tang_dan': tang})
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    json.dump(rec, open(os.path.join(a.out_dir, '66-verify.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    return 0 if not loi else 1


if __name__ == '__main__':
    sys.exit(main())
