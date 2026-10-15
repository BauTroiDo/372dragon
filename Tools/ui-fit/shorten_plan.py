# -*- coding: utf-8 -*-
"""ui-fit-2 (17/09/2026): lap KE HOACH rut ngan chuoi StrDictionary cho vua KHUNG HEP NHAT dang dung khoa do.

Vao:
  --measure   thu muc do cua measure_ui_text.py chay voi --all-rows (co MOI widget, ke ca khong tran)
  --dict      StrDictionary.txt dang chay (mac dinh Assets/CanonicalCY/Data/ConfigFolder/StrDictionary.txt)
  --cy-dict   TSV chu Trung goc CY (extract_cy_dict.py)
  data/short_vi.tsv   ban rut ngan VIET TAY: khoa<TAB>chuoi_ngan[<TAB>ghi chu]  (thang moi luat tu dong)
  data/abbr_vi.tsv    bang viet tat dung chung: muc<TAB>day_du<TAB>viet_tat[<TAB>ghi chu]
  data/nfd_fix.tsv    sua tay cho dong NFD ma NFC khong ghep duoc: khoa<TAB>chuoi_dung

Ra (trong --out):
  plan.tsv            moi khoa: trang thai, ngan sach px, chuoi cu/moi, luat da dung
  override_rows.tsv   dong '#KHOA<TAB>chuoi<TAB>ghi chu' de gop vao Registry/i18n/cy_vi_override.tsv
  manual_queue.tsv    khoa chua vua sau luat tu dong -> can viet tay (co ngan sach, font, chuoi CY)

Cach "vua": voi TUNG widget dang dung khoa (chi cac widget ma chuoi CY goc VUA khung, cy=cy-fit - khung ma CY
da thiet ke cho khoa do), be rong chuoi moi (do bang FreeType, dung font cua widget do) <= be rong khung.
Nut WordWrap* chi cao 18 px (1 dong o 12pt: line spacing 23 px) nen van phai vua mot dong.
Lenh gop: python Tools/ui-fit/shorten_plan.py --measure <dir> --cy-dict <tsv> --out <dir> [--scope fit|over|all]
"""

import argparse
import collections
import csv
import os
import re
import sys
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ceguitext  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(HERE, "data")
DEFAULT_ROOT = r"C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data"
KEY_ONLY = re.compile(r"^\s*#\{([^}]+)\}\s*$")
COMB = re.compile("[\u0300-\u036f]")
HAN = re.compile("[\u4e00-\u9fff]")
LINE_SPACING = {12: 23, 13: 25, 14: 27, 15: 29, 16: 31, 18: 35}  # NotoSansSC @96dpi, Font_FreeType d_lineSpacing


def load_tsv(path, ncols=2):
    rows = []
    if not os.path.exists(path):
        return rows
    with open(path, "r", encoding="utf-8") as fh:
        for i, line in enumerate(fh):
            line = line.rstrip("\r\n")
            if not line or line.startswith("#!"):
                continue
            parts = line.split("\t")
            if i == 0 and parts[0] in ("khoa", "key", "muc", "level"):
                continue
            if len(parts) < ncols:
                continue
            rows.append(parts)
    return rows


def load_dictionary(path):
    d = {}
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for idx, line in enumerate(fh):
            if idx < 2:
                continue
            line = line.rstrip("\r\n")
            if "\t" not in line:
                continue
            k, v = line.split("\t", 1)
            d.setdefault(k, v)
    return d


# ----------------------------------------------------------------- rules

CLASSIFIER = r"(?:cái|chiếc|viên|quyển|tấm|cây|bộ|con|lá|cuốn|thanh|bình|hộp|túi|gói|phần|món|đôi|tờ|cục|khối|hạt|giọt|lần|vị|người|quả|trái)"


def rule_norm(s):
    s = unicodedata.normalize("NFC", s)
    s = s.replace("：", ":").replace("，", ",").replace("。", ".").replace("！", "!").replace("？", "?")
    s = re.sub(r"[ \t]+", " ", s).strip()
    s = re.sub(r"\s+:", ":", s)
    s = re.sub(r"\s+,", ",", s)
    return s


