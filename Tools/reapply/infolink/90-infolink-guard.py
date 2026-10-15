# -*- coding: utf-8 -*-
"""90-infolink-guard - dem va CANH GIU cac the sieu lien ket toa do cua CY trong StrDictionary.txt.

VI SAO CAN:
    Cac the "#{_INFOAIM<x>,<y>,<scene>,<ten>}" va 11 ho anh em cua no la cho BAM DE TU TIM DUONG trong
    loi thoai / mo ta nhiem vu cua CY 3.71. Truoc 19/09/2026 client bo chung hoan toan (phat ra 0 ky tu:
    205 - 32 - 26 - 4 = 143, xem Timeline\\handoff\\qlog-crash.md), nen:
      * nguoi rut ngan chuoi cho vua khung KHONG THAY chung chiem cho,
      * cong cu do be rong cung khong tinh chung,
    => chung trong y het rac co the cat. Da xay ra that: `ui-fit-2` xoa mat `#{_INFOMAP242,269,0,景年}`
    khoi `ZHHD1_181128_292` (nhanh i18n-count do duoc 19/09). Mat im lang, khong ai thay.

    Tu 19/09 client da no cac the nay (Src\\Client\\CEGUISystem\\CysInfoLink.h) nen chung co chu hien ra,
    nhung phep kiem nay van can: no bien "mat im lang" thanh "do ngay".

CACH DUNG:
    python 90-infolink-guard.py count    <StrDictionary.txt>
    python 90-infolink-guard.py baseline <StrDictionary.txt> <baseline.json>
    python 90-infolink-guard.py check    <StrDictionary.txt> <baseline.json>      # rc=1 khi GIAM
    python 90-infolink-guard.py selftest <StrDictionary.txt> <baseline.json>      # phep kiem co biet truot khong

    `check` chi do khi so the cua MOT ho GIAM so voi baseline. Them the la binh thuong (nhap noi dung moi),
    no chi in ra de nguoi doc thay.

    Sau moi dot sua StrDictionary co chu dich, chay `check`. Neu do va viec giam la CO Y, chay lai `baseline`
    va ghi ly do vao commit.
"""
import io
import json
import os
import re
import sys

# 12 ho the toa do CY thuc su co trong du lieu / trong binary CY (khop bang trong CysInfoLink.h).
# Cac the "_INFO*" khac (_INFOMSG, _INFOID, _INFOUSR, _INFOACHV, _INFOPNE, _INFOXZ, _INFOSER, _INFOTZZ)
# KHONG phai lien ket toa do - co tinh khong dem o day.
FAMILIES = [
    "_INFOUSEITEM", "_INFO2WYXZ", "_INFO2CITY", "_INFO2HOME", "_INFO2LINE",
    "_INFOCITY", "_INFOHOME", "_INFOKILL", "_GETITEM", "_INFOAIM", "_INFOMAP", "_GETPET",
]
TAG_RE = re.compile(r"#\{(" + "|".join(FAMILIES) + r")([^{}]*)\}")

# Cac the "_INFO*" khong phai lien ket toa do - bo qua, khong canh bao.
NOT_LINKS = ("_INFOMSG", "_INFOID", "_INFOUSR", "_INFOACHV", "_INFOPNE", "_INFOXZ", "_INFOSER", "_INFOTZZ")
ANY_RE = re.compile(r"#\{(_(?:INFO|GET)[^{}]*)\}")


def read_text(path):
    with io.open(path, "r", encoding="utf-8", errors="replace") as handle:
        return handle.read()


def count(text):
    """-> (tong the theo ho, so DONG mang the, tong the)."""
    per_family = dict((name, 0) for name in FAMILIES)
    rows_with_tags = 0
    total = 0
    for line in text.splitlines():
        found = False
        for match in TAG_RE.finditer(line):
            per_family[match.group(1)] += 1
            total += 1
            found = True
        if found:
            rows_with_tags += 1
    return per_family, rows_with_tags, total


def suspects(text):
    """Cac khoa '_INFO*' / '_GET*' khong thuoc 12 ho VA khong thuoc nhom khong-phai-lien-ket.

    Do 19/09 tren StrDictionary hien tai: 5 truong hop, deu la LOI CHINH TA CO SAN CUA DU LIEU CY
    ('_INFOAI' thieu chu M x4, '_INFOMPA' dao chu x1). CY goc cung bo chung (no so substr(0,8)), nen
    day khong phai loi cua ban dich - nhung mot con so LON len o day nghia la ai do vua lam hong the.
    """
    found = {}
    for match in ANY_RE.finditer(text):
        key = match.group(1)
        if any(key.startswith(name) for name in FAMILIES):
            continue
        if any(key.startswith(name) for name in NOT_LINKS):
            continue
        found[key] = found.get(key, 0) + 1
    return found


