# -*- coding: utf-8 -*-
"""Do be rong chu dung DUNG font va DUNG phep tinh cua engine CEGUI 0.4.1 trong CY-Source.

Bang chung cho tung buoc (doc truc tiep tu ma nguon, khong uoc luong):

  1. Chon bien the font theo CodePage:
     Src/ThirdParty/CEGUI-0.4.1/CEGUI/include/CysFontDefinition.h :: select(codePage)
     Runtime CodePage = System_CodePage trong Bin64/WXSystem.cfg (hien la 65001)
     -> Src/Client/CEGUISystem/UISystem.cpp:374-376
  2. Size cua font doc bang getValueAsInteger => "14.1" bi cat thanh 14 (uint)
     Src/ThirdParty/CEGUI-0.4.1/CEGUI/src/CEGUIFont_xmlHandler.cpp:87
     Src/ThirdParty/CEGUI-0.4.1/CEGUI/src/CEGUIXMLAttributes.cpp:130-148
  3. FT_Set_Char_Size(face, 0, ptSize*64, 96, 96)  (DPI 96 la hang so cua renderer)
     Src/ThirdParty/CEGUI-0.4.1/CEGUI/src/CEGUIFont_FreeType.cpp:126-135
     Src/ThirdParty/CEGUI-0.4.1/CEGUIRenderer/include/OgreCEGUIRenderer.h:273 -> 96
  4. advance = glyph->advance.x >> 6 (so nguyen pixel), nap bang
     FT_LOAD_RENDER|FT_LOAD_NO_AUTOHINT|FT_LOAD_TARGET_NORMAL
     Src/ThirdParty/CEGUI-0.4.1/CEGUI/src/CEGUIFont_FreeType.cpp:163-217
  5. Be rong chuoi = TONG advance cua tung ma diem; ma diem markup (0xFA/0xFB/0xFC/0xFD/0xFE)
     khong cong be rong (tru animate 0xFA/0xE3).
     Src/ThirdParty/CEGUI-0.4.1/CEGUI/src/CEGUIFontBase.cpp:390-460 (getTextExtent)
"""

import os
import re
import freetype

FT_LOAD_RENDER = 4
FT_LOAD_NO_AUTOHINT = 32768
FT_LOAD_TARGET_NORMAL = 0
LOAD_FLAGS = FT_LOAD_RENDER | FT_LOAD_NO_AUTOHINT | FT_LOAD_TARGET_NORMAL

DPI = 96  # OgreCEGUIRenderer::getHorzScreenDPI() -> 96


class Font(object):
    """Mot font da chon bien the CodePage, do be rong y het Font_FreeType."""

    def __init__(self, name, ttf_path, pt_size):
        self.name = name
        self.path = ttf_path
        self.pt_size = pt_size
        self.face = freetype.Face(ttf_path)
        self.face.select_charmap(freetype.FT_ENCODING_UNICODE)
        # FT_Set_Char_Size(face, 0, ptSize*64, 96, 96)
        self.face.set_char_size(0, int(pt_size) * 64, DPI, DPI)
        self._adv = {}
        self.line_height = None
        # ui-fit-3: khoang cach dong y het Font_FreeType::updateFontInfo
        #   d_lineSpacing = (face->height / face->units_per_EM) * face->size->metrics.y_ppem
        #   Src/ThirdParty/CEGUI-0.4.1/CEGUI/src/CEGUIFont_FreeType.cpp:151
        try:
            self.line_spacing = (float(self.face.height) / float(self.face.units_per_EM)) \
                * float(self.face.size.y_ppem)
        except Exception:
            self.line_spacing = float(pt_size) * DPI / 72.0

    def advance(self, ch):
        cp = ord(ch)
        a = self._adv.get(cp)
        if a is None:
            try:
                self.face.load_char(ch, LOAD_FLAGS)
                a = self.face.glyph.advance.x >> 6
                self._missing = getattr(self, "_missing", set())
                if self.face.get_char_index(cp) == 0:
                    self._missing.add(cp)
            except Exception:
                a = 0
            self._adv[cp] = a
        return a

    def has_glyph(self, ch):
        return self.face.get_char_index(ord(ch)) != 0

    def extent(self, text):
        """Tong advance, bo qua ma diem markup - giong FontBase::getTextExtent."""
        return sum(self.advance(c) for c in text)


_SIZE_RE = re.compile(r'Size\s*=\s*"([^"]*)"')
_NAME_RE = re.compile(r'Name\s*=\s*"([^"]*)"')
_FILE_RE = re.compile(r'Filename\s*=\s*"([^"]*)"')
_CP_RE = re.compile(r'CodePage\s*=\s*"([^"]*)"')
_TYPE_RE = re.compile(r'Type\s*=\s*"([^"]*)"')
_FONTLINE_RE = re.compile(r"<Font\b[^>]*/?>")


