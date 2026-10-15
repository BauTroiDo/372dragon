# -*- coding: utf-8 -*-
"""ui-fit: tim MOI cho chu tran khung / bi cat trong giao dien CanonicalCY.

Cach do (khong uoc luong bang "so ky tu"):
  - hinh hoc widget dung lai y het CEGUI 0.4.1 (UnifiedSize/UnifiedPosition/Absolute*/
    Position/Size mode Relative mac dinh), goc toa do = rect day du cua cha
    (Window::getUnclippedInnerRect == getUnclippedPixelRect trong ban nay);
  - be rong chu do bang FreeType tren DUNG file font + DUNG co chu ma client nap
    (xem Tools/ui-fit/ceguitext.py, moi buoc co dan nguon);
  - vung ve chu cua ho SimpleText = TOAN BO rect cua widget
    (FalagardSimpleText::getTextRenderArea -> Rect(Point(0,0), getAbsoluteSize()),
     Src/Client/CEGUIFalagardEx/FalSimpleText.h:115) va chu BI CAT theo rect do
     (clipper chi noi ra theo chieu DOC, FalSimpleText.cpp:77-82).

Chay:
  python Tools/ui-fit/measure_ui_text.py --out <thu muc>
"""

import argparse
import codecs
import csv
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ceguitext  # noqa: E402
import dbc_sources  # noqa: E402

DEFAULT_ROOT = r"C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data"

# Ho widget ma vung ve chu = toan bo rect va chu bi cat theo rect do.
SIMPLE_TEXT_TARGETS = {"Falagard/SimpleText"}

# Ho nut: chu nam trong NamedArea cua looknfeel; do duoc nhung sai so lon hon.
BUTTON_TARGETS = {
    "Falagard/Button", "Falagard/CheckBox", "Falagard/SuperBarButton",
    "Falagard/AchievementWindowTextButton", "Falagard/AchievementBarWindowButton",
    "Falagard/AchievementWindowCatalogButton",
}

WORDWRAP = {"WordWrapLeftAligned", "WordWrapRightAligned", "WordWrapCentred",
            "WordWrapJustified", "WordWrapLeftAligned2"}

# ui-fit-3 19/09: ho widget NGOAI hai nhom tren van CAT chu, chi khac cho lay vung ve.
# Dung RIENG cho nhanh do DBC - KHONG dua vao `draws_text` de so cu (4.269/441) khong doi.
#   Falagard/DragTitle   : `class FalagardDragTitle : public FalagardSimpleText` (FalDragTitle.h:20)
#                          -> vung ve = toan bo rect, y het SimpleText.
#   Falagard/StaticText  : ve trong NamedArea "TextRenderArea"; HorzFormatting mac dinh LeftAligned va
#                          thanh cuon NGANG mac dinh TAT (CEGUIStaticText.cpp:52,56) -> van bi cat.
DBC_SIMPLE_LIKE = {"Falagard/DragTitle"}
DBC_NAMED_AREA = {"Falagard/StaticText": ("TextRenderArea", "hop-mo-ta")}
# Ho tu gian be rong theo chu (khong bao gio cat) - FalagardSelfFitWindow.cpp:82-103.
DBC_SELF_FIT = {"Falagard/SelfFitWindow", "Falagard/PaoPao"}
# Ho khong he ve chu: FalagardSuperProgress.cpp khong co mot dong nao nhac toi text/font va
# TLBB_Look_ProgressSkill co 0 <TextComponent>.
DBC_NO_TEXT = {"Falagard/SuperProgress"}


# --------------------------------------------------------------- geometry

