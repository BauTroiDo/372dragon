"""skin_v2_looks.py - rewrite the effective WidgetLooks of a TLBB InterfaceFolder to skin v2.

The transform never changes window types, sizes, properties or child windows; it only swaps the
imagery a look draws:
A) frame-bound sections of the shared looks TLBB_Look_Common / TLBB_GL_Common (main frames and
   the window backgrounds tied to their geometry) are replaced by v2 sections;
B) FrameComponents whose images all belong to one known family (085 or v1 GL pieces) are rebuilt
   as crisp v2 nine-slices (3-slice button/tab/edit art becomes 9-slice);
C) single images (slots, tab images, scrollbar parts, small buttons, fills) are remapped; uniform
   fills are forced to Stretched (a 2x2 fill tiled over a panel would cost thousands of quads);
D) set:/image: property values (SelectBrush, NormalImage of look children) are remapped.
Only looks that change are emitted; they override the originals because the v2 looknfeel file is
loaded last (CEGUI WidgetLookManager::addWidgetLook replaces an existing look).
"""
import copy
import os
import re
import xml.etree.ElementTree as ET

SET = "Common_GL2"
LNF_NAME = "Schema/TLBBLook_GLv2.looknfeel.xml"
COMMENT = re.compile(r"<!--.*?-->", re.S)
ATTR = re.compile(r'([A-Za-z_][\w:.-]*)\s*=\s*"([^"]*)"')
R9 = r"(LT|T|RT|L|R|LB|B|RB|C|M)"
STATE = {"Normal": "Normal", "Normor": "Normal", "Hover": "Hover", "Pushed": "Pushed", "Push": "Pushed",
         "Disable": "Disable", "Disabled": "Disable", "Dis": "Disable"}
PART = {"LT": "LT", "T": "T", "RT": "RT", "L": "L", "R": "R", "LB": "LB", "B": "B", "RB": "RB", "C": "C", "M": "C",
        "LB2": "LB", "RB2": "RB", "B2": "B", "Left": "L", "Mid": "C", "Right": "R"}
