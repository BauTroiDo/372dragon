"""Extract packet IDs from a stripped Linux x86-64 TLBB server binary (tlbb15 Server/Login/World) through
Itanium C++ RTTI. Static only: the binary is read as bytes, never executed.

typeinfo name "N7Packets<len><Name>FactoryE" -> typeinfo object {vptr, char* name} -> vtable {0, &typeinfo, f0..}
The GetPacketID slot is the first slot whose decoded 'return constant' values are unique over all factories.

Usage: pkt_ids_elf.py <elf> <out.tsv>
"""
import re
import struct
import sys

import numpy as np


def load_segments(data):
    assert data[:4] == b'\x7fELF' and data[4] == 2
    phoff, = struct.unpack_from('<Q', data, 0x20)
    phentsize, phnum = struct.unpack_from('<HH', data, 0x36)
    segs = []
    for i in range(phnum):
        p_type, p_flags, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_align = struct.unpack_from(
            '<IIQQQQQQ', data, phoff + i * phentsize)
        if p_type == 1:
            segs.append((p_vaddr, p_offset, p_filesz, p_flags))
    return segs


def main():
    path, out = sys.argv[1], sys.argv[2]
    with open(path, 'rb') as f:
        data = f.read()
    segs = load_segments(data)

    def off2va(off):
        for va, fo, fs, fl in segs:
            if fo <= off < fo + fs:
                return va + off - fo
        return None

    def va2off(va):
        for sva, fo, fs, fl in segs:
            if sva <= va < sva + fs:
                return fo + va - sva
        return None

    def decode(va, depth=0):
        off = va2off(va)
        if off is None:
            return None, 'unmapped'
        b = data[off:off + 24]
        i = 0
        if b[:4] == b'\xf3\x0f\x1e\xfa':           # endbr64
            i = 4
        if b[i:i + 1] == b'\x55' and b[i + 1:i + 4] == b'\x48\x89\xe5':   # push rbp; mov rbp,rsp
            i += 4
            if b[i:i + 4] == b'\x48\x89\x7d\xf8':   # mov [rbp-8], rdi
                i += 4
            if b[i] == 0xB8:
                return struct.unpack_from('<I', b, i + 1)[0], 'O0 mov eax'
        if b[i] == 0xB8 and b[i + 5] in (0xC3, 0xF3):
            return struct.unpack_from('<I', b, i + 1)[0], 'mov eax'
        if b[i:i + 2] == b'\x66\xB8':
            return struct.unpack_from('<H', b, i + 2)[0], 'mov ax'
        if b[i:i + 3] in (b'\x31\xc0\xc3', b'\x33\xc0\xc3'):
            return 0, 'xor eax'
        if b[i] == 0xE9 and depth < 3:
            return decode(va + i + 5 + struct.unpack_from('<i', b, i + 1)[0], depth + 1)
        return None, b[:12].hex()

    names = {}
    for m in re.finditer(rb'N7Packets(\d+)([A-Za-z_0-9]+)E\x00', data):
        ln = int(m.group(1))
        nm = m.group(2)
        if len(nm) != ln or not nm.endswith(b'Factory'):
            continue
        names[off2va(m.start())] = nm[:-7].decode()
    # one pass over all 8-aligned qwords of the data segments (numpy) instead of one regex scan per name
    qw = np.frombuffer(data[:len(data) // 8 * 8], dtype='<u8')
    name_vas = np.array(sorted(names), dtype='<u8')
    hit = np.nonzero(np.isin(qw, name_vas))[0]
    ti = {}
    for i in hit:                                   # typeinfo = {vptr, name}: the name pointer is at +8
        if i >= 1:
            ti[off2va(int(i - 1) * 8)] = names[int(qw[i])]
    ti_vas = np.array(sorted(k for k in ti if k is not None), dtype='<u8')
    hit2 = np.nonzero(np.isin(qw, ti_vas))[0]
    rows = []
    for i in hit2:                                  # vtable = {offset_to_top 0, &typeinfo, slots...}
        if i >= 1 and qw[i - 1] == 0:
            base = int(i + 1) * 8
            slots = [int(x) for x in qw[i + 1:i + 9]]
            rows.append((ti[int(qw[i])], off2va(base), slots))
    sid = None
    for k in range(0, 8):
        vals = [decode(r[2][k])[0] for r in rows]
        if all(v is not None for v in vals) and len(set(vals)) == len(vals):
            sid = k
            break
    if sid is None:
        raise SystemExit(f'no unique slot; factories={len(rows)}')
    res = sorted(((n, decode(s[sid])[0], vt) for n, vt, s in rows), key=lambda r: r[1])
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        f.write('name\tid\tvtable_va\n')
        for n, i, vt in res:
            f.write(f'{n}\t{i}\t0x{vt:x}\n')
    ids = [r[1] for r in res]
    print(f'{path}: factory typeinfo names {len(names)}, typeinfos {len(ti)}, vtables {len(rows)}, '
          f'GetPacketID slot {sid}, ids {min(ids)}..{max(ids)}')


if __name__ == '__main__':
    main()
