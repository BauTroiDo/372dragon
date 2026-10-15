# -*- coding: utf-8 -*-
"""cys_i18nscope_apply.py - CYS-I18NSCOPE: AP ban rut gon theo cap (KHOA, KHUNG).

Hai viec, hai lenh:

  `drop`   Xoa nhung dong ghi de DA THUA: ban day du vua o MOI o cua MOI khung dung khoa do
           (khong chi khung ngan sach). Khong can co che gi moi - chi xoa dong, ban dich that
           tu quay lai. Day la dot re nhat.

  `frame`  Sinh bang ghi de theo KHUNG cho cac khoa `rescue-table.json` noi ban day du VUA:
             - khoa goc  giu nguyen BAN RUT GON  (moi khung hep khong phai dong gi);
             - khoa moi `KHOA@Khung` mang BAN DAY DU;
             - `82-frame-keys.py` doi `#{KHOA}` -> `#{KHOA@Khung}` trong DUNG nhung khung do.
           Huong nay chon co chu dich: no KHONG dong vao mot dong nao cua 3.374 khung hep dang
           chay, nen mot dot hong chi anh huong dung nhung khung no sua. `stage-play-2\\Data` la
           junction toi `Assets\\CanonicalCY\\Data` => moi thay doi vao THANG ban nguoi dung choi.

LUAT AN TOAN cua ca hai lenh (kiem trƯOC khi ghi, khong tin bang trong tay):
  * do lai tren `m-short/overflow.csv` + `m-full/overflow.csv` (FreeType, hinh hoc CEGUI);
  * mot khoa chi vao `drop` khi ban day du vua o **moi** o cua **moi** khung;
  * mot (khoa, khung) chi vao `frame` khi ban day du vua o **moi** o cua **dung khung do**;
  * `cy_translate.validate(zh, vi)` chay tren tung gia tri se ghi - ke ca gia tri do chinh
    duong ong sinh ra (ban dich tay khong an toan hon ban dich may, va nguoc lai cung the).

usage:
  python -B cys_i18nscope_apply.py drop  [--limit N] [--write]
  python -B cys_i18nscope_apply.py frame [--limit N] [--write]
  python -B cys_i18nscope_apply.py --selftest
"""
import argparse
import collections
import datetime
import io
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cy_gui_dict as GDICT            # noqa: E402
import cy_translate as CT              # noqa: E402
import cys_i18nscope_leak as LEAK      # noqa: E402
import cys_i18nscope_rescue as RES     # noqa: E402

CYS = LEAK.CYS
LOGS = os.path.join(CYS, 'Build', 'Logs', '2026-09-19-i18n-scope')
OVERRIDE = GDICT.OVERRIDE_TSV
FRAME_TSV = os.path.join(CYS, 'Registry', 'i18n', 'cy_vi_frame_override.tsv')
FRAME_PATCHES = os.path.join(CYS, 'Tools', 'reapply', 'i18n-scope', 'data', 'frame-key-patches.json')
EPS = RES.FIT_EPS


def load_all():
    budget = LEAK.load_budget()
    now, full, zh = LEAK.build_dicts(set(budget))
    _bk, _lr, known, dirs, _st = LEAK.scan_layouts()
    short_rows = RES.read_rows(os.path.join(LOGS, 'm-short', 'overflow.csv'))
    full_rows = RES.read_rows(os.path.join(LOGS, 'm-full', 'overflow.csv'))
    return budget, now, full, zh, known, dirs, short_rows, full_rows


def per_key_slots(short_rows, full_rows, budget):
    """{key: [(frame, layout, widget, box_w, w_full, over_full, visible)]} cho khoa co ngan sach."""
    out = collections.defaultdict(list)
    for k, srow in short_rows.items():
        m = RES.RAW1.match((srow.get('raw') or '').strip())
        if not m or m.group(1) not in budget:
            continue
        frow = full_rows.get(k)
        if frow is None:
            continue
        out[m.group(1)].append({
            'frame': RES.frame_of(srow['layout']), 'layout': srow['layout'],
            'widget': srow['widget'], 'box_w': float(srow['box_w']),
            'w_full': float(frow['text_w']), 'over_full': float(frow['over_px']),
            'over_short': float(srow['over_px']), 'visible': srow.get('visible') == '1'})
    return out


