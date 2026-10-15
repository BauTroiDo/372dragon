# -*- coding: utf-8 -*-
"""cys_i18nscope_rescue.py - CYS-I18NSCOPE 19/09/2026: "chuyen ghi de sang cap (KHOA, KHUNG) thi CUU duoc bao nhieu cho?"

Thuoc do
--------
KHONG dung `cy_layout_fit.est_width` (uoc luong theo ky tu). Dung DUNG bo do da sinh ra 3.377 ban
rut gon: `Tools/ui-fit/measure_ui_text.py` + `ceguitext.py` - FreeType tren dung tep font, dung co
chu, dung hinh hoc CEGUI 0.4.1. Hai lan do tren CUNG cay layout, chi khac mot tep StrDictionary.txt:

    m-short/overflow.csv   bang dang chay (byte-identical voi Assets/CanonicalCY/.../StrDictionary.txt)
    m-full/overflow.csv    bang do chinh duong ong sinh ra khi BO 3.377 ghi de co ghi chu ngan sach

Doi chieu: lan chay lai nay cho 10.041 cho tran (ban day du) -> 4.214 (ban rut gon). ui-fit-2 ghi
10.091 -> 4.269. Hai phep do doc lap lech < 0,6 % => dang dung cung mot thuoc.

Mot O duoc goi la CUU DUOC khi ca bon dieu sau dung:
  1. o tham chieu dung mot khoa `#{KEY}` co ghi chu ngan sach;
  2. khung chua o KHONG nam trong tap khung ngan sach cua khoa do;
  3. o KHONG tran voi ban rut gon (dang binh thuong) - de khong tinh cong nhung cho von da hong;
  4. o CUNG KHONG tran voi ban DAY DU  => ban rut gon o day la vo ich.

Con so phu, quan trong khong kem: o NAM TRONG khung ngan sach ma ban day du van vua
(`stale_budget`) - tuc phep rut goc da khong con can nua.

usage:
  python -B cys_i18nscope_rescue.py --short <dir> --full <dir> --out rescue-real.json
  python -B cys_i18nscope_rescue.py --selftest
"""
import argparse
import collections
import csv
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cys_i18nscope_leak as LEAK    # noqa: E402

RAW1 = re.compile(r'^#\{([^}]+)\}$')
FIT_EPS = 0.5      # y het nguong `over > 0.5` cua measure_ui_text.py


def read_rows(path, strict=True):
    """{(layout, widget, raw): row} cua mot overflow.csv chay voi --all-rows.

    BAY DA SAP THAT (19/09, dot `drop` dau tien): khoa ban dau la `(layout, widget)` va no
    KHONG DUY NHAT - mot widget co the duoc do NHIEU LAN voi cac chuoi khac nhau, vi Lua dat
    text nao tuy nhanh (do duoc: 1.942 cap trung lap tren 19.757 dong). Dong sau de len dong
    truoc, va THU TU giua hai lan do lai khac nhau => dong dang TRAN co the bien mat khoi phep
    phan tich mot cach ngau nhien. Hau qua that: 35 khoa duoc ket luan "bo ghi de van vua o moi
    khung", ap vao roi do lai thi sinh 38 cho tran moi. Da hoan tac.
    `raw` (chuoi NGUON truoc khi tra bang) la thu phan biet cac dong do.

    Ngay ca `(layout, widget, raw)` cung con 85/19.671 nhom co HAI dong: bien the `dyn`
    (`measure_ui_text --dyn-digits` them chu so cho o se duoc Lua dien so vao). Khong ghep theo
    thu tu - lay dong TE NHAT cua nhom (over_px lon nhat). "Vua" khi ca truong hop xau nhat vua;
    khong phu thuoc thu tu dong trong CSV, nen hai lan do lai luon cho cung ket qua.
    """
    out = {}
    with open(path, encoding='utf-8', newline='') as fh:
        for r in csv.DictReader(fh):
            k = (r['layout'], r['widget'], r['raw'])
            cur = out.get(k)
            if cur is None or float(r['over_px']) > float(cur['over_px']):
                out[k] = r
    if strict:
        n = sum(1 for _ in csv.DictReader(open(path, encoding='utf-8', newline='')))
        if n < len(out):
            raise SystemExit('overflow.csv: %d dong < %d nhom - doc hong' % (n, len(out)))
    return out


def frame_of(layout_rel):
    return os.path.basename(layout_rel).split('.')[0].lower()


