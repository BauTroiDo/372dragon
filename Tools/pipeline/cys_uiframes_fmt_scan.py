#!/usr/bin/env python3
# CYS-UIFRAMES: do lop loi (c) "chuoi dinh dang hong".
#
# StrDictionary.txt co dang `key<TAB>value`. Ban Viet duoc sinh ra tu ban chu Han.
# Neu so o dinh dang (%s %d %u ...) LECH giua hai ban thi `ScriptGlobal_Format`
# nhan sai so tham so => hoac in ra rac, hoac NEM.
# Cung dem ca the cua rieng du an: `#{...}` va `#R #W #Y` (mau).
#
# Ket qua LUON ghi ra JSON (--out). Co --self-test (doi chung am bat buoc).

import argparse
import json
import re
import sys

# %s %d %u %x %02d %-5s %.2f ... ; bo qua "%%"
# CO Y SIET: KHONG cho co dau cach sau `%`. Ban dau co `[-+ #0]*` (co dau cach)
# thi van Viet "giam 50% gia" bi doc thanh mot o dinh dang "% g" => 158 khoa lech,
# trong do nhieu khoa la DUONG TINH GIA. Lua `string.format` khong dung co dau cach.
FMT_RE = re.compile(r"%(?!%)[-+0]*[0-9]*(?:\.[0-9]+)?[diouxXeEfgGcs]")
TAG_RE = re.compile(r"#\{[^}]*\}")


def load(path, encodings=("utf-8", "gbk", "gb18030")):
    with open(path, "rb") as fh:
        raw = fh.read()
    for enc in encodings:
        try:
            text = raw.decode(enc)
            break
        except UnicodeDecodeError:
            continue
    else:
        text = raw.decode("utf-8", errors="replace")
    out = {}
    for line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if not line or "\t" not in line:
            continue
        k, _, v = line.partition("\t")
        k = k.strip()
        if k and k not in out:
            out[k] = v
    return out


def sig(value):
    """Chu ky dinh dang cua mot chuoi: danh sach cac o %, va so the #{}.

    Phai bo cap `%%` TRUOC khi do, neu khong `%% h...` se bi doc thanh mot o
    (`% h` + `o`) — chinh self-test da bat duoc loi nay trong ban dau.
    """
    value = value.replace("%%", "\x00")
    return ([m.group(0) for m in FMT_RE.finditer(value)], len(TAG_RE.findall(value)))


def compare(vi, zh):
    rows = []
    for k, v in vi.items():
        if k not in zh:
            continue
        fv, tv = sig(v)
        fz, tz = sig(zh[k])
        if fv == fz and tv == tz:
            continue
        rows.append({
            "key": k,
            "vi_fmt": fv, "zh_fmt": fz,
            "vi_tags": tv, "zh_tags": tz,
            "kind": ("fmt-count" if len(fv) != len(fz)
                     else "fmt-type" if fv != fz else "tag-count"),
            "vi": v[:180], "zh": zh[k][:180],
        })
    return rows


SELF_VI = {
    "A": "Ban nhan %d vang",          # khop
    "B": "Ban nhan vang",             # MAT mot o  -> fmt-count
    "C": "Ban nhan %s vang",          # DOI kieu   -> fmt-type
    "D": "Xin chao #{_INFOUSR%s}",    # khop ca the
    "E": "Xin chao %s #{T1}",         # MAT mot the, o % giu nguyen -> tag-count
    "F": "100%% hoan thanh",          # %% khong tinh la o
}
SELF_ZH = {
    "A": "获得 %d 金",
    "B": "获得 %d 金",
    "C": "获得 %d 金",
    "D": "你好 #{_INFOUSR%s}",
    "E": "你好 %s #{T1}#{T2}",
    "F": "100%% 完成",
}


def self_test():
    ok = True

    def check(label, cond, detail=""):
        nonlocal ok
        print(("PASS " if cond else "FAIL ") + label + ("  " + detail if detail else ""))
        if not cond:
            ok = False

    rows = {r["key"]: r for r in compare(SELF_VI, SELF_ZH)}
    check("detects_missing_format_slot", rows.get("B", {}).get("kind") == "fmt-count")
    check("detects_changed_format_type", rows.get("C", {}).get("kind") == "fmt-type")
    check("detects_missing_tag", rows.get("E", {}).get("kind") == "tag-count")
    check("no_false_positive_on_identical", "A" not in rows and "D" not in rows)
    check("percent_percent_is_not_a_slot", "F" not in rows)
    # bo quet phai BIET TRUOT
    saved = FMT_RE.pattern
    import re as _re
    globals()["FMT_RE"] = _re.compile(r"(?!x)x")
    blind = {r["key"] for r in compare(SELF_VI, SELF_ZH)}
    globals()["FMT_RE"] = _re.compile(saved)
    check("scan_can_fail_when_pattern_broken", "B" not in blind and "C" not in blind)
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--vi")
    ap.add_argument("--zh")
    ap.add_argument("--out")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        print("DINH NGHIA DEM: 1 'khoa lech' = 1 khoa co mat o CA HAI ban ma chu ky dinh dang khac nhau.")
        sys.exit(0 if self_test() else 1)
    if not (a.vi and a.zh and a.out):
        ap.error("can --vi --zh --out")
    vi, zh = load(a.vi), load(a.zh)
    rows = compare(vi, zh)
    kinds = {}
    for r in rows:
        kinds[r["kind"]] = kinds.get(r["kind"], 0) + 1
    out = {
        "counting_definition": "1 khoa lech = 1 khoa co mat o CA HAI ban ma chu ky dinh dang khac nhau",
        "vi_file": a.vi, "zh_file": a.zh,
        "vi_keys": len(vi), "zh_keys": len(zh),
        "keys_in_both": sum(1 for k in vi if k in zh),
        "mismatched_keys": len(rows), "by_kind": kinds,
        "rows": rows,
    }
    json.dump(out, open(a.out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("chung khoa=%d lech=%d %s -> %s"
          % (out["keys_in_both"], len(rows), kinds, a.out))


if __name__ == "__main__":
    main()
