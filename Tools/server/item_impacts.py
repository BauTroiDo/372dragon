#!/usr/bin/env python3
"""item-live — trả lại hiệu ứng cho vật phẩm tiêu hao, và cho quái Vô Lượng Sơn rơi đồ.

Hai bảng, hai luật, cùng một nguyên tắc: **không bịa số, chỉ chép dòng có thật**.

1. `configs/StandardImpact.txt`
   `Game_2/Script/scripts/obj/commonitem/*.lua` gọi `LuaFnSendSpecificImpactToUnit(..., g_ImpactN, 0)` với ID
   impact của bản 0.85, nhưng bảng impact đã bị thay sang bộ CY (commit 5a4529a), nên 161/545 ID không còn dòng.
   `impactenginer:init_impact_from_data` trả `false` và **không log gì** (`impactenginer.lua:63` bị chú thích),
   trong khi `services/scene/skill/human/script.lua action_active_once_handler` đã gọi `OnDeplete` (trừ món)
   TRƯỚC `OnActivateOnce` (gửi impact) — người chơi mất thuốc mà không nhận được gì.

   Luật `copy85`: ID I thiếu ở bảng CY nhưng CÓ ở `/home/ubuntu/configs/StandardImpact.txt` (bản 0.85)
                  ==> chép NGUYÊN dòng đó (81 cột, byte GBK y hệt, kể cả Data_Index) vào đúng vị trí sắp xếp.
   Hai bảng có **cùng 81 cột, cùng tên cột, cùng dòng kiểu**, nên đây là phép chép dòng thuần tuý, không ánh xạ.
   ID nào không có ở cả hai bảng thì BỎ và ghi lý do (hiện: 4931, 340001).

2. `configs/MonsterDropBoxs.txt`
   Không một cảnh nào server thực sự dựng (`active=1 AND type=0`, đúng 17 cảnh) có quái với dòng
   `MonsterDropBoxs` còn vật phẩm, nên `monster:dispatch_item_box` không bao giờ tạo hộp. Bản 0.85 **cũng không**
   có quái 900..909 của Vô Lượng Sơn, nên không có dòng nào để chép nguyên.

   Luật `clonerow`: chép NGUYÊN một dòng CÓ THẬT trong chính bảng CY (dòng mẫu `--drop-template`, mặc định 3640
                    贼兵喽啰 — quái cấp 10 của 贼寇营地, hộp 75/76 còn vật phẩm), **chỉ đổi đúng ô Data_Index**
                    sang ID quái đích. Mọi ô khác (Mvalue, 怪物掉落类型, DID1..DID20) giữ nguyên byte.
   Công cụ tự kiểm trên bảng sống: dòng mẫu phải tồn tại, mọi DID của nó phải có trong `DropBoxContent` và ít
   nhất một hộp phải còn vật phẩm; quái đích phải có trong `MonsterAttrExTable` và phải thực sự xuất hiện trong
   file `<scene>_monster.ini` của một cảnh `active=1 type=0`. Sai một điều kiện ⇒ BỎ mục đó, ghi lý do.

Lệnh:

  item_impacts.py plan   --out <dir> [--drop-template 3640] [--no-drop] [--no-impact]
        dựng <dir>/configs/{StandardImpact,MonsterDropBoxs}.txt + plan.json + item_impacts.tsv (chỉ đọc R)
  item_impacts.py apply  --staging <dir> [--dry-run]
        kiểm lại điều kiện trên bảng SỐNG, sao lưu R/backups/item-impacts-<UTC>/, rồi chép vào R
  item_impacts.py reload [--port 16002] [--only std_impact|drop_rate]
        nạp nóng hai bảng qua debug_console của Game zone 1 (KHÔNG restart, KHÔNG `clearcache`).
        `clearcache` của `reload_configs.exp` xoá cache chunk Lua TOÀN TIẾN TRÌNH — nguy hiểm khi agent khác
        đang sửa dở `.lua` trong cây làm việc, nên ở đây chỉ gọi đúng hai hàm reload.
        ⚠ **CHƯA CHẠY THẬT** (17/09): đợt áp đầu tiên trùng cửa sổ restart của người điều phối nên bảng được nạp
        bằng restart, lệnh này không cần dùng. Đường gọi đã đọc kỹ (`scenemanager_core:reload_std_impact` /
        `reload_drop_rate` → `.CfgDB` đọc lại file → phát cho mọi cảnh; mẫu `GameServer/reload_drop.exp` dùng
        đúng ba dịch vụ đó) nhưng hãy coi là chưa kiểm chứng cho tới lần chạy đầu.
  item_impacts.py verify --plan <plan.json> [--staging <dir>]
        GBK toàn file, ID tăng dần, mọi ID trong plan đã có mặt và **khớp byte** với nguồn (0.85 cho impact,
        dòng mẫu cho drop), logic của dòng impact mới đã đăng ký trong impactenginer, và trong cảnh server thực
        sự dựng đã có quái rơi đồ được.
        Chỉ xét ĐÚNG các ID trong plan: 329 ID "đổi nghĩa" là dòng CY có sẵn, không phải việc của công cụ này —
        chúng được liệt kê riêng ở khoá `changed_meaning` như THÔNG TIN, không phải lỗi.

Idempotent: chạy `plan` lần hai sau khi đã `apply` thì danh sách thiếu rỗng và `apply` báo `nothing to do`.

Chạy trong WSL TLBB bằng root:
    python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/item_impacts.py <lệnh>
Đặc tả: `Docs/specs/net/item_vi.md`.
"""
import argparse
import bisect
import datetime
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table, write_table, g, sha  # noqa: E402

