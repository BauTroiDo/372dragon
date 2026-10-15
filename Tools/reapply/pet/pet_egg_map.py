#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""pet-gc512 (18/09/2026) — ánh xạ TRỨNG TRÂN THÚ (珍兽蛋) → trân thú nở ra, theo TÊN + 可携带等级, trên server riêng.

## Vì sao
`configs/CommonItem.txt` của server riêng là bảng **CY** (ID CY, `cs3c-tables`), còn `Game_2/Script` là cây **0.85**.
Cột 13 (脚本编号) đưa 490/499 trứng CY tới `scripts/obj/commonitem/300027.lua`, nhưng bảng `g_petList` trong file
đó được viết cho **vật phẩm 0.85 cùng ID** — hai nhánh khác nhau, cùng ID có thể là vật phẩm khác (MOC 17/09 mục 4.3).
Đo theo TÊN (`Build/Logs/2026-09-18-pet-gc512/scripts/11-egg-truth-by-name.py`), trước khi sửa:

    OK (nở đúng tên)                        281
    có mục nhưng nở ra CON KHÁC              17   (vd 珍兽蛋：咩小萌 → 星冥人偶宝宝)
    không có mục → "Đạo cụ chưa mở"         192
    cột 13 trỏ script không tồn tại           9   (892728 / 999300 / 999811 / 893631 / -1) — không sửa ở đây

Con số "169/517 lệch ánh xạ" của 17/09 đo theo FILE, không theo tên: nó đếm cả vật phẩm CY không phải trứng
(珍兽笼, sách kỹ năng 840005) và bỏ sót 17 trứng nở sai con.

## Quy tắc (hiệu chuẩn bằng 281 trứng đang đúng — `12-egg-calibrate.py`: 270/274 có cột 3 = lv trứng)
    "珍兽蛋：X" cấp L      → dòng PetAttrTable tên "X宝宝",  cột 3 (可携带等级) == L
    "变异珍兽蛋：X" cấp L  → dòng PetAttrTable tên "变异X",  cột 3 == L   ("珍兽蛋：变异X" cũng → "变异X")
    đúng MỘT dòng khớp    → dùng; không dòng nào cùng cấp nhưng tên là DUY NHẤT → dùng dòng đó;
    nhiều dòng cùng cấp / không có tên / tên chứa 废弃·神秘·（雄）·（雌） → KHÔNG đoán, ghi vào báo cáo.
Dạng mục ghi đúng như 281 mục đang chạy: `g_petList[item] = {type=1, dataId=<id>, level=1}`.
Mục cũ sai được giữ lại dưới dạng chú thích `--CYS-PET egg-map old:` để hoàn tác bằng mắt được.

## Dùng (trong WSL TLBB, python3; chỉ `apply` ghi file)
    python3 Tools/server/pet_egg_map.py plan    [--out F]          tính bảng đổi, KHÔNG ghi
    python3 Tools/server/pet_egg_map.py apply   [--out F] [--dry-run]
                                                sao lưu R/backups/pet-eggmap-<UTC>/300027.lua rồi ghi (GBK, giữ CRLF, idempotent)
    python3 Tools/server/pet_egg_map.py verify  [--out F]          đo lại: mọi trứng sửa được phải nở đúng tên; luac -p
    python3 Tools/server/pet_egg_map.py reload  [--port 16002]     nạp nóng script cho mọi cảnh (scenemanager reload_scripts)
