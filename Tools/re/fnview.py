# -*- coding: utf-8 -*-
"""fnview.py - view functions from a (condensed) Ghidra decompile dump.
Usage: python fnview.py <file> <lits|full|head> <addr1,addr2,...> [maxchars]
  lits : de-duplicated string literals of each function (+ called FUN_ counts)
  full : whole function text (truncated to maxchars)
  head : function signatures only
"""
import collections
import re
import sys


def main():
    path, mode, addrs = sys.argv[1], sys.argv[2], sys.argv[3].replace('+', ',').split(',')
    maxc = int(sys.argv[4]) if len(sys.argv) > 4 else 8000
    text = open(path, encoding='utf-8', errors='replace').read()
    parts = re.split(r'(?m)^==== FUNCTION ', text)
    d = {}
    for p in parts[1:]:
        k = p.split()[0]
        d.setdefault(k, p)
        m = re.search(r'@ ([0-9a-f]+)', p.split('\n', 1)[0])
        if m:
            d.setdefault(m.group(1), p)
    for a in addrs:
        a = a.strip()
        s = d.get(a)
        if s is None:
            print('#### %s NOT FOUND' % a)
            continue
        if mode == 'lits':
            lits = []
            for l in re.findall(r'"((?:[^"\\]|\\.)*)"', s):
                if not lits or lits[-1] != l:
                    lits.append(l)
            calls = collections.Counter(re.findall(r'(FUN_18[0-9a-f]+|Ogre::[\w:]+)\(', s))
            print('#### %s  (%d chars)' % (s.split('\n', 1)[0].strip(), len(s)))
            print('   literals: ' + ' | '.join(lits)[:maxc])
            print('   calls: ' + ', '.join('%s x%d' % kv for kv in calls.most_common(14)))
        elif mode == 'head':
            print(s.split('\n', 2)[1] if '\n' in s else s[:200])
        else:
            print('==== ' + s[:maxc])
        print()


if __name__ == '__main__':
    main()
