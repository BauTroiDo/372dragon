# -*- coding: utf-8 -*-
"""CYS-PRINTFFIX: cong BE RONG cho cac o bi doi `%` -> `％`.

Hai phep kiem, dung nhu `i18n-scope` da chi ra rang "vua khung" CHUA DU:
  1. TRAN  - chu co vuot o cua chinh no khong (o HEP NHAT trong moi khung tham chieu khoa);
  2. DE NHAU - o co vuot khoang trong toi widget ke ben khong (ngan sach hep hon be rong o).

Chay: python -X utf8 Tools/pipeline/cys_printffix_fitgate.py --out <file>.json
      python -X utf8 Tools/pipeline/cys_printffix_fitgate.py --selftest
"""
import argparse
import csv
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(REPO, 'Tools', 'ui-fit'))
sys.path.insert(0, os.path.join(REPO, 'Docs', 'evidence', 'assetinv'))

DATA = os.path.join(REPO, 'Assets', 'CanonicalCY', 'Data')
SCOPE_LOGS = os.path.join(REPO, 'Build', 'Logs', '2026-09-19-i18n-scope')
OVERFLOW_CSV = os.path.join(SCOPE_LOGS, 'm-short', 'overflow.csv')
OVERLAP_CSV = os.path.join(SCOPE_LOGS, 'm-short', 'overlap.csv')


def _overlap_room():
    """{(layout, widget): khoang_trong_px} - tu meo trai chu toi meo trai widget KE BEN.

    `i18n-scope` do duoc rang "vua o cua chinh no" CHUA DU: o co the rong hon khoang trong
    that su toi widget ben canh. `overlap.csv` giu dung cac cot do (`ink_l`, `kia_l`).
    """
    room = {}
    if not os.path.exists(OVERLAP_CSV):
        return room
    with io.open(OVERLAP_CSV, encoding='utf-8', newline='') as fh:
        for r in csv.DictReader(fh):
            try:
                ink_l, kia_l = float(r['ink_l']), float(r['kia_l'])
            except (TypeError, ValueError, KeyError):
                continue
            if kia_l <= ink_l:
                continue                      # widget ke ben nam BEN TRAI - khong phai ran buoc phai
            k = (r['layout'], r['widget'])
            v = kia_l - ink_l
            if k not in room or v < room[k]:
                room[k] = v
    return room


_LUA_SET = re.compile(r'([A-Za-z_][A-Za-z0-9_]*)\s*:\s*Set(?:Text|ToolTip|Caption)\s*\(\s*"([^"]*)"')
_MARK = re.compile(r'#\{([A-Za-z0-9_@]+)\}')


def _lua_widget_for_key():
    """{key: [widget, ...]} - widget nao duoc Lua gan chinh chuoi `#{KHOA}` do.

    CAN THIET vi 134 o cua dot nay KHONG he xuat hien duoi dang `#{KHOA}` trong tep layout, nen
    bang ngan sach dung khoa (cach `i18n-scope` dung) tra ve RONG cho tat ca - mot den xanh rong.
    Duong that cua chung la Lua: `Handbook_Direction:SetText("#{TLTJ_110114_04}")`.
    """
    out = {}
    ui = os.path.join(DATA, 'InterfaceFolder')
    for dp, _dn, fn in os.walk(ui):
        for f in fn:
            if not f.lower().endswith('.lua'):
                continue
            try:
                txt = io.open(os.path.join(dp, f), 'rb').read().decode('utf-8', 'replace')
            except Exception:
                continue
            if '#{' not in txt:
                continue
            for m in _LUA_SET.finditer(txt):
                for km in _MARK.finditer(m.group(2)):
                    out.setdefault(km.group(1), set()).add(m.group(1))
    return {k: sorted(v) for k, v in out.items()}


def budgets():
    """{key: (ngan_sach_px, khung, widget, font, pt, nguon)} - lay cai NGHIEM NGAT NHAT.

    `box_w` = be rong o cua chinh widget (cong TRAN); khoang trong toi widget ke ben (cong DE NHAU)
    thang khi no HEP HON - dung cach `i18n-scope` da chung minh la can thiet.
    Hai duong vao: `#{KHOA}` viet thang trong layout, VA widget do Lua gan (`:SetText("#{KHOA}")`).
    """
    out = {}
    room = _overlap_room()
    gaps = 0
    rx = re.compile(r'^#\{([^}]+)\}$')
    by_widget = {}
    with io.open(OVERFLOW_CSV, encoding='utf-8', newline='') as fh:
        for r in csv.DictReader(fh):
            w, srckind = float(r['box_w']), 'box_w'
            gap = room.get((r['layout'], r['widget']))
            if gap is not None and gap < w:
                w, srckind = gap, 'gap'
            rec = (w, r['layout'], r['widget'], r['font'], int(r['pt']), srckind)
            cur_w = by_widget.get(r['widget'])
            if cur_w is None or w < cur_w[0]:
                by_widget[r['widget']] = rec
            m = rx.match((r['raw'] or '').strip())
            if not m:
                continue
            cur = out.get(m.group(1))
            if cur is None or w < cur[0]:
                if srckind == 'gap' and (cur is None or cur[5] != 'gap'):
                    gaps += 1
                out[m.group(1)] = rec
    for key, widgets in _lua_widget_for_key().items():
        for wname in widgets:
            rec = by_widget.get(wname)
            if rec is None:
                continue
            rec = rec[:5] + (rec[5] + '/lua',)
            cur = out.get(key)
            if cur is None or rec[0] < cur[0]:
                out[key] = rec
    return out, gaps


