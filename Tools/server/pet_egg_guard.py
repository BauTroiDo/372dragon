#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""pet-egg-56 (19/09/2026) — TAT cac muc `g_petList` no ra SAI LOAI vi ID vat pham doi nghia
giua hai nhanh, tren server rieng.

## Van de (do live, `Build/Logs/2026-09-19-pet-egg-56/live/wrong-30309078-truoc-074700`)
`configs/CommonItem.txt` la bang **CY**, con `Game_2/Script/.../300027.lua` la cay **0.85**.
Vai ID vat pham la MOT thu trong 0.85 va MOT THU KHAC trong CY. Muc `g_petList` viet cho vat pham
0.85 van con, nen nguoi choi dung trung CY thi:

    30309078  CY = "珍兽蛋：玉兔"   /  0.85 = "珍兽蛋：狭路逢"
    -> muc 0.85 cho ra 24649 "梵圣人偶宝宝" (hai con, vi type=2 goi Create2RMBPetToHuman34534)
    -> do bang bot: count 1->0 (MAT trung), tui thu 2 -> 4, ca hai con deu KHONG phai 玉兔

`300027.lua:1118` goi `EraseItem` TRUOC khi tao thu, con nhanh "khong co muc" thi
`notify_tips("Đạo cụ chưa mở") return 0` — **khong xoa vat pham**. Nen khi khong the biet con
DUNG la con nao, tra ve trang thai "chua mo" la nghiem ngat tot hon: nguoi choi giu lai trung.

## Luat chon (khong doan, khong che du lieu)
Tat mot muc khi CA BA dieu sau dung:
  1. vat pham la 珍兽蛋 va cot 13 `脚本编号` = 300027 tren server rieng (CY);
  2. MOI con no ra deu co ten KHONG chua loi ten trong ten trung (vd 玉兔 vs 梵圣人偶);
  3. cung ID do trong `CommonItem.txt` cua cay **0.85 goc** (`/home/ubuntu/configs`) mang ten
     KHAC han  => chung minh muc nay duoc viet cho MOT VAT PHAM KHAC, khong phai loi go.
Dieu 3 loai tru dung nhung ca "doi ten thuong hieu" ma CA HAI nhanh deu nhu nhau
(30309031 珍兽蛋：黄鸟 -> 雏凤宝宝, 30309040 珍兽蛋：山羊 -> 技嘉羊宝宝): o do khong co ban
nao dung hon, sua la doi hanh vi goc theo phong doan.

Cong cu nay **khong bao gio tu dat dataId moi**. Muon dien muc moi thi dung `pet_egg_map.py`.

## Dung (trong WSL TLBB, python3; chi `apply` ghi file)
    python3 Tools/server/pet_egg_guard.py plan   [--out F]
    python3 Tools/server/pet_egg_guard.py apply  [--out F] [--dry-run]
    python3 Tools/server/pet_egg_guard.py verify [--out F]
    python3 Tools/server/pet_egg_guard.py revert --backup <thu muc>       chep lai ban cu
