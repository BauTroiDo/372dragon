"""Packet class vtables of a TLBB Game.exe (x64 MSVC) through RTTI (static, never runs the file).

For every ".?AV<Name>@Packets@@" (the packet itself, not the Factory) find COL -> vftable and dump the first
N slots. Joined with the factory table (pkt_ids_cy.tsv from Tools/re/cyswitch/pkt_ids.py) for the packet ID.

Usage: pkt_vtables.py <Game.exe> <pkt_ids.tsv> <out.tsv> [nslots]
"""
import re
import struct
import sys

sys.path.insert(0, __file__.rsplit('\\', 1)[0].rsplit('/', 1)[0] + '/../re/cyswitch')
from pkt_ids import Image  # noqa: E402


def main():
    exe, ids_tsv, out = sys.argv[1:4]
    nslots = int(sys.argv[4]) if len(sys.argv) > 4 else 8
    img = Image(exe)
    data = bytes(img.data)
    ids = {}
    for line in open(ids_tsv, encoding='utf-8').read().splitlines()[1:]:
        p = line.split('\t')
        if p[1]:
            ids[p[0]] = int(p[1])
    tds = {}
    for m in re.finditer(rb'\.\?AV([A-Za-z_0-9]+)@Packets@@\x00', data):
        name = m.group(1).decode()
        if name.endswith('Factory'):
            continue
        rva = img.off2rva(m.start())
        if rva is not None:
            tds[rva - 16] = name
    _, va, vs, raw, rs = img.sec('.rdata')
    blob = data[raw:raw + rs]
    cols = {}
    for i in range(0, len(blob) - 24, 4):
        sig, off, cdoff, ptd, pcd, pself = struct.unpack_from('<IIIIII', blob, i)
        if sig == 1 and ptd in tds and pself == va + i:
            cols[img.base + va + i] = tds[ptd]
    rows = []
    for i in range(0, len(blob) - 8, 8):
        q = struct.unpack_from('<Q', blob, i)[0]
        if q in cols:
            vt = va + i + 8
            slots = [struct.unpack_from('<Q', blob, i + 8 + 8 * k)[0] for k in range(nslots)]
            rows.append((cols[q], vt, slots))
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        f.write('name\tid\tvtable_va\t' + '\t'.join(f'slot{k}' for k in range(nslots)) + '\n')
        for name, vt, slots in sorted(rows, key=lambda r: (ids.get(r[0], 99999), r[0])):
            f.write(f'{name}\t{ids.get(name, "")}\t{img.base + vt:x}\t' + '\t'.join(f'{s:x}' for s in slots) + '\n')
    print(f'packet TDs {len(tds)} vtables {len(rows)} with id {sum(1 for r in rows if r[0] in ids)}')


if __name__ == '__main__':
    main()
