"""falagard_render.py - offline CEGUI/Falagard renderer for TLBB layouts (evidence only, read-only).

Draws a layout from the real scheme / looknfeel / imageset / texture data, following CEGUI 0.4.1
(CY-Source\\Src\\ThirdParty\\CEGUI-0.4.1) and the shipped TLBB widgets:
* WindowType -> FalagardMapping (last one wins) -> WidgetLook (a later looknfeel replaces an earlier one).
* FrameComponent: corners at image size, edges stretched between the corners, background inside the
  edges honouring Vert/HorzFormat (Stretched/Tiled/aligned). ImageryComponent: same formats
  (default Top/Left aligned). Colours (Section ref x ImagerySection x component) modulate.
* Areas: AbsoluteDim, UnifiedDim, ImageDim, WidgetDim, FontDim, PropertyDim with DimOperator.
* Static windows (StaticImage/BoundWindow/...): Image property, EnabledFrame (FrameEnabled),
  EnabledBackground (BackgroundEnabled), Enabled.  SimpleText/DragTitle: Enabled imagery, then text
  (the shipped FalagardSimpleText::populateRenderCache @1800500b0 renders the state imagery).
  Buttons/CheckBoxes: Normal (Pushed when Selected=True) + legacy NormalImage.  ActionButton:
  BackgroundImage + Normal.  SuperTooltip: Frame + Enabled.  Auto children (<Child>) are created.
* Text: Noto Sans SC from the skin, Size in points at 96 dpi (px = pt*4/3), 1 px dark edge,
  TLBB markup #R #G #B #K #Y #W #cRRGGBB #eRRGGBB #r ## #n #u #b #{KEY} #aB..#aE.
The roots list is searched in order, so a staged skin (folder with InterfaceFolder/MaterialFolder)
placed before the client Data folder overrides the client files exactly as an install would.

usage: falagard_render.py LAYOUT [--root DIR ...] [--screen W,H] [--out PNG] [--state JSON]
                          [--text Win=Text ...] [--bg PNG] [--crop auto|x,y,w,h]
"""
import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

DEF_ROOT = r"C:\TLBB\085\client_GL\Data"
COMMENT = re.compile(r"<!--.*?-->", re.S)
ATTR = re.compile(r'([A-Za-z_][\w:.-]*)\s*=\s*"([^"]*)"')
SETREF = re.compile(r'set:\s*([^\s"]+)\s+image:\s*([^\s"]+)')
NUM = r'\s*([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)\s*'
UNI = re.compile(r'\{\{' + NUM + ',' + NUM + r'\}\s*,\s*\{' + NUM + ',' + NUM + r'\}\}?')
UNI4 = re.compile(r'\{\{' + NUM + ',' + NUM + r'\}\s*,\s*\{' + NUM + ',' + NUM + r'\}\s*,\s*\{' + NUM + ',' + NUM + r'\}\s*,\s*\{' + NUM + ',' + NUM + r'\}\}?')
UNI1 = re.compile(r'\{' + NUM + ',' + NUM + r'\}')
ABSPOS = re.compile(r'x:' + NUM + r'y:' + NUM)
ABSSZ = re.compile(r'w:' + NUM + r'h:' + NUM)
ABSRECT = re.compile(r'l:' + NUM + r't:' + NUM + r'r:' + NUM + r'b:' + NUM)
TOKEN = re.compile(r'<Window\b([^>]*?)(/?)>|<Property\s+Name\s*=\s*"([^"]+)"\s+Value\s*=\s*"([^"]*)"\s*/?>|</Window\s*>')
XDIMS = ("LeftEdge", "RightEdge", "Width", "XPosition", "XOffset")
DIM_TAGS = ("AbsoluteDim", "UnifiedDim", "ImageDim", "WidgetDim", "FontDim", "PropertyDim")
SHORT = {"R": (255, 0, 0), "G": (0, 255, 0), "B": (0, 0, 255), "K": (0, 0, 0), "Y": (255, 255, 0), "W": (255, 255, 255)}
NATIVE_TEXT = ("Falagard/SimpleText", "Falagard/DragTitle", "Falagard/SuperTooltip/ResizeText", "Falagard/StaticText",
               "Falagard/IMEEditBox", "Falagard/SafeIMEEditBox", "Falagard/Editbox", "Falagard/MultiIMEEditBox")
SKIP_CONTENT = ("Falagard/SceneMap", "Falagard/WorldMap", "Falagard/MeshWindow", "Falagard/ChatHistory", "Falagard/ChatBoard",
                "Falagard/Radar", "Falagard/MiniMap", "Falagard/CreatureBoard", "Falagard/BeHidBoard", "Falagard/PS")
WHITE = ((1.0, 1.0, 1.0, 1.0),) * 4


def read_text(path):
    with open(path, "rb") as f:
        b = f.read()
    if b[:3] == b"\xef\xbb\xbf":
        b = b[3:]
    try:
        return b.decode("utf-8")
    except UnicodeDecodeError:
        return b.decode("gb18030", errors="replace")


def fnum(v, d=0.0):
    try:
        return float(v)
    except (TypeError, ValueError):
        return d


def parse_colour(s):
    """CEGUI colour string: 'AARRGGBB' or 'tl:AARRGGBB tr:.. bl:.. br:..' -> 4 corner RGBA floats."""
    if not s:
        return None
    s = s.strip()
    m = re.findall(r'(tl|tr|bl|br):\s*([0-9a-fA-F]{8})', s)
    if m:
        d = {k: v for k, v in m}
        return tuple(_c8(d.get(k, "FFFFFFFF")) for k in ("tl", "tr", "bl", "br"))
    m = re.search(r'[0-9a-fA-F]{8}', s)
    if m:
        c = _c8(m.group(0))
        return (c, c, c, c)
    return None


def _c8(h):
    v = int(h, 16)
    return (((v >> 16) & 255) / 255.0, ((v >> 8) & 255) / 255.0, (v & 255) / 255.0, ((v >> 24) & 255) / 255.0)


def cmul(a, b):
    if a is None:
        return b
    if b is None:
        return a
    return tuple(tuple(x * y for x, y in zip(p, q)) for p, q in zip(a, b))


def cols_of(el):
    """<Colours topLeft=.. topRight=.. bottomLeft=.. bottomRight=..> child of el."""
    c = el.find("Colours") if el is not None else None
    if c is None:
        return None
    return tuple(_c8(c.get(k, "FFFFFFFF")) for k in ("topLeft", "topRight", "bottomLeft", "bottomRight"))