def _nums(value):
    return [float(x) for x in re.findall(r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?", value or "")]


def parse_unified_pair(value):
    """'{{s,o},{s,o}}' -> ((sx,ox),(sy,oy)). Thieu dau '}' la DINH DANG GOC, van doc duoc."""
    n = _nums(value)
    if len(n) < 4:
        return None
    return ((n[0], n[1]), (n[2], n[3]))


def parse_xy(value):
    n = _nums(value)
    if len(n) < 2:
        return None
    return (n[0], n[1])


class Node(object):
    __slots__ = ("wtype", "name", "props", "children", "parent",
                 "x", "y", "w", "h", "layout", "line")

    def __init__(self, wtype, name, line=0):
        self.wtype = wtype
        self.name = name
        self.props = {}
        self.children = []
        self.parent = None
        self.x = self.y = self.w = self.h = 0.0
        self.layout = ""
        self.line = line


def parse_layout(path):
    """Doc mot .layout.xml -> danh sach cay goc. Bo qua file hong cu phap."""
    try:
        raw = open(path, "rb").read()
        if raw.startswith(codecs.BOM_UTF8):
            raw = raw[3:]
        root = ET.fromstring(raw)
    except Exception as exc:
        return None, str(exc)

    def build(el):
        node = Node(el.get("Type", ""), el.get("Name", ""))
        for child in el:
            if child.tag == "Property":
                node.props[child.get("Name", "")] = child.get("Value", "")
            elif child.tag == "Window":
                sub = build(child)
                sub.parent = node
                node.children.append(sub)
            elif child.tag == "AutoWindow":
                sub = build(child)
                sub.parent = node
                node.children.append(sub)
        return node

    roots = []
    for el in root.iter("Window"):
        # chi lay cac Window truc tiep duoi GUILayout
        pass
    for el in list(root):
        if el.tag == "Window":
            roots.append(build(el))
    return roots, None


def resolve(node, parent_w, parent_h):
    """Tinh rect tuyet doi. Mo phong Window::setWindowSize / setSize(Relative|Absolute)."""
    p = node.props
    sw, ow, sh, oh = None, None, None, None
    sx, ox, sy, oy = None, None, None, None

    if "UnifiedSize" in p:
        u = parse_unified_pair(p["UnifiedSize"])
        if u:
            (sw, ow), (sh, oh) = u
    if "UnifiedWidth" in p:
        n = _nums(p["UnifiedWidth"])
        if len(n) >= 2:
            sw, ow = n[0], n[1]
    if "UnifiedHeight" in p:
        n = _nums(p["UnifiedHeight"])
        if len(n) >= 2:
            sh, oh = n[0], n[1]
    if "AbsoluteSize" in p:
        xy = parse_xy(p["AbsoluteSize"])
        if xy:
            sw, ow, sh, oh = 0.0, xy[0], 0.0, xy[1]
    if "RelativeSize" in p:
        xy = parse_xy(p["RelativeSize"])
        if xy:
            sw, ow, sh, oh = xy[0], 0.0, xy[1], 0.0
    if "Size" in p:  # MetricsMode mac dinh = Relative
        xy = parse_xy(p["Size"])
        if xy:
            sw, ow, sh, oh = xy[0], 0.0, xy[1], 0.0

    if "UnifiedPosition" in p:
        u = parse_unified_pair(p["UnifiedPosition"])
        if u:
            (sx, ox), (sy, oy) = u
    if "UnifiedXPosition" in p:
        n = _nums(p["UnifiedXPosition"])
        if len(n) >= 2:
            sx, ox = n[0], n[1]
    if "UnifiedYPosition" in p:
        n = _nums(p["UnifiedYPosition"])
        if len(n) >= 2:
            sy, oy = n[0], n[1]
    if "AbsolutePosition" in p:
        xy = parse_xy(p["AbsolutePosition"])
        if xy:
            sx, ox, sy, oy = 0.0, xy[0], 0.0, xy[1]
    if "RelativePosition" in p:
        xy = parse_xy(p["RelativePosition"])
        if xy:
            sx, ox, sy, oy = xy[0], 0.0, xy[1], 0.0
    if "Position" in p:
        xy = parse_xy(p["Position"])
        if xy:
            sx, ox, sy, oy = xy[0], 0.0, xy[1], 0.0

    node.w = (sw * parent_w + ow) if sw is not None else parent_w
    node.h = (sh * parent_h + oh) if sh is not None else parent_h
    node.x = (sx * parent_w + ox) if sx is not None else 0.0
    node.y = (sy * parent_h + oy) if sy is not None else 0.0

    for c in node.children:
        resolve(c, node.w, node.h)


# ------------------------------------------------------------ scheme/look

def load_scheme(path):
    """WindowType -> (TargetType, LookNFeel)."""
    mapping = {}
    raw = open(path, "r", encoding="utf-8", errors="replace").read()
    for m in re.finditer(r'<FalagardMapping\s+WindowType="([^"]+)"\s+TargetType="([^"]+)"(?:\s+LookNFeel="([^"]*)")?', raw):
        mapping[m.group(1)] = (m.group(2), m.group(3) or "")
    return mapping


def _dim(block, kind):
    """Doc mot <Dim type="kind"> trong <Area> -> (scale, offset) so voi rect widget."""
    m = re.search(r'<Dim\s+type="%s"\s*>(.*?)</Dim>' % kind, block, re.S)
    if not m:
        return None
    body = m.group(1)
    u = re.search(r'<UnifiedDim([^>]*)/?>', body)
    if u:
        attrs = u.group(1)
        sc = re.search(r'scale="([-\d.]+)"', attrs)
        off = re.search(r'offset="([-\d.]+)"', attrs)
        scale = float(sc.group(1)) if sc else 0.0
        offset = float(off.group(1)) if off else 0.0
        sub = re.search(r'<DimOperator\s+op="Subtract"\s*>\s*<AbsoluteDim\s+value="([-\d.]+)"', body)
        if sub:
            offset -= float(sub.group(1))
        add = re.search(r'<DimOperator\s+op="Add"\s*>\s*<AbsoluteDim\s+value="([-\d.]+)"', body)
        if add:
            offset += float(add.group(1))
        return (scale, offset)
    a = re.search(r'<AbsoluteDim\s+value="([-\d.]+)"', body)
    if a:
        return (0.0, float(a.group(1)))
    return None


class Look(object):
    __slots__ = ("name", "props", "defs", "has_text", "area", "horz_prop", "sections", "named")

    def __init__(self, name):
        self.name = name
        self.props = {}
        self.defs = {}
        self.has_text = False
        self.area = None       # (left_scale,left_off,width_scale,width_off)
        self.horz_prop = None
        self.named = {}        # ui-fit-3: NamedArea -> (left_scale,left_off,width_scale,width_off)


def load_looks(schema_dir):
    """LookName -> Look. Nut chi VE chu khi look co <TextComponent> duoc StateImagery dung."""
    looks = {}
    for fn in sorted(os.listdir(schema_dir)):
        if not fn.endswith(".looknfeel.xml"):
            continue
        raw = open(os.path.join(schema_dir, fn), "r", encoding="utf-8", errors="replace").read()
        for m in re.finditer(r'<WidgetLook\s+name="([^"]+)"(.*?)</WidgetLook>', raw, re.S):
            name, body = m.group(1), m.group(2)
            look = Look(name)
            head = body.split("<StateImagery", 1)[0]
            for pm in re.finditer(r'<Property\s+name="([^"]+)"\s+value="([^"]*)"', head):
                look.props[pm.group(1)] = pm.group(2)
            for pm in re.finditer(r'<PropertyDefinition\s+name="([^"]+)"\s+initialValue="([^"]*)"', head):
                look.defs[pm.group(1)] = pm.group(2)
            tc = re.search(r"<TextComponent>(.*?)</TextComponent>", body, re.S)
            if tc:
                look.has_text = True
                area = re.search(r"<Area>(.*?)</Area>", tc.group(1), re.S)
                if area:
                    a = area.group(1)
                    left = _dim(a, "LeftEdge") or (0.0, 0.0)
                    width = _dim(a, "Width")
                    if width is None:
                        right = _dim(a, "RightEdge")
                        width = ((right[0] - left[0], right[1] - left[1]) if right else (1.0, 0.0))
                    look.area = (left[0], left[1], width[0], width[1])
                hp = re.search(r'<HorzFormatProperty\s+name="([^"]+)"', tc.group(1))
                if hp:
                    look.horz_prop = hp.group(1)
            # ui-fit-3: NamedArea (vung ve chu cua FalagardStaticText & ho hang, doc bang ten trong C++)
            for na in re.finditer(r'<NamedArea\s+name="([^"]+)"\s*>(.*?)</NamedArea>', body, re.S):
                ar = re.search(r"<Area>(.*?)</Area>", na.group(2), re.S)
                if not ar:
                    continue
                a = ar.group(1)
                left = _dim(a, "LeftEdge") or (0.0, 0.0)
                width = _dim(a, "Width")
                if width is None:
                    right = _dim(a, "RightEdge")
                    width = ((right[0] - left[0], right[1] - left[1]) if right else (1.0, 0.0))
                look.named[na.group(1)] = (left[0], left[1], width[0], width[1])
            looks[name] = look
    return looks


# ------------------------------------------------------------------- lua

SETTEXT_RE = re.compile(r'([A-Za-z_][A-Za-z_0-9]*)\s*:\s*SetText\s*\(')
STRING_RE = re.compile(r'"((?:[^"\\]|\\.)*)"' r"|'((?:[^'\\]|\\.)*)'")


def _balanced_arg(src, start):
    """Doc doi so cua loi goi bat dau tai '(' o vi tri start-1, dung dau ngoac can bang."""
    depth = 1
    i = start
    n = len(src)
    while i < n and depth and i - start < 1200:
        c = src[i]
        if c in "\"'":
            q = c
            i += 1
            while i < n and src[i] != q:
                i += 2 if src[i] == "\\" else 1
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return src[start:i]
        i += 1
    return None


def lua_texts(lua_path):
    """{TenWidget: [(chuoi ghep, co_phan_dong)]} lay tu cac loi goi SetText."""
    out = {}
    try:
        src = open(lua_path, "r", encoding="utf-8", errors="replace").read()
    except Exception:
        return out
    src = re.sub(r"--\[\[.*?\]\]", "", src, flags=re.S)
    src = re.sub(r"(?m)--(?!\[\[).*$", "", src)
    for m in SETTEXT_RE.finditer(src):
        widget = m.group(1)
        arg = _balanced_arg(src, m.end())
        if arg is None or arg.count("\n") > 2:
            continue
        # Bo doi so cua loi goi long nhau: "HUILIUEXP" trong Player:GetData("HUILIUEXP")
        # KHONG phai chu hien thi.
        flat, depth = [], 0
        for ch in arg:
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth = max(0, depth - 1)
            elif depth == 0:
                flat.append(ch)
        flat = "".join(flat)
        parts = ["".join(g for g in mm.groups() if g is not None)
                 for mm in STRING_RE.finditer(flat)]
        literal = "".join(p.replace('\\"', '"').replace("\\n", "\n") for p in parts)
        dynamic = bool(re.search(r"\.\.|GetStr|tostring|format|Get[A-Z]|\bnum|\bn[A-Z]", arg))
        if not literal and not dynamic:
            continue
        out.setdefault(widget, []).append((literal, dynamic))
    return out


# Widget ve chu/so ngay ca khi layout khong dat Text (tien, o nhap, dem gio).
PAINTS_TEXT = {"Falagard/Money", "Falagard/Editbox", "Falagard/IMEEditBox",
               "Falagard/MultiIMEEditBox", "Falagard/SimpleText", "Falagard/StaticText"}

# Gia tri Text khong phai chu hien thi: mo ta tai nguyen / ten kieu widget.
NOT_TEXT_RE = re.compile(r'^\s*(set:|Imageset:|image:|TLBB_[A-Za-z0-9_]*\s*$)')


# --------------------------------------------------------------- measure

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", default=DEFAULT_ROOT)
    ap.add_argument("--out", required=True)
    ap.add_argument("--screen", default="1024x768")
    ap.add_argument("--codepage", type=int, default=65001)
    ap.add_argument("--dyn-digits", type=int, default=6,
                    help="so chu so gia dinh cho phan chuoi dong trong Lua")
    ap.add_argument("--filter", default="")
    ap.add_argument("--cy-dict", default="",
                    help="TSV chu goc tieng Trung cua CY (Tools/ui-fit/extract_cy_dict.py)")
    ap.add_argument("--all-rows", action="store_true",
                    help="ghi ca cac widget KHONG tran (de kiem tra)")
    # ui-fit-3 19/09: gioi han #3/#8 cua ban truoc - chu den tu bang DBC (ConfigFolder) khong duoc do.
    ap.add_argument("--dbc", action="store_true",
                    help="do ca chu den tu cot hien thi cua bang DBC (Tools/ui-fit/dbc_sources.py)")
    ap.add_argument("--dbc-baseline", default="",
                    help="thu muc ConfigFolder BAN CY (truoc khi dich) de so cy_w/vi_w")
    # ui-fit-3 19/09: the toa do cua CY (#{_INFOAIM..}) nay NO thanh chu that (nhanh `info-links`).
    # Co la de tai hien THE GIOI CU va tach rieng anh huong - khong phai de dung that.
    ap.add_argument("--no-infolink", action="store_true",
                    help="tat viec no the #{_INFO..} (tai hien cach do truoc 19/09)")
    ap.add_argument("--dbc-baseline-encoding", default="gbk",
                    help="bang CY goc la GBK; dat utf-8 de chay doi chung (baseline = chinh ban dang do)")
    args = ap.parse_args()

    infolink = not args.no_infolink
    data = args.data
    ui_root = os.path.join(data, "InterfaceFolder")
    schema = os.path.join(ui_root, "Schema")
    sw, sh = (int(x) for x in args.screen.lower().split("x"))

    fonts = ceguitext.load_fonts(schema, ui_root, args.codepage)
    scheme = load_scheme(os.path.join(schema, "WoWLookSkin.scheme.xml"))
    looks = load_looks(schema)
    dictionary = ceguitext.load_dictionary(os.path.join(data, "ConfigFolder", "StrDictionary.txt"))
    cy_dict = {}
    if args.cy_dict:
        with open(args.cy_dict, "r", encoding="utf-8", errors="replace") as fh:
            for line in fh:
                parts = line.rstrip("\r\n").split("\t")
                if len(parts) == 2:
                    cy_dict[parts[0]] = parts[1]

    # font mac dinh = font dau tien duoc tao trong scheme (System::setDefaultFont)
    scheme_raw = open(os.path.join(schema, "WoWLookSkin.scheme.xml"), "r",
                      encoding="utf-8", errors="replace").read()
    first = re.search(r'<Font\s+Name="([^"]+)"', scheme_raw)
    default_font = first.group(1) if first else "SongTiBmp12"

    # ---- ui-fit-3: cot hien thi cua bang DBC ------------------------------------------------
    cfg_dir = os.path.join(data, "ConfigFolder")
    dbc_cache = {}

    def dbc_values(table, col, baseline=False):
        """[(chuoi, so dong dung chuoi do)] cua mot cot; baseline=True -> ban CY truoc khi dich."""
        root = args.dbc_baseline if baseline else cfg_dir
        key = (root, table, col)
        if key in dbc_cache:
            return dbc_cache[key]
        path = os.path.join(root, table)
        try:
            vals = dbc_sources.read_column(
                path, col, "utf-8" if not baseline else args.dbc_baseline_encoding)
        except Exception as exc:
            dbc_cache[key] = ("err", str(exc))
            return dbc_cache[key]
        cnt = {}
        for i, v in enumerate(vals):
            if v.strip():
                cnt.setdefault(v, []).append(i)
        dbc_cache[key] = ("ok", cnt)
        return dbc_cache[key]

    dbc_rows = []
    dbc_den = {}
    dbc_stats = {"widget": 0, "cap_widget_cot": 0, "gia_tri_do": 0, "tran": 0,
                 "tran_moi_do_dich": 0, "tran_ca_ben_cy": 0, "widget_khong_doi_chieu_duoc": 0,
                 "widget_bo_qua_theo_ho": 0}
    dbc_unmatched = []

    os.makedirs(args.out, exist_ok=True)
    rows = []
    overlaps = []
    seen = set()
    stats = {"layouts": 0, "parse_errors": 0, "text_widgets": 0, "measured": 0,
             "overflow": 0, "unknown_key": 0, "missing_glyph": 0}
    bad = []
    missing_glyph_chars = {}

    for dirpath, _dirs, files in os.walk(ui_root):
        for fn in sorted(files):
            if not fn.endswith(".layout.xml"):
                continue
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, ui_root).replace("\\", "/")
            if args.filter and args.filter.lower() not in rel.lower():
                continue
            stats["layouts"] += 1
            roots, err = parse_layout(path)
            if err:
                stats["parse_errors"] += 1
                bad.append((rel, err))
                continue
            lua_path = os.path.join(dirpath, fn[:-len(".layout.xml")] + ".lua")
            lua = lua_texts(lua_path)
            dbc_map = dbc_sources.scan_lua(lua_path) if args.dbc else {}
            dbc_seen_widgets = set()
            for ev in (dbc_sources.EVENT_PROV if args.dbc else []):
                if ev["layout"] == rel:
                    for s in ev["sources"]:
                        r = dict(s)
                        r.update(setter="SetText(OnEvent)", literal="", confidence="su-kien",
                                 lua_line=0, recv="event", meth=ev["event"])
                        dbc_map.setdefault(ev["widget"], []).append(r)

            for root in roots:
                resolve(root, float(sw), float(sh))

            placed = []   # (id(cha), node, x, y, vis, target, draws_text, ink_l, ink_r)

            def walk(node, ax, ay, vis):
                nx, ny = ax + node.x, ay + node.y
                vis = vis and node.props.get("Visible", "True").lower() != "false"
                target, lookname = scheme.get(node.wtype, ("", ""))
                look = looks.get(lookname)
                lookprops = look.props if look else {}
                fontname = node.props.get("Font") or lookprops.get("Font") or default_font

                texts = []
                if "Text" in node.props and node.props["Text"].strip():
                    texts.append(("layout", node.props["Text"]))
                for lit, dyn in lua.get(node.name, []):
                    texts.append(("lua" + ("+dyn" if dyn else ""), lit))

                draws_text = target in SIMPLE_TEXT_TARGETS or (look is not None and look.has_text)
                # ui-fit-3: hinh hoc vung ve chu phai tinh CA khi layout/lua khong dat chuoi nao - widget
                # duoc bang DBC bom chu luc chay thuong khong co Text trong layout (CreateRole_SelectHair_Text2).
                font = fonts.get(fontname) or fonts.get(default_font)
                kind = avail = horz = None
                if draws_text:
                    if target in SIMPLE_TEXT_TARGETS:
                        kind = "label"
                        avail = node.w
                        horz = (node.props.get("HorzFormatting")
                                or lookprops.get("HorzFormatting") or "LeftAligned")
                    else:
                        kind = "button"
                        a = look.area or (0.0, 0.0, 1.0, 0.0)
                        avail = a[2] * node.w + a[3]
                        horz = "CentreAligned"
                        if look.horz_prop:
                            horz = (node.props.get(look.horz_prop)
                                    or look.defs.get(look.horz_prop) or "CentreAligned")

                # vung ve chu RIENG cho nhanh DBC: phu them DragTitle / StaticText / tu-gian / khong-ve
                dbc_kind, dbc_avail, dbc_horz, dbc_skip = kind, avail, horz, ""
                if not draws_text:
                    if target in DBC_SIMPLE_LIKE:
                        dbc_kind, dbc_avail = "tieu-de", node.w
                        dbc_horz = (node.props.get("HorzFormatting")
                                    or lookprops.get("HorzFormatting") or "LeftAligned")
                    elif target in DBC_NAMED_AREA and look is not None:
                        na, knd = DBC_NAMED_AREA[target]
                        a = look.named.get(na)
                        if a:
                            dbc_kind, dbc_avail = knd, a[2] * node.w + a[3]
                            dbc_horz = (node.props.get("HorzFormatting")
                                        or lookprops.get("HorzFormatting") or "LeftAligned")
                    elif target in DBC_SELF_FIT:
                        dbc_skip = "tu-gian-theo-chu"
                    elif target in DBC_NO_TEXT:
                        dbc_skip = "widget-khong-ve-chu"

                if dbc_skip and node.name in dbc_map:
                    dbc_seen_widgets.add(node.name)
                    for rec in dbc_map[node.name]:
                        dbc_unmatched.append({"layout": rel, "widget": node.name,
                                              "ly_do": dbc_skip + " (" + node.wtype + ")",
                                              "table": rec["table"], "col": rec["col"]})
                    dbc_stats["widget_bo_qua_theo_ho"] += 1

                if not dbc_skip and node.name in dbc_map and dbc_avail is not None:
                    dbc_seen_widgets.add(node.name)
                    dbc_stats["widget"] += 1
                    for rec in dbc_map[node.name]:
                        dbc_stats["cap_widget_cot"] += 1
                        ok, cur = dbc_values(rec["table"], rec["col"])
                        if ok != "ok":
                            dbc_unmatched.append({"layout": rel, "widget": node.name,
                                                  "ly_do": "khong doc duoc bang: " + cur,
                                                  "table": rec["table"], "col": rec["col"]})
                            continue
                        base = {}
                        if args.dbc_baseline:
                            bok, bvals = dbc_values(rec["table"], rec["col"], baseline=True)
                            if bok == "ok":
                                base = bvals
                        pre, _l = ceguitext.expand_markup(rec["literal"], dictionary, 0, infolink)
                        pre_w = font.extent(pre.replace("\n", ""))
                        # ban CY: cung dong -> chuoi Han goc, do bang cung font
                        by_row = {}
                        for zh, idxs in base.items():
                            for i in idxs:
                                by_row[i] = zh
                        # ui-fit-3 (mo rong bay #4 cua ui-fit-2): WordWrap* chi cuu duoc neu khung CAO
                        # du HAI dong. Khung cao 18-22 px voi line spacing 23 px thi khong the xuong
                        # dong -> van bi cat. Ho StaticText co thanh cuon doc rieng nen khong ap luat nay.
                        wrap = dbc_horz in WORDWRAP
                        one_line = (wrap and dbc_kind != "hop-mo-ta"
                                    and node.h < 2.0 * getattr(font, "line_spacing", 23.0) - 0.5)
                        if one_line:
                            wrap = False
                        for val, idxs in cur.items():
                            shown, _lost = ceguitext.expand_markup(val, dictionary, 0, infolink)
                            lines = shown.split("\n") or [""]
                            vi_w = max(font.extent(s) for s in lines) + pre_w
                            zh = by_row.get(idxs[0], "")
                            cy_w = -1
                            if zh:
                                zsh, _z = ceguitext.expand_markup(zh, dictionary, 0, infolink)
                                cy_w = max(font.extent(s) for s in zsh.split("\n")) + pre_w
                            dbc_stats["gia_tri_do"] += 1
                            pair_key = "%s|%s|%s.c%d" % (rel, node.name, rec["table"], rec["col"])
                            d = dbc_den.setdefault(pair_key, {"da_do": 0, "dong": 0, "wrap": int(wrap),
                                                              "box_w": round(dbc_avail, 1),
                                                              "box_h": round(node.h, 1),
                                                              "line_spacing": round(getattr(font, "line_spacing", 0.0), 1),
                                                              "wrap_1_dong": int(one_line),
                                                              "kind": dbc_kind, "dot": rec["batch"]})
                            d["da_do"] += 1
                            d["dong"] += len(idxs)
                            over = vi_w - dbc_avail
                            if over <= 0.5 or wrap:
                                continue
                            dbc_stats["tran"] += 1
                            cls = "khong-co-ban-cy"
                            if cy_w >= 0:
                                cls = "cy-fit" if cy_w <= dbc_avail + 0.5 else "cy-over"
                                dbc_stats["tran_moi_do_dich" if cls == "cy-fit"
                                          else "tran_ca_ben_cy"] += 1
                            dbc_rows.append({
                                "layout": rel, "widget": node.name, "type": node.wtype,
                                "kind": dbc_kind, "setter": rec["setter"], "dot": rec["batch"],
                                "table": rec["table"], "col": rec["col"], "member": rec["member"],
                                "so_dong": len(idxs), "dong_dau": idxs[0],
                                "font": font.name, "pt": font.pt_size,
                                "box_w": round(dbc_avail, 1), "box_h": round(node.h, 1),
                                "vi_w": vi_w, "over_px": round(over, 1),
                                "over_pct": round(100.0 * over / max(dbc_avail, 1.0), 1),
                                "cy_w": cy_w, "cy": cls,
                                "horz": dbc_horz, "wrap_1_dong": int(one_line),
                                "visible": int(vis),
                                "tin_cay": rec["confidence"], "lua_line": rec["lua_line"],
                                "tien_to": rec["literal"][:40],
                                "vi": shown[:120], "zh": zh[:80],
                            })

                if texts and draws_text:
                    stats["text_widgets"] += 1
                    for src, raw in texts:
                        if NOT_TEXT_RE.match(raw) or raw.strip() == node.wtype:
                            continue
                        shown, lost = ceguitext.expand_markup(raw, dictionary, 0, infolink)
                        if raw.strip().startswith("#{") and shown == raw:
                            stats["unknown_key"] += 1
                        base = shown
                        if src.endswith("dyn"):
                            shown = shown + "0" * args.dyn_digits
                        if not shown.strip():
                            continue
                        lines = shown.split("\n")
                        wide = max(lines, key=lambda s: font.extent(s))
                        ext = font.extent(wide)
                        base_lines = base.split("\n") if base.strip() else [""]
                        ext_min = max(font.extent(s) for s in base_lines)
                        key = (rel, node.name, wide)
                        if key in seen:
                            continue
                        seen.add(key)
                        stats["measured"] += 1
                        for ch in wide:
                            if ch not in "\r\n\t" and not font.has_glyph(ch):
                                missing_glyph_chars.setdefault(ch, 0)
                                missing_glyph_chars[ch] += 1
                        cy_w, cy_cls = -1, "no-cy"
                        if cy_dict and raw.strip().startswith("#{"):
                            cy_raw, _ = ceguitext.expand_markup(raw, cy_dict, 0, infolink)
                            if cy_raw and cy_raw != raw:
                                cy_w = max(font.extent(s2) for s2 in cy_raw.split("\n"))
                        if horz in ("RightAligned",):
                            ink_l, ink_r = nx + node.w - ext, nx + node.w
                        elif horz in ("HorzCentred", "CentreAligned", "WordWrapCentred",
                                      "WordWrapCentreAligned"):
                            ink_l = nx + (node.w - ext) / 2.0
                            ink_r = ink_l + ext
                        else:
                            ink_l, ink_r = nx, nx + ext
                        ink_l = max(ink_l, nx)
                        ink_r = min(ink_r, nx + node.w)   # chu bi cat theo rect cua chinh no
                        if ink_r > ink_best.get(node.name, (0.0, 0.0))[1]:
                            ink_best[node.name] = (ink_l, ink_r)
                        wrap = horz in WORDWRAP
                        over = ext - avail
                        if cy_w >= 0:
                            cy_cls = "cy-fit" if cy_w <= avail + 0.5 else "cy-over"
                        # ui-fit-2 17/09: --all-rows ghi ca widget KHONG tran (de biet MOI khung dung mot khoa)
                        if (over > 0.5 or args.all_rows) and not wrap:
                            if over > 0.5:
                                stats["overflow"] += 1
                            rows.append({
                                "layout": rel,
                                "widget": node.name,
                                "type": node.wtype,
                                "target": target,
                                "kind": kind,
                                "source": src,
                                "font": font.name,
                                "pt": font.pt_size,
                                "box_w": round(avail, 1),
                                "box_h": round(node.h, 1),   # ui-fit-2: chieu cao, de biet nut WordWrap* co cho cho dong 2 khong
                                "text_w": ext,
                                "over_px": round(over, 1),
                                "over_px_min": round(ext_min - avail, 1),
                                "cy_w": cy_w,
                                "cy": cy_cls,
                                "over_pct": round(100.0 * over / max(avail, 1.0), 1),
                                "horz": horz,
                                "abs_x": round(nx, 1),
                                "abs_y": round(ny, 1),
                                "visible": int(vis),
                                "raw": raw[:200],
                                "shown": wide[:200],
                                "dyn": int(src.endswith("dyn")),
                                "lost": int(lost),
                            })
                placed.append((id(node.parent), node, nx, ny, vis, target,
                               draws_text and bool(texts)))
                for c in node.children:
                    walk(c, nx, ny, vis)

            ink_best = {}
            for root in roots:
                walk(root, 0.0, 0.0, True)
            for wname, recs in dbc_map.items():
                if wname in dbc_seen_widgets:
                    continue
                dbc_stats["widget_khong_doi_chieu_duoc"] += 1
                dbc_unmatched.append({
                    "layout": rel, "widget": wname,
                    "ly_do": ("ben nhan khong phai ten widget tron (phan tu bang / o trong bang)"
                              if ("[" in wname or "." in wname)
                              else "khong co widget ten nay trong layout (tao luc chay?)"),
                    "table": recs[0]["table"], "col": recs[0]["col"]})
            # --- de nhau: chu cua mot widget phu len mot widget KHAC CUNG VE CHU
            by_parent = {}
            for item in placed:
                by_parent.setdefault(item[0], []).append(item)
            for group in by_parent.values():
                for pid, node, nx, ny, vis, target, has_text in group:
                    if not (vis and has_text and node.name in ink_best):
                        continue
                    il, ir = ink_best[node.name]
                    for pid2, other, ox, oy, ovis, otarget, ohas in group:
                        if other is node or not ovis:
                            continue
                        if not (ohas or otarget in PAINTS_TEXT):
                            continue
                        # Chi tinh "chu tran sang o BEN PHAI" - dung chu ky that cua loi de nhau.
                        # Hai widget cung mot cho (Show/Hide luan phien, o menu nhan ban luc chay)
                        # khong phai loi bo cuc.
                        if ox <= nx + 2.0:
                            continue
                        if abs(other.w - node.w) < 4.0 and abs(other.h - node.h) < 4.0:
                            continue
                        vlap = min(ny + node.h, oy + other.h) - max(ny, oy)
                        if vlap <= 0.5 * min(node.h, other.h) or vlap <= 0:
                            continue
                        hlap = min(ir, ox + other.w) - max(il, ox)
                        if hlap <= 2.0:
                            continue
                        overlaps.append({
                            "layout": rel, "widget": node.name, "type": node.wtype,
                            "de_len": other.name, "de_len_type": other.wtype,
                            "chong_px": round(hlap, 1),
                            "ink_l": round(il, 1), "ink_r": round(ir, 1),
                            "kia_l": round(ox, 1), "kia_r": round(ox + other.w, 1),
                        })

    rows.sort(key=lambda r: (-r["over_px"], r["layout"], r["widget"]))
    csv_path = os.path.join(args.out, "overflow.csv")
    with open(csv_path, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()) if rows else
                           ["layout", "widget", "type", "target", "kind", "source", "font",
                            "pt", "box_w", "box_h", "text_w", "over_px", "over_px_min", "cy_w", "cy", "over_pct", "horz",
                            "abs_x", "abs_y", "visible", "raw", "shown", "dyn", "lost"])
        w.writeheader()
        for r in rows:
            w.writerow(r)

    seen_ov = set()
    uniq = []
    for o in overlaps:
        k = (o["layout"], o["widget"], o["de_len"])
        if k in seen_ov:
            continue
        seen_ov.add(k)
        uniq.append(o)
    uniq.sort(key=lambda o: -o["chong_px"])
    with open(os.path.join(args.out, "overlap.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["layout", "widget", "type", "de_len", "de_len_type",
                                           "chong_px", "ink_l", "ink_r", "kia_l", "kia_r"])
        w.writeheader()
        for o in uniq:
            w.writerow(o)
    stats["overlap"] = len(uniq)
    stats["missing_glyph"] = len(missing_glyph_chars)
    stats["infolink"] = int(infolink)

    if args.dbc:
        dbc_rows.sort(key=lambda r: (-r["over_px"], r["layout"], r["widget"]))
        cols = ["layout", "widget", "type", "kind", "setter", "dot", "table", "col", "member",
                "so_dong", "dong_dau", "font", "pt", "box_w", "box_h", "vi_w", "over_px",
                "over_pct", "cy_w", "cy", "horz", "wrap_1_dong", "visible", "tin_cay", "lua_line", "tien_to",
                "vi", "zh"]
        with open(os.path.join(args.out, "dbc_overflow.csv"), "w", newline="",
                  encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=cols)
            w.writeheader()
            for r in dbc_rows:
                w.writerow(r)
        with open(os.path.join(args.out, "dbc_unmatched.csv"), "w", newline="",
                  encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=["layout", "widget", "ly_do", "table", "col"])
            w.writeheader()
            for r in dbc_unmatched:
                w.writerow(r)
        per_pair = {}
        for r in dbc_rows:
            k = "%s|%s.c%d" % (r["widget"], r["table"], r["col"])
            p = per_pair.setdefault(k, {"layout": r["layout"], "dot": r["dot"], "chuoi_tran": 0,
                                        "dong_tran": 0, "max_over": 0.0, "cy_fit": 0, "cy_over": 0})
            p["chuoi_tran"] += 1
            p["dong_tran"] += r["so_dong"]
            p["max_over"] = max(p["max_over"], r["over_px"])
            if r["cy"] == "cy-fit":
                p["cy_fit"] += 1
            elif r["cy"] == "cy-over":
                p["cy_over"] += 1
        with open(os.path.join(args.out, "dbc_summary.json"), "w", encoding="utf-8") as fh:
            json.dump({"stats": dbc_stats,
                       "mau_so_tung_cap": dbc_den,
                       "theo_cap_widget_cot": per_pair,
                       "khong_cat_duoc": dbc_sources.NON_CLIPPING},
                      fh, ensure_ascii=False, indent=2)
    with open(os.path.join(args.out, "summary.json"), "w", encoding="utf-8") as fh:
        json.dump({"stats": stats,
                   "fonts": {k: {"file": os.path.basename(v.path), "pt": v.pt_size}
                             for k, v in fonts.items()},
                   "default_font": default_font,
                   "screen": [sw, sh],
                   "parse_errors": bad[:50],
                   "missing_glyphs": {k: v for k, v in
                                      sorted(missing_glyph_chars.items(), key=lambda kv: -kv[1])[:40]}},
                  fh, ensure_ascii=False, indent=2)

    print("layouts       :", stats["layouts"], "| loi cu phap:", stats["parse_errors"])
    print("widget co chu :", stats["text_widgets"], "| luot do:", stats["measured"])
    print("TRAN KHUNG    :", stats["overflow"])
    print("DE LEN NHAU   :", stats["overlap"])
    print("thieu glyph   :", stats["missing_glyph"], "ky tu khac nhau")
    print("->", csv_path)
    if args.dbc:
        print("--- chu tu bang DBC (ConfigFolder) ---")
        print("widget duoc DBC bom chu :", dbc_stats["widget"],
              "| cap widget-cot:", dbc_stats["cap_widget_cot"],
              "| khong doi chieu duoc:", dbc_stats["widget_khong_doi_chieu_duoc"])
        print("gia tri da do           :", dbc_stats["gia_tri_do"])
        print("TRAN KHUNG              :", dbc_stats["tran"],
              "| trong do CY vua ma Viet tran:", dbc_stats["tran_moi_do_dich"],
              "| CY cung tran:", dbc_stats["tran_ca_ben_cy"])


if __name__ == "__main__":
    main()
