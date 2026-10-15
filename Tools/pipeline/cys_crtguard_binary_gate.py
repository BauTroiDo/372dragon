# -*- coding: utf-8 -*-
"""CYS-CRTGUARD: cong canh BINARY - ban va co THAT SU trong tep se chay khong?

"Da cai" khong bang "da bien dich" khong bang "co trong tep giao di" (ba dang sai lam do dem,
MOC-17-09 muc 4c). Mot lan ai do doi thu tu link, doi cau hinh, hay dung lai mot Game.exe cu,
handler bien mat IM LANG va ta quay ve lop loi "chet khong dau vet" ma khong ai hay.

Cong nay doc BANG IMPORT COFF cua Game.exe va doi:
  - `_set_invalid_parameter_handler`  (handler tham so CRT khong hop le)
  - `_set_purecall_handler`
  - chuoi `CYS-CRTGUARD: ARM=`        (dong log khoi dong)
va o UI_CEGUI.dll doi chuoi cua chot `%n` tai diem nghen.

    python cys_crtguard_binary_gate.py <thu muc Bin64>
    python cys_crtguard_binary_gate.py --selftest        # gom ca DOI CHUNG AM

DOI CHUNG AM cua selftest: chay chinh cong nay tren `Tools\\DATA NEW\\CY Game\\Bin64` (CY 3.71).
CY KHONG cai handler, nen cong PHAI bao DO o do. Mot cong khong biet truot la mot cong mu.
"""
import os
import re
import subprocess
import sys

OBJDUMP = os.environ.get("CYS_OBJDUMP", r"C:\Program Files\LLVM\bin\llvm-objdump.exe")
STRINGS = os.environ.get("CYS_STRINGS", r"C:\Program Files\LLVM\bin\llvm-strings.exe")

NEED_IMPORTS = ["_set_invalid_parameter_handler", "_set_purecall_handler"]
NEED_STR_EXE = ["CYS-CRTGUARD: ARM="]
NEED_STR_UI = ["CYS-CRTGUARD: khoa tu dien"]

CY_BIN64 = r"C:\TLBB\085\Tools\DATA NEW\CY Game\Bin64"


def imports_of(path):
    out = subprocess.run([OBJDUMP, "-p", path], capture_output=True, text=True,
                         errors="replace").stdout
    return set(re.findall(r"^\s+\d+\s+(\S+)$", out, re.M))


def strings_of(path):
    return subprocess.run([STRINGS, "-a", path], capture_output=True, text=True,
                          errors="replace").stdout


def check(bin_dir, quiet=False):
    """-> (ok, danh sach dong)"""
    lines = []
    ok = True
    exe = os.path.join(bin_dir, "Game.exe")
    ui = os.path.join(bin_dir, "UI_CEGUI.dll")
    if not os.path.exists(exe):
        return False, ["KHONG CO %s" % exe]

    imp = imports_of(exe)
    for s in NEED_IMPORTS:
        have = s in imp
        ok = ok and have
        lines.append("  Game.exe nhap %-34s : %s" % (s, "CO" if have else "KHONG  <== DO"))

    blob = strings_of(exe)
    for s in NEED_STR_EXE:
        have = s in blob
        ok = ok and have
        lines.append("  Game.exe co chuoi %-30s : %s" % (repr(s), "CO" if have else "KHONG  <== DO"))

    if os.path.exists(ui):
        blob = strings_of(ui)
        for s in NEED_STR_UI:
            have = s in blob
            ok = ok and have
            lines.append("  UI_CEGUI.dll co chuoi %-26s : %s" % (repr(s), "CO" if have else "KHONG  <== DO"))
    else:
        lines.append("  (khong co UI_CEGUI.dll trong thu muc nay - bo qua chot diem nghen)")

    return ok, lines


def main():
    args = [a for a in sys.argv[1:]]
    if args and args[0] == "--selftest":
        print("== DOI CHUNG AM: chay cong tren CY 3.71 (KHONG cai handler) ==")
        print("   %s" % CY_BIN64)
        if not os.path.isdir(CY_BIN64):
            print("   BO QUA: khong co thu muc CY tren may nay")
            return 0
        ok, lines = check(CY_BIN64)
        for l in lines:
            print(l)
        if ok:
            print("SELFTEST FAIL: cong bao XANH tren CY 3.71 - cong nay MU")
            return 1
        print("SELFTEST OK - cong BIET TRUOT (CY 3.71 bi bao DO dung nhu phai the)")
        return 0

    if not args:
        print(__doc__)
        return 2
    bin_dir = args[0]
    print("cong CYS-CRTGUARD tren: %s" % bin_dir)
    ok, lines = check(bin_dir)
    for l in lines:
        print(l)
    print("KET QUA: %s" % ("XANH - ban va co trong binary" if ok else
                           "DO - ban va KHONG co trong binary, DUNG TIN ket qua do tren stage nay"))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
