#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verify_cursor.py -- runtime proof that the CY-Source cursor fix works.

Run this WHILE a staged Game.exe built from this fix is showing its
offline login screen (Game.exe -fl) with the game window focused, so the
cursor Windows reports system-wide is the one CCursorMng set.

Checks performed, and why each one is meaningful rather than cosmetic:

  1. GetCursorInfo(): flags must include CURSOR_SHOWING and hCursor must
     be non-NULL. This is the literal negation of the reported bug --
     CCursorMng::Initial used to call LoadCursorFromFile against
     "..\\Data\\Cursor\\*.ani", a folder that ships in none of Canonical,
     client_GL or the build stage, so every handle came back NULL and
     OnSetCursor() called ::SetCursor(NULL): an invisible cursor.

  2. GetIconInfo() on that live hCursor, decoded with GetDIBits(): the
     actual pixel content of the cursor Windows is CURRENTLY showing is
     compared against Src\\Client\\WXClient\\Res\\gl\\GL_Normal.cur (the
     file Tools\\cursor\\extract_cursors.py rebuilt from client_GL's own
     Game.exe). HCURSOR handle values are not guaranteed comparable
     across processes, so this script does not rely on that; comparing
     the decoded pixels of the live handle against the known-good art is
     a stronger proof of "this is really B's normal cursor" than any
     handle-equality check could be.

  3. A screenshot centered on the cursor's on-screen position, with the
     live hCursor additionally stamped onto it via DrawIconEx. This is
     not decorative: plain BitBlt screen capture does not include the
     hardware cursor overlay, so an unmodified screenshot would show an
     empty desktop under the mouse even when the cursor is genuinely
     visible. DrawIconEx renders the exact handle GetCursorInfo returned,
     at the exact position it reported, so the saved PNG is genuine
     evidence of what GetCursorInfo() found, not a separately-staged
     illustration.

Usage:
    python verify_cursor.py --expect ..\\..\\Src\\Client\\WXClient\\Res\\gl\\GL_Normal.cur --out .