# (regex on "imageset:image", family, group index of the state or None, group index of the part)
FAMILY = [
    (r"^Common_GL:BtnY_(Left|Mid|Right)_(Normal|Hover|Pushed|Disable)$", "BY", 2, 1),
    (r"^Button1:BtnCommon_(Left|Mid|Right)_(Normal|Hover|Pushed|Disable)$", "BY", 2, 1),
    (r"^Common_GL:BtnG_(Left|Mid|Right)_(Normal|Hover|Pushed|Disable)$", "BG", 2, 1),
    (r"^Button1:BtnCommon3_(Left|Mid|Right)_(Normal|Hover|Pushed|Disable)$", "BG", 2, 1),
    (r"^Button4:BtnCommon_Green_(Left|Mid|Right)_(Normal|Hover|Pushed|Disable)$", "BG", 2, 1),
    (r"^Common_GL:BtnR_(Left|Mid|Right)_(Normal|Hover|Pushed|Disable)$", "BR", 2, 1),
    (r"^Button2:BtnCommon2_(Left|Mid|Right)_(Normal|Hover|Pushed|Disable)$", "BR", 2, 1),
    (r"^Common_GL:BtnS_(Left|Mid|Right)_(Normal|Hover|Pushed|Disable)$", "BS", 2, 1),
    (r"^Common_GL:BtnBig_(Normal|Hover|Pushed|Disable)_" + R9 + "$", "BB", 1, 2),
    (r"^Button12:BigBtn_(Normal|Normor|Hover|Pushed|Push|Dis)_" + R9 + "$", "BB", 1, 2),
    (r"^Common_GL:Tab_(Left|Mid|Right)_(Normal|Hover|Pushed|Disable)$", "T", 2, 1),
    (r"^CommonFrame7:FenYe2Btn_(Left|Mid|Right)_(Normal|Hover|Pushed|Disable)$", "T", 2, 1),
    (r"^RosebangUI1:FenYe5Btn_(Left|Mid|Right)_(Normal|Hover|Pushed|Disable)$", "T", 2, 1),
    (r"^Common_GL:TabFull_(Normal|Hover|Pushed|Disable)$", "T", 1, None),
    (r"^Common_GL:Panel_" + R9 + "$", "P", None, 1),
    (r"^Button6:Lace_Frame[1236]_" + R9 + "$", "P", None, 1),
    (r"^ZLHeroMeeting:BKInside_" + R9 + "$", "P", None, 1),
    (r"^Common_GL:Panel_(Left|Mid|Right)$", "E", None, 1),
    (r"^Button3:EditBox_(L|M|R)$", "E", None, 1),
    (r"^Common_GL:Dk1_" + R9 + "$", "E", None, 1),
    (r"^Common_GL:Tip_" + R9 + "$", "TT", None, 1),
    (r"^CommonFrame:CommonFrame2_" + R9 + "$", "TT", None, 1),
    (r"^ZLHeroMeeting:BKBig_" + R9 + "$", "TT", None, 1),
    (r"^Button6:SelectFrame_" + R9 + "$", "TT", None, 1),
    (r"^Common_GL:Lace4_" + R9 + "$", "L", None, 1),
    (r"^Button6:Lace_Frame4_" + R9 + "$", "L", None, 1),
    (r"^Common_GL:Frame_" + R9 + "$", "W", None, 1),
    (r"^Common_GL:Dragon_" + R9 + "$", "D", None, 1),
    (r"^CommonItem:(?:Pet|Player)Frame_(LT|RT|LB2?|RB2?|L|R|T|B2?)$", "M", None, 1),
    (r"^Common_GL:HeroTitle_(L|M|R)$", "HT", None, 1),
    (r"^ZLHeroMeeting:Title_Big_(L|M|R)$", "HT", None, 1),
    (r"^Common_GL:Lace5_(L|M|R)$", "L5", None, 1),
    (r"^Button6:Lace_Frame5_(L|M|R)$", "L5", None, 1),
]
FAMILY = [(re.compile(a), b, c, d) for a, b, c, d in FAMILY]
STATEFUL = {"BY", "BG", "BR", "BS", "BB", "T", "SBM"}
THREE = {"HT", "L5"}
NOCENTER_ART = {"M"}                      # model frame art has no centre piece
# single images: (regex, action, v2 name, forced format or None, state group)
SINGLE = [
    (r"^(?:Common_GL:Slot_Normal|CommonItem:ActionBK|DressBox:DressFrame2)$", "nine", "S", None),
    (r"^(?:Common_GL:Slot_Hover|CommonFrame:ActionButtonHover)$", "nine", "SH", None),
    (r"^(?:Common_GL:Slot_Pushed|CommonFrame:ActionButtonPushed)$", "nine", "SP", None),
    (r"^(?:Common_GL:Slot_Active|Icons0:ButtonActive0)$", "nine", "SP", None),
    (r"^(?:Common_GL:Slot_Disable|Face_04:Remind_Bak)$", "image", "SD", "Stretched"),
    (r"^Common_GL:TabFull_(Normal|Hover|Pushed|Disable)$", "nine_state", "T", None),
    (r"^Button5:BtnPage_(?:Up|Down)_(Normal|Hover|Pushed|Disabled)$", "nine_state", "T", None),
    (r"^(?:Common_GL:Scroll_Track|Button1:ScrollBar_Bar)$", "nine", "SBT", None),
    (r"^(?:Common_GL:Scroll_Thumb|Button1:ScrollBar_Thumb|Button4:ScrollBar_Thumb)_(Normal|Hover|Pushed|Disabled?)$", "thumb", "SBM", None),
    (r"^CommonFrame4:Special_Thumb_(Normal)$", "thumb", "SBM", None),
    (r"^(?:Common_GL:Scroll|Button1:ScrollBar)_Up_(Normal|Hover|Pushed)$", "image_state", "SBU", None),
    (r"^(?:Common_GL:Scroll|Button1:ScrollBar)_Down_(Normal|Hover|Pushed)$", "image_state", "SBD", None),
    (r"^Button3:ComboListButton_(Normal|Hover|Pushed)$", "image_state", "SBD", None),
    (r"^(?:Common_GL:BtnClose|Button1:BtnClose)_(Normal|Hover|Pushed)$", "image_state", "C", None),
    (r"^(?:Common_GL:BtnHelp|Button1:BtnHelp)_(Normal|Hover|Pushed)$", "image_state", "H", None),
    (r"^(?:Common_GL:BtnAdd|Button1:BtnAdd)_(Normal|Hover|Pushed|Disable)$", "image_state", "A", None),
    (r"^(?:Common_GL:BtnClose2|ZLHeroMeeting:Close)_(Normal|Hover|Pushed|Push)$", "image_state", "X2", None),
    (r"^(?:Common_GL:Page_Prev|Button1:BtnTrunLeft)_(Normal|Hover|Pushed|Disable)$", "image_state", "PP", None),
    (r"^(?:Common_GL:Page_Next|Button1:BtnTrunRight)_(Normal|Hover|Pushed|Disable)$", "image_state", "PN", None),
    (r"^(?:Common_GL:Check_Off|Button1:BtnRedio_Normal)$", "image", "CK_Off", None),
    (r"^(?:Common_GL:Check_On|Button1:BtnRedio_Pushed)$", "image", "CK_On", None),
    (r"^(?:Common_GL:Bg|Background:View)$", "image", "Bg", None),
    (r"^(?:Common_GL:Panel_C|Background1:View|CommonFrame:CommonEditBoxBK)$", "image", "P_C", "Stretched"),
    (r"^(?:Common_GL:Tip_C|CommonFrame:PaoPao_BK)$", "image", "TT_C", "Stretched"),
    (r"^(?:Common_GL:Bar_Light|CommonStaticImage:ProgressLight)$", "image", "BarLight", None),
]
SINGLE = [(re.compile(a), b, c, d) for a, b, c, d in SINGLE]
BRUSH_PROPS = ("SelectBrush", "SelectionBrushImage")
W_FRAMES = ("Main_Frame_Type0", "Main_Frame_Type1", "Main_Frame_Type2", "Main_Frame_Type4", "Main_Frame_Type5",
            "Main_Frame_Type7", "Main_Frame_Type20", "Frame_Type_FrameY")