R = '/home/ubuntu/cys-test-20260913'
OLD = '/home/ubuntu'                       # server gốc 0.85, chỉ đọc
SI = 'configs/StandardImpact.txt'
MDB = 'configs/MonsterDropBoxs.txt'
DBC = 'configs/DropBoxContent.txt'
MAE = 'configs/MonsterAttrExTable.txt'
SCENE_INFO = 'configs/SceneInfo.ini'
ITEM_SCRIPTS = 'Game_2/Script/scripts/obj/commonitem'
IMPACT_ENGINER = 'GameServer/lualib/impactenginer.lua'
MARK = 'item-impacts'

SI_ID, SI_NAME, SI_LOGIC = 0, 1, 2
DROP_TARGETS = list(range(900, 910))       # 高山白猿 … 山蛛: quái dã ngoại Vô Lượng Sơn (cảnh 6/73/74)
DROP_TEMPLATE = 3640                       # 贼兵喽啰 cấp 10, hộp 75 (30700232) + 76 (20310176/20310180)


# ---------------------------------------------------------------- đọc dữ liệu

def item_script_impacts(root):
    """{ID impact: [tên file script]} lấy từ `g_Impact1/2` của scripts/obj/commonitem/*.lua."""
    d = os.path.join(root, ITEM_SCRIPTS)
    used = {}
    for fn in sorted(os.listdir(d)):
        if not fn.endswith('.lua'):
            continue
        with open(os.path.join(d, fn), encoding='utf-8', errors='replace') as f:
            text = f.read()
        for m in re.finditer(r'g_Impact[12]\s*=\s*(-?\d+)', text):
            v = int(m.group(1))
            if v > 0:
                used.setdefault(v, []).append(fn)
    return used


def by_id(table):
    return {int(r[0]): r for r in table['rows']}


def scene_rows(root):
    """{id cảnh: {khoá: giá trị}} của SceneInfo.ini (GBK)."""
    with open(os.path.join(root, SCENE_INFO), 'rb') as f:
        data = f.read().decode('gbk', errors='replace')
    cur, info = None, {}
    for line in data.splitlines():
        line = line.split(';')[0].strip()
        m = re.match(r'\[scene(\d+)\]', line)
        if m:
            cur = int(m.group(1))
            info[cur] = {}
            continue
        if cur is not None and '=' in line:
            k, v = line.split('=', 1)
            info[cur][k.strip()] = v.strip()
    return info


