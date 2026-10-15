# -*- coding: utf-8 -*-
"""Pick the implementing functions to decompile (evidence for the top-N methods by script call count).

Writes Build/re/luaapi/decomp_<module>.txt (one VA per line) from Registry/luaapi/catalog.json.
Usage: pick_decomp.py [N_game=300] [N_ui=120]
"""
import json, os, sys

CY = r'C:\TLBB\085\CY-Source'
cat = json.load(open(os.path.join(CY, r'Registry\luaapi\catalog.json'), encoding='utf-8'))['entries']
n_game = int(sys.argv[1]) if len(sys.argv) > 1 else 300
n_ui = int(sys.argv[2]) if len(sys.argv) > 2 else 120
for mod, n in (('Game.exe', n_game), ('UI_CEGUI.dll', n_ui)):
    es = [e for e in cat if e['module'] == mod and e.get('impl_va')]
    key = (lambda e: -(e['calls_exact'] or 0)) if mod == 'Game.exe' else (lambda e: -(e['calls_any'] or 0))
    es.sort(key=key)
    seen, out = set(), []
    for e in es:
        if len(out) >= n:
            break
        va = e['impl_va']
        if va in seen:
            continue
        seen.add(va)
        out.append('%s\t%s:%s\t%d' % (va, e['receiver'], e['name'], e['calls_exact'] if mod == 'Game.exe' else e['calls_any']))
    p = os.path.join(CY, r'Build\re\luaapi', 'decomp_%s.txt' % mod)
    open(p, 'w', encoding='utf-8').write('\n'.join(out) + '\n')
    print(mod, len(out), '->', p)
