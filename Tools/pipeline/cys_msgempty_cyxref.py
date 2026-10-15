# -*- coding: utf-8 -*-
"""CYS-MSGEMPTY: dinh vi khoa cua CY bang XREF CHUOI, khong bang ten ham.

Luat 22.8: dia chi CY phai kem TEN BAN DUNG + sha256, va dinh vi bang CHUOI/KY HIEU.
Bo nay lam dung the: tim chuoi trong tep, doi ra VA, roi quet `.text` tim moi
`lea reg,[rip+disp32]` tro toi dung VA do. Khong doc ten ham, khong tin ghi chu.

Dung de tra loi mot cau hoi dang: "giua hai khoa A va C ma ta BIET, CY dung khoa B nao?"

    python cys_msgempty_cyxref.py --exe <Game.exe> --str KHOA1 --str KHOA2 ... [--window 4096]
"""
import argparse
import hashlib
import os
import re
import struct
import sys


def sha256(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def pe_sections(data):
    e_lfanew = struct.unpack_from('<I', data, 0x3C)[0]
    assert data[e_lfanew:e_lfanew + 4] == b'PE\0\0', "khong phai PE"
    coff = e_lfanew + 4
    nsec = struct.unpack_from('<H', data, coff + 2)[0]
    opt_size = struct.unpack_from('<H', data, coff + 16)[0]
    opt = coff + 20
    magic = struct.unpack_from('<H', data, opt)[0]
    image_base = struct.unpack_from('<Q', data, opt + 24)[0] if magic == 0x20b else \
        struct.unpack_from('<I', data, opt + 28)[0]
    sec = opt + opt_size
    out = []
    for i in range(nsec):
        o = sec + i * 40
        name = data[o:o + 8].rstrip(b'\0').decode('latin-1')
        vsize, vaddr, rsize, raddr = struct.unpack_from('<IIII', data, o + 8)
        out.append({"name": name, "va": image_base + vaddr, "vsize": vsize,
                    "raw": raddr, "rsize": rsize})
    return image_base, out


def off_to_va(secs, off):
    for s in secs:
        if s["raw"] <= off < s["raw"] + s["rsize"]:
            return s["va"] + (off - s["raw"])
    return None


def va_to_off(secs, va):
    for s in secs:
        if s["va"] <= va < s["va"] + s["vsize"]:
            d = va - s["va"]
            if d < s["rsize"]:
                return s["raw"] + d
    return None


LEA_RIP = re.compile(rb'[\x48\x4c]\x8d[\x05\x0d\x15\x1d\x25\x2d\x35\x3d]', re.S)


def xrefs_to(data, secs, target_va, text):
    """moi `lea r64,[rip+disp32]` trong .text tro toi target_va -> tra ve VA cua lenh."""
    hits = []
    base_off = text["raw"]
    base_va = text["va"]
    buf = data[text["raw"]:text["raw"] + text["rsize"]]
    for m in LEA_RIP.finditer(buf):
        i = m.start()
        if i + 7 > len(buf):
            continue
        disp = struct.unpack_from('<i', buf, i + 3)[0]
        next_va = base_va + i + 7
        if next_va + disp == target_va:
            hits.append(base_va + i)
    return hits


KEYLIKE = re.compile(rb'[A-Za-z_][A-Za-z0-9_]{4,79}\x00')


def strings_referenced_in(data, secs, text, lo, hi):
    """moi chuoi dang-khoa duoc `lea rip` tro toi TU trong doan ma [lo,hi]."""
    # 1. ban do VA chuoi -> ten, cho moi section du lieu
    vamap = {}
    for s in secs:
        if s["name"] == ".text":
            continue
        buf = data[s["raw"]:s["raw"] + s["rsize"]]
        for m in KEYLIKE.finditer(buf):
            i = m.start()
            if i and buf[i - 1] not in (0,):
                continue
            vamap[s["va"] + i] = m.group()[:-1].decode('latin-1')
    # 2. quet lea trong doan
    out = []
    base_va = text["va"]
    off_lo = lo - base_va
    off_hi = hi - base_va
    buf = data[text["raw"]:text["raw"] + text["rsize"]]
    for m in LEA_RIP.finditer(buf, max(0, off_lo), min(len(buf), off_hi)):
        i = m.start()
        if i + 7 > len(buf):
            continue
        disp = struct.unpack_from('<i', buf, i + 3)[0]
        tgt = base_va + i + 7 + disp
        if tgt in vamap:
            out.append((base_va + i, vamap[tgt]))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--exe', required=True)
    ap.add_argument('--str', dest='strings', action='append', default=[])
    ap.add_argument('--near', help='VA dang 0x... - liet ke chuoi dang-khoa duoc tro toi quanh do')
    ap.add_argument('--window', type=lambda x: int(x, 0), default=0x400)
    args = ap.parse_args()
    if not args.strings and not args.near:
        ap.error("can --str hoac --near")

    data = open(args.exe, 'rb').read()
    base, secs = pe_sections(data)
    text = next(s for s in secs if s["name"] == ".text")
    print("tep   : %s" % args.exe)
    print("sha256: %s" % sha256(args.exe))
    print("base  : 0x%X   .text VA 0x%X raw 0x%X size 0x%X"
          % (base, text["va"], text["raw"], text["rsize"]))
    print()
    for s in args.strings:
        pat = s.encode('latin-1') + b'\x00'
        offs = []
        start = 0
        while True:
            i = data.find(pat, start)
            if i < 0:
                break
            # phai la dau chuoi: byte truoc la NUL hoac khong in duoc
            if i == 0 or data[i - 1] in (0, 10, 13):
                offs.append(i)
            start = i + 1
        if not offs:
            print("%-42s KHONG CO trong tep" % s)
            continue
        for off in offs:
            va = off_to_va(secs, off)
            hits = xrefs_to(data, secs, va, text) if va else []
            print("%-42s off 0x%06X  VA 0x%X  xref %d  %s"
                  % (s, off, va or 0, len(hits),
                     " ".join("0x%X" % h for h in hits[:8])))
    if args.near:
        c = int(args.near, 0)
        lo, hi = c - args.window, c + args.window
        print()
        print("chuoi dang-khoa duoc tro toi trong [0x%X, 0x%X]:" % (lo, hi))
        for va, name in strings_referenced_in(data, secs, text, lo, hi):
            print("   0x%X  %s" % (va, name))
    return 0


if __name__ == '__main__':
    sys.exit(main())
