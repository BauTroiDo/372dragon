# -*- coding: utf-8 -*-
"""CYS-UIEDIT 19/09/2026 — sinh `ui_edit_targets.tsv` cho bo sua bo cuc UI trong game.

Bo sua doc file nay de PgUp/PgDn di qua tung khung HONG THAT, ke ca khung khong co duong mo binh
thuong. Moi dong:

    <ten khung trong InterfaceEx.txt>  <TAB>  <ten widget tran>  <TAB>  <ghi chu>

Cot 1 la ten window cua `InterfaceEx.txt` (cot 1 `szName`) — chinh la ten ma
`CUIWindowMng::ShowWindowByName` tra cuu. KHONG dung ten tep layout: ca hai gan giong nhau nhung
KHONG phai lúc nao cung trung (vd nhieu khung dung chung mot tep).

Nguon xep hang (hai lop, ghep lai):
  * `dbc_overflow.csv`  — chu den tu bang DBC. 9 widget o 8 khung gay ~10.000 gia tri tran; keo mot
                          widget o day sua hang nghin dong cung luc ⇒ xep truoc.
  * `overflow.csv`      — chu tinh trong layout / `StrDictionary`. Xep theo so widget tran cua khung.

Chay:
  python -X utf8 Tools/ui-fit/make_edit_targets.py --measure <thu muc do> --out <file .tsv> [--top 40]
"""
import argparse
import collections
import csv
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(REPO, "Tools", "game"))

INTERFACE_EX = os.path.join(REPO, "Assets", "CanonicalCY", "Data", "ConfigFolder", "InterfaceEx.txt")


def window_index():
    """ten tep layout (chu thuong, khong thu muc) -> ten window cua InterfaceEx.txt."""
    from dbc_inventory import Table
    table = Table(INTERFACE_EX)
    index = {}
    for row in table.rows:
        if len(row) < 3:
            continue
        name, layout = row[1], row[2]
        if not name or not layout:
            continue
        base = str(layout).replace("/", "\\").split("\\")[-1].lower()
        index.setdefault(base, str(name))
    return index, len(table.rows)


def read_csv(path):
    if not os.path.exists(path):
        return []
    with io.open(path, encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--measure", required=True, help="thu muc ket qua measure_ui_text.py")
    ap.add_argument("--out", required=True)
    ap.add_argument("--top", type=int, default=40, help="so khung lop layout lay them sau lop DBC")
    # CYS-UIEDIT 20/09 (ui-editor-2): lop GHIM. Hai nhom cho "chi keo o moi sua duoc" KHONG noi len
    # trong cach xep hang theo SO CHO TRAN — hang 17 the chi la mot o 35 px trong mat bo do, va bon o
    # cua `i18n-scope` chi con sai MAU chu khong con mat chu. Khong ghim thi moi lan sinh lai danh sach
    # deu lam mat chung, im lang. Cung lop mat du lieu da phai tra gia bang 242 dong DBC.
    ap.add_argument("--pin", default=os.path.join(REPO, "Tools", "reapply", "ui-editor", "data",
                                                  "ui_edit_targets_pinned.tsv"),
                    help="tep khung ghim, chen ngay sau lop DBC (de trong de bo qua)")
    args = ap.parse_args()

    index, rows_total = window_index()
    dbc = read_csv(os.path.join(args.measure, "dbc_overflow.csv"))
    lay = read_csv(os.path.join(args.measure, "overflow.csv"))

    out = []
    seen = set()
    unresolved = []

    def push(layout_rel, widget, note):
        base = layout_rel.replace("/", "\\").split("\\")[-1].lower()
        window = index.get(base)
        if not window:
            unresolved.append(layout_rel)
            return False
        key = (window, widget)
        if key in seen:
            return False
        seen.add(key)
        out.append((window, widget, note))
        return True

    # --- lop 1: chu tu bang DBC (mot widget = hang nghin gia tri)
    group = collections.defaultdict(lambda: {"n": 0, "max": 0.0, "box": 0.0, "tbl": ""})
    for r in dbc:
        try:
            over = float(r["over_px"])
        except (TypeError, ValueError):
            continue
        if over <= 0.5:
            continue
        g = group[(r["layout"], r["widget"])]
        g["n"] += 1
        g["max"] = max(g["max"], over)
        g["box"] = float(r["box_w"])
        g["tbl"] = "%s.%s" % (r["table"], r["col"])
    for (layout_rel, widget), g in sorted(group.items(), key=lambda t: -t[1]["n"]):
        push(layout_rel, widget, "DBC %s: %d gia tri tran, o rong %.1f px, tran toi da %+.0f px"
             % (g["tbl"], g["n"], g["box"], g["max"]))

    # --- lop GHIM: cot 1 da la TEN WINDOW san (khong phai ten tep layout) nen khong qua `push`,
    #     vi `push` tra ten window tu ten tep. Van dung chung `seen` de khong sinh dong trung.
    pinned = 0
    if args.pin and os.path.exists(args.pin):
        with io.open(args.pin, encoding="utf-8") as fh:
            for line in fh:
                line = line.rstrip("\n").rstrip("\r")
                if not line or line.startswith("#"):
                    continue
                parts = line.split("\t")
                if len(parts) < 2 or not parts[0] or not parts[1]:
                    continue
                key = (parts[0], parts[1])
                if key in seen:
                    continue
                seen.add(key)
                out.append((parts[0], parts[1], parts[2] if len(parts) > 2 else "ghim"))
                pinned += 1

    # --- lop 2: chu tinh trong layout / StrDictionary, xep theo so widget tran cua khung
    by_layout = collections.defaultdict(list)
    for r in lay:
        try:
            over = float(r["over_px"])
        except (TypeError, ValueError):
            continue
        if over <= 0.5:
            continue
        by_layout[r["layout"]].append(r)
    ranked = sorted(by_layout.items(), key=lambda t: -len({x["widget"] for x in t[1]}))
    for layout_rel, rows in ranked[:args.top]:
        worst = max(rows, key=lambda x: float(x["over_px"]))
        push(layout_rel, worst["widget"], "layout: %d widget tran, nang nhat %+.0f px (o %.1f px)"
             % (len({x["widget"] for x in rows}), float(worst["over_px"]), float(worst["box_w"])))

    with io.open(args.out, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# CYS-UIEDIT v1 - danh sach khung hong cho PgUp/PgDn cua bo sua bo cuc.\n")
        fh.write("# window\twidget\tghi chu\n")
        for window, widget, note in out:
            fh.write("%s\t%s\t%s\n" % (window, widget, note))

    print("InterfaceEx.txt   : %d dong" % rows_total)
    print("lop DBC           : %d widget" % len(group))
    print("lop GHIM          : %d dong tu %s" % (pinned, args.pin if args.pin else "(tat)"))
    print("lop layout (--top): %d khung" % min(args.top, len(ranked)))
    print("da ghi            : %d dong -> %s" % (len(out), args.out))
    if unresolved:
        uniq = sorted(set(unresolved))
        print("KHONG TRA DUOC ten window cho %d tep layout (bo qua): %s" % (len(uniq), ", ".join(uniq[:5])))


if __name__ == "__main__":
    main()
