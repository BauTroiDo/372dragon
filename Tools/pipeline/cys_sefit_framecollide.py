#!/usr/bin/env python3
# CYS-SEFIT: thu hep va cham nghia xuong muc CO HAI THAT SU.
#
# Mot nhom "va cham" toan cuc chua chac la loi: "Huy" dich tu 取消/放弃 la
# BINH THUONG vi hai chuoi do khong bao gio hien canh nhau.
#
# Loi THAT su la khi HAI khoa cua cung mot nhom va cham cung xuat hien trong
# CUNG MOT khung (cung file .layout.xml hoac cung file .lua cua khung do)
# => nguoi choi nhin thay hai nhan GIONG HET NHAU cho hai khai niem khac nhau
#    va khong co cach nao phan biet.
#
# Ket qua LUON ghi ra JSON (--out).

import argparse
import json
import os
import re
from collections import defaultdict

TOKEN_RE = re.compile(r"#\{([A-Za-z0-9_()\[\]\-\.]+)\}")


def index_frames(root):
    """frame_name -> set(token). Gom .layout.xml va .lua cung thu muc khung."""
    frames = defaultdict(set)
    where = defaultdict(lambda: defaultdict(set))  # token -> frame -> {files}
    for dirpath, _dirs, files in os.walk(root):
        for fn in files:
            low = fn.lower()
            if not (low.endswith(".layout.xml") or low.endswith(".lua")):
                continue
            path = os.path.join(dirpath, fn)
            # ten khung = thu muc chua file, tinh tu root
            rel = os.path.relpath(dirpath, root)
            frame = rel.split(os.sep)[0] if rel != "." else "_root"
            try:
                with open(path, "rb") as fh:
                    text = fh.read().decode("utf-8", errors="replace")
            except OSError:
                continue
            for tok in TOKEN_RE.findall(text):
                frames[frame].add(tok)
                where[tok][frame].add(os.path.relpath(path, root))
    return frames, where


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--collide-json", required=True, help="dau ra cua cys_sefit_dupscan.py")
    ap.add_argument("--interface-root", required=True, help="thu muc InterfaceFolder")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    data = json.load(open(args.collide_json, encoding="utf-8"))
    frames, where = index_frames(args.interface_root)

    # token -> frames chua no
    tok_frames = {t: set(fr.keys()) for t, fr in where.items()}

    harmful = []
    for grp in data["collisions"]:
        keys = [m["key"] for m in grp["members"]]
        cn_of = {m["key"]: m["cn"] for m in grp["members"]}
        # nhom cac khoa theo khung
        per_frame = defaultdict(list)
        for k in keys:
            for fr in tok_frames.get(k, ()):
                per_frame[fr].append(k)
        for fr, ks in per_frame.items():
            if len(ks) < 2:
                continue
            # chi tinh la co hai neu CHUOI GOC cua chung khac nhau
            if len({cn_of[k] for k in ks}) < 2:
                continue
            harmful.append(
                {
                    "frame": fr,
                    "vi": grp["vi"],
                    "keys": sorted(ks),
                    "cn": {k: cn_of[k] for k in sorted(ks)},
                    "files": sorted(
                        {f for k in ks for f in where[k].get(fr, ())}
                    ),
                }
            )

    harmful.sort(key=lambda d: (d["frame"], d["vi"]))
    out = {
        "collide_json": args.collide_json,
        "interface_root": args.interface_root,
        "frames_indexed": len(frames),
        "tokens_indexed": len(where),
        "collision_groups_global": data["collision_groups"],
        "harmful_same_frame_count": len(harmful),
        "harmful_frames": sorted({h["frame"] for h in harmful}),
        "harmful": harmful,
    }
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=2)
    print("da ghi JSON: %s" % args.out)
    print("khung da lap chi muc=%d  token=%d" % (len(frames), len(where)))
    print("va cham TOAN CUC=%d  ->  va cham CUNG MOT KHUNG=%d (tren %d khung)"
          % (data["collision_groups"], len(harmful), len(out["harmful_frames"])))


if __name__ == "__main__":
    main()
