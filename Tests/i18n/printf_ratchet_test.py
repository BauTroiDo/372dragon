# -*- coding: utf-8 -*-
"""Bánh cóc (ratchet) cho lớp lỗi `% <chữ cái>` trong StrDictionary đang chạy.

CƠ CHẾ (i18n-run 19/09 đã đo trên CRT thật): `_vsnprintf` trong `ParserString_VarParam`
(`Src/Client/CEGUISystem/UIString.cpp:918`) đọc đúng số đặc tả printf có trong chuỗi. Nếu bản
dịch có NHIỀU đặc tả hơn nguồn Hán thì nó lấy thêm một đối số **không tồn tại** — đọc con trỏ rác.
Chiều ngược lại vô hại (thừa đối số thì bỏ qua).

Tiếng Trung gần như không bao giờ mắc, vì nó viết `50％` (U+FF05, toàn rộng) — không phải đặc tả.
Tiếng Việt viết `50% giá trị` → `% g` LÀ một đặc tả. Đo 20/09: **134 ô** có nhiều đặc tả hơn
nguồn, **122 ô** thuộc đúng mẫu `% <chữ cái>`.

CỬA CHƯA CANH: những ô này KHÔNG đến từ đường ống rút ngắn (0/3.339) mà từ **bộ nhớ dịch**
(`translation.db`) — `cy_gui_dict.build()` gọi `tm.lookup()` rồi dùng thẳng, chỉ lọc qua
`wrecked()`, **không** qua `cy_translate.validate()`.

Chặn cứng ở đây sẽ đẩy 134 ô về chữ Hán — một hồi quy người dùng thấy ngay — nên tệp này KHÔNG
chặn: nó là **bánh cóc**. Con số chỉ được phép GIỮ NGUYÊN hoặc GIẢM. Ai làm nó tăng sẽ thấy đỏ
ngay ở đây thay vì phát hiện bằng một cú văng.

Chạy:  python -X utf8 Tests/i18n/printf_ratchet_test.py [--update]
"""
import argparse
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'Tools', 'pipeline'))
sys.path.insert(0, os.path.join(REPO, 'Docs', 'evidence', 'assetinv'))
BASELINE = os.path.join(HERE, 'printf_ratchet_baseline.json')
DICT = os.path.join(REPO, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'StrDictionary.txt')
PCT_SPACE = re.compile(r'% [A-Za-z]')

# CYS-PRINTFFIX (printf-fix 20/09/2026) - DINH CHINH MO HINH CUA CHINH TEP NAY.
#
# Ban dau tep nay so `so dac ta cua ban dich > so dac ta cua nguon Han`. Mo hinh do THIEU: CY 3.71
# TU NO cung chua dac ta tai nan (`100%` dinh ngay ma mau `#cfff263` thanh `%#c`) - do duoc 218 cho.
# Nguoi goi day doi so theo nhung THAM SO TAC GIA THAT SU VIET (`%s0`, `%s1`, `%d`...), khong theo
# cai `%#c` do van ban sinh ra. Nen "bang nguon" van co the doc qua.
#
# Do duoc: sau khi da sua 134 o theo mo hinh CU, van con 195 o doc mot doi so khong ton tai, 16
# trong do bang `%s` (giai tham chieu con tro rac), 2 trong 16 la do ban dich lam TE HON nguon.
#
# => Con so chinh cua banh coc nay nay la `strict`: so dac ta cua ban dich > so DOI SO THAT.
# `over` (mo hinh cu) van duoc do va van khong duoc phep tang - hai phep dem doc lap phai cung di
# xuong, dung luat "mot cong cu do chi co MOT nguon so thi khong biet no dem thieu".
SPEC_FULL = re.compile(
    r'%(?!%)([-+ #0]*)([0-9]*)((?:\.[0-9]+)?)((?:hh|h|ll|l|L|z|j|t)?)([diouxXeEfFgGaAcspn])')


def _accidental(m):
    """Dac ta do VAN BAN sinh ra: co flag dau cach hoac '#', khong co do rong/do chinh xac.

    Co y viet LAI o day thay vi import tu `cy_gui_dict`: banh coc phai la Y KIEN THU HAI doc lap
    voi cai cong ma no canh. `cross_check()` ben duoi bat hai ban phai ra cung mot so.
    """
    return (' ' in m.group(1) or '#' in m.group(1)) and not m.group(2) and not m.group(3)


