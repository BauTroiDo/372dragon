# -*- coding: utf-8 -*-
"""CYS-MSGEMPTY: xep 72 khoa rong vao BA NHOM, moi nhom mot cach xu ly khac han.

  (a) CY CO duong tuong duong nhung DOI TEN KHOA  -> sua CHO GOI sang khoa CY
  (b) CY BO HAN duong do                          -> khong lam gi
  (c) CY van dung, ta THIEU DONG TU DIEN          -> them ban dich

Phep do: CY 3.71 doi ten khoa theo luoc do `<DonViBienDich>_Info_<TenCu>` (vi du
`Target_Not_Exist` -> `GCRelationHandler_Info_Target_Not_Exist`). Cong nay:
  1. tim MOI chuoi trong CY Game.exe co dang `*_<TenCu>` (khong doan truoc tien to),
  2. kiem xem khoa CY do CO SAN trong StrDictionary cua ta chua (co san = chi phai sua ma),
  3. doi chung AM: khoa bia dat phai khong khop gi.

    python cys_msgempty_map.py --scan <scan.json> --cy-strings <cy-bin64-strings.txt> --out <map.json>
"""
import argparse
import json
import os
import re
import sys
import time

DICT = os.environ.get(
    "CYS_DICT",
    r"C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ConfigFolder\StrDictionary.txt")

NEG = ["Bia_Dat_Khong_Co", "ZZZ_Khong_Ton_Tai"]


def load_dict(path):
    d = {}
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            if '\t' not in line:
                continue
            k, v = line.rstrip('\n').rstrip('\r').split('\t', 1)
            d[k] = v
    return d


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scan', required=True)
    ap.add_argument('--cy-strings', required=True)
    ap.add_argument('--out', required=True)
    args = ap.parse_args()

    scan = json.load(open(args.scan, encoding='utf-8'))
    d = load_dict(DICT)

    cy = set()
    with open(args.cy_strings, 'r', encoding='latin-1') as f:
        for line in f:
            s = line.rstrip('\n').rstrip('\r')
            if re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]{2,80}', s):
                cy.add(s)
    # chi so hau to: hau to -> danh sach khoa CY ket thuc bang no
    suffix_index = {}
    for s in cy:
        for m in re.finditer(r'_', s):
            suffix_index.setdefault(s[m.end():], []).append(s)

    # 72 khoa + noi goi
    rows = []
    for s in scan['sites']:
        if not s.get('literal') or s['in_dict']['CanonicalCY']:
            continue
        rows.append({
            "key": s['key'], "origin": "call-site",
            "file": s['file'], "line": s['line'], "macro": s['macro'],
            "nargs": s['nargs'], "sink": s['sink'], "guards": s['guards'][-3:],
        })
    tbl_file = {t['var']: t['file'] for t in scan['tables']}
    for e in scan['table_missing']:
        rows.append({
            "key": e['key'], "origin": "table:" + e['table'],
            "file": tbl_file[e['table']], "line": None, "macro": "NOCOLORMSGFUNC",
            "nargs": 0, "sink": "GE_NEW_DEBUGMESSAGE", "guards": [],
        })

    def unit(fp):
        return os.path.basename(fp).rsplit('.', 1)[0]

    out_rows = []
    for r in rows:
        k = r['key']
        cands = sorted(set(suffix_index.get(k, [])))
        u = unit(r['file'])
        # Thu tu uu tien PHAI la khop CHINH XAC truoc. Ban dau toi chi loc theo tien to don vi
        # nen `Team_Is_Full` bat nham `GCTeamErrorHandler_Info_Target_Team_Is_Full` (hau to
        # trung) va `MONEY_OVERFLOW` bat `EXCHANGE_MONEY_OVERFLOW`. Hai ca deu la "cong dem
        # hoan hao tren mot dinh nghia thieu" - muc 17.
        preferred = None
        exact_unit = u + "_Info_" + k
        if exact_unit in cy:
            preferred = exact_unit
        if preferred is None:
            for c in cands:
                if c.endswith("_Info_" + k):
                    preferred = c
                    break
        if preferred is None:
            for c in cands:
                if c.startswith(u + "_"):
                    preferred = c
                    break
        # KHONG chon bua mot ung vien chi vi hau to trung: do la mot phong doan, khong phai do.
        if preferred is None:
            preferred = None
        in_our_dict = preferred in d if preferred else False
        if preferred and in_our_dict:
            group, act = "a", "doi cho goi sang khoa CY (ban dich DA CO)"
        elif preferred and not in_our_dict:
            group, act = "a", "doi cho goi sang khoa CY + them ban dich"
        elif k in cy:
            group, act = "c", "CY van dung dung ten nay - chi thieu dong tu dien"
        else:
            group, act = "b?", "khong tim thay dau vet trong CY - can doc ma CY"
        rr = dict(r)
        rr.update({"cy_candidates": cands, "cy_key": preferred,
                   "cy_key_in_our_dict": in_our_dict,
                   "our_value": d.get(preferred, "") if preferred else "",
                   "group": group, "action": act})
        out_rows.append(rr)

    neg_hit = [n for n in NEG if suffix_index.get(n)]
    res = {
        "generated": time.strftime("%Y-%m-%d %H:%M:%S"),
        "dict": DICT,
        "cy_identifier_strings": len(cy),
        "negative_control_hits": neg_hit,
        "rows": out_rows,
    }
    json.dump(res, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

    print("chuoi dinh danh trong CY Game.exe : %d" % len(cy))
    print("doi chung AM                      : %d/%d %s"
          % (len(neg_hit), len(NEG), "OK" if not neg_hit else "<<< HONG"))
    g = {}
    for r in out_rows:
        g[r['group']] = g.get(r['group'], 0) + 1
    print()
    for k in sorted(g):
        print("  nhom %-3s : %d dong" % (k, g[k]))
    nkeys = {}
    for r in out_rows:
        nkeys.setdefault(r['group'], set()).add(r['key'])
    print()
    for k in sorted(nkeys):
        print("  nhom %-3s : %d KHOA rieng biet" % (k, len(nkeys[k])))
    print()
    print("-> %s" % args.out)
    return 0


if __name__ == '__main__':
    sys.exit(main())