Exit code 0 = all checks passed; 1 = a check failed (see JSON report for
which one); 2 = usage/environment error (e.g. no window has a cursor set
yet -- retry after the login screen has actually painted).
"""
import argparse
import ctypes
import ctypes.wintypes as wt
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import extract_cursors as ec  # reuse dib_to_rgba / write_png -- see that module for format notes

user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32

CURSOR_SHOWING = 0x00000001
DIB_RGB_COLORS = 0
SRCCOPY = 0x00CC0020
DI_NORMAL = 0x0003


class CURSORINFO(ctypes.Structure):
    _fields_ = [("cbSize", wt.DWORD), ("flags", wt.DWORD),
                ("hCursor", wt.HANDLE), ("ptScreenPos", wt.POINT)]


class ICONINFO(ctypes.Structure):
    _fields_ = [("fIcon", wt.BOOL), ("xHotspot", wt.DWORD), ("yHotspot", wt.DWORD),
                ("hbmMask", wt.HANDLE), ("hbmColor", wt.HANDLE)]


class BITMAP(ctypes.Structure):
    _fields_ = [("bmType", ctypes.c_long), ("bmWidth", ctypes.c_long), ("bmHeight", ctypes.c_long),
                ("bmWidthBytes", ctypes.c_long), ("bmPlanes", wt.WORD), ("bmBitsPixel", wt.WORD),
                ("bmBits", ctypes.c_void_p)]


class BITMAPINFOHEADER(ctypes.Structure):
    _fields_ = [("biSize", wt.DWORD), ("biWidth", ctypes.c_long), ("biHeight", ctypes.c_long),
                ("biPlanes", wt.WORD), ("biBitCount", wt.WORD), ("biCompression", wt.DWORD),
                ("biSizeImage", wt.DWORD), ("biXPelsPerMeter", ctypes.c_long),
                ("biYPelsPerMeter", ctypes.c_long), ("biClrUsed", wt.DWORD), ("biClrImportant", wt.DWORD)]


# CYS: explicit argtypes/restype for every WinAPI call below. Without
# these, ctypes falls back to guessing a call signature from the Python
# values passed in, and for a HANDLE/HBITMAP that is a large 64-bit value
# (routine on a 64-bit process) it can guess a 32-bit C int and raise
# "OverflowError: int too long to convert" -- caught the hard way the
# first time this script ran against a real live cursor handle.
user32.GetCursorInfo.argtypes = [ctypes.POINTER(CURSORINFO)]
user32.GetCursorInfo.restype = wt.BOOL
user32.GetIconInfo.argtypes = [wt.HANDLE, ctypes.POINTER(ICONINFO)]
user32.GetIconInfo.restype = wt.BOOL
user32.DrawIconEx.argtypes = [wt.HDC, ctypes.c_int, ctypes.c_int, wt.HANDLE, ctypes.c_int, ctypes.c_int,
                               wt.UINT, wt.HBRUSH, wt.UINT]
user32.DrawIconEx.restype = wt.BOOL
user32.GetDC.argtypes = [wt.HWND]
user32.GetDC.restype = wt.HDC
user32.ReleaseDC.argtypes = [wt.HWND, wt.HDC]
user32.ReleaseDC.restype = ctypes.c_int
gdi32.GetObjectW.argtypes = [wt.HANDLE, ctypes.c_int, wt.LPVOID]
gdi32.GetObjectW.restype = ctypes.c_int
gdi32.GetDIBits.argtypes = [wt.HDC, wt.HANDLE, wt.UINT, wt.UINT, wt.LPVOID,
                             ctypes.POINTER(BITMAPINFOHEADER), wt.UINT]
gdi32.GetDIBits.restype = ctypes.c_int
gdi32.CreateCompatibleDC.argtypes = [wt.HDC]
gdi32.CreateCompatibleDC.restype = wt.HDC
gdi32.CreateCompatibleBitmap.argtypes = [wt.HDC, ctypes.c_int, ctypes.c_int]
gdi32.CreateCompatibleBitmap.restype = wt.HANDLE
gdi32.SelectObject.argtypes = [wt.HDC, wt.HANDLE]
gdi32.SelectObject.restype = wt.HANDLE
gdi32.BitBlt.argtypes = [wt.HDC, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int,
                          wt.HDC, ctypes.c_int, ctypes.c_int, wt.DWORD]
gdi32.BitBlt.restype = wt.BOOL
gdi32.DeleteObject.argtypes = [wt.HANDLE]
gdi32.DeleteObject.restype = wt.BOOL
gdi32.DeleteDC.argtypes = [wt.HDC]
gdi32.DeleteDC.restype = wt.BOOL


def get_dib_32bpp_topdown(hdc, hbmp):
    """Return (width, height, bgra_bytes) for a bitmap handle, forcing a
    32bpp top-down readback regardless of the bitmap's native depth."""
    bmp = BITMAP()
    if not gdi32.GetObjectW(hbmp, ctypes.sizeof(BITMAP), ctypes.byref(bmp)):
        raise OSError("GetObjectW failed")
    width, height = bmp.bmWidth, bmp.bmHeight
    bih = BITMAPINFOHEADER(biSize=ctypes.sizeof(BITMAPINFOHEADER), biWidth=width,
                            biHeight=-height, biPlanes=1, biBitCount=32, biCompression=0)
    buf = (ctypes.c_ubyte * (width * height * 4))()
    got = gdi32.GetDIBits(hdc, hbmp, 0, height, buf, ctypes.byref(bih), DIB_RGB_COLORS)
    if got == 0:
        raise OSError("GetDIBits failed")
    return width, height, bytes(buf)


def bgra_to_rgba(buf):
    out = bytearray(len(buf))
    out[0::4] = buf[2::4]
    out[1::4] = buf[1::4]
    out[2::4] = buf[0::4]
    out[3::4] = buf[3::4]
    return bytes(out)