def plan_drop(data):
    """Khoa co the XOA ghi de: ban day du vua o MOI o cua MOI khung."""
    budget, now, full, zh, _known, _dirs, srows, frows = data
    slots = per_key_slots(srows, frows, budget)
    out = []
    for key, ss in sorted(slots.items()):
        if now.get(key, '') == full.get(key, ''):
            continue
        if not ss or any(s['over_full'] > EPS for s in ss):
            continue
        err = CT.validate(zh.get(key, ''), full.get(key, ''))
        out.append({'key': key, 'zh': zh.get(key, ''), 'short': now.get(key, ''),
                    'full': full.get(key, ''), 'budget_px': budget[key][0],
                    'budget_frame': budget[key][1], 'slots': ss, 'validate': err,
                    'frames': sorted({s['frame'] for s in ss})})
    return out


def plan_frame(data):
    """(khoa, khung) co the mang BAN DAY DU: moi o cua khung do chua noi, va khung do khong
    phai khung ngan sach, va o do dang KHONG tran voi ban rut gon."""
    budget, now, full, zh, known, dirs, srows, frows = data
    slots = per_key_slots(srows, frows, budget)
    out = []
    for key, ss in sorted(slots.items()):
        if now.get(key, '') == full.get(key, ''):
            continue
        if ss and all(s['over_full'] <= EPS for s in ss):
            continue        # ban day du vua o MOI noi => thuoc lenh `drop`, re hon; hai dot ROI NHAU
        bset, _k = LEAK.resolve_budget_frames(budget[key][1], known, dirs)
        by_frame = collections.defaultdict(list)
        for s in ss:
            if s['frame'] not in bset:
                by_frame[s['frame']].append(s)
        err = CT.validate(zh.get(key, ''), full.get(key, ''))
        for frame, fs in sorted(by_frame.items()):
            if any(s['over_short'] > EPS for s in fs):
                continue                      # o do da hong san - khong phai viec cua dot nay
            if any(s['over_full'] > EPS for s in fs):
                continue
            out.append({'key': key, 'frame': frame, 'zh': zh.get(key, ''),
                        'short': now.get(key, ''), 'full': full.get(key, ''),
                        'budget_px': budget[key][0], 'budget_frame': budget[key][1],
                        'slots': fs, 'validate': err})
    return out


def write_drop(rows):
    """Xoa dong `#KHOA` khoi cy_vi_override.tsv. Tra ve so dong da xoa."""
    keys = {r['key'] for r in rows}
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    shutil.copy2(OVERRIDE, OVERRIDE + '.bak-i18n-scope-' + stamp)
    with io.open(OVERRIDE, encoding='utf-8', newline='') as f:
        lines = f.read().split('\n')
    keep, gone = [], 0
    for i, ln in enumerate(lines):
        p = ln.split('\t')
        if i and p and p[0].startswith('#') and p[0][1:] in keys:
            gone += 1
            continue
        keep.append(ln)
    with io.open(OVERRIDE, 'w', encoding='utf-8', newline='') as f:
        f.write('\n'.join(keep))
    return gone, stamp


def write_frame(rows):
    """Ghi/hop nhat Registry/i18n/cy_vi_frame_override.tsv + Tools/reapply/i18n-scope/data/..."""
    cur = {}
    if os.path.exists(FRAME_TSV):
        with io.open(FRAME_TSV, encoding='utf-8', newline='') as f:
            for ln in f.read().split('\n')[1:]:
                p = ln.rstrip('\r').split('\t')
                if len(p) >= 3 and p[0]:
                    cur[(p[0], p[1])] = (p[2], p[3] if len(p) > 3 else '')
    note = 'i18n-scope 19/09: ban day du vua khung nay; khoa goc giu ban rut gon'
    added = 0
    for r in rows:
        k = (r['key'], r['frame'])
        if k not in cur:
            added += 1
        cur[k] = (r['full'], note)
    os.makedirs(os.path.dirname(FRAME_TSV), exist_ok=True)
    if os.path.exists(FRAME_TSV):
        stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
        shutil.copy2(FRAME_TSV, FRAME_TSV + '.bak-i18n-scope-' + stamp)
    with io.open(FRAME_TSV, 'w', encoding='utf-8', newline='') as f:
        f.write('ident\tframe\tvi\tnote\n')
        for (key, frame), (vi, nt) in sorted(cur.items()):
            f.write('%s\t%s\t%s\t%s\n' % (key, frame, vi, nt))
    # ban va tham chieu: gom theo TEP layout that (mot khung co the nhieu o)
    patches = collections.defaultdict(list)
    for r in rows:
        for s in r['slots']:
            patches[s['layout']].append({'key': r['key'], 'frame': r['frame'],
                                         'widget': s['widget']})
    os.makedirs(os.path.dirname(FRAME_PATCHES), exist_ok=True)
    with io.open(FRAME_PATCHES, 'w', encoding='utf-8', newline='') as f:
        json.dump({'layouts': {k: sorted({(p['key'], p['frame']) for p in v})
                               for k, v in sorted(patches.items())}}, f,
                  ensure_ascii=False, indent=1)
    return added, len(patches)


