#!/usr/bin/env python3
"""zongmen_tables.py - nhap ba bang tong mon cua CY vao `R/configs/` (server-data 17/09/2026).

BA BANG: `TalentInfo.txt` (25 cot x 15 dong), `ZongmenTalent.txt` (37 x 255), `TalentLayerLevel.txt` (6 x 10).

NGUON. **KHONG** lay tu `Assets/CanonicalCY/Data/ConfigFolder/` - o do chung la DBC nhi phan `00CCBBDD`,
khong phai bang text cua server. Lay tu ban do text cua CY: `<TLBB>/Tools/DATA NEW/DataCY31-08-26/Config/`.
Ba file do da la text tab, GBK, CRLF, hai dong tieu de - dung khuon `configs/*.txt` cua server.

BA SU THAT PHAI DOC TRUOC KHI TIN VAO VIEC NAY (do 17/09, xem `Docs/specs/server/server-data_vi.md`):

 1. **Hom nay server KHONG doc ba bang nay.** `grep -rn 'TalentInfo|ZongmenTalent|TalentLayerLevel'` tren
    ca cay server ra **0 dong**; `cfghelper.lua` chi co **178** loi goi `read:load(...)` va khong cai nao
    la ba bang nay. Nap bang xong thi "server 0 loi" la **hien nhien dung**, va no **khong chung minh** dieu gi.
    Viec nhap chi de: (a) server va client dung **cung mot bo so**, (b) nguoi viet phan tong mon phia server
    sau nay co san bang o dung dinh dang, khong phai giai ma DBC lai.
 2. **Ba bang nay KHONG co ten cot.** DBC nhi phan cua CY chi luu KIEU cot (0 = INT, 2 = STRING), khong luu
    ten; ban do text vi vay lap lai dong kieu hai lan. `cfghelper` doc theo TEN cot, nen ai viet reader cho
    ba bang nay **phai doc theo VI TRI**. Day la su that cua du lieu CY, khong phai loi cua ban do.
 3. **Bay "hoan vi kieu cot" cua `CharTitleNew` KHONG ap dung o day.** Bay do xay ra khi *tron* dong CY vao
    mot bang server DA CO (server `8 STRING, 9 INT` con CY `8 INT, 9 STRING`). Ba bang nay server **chua co**,
    nen day la chep **ca file**, khong co bang nao de doi chieu kieu, va cung khong co gi de lech.

CHIEU NGUOC LAI (chi ghi nhan, khong lam): `SectDesc.txt` (985 dong) va `SectInfo.txt` (985 dong) CO tren
server nhung **khong co trong ban do CY** va khong co trong `Assets/CanonicalCY/Data/ConfigFolder`. Do la
ly do `Lua_GetSectDesc` phia client chua cai duoc. Dua hai bang do sang client la viec cua `Assets/`,
ngoai pham vi cong cu nay.

LUAT NHAP - tu choi neu sai bat ky dieu nao:
  * file nguon giai ma **GBK toan file** (bay `txtreader` doi `gbk.toutf8` ca dong);
  * moi dong du lieu co **dung so cot** cua dong kieu;
  * cot 0 la so nguyen va **tang dan, khong trung**;
  * file dich **chua ton tai** (neu da co va khac noi dung thi la cua nguoi khac -> tu choi).

Lenh:
  zongmen_tables.py survey
  zongmen_tables.py plan   --out DIR
  zongmen_tables.py apply  --staging DIR [--dry-run]
  zongmen_tables.py verify
  zongmen_tables.py revert --backup DIR

Chay trong WSL TLBB bang root:
    python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/zongmen_tables.py <lenh>
Dac ta: `Docs/specs/server/server-data_vi.md`.
"""
import argparse
import datetime
import hashlib
import json
import os
import re
import shutil
import sys

R = '/home/ubuntu/cys-test-20260913'
SRC = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
TABLES = ('TalentInfo.txt', 'ZongmenTalent.txt', 'TalentLayerLevel.txt')
SERVER_ONLY = ('SectDesc.txt', 'SectInfo.txt')
CRLF, LF, TAB = b'\r\n', b'\n', b'\t'
LOCK = 'configs/.scene_install.lock'       # dung chung voi scene_install.py / ride_data.py


def sha(b):
    return hashlib.sha256(b).hexdigest()