def live_scene_monsters(root):
    """{type quái: [id cảnh]} cho MỌI cảnh server thực sự dựng (scenemanager_core: active=1 AND type=0)."""
    out = {}
    for sid, v in sorted(scene_rows(root).items()):
        if v.get('active') != '1' or v.get('type') != '0':
            continue
        f = v.get('file', '')
        base = f[:-4] if f.endswith('.scn') else f
        p = os.path.join(root, 'Game_2/Scene/%s_monster.ini' % base)
        if not os.path.exists(p):
            continue
        with open(p, 'rb') as fh:
            raw = fh.read().decode('gbk', errors='replace')
        for line in raw.splitlines():
            line = line.split(';')[0].strip()
            if line.startswith('type='):
                try:
                    t = int(line[5:])
                except ValueError:
                    continue
                out.setdefault(t, [])
                if sid not in out[t]:
                    out[t].append(sid)
    return out


def cells(row, names, pattern):
    """Giá trị số của mọi cột có tên khớp `pattern`, bỏ -1 và ô rỗng."""
    out = []
    for i, n in enumerate(names):
        if i < len(row) and re.match(pattern, g(n)):
            s = g(row[i]).strip()
            if s.lstrip('-').isdigit() and int(s) != -1:
                out.append(int(s))
    return out


def registered_logics(root):
    """logic_id đã có dòng trong bảng đăng ký của impactenginer."""
    with open(os.path.join(root, IMPACT_ENGINER), encoding='utf-8', errors='replace') as f:
        text = f.read()
    return set(int(m) for m in re.findall(r'\[(\d+)\]\s*=\s*"scene\.skill\.impact_logic\.', text))


# ---------------------------------------------------------------- plan

def build_impact_rows(note):
    live = read_table(os.path.join(R, SI))
    old = read_table(os.path.join(OLD, SI))
    if live['types'] != old['types'] or live['names'] != old['names']:
        raise SystemExit('hai bang StandardImpact khac cot -> tu choi (luat chep nguyen khong con dung)')
    have, src = by_id(live), by_id(old)
    used = item_script_impacts(R)
    missing = sorted(v for v in used if v not in have)
    add, skip = [], []
    for i in missing:
        if i in src:
            add.append(src[i])
            note('impact', i, 'copy85', 'ok', '%d script; 0.85="%s" logic %s'
                 % (len(used[i]), g(src[i][SI_NAME]), g(src[i][SI_LOGIC])), used[i][:3])
        else:
            skip.append(i)
            note('impact', i, 'copy85', 'skip', 'khong co o ca hai bang', used[i][:3])
    return live, add, skip, used, missing


def build_drop_rows(template_id, note):
    live = read_table(os.path.join(R, MDB))
    boxes = read_table(os.path.join(R, DBC))
    attrs = read_table(os.path.join(R, MAE))
    have, box_by_id, attr_by_id = by_id(live), by_id(boxes), by_id(attrs)
    if template_id not in have:
        raise SystemExit('dong mau %d khong co trong MonsterDropBoxs -> tu choi' % template_id)
    tpl = have[template_id]
    dids = cells(tpl, live['names'], r'DID\d+')
    if not dids:
        raise SystemExit('dong mau %d khong tro toi hop nao -> tu choi' % template_id)
    usable = []
    for b in dids:
        if b not in box_by_id:
            raise SystemExit('hop %d cua dong mau khong co trong DropBoxContent -> tu choi' % b)
        if cells(box_by_id[b], boxes['names'], r'Item\d+ID'):
            usable.append(b)
    if not usable:
        raise SystemExit('moi hop cua dong mau %d deu rong -> tu choi' % template_id)
    in_scene = live_scene_monsters(R)
    add, skip = [], []
    for t in DROP_TARGETS:
        if t in have:
            skip.append(t)
            note('drop', t, 'clonerow', 'skip', 'da co dong trong MonsterDropBoxs', [])
            continue
        if t not in attr_by_id:
            skip.append(t)
            note('drop', t, 'clonerow', 'skip', 'khong co trong MonsterAttrExTable', [])
            continue
        if t not in in_scene:
            skip.append(t)
            note('drop', t, 'clonerow', 'skip', 'khong xuat hien o canh active=1 type=0 nao', [])
            continue
        row = list(tpl)
        row[0] = str(t).encode('ascii')       # CHỈ đổi Data_Index
        add.append(row)
        note('drop', t, 'clonerow', 'ok',
             'chep dong %d; ten="%s" cap %s; hop con vat pham: %s'
             % (template_id, g(attr_by_id[t][1]), g(attr_by_id[t][3]), usable),
             ['scene %d' % s for s in in_scene[t]])
    return live, add, skip, usable


