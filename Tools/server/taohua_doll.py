# -*- coding: utf-8 -*-
"""taohua_doll.py — bộ kiểm CHỈ ĐỌC cho nhóm chiêu "điều khiển 离人偶" của 桃花岛 (phái 13).

Chạy trong WSL (root), đọc bảng thật của server riêng. KHÔNG ghi gì vào server.

    python3 /mnt/c/TLBB/085/CY-Source/Tools/server/taohua_doll.py verify --out <dir>
    python3 .../taohua_doll.py plan   --out <dir>     # liệt kê việc PHẢI sửa (ở bảng của agent khác)
    python3 .../taohua_doll.py apply                  # từ chối: không có gì thuộc phạm vi ghi của agent này

Vì sao có `plan` mà `apply` từ chối: sau khi đo, KHÔNG có thay đổi nào cần làm trong
`lualib/cy_four_combat/**` hay `lualib/cy_idcollections.lua` (xem `Timeline\\handoff\\taohua-doll.md`).
Việc còn lại nằm ở `configs/StandardImpact.txt` — bảng của `impact-data` — nên `plan` chỉ *liệt kê*
và `apply` từ chối thay vì âm thầm sửa bảng ngoài phạm vi.

Sáu phép kiểm:
  1. set340    — tập ID 340 (桃花岛共情技能) phải TRÙNG KHÍT tập template có tip "需要离人偶出战"
  2. cond16    — mọi template 桃花岛 có 条件和消耗逻辑 = 16, giá trị 共情, và có/không thuộc tập 340
  3. summon    — chuỗi "xuất chiến": chiêu tạo rối, dòng quái 傀儡模型, vật thể đặc biệt, bẫy để lại
  4. impacts   — mọi ô impact của 7 chiêu con rối → dòng StandardImpact thật; đánh dấu VA CHẠM/THIẾU
  5. series    — ô impact chạy theo cấp có rơi trọn vào khối 坐骑 không (bằng chứng va chạm dải ID)
  6. lua       — `luac5.4 -p` mọi file Lua của `cy_four_combat` + `cy_idcollections.lua`
"""
import argparse
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, 'menpai_audit'))
from tlbbtab import load, num, R  # noqa: E402

GS = os.path.join(R, 'GameServer')
CFG = os.path.join(R, 'configs')

TAO_FACTION = 13
TAO_TEMPLATES = range(3800, 3837)
COLLECTION_ID = 340
NEED_DOLL_TIP = '需要离人偶出战'
SUMMON_TIP = '将离人偶投掷到'
DOLL_MONSTER = 17097
# `tao.lua` refs: special_objects 936/939 → resolve → 2100/2101
TAO_SPECIAL_OBJS = (2100, 2101)
# Khối 坐骑 của bảng GL/HJS: 逻辑ID 97 + 分类ID 99. Một hiệu ứng 桃花岛 không bao giờ là buff thú cưỡi.
MOUNT_LOGIC, MOUNT_CLASS = 97, 99
DOLL_SKILLS = (3801, 3804, 3806, 3807, 3809, 3820, 3822)


def _tables():
    tn, trows = load(os.path.join(CFG, 'SkillTemplate_V1.txt'))
    dn, drows = load(os.path.join(CFG, 'SkillData_V1.txt'))
    sn, srows = load(os.path.join(CFG, 'StandardImpact.txt'))
    on, orows = load(os.path.join(CFG, 'SpecialObjData.txt'))
    mn, mrows = load(os.path.join(CFG, 'MonsterAttrExTable.txt'))
    tm = {num(r['ID,(技能系的ID)']): r for r in trows}
    sd = {num(r[dn[0]]): r for r in drows}
    si = {}
    for r in srows:
        si.setdefault(num(r[sn[0]]), r)
    so = {num(r[on[0]]): r for r in orows}
    mo = {num(r[mn[0]]): r for r in mrows}
    return dict(tn=tn, dn=dn, sn=sn, on=on, mn=mn, tm=tm, sd=sd, si=si, so=so, mo=mo)


def _label_cells(T, data_id):
    """cặp (参数说明, 参数值) của một dòng SkillData, theo vị trí cột như bảng thật"""
    r = T['sd'].get(data_id)
    if not r:
        return None
    cells = r['__cells']
    base = T['dn'].index('目标级别') + 3
    out = []
    i = base
    while i + 1 < len(cells):
        lab, val = cells[i].strip(), cells[i + 1].strip()
        if lab and lab != '-1':
            out.append((lab, val))
        i += 2
    return out