def analyse(short_rows, full_rows, budget, known, dir_frames, now, full_dict, zh):
    """now = bang DANG CHAY (rut gon), full_dict = bang khi bo ghi de."""
    res = {'slots_total': 0, 'slots_budget_key': 0, 'slots_override_no_change': 0, 'slots_other_frame': 0,
           'rescued_slots': 0, 'rescued_slots_visible': 0,
           'rescued_keys': 0, 'rescued_frames': 0,
           'stale_budget_slots': 0, 'stale_budget_keys': 0,
           'already_broken_slots': 0, 'still_overflow_slots': 0}
    per_key = collections.defaultdict(lambda: {'rescued': [], 'blocked': [], 'budget_slots': []})
    frames = collections.Counter()
    for k, srow in short_rows.items():
        res['slots_total'] += 1
        m = RAW1.match((srow.get('raw') or '').strip())
        if not m or m.group(1) not in budget:
            continue
        key = m.group(1)
        frow = full_rows.get(k)
        if frow is None:
            continue
        # CYS-I18NSCOPE: doi chung tren du lieu that (control-real-data.json) bat duoc lo hong nay:
        # neu mot ghi de KHONG lam doi gia tri thi khong co gi de "cuu", nhung ban dau ham nay van
        # dem o do. Hien tai ca 3.377 ghi de deu lam doi gia tri nen con so khong doi - nhung mot
        # cong cu khong co cong nay se am tham dem thua ngay khi ai do them mot ghi de vo hai.
        if now.get(key, '') == full_dict.get(key, ''):
            res['slots_override_no_change'] = res.get('slots_override_no_change', 0) + 1
            continue
        res['slots_budget_key'] += 1
        bset, _kind = LEAK.resolve_budget_frames(budget[key][1], known, dir_frames)
        fr = frame_of(srow['layout'])
        s_over = float(srow['over_px'])
        f_over = float(frow['over_px'])
        vis = srow.get('visible') == '1'
        rec = {'frame': fr, 'layout': srow['layout'], 'widget': srow['widget'],
               'font': srow['font'], 'pt': srow['pt'], 'box_w': float(srow['box_w']),
               'w_short': float(srow['text_w']), 'w_full': float(frow['text_w']),
               'over_full': f_over, 'visible': vis}
        if fr in bset:
            per_key[key]['budget_slots'].append(rec)
            if f_over <= FIT_EPS:
                res['stale_budget_slots'] += 1
            continue
        res['slots_other_frame'] += 1
        if s_over > FIT_EPS:
            res['already_broken_slots'] += 1        # tran ngay ca voi ban rut gon -> khong tinh cong
            continue
        if f_over <= FIT_EPS:
            res['rescued_slots'] += 1
            if vis:
                res['rescued_slots_visible'] += 1
            per_key[key]['rescued'].append(rec)
            frames[fr] += 1
        else:
            res['still_overflow_slots'] += 1
            per_key[key]['blocked'].append(rec)
    res['rescued_keys'] = sum(1 for v in per_key.values() if v['rescued'])
    res['rescued_frames'] = len(frames)
    res['stale_budget_keys'] = sum(1 for v in per_key.values()
                                   if v['budget_slots'] and all(s['over_full'] <= FIT_EPS
                                                                for s in v['budget_slots']))
    res['top_frames'] = frames.most_common(20)
    stale = []
    for key, v in sorted(per_key.items()):
        if v['budget_slots'] and all(x['over_full'] <= FIT_EPS for x in v['budget_slots']):
            stale.append({'key': key, 'zh': zh.get(key, ''), 'short': now.get(key, ''),
                          'full': full_dict.get(key, ''), 'budget_px': budget[key][0],
                          'budget_frame': budget[key][1], 'budget_slots': v['budget_slots'],
                          'also_leaks': bool(v['rescued'] or v['blocked'])})
    table = []
    for key, v in sorted(per_key.items()):
        if not (v['rescued'] or v['blocked']):
            continue
        table.append({'key': key, 'zh': zh.get(key, ''), 'short': now.get(key, ''),
                      'full': full_dict.get(key, ''),
                      'budget_px': budget[key][0], 'budget_frame': budget[key][1],
                      'budget_slots_full_fits': all(s['over_full'] <= FIT_EPS for s in v['budget_slots'])
                      if v['budget_slots'] else None,
                      'rescued_frames': sorted({s['frame'] for s in v['rescued']}),
                      'blocked_frames': sorted({s['frame'] for s in v['blocked']}),
                      'rescued': v['rescued'], 'blocked': v['blocked'],
                      'budget_slots': v['budget_slots']})
    return res, table, stale


