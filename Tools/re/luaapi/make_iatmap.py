# -*- coding: utf-8 -*-
"""Write IAT-slot maps + binary identity for the B binaries (read-only).

Outputs (CY-Source/Build/re/luaapi):
  iat_Game.exe.tsv, iat_UI_CEGUI.dll.tsv   VA<TAB>dll<TAB>import name   (from client\\Bin64 = B original)
  binaries.json                             sha256 + section table of client / client_GL / Ghidra-copy notes
The Ghidra script LuaApiDump.java reads the iat_*.tsv files to name CALL [IAT] targets
independently of how Ghidra organises external symbols.
"""
import hashlib, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pe_util import PE

OUT = r'C:\TLBB\085\CY-Source\Build\re\luaapi'
BINS = {
    'Game.exe': [r'C:\TLBB\085\client\Bin64\Game.exe', r'C:\TLBB\085\client_GL\Bin64\Game.exe'],
    'UI_CEGUI.dll': [r'C:\TLBB\085\client\Bin64\UI_CEGUI.dll', r'C:\TLBB\085\client_GL\Bin64\UI_CEGUI.dll'],
}


def main():
    os.makedirs(OUT, exist_ok=True)
    ident = {}
    for prog, paths in BINS.items():
        pe = PE(paths[0])
        with open(os.path.join(OUT, 'iat_%s.tsv' % prog), 'w', encoding='utf-8', newline='\n') as f:
            f.write('# IAT slots of %s (image base 0x%x)\n' % (paths[0], pe.image_base))
            for va, dll, nm in pe.imports():
                f.write('%x\t%s\t%s\n' % (va, dll, nm))
        for p in paths:
            q = PE(p)
            ident[p] = {
                'sha256': hashlib.sha256(q.data).hexdigest(),
                'size': len(q.data),
                'image_base': hex(q.image_base),
                'sections': [[s[0], hex(s[1]), hex(s[2]), hex(s[3]), hex(s[4])] for s in q.sections],
                'n_imports': len(q.imports()),
            }
        a, b = PE(paths[0]), PE(paths[1])
        ia = {(d, n): v for v, d, n in a.imports()}
        ib = {(d, n): v for v, d, n in b.imports()}
        ident[prog + ':import_diff'] = {
            'only_client': sorted('%s!%s' % k for k in set(ia) - set(ib)),
            'only_client_GL': sorted('%s!%s' % k for k in set(ib) - set(ia)),
            'slot_moved': sorted('%s!%s' % k for k in set(ia) & set(ib) if ia[k] != ib[k]),
        }
    json.dump(ident, open(os.path.join(OUT, 'binaries.json'), 'w', encoding='utf-8'), indent=1)
    for k, v in ident.items():
        if k.endswith(':import_diff'):
            print(k, {x: len(y) for x, y in v.items()}, v['only_client'][:6], v['only_client_GL'][:6])
        else:
            print(k, v['sha256'][:16], v['size'], [s[0] for s in v['sections']])


if __name__ == '__main__':
    main()
