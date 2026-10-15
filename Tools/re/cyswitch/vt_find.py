"""Locate MSVC x64 vftables of named classes through RTTI and list IAT slots of WS2_32 ordinals.

Static only. Usage:
  vt_find.py <exe> vt <mangled-class>...     e.g. CGConnect@Packets@@  (prints vftable VA + first 8 slot VAs)
  vt_find.py <exe> iat <dll> <ordinal|name>...
"""
import re
import struct
import sys

import pefile


def main():
    exe, mode, args = sys.argv[1], sys.argv[2], sys.argv[3:]
    pe = pefile.PE(exe, fast_load=True)
    base = pe.OPTIONAL_HEADER.ImageBase
    if mode == 'iat':
        pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_IMPORT']])
        dll = args[0].lower()
        want = args[1:]
        for ent in pe.DIRECTORY_ENTRY_IMPORT:
            if ent.dll.decode().lower() != dll:
                continue
            for imp in ent.imports:
                key = imp.name.decode() if imp.name else str(imp.ordinal)
                if key in want:
                    print(f'{dll}\t{key}\tIAT VA 0x{imp.address:x}')
        return
    data = pe.__data__
    rd = [s for s in pe.sections if s.Name.startswith(b'.rdata')][0]
    rva0, raw0, rs = rd.VirtualAddress, rd.PointerToRawData, rd.SizeOfRawData
    blob = bytes(data[raw0:raw0 + rs])

    def off2rva(off):
        for s in pe.sections:
            if s.PointerToRawData <= off < s.PointerToRawData + s.SizeOfRawData:
                return s.VirtualAddress + off - s.PointerToRawData
    for cls in args:
        m = re.search(re.escape(b'.?AV' + cls.encode() + b'\x00'), bytes(data))
        if not m:
            print(cls, 'TD not found')
            continue
        td = off2rva(m.start()) - 16
        cols = [rva0 + i for i in range(0, len(blob) - 24, 4)
                if struct.unpack_from('<I', blob, i)[0] == 1 and struct.unpack_from('<I', blob, i + 12)[0] == td
                and struct.unpack_from('<I', blob, i + 20)[0] == rva0 + i]
        for c in cols:
            pat = struct.pack('<Q', base + c)
            for mm in re.finditer(re.escape(pat), blob):
                if mm.start() % 8:
                    continue
                vt = rva0 + mm.start() + 8
                off_this = struct.unpack_from('<I', blob, c - rva0 + 4)[0]
                slots = [struct.unpack_from('<Q', blob, mm.start() + 8 + 8 * k)[0] for k in range(8)]
                print(f'{cls}\tvftable VA 0x{base + vt:x}\tthis-offset {off_this}\tslots ' +
                      ','.join(f'0x{s:x}' for s in slots))


if __name__ == '__main__':
    main()
