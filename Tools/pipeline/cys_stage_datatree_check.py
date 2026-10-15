#!/usr/bin/env python3
# CYS-UIFRAMES: kiem mot stage doc DU LIEU tu cay nao, va CHAN neu sai cay.
#
# VI SAO CAN: `stage_game.py` chon cay du lieu MAC DINH mot cach IM LANG. Nam stage tro vao
# `Assets\Canonical` (cay TRUOC khi du an chot "moi thu nhu CY" ngay 14/09) deu VANG khi vao the
# gioi - binary thoi CY doc bang thoi tien-CY nen `GetIconName()` tra con tro rac
# (GMActionSystem_Item.cpp:64/67). Chung dung sach, cum DLL khop, moi tu kiem XANH, roi vang o
# cho khong ai ngo. Phep tu kiem san co CO kiem `Data` la junction nhung KHONG kiem no tro DI DAU.
#
# Do duoc 20/09: Canonical = 14 thu muc, StrDictionary 03/09 13,4 MB
#                CanonicalCY = 23 thu muc, StrDictionary 20/09 27,8 MB
#
#   python cys_stage_datatree_check.py <stage-dir> [--want CanonicalCY] [--out ket-qua.json]
#
# Ma thoat: 0 = dung cay, 1 = SAI CAY (dung tin ket qua do nao tren stage nay), 2 = khong doc duoc.

import argparse
import json
import os
import sys

DEFAULT_WANT = "CanonicalCY"


def junction_target(path):
    """Thu muc dich cua junction/symlink; None neu khong phai lien ket."""
    try:
        if not os.path.isdir(path):
            return None
        # os.path.realpath giai ca junction tren Windows
        real = os.path.realpath(path)
        return real if os.path.normcase(real) != os.path.normcase(os.path.abspath(path)) else None
    except OSError:
        return None


def tree_name(target):
    """`...\\Assets\\CanonicalCY\\Data` -> `CanonicalCY`."""
    if not target:
        return None
    parts = os.path.normpath(target).split(os.sep)
    for i, p in enumerate(parts):
        if p.lower() == "assets" and i + 1 < len(parts):
            return parts[i + 1]
    return parts[-2] if len(parts) >= 2 else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stage", nargs="?")
    ap.add_argument("--want", default=DEFAULT_WANT)
    ap.add_argument("--out")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()

    if a.self_test:
        ok = True

        def check(label, cond, detail=""):
            nonlocal ok
            print(("PASS " if cond else "FAIL ") + label + ("  " + detail if detail else ""))
            if not cond:
                ok = False

        print("DINH NGHIA: 'cay du lieu' = thu muc ngay sau `Assets` tren duong dan ma "
              "`<stage>\\Data` tro toi.")
        check("reads_CanonicalCY", tree_name(r"C:\x\Assets\CanonicalCY\Data") == "CanonicalCY")
        check("reads_Canonical", tree_name(r"C:\x\Assets\Canonical\Data") == "Canonical")
        check("distinguishes_the_two",
              tree_name(r"C:\x\Assets\Canonical\Data") != tree_name(r"C:\x\Assets\CanonicalCY\Data"),
              "(day la ca hai bi lan - 5 stage vang vi cho nay)")
        check("no_link_gives_None", tree_name(None) is None)
        sys.exit(0 if ok else 1)

    if not a.stage:
        ap.error("can <stage-dir>")
    data = os.path.join(a.stage, "Data")
    target = junction_target(data)
    name = tree_name(target)
    res = {
        "counting_definition": "cay du lieu = thu muc ngay sau `Assets` tren duong dan <stage>/Data tro toi",
        "stage": a.stage, "data_link_target": target, "tree": name, "want": a.want,
        "ok": bool(name) and name.lower() == a.want.lower(),
    }
    if a.out:
        json.dump(res, open(a.out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    if not target:
        print("KHONG DOC DUOC: %s khong phai junction/symlink (hoac khong ton tai)" % data)
        sys.exit(2)
    print("stage=%s\n  Data -> %s\n  cay = %s (can %s)" % (a.stage, target, name, a.want))
    if res["ok"]:
        print("KET QUA: DUNG CAY")
        sys.exit(0)
    print("KET QUA: SAI CAY - DUNG TIN bat ky ket qua do nao tren stage nay.")
    print("  (Binary thoi CY doc bang thoi tien-CY => GetIconName() tra con tro rac => vang khi vao the gioi.)")
    sys.exit(1)


if __name__ == "__main__":
    main()
