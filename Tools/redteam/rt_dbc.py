#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""red-team: bo doc DBC 00CCBBDD toi thieu, doc-lap (chi doc, khong ghi).

Dinh dang (doi chieu tu Src/Shared/Common/DataBase/TLBB_DBC.cpp, va tu
Tools/reapply/scenedef/72-dbc-pool-rows.py da chay that tren SceneDefineEx):
  0x00  magic  00 CC BB DD
  0x04  u32 nField
  0x08  u32 nRecord
  0x0C  u32 poolSize
  0x10  u32 type[nField]      0=INT 1=FLOAT 2=STRING
        u32 cell[nRecord][nField]
        pool[poolSize]        chuoi NUL-terminated; o STRING la OFFSET vao pool
"""
import struct
import sys

MAGIC = b"\x00\xcc\xbb\xdd"
T_INT, T_FLOAT, T_STRING = 0, 1, 2


class Dbc(object):
    def __init__(self, path):
        with open(path, "rb") as fh:
            b = fh.read()
        if b[:4] != MAGIC:
            raise ValueError("%s khong phai DBC 00CCBBDD" % path)
        self.path = path
        self.nF, self.nR, self.pool_size = struct.unpack_from("<3I", b, 4)
        self.types = list(struct.unpack_from("<%dI" % self.nF, b, 16))
        off = 16 + self.nF * 4
        self.cells = struct.unpack_from("<%dI" % (self.nF * self.nR), b, off)
        self.pool = b[off + self.nF * self.nR * 4:]
        if len(self.pool) != self.pool_size:
            raise ValueError("%s: pool %d != header %d" %
                             (path, len(self.pool), self.pool_size))

    def raw(self, r, c):
        return self.cells[r * self.nF + c]

    def i(self, r, c):
        return struct.unpack("<i", struct.pack("<I", self.raw(r, c)))[0]

    def f(self, r, c):
        return struct.unpack("<f", struct.pack("<I", self.raw(r, c)))[0]

    def s(self, r, c):
        o = self.raw(r, c)
        if o >= self.pool_size:
            o = 0
        e = self.pool.find(b"\0", o)
        return self.pool[o:e if e >= 0 else len(self.pool)]

    def cell(self, r, c):
        t = self.types[c]
        if t == T_STRING:
            return self.s(r, c)
        if t == T_FLOAT:
            return self.f(r, c)
        return self.i(r, c)

    def col(self, c):
        return [self.cell(r, c) for r in range(self.nR)]

    def find_rows(self, c, value):
        return [r for r in range(self.nR) if self.cell(r, c) == value]


if __name__ == "__main__":
    for p in sys.argv[1:]:
        d = Dbc(p)
        print("%s: %d cot x %d dong, pool %d byte" % (p, d.nF, d.nR, d.pool_size))
        print("  kieu cot:", "".join("ifs"[t] if t < 3 else "?" for t in d.types))
        for r in range(min(2, d.nR)):
            print("  dong %d:" % r, [d.cell(r, c) for c in range(min(14, d.nF))])
