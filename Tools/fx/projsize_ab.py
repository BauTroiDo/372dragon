#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CYS-PROJSIZE: cham A/B cua "co vong bao tam chieu phai THEO tam chieu".

Hai canh chay tren CUNG MOT binary, khac dung MOT bien moi truong `CYS_RINGSIZE`:
  canh 0 (doi chung) = nguyen van duong ma 0.85 (ap setProjectionSize len `CRFObj_Dummy::m_pEffect`,
                       mot con tro LUON NULL tren duong nay => khong bao gio co tac dung)
  canh 1 (ban va)    = ap len effect CUA CHINH `CWXObj_ProjTex` nhu CY 3.71 va client_GL

MOI CANH la MOT luot, trong luot do bo do quet BA ban kinh tren CUNG MOT camera:
  CYS_AURARING_SWEEP=300,1000,800  =>  anh projsize-0 (3 m), projsize-1 (10 m), projsize-2 (8 m)
800 nam o cuoi lam MOC DOI CHIEU CHEO: 800 la dung gia tri trong du lieu (`ProjectionSize 800` cua
`aura_rune_projector*`), nen o canh va no PHAI ra cung co voi canh doi chung.

================== NGUONG DA DANG KY TRUOC KHI CHAY - KHONG DUOC NOI RA SAU ==================
 (1) canh 0: WXRender.log co >=1 dong `CYS-RINGSIZE: dummy ... type=4 ... fix=0`
             VA co DUNG 0 dong `CYS-RINGSIZE: projtex`   (duong cu khong he goi setProjectionSize)
 (2) canh 1: co `CYS-RINGSIZE: projtex type=4 size=<S> elements=N (N>=1)` cho CA BA S = 300/1000/800
 (3) canh 1: co `CYS-RINGSIZE: projtex type=2 ... size=100` - decal chi dich cua CON TRO giu dung
             gia tri cua du lieu (`reachable_projector` co ProjectionSize 100) => khong hoi quy
 (4) ca hai canh: bo do di het - `sweep=3`, `ring_made=1`, `lenh=MCT_SKILL_AREA`
 (5) ca hai canh: 0 dong ERROR trong WXClient.log va WXRender.log (doc TRUOC moi minidump)
 (6) ca SAU anh: cum vong >= 800 px va tam nam trong vung san choi
 (7) canh 0: max(W)/min(W) <= 1.15  - ba vong CUNG MOT CO (day la LOI hien tai, phai tai hien duoc)
 (8) canh 1: W(1000)/W(300) trong [2.80, 3.90]   (ly tuong 1000/300 = 3.33)
 (9) canh 1: W(800)/W(300)  trong [2.25, 3.10]   (ly tuong  800/300 = 2.67)
(10) canh 1: W(800) lech <= 15 % so voi trung binh W cua canh 0 (hai ben cung la 800 don vi)
(11) canh 1: W(300) < W(800) < W(1000), moi khoang cach >= 20 px
Bat ky o nao khong dat => BAO SAI. Khong dien giai lai nguong, khong noi nguong.
===============================================================================================

CHON CUM NAO LA "VONG" - luat dat TRUOC khi nhin so lieu:
  Neo = tam cum LON NHAT cua anh `projsize-1` (ban kinh 10 m - vat lon nhat khung hinh) CUA CHINH
  luot do. Voi moi anh, chon cum co tam GAN NEO NHAT trong so cac cum >= 400 px.
  Ly do co luat nay: `auraring` suyt bao oan mot ban va dung vi cum "lon nhat" la con cong Khong Tuoc
  (110x94 px) trong mot the gioi SONG. Vong 3 m o camera nay chi ~122 px be ngang, tuc CUNG CO voi
  con cong => "lon nhat" khong con phan biet duoc, phai dung VI TRI.

    python projsize_ab.py --selftest
    python projsize_ab.py --edge0 <thu-muc> --edge1 <thu-muc> [--out <tep>]