def read_expected_cur_rgba(cur_path):
    """Decode the first frame of a standalone .cur FILE (not a PE
    resource -- so, unlike extract_cursors' PE path, no 4-byte hotspot
    prefix to strip: file-format ICONDIRENTRY carries the hotspot and the
    image bytes are pure DIB) into (width, height, rgba, hotspot)."""
    data = Path(cur_path).read_bytes()
    import struct
    reserved, idtype, count = struct.unpack_from('<HHH', data, 0)
    if reserved != 0 or idtype != 2 or count < 1:
        raise ValueError(f"{cur_path}: not a valid .cur file")
    w, h, cc, res, hx, hy, bytes_in_res, image_off = struct.unpack_from('<BBBBHHII', data, 6)
    dib = data[image_off:image_off + bytes_in_res]
    width, height, rgba = ec.dib_to_rgba(dib)
    return width, height, rgba, (hx, hy)


def compare_rgb(expected_rgba, actual_rgba, width, height, tolerance=24):
    """Compare RGB channels only (alpha handling differs between a
    monochrome-AND-mask cursor's reconstructed hbmColor and our own DIB
    decode), pixel by pixel, allowing a small tolerance for GDI's
    palette/DDB round-tripping. Returns (matches, total, max_diff)."""
    total = width * height
    matches = 0
    max_diff = 0
    for i in range(total):
        eo, ao = i * 4, i * 4
        for c in range(3):
            d = abs(expected_rgba[eo + c] - actual_rgba[ao + c])
            max_diff = max(max_diff, d)
        if all(abs(expected_rgba[eo + c] - actual_rgba[ao + c]) <= tolerance for c in range(3)):
            matches += 1
    return matches, total, max_diff


