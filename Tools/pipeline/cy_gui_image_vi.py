# -*- coding: utf-8 -*-
"""cy_gui_image_vi.py - layer cy-gui-image-vi: Vietnamese labels painted into CY 3.71 GUI textures (15/09/2026).

CY draws many labels into its imageset textures (tabs, buttons, minimap badges, login buttons ...). CEGUI text cannot
replace them without changing layouts and Lua, and it would lose CY's gold/outline look for every button state, so
this layer repaints the label inside the texture, keeping file names, imageset names and rectangles unchanged:

    Registry/i18n/cy_gui_image_vi.tsv   one row per image (or a family of state images) with the Vietnamese label
    source texture                      CY 3.71 bytes (Interface.axp through build_canonical_cy, or a read-only
                                        InterfaceFolder on disk for the standalone mode), never modified
    output                              <gen>/InterfaceFolder/<texture relpath> (same name, same container family:
                                        DDS -> uncompressed A8R8G8B8 DDS, TGA -> 32-bit TGA, PNG -> PNG, JPG -> JPG q95)
                                        + <gen>/_manifest rows (texture, image, zh, vi, source sha256, output sha256)

Repaint of one image rectangle (paint_label):
  1. text mask  = pixels whose colour matches the label ink (auto: the brightest/most saturated cluster that differs
                  from the local background; or `ink=` from the registry) + the outline ring around them (dilate);
  2. erase      = transparent labels (alpha < 16 outside the ink): alpha of the mask -> 0;
                  opaque labels: cv2.inpaint (Telea) of RGB inside the mask, alpha kept;
  3. draw       = Noto Sans SC (the project font, Docs/specs/ui/fonts_vi.md) at the largest size that fits the text
                  box (the bounding box of the removed ink, never the frame), ink colour = median of the removed ink,
                  outline colour = median of the ring, 1 px stroke when the source had an outline; vertical gradient
                  kept when the source ink had one (top/bottom medians).
Nothing else in the texture changes (checked: pixels outside the repainted rectangles are byte-identical before
encoding; DXT sources are decoded once, so the output equals the decoded source outside the rectangles).

Standalone:  cy_gui_image_vi.py --ui <InterfaceFolder> --out <dir> [--only IMAGESET[,..]] [--preview]
"""
import argparse
import collections
import csv
import hashlib
import io
import json
import os
import re
import struct
import sys
import unicodedata

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
REGISTRY = os.path.join(REPO, 'Registry', 'i18n', 'cy_gui_image_vi.tsv')
LAYER = 'cy-gui-image-vi'
TOOL = 'cy_gui_image_vi.py 1.0 (2026-09-15)'
FONT_REL = 'Schema/NotoSansSC-Regular.ttf'

_ATTRV = re.compile(r'(\w+)\s*=\s*"([^"]*)"')


# ------------------------------------------------------------------------------------------------- text / readers
def decode_text(raw):
    if raw[:2] in (b'\xff\xfe', b'\xfe\xff'):
        return raw[2:].decode('utf-16-le' if raw[:2] == b'\xff\xfe' else 'utf-16-be')
    if raw[:3] == b'\xef\xbb\xbf':
        raw = raw[3:]
    try:
        return raw.decode('utf-8')
    except UnicodeDecodeError:
        return raw.decode('gb18030')


class DiskReader:
    """Files below a read-only InterfaceFolder (relative paths with / or \\, case-insensitive)."""

    def __init__(self, root):
        self.root = root
        self.by_rel, self.by_base = {}, collections.defaultdict(list)
        for dp, _dirs, files in os.walk(root):
            for fn in files:
                rel = os.path.relpath(os.path.join(dp, fn), root).replace('\\', '/')
                self.by_rel[rel.lower()] = rel
                self.by_base[fn.lower()].append(rel)

    def resolve(self, rel):
        rel = rel.replace('\\', '/').lower()
        if rel in self.by_rel:
            return self.by_rel[rel]
        hits = self.by_base.get(rel.rsplit('/', 1)[-1])
        return hits[0] if hits else None

    def read(self, rel):
        with open(os.path.join(self.root, rel), 'rb') as f:
            return f.read()

    def origin(self, rel):
        return 'disk:' + rel


class AxpReader:
    """Interface.axp of CY 3.71 (S4) with the S2 fallback for wrapper types 1-18, like build_canonical_cy."""

    def __init__(self, axp, s2_dir, ax):
        self.a, self.s2, self.ax = axp, s2_dir, ax
        names = [n for n, _ in axp.file_list()]
        self.by_rel = {n.replace('\\', '/').lower(): n for n in names}
        self.by_base = collections.defaultdict(list)
        for n in names:
            self.by_base[n.replace('\\', '/').rsplit('/', 1)[-1].lower()].append(n)

    def resolve(self, rel):
        rel = rel.replace('\\', '/').lower()
        if rel in self.by_rel:
            return self.by_rel[rel]
        hits = self.by_base.get(rel.rsplit('/', 1)[-1])
        return hits[0] if hits else None

    def read(self, name):
        ent = self.a.entry(name)
        raw = self.a.read(ent)
        hd = self.ax.decode_header(raw, ent[1])
        if hd is None:
            return raw
        alg, plen = hd[0], hd[1]
        if alg < 19:
            with open(os.path.join(self.s2, name.replace('/', '\\')), 'rb') as f:
                return f.read(plen + 64)[:plen]
        data = self.ax.decrypt(raw[self.ax.HDR_SIZE:], alg, plen)
        if data is None:
            raise ValueError('not decryptable: ' + name)
        return data[:plen]

    def origin(self, name):
        return 'S4:Interface.axp:' + name


