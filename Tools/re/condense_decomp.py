# -*- coding: utf-8 -*-
"""condense_decomp.py - strip MSVC std::string / refcount boilerplate from Ghidra decompiler output so the
render-relevant statements (string literals, Ogre calls, field writes, float constants) remain.
Usage: python condense_decomp.py <in.txt> [<in2.txt> ...]   -> writes <in>_c.txt next to each input
"""
import re
import sys

DROP = [re.compile(p) for p in (
    r'^\s*local_\w+ = 0xf;$', r'^\s*local_\w+ = 0;$', r'^\s*local_\w+ = \(basic_string<.*>\)0x0;$',
    r'^\s*local_\w+ = \(OverlayElement \*\).*0xffffffffffffff00\);$', r'^\s*local_\w+\[\d+\] = local_\w+\[\d+\] & 0xffffffffffffff00;$',
    r'^\s*LOCK\(\);$', r'^\s*UNLOCK\(\);$', r'^\s*\*\(int \*\)plVar\d+ = \(int\)\*plVar\d+ \+ -1;$',
    r'^\s*\*piVar\d+ = \*piVar\d+ \+ -1;$', r'^\s*plVar\d+ = local_\w+ \+ 1;$', r'^\s*piVar\d+ = \(int \*\)\(\(longlong\)local_\w+ \+ 0xc\);$',
    r'^\s*[\w<>:,\s\*]+?\s\*?(local_|uStack_|auStack_|in_stack_|unaff_|extraout_)\w*(\s*\[\d+\])?;$',
    r'^\s*/\* WARNING:.*\*/$',
)]


def condense(lines):
    out = []
    i = 0
    n = len(lines)
    while i < n:
        s = lines[i].rstrip('\n')
        st = s.strip()
        if re.match(r'^if \(0xf < \w+\) \{$', st) and i + 2 < n and 'FUN_180034cb0' in lines[i + 1] and lines[i + 2].strip() == '}':
            i += 3
            continue
        if re.match(r'^if \(0xf < \w+\) \{$', st) and i + 2 < n and lines[i + 2].strip() == '}':
            i += 3
            continue
        if re.match(r'^if \(\(int\)\*plVar\d+ == 0\) \{$', st) or re.match(r'^if \(\*piVar\d+ == 0\) \{$', st):
            # refcount release block: skip to matching brace
            depth = 0
            while i < n:
                depth += lines[i].count('{') - lines[i].count('}')
                i += 1
                if depth <= 0:
                    break
            continue
        if any(p.match(s) for p in DROP) or not st:
            i += 1
            continue
        out.append(s)
        i += 1
    return out


def main():
    for p in sys.argv[1:]:
        lines = open(p, encoding='utf-8', errors='replace').read().split('\n')
        out = condense(lines)
        q = p[:-4] + '_c.txt' if p.endswith('.txt') else p + '_c'
        open(q, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
        print(p, len(lines), '->', len(out))


if __name__ == '__main__':
    main()