def selftest():
    ok = True

    def chk(name, cond, detail=''):
        nonlocal ok
        print(('PASS ' if cond else 'FAIL ') + name + (' | ' + detail if detail else ''))
        if not cond:
            ok = False

    def row(layout, widget, raw, box, tw, over, vis='1'):
        return {'layout': layout, 'widget': widget, 'raw': raw, 'box_w': str(box),
                'text_w': str(tw), 'over_px': str(over), 'visible': vis,
                'font': 'SongTiBmp12', 'pt': '12'}

    short = {('Pet/Pet.layout.xml', 'a', '#{K}'): row('Pet/Pet.layout.xml', 'a', '#{K}', 30, 20, 0),
             ('SelfEquip/SelfEquip.layout.xml', 'b', '#{K}'): row('SelfEquip/SelfEquip.layout.xml', 'b', '#{K}', 120, 20, 0),
             ('Tiny/Tiny.layout.xml', 'c', '#{K}'): row('Tiny/Tiny.layout.xml', 'c', '#{K}', 36, 20, 0),
             ('Bad/Bad.layout.xml', 'd', '#{K}'): row('Bad/Bad.layout.xml', 'd', '#{K}', 10, 20, 10)}
    full = {('Pet/Pet.layout.xml', 'a', '#{K}'): row('Pet/Pet.layout.xml', 'a', '#{K}', 30, 60, 30),
            ('SelfEquip/SelfEquip.layout.xml', 'b', '#{K}'): row('SelfEquip/SelfEquip.layout.xml', 'b', '#{K}', 120, 60, 0),
            ('Tiny/Tiny.layout.xml', 'c', '#{K}'): row('Tiny/Tiny.layout.xml', 'c', '#{K}', 36, 60, 24),
            ('Bad/Bad.layout.xml', 'd', '#{K}'): row('Bad/Bad.layout.xml', 'd', '#{K}', 10, 60, 50)}
    budget = {'K': (30, 'Pet')}
    known = {'pet', 'selfequip', 'tiny', 'bad'}
    dirs = {'pet': {'pet'}, 'selfequip': {'selfequip'}, 'tiny': {'tiny'}, 'bad': {'bad'}}
    res, tab, _st = analyse(short, full, budget, known, dirs, {'K': 'N'}, {'K': 'Ngan'}, {})
    chk('o RONG o khung khac duoc tinh la CUU', res['rescued_slots'] == 1,
        'rescued=%d' % res['rescued_slots'])
    chk('o HEP o khung khac KHONG duoc tinh', res['still_overflow_slots'] == 1,
        'still=%d' % res['still_overflow_slots'])
    chk('o VON DA TRAN voi ban rut gon bi loai rieng', res['already_broken_slots'] == 1,
        'broken=%d' % res['already_broken_slots'])
    chk('o trong chinh khung ngan sach KHONG tinh la cuu',
        res['rescued_frames'] == 1 and tab[0]['rescued_frames'] == ['selfequip'])
    # doi chung cho phep dem 'ngan sach da cu': ban day du van vua o chinh khung ngan sach
    full2 = dict(full)
    full2[('Pet/Pet.layout.xml', 'a', '#{K}')] = row('Pet/Pet.layout.xml', 'a', '#{K}', 30, 20, 0)
    res2, _t2, _s2 = analyse(short, full2, budget, known, dirs, {'K': 'N'}, {'K': 'Ngan'}, {})
    chk('bat duoc "ghi de da khong con can" khi ban day du vua chinh khung ngan sach',
        res['stale_budget_slots'] == 0 and res2['stale_budget_slots'] == 1,
        'truoc=%d sau=%d' % (res['stale_budget_slots'], res2['stale_budget_slots']))
    print('SELFTEST', 'OK' if ok else 'FAILED')
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    base = os.path.join(LEAK.CYS, 'Build', 'Logs', '2026-09-19-i18n-scope')
    ap.add_argument('--short', default=os.path.join(base, 'm-short', 'overflow.csv'))
    ap.add_argument('--full', default=os.path.join(base, 'm-full', 'overflow.csv'))
    ap.add_argument('--out', default=os.path.join(base, 'rescue-real.json'))
    ap.add_argument('--table', default=os.path.join(base, 'rescue-table.json'))
    ap.add_argument('--selftest', action='store_true')
    args = ap.parse_args()
    if args.selftest:
        return selftest()
    budget = LEAK.load_budget()
    now, full_dict, zh = LEAK.build_dicts(set(budget))
    _bk, _lr, known, dir_frames, _st = LEAK.scan_layouts()
    res, table, stale = analyse(read_rows(args.short), read_rows(args.full), budget, known,
                                dir_frames, now, full_dict, zh)
    with open(os.path.join(os.path.dirname(args.out), 'stale-overrides.json'), 'w',
              encoding='utf-8') as f:
        json.dump(stale, f, ensure_ascii=False, indent=1)
    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    with open(args.table, 'w', encoding='utf-8') as f:
        json.dump(table, f, ensure_ascii=False, indent=1)
    print(json.dumps(res, ensure_ascii=False, indent=1))
    return 0


if __name__ == '__main__':
    sys.exit(main())