# ------------------------------------------------------------------------------------------------- imagesets
class ImagesetIndex:
    def __init__(self, ui_root=None, reader=None):
        self.r = reader
        scheme = decode_text(self.r.read(self.r.resolve('Schema/WoWLookSkin.scheme.xml')))
        self.files = {}
        for m in re.finditer(r'<Imageset\b[^>]*/>', scheme):
            at = dict(_ATTRV.findall(m.group(0)))
            if 'Name' in at and 'Filename' in at:
                self.files.setdefault(at['Name'], at['Filename'])
        self._all = None
        self._sets = {}

    def _chunk_from_all(self, name):
        if self._all is None:
            self._all = {}
            rel = self.r.resolve('Schema/all.imageset.xml')
            text = decode_text(self.r.read(rel)) if rel else ''
            for m in re.finditer(r'<Imageset\b[^>]*?\bName="([^"]+)"[^>]*>.*?</Imageset>', text, re.S):
                self._all.setdefault(m.group(1), m.group(0))
        return self._all.get(name)

    def imageset(self, name):
        if name in self._sets:
            return self._sets[name]
        text = None
        fn = self.files.get(name)
        if fn:
            rel = self.r.resolve(fn)
            if rel:
                text = decode_text(self.r.read(rel))
        if text is None or ('Name="%s"' % name) not in text:
            text = self._chunk_from_all(name)
        res = None
        if text:
            head = re.search(r'<Imageset\b[^>]*>', text)
            at = dict(_ATTRV.findall(head.group(0))) if head else {}
            imgs = {}
            for m in re.finditer(r'<Image\b[^>]*/>', text):
                ia = dict(_ATTRV.findall(m.group(0)))
                try:
                    imgs[ia['Name']] = (int(float(ia['XPos'])), int(float(ia['YPos'])), int(float(ia['Width'])),
                                        int(float(ia['Height'])))
                except (KeyError, ValueError):
                    continue
            res = (at.get('Imagefile', ''), imgs)
        self._sets[name] = res
        return res

    def image(self, iset, img):
        s = self.imageset(iset)
        if not s or img not in s[1]:
            return None
        tex = self.r.resolve(s[0])
        if tex is None:
            return None
        return (tex,) + s[1][img]

    def texture_rgba(self, tex):
        return decode_image(self.r.read(tex))[0]


# ------------------------------------------------------------------------------------------------- codecs
def decode_image(data):
    """-> (RGBA uint8 HxWx4, kind) kind in dds/tga/png/jpg."""
    if data[:4] == b'DDS ':
        sys.path.insert(0, HERE)
        import upscale_pack as UP  # noqa: E402  (numpy DXT1/3/5 + ARGB decoder of this pipeline)
        px, _h, _fmt = UP.decode_dds(data)
        return px, 'dds'
    im = Image.open(io.BytesIO(data))
    kind = {'TGA': 'tga', 'PNG': 'png', 'JPEG': 'jpg'}.get(im.format, im.format.lower())
    return np.array(im.convert('RGBA')), kind


