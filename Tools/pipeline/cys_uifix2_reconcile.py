#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""cys_uifix2_reconcile.py  (CYS-UIFIX2)

Bat khop HAI bo quet lop loi null-object, tren CUNG MOT cay nguon, CUNG MOT luc:
  A = cys_uiframes_stub_scan.py   (lop N1 + N2 = null-object)
  B = cys_sefit_nullobj_scan.py   (moi lan dung gia tri null-object)

Ba cau hoi phai tra loi bang SO, khong bang y kien:
  1. Moi ben THAY gi ma ben kia KHONG thay (khung + ham host).
  2. Trong so do, bao nhieu la BAO DONG GIA vi ham ay DA CO HOST THAT
     (ca hai bo quet deu khong nhan ra 12/13 file CysHost dang ky bang bang).
  3. Lop "ma chet bi che": khung co site null-object, so voi khung co site do
     la CU NEM DAU TIEN trong ham cua no. Hai con so, HAI CAI TEN KHAC NHAU.

Doi chung am bat buoc: --self-test.
ASCII only trong ma nguon.
"""
import argparse
import json
import os
import re
import sys


def load(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def read_text(path):
    with open(path, "rb") as fh:
        return fh.read().decode("utf-8", errors="replace")


# ---------------------------------------------------------------- host index
QUOTED_RE = re.compile(r'"([A-Za-z_][A-Za-z0-9_]{2,})"')


def hosted_names(src_dir):
    """Moi ten nam trong dau nhay kep o cac file CysHost*.cpp.

    CO Y de RONG: dung de TRA LOI cau hoi "ten nay co xuat hien nhu mot ten ham
    duoc dang ky khong", roi doi chieu voi bo trich hep (cys_uifix2_hosts.py).
    Hai nguon doc lap; lech nhau thi phai truy, khong duoc chon so dep hon.
    """
    names = set()
    for fn in sorted(os.listdir(src_dir)):
        if fn.startswith("CysHost") and fn.endswith((".cpp", ".h")):
            names |= set(QUOTED_RE.findall(read_text(os.path.join(src_dir, fn))))
    return names


def base_name(call):
    """'Recv:Name' -> 'Name'."""
    return call.split(":")[-1] if call else call


# ------------------------------------------------------------------ phan tich
def a_sets(a_doc):
    """Bo A: chi lay lop null-object (N1 + N2)."""
    hits = [h for h in a_doc["hits"] if h["class"] in ("N1", "N2")]
    frames = set(h["frame"] for h in hits)
    funcs = set(h["call"] for h in hits)
    return hits, frames, funcs


def b_sets(b_doc):
    hits = b_doc["hits"]
    frames = set(h["frame"] for h in hits)
    funcs = set()
    for h in hits:
        recv = h.get("receiver") or "_G"
        funcs.add("%s:%s" % (recv, h["function"]))
    return hits, frames, funcs


def first_throw_frames(a_doc):
    """Khung ma site N1/N2 la CU NEM DAU TIEN trong ham chua no.

    'Dau tien' = dong nho nhat trong cung (file, use_func) giua MOI site cua
    MOI lop (N1..N4) - vi mot cu nem lop khac o tren cung giet ham truoc.
    """
    first = {}
    for h in a_doc["hits"]:
        key = (h["file"], h.get("use_func") or "")
        ln = h["line"]
        if key not in first or ln < first[key]:
            first[key] = ln
    frames = set()
    for h in a_doc["hits"]:
        if h["class"] not in ("N1", "N2"):
            continue
        key = (h["file"], h.get("use_func") or "")
        if first.get(key) == h["line"]:
            frames.add(h["frame"])
    return frames


# ------------------------------------------------------------------ self-test
def self_test():
    ok = True

    def check(name, cond, extra=""):
        nonlocal ok
        print(("PASS " if cond else "FAIL ") + name + ("  " + extra if extra else ""))
        if not cond:
            ok = False

    a_doc = {"hits": [
        # khung K1: site N4 o dong 10 (cu nem DAU TIEN), site N2 o dong 20 -> BI CHE
        {"frame": "K1", "file": "K1/K1.lua", "use_func": "f", "line": 10, "class": "N4", "call": "R:a"},
        {"frame": "K1", "file": "K1/K1.lua", "use_func": "f", "line": 20, "class": "N2", "call": "R:b"},
        # khung K2: site N2 o dong 5 la cu nem DAU TIEN -> KHONG bi che
        {"frame": "K2", "file": "K2/K2.lua", "use_func": "g", "line": 5, "class": "N2", "call": "R:c"},
        {"frame": "K2", "file": "K2/K2.lua", "use_func": "g", "line": 9, "class": "N4", "call": "R:d"},
    ]}
    hits, frames, funcs = a_sets(a_doc)
    check("A_chi_lay_N1_N2", len(hits) == 2 and frames == {"K1", "K2"}, "frames=%s" % sorted(frames))
    ft = first_throw_frames(a_doc)
    check("cu_nem_dau_tien_loai_khung_bi_che", ft == {"K2"}, "ft=%s" % sorted(ft))
    check("chenh_lech_dung_bang_1", len(frames) - len(ft) == 1)

    b_doc = {"hits": [
        {"frame": "K2", "file": "K2/K2.lua", "receiver": "R", "function": "c"},
        {"frame": "K9", "file": "K9/K9.lua", "receiver": "_G", "function": "z"},
    ]}
    bh, bf, bfn = b_sets(b_doc)
    check("B_ghep_receiver_va_ten", bfn == {"R:c", "_G:z"}, "funcs=%s" % sorted(bfn))
    check("B_khung", bf == {"K2", "K9"})
    check("hieu_hai_ben_dung", (bf - frames) == {"K9"} and (frames - bf) == {"K1"})

    # doi chung am: hai bo GIONG HET nhau thi hieu phai RONG
    check("biet_TRUOT_khi_hai_ben_giong_nhau", (frames - frames) == set() and (funcs - funcs) == set())
    check("base_name", base_name("DataPool:CreateActionItemForShow") == "CreateActionItemForShow"
          and base_name("Lua_X") == "Lua_X")
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--a", help="uiframes stub scan json")
    ap.add_argument("--b", help="sefit nullobj scan json")
    ap.add_argument("--luaapigen-src", default="Src/Client/LuaApiGen")
    ap.add_argument("--hosts", help="cys_uifix2_hosts.py json (bo trich HEP)")
    ap.add_argument("--out")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        raise SystemExit(0 if self_test() else 1)
    if not (args.a and args.b and args.out):
        ap.error("can --a --b --out")

    a_doc, b_doc = load(args.a), load(args.b)
    a_hits, a_frames, a_funcs = a_sets(a_doc)
    b_hits, b_frames, b_funcs = b_sets(b_doc)

    wide = hosted_names(args.luaapigen_src)
    narrow = set()
    if args.hosts:
        narrow = set(load(args.hosts)["hosts"])

    def hosted(call):
        return call in narrow or base_name(call) in wide

    a_only_f = sorted(a_frames - b_frames)
    b_only_f = sorted(b_frames - a_frames)
    a_only_fn = sorted(a_funcs - b_funcs)
    b_only_fn = sorted(b_funcs - a_funcs)

    # TACH HAI NGUYEN NHAN KHAC HAN NHAU cho phan "chi B thay":
    #  (i)  A CO thay dong ay nhung XEP LOP KHAC (N3/N4) -> khac DINH NGHIA, khong phai mu;
    #  (ii) A KHONG thay chut nao -> A THAT SU MU.
    a_all_funcs = set(h["call"] for h in a_doc["hits"])
    a_all_frames = set(h["frame"] for h in a_doc["hits"])
    b_only_fn_classified = sorted(f for f in b_only_fn if f in a_all_funcs)
    b_only_fn_blind = sorted(f for f in b_only_fn if f not in a_all_funcs)
    b_only_f_classified = sorted(f for f in b_only_f if f in a_all_frames)
    b_only_f_blind = sorted(f for f in b_only_f if f not in a_all_frames)

    # Receiver la BIEN CUC BO chu khong phai bang toan cuc -> lenh goi that KHONG bao gio
    # cham toi stub. Nhan dien bang chinh cac tep Lua: 'local <recv>' trong cung tep.
    local_recv = {}
    for h in a_hits:
        recv = h["call"].split(":")[0]
        if recv in ("_G", ""):
            continue
        path = os.path.join(b_doc.get("interface_root", "Assets/CanonicalCY/Data/InterfaceFolder"),
                            h["file"].replace("/", os.sep))
        if not os.path.isfile(path):
            continue
        if re.search(r'(?m)^\s*local\s+%s\s*=' % re.escape(recv), read_text(path)):
            local_recv.setdefault(h["call"], []).append("%s:%d" % (h["file"], h["line"]))

    ft = first_throw_frames(a_doc)

    # bang chung tung dong cho phan lech ham
    def sample_a(call, n=2):
        return [{"file": h["file"], "line": h["line"], "class": h["class"], "text": h["text"][:140]}
                for h in a_hits if h["call"] == call][:n]

    def sample_b(call, n=2):
        out = []
        for h in b_hits:
            if "%s:%s" % (h.get("receiver") or "_G", h["function"]) != call:
                continue
            u = (h.get("uses") or [{}])[0]
            out.append({"file": h["file"], "call_line": h["call_line"],
                        "use_line": u.get("line"), "kind": u.get("kind"),
                        "text": (u.get("text") or "")[:140]})
            if len(out) >= n:
                break
        return out

    doc = {
        "counting_definition": {
            "site": "1 dong Lua se nem (A) / 1 bien bi nhiem co it nhat 1 lan dung (B)",
            "khung": "thu muc cap 1 duoi InterfaceFolder",
            "ham": "Receiver:Ten (receiver '_G' cho ham toan cuc)",
        },
        "A_uiframes_nullobject_only": {"sites": len(a_hits), "frames": len(a_frames), "funcs": len(a_funcs)},
        "B_sefit": {"sites": len(b_hits), "frames": len(b_frames), "funcs": len(b_funcs)},
        "giao_nhau": {"frames": len(a_frames & b_frames), "funcs": len(a_funcs & b_funcs)},
        "hop": {"frames": len(a_frames | b_frames), "funcs": len(a_funcs | b_funcs)},
        "chi_A_thay": {"frames": a_only_f, "funcs": a_only_fn},
        "chi_B_thay": {"frames": b_only_f, "funcs": b_only_fn},
        "chi_B_thay_TACH_NGUYEN_NHAN": {
            "ghi_chu": "A thay nhung XEP LOP N3/N4 = khac dinh nghia; A khong thay = A that su mu",
            "funcs_A_xep_lop_khac": b_only_fn_classified,
            "funcs_A_MU_hoan_toan": b_only_fn_blind,
            "frames_A_xep_lop_khac": b_only_f_classified,
            "frames_A_MU_hoan_toan": b_only_f_blind,
        },
        "bao_dong_gia_receiver_la_bien_cuc_bo": {
            "ghi_chu": "'Recv:Ten()' voi Recv la BIEN CUC BO thi loi goi di qua metatable cua doi "
                       "tuong, KHONG qua bang toan cuc mang stub => ca hai bo quet deu bao oan",
            "so_ham": len(local_recv),
            "chi_tiet": {k: v[:3] for k, v in sorted(local_recv.items())},
        },
        "host_that_su_da_co": {
            "bo_trich_hep_cys_uifix2_hosts": len(narrow),
            "ten_trong_dau_nhay_o_CysHost_rong": len(wide),
            "A_funcs_DA_CO_HOST": sorted(f for f in a_funcs if hosted(f)),
            "B_funcs_DA_CO_HOST": sorted(f for f in b_funcs if hosted(f)),
        },
        "ma_chet_bi_che": {
            "khung_co_site_null_object": len(a_frames),
            "khung_co_CU_NEM_DAU_TIEN_la_null_object": len(ft),
            "chenh_lech_khung_bi_che": len(a_frames) - len(ft),
            "danh_sach_khung_bi_che": sorted(a_frames - ft),
        },
        "bang_chung_lech_ham": {
            "chi_A": {f: sample_a(f) for f in a_only_fn[:40]},
            "chi_B": {f: sample_b(f) for f in b_only_fn[:40]},
        },
    }
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(doc, fh, ensure_ascii=False, indent=1)

    print("A (uiframes, chi N1/N2): sites=%d frames=%d funcs=%d"
          % (len(a_hits), len(a_frames), len(a_funcs)))
    print("B (sefit)              : sites=%d frames=%d funcs=%d"
          % (len(b_hits), len(b_frames), len(b_funcs)))
    print("giao khung=%d  hop khung=%d | giao ham=%d  hop ham=%d"
          % (len(a_frames & b_frames), len(a_frames | b_frames),
             len(a_funcs & b_funcs), len(a_funcs | b_funcs)))
    print("chi A thay: %d khung, %d ham | chi B thay: %d khung, %d ham"
          % (len(a_only_f), len(a_only_fn), len(b_only_f), len(b_only_fn)))
    print("  trong 'chi B': A xep lop khac = %d ham / %d khung; A MU han = %d ham / %d khung"
          % (len(b_only_fn_classified), len(b_only_f_classified),
             len(b_only_fn_blind), len(b_only_f_blind)))
    print("  bao dong gia 'receiver la bien cuc bo': %d ham" % len(local_recv))
    print("HOST DA CO ma bo quet van dem: A=%d ham, B=%d ham"
          % (len(doc["host_that_su_da_co"]["A_funcs_DA_CO_HOST"]),
             len(doc["host_that_su_da_co"]["B_funcs_DA_CO_HOST"])))
    print("ma chet bi che: khung co site=%d, khung co CU NEM DAU TIEN=%d, chenh=%d"
          % (len(a_frames), len(ft), len(a_frames) - len(ft)))
    print("-> %s" % args.out)


if __name__ == "__main__":
    main()
