# -*- coding: utf-8 -*-
"""ui-fit-2: so hai lo anh CysUiViewer (truoc / sau khi rut ngan chuoi) va ghep anh truoc|sau canh nhau.

  python Tools/ui-fit/diff_shots.py --before <D1>/shots --after <D2>/shots --out <D3> [--frames A,B,C] [--top N]

Khong can thu vien ngoai: doc PNG bang zlib + struct (chi anh RGB/RGBA 8 bit, khong interlace - dung dinh dang
CysUiViewer ghi ra). Dem so pixel khac nhau giua hai anh cung ten; xep hang khung doi nhieu nhat; voi cac khung
duoc chon thi ghi mot PNG ghep ngang co vach phan cach.
"""
import argparse
import os
import struct
import zlib


def read_png(path):
    with open(path, "rb") as fh:
        raw = fh.read()
    if raw[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("khong phai PNG: %s" % path)
    pos, idat, w, h, bd, ct = 8, [], 0, 0, 0, 0
    while pos < len(raw):
        ln = struct.unpack(">I", raw[pos:pos + 4])[0]
        typ = raw[pos + 4:pos + 8]
        data = raw[pos + 8:pos + 8 + ln]
        if typ == b"IHDR":
            w, h, bd, ct, _cm, _fm, il = struct.unpack(">IIBBBBB", data)
            if bd != 8 or ct not in (2, 6) or il:
                raise ValueError("chi doc PNG 8-bit RGB/RGBA khong interlace: %s" % path)
        elif typ == b"IDAT":
            idat.append(data)
        elif typ == b"IEND":
            break
        pos += 12 + ln
    ch = 3 if ct == 2 else 4
    dec = zlib.decompress(b"".join(idat))
    stride = w * ch
    out = bytearray(h * stride)
    prev = bytearray(stride)
    p = 0
    for y in range(h):
        f = dec[p]; p += 1
        line = bytearray(dec[p:p + stride]); p += stride
        if f == 1:
            for i in range(ch, stride):
                line[i] = (line[i] + line[i - ch]) & 0xFF
        elif f == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif f == 3:
            for i in range(stride):
                a = line[i - ch] if i >= ch else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 0xFF
        elif f == 4:
            for i in range(stride):
                a = line[i - ch] if i >= ch else 0
                b = prev[i]
                c = prev[i - ch] if i >= ch else 0
                pp = a + b - c
                pa, pb, pc = abs(pp - a), abs(pp - b), abs(pp - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xFF
        out[y * stride:(y + 1) * stride] = line
        prev = line
    return w, h, ch, bytes(out)


def write_png(path, w, h, ch, pix):
    raw = bytearray()
    stride = w * ch
    for y in range(h):
        raw.append(0)
        raw += pix[y * stride:(y + 1) * stride]
    def chunk(typ, data):
        c = struct.pack(">I", len(data)) + typ + data
        return c + struct.pack(">I", zlib.crc32(typ + data) & 0xFFFFFFFF)
    body = (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2 if ch == 3 else 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(raw), 6))
            + chunk(b"IEND", b""))
    with open(path, "wb") as fh:
        fh.write(body)


def diff_count(a, b, tol=12):
    w1, h1, c1, p1 = a
    w2, h2, c2, p2 = b
    if (w1, h1) != (w2, h2):
        return -1
    n = 0
    step = c1
    for i in range(0, len(p1), step):
        if abs(p1[i] - p2[i]) > tol or abs(p1[i + 1] - p2[i + 1]) > tol or abs(p1[i + 2] - p2[i + 2]) > tol:
            n += 1
    return n


def side_by_side(a, b, path, gap=8):
    w1, h1, c1, p1 = a
    w2, h2, c2, p2 = b
    W, H = w1 + gap + w2, max(h1, h2)
    out = bytearray(b"\x20\x24\x2c" * (W * H))   # nen xam nhu viewer
    for (w, h, c, p, x0) in ((w1, h1, c1, p1, 0), (w2, h2, c2, p2, w1 + gap)):
        for y in range(h):
            src = y * w * c
            dst = (y * W + x0) * 3
            if c == 3:
                out[dst:dst + w * 3] = p[src:src + w * 3]
            else:
                for x in range(w):
                    out[dst + x * 3:dst + x * 3 + 3] = p[src + x * 4:src + x * 4 + 3]
    for y in range(H):   # vach phan cach do
        d = (y * W + w1 + gap // 2) * 3
        out[d:d + 3] = b"\xc8\x32\x32"
    write_png(path, W, H, 3, bytes(out))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--before", required=True)
    ap.add_argument("--after", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--frames", default="")
    ap.add_argument("--top", type=int, default=0)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    names = sorted(n for n in os.listdir(args.before) if n.endswith(".png")
                   and os.path.isfile(os.path.join(args.after, n)))
    want = set(x.strip() + ".png" for x in args.frames.split(",") if x.strip())
    scored, missing = [], 0
    for n in names:
        if want and n not in want and not args.top:
            continue
        try:
            a = read_png(os.path.join(args.before, n))
            b = read_png(os.path.join(args.after, n))
        except Exception:
            missing += 1
            continue
        d = diff_count(a, b)
        scored.append((d, n, a, b))
    scored.sort(key=lambda t: -t[0])
    changed = [t for t in scored if t[0] > 0]
    print("anh so duoc: %d | khac nhau: %d | bo qua: %d" % (len(scored), len(changed), missing))
    pick = [t for t in scored if (not want or t[1] in want)]
    if args.top:
        pick = (pick if want else []) + [t for t in changed if t not in pick][:args.top]
    for d, n, a, b in pick:
        side_by_side(a, b, os.path.join(args.out, n[:-4] + "-truoc-sau.png"))
        print("  %-34s %7d pixel doi -> %s" % (n[:-4], d, n[:-4] + "-truoc-sau.png"))
    with open(os.path.join(args.out, "diff.tsv"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("khung\tpixel_doi\n")
        for d, n, _a, _b in scored:
            fh.write("%s\t%d\n" % (n[:-4], d))


if __name__ == "__main__":
    main()
