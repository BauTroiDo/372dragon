#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""red-team: kiem doc lap ten model tui roi do ma `crash-anim` (1eb6858a) da ghi cung.

Cau hoi: ban va doi tu tra cuu StrDictionary sang chuoi GBK cung
"0\\xce\\xed\\xc6\\xb7/\\xb0\\xfc\\xb8\\xa4.obj"  (= "0物品/包袱.obj").
Phep nghiem thu cua ho do "tien trinh khong chet". No KHONG do
"ten do co nap ra model that khong" => tui roi do co the VO HINH.

DINH NGHIA DEM: mot ten duoc coi la CO trong all.obj neu byte GBK cua no
xuat hien nhu mot dong khai bao doi tuong (tim tho theo byte, in ca ngu canh).
"""
import os
import re
import sys

ALLOBJ = r"C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ModelFolder\all.obj"
NAME_HEX = b"0\xce\xef\xc6\xb7/\xb0\xfc\xb8\xa4.obj"       # nhu trong ban va
NAME_ALT = b"0\xce\xef\xc6\xb7\\\xb0\xfc\xb8\xa4.obj"      # cung ten, dau \ nguoc
NAME_DIR = b"0\xce\xef\xc6\xb7"                            # "0物品"
NAME_BAG = b"\xb0\xfc\xb8\xa4"                             # "包袱"


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else ALLOBJ
    with open(path, "rb") as fh:
        blob = fh.read()
    print("tep      :", path)
    print("kich thuoc:", len(blob), "byte")
    print()
    for label, needle in (("ten trong ban va (dau /)", NAME_HEX),
                          ("cung ten, dau \\", NAME_ALT),
                          ("thu muc '0物品'", NAME_DIR),
                          ("ten '包袱'", NAME_BAG)):
        n = blob.count(needle)
        print("%-28s : %d lan" % (label, n))
    print()
    # in moi dong co chua "包袱"
    lines = blob.split(b"\n")
    hits = [(i, l) for i, l in enumerate(lines, 1) if NAME_BAG in l]
    print("== moi dong chua '包袱' (%d) ==" % len(hits))
    for i, l in hits[:40]:
        try:
            txt = l.decode("gbk", errors="replace").rstrip()
        except Exception:
            txt = repr(l)
        print("  %6d: %s" % (i, txt))
    # doi chung duong: mot ten chac chan co, lay tu chinh tep
    print()
    m = re.findall(rb"^\s*([^\s\[\]#]+\.obj)\s*$", blob, re.M)
    print("so dong trong all.obj khop mau '<ten>.obj' don le:", len(m))
    if m:
        print("vi du 3 ten:", [x.decode("gbk", "replace") for x in m[:3]])


if __name__ == "__main__":
    main()
