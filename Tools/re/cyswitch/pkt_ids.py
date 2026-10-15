"""Extract packet IDs / max sizes from a TLBB Game.exe (x64 MSVC) through RTTI.

Static only: reads the PE file, never runs it.

PacketFactory (Src/Shared/Common/PacketFactory.h):
    vtbl[0] ~PacketFactory, [1] CreatePacket, [2] GetPacketID, [3] GetPacketMaxSize
Path: ".?AV<Name>Factory@Packets@@" TypeDescriptor -> RTTICompleteObjectLocator (sig 1, pSelf) ->
qword pointer to COL in .rdata -> vftable = pointer + 8.

Usage: pkt_ids.py <Game.exe> <out.tsv>
"""
import re
import struct
import sys

import pefile


class Image:
    def __init__(self, path):
        self.pe = pefile.PE(path, fast_load=True)
        self.base = self.pe.OPTIONAL_HEADER.ImageBase
        self.data = self.pe.__data__
        self.secs = [(s.Name.rstrip(b'\0').decode(), s.VirtualAddress, s.Misc_VirtualSize,
                      s.PointerToRawData, s.SizeOfRawData) for s in self.pe.sections]

    def sec(self, name):
        for s in self.secs:
            if s[0] == name:
                return s
        raise KeyError(name)

    def off2rva(self, off):
        for n, va, vs, raw, rs in self.secs:
            if raw <= off < raw + rs:
                return va + off - raw
        return None

    def rva2off(self, rva):
        for n, va, vs, raw, rs in self.secs:
            if va <= rva < va + max(vs, rs) and rva - va < rs:
                return raw + rva - va
        return None

    def read(self, rva, n):
        off = self.rva2off(rva)
        if off is None:
            return b''
        return bytes(self.data[off:off + n])

    def sec_of_rva(self, rva):
        for n, va, vs, raw, rs in self.secs:
            if va <= rva < va + max(vs, rs):
                return n
        return None


def decode_const(img, rva, depth=0):
    """Return (value, pattern) for tiny 'return constant' functions, following jmp thunks."""
    b = img.read(rva, 16)
    if not b:
        return None, 'unreadable'
    if b[0] == 0xE9 and depth < 3:                       # jmp rel32
        tgt = rva + 5 + struct.unpack_from('<i', b, 1)[0]
        return decode_const(img, tgt, depth + 1)
    if b[0] == 0xB8 and b[5] == 0xC3:                    # mov eax, imm32 ; ret
        return struct.unpack_from('<I', b, 1)[0], 'mov eax'
    if b[:2] == b'\x66\xB8' and b[4] == 0xC3:            # mov ax, imm16 ; ret
        return struct.unpack_from('<H', b, 2)[0], 'mov ax'
    if b[:3] in (b'\x33\xC0\xC3', b'\x31\xC0\xC3'):      # xor eax, eax ; ret
        return 0, 'xor eax'
    if b[:2] == b'\xB0' and b[2] == 0xC3:
        return b[1], 'mov al'
    return None, b[:12].hex()


def main():
    path, out = sys.argv[1], sys.argv[2]
    img = Image(path)
    data = bytes(img.data)
    rdata = img.sec('.rdata')
    data_sec = img.sec('.data')

    # 1. type descriptors
    tds = {}
    for m in re.finditer(rb'\.\?AV([A-Za-z_0-9]+)Factory@Packets@@\x00', data):
        rva = img.off2rva(m.start())
        if rva is None:
            continue
        tds[rva - 16] = m.group(1).decode()

    # 2. complete object locators (x64: sig=1, ..., pTypeDescriptor, pClassDescriptor, pSelf)
    cols = {}
    _, va, vs, raw, rs = rdata
    blob = data[raw:raw + rs]
    for i in range(0, len(blob) - 24, 4):
        sig, off, cdoff, ptd, pcd, pself = struct.unpack_from('<IIIIII', blob, i)
        if sig == 1 and ptd in tds and pself == va + i:
            cols[va + i] = tds[ptd]

    # 3. vtables: qword pointers to COL
    colva = {img.base + r: name for r, name in cols.items()}
    rows = []
    for i in range(0, len(blob) - 8, 8):
        q = struct.unpack_from('<Q', blob, i)[0]
        if q in colva:
            vt = va + i + 8
            name = colva[q]
            slots = [struct.unpack_from('<Q', blob, i + 8 + 8 * k)[0] - img.base for k in range(6)]
            rows.append((name, vt, slots))

    # 4. slot layout. Measured on client_GL and CY 3.71: the factory vtable has 4 slots
    #    [0] dtor, [1] CreatePacket, [2] shared DestroyPacket (calls obj->vtbl[0](1)), [3] GetPacketID.
    #    There is no GetPacketMaxSize slot in these branches. The ID slot is detected as the first slot whose
    #    decoded constants are unique over all factories.
    sid = None
    for k in range(1, 4):
        vals = [decode_const(img, r[2][k])[0] for r in rows]
        if all(v is not None for v in vals) and len(set(vals)) == len(vals):
            sid = k
            break
    if sid is None:
        raise SystemExit('no slot with unique constant ids')
    rows = [(n, vt, s) + decode_const(img, s[sid]) for n, vt, s in rows]
    print(f'slot layout: GetPacketID = factory vtbl[{sid}]')

    names_td = set(tds.values())
    found = {r[0] for r in rows}
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        f.write('name\tid\tfactory_vtable_rva\tgetid_rva\tid_pattern\n')
        for name, vt, slots, pid, pat_id in sorted(rows, key=lambda r: (r[3] is None, r[3] or 0, r[0])):
            f.write(f'{name}\t{"" if pid is None else pid}\t0x{vt:x}\t0x{slots[sid]:x}\t{pat_id}\n')
    ok = sum(1 for r in rows if r[3] is not None)
    ids = [r[3] for r in rows if r[3] is not None]
    dup = len(ids) - len(set(ids))
    print(f'{path}: factory TDs {len(tds)}, COLs {len(cols)}, vtables {len(rows)}, id decoded {ok}, '
          f'duplicate ids {dup}, TD without vtable {len(names_td - found)}, id range {min(ids)}..{max(ids)}')


if __name__ == '__main__':
    main()
