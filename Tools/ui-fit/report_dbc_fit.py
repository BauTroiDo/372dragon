# -*- coding: utf-8 -*-
"""ui-fit-3: xep hang cho tran den tu bang DBC + xuat danh sach chuoi can rut ngan cho i18n.

    python Tools/ui-fit/report_dbc_fit.py --measure <thu muc measure_ui_text --dbc> [--dot 2]

Ra:
    <thu muc>/dbc_rank.txt        bang xep hang theo khung (nguoi doc)
    <thu muc>/for_i18n_dbc.tsv    tung chuoi can rut ngan: bang, cot, dong, px thua, khung, zh, vi
"""

import argparse
import collections
import csv
import json
import os
import statistics


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--measure", required=True)
    ap.add_argument("--dot", default="", help="chi lay dot nay (1 = bang dich dot truoc, 2 = 8 bang i18n-2)")
    args = ap.parse_args()

    rows = list(csv.DictReader(open(os.path.join(args.measure, "dbc_overflow.csv"),
                                    encoding="utf-8")))
    den = json.load(open(os.path.join(args.measure, "dbc_summary.json"),
                        encoding="utf-8"))["mau_so_tung_cap"]
    if args.dot:
        rows = [r for r in rows if r["dot"] == args.dot]

    agg = collections.defaultdict(collections.Counter)
    px = collections.defaultdict(list)
    for r in rows:
        k = "%s|%s|%s.c%s" % (r["layout"], r["widget"], r["table"], r["col"])
        agg[k][r["cy"]] += 1
        agg[k]["tran"] += 1
        agg[k]["dong"] += int(r["so_dong"])
        px[k].append(float(r["over_px"]))

    out = []
    hdr = ("%-3s %-34s %-26s %-9s %6s %5s %6s %6s %6s %6s %6s %6s"
           % ("dot", "khung/widget", "bang.cot", "kieu", "box_w", "w1d",
              "n_do", "n_tran", "cy_fit", "cy_ovr", "max_px", "med_px"))
    out.append(hdr)
    out.append("-" * len(hdr))
    for k in sorted(agg, key=lambda k: -agg[k]["tran"]):
        d = den.get(k, {})
        _lay, w, tc = k.split("|")
        a = agg[k]
        out.append("%-3s %-34s %-26s %-9s %6s %5s %6s %6d %6d %6d %6d %6d" % (
            d.get("dot", "?"), w[:34], tc, d.get("kind", "?"), d.get("box_w", "?"),
            d.get("wrap_1_dong", "?"), d.get("da_do", "?"), a["tran"], a["cy-fit"],
            a["cy-over"], int(max(px[k])), int(statistics.median(px[k]))))
    txt = "\n".join(out)
    open(os.path.join(args.measure, "dbc_rank.txt"), "w", encoding="utf-8").write(txt + "\n")
    print(txt)

    # danh sach cho i18n: chi nhung chuoi ma CY VUA khung con ban Viet tran (loi do ban dich)
    need = [r for r in rows if r["cy"] == "cy-fit"]
    need.sort(key=lambda r: -float(r["over_px"]))
    with open(os.path.join(args.measure, "for_i18n_dbc.tsv"), "w", newline="",
              encoding="utf-8") as fh:
        w = csv.writer(fh, delimiter="\t")
        w.writerow(["bang", "cot", "member", "dong_dau", "so_dong", "khung", "widget",
                    "box_w", "vi_w", "cy_w", "thua_px", "zh", "vi"])
        for r in need:
            w.writerow([r["table"], r["col"], r["member"], r["dong_dau"], r["so_dong"],
                        r["layout"].split("/")[0], r["widget"], r["box_w"], r["vi_w"],
                        r["cy_w"], r["over_px"], r["zh"], r["vi"]])
    print("\n-> %s (%d chuoi can rut ngan)"
          % (os.path.join(args.measure, "for_i18n_dbc.tsv"), len(need)))


if __name__ == "__main__":
    main()