def _cond_slots(T, data_id):
    """ba ô điều kiện: [(logic, p0, p1, nhãn), ...] — bỏ ô -1"""
    r = T['sd'].get(data_id)
    if not r:
        return []
    def lst(name):
        v = r.get(name)
        return v if isinstance(v, list) else [v]
    logics = lst('条件和消耗逻辑')
    labels = lst('条件或消耗参数说明')
    values = lst('条件或消耗参数值')[0]
    values = values if isinstance(values, list) else [values]
    # '条件或消耗参数值' lặp 6 lần = 3 ô × 2 tham số, đọc thẳng từ __cells cho chắc
    cells = r['__cells']
    first = T['dn'].index('条件或消耗参数说明')
    out = []
    for k in range(3):
        base = first + k * 4
        lab = cells[base].strip() if base < len(cells) else '-1'
        lg = num(cells[base + 1]) if base + 1 < len(cells) else -1
        p0 = num(cells[base + 2]) if base + 2 < len(cells) else -1
        p1 = num(cells[base + 3]) if base + 3 < len(cells) else -1
        if lg is not None and lg != -1:
            out.append(dict(slot=k + 1, logic=lg, p0=p0, p1=p1, label=lab))
    return out


def _lv1(T, tid):
    r = T['tm'].get(tid)
    return num(r['心法1级对应的实际技能ID']) if r else None


def _tip(T, data_id):
    r = T['sd'].get(data_id)
    return (r.get('技能描述(FOR TIP)$1$') or '') if r else ''


def _name(T, tid):
    r = T['tm'].get(tid)
    return (r['技能名字$1$'] if r else '') or ''


def _collection_340():
    """đọc tập ID 340 từ lualib/cy_idcollections.lua (bảng sinh máy)"""
    path = os.path.join(GS, 'lualib', 'cy_idcollections.lua')
    text = open(path, encoding='utf-8').read()
    m = re.search(r'\[%d\]\s*=\s*\{type\s*=\s*(\d+),\s*ids\s*=\s*\{(.*?)\}\}' % COLLECTION_ID, text)
    if not m:
        return None, None
    ids = sorted(int(x) for x in re.findall(r'\[(\d+)\]\s*=\s*true', m.group(2)))
    return int(m.group(1)), ids


# ------------------------------------------------------------------ phép kiểm
def check_set340(T):
    ctype, ids = _collection_340()
    need = []
    for tid in TAO_TEMPLATES:
        d = _lv1(T, tid)
        if d is None:
            continue
        if NEED_DOLL_TIP in _tip(T, d):
            need.append(tid)
    need = sorted(need)
    return dict(
        name='set340',
        collection_type=ctype,
        collection_ids=ids,
        tip_need_doll=need,
        tip_text=NEED_DOLL_TIP,
        equal=(ids == need),
        note='Tập 340 chỉ có ở IDCollections của tlbb15 (bảng client CY 3.71 KHÔNG có dòng 340); '
             'kiểm bằng cách so với tip CY "%s" của chính server.' % NEED_DOLL_TIP,
        ok=(ids == need),
    )


def check_cond16(T):
    rows = []
    _, ids340 = _collection_340()
    ids340 = ids340 or []
    for tid in TAO_TEMPLATES:
        d = _lv1(T, tid)
        if d is None:
            continue
        slots = [s for s in _cond_slots(T, d) if s['logic'] == 16]
        if not slots:
            continue
        rows.append(dict(template=tid, name=_name(T, tid), data_id=d,
                         empathy=slots[0]['p0'], label=slots[0]['label'],
                         in_collection_340=(tid in ids340),
                         gated_by_doll=(tid in ids340),
                         charged=(tid in ids340)))
    ungated = [r['template'] for r in rows if not r['in_collection_340']]
    return dict(
        name='cond16', rows=rows, charged_count=len([r for r in rows if r['charged']]),
        not_charged=ungated,
        note='condition_cy.logics[16].applies đòi kỹ năng ∈ tập 340 ⇒ các template ngoài tập vừa KHÔNG bị '
             'chặn theo 共情 vừa KHÔNG bị trừ 共情, dù SkillData của chúng khai đúng ô 类型16.',
        ok=True,
    )