class LookDef:
    __slots__ = ("name", "src", "props", "propdefs", "sections", "states", "named", "children")

    def __init__(self, el, src):
        self.name, self.src = el.get("name"), src
        self.props, self.propdefs, self.sections, self.states, self.named, self.children = {}, {}, {}, {}, {}, []
        for c in el:
            t = c.tag
            if t == "Property":
                k = c.get("name") or c.get("Name")
                v = c.get("value") if c.get("value") is not None else c.get("Value")
                if k:
                    self.props[k] = v or ""
            elif t in ("PropertyDefinition", "PropertyLinkDefinition"):
                self.propdefs[c.get("name")] = c.get("initialValue", "")
            elif t == "ImagerySection":
                self.sections[c.get("name")] = c
            elif t == "StateImagery":
                self.states[c.get("name")] = c
            elif t == "NamedArea":
                self.named[c.get("name")] = c.find("Area")
            elif t == "Child":
                self.children.append(c)


class Skin:
    """Scheme + looks + imagesets + textures + fonts resolved over a list of Data-like roots."""

    def __init__(self, roots, autoscale=False):
        self.roots = [r for r in roots if r]
        self.autoscale = autoscale
        self.notes = []
        sch = self.find("InterfaceFolder/Schema/WoWLookSkin.scheme.xml")
        if not sch:
            raise FileNotFoundError("scheme not found in %s" % self.roots)
        text = COMMENT.sub("", read_text(sch))
        self.imageset_files, self.lnf_files, self.mapping, self.alias, font_files = {}, [], {}, {}, {}
        for m in re.finditer(r"<(Imageset|LookNFeel|FalagardMapping|WindowAlias|Font)\b([^>]*)>", text):
            a = dict(ATTR.findall(m.group(2)))
            k = m.group(1)
            if k == "Imageset" and "Name" in a:
                self.imageset_files[a["Name"]] = a.get("Filename", "")
            elif k == "LookNFeel" and "Filename" in a:
                self.lnf_files.append(a["Filename"])
            elif k == "FalagardMapping" and "WindowType" in a:
                self.mapping[a["WindowType"]] = (a.get("TargetType", ""), a.get("LookNFeel", ""))
            elif k == "WindowAlias" and "Alias" in a:
                self.alias[a["Alias"]] = a.get("Target", "")
            elif k == "Font" and "Name" in a:
                font_files[a["Name"]] = a.get("Filename", "")
        self.looks = {}
        for rel in self.lnf_files:
            p = self.find("InterfaceFolder/" + rel)
            if not p:
                self.notes.append("missing looknfeel " + rel)
                continue
            self._load_lnf(p, rel)
        self.font_pt = {}
        for name, rel in font_files.items():
            p = self.find("InterfaceFolder/" + rel)
            if not p:
                continue
            t = read_text(p)
            m = re.search(r'<Font\b[^>]*\bSize="([0-9.]+)"[^>]*CodePage="65001"', t) or re.search(r'<Font\b[^>]*\bSize="([0-9.]+)"', t)
            if m:
                self.font_pt[name] = float(m.group(1))
        self.noto = self.find("InterfaceFolder/Schema/NotoSansSC-Regular.ttf") or "C:/Windows/Fonts/arial.ttf"
        self._sets, self._tex, self._crop, self._fonts, self._strs, self._rs = {}, {}, {}, {}, None, {}

    def find(self, rel):
        rel = rel.replace("/", os.sep).replace("\\", os.sep)
        for r in self.roots:
            p = os.path.join(r, rel)
            if os.path.isfile(p):
                return p
        return None

    def _load_lnf(self, path, rel):
        text = COMMENT.sub("", read_text(path))
        text = re.sub(r"^\s*<\?xml[^>]*\?>", "", text)
        try:
            root = ET.fromstring(text)
            els = root.findall("WidgetLook")
        except ET.ParseError as ex:
            self.notes.append("looknfeel parse fallback %s: %s" % (rel, ex))
            els = []
            for m in re.finditer(r"<WidgetLook\b.*?</WidgetLook\s*>", text, re.S):
                try:
                    els.append(ET.fromstring(m.group(0)))
                except ET.ParseError:
                    pass
        for el in els:
            self.looks[el.get("name")] = LookDef(el, rel)

    # ------------------------------------------------------------------ images
    def imageset(self, name):
        if name not in self._sets:
            info = None
            rel = self.imageset_files.get(name)
            p = self.find("InterfaceFolder/" + rel) if rel else None
            if p:
                t = read_text(p)
                head = re.search(r"<Imageset\b([^>]*)>", t)
                a = dict(ATTR.findall(head.group(1))) if head else {}
                imgs = {}
                for m in re.finditer(r"<Image\b([^>]*?)/?>", t):
                    b = dict(ATTR.findall(m.group(1)))
                    if "Name" in b:
                        imgs[b["Name"]] = (int(fnum(b.get("XPos"))), int(fnum(b.get("YPos"))), int(fnum(b.get("Width"))),
                                           int(fnum(b.get("Height"))), fnum(b.get("XOffset")), fnum(b.get("YOffset")))
                info = dict(file=a.get("Imagefile", ""), images=imgs, auto=a.get("AutoScaled", "false").lower() == "true",
                            native=(fnum(a.get("NativeHorzRes"), 1024.0), fnum(a.get("NativeVertRes"), 768.0)))
            self._sets[name] = info
        return self._sets[name]

    def texture(self, rel):
        if rel not in self._tex:
            p = self.find("MaterialFolder/" + rel) or self.find("InterfaceFolder/" + rel)
            im = None
            if p:
                try:
                    im = Image.open(p).convert("RGBA")
                except Exception as ex:
                    self.notes.append("texture %s: %s" % (rel, ex))
            else:
                self.notes.append("missing texture " + rel)
            self._tex[rel] = im
        return self._tex[rel]

    def image(self, setname, name):
        k = (setname, name)
        if k not in self._crop:
            s = self.imageset(setname)
            im = None
            if s and name in s["images"]:
                tex = self.texture(s["file"])
                if tex is not None:
                    x, y, w, h = s["images"][name][:4]
                    im = tex.crop((x, y, x + w, y + h))
            if im is None:
                self.notes.append("missing image %s:%s" % k)
            self._crop[k] = im
        return self._crop[k]

    def image_size(self, setname, name, screen=None):
        s = self.imageset(setname)
        if not s or name not in s["images"]:
            return None
        x, y, w, h, ox, oy = s["images"][name]
        if self.autoscale and s["auto"] and screen:
            return (x, y, w * screen[0] / s["native"][0], h * screen[1] / s["native"][1], ox, oy)
        return (x, y, w, h, ox, oy)

    def ref(self, v):
        m = SETREF.search(v or "")
        return (m.group(1), m.group(2)) if m else None

    # ------------------------------------------------------------------ text
    def font(self, name):
        pt = self.font_pt.get(name or "", self.font_pt.get("SongTiBmp12", 12.0))
        px = max(6, int(round(pt * 96.0 / 72.0)))
        if px not in self._fonts:
            self._fonts[px] = ImageFont.truetype(self.noto, px)
        return self._fonts[px]

    def strdict(self, key):
        if self._strs is None:
            self._strs = {}
            p = self.find("ConfigFolder/StrDictionary.txt")
            if p:
                for line in open(p, encoding="utf-8", errors="replace"):
                    q = line.rstrip("\r\n").split("\t")
                    if len(q) >= 2:
                        self._strs.setdefault(q[0], q[1])
        return self._strs.get(key)

    def resolve(self, raw):
        if not raw:
            return ""
        return re.sub(r"#\{([^}]+)\}", lambda m: self.strdict(m.group(1)) or m.group(0), raw)


