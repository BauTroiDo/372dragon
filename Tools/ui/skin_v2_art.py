"""skin_v2_art.py - GL-style v2 UI pieces for TLBB CEGUI (deterministic; sources are only read).

Art: TLGL (Thien Long Quy Lai) ui_png textures.  Rules:
* 1-px padding (a duplicated or transparent outer ring in the decoded PNG) is detected and cut.
* Nine-slices keep corners at 1:1 and take edges/centre as thin slices from a uniform region, so
  CEGUI's stretched edges stay crisp at any widget size (FrameComponent stretches edges).
* Button/slot state variants use the GL shaders from ui/base/btn*.xml + ui/color/color.xml:
  Hover = Overlay(btndown AAAAAA), Pushed = Multiply(btndown), Disable = MakeGray.
* Title bands are recoloured to the dark lacquer gradient of i_tongyong_teshu_kuangti1 so the
  085 title strings (#gFF0FA0 gold gradient) keep contrast; rails, lines and ornaments stay GL.
"""
import hashlib
import os

import numpy as np
from PIL import Image, ImageOps

GLT = r"C:\TLBB\085\Tools\DATA NEW\TLGL_extracted\ui_png\texture"
GLT_DXT = r"C:\TLBB\085\Tools\DATA NEW\TLGL_extracted\ui_png_dxt\texture"
BTNDOWN = 0xAA / 255.0
BTNOVER = 0xB4 / 255.0


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def detect_pad(im):
    a = np.asarray(im).astype(int)
    h, w = a.shape[:2]
    if h < 5 or w < 5:
        return 0
    ring = np.concatenate([a[0, 1:-1], a[-1, 1:-1], a[1:-1, 0], a[1:-1, -1]])
    inner = np.concatenate([a[1, 1:-1], a[-2, 1:-1], a[1:-1, 1], a[1:-1, -2]])
    if (ring[:, 3] < 8).mean() > 0.95 or (np.abs(ring - inner).max(axis=1) <= 6).mean() > 0.9:
        return 1
    return 0


def _f(im):
    return np.asarray(im.convert("RGBA")).astype(np.float32) / 255.0


def _i(a):
    return Image.fromarray(np.clip(a * 255.0 + 0.5, 0, 255).astype(np.uint8), "RGBA")


def overlay(im, s=BTNDOWN):
    a = _f(im)
    rgb = a[..., :3]
    a[..., :3] = np.where(rgb < 0.5, 2 * rgb * s, 1 - 2 * (1 - rgb) * (1 - s))
    return _i(a)


def multiply(im, s=BTNDOWN):
    a = _f(im)
    a[..., :3] *= s
    return _i(a)


def makegray(im):
    a = _f(im)
    lum = a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114
    a[..., 0] = a[..., 1] = a[..., 2] = lum
    return _i(a)


STATES = (("Normal", lambda im: im), ("Hover", overlay), ("Pushed", multiply), ("Disable", makegray))