def rule_trail_dot(s):
    # nhan ngan (khong phai cau) khong can dau cham cuoi
    if len(s) <= 24 and s.endswith(".") and not s.endswith(".."):
        return s[:-1]
    return s


def rule_classifier(s):
    # "%s0 cái Đồng Tâm Kết" -> "%s0 Đồng Tâm Kết" ; "5 viên" giu nguyen khi khong co danh tu sau
    s2 = re.sub(r"((?:%s\d|%d|\d+)(?:#[cC][0-9a-fA-F]{6}|#[A-Za-z])*)\s+" + CLASSIFIER + r"\s+(?=\S)", r"\1 ", s)
    return s2


def rule_filler(s):
    s2 = re.sub(r"^(?:(#[cC][0-9a-fA-F]{6}|#[A-Za-z])*)\s*(?:Xin hãy|Xin mời|Vui lòng|Hãy|Xin|Mời)\s+", r"\1", s)
    s2 = re.sub(r"\s+của (?:bạn|ngươi|người chơi|nhân vật)\b", "", s2)
    s2 = re.sub(r"\bgiao diện\s+", "", s2, flags=re.I)
    s2 = re.sub(r"\s+nhân vật$", "", s2)
    # "Tiến độ hiện tại:" -> "Tiến độ:" ; chi bo khi dung SAU mot tu khac (khong bo "Hiện tại không thể...")
    s2 = re.sub(r"(?<=\S)\s+hiện tại", "", s2)
    return s2


def capitalize_like(src_word, short):
    """Giu kieu hoa/thuong cua tu goc; viet tat toan chu hoa (KN, NB, HĐ) giu nguyen."""
    if short.isupper() or (len(short) <= 3 and short == short.upper()):
        return short
    if src_word[:1].isupper() and short[:1].islower():
        return short[:1].upper() + short[1:]
    if src_word[:1].islower() and short[:1].isupper():
        return short[:1].lower() + short[1:]
    return short


class Abbr(object):
    def __init__(self, rows):
        self.levels = collections.defaultdict(list)
        for parts in rows:
            lvl = int(parts[0])
            full, short = parts[1], parts[2]
            self.levels[lvl].append((full, short))
        for lvl in self.levels:
            self.levels[lvl].sort(key=lambda fs: -len(fs[0]))

    def apply(self, s, lvl, measure, fits):
        """Thay tung muc tu dai nhat truoc; dung ngay khi vua."""
        used = []
        for full, short in self.levels.get(lvl, []):
            pat = re.compile(r"(?<![A-Za-zÀ-ỹ])" + re.escape(full) + r"(?![A-Za-zÀ-ỹ])", re.I)
            if not pat.search(s):
                continue
            s2 = pat.sub(lambda m: capitalize_like(m.group(0), short), s)
            if s2 != s:
                used.append("%s>%s" % (full, short))
                s = s2
                if fits(s):
                    break
        return s, used


# --------------------------------------------------------------- measure

class Budget(object):
    __slots__ = ("font", "box_w", "box_h", "horz", "kind", "layout", "widget", "cy_w")

    def __init__(self, r):
        self.font = r["font"]
        self.box_w = float(r["box_w"])
        self.box_h = float(r.get("box_h") or 0)
        self.horz = r["horz"]
        self.kind = r["kind"]
        self.layout = r["layout"]
        self.widget = r["widget"]
        self.cy_w = float(r["cy_w"])


def width_of(text, font, dictionary):
    shown, _ = ceguitext.expand_markup(text, dictionary)
    lines = shown.split("\n") if shown else [""]
    return max(font.extent(l) for l in lines)