GCLP_HCURSOR = -12  # class long/ptr index for the window class's cursor


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--expect', required=True, help='Path to the .cur file the live cursor is expected to match (e.g. Res\\gl\\GL_Normal.cur)')
    ap.add_argument('--out', default='.', help='Directory to write verify_cursor.json / verify_cursor_screenshot.png into')
    ap.add_argument('--hwnd', type=lambda s: int(s, 0), default=None,
                     help='Game main window handle (decimal or 0x-hex): if given, also checks that '
                          'GetClassLongPtrW(hwnd, GCLP_HCURSOR) exactly equals GetCursorInfo().hCursor '
                          '-- the strongest available proof the CursorMng robust-fix (SetClassLongPtrW) '
                          'is the thing actually driving what is on screen.')
    args = ap.parse_args()

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    report = {'ok': False, 'checks': {}}

    ci = CURSORINFO()
    ci.cbSize = ctypes.sizeof(CURSORINFO)
    if not user32.GetCursorInfo(ctypes.byref(ci)):
        report['checks']['GetCursorInfo'] = {'ok': False, 'error': 'GetCursorInfo() returned FALSE'}
        _finish(report, out_dir, ok=False)
        return 2

    showing = bool(ci.flags & CURSOR_SHOWING)
    non_null = bool(ci.hCursor)
    report['checks']['GetCursorInfo'] = {
        'ok': showing and non_null,
        'flags': hex(ci.flags),
        'CURSOR_SHOWING_set': showing,
        'hCursor': hex(ci.hCursor) if ci.hCursor else None,
        'hCursor_non_null': non_null,
        'ptScreenPos': [ci.ptScreenPos.x, ci.ptScreenPos.y],
    }

    if args.hwnd is not None:
        user32.GetClassLongPtrW.argtypes = [wt.HWND, ctypes.c_int]
        user32.GetClassLongPtrW.restype = ctypes.c_void_p
        class_cursor = user32.GetClassLongPtrW(args.hwnd, GCLP_HCURSOR)
        report['checks']['class_cursor_equals_live_cursor'] = {
            'ok': bool(class_cursor) and class_cursor == ci.hCursor,
            'hwnd': hex(args.hwnd),
            'class_cursor': hex(class_cursor) if class_cursor else None,
            'live_cursor': hex(ci.hCursor) if ci.hCursor else None,
            'note': 'Exact handle equality: GetClassLongPtrW(hwnd, GCLP_HCURSOR) (what CursorMng\'s '
                    'robust fix sets via SetClassLongPtrW) vs. GetCursorInfo().hCursor (what Windows is '
                    'actually showing right now). Both are read cross-process, from this same script.',
        }

    hdc_screen = user32.GetDC(0)
    pixel_check = {'ok': False}
    if non_null:
        try:
            ii = ICONINFO()
            if not user32.GetIconInfo(ci.hCursor, ctypes.byref(ii)):
                raise OSError("GetIconInfo failed")
            try:
                width, height, bgra = get_dib_32bpp_topdown(hdc_screen, ii.hbmColor if ii.hbmColor else ii.hbmMask)
                actual_rgba = bgra_to_rgba(bgra)
                exp_w, exp_h, exp_rgba, exp_hot = read_expected_cur_rgba(args.expect)
                same_size = (width, height) == (exp_w, exp_h)
                matches = total = max_diff = None
                if same_size:
                    matches, total, max_diff = compare_rgb(exp_rgba, actual_rgba, width, height)
                pixel_check = {
                    'ok': bool(same_size and matches is not None and matches / total >= 0.90),
                    'live_size': [width, height],
                    'expected_size': [exp_w, exp_h],
                    'live_hotspot_from_iconinfo': [ii.xHotspot, ii.yHotspot],
                    'expected_hotspot_from_cur_file': list(exp_hot),
                    'matching_pixels': matches,
                    'total_pixels': total,
                    'match_ratio': (matches / total) if total else None,
                    'max_channel_diff': max_diff,
                    'note': 'RGB compared with tolerance 24/255 per channel; alpha ignored (AND-mask '
                            'vs. DIB-alpha reconstruction differ in GDI even for an identical source image).',
                }
            finally:
                if ii.hbmColor:
                    gdi32.DeleteObject(ii.hbmColor)
                if ii.hbmMask:
                    gdi32.DeleteObject(ii.hbmMask)
        except Exception as exc:
            pixel_check = {'ok': False, 'error': str(exc)}
    report['checks']['pixel_match_vs_expected_cur'] = pixel_check

    # Screenshot: BitBlt a region around the cursor, then DrawIconEx the
    # SAME hCursor GetCursorInfo returned at the SAME position it
    # reported -- see module docstring for why BitBlt alone is not enough.
    shot_check = {'ok': False}
    try:
        box = 160
        cx, cy = ci.ptScreenPos.x, ci.ptScreenPos.y
        x0, y0 = max(cx - box // 2, 0), max(cy - box // 2, 0)
        mem_dc = gdi32.CreateCompatibleDC(hdc_screen)
        bmp = gdi32.CreateCompatibleBitmap(hdc_screen, box, box)
        old = gdi32.SelectObject(mem_dc, bmp)
        gdi32.BitBlt(mem_dc, 0, 0, box, box, hdc_screen, x0, y0, SRCCOPY)
        if non_null:
            user32.DrawIconEx(mem_dc, cx - x0, cy - y0, ci.hCursor, 0, 0, 0, None, DI_NORMAL)
        width, height, bgra = get_dib_32bpp_topdown(hdc_screen, bmp)
        rgba = bgra_to_rgba(bgra)
        png_path = out_dir / 'verify_cursor_screenshot.png'
        ec.write_png(png_path, width, height, rgba)
        gdi32.SelectObject(mem_dc, old)
        gdi32.DeleteObject(bmp)
        gdi32.DeleteDC(mem_dc)
        shot_check = {'ok': True, 'path': str(png_path), 'region': [x0, y0, box, box],
                      'cursor_drawn_at': [cx - x0, cy - y0]}
    except Exception as exc:
        shot_check = {'ok': False, 'error': str(exc)}
    report['checks']['screenshot_with_drawiconex'] = shot_check
    user32.ReleaseDC(0, hdc_screen)

    overall_ok = (report['checks']['GetCursorInfo']['ok']
                  and pixel_check.get('ok', False)
                  and shot_check.get('ok', False))
    if 'class_cursor_equals_live_cursor' in report['checks']:
        overall_ok = overall_ok and report['checks']['class_cursor_equals_live_cursor']['ok']
    return _finish(report, out_dir, overall_ok)


def _finish(report, out_dir, ok):
    report['ok'] = ok
    path = out_dir / 'verify_cursor.json'
    path.write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report, indent=2))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
