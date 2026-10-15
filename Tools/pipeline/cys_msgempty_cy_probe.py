# -*- coding: utf-8 -*-
"""CYS-MSGEMPTY: khoa nao trong 72 khoa rong CON duoc CY 3.71 dung?

Cau hoi 4 cua de bai. Luat 22.8: dia chi/ket luan ve CY phai kem TEN BAN DUNG + sha256.
Ban dung do o day duoc doc TU TEP `(version)` cua chinh thu muc CY, khong tin ghi chu.

Phep do: rut chuoi ASCII cua `Game.exe` (x64 va x86) roi tim khoa. KEM:
  * DOI CHUNG DUONG - 66 khoa `g_szGemAttName` va `Ability_Requiement`, deu la khoa ma
    ban 0.85 CO trong tu dien. Neu phep do khong tim thay chung thi phep do HONG, va
    moi ket luan "CY khong co khoa X" deu vo nghia.
  * DOI CHUNG AM - vai khoa bia dat, phai KHONG tim thay.

    python cys_msgempty_cy_probe.py --scan <msgempty-scan.json> --out <cyprobe.json>
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time

CY_ROOT = os.environ.get("CYS_CY_ROOT", r"C:\TLBB\085\Tools\DATA NEW\CY Game")
STRINGS = os.environ.get("CYS_LLVM_STRINGS", r"C:\Program Files\LLVM\bin\llvm-strings.exe")

NEG_CONTROL = ["WIN_EXP_KHONG_CO_THAT", "CYS_MSGEMPTY_BIA_DAT", "ZZZ_KHONG_TON_TAI_9x"]


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def build_id(root):
    p = os.path.join(root, "(version)")
    if not os.path.isfile(p):
        return None
    with open(p, 'rb') as f:
        return f.readline().decode('ascii', 'replace').strip()


def strings_of(path, minlen=4):
    out = subprocess.run([STRINGS, "-a", "-n", str(minlen), path],
                         capture_output=True)
    if out.returncode != 0:
        raise SystemExit("llvm-strings loi: %s" % out.stderr[:300])
    return out.stdout.decode('latin-1')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scan', required=True)
    ap.add_argument('--out', required=True)
    args = ap.parse_args()

    scan = json.load(open(args.scan, encoding='utf-8'))
    keys_sites = sorted({s['key'] for s in scan['sites']
                         if s.get('literal') and not s['in_dict']['CanonicalCY']})
    keys_table = [e['key'] for e in scan['table_missing']]
    # doi chung duong: khoa BANG CO trong tu dien cua ta (g_szGemAttName) + Ability_Requiement
    pos = []
    for t in scan['tables']:
        for e in t['keys']:
            if e['key'] and e['in_dict'].get('CanonicalCY'):
                pos.append(e['key'])
    pos.append("Ability_Requiement")

    bins = []
    for rel in (r"Bin64\Game.exe", r"Bin\Game.exe"):
        p = os.path.join(CY_ROOT, rel)
        if os.path.isfile(p):
            bins.append((rel, p))

    result = {
        "generated": time.strftime("%Y-%m-%d %H:%M:%S"),
        "cy_root": CY_ROOT,
        "cy_build_id": build_id(CY_ROOT),
        "binaries": [],
        "keys_from_call_sites": keys_sites,
        "keys_from_tables": keys_table,
        "found": {},
    }

    corpus = {}
    for rel, p in bins:
        txt = strings_of(p)
        corpus[rel] = txt
        result["binaries"].append({
            "rel": rel, "sha256": sha256(p), "size": os.path.getsize(p),
            "strings_bytes": len(txt),
        })

    def probe(k):
        r = {}
        for rel, txt in corpus.items():
            # khoa la mot chuoi ket-NUL doc lap trong binary; llvm-strings tach theo dong
            r[rel] = len(re.findall(r'(?m)^' + re.escape(k) + r'$', txt))
        return r

    for k in keys_sites + keys_table:
        result["found"][k] = probe(k)
    result["positive_control"] = {k: probe(k) for k in pos}
    result["negative_control"] = {k: probe(k) for k in NEG_CONTROL}

    json.dump(result, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

    # --- bao cao
    print("CY build: %s" % result["cy_build_id"])
    for b in result["binaries"]:
        print("  %-16s sha256 %s" % (b["rel"], b["sha256"]))
    npos = sum(1 for k, v in result["positive_control"].items() if any(v.values()))
    print("\nDOI CHUNG DUONG : %d/%d khoa tim thay trong CY  %s"
          % (npos, len(pos), "OK" if npos > 0 else "<<< PHEP DO HONG"))
    nneg = sum(1 for k, v in result["negative_control"].items() if any(v.values()))
    print("DOI CHUNG AM    : %d/%d khoa bia dat tim thay   %s"
          % (nneg, len(NEG_CONTROL), "OK" if nneg == 0 else "<<< PHEP DO HONG"))
    if npos == 0:
        print("\n!! Doi chung duong TRUOT => khong duoc phep ket luan gi tu phep do nay.")
        return 1

    hit = [k for k in keys_sites + keys_table if any(result["found"][k].values())]
    miss = [k for k in keys_sites + keys_table if not any(result["found"][k].values())]
    print("\n72 khoa rong, CY 3.71 CO chuoi : %d" % len(hit))
    for k in hit:
        print("    CO  %-34s %s" % (k, result["found"][k]))
    print("\n72 khoa rong, CY 3.71 KHONG co : %d" % len(miss))
    for k in miss:
        print("    -   %s" % k)
    print("\n-> %s" % args.out)
    return 0


if __name__ == '__main__':
    sys.exit(main())
