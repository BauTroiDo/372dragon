#!/usr/bin/env python3
# CYS: Tests/abi/compare_sizes.py - compares Registry/abi/struct_sizes_x86.json with struct_sizes_x64.json.
#
# Writes Registry/abi/struct_sizes_diff.json and struct_sizes_diff.tsv and prints a summary. Every type whose size,
# or any member's offset/size, differs between x86 and x64 is listed and classified by the member types that cause
# the difference:
#   vptr     - polymorphic class (virtual table pointer); packets serialize field by field, so not on the wire
#   pointer  - pointer / handle members: runtime-only data, never valid on the wire or on disk
#   long     - long/ULONG/LONG members (4 bytes on both Windows ABIs; listed only if they still differ)
#   size_t   - size_t/ptrdiff_t/INT_PTR-like members
#   nested   - a member whose own type differs
#   padding  - offsets shifted only by alignment of the above
# `wire_fields` lists members whose own sizeof differs: those break Read/Write code that uses sizeof(member).
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
REG = os.path.join(ROOT, 'Registry', 'abi')

PTR_RE = re.compile(r'\*|\b(LP[A-Z]*STR|LPVOID|PVOID|HANDLE|HWND|HINSTANCE|HMODULE|SMHandle|DBHandle|SOCKET|'
                    r'ULONG_PTR|LONG_PTR|UINT_PTR|INT_PTR|DWORD_PTR|WPARAM|LPARAM|LRESULT)\b')
SIZET_RE = re.compile(r'\b(size_t|ptrdiff_t|intptr_t|uintptr_t)\b')
LONG_RE = re.compile(r'\b(long|LONG|ULONG|ulong|DWORD|IP_t|SM_KEY)\b')
TIME_RE = re.compile(r'\btime_t\b')


def load(path):
    with open(path, encoding='utf-8') as f:
        d = json.load(f)
    return d, {t['name']: t for t in d['types']}


def classify_member(mt, nested_diff):
    base = re.sub(r'\[.*?\]', '', mt).strip()
    if PTR_RE.search(mt):
        return 'pointer'
    if SIZET_RE.search(mt):
        return 'size_t'
    if TIME_RE.search(mt):
        return 'time_t'
    if LONG_RE.search(mt):
        return 'long'
    name = base.split()[-1] if base.split() else base
    if name in nested_diff:
        return 'nested'
    return 'other'


def main():
    # compare_sizes.py [x86.json] [x64.json]  (default: Registry/abi/struct_sizes_x86.json / _x64.json)
    p86 = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REG, 'struct_sizes_x86.json')
    p64 = sys.argv[2] if len(sys.argv) > 2 else os.path.join(REG, 'struct_sizes_x64.json')
    d86, t86 = load(p86)
    d64, t64 = load(p64)

    size_diff = {n for n in t86 if n in t64 and t86[n]['size'] != t64[n]['size']}
    short = {n.split('::')[-1] for n in size_diff}
    rows, report = [], []
    for name in sorted(set(t86) & set(t64)):
        a, b = t86[name], t64[name]
        fa = {f['name']: f for f in a['fields']}
        fb = {f['name']: f for f in b['fields']}
        moved, wire, causes = [], [], set()
        for f in a['fields']:
            g = fb.get(f['name'])
            if not g:
                continue
            if f['size'] != g['size']:
                c = classify_member(f['type'], short)
                causes.add(c)
                wire.append({'field': f['name'], 'type': f['type'], 'x86': f['size'], 'x64': g['size'], 'cause': c})
            if f['offset'] != g['offset']:
                moved.append({'field': f['name'], 'x86': f['offset'], 'x64': g['offset']})
        if a['size'] == b['size'] and not wire and not moved:
            continue
        if a['polymorphic']:
            causes.add('vptr')
        if moved and not wire and not causes:
            causes.add('padding')
        entry = {'name': name, 'file': a['file'], 'line': a['line'], 'x86': a['size'], 'x64': b['size'],
                 'polymorphic': a['polymorphic'], 'causes': sorted(causes), 'wire_fields': wire,
                 'moved_fields': len(moved)}
        report.append(entry)
        rows.append('\t'.join([name, a['file'], str(a['line']), str(a['size']), str(b['size']),
                               'yes' if a['polymorphic'] else 'no', ','.join(sorted(causes)),
                               ';'.join('%s:%s(%d->%d)' % (w['field'], w['type'], w['x86'], w['x64'])
                                        for w in wire)]))

    only86 = sorted(set(t86) - set(t64))
    only64 = sorted(set(t64) - set(t86))
    out = {
        'x86': {'types': len(t86), 'msc_full_ver': d86.get('msc_full_ver'), 'time_t_size': d86.get('time_t_size')},
        'x64': {'types': len(t64), 'msc_full_ver': d64.get('msc_full_ver'), 'time_t_size': d64.get('time_t_size')},
        'differing_types': len(report),
        'size_differs': sum(1 for e in report if e['x86'] != e['x64']),
        'with_wire_fields': sum(1 for e in report if e['wire_fields']),
        'only_in_x86': only86, 'only_in_x64': only64,
        'types': report,
    }
    with open(os.path.join(REG, 'struct_sizes_diff.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    with open(os.path.join(REG, 'struct_sizes_diff.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('type\tfile\tline\tx86\tx64\tpolymorphic\tcauses\tmembers_with_different_size\n')
        f.write('\n'.join(rows) + ('\n' if rows else ''))

    by_cause = {}
    for e in report:
        for c in e['causes'] or ['?']:
            by_cause[c] = by_cause.get(c, 0) + 1
    print('types: x86 %d, x64 %d; differing %d (size %d); with differently-sized members %d'
          % (len(t86), len(t64), out['differing_types'], out['size_differs'], out['with_wire_fields']))
    print('by cause:', ', '.join('%s=%d' % kv for kv in sorted(by_cause.items())))
    for e in report:
        if e['wire_fields'] and 'vptr' not in e['causes']:
            print('  %-50s %5d -> %5d  %s' % (e['name'], e['x86'], e['x64'],
                                             ', '.join('%s(%s)' % (w['field'], w['type']) for w in e['wire_fields'])))
    return 0


if __name__ == '__main__':
    sys.exit(main())
