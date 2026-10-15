# -*- coding: utf-8 -*-
"""Rut bang chu GOC cua CY 3.71 (tieng Trung) ra TSV de doi chieu be rong.

Nguon: C:\\TLBB\\085\\Tools\\DATA NEW\\CY Game\\Data\\Config.axp -> StrDictionary.txt
       (payload ma hoa, alg 24; sau khi giai la DBC nhi phan 00CCBBDD, 2 cot STRING)

Dung lai bo doc AXP co san cua du an (Docs/evidence/assetinv/axp_index.py) de giai ma payload.
Phan DBC doc tai cho vi BAY: Tools/game/dbc_inventory.py thu UTF-8 TRUOC roi moi GBK, nen
chuoi GBK ngan nhu "hoc tap" (D1 A7 CF B0) lai la UTF-8 hop le va ra chu Kirin ('...').
O day ep GBK cho moi o STRING.

Chay:
  python Tools/ui-fit/extract_cy_dict.py --out <thu muc>/cy_strdict.tsv
"""

import argparse
import os
import struct
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "Docs", "evidence", "assetinv"))

DEFAULT_AXP = r"C:\TLBB\085\Tools\DATA NEW\CY Game\Data\Config.axp"


def read_dbc_strings(raw, encoding="gbk"):
    """DBC 00CCBBDD hai cot STRING -> [(key, value)]. Bo dem chuoi doc bang GBK."""
    if raw[:4] != b"\x00\xcc\xbb\xdd":
        raise SystemExit("khong phai DBC nhi phan 00CCBBDD")
    _, fields, records, strings = struct.unpack_from("<Iiii", raw, 0)
    kinds = struct.unpack_from("<%dI" % fields, raw, 16)
    if fields != 2 or set(kinds) != {2}:  # 2 = STRING (TLBB_DBC.cpp)
        raise SystemExit("bang khong phai 2 cot STRING: fields=%d kinds=%s" % (fields, kinds))
    base = 16 + 4 * fields
    cells = struct.unpack_from("<%dI" % (fields * records), raw, base)
    pool = raw[base + 4 * fields * records:base + 4 * fields * records + strings]

    def cell(v):
        end = pool.find(b"\0", v) if v < len(pool) else -1
        return pool[v:end].decode(encoding, "replace") if end >= 0 else ""

    return [(cell(cells[r * 2]), cell(cells[r * 2 + 1])) for r in range(records)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--axp", default=DEFAULT_AXP)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    import axp_index as AX

    archive = AX.Axp(args.axp)
    payload = archive.payload_full("StrDictionary.txt", maxlen=64 << 20)
    if payload is None:
        raise SystemExit("khong tim thay StrDictionary.txt trong " + args.axp)
    alg, data = payload
    rows = read_dbc_strings(data)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)) or ".", exist_ok=True)
    with open(args.out, "w", encoding="utf-8", newline="") as fh:
        for key, value in rows:
            fh.write("%s\t%s\r\n" % (key, value.replace("\t", " ")))
    print("alg=%s  records=%d  -> %s" % (alg, len(rows), args.out))


if __name__ == "__main__":
    main()