def parse_int_attr(value, default):
    """istringstream >> int : "14.1" -> 14, "" -> loi -> default."""
    m = re.match(r"\s*([+-]?\d+)", value or "")
    return int(m.group(1)) if m else default


def load_fonts(schema_dir, ui_root, code_page=65001):
    """Doc *.font trong Schema, chon bien the CodePage, tra {ten: Font}."""
    fonts = {}
    for fn in sorted(os.listdir(schema_dir)):
        if not fn.endswith(".font"):
            continue
        raw = open(os.path.join(schema_dir, fn), "r", encoding="utf-8", errors="replace").read()
        chosen = None
        for line in _FONTLINE_RE.findall(raw):
            cp = _CP_RE.search(line)
            if cp and parse_int_attr(cp.group(1), -1) == code_page:
                chosen = line
                break
        if chosen is None:
            continue
        name = _NAME_RE.search(chosen).group(1)
        filename = _FILE_RE.search(chosen).group(1)
        ftype = (_TYPE_RE.search(chosen).group(1) if _TYPE_RE.search(chosen) else "FreeType")
        if ftype != "FreeType":
            continue
        size = parse_int_attr(_SIZE_RE.search(chosen).group(1) if _SIZE_RE.search(chosen) else "12", 12)
        path = os.path.join(ui_root, filename.replace("/", os.sep))
        if not os.path.isfile(path):
            continue
        fonts[name] = Font(name, path, size)
    return fonts


# -------------------------------------------------------------- info link
#
# ui-fit-3 19/09, dong bo voi `info-links`: BAN GUONG THU BA cua bo phan tich.
#
# Nhanh `info-links` cai dat cac the toa do cua CY (`#{_INFOAIM<x>,<y>,<scene>,<ten>}` + 11 ho anh em).
# Truoc do chung phat ra 0 ky tu; nay chung no thanh `#aB{x,y,scene,type,target}#u[x,y]#u#aE`, tuc phan
# NHIN THAY duoc la `[x,y]`. Ho tu khai co HAI ban guong cua bo phan tich (`UIString.cpp` cua game va
# `UiViewerText.cpp` cua CysUiViewer); bo do nay la ban thu BA - khong dong bo thi moi phep do be rong
# lech AM THAM tren moi chuoi co the.
#
# Nguon su that duy nhat: Src/Client/CEGUISystem/CysInfoLink.h (header-only, cac dia chi RE cua CY 3.71
# nam trong khoi chu thich dau file do). Phan duoi day chep lai DUNG ngu nghia cua:
#   CysInfoLink::Tags / ReadInt / SafeTarget / Parse / Format / Expand
# va cho noi vao dung cho ma `UIString.cpp:693-706` chen nhanh: THU no the TRUOC, no duoc thi KHONG tra
# tu dien nua (`else if(!bInfoLink)` o UIString.cpp:781).

# (the, ma loai) - the DAI dung truoc de tien to khong che mat anh em dai hon (CysInfoLink.h::Tags)
_INFO_TAGS = (
    ("_INFOUSEITEM", 2), ("_INFO2WYXZ", 8), ("_INFO2CITY", 5), ("_INFO2HOME", 6),
    ("_INFO2LINE", 7), ("_INFOCITY", 5), ("_INFOHOME", 6), ("_INFOKILL", 1),
    ("_GETITEM", 3), ("_INFOAIM", 0), ("_INFOMAP", 0), ("_GETPET", 4),
)


def _info_read_int(s, i):
    """CysInfoLink::ReadInt - dau, chu so (gia tri ngung cong khi >= 1e8), phan thap phan bi CAT."""
    begin = i
    n = len(s)
    negative = False
    if i < n and s[i] in "+-":
        negative = s[i] == "-"
        i += 1
    digits = 0
    value = 0
    while i < n and s[i].isdigit() and s[i] in "0123456789":
        if value < 100000000:
            value = value * 10 + (ord(s[i]) - 48)
        digits += 1
        i += 1
    if digits == 0:
        return None, begin
    if i < n and s[i] == ".":
        i += 1
        while i < n and s[i] in "0123456789":
            i += 1
    return (-value if negative else value), i


def info_link_expand(key):
    """CysInfoLink::Expand - `#{<key>}` -> chuoi sieu lien ket cua CY, hoac None neu khong phai the toa do."""
    hit = None
    for tag, ltype in _INFO_TAGS:
        if len(key) > len(tag) and key.startswith(tag):
            hit = (tag, ltype)
            break
    if hit is None:
        return None
    i = len(hit[0])
    x, i = _info_read_int(key, i)
    if x is None or i >= len(key) or key[i] != ",":
        return None
    i += 1
    y, i = _info_read_int(key, i)
    if y is None or i >= len(key) or key[i] != ",":
        return None
    i += 1
    scene, i = _info_read_int(key, i)
    if scene is None:
        return None
    target = ""
    if i < len(key) and key[i] == ",":
        # SafeTarget: '#', '{', '}' khong bao gio duoc vao khoa
        target = "".join(c for c in key[i + 1:] if c not in "#{}")
    return "#aB{%d,%d,%d,%d,%s}#u[%d,%d]#u#aE" % (x, y, scene, hit[1], target, x, y)