class Art:
    def __init__(self):
        self.pieces, self.prov, self.sources = {}, {}, {}

    # ------------------------------------------------------------------ sources
    def load(self, rel, pad=None):
        p = os.path.join(GLT, rel.replace("/", os.sep) + ".png")
        if not os.path.exists(p):
            p = os.path.join(GLT_DXT, rel.replace("/", os.sep) + ".png")
        im = Image.open(p).convert("RGBA")
        if pad is None:
            pad = detect_pad(im)
        if rel not in self.sources:
            self.sources[rel] = dict(path=p, sha256=sha256(p), size="%dx%d" % im.size, pad=pad)
        return im.crop((pad, pad, im.width - pad, im.height - pad)) if pad else im

    def add(self, name, im, src, op):
        if name in self.pieces:
            raise ValueError("duplicate piece " + name)
        self.pieces[name] = im
        self.prov[name] = dict(src=src, op=op, size="%dx%d" % im.size)

    # ------------------------------------------------------------------ slicing
    def nine(self, tag, im, l, t, r, b, src, grad=False, edge=2, center=True):
        """tag_{LT,T,RT,L,C,R,LB,B,RB}. grad=True keeps the full middle height for L/R/C (vertical gradient)."""
        w, h = im.size
        mx = max(l, min(w - r - edge, (l + w - r) // 2))
        my = max(t, min(h - b - edge, (t + h - b) // 2))
        boxes = {"LT": (0, 0, l, t), "RT": (w - r, 0, w, t), "LB": (0, h - b, l, h), "RB": (w - r, h - b, w, h),
                 "T": (mx, 0, mx + edge, t), "B": (mx, h - b, mx + edge, h)}
        if grad:
            boxes.update({"L": (0, t, l, h - b), "R": (w - r, t, w, h - b), "C": (mx, t, mx + edge, h - b)})
        else:
            boxes.update({"L": (0, my, l, my + edge), "R": (w - r, my, w, my + edge), "C": (mx, my, mx + edge, my + edge)})
        for k, bx in boxes.items():
            if k == "C" and not center:
                continue
            if bx[2] > bx[0] and bx[3] > bx[1]:
                self.add("%s_%s" % (tag, k), im.crop(bx), src, "nine %s %s" % (k, bx))

    def nine_states(self, tag, im, l, t, r, b, src, grad=False, states=STATES):
        for st, fn in states:
            self.nine("%s_%s" % (tag, st), fn(im), l, t, r, b, src + " [%s]" % st, grad)

    def single_states(self, tag, im, src, states=STATES):
        for st, fn in states:
            self.add("%s_%s" % (tag, st), fn(im), src, "state " + st)

    # ------------------------------------------------------------------ composites
    def band_gradient(self, n):
        """dark lacquer band of i_tongyong_teshu_kuangti1 (rows 4..27 of its middle column), resampled to n rows."""
        tk = np.asarray(self.load("base/i_tongyong_teshu_kuangti1", 0)).astype(np.float32)
        col = tk[4:28, tk.shape[1] // 2, :3]
        idx = np.linspace(0, len(col) - 1, n)
        out = np.array([col[int(np.floor(i))] * (1 - (i % 1)) + col[min(len(col) - 1, int(np.floor(i)) + 1)] * (i % 1) for i in idx])
        return out * 0.9

    def fret(self):
        """gold square-spiral corner ornament of i_tongyong_teshu_kuangti1 (14x14)."""
        return self.load("base/i_tongyong_teshu_kuangti1", 0).crop((1, 1, 15, 15))

    def window_frame(self):
        """GL i_tongyong_kuangti2 with its amber title band recoloured dark + gold fret ornaments."""
        k2 = self.load("base/i_tongyong_kuangti2")
        a = np.asarray(k2).copy()
        h, w = a.shape[:2]
        rows = list(range(4, 26))
        grad = self.band_gradient(len(rows))
        xs = np.arange(w)
        for i, r in enumerate(rows):
            row = a[r].astype(int)
            m = (row[:, 3] == 255) & (row[:, 0] - row[:, 2] > 25) & (xs >= 8) & (xs < w - 8)
            a[r, m, :3] = grad[i].astype(np.uint8)
        im = Image.fromarray(a, "RGBA")
        fr = self.fret()
        im.alpha_composite(fr, (10, 5))
        im.alpha_composite(ImageOps.mirror(fr), (w - 10 - fr.width, 5))
        return im

    def dragon_frame(self):
        """GL i_tongyong_kuangti1 (dragon head, left half) with the band recoloured where it is plain band colour."""
        k1 = self.load("base/i_tongyong_kuangti1")
        a = np.asarray(k1).astype(np.float32)
        h, w = a.shape[:2]
        ref = a[:, w - 2, :3]
        band = [r for r in range(0, 60) if a[r, w - 2, 3] > 250 and ref[r, 0] - ref[r, 2] > 40]
        grad = self.band_gradient(len(band)) if band else None
        for i, r in enumerate(band):
            d = np.sqrt(((a[r, :, :3] - ref[r]) ** 2).sum(axis=1))
            wgt = np.clip((70.0 - d) / 40.0, 0.0, 1.0)
            wgt[:60] = 0.0
            wgt[a[r, :, 3] < 250] = 0.0
            a[r, :, :3] = a[r, :, :3] * (1 - wgt[:, None]) + grad[i][None, :] * wgt[:, None]
        return Image.fromarray(np.clip(a + 0.5, 0, 255).astype(np.uint8), "RGBA"), (min(band), max(band)) if band else (0, 0)

    def lace_frame(self):
        """dituk panel with the gold corner brackets of i_tongyong_teshu_kuangti1 (48x48)."""
        pn = self.load("base/i_tongyong_dituk")
        base = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
        base.paste(pn.crop((0, 0, 24, 24)), (0, 0))
        base.paste(pn.crop((pn.width - 24, 0, pn.width, 24)), (24, 0))
        base.paste(pn.crop((0, pn.height - 24, 24, pn.height)), (0, 24))
        base.paste(pn.crop((pn.width - 24, pn.height - 24, pn.width, pn.height)), (24, 24))
        tk = self.load("base/i_tongyong_teshu_kuangti1", 0)
        br = tk.crop((0, tk.height - 16, 16, tk.height))                     # bottom-left gold bracket
        base.alpha_composite(br, (0, 32))
        base.alpha_composite(ImageOps.mirror(br), (32, 32))
        base.alpha_composite(ImageOps.flip(br), (0, 0))
        base.alpha_composite(ImageOps.flip(ImageOps.mirror(br)), (32, 0))
        return base

    # ------------------------------------------------------------------ catalogue
    def build(self, bars=None):
        S = "ui_png/texture/"
        # window frame (plain): rails 8, title band 30, bottom 13 (line + fret feet)
        wf = self.window_frame()
        self.nine("W", wf, 32, 30, 32, 13, S + "base/i_tongyong_kuangti2 + teshu band/fret")
        self.add("Bg", self.load("base/i_tongyong_bg"), S + "base/i_tongyong_bg", "tile")
        # dragon frame (wnd1/wnd2 of GL)
        df, band = self.dragon_frame()
        self.band_rows = band
        dw, dh = df.size
        for k, bx in {"LT": (0, 0, dw, 58), "T": (dw - 3, 0, dw - 1, 58), "L": (0, 100, 24, 102), "LB": (0, 200, dw, dh),
                      "B": (dw - 3, 200, dw - 1, dh)}.items():
            self.add("D_" + k, df.crop(bx), S + "base/i_tongyong_kuangti1 (band recoloured)", "crop %s" % (bx,))
        for k in ("LT", "L", "LB"):
            self.add("D_" + {"LT": "RT", "L": "R", "LB": "RB"}[k], ImageOps.mirror(self.pieces["D_" + k]), S + "base/i_tongyong_kuangti1", "mirror")
        # hero title strip: dragon head + dark band, pre-scaled to 30 px (HeroTitle01 windows are 30 px tall)
        ht = df.crop((0, 0, dw, 44))
        ht = ht.resize((int(round(ht.width * 30 / 44.0)), 30), Image.LANCZOS)
        self.add("HT_L", ht, S + "base/i_tongyong_kuangti1", "crop 0..44, scale 30/44")
        self.add("HT_R", ImageOps.mirror(ht), S + "base/i_tongyong_kuangti1", "mirror")
        self.add("HT_M", ht.crop((ht.width - 3, 0, ht.width - 1, 30)), S + "base/i_tongyong_kuangti1", "band column")
        # panels, lace, tooltip, edit, model frame
        self.nine("P", self.load("base/i_tongyong_dituk"), 8, 8, 8, 8, S + "base/i_tongyong_dituk")
        self.nine("L", self.lace_frame(), 16, 16, 16, 16, S + "base/i_tongyong_dituk + teshu brackets")
        self.nine("TT", self.load("base/i_tongyong_tip_ditu"), 8, 8, 8, 8, S + "base/i_tongyong_tip_ditu")
        self.nine("E", self.load("base/i_beibao_dk1"), 3, 3, 3, 3, S + "base/i_beibao_dk1 (GL bgedit)")
        self.nine("M", self.load("font/role/i_juese_fengexian", 0), 18, 18, 18, 18, S + "font/role/i_juese_fengexian", center=False)
        l5 = self.load("base/i_tongyong_teshu_kuangti2", 0)
        self.add("L5_L", l5.crop((0, 0, 72, l5.height)), S + "base/i_tongyong_teshu_kuangti2", "left cap")
        self.add("L5_R", l5.crop((l5.width - 72, 0, l5.width, l5.height)), S + "base/i_tongyong_teshu_kuangti2", "right cap")
        self.add("L5_M", l5.crop((l5.width // 2, 0, l5.width // 2 + 2, l5.height)), S + "base/i_tongyong_teshu_kuangti2", "middle column")
        # buttons (9-slice, GL state shaders)
        for tag, rel in (("BY", "base/i_tongyong_anniu_yellow_1"), ("BR", "base/ts_b_btn2"), ("BG", "base/i_tongyong_anniu_green"),
                         ("BS", "base/i_tongyong_anniuxiao_yellow")):
            self.nine_states(tag, self.load(rel), 5, 5, 5, 5, S + rel, grad=True)
        self.nine_states("BB", self.load("base/i_tongyong_huodong_anniu", 0), 5, 5, 5, 5, S + "base/i_tongyong_huodong_anniu", grad=True)
        # tabs: GL switch_btn1 = fenyeanniu1 normal, fenyeanniu2 selected/hover
        t1, t2 = self.load("base/i_tongyong_fenyeanniu1", 0), self.load("base/i_tongyong_fenyeanniu2", 0)
        for st, im in (("Normal", t1), ("Hover", overlay(t2, BTNOVER)), ("Pushed", t2), ("Disable", makegray(t2))):
            self.nine("T_%s" % st, im, 5, 11, 11, 5, S + "base/i_tongyong_fenyeanniu1/2 [%s]" % st, grad=True)
        # item slots: GL font/box
        self.nine("S", self.load("font/box/i_box_bg1"), 8, 8, 8, 8, S + "font/box/i_box_bg1")
        self.nine("SH", self.load("font/box/i_box_over", 0), 14, 14, 14, 14, S + "font/box/i_box_over", center=True)
        self.nine("SP", self.load("font/box/i_box_down", 0), 14, 14, 14, 14, S + "font/box/i_box_down", center=True)
        self.add("SD", Image.new("RGBA", (8, 8), (0, 0, 0, 150)), "synthetic", "disabled veil (60% black)")
        # scrollbar: GL vscrollbar.xml = track xlt4, thumb xlt1 + grip xlt6, arrows xlt2/xlt3
        self.nine("SBT", self.load("base/i_tongyong_xlt4"), 3, 3, 3, 3, S + "base/i_tongyong_xlt4")
        th = self.load("base/i_tongyong_xlt1")
        for st, fn in (("Normal", lambda im: im), ("Hover", lambda im: overlay(im, BTNOVER)), ("Pushed", multiply), ("Disable", makegray)):
            self.nine("SBM_%s" % st, fn(th), 3, 3, 3, 3, S + "base/i_tongyong_xlt1 [%s]" % st)
        self.add("SBG", self.load("base/i_tongyong_xlt6"), S + "base/i_tongyong_xlt6", "grip")
        for tag, rel in (("SBU", "base/i_tongyong_xlt2"), ("SBD", "base/i_tongyong_xlt3")):
            im = self.load(rel)
            for st, fn in (("Normal", lambda im: im), ("Hover", lambda im: overlay(im, BTNOVER)), ("Pushed", multiply), ("Disable", makegray)):
                self.add("%s_%s" % (tag, st), fn(im), S + rel, "state " + st)
        # small buttons
        for tag, rel, pad in (("C", "base/i_tongyong_guanbi", 0), ("H", "base/i_tongyong_wenhao1", None), ("A", "base/i_tongyong_jia", None),
                              ("X2", "base/i_tongyong_guanbi1", None), ("PP", "base/i_tongyong_fanye1", 0), ("PN", "base/i_tongyong_fanye2", 0)):
            self.single_states(tag, self.load(rel, pad), S + rel)
        for tag, rel, pad in (("CK_Off", "base/i_tongyong_fuxuanze1", None), ("CK_On", "base/i_tongyong_fuxuanze2", 0),
                              ("RD_Off", "base/i_tongyong_xuanze1", None), ("RD_On", "base/i_tongyong_xuanze2", 0)):
            self.add(tag, self.load(rel, pad), S + rel, "as is")
        self.add("Blank", Image.new("RGBA", (4, 4), (0, 0, 0, 0)), "synthetic", "transparent")
        self.add("SEL", self.load("base/i_tiaozhan_liebiao_over"), S + "base/i_tiaozhan_liebiao_over", "list selection brush")
        self.add("BarLight", self.load("font/skillbar/i_zhujie_jdt1"), S + "font/skillbar/i_zhujie_jdt1", "progress head light")
        # progress bars: GL i_bsqd_jdt profile recoloured to the 085 colour of each bar look
        if bars:
            jd = self.load("font/signin/i_bsqd_jdt")
            jd = jd.crop((jd.width // 2 - 4, 0, jd.width // 2 + 4, jd.height))
            a = np.asarray(jd).astype(np.float32)
            refl = (a[a.shape[0] // 2, 4, :3] * (0.299, 0.587, 0.114)).sum()
            for tag, rgb in sorted(bars.items()):
                k = (a[..., :3] * (0.299, 0.587, 0.114)).sum(axis=2, keepdims=True) / max(refl, 1.0)
                out = a.copy()
                out[..., :3] = np.clip(k * np.array(rgb, np.float32)[None, None, :], 0, 255)
                self.add("Bar_" + tag, Image.fromarray(out.astype(np.uint8), "RGBA"), S + "font/signin/i_bsqd_jdt", "recolour %s" % (rgb,))
        return self

    # ------------------------------------------------------------------ atlas
    def atlas(self, width=1024):
        """shelf packing; each piece gets a 1-px extruded border (no bilinear seams) + 1-px gap."""
        x = y = rowh = 0
        pos = {}
        for name, im in sorted(self.pieces.items(), key=lambda kv: (-kv[1].size[1], kv[0])):
            w, h = im.size
            if x + w + 3 > width:
                x, y, rowh = 0, y + rowh + 3, 0
            pos[name] = (x + 1, y + 1, w, h)
            x += w + 3
            rowh = max(rowh, h)
        H = 1 << (y + rowh + 3 - 1).bit_length()
        atlas = Image.new("RGBA", (width, H), (0, 0, 0, 0))
        for name, (px, py, w, h) in pos.items():
            im = self.pieces[name]
            ext = ImageOps.expand(im, border=1)
            a = np.asarray(ext).copy()
            a[0, 1:-1], a[-1, 1:-1] = a[1, 1:-1], a[-2, 1:-1]
            a[:, 0], a[:, -1] = a[:, 1], a[:, -2]
            atlas.paste(Image.fromarray(a, "RGBA"), (px - 1, py - 1))
        return atlas, pos