W_BACKS = ("Background_Type1", "Background_Type4", "Background_Type5", "Background_Type7")


def read_text(path):
    with open(path, "rb") as f:
        b = f.read()
    if b[:3] == b"\xef\xbb\xbf":
        b = b[3:]
    try:
        return b.decode("utf-8")
    except UnicodeDecodeError:
        return b.decode("gb18030", errors="replace")


def scheme_lnfs(if_dir):
    t = COMMENT.sub("", read_text(os.path.join(if_dir, "Schema", "WoWLookSkin.scheme.xml")))
    return [dict(ATTR.findall(m.group(1))).get("Filename", "") for m in re.finditer(r"<LookNFeel\b([^>]*)>", t)]


def load_effective_looks(if_dir):
    """name -> (Element, rel) with the last definition winning; our own v2 file is never an input."""
    looks, errors = {}, []
    for rel in scheme_lnfs(if_dir):
        if rel.replace("\\", "/").lower() == LNF_NAME.lower():
            continue
        p = os.path.join(if_dir, rel.replace("/", os.sep))
        if not os.path.isfile(p):
            errors.append("missing " + rel)
            continue
        text = re.sub(r"^\s*<\?xml[^>]*\?>", "", COMMENT.sub("", read_text(p)))
        try:
            els = ET.fromstring(text).findall("WidgetLook")
        except ET.ParseError as ex:
            errors.append("parse %s: %s" % (rel, ex))
            els = []
            for m in re.finditer(r"<WidgetLook\b.*?</WidgetLook\s*>", text, re.S):
                try:
                    els.append(ET.fromstring(m.group(0)))
                except ET.ParseError:
                    pass
        for el in els:
            looks[el.get("name")] = (el, rel)
    return looks, errors


# ---------------------------------------------------------------------- XML builders
def _dim(parent, typ, child):
    d = ET.SubElement(parent, "Dim", {"type": typ})
    d.append(child)


def _abs(v):
    return ET.Element("AbsoluteDim", {"value": str(v)})


def _uni(scale, typ, sub=0):
    u = ET.Element("UnifiedDim", {"scale": str(scale), "type": typ})
    if sub:
        op = ET.SubElement(u, "DimOperator", {"op": "Subtract"})
        op.append(_abs(sub))
    return u


def area_full():
    a = ET.Element("Area")
    _dim(a, "LeftEdge", _abs(0))
    _dim(a, "TopEdge", _abs(0))
    _dim(a, "Width", _uni(1, "Width"))
    _dim(a, "Height", _uni(1, "Height"))
    return a