def rows_of(raw):
    lines = [l.rstrip(b'\r') for l in raw.split(LF)]
    while lines and not lines[-1].strip():
        lines.pop()
    return lines


def check(raw, name):
    """Tra (loi[], thong tin{}). Khong ném - de survey in het moi loi cung mot luot."""
    errs, info = [], {}
    try:
        raw.decode('gbk')
        info['gbk'] = True
    except UnicodeDecodeError as e:
        info['gbk'] = False
        errs.append('%s: KHONG phai GBK toan file (%s)' % (name, e))
    lines = rows_of(raw)
    if len(lines) < 3:
        errs.append('%s: it hon 3 dong' % name)
        return errs, info
    ncol = len(lines[0].split(TAB))
    info['so_cot'] = ncol
    info['so_dong_du_lieu'] = len(lines) - 2
    info['tieu_de_lap'] = (lines[0] == lines[1])
    bad = [i + 1 for i, l in enumerate(lines) if len(l.split(TAB)) != ncol]
    if bad:
        errs.append('%s: %d dong sai so cot (dong %s...)' % (name, len(bad), bad[:5]))
    ids, prev = [], None
    for i, l in enumerate(lines[2:], start=3):
        c = l.split(TAB)[0]
        if not re.fullmatch(rb'-?\d+', c):
            errs.append('%s: dong %d cot 0 khong phai so: %r' % (name, i, c[:20]))
            break
        v = int(c)
        if prev is not None and v <= prev:
            errs.append('%s: dong %d cot 0 khong tang dan (%d sau %d)' % (name, i, v, prev))
            break
        prev = v
        ids.append(v)
    info['id_min'] = min(ids) if ids else None
    info['id_max'] = max(ids) if ids else None
    info['eol'] = 'CRLF' if raw.count(CRLF) >= len(lines) - 1 else 'LF/tron'
    return errs, info


def cmd_survey(args):
    out = {'nguon': SRC, 'dich': os.path.join(R, 'configs'), 'bang': {}}
    for t in TABLES:
        p = os.path.join(SRC, t)
        d = os.path.join(R, 'configs', t)
        e = {'nguon_co': os.path.exists(p), 'dich_da_co': os.path.exists(d)}
        if e['nguon_co']:
            raw = open(p, 'rb').read()
            errs, info = check(raw, t)
            e.update(info)
            e['loi'] = errs
            e['sha_nguon'] = sha(raw)
        if e['dich_da_co']:
            e['sha_dich'] = sha(open(d, 'rb').read())
            e['giong_nguon'] = e.get('sha_dich') == e.get('sha_nguon')
        out['bang'][t] = e
    out['chieu_nguoc_lai'] = {}
    for t in SERVER_ONLY:
        out['chieu_nguoc_lai'][t] = {
            'co_tren_server': os.path.exists(os.path.join(R, 'configs', t)),
            'co_trong_ban_do_CY': os.path.exists(os.path.join(SRC, t)),
        }
    # co ai doc ba bang nay khong?
    hits = []
    for dp, _dn, fns in os.walk(os.path.join(R, 'GameServer')):
        for fn in fns:
            if not fn.endswith('.lua'):
                continue
            try:
                txt = open(os.path.join(dp, fn), encoding='utf-8', errors='replace').read()
            except OSError:
                continue
            for t in TABLES:
                if t in txt or t[:-4] in txt:
                    hits.append('%s -> %s' % (os.path.relpath(os.path.join(dp, fn), R), t))
    out['server_doc_ba_bang_nay'] = hits
    print(json.dumps(out, ensure_ascii=False, indent=2))
    return 0


def cmd_plan(args):
    os.makedirs(os.path.join(args.out, 'configs'), exist_ok=True)
    plan = {'utc': datetime.datetime.utcnow().isoformat() + 'Z', 'nguon': SRC, 'bang': {}}
    allerr = []
    for t in TABLES:
        p = os.path.join(SRC, t)
        if not os.path.exists(p):
            allerr.append('%s: khong co o nguon' % t)
            continue
        raw = open(p, 'rb').read()
        errs, info = check(raw, t)
        allerr += errs
        if errs:
            continue
        # chuan hoa: CRLF thuan + ket thuc bang mot dong trong
        data = CRLF.join(rows_of(raw)) + CRLF
        data.decode('gbk')                       # kiem lai sau khi chuan hoa
        with open(os.path.join(args.out, 'configs', t), 'wb') as f:
            f.write(data)
        plan['bang'][t] = {**info, 'sha_nguon': sha(raw), 'sha_sau_chuan_hoa': sha(data),
                           'byte': len(data)}
    plan['loi'] = allerr
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=2)
    print(json.dumps(plan, ensure_ascii=False, indent=2))
    return 1 if allerr else 0


