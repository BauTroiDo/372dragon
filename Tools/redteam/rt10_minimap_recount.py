#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""red-team: dem lai doc lap so o ban do nho (minimap tiles).

KHAC phuong phap cua nhanh `minimap-holes`:
  - ho mo phong vong lap `createTiledBackground` tren chi muc tep cua HAI thu muc
    (SceneFolder, Scene2Folder).
  - toi quet TOAN BO cay du lieu ma resource provider co the cham toi
    (moi thu muc trong WXResources.cfg + Overlay + cac file .zip Bootstrap),
    roi suy hinh chu nhat tu TAP DAY DU chu khong tu vong lap tham do,
    va so hai ket qua.

DINH NGHIA DEM (in truoc moi con so, theo luat muc 15 cua dieu phoi):
  base            : chuoi khop regex ^jpg_(.+)_(\\d+)_(\\d+)\\.dds$ nhom 1
  probe_nx        : nx ma client suy ra = so n nho nhat sao cho (n,0) KHONG ton tai
  probe_ny        : tuong tu voi (0,n)
  full_max_x/y    : max toa do co that trong tap tep cua base do
  truncated       : full_max_x >= probe_nx  hoac  full_max_y >= probe_ny
                    => client ve THIEU mot phan ban do (o mo coi)
  hole            : toa do (i,j) voi i<probe_nx, j<probe_ny ma tep KHONG ton tai
