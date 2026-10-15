#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ui-fit-2 (17-18/09/2026): ap lai cac chuoi StrDictionary DA RUT NGAN cho vua khung giao dien CY.

VI SAO CAN: khac voi `80-ui-fit-strings.py` (sua truc tiep file trong `Assets/CanonicalCY/Data/InterfaceFolder`,
bi `build_canonical_cy.py` xoa), lop nay sua **nguon**: `Registry/i18n/cy_vi_override.tsv` - file NAM TRONG GIT.
`build_canonical_cy.py --apply --gui cy` va `Tools/pipeline/cy_i18n_apply.py apply` deu doc file do, nen sau khi
dung lai cay Assets thi StrDictionary.txt tu dong co lai ban rut ngan. Script nay chi de:

  * `verify`  kiem tra ca ba thu con khop: so dong `ui-fit-2` trong cy_vi_override.tsv, gia tri thuc trong
              StrDictionary.txt dang chay, va 0 dong con dau tieng Viet dang to hop (NFD).
  * `apply`   chay lai `cy_i18n_apply.py apply` (dan xuat StrDictionary + cac bang DBC tu Registry).
  * `plan`    chi in trang thai, khong ghi gi.

Nguon du lieu that su cua lop nay:
  Tools/ui-fit/data/short_vi.tsv   ban rut ngan viet tay (khoa -> chuoi ngan + ly do)
  Tools/ui-fit/data/abbr_vi.tsv    bang viet tat dung chung
  Tools/ui-fit/data/nfd_fix.tsv    sua tay cho dong NFD ma NFC khong ghep duoc
Dung lai tu dau (khi can lam lai tu so do):
  python Tools/ui-fit/measure_ui_text.py --out <D> --cy-dict <cy.tsv> --dyn-digits 7 --all-rows
  python Tools/ui-fit/shorten_plan.py   --measure <D> --cy-dict <cy.tsv> --out <P> --scope fit   (roi --scope over)
  python Tools/ui-fit/apply_overrides.py --rows <P>/override_rows.tsv --nfd
  python -B Tools/pipeline/cy_i18n_apply.py apply

LUAT SO MOT van giu: khong noi container theo ty le, khong dung toi UnifiedSize/UnifiedPosition/Absolute*.
Lop nay CHI doi chu hien thi.
"""
import argparse
import os
import re
import subprocess
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OVERRIDE = os.path.join(ROOT, "Registry", "i18n", "cy_vi_override.tsv")
DICT = os.path.join(ROOT, "Assets", "CanonicalCY", "Data", "ConfigFolder", "StrDictionary.txt")
GEN = os.path.join(ROOT, "Assets", "CanonicalCY", "_generated", "gui-cy", "ConfigFolder", "StrDictionary.txt")
APPLY = os.path.join(ROOT, "Tools", "pipeline", "cy_i18n_apply.py")
COMB = re.compile("[̀-ͯ]")
TAG = "ui-fit-2"


def load_override():
    """-> {khoa: (gia tri, ghi chu)} cho cac dong do ui-fit-2 them."""
    rows = {}
    with open(OVERRIDE, "r", encoding="utf-8") as fh:
        for i, line in enumerate(fh):
            if i == 0:
                continue
            parts = line.rstrip("\r\n").split("\t")
            if len(parts) < 2 or not parts[0].startswith("#"):
                continue
            note = parts[2] if len(parts) > 2 else ""
            if TAG in note:
                rows.setdefault(parts[0][1:], (parts[1], note))
    return rows


def load_dict(path):
    d = {}
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for i, line in enumerate(fh):
            if i < 2:
                continue
            line = line.rstrip("\r\n")
            if "\t" not in line:
                continue
            k, v = line.split("\t", 1)
            d.setdefault(k, v)
    return d


def check():
    rows = load_override()
    problems = []
    if not os.path.isfile(DICT):
        return rows, ["THIEU %s - chay cy_i18n_apply.py apply" % DICT], 0
    d = load_dict(DICT)
    bad = [k for k, (v, _n) in rows.items() if d.get(k) != v]
    nfd = [k for k, v in d.items() if COMB.search(v)]
    if bad:
        problems.append("%d khoa trong StrDictionary KHAC ban rut ngan (vi du: %s)" % (len(bad), ", ".join(bad[:5])))
    if nfd:
        problems.append("%d dong con dau tieng Viet dang to hop NFD (vi du: %s)" % (len(nfd), ", ".join(nfd[:5])))
    for k, (v, _n) in rows.items():
        if COMB.search(unicodedata.normalize("NFC", v)) and v == d.get(k):
            problems.append("khoa %s con dau roi sau NFC - can mot dong trong Tools/ui-fit/data/nfd_fix.tsv" % k)
    return rows, problems, len(nfd)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=("plan", "apply", "verify"))
    args = ap.parse_args()
    rows, problems, _n = check()
    print("ban rut ngan ui-fit-2 trong cy_vi_override.tsv: %d khoa" % len(rows))
    if args.cmd == "apply":
        if not problems:
            print("da khop san; van chay cy_i18n_apply.py apply cho chac (idempotent)")
        rc = subprocess.call([sys.executable, "-B", APPLY, "apply"], cwd=ROOT)
        if rc:
            print("cy_i18n_apply.py apply that bai rc=%d" % rc)
            return rc
        rows, problems, _n = check()
    for p in problems:
        print("SAI: %s" % p)
    print("%s: khoa=%d hong=%d" % (args.cmd, len(rows), len(problems)))
    return 1 if (args.cmd in ("verify", "apply") and problems) else 0


if __name__ == "__main__":
    sys.exit(main())