def check_summon(T):
    out = dict(name='summon', ok=True, items=[])

    def add(key, ok, detail):
        out['items'].append(dict(key=key, ok=bool(ok), detail=detail))
        if not ok:
            out['ok'] = False

    summoners = []
    for tid in TAO_TEMPLATES:
        d = _lv1(T, tid)
        if d is not None and SUMMON_TIP in _tip(T, d):
            summoners.append(tid)
    add('summon_skill', summoners == [3801],
        'chiêu có tip "%s" = %s (%s)' % (SUMMON_TIP, summoners,
                                         ', '.join(_name(T, t) for t in summoners)))
    m = T['mo'].get(DOLL_MONSTER)
    add('doll_monster', m is not None,
        'MonsterAttrEx %d = %s, 友好值=%s, HP上限=%s' % (
            DOLL_MONSTER, m.get('名称$1$') if m else 'KHONG CO DONG',
            m.get('友好值') if m else '-', m.get('HP上限') if m else '-'))
    for oid in TAO_SPECIAL_OBJS:
        r = T['so'].get(oid)
        add('special_%d' % oid, r is not None,
            'SpecialObjData %d = %s' % (oid, r.get('名称$1$') if r else 'KHONG CO DONG'))
    # bẫy để lại sau khi thu hồi rối (3804), đọc đủ 16 cấp
    d = _lv1(T, 3804)
    traps = set()
    for lv in range(16):
        for lab, val in (_label_cells(T, d + lv) or []):
            if lab == '傀儡回收后，原地留下陷阱ID':
                traps.add(num(val))
    for tid in sorted(x for x in traps if x and x > 0):
        r = T['so'].get(tid)
        add('recall_trap_%d' % tid, r is not None,
            'SpecialObjData %d = %s (ô 傀儡回收后，原地留下陷阱ID của 3804, 16/16 cấp)'
            % (tid, r.get('名称$1$') if r else 'KHONG CO DONG'))
    return out


def _impact_state(T, iid):
    r = T['si'].get(iid)
    if not r:
        return 'missing', None, None
    name = r.get('效果名称$1$') or ''
    logic = num(r.get('逻辑ID'))
    klass = num(r.get('分类ID（专门用于识别某一类BUFF）'))
    if logic == MOUNT_LOGIC and klass == MOUNT_CLASS:
        return 'collision_mount', name, logic
    return 'ok', name, logic


def check_impacts(T):
    rows = []
    bad = 0
    for tid in DOLL_SKILLS:
        d = _lv1(T, tid)
        for lv in (0, 3):
            for lab, val in (_label_cells(T, d + lv) or []):
                iid = num(val)
                if not isinstance(iid, int) or iid <= 1000:
                    continue
                if not any(k in lab for k in ('效果', 'BUFF', 'buff', '陷阱')):
                    continue
                if '陷阱' in lab:
                    r = T['so'].get(iid)
                    state = 'ok' if r else 'missing'
                    nm, lg = (r.get('名称$1$') if r else None), None
                    table = 'SpecialObjData'
                else:
                    state, nm, lg = _impact_state(T, iid)
                    table = 'StandardImpact'
                if state != 'ok':
                    bad += 1
                rows.append(dict(template=tid, name=_name(T, tid), level=lv + 1, label=lab,
                                 id=iid, table=table, state=state, row_name=nm, logic=lg))
    return dict(name='impacts', rows=rows, bad=bad,
                note='state=collision_mount ⇒ ID của CY rơi vào khối 坐骑 của bảng GL/HJS '
                     '(逻辑ID %d + 分类ID %d): impact VẪN lên người, KHÔNG báo lỗi, nhưng là buff thú cưỡi '
                     'rỗng thay cho hiệu ứng thật.' % (MOUNT_LOGIC, MOUNT_CLASS),
                ok=(bad == 0))


def check_series(T):
    """ô impact chạy theo cấp: nếu 16 cấp rơi trọn vào khối 坐骑 thì đó là dải ID va chạm"""
    rows = []
    for tid in DOLL_SKILLS:
        d = _lv1(T, tid)
        per_label = {}
        for lv in range(16):
            for lab, val in (_label_cells(T, d + lv) or []):
                if not any(k in lab for k in ('效果', 'BUFF', 'buff')):
                    continue
                iid = num(val)
                if isinstance(iid, int) and iid > 1000:
                    per_label.setdefault(lab, []).append(iid)
        for lab, ids in per_label.items():
            if len(set(ids)) < 2:
                continue
            states = [_impact_state(T, i)[0] for i in ids]
            rows.append(dict(template=tid, name=_name(T, tid), label=lab,
                             ids=ids, first=ids[0], last=ids[-1],
                             all_mount=all(s == 'collision_mount' for s in states),
                             states=sorted(set(states))))
    return dict(name='series', rows=rows,
                note='dãy ID liên tiếp theo cấp mà mọi mức đều là dòng 坐骑 ⇒ chứng minh va chạm DẢI, '
                     'không phải một ô nhập sai.',
                ok=not any(r['all_mount'] for r in rows))


def check_lua():
    files = []
    root = os.path.join(GS, 'lualib', 'cy_four_combat')
    for n in sorted(os.listdir(root)):
        if n.endswith('.lua'):
            files.append(os.path.join(root, n))
    files.append(os.path.join(GS, 'lualib', 'cy_idcollections.lua'))
    errs = []
    for f in files:
        p = subprocess.run(['luac5.4', '-p', f], capture_output=True, text=True)
        if p.returncode != 0:
            errs.append(dict(file=f, err=(p.stderr or p.stdout).strip()))
    return dict(name='lua', checked=len(files), errors=errs, ok=not errs)