def area_inset(l, t, r, b):
    a = ET.Element("Area")
    _dim(a, "LeftEdge", _abs(l))
    _dim(a, "TopEdge", _abs(t))
    _dim(a, "RightEdge", _uni(1, "RightEdge", r))
    _dim(a, "BottomEdge", _uni(1, "BottomEdge", b))
    return a


NINE_TYPES = (("TopLeftCorner", "LT"), ("TopRightCorner", "RT"), ("BottomLeftCorner", "LB"), ("BottomRightCorner", "RB"),
              ("LeftEdge", "L"), ("RightEdge", "R"), ("TopEdge", "T"), ("BottomEdge", "B"))


def frame9(prefix, center=False, area=None):
    fc = ET.Element("FrameComponent")
    fc.append(area if area is not None else area_full())
    for t, k in NINE_TYPES:
        ET.SubElement(fc, "Image", {"type": t, "imageset": SET, "image": "%s_%s" % (prefix, k)})
    if center:
        ET.SubElement(fc, "Image", {"type": "Background", "imageset": SET, "image": prefix + "_C"})
        ET.SubElement(fc, "VertFormat", {"type": "Stretched"})
        ET.SubElement(fc, "HorzFormat", {"type": "Stretched"})
    return fc


def frame3(prefix, area=None):
    fc = ET.Element("FrameComponent")
    fc.append(area if area is not None else area_full())
    ET.SubElement(fc, "Image", {"type": "LeftEdge", "imageset": SET, "image": prefix + "_L"})
    ET.SubElement(fc, "Image", {"type": "RightEdge", "imageset": SET, "image": prefix + "_R"})
    ET.SubElement(fc, "Image", {"type": "Background", "imageset": SET, "image": prefix + "_M"})
    ET.SubElement(fc, "VertFormat", {"type": "Stretched"})
    ET.SubElement(fc, "HorzFormat", {"type": "Stretched"})
    return fc


def tile(image, inset, fmt="Tiled"):
    ic = ET.Element("ImageryComponent")
    ic.append(area_inset(*inset))
    ET.SubElement(ic, "Image", {"imageset": SET, "image": image})
    ET.SubElement(ic, "VertFormat", {"type": fmt})
    ET.SubElement(ic, "HorzFormat", {"type": fmt})
    return ic


def grip(area):
    ic = ET.Element("ImageryComponent")
    ic.append(copy.deepcopy(area) if area is not None else area_full())
    ET.SubElement(ic, "Image", {"imageset": SET, "image": "SBG"})
    ET.SubElement(ic, "VertFormat", {"type": "CentreAligned"})
    ET.SubElement(ic, "HorzFormat", {"type": "CentreAligned"})
    return ic


