#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""red-team: kiem khang dinh SUY LUAN cua `bullet-fx` (226075cf) bang MOT DUONG KHAC.

Ho DO: "dan duoc tao va ve" tren 8 ca duong do chinh ho chon (rig offline).
Ho SUY: "nguoi dung khong thay dan vi nhan vat ho khong co ky nang nao mang dan".

Toi kiem cau SUY do tu danh sach ky nang CO THAT trong log phien choi cua
nguoi dung, va doc bang DBC nhi phan bang bo doc rieng (Tools/redteam/rt_dbc.py).

DINH NGHIA DEM
  ky nang cua nguoi dung : ma `id` trong cap `id/level` cua dong
      "CYS skill: skills applied 9/9 menpai=9 [0/0,1/1,...]" trong WXClient.log
  cot 'ID dan'           : cot INT cua SkillTemplate_V1 co ty le gia tri >0
      nam trong tap ID cot 0 cua Bullet.txt cao nhat (tu suy, khong chep cua ho)
  "mang dan"             : dong ky nang do co gia tri >0 o cot ay
Moc gio do: in khi chay.
"""
import os
import re
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rt_dbc import Dbc, T_INT  # noqa: E402

CFG = r"C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ConfigFolder"
LOG2 = r"C:\TLBB\085\CY-Source\Build\Logs\2026-09-19-user-play-2\WXClient.log"
LOG1 = r"C:\TLBB\085\CY-Source\Build\Logs\2026-09-19-user-play-1\WXClient.log"
CTRL = (371, 381, 385, 391)   # bullet-fx khai: 4 chieu Vo Dang CO dan


def skills_from_log(path):
    """doc danh sach ky nang tu chinh log phien choi, khong go tay"""
    if not os.path.isfile(path):
        return None, None
    with open(path, "rb") as fh:
        raw = fh.read()
    txt = raw.decode("utf-8", errors="replace")
    best = None
    for m in re.finditer(r"skills applied (\d+)/(\d+) menpai=(-?\d+) \[([^\]]*)\]", txt):
        pairs = []
        for tok in m.group(4).split(","):
            tok = tok.strip()
            if "/" in tok:
                a, b = tok.split("/", 1)
                if a.strip().lstrip("-").isdigit():
                    pairs.append((int(a), b.strip()))
        if best is None or len(pairs) > len(best[1]):
            best = (m.group(0), pairs)
    if best is None:
        return None, None
    return best[0], [p[0] for p in best[1]]


def main():
    print("moc gio do:", time.strftime("%Y-%m-%d %H:%M:%S"))
    bl = Dbc(os.path.join(CFG, "Bullet.txt"))
    sk = Dbc(os.path.join(CFG, "SkillTemplate_V1.txt"))
    print("Bullet.txt          : %d cot x %d dong" % (bl.nF, bl.nR))
    print("SkillTemplate_V1.txt: %d cot x %d dong" % (sk.nF, sk.nR))

    bullet_ids = set(bl.col(0))
    print("ID dan phan biet     : %d (min %d, max %d)" %
          (len(bullet_ids), min(bullet_ids), max(bullet_ids)))

    cand = []
    for c in range(sk.nF):
        if sk.types[c] != T_INT:
            continue
        vals = [v for v in sk.col(c) if isinstance(v, int) and v > 0]
        if len(vals) < 20:
            continue
        hit = sum(1 for v in vals if v in bullet_ids)
        cand.append((hit / float(len(vals)), len(vals), hit, c))
    cand.sort(reverse=True)
    print("\n== 6 cot giong 'ID dan' nhat ==")
    for ratio, n, hit, c in cand[:6]:
        print("  cot %3d: ty le %.3f (%d/%d gia tri >0 la ID dan co that)" % (c, ratio, hit, n))

    # doi chung duong chon cot: cot dung PHAI lam 4 ky nang Vo Dang cua bullet-fx ra dan
    chosen = []
    for ratio, n, hit, c in cand:
        if ratio < 0.95:
            continue
        rows = [r for r in range(sk.nR) if sk.i(r, 0) in CTRL]
        if any(sk.i(r, c) > 0 for r in rows):
            chosen.append(c)
    print("\ncot duoc chon (ty le >=0.95 VA lam 371/381/385/391 ra dan):", chosen)
    if not chosen:
        print("KHONG chon duoc cot => phep do nay MU, khong ket luan gi.")
        return

    by_id = {}
    for r in range(sk.nR):
        by_id.setdefault(sk.i(r, 0), []).append(r)

    for label, logp in (("phien 2 (ban DA va)", LOG2), ("phien 1 (ban CHUA va)", LOG1)):
        line, ids = skills_from_log(logp)
        print("\n===== %s =====" % label)
        if not ids:
            print("  khong tim thay dong 'skills applied' trong log")
            continue
        print("  nguon:", line)
        any_bullet = False
        for sid in ids:
            rows = by_id.get(sid, [])
            if not rows:
                print("   ky nang %4d: KHONG CO dong trong SkillTemplate_V1" % sid)
                continue
            vals = sorted({sk.i(r, c) for r in rows for c in chosen if sk.i(r, c) > 0})
            name = sk.s(rows[0], 2).decode("utf-8", "replace")
            if vals:
                any_bullet = True
                print("   ky nang %4d (%s): CO DAN -> %s" % (sid, name, vals))
            else:
                print("   ky nang %4d (%s): khong dan" % (sid, name))
        print("  => %s" % ("CO ky nang mang dan: khang dinh cua bullet-fx BI BAC"
                           if any_bullet else
                           "0 ky nang mang dan: khang dinh cua bullet-fx DUNG"))

    print("\n== DOI CHUNG DUONG (bullet-fx noi 4 chieu nay CO dan) ==")
    for sid in CTRL:
        rows = by_id.get(sid, [])
        vals = sorted({sk.i(r, c) for r in rows for c in chosen if sk.i(r, c) > 0})
        name = sk.s(rows[0], 2).decode("utf-8", "replace") if rows else "?"
        print("   ky nang %4d (%s): %s" % (sid, name, vals if vals else "khong dan"))


if __name__ == "__main__":
    main()
