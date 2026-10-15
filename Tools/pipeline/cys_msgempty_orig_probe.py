# -*- coding: utf-8 -*-
"""CYS-MSGEMPTY: 72 khoa rong co trong CLIENT GOC 0.85 khong? (cau hoi cua dieu phoi)

Ba cay, ba cau hoi khac nhau - KHONG duoc tron:
  * `C:\\TLBB\\085\\client`        -> "ban GOC 0.85 lam gi"   (chi doc, luat 06/09)
  * `CY-Source\\Assets\\CanonicalCY` -> "ta dang co gi hom nay"
  * `Tools\\DATA NEW\\CY Game`     -> "CY 3.71 lam gi"        (tieu chi thang)

Moi ket luan deu ghi kem TEN CAY + sha256 cua tep da doc.
Doi chung duong + am bat buoc, giong `cys_msgempty_cy_probe.py`.

    python cys_msgempty_orig_probe.py --scan <scan.json> --out <orig.json>
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time

ORIG = os.environ.get("CYS_ORIG_CLIENT", r"C:\TLBB\085\client")
STRINGS = os.environ.get("CYS_LLVM_STRINGS", r"C:\Program Files\LLVM\bin\llvm-strings.exe")
DICTS = [
    ("orig/ConfigFolder", os.path.join(ORIG, r"Data\ConfigFolder\StrDictionary.txt")),
    ("orig/ConfigDecoded", os.path.join(ORIG, r"Data\ConfigDecoded\StrDictionary.txt")),
    ("ref/tlbb085", r"C:\TLBB\085\CY-Source\Reference\tlbb085\085\Build\Client\Data\Config\StrDictionary.txt"),
]
BINS = [
    ("orig/Bin64/Game.exe", os.path.join(ORIG, r"Bin64\Game.exe")),
    ("orig/Bin/Game.exe", os.path.join(ORIG, r"Bin\Game.exe")),
]
NEG = ["WIN_EXP_KHONG_CO_THAT", "CYS_MSGEMPTY_BIA_DAT"]
POS = ["ERRORSpecialString", "Ability_Requiement"]


def sha256(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def load_dict(p):
    d, dup = {}, 0
    with open(p, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            if '\t' not in line:
                continue
            k, v = line.rstrip('\n').rstrip('\r').split('\t', 1)
            if k in d:
                dup += 1
            d[k] = v
    return d, dup


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scan', required=True)
    ap.add_argument('--out', required=True)
    args = ap.parse_args()
    scan = json.load(open(args.scan, encoding='utf-8'))
    keys = sorted({s['key'] for s in scan['sites']
                   if s.get('literal') and not s['in_dict']['CanonicalCY']})
    keys += [e['key'] for e in scan['table_missing']]

    res = {"generated": time.strftime("%Y-%m-%d %H:%M:%S"), "orig_root": ORIG,
           "dicts": {}, "bins": {}, "keys": keys, "in_orig_dict": {}, "in_orig_bin": {}}

    for name, p in DICTS:
        if not os.path.isfile(p):
            res["dicts"][name] = {"path": p, "exists": False}
            continue
        d, dup = load_dict(p)
        res["dicts"][name] = {"path": p, "exists": True, "keys": len(d), "dup_keys": dup,
                              "sha256": sha256(p),
                              "mtime": time.strftime("%Y-%m-%d %H:%M:%S",
                                                     time.localtime(os.path.getmtime(p)))}
        res["dicts"][name]["_d"] = d

    corpus = {}
    for name, p in BINS:
        if not os.path.isfile(p):
            continue
        out = subprocess.run([STRINGS, "-a", "-n", "4", p], capture_output=True)
        corpus[name] = out.stdout.decode('latin-1')
        res["bins"][name] = {"path": p, "sha256": sha256(p), "size": os.path.getsize(p)}

    def in_bin(k):
        return {n: len(re.findall(r'(?m)^' + re.escape(k) + r'$', t)) for n, t in corpus.items()}

    for k in keys + NEG + POS:
        res["in_orig_dict"][k] = {n: (k in v["_d"]) for n, v in res["dicts"].items() if "_d" in v}
        res["in_orig_bin"][k] = in_bin(k)

    for v in res["dicts"].values():
        v.pop("_d", None)

    json.dump(res, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

    print("CLIENT GOC: %s" % ORIG)
    for n, v in res["bins"].items():
        print("  %-22s sha256 %s" % (n, v["sha256"]))
    for n, v in res["dicts"].items():
        if v.get("exists"):
            print("  %-22s sha256 %s  %d khoa  trung %d  mtime %s"
                  % (n, v["sha256"][:16] + "...", v["keys"], v["dup_keys"], v["mtime"]))
    print()
    okpos = [k for k in POS if any(res["in_orig_bin"][k].values())
             or any(res["in_orig_dict"][k].values())]
    okneg = [k for k in NEG if any(res["in_orig_bin"][k].values())
             or any(res["in_orig_dict"][k].values())]
    print("DOI CHUNG DUONG : %d/%d  %s" % (len(okpos), len(POS), "OK" if okpos else "<<< HONG"))
    print("DOI CHUNG AM    : %d/%d  %s" % (len(okneg), len(NEG), "OK" if not okneg else "<<< HONG"))
    if not okpos:
        return 1

    n_bin = n_dict = n_both = 0
    print("\n%-30s %-12s %s" % ("khoa", "trong EXE?", "trong TU DIEN GOC?"))
    for k in keys:
        b = any(res["in_orig_bin"][k].values())
        d = any(res["in_orig_dict"][k].values())
        n_bin += b
        n_dict += d
        n_both += (b and d)
        print("%-30s %-12s %s" % (k, "CO" if b else "-", "CO" if d else "-"))
    print("\nTONG %d khoa: trong EXE goc %d | trong TU DIEN goc %d | ca hai %d"
          % (len(keys), n_bin, n_dict, n_both))
    print("-> %s" % args.out)
    return 0


if __name__ == '__main__':
    sys.exit(main())
