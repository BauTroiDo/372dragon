# -*- coding: utf-8 -*-
"""Print decompiled functions (by address) from a Ghidra DumpAll-style all.c.

Usage: python extract_fn.py <all.c> <hexaddr> [<hexaddr> ...]
       python extract_fn.py <all.c> --calls <hexaddr>   (list FUN_ callees)
Addresses may be given as 18001c6f0 or 1c6f0 (image base 0x180000000 assumed).
"""
import re
import sys


def load(path):
    funcs = {}
    order = []
    cur = None
    buf = []
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            m = re.match(r'// ==== ([0-9a-f]+)\s+(.*?) ====', line)
            if m:
                if cur is not None:
                    funcs[cur] = ''.join(buf)
                cur = int(m.group(1), 16)
                order.append(cur)
                buf = [line]
            elif cur is not None:
                buf.append(line)
    if cur is not None:
        funcs[cur] = ''.join(buf)
    return funcs


def norm(a):
    v = int(a, 16)
    if v < 0x180000000:
        v += 0x180000000
    return v


def main():
    funcs = load(sys.argv[1])
    args = sys.argv[2:]
    if args and args[0] == '--calls':
        for a in args[1:]:
            body = funcs.get(norm(a), '')
            callees = sorted(set(re.findall(r'FUN_1800[0-9a-f]{5}', body)))
            print('%s: %s' % (a, ' '.join(callees)))
        return
    for a in args:
        body = funcs.get(norm(a))
        if body is None:
            print('// !!! %s not found' % a)
        else:
            sys.stdout.write(body)


if __name__ == '__main__':
    main()