Sao luu: `R/backups/pet-eggguard-<UTC>/300027.lua`. Giu GBK + kieu xuong dong cu, idempotent,
`luac5.4 -p` sau khi ghi; cu phap hong thi TU DONG tra lai ban cu.
`Game_2/Script/**` nap luoi (`try_load`) nen KHONG can restart; muon nap ngay thi
`python3 Tools/server/pet_egg_map.py reload`.
"""
import argparse
import collections
import datetime
import io
import json
import os
import re
import shutil
import subprocess

R = '/home/ubuntu/cys-test-20260913'
ORIG = '/home/ubuntu'                       # cay 0.85 goc, chi doc
REL = 'Game_2/Script/scripts/obj/commonitem/300027.lua'
MARK = 'pet-eggguard'
TAG = 'CYS-PET egg-guard'
OFF_PREFIX = '--' + TAG + ' off: '
ANY_RE = re.compile(r'^\s*g_petList\[(\d+)\]')


def rd_rows(path):
    raw = io.open(path, 'rb').read().decode('gbk', 'replace')
    for ln in raw.replace('\r\n', '\n').split('\n'):
        if ln.strip():
            yield ln.split('\t')


def load_items(cfgdir):
    out = {}
    for c in rd_rows(os.path.join(cfgdir, 'CommonItem.txt')):
        if len(c) >= 27 and re.fullmatch(r'\d+', c[0].strip()):
            out[int(c[0])] = {'name': c[6].strip(), 'lv': c[8].strip(), 'script': c[13].strip()}
    return out


def load_pets(cfgdir):
    out = {}
    for c in rd_rows(os.path.join(cfgdir, 'PetAttrTable.txt')):
        c = [x.strip() for x in c]
        if len(c) >= 51 and re.fullmatch(r'\d+', c[0]):
            out[int(c[0])] = {'name': c[1], 'take_level': c[3]}
    return out


def split_core(name):
    for sep in ('：', ':'):
        if sep in name:
            return name.split(sep, 1)[1].strip()
    return name.strip()


def runtime_petlist(path):
    """Chay file Lua that de lay bang g_petList (tinh ca ghi de + dang type=2)."""
    here = os.path.dirname(os.path.abspath(__file__))
    lua = os.path.join(here, 'pet_egg_petlist.lua')
    r = subprocess.run(['lua5.4', lua, path], capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit('khong chay duoc %s: %s' % (lua, r.stderr[:400]))
    return {e['item']: e for e in json.loads(r.stdout)}


def targets(entry):
    if entry.get('bands'):
        return [b['dataId'] for b in entry['bands']]
    return [entry['dataId']] if entry.get('dataId') is not None else []


def decide():
    cy_items, pets = load_items(os.path.join(R, 'configs')), load_pets(os.path.join(R, 'configs'))
    old_items = load_items(os.path.join(ORIG, 'configs'))
    path = os.path.join(R, REL)
    raw = io.open(path, 'rb').read()
    plist = runtime_petlist(path)

    rows = []
    for item, m in sorted(cy_items.items()):
        if '珍兽蛋' not in m['name'] or m['script'] != '300027':
            continue
        e = plist.get(item)
        tg = targets(e) if e else []
        if not tg:
            continue
        core = split_core(m['name'])
        names = [pets.get(t, {}).get('name', '?') for t in tg]
        wrong = bool(core) and all(core not in n for n in names)
        old = old_items.get(item)
        other_item = (old is not None and old['name'] != m['name'])
        row = {'item': item, 'ten_CY': m['name'], 'lv': m['lv'], 'dataIds': tg, 'ten_con': names,
               'ten_085': (old or {}).get('name'), 'no_sai_loai': wrong, 'ID_doi_nghia': other_item}
        if wrong and other_item:
            row['action'] = 'tat'
        elif wrong and old is None:
            row['action'] = 'giu:vat-pham-chi-co-o-CY(khong doi chieu duoc)'
        elif wrong:
            row['action'] = 'giu:hai-nhanh-cung-ten(doi-ten-thuong-hieu, khong sua theo phong doan)'
        else:
            continue
        rows.append(row)
    return path, raw, plist, rows


def read_lines(raw):
    crlf = b'\r\n' in raw
    return raw.decode('gbk', 'replace').replace('\r\n', '\n').split('\n'), crlf


def rewrite(lines, items_off):
    out, touched = list(lines), collections.Counter()
    for i, ln in enumerate(out):
        m = ANY_RE.match(ln)
        if m and int(m.group(1)) in items_off and not ln.startswith(OFF_PREFIX):
            out[i] = OFF_PREFIX + ln
            touched[int(m.group(1))] += 1
    return out, touched


def lua_syntax(path):
    for exe in ('luac5.4', 'luac'):
        try:
            r = subprocess.run([exe, '-p', path], capture_output=True, text=True)
            return {'tool': exe, 'rc': r.returncode, 'stderr': r.stderr.strip()[:400]}
        except FileNotFoundError:
            continue
    return {'tool': None, 'rc': None, 'stderr': 'khong co luac trong WSL'}


def emit(obj, args):
    text = json.dumps(obj, ensure_ascii=False, indent=1)
    print(text)
    if getattr(args, 'out', ''):
        with io.open(args.out, 'w', encoding='utf-8') as f:
            f.write(text)


def summary(rows, plist):
    return {'so_trung_no_sai_loai': len(rows),
            'se_tat': [r['item'] for r in rows if r['action'] == 'tat'],
            'giu_lai': {r['item']: r['action'] for r in rows if r['action'] != 'tat'},
            'muc_g_petList_dang_song': len(plist)}


def cmd_plan(args):
    path, raw, plist, rows = decide()
    emit({'file': path, 'summary': summary(rows, plist), 'chi_tiet': rows}, args)
    return 0


def cmd_apply(args):
    path, raw, plist, rows = decide()
    off = {r['item'] for r in rows if r['action'] == 'tat'}
    lines, crlf = read_lines(raw)
    new_lines, touched = rewrite(lines, off)
    if not touched:
        emit({'file': path, 'changed': 0, 'note': 'khong con gi de tat (idempotent)',
              'summary': summary(rows, plist)}, args)
        return 0
    text = '\n'.join(new_lines)
    if crlf:
        text = text.replace('\n', '\r\n')
    new_raw = text.encode('gbk', 'replace')
    if args.dry_run:
        emit({'file': path, 'dry_run': True, 'dong_se_tat': dict(touched),
              'bytes': [len(raw), len(new_raw)], 'summary': summary(rows, plist)}, args)
        return 0
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(R, 'backups', '%s-%s' % (MARK, stamp))
    os.makedirs(bak, exist_ok=True)
    shutil.copy2(path, os.path.join(bak, '300027.lua'))
    with open(path, 'wb') as f:
        f.write(new_raw)
    syn = lua_syntax(path)
    if syn['rc'] not in (0, None):
        shutil.copy2(os.path.join(bak, '300027.lua'), path)
        emit({'file': path, 'error': 'cu phap Lua hong sau khi ghi, DA TRA LAI ban cu',
              'lua_syntax': syn, 'backup': bak}, args)
        return 1
    emit({'file': path, 'backup': bak, 'dong_da_tat': dict(touched),
          'bytes': [len(raw), len(new_raw)], 'lua_syntax': syn,
          'summary': summary(rows, plist), 'chi_tiet': [r for r in rows if r['action'] == 'tat']}, args)
    return 0


def cmd_verify(args):
    path, raw, plist, rows = decide()
    errs = []
    still = [r['item'] for r in rows if r['action'] == 'tat']
    if still:
        errs.append('con %d muc no sai loai chua tat: %s' % (len(still), still))
    text = raw.decode('gbk', 'replace')
    n_off = text.count(OFF_PREFIX)
    syn = lua_syntax(path)
    if syn['rc'] not in (0, None):
        errs.append('cu phap Lua hong: %s' % syn['stderr'])
    try:
        raw.decode('gbk')
    except UnicodeDecodeError as e:
        errs.append('file khong con GBK hop le: %s' % e)
    out = {'file': path, 'so_dong_da_tat': n_off, 'lua_syntax': syn,
           'muc_g_petList_dang_song': len(plist),
           'giu_lai': {r['item']: r['action'] for r in rows if r['action'] != 'tat'},
           'errors': errs, 'status': 'PASS' if not errs else 'FAIL'}
    emit(out, args)
    return 0 if not errs else 1


def cmd_revert(args):
    src = os.path.join(args.backup, '300027.lua')
    dst = os.path.join(R, REL)
    shutil.copy2(src, dst)
    emit({'restored_from': src, 'to': dst, 'lua_syntax': lua_syntax(dst)}, args)
    return 0


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('plan', 'apply', 'verify', 'revert'):
        p = sub.add_parser(name)
        p.add_argument('--out', default='')
        if name == 'apply':
            p.add_argument('--dry-run', action='store_true')
        if name == 'revert':
            p.add_argument('--backup', required=True)
    args = ap.parse_args()
    return {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify, 'revert': cmd_revert}[args.cmd](args)


if __name__ == '__main__':
    raise SystemExit(main())
