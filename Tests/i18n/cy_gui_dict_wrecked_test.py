# -*- coding: utf-8 -*-
"""Doi chung cho `cy_gui_dict.wrecked()` - bo loc chan ban dich HONG truoc khi no vao tu dien.

Luat cua du an: mot bo kiem khong bat duoc lop loi DA BIET thi lan sau van khong bat duoc.
Ba lop hong da gap, moi lop mot phep kiem duong + mot phep kiem am:

  1. lo dich cu ghep nhieu cau bang " || " hoac lam ro ri manh GUID   (CYS-I18NCOUNT, 19/09)
  2. ban dich mo mot the `#{` ma nguon khong mo                        (CYS-I18NCOUNT, 19/09)
  3. ban dich KHONG LIEN QUAN GI toi nguon - nguon <= 2 chu Han, dich dai bat thuong
     (CYS-I18NSCOPE, 19/09: mot chuoi URL nap tien tra ve cho 8 chu Han don le khac nhau)

Phep kiem AM quan trong khong kem phep kiem duong: no chung minh bo loc KHONG chan oan nhung
ban dich ngan-sang-dai binh thuong ("买" -> "Mua vật phẩm").

Chay:  python -X utf8 Tests/i18n/cy_gui_dict_wrecked_test.py
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..',
                                'Tools', 'pipeline'))
import cy_gui_dict as G     # noqa: E402

URL = 'Nạp thêm tại: https://platform.beeknoee.com/billing'

CASES = [
    # (zh, vi, mong doi bi chan?, ten)
    ('确定', 'Xác nhận', False, 'AM ban dich binh thuong'),
    ('买', 'Mua vật phẩm', False, 'AM nguon 1 chu -> 12 ky tu van phai qua'),
    ('风', 'Phong', False, 'AM Han-Viet mot chu'),
    ('体力:', 'Thể lực:', False, 'AM nhan ngan co dau hai cham'),
    ('外功攻击:', 'Ngoại công:', False, 'AM nguon 5 chu, dich dai hon van qua'),
    ('风', URL, True, 'DUONG lop 3: nguon 1 chu -> 50 ky tu khong lien quan'),
    ('鞋', URL, True, 'DUONG lop 3: chu khac, cung mot chuoi rac'),
    ('#cfff263名！', '#cfff263bảng xếp hạng Tu luyện!', True, 'DUONG lop 3: manh cau bi thay'),
    ('确定', 'A || B', True, 'DUONG lop 1: dau phan cach cua lo dich hong'),
    ('确定', 'abcd-1234-ef567', True, 'DUONG lop 1: manh GUID'),
    ('#您好', '#{Xin chao', True, 'DUONG lop 2: mo the #{ ma nguon khong mo'),
    ('#{_ITEM', '#{_ITEM', False, 'AM lop 2: nguon CUNG la manh mo the -> khong chan'),
]


def main():
    bad = 0
    for zh, vi, want, name in CASES:
        got = bool(G.wrecked(vi, zh))
        ok = got == want
        print(('PASS ' if ok else 'FAIL ') + name +
              ('' if ok else ' | mong doi %s, nhan %s | zh=%r vi=%r' % (want, got, zh, vi[:40])))
        bad += 0 if ok else 1
    # doi chung cho chinh phep kiem: tat luat lop 3 di thi HAI dong DUONG phai do
    orig = G._visible_len
    G._visible_len = lambda s: 99
    broke = sum(1 for zh, vi, want, _n in CASES
                if want and 'lop 3' in _n and not bool(G.wrecked(vi, zh)))
    G._visible_len = orig
    print(('PASS ' if broke == 3 else 'FAIL ') +
          'DOI CHUNG: tat luat lop 3 thi ca 3 ca DUONG cua no deu lot (%d/3)' % broke)
    bad += 0 if broke == 3 else 1
    print('KET QUA:', 'OK' if not bad else '%d FAIL' % bad)
    return 0 if not bad else 1


if __name__ == '__main__':
    sys.exit(main())