def run(rows):
    """rows: [(key, vi_truoc, vi_sau)] -> (ket qua, so o hong)."""
    import ceguitext
    import cys_i18nscope_collide_fix as CF
    fonts = CF.load_fonts()
    dic = ceguitext.load_dictionary(os.path.join(DATA, 'ConfigFolder', 'StrDictionary.txt'))
    box, n_gap = budgets()
    out, bad = [], 0
    for key, before, after in rows:
        b = box.get(key.split('@')[0])
        rec = {'key': key, 'budget_px': None, 'source': None, 'frame': None,
               'w_before': None, 'w_after': None, 'delta_px': None, 'fits': None}
        fname = b[3] if b else 'SongTiBmp12'
        w0, _ = CF.text_px(fonts, dic, before, fname)
        w1, _ = CF.text_px(fonts, dic, after, fname)
        rec.update({'w_before': w0, 'w_after': w1, 'delta_px': w1 - w0, 'font': fname})
        if b:
            rec.update({'budget_px': b[0], 'frame': b[1].split('/')[0], 'widget': b[2],
                        'source': b[5], 'fits': w1 <= b[0] + 0.5,
                        'fits_before': w0 <= b[0] + 0.5})
            # chi tinh la HONG khi ban sua LAM no hong: truoc vua, sau tran
            if rec['fits'] is False and rec['fits_before'] is not False:
                bad += 1
                rec['REGRESSION'] = True
        out.append(rec)
    return out, bad, n_gap


def selftest():
    ok = 0
    b, n_gap = budgets()
    a = len(b) > 100
    print('  %-4s doc duoc ngan sach cho %d khoa (can > 100)' % ('OK' if a else 'FAIL', len(b)))
    ok += a
    print('       trong do %d khoa dung khoang trong (cong DE NHAU) thay vi box_w' % n_gap)
    # doi chung AM: mot chuoi dai gap boi phai TRUOT
    k = next(iter(b))
    rows = [(k, u'x', u'x' * 400)]
    res, bad, _ = run(rows)
    c = bad == 1 and res[0]['fits'] is False
    print('  %-4s doi chung am: 400 ky tu tren khoa %r bi bao TRAN (bad=%d)'
          % ('OK' if c else 'FAIL', k, bad))
    ok += c
    # doi chung DUONG: khong doi gi thi khong hong
    res2, bad2, _ = run([(k, u'x', u'x')])
    d = bad2 == 0
    print('  %-4s doi chung duong: khong doi -> bad=0' % ('OK' if d else 'FAIL'))
    ok += d
    e = res[0]['delta_px'] > res2[0]['delta_px']
    print('  %-4s be rong tang theo do dai (phep do co phan ung)' % ('OK' if e else 'FAIL'))
    ok += e
    print('selftest: %d/4' % ok)
    return 0 if ok == 4 else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rows', help='JSON [[key, truoc, sau], ...]')
    ap.add_argument('--out')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    rows = json.load(io.open(a.rows, encoding='utf-8'))
    res, bad, n_gap = run([tuple(r) for r in rows])
    have = [r for r in res if r['budget_px'] is not None]
    reg = [r for r in res if r.get('REGRESSION')]
    summary = {'rows': len(res), 'with_budget': len(have), 'no_budget': len(res) - len(have),
               'keys_using_gap_budget': n_gap, 'REGRESSIONS': len(reg),
               'max_delta_px': max((r['delta_px'] for r in res), default=0),
               'already_overflowing_before': len([r for r in have if r.get('fits_before') is False])}
    if a.out:
        with io.open(a.out, 'w', encoding='utf-8') as fh:
            json.dump({'summary': summary, 'rows': res}, fh, ensure_ascii=False, indent=1)
        print('da ghi', a.out)
    print(json.dumps(summary, ensure_ascii=False, indent=1))
    for r in reg[:20]:
        print('  TRAN MOI', r['key'], r['w_after'], '>', r['budget_px'], r.get('frame'))
    return 1 if reg else 0


if __name__ == '__main__':
    sys.exit(main())