def report(per_family, rows_with_tags, total, stream=sys.stdout):
    stream.write("the sieu lien ket toa do trong StrDictionary.txt\n")
    for name in sorted(FAMILIES, key=lambda n: (-per_family[n], n)):
        if per_family[name]:
            stream.write("  %-14s %6d\n" % (name, per_family[name]))
    for name in sorted(FAMILIES):
        if not per_family[name]:
            stream.write("  %-14s %6d\n" % (name, 0))
    stream.write("  %-14s %6d  (dong mang the: %d)\n" % ("TONG", total, rows_with_tags))


def report_suspects(text, stream=sys.stdout):
    found = suspects(text)
    total = sum(found.values())
    stream.write("  the _INFO*/_GET* KHONG thuoc 12 ho (nghi loi chinh ta): %d\n" % total)
    for key in sorted(found):
        stream.write("    %s  x%d\n" % (key, found[key]))
    return total


def do_baseline(dict_path, out_path):
    text = read_text(dict_path)
    per_family, rows, total = count(text)
    report(per_family, rows, total)
    bad = report_suspects(text)
    data = {
        "source": os.path.abspath(dict_path),
        "families": per_family,
        "rows_with_tags": rows,
        "total": total,
        "malformed": bad,
    }
    with io.open(out_path, "w", encoding="utf-8") as handle:
        handle.write(json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False))
        handle.write("\n")
    sys.stdout.write("da ghi baseline: %s\n" % out_path)
    return 0


def compare(per_family, rows, total, baseline, stream=sys.stdout):
    """-> so ho bi GIAM (0 = xanh)."""
    lost = 0
    for name in FAMILIES:
        was = int(baseline["families"].get(name, 0))
        now = per_family[name]
        if now < was:
            stream.write("  [HONG] %-14s %d -> %d  (mat %d the)\n" % (name, was, now, was - now))
            lost += 1
        elif now > was:
            stream.write("  [them] %-14s %d -> %d\n" % (name, was, now))
    if not lost:
        stream.write("  [OK]   khong ho nao bi giam (tong %d -> %d, dong %d -> %d)\n"
                     % (int(baseline["total"]), total, int(baseline["rows_with_tags"]), rows))
    return lost


def do_check(dict_path, baseline_path):
    with io.open(baseline_path, "r", encoding="utf-8") as handle:
        baseline = json.load(handle)
    text = read_text(dict_path)
    per_family, rows, total = count(text)
    report(per_family, rows, total)
    bad = report_suspects(text)
    was_bad = int(baseline.get("malformed", 0))
    if bad > was_bad:
        sys.stdout.write("  [HONG] the hong tang %d -> %d (co the ai do vua go sai ten the)\n" % (was_bad, bad))
    lost = compare(per_family, rows, total, baseline)
    if bad > was_bad:
        lost += 1
    if lost:
        sys.stdout.write("\nCo the bi XOA. Neu day la co y, chay lai `baseline` va ghi ly do vao commit.\n")
        return 1
    return 0


def do_selftest(dict_path, baseline_path):
    """Phep kiem phai BIET TRUOT: bo mot the trong ban sao trong bo nho -> phai do."""
    with io.open(baseline_path, "r", encoding="utf-8") as handle:
        baseline = json.load(handle)
    text = read_text(dict_path)
    per_family, rows, total = count(text)
    ok = compare(per_family, rows, total, baseline, stream=io.StringIO()) == 0
    sys.stdout.write("1. file that so voi baseline -> %s (ky vong: xanh)\n" % ("XANH" if ok else "DO"))

    match = TAG_RE.search(text)
    if not match:
        sys.stdout.write("2. khong tim thay the nao de thu -> KHONG THU DUOC\n")
        return 1
    damaged = text[:match.start()] + text[match.end():]
    d_family, d_rows, d_total = count(damaged)
    sink = io.StringIO()
    caught = compare(d_family, d_rows, d_total, baseline, stream=sink) > 0
    sys.stdout.write("2. ban sao bi xoa 1 the %s -> %s (ky vong: do)\n"
                     % (match.group(1), "DO" if caught else "XANH"))
    sys.stdout.write(sink.getvalue())
    if ok and caught:
        sys.stdout.write("SELFTEST OK - phep kiem biet truot.\n")
        return 0
    sys.stdout.write("SELFTEST HONG.\n")
    return 1


def main(argv):
    if len(argv) < 3:
        sys.stdout.write(__doc__)
        return 2
    mode, dict_path = argv[1], argv[2]
    if mode == "count":
        per_family, rows, total = count(read_text(dict_path))
        report(per_family, rows, total)
        return 0
    if len(argv) < 4:
        sys.stdout.write(__doc__)
        return 2
    if mode == "baseline":
        return do_baseline(dict_path, argv[3])
    if mode == "check":
        return do_check(dict_path, argv[3])
    if mode == "selftest":
        return do_selftest(dict_path, argv[3])
    sys.stdout.write(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
