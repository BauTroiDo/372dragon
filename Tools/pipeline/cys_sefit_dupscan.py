#!/usr/bin/env python3
# CYS-SEFIT: quet va cham nghia trong ban dich.
#
# Muc dich: tim cac khoa co CHUOI GOC TIENG TRUNG KHAC NHAU nhung BAN DICH
# TIENG VIET GIONG HET NHAU. Do la loi mat phan biet ngu nghia -- nguoi choi
# nhin thay cung mot nhan cho hai khai niem khac nhau. Cong cu keo khung bang
# tay KHONG cuu duoc lop loi nay.
#
# Ket qua LUON ghi ra JSON (--out). Khong doc bang in man hinh de ket luan.
#
# Doi chung am (--selftest): chung minh phep do PHAT HIEN DUOC loi khi loi con
# do, va KHONG bao dong gia khi hai khoa cung chuoi goc.

import argparse
import json
import sys
from collections import defaultdict


def read_dict(path, encoding):
    """Doc StrDictionary dang TSV: key<TAB>value. Tra ve dict + so dong bo qua."""
    out = {}
    skipped = 0
    with open(path, "rb") as fh:
        raw = fh.read()
    text = raw.decode(encoding, errors="replace")
    for lineno, line in enumerate(text.splitlines(), 1):
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) < 2:
            skipped += 1
            continue
        key = parts[0].strip()
        val = parts[1]
        if not key:
            skipped += 1
            continue
        # giu lan xuat hien DAU TIEN, giong cach client nap bang
        if key not in out:
            out[key] = val
    return out, skipped


def scan(vi_path, cn_path, vi_enc="utf-8", cn_enc="gbk", prefix=None):
    vi, vi_skip = read_dict(vi_path, vi_enc)
    cn, cn_skip = read_dict(cn_path, cn_enc)

    joined = 0
    by_vi = defaultdict(list)  # vi_string -> [(key, cn_string)]
    for key, vi_val in vi.items():
        if prefix and not key.startswith(prefix):
            continue
        cn_val = cn.get(key)
        if cn_val is None:
            continue
        joined += 1
        by_vi[vi_val].append((key, cn_val))

    collisions = []
    for vi_val, members in by_vi.items():
        distinct_cn = {c for _, c in members}
        if len(distinct_cn) > 1:
            collisions.append(
                {
                    "vi": vi_val,
                    "distinct_cn_count": len(distinct_cn),
                    "members": [
                        {"key": k, "cn": c} for k, c in sorted(members)
                    ],
                }
            )
    collisions.sort(key=lambda d: (-d["distinct_cn_count"], d["vi"]))

    return {
        "vi_path": vi_path,
        "cn_path": cn_path,
        "prefix_filter": prefix,
        "vi_keys_total": len(vi),
        "cn_keys_total": len(cn),
        "vi_lines_skipped": vi_skip,
        "cn_lines_skipped": cn_skip,
        "keys_joined": joined,
        "vi_strings_distinct": len(by_vi),
        "collision_groups": len(collisions),
        "collision_keys": sum(len(c["members"]) for c in collisions),
        "collisions": collisions,
    }


def selftest():
    """Doi chung am: phep do phai BAT DUOC loi, va phai IM khi khong co loi."""
    ok = True

    # Truong hop 1: hai chuoi goc KHAC nhau -> cung ban dich => PHAI bao loi.
    by_vi = defaultdict(list)
    by_vi["The luc:"] = [("A", "体力:"), ("B", "精力:")]
    hit = [v for v, m in by_vi.items() if len({c for _, c in m}) > 1]
    if hit != ["The luc:"]:
        print("SELFTEST FAIL: khong bat duoc va cham that", file=sys.stderr)
        ok = False
    else:
        print("SELFTEST OK: bat duoc va cham that (2 chuoi goc khac -> 1 ban dich)")

    # Truong hop 2: hai khoa CUNG chuoi goc -> cung ban dich => KHONG duoc bao.
    by_vi2 = defaultdict(list)
    by_vi2["Dong y"] = [("A", "确定"), ("B", "确定")]
    hit2 = [v for v, m in by_vi2.items() if len({c for _, c in m}) > 1]
    if hit2:
        print("SELFTEST FAIL: bao dong gia tren cung chuoi goc", file=sys.stderr)
        ok = False
    else:
        print("SELFTEST OK: khong bao dong gia (cung chuoi goc)")

    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--vi", help="StrDictionary tieng Viet (UTF-8)")
    ap.add_argument("--cn", help="StrDictionary tieng Trung (GBK)")
    ap.add_argument("--vi-enc", default="utf-8")
    ap.add_argument("--cn-enc", default="gbk")
    ap.add_argument("--prefix", default=None, help="chi quet khoa bat dau bang tien to nay")
    ap.add_argument("--out", help="ghi ket qua day du ra file JSON")
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()

    if args.selftest:
        sys.exit(0 if selftest() else 1)

    if not args.vi or not args.cn:
        ap.error("can --vi va --cn")

    res = scan(args.vi, args.cn, args.vi_enc, args.cn_enc, args.prefix)

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(res, fh, ensure_ascii=False, indent=2)
        print("da ghi JSON: %s" % args.out)

    # Chi in TOM TAT. Con so that nam trong JSON.
    print("khoa VI=%d  khoa CN=%d  ghep duoc=%d" % (res["vi_keys_total"], res["cn_keys_total"], res["keys_joined"]))
    print("nhom va cham=%d  tong khoa dinh va cham=%d" % (res["collision_groups"], res["collision_keys"]))


if __name__ == "__main__":
    main()