class Transformer:
    def __init__(self, geo, pieces):
        self.geo = geo                    # {"W_inset": (l,t,r,b), "D_inset": (...)}
        self.pieces = set(pieces)         # names present in the v2 atlas
        self.stats = {}

    def _note(self, k):
        self.stats[k] = self.stats.get(k, 0) + 1

    # -- A: sections of the shared looks
    def section_components(self, look, name):
        g = self.geo
        if name in W_FRAMES:
            return [frame9("W")]
        if name == "Main_Frame_Type3":
            return [frame9("D")]
        if name in W_BACKS or (look == "TLBB_GL_Common" and name == "Background_Common"):
            return [tile("Bg", g["W_inset"])]
        if name == "Background_Type3":
            return [tile("Bg", g["D_inset"])]
        if name == "Main_Frame_Back_Type1":
            return []
        if look == "TLBB_GL_Common":
            if name in ("Frame_Type_Lace1", "Frame_Type_Lace2", "Frame_Type_Lace3"):
                return [frame9("P")]
            if name == "Background_Common1":
                return [tile("P_C", (2, 2, 2, 2), "Stretched")]
            if name == "Frame_Type_Lace4":
                return [frame9("L")]
            if name == "Frame_Type_Lace5":
                return [frame3("L5")]
            if name == "Frame_Type2":
                return [frame9("TT")]
            if name == "Background_Frame_Type2":
                return [tile("TT_C", (4, 4, 4, 4), "Stretched")]
            if name == "Main_HeroFrame_Type1":
                return [frame9("TT"), tile("TT_C", (4, 4, 4, 4), "Stretched")]
            if name == "Hero_Title_Type01":
                return [frame3("HT")]
        return None

    # -- B: frame families
    def family_of(self, key):
        for rx, fam, sg, pg in FAMILY:
            m = rx.match(key)
            if m:
                st = STATE.get(m.group(sg), "Normal") if sg else None
                part = PART.get(m.group(pg), None) if pg else "C"
                return fam, st, part
        return None

    def map_frame(self, fc):
        imgs = fc.findall("Image")
        if not imgs:
            return False
        if len(imgs) == 1 and (imgs[0].get("type") or "Background") == "Background":
            key = "%s:%s" % (imgs[0].get("imageset"), imgs[0].get("image"))
            if self.family_of(key) is None:
                s = self.single_of(key) or self.bar_of(key)
                if s and s[0] in ("image", "image_state"):
                    new = "%s_%s" % (s[1], s[3]) if s[0] == "image_state" else s[1]
                    if new in self.pieces:
                        imgs[0].set("imageset", SET)
                        imgs[0].set("image", new)
                        if s[2]:
                            for tag in ("VertFormat", "HorzFormat", "VertFormatProperty", "HorzFormatProperty"):
                                for x in fc.findall(tag):
                                    fc.remove(x)
                            ET.SubElement(fc, "VertFormat", {"type": s[2]})
                            ET.SubElement(fc, "HorzFormat", {"type": s[2]})
                        self._note("frameimage:" + s[1])
                        return True
                if s and s[0] in ("nine", "nine_state", "thumb"):
                    prefix = "%s_%s" % (s[1], s[3]) if s[0] in ("nine_state", "thumb") else s[1]
                    fc.remove(imgs[0])
                    for x in fc.findall("VertFormat") + fc.findall("HorzFormat"):
                        fc.remove(x)
                    for t, k in NINE_TYPES:
                        ET.SubElement(fc, "Image", {"type": t, "imageset": SET, "image": "%s_%s" % (prefix, k)})
                    ET.SubElement(fc, "Image", {"type": "Background", "imageset": SET, "image": prefix + "_C"})
                    ET.SubElement(fc, "VertFormat", {"type": "Stretched"})
                    ET.SubElement(fc, "HorzFormat", {"type": "Stretched"})
                    self._note("frame9:" + s[1])
                    return True
                return False
        fams = set()
        has_bg = False
        for e in imgs:
            f = self.family_of("%s:%s" % (e.get("imageset"), e.get("image")))
            if f is None:
                return False
            fams.add(f[:2])
            if (e.get("type") or "Background") == "Background":
                has_bg = True
        if len(fams) != 1:
            return False
        fam, st = fams.pop()
        prefix = "%s_%s" % (fam, st) if fam in STATEFUL else fam
        for e in imgs + fc.findall("VertFormat") + fc.findall("HorzFormat"):
            fc.remove(e)
        if fam in THREE:
            for t, k in (("LeftEdge", "L"), ("RightEdge", "R"), ("Background", "M")):
                ET.SubElement(fc, "Image", {"type": t, "imageset": SET, "image": "%s_%s" % (prefix, k)})
        else:
            for t, k in NINE_TYPES:
                ET.SubElement(fc, "Image", {"type": t, "imageset": SET, "image": "%s_%s" % (prefix, k)})
            if has_bg and fam not in NOCENTER_ART:
                ET.SubElement(fc, "Image", {"type": "Background", "imageset": SET, "image": prefix + "_C"})
        ET.SubElement(fc, "VertFormat", {"type": "Stretched"})
        ET.SubElement(fc, "HorzFormat", {"type": "Stretched"})
        self._note("frame:" + fam)
        return True

    # -- C: single images
    def single_of(self, key):
        for rx, act, name, fmt in SINGLE:
            m = rx.match(key)
            if m:
                st = STATE.get(m.group(1), "Normal") if m.groups() else None
                return act, name, fmt, st
        m = re.match(r"^Common_GL:Bar_(\w+)$", key)
        if m and ("Bar_" + m.group(1)) in self.pieces:
            return "image", "Bar_" + m.group(1), None, None
        return None

    def map_imagery(self, ic):
        """returns None (unchanged) or the list of elements replacing ic."""
        e = ic.find("Image")
        if e is None:
            return None
        key = "%s:%s" % (e.get("imageset"), e.get("image"))
        s = self.single_of(key) or self.bar_of(key)
        if s is None:
            return None
        act, name, fmt, st = s
        area = ic.find("Area")
        if act in ("nine", "nine_state", "thumb"):
            prefix = "%s_%s" % (name, st) if act in ("nine_state", "thumb") else name
            fc = frame9(prefix, center=True, area=copy.deepcopy(area) if area is not None else None)
            for c in ic.findall("Colours") + ic.findall("ColourProperty"):
                fc.append(copy.deepcopy(c))
            self._note("imagery:" + name)
            return [fc, grip(area)] if act == "thumb" else [fc]
        new = "%s_%s" % (name, st) if act == "image_state" else name
        if new not in self.pieces:
            return None
        e.set("imageset", SET)
        e.set("image", new)
        if fmt:
            for tag in ("VertFormat", "HorzFormat"):
                for x in ic.findall(tag):
                    ic.remove(x)
            for tag in ("VertFormatProperty", "HorzFormatProperty"):
                for x in ic.findall(tag):
                    ic.remove(x)
            ET.SubElement(ic, "VertFormat", {"type": fmt})
            ET.SubElement(ic, "HorzFormat", {"type": fmt})
        self._note("image:" + name)
        return [ic]

    def bar_of(self, key):
        tag = self.bar_keys.get(key) if hasattr(self, "bar_keys") else None
        return ("image", "Bar_" + tag, None, None) if tag and ("Bar_" + tag) in self.pieces else None

    # -- D: property values
    def map_value(self, prop, v):
        m = re.search(r"set:\s*([^\s\"]+)\s+image:\s*([^\s\"]+)", v or "")
        if not m:
            return None
        key = "%s:%s" % (m.group(1), m.group(2))
        if prop in BRUSH_PROPS:
            return "set:%s image:SEL" % SET
        s = self.single_of(key)
        if not s:
            return None
        act, name, fmt, st = s
        new = "%s_%s" % (name, st) if act == "image_state" else (name if act == "image" else None)
        if new is None and act in ("nine", "nine_state"):
            return None
        if new not in self.pieces:
            return None
        return v[:m.start()] + "set:%s image:%s" % (SET, new) + v[m.end():]

    # -- whole look
    def transform(self, name, el):
        new = copy.deepcopy(el)
        changes = []
        if name in ("TLBB_Look_Common", "TLBB_GL_Common"):
            for sec in new.findall("ImagerySection"):
                comps = self.section_components(name, sec.get("name"))
                if comps is None:
                    continue
                keep = [copy.deepcopy(c) for c in sec if c.tag in ("Colours", "ColourProperty")]
                for c in list(sec):
                    sec.remove(c)
                for c in keep + comps:
                    sec.append(c)
                changes.append("section " + sec.get("name"))
                self._note("section")
        for sec in new.iter("ImagerySection"):
            for comp in list(sec):
                if comp.tag == "FrameComponent" and comp.find("Image") is not None:
                    if comp.find("Image").get("imageset") == SET:
                        continue
                    if self.map_frame(comp):
                        changes.append("frame %s" % sec.get("name"))
                elif comp.tag == "ImageryComponent":
                    rep = self.map_imagery(comp)
                    if rep is not None and rep != [comp]:
                        i = list(sec).index(comp)
                        sec.remove(comp)
                        for k, r in enumerate(rep):
                            sec.insert(i + k, r)
                        changes.append("imagery %s" % sec.get("name"))
                    elif rep == [comp]:
                        changes.append("image %s" % sec.get("name"))
        for p in new.iter("Property"):
            k = p.get("name") or p.get("Name")
            vk = "value" if p.get("value") is not None else "Value"
            nv = self.map_value(k, p.get(vk))
            if nv is not None and nv != p.get(vk):
                p.set(vk, nv)
                changes.append("property " + k)
                self._note("property")
        return (new, changes) if changes else (None, [])


def serialize(looks_out, header):
    """UTF-8 BOM + CRLF, ' />' self-closing (ElementTree default)."""
    parts = ['<?xml version="1.0" ?>', "<!-- %s -->" % header, "<Falagard>"]
    for el in looks_out:
        ET.indent(el, space="  ", level=1)
        el.tail = None
        parts.append("  " + ET.tostring(el, encoding="unicode").rstrip())
    parts.append("</Falagard>")
    text = "\r\n".join("\n".join(parts).split("\n")) + "\r\n"
    return b"\xef\xbb\xbf" + text.encode("utf-8")
