#!/usr/bin/env python3
# CYS-SEFIT: kiem ke MOI duong chet tiem tang trong MOT file Lua giao dien.
#
# Vi sao can rieng cong cu nay: va tung cho mot la sai chien luoc. Hai lan lien tiep
# cu nem chi DOI XUONG dong duoi (1465 -> 1480 -> 1723), trieu chung tren man hinh
# gan nhu y het, nen nguoi dung lai bao "van loi". Phai liet ke HET roi va mot luot.
#
# Bo quet doi chieu MOI loi goi ham host trong file voi dac ta `rets` cua stub sinh
# tu dong, roi phan loai theo BA hinh dang sai da gap that:
#   A. NULL-OBJECT  : rets "o" -> tra mot bang ma moi truong la HAM
#                     => `x ~= nil` lot, `x.f >= 1` nem, `x <= 129` nem
#   B. THIEU SO LUONG: Lua bind N gia tri, stub tra M < N  => cac bien thua = nil
#   C. AN TOAN      : so luong khop va kieu dung
#
# QUAN TRONG - CO PHAN TICH KHA DUNG (reachability):
# mot diem "dinh" chua chac NEM. Neu ngay dong sau co canh `if <bien> ~= nil then`
# va bien do dang la nil (vi stub tra it gia tri hon) thi CA KHOI bi bo qua, nen
# moi dong ben trong khoi deu KHONG chay. Bo quet danh dau cac diem nhu vay la
# "bi-canh-chan" thay vi bao dong. Day la khac biet giua mot danh sach tinh va mot
# danh sach dung duoc.
#
# Ket qua LUON ghi ra JSON (--out).

import argparse
import json
import os
import re

STUB_RE = re.compile(
    r'Stub\s*\(\s*\w+\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]*)"\s*\)'
)
KNOWN = set("nsbzt1N")


def load_stubs(src_dir):
    out = {}
    for fn in sorted(os.listdir(src_dir)):
        if not fn.endswith(".cpp"):
            continue
        with open(os.path.join(src_dir, fn), "rb") as fh:
            text = fh.read().decode("utf-8", errors="replace")
        for recv, name, rets in STUB_RE.findall(text):
            out[(recv, name)] = rets
    return out


def rets_count(spec):
    return len(spec)


def is_nullobj(spec):
    return bool(spec) and any(c not in KNOWN for c in spec)


CALL_RE = re.compile(
    r"^(?P<indent>\s*)(?P<local>local\s+)?(?P<vars>[A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*=\s*"
    r"(?:(?P<recv>[A-Za-z_]\w*)\s*:\s*)?(?P<fn>[A-Za-z_]\w*)\s*\("
)
# MOI bien duoc kiem nil trong mot dong, khong chi bien dau tien.
# (Ban dau regex nay chi lay cai dau tien roi `break`, nen dong 1301
#  `if nOpenDate ~= nil and nDayCount ~= nil then` bi doc thanh "chi canh nOpenDate"
#  va dong 1300 bi xep nham thanh SE NEM. Do la bao dong gia - cung mot toi voi bo sot,
#  chi nguoc chieu.)
GUARD_VAR_RE = re.compile(r"\b([A-Za-z_]\w*)\s*(?:~=|==)\s*nil")


def audit(lua_path, stubs, hosted):
    with open(lua_path, "rb") as fh:
        lines = fh.read().decode("utf-8", errors="replace").splitlines()
    rows = []
    for i, raw in enumerate(lines):
        line = raw.split("--")[0]
        m = CALL_RE.match(line)
        if not m:
            continue
        fn = m.group("fn")
        recv = m.group("recv") or "_G"
        spec = stubs.get((recv, fn))
        if spec is None:
            continue
        variables = [v.strip() for v in m.group("vars").split(",") if v.strip()]
        binds = len(variables)
        ret_n = rets_count(spec)
        nullobj = is_nullobj(spec)

        # canh ngay sau: `if <bien cuoi> ~= nil` hoac `if <bien> == nil then break/return`
        guarded_by = None
        for j in range(i + 1, min(i + 4, len(lines))):
            text_j = lines[j].split("--")[0]
            if "if" not in text_j:
                continue
            for name in GUARD_VAR_RE.findall(text_j):
                if name not in variables:
                    continue
                # bien nay co dang la nil khong? (stub tra it gia tri hon so bien bind)
                if variables.index(name) >= ret_n:
                    guarded_by = {"line": j + 1, "var": name,
                                  "text": lines[j].strip()[:120]}
                    break
            if guarded_by:
                break

        if (recv, fn) in hosted:
            kind, note = "DA-VA", "nhanh nay da cai ham that"
        elif guarded_by and binds > ret_n:
            kind, note = "BI-CANH-CHAN", ("khoi bi bo qua vi `%s` la nil (stub tra %d gia tri, script bind %d)"
                                          % (guarded_by["var"], ret_n, binds))
        elif binds > ret_n:
            kind, note = "B-THIEU-SO-LUONG", ("script bind %d, stub tra %d => %d bien thua = nil"
                                              % (binds, ret_n, binds - ret_n))
        elif nullobj:
            kind, note = "A-NULL-OBJECT", "rets \"%s\" => bang ma moi truong la HAM" % spec
        else:
            kind, note = "C-AN-TOAN", "so luong khop, kieu thuong"
        rows.append({
            "line": i + 1, "receiver": recv, "function": fn, "rets_spec": spec,
            "rets_count": ret_n, "lua_binds": binds, "vars": variables,
            "kind": kind, "note": note, "guard": guarded_by,
            "text": line.strip()[:150],
        })
    return rows, len(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luaapigen-src", required=True)
    ap.add_argument("--lua", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--hosted", default="",
                    help="danh sach 'Recv:Name' da duoc cai that, cach nhau bang dau phay")
    args = ap.parse_args()

    hosted = set()
    for item in args.hosted.split(","):
        item = item.strip()
        if ":" in item:
            r, n = item.rsplit(":", 1)
            hosted.add((r, n))

    stubs = load_stubs(args.luaapigen_src)
    rows, nlines = audit(args.lua, stubs, hosted)

    order = ["A-NULL-OBJECT", "B-THIEU-SO-LUONG", "BI-CANH-CHAN", "DA-VA", "C-AN-TOAN"]
    counts = {k: sum(1 for r in rows if r["kind"] == k) for k in order}
    out = {"lua": args.lua, "lua_lines": nlines, "stub_calls_found": len(rows),
           "counts": counts, "rows": sorted(rows, key=lambda r: r["line"])}
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=2)
    print("da ghi JSON: %s" % args.out)
    print("%s: %d dong, %d loi goi ham host co stub" % (os.path.basename(args.lua), nlines, len(rows)))
    for k in order:
        print("  %-18s %d" % (k, counts[k]))
    for r in rows:
        if r["kind"] in ("A-NULL-OBJECT", "B-THIEU-SO-LUONG"):
            print("  >> dong %-5d %s:%s  %s" % (r["line"], r["receiver"], r["function"], r["note"]))


if __name__ == "__main__":
    main()
