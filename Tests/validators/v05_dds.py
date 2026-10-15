# -*- coding: utf-8 -*-
"""V05 dds_check - texture headers (Docs/05 muc 6.3 / 7, Docs/08 muc 3.4 / 3.10).

Checks: 'DDS ' magic (a PNG/JPEG renamed .dds is a warning), fourCC in the allowed set
(DXT1/DXT3/DXT5 + uncompressed ARGB/RGB/L8/A8L8/16-bit; ATI1/ATI2/BC4/BC5 warn - only engines with the
path can read them; DX10 header error - no source uses it and the D3D9 engines cannot), declared data
fits in the file, mipmaps present (warn), power-of-two edges (warn), edges <= 4096 (error),
trailing bytes after the data (warn).
"""
from .common import ERROR, WARN, INFO, F, Report

VID = 'V05'
ALLOWED = {'DXT1', 'DXT3', 'DXT5', 'A8R8G8B8', 'X8R8G8B8', 'A8B8G8R8', 'X8B8G8R8', 'R8G8B8', 'A8L8', 'L8', 'A8',
           'A1R5G5B5', 'A4R4G4B4', 'R5G6B5'}
LIMITED = {'ATI1', 'ATI2', 'BC4U', 'BC4S', 'BC5U', 'BC5S', 'DXT2', 'DXT4'}
MAX_EDGE = 4096


def _pow2(v):
    return v > 0 and not (v & (v - 1))


def check(data, subject='', report=None):
    rep = report if report is not None else Report()
    if data[:4] != b'DDS ':
        kind = F.magic_of(data[:16])
        if kind in ('PNG', 'JPEG'):
            rep.add(VID, WARN, subject, 'file content is %s, not DDS' % kind)
        else:
            rep.add(VID, ERROR, subject, 'not a DDS file (%s)' % kind)
        return rep, None
    if len(data) < 128:
        rep.add(VID, ERROR, subject, 'DDS header truncated (%d bytes)' % len(data))
        return rep, None
    info = F.dds_info(data)
    fmt = info.get('fmt', '')
    w, h, mips = info.get('w', 0), info.get('h', 0), info.get('mips', 0)
    if fmt.startswith('DX10'):
        rep.add(VID, ERROR, subject, 'DX10 extended header (%s) - not readable by the D3D9 engines' % fmt)
    elif fmt in LIMITED:
        rep.add(VID, WARN, subject, 'fourCC %s is only readable by engines with that path' % fmt)
    elif fmt not in ALLOWED:
        rep.add(VID, ERROR, subject, 'pixel format %s not in the allowed set' % fmt)
    if not w or not h:
        rep.add(VID, ERROR, subject, 'zero width/height')
    if max(w, h) > MAX_EDGE:
        rep.add(VID, ERROR, subject, 'edge %dx%d > %d' % (w, h, MAX_EDGE))
    if w and h and not (_pow2(w) and _pow2(h)):
        rep.add(VID, WARN, subject, 'edge %dx%d is not a power of two' % (w, h))
    if mips <= 1 and max(w, h) > 4:
        rep.add(VID, WARN, subject, 'no mipmap chain (%dx%d, mips=%d)' % (w, h, mips))
    if info.get('err') == 'short':
        rep.add(VID, ERROR, subject, 'file shorter than the declared %s %dx%d data' % (fmt, w, h))
    elif 0 < info.get('end', len(data)) < len(data):
        extra = len(data) - info['end']
        rep.add(VID, WARN, subject, '%d byte(s) after the declared image data' % extra)
    rep.add(VID, INFO, subject, '%s %dx%d mips=%d' % (fmt, w, h, mips))
    return rep, info
