# -*- coding: utf-8 -*-
"""CYS-CHATENTER: tim vftable cua mot lop bang RTTI (x64 MSVC) trong cay SONG, roi in cac o.
    python cys_chatenter_rtti.py <pe> <ten RTTI, vd .?AVCUISystem@@> [--slots 60-66] [--count N]
Dinh vi bang KY HIEU RTTI (luat 22.8), khong bang dia chi chep tay."""
import sys, struct, argparse
sys.path.insert(0, r"C:\TLBB\085\CY-Source\Tools\pipeline")
from cys_chatenter_pe import PE, header

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('pe'); ap.add_argument('rtti'); ap.add_argument('--slots'); ap.add_argument('--count', type=int, default=0)
    a = ap.parse_args()
    pe = PE(a.pe); header(pe); d = pe.data
    name = a.rtti.encode('latin-1') + b'\0'
    pos = d.find(name)
    if pos < 0: print('# khong thay RTTI name'); return 1
    # TypeDescriptor starts 0x10 before the name (vfptr, spare, name)
    td_off = pos - 0x10
    td_rva = None
    for nm, va, vs, ra, rs in pe.secs:
        if ra <= td_off < ra + rs: td_rva = va + td_off - ra
    print('# TypeDescriptor rva 0x%x' % td_rva)
    # CompleteObjectLocator: signature(1) offset cdOffset pTypeDescriptor(rva) pClassDescriptor pSelf
    rdata = [s for s in pe.secs if s[0] == '.rdata'][0]
    buf = d[rdata[3]:rdata[3] + rdata[4]]
    cols = []
    i = 0
    pat = struct.pack('<I', td_rva)
    while True:
        i = buf.find(pat, i)
        if i < 0: break
        if i >= 12:
            sig, off, cd = struct.unpack_from('<III', buf, i - 12)
            if sig == 1:
                col_rva = rdata[1] + i - 12
                self_rva = struct.unpack_from('<I', buf, i + 8)[0]
                if self_rva == col_rva:
                    cols.append((col_rva, off))
        i += 1
    for col_rva, off in cols:
        # vftable: qword pointing to COL sits at vftable-8
        target = struct.pack('<Q', pe.base + col_rva)
        j = buf.find(target)
        while j >= 0:
            vt_rva = rdata[1] + j + 8
            print('# COL rva 0x%x (offset trong doi tuong = 0x%x) -> vftable rva 0x%x' % (col_rva, off, vt_rva))
            lo, hi = 0, (a.count or 8)
            if a.slots:
                lo, hi = [int(x) for x in a.slots.split('-')]; hi += 1
            for k in range(lo, hi):
                v = struct.unpack_from('<Q', buf, j + 8 + k * 8)[0]
                print('   [%3d] +0x%03x -> rva 0x%x' % (k, k * 8, v - pe.base))
            j = buf.find(target, j + 1)
    return 0
if __name__ == '__main__':
    sys.exit(main())
