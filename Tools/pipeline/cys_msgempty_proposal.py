# -*- coding: utf-8 -*-
"""CYS-MSGEMPTY: kiem BANG DE XUAT anh xa khoa - truoc khi sua mot dong ma nao.

Moi dong de xuat phai qua BON cong, moi cong mot nguon doc lap:
  1. khoa dich CO trong `StrDictionary.txt` dang dung (neu khong thi de xuat vo nghia)
  2. khoa dich CO trong `Game.exe` cua CY 3.71  -> "CY that su dung no"
  3. khoa dich CO trong `Game.exe` cua client GOC 0.85 -> "khong phai ta bia ra"
  4. SO DAC TA cua o tu dien <= SO DOI SO cua cho goi  (bat bien printf cua `printf-fix`:
     doc qua = doc doi so khong ton tai; `%n` = giet tien trinh)

Cong 4 dung LAI BAN DEM cua `cys_crtguard_keycheck.count_args` - khong viet lai lan ba,
nhung co doi chung: neu ban Python va ban C++ lech thi `callcheck` da do.
"""
import io
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cys_crtguard_keycheck import count_args  # noqa: E402

DICT = r"C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ConfigFolder\StrDictionary.txt"
CY_STR = r"C:\TLBB\085\CY-Source\Build\Logs\2026-09-20-msg-empty\cy-bin64-strings.txt"
ORIG_STR = r"C:\TLBB\085\CY-Source\Build\Logs\2026-09-20-msg-empty\orig-bin64-strings.txt"

# (khoa 0.85, khoa CY de xuat, so doi so cua cho goi, ghi chu)
PROPOSAL = [
    ("WIN_EXP", "GCDetailExp_Human_NormalExp", 1, "CY doi CO CHE: thong bao di theo goi GCDetailExp(1288), khong suy tu delta Set_Exp"),
    ("WIN_ADD_EXP", "GCDetailExp_Human_AdditionalExp", 1, "nhu tren"),
    ("WIN_ITEM", "battle_get_myself", 1, "'Nguoi nhan duoc #H%s#W.'"),
    ("EXP_OVERFLOW", "battle_nomore_exp", 0, "'Kinh nghiem da dat gioi han toi da.'"),
    ("Talk_Obj_Shield", "GMGameInterface_Script_Talk_Info_Obj_PingBi", 1, "PingBi = chan"),
    ("Talk_Obj_Offline", "GMGameInterface_Script_Talk_Info_Obj_Error", 1, "cung don vi Talk"),
    ("InvalidSpecialString", "ERRORSpecialString", 0, "chinh ma 0.85 da dung khoa nay o Talk.cpp:4023"),
    ("MAIL_NOT_EMPTY", "NULL_MAIL", 0, "'Khong the gui thu trong'"),
    ("SERVER_MAIL", "SYSTEM_MAIL", 0, "ten nguoi gui thu he thong (duong CHET hom nay)"),
    ("TEAM_DISMISS", "GMUIDataPool_Info_Team_Dismiss", 0, "cung don vi (duong CHET hom nay)"),
    ("TEAM_FOLLOW_OTHER", "GCReturnTeamFollowHandler_Info_Join_Follow", 1, "cung don vi (CHET)"),
    ("SKILL_LEVLE_UP", "GCAbilityLevelHandler_1", 2, "cung don vi (CHET)"),
    ("Up_Skill_Level", "GMDataPool_Info_Can_Not_Learn", 0, "CUNG DON VI nhung NGHIA LECH - can doc ma CY truoc khi dung"),
]


def main():
    d = {}
    for line in io.open(DICT, encoding='utf-8', errors='replace'):
        if '\t' not in line:
            continue
        k, v = line.rstrip('\n').rstrip('\r').split('\t', 1)
        d[k] = v
    cy = set(x.rstrip() for x in io.open(CY_STR, encoding='latin-1'))
    og = set(x.rstrip() for x in io.open(ORIG_STR, encoding='latin-1'))

    bad = 0
    print("%-22s %-46s %-4s %-4s %-3s %-3s %-4s %s"
          % ("khoa 0.85", "khoa de xuat", "args", "spec", "CY", "085", "cong", "van ban"))
    for old, new, nargs, note in PROPOSAL:
        v = d.get(new)
        if v is None:
            print("%-22s %-46s  ---- KHONG CO TRONG TU DIEN ----" % (old, new))
            bad += 1
            continue
        n, fatal = count_args(v)
        ok = (n <= nargs) and not fatal
        if not ok:
            bad += 1
        print("%-22s %-46s %-4d %-4d %-3s %-3s %-4s %s"
              % (old, new, nargs, n, "CO" if new in cy else "-",
                 "CO" if new in og else "-", "XANH" if ok else "DO", v[:46]))
    print()
    print("de xuat: %d, DO: %d" % (len(PROPOSAL), bad))

    # ------------------------------------------------------------------ cong thu hai
    # `OnGCDetailExp` truyen khoa CHAY-THOI (mot bang `lines[]`), nen cong tinh cua
    # `cys_crtguard_callcheck.py` KHONG nhin thay no. Doc thang bang do tu ma nguon - khong chep
    # tay danh sach vao day, vi mot ban sao chep tay se khong bao gio biet ma nguon da doi.
    src = os.environ.get("CYS_SRC", r"C:\TLBB\085\CY-Source\Src")
    p = os.path.join(src, r"Client\WXClient\Network\CysModernHandlers.cpp")
    txt = open(p, 'rb').read().decode('utf-8', 'replace')
    m = re.search(r'const Group groups\[\]\s*=\s*\{(.*?)\n        \};', txt, re.S)
    print()
    if not m:
        print("CONG GCDetailExp: KHONG TIM THAY bang `groups[]` -> cong nay mu, coi nhu DO")
        return 1
    keys = re.findall(r'"([^"]+)"', m.group(1))
    if len(keys) % 3 != 0:
        print("CONG GCDetailExp: %d khoa, khong chia het cho 3 -> bang sai hinh, DO" % len(keys))
        return 1
    # thu tu trong moi nhom: both (2 doi so) / onlyNormal (1) / onlyAdditional (1)
    expect = [2, 1, 1] * (len(keys) // 3)
    print("CONG GCDetailExp - bang `groups[]` doc tu ma nguon: %d khoa / %d nhom"
          % (len(keys), len(keys) // 3))
    bad2 = 0
    for k, want in zip(keys, expect):
        v = d.get(k)
        if v is None:
            print("   DO   %-42s khong co trong tu dien" % k)
            bad2 += 1
            continue
        n, fatal = count_args(v)
        ok = (n <= want) and not fatal
        if not ok:
            bad2 += 1
        print("   %-4s %-42s dac ta %d (cho goi dua %d)  CY=%s 085=%s"
              % ("XANH" if ok else "DO", k, n, want, "CO" if k in cy else "-",
                 "CO" if k in og else "-"))
    print()
    print("CONG GCDetailExp: %d khoa, DO: %d" % (len(keys), bad2))
    return 0 if (bad == 0 and bad2 == 0) else 1


if __name__ == '__main__':
    sys.exit(main())