CHECKS = ('set340', 'cond16', 'summon', 'impacts', 'series', 'lua')


def run_all():
    T = _tables()
    res = dict(
        set340=check_set340(T), cond16=check_cond16(T), summon=check_summon(T),
        impacts=check_impacts(T), series=check_series(T), lua=check_lua(),
    )
    res['ok'] = all(res[k]['ok'] for k in CHECKS)
    return res


def as_text(res):
    L = []
    s = res['set340']
    L.append('[set340 ] %s  tap340=%s  tip"%s"=%s' % (
        'TRUNG KHIT' if s['ok'] else 'LECH', s['collection_ids'], s['tip_text'], s['tip_need_doll']))
    c = res['cond16']
    L.append('[cond16 ] %d template co dieu kien 16; bi chan+tru 共情: %s; KHONG bi chan/tru: %s' % (
        len(c['rows']), [r['template'] for r in c['rows'] if r['charged']], c['not_charged']))
    for r in c['rows']:
        L.append('           %d %-10s 共情=%-4s trong340=%s' % (
            r['template'], r['name'], r['empathy'], r['in_collection_340']))
    for it in res['summon']['items']:
        L.append('[summon ] %s %s: %s' % ('OK ' if it['ok'] else 'SAI', it['key'], it['detail']))
    i = res['impacts']
    L.append('[impacts] %d o, %d o hong' % (len(i['rows']), i['bad']))
    for r in i['rows']:
        if r['state'] != 'ok':
            L.append('           HONG %d %s cap%d "%s" -> %s %s = %s (logic %s) [%s]' % (
                r['template'], r['name'], r['level'], r['label'], r['table'], r['id'],
                r['row_name'], r['logic'], r['state']))
    for r in res['series']['rows']:
        if r['all_mount']:
            L.append('[series ] VA CHAM DAI %d %s "%s": %d..%d deu la dong 坐骑' % (
                r['template'], r['name'], r['label'], r['first'], r['last']))
    l = res['lua']
    L.append('[lua    ] luac5.4 -p %d file: %s' % (l['checked'], 'sach' if l['ok'] else l['errors']))
    L.append('OK = %s' % res['ok'])
    return '\n'.join(L)


def plan(res):
    """việc PHẢI sửa — và ai sở hữu file đó"""
    todo = []
    for r in res['impacts']['rows']:
        if r['state'] == 'collision_mount':
            todo.append(dict(owner='impact-data', file='configs/StandardImpact.txt',
                             what='ID %d cua %d %s (o "%s") dang la dong 坐骑 "%s" — can doi ID '
                                  'trong SkillData_V1 sang dai trong, hoac nhap dong CY o ID khac'
                                  % (r['id'], r['template'], r['name'], r['label'], r['row_name'])))
        elif r['state'] == 'missing':
            todo.append(dict(owner='impact-data', file='configs/StandardImpact.txt',
                             what='ID %d cua %d %s (o "%s") THIEU dong' % (
                                 r['id'], r['template'], r['name'], r['label'])))
    seen, uniq = set(), []
    for t in todo:
        k = t['what']
        if k not in seen:
            seen.add(k)
            uniq.append(t)
    return dict(in_scope=[], out_of_scope=uniq,
                note='Khong co viec nao nam trong pham vi ghi cua taohua-doll '
                     '(lualib/cy_four_combat/**, lualib/cy_idcollections.lua): tap 340 dung, '
                     'chuoi xuat chien 3801 dang song.')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('cmd', choices=('verify', 'plan', 'apply'))
    ap.add_argument('--out', help='thu muc ghi bao cao (json + txt)')
    a = ap.parse_args()
    if a.cmd == 'apply':
        print('apply: TU CHOI. Khong co thay doi nao thuoc pham vi ghi cua taohua-doll.\n'
              'Chay `plan` de xem viec con lai va file do thuoc agent nao.')
        return 2
    res = run_all()
    text = as_text(res)
    if a.cmd == 'plan':
        res['plan'] = plan(res)
        text += '\n\n--- plan ---\n' + json.dumps(res['plan'], ensure_ascii=False, indent=2)
    print(text)
    if a.out:
        os.makedirs(a.out, exist_ok=True)
        with open(os.path.join(a.out, '%s.json' % a.cmd), 'w', encoding='utf-8') as f:
            json.dump(res, f, ensure_ascii=False, indent=2)
        with open(os.path.join(a.out, '%s.txt' % a.cmd), 'w', encoding='utf-8') as f:
            f.write(text + '\n')
    return 0 if res['ok'] else 1


if __name__ == '__main__':
    sys.exit(main())
