# -*- coding: utf-8 -*-
"""Minimal read-only PE32+/PE32 helper (no third-party deps).

Used by the Lua host-API catalog tools to
  * map RVA <-> file offset,
  * list imports as IAT-slot VA -> (dll, name),
  * read C strings / raw bytes at a VA (for byte-identity checks between the
    Ghidra-analyzed copy and the current client / client_GL binaries).
"""
import struct


class PE:
    def __init__(self, path):
        self.path = path
        with open(path, 'rb') as f:
            self.data = f.read()
        d = self.data
        if d[:2] != b'MZ':
            raise ValueError('not MZ: %s' % path)
        pe = struct.unpack_from('<I', d, 0x3C)[0]
        if d[pe:pe + 4] != b'PE\0\0':
            raise ValueError('not PE: %s' % path)
        self.machine, nsec, _, _, _, optsz, _ = struct.unpack_from('<HHIIIHH', d, pe + 4)
        opt = pe + 24
        magic = struct.unpack_from('<H', d, opt)[0]
        self.pe64 = magic == 0x20B
        if self.pe64:
            self.image_base = struct.unpack_from('<Q', d, opt + 24)[0]
            dd = opt + 112
        else:
            self.image_base = struct.unpack_from('<I', d, opt + 28)[0]
            dd = opt + 96
        self.dirs = [struct.unpack_from('<II', d, dd + 8 * i) for i in range(16)]
        self.sections = []
        so = opt + optsz
        for i in range(nsec):
            name = d[so + 40 * i: so + 40 * i + 8].rstrip(b'\0').decode('latin-1')
            vsz, va, rsz, rptr = struct.unpack_from('<IIII', d, so + 40 * i + 8)
            chars = struct.unpack_from('<I', d, so + 40 * i + 36)[0]
            self.sections.append((name, va, vsz, rptr, rsz, chars))

    # ------------------------------------------------------------------ mapping
    def rva2off(self, rva):
        for name, va, vsz, rptr, rsz, _ in self.sections:
            if va <= rva < va + max(vsz, rsz):
                if rva - va >= rsz:
                    return None  # in virtual-only tail (bss)
                return rptr + (rva - va)
        return None

    def section_of(self, rva):
        for s in self.sections:
            if s[1] <= rva < s[1] + max(s[2], s[4]):
                return s[0]
        return None

    def read(self, rva, n):
        off = self.rva2off(rva)
        if off is None:
            return None
        return self.data[off:off + n]

    def cstr(self, rva, maxlen=512):
        off = self.rva2off(rva)
        if off is None:
            return None
        end = self.data.find(b'\0', off, off + maxlen)
        if end < 0:
            return None
        return self.data[off:end]

    # ------------------------------------------------------------------ imports
    def imports(self):
        """Return list of (iat_slot_va, dll, name_or_ordinal)."""
        res = []
        rva, size = self.dirs[1]
        if not rva:
            return res
        psz = 8 if self.pe64 else 4
        i = 0
        while True:
            off = self.rva2off(rva + 20 * i)
            if off is None:
                break
            oft, _, _, name_rva, ft = struct.unpack_from('<IIIII', self.data, off)
            if not (oft or name_rva or ft):
                break
            dll = self.cstr(name_rva).decode('latin-1')
            thunk = oft or ft
            j = 0
            while True:
                toff = self.rva2off(thunk + psz * j)
                if toff is None:
                    break
                v = struct.unpack_from('<Q' if self.pe64 else '<I', self.data, toff)[0]
                if v == 0:
                    break
                if v >> (63 if self.pe64 else 31):
                    nm = '#%d' % (v & 0xFFFF)
                else:
                    nm = self.cstr((v & 0x7FFFFFFF) + 2).decode('latin-1')
                res.append((self.image_base + ft + psz * j, dll, nm))
                j += 1
            i += 1
        return res