def segments(txt, base=(255, 255, 255)):
    """TLBB markup -> [(text, rgb, edge_rgb or None)]; '\n' kept inside text."""
    out, col, edge, buf, i = [], base, None, "", 0
    while i < len(txt):
        ch = txt[i]
        if ch == "#" and i + 1 < len(txt):
            k = txt[i + 1]
            if k == "g" and re.fullmatch(r"[0-9a-fA-F]{6}", txt[i + 2:i + 8] or ""):
                # #gRGBRGB: vertical gradient, two 3-digit colours (title strings use #gFF0FA0)
                if buf:
                    out.append((buf, col, edge))
                    buf = ""
                h = txt[i + 2:i + 8]
                col = (tuple(int(c, 16) * 17 for c in h[:3]), tuple(int(c, 16) * 17 for c in h[3:]))
                i += 8
                continue
            if k in SHORT or k in "ce" or k in "bunr#a" or k.isdigit() or k == "-":
                if k == "#":
                    buf += "#"
                    i += 2
                    continue
                if buf:
                    out.append((buf, col, edge))
                    buf = ""
                if k in SHORT:
                    col = SHORT[k]
                    i += 2
                elif k in "ce":
                    h = txt[i + 2:i + 8]
                    if re.fullmatch(r"[0-9a-fA-F]{6}", h):
                        rgb = tuple(int(h[j:j + 2], 16) for j in (0, 2, 4))
                        if k == "c":
                            col = rgb
                        else:
                            edge = rgb
                        i += 8
                    else:
                        i += 2
                elif k == "r":
                    buf += "\n"
                    i += 2
                elif k == "n":
                    col, edge = base, None
                    i += 2
                elif k == "a":
                    m = re.match(r"#aB\{[^}]*\}|#aE|#a", txt[i:])
                    i += len(m.group(0)) if m else 2
                elif k == "-":
                    m = re.match(r"#-\d{1,2}", txt[i:])
                    i += len(m.group(0)) if m else 1
                elif k.isdigit():
                    m = re.match(r"#\d{1,2}", txt[i:])
                    i += len(m.group(0))
                else:
                    i += 2
                continue
        buf += ch
        i += 1
    if buf:
        out.append((buf, col, edge))
    return out


class Node:
    __slots__ = ("type", "name", "props", "children", "parent", "auto", "childdef")

    def __init__(self, type_, name, parent):
        self.type, self.name, self.parent = type_, name, parent
        self.props, self.children, self.auto, self.childdef = {}, [], False, None


def parse_layout(path):
    text = COMMENT.sub("", read_text(path))
    roots, stack = [], []
    for m in TOKEN.finditer(text):
        if m.group(1) is not None:
            a = dict(ATTR.findall(m.group(1)))
            n = Node(a.get("Type", ""), a.get("Name", ""), stack[-1] if stack else None)
            (n.parent.children if n.parent else roots).append(n)
            if m.group(2) != "/":
                stack.append(n)
        elif m.group(3) is not None:
            if stack:
                stack[-1].props[m.group(3)] = m.group(4)
        elif stack:
            stack.pop()
    return roots


class Ctx:
    """Evaluation context of one window for Dims/Areas."""
    __slots__ = ("r", "node", "w", "h", "rects", "look")

    def __init__(self, r, node, rect, look):
        self.r, self.node, self.look = r, node, look
        self.w, self.h = rect[2], rect[3]
        self.rects = r.rects

    def prop(self, k, d=None):
        return self.r.prop(self.node, self.look, k, d)

    def widget_rect(self, suffix):
        me = self.rects.get(self.node)
        if suffix:
            for c in self.node.children:
                if c.name == self.node.name + suffix and c in self.rects:
                    cx, cy, cw, ch = self.rects[c]
                    return (cx - me[0], cy - me[1], cw, ch)
        return (0, 0, self.w, self.h)