def encode_image(px, kind):
    h, w = px.shape[:2]
    if kind == 'dds':
        hdr = bytearray(128)
        struct.pack_into('<4s7I', hdr, 0, b'DDS ', 124, 0x100F, h, w, w * 4, 0, 1)
        struct.pack_into('<8I', hdr, 76, 32, 0x41, 0, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
        struct.pack_into('<I', hdr, 108, 0x1000)
        return bytes(hdr) + np.ascontiguousarray(px[..., [2, 1, 0, 3]]).tobytes()
    buf = io.BytesIO()
    im = Image.fromarray(px, 'RGBA')
    if kind == 'tga':
        im.save(buf, 'TGA', rle=False)
    elif kind == 'png':
        im.save(buf, 'PNG')
    elif kind == 'jpg':
        im.convert('RGB').save(buf, 'JPEG', quality=95, subsampling=0)
    else:
        raise ValueError('unsupported texture kind ' + kind)
    return buf.getvalue()


# ------------------------------------------------------------------------------------------------- registry
def parse_opts(s):
    out = {}
    for part in (s or '').split(';'):
        part = part.strip()
        if not part:
            continue
        k, _, v = part.partition('=')
        out[k.strip()] = v.strip() if _ else '1'
    return out


def load_registry(path=REGISTRY):
    """[{imageset, images:[pattern], zh, vi, opts, note, line}] - '#' lines are comments."""
    rows = []
    with open(path, encoding='utf-8') as f:
        for n, line in enumerate(f, 1):
            line = line.rstrip('\n').rstrip('\r')
            if not line.strip() or line.startswith('#'):
                continue
            cols = line.split('\t')
            if cols[0] == 'imageset':
                continue
            cols += [''] * (6 - len(cols))
            iset, images, zh, vi, opts, note = cols[:6]
            if not iset or not images or not vi:
                raise ValueError('%s:%d: imageset, images and vi are required' % (path, n))
            rows.append({'imageset': iset.strip(), 'images': [p.strip() for p in images.split(',') if p.strip()],
                         'zh': zh.strip(), 'vi': unicodedata.normalize('NFC', vi.strip()), 'opts': parse_opts(opts),
                         'note': note.strip(), 'line': n})
    return rows


def match_images(patterns, names):
    out = []
    for p in patterns:
        rx = re.compile('^' + re.escape(p).replace(r'\*', '.*') + '$')
        hit = [n for n in names if rx.match(n)]
        if not hit:
            raise KeyError(p)
        out += [h for h in sorted(hit) if h not in out]
    return out


# ------------------------------------------------------------------------------------------------- painting
def _box(s):
    return tuple(int(v) for v in s.split(','))


def _hex(s):
    s = s.lstrip('#')
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def ink_channel(img, opts):
    """uint8 plane the label is searched on: luminance (default) or one colour channel (chan=r|g|b, e.g. the red
    glyphs of the target type badges), premultiplied by alpha."""
    a = img[..., 3].astype(np.float32) / 255.0
    ch = opts.get('chan')
    if ch in ('r', 'g', 'b'):
        v = img[..., 'rgb'.index(ch)].astype(np.float32)
    else:
        v = 0.299 * img[..., 0] + 0.587 * img[..., 1] + 0.114 * img[..., 2]
    return np.clip(v * a, 0, 255).astype(np.uint8)


def find_ink(crop, opts):
    """-> (ink bool HxW, box (x0,y0,x1,y1) exclusive) of the label drawn in an RGBA crop."""
    import cv2
    h, w = crop.shape[:2]
    y = ink_channel(crop, opts)
    # white top-hat: strokes thinner than the structuring element (glyph strokes) survive, broad plates do not
    k = int(opts.get('k', 0)) or (5 if min(h, w) <= 24 else 7 if min(h, w) <= 48 else 9)
    se = cv2.getStructuringElement(cv2.MORPH_ELLIPSE if 'round' in opts else cv2.MORPH_RECT, (k, k))
    if opts.get('ink') == 'dark':
        res = cv2.morphologyEx(y, cv2.MORPH_BLACKHAT, se)
    else:
        res = cv2.morphologyEx(y, cv2.MORPH_TOPHAT, se)
    t = float(opts.get('t', 0))
    if not t:
        region = res
        if opts.get('icon') == 'round':
            yy_, xx_ = np.mgrid[0:h, 0:w]
            rr = float(opts.get('r', 0.37)) * min(h, w)
            disc = ((yy_ + 0.5 - h / 2.0) ** 2 + (xx_ + 0.5 - w / 2.0) ** 2) <= rr * rr
            region = np.ascontiguousarray(res[disc]).reshape(-1, 1)
        elif 'box' in opts:     # threshold measured inside the label box (dim normal states)
            bx0, by0, bx1, by1 = _box(opts['box'])
            region = np.ascontiguousarray(res[by0:by1, bx0:bx1])
        otsu, _ = cv2.threshold(region, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        t = max(float(opts.get('tmin', 22)), float(otsu))
    ink = res > t
    if opts.get('icon') == 'round':
        # round badge: the glyph sits inside the rim; keep the central disc only (rim, highlights outside)
        r = float(opts.get('r', 0.37)) * min(h, w)
        yy_, xx_ = np.mgrid[0:h, 0:w]
        ink &= ((yy_ + 0.5 - h / 2.0) ** 2 + (xx_ + 0.5 - w / 2.0) ** 2) <= r * r
        ys, xs = np.nonzero(ink)
        if not len(xs):
            return ink, None
        return ink, (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    if 'box' in opts:
        x0, y0, x1, y1 = _box(opts['box'])
        m = np.zeros_like(ink)
        m[y0:y1, x0:x1] = True
        ink &= m
    n, lab, st, _c = cv2.connectedComponentsWithStats(ink.astype(np.uint8), connectivity=8)
    keep = np.zeros(n, bool)
    for i in range(1, n):
        x, yy, ww, hh, area = st[i]
        border = x == 0 or yy == 0 or x + ww == w or yy + hh == h
        frame = (ww > 0.85 * w or hh > 0.85 * h) and w > 20
        if area < 2 or (border and 'box' not in opts and 'keepborder' not in opts):
            continue
        if frame and 'keepframe' not in opts and 'box' not in opts:
            continue
        keep[i] = True
    ink = keep[lab]
    if not ink.any():
        return ink, None
    if 'box' not in opts:
        # row profile of the glyph-like components (thin frame lines excluded), then the band around its peak
        glyph = keep.copy()
        for i in range(1, n):
            if keep[i]:
                ww, hh = st[i][2], st[i][3]
                if (hh <= 2 and ww >= 8) or (ww <= 2 and hh >= 8):
                    glyph[i] = False
        prof = (glyph[lab] if glyph.any() else ink).sum(1).astype(np.float32)
        top = int(prof.argmax())
        lo = hi = top
        thr = 0.06 * prof.max()
        while lo > 0 and prof[lo - 1] > thr:
            lo -= 1
        while hi < h - 1 and prof[hi + 1] > thr:
            hi += 1
        band = np.zeros(n, bool)
        for i in range(1, n):
            if keep[i]:
                cy = st[i][1] + st[i][3] / 2.0
                band[i] = lo - 1 <= cy <= hi + 1
        if band.any():
            ink = band[lab]
    ys, xs = np.nonzero(ink)
    return ink, (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)


_FONTS = {}


def font(path, size):
    key = (path, size)
    if key not in _FONTS:
        _FONTS[key] = ImageFont.truetype(path, size)
    return _FONTS[key]


QA_RESIDUAL_MAX = 0.08     # share of the Chinese ink texels still standing out of the erased background
QA_CONTRAST_MIN = 2.0      # (L1 + 0.05) / (L2 + 0.05) label ink vs erased background under it (disabled: 1.3)


def _rel_lum(rgb):
    c = np.asarray(rgb, np.float64) / 255.0
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[..., 0] + 0.7152 * c[..., 1] + 0.0722 * c[..., 2]


def quality(crop, erased, new, ink, er, fa, box, ax, vband, round_info, fill_col, opts):
    """Automatic checks of one repainted image:
    bounds   = texels of the new label (coverage > 0.25) outside the allowed text box (erase box + declared text
               area; round badges: the core circle less the margin) -> must be 0;
    residual = Chinese ink texels still detected on the erased background (same top-hat, half the ink median);
    contrast = WCAG-style ratio between the label ink and the erased background under the label."""
    import cv2
    h, w = crop.shape[:2]
    x0, y0, x1, y1 = box
    g = int(opts.get('grow', 2)) + 1
    text = fa > 0.25
    if round_info is not None:
        yy_, xx_ = np.mgrid[0:h, 0:w]
        cx_, cy_ = round_info['center']
        allowed = np.hypot(xx_ + 0.5 - cx_, yy_ + 0.5 - cy_) <= round_info['core'] - float(opts.get('margin', 2)) + 0.75
    else:
        allowed = np.zeros((h, w), bool)
        ex0, ex1 = int(np.floor(min(x0 - g, ax[0]))) - 1, int(np.ceil(max(x1 + g, ax[1]))) + 1   # 1 texel rounding
        allowed[max(0, vband[0]):min(h, vband[1]), max(0, ex0):min(w, ex1)] = True
    bounds = int((text & ~allowed).sum())

    def tophat(img):
        y = ink_channel(img, opts)
        k = int(opts.get('k', 0)) or (5 if min(h, w) <= 24 else 7 if min(h, w) <= 48 else 9)
        se = cv2.getStructuringElement(cv2.MORPH_RECT, (k, k))
        return cv2.morphologyEx(y, cv2.MORPH_BLACKHAT if opts.get('ink') == 'dark' else cv2.MORPH_TOPHAT, se)
    t0 = tophat(crop)
    tv = max(22.0, 0.5 * float(np.median(t0[ink]))) if ink.any() else 22.0
    residual = float(((tophat(erased) > tv) & ink).sum()) / max(1, int(ink.sum()))
    under = (fa > 0.5)
    if under.any():
        bg = erased[..., :3][under].astype(np.float64).mean(0)
        fg = np.asarray(fill_col, np.float64).reshape(-1, 3).mean(0)
        l1, l2 = float(_rel_lum(fg)), float(_rel_lum(bg))
        contrast = (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    else:
        contrast = 0.0
    res = {'bounds_px': bounds, 'residual': round(residual, 3), 'contrast': round(contrast, 2)}
    if 'contrast_min' in opts:     # documented per row: CY itself draws that label with a low contrast
        res['contrast_min'] = float(opts['contrast_min'])
    return res


def qa_status(name, qa):
    """ok / fail:<reasons> for the manifest (disabled states may have a lower contrast, as in CY)."""
    bad = []
    if qa.get('bounds_px', 0) > 0:
        bad.append('bounds')
    if qa.get('residual', 0) > QA_RESIDUAL_MAX:
        bad.append('residual')
    low = 1.3 if re.search(r'disab|disbl', name, re.I) else float(qa.get('contrast_min', QA_CONTRAST_MIN))
    if qa.get('contrast', 99) < low:
        bad.append('contrast')
    if qa.get('fits') is False:
        bad.append('round-fit')
    return 'ok' if not bad else 'fail:' + ','.join(bad)


def text_masks(vi, f, stroke, bold, shadow, sq, opts):
    """Coverage masks (float 0..1) of one label: fill and outline/shadow, squeezed horizontally by sq.
    Returns (fill, outline, canvas width, canvas height, bbox top) - the canvas has a 2 px pad left/top."""
    l, t, r, b = f.getbbox(vi, stroke_width=stroke)
    tw, th = r - l, b - t
    cw, ch = tw + 4 + bold + shadow, th + 4 + shadow
    fill_m = Image.new('L', (cw, ch), 0)
    ImageDraw.Draw(fill_m).text((2 - l, 2 - t), vi, font=f, fill=255)
    if bold:     # faux bold: CY label glyphs are heavy; one texel to the right
        fm_ = np.array(fill_m)
        fill_m = Image.fromarray(np.maximum(fm_, np.roll(fm_, 1, 1)))
    strk_m = Image.new('L', (cw, ch), 0)
    if stroke:
        ImageDraw.Draw(strk_m).text((2 - l, 2 - t), vi, font=f, fill=255, stroke_width=stroke, stroke_fill=255)
        if bold:
            sm_ = np.array(strk_m)
            strk_m = Image.fromarray(np.maximum(sm_, np.roll(sm_, 1, 1)))
    elif shadow:
        fm_ = np.array(fill_m).astype(np.float32)
        sh = np.roll(np.roll(fm_, shadow, 0), shadow, 1) * float(opts.get('shadow_alpha', 0.85))
        strk_m = Image.fromarray(np.clip(sh, 0, 255).astype(np.uint8))
    if sq < 0.999:
        nw = max(1, int(round(cw * sq)))
        fill_m = fill_m.resize((nw, ch), Image.LANCZOS)
        strk_m = strk_m.resize((nw, ch), Image.LANCZOS)
        cw = nw
    return np.array(fill_m, np.float32) / 255.0, np.array(strk_m, np.float32) / 255.0, cw, ch, t


def place_masks(fm, sm, cw, ch, cx, oy, t, sq, h, w):
    """Put the canvas so that the ink is centred on cx and the bbox top sits at oy + t. Returns (fa, sa, py0)."""
    pad = sq if sq < 0.999 else 1.0
    px0 = int(round(cx - (cw - 4 * pad) / 2.0 - 2 * pad))
    py0 = int(round(oy + t - 2))
    fa = np.zeros((h, w), np.float32)
    sa = np.zeros((h, w), np.float32)
    sx0, sy0 = max(0, -px0), max(0, -py0)
    dx0, dy0 = max(0, px0), max(0, py0)
    dx1, dy1 = min(w, px0 + cw), min(h, py0 + ch)
    if dx1 > dx0 and dy1 > dy0:
        fa[dy0:dy1, dx0:dx1] = fm[sy0:sy0 + dy1 - dy0, sx0:sx0 + dx1 - dx0]
        sa[dy0:dy1, dx0:dx1] = sm[sy0:sy0 + dy1 - dy0, sx0:sx0 + dx1 - dx0]
    return fa, sa, py0


def round_badge(crop, opts):
    """Round CY badge (single glyph inside a rim): background rebuilt from ring x sector medians (the glyph covers
    less than half of every ring, and the lower/upper luminance percentile of each bucket is the plate), core radius
    = inner edge of the rim on that background, glyph mask = texels far from the background inside the core."""
    import cv2
    h, w = crop.shape[:2]
    alpha = crop[..., 3]
    ys_, xs_ = np.nonzero(alpha > 128)
    if len(xs_):
        ccx, ccy = (xs_.min() + xs_.max() + 1) / 2.0, (ys_.min() + ys_.max() + 1) / 2.0
        rad = min(xs_.max() + 1 - xs_.min(), ys_.max() + 1 - ys_.min()) / 2.0
    else:
        ccx, ccy, rad = w / 2.0, h / 2.0, min(w, h) / 2.0
    yy_, xx_ = np.mgrid[0:h, 0:w]
    dist = np.hypot(xx_ + 0.5 - ccx, yy_ + 0.5 - ccy)
    ang = np.arctan2(yy_ + 0.5 - ccy, xx_ + 0.5 - ccx)
    rgbf = crop.astype(np.float32)
    plane = ink_channel(crop, opts).astype(np.float32)
    dark = opts.get('ink') == 'dark'
    n_sec = 12
    sec = (np.floor((ang + np.pi) / (2 * np.pi) * n_sec).astype(int)) % n_sec
    rbin = np.floor(dist).astype(int)
    bg = rgbf.copy()
    for r in range(int(rad) + 2):
        ring = rbin == r
        if not ring.any():
            continue
        secs = n_sec if r >= 4 else 1
        for s in range(secs):
            sel = (ring & (sec == s)) if secs > 1 else ring
            if not sel.any():
                continue
            q = np.percentile(plane[sel], 70 if dark else 30)
            pick = sel & ((plane >= q) if dark else (plane <= q))
            bg[sel] = np.median(rgbf[pick], axis=0)
    bg = cv2.GaussianBlur(bg, (3, 3), 0.8)
    bl = ink_channel(np.clip(bg, 0, 255).astype(np.uint8), {})
    prof = []
    for r in range(int(rad) + 1):
        sel = (rbin == r) & (alpha > 128)
        prof.append(float(bl[sel].mean()) if sel.any() else np.nan)
    prof = np.array(prof)
    # CY rims start with a dark separating ring: the core ends at the darkest ring of the outer half (measured on the
    # rebuilt background, so the glyph does not count)
    # (dark plates such as the red target badges have a light rim instead: the ring farthest from the plate wins)
    lo_r, hi_r = max(2, int(round(rad * 0.55))), max(3, int(rad) - 2)
    edge = rad * 0.75
    seg = prof[lo_r:hi_r + 1]
    if seg.size and np.isfinite(seg).any():
        plate = np.nanmedian(prof[1:lo_r]) if np.isfinite(prof[1:lo_r]).any() else np.nanmedian(seg)
        edge = float(lo_r + int(np.nanargmax(np.abs(seg - plate))))
    core = float(opts.get('core', edge))
    inside = dist <= core + 0.5
    if opts.get('chan') in ('r', 'g', 'b'):
        c = 'rgb'.index(opts['chan'])
        diff = np.abs(rgbf[..., c] - bg[..., c])
    else:
        diff = np.abs(rgbf[..., :3] - bg[..., :3]).max(2)
    vals = np.clip(diff[inside], 0, 255).astype(np.uint8).reshape(-1, 1)
    otsu = cv2.threshold(vals, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[0] if vals.size else 0
    thr = max(float(opts.get('tmin', 20)), float(otsu), float(opts.get('t', 0)))
    ink = (diff > thr) & inside
    n, lab, st, _c = cv2.connectedComponentsWithStats(ink.astype(np.uint8), connectivity=8)
    keep = np.zeros(n, bool)
    keep[1:] = st[1:, 4] >= 2
    ink = keep[lab]
    er = cv2.dilate(ink.astype(np.uint8), np.ones((3, 3), np.uint8), iterations=int(opts.get('grow', 1)))
    er &= (dist <= core + 1.0).astype(np.uint8)
    if not ink.any():
        return None
    ys, xs = np.nonzero(ink)
    return {'ink': ink, 'box': (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1), 'er': er,
            'bg': np.clip(np.round(bg), 0, 255).astype(np.uint8), 'center': (ccx, ccy), 'rad': rad, 'core': core,
            'dist': dist, 'diff': diff, 'thr': thr}


def paint_label(crop, vi, opts, font_path, ref=None):
    """Repaint one RGBA crop. ref = (ink, box) measured on the family's reference state (same size) or None.
    Returns (new crop, info dict)."""
    import cv2
    h, w = crop.shape[:2]
    rb = round_badge(crop, opts) if opts.get('icon') == 'round' else None
    if opts.get('icon') == 'round':
        if rb is None:
            return crop, {'status': 'no-ink'}
        ink, box = rb['ink'], rb['box']
    else:
        ink, box = find_ink(crop, opts) if ref is None else ref
    if box is None:
        return crop, {'status': 'no-ink'}
    x0, y0, x1, y1 = box
    # colours of the removed label (measured on this state: hover/pushed/disabled differ)
    rgb = crop[..., :3].astype(np.float32)
    alpha = crop[..., 3]
    own = ink & (alpha > 128)
    if own.sum() < 4:
        own = ink
    # ink colour = the most label-like texels of the mask (brightest 35 % for light ink, darkest for dark ink):
    # the mask also holds anti-aliased edges and, on small plates, some background
    lum = 0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]
    lv = lum[own]
    if opts.get('ink') == 'dark':
        inkcore = own & (lum <= np.percentile(lv, 35))
    else:
        inkcore = own & (lum >= np.percentile(lv, 65))
    mid = (y0 + y1) / 2.0
    rows_ = np.arange(h)[:, None]
    top, bot = rgb[inkcore & (rows_ < mid)], rgb[inkcore & (rows_ >= mid)]
    allc = rgb[inkcore]
    pick = lambda arr: np.median(arr, axis=0) if len(arr) >= 2 else np.median(allc, axis=0)  # noqa: E731
    col_top, col_bot = pick(top), pick(bot)
    if 'color' in opts:
        col_top = col_bot = np.array(_hex(opts['color']), np.float32)
    kern = np.ones((3, 3), np.uint8)
    ring = cv2.dilate(ink.astype(np.uint8), kern, iterations=int(opts.get('ring', 1))).astype(bool) & ~ink
    solid = ring & (alpha > 128)
    ringcol = np.median(rgb[solid], axis=0) if solid.sum() >= 3 else np.zeros(3, np.float32)
    ink_l = float(np.dot((col_top + col_bot) / 2, [0.299, 0.587, 0.114]))
    ring_l = float(np.dot(ringcol, [0.299, 0.587, 0.114]))
    # outline: CY labels have a dark rim; a 1 px stroke is kept for large text, small text gets a drop shadow
    # (a full stroke closes the counters of 8-10 px Vietnamese letters)
    outline = ring_l < ink_l - 60 or solid.sum() < 3
    if rb is not None:
        ringcol = np.minimum(ringcol, np.array(rb['bg'][..., :3][rb['er'].astype(bool)].mean(0) * 0.45
                                               if rb['er'].any() else ringcol))
        outline = True
    stroke = int(opts.get('stroke', 1 if outline else 0))
    if 'stroke_color' in opts:
        ringcol = np.array(_hex(opts['stroke_color']), np.float32)
    if rb is not None:
        er = rb['er']
        out = np.where(er[..., None].astype(bool), rb['bg'], crop)
    else:
        # erase: ink + its outline/glow, only near the label box
        er = cv2.dilate(ink.astype(np.uint8), kern, iterations=int(opts.get('grow', 2)))
        lim = np.zeros((h, w), np.uint8)
        g = int(opts.get('grow', 2)) + 1
        lim[max(0, y0 - g):min(h, y1 + g), max(0, x0 - g):min(w, x1 + g)] = 1
        er &= lim
        out = crop.copy()
        if er.any():
            radius = float(opts.get('radius', 3))
            pad = 4
            big = cv2.copyMakeBorder(crop, pad, pad, pad, pad, cv2.BORDER_REFLECT)
            bm = cv2.copyMakeBorder(er, pad, pad, pad, pad, cv2.BORDER_CONSTANT, value=0)
            rgb_i = cv2.inpaint(np.ascontiguousarray(big[..., :3]), bm, radius, cv2.INPAINT_TELEA)
            a_i = cv2.inpaint(np.ascontiguousarray(big[..., 3]), bm, radius, cv2.INPAINT_TELEA)
            tel = np.concatenate([rgb_i, a_i[..., None]], 2)[pad:-pad, pad:-pad].astype(np.float32)
            mode = opts.get('fill', 'mix')
            if mode in ('hlerp', 'mix'):
                # row-wise linear interpolation between the nearest kept texels left and right: keeps the vertical
                # gradient of CY button plates (Telea alone smears them)
                hl = crop.astype(np.float32).copy()
                m = er.astype(bool)
                xs = np.arange(w)
                for r in range(h):
                    row_m = m[r]
                    if not row_m.any():
                        continue
                    good = ~row_m
                    if good.sum() < 2:
                        hl[r] = tel[r]
                        continue
                    for c in range(4):
                        hl[r, row_m, c] = np.interp(xs[row_m], xs[good], crop[r, good, c].astype(np.float32))
                fillv = hl if mode == 'hlerp' else (hl + tel) / 2.0
            else:
                fillv = tel
            out = np.where(er[..., None].astype(bool), np.clip(np.round(fillv), 0, 255).astype(np.uint8), crop)
    # text area
    if 'area' in opts:
        ax0, ay0, ax1, ay1 = _box(opts['area'])
    else:
        bw = x1 - x0
        grow_x = int(round(float(opts.get('widen', 0.06)) * w))
        ax0, ax1 = max(1, x0 - grow_x), min(w - 1, x1 + grow_x)
        if bw < w * 0.5 and 'widen' not in opts:     # narrow labels (single glyph) may use most of the image
            ax0, ax1 = max(1, min(x0, int(w * 0.12))), min(w - 1, max(x1, w - int(w * 0.12)))
        ay0, ay1 = y0, y1
    aw, ah = ax1 - ax0, ay1 - ay0
    fpath = font_path
    # size: Latin capital height ~ cap x the removed CJK glyph height; Vietnamese marks may use the free margin above
    # and below the glyph box (the whole image height), never beyond it
    cap = float(opts.get('cap', 0.8))
    cyy = (ay0 + ay1) / 2.0 + float(opts.get('dy', 0))
    squeeze_min = float(opts.get('squeeze', 0.78))
    vtop, vbot = int(opts.get('vtop', 0)), h - int(opts.get('vbot', 0))

    def fit(size):
        f_ = font(fpath, size)
        l_, t_, r_, b_ = f_.getbbox(vi, stroke_width=stroke)
        ct, cb = f_.getbbox('H')[1], f_.getbbox('H')[3]
        oy = cyy - (ct + cb) / 2.0
        top_, bot_ = oy + t_, oy + b_
        shift = 0.0
        if top_ < vtop:
            shift = vtop - top_
        elif bot_ > vbot:
            shift = vbot - bot_
        ok_v = (b_ - t_) <= (vbot - vtop) and (cb - ct) <= max(4, cap * ah + 0.5)
        return ok_v, r_ - l_, oy + shift

    round_info = None
    shadow = 0
    if rb is None:
        best = None
        size_max = int(opts.get('size', 0)) or max(7, int(round(ah * 1.6)))
        for size in range(size_max, 6, -1):
            ok_v, tw_, _oy = fit(size)
            if not ok_v and 'size' not in opts:
                continue
            if tw_ <= aw:
                best = (size, 1.0)
                break
            if tw_ * squeeze_min <= aw or 'size' in opts:
                best = (size, min(1.0, aw / float(tw_)))
                break
        if best is None:
            best = (7, min(1.0, aw / float(max(1, fit(7)[1]))))
        size, sq = best
        if stroke and 'stroke' not in opts and size < int(opts.get('stroke_min', 12)):
            stroke, shadow = 0, 1
        cx = (ax0 + ax1) / 2.0 + float(opts.get('dx', 0))
        oy = fit(size)[2]
    else:
        # round badge: every texel of the new label (marks and shadow included) inside core - margin; bigger sizes
        # first, a light squeeze, then the shorter alternatives of the registry (alt=A|B); never below minsize
        ccx, ccy = rb['center']
        core, dist = rb['core'], rb['dist']
        lim_r = core - float(opts.get('margin', 2))
        min_size = int(opts.get('minsize', 7))
        labels = [vi] + [s_ for s_ in opts.get('alt', '').split('|') if s_]
        stroke = 0
        chosen = None
        readable = int(opts.get('readable', 9))
        # pass 1: every label (full word first) at a readable size; pass 2: the same labels down to minsize
        # pass 3: the shortest label at minsize without the drop shadow (22 px badges)
        sh_default = int(opts.get('shadow', 1))
        # order: full word >= readable, full word >= readable-1, each shorter alternative >= readable, then minsize
        passes = ([(labels[0], readable, sh_default), (labels[0], readable - 1, sh_default)]
                  + [(lab_, readable, sh_default) for lab_ in labels[1:]]
                  + [(lab_, min_size, sh_default) for lab_ in labels] + [(labels[-1], min_size, 0)])
        for lab_, floor_, sh_ in passes:
            # a badge label is never bigger than the CY glyph it replaces (about the core diameter)
            start = int(opts.get('size', 0)) or max(floor_, min(int(round(2.2 * lim_r)), int(round(1.5 * core))))
            if 'size' in opts and floor_ != min_size:
                continue
            for size_ in range(start, floor_ - 1, -1):
                f_ = font(fpath, size_)
                bold_ = int(opts.get('bold', 1 if size_ >= 11 else 0))
                ct, cb = f_.getbbox('H')[1], f_.getbbox('H')[3]
                l_, t2, r_, b_ = f_.getbbox(lab_)
                for sq_ in (1.0, 0.92, 0.85):
                    fm_, sm_, cw_, ch_, t_ = text_masks(lab_, f_, 0, bold_, sh_, sq_, opts)
                    oy_ = ccy - ((ct + cb) / 2.0 + (t2 + b_) / 2.0) / 2.0 + float(opts.get('dy', 0))
                    fa_, sa_, _p = place_masks(fm_, sm_, cw_, ch_, ccx + float(opts.get('dx', 0)), oy_, t_, sq_, h, w)
                    cov = np.maximum(fa_, sa_) > 0.25
                    whole = int((np.maximum(fm_, sm_) > 0.25).sum())
                    if cov.any() and int(cov.sum()) == whole and float(dist[cov].max()) <= lim_r + 0.5:
                        chosen = (lab_, size_, sq_, oy_, True, sh_)
                        break
                if chosen or 'size' in opts:
                    break
            if chosen:
                break
        if chosen is None:
            f_ = font(fpath, min_size)
            chosen = (labels[-1], min_size, 0.85, ccy - (f_.getbbox('H')[1] + f_.getbbox('H')[3]) / 2.0, False, 0)
        vi, size, sq, oy, fits, shadow = chosen
        cx = ccx + float(opts.get('dx', 0))
        ax0, ax1 = 0, w
        round_info = {'core': round(core, 1), 'center': [round(ccx, 1), round(ccy, 1)], 'label': vi, 'fits': fits,
                      'alt_used': vi != labels[0]}
    if 'shadow' in opts:
        shadow = int(opts['shadow'])
    bold = int(opts.get('bold', 1 if size >= 11 else 0))
    f = font(fpath, size)
    fm, sm, cw, ch, t = text_masks(vi, f, stroke, bold, shadow, sq, opts)
    fa, sa, py0 = place_masks(fm, sm, cw, ch, cx, oy, t, sq, h, w)
    ty = np.clip((np.arange(h, dtype=np.float32) - py0) / max(1, ch - 1), 0, 1)[:, None, None]
    fill_col = col_top[None, None, :] * (1 - ty) + col_bot[None, None, :] * ty
    res = out.astype(np.float32)
    a_bg = res[..., 3:4] / 255.0
    col = res[..., :3]
    if stroke or shadow:
        s = sa[..., None] * float(opts.get('stroke_alpha', 1.0))
        col = col * (1 - s) + ringcol[None, None, :] * s
        a_bg = np.maximum(a_bg, s)
    fl = fa[..., None]
    col = col * (1 - fl) + fill_col * fl
    a_new = np.maximum(a_bg, fl)
    res[..., :3] = col
    res[..., 3:4] = a_new * 255.0
    new = np.clip(np.round(res), 0, 255).astype(np.uint8)
    qa = quality(crop, out, new, ink, er, np.maximum(fa, sa), box, (ax0, ax1), (vtop, vbot), round_info, fill_col,
                 opts)
    if round_info is not None:
        qa.update(round_info)
        # residual of a badge = glyph-like texels (far from the rebuilt plate) left outside the erased mask, in and
        # just around the core: the top-hat measure of plates does not apply to the radial background
        left = (rb['diff'] > rb['thr']) & ~er.astype(bool) & (rb['dist'] <= rb['core'] - 0.5)
        qa['residual'] = round(float(left.sum()) / max(1, int(ink.sum())), 3)
    return new, {'status': 'ok', 'box': box, 'size': size, 'squeeze': round(sq, 3), 'stroke': stroke,
                 'shadow': shadow, 'bold': bold, 'label': vi, 'qa': qa,
                 'ink': [int(v) for v in col_top], 'ring': [int(v) for v in ringcol], '_erase': er}


# ------------------------------------------------------------------------------------------------- generate
def _ref_name(names, opts):
    if 'ref' in opts:
        return opts['ref']
    for key in ('_Normal', 'Normal', '_Nor', '_A1', '_B1'):
        for n in names:
            if n.endswith(key) or key in n:
                return n
    return names[0]


MANIFEST_HEADER = ['texture', 'imageset', 'image', 'rect', 'zh', 'vi', 'paint', 'note', 'registry_line', 'qa', 'source',
                   'source_sha256', 'output_sha256', 'kind']


def generate(reader, gen_dir, registry=None, font_path=None, only=None, preview_dir=None):
    """Repaint every registry row into gen_dir. Returns (files [(rel 'InterfaceFolder\\...', path)], manifest rows,
    problems [(registry line, name, problem)], stats)."""
    idx = ImagesetIndex(reader=reader)
    rows = load_registry(registry or REGISTRY)
    if font_path is None:
        raise ValueError('font_path is required (Schema/NotoSansSC-Regular.ttf of the GUI layer)')
    by_tex = collections.OrderedDict()
    problems = []
    for row in rows:
        if only and row['imageset'] not in only:
            continue
        s = idx.imageset(row['imageset'])
        if s is None:
            problems.append((row['line'], row['imageset'], 'imageset not found'))
            continue
        try:
            names = match_images(row['images'], list(s[1]))
        except KeyError as ex:
            problems.append((row['line'], row['imageset'], 'image not found: %s' % ex))
            continue
        tex = reader.resolve(s[0])
        if tex is None:
            problems.append((row['line'], row['imageset'], 'texture not found: ' + s[0]))
            continue
        by_tex.setdefault(tex, []).append((row, names, s[1]))
    files, manifest = [], []
    stats = collections.Counter()
    prev = []
    qa_fail = []
    for tex, items in by_tex.items():
        src = reader.read(tex)
        px, kind = decode_image(src)
        orig = px.copy()
        done = np.zeros(px.shape[:2], bool)
        painted = set()
        tex_rows = []
        for row, names, rects in items:
            opts = row['opts']
            if 'ref' in opts:
                refn = opts['ref']
            else:
                # reference state = the one whose label is found most clearly (largest ink, not a line)
                refn, best = _ref_name(names, opts), -1
                for n in names:
                    x, y, w, h = rects[n]
                    if y + h > px.shape[0] or x + w > px.shape[1]:
                        continue
                    ink_, box_ = find_ink(orig[y:y + h, x:x + w], opts)
                    if box_ is not None and box_[3] - box_[1] >= min(5, h // 2) and int(ink_.sum()) > best:
                        refn, best = n, int(ink_.sum())
            rx, ry, rw, rh = rects[refn]
            ref_ink, ref_box = find_ink(orig[ry:ry + rh, rx:rx + rw], opts)
            ref_size = ref_core = ref_label = None
            for n in [refn] + [m for m in names if m != refn]:
                x, y, w, h = rects[n]
                if y + h > px.shape[0] or x + w > px.shape[1]:
                    problems.append((row['line'], n, 'rectangle outside the texture'))
                    continue
                if (x, y, w, h) in painted:
                    stats['shared_rect_skipped'] += 1      # two image names on one rectangle: painted once
                    continue
                crop = orig[y:y + h, x:x + w]
                o = dict(opts)
                if ref_box is not None and (w, h) == (rw, rh) and n != refn and 'box' not in opts:
                    bx0, by0, bx1, by1 = ref_box
                    o['box'] = '%d,%d,%d,%d' % (max(0, bx0 - 1), max(0, by0 - 1), min(w, bx1 + 1), min(h, by1 + 1))
                    o['keepborder'] = '1'
                label = row['vi']
                if ref_size is not None and (w, h) == (rw, rh) and 'size' not in opts:
                    o['size'] = str(ref_size)          # one text size for every state of the button
                    if ref_core is not None:           # round badges: same core, same (possibly shorter) label
                        o.setdefault('core', str(ref_core))
                        o.setdefault('shadow', str(ref_shadow))
                        o.pop('alt', None)
                        label = ref_label
                new, info = paint_label(crop, label, o, font_path)
                if info['status'] != 'ok':
                    problems.append((row['line'], n, info['status']))
                    stats['no_ink'] += 1
                    continue
                if n == refn:
                    ref_size, ref_core, ref_label = info['size'], info['qa'].get('core'), info['label']
                    ref_shadow = info['shadow']
                # CY rectangles may overlap by a few texels (TServerUI2 Bang_Xuanzhan_*): only changed texels are written
                changed = np.any(new != crop, axis=2)
                region = px[y:y + h, x:x + w]
                region[changed] = new[changed]
                done[y:y + h, x:x + w] |= changed
                painted.add((x, y, w, h))
                stats['images_painted'] += 1
                erase = info.pop('_erase')
                status = qa_status(n, info['qa'])
                stats['qa_ok' if status == 'ok' else 'qa_fail'] += 1
                if status != 'ok':
                    qa_fail.append((row['line'], row['imageset'] + ':' + n, status, json.dumps(info['qa'])))
                tex_rows.append([tex, row['imageset'], n, '%d,%d,%d,%d' % (x, y, w, h), row['zh'], info['label'],
                                 json.dumps(info, ensure_ascii=False), row['note'], row['line'], status])
                if preview_dir is not None:
                    mask = crop.copy()
                    mask[erase.astype(bool)] = (255, 0, 255, 255)
                    prev.append(('%s:%s  %s  (L%d)  QA %s  %s' % (row['imageset'], n, info['label'], row['line'], status,
                                                                json.dumps(info['qa'])), crop, new, mask))
        outside = ~done
        if not np.array_equal(px[outside], orig[outside]):
            raise AssertionError('pixels outside the painted rectangles changed: ' + tex)
        data = encode_image(px, kind)
        rel = 'InterfaceFolder\\' + tex.replace('/', '\\')
        dest = os.path.join(gen_dir, rel)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        old = None
        if os.path.exists(dest):
            with open(dest, 'rb') as f:
                old = f.read()
        if old != data:
            with open(dest + '.part', 'wb') as f:
                f.write(data)
            os.replace(dest + '.part', dest)
        files.append((rel, dest))
        stats['textures'] += 1
        ssha, osha = hashlib.sha256(src).hexdigest(), hashlib.sha256(data).hexdigest()
        for r in tex_rows:
            manifest.append(tuple(r) + (reader.origin(tex), ssha, osha, kind))
    if preview_dir is not None and prev:
        write_preview(prev, preview_dir, font_path)
        write_preview([p[:3] for p in prev], os.path.join(preview_dir, 'review-2x'), font_path, zoom=2, per=30)
    stats['problems'] = len(problems)
    for q in qa_fail:
        problems.append((q[0], q[1], 'qa ' + q[2] + ' ' + q[3]))
    return files, manifest, problems, dict(stats)


def write_tsv(path, header, rows):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\t'.join(header) + '\n')
        for r in rows:
            f.write('\t'.join(str(v).replace('\t', ' ') for v in r) + '\n')


def write_preview(items, out_dir, font_path, zoom=3, per=18):
    os.makedirs(out_dir, exist_ok=True)
    lab = font(font_path, 12)
    for s in range(0, len(items), per):
        part = items[s:s + per]
        width = max(420, min(2400, max(it[1].shape[1] for it in part) * zoom * (len(part[0]) - 1) + 60))
        heights = [it[1].shape[0] * zoom + 20 for it in part]
        sheet = Image.new('RGB', (width, sum(heights) + 4), (58, 58, 66))
        d = ImageDraw.Draw(sheet)
        yy = 2
        for it, hh in zip(part, heights):
            d.text((4, yy), it[0], font=lab, fill=(255, 255, 0))
            for k, im in enumerate(it[1:]):
                h, w = im.shape[:2]
                bg = Image.new('RGBA', (w, h), (34, 38, 46, 255))
                bg.alpha_composite(Image.fromarray(im, 'RGBA'))
                big = bg.resize((w * zoom, h * zoom), Image.NEAREST).convert('RGB')
                sheet.paste(big, (4 + k * (w * zoom + 16), yy + 16))
            yy += hh
        sheet.save(os.path.join(out_dir, 'preview-%03d.png' % (s // per)))


def main():
    ap = argparse.ArgumentParser(description='cy-gui-image-vi standalone')
    ap.add_argument('--ui', required=True, help='read-only InterfaceFolder holding the CY textures')
    ap.add_argument('--out', required=True, help='output root (writes <out>/InterfaceFolder/... + _manifest)')
    ap.add_argument('--registry', default=REGISTRY)
    ap.add_argument('--only', help='comma list of imagesets')
    ap.add_argument('--preview', action='store_true')
    a = ap.parse_args()
    if os.path.abspath(a.out).lower().startswith(os.path.abspath(a.ui).lower()):
        raise SystemExit('--out must not lie below --ui (sources are read only)')
    reader = DiskReader(a.ui)
    fp = os.path.join(a.ui, FONT_REL.replace('/', os.sep))
    files, manifest, problems, stats = generate(reader, a.out, a.registry, fp,
                                                set(a.only.split(',')) if a.only else None,
                                                os.path.join(a.out, '_preview') if a.preview else None)
    write_tsv(os.path.join(a.out, '_manifest', 'gui_image_vi.tsv'), MANIFEST_HEADER, manifest)
    write_tsv(os.path.join(a.out, '_manifest', 'gui_image_vi_problems.tsv'), ['registry_line', 'name', 'problem'],
              problems)
    print(json.dumps({'tool': TOOL, 'files': len(files), 'stats': stats, 'problems': problems[:20]},
                     ensure_ascii=False, indent=1))
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