"""
import argparse
import io
import os
import re
import sys

RANGES = (300.0, 1000.0, 800.0)          # thu tu dung bang thu tu anh projsize-0/-1/-2
TAGS = ("projsize-0", "projsize-1", "projsize-2")
DELTA = 24                                # nguong lech kenh mau de tinh la "diem anh doi"
MIN_CLUSTER_PX = 400                      # cum nho hon thi khong xet lam vong
MIN_RING_PX = 800                         # (6) cum vong phai it nhat bang nay
PLAY_AREA = (330, 60, 1180, 600)          # (6) vung san choi 1280x720, ngoai HUD

EQ_MAX_RATIO = 1.15                       # (7)
R_1000_300 = (2.80, 3.90)                 # (8)
R_800_300 = (2.25, 3.10)                  # (9)
ANCHOR_TOL = 0.15                         # (10)
MIN_GAP_PX = 20                           # (11)
NEO_R = 60                                # ban kinh quanh NEO de tim vong (px)
MAX_ASYM = 0.25                           # (6) do lech trai/phai quanh tam; lon hon = cum bi gop

RE_DUMMY = re.compile(r"CYS-RINGSIZE: dummy type=(\d+) fix=(\d+) show=(\d+) "
                      r"range_in=([-\d.eE+]+) range_used=([-\d.eE+]+) m_pEffect=(\d+)")
RE_PROJTEX = re.compile(r"CYS-RINGSIZE: projtex type=(\d+) size=([-\d.eE+]+) elements=(\d+)")
RE_SWEEP = re.compile(r"CYS-AURARING: sweep=(\d+) gia tri")
RE_RESULT = re.compile(r"CYS-AURARING: KET QUA - chieu=(-?\d+) DamageRange=([\d.-]+) "
                       r"RingRange=([\d.-]+) lenh=(\S+) ring_made=(\d)")
RE_ERROR = re.compile(r"\bERROR\b")
AURA_RUNE = 4
REACHABLE = 2


def read_text(path):
    if not os.path.isfile(path):
        return None
    with io.open(path, "rb") as fh:
        return fh.read().decode("utf-8", "replace")


def shot(run_dir, tag):
    """Anh cua pha `tag`; ten that la cys-gl-<tick>-<tag>.png hoac cys-live-<tick>-<tag>.png."""
    if not os.path.isdir(run_dir):
        return None
    hits = sorted(n for n in os.listdir(run_dir)
                  if n.lower().endswith(".png") and n.endswith("-%s.png" % tag))
    return os.path.join(run_dir, hits[-1]) if hits else None


def clusters(before, during):
    """Danh sach cum lien thong 4-huong cua cac diem anh DOI: (npx, w, h, cx, cy). None neu thieu anh."""
    if not before or not during or not os.path.isfile(before) or not os.path.isfile(during):
        return None
    from PIL import Image
    import numpy as np
    a = np.asarray(Image.open(before).convert("RGB"), dtype=np.int16)
    b = np.asarray(Image.open(during).convert("RGB"), dtype=np.int16)
    if a.shape != b.shape:
        return None
    mask = np.abs(b - a).max(axis=2) > DELTA
    h, w = mask.shape
    idx = np.nonzero(mask.ravel())[0]
    if idx.size == 0:
        return []
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
    out = []
    for members in groups.values():
        ys = sorted(m // w for m in members)
        xs = sorted(m % w for m in members)
        n = len(members)
        lo = xs[int(0.05 * (n - 1))]
        hi = xs[int(0.95 * (n - 1))]
        cx = int(round(sum(xs) / float(n)))
        # BAT MERGE: vong la vat DOI XUNG quanh tam. Neu mot NPC di ngang dinh vao vong thi cum
        # lien thong gop lam mot va mot ben dai han han ben kia. Khi do phep do KHONG DUNG DUOC -
        # va phai bao to chu khong duoc am tham tra ra mot con so sai.
        left, right = cx - lo, hi - cx
        asym = abs(left - right) / float(max(1, hi - lo + 1))
        out.append((n, max(xs) - min(xs) + 1, max(ys) - min(ys) + 1,
                    cx, int(round(sum(ys) / float(n))),
                    hi - lo + 1, round(asym, 3)))
    out.sort(key=lambda c: -c[0])
    return out


def pick_ring(cs, anchor):
    """Cum LON NHAT trong ban kinh NEO_R quanh NEO (chi xet cum >= MIN_CLUSTER_PX).

    DOI LUAT SAU KHI THAY SO LIEU CANH 0 - ghi ro, khong giau (Build/Logs/2026-09-20-projsize/
    nguong-dang-ky-truoc.txt, phu luc 2):
    Luat cu la "cum co tam GAN NEO NHAT". No hong ngay o anh dau tien cua canh doi chung:
    tai anh projsize-0 co HAI cum cung nam duoi chan nhan vat - vong that 21.906 px tam (637,402)
    va mot manh vun 891 px tam (642,384). Neo la (640,393), nen khoang cach la 9,5 so 9,2 -
    luat "gan nhat" chon MANH VUN. Khi hai vat cung o duoi chan nhan vat thi "gan nhat" la mot
    phep tung dong xu, khong phai mot phep chon.
    Luat moi: trong ban kinh NEO_R = 60 px quanh neo (ba tam vong cua canh 0 nam trong pham vi
    10 px cua nhau, con con cong Khong Tuoc cach 214 px), lay cum LON NHAT.
    Phep doi nay chi doi VAT NAO duoc goi la "vong"; no KHONG dong vao mot nguong nao. Va vi no
    duoc dinh nghia SAU khi nhin so lieu, no yeu hon cac o dua tren LOG (1,2,3,4,5) - cac o do
    dang ky truoc, nhi phan, khong mo ho."""
    if not cs:
        return None
    big = [c for c in cs if c[0] >= MIN_CLUSTER_PX]
    if not big:
        return None
    if anchor is None:
        return big[0]
    ax, ay = anchor
    near = [c for c in big if (c[3] - ax) ** 2 + (c[4] - ay) ** 2 <= NEO_R * NEO_R]
    if not near:
        return None
    return max(near, key=lambda c: c[0])


def read_edge(run_dir):
    e = {"dir": run_dir}
    render = read_text(os.path.join(run_dir, "WXRender.log"))
    client = read_text(os.path.join(run_dir, "WXClient.log"))
    e["render_found"] = render is not None
    e["client_found"] = client is not None
    render = render or ""
    client = client or ""
    e["dummy"] = [(int(t), int(f), int(sh), float(ri), float(ru), int(pe))
                  for t, f, sh, ri, ru, pe in RE_DUMMY.findall(render)]
    e["projtex"] = [(int(t), float(s), int(n)) for t, s, n in RE_PROJTEX.findall(render)]
    m = RE_SWEEP.search(client)
    e["sweep"] = int(m.group(1)) if m else 0
    # Bay so 2 cua `auraring`: mot dau xuat hien NHIEU LAN thi `.search()` lay dong DAU TIEN.
    # O day probe in "KET QUA" MOT LAN MOI BUOC QUET (ba lan). Ba dong mang cung `ring_made` va
    # cung `lenh`, nen lay dong nao cung ra so do - nhung lay dong CUOI thi dung y nghia hon
    # (sau khi da quet xong) va khong phu thuoc vao su trung hop do.
    hits = RE_RESULT.findall(client)
    e["result_lines"] = len(hits)
    r = hits[-1] if hits else None
    e["ring_made"] = int(r[4]) if r else 0
    e["mct"] = r[3] if r else None
    e["errors"] = len(RE_ERROR.findall(client)) + len(RE_ERROR.findall(render))

    before = shot(run_dir, "auraring-before")
    e["shots"] = {}
    e["clusters"] = {}
    for tag in TAGS:
        p = shot(run_dir, tag)
        e["shots"][tag] = p
        e["clusters"][tag] = clusters(before, p)
    anchor = None
    cs1 = e["clusters"].get("projsize-1")
    if cs1:
        big = [c for c in cs1 if c[0] >= MIN_CLUSTER_PX]
        if big:
            anchor = (big[0][3], big[0][4])
    e["anchor"] = anchor
    e["ring"] = {tag: pick_ring(e["clusters"].get(tag), anchor) for tag in TAGS}
    return e


def _w(e, tag):
    """BE NGANG dung de cham = khoang phan vi 5-95 % cua cac diem anh trong cum, KHONG phai hop bao.

    VI SAO DOI (doi TRUOC khi chay luot dau tien, chua nhin mot so lieu that nao):
    `auraring` do vong 800 ra hop bao 325x216 tam (636,398), va con cong Khong Tuoc o (854,446)
    rong 110 px, tuc trai ra toi ~799. Vong 10 m se rong ~406 px, phu toi ~839 => hai vat CHAM NHAU
    va cum lien thong 4-huong se GOP LAM MOT. Luc do hop bao phong len vi mot con NPC di ngang, va
    o (8) se truot vi mot ly do khong lien quan gi den ban va.
    Phan vi 5-95 % bo duoc mot "cau noi" mong ma van do dung vat chinh. Voi mot hinh tron dac,
    khoang 5-95 % la MOT TI LE CO DINH cua be ngang that (cung mot hinh dang, chi khac ti le),
    nen no TRIET TIEU trong moi ti so - tuc o (8)(9)(10)(11) khong bi lech vi phep doi nay.
    Hop bao VAN DUOC IN RA nguyen ven de nguoi sau kiem lai.
    """
    r = e["ring"].get(tag)
    return r[5] if r else None


def judge(e0, e1):
    rows = []

    def row(code, what, got, ok):
        rows.append((code, what, got, bool(ok)))

    # --- (1) canh 0: duong cu chay, va KHONG goi setProjectionSize lan nao
    d0 = [d for d in e0["dummy"] if d[0] == AURA_RUNE]
    row("1", "canh 0: co dong dummy type=4 fix=0 VA 0 dong projtex",
        "dummy(type=4,fix=0)=%d, projtex=%d" % (len([d for d in d0 if d[1] == 0]), len(e0["projtex"])),
        len([d for d in d0 if d[1] == 0]) >= 1 and len(e0["projtex"]) == 0)

    # --- (2) canh 1: ba co da duoc ap len effect cua ProjTex
    sizes = sorted(set(round(s, 1) for t, s, n in e1["projtex"] if t == AURA_RUNE and n >= 1))
    want = sorted(round(v, 1) for v in RANGES)
    row("2", "canh 1: projtex type=4 co du ba co %s, elements>=1" % (want,),
        str(sizes), all(v in sizes for v in want))

    # --- (3) canh 1: decal con tro giu dung 100 cua du lieu
    reach = [s for t, s, n in e1["projtex"] if t == REACHABLE]
    row("3", "canh 1: projtex type=2 (con tro) size=100 - khong hoi quy",
        str(sorted(set(round(s, 1) for s in reach))) if reach else "khong co dong nao",
        bool(reach) and all(abs(s - 100.0) < 0.01 for s in reach))

    # --- (4) bo do di het ca hai canh
    ok4 = all(e["sweep"] == 3 and e["ring_made"] == 1 and e["mct"] == "MCT_SKILL_AREA"
              for e in (e0, e1))
    row("4", "ca hai canh: sweep=3, ring_made=1, lenh=MCT_SKILL_AREA",
        "e0(sweep=%d,ring=%d,%s) e1(sweep=%d,ring=%d,%s)"
        % (e0["sweep"], e0["ring_made"], e0["mct"], e1["sweep"], e1["ring_made"], e1["mct"]), ok4)

    # --- (5) khong co ERROR
    row("5", "ca hai canh: 0 dong ERROR", "e0=%d e1=%d" % (e0["errors"], e1["errors"]),
        e0["errors"] == 0 and e1["errors"] == 0)

    # --- (6) sau anh deu co vong that
    x0, y0, x1, y1 = PLAY_AREA
    detail = []
    ok6 = True
    for name, e in (("e0", e0), ("e1", e1)):
        for tag in TAGS:
            r = e["ring"].get(tag)
            if not r:
                detail.append("%s/%s: khong co cum" % (name, tag))
                ok6 = False
                continue
            inside = x0 <= r[3] <= x1 and y0 <= r[4] <= y1
            sym = r[6] <= MAX_ASYM
            detail.append("%s/%s: %dpx %dx%d W=%d tam(%d,%d) lech=%.2f%s%s"
                          % (name, tag, r[0], r[1], r[2], r[5], r[3], r[4], r[6],
                             "" if inside else " NGOAI", "" if sym else " CUM-BI-GOP"))
            if r[0] < MIN_RING_PX or not inside or not sym:
                ok6 = False
    row("6", "ca sau anh: cum vong >= %d px, tam trong vung san choi, lech <= %.2f"
        % (MIN_RING_PX, MAX_ASYM),
        " | ".join(detail), ok6)

    w0 = [_w(e0, t) for t in TAGS]
    w1 = [_w(e1, t) for t in TAGS]

    # --- (7) canh 0: ba vong CUNG mot co (loi hien tai)
    if all(v for v in w0):
        ratio0 = max(w0) / float(min(w0))
        row("7", "canh 0: max(W)/min(W) <= %.2f (ba vong cung co)" % EQ_MAX_RATIO,
            "W=%s => %.3f" % (w0, ratio0), ratio0 <= EQ_MAX_RATIO)
    else:
        row("7", "canh 0: max(W)/min(W) <= %.2f" % EQ_MAX_RATIO, "thieu so do %s" % (w0,), False)

    # --- (8)(9)(11) canh 1: co PHAI theo ban kinh
    if all(v for v in w1):
        r83 = w1[1] / float(w1[0])
        r23 = w1[2] / float(w1[0])
        row("8", "canh 1: W(1000)/W(300) trong [%.2f, %.2f]" % R_1000_300,
            "%d/%d = %.3f" % (w1[1], w1[0], r83), R_1000_300[0] <= r83 <= R_1000_300[1])
        row("9", "canh 1: W(800)/W(300) trong [%.2f, %.2f]" % R_800_300,
            "%d/%d = %.3f" % (w1[2], w1[0], r23), R_800_300[0] <= r23 <= R_800_300[1])
        row("11", "canh 1: W(300) < W(800) < W(1000), moi khoang >= %d px" % MIN_GAP_PX,
            "W=%s" % (w1,),
            w1[2] - w1[0] >= MIN_GAP_PX and w1[1] - w1[2] >= MIN_GAP_PX)
    else:
        row("8", "canh 1: W(1000)/W(300)", "thieu so do %s" % (w1,), False)
        row("9", "canh 1: W(800)/W(300)", "thieu so do %s" % (w1,), False)
        row("11", "canh 1: thu tu ba co", "thieu so do %s" % (w1,), False)

    # --- (10) moc doi chieu cheo: 800 hai ben phai bang nhau
    if all(v for v in w0) and w1[2]:
        mean0 = sum(w0) / float(len(w0))
        dev = abs(w1[2] - mean0) / mean0
        row("10", "canh 1 W(800) lech <= %d%% so voi trung binh W canh 0" % int(ANCHOR_TOL * 100),
            "%d so %.1f => %.1f%%" % (w1[2], mean0, dev * 100.0), dev <= ANCHOR_TOL)
    else:
        row("10", "moc doi chieu cheo 800", "thieu so do", False)

    return rows


def report(e0, e1, rows, out=None):
    lines = []
    lines.append("CYS-PROJSIZE A/B - co vong bao tam chieu phai THEO tam chieu")
    lines.append("canh 0 (CYS_RINGSIZE=0, duong ma 0.85): %s" % e0["dir"])
    lines.append("canh 1 (CYS_RINGSIZE=1, nhu CY/GL):     %s" % e1["dir"])
    lines.append("quet ban kinh: %s -> anh %s" % (list(RANGES), list(TAGS)))
    lines.append("")
    for name, e in (("canh 0", e0), ("canh 1", e1)):
        lines.append("%s: dummy=%d projtex=%d sweep=%d ring_made=%d mct=%s errors=%d neo=%s"
                     % (name, len(e["dummy"]), len(e["projtex"]), e["sweep"], e["ring_made"],
                        e["mct"], e["errors"], e["anchor"]))
        for tag in TAGS:
            r = e["ring"].get(tag)
            cs = e["clusters"].get(tag)
            top = (cs[:3] if cs else [])
            lines.append("    %-11s vong(px,hopbao_w,hopbao_h,cx,cy,W_p5_95)=%s | ba cum lon nhat=%s"
                         % (tag, r, top))
        for t, s, n in e["projtex"]:
            lines.append("    projtex type=%d size=%.1f elements=%d" % (t, s, n))
        for d in e["dummy"]:
            lines.append("    dummy type=%d fix=%d show=%d range_in=%.1f range_used=%.1f m_pEffect=%d" % d)
    lines.append("")
    ok = True
    for code, what, got, good in rows:
        ok = ok and good
        lines.append("(%-2s) %-70s | %-46s | %s" % (code, what, got, "DAT" if good else "KHONG DAT"))
    lines.append("")
    lines.append("KET LUAN: %s" % ("DAT TAT CA - duoc phep commit"
                                   if ok else "BAO SAI - KHONG commit"))
    text = "\n".join(lines)
    if out:
        with io.open(out, "w", encoding="utf-8") as fh:
            fh.write(text + "\n")
    return ok, text


# --------------------------------------------------------------------------- selftest
def _mk(dirpath, tag, rings, size=(1280, 720), decoy=None):
    """Ve mot anh: `rings` = danh sach (cx, cy, ban kinh px) ve thanh dia dac."""
    from PIL import Image, ImageDraw
    os.makedirs(dirpath, exist_ok=True)
    im = Image.new("RGB", size, (20, 30, 40))
    d = ImageDraw.Draw(im)
    for cx, cy, r in rings:
        d.ellipse([cx - r, cy - int(r * 0.66), cx + r, cy + int(r * 0.66)], fill=(240, 200, 60))
    if decoy:
        dx, dy, dr = decoy
        d.ellipse([dx - dr, dy - dr, dx + dr, dy + dr], fill=(250, 40, 40))
    im.save(os.path.join(dirpath, "cys-gl-1-%s.png" % tag))


def _logs(dirpath, fix, sizes, sweep=3, ring=1, mct="MCT_SKILL_AREA", errors=0, reach=100.0,
          projtex_on_edge0=False):
    os.makedirs(dirpath, exist_ok=True)
    render = []
    for s in sizes:
        render.append("CYS-RINGSIZE: dummy type=4 fix=%d show=1 range_in=%.1f range_used=%.1f m_pEffect=0"
                      % (fix, s, s))
        if fix or projtex_on_edge0:
            render.append("CYS-RINGSIZE: projtex type=4 size=%.1f elements=1" % s)
    if fix:
        render.append("CYS-RINGSIZE: dummy type=2 fix=1 show=1 range_in=100.0 range_used=100.0 m_pEffect=0")
        render.append("CYS-RINGSIZE: projtex type=2 size=%.1f elements=1" % reach)
    for _ in range(errors):
        render.append("14:00:00: ERROR something blew up")
    with io.open(os.path.join(dirpath, "WXRender.log"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(render) + "\n")
    client = ["CYS-AURARING: sweep=%d gia tri [300.0 1000.0 800.0 0.0]" % sweep,
              "CYS-AURARING: KET QUA - chieu=34 DamageRange=0.00 RingRange=0.0 lenh=%s ring_made=%d "
              "sweep_at=2 sweep_value=800.0 doc_lai=800.0" % (mct, ring)]
    with io.open(os.path.join(dirpath, "WXClient.log"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(client) + "\n")


def _run(base, name, fix, widths, **kw):
    """widths = ba ban kinh px cua ba anh; canh doi chung thi ba so bang nhau."""
    d = os.path.join(base, name)
    os.makedirs(d, exist_ok=True)
    decoy = kw.pop("decoy", None)
    decoy_all = kw.pop("decoy_all", None)
    _mk(d, "auraring-before", [])
    for tag, r in zip(TAGS, widths):
        dd = decoy_all if decoy_all else (decoy if tag == TAGS[0] else None)
        _mk(d, tag, [(640, 400, r)] if r else [], decoy=dd)
    _logs(d, fix, kw.pop("sizes", RANGES), **kw)
    return d


def selftest():
    import shutil
    import tempfile
    base = tempfile.mkdtemp(prefix="projsize-selftest-")
    cases = []
    try:
        # 1. ca DUONG: canh 0 ba vong bang nhau (160 px ban kinh = 321 px be ngang),
        #    canh 1 ti le 300:1000:800 quanh cung moc 800.
        e0 = _run(base, "ok-e0", 0, (160, 160, 160))
        e1 = _run(base, "ok-e1", 1, (60, 200, 160))
        cases.append(("ca duong: ti le dung", judge(read_edge(e0), read_edge(e1)), True))

        # 2. ca AM: canh 1 KHONG doi co (ban va khong co tac dung) => phai KHONG DAT
        e1b = _run(base, "flat-e1", 1, (160, 160, 160))
        cases.append(("ca am: canh 1 ba vong bang nhau", judge(read_edge(e0), read_edge(e1b)), False))

        # 3. ca AM: canh 0 DA doi co san (doi chung khong con la doi chung)
        e0b = _run(base, "moved-e0", 0, (60, 200, 160), projtex_on_edge0=True)
        cases.append(("ca am: canh 0 cung doi co", judge(read_edge(e0b), read_edge(e1)), False))

        # 4. ca AM: luot CHUA HE CHAY (thu muc rong)
        empty = os.path.join(base, "empty")
        os.makedirs(empty, exist_ok=True)
        cases.append(("ca am: luot chua he chay", judge(read_edge(empty), read_edge(empty)), False))

        # 5. ca AM: co ERROR trong log
        e1c = _run(base, "err-e1", 1, (60, 200, 160), errors=3)
        cases.append(("ca am: co dong ERROR", judge(read_edge(e0), read_edge(e1c)), False))

        # 6. ca AM: decal con tro bi keo theo (type=2 khong con 100)
        e1d = _run(base, "reach-e1", 1, (60, 200, 160), reach=300.0)
        cases.append(("ca am: decal con tro bi doi co", judge(read_edge(e0), read_edge(e1d)), False))

        # 7. ca AM cho CHINH DUNG CU: mot "con cong" 130x130 px o xa neo, to hon vong 3 m.
        #    Luat "gan neo nhat" phai van chon dung vong, nen ket qua van DAT.
        e1e = _run(base, "decoy-e1", 1, (60, 200, 160), decoy=(1000, 250, 65))
        cases.append(("ca am dung cu: co cum gia to hon vong 3 m", judge(read_edge(e0), read_edge(e1e)), True))

        # 7b. ca AM nang hon: con cong CHAM vao vong 10 m => cum lien thong GOP LAM MOT.
        #     Hop bao se phong len; phan vi 5-95 % phai van cho ti so dung => van DAT.
        e1h = _run(base, "touch-e1", 1, (60, 200, 160), decoy_all=(870, 400, 60))
        # Mong doi la KHONG DAT, va phai truot o o (6) "cum bi gop" - tuc bo do BAO TO chu khong
        # am tham tra ra mot ti so sai. Day la ca "phep do co THAT SU chay khong" cua chinh dung cu.
        rows7b = judge(read_edge(e0), read_edge(e1h))
        cases.append(("ca am dung cu: NPC cham vong 10 m => phai bao CUM BI GOP",
                      rows7b, False))
        # GHI RO GIOI HAN CUA DUNG CU (do duoc khi viet ca nay, khong phai suy doan): voi mot NPC
        # DAY DAN dinh vao vong, do lech trai/phai chi len 0,078 - DUOI nguong 0,25 - nen o (6)
        # KHONG bat duoc. Thu bat duoc la o (8): be ngang phong tu ~325 len 398 => ti so 4,02,
        # ra ngoai [2,80; 3,90]. Tuc merge van lam phep do BAO TO, nhung qua o ti so chu khong qua
        # o hinh dang. RUI RO CON LAI, noi thang: mot merge vua du de ti so roi DUNG VAO khoang
        # cho phep thi khong o nao bat duoc. Vi vay khi cham that toi VAN in do lech va VAN nhin anh.
        assert not all(r[3] for r in rows7b), "merge phai lam ket luan chuyen sang BAO SAI"

        # 8. ca AM: bo do khong di het (mct sai)
        e1f = _run(base, "mct-e1", 1, (60, 200, 160), mct="MCT_PLAYER_MOVETO")
        cases.append(("ca am: lenh chuot khong phai MCT_SKILL_AREA",
                      judge(read_edge(e0), read_edge(e1f)), False))

        # 9. ca AM: thieu mot anh
        e1g = _run(base, "miss-e1", 1, (60, 200, 160))
        os.remove(shot(e1g, "projsize-2"))
        cases.append(("ca am: thieu mot anh", judge(read_edge(e0), read_edge(e1g)), False))

        # 10. ca AM: moc cheo lech (canh 1 dung ti le nhung to gap doi canh 0)
        e0c = _run(base, "small-e0", 0, (80, 80, 80))
        cases.append(("ca am: moc 800 hai ben khac nhau", judge(read_edge(e0c), read_edge(e1)), False))

        good = 0
        for name, rows, want in cases:
            got = all(r[3] for r in rows)
            ok = (got == want)
            good += 1 if ok else 0
            bad = [r[0] for r in rows if not r[3]]
            print("%-52s mong=%-5s duoc=%-5s %s   o truot: %s"
                  % (name, want, got, "PASS" if ok else "FAIL", bad))
        print("selftest %d/%d" % (good, len(cases)))
        return 0 if good == len(cases) else 1
    finally:
        shutil.rmtree(base, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--edge0")
    ap.add_argument("--edge1")
    ap.add_argument("--out")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if not (a.edge0 and a.edge1):
        ap.error("can --edge0 va --edge1 (hoac --selftest)")
    e0 = read_edge(a.edge0)
    e1 = read_edge(a.edge1)
    ok, text = report(e0, e1, judge(e0, e1), a.out)
    sys.stdout.write(text + "\n")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
