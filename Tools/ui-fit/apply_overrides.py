# -*- coding: utf-8 -*-
"""ui-fit-2 (17/09/2026): gop ban rut ngan (override_rows.tsv cua shorten_plan.py) + sua dong NFD -> NFC vao
Registry/i18n/cy_vi_override.tsv (dinh dang '#KHOA<TAB>vi<TAB>note'; dong DAU TIEN cua mot khoa thang, xem
Tools/pipeline/cy_gui_dict.py load_tsv_dict -> setdefault). Vi vay khoa da co thi THAY tai cho, chua co thi noi them.

  python Tools/ui-fit/apply_overrides.py --rows <plan>/override_rows.tsv [--rows ...] [--nfd] [--dry]

--nfd: quet StrDictionary dang chay, moi dong co dau to hop (U+0300-U+036F) -> unicodedata NFC, roi ap them
       data/nfd_fix.tsv (khoa<TAB>cu<TAB>moi: thay chuoi con sau khi NFC, cho cac to hop NFC khong ghep duoc).
Sao luu: <file>.bak-ui-fit-2-<stamp> canh file (nhu i18n-cy da lam). Sau do chay:
  python -B Tools/pipeline/cy_i18n_apply.py apply
"""
import argparse
import csv
import datetime
import io
import os
import re
import shutil
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
OVERRIDE = os.path.join(REPO, "Registry", "i18n", "cy_vi_override.tsv")
DICT = os.path.join(REPO, "Assets", "CanonicalCY", "Data", "ConfigFolder", "StrDictionary.txt")
COMB = re.compile("[̀-ͯ]")


def load_dictionary(path):
    d = {}
    with io.open(path, "r", encoding="utf-8", errors="replace") as fh:
        for idx, line in enumerate(fh):
            if idx < 2:
                continue
            line = line.rstrip("\r\n")
            if "\t" not in line:
                continue
            k, v = line.split("\t", 1)
            d.setdefault(k, v)
    return d


def cy_source_text():
    """{khoa: chu Han goc} lay tu chinh CY 3.71 Config.axp - khong chep tay, khong doan."""
    sys.path.insert(0, os.path.join(REPO, "Tools", "pipeline"))
    sys.path.insert(0, os.path.join(REPO, "Docs", "evidence", "assetinv"))
    import cy_gui_dict as G
    import cys_i18nscope_leak as LEAK
    import axp_index as AX
    a = AX.Axp(LEAK.S4_STR)
    _n, raw = a.payload_full("StrDictionary.txt", 256 << 20)
    a.f.close()
    out = {}
    for kb, vb in G.parse_binary_dbc(raw):
        out.setdefault(kb.decode("gbk"), vb.decode("gbk", "replace"))
    return out


def validate_rows(rows):
    """-> [(khoa, loi, chu Han, ban rut ngan)] cho moi dong KHONG qua cy_translate.validate()."""
    sys.path.insert(0, os.path.join(REPO, "Tools", "pipeline"))
    import cy_translate as CT
    zh = cy_source_text()
    bad = []
    for k, v, _note in rows:
        z = zh.get(k)
        if z is None:
            continue          # khoa khong co trong CY 3.71: khong co nguon de doi chieu
        err = CT.validate(z, v)
        if err:
            bad.append((k, err, z, v))
    return bad


