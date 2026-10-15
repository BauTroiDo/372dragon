# -*- coding: utf-8 -*-
"""CYS-CRTGUARD: cac BANG KHOA CO DINH duoc goi voi 0 DOI SO - o tu dien co dac ta khong?

`NOCOLORMSGFUNC(pErrString[i])` goi `ParserString_VarParam` voi DUNG 0 doi so bien, roi ban
mau tu `StrDictionary` di thang vao `_vsnprintf`. Neu o tu dien co BAT KY dac ta nao thi lan
dinh dang do doc doi so KHONG TON TAI ngay hom nay - khong can cho mot dong script moi.

`printf-fix` do "0/134 khoa tro toi duoc", nhung 134 la cac dac ta TAI NAN. Mot `%s` CO CHU Y
trong mot khoa cua bang nay la mot chuyen khac han. Day la phep do do.
"""
import os
import re
import sys

DICT = os.environ.get(
    "CYS_DICT",
    r"C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ConfigFolder\StrDictionary.txt")
SRC = r"C:\TLBB\085\CY-Source\Src"

TABLES = [
    ("pRelationString", r"Client\WXClient\Network\PacketHandler\GCRelationHandler.cpp"),
    ("pString",         r"Client\WXClient\Network\PacketHandler\GCTeamErrorHandler.cpp"),
    ("pErrString",      r"Client\WXClient\Network\PacketHandler\GCTeamFollowErrHandler.cpp"),
    ("g_szGemAttName",  r"Client\WXClient\Object\Item\Obj_Item_Gem.cpp"),
]

CONV = "diouxXeEfFgGaAcCsSpZn"


def count_args(fmt):
    """Ban Python cua CysFmt_CountArgs - CO Y viet lai doc lap (luat 'dem hai lan'):
    neu hai ban lech nhau tren cung mot chuoi thi phai truy, dung chon ban de hon."""
    n = 0
    i = 0
    L = len(fmt)
    fatal = False
    while i < L:
        if fmt[i] != '%':
            i += 1
            continue
        i += 1
        if i < L and fmt[i] == '%':
            i += 1
            continue
        while i < L and fmt[i] in "-+ #0":
            i += 1
        if i < L and fmt[i] == '*':
            n += 1
            i += 1
        else:
            while i < L and fmt[i].isdigit():
                i += 1
        if i < L and fmt[i] == '.':
            i += 1
            if i < L and fmt[i] == '*':
                n += 1
                i += 1
            else:
                while i < L and fmt[i].isdigit():
                    i += 1
        if i < L and fmt[i] == 'I':
            i += 1
            if fmt[i:i + 2] in ("64", "32"):
                i += 2
        elif i < L and fmt[i] in "hl":
            c = fmt[i]
            i += 1
            if i < L and fmt[i] == c:
                i += 1
        elif i < L and fmt[i] in "Lwztj":
            i += 1
        if i < L and fmt[i] in CONV:
            if fmt[i] == 'n':
                fatal = True
            n += 1
            i += 1
    return n, fatal


def table_keys(var, rel):
    p = os.path.join(SRC, rel)
    txt = open(p, 'rb').read().decode('utf-8', 'replace')
    m = re.search(re.escape(var) + r'\s*\[\s*\]\s*=\s*\{(.*?)\};', txt, re.S)
    if not m:
        return []
    body = m.group(1)
    body = re.sub(r'//[^\n]*', '', body)
    return [s for s in re.findall(r'"([^"]*)"', body)]


def main():
    d = {}
    with open(DICT, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            if '\t' not in line:
                continue
            k, v = line.rstrip('\n').split('\t', 1)
            d[k] = v
    print("StrDictionary: %d khoa  (%s)" % (len(d), DICT))
    total = 0
    armed = 0
    missing = 0
    for var, rel in TABLES:
        keys = table_keys(var, rel)
        print("\n--- %-18s %d khoa  (%s)" % (var, len(keys), rel))
        for k in keys:
            if not k:
                continue
            total += 1
            if k not in d:
                missing += 1
                print("    %-40s KHONG CO TRONG TU DIEN -> chuoi rong, vo hai" % k)
                continue
            n, fatal = count_args(d[k])
            if n > 0 or fatal:
                armed += 1
                print("    %-40s DOC %d DOI SO%s  <-- MIN DA GAI: [%s]"
                      % (k, n, " + %n GIET TIEN TRINH" if fatal else "", d[k][:70]))
    print("\nTONG: %d khoa; %d khong co trong tu dien; **%d khoa doc doi so khong ton tai**"
          % (total, missing, armed))
    return 0 if armed == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