Hoàn tác: chép file trong thư mục backup về `Game_2/Script/scripts/obj/commonitem/300027.lua` rồi `reload`.
"""
import argparse
import collections
import datetime
import io
import json
import os
import re
import shutil
import socket
import subprocess

R = '/home/ubuntu/cys-test-20260913'
CFG = os.path.join(R, 'configs')
REL = 'Game_2/Script/scripts/obj/commonitem/300027.lua'
MARK = 'pet-eggmap'
TAG = 'CYS-PET egg-map'
OLD_PREFIX = '--' + TAG + ' old: '
SKIP_WORDS = ('废弃', '神秘', '（雄）', '（雌）')


def rd(path):
    return io.open(path, 'rb').read().decode('gbk', 'replace')


def load_items():
    items = {}
    for l in rd(os.path.join(CFG, 'CommonItem.txt')).replace('\r\n', '\n').split('\n'):
        c = l.split('\t')
        if len(c) > 13 and re.fullmatch(r'\d+', c[0].strip()):
            items[int(c[0])] = {'name': c[6].strip(), 'lv': c[8].strip(), 'script': c[13].strip()}
    return items


def load_pets():
    pets, by_name = {}, collections.defaultdict(list)
    for l in rd(os.path.join(CFG, 'PetAttrTable.txt')).replace('\r\n', '\n').split('\n'):
        c = [x.strip() for x in l.split('\t')]
        if len(c) > 6 and re.fullmatch(r'\d+', c[0]):
            pid = int(c[0])
            pets[pid] = {'name': c[1], 'take_level': c[3], 'variant': c[5], 'baby': c[6]}
            by_name[c[1]].append(pid)
    return pets, by_name


def split_core(name):
    for sep in ('：', ':'):
        if sep in name:
            return name.split(sep, 1)[1].strip()
    return name.strip()


def wanted_name(iname):
    core = split_core(iname)
    if iname.startswith('变异'):          # 变异珍兽蛋：X  -> 变异X
        return '变异' + core
    if core.startswith('变异'):           # 珍兽蛋：变异X  -> 变异X (30309779.. 珍兽蛋：变异兔子)
        return core
    return core + '宝宝'                  # 珍兽蛋：X      -> X宝宝


ENTRY_RE = re.compile(r'^g_petList\[(\d+)\]\s*=\s*\{\s*type=(\d+),\s*dataId=(\d+)')
ANY_RE = re.compile(r'^g_petList\[(\d+)\]')


def parse_script(text):
    """-> lines (list, '\n' normalized), item -> list of (line index, kind, dataId or None) for LIVE lines only"""
    lines = text.split('\n')
    where = collections.defaultdict(list)
    for i, ln in enumerate(lines):
        m = ENTRY_RE.match(ln)
        if m:
            where[int(m.group(1))].append((i, 'single' if m.group(2) == '1' else 'multi', int(m.group(3))))
            continue
        m = ANY_RE.match(ln)
        if m:
            where[int(m.group(1))].append((i, 'other', None))
    return lines, where


def decide(items, pets, by_name, lines, where):
    """One row per CY egg dispatched to 300027; row['action'] in keep / add / replace / skip:<reason>."""
    rows = []
    for item in sorted(items):
        m = items[item]
        if '珍兽蛋' not in m['name'] or m['script'] != '300027':
            continue
        row = {'item': item, 'name': m['name'], 'lv': m['lv'], 'current': [], 'target': None, 'action': ''}
        for (i, kind, pid) in where.get(item, []):
            if pid is not None:
                row['current'].append({'line': i + 1, 'kind': kind, 'dataId': pid, 'pet': pets.get(pid, {}).get('name', '?')})
        if any(w in m['name'] for w in SKIP_WORDS):
            row['action'] = 'skip:special-name'
            rows.append(row)
            continue
        wanted = wanted_name(m['name'])
        row['wanted'] = wanted
        ids = by_name.get(wanted, [])
        same_level = [pid for pid in ids if pets[pid]['take_level'] == m['lv']]
        if len(same_level) == 1:
            row['target'] = same_level[0]
            row['rule'] = 'name+take_level'
        elif not same_level and len(ids) == 1:
            row['target'] = ids[0]
            row['rule'] = 'name-unique'
        elif not ids:
            row['action'] = 'skip:no-pet-with-that-name'
            rows.append(row)
            continue
        else:
            row['action'] = 'skip:ambiguous(%d rows at that level, %d total)' % (len(same_level), len(ids))
            row['candidates'] = ids
            rows.append(row)
            continue
        singles = [c for c in row['current'] if c['kind'] == 'single']
        live = row['current']
        # the last live definition of the item wins in Lua; "keep" only when it is a single entry already pointing there
        if live and live[-1]['kind'] == 'single' and live[-1]['dataId'] == row['target'] and len(live) == 1:
            row['action'] = 'keep'
        elif live:
            row['action'] = 'replace'
        else:
            row['action'] = 'add'
        rows.append(row)
    return rows


def new_line(row, pets):
    return 'g_petList[%d] = {type=1, dataId=%d, level=1}\t--%s [%s: %s, ten+可携带等级 %s]' % (
        row['item'], row['target'], row['name'], TAG, pets[row['target']]['name'], row['lv'])


def rewrite(lines, where, rows, pets):
    """Returns the new line list. Old live lines of replaced items become comments; new lines go right after the
    last old line of that item, or after the last g_petList line of the file for additions."""
    out = list(lines)
    to_add = []
    for row in rows:
        if row['action'] == 'replace':
            idxs = [i for (i, kind, pid) in where[row['item']]]
            for i in idxs:
                if not out[i].startswith(OLD_PREFIX):
                    out[i] = OLD_PREFIX + out[i]
            out[max(idxs)] = out[max(idxs)] + '\n' + new_line(row, pets)
        elif row['action'] == 'add':
            to_add.append(new_line(row, pets))
    if to_add:
        last = max(i for i, ln in enumerate(out) if ANY_RE.match(ln) or ln.startswith(OLD_PREFIX))
        block = ['--' + TAG + ': ' + str(len(to_add)) + ' trung CY khong co muc trong bang 0.85 (theo ten + 可携带等级, xem Tools/server/pet_egg_map.py)']
        out[last] = out[last] + '\n' + '\n'.join(block + to_add)
    return '\n'.join(out).split('\n')


def lua_syntax(path):
    for exe in ('luac5.4', 'luac', 'lua5.4', 'lua'):
        try:
            if exe.startswith('luac'):
                r = subprocess.run([exe, '-p', path], capture_output=True, text=True)
            else:
                r = subprocess.run([exe, '-e', 'local f,e=loadfile(%r) if not f then io.stderr:write(e) os.exit(1) end' % path],
                                   capture_output=True, text=True)
            return {'tool': exe, 'rc': r.returncode, 'stderr': r.stderr.strip()[:400]}
        except FileNotFoundError:
            continue
    return {'tool': None, 'rc': None, 'stderr': 'khong co lua/luac trong WSL'}


def summarize(rows):
    c = collections.Counter(r['action'].split(':')[0] for r in rows)
    return {'eggs_dispatched_to_300027': len(rows), 'keep': c['keep'], 'add': c['add'], 'replace': c['replace'], 'skip': c['skip'],
            'skip_reasons': dict(collections.Counter(r['action'] for r in rows if r['action'].startswith('skip')))}


def emit(obj, args):
    text = json.dumps(obj, ensure_ascii=False, indent=1)
    print(text)
    if args.out:
        with io.open(args.out, 'w', encoding='utf-8') as f:
            f.write(text)


def analyse():
    items = load_items()
    pets, by_name = load_pets()
    path = os.path.join(R, REL)
    raw = io.open(path, 'rb').read()
    crlf = b'\r\n' in raw
    text = raw.decode('gbk', 'replace').replace('\r\n', '\n')
    lines, where = parse_script(text)
    rows = decide(items, pets, by_name, lines, where)
    return items, pets, path, raw, crlf, lines, where, rows


def cmd_plan(args):
    items, pets, path, raw, crlf, lines, where, rows = analyse()
    out = {'file': path, 'crlf': crlf, 'summary': summarize(rows),
           'changes': [r for r in rows if r['action'] in ('add', 'replace')],
           'skipped': [r for r in rows if r['action'].startswith('skip')]}
    emit(out, args)
    return 0


def cmd_apply(args):
    items, pets, path, raw, crlf, lines, where, rows = analyse()
    todo = [r for r in rows if r['action'] in ('add', 'replace')]
    if not todo:
        emit({'file': path, 'changed': 0, 'note': 'khong con gi de doi (idempotent)', 'summary': summarize(rows)}, args)
        return 0
    new_lines = rewrite(lines, where, rows, pets)
    new_text = '\n'.join(new_lines)
    if crlf:
        new_text = new_text.replace('\n', '\r\n')
    new_raw = new_text.encode('gbk', 'replace')
    if args.dry_run:
        emit({'file': path, 'dry_run': True, 'summary': summarize(rows), 'bytes': [len(raw), len(new_raw)]}, args)
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
        emit({'file': path, 'error': 'cu phap Lua hong sau khi ghi, DA TRA LAI ban cu', 'lua_syntax': syn}, args)
        return 1
    emit({'file': path, 'backup': bak, 'summary': summarize(rows), 'bytes': [len(raw), len(new_raw)],
          'lua_syntax': syn, 'changes': [{'item': r['item'], 'name': r['name'], 'lv': r['lv'], 'action': r['action'],
                                          'target': r['target'], 'pet': pets[r['target']]['name'], 'rule': r['rule'],
                                          'was': r['current']} for r in todo]}, args)
    return 0


def cmd_verify(args):
    items, pets, path, raw, crlf, lines, where, rows = analyse()
    errors = []
    for r in rows:
        if r['action'] in ('add', 'replace'):
            errors.append('%d %s lv %s van con %s' % (r['item'], r['name'], r['lv'], r['action']))
    syn = lua_syntax(path)
    if syn['rc'] not in (0, None):
        errors.append('cu phap Lua hong: %s' % syn['stderr'])
    # every kept egg hatches a pet whose name contains the item's core name
    wrong = []
    for r in rows:
        if r['action'] == 'keep':
            core = split_core(r['name'])
            pn = pets.get(r['current'][-1]['dataId'], {}).get('name', '?')
            if core not in pn:
                wrong.append((r['item'], r['name'], pn))
    if wrong:
        errors.append('%d trung "keep" nhung ten khong khop: %s' % (len(wrong), wrong[:5]))
    out = {'file': path, 'summary': summarize(rows), 'lua_syntax': syn, 'errors': errors, 'status': 'PASS' if not errors else 'FAIL'}
    emit(out, args)
    return 0 if not errors else 1


def cmd_reload(args):
    services = ['.SceneManager', '.Copyscenemanager', '.Dynamicscenemanager']
    sent, out = [], []
    s = socket.create_connection(('127.0.0.1', args.port), timeout=10)
    s.settimeout(6)
    try:
        try:
            out.append(s.recv(4096).decode('utf-8', 'replace'))
        except socket.timeout:
            pass
        for svc in services:
            cmd = 'call %s "reload_scripts"\n' % svc
            s.sendall(cmd.encode('utf-8'))
            sent.append(cmd.strip())
            try:
                out.append(s.recv(8192).decode('utf-8', 'replace'))
            except socket.timeout:
                out.append('(timeout)')
    finally:
        s.close()
    emit({'port': args.port, 'sent': sent, 'console': ''.join(out)[-1500:]}, args)
    return 0


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('plan', 'apply', 'verify', 'reload'):
        p = sub.add_parser(name)
        p.add_argument('--out', default='')
        if name == 'apply':
            p.add_argument('--dry-run', action='store_true')
        if name == 'reload':
            p.add_argument('--port', type=int, default=16002)
    args = ap.parse_args()
    return {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify, 'reload': cmd_reload}[args.cmd](args)


if __name__ == '__main__':
    raise SystemExit(main())