def nfd_rows(dictionary, fixes):
    out = []
    for k, v in dictionary.items():
        if not COMB.search(v):
            continue
        n = unicodedata.normalize("NFC", v)
        for old, new in fixes.get(k, []):
            n = n.replace(old, new)
        left = sorted(set("U+%04X" % ord(c) for c in n if COMB.match(c)))
        note = "ui-fit-2 17/09: dau tieng Viet dang NFD -> NFC (NotoSansSC khong co glyph U+0323/U+0303 roi)"
        if k in fixes:
            note += "; sua tay: " + "; ".join("%r->%r" % (o, nw) for o, nw in fixes[k])
        if left:
            note += "; CON DAU ROI " + ",".join(left)
        out.append((k, n, note))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rows", action="append", default=[])
    ap.add_argument("--nfd", action="store_true")
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--override", default=OVERRIDE)
    ap.add_argument("--allow-token-drift", action="store_true",
                    help="CHI dung khi lech tui token la CO Y va da ghi ly do vao cot note")
    args = ap.parse_args()

    new_rows = []  # (key, vi, note)
    for path in args.rows:
        with io.open(path, "r", encoding="utf-8") as fh:
            for r in csv.DictReader(fh, delimiter="\t"):
                ident = r["ident"]
                if not ident.startswith("#"):
                    raise SystemExit("dong khong phai #KHOA: %r" % ident)
                new_rows.append((ident[1:], r["vi"], r.get("note", "")))
    if args.nfd:
        fixes = {}
        fx = os.path.join(HERE, "data", "nfd_fix.tsv")
        if os.path.exists(fx):
            with io.open(fx, "r", encoding="utf-8") as fh:
                for i, line in enumerate(fh):
                    p = line.rstrip("\r\n").split("\t")
                    if i == 0 or len(p) < 3:
                        continue
                    fixes.setdefault(p[0], []).append((p[1], p[2]))
        shortened = {k for k, _, _ in new_rows}
        for k, n, note in nfd_rows(load_dictionary(DICT), fixes):
            if k in shortened:
                continue  # ban rut ngan da NFC san
            new_rows.append((k, n, note))

    for k, v, _ in new_rows:
        if "\t" in v or "\r" in v or "\n" in v:
            raise SystemExit("gia tri co TAB/xuong dong: %s" % k)
        if COMB.search(v):
            print("CANH BAO: van con dau roi trong %s" % k)

    # CYS-I18NSCOPE (i18n-scope 20/09/2026): CONG BAT BUOC. Duong ong rut ngan nay truoc day
    # KHONG chay `cy_translate.validate()`, va do duoc: 62/3.339 dong da vao Registry voi tui
    # token LECH so voi chu Han nguon - trong do 6 dong THEM ma dieu khien (engine NUOT chu:
    # "trang bi" viet tat thanh "#T.bi#" sinh ma #T va #C), 1 dong lech CHI SO tham so
    # (`%s0级` -> `%s c0`), 5 dong mat han mot `%sN`, 1 dong mat the `#{_INFOMAP...}` (mat cho
    # bam tu tim duong). Luat cua du an: MOI ban dich, ke ca dich tay va ke ca ban RUT NGAN
    # cua chinh may, deu phai qua `validate()`. Mot duong ong sinh du lieu ma khong co cong
    # kiem thi 62 dong hom nay se thanh 200 dong tuan sau.
    bad = [] if args.allow_token_drift else validate_rows(new_rows)
    if bad:
        print("TU CHOI %d dong khong qua validate() so voi chu Han nguon:" % len(bad))
        for k, err, zh, v in bad[:20]:
            print("    %-24s %-24s %r -> %r" % (k, err, zh[:28], v[:36]))
        raise SystemExit("sua ban rut ngan cho dung tui token roi chay lai "
                         "(hoac dat --allow-token-drift neu THAT SU co y, kem ly do trong note)")

    with io.open(args.override, "r", encoding="utf-8") as fh:
        lines = [l.rstrip("\r\n") for l in fh]
    header, body = lines[0], lines[1:]
    index = {}
    for i, line in enumerate(body):
        if line and line.startswith("#"):
            index.setdefault(line.split("\t", 1)[0][1:], i)
    replaced = added = same = 0
    for k, v, note in new_rows:
        row = "#%s\t%s\t%s" % (k, v, note)
        if k in index:
            old = body[index[k]]
            old_val = old.split("\t")[1] if "\t" in old else ""
            if old_val == v:
                same += 1
                continue
            body[index[k]] = row + " | thay dong cu: %r" % old_val[:60]
            replaced += 1
        else:
            index[k] = len(body)
            body.append(row)
            added += 1
    print("override rows: %d | them %d, thay %d, giu nguyen %d, tong dong %d" % (len(new_rows), added, replaced, same, len(body)))
    if args.dry:
        return
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    bak = args.override + ".bak-ui-fit-2-" + stamp
    shutil.copy2(args.override, bak)
    with io.open(args.override, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(header + "\n" + "\n".join(body) + "\n")
    print("da ghi %s (sao luu %s)" % (args.override, os.path.basename(bak)))


if __name__ == "__main__":
    main()