def selftest():
    ok = True

    def chk(n, c, d=''):
        nonlocal ok
        print(('PASS ' if c else 'FAIL ') + n + (' | ' + d if d else ''))
        ok = ok and c

    def row(layout, widget, raw, box, tw, over, vis='1'):
        return {'layout': layout, 'widget': widget, 'raw': raw, 'box_w': str(box),
                'text_w': str(tw), 'over_px': str(over), 'visible': vis,
                'font': 'SongTiBmp12', 'pt': '12'}
    # K1: vua o MOI khung  -> drop duoc.  K2: mot khung van tran -> KHONG drop, nhung khung rong
    # van vao `frame`.  K3: o da hong san voi ban rut gon -> khong dung ca hai lenh.
    s = {('Pet/Pet.layout.xml', 'a', '#{K}'): row('Pet/Pet.layout.xml', 'a', '#{K1}', 200, 20, 0),
         ('Big/Big.layout.xml', 'b'): row('Big/Big.layout.xml', 'b', '#{K1}', 200, 20, 0),
         ('Pet/Pet.layout.xml', 'c'): row('Pet/Pet.layout.xml', 'c', '#{K2}', 30, 20, 0),
         ('Big/Big.layout.xml', 'd'): row('Big/Big.layout.xml', 'd', '#{K2}', 200, 20, 0),
         ('Pet/Pet.layout.xml', 'e'): row('Pet/Pet.layout.xml', 'e', '#{K3}', 30, 20, 0),
         ('Bad/Bad.layout.xml', 'f'): row('Bad/Bad.layout.xml', 'f', '#{K3}', 10, 20, 9)}
    fl = {('Pet/Pet.layout.xml', 'a', '#{K}'): row('Pet/Pet.layout.xml', 'a', '#{K1}', 200, 60, 0),
          ('Big/Big.layout.xml', 'b'): row('Big/Big.layout.xml', 'b', '#{K1}', 200, 60, 0),
          ('Pet/Pet.layout.xml', 'c'): row('Pet/Pet.layout.xml', 'c', '#{K2}', 30, 60, 30),
          ('Big/Big.layout.xml', 'd'): row('Big/Big.layout.xml', 'd', '#{K2}', 200, 60, 0),
          ('Pet/Pet.layout.xml', 'e'): row('Pet/Pet.layout.xml', 'e', '#{K3}', 30, 60, 30),
          ('Bad/Bad.layout.xml', 'f'): row('Bad/Bad.layout.xml', 'f', '#{K3}', 10, 60, 50)}
    bud = {'K1': (200, 'Pet'), 'K2': (30, 'Pet'), 'K3': (30, 'Pet')}
    now = {'K1': 'ngan', 'K2': 'ngan', 'K3': 'ngan'}
    full = {'K1': 'day du', 'K2': 'day du', 'K3': 'day du'}
    zh = {'K1': 'a', 'K2': 'b', 'K3': 'c'}
    known = {'pet', 'big', 'bad'}
    dirs = {'pet': {'pet'}, 'big': {'big'}, 'bad': {'bad'}}
    data = (bud, now, full, zh, known, dirs, s, fl)
    d = plan_drop(data)
    chk('drop CHI lay khoa vua o moi khung', [x['key'] for x in d] == ['K1'],
        'lay=%s' % [x['key'] for x in d])
    fr = plan_frame(data)
    got = sorted((x['key'], x['frame']) for x in fr)
    chk('frame lay dung (K2,big), KHONG lay khung ngan sach, KHONG lay o da hong',
        got == [('K2', 'big')], 'lay=%s' % got)
    now2 = dict(now, K1='day du')
    chk('ghi de khong lam doi gia tri => khong vao drop',
        [x['key'] for x in plan_drop((bud, now2, full, zh, known, dirs, s, fl))] == [],
        'K1 now==full')
    # DOI CHUNG HOI QUY cho dung cai bay da sap that (xem read_rows): MOT widget, HAI chuoi.
    # Khoa join cu `(layout, widget)` lam dong thu hai de len dong thu nhat => o dang tran BIEN MAT
    # va khoa duoc ket luan nham la "bo ghi de van vua". Phep kiem nay PHAI do neu ai do doi khoa
    # join tro lai. (That: 35 khoa qua cong, ap vao sinh 38 cho tran moi, da hoan tac.)
    s2 = {('Two/Two.layout.xml', 'w', '#{KA}'): row('Two/Two.layout.xml', 'w', '#{KA}', 150, 45, 0),
          ('Two/Two.layout.xml', 'w', '#{KB}'): row('Two/Two.layout.xml', 'w', '#{KB}', 150, 71, 0)}
    f2 = {('Two/Two.layout.xml', 'w', '#{KA}'): row('Two/Two.layout.xml', 'w', '#{KA}', 150, 260, 110),
          ('Two/Two.layout.xml', 'w', '#{KB}'): row('Two/Two.layout.xml', 'w', '#{KB}', 150, 71, 0)}
    d2 = plan_drop(({'KA': (150, 'Two'), 'KB': (150, 'Two')},
                    {'KA': 'ngan', 'KB': 'ngan'}, {'KA': 'day du', 'KB': 'ngan2'},
                    {'KA': 'a', 'KB': 'b'}, {'two'}, {'two': {'two'}}, s2, f2))
    chk('HOI QUY mot widget hai chuoi: khoa co chuoi TRAN khong duoc vao drop',
        [x['key'] for x in d2] == ['KB'], 'lay=%s (KA PHAI bi loai)' % [x['key'] for x in d2])
    print('SELFTEST', 'OK' if ok else 'FAILED')
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', nargs='?', default='drop', choices=('drop', 'frame'))
    ap.add_argument('--limit', type=int, default=0, help='chi lay N dong dau (ap theo dot nho)')
    ap.add_argument('--write', action='store_true')
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--out', default='')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    data = load_all()
    rows = plan_drop(data) if a.cmd == 'drop' else plan_frame(data)
    # `validate()` o day bat mot lop ma toi KHONG doan truoc: co nhung dong "ghi de ngan sach"
    # thuc ra la BAN DICH DUY NHAT cua khoa - bo no ra thi duong ong roi ve `untranslated` va
    # chu HAN quay lai man hinh ("han left"). Loai rieng, khong huy ca dot.
    bad = [r for r in rows if r['validate']]
    rows = [r for r in rows if not r['validate']]
    if bad:
        print('LOAI %d dong (validate): bo ghi de se lam hong chinh cho do' % len(bad))
        for r in bad[:10]:
            print('    %-22s %-18s %s' % (r['key'], r['validate'], repr(r['full'])[:52]))
        with io.open(os.path.join(LOGS, 'rejected-%s.json' % a.cmd), 'w', encoding='utf-8') as f:
            json.dump(bad, f, ensure_ascii=False, indent=1)
    if a.limit:
        rows = rows[:a.limit]
    out = a.out or os.path.join(LOGS, 'plan-%s.json' % a.cmd)
    with io.open(out, 'w', encoding='utf-8') as f:
        json.dump(rows, f, ensure_ascii=False, indent=1)
    if a.cmd == 'drop':
        print('XOA duoc %d ghi de | %d o | %d khung'
              % (len(rows), sum(len(r['slots']) for r in rows),
                 len({s['frame'] for r in rows for s in r['slots']})))
    else:
        print('(khoa, khung) ap duoc: %d | %d o | %d khung | %d khoa'
              % (len(rows), sum(len(r['slots']) for r in rows),
                 len({r['frame'] for r in rows}), len({r['key'] for r in rows})))
    print('-> ' + out)
    if not a.write:
        print('(chua ghi gi - them --write)')
        return 0
    if a.cmd == 'drop':
        n, stamp = write_drop(rows)
        print('da xoa %d dong khoi cy_vi_override.tsv | sao luu .bak-i18n-scope-%s' % (n, stamp))
    else:
        n, nl = write_frame(rows)
        print('cy_vi_frame_override.tsv: them %d cap | ban va tham chieu: %d tep layout' % (n, nl))
    return 0


if __name__ == '__main__':
    sys.exit(main())
