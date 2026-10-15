# -*- coding: utf-8 -*-
"""Bien overflow.csv thanh ba danh sach dung duoc ngay.

  for_i18n.tsv   danh sach chuoi CAN RUT NGAN gui cho i18n-cy:
                 khoa -> chuoi hien tai -> khung hep nhat -> ngan sach px -> chuoi CY goc
  by_frame.tsv   khung nao hong nhieu nhat (xep theo so loi chac chan)
  worst.tsv      200 widget tran nang nhat, co duong dan file

Chay:
  python Tools/ui-fit/report_ui_fit.py --in <thu muc co overflow.csv> [--out <thu muc>]
"""

import argparse
import collections
import csv
import os
import re

KEY_ONLY = re.compile(r"^\s*#\{([^}]+)\}\s*$")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="indir", required=True)
    ap.add_argument("--out", default="")
    ap.add_argument("--min-over", type=float, default=0.5)
    args = ap.parse_args()
    out = args.out or args.indir
    os.makedirs(out, exist_ok=True)

    with open(os.path.join(args.indir, "overflow.csv"), "r", encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh))

    # "chac chan": tran ngay ca khi phan gia tri chay bang rong, widget khong bi an
    sure = [r for r in rows
            if r["visible"] == "1" and float(r["over_px_min"]) > args.min_over]
    reg = [r for r in sure if r["cy"] == "cy-fit"]      # CY vua, ban Viet tran -> do dich
    cyover = [r for r in sure if r["cy"] == "cy-over"]  # CY cung tran -> hanh vi cua CY

    # ---- for_i18n.tsv : gom theo khoa StrDictionary
    per_key = collections.defaultdict(list)
    for r in reg:
        m = KEY_ONLY.match(r["raw"])
        if m:
            per_key[m.group(1)].append(r)
    lines = []
    for key, rs in per_key.items():
        tight = min(rs, key=lambda r: float(r["box_w"]))
        lines.append({
            "khoa": key,
            "so_widget": len(rs),
            "khung_hep_nhat_px": tight["box_w"],
            "be_rong_hien_tai_px": tight["text_w"],
            "vuot_px": tight["over_px_min"],
            "be_rong_CY_px": tight["cy_w"],
            "font": tight["font"],
            "chuoi_hien_tai": tight["shown"],
            "khung_vi_du": tight["layout"].split("/")[0],
            "widget_vi_du": tight["widget"],
        })
    lines.sort(key=lambda d: (-int(d["so_widget"]), -float(d["vuot_px"])))
    _write(os.path.join(out, "for_i18n.tsv"), lines)

    # ---- by_frame.tsv
    frames = collections.Counter(r["layout"].split("/")[0] for r in reg)
    worst_of = {}
    for r in reg:
        f = r["layout"].split("/")[0]
        if f not in worst_of or float(r["over_px_min"]) > float(worst_of[f]["over_px_min"]):
            worst_of[f] = r
    frows = [{"khung": f, "so_loi": n,
              "nang_nhat_px": worst_of[f]["over_px_min"],
              "widget_nang_nhat": worst_of[f]["widget"],
              "chuoi": worst_of[f]["shown"][:80]}
             for f, n in frames.most_common()]
    _write(os.path.join(out, "by_frame.tsv"), frows)

    # ---- worst.tsv
    w = sorted(reg, key=lambda r: -float(r["over_px_min"]))[:200]
    _write(os.path.join(out, "worst.tsv"),
           [{k: r[k] for k in ("layout", "widget", "type", "kind", "font", "box_w",
                               "text_w", "over_px_min", "cy_w", "horz", "source", "shown")}
            for r in w])

    # ---- overlap_by_frame.tsv
    ovpath = os.path.join(args.indir, "overlap.csv")
    n_ov = 0
    if os.path.isfile(ovpath):
        with open(ovpath, "r", encoding="utf-8") as fh:
            ov = list(csv.DictReader(fh))
        n_ov = len(ov)
        cnt = collections.Counter(r["layout"].split("/")[0] for r in ov)
        worst = {}
        for r in ov:
            f = r["layout"].split("/")[0]
            if f not in worst or float(r["chong_px"]) > float(worst[f]["chong_px"]):
                worst[f] = r
        _write(os.path.join(out, "overlap_by_frame.tsv"),
               [{"khung": f, "so_cap": n, "nang_nhat_px": worst[f]["chong_px"],
                 "widget": worst[f]["widget"], "de_len": worst[f]["de_len"]}
                for f, n in cnt.most_common()])

    print("tong dong tran      :", len(rows))
    print("chac chan + hien    :", len(sure))
    print("  do DICH (CY vua)  :", len(reg), " <- danh sach phai sua")
    print("  CY cung tran      :", len(cyover), " <- hanh vi cua CY, de sau")
    print("khoa StrDictionary  :", len(per_key), "khoa  ->", os.path.join(out, "for_i18n.tsv"))
    print("khung co loi        :", len(frames), "->", os.path.join(out, "by_frame.tsv"))
    print("cap chu de len nhau :", n_ov, "->", os.path.join(out, "overlap_by_frame.tsv"))


def _write(path, rows):
    if not rows:
        open(path, "w", encoding="utf-8").write("")
        return
    with open(path, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()), delimiter="\t")
        w.writeheader()
        for r in rows:
            w.writerow(r)


if __name__ == "__main__":
    main()
