#!/usr/bin/env python3
# CYS: Tests/abi/audit_command_params.py - x64 audit of the SCommand parameter union (Src/Client/WXClient/GameCommand.h).
#
# SCommand keeps its parameters in a union of 4-byte arrays (m_adwParam, m_auParam, m_afParam, m_anParam, m_abParam),
# 8-byte arrays (m_auqParam, m_aqParam) and pointer arrays (m_apParam, m_apConstParam). On x86 every array has a
# 4-byte stride, so index i always means bytes 4i..4i+3. On x64 the pointer arrays have an 8-byte stride:
# m_apParam[k] covers the bytes of m_adwParam[2k] and m_adwParam[2k+1]. A command that stores a pointer at index k
# and a 4-byte value at index 2k or 2k+1 therefore corrupts one of them on x64.
# This script lists, per command id (DPC_*/AIC_*/OC_*/WC_* constants that appear in a `m_wID = X` store or a
# `case X:` handler), the indices used through each view and reports overlapping pairs.
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
SRC = os.path.join(ROOT, 'Src', 'Client', 'WXClient')
VIEW4 = ('m_adwParam', 'm_auParam', 'm_afParam', 'm_anParam', 'm_abParam')
VIEWP = ('m_apParam', 'm_apConstParam')
VIEW8 = ('m_auqParam', 'm_aqParam')
USE_RE = re.compile(r'\b(%s)\s*\[\s*(\d+)\s*\]' % '|'.join(VIEW4 + VIEWP + VIEW8))
ID_RE = re.compile(r'\bm_wID\s*=\s*(\w+)|\bcase\s+(\w+)\s*:|\bm_typeMouse\s*=\s*SCommand_Mouse::(\w+)|'
                   r'\bcase\s+SCommand_Mouse::(\w+)\s*:')


def byte_range(view, idx, ptr=8):
    if view in VIEW4:
        return (4 * idx, 4 * idx + 4)
    if view in VIEW8:
        return (8 * idx, 8 * idx + 8)
    return (ptr * idx, ptr * idx + ptr)


def main():
    uses = {}   # command -> list of (view, idx, file, line)
    for dirpath, _d, files in os.walk(SRC):
        for fn in files:
            if not fn.lower().endswith(('.cpp', '.h')):
                continue
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, SRC).replace('\\', '/')
            cur = None
            for i, ln in enumerate(open(path, encoding='utf-8-sig', errors='replace'), 1):
                code = ln.split('//')[0]
                m = ID_RE.search(code)
                if m:
                    cur = next(g for g in m.groups() if g)
                for u in USE_RE.finditer(code):
                    uses.setdefault(cur or '?', []).append((u.group(1), int(u.group(2)), rel, i))
    conflicts = 0
    for cmd, lst in sorted(uses.items()):
        ptrs = [(v, k, f, l) for (v, k, f, l) in lst if v in VIEWP]
        if not ptrs:
            continue
        others = [(v, k, f, l) for (v, k, f, l) in lst if v not in VIEWP]
        hits = []
        for (pv, pk, pf, pl) in ptrs:
            p64 = byte_range(pv, pk, 8)
            for (ov, ok, of, ol) in others:
                o = byte_range(ov, ok)
                # the pair means the same slot on x86 when both are 4-byte index pk == ok; overlap only matters otherwise
                if o[0] < p64[1] and p64[0] < o[1] and not (ov in VIEW4 and ok == pk):
                    hits.append('%s[%d] %s:%d  x  %s[%d] %s:%d' % (pv, pk, pf, pl, ov, ok, of, ol))
        if hits:
            conflicts += 1
            print('== %s' % cmd)
            for h in sorted(set(hits)):
                print('   ' + h)
    print('commands with x64 overlaps: %d' % conflicts)
    return 0


if __name__ == '__main__':
    sys.exit(main())
