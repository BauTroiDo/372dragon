# -*- coding: utf-8 -*-
"""pf_summary.py - per-function digest of Ghidra decompiles: string literals + Ogre compositor/material calls +
TextureDefinition field writes + float/int immediates written to objects.  Input: *_c.txt from condense_decomp.py
Usage: python pf_summary.py <in_c.txt> <out.txt>
"""
import re
import sys

KEEP = re.compile(r'"|Ogre::Composit|createTextureDefinition|setMaterial|setInput|setOutput|setType|setIdentifier|'
                  r'createTargetPass|createPass|setClear|RenderQueue|setShadows|setVisibility|setOnlyInitial|'
                  r'setNumInitial|setLodBias|setMaterialScheme|pTVar\d+ \+ 0x|\(float \*\)|= 0x3[ef]|= 0x4[0-4]|'
                  r'setParameter|getParameter|setNamedConstant|setAutoConstant|PixelFormat|PF_|createTexture|'
                  r'addCompositor|setCompositorEnabled|setEnabled|getSingleton|FUN_18007bb30|FUN_18007af90|'
                  r'readFloat|\+ 8\)\)\(|ScaleFactor|Width|Height|format')


def main():
    src, dst = sys.argv[1], sys.argv[2]
    text = open(src, encoding='utf-8', errors='replace').read()
    parts = re.split(r'(?m)^==== FUNCTION ', text)
    out = []
    for p in parts[1:]:
        head, _, body = p.partition('\n')
        lines = [l.strip() for l in body.split('\n') if KEEP.search(l)]
        lits = []
        for l in re.findall(r'"((?:[^"\\]|\\.)*)"', body):
            if not lits or lits[-1] != l:
                lits.append(l)
        out.append('#### ' + head.strip())
        out.append('   literals: ' + ' | '.join(lits)[:3000])
        for l in lines:
            out.append('   ' + l[:220])
    open(dst, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
    print(dst, len(out))


if __name__ == '__main__':
    main()