def merge_sorted(table, add):
    """Chèn các dòng mới vào đúng vị trí sắp xếp theo Data_Index; dòng cũ giữ nguyên đối tượng."""
    rows = list(table['rows'])
    keys = [int(r[0]) for r in rows]
    for r in sorted(add, key=lambda x: int(x[0])):
        i = int(r[0])
        pos = bisect.bisect_left(keys, i)
        rows.insert(pos, r)
        keys.insert(pos, i)
    return rows


def cmd_plan(args):
    lines = []

    def note(kind, ident, rule, state, why, evidence):
        lines.append('\t'.join([kind, str(ident), rule, state, why, ' '.join(str(e) for e in evidence)]))

    out = {'root': R, 'template': args.drop_template}
    staged = []
    if not args.no_impact:
        live, add, skip, used, missing = build_impact_rows(note)
        out['impact'] = {'table': SI, 'live_rows': len(live['rows']), 'ids_used_by_scripts': len(used),
                         'missing': len(missing), 'add': sorted(int(r[0]) for r in add), 'skip': skip}
        rows = merge_sorted(live, add)
        write_table(os.path.join(args.out, SI), live['types'], live['names'], rows, live['eol'])
        staged.append((SI, len(live['rows']), len(rows)))
    if not args.no_drop:
        live, add, skip, usable = build_drop_rows(args.drop_template, note)
        out['drop'] = {'table': MDB, 'live_rows': len(live['rows']), 'boxes_with_items': usable,
                       'add': sorted(int(r[0]) for r in add), 'skip': skip}
        rows = merge_sorted(live, add)
        write_table(os.path.join(args.out, MDB), live['types'], live['names'], rows, live['eol'])
        staged.append((MDB, len(live['rows']), len(rows)))
    out['staged'] = [{'table': t, 'before': a, 'after': b, 'added': b - a} for t, a, b in staged]
    os.makedirs(args.out, exist_ok=True)
    with open(os.path.join(args.out, 'item_impacts.tsv'), 'w', encoding='utf-8') as f:
        f.write('kind\tid\trule\tstate\twhy\tevidence\n')
        f.write('\n'.join(lines) + '\n')
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print(json.dumps(out, ensure_ascii=False)[:2000])


# ---------------------------------------------------------------- apply

def apply_one(rel, staging, dry, report):
    src_file = os.path.join(staging, rel)
    if not os.path.exists(src_file):
        return None
    dst = os.path.join(R, rel)
    base, new = read_table(dst), read_table(src_file)
    if base['types'] != new['types'] or base['names'] != new['names']:
        raise SystemExit('%s: dong kieu/ten cot doi -> tu choi' % rel)
    old_by, new_by = by_id(base), by_id(new)
    for i, r in old_by.items():
        if i not in new_by:
            raise SystemExit('%s: dong cu %d bien mat -> tu choi' % (rel, i))
        if new_by[i] != r:
            raise SystemExit('%s: dong cu %d bi doi -> tu choi' % (rel, i))
    added = sorted(set(new_by) - set(old_by))
    ids = [int(r[0]) for r in new['rows']]
    if any(ids[k] >= ids[k + 1] for k in range(len(ids) - 1)):
        raise SystemExit('%s: Data_Index khong tang dan -> tu choi' % rel)
    report[rel] = {'before': len(base['rows']), 'after': len(new['rows']),
                   'added': len(added), 'added_ids': added}
    if dry or not added:
        return None
    return dst, src_file


