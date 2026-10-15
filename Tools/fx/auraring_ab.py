#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CYS-AURARING: cham hai canh A/B cua VONG BAO TAM CHIEU theo NGUONG DA DANG KY TRUOC.

Hai canh chay tren CUNG MOT binary, khac dung MOT bien moi truong `CYS_AURARING`:
  canh 0 (doi chung am) = nguyen van duong ma cu (ten template tran "aura_rune_projector")
  canh 1 (ban va)       = ghep chi so nhu CY ("aura_rune_projector0")

NGUONG DA DANG KY (viet TRUOC khi chay; khong duoc noi ra sau):
  (1) canh 0: WXRender.log co `effect=aura_rune_projector` KHONG kem chu so
  (2) canh 0: WXRender.log co `can't find the required effect template 'aura_rune_projector`
  (3) canh 0: cum thay doi LON NHAT co hop bao < 200x140 (mat khong thay vong nao)
  (4) canh 1: WXRender.log co `effect=aura_rune_projector0`
  (5) canh 1: WXRender.log KHONG co dong "can't find ... aura_rune_projector"
  (6) canh 1: cum thay doi LON NHAT co hop bao >= 200x140 VA tam nam trong vung san choi
  (7) ca hai canh: probe di toi `ring_made=1` va `lenh=MCT_SKILL_AREA`
  (8) ca hai canh: 0 dong ERROR trong WXClient.log/WXRender.log (doc TRUOC moi minidump)

Bat ky o nao khong dat => BAO SAI. Khong dien giai lai nguong.

Phep do anh nam TRONG MOT LUOT: `auraring-before` (truoc khi bat vong) va `auraring-2`
(khi vong dang bat) chup cung camera, cung vi tri, cach nhau ~4,5 s. Khac dung mot thu:
vong bat hay chua. Do la doi chung am di qua DUNG duong ma, cung luot, khac mot bien.

    python auraring_ab.py --selftest
    python auraring_ab.py --edge0 <thu-muc> --edge1 <thu-muc> [--out <tep>]