# ---------------------------------------------------------------- markup

_EMOTE_RE = re.compile(r"^#(-?\d{1,2})")


def expand_markup(text, dictionary, depth=0, infolink=True):
    """Tra ve (chuoi hien thi, co_markup_dong).

    Xu ly y nhu CUIStringSystem::_ParseString cho phan anh huong be rong:
      #{KEY} -> the toa do CY (xem info_link_expand) TRUOC, khong duoc thi tra bang;
      #r -> xuong dong; #b #u #n #c.. -> ma diem 0 be rong;
      #aB{..} / #aE -> hyperlink (0 be rong); #NN -> bieu tuong (co be rong, bo qua o day).

    `infolink=False` tai hien THE GIOI CU (truoc nhanh `info-links` 19/09), dung de tach rieng anh huong
    cua viec cac the nay bat dau hien chu - khong phai de dung that.
    """
    if depth > 4 or not text:
        return text or "", False
    out = []
    i = 0
    n = len(text)
    lost = False
    while i < n:
        c = text[i]
        if c != "#":
            out.append(c)
            i += 1
            continue
        if i + 1 >= n:
            i += 1
            continue
        nxt = text[i + 1]
        if nxt == "{":
            j = text.find("}", i + 2)
            if j < 0:
                out.append(c)
                i += 1
                continue
            key = text[i + 2:j]
            # CYS-INFOLINK: UIString.cpp:693 dat nhanh nay TRUOC moi nhanh khac, va UIString.cpp:781
            # doi `else` thanh `else if(!bInfoLink)` -> the da no thi KHONG tra tu dien nua.
            link = info_link_expand(key) if infolink else None
            if link is not None:
                sub, sublost = expand_markup(link, dictionary, depth + 1, infolink)
                out.append(sub)
                lost = lost or sublost
            elif key.startswith("_ITEM") or key.startswith("_TIME") or key.startswith("_MONEY"):
                out.append("")  # gia tri chay, khong do duoc tinh
                lost = True
            else:
                val = dictionary.get(key)
                if val is None:
                    lost = True
                else:
                    sub, sublost = expand_markup(val, dictionary, depth + 1, infolink)
                    out.append(sub)
                    lost = lost or sublost
            i = j + 1
            continue
        if nxt == "r":
            out.append("\n")
            i += 2
            continue
        if nxt == "#":
            out.append("#")
            i += 2
            continue
        if nxt in "bun":
            i += 2
            continue
        if nxt == "a":
            if i + 2 < n and text[i + 2] == "B":
                j = text.find("}", i + 3)
                i = (j + 1) if j >= 0 and text[i + 3:i + 4] == "{" else i + 3
            else:
                i += 3
            continue
        if nxt in "cge":
            # ui-fit-2 17/09: CysTextColourParser (CysTextColour.h): #c/#g/#e + 6 hex = 8 ky tu, 0 be rong
            # (0xFB mau, 0xD0 gradient, 0xFC vien - FontBase::getTextExtent bo qua ca ba). Truoc day #g/#e chi
            # an 2 ky tu nen 6 chu hex bi do nhu chu that (+45..70 px sai) - do la loi cua bo do, khong phai cua UI.
            m = re.match(r"#[cge]([0-9a-fA-F]{6})", text[i:])
            i += 8 if m else 2
            continue
        if nxt == "C":
            m = re.match(r"#C([0-9a-fA-F]{6}|[0-9a-fA-F]{8}|\d)", text[i:])
            i += len(m.group(0)) if m else 2
            continue
        m = _EMOTE_RE.match(text[i:])
        if m:
            i += len(m.group(0))
            lost = True  # bieu tuong co be rong rieng, khong do o day
            continue
        # ky tu mau mot chu (#R #G #Y ...) - engine nuot mot ky tu
        i += 2
    return "".join(out), lost


def load_dictionary(path):
    """StrDictionary.txt : 2 cot KEY<TAB>VALUE, UTF-8, bo 2 dong dau."""
    d = {}
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for idx, line in enumerate(fh):
            if idx < 2:
                continue
            line = line.rstrip("\r\n")
            if not line or line[0] == "#":
                continue
            parts = line.split("\t")
            if len(parts) != 2:
                continue
            d[parts[0]] = parts[1]
    return d
