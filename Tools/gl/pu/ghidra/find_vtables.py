#!/usr/bin/env python3
"""find_vtables.py - locate MSVC x64 RTTI primary vftables of named classes in a PE image (no Ghidra needed).

  find_vtables.py EXE Class[:depth] [Class[:depth] ...]   ->  prints  Class@0xVTABLE:depth  (nslots)

Chain: ".?AV<Class>@@" type-descriptor name (TypeDescriptor = name - 16) -> CompleteObjectLocator
{sig=1, offset=0, cdOffset, rva TypeDescriptor, rva ClassHierarchy, rva self} -> vtable[-1] points to the COL.
"""
import re
import struct
import sys


def load(path):
    d = open(path, 'rb').read()
    pe = struct.unpack_from('<I', d, 0x3c)[0]
    nsec = struct.unpack_from('<H', d, pe + 6)[0]
    optsz = struct.unpack_from('<H', d, pe + 20)[0]
    base = struct.unpack_from('<Q', d, pe + 24 + 24)[0]
    secs = []
    so = pe + 24 + optsz
    for _ in range(nsec):
        name = d[so:so + 8].rstrip(b'\0').decode('latin1')
        vsz, va, rsz, rp = struct.unpack_from('<IIII', d, so + 8)
        secs.append((name, base + va, rsz, rp))
        so += 40
    return d, base, secs


def main():
    exe = sys.argv[1]
    d, base, secs = load(exe)

    def off2va(o):
        for n, va, rsz, rp in secs:
            if rp <= o < rp + rsz:
                return va + o - rp

    def va2off(v):
        for n, va, rsz, rp in secs:
            if va <= v < va + rsz:
                return rp + v - va

    text = [(va, va + rsz) for n, va, rsz, rp in secs if n == '.text']
    in_text = lambda v: any(a <= v < b for a, b in text)
    for spec in sys.argv[2:]:
        cls, _, depth = spec.partition(':')
        name = b'.?AV' + cls.encode() + b'@@\0'
        found = []
        for m in re.finditer(re.escape(name), d):
            td_va = off2va(m.start()) - 16
            td_rva = td_va - base
            pat = struct.pack('<I', td_rva)
            k = d.find(pat)
            while k >= 0:
                col = k - 12
                sig, off, cdoff, ptd, pchd, pself = struct.unpack_from('<IIIIII', d, col)
                col_va = off2va(col)
                if sig == 1 and off == 0 and col_va is not None and pself == col_va - base:
                    q = d.find(struct.pack('<Q', col_va))
                    while q >= 0:
                        vt = off2va(q + 8)
                        n = 0
                        while True:
                            fp = struct.unpack_from('<Q', d, q + 8 + 8 * n)[0]
                            if not in_text(fp):
                                break
                            n += 1
                        if n:
                            found.append((vt, n))
                        q = d.find(struct.pack('<Q', col_va), q + 8)
                k = d.find(pat, k + 4)
        if not found:
            print('# %s: not found' % cls)
        for vt, n in found:
            print('%s@0x%x:%s  (%d slots)' % (cls, vt, depth or '0', n))


if __name__ == '__main__':
    main()