def cmd_apply(args):
    report, todo = {}, []
    for rel in (SI, MDB):
        r = apply_one(rel, args.staging, args.dry_run, report)
        if r:
            todo.append(r)
    if args.dry_run:
        print(json.dumps({'dry_run': True, 'tables': report}, ensure_ascii=False))
        return
    if not todo:
        print(json.dumps({'nothing to do': True, 'tables': report}, ensure_ascii=False))
        return
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(R, 'backups', '%s-%s' % (MARK, stamp))
    os.makedirs(bak, exist_ok=True)
    for dst, src_file in todo:
        shutil.copy2(dst, os.path.join(bak, os.path.basename(dst)))
    for dst, src_file in todo:
        shutil.copy2(src_file, dst)
    for rel in report:
        report[rel]['sha'] = sha(os.path.join(R, rel))
    print(json.dumps({'backup': bak, 'tables': report}, ensure_ascii=False))


# ---------------------------------------------------------------- verify

def cmd_reload(args):
    """Gọi reload_std_impact / reload_drop_rate qua debug_console (Game zone 1, cổng 16002).

    Cả hai hàm ở `lualib/scenemanager_core.lua` đều làm đúng hai việc: bảo `.CfgDB` đọc LẠI FILE, rồi phát
    bảng mới cho mọi cảnh. Không đụng cache chunk Lua, nên an toàn khi agent khác đang sửa dở `.lua`.
    """
    import socket
    groups = [args.only] if args.only else ['std_impact', 'drop_rate']
    services = ['.SceneManager', '.Copyscenemanager', '.Dynamicscenemanager']
    sent, out = [], []
    s = socket.create_connection(('127.0.0.1', args.port), timeout=10)
    s.settimeout(6)
    try:
        try:
            out.append(s.recv(4096).decode('utf-8', 'replace'))
        except socket.timeout:
            pass
        for grp in groups:
            for svc in services:
                cmd = 'call %s "reload_%s"\n' % (svc, grp)
                s.sendall(cmd.encode('utf-8'))
                sent.append(cmd.strip())
                try:
                    out.append(s.recv(8192).decode('utf-8', 'replace'))
                except socket.timeout:
                    out.append('(timeout)')
    finally:
        s.close()
    print(json.dumps({'port': args.port, 'sent': sent, 'console': ''.join(out)[-1500:]}, ensure_ascii=False))


