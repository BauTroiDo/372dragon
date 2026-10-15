# -*- coding: utf-8 -*-
"""Dump MSVC RTTI vftables (class name + slot RVAs) of a PE file (x86 or x64).

Read-only helper for the PathLib clean-room spec: it only parses the file.
Usage: python dump_vtables.py <PE file> [name-filter] [all.c for symbol names]
"""
import re
import sys
import struct

import pefile


def main():
    path = sys.argv[1]
    flt = sys.argv[2] if len(sys.argv) > 2 else 'PathLib'
    names = {}
    if len(sys.argv) > 3:
        with open(sys.argv[3], 'r', encoding='utf-8', errors='replace') as f:
            for line in f:
                m = re.match(r'// ==== ([0-9a-f]+)\s+(.*?) ====', line)
                if m:
                    names[int(m.group(1), 16)] = m.group(2)
    pe = pefile.PE(path, fast_load=True)
    base = pe.OPTIONAL_HEADER.ImageBase
    is64 = pe.FILE_HEADER.Machine == 0x8664
    psz = 8 if is64 else 4
    data = pe.get_memory_mapped_image()
    text = [s for s in pe.sections if s.Characteristics & 0x20000000]

    def in_text(rva):
        return any(s.VirtualAddress <= rva < s.VirtualAddress + s.Misc_VirtualSize for s in text)

    def rd(rva, n):
        return data[rva:rva + n]

    def u32(rva):
        return struct.unpack_from('<I', data, rva)[0]

    def ptr(rva):
        return struct.unpack_from('<Q' if is64 else '<I', data, rva)[0]

    def cstr(rva):
        end = data.find(b'\0', rva)
        return data[rva:end].decode('latin-1')

    found = []
    for s in pe.sections:
        if s.Characteristics & 0x20000000:
            continue
        start = s.VirtualAddress
        end = start + s.Misc_VirtualSize
        for off in range(start, end - psz, psz):
            p = ptr(off)
            if not (base <= p < base + len(data)):
                continue
            col = p - base
            if col + 24 > len(data):
                continue
            sig = u32(col)
            if is64:
                if sig != 1:
                    continue
                td_rva = u32(col + 12)
                self_rva = u32(col + 20)
                if self_rva != col:
                    continue
            else:
                if sig != 0:
                    continue
                td = u32(col + 12)
                if not (base <= td < base + len(data)):
                    continue
                td_rva = td - base
            if td_rva + 2 * psz + 4 > len(data):
                continue
            name = cstr(td_rva + 2 * psz)
            if not name.startswith('.?A'):
                continue
            vt = off + psz
            slots = []
            q = vt
            while q + psz <= len(data):
                f = ptr(q)
                if not (base <= f < base + len(data)) or not in_text(f - base):
                    break
                slots.append(f - base)
                q += psz
            offset = u32(col + 4)
            found.append((name, vt, offset, slots))
    for name, vt, offset, slots in found:
        if flt and flt not in name:
            continue
        print('%s  vftable RVA 0x%X  (this-offset %d)  %d slots' % (name, vt, offset, len(slots)))
        for i, f in enumerate(slots):
            nm = names.get(base + f, '')
            print('   [%2d] +0x%03X  RVA 0x%06X  %s' % (i, i * psz, f, nm))


if __name__ == '__main__':
    main()