"""
import argparse
import io
import os
import re
import sys

# CAI DAT NAY DA BI THAY - ghi ro thay vi im lang doi nguong.
# Nguong dang ky BAN DAU la TONG so diem anh doi (canh 0 <= 1500, canh 1 >= 5000). Lan chay
# that cho canh 0 = 6457 diem => TRUOT, nhung MAT nhin thi canh 0 KHONG CO VONG NAO. Truy ra:
# hai anh cach nhau ~4,5 s trong mot THE GIOI SONG, nen tong so diem anh doi dem ca NPC dang di
# (cum lon nhat cua canh 0 la 4498 px, hop bao 110x94, tam (854,446) - dung con cong Khong Tuoc),
# chu thich noi dau man hinh, va van ban treo. Dung y bay so 1 cua fx-cy-2: "tu dem diem anh tho
# tren khung co nhan vat" thi dang do NPC dung dua, khong phai hieu ung.
# => KHONG noi nguong; THAY dung cu. Dung cu moi do CUM LIEN THONG LON NHAT va HOP BAO cua no:
# vong 8 m o camera nay la mot cum duy nhat ~325x216 px, con NPC/chu la cac cum < 150 px.
# Hai so tach nhau theo HANG (dien tich hop bao 70.200 so 10.340). Dung cu nay duoc dinh nghia
# SAU khi da nhin so lieu, nen no co trong luong THAP HON sau o dua tren LOG (1,2,4,5,7,8) - cac
# o do da dang ky truoc va khong mo ho. Tong so diem anh van duoc IN RA, chi khong con lam cong.
MIN_RING_W = 200            # (6) be ngang hop bao cum lon nhat
MIN_RING_H = 140            # (6) chieu cao hop bao cum lon nhat
PLAY_AREA = (330, 60, 1180, 600)   # (6) vung san choi: ngoai HUD trai/phai, thanh tren va thanh duoi
DELTA = 24                  # nguong lech kenh mau de tinh la "diem anh doi"

RE_EFFECT = re.compile(r"CYS-FXCY2 auraring: type=(\d+) effect=(\S+)")
# BUG DA SUA: ban dau dung .search() nen no lay dong DAU TIEN, ma dong dau tien la
# `type=2 effect=reachable_projector` (vong chi dich cua con tro, mot nhanh KHAC cua cung switch).
# Phai loc dung dong AURA_RUNE (type >= 4). Ca hai luot that deu co ca hai dong, nen loi nay
# lam ca hai o 1 va 4 bao TRUOT oan tren mot ban va thuc su chay dung.
AURA_RUNE = 4
RE_MISSING = re.compile(r"can't find the required effect template 'aura_rune_projector")
RE_RESULT = re.compile(r"CYS-AURARING: KET QUA - chieu=(-?\d+) DamageRange=([\d.-]+) "
                       r"RingRange=([\d.-]+) lenh=(\S+) ring_made=(\d)")
RE_ERROR = re.compile(r"\bERROR\b")


def read_text(path):
    if not os.path.isfile(path):
        return None
    with io.open(path, "rb") as fh:
        return fh.read().decode("utf-8", "replace")


def shot(run_dir, tag):
    """Anh cua pha `tag` trong mot thu muc luot; ten that la cys-gl-<tick>-<tag>.png."""
    if not os.path.isdir(run_dir):
        return None
    hits = sorted(n for n in os.listdir(run_dir)
                  if n.lower().endswith(".png") and n.endswith("-%s.png" % tag))
    return os.path.join(run_dir, hits[-1]) if hits else None


def changed_pixels(before, during):
    """(tong diem doi, px cum lon nhat, rong hop bao cum, cao hop bao cum, tam x, tam y).

    Cum lien thong 4-huong, gan nhan bang union-find (khong can scipy)."""
    if not before or not during:
        return None
    from PIL import Image
    import numpy as np
    a = np.asarray(Image.open(before).convert("RGB"), dtype=np.int16)
    b = np.asarray(Image.open(during).convert("RGB"), dtype=np.int16)
    if a.shape != b.shape:
        return None
    mask = np.abs(b - a).max(axis=2) > DELTA
    total = int(mask.sum())
    if total == 0:
        return (0, 0, 0, 0, -1, -1)
    h, w = mask.shape
    idx = np.nonzero(mask.ravel())[0]
    alive = set(int(i) for i in idx)
    parent = {}

    def find(x):
        root = x
        while parent.get(root, root) != root:
            root = parent[root]
        while parent.get(x, x) != x:
            parent[x], x = root, parent[x]
        return root

    for i in idx:
        i = int(i)
        y, x = divmod(i, w)
        if x + 1 < w and i + 1 in alive:
            ra, rb = find(i), find(i + 1)
            if ra != rb:
                parent[ra] = rb
        if y + 1 < h and i + w in alive:
            ra, rb = find(i), find(i + w)
            if ra != rb:
                parent[ra] = rb
    groups = {}
    for i in idx:
        groups.setdefault(find(int(i)), []).append(int(i))
    big = max(groups.values(), key=len)
    import numpy as _np
    arr = _np.array(big)
    ys, xs = arr // w, arr % w
    return (total, len(big), int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1),
            int(round(xs.mean())), int(round(ys.mean())))


def read_edge(run_dir):
    e = {"dir": run_dir, "render": None, "client": None}
    render = read_text(os.path.join(run_dir, "WXRender.log"))
    client = read_text(os.path.join(run_dir, "WXClient.log"))
    e["render_found"] = render is not None
    e["client_found"] = client is not None
    render = render or ""
    client = client or ""
    hits = [(int(t), n) for t, n in RE_EFFECT.findall(render) if int(t) >= AURA_RUNE]
    e["effect"] = hits[-1][1] if hits else None
    e["type"] = hits[-1][0] if hits else None
    e["sibling_types"] = sorted(set(int(t) for t, _ in RE_EFFECT.findall(render) if int(t) < AURA_RUNE))
    e["missing_line"] = bool(RE_MISSING.search(render))
    m = RE_RESULT.search(client)
    e["ring_made"] = int(m.group(5)) if m else 0
    e["mct"] = m.group(4) if m else None
    e["skill"] = int(m.group(1)) if m else None
    e["damage_range"] = float(m.group(2)) if m else None
    e["ring_range"] = float(m.group(3)) if m else None
    e["errors"] = len(RE_ERROR.findall(client)) + len(RE_ERROR.findall(render))
    e["pixels"] = changed_pixels(shot(run_dir, "auraring-before"), shot(run_dir, "auraring-2"))
    return e


def judge(e0, e1):
    """Tra ve danh sach (ma o, mo ta, gia tri do duoc, dat?)."""
    px0 = e0["pixels"]
    px1 = e1["pixels"]
    rows = []
    rows.append(("1", "canh 0: effect=aura_rune_projector (KHONG chu so)",
                 str(e0["effect"]), e0["effect"] == "aura_rune_projector"))
    rows.append(("2", "canh 0: co dong \"can't find ... aura_rune_projector\"",
                 "co" if e0["missing_line"] else "khong", e0["missing_line"]))
    rows.append(("3", "canh 0: cum lon nhat co hop bao < %dx%d" % (MIN_RING_W, MIN_RING_H),
                 "thieu anh" if px0 is None else "%d px, hop bao %dx%d" % (px0[1], px0[2], px0[3]),
                 px0 is not None and not (px0[2] >= MIN_RING_W and px0[3] >= MIN_RING_H)))
    rows.append(("4", "canh 1: effect=aura_rune_projector0",
                 str(e1["effect"]), e1["effect"] == "aura_rune_projector0"))
    rows.append(("5", "canh 1: KHONG co dong \"can't find\"",
                 "co" if e1["missing_line"] else "khong", not e1["missing_line"]))
    x0, y0, x1, y1 = PLAY_AREA
    rows.append(("6", "canh 1: cum lon nhat hop bao >= %dx%d va tam trong vung san choi"
                 % (MIN_RING_W, MIN_RING_H),
                 "thieu anh" if px1 is None
                 else "%d px, hop bao %dx%d, tam (%d,%d)" % (px1[1], px1[2], px1[3], px1[4], px1[5]),
                 px1 is not None and px1[2] >= MIN_RING_W and px1[3] >= MIN_RING_H
                 and x0 <= px1[4] <= x1 and y0 <= px1[5] <= y1))
    rows.append(("7", "ca hai canh: ring_made=1 va lenh=MCT_SKILL_AREA",
                 "canh0 %s/%s, canh1 %s/%s" % (e0["ring_made"], e0["mct"], e1["ring_made"], e1["mct"]),
                 e0["ring_made"] == 1 and e1["ring_made"] == 1
                 and e0["mct"] == "MCT_SKILL_AREA" and e1["mct"] == "MCT_SKILL_AREA"))
    rows.append(("8", "ca hai canh: 0 dong ERROR trong log",
                 "canh0 %d, canh1 %d" % (e0["errors"], e1["errors"]),
                 e0["errors"] == 0 and e1["errors"] == 0))
    return rows


def render_report(e0, e1, rows):
    out = []
    out.append("CYS-AURARING - cham A/B vong bao tam chieu")
    out.append("  canh 0 (doi chung am): %s" % e0["dir"])
    out.append("  canh 1 (ban va)      : %s" % e1["dir"])
    out.append("")
    for tag, e in (("canh 0", e0), ("canh 1", e1)):
        px = e["pixels"]
        out.append("%s: effect=%s type=%s missing_line=%s chieu=%s DamageRange=%s RingRange=%s "
                   "lenh=%s ring_made=%s ERROR=%d"
                   % (tag, e["effect"], e["type"], e["missing_line"], e["skill"],
                      e["damage_range"], e["ring_range"], e["mct"], e["ring_made"], e["errors"]))
        out.append("        anh: %s" % ("THIEU" if px is None else
                   "tong %d diem doi; cum lon nhat %d px, hop bao %dx%d, tam (%d,%d)" % px))
    out.append("")
    out.append("%-4s %-62s %-28s %s" % ("o", "nguong da dang ky", "do duoc", "ket qua"))
    for tag, desc, got, ok in rows:
        out.append("%-4s %-62s %-28s %s" % (tag, desc, got, "DAT" if ok else "KHONG DAT"))
    bad = [r[0] for r in rows if not r[3]]
    out.append("")
    out.append("KET LUAN: %s" % ("XANH - ca %d o deu dat" % len(rows) if not bad
                                 else "BAO SAI - o khong dat: %s" % ", ".join(bad)))
    return "\n".join(out)


def _selftest():
    """Bo cham phai BIET TRUOT: moi ca am duoi day phai ra dung o hong cua no."""
    import shutil
    import tempfile
    from PIL import Image
    import numpy as np

    root = tempfile.mkdtemp(prefix="auraring-selftest-")
    fails = []

    def make(name, effect, missing, ring_px, ring_made=1, mct="MCT_SKILL_AREA", errors=0):
        d = os.path.join(root, name)
        os.makedirs(d, exist_ok=True)
        r = "CYS-FXCY2 auraring: type=4 effect=%s\n" % effect
        if missing:
            r += "OGRE EXCEPTION: can't find the required effect template 'aura_rune_projector\n"
        io.open(os.path.join(d, "WXRender.log"), "w", encoding="utf-8").write(r)
        c = ("CYS-AURARING: KET QUA - chieu=395 DamageRange=7.00 RingRange=700.0 lenh=%s ring_made=%d.\n"
             % (mct, ring_made))
        c += "ERROR something\n" * errors
        io.open(os.path.join(d, "WXClient.log"), "w", encoding="utf-8").write(c)
        base = np.zeros((720, 1280, 3), dtype=np.uint8)
        Image.fromarray(base).save(os.path.join(d, "cys-gl-1-auraring-before.png"))
        during = base.copy()
        # ring_px = be ngang cua cum duy nhat; luon ve mot hinh chu nhat 0,66 ti le nhu vong that,
        # tam o giua vung san choi. Them mot cum nhieu 110x94 GIONG CON CONG cua luot that de
        # cong phai phan biet duoc "vong" voi "NPC dang di".
        during[430:524, 800:910] = 200
        if ring_px:
            w_ = int(ring_px); h_ = int(round(ring_px * 0.66))
            during[397 - h_ // 2:397 + h_ - h_ // 2, 635 - w_ // 2:635 + w_ - w_ // 2] = 255
        Image.fromarray(during).save(os.path.join(d, "cys-gl-1-auraring-2.png"))
        return d

    def run(c, p):
        return judge(read_edge(c), read_edge(p))

    def bad(rows):
        return sorted(r[0] for r in rows if not r[3])

    try:
        # 1 - ca DUONG day du (canh 1 co vong 325 px ngang; ca hai canh deu co cum NPC 110x94)
        ok = run(make("c-ok", "aura_rune_projector", True, 0),
                 make("p-ok", "aura_rune_projector0", False, 325))
        if bad(ok):
            fails.append("ca duong phai xanh, lai hong o %s" % bad(ok))
        # 2 - canh va KHONG ve vong (dung ca ma fx-cy-2 so: log dung ma anh trong)
        r = run(make("c2", "aura_rune_projector", True, 0),
                make("p2", "aura_rune_projector0", False, 0))
        if bad(r) != ["6"]:
            fails.append("canh va khong ve vong phai hong DUNG o 6, ra %s" % bad(r))
        # 3 - canh doi chung LAI ve vong (cong khong biet truot thi se bo qua)
        r = run(make("c3", "aura_rune_projector", True, 325),
                make("p3", "aura_rune_projector0", False, 325))
        if bad(r) != ["3"]:
            fails.append("canh doi chung ve vong phai hong DUNG o 3, ra %s" % bad(r))
        # 4 - ban va khong vao duoc binary (van ten tran)
        r = run(make("c4", "aura_rune_projector", True, 0),
                make("p4", "aura_rune_projector", True, 0))
        if bad(r) != ["4", "5", "6"]:
            fails.append("ban va khong vao phai hong 4,5,6; ra %s" % bad(r))
        # 5 - doi chung KHONG co dong "can't find" => no khong di qua duong loi
        r = run(make("c5", "aura_rune_projector", False, 0),
                make("p5", "aura_rune_projector0", False, 325))
        if bad(r) != ["2"]:
            fails.append("doi chung thieu dong can't find phai hong DUNG o 2, ra %s" % bad(r))
        # 6 - probe khong toi duoc MCT_SKILL_AREA
        r = run(make("c6", "aura_rune_projector", True, 0, ring_made=0, mct="MCT_PLAYER_MOVETO"),
                make("p6", "aura_rune_projector0", False, 325))
        if bad(r) != ["7"]:
            fails.append("probe khong vao MCT_SKILL_AREA phai hong DUNG o 7, ra %s" % bad(r))
        # 7 - log co ERROR
        r = run(make("c7", "aura_rune_projector", True, 0),
                make("p7", "aura_rune_projector0", False, 325, errors=3))
        if bad(r) != ["8"]:
            fails.append("log co ERROR phai hong DUNG o 8, ra %s" % bad(r))
        # 8 - LUOT CHUA HE CHAY (thu muc rong) - bay lon nhat cua phien
        empty = os.path.join(root, "trong")
        os.makedirs(empty, exist_ok=True)
        r = run(empty, empty)
        if len(bad(r)) < 6:
            fails.append("luot chua he chay phai hong hau het o, ra %s" % bad(r))
        # 9 - vong qua NHO (chi bang cum NPC) => van phai truot o 6
        r = run(make("c9", "aura_rune_projector", True, 0),
                make("p9", "aura_rune_projector0", False, 120))
        if bad(r) != ["6"]:
            fails.append("vong qua nho phai hong DUNG o 6, ra %s" % bad(r))
        # 10 - DOI CHUNG CUA CHINH CONG: cum NPC 110x94 mot minh KHONG duoc tinh la vong
        px = read_edge(make("c10", "aura_rune_projector", True, 0))["pixels"]
        if px is None or px[2] >= MIN_RING_W or px[3] >= MIN_RING_H:
            fails.append("cum NPC gia phai nho hon nguong vong, do duoc %s" % (px,))
    finally:
        shutil.rmtree(root, ignore_errors=True)

    total = 10
    for line in fails:
        print("  HONG:", line)
    print("selftest: %d/%d PASS" % (total - len(fails), total))
    return 0 if not fails else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--edge0")
    ap.add_argument("--edge1")
    ap.add_argument("--out")
    a = ap.parse_args()
    if a.selftest:
        return _selftest()
    if not a.edge0 or not a.edge1:
        ap.error("can --edge0 va --edge1")
    e0, e1 = read_edge(a.edge0), read_edge(a.edge1)
    rows = judge(e0, e1)
    text = render_report(e0, e1, rows)
    print(text)
    if a.out:
        io.open(a.out, "w", encoding="utf-8").write(text + "\n")
    return 0 if all(r[3] for r in rows) else 1


if __name__ == "__main__":
    sys.exit(main())