def cmd_verify(args):
    errors, info = [], {}
    root = args.staging if args.staging else R
    plan_path = args.plan or (os.path.join(args.staging, 'plan.json') if args.staging else '')
    if not plan_path or not os.path.exists(plan_path):
        raise SystemExit('can --plan <plan.json> (hoac --staging chua plan.json)')
    with open(plan_path, encoding='utf-8') as f:
        plan = json.load(f)
    planned_impacts = plan.get('impact', {}).get('add', [])
    planned_drops = plan.get('drop', {}).get('add', [])
    template = plan.get('template', DROP_TEMPLATE)
    src = by_id(read_table(os.path.join(OLD, SI)))
    used = item_script_impacts(R)

    for rel in (SI, MDB):
        p = os.path.join(root, rel)
        with open(p, 'rb') as f:
            data = f.read()
        try:
            data.decode('gbk')
        except UnicodeDecodeError as e:
            errors.append('%s: khong phai GBK: %s' % (rel, e))
        t = read_table(p)
        ids = [int(r[0]) for r in t['rows']]
        if any(ids[k] >= ids[k + 1] for k in range(len(ids) - 1)):
            errors.append('%s: Data_Index khong tang dan' % rel)
        if len(set(ids)) != len(ids):
            errors.append('%s: Data_Index trung' % rel)
        for r in t['rows']:
            if len(r) != len(t['types']):
                errors.append('%s: dong %s co %d cot, can %d' % (rel, g(r[0]), len(r), len(t['types'])))
                break
        info[rel] = {'rows': len(t['rows']), 'sha': sha(p)}

    # --- impact: CHỈ xét các ID trong plan (dòng do công cụ này thêm)
    live = by_id(read_table(os.path.join(root, SI)))
    missing_now = [i for i in planned_impacts if i not in live]
    differ = [i for i in planned_impacts if i in live and live[i] != src.get(i)]
    still = sorted(v for v in used if v not in live)
    info['impact'] = {'ids_used_by_scripts': len(used), 'planned': len(planned_impacts),
                      'present_now': len(planned_impacts) - len(missing_now),
                      'not_added': missing_now, 'not_byte_identical': differ,
                      'still_missing_after_apply': still}
    if missing_now:
        errors.append('StandardImpact: %d ID trong plan chua co mat: %s' % (len(missing_now), missing_now[:10]))
    if differ:
        errors.append('StandardImpact: %d dong moi khong khop byte voi ban 0.85: %s' % (len(differ), differ[:10]))

    logics = registered_logics(R)
    unreg = sorted({int(g(live[i][SI_LOGIC])) for i in planned_impacts
                    if i in live and g(live[i][SI_LOGIC]).lstrip('-').isdigit()} - logics)
    info['impact']['logic_not_registered'] = unreg
    if unreg:
        errors.append('logic cua dong MOI chua dang ky trong impactenginer: %s' % unreg)

    # 329 ID "đổi nghĩa" là dòng CY có sẵn — KHÔNG phải việc của công cụ này, chỉ liệt kê
    changed = sorted(i for i in used if i in live and i in src and live[i] != src[i])
    info['changed_meaning'] = {'count': len(changed),
                               'sample': [{'id': i, 'cy': g(live[i][SI_NAME]), 'cy_logic': g(live[i][SI_LOGIC]),
                                           'v085': g(src[i][SI_NAME])} for i in changed[:5]]}

    mdb = by_id(read_table(os.path.join(root, MDB)))
    tpl = mdb.get(template)
    bad_drop = []
    for t in planned_drops:
        row = mdb.get(t)
        if not row:
            bad_drop.append({'id': t, 'why': 'chua co dong'})
        elif tpl is None:
            bad_drop.append({'id': t, 'why': 'khong tim thay dong mau %d' % template})
        elif row[1:] != tpl[1:]:
            bad_drop.append({'id': t, 'why': 'khac dong mau ngoai o Data_Index'})
    info['drop_rows'] = {'template': template, 'planned': len(planned_drops), 'bad': bad_drop}
    if bad_drop:
        errors.append('MonsterDropBoxs: %d dong moi khong dung luat clonerow' % len(bad_drop))

    boxes = read_table(os.path.join(R, DBC))
    box_by = by_id(boxes)
    live_m = live_scene_monsters(R)
    droppable = []
    for t, scenes in sorted(live_m.items()):
        row = mdb.get(t)
        if not row:
            continue
        for b in cells(row, read_table(os.path.join(root, MDB))['names'], r'DID\d+'):
            if b in box_by and cells(box_by[b], boxes['names'], r'Item\d+ID'):
                droppable.append({'monster': t, 'scenes': scenes, 'box': b})
                break
    info['drop'] = {'droppable_monsters_in_running_scenes': droppable}
    if not droppable:
        errors.append('van khong quai nao trong canh dang chay roi do duoc')

    print(json.dumps({'ok': not errors, 'errors': errors, 'info': info}, ensure_ascii=False, indent=1))
    return 1 if errors else 0


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('plan')
    p.add_argument('--out', required=True)
    p.add_argument('--drop-template', type=int, default=DROP_TEMPLATE)
    p.add_argument('--no-drop', action='store_true')
    p.add_argument('--no-impact', action='store_true')
    p = sub.add_parser('apply')
    p.add_argument('--staging', required=True)
    p.add_argument('--dry-run', action='store_true')
    p = sub.add_parser('reload')
    p.add_argument('--port', type=int, default=16002)     # debug_console cua Game zone 1 (server rieng)
    p.add_argument('--only', choices=('std_impact', 'drop_rate'), default='')
    p = sub.add_parser('verify')
    p.add_argument('--staging', default='')
    p.add_argument('--plan', default='')
    args = ap.parse_args()
    if args.cmd == 'plan':
        cmd_plan(args)
    elif args.cmd == 'apply':
        cmd_apply(args)
    elif args.cmd == 'reload':
        cmd_reload(args)
    else:
        sys.exit(cmd_verify(args))


if __name__ == '__main__':
    main()