def fits_budget(text, b, fonts, dictionary):
    font = fonts.get(b.font) or fonts["SongTiBmp12"]
    shown, _ = ceguitext.expand_markup(text, dictionary)
    lines = shown.split("\n") if shown else [""]
    lsp = LINE_SPACING.get(font.pt_size, 23)
    if b.horz.startswith("WordWrap") and b.box_h >= 2 * lsp:
        # nut cao du 2 dong: xuong dong theo tu
        max_lines = int(b.box_h // lsp)
        n_lines = 0
        for line in lines:
            words = line.split(" ")
            cur = ""
            n_lines += 1
            for w in words:
                cand = (cur + " " + w) if cur else w
                if font.extent(cand) <= b.box_w + 0.5:
                    cur = cand
                else:
                    if font.extent(w) > b.box_w + 0.5:
                        return False
                    cur = w
                    n_lines += 1
        return n_lines <= max_lines
    return max(font.extent(l) for l in lines) <= b.box_w + 0.5


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--measure", required=True)
    ap.add_argument("--data", default=DEFAULT_ROOT)
    ap.add_argument("--dict", default="")
    ap.add_argument("--cy-dict", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--scope", default="fit", choices=("fit", "over", "all"))
    ap.add_argument("--min-box", type=float, default=24.0, help="khung hep hon muc nay coi la cho giu cho (bo qua)")
    args = ap.parse_args()

    ui = os.path.join(args.data, "InterfaceFolder")
    fonts = ceguitext.load_fonts(os.path.join(ui, "Schema"), ui, 65001)
    dict_path = args.dict or os.path.join(args.data, "ConfigFolder", "StrDictionary.txt")
    dictionary = load_dictionary(dict_path)
    cy = {}
    with open(args.cy_dict, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            p = line.rstrip("\r\n").split("\t")
            if len(p) == 2:
                cy.setdefault(p[0], p[1])

    manual = {}
    manual_note = {}
    for parts in load_tsv(os.path.join(DATA_DIR, "short_vi.tsv"), 2):
        manual.setdefault(parts[0], parts[1])
        manual_note[parts[0]] = parts[2] if len(parts) > 2 else ""
    abbr = Abbr(load_tsv(os.path.join(DATA_DIR, "abbr_vi.tsv"), 3))
    nfd_fix = {p[0]: p[1] for p in load_tsv(os.path.join(DATA_DIR, "nfd_fix.tsv"), 2)}

    with open(os.path.join(args.measure, "overflow.csv"), "r", encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh))
    usages = collections.defaultdict(list)
    for r in rows:
        m = KEY_ONLY.match(r["raw"])
        if m:
            usages[m.group(1)].append(r)

    # khoa can xet: co it nhat mot widget HIEN, tran chac chan, theo scope
    def cls_of(r):
        return r["cy"]
    keys = []
    for k, rs in usages.items():
        sure = [r for r in rs if r["visible"] == "1" and float(r["over_px_min"]) > 0.5]
        if not sure:
            continue
        has_fit = any(cls_of(r) == "cy-fit" for r in sure)
        has_over = any(cls_of(r) == "cy-over" for r in sure)
        if args.scope == "fit" and not has_fit:
            continue
        if args.scope == "over" and (has_fit or not has_over):
            continue
        if args.scope == "all" and not (has_fit or has_over):
            continue
        keys.append(k)

    os.makedirs(args.out, exist_ok=True)
    plan, overrides, queue = [], [], []
    stats = collections.Counter()
    for k in sorted(keys, key=lambda k: (-len(usages[k]), k)):
        rs = usages[k]
        cur = dictionary.get(k)
        if cur is None:
            stats["no-dict"] += 1
            continue
        # ngan sach: cac widget ma CY vua (cy-fit); neu khoa chi co cy-over thi lay khung >= min-box va cy_w <= 1.5*box
        buds = [Budget(r) for r in rs if r["cy"] == "cy-fit" and float(r["box_w"]) >= args.min_box]
        if not buds:
            buds = [Budget(r) for r in rs if r["cy"] == "cy-over" and float(r["box_w"]) >= args.min_box
                    and float(r["cy_w"]) <= 1.5 * float(r["box_w"])]
        if not buds:
            # ui-fit-2 vong 3: khoa KHONG co ngan sach do duoc (CY goc cung rong hon 1,5 lan khung, hoac moi
            # cho dung deu la o giu cho) van phai xuat neu co ban VIET TAY - truoc day bi bo IM LANG va 150
            # dong cua batch11 bien mat khong bao loi.
            if k not in manual:
                stats["placeholder-only"] += 1
                continue
            buds = [Budget(r) for r in rs]
        tight = min(buds, key=lambda b: b.box_w)
        tfont = fonts.get(tight.font) or fonts["SongTiBmp12"]

        def fits(text):
            return all(fits_budget(text, b, fonts, dictionary) for b in buds)

        cur_w = width_of(cur, tfont, dictionary)
        cur_fits = fits(cur)
        used = []
        status = ""
        if k in manual:
            new = unicodedata.normalize("NFC", manual[k])
            used.append("tay")
            status = "manual" if fits(new) else "manual-OVER"
        elif cur_fits:
            new = cur
            status = "already"
        else:
            new = rule_norm(cur)
            if new != cur:
                used.append("norm")
            if not fits(new):
                n2 = rule_trail_dot(new)
                if n2 != new:
                    used.append("dot"); new = n2
            if not fits(new):
                n2 = rule_classifier(new)
                if n2 != new:
                    used.append("loai-tu"); new = n2
            if not fits(new):
                n2 = rule_filler(new)
                if n2 != new:
                    used.append("dem"); new = n2
            for lvl in (1, 2):
                if fits(new):
                    break
                new, u = abbr.apply(new, lvl, None, fits)
                used += ["L%d:%s" % (lvl, x) for x in u]
            status = "auto" if fits(new) else "OVER"
        if k in nfd_fix:
            new = nfd_fix[k]
            used.append("nfd-fix")
        new = unicodedata.normalize("NFC", new)
        new_w = width_of(new, tfont, dictionary)
        stats[status] += 1
        entry = {
            "khoa": k, "trang_thai": status, "so_widget": len(rs), "so_khung_ngan_sach": len(buds),
            "khung_px": tight.box_w, "font": tight.font, "kind": tight.kind,
            "cu_px": cur_w, "moi_px": new_w, "cy_px": int(tight.cy_w),
            "luat": ";".join(used), "chuoi_cu": cur, "chuoi_moi": new, "chuoi_cy": cy.get(k, ""),
            "khung_vi_du": tight.layout.split("/")[0], "widget_vi_du": tight.widget,
            "ghi_chu": manual_note.get(k, ""),
        }
        plan.append(entry)
        # ui-fit-2 vong 3: ban VIET TAY luon duoc ap, ke ca khi van con tran vai px (vi du "Khac" 37/35 px:
        # da can nhac, khong co cach viet ngan hon ma con hieu duoc). Truoc day "manual-OVER" bi bo im lang.
        if status in ("auto", "manual", "manual-OVER") and new != cur:
            overrides.append({"ident": "#" + k, "vi": new,
                              "note": "ui-fit-2 17/09: vua %d px %s (%s) %s; cu=%d px%s" % (
                                  tight.box_w, entry["khung_vi_du"], tight.widget, tight.font, cur_w,
                                  (" | " + manual_note[k]) if manual_note.get(k) else "")})
        if status in ("OVER", "manual-OVER"):
            queue.append(entry)

    _write(os.path.join(args.out, "plan.tsv"), plan)
    # CYS-I18NSCOPE 20/09: canh bao SOM ngay o buoc soan, truoc khi ai do chay apply_overrides.
    # Cong CUNG nam o apply_overrides.py (no tu choi ghi); o day chi de nguoi soan thay ngay
    # dong nao se bi chan thay vi phat hien o cuoi duong ong.
    try:
        sys.path.insert(0, HERE)
        from apply_overrides import validate_rows
        bad = validate_rows([(r["ident"].lstrip("#"), r["vi"], r.get("note", ""))
                             for r in overrides])
        if bad:
            print("CANH BAO: %d dong se bi apply_overrides.py TU CHOI (lech tui token):"
                  % len(bad))
            for k, err, zh, v in bad[:10]:
                print("    %-22s %-22s %r -> %r" % (k, err, zh[:26], v[:34]))
    except Exception as ex:                       # khong chan viec soan ke hoach vi loi phu
        print("(khong chay duoc canh bao validate:", ex, ")")
    _write(os.path.join(args.out, "override_rows.tsv"), overrides)
    _write(os.path.join(args.out, "manual_queue.tsv"), queue)
    print("khoa xet:", len(plan), dict(stats))
    print("override rows:", len(overrides), "| manual queue:", len(queue))
    print("->", args.out)


def _write(path, rows):
    if not rows:
        open(path, "w", encoding="utf-8").write("")
        return
    with open(path, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()), delimiter="\t")
        w.writeheader()
        for r in rows:
            w.writerow(r)


if __name__ == "__main__":
    main()
