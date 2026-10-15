# -*- coding: utf-8 -*-
"""Do be rong mot vai chuoi bang DUNG font client dung - de chon ban dich vua khung.

  python Tools/ui-fit/fit_text.py --font SongTiBmp12 --box 132 "Kinh nghiem hien tai:" "KN hien tai:"
  python Tools/ui-fit/fit_text.py --font SongTiBmp12 --box 132 --digits 8 --file candidates.txt
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ceguitext  # noqa: E402

DEFAULT_DATA = r"C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", default=DEFAULT_DATA)
    ap.add_argument("--font", default="SongTiBmp12")
    ap.add_argument("--box", type=float, default=0.0)
    ap.add_argument("--digits", type=int, default=0, help="so chu so se noi vao sau chuoi")
    ap.add_argument("--file", default="", help="doc them cac chuoi tu file, moi dong mot chuoi")
    ap.add_argument("texts", nargs="*")
    args = ap.parse_args()

    ui = os.path.join(args.data, "InterfaceFolder")
    fonts = ceguitext.load_fonts(os.path.join(ui, "Schema"), ui, 65001)
    if args.font not in fonts:
        raise SystemExit("font khong co: %s (co: %s)" % (args.font, ", ".join(sorted(fonts))))
    font = fonts[args.font]

    items = list(args.texts)
    if args.file:
        with open(args.file, "r", encoding="utf-8") as fh:
            items += [l.rstrip("\r\n") for l in fh if l.strip()]

    pad = "0" * args.digits
    print("font %s = %s %dpt (em %.1f px)" % (font.name, os.path.basename(font.path),
                                              font.pt_size, font.pt_size * 96.0 / 72.0))
    if args.box:
        print("khung %.0f px" % args.box)
    for t in items:
        w = font.extent(t + pad)
        mark = ""
        if args.box:
            mark = "  VUA (con %.0f px)" % (args.box - w) if w <= args.box else "  TRAN %.0f px" % (w - args.box)
        print("%5d px  %-44s%s" % (w, repr(t)[1:-1][:44], mark))


if __name__ == "__main__":
    main()