def n_args(zh):
    """So doi so nguoi goi day len = so dac ta cua nguon Han KHONG phai tai nan."""
    return sum(1 for m in SPEC_FULL.finditer(zh or '') if not _accidental(m))


def cross_check(zh_map, vi_map):
    """Luat "dem hai lan": ban doc lap o day va ban trong `cy_gui_dict` phai ra CUNG mot so."""
    import cy_gui_dict as G
    mine = sorted(k for k, v in vi_map.items()
                  if k.split('@')[0] in zh_map
                  and len(SPEC_FULL.findall(v)) > n_args(zh_map[k.split('@')[0]]))
    theirs = sorted(k for k, v in vi_map.items()
                    if k.split('@')[0] in zh_map and G.printf_over(zh_map[k.split('@')[0]], v))
    return mine, theirs


def measure():
    import cy_gui_dict as G
    import cy_translate as CT
    import axp_index as AX
    import cys_i18nscope_leak as LEAK
    a = AX.Axp(LEAK.S4_STR)
    _n, raw = a.payload_full('StrDictionary.txt', 256 << 20)
    a.f.close()
    zh = {}
    for kb, vb in G.parse_binary_dbc(raw):
        zh.setdefault(kb.decode('gbk'), vb.decode('gbk', 'replace'))
    vi = {}
    with io.open(DICT, 'rb') as fh:
        for ln in fh.read().decode('utf-8').split('\r\n')[2:]:
            if '\t' in ln:
                k, v = ln.split('\t', 1)
                vi.setdefault(k, v)
    P = CT.PRINTF_SPEC
    over = sorted(k for k, v in vi.items()
                  if k.split('@')[0] in zh
                  and len(P.findall(v)) > len(P.findall(zh[k.split('@')[0]])))
    strict, theirs = cross_check(zh, vi)
    if strict != theirs:
        raise SystemExit('HAI PHEP DEM LECH NHAU: banh coc %d, cy_gui_dict.printf_over %d. '
                         'Truy nguyen nhan, dung chon con so dep hon.' % (len(strict), len(theirs)))
    return over, [k for k in over if PCT_SPACE.search(vi[k])], strict


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--update', action='store_true',
                    help='ghi lai moc SAU khi da GIAM that (khong bao gio de tang)')
    a = ap.parse_args()
    over, pct, strict = measure()
    print('o doc mot DOI SO KHONG TON TAI (mo hinh dung): %d' % len(strict))
    print('o co nhieu dac ta hon nguon Han (mo hinh cu) : %d (mau "%% <chu>": %d)'
          % (len(over), len(pct)))
    if a.update or not os.path.exists(BASELINE):
        base = {'strict': len(strict), 'over': len(over), 'pct_space': len(pct),
                'keys': over, 'strict_keys': strict}
        with io.open(BASELINE, 'w', encoding='utf-8') as fh:
            json.dump(base, fh, ensure_ascii=False, indent=1)
        print('da ghi moc:', BASELINE)
        return 0
    with io.open(BASELINE, encoding='utf-8') as fh:
        base = json.load(fh)
    new = sorted(set(over) - set(base['keys']))
    snew = sorted(set(strict) - set(base.get('strict_keys', [])))
    ok = (len(over) <= base['over'] and not new
          and len(strict) <= base.get('strict', len(strict)) and not snew)
    print(('PASS ' if ok else 'FAIL ')
          + 'banh coc: dung %d <= moc %d (khoa MOI %d) | cu %d <= moc %d (khoa MOI %d)'
          % (len(strict), base.get('strict', -1), len(snew),
             len(over), base['over'], len(new)))
    for k in snew[:15]:
        print('    MOI (doc doi so khong ton tai)', k)
    for k in new[:15]:
        print('    MOI (nhieu dac ta hon nguon)', k)
    if len(over) < base['over'] or len(strict) < base.get('strict', len(strict)):
        print('(da GIAM - chay lai voi --update de ha moc)')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
