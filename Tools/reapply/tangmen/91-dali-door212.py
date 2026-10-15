# -*- coding: utf-8 -*-
"""[CYS-TANGMEN 20/09/2026] Bat NPC 接引使 cua Duong Mon o Dai Ly (race 56003 唐昱).

HAI THAY DOI, PHAI DI CUNG NHAU - lam mot cai thoi la NPC "bat roi ma khong hien":

  (1) `[monster212_off]` -> `[monster212]`
      GameServer/services/scene/scenecore.lua:657 create_monsters()
          for i = 0, self.monster_conf.info.monstercount - 1 do
              local key = string.format("monster%d", i)      <-- CHI lap ten dung khuon nay
      => section mang ten khac KHONG BAO GIO duoc sinh. (`monstercount` cua tep nay = 217 nen
      chi so 212 nam trong tam; da do.)

  (2) `pos_x=;166.0000` -> `pos_x=166.0000`
      GameServer/lualib/inireader.lua:31   line:match("([_%w]+)=([^%;-%\\r-%\\t]+)")
      Tap ky tu bi loai la { ';' , '-' , CR , TAB }. Gia tri bat dau bang ';' => CA DONG khong khop
      => khoa `pos_x` KHONG BAO GIO duoc dat => scenecore.lua:709
          local world_pos = {x = conf.pos_x or conf.x, y = conf.pos_z or conf.z}
      nhan x = nil. Tien to ';' chinh la cach tac gia CY tat mot NPC: do duoc 95 section co
      pos_x/pos_z bi loai kieu nay tren 1.932 tep (xem Build/Logs/2026-09-20-tangmen/31-*).

  91-dali-door212.py plan|apply|verify|undo [--ini F] [--out F]
  (chay TRONG WSL: tep nam o /home/ubuntu/cys-test-20260913/Game_2/Scene)

Ghi o muc BYTE, GIU NGUYEN GBK va kieu xuong dong. `apply` khang dinh phan con lai cua tep
KHONG doi mot byte truoc khi ghi, va sao luu truoc.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import time

R = '/home/ubuntu/cys-test-20260913'
INI_MAC_DINH = os.path.join(R, 'Game_2', 'Scene', 'dali_new_320_monster.ini')
BAK_THUMUC = os.path.join(R, 'backups')
SEC_CU = b'[monster212_off]'
SEC_MOI = b'[monster212]'
POS_CU = b'pos_x=;166.0000'
POS_MOI = b'pos_x=166.0000'
RACE = b'type=56003'
# nguyen van luat cua inireader.lua: gia tri phai bat dau bang ky tu KHONG thuoc {';','-',CR,TAB}
INI_OK = re.compile(rb'^([_A-Za-z0-9]+)=([^;\-\r\t]+)')


def dec(b):
    try:
        return b.decode('utf-8')
    except UnicodeDecodeError:
        return b.decode('gbk', 'replace')


def doc(path):
    raw = open(path, 'rb').read()
    return raw, hashlib.sha256(raw).hexdigest()


def cat_section(raw, ten):
    i = raw.find(ten)
    if i < 0:
        return None, None, None
    j = raw.find(b'\n[', i)
    j = len(raw) if j < 0 else j + 1
    return i, j, raw[i:j]


def kv_bi_bo(body):
    out = []
    for line in body.split(b'\n'):
        line = line.strip(b'\r')
        if not line or line.startswith(b'['):
            continue
        if b'=' not in line:
            continue
        k = line.split(b'=', 1)[0]
        if not re.match(rb'^[_A-Za-z0-9]+$', k):
            continue
        if not INI_OK.match(line):
            out.append(dec(line))
    return out


def emit(rec, args):
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    if getattr(args, 'out', ''):
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        json.dump(rec, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)


def cmd_plan(args):
    raw, sha = doc(args.ini)
    i, j, body = cat_section(raw, SEC_CU)
    i2, j2, body2 = cat_section(raw, SEC_MOI + b'\n')
    rec = {'lenh': 'plan', 'ini': args.ini, 'sha256': sha, 'byte': len(raw),
           'co_section_cu': i is not None, 'co_section_moi_roi': i2 is not None,
           'section_hien_tai': dec(body) if body else None,
           'dong_inireader_BO_QUA': kv_bi_bo(body) if body else None,
           'se_doi': [dec(SEC_CU) + ' -> ' + dec(SEC_MOI), dec(POS_CU) + ' -> ' + dec(POS_MOI)]}
    emit(rec, args)
    return 0


def cmd_apply(args):
    raw, sha = doc(args.ini)
    i, j, body = cat_section(raw, SEC_CU)
    if i is None:
        i2, _, _ = cat_section(raw, SEC_MOI + b'\n')
        emit({'lenh': 'apply', 'da_du': i2 is not None, 'ini': args.ini, 'sha256': sha,
              'ghi_chu': 'khong con [monster212_off]' }, args)
        return 0 if i2 is not None else 1
    if RACE not in body:
        sys.exit('section [monster212_off] khong chua %s - TU CHOI ghi' % dec(RACE))
    if body.count(SEC_CU) != 1 or body.count(POS_CU) != 1:
        sys.exit('so lan xuat hien khong phai 1/1 - TU CHOI ghi')
    body_moi = body.replace(SEC_CU, SEC_MOI).replace(POS_CU, POS_MOI)
    moi = raw[:i] + body_moi + raw[j:]
    # BAT BIEN TRUOC KHI GHI: doi nguoc hai thay doi phai ra LAI file cu, tung byte.
    nguoc = moi[:i] + moi[i:i + len(body_moi)].replace(SEC_MOI, SEC_CU).replace(POS_MOI, POS_CU) \
        + moi[i + len(body_moi):]
    if nguoc != raw:
        sys.exit('bat bien hong: doi nguoc khong ra lai file cu - KHONG ghi')
    if len(moi) != len(raw) - (len(SEC_CU) - len(SEC_MOI)) - (len(POS_CU) - len(POS_MOI)):
        sys.exit('so byte khong dung - KHONG ghi')
    bak_dir = os.path.join(BAK_THUMUC, 'tangmen-door212-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()))
    os.makedirs(bak_dir, exist_ok=True)
    bak = os.path.join(bak_dir, os.path.basename(args.ini))
    shutil.copy2(args.ini, bak)
    tmp = args.ini + '.tangmen.tmp'
    open(tmp, 'wb').write(moi)
    os.replace(tmp, args.ini)
    raw2, sha2 = doc(args.ini)
    _, _, body2 = cat_section(raw2, SEC_MOI + b'\n')
    emit({'lenh': 'apply', 'ini': args.ini, 'sao_luu': bak,
          'sha256_truoc': sha, 'sha256_sau': sha2,
          'byte_truoc': len(raw), 'byte_sau': len(raw2),
          'section_sau': dec(body2) if body2 else None,
          'dong_inireader_BO_QUA_sau': kv_bi_bo(body2) if body2 else None}, args)
    return 0


def cmd_verify(args):
    raw, sha = doc(args.ini)
    loi = []
    i, j, body = cat_section(raw, SEC_MOI + b'\n')
    if i is None:
        loi.append('KHONG co section [monster212]')
    else:
        if RACE not in body:
            loi.append('[monster212] khong chua %s' % dec(RACE))
        # CHI o VI TRI moi la loi. Cac dong `=-1` cung bi inireader bo qua, nhung do la hanh vi
        # CO SAN cua ca 50.780 section trong 1.932 tep (da do) - khong phai viec cua dot nay.
        bo = [x for x in kv_bi_bo(body) if x.startswith('pos_x') or x.startswith('pos_z')]
        if bo:
            loi.append('inireader se BO QUA dong vi tri: %s' % bo)
        m = re.search(rb'^pos_x=(.*)$', body, re.M)
        if not m:
            loi.append('khong co dong pos_x')
        elif not INI_OK.match(b'pos_x=' + m.group(1)):
            loi.append('pos_x van bi inireader bo qua: %r' % m.group(1))
    if raw.find(SEC_CU) >= 0:
        loi.append('van con [monster212_off]')
    # dem hai lan: so section `monster<so>` truoc/sau phai tang dung 1 so voi ban sao luu gan nhat
    bs = sorted(p for p in (os.path.join(BAK_THUMUC, d, os.path.basename(args.ini))
                            for d in (os.listdir(BAK_THUMUC) if os.path.isdir(BAK_THUMUC) else [])
                            if d.startswith('tangmen-door212-')) if os.path.exists(p))
    them = None
    if bs:
        raw0 = open(bs[-1], 'rb').read()
        n0 = len(re.findall(rb'^\[monster\d+\]', raw0, re.M))
        n1 = len(re.findall(rb'^\[monster\d+\]', raw, re.M))
        them = n1 - n0
        if them != 1:
            loi.append('so section monster<so> tang %s, phai tang dung 1 (sao luu %s)' % (them, bs[-1]))
    rec = {'lenh': 'verify', 'ini': args.ini, 'sha256': sha, 'ok': not loi, 'loi': loi,
           'ghi_nhan_KHONG_phai_loi': (
               [x for x in kv_bi_bo(body) if not (x.startswith('pos_x') or x.startswith('pos_z'))]
               if i is not None else None),
           'section': dec(body) if i is not None else None,
           'so_section_monster_tang': them,
           'so_section_monster_hien_tai': len(re.findall(rb'^\[monster\d+\]', raw, re.M)),
           'so_section__off_con_lai': len(re.findall(rb'^\[[^\]\r\n]+_off\]', raw, re.M))}
    emit(rec, args)
    return 0 if rec['ok'] else 1


def cmd_undo(args):
    ds = sorted(d for d in (os.listdir(BAK_THUMUC) if os.path.isdir(BAK_THUMUC) else [])
                if d.startswith('tangmen-door212-'))
    if not ds:
        sys.exit('khong co ban sao luu tangmen-door212-* trong %s' % BAK_THUMUC)
    bak = os.path.join(BAK_THUMUC, ds[-1], os.path.basename(args.ini))
    shutil.copy2(bak, args.ini)
    raw, sha = doc(args.ini)
    emit({'lenh': 'undo', 'tu': bak, 'sha256': sha, 'byte': len(raw)}, args)
    return 0


ap = argparse.ArgumentParser()
sub = ap.add_subparsers(dest='cmd')
for _n in ('plan', 'apply', 'verify', 'undo'):
    _a = sub.add_parser(_n)
    _a.add_argument('--ini', default=INI_MAC_DINH)
    _a.add_argument('--out', default='')
_args = ap.parse_args()
_f = {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify, 'undo': cmd_undo}.get(_args.cmd)
sys.exit(_f(_args) if _f else (ap.print_help() or 2))