Moc gio do: ghi trong ket qua.
"""
import json
import os
import re
import sys
import time
import zipfile

TILE_RE = re.compile(r"^jpg_(.+)_(\d+)_(\d+)\.dds$", re.IGNORECASE)


def collect(roots, zips):
    """tra ve {base: {(x,y): [duong dan...]}} va danh sach moi tep jpg_*.dds thay duoc"""
    tiles = {}
    allnames = {}
    for root in roots:
        if not os.path.isdir(root):
            continue
        for dirpath, _dirnames, filenames in os.walk(root):
            for fn in filenames:
                low = fn.lower()
                if not low.startswith("jpg_") or not low.endswith(".dds"):
                    continue
                allnames.setdefault(low, []).append(os.path.join(dirpath, fn))
                m = TILE_RE.match(fn)
                if not m:
                    continue
                base, sx, sy = m.group(1), int(m.group(2)), int(m.group(3))
                tiles.setdefault(base.lower(), {}).setdefault((sx, sy), []).append(
                    os.path.join(dirpath, fn))
    for zpath in zips:
        if not os.path.isfile(zpath):
            continue
        try:
            with zipfile.ZipFile(zpath) as z:
                for name in z.namelist():
                    fn = os.path.basename(name)
                    low = fn.lower()
                    if not low.startswith("jpg_") or not low.endswith(".dds"):
                        continue
                    allnames.setdefault(low, []).append(zpath + "!" + name)
                    m = TILE_RE.match(fn)
                    if not m:
                        continue
                    base, sx, sy = m.group(1), int(m.group(2)), int(m.group(3))
                    tiles.setdefault(base.lower(), {}).setdefault((sx, sy), []).append(
                        zpath + "!" + name)
        except Exception as exc:  # pragma: no cover
            print("ZIP LOI %s: %s" % (zpath, exc), file=sys.stderr)
    return tiles, allnames


def analyse(tiles):
    out = {}
    for base, coords in tiles.items():
        have = set(coords.keys())
        if (0, 0) not in have:
            out[base] = {"no_origin": True, "n_files": len(have)}
            continue
        nx = 1
        while nx < 64 and (nx, 0) in have:
            nx += 1
        ny = 1
        while ny < 64 and (0, ny) in have:
            ny += 1
        full_max_x = max(x for x, _ in have)
        full_max_y = max(y for _, y in have)
        holes = sorted([(i, j) for i in range(nx) for j in range(ny)
                        if (i, j) not in have])
        orphans = sorted([c for c in have if c[0] >= nx or c[1] >= ny])
        dup = {("%d_%d" % c): v for c, v in coords.items() if len(v) > 1}
        out[base] = {
            "no_origin": False,
            "probe_nx": nx,
            "probe_ny": ny,
            "full_max_x": full_max_x,
            "full_max_y": full_max_y,
            "truncated": bool(orphans),
            "n_expected": nx * ny,
            "n_files": len(have),
            "holes": ["%d_%d" % c for c in holes],
            "orphans": ["%d_%d" % c for c in orphans],
            "duplicate_coord_files": dup,
        }
    return out


def main():
    stage = sys.argv[1] if len(sys.argv) > 1 else \
        r"C:\TLBB\085\CY-Source\Build\world-gui\stage-play-2"
    data = os.path.join(stage, "Data")
    overlay = os.path.join(stage, "Overlay")
    patch = os.path.join(stage, "Patch")
    roots = [data, overlay, patch]
    zips = [os.path.join(data, "OgreCore.zip"),
            os.path.join(data, "MaterialTemplates.zip")]
    t0 = time.time()
    tiles, allnames = collect(roots, zips)
    res = analyse(tiles)
    n_bases = len(res)
    n_trunc = sum(1 for v in res.values() if v.get("truncated"))
    n_holes = sum(len(v.get("holes", [])) for v in res.values())
    n_noorig = sum(1 for v in res.values() if v.get("no_origin"))
    n_expected = sum(v.get("n_expected", 0) for v in res.values())
    n_dup = sum(1 for v in res.values() if v.get("duplicate_coord_files"))
    summary = {
        "dinh_nghia_dem": {
            "base": "regex ^jpg_(.+)_(\\d+)_(\\d+)\\.dds$ nhom 1, lower()",
            "probe_nx/ny": "mo phong dung hai vong while cua createTiledBackground",
            "truncated": "co it nhat mot toa do >= probe_nx hoac >= probe_ny",
            "hole": "toa do trong hinh chu nhat probe ma khong co tep",
            "nguon_quet": roots + zips,
        },
        "moc_gio_do": time.strftime("%Y-%m-%d %H:%M:%S"),
        "stage": stage,
        "giay_chay": round(time.time() - t0, 2),
        "so_tep_jpg_dds_thay_duoc": len(allnames),
        "so_base": n_bases,
        "so_base_khong_co_0_0": n_noorig,
        "so_base_BI_CAT_CUT": n_trunc,
        "so_LO_ben_trong": n_holes,
        "so_base_co_tep_TRUNG_TEN_o_nhieu_thu_muc": n_dup,
        "tong_o_mong_doi": n_expected,
    }
    outp = sys.argv[2] if len(sys.argv) > 2 else \
        r"C:\TLBB\085\CY-Source\Build\Logs\2026-09-19-red-team\rt10-minimap-recount.json"
    with open(outp, "w", encoding="utf-8") as fh:
        json.dump({"tom_tat": summary, "theo_base": res}, fh,
                  ensure_ascii=False, indent=1, sort_keys=True)
    print(json.dumps(summary, ensure_ascii=False, indent=1))
    bad = {k: v for k, v in res.items()
           if v.get("truncated") or v.get("holes") or v.get("no_origin")}
    if bad:
        print("\n== BASE CO VAN DE (%d) ==" % len(bad))
        for k in sorted(bad):
            print(" ", k, json.dumps(bad[k], ensure_ascii=False))
    dups = {k: v["duplicate_coord_files"] for k, v in res.items()
            if v.get("duplicate_coord_files")}
    if dups:
        print("\n== BASE CO O TRUNG TEN NHIEU THU MUC (%d) ==" % len(dups))
        for k in sorted(dups):
            print(" ", k, "->", sorted(dups[k].keys())[:6],
                  "…" if len(dups[k]) > 6 else "")
    print("\nJSON:", outp)


if __name__ == "__main__":
    main()