class Renderer:
    def __init__(self, skin, screen=(1920, 1080), state=None, selected_state="Normal"):
        self.s, self.screen = skin, screen
        self.state = state or {}
        self.hide = set(self.state.get("hide", []))
        self.show = set(self.state.get("show", []))
        self.texts = dict(self.state.get("text", {}))
        self.rects = {}
        self.notes = []
        self._rcache = {}

    # ------------------------------------------------------------------ helpers
    def resolve_type(self, t):
        t2 = self.s.alias.get(t, t)
        return self.s.mapping.get(t2, ("", ""))

    def look_of(self, node):
        tt, lk = self.resolve_type(node.type)
        return tt, self.s.looks.get(lk)

    def prop(self, node, look, k, d=None):
        if k in node.props:
            return node.props[k]
        if look is not None:
            if k in look.props:
                return look.props[k]
            if k in look.propdefs:
                return look.propdefs[k]
        return d

    def eval_dim(self, el, ctx):
        t = el.tag
        if t == "AbsoluteDim":
            v = fnum(el.get("value"))
        elif t == "UnifiedDim":
            base = ctx.w if el.get("type", "") in XDIMS else ctx.h
            v = fnum(el.get("scale")) * base + fnum(el.get("offset"))
        elif t == "ImageDim":
            info = self.s.image_size(el.get("imageset"), el.get("image"), self.screen)
            d = el.get("dimension", "Width")
            if info is None:
                v = 0.0
            else:
                x, y, w, h, ox, oy = info
                v = {"Width": w, "Height": h, "XOffset": ox, "YOffset": oy, "LeftEdge": x, "XPosition": x, "TopEdge": y,
                     "YPosition": y, "RightEdge": x + w, "BottomEdge": y + h}.get(d, w)
        elif t == "WidgetDim":
            x, y, w, h = ctx.widget_rect(el.get("widget", ""))
            v = {"Width": w, "Height": h, "LeftEdge": x, "XPosition": x, "TopEdge": y, "YPosition": y, "RightEdge": x + w,
                 "BottomEdge": y + h}.get(el.get("dimension", "Width"), w)
        elif t == "FontDim":
            fnt = self.s.font(el.get("font") or ctx.prop("Font"))
            if el.get("type") == "HorzExtent":
                v = fnt.getlength(el.get("string") or self.s.resolve(ctx.node.props.get("Text", "")))
            else:
                v = fnt.size * 1.25
            v += fnum(el.get("padding"))
        elif t == "PropertyDim":
            v = fnum(ctx.prop(el.get("name")), 0.0)
        else:
            v = 0.0
        op = el.find("DimOperator")
        if op is not None:
            sub = next((c for c in op if c.tag in DIM_TAGS), None)
            if sub is not None:
                o = self.eval_dim(sub, ctx)
                k = op.get("op", "Add")
                v = v + o if k == "Add" else v - o if k == "Subtract" else v * o if k == "Multiply" else (v / o if o else 0.0)
        return v

    def eval_area(self, area, ctx):
        if area is None:
            return (0.0, 0.0, ctx.w, ctx.h)
        d = {}
        for dim in area.findall("Dim"):
            sub = next((c for c in dim if c.tag in DIM_TAGS), None)
            d[dim.get("type")] = self.eval_dim(sub, ctx) if sub is not None else 0.0
        l = d.get("LeftEdge", d.get("XPosition", 0.0))
        t = d.get("TopEdge", d.get("YPosition", 0.0))
        w = d["Width"] if "Width" in d else (d["RightEdge"] - l if "RightEdge" in d else ctx.w - l)
        h = d["Height"] if "Height" in d else (d["BottomEdge"] - t if "BottomEdge" in d else ctx.h - t)
        return (l, t, w, h)

    # ------------------------------------------------------------------ geometry
    def layout_rect(self, n, parent):
        pw, ph = parent[2], parent[3]
        p = n.props
        absmode = p.get("MetricsMode", "").lower() == "absolute"
        x = y = 0.0
        w, h = pw, ph
        v = p.get("UnifiedAreaRect")
        m = UNI4.search(v) if v else None
        if m:
            a = list(map(float, m.groups()))
            x, y = a[0] * pw + a[1], a[2] * ph + a[3]
            w, h = a[4] * pw + a[5] - x, a[6] * ph + a[7] - y
            return (parent[0] + x, parent[1] + y, w, h)
        pos = size = None
        if p.get("UnifiedPosition") and UNI.search(p["UnifiedPosition"]):
            pos = tuple(map(float, UNI.search(p["UnifiedPosition"]).groups()))
        elif p.get("AbsolutePosition") and ABSPOS.search(p["AbsolutePosition"]):
            mm = ABSPOS.search(p["AbsolutePosition"])
            pos = (0.0, float(mm.group(1)), 0.0, float(mm.group(2)))
        elif p.get("Position") and ABSPOS.search(p["Position"]):
            mm = ABSPOS.search(p["Position"])
            pos = (0.0, float(mm.group(1)), 0.0, float(mm.group(2))) if absmode else (float(mm.group(1)), 0.0, float(mm.group(2)), 0.0)
        elif p.get("UnifiedXPosition") or p.get("UnifiedYPosition"):
            mx = UNI1.search(p.get("UnifiedXPosition", "{0,0}"))
            my = UNI1.search(p.get("UnifiedYPosition", "{0,0}"))
            pos = (float(mx.group(1)), float(mx.group(2)), float(my.group(1)), float(my.group(2)))
        if p.get("UnifiedSize") and UNI.search(p["UnifiedSize"]):
            size = tuple(map(float, UNI.search(p["UnifiedSize"]).groups()))
        elif p.get("AbsoluteSize") and ABSSZ.search(p["AbsoluteSize"]):
            mm = ABSSZ.search(p["AbsoluteSize"])
            size = (0.0, float(mm.group(1)), 0.0, float(mm.group(2)))
        elif p.get("Size") and ABSSZ.search(p["Size"]):
            mm = ABSSZ.search(p["Size"])
            size = (0.0, float(mm.group(1)), 0.0, float(mm.group(2))) if absmode else (float(mm.group(1)), 0.0, float(mm.group(2)), 0.0)
        elif p.get("UnifiedWidth") or p.get("UnifiedHeight"):
            mw = UNI1.search(p.get("UnifiedWidth", "{1,0}"))
            mh = UNI1.search(p.get("UnifiedHeight", "{1,0}"))
            size = (float(mw.group(1)), float(mw.group(2)), float(mh.group(1)), float(mh.group(2)))
        if p.get("AbsoluteRect") and ABSRECT.search(p["AbsoluteRect"]):
            mm = list(map(float, ABSRECT.search(p["AbsoluteRect"]).groups()))
            return (parent[0] + mm[0], parent[1] + mm[1], mm[2] - mm[0], mm[3] - mm[1])
        if size is not None:
            w, h = size[0] * pw + size[1], size[2] * ph + size[3]
        if pos is not None:
            x, y = pos[0] * pw + pos[1], pos[2] * ph + pos[3]
        return (parent[0] + x, parent[1] + y, w, h)

    def build(self, roots):
        """create auto children and compute absolute rects (parents first)."""
        def expand(n):
            tt, look = self.look_of(n)
            if look is not None and look.children and not n.children_auto_done if False else (look is not None and look.children):
                autos = []
                for cd in look.children:
                    c = Node(cd.get("type", ""), n.name + cd.get("nameSuffix", ""), n)
                    c.auto, c.childdef = True, cd
                    for pe in cd.findall("Property"):
                        k = pe.get("name") or pe.get("Name")
                        if k:
                            c.props[k] = pe.get("value") if pe.get("value") is not None else pe.get("Value", "")
                    autos.append(c)
                existing = {c.name for c in n.children}
                n.children[:0] = [c for c in autos if c.name not in existing]
            for c in list(n.children):
                if c.auto and c.children == [] and c.childdef is not None:
                    pass
                expand_child(c)

        seen = set()

        def expand_child(c):
            if id(c) in seen:
                return
            seen.add(id(c))
            expand(c)

        for r0 in roots:
            expand_child(r0)
        screen_rect = (0.0, 0.0, float(self.screen[0]), float(self.screen[1]))

        def place(n, parent_rect, parent_node):
            if n.auto and parent_node is not None:
                ptt, plook = self.look_of(parent_node)
                ctx = Ctx(self, parent_node, parent_rect, plook)
                x, y, w, h = self.eval_area(n.childdef.find("Area"), ctx)
                self.rects[n] = (parent_rect[0] + x, parent_rect[1] + y, w, h)
            else:
                self.rects[n] = self.layout_rect(n, parent_rect)
            for c in n.children:
                place(c, self.rects[n], n)

        for r0 in roots:
            place(r0, screen_rect, None)

    # ------------------------------------------------------------------ drawing primitives
    def blit(self, canvas, img, x, y, w, h, clip, col=None, alpha=1.0):
        if img is None or w <= 0.01 or h <= 0.01:
            return
        X0, Y0, X1, Y1 = int(round(x)), int(round(y)), int(round(x + w)), int(round(y + h))
        if X1 <= X0 or Y1 <= Y0:
            return
        ix0, iy0, ix1, iy1 = max(X0, clip[0]), max(Y0, clip[1]), min(X1, clip[2]), min(Y1, clip[3])
        if ix1 <= ix0 or iy1 <= iy0:
            return
        key = (id(img), X1 - X0, Y1 - Y0)
        im = self._rcache.get(key)
        if im is None:
            im = img if img.size == (X1 - X0, Y1 - Y0) else img.resize((X1 - X0, Y1 - Y0), Image.BILINEAR)
            if len(self._rcache) > 4000:
                self._rcache.clear()
            self._rcache[key] = im
        if (col is not None and col != WHITE) or alpha < 0.999:
            a = np.asarray(im).astype(np.float32)
            c = col or WHITE
            top = np.array([(c[0][k] + c[1][k]) * 0.5 for k in range(4)], np.float32)
            bot = np.array([(c[2][k] + c[3][k]) * 0.5 for k in range(4)], np.float32)
            t = np.linspace(0.0, 1.0, a.shape[0], dtype=np.float32)[:, None, None]
            mul = top[None, None, :] * (1 - t) + bot[None, None, :] * t
            mul[..., 3] *= alpha
            im = Image.fromarray(np.clip(a * mul, 0, 255).astype(np.uint8), "RGBA")
        canvas.alpha_composite(im.crop((ix0 - X0, iy0 - Y0, ix1 - X0, iy1 - Y0)), (ix0, iy0))

    def draw_formatted(self, canvas, img, rect, hf, vf, clip, col, alpha):
        if img is None:
            return
        x, y, w, h = rect
        iw, ih = img.size
        cl = (max(clip[0], int(round(x))), max(clip[1], int(round(y))), min(clip[2], int(round(x + w))), min(clip[3], int(round(y + h))))
        if hf == "Stretched":
            xs, tw, nx = [x], w, 1
        elif hf == "Tiled":
            nx = max(1, int((w + iw - 1) // iw)) if iw else 1
            xs, tw = [x + i * iw for i in range(nx)], iw
        else:
            tw, nx = iw, 1
            xs = [x] if hf in ("LeftAligned", "") else ([x + (w - iw) / 2.0] if hf == "CentreAligned" else [x + w - iw])
        if vf == "Stretched":
            ys, th = [y], h
        elif vf == "Tiled":
            ny = max(1, int((h + ih - 1) // ih)) if ih else 1
            ys, th = [y + i * ih for i in range(ny)], ih
        else:
            th = ih
            ys = [y] if vf in ("TopAligned", "") else ([y + (h - ih) / 2.0] if vf == "CentreAligned" else [y + h - ih])
        for yy in ys:
            for xx in xs:
                self.blit(canvas, img, xx, yy, tw, th, cl, col, alpha)

    # ------------------------------------------------------------------ Falagard components
    def fmt_of(self, comp, ctx, tag, default):
        e = comp.find(tag + "Format")
        if e is not None:
            return self._norm_fmt(e.get("type", default))
        e = comp.find(tag + "FormatProperty")
        if e is not None:
            return self._norm_fmt(ctx.prop(e.get("name"), default))
        return default

    @staticmethod
    def _norm_fmt(v):
        v = (v or "").replace("Horz", "").replace("Vert", "")
        return {"Centred": "CentreAligned", "Centered": "CentreAligned", "CentreAligned": "CentreAligned", "Stretched": "Stretched",
                "Tiled": "Tiled", "LeftAligned": "LeftAligned", "RightAligned": "RightAligned", "TopAligned": "TopAligned",
                "BottomAligned": "BottomAligned", "Justified": "LeftAligned"}.get(v, v)

    def draw_section_ref(self, canvas, look, ref, ctx, ox, oy, clip, mod, alpha):
        lk = ref.get("look") or (look.name if look else None)
        L = self.s.looks.get(lk)
        sec = L.sections.get(ref.get("section")) if L else None
        if sec is None:
            if ref.get("section"):
                self.notes.append("missing section %s/%s" % (lk, ref.get("section")))
            return
        col = cmul(cmul(mod, cols_of(ref)), cols_of(sec))
        cp = ref.find("ColourProperty")
        if cp is not None:
            col = cmul(col, parse_colour(ctx.prop(cp.get("name"))))
        for comp in sec:
            if comp.tag == "FrameComponent":
                self.draw_frame(canvas, comp, ctx, ox, oy, clip, col, alpha)
            elif comp.tag == "ImageryComponent":
                self.draw_imagery(canvas, comp, ctx, ox, oy, clip, col, alpha)
            elif comp.tag == "TextComponent":
                self.draw_textcomp(canvas, comp, ctx, ox, oy, clip, col, alpha)

    def draw_state(self, canvas, look, state, ctx, ox, oy, clip, alpha):
        si = look.states.get(state) if look else None
        if si is None:
            return False
        if (si.get("clipped") or "true").lower() == "false":
            clip = self._parent_clip(ctx.node)
        for layer in si.findall("Layer"):
            for ref in layer.findall("Section"):
                self.draw_section_ref(canvas, look, ref, ctx, ox, oy, clip, None, alpha)
        return True

    def draw_frame(self, canvas, comp, ctx, ox, oy, clip, col, alpha):
        x, y, w, h = self.eval_area(comp.find("Area"), ctx)
        X, Y = ox + x, oy + y
        col = cmul(col, cols_of(comp))
        imgs = {}
        for e in comp.findall("Image"):
            # FalagardXMLHelper::stringToFrameImageComponent: unknown/missing type -> FIC_BACKGROUND
            t = e.get("type") or "Background"
            imgs[t] = self.s.image(e.get("imageset"), e.get("image"))
        g = imgs.get
        topOff = leftOff = rightOff = botOff = 0.0
        topW = botW = w
        leftH = rightH = h
        TL, TR, BL, BR = g("TopLeftCorner"), g("TopRightCorner"), g("BottomLeftCorner"), g("BottomRightCorner")
        if TL is not None:
            self.blit(canvas, TL, X, Y, TL.width, TL.height, clip, col, alpha)
            topOff += TL.width
            leftOff += TL.height
            topW -= topOff
            leftH -= leftOff
        if TR is not None:
            self.blit(canvas, TR, X + w - TR.width, Y, TR.width, TR.height, clip, col, alpha)
            rightOff += TR.height
            topW -= TR.width
            rightH -= rightOff
        if BL is not None:
            self.blit(canvas, BL, X, Y + h - BL.height, BL.width, BL.height, clip, col, alpha)
            botOff += BL.width
            botW -= botOff
            leftH -= BL.height
        if BR is not None:
            self.blit(canvas, BR, X + w - BR.width, Y + h - BR.height, BR.width, BR.height, clip, col, alpha)
            botW -= BR.width
            rightH -= BR.height
        bl, bt, br, bb = X, Y, X + w, Y + h
        T, B, L, R = g("TopEdge"), g("BottomEdge"), g("LeftEdge"), g("RightEdge")
        if T is not None:
            self.blit(canvas, T, X + topOff, Y, topW, T.height, clip, col, alpha)
            bt += T.height
        if B is not None:
            self.blit(canvas, B, X + botOff, Y + h - B.height, botW, B.height, clip, col, alpha)
            bb -= B.height
        if L is not None:
            self.blit(canvas, L, X, Y + leftOff, L.width, leftH, clip, col, alpha)
            bl += L.width
        if R is not None:
            self.blit(canvas, R, X + w - R.width, Y + rightOff, R.width, rightH, clip, col, alpha)
            br -= R.width
        bg = g("Background")
        if bg is not None:
            self.draw_formatted(canvas, bg, (bl, bt, br - bl, bb - bt), self.fmt_of(comp, ctx, "Horz", "Stretched"),
                                self.fmt_of(comp, ctx, "Vert", "Stretched"), clip, col, alpha)

    def draw_imagery(self, canvas, comp, ctx, ox, oy, clip, col, alpha):
        x, y, w, h = self.eval_area(comp.find("Area"), ctx)
        e = comp.find("Image")
        img = None
        if e is not None:
            img = self.s.image(e.get("imageset"), e.get("image"))
        else:
            e = comp.find("ImageProperty")
            if e is not None:
                r = self.s.ref(ctx.prop(e.get("name")))
                img = self.s.image(*r) if r else None
        col = cmul(col, cols_of(comp))
        cp = comp.find("ColourProperty")
        if cp is not None:
            col = cmul(col, parse_colour(ctx.prop(cp.get("name"))))
        self.draw_formatted(canvas, img, (ox + x, oy + y, w, h), self.fmt_of(comp, ctx, "Horz", "LeftAligned"),
                            self.fmt_of(comp, ctx, "Vert", "TopAligned"), clip, col, alpha)

    def draw_textcomp(self, canvas, comp, ctx, ox, oy, clip, col, alpha):
        n = ctx.node
        raw = self.texts.get(n.name, n.props.get("Text", ""))
        te = comp.find("Text")
        if te is not None and te.get("string"):
            raw = te.get("string")
        if not raw:
            return
        x, y, w, h = self.eval_area(comp.find("Area"), ctx)
        col = cmul(col, cols_of(comp))
        c = (col or WHITE)[0]
        base = tuple(int(255 * c[k]) for k in range(3))
        fnt = self.s.font((te.get("font") if te is not None else None) or ctx.prop("Font"))
        self.draw_text(canvas, raw, fnt, (ox + x, oy + y, w, h), self.fmt_of(comp, ctx, "Horz", "LeftAligned"),
                       self.fmt_of(comp, ctx, "Vert", "TopAligned"), clip, base, alpha * c[3])

    def draw_text(self, canvas, raw, fnt, rect, hf, vf, clip, base=(255, 255, 255), alpha=1.0):
        txt = self.s.resolve(raw)
        if not txt:
            return
        x, y, w, h = rect
        segs = segments(txt, base)
        d = ImageDraw.Draw(canvas)
        lines, cur = [[]], 0.0
        wrap = "WordWrap" in (hf or "")
        for t, col, edge in segs:
            parts = t.split("\n")
            for pi, part in enumerate(parts):
                if pi > 0:
                    lines.append([])
                    cur = 0.0
                if not wrap:
                    lines[-1].append((part, col, edge))
                    cur += fnt.getlength(part)
                    continue
                for wi, word in enumerate(part.split(" ")):
                    piece = (" " if wi > 0 else "") + word
                    pw = fnt.getlength(piece)
                    if lines[-1] and cur + pw > w and cur > 0:
                        lines.append([(word, col, edge)])
                        cur = fnt.getlength(word)
                    else:
                        lines[-1].append((piece, col, edge))
                        cur += pw
        lh = round(fnt.size * 1.625) if len(lines) > 1 else fnt.size
        asc, desc = fnt.getmetrics()
        th = lh * (len(lines) - 1) + asc + desc
        if "Top" in (vf or ""):
            ty = y
        elif "Bottom" in (vf or ""):
            ty = y + h - th
        else:
            ty = y + (h - th) / 2.0
        layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        for ln in lines:
            lw = sum(fnt.getlength(t) for t, _, _ in ln)
            hfk = hf or ""
            tx = x + (w - lw) / 2.0 if ("Centre" in hfk or "Centred" in hfk) else (x + w - lw if "Right" in hfk else x)
            for t, col, edge in ln:
                ec = (edge + (230,)) if edge else (0, 0, 0, 170)
                for dx, dy in ((1, 1), (-1, 0), (1, 0), (0, -1), (0, 1)):
                    ld.text((tx + dx, ty + dy), t, font=fnt, fill=ec)
                if isinstance(col[0], tuple):
                    c1, c2 = col
                    gw, gh = int(fnt.getlength(t)) + 4, asc + desc + 4
                    m = Image.new("L", (gw, gh), 0)
                    ImageDraw.Draw(m).text((2, 2), t, font=fnt, fill=255)
                    ramp = np.linspace(0.0, 1.0, gh, dtype=np.float32)[:, None]
                    g = np.zeros((gh, gw, 4), np.uint8)
                    for k in range(3):
                        g[..., k] = (c1[k] * (1 - ramp) + c2[k] * ramp).astype(np.uint8)
                    g[..., 3] = np.asarray(m)
                    px, py = int(round(tx)) - 2, int(round(ty)) - 2
                    if px >= 0 and py >= 0:
                        layer.alpha_composite(Image.fromarray(g, "RGBA"), (px, py))
                else:
                    ld.text((tx, ty), t, font=fnt, fill=tuple(col) + (255,))
                tx += fnt.getlength(t)
            ty += lh
        cx0, cy0, cx1, cy1 = clip
        if cx1 <= cx0 or cy1 <= cy0:
            return
        part = layer.crop((cx0, cy0, cx1, cy1))
        if alpha < 0.999:
            a = np.asarray(part).copy()
            a[..., 3] = (a[..., 3] * alpha).astype(np.uint8)
            part = Image.fromarray(a, "RGBA")
        canvas.alpha_composite(part, (cx0, cy0))

    # ------------------------------------------------------------------ windows
    def visible(self, n, root_set):
        while n is not None:
            if n.name in self.hide:
                return False
            if n not in root_set and n.name not in self.show and (n.props.get("Visible", "True").lower() == "false"):
                return False
            n = n.parent
        return True

    def _parent_clip(self, n):
        clip = (0, 0, self.screen[0], self.screen[1])
        p = n.parent
        chain = []
        while p is not None:
            chain.append(p)
            p = p.parent
        for q in reversed(chain):
            qx, qy, qw, qh = self.rects[q]
            clip = (max(clip[0], int(round(qx))), max(clip[1], int(round(qy))), min(clip[2], int(round(qx + qw))), min(clip[3], int(round(qy + qh))))
        return clip

    def alpha_of(self, n):
        a = 1.0
        while n is not None:
            a *= fnum(n.props.get("Alpha"), 1.0)
            if n.props.get("InheritsAlpha", "True").lower() == "false":
                break
            n = n.parent
        return a

    def draw_window(self, canvas, n, parent_clip, root_set):
        if not self.visible(n, root_set):
            return
        x, y, w, h = self.rects[n]
        own = (max(parent_clip[0], int(round(x))), max(parent_clip[1], int(round(y))),
               min(parent_clip[2], int(round(x + w))), min(parent_clip[3], int(round(y + h))))
        tt, look = self.look_of(n)
        alpha = self.alpha_of(n)
        ctx = Ctx(self, n, (x, y, w, h), look)
        if own[2] > own[0] and own[3] > own[1] and tt not in SKIP_CONTENT:
            self.draw_self(canvas, n, tt, look, ctx, x, y, w, h, own, alpha)
        # CEGUI z-order: AlwaysOnTop children are drawn after their normal siblings
        kids = [c for c in n.children if c.props.get("AlwaysOnTop", "False").lower() != "true"]
        kids += [c for c in n.children if c.props.get("AlwaysOnTop", "False").lower() == "true"]
        for c in kids:
            cclip = own if c.props.get("ClippedByParent", "True").lower() != "false" else parent_clip
            self.draw_window(canvas, c, cclip, root_set)

    def draw_self(self, canvas, n, tt, look, ctx, x, y, w, h, clip, alpha):
        st = look.states if look else {}
        if tt == "Falagard/SuperProgress":
            prog = fnum(n.props.get("CurrentProgress", self.prop(n, look, "CurrentProgress", "0.7")), 0.7)
            sub = (clip[0], clip[1], min(clip[2], int(round(x + w * max(0.0, min(1.0, prog or 0.7))))), clip[3])
            for s in ("Background", "Enabled", "LightEnable"):
                self.draw_state(canvas, look, s, ctx, x, y, sub if s == "Enabled" else clip, alpha)
            return
        if tt in ("Falagard/SuperTooltip", "Falagard/ChatChannel"):
            self.draw_state(canvas, look, "Frame", ctx, x, y, clip, alpha)
            self.draw_state(canvas, look, "Enabled", ctx, x, y, clip, alpha)
            return
        img_prop = n.props.get("Image")
        is_static = "EnabledFrame" in st or "EnabledBackground" in st or tt in ("Falagard/StaticImage", "Falagard/BoundWindow", "Falagard/AnimateImage", "Falagard/StaticText")
        if is_static and "Normal" not in st:
            r = self.s.ref(img_prop)
            if r:
                area = None
                if look is not None:
                    fe = self.prop(n, look, "FrameEnabled", "False").lower() == "true"
                    area = look.named.get(("WithFrame" if fe else "NoFrame") + "ImageRenderArea")
                ix, iy, iw, ih = self.eval_area(area, ctx) if area is not None else (0, 0, w, h)
                hf = self._norm_fmt(n.props.get("HorzFormatting", "HorzStretched"))
                vf = self._norm_fmt(n.props.get("VertFormatting", "VertStretched"))
                self.draw_formatted(canvas, self.s.image(*r), (x + ix, y + iy, iw, ih), hf, vf, clip, None, alpha)
            if self.prop(n, look, "FrameEnabled", "False").lower() == "true":
                self.draw_state(canvas, look, "EnabledFrame", ctx, x, y, clip, alpha)
            if self.prop(n, look, "BackgroundEnabled", "False").lower() == "true":
                self.draw_state(canvas, look, "EnabledBackground", ctx, x, y, clip, alpha)
            self.draw_state(canvas, look, "Enabled", ctx, x, y, clip, alpha)
            if tt == "Falagard/StaticText":
                self.native_text(canvas, n, look, ctx, x, y, w, h, clip, alpha)
            return
        if "Normal" in st or "BackgroundImage" in st:
            sel = n.props.get("Selected", "False").lower() == "true" or n.props.get("Checked", "False").lower() == "true"
            if "BackgroundImage" in st:
                self.draw_state(canvas, look, "BackgroundImage", ctx, x, y, clip, alpha)
            state = "Pushed" if sel and "Pushed" in st else ("SelectedNormal" if sel and "SelectedNormal" in st else "Normal")
            self.draw_state(canvas, look, state, ctx, x, y, clip, alpha)
            r = self.s.ref(n.props.get("NormalImage"))
            if r:
                self.blit(canvas, self.s.image(*r), x, y, w, h, clip, None, alpha)
            if tt in NATIVE_TEXT:
                self.native_text(canvas, n, look, ctx, x, y, w, h, clip, alpha)
            return
        if tt == "Falagard/Editbox" or tt == "Falagard/MultiIMEEditBox":
            self.draw_state(canvas, look, "Enabled", ctx, x, y, clip, alpha)
        elif "Disabled" in st and "Enabled" not in st and n.props.get("Disabled", "False").lower() == "true":
            self.draw_state(canvas, look, "Disabled", ctx, x, y, clip, alpha)
        elif "Enabled" in st:
            self.draw_state(canvas, look, "Enabled", ctx, x, y, clip, alpha)
        elif "EnabledBackground" in st:
            self.draw_state(canvas, look, "EnabledBackground", ctx, x, y, clip, alpha)
        r = self.s.ref(img_prop)
        if r and tt not in ("Falagard/SimpleText",):
            self.blit(canvas, self.s.image(*r), x, y, w, h, clip, None, alpha)
        if tt in NATIVE_TEXT:
            self.native_text(canvas, n, look, ctx, x, y, w, h, clip, alpha)

    def native_text(self, canvas, n, look, ctx, x, y, w, h, clip, alpha):
        raw = self.texts.get(n.name, n.props.get("Text", ""))
        if not raw:
            return
        area = look.named.get("TextArea") if look else None
        if area is None and look is not None:
            fe = self.prop(n, look, "FrameEnabled", "False").lower() == "true"
            area = look.named.get(("WithFrame" if fe else "NoFrame") + "TextRenderArea")
        tx, ty, tw, th = self.eval_area(area, ctx) if area is not None else (0, 0, w, h)
        hf = self.prop(n, look, "HorzFormatting", "LeftAligned")
        vf = self.prop(n, look, "VertFormatting", "VertCentred")
        c = parse_colour(self.prop(n, look, "TextColor") or self.prop(n, look, "TextColour") or "")
        base = tuple(int(255 * v) for v in c[0][:3]) if c else (255, 255, 255)
        self.draw_text(canvas, raw, self.s.font(self.prop(n, look, "Font")), (x + tx, y + ty, tw, th), hf, vf, clip, base, alpha)

    def render(self, roots, bg=None):
        canvas = Image.new("RGBA", self.screen, (0, 0, 0, 0))
        if bg is not None:
            canvas.alpha_composite(bg.resize(self.screen, Image.LANCZOS).convert("RGBA"))
        root_set = set(roots)
        for r0 in roots:
            self.draw_window(canvas, r0, (0, 0, self.screen[0], self.screen[1]), root_set)
        return canvas


def render_layout(skin, layout, screen=(1920, 1080), state=None, bg=None, texts=None):
    p = skin.find("InterfaceFolder/%s/%s.layout.xml" % (layout, layout))
    if p is None:
        cand = [os.path.join(dp, f) for r in skin.roots for dp, dn, fn in os.walk(os.path.join(r, "InterfaceFolder", layout)) for f in fn if f.lower().endswith(".layout.xml")]
        if not cand:
            raise FileNotFoundError(layout)
        p = cand[0]
    st = dict(state or {})
    if texts:
        st.setdefault("text", {}).update(texts)
    r = Renderer(skin, screen, st)
    roots = parse_layout(p)
    for w, kv in st.get("prop", {}).items():
        for n in _walk(roots):
            if n.name == w:
                n.props.update(kv)
    r.build(roots)
    img = r.render(roots, bg)
    return img, r, roots


def _walk(nodes):
    for n in nodes:
        yield n
        yield from _walk(n.children)


def content_bbox(img, roots, rects, pad=12):
    xs = [rects[n] for n in _walk(roots) if n in rects and rects[n][2] > 0 and rects[n][3] > 0]
    bb = img.getchannel("A").getbbox()
    if not bb:
        return (0, 0, img.width, img.height)
    return (max(0, bb[0] - pad), max(0, bb[1] - pad), min(img.width, bb[2] + pad), min(img.height, bb[3] + pad))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("layout")
    ap.add_argument("--root", action="append", help="Data-like root (repeatable, first wins); default client_GL\\Data")
    ap.add_argument("--screen", default="1920,1080")
    ap.add_argument("--out")
    ap.add_argument("--state")
    ap.add_argument("--text", nargs="*", default=[])
    ap.add_argument("--bg")
    ap.add_argument("--crop", default="auto")
    ap.add_argument("--autoscale", action="store_true", help="honour AutoScaled imagesets (CEGUI 0.4.1 behaviour)")
    a = ap.parse_args()
    skin = Skin(a.root or [DEF_ROOT], autoscale=a.autoscale)
    screen = tuple(int(v) for v in a.screen.split(","))
    state = json.load(open(a.state, encoding="utf-8")) if a.state else {}
    texts = dict(t.split("=", 1) for t in a.text)
    bg = Image.open(a.bg) if a.bg else None
    img, r, roots = render_layout(skin, a.layout, screen, state, bg, texts)
    if a.crop == "auto":
        layer, _, _ = render_layout(skin, a.layout, screen, state, None, texts)
        img = img.crop(content_bbox(layer, roots, r.rects))
    elif a.crop and a.crop != "none":
        cx, cy, cw, ch = (int(v) for v in a.crop.split(","))
        img = img.crop((cx, cy, cx + cw, cy + ch))
    out = a.out or os.path.join(os.getcwd(), a.layout + ".png")
    img.convert("RGB").save(out)
    print("saved", out, img.size)
    for s in sorted(set(r.notes + skin.notes))[:40]:
        print("  !", s)


if __name__ == "__main__":
    sys.exit(main())
