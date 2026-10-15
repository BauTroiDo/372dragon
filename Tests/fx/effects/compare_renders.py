#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Compare two TlbbViewer render dirs case-by-case (before vs after). Reports byte-identical count and, for
differing PNGs, the decoded max per-channel abs diff and mean diff. At model scale 1.0 the use_scale change is a
no-op, so every case should be byte-identical (regression guard). Usage: compare_renders.py <before> <after>."""
import os
import struct
import sys
import zlib


def decode(path):
    b = open(path, "rb").read()
    if b[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    i = 8
    w = h = color = 0
    idat = bytearray()
    while i + 8 <= len(b):
        ln = struct.unpack_from(">I", b, i)[0]
        typ = b[i + 4:i + 8]
        d = b[i + 8:i + 8 + ln]
        if typ == b"IHDR":
            w, h, _, color = struct.unpack_from(">IIBB", d, 0)
        elif typ == b"IDAT":
            idat += d
        elif typ == b"IEND":
            break
        i += 12 + ln
    ch = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(color, 4)
    raw = zlib.decompress(bytes(idat))
    stride = w * ch
    out = bytearray(w * h * ch)
    prev = bytearray(stride)
    pos = 0
    for y in range(h):
        f = raw[pos]; pos += 1
        line = bytearray(raw[pos:pos + stride]); pos += stride
        if f == 1:
            for x in range(ch, stride):
                line[x] = (line[x] + line[x - ch]) & 0xFF
        elif f == 2:
            for x in range(stride):
                line[x] = (line[x] + prev[x]) & 0xFF
        elif f == 3:
            for x in range(stride):
                a = line[x - ch] if x >= ch else 0
                line[x] = (line[x] + ((a + prev[x]) >> 1)) & 0xFF
        elif f == 4:
            for x in range(stride):
                a = line[x - ch] if x >= ch else 0
                c = prev[x - ch] if x >= ch else 0
                p = a + prev[x] - c
                pa, pb, pc = abs(p - a), abs(p - prev[x]), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (prev[x] if pb <= pc else c)
                line[x] = (line[x] + pr) & 0xFF
        out[y * stride:(y + 1) * stride] = line
        prev = line
    return w, h, ch, out


def main():
    before, after = sys.argv[1], sys.argv[2]
    labels = sorted(f[:-4] for f in os.listdir(before) if f.endswith(".png"))
    ident = same_px = diff = missing = 0
    worst = []
    for lab in labels:
        pa, pb = os.path.join(before, lab + ".png"), os.path.join(after, lab + ".png")
        if not os.path.exists(pb):
            missing += 1
            print("%-22s MISSING in after" % lab)
            continue
        a, b = open(pa, "rb").read(), open(pb, "rb").read()
        if a == b:
            ident += 1
            continue
        da, db = decode(pa), decode(pb)
        if not da or not db or da[:3] != db[:3]:
            diff += 1
            print("%-22s size/format differs" % lab)
            continue
        px_a, px_b = da[3], db[3]
        mx = mean = 0
        n = len(px_a)
        s = 0
        for i in range(n):
            d = abs(px_a[i] - px_b[i])
            if d > mx:
                mx = d
            s += d
        mean = s / n
        if mx == 0:
            same_px += 1
        else:
            diff += 1
            worst.append((mx, mean, lab))
    print("\n%d byte-identical, %d pixel-identical (re-encoded), %d differ, %d missing (of %d)" %
          (ident, same_px, diff, missing, len(labels)))
    for mx, mean, lab in sorted(worst, reverse=True)[:15]:
        print("  %-22s max=%d mean=%.3f" % (lab, mx, mean))
    return 0 if (diff == 0 and missing == 0) else 1


if __name__ == "__main__":
    sys.exit(main())
