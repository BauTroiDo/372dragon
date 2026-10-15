# -*- coding: utf-8 -*-
"""pf_digest.py - compact "compositor script" reconstruction from condensed Ghidra decompiles of the Render.dll (B)
post-filter builder functions (pf_builders_c.txt).  Emits, per function: texture definitions (name, reference,
raw field writes by offset), target passes (output alias, input mode), passes (type, material, inputs, id).
Offsets are raw Ogre::CompositionTechnique::TextureDefinition field offsets of the B OgreMain build (see spec).
Usage: python pf_digest.py <pf_builders_c.txt> <out.txt>
"""
import re
import sys


def lit_before(lines, i, var):
    # find FUN_180002590(&var,"literal" ...) before line i
    for j in range(i - 1, max(-1, i - 40), -1):
        m = re.search(r'FUN_1800025[0-9a-f]0\(&?%s,"((?:[^"\\]|\\.)*)"' % re.escape(var), lines[j])
        if m:
            return m.group(1)
        m = re.search(r'FUN_180001260\(&?%s,"((?:[^"\\]|\\.)*)"' % re.escape(var), lines[j])
        if m:
            return m.group(1)
    return '?'


def digest(body):
    lines = [l.strip() for l in body.split('\n')]
    out = []
    tex = {}
    for i, l in enumerate(lines):
        m = re.search(r'(\w+) = Ogre::CompositionTechnique::createTextureDefinition\(\w+,&?(\w+)\)', l)
        if m:
            tex[m.group(1)] = lit_before(lines, i, m.group(2))
            out.append('TEX %s' % tex[m.group(1)])
            continue
        m = re.match(r'^\*?\(?(?:\w+ \*)?\)?\(?(\w+) \+ (0x[0-9a-f]+)\)? = (.+);$', l.replace('*(', '(').replace('(undefined4 *)', '').replace('(undefined8 *)', '').replace('(float *)', '').replace('(ulonglong *)', '').replace('(uint *)', ''))
        if m and m.group(1) in tex:
            out.append('   %s.+%s = %s' % (tex[m.group(1)], m.group(2), m.group(3)))
            continue
        m = re.search(r'FUN_180002590\((\w+) \+ (0x[0-9a-f]+),"([^"]*)"', l)
        if m and m.group(1) in tex:
            out.append('   %s.+%s = "%s"' % (tex[m.group(1)], m.group(2), m.group(3)))
            continue
        m = re.search(r'\w+\[(0x[0-9a-f]+)\] = .*', l)
        if m and any(l.startswith(v + '[') for v in tex):
            v = l.split('[')[0]
            out.append('   %s.[%s] %s' % (tex[v], m.group(1), l.split('=', 1)[1].strip()))
            continue
        m = re.search(r'Ogre::(Composition\w+)::(\w+)\((.*)\);?$', l)
        if m:
            cls, meth, args = m.groups()
            if meth in ('setMaterialName', 'setOutputNameAlias', 'setInputRTAliasName', 'setOutputRTAliasName', 'setOutputName'):
                vars_ = re.findall(r'&(\w+)', args)
                vals = [lit_before(lines, i, v) for v in vars_]
                out.append('%s.%s(%s)' % (cls.replace('Composition', ''), meth, ', '.join(vals) or args))
            elif meth == 'setInputAlias' or meth == 'setInput':
                vars_ = re.findall(r'&(\w+)', args)
                vals = [lit_before(lines, i, v) for v in vars_]
                out.append('%s.%s(%s | %s)' % (cls.replace('Composition', ''), meth, args, ', '.join(vals)))
            elif meth not in ('createTechnique',):
                out.append('%s.%s(%s)' % (cls.replace('Composition', ''), meth, args[:80]))
    return out


def main():
    text = open(sys.argv[1], encoding='utf-8', errors='replace').read()
    parts = re.split(r'(?m)^==== FUNCTION ', text)
    res = []
    for p in parts[1:]:
        head, _, body = p.partition('\n')
        d = digest(body)
        lits = []
        for l in re.findall(r'"((?:[^"\\]|\\.)*)"', body):
            if not lits or lits[-1] != l:
                lits.append(l)
        res.append('#### ' + head.strip())
        res.append('   literals: ' + ' | '.join(lits)[:1500])
        res.extend('   ' + x for x in d)
    open(sys.argv[2], 'w', encoding='utf-8', newline='\n').write('\n'.join(res))
    print(sys.argv[2], len(res))


if __name__ == '__main__':
    main()