def cmd_apply(args):
    import fcntl
    plan = json.load(open(os.path.join(args.staging, 'plan.json'), encoding='utf-8'))
    if plan['loi']:
        raise SystemExit('plan con loi -> tu choi apply')
    todo = []
    for t in TABLES:
        s = os.path.join(args.staging, 'configs', t)
        d = os.path.join(R, 'configs', t)
        if not os.path.exists(s):
            continue
        new = open(s, 'rb').read()
        if os.path.exists(d):
            cur = open(d, 'rb').read()
            if cur == new:
                continue
            raise SystemExit('%s da ton tai va KHAC noi dung -> tu choi de (co the cua nguoi khac)' % t)
        todo.append((t, d, new))
    if not todo:
        print(json.dumps({'ket_qua': 'khong co gi de lam', 'so_bang': 0}, ensure_ascii=False))
        return 0
    if args.dry_run:
        print(json.dumps({'dry_run': True, 'se_them': [t for t, _d, _n in todo]}, ensure_ascii=False))
        return 0
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'zongmen-tables-%s' % stamp)
    os.makedirs(bdir, exist_ok=True)
    lockp = os.path.join(R, LOCK)
    os.makedirs(os.path.dirname(lockp), exist_ok=True)
    with open(lockp, 'a+') as lk:
        fcntl.flock(lk, fcntl.LOCK_EX)
        try:
            for t, d, new in todo:
                if os.path.exists(d):                     # kiem lai TRONG lock
                    raise SystemExit('%s vua xuat hien trong luc cho lock -> tu choi' % t)
                with open(d, 'wb') as f:
                    f.write(new)
        finally:
            fcntl.flock(lk, fcntl.LOCK_UN)
    res = {'sao_luu': bdir, 'ghi_chu': 'ba bang deu la file MOI -> hoan tac = xoa chung',
           'da_them': [t for t, _d, _n in todo]}
    with open(os.path.join(bdir, 'apply.json'), 'w', encoding='utf-8') as f:
        json.dump({**res, 'plan': plan}, f, ensure_ascii=False, indent=2)
    print(json.dumps(res, ensure_ascii=False, indent=2))
    return 0


def cmd_verify(args):
    res = {'bang': {}, 'loi': []}
    for t in TABLES:
        d = os.path.join(R, 'configs', t)
        if not os.path.exists(d):
            res['loi'].append('%s: chua co trong configs' % t)
            continue
        raw = open(d, 'rb').read()
        errs, info = check(raw, t)
        res['loi'] += errs
        src = os.path.join(SRC, t)
        if os.path.exists(src):
            info['giong_nguon_sau_chuan_hoa'] = (
                sha(raw) == sha(CRLF.join(rows_of(open(src, 'rb').read())) + CRLF))
        res['bang'][t] = info
    res['ok'] = not res['loi']
    print(json.dumps(res, ensure_ascii=False, indent=2))
    return 0 if res['ok'] else 1


def cmd_revert(args):
    n = []
    for t in TABLES:
        d = os.path.join(R, 'configs', t)
        if os.path.exists(d):
            os.remove(d)
            n.append(t)
    print(json.dumps({'da_xoa': n}, ensure_ascii=False))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('survey'); p.set_defaults(fn=cmd_survey)
    p = sub.add_parser('plan'); p.add_argument('--out', required=True); p.set_defaults(fn=cmd_plan)
    p = sub.add_parser('apply'); p.add_argument('--staging', required=True)
    p.add_argument('--dry-run', action='store_true'); p.set_defaults(fn=cmd_apply)
    p = sub.add_parser('verify'); p.set_defaults(fn=cmd_verify)
    p = sub.add_parser('revert'); p.set_defaults(fn=cmd_revert)
    a = ap.parse_args()
    sys.exit(a.fn(a))


if __name__ == '__main__':
    main()
