#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ui-fit: ap lai cac ban dich DA RUT NGAN cho vua khung, trong Assets/CanonicalCY.

VI SAO CAN: `Tools/pipeline/build_canonical_cy.py` dung lai `Assets/CanonicalCY` tu cac .axp cua
CY 3.71 va se XOA moi sua doi trong do. Script nay la CONG THUC de ap lai.

LUAT SO MOT cua mang nay: KHONG noi container theo ty le (2.381 o luoi phu thuoc nhau).
Cach sua dung = RUT NGAN BAN DICH. Vi vay moi thay doi o day chi la:
  - doi mot chuoi hien thi trong *.lua thanh chuoi ngan hon, hoac
  - them mot thuoc tinh KHONG dong den hinh hoc (vi du Tooltip) vao *.layout.xml.
Khong doi UnifiedSize / UnifiedPosition / AbsoluteSize / AbsolutePosition.

Dung:
  python -X utf8 Tools/reapply/ui-fit/80-ui-fit-strings.py plan
  python -X utf8 Tools/reapply/ui-fit/80-ui-fit-strings.py apply  --bak Build/reapply-bak
  python -X utf8 Tools/reapply/ui-fit/80-ui-fit-strings.py verify

`apply` idempotent: chay lan hai khong doi gi (dem `da co` thay vi `da ghi`).
`verify` doc LAI tu dia va kiem tra tung ban vá + kiem "khong con chuoi cu".
"""

import argparse
import hashlib
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
UI = os.path.join(ROOT, "Assets", "CanonicalCY", "Data", "InterfaceFolder")
PATCHES = os.path.join(HERE, "data", "ui-fit-patches.json")


def load():
    with open(PATCHES, "r", encoding="utf-8") as fh:
        return json.load(fh)


def read(path):
    with open(path, "rb") as fh:
        return fh.read()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=("plan", "apply", "verify"))
    ap.add_argument("--ui", default=UI)
    ap.add_argument("--bak", default="")
    args = ap.parse_args()

    doc = load()
    todo, done, missing = 0, 0, 0
    per_file = {}
    for patch in doc["patches"]:
        per_file.setdefault(patch["file"], []).append(patch)

    for rel, patches in sorted(per_file.items()):
        path = os.path.join(args.ui, rel.replace("/", os.sep))
        if not os.path.isfile(path):
            print("THIEU FILE %s" % rel)
            missing += len(patches)
            continue
        raw = read(path)
        text = raw.decode("utf-8")
        # Cac .layout.xml cua CY dung CRLF, .lua dung LF: doi ban va theo file, GIU nguyen kieu xuong dong.
        eol = "\r\n" if "\r\n" in text else "\n"
        changed = text
        for p in patches:
            old = p["old"].replace("\n", eol)
            new = p["new"].replace("\n", eol)
            n_old = changed.count(old)
            n_new = changed.count(new)
            if args.cmd == "verify":
                ok = n_old == 0 and n_new >= p.get("count", 1)
                print("%-4s %-46s %s -> %s  (cu=%d moi=%d)" %
                      ("OK" if ok else "SAI", rel, _s(old), _s(new), n_old, n_new))
                if ok:
                    done += 1
                else:
                    missing += 1
                continue
            if n_old == 0 and n_new >= p.get("count", 1):
                done += 1
                if args.cmd == "plan":
                    print("da co   %-46s %s" % (rel, _s(new)))
                continue
            if n_old != p.get("count", 1):
                print("SAI SO LUONG %s: '%s' thay %d lan, cho %d -> BO QUA"
                      % (rel, _s(old), n_old, p.get("count", 1)))
                missing += 1
                continue
            changed = changed.replace(old, new)
            todo += 1
            if args.cmd == "plan":
                print("se ghi  %-46s %s -> %s" % (rel, _s(old), _s(new)))
        if args.cmd == "apply" and changed != text:
            if args.bak:
                dst = os.path.join(args.bak, "ui-fit", rel.replace("/", os.sep))
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                if not os.path.exists(dst):
                    shutil.copy2(path, dst)
            tmp = path + ".uifit.tmp"
            with open(tmp, "wb") as fh:
                fh.write(changed.encode("utf-8"))
            os.replace(tmp, path)
            print("da ghi  %s  sha256 %s" % (rel, hashlib.sha256(changed.encode("utf-8")).hexdigest()[:16]))

    print("\n%s: se-ghi=%d da-co=%d hong=%d" % (args.cmd, todo, done, missing))
    return 1 if (args.cmd == "verify" and missing) else 0


def _s(v):
    return repr(v)[1:-1][:44]


if __name__ == "__main__":
    sys.exit(main())
