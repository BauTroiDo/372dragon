# -*- coding: utf-8 -*-
"""ogre_api_gap.py - list OgreMain.dll (B, client_GL) exported methods of rendering-relevant classes and flag the
ones whose identifier does not exist anywhere in the 0.85 OGRE source (OgreMain include+src).
Read-only.  Output: Tools/re/out/ogre_api_gap.tsv (+ summary on stdout)
"""
import collections
import glob
import os
import re

import pefile

B = r'C:\TLBB\085\client_GL\Bin64\OgreMain.dll'
SRC = r'C:\TLBB\085\CY-Source\Src\Engine\OGRE\OgreMain'
OUT = r'C:\TLBB\085\CY-Source\Tools\re\out\ogre_api_gap.tsv'
CLASSES = ['AutoParamDataSource', 'GpuProgramParameters', 'Pass', 'TextureUnitState', 'Technique', 'Material',
           'MaterialSerializer', 'SceneManager', 'CompositionTechnique', 'CompositionTargetPass', 'CompositionPass',
           'CompositorInstance', 'CompositorChain', 'Compositor', 'CompositorManager', 'SceneRenderProxy',
           'RenderConfigManager', 'ParticleSystem', 'ParticleSystemManager', 'UIParticleSystem', 'Entity', 'SubEntity',
           'GfxLayer', 'HighLevelGpuProgram', 'GpuProgram', 'GpuProgramManager', 'Camera', 'Viewport', 'RenderTarget',
           'TextureManager', 'Texture', 'RenderSystem', 'MovableObject', 'Renderable', 'BillboardParticleRenderer',
           'ParticleSystemRenderer', 'ParticleEmitter', 'ParticleAffector', 'RenderQueue', 'RenderQueueGroup',
           'MergeParticleSystem', 'BackParticleSystem', 'IParticleSystem', 'ParticleSystemData', 'TangentSpaceCalc',
           'FuncProfileManager', 'PixelUtil', 'Image']


def main():
    pe = pefile.PE(B, fast_load=True)
    pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
    names = [e.name.decode('latin-1') for e in pe.DIRECTORY_ENTRY_EXPORT.symbols if e.name]
    text = []
    for p in glob.glob(SRC + r'\**\*.*', recursive=True):
        if re.search(r'\.(h|cpp|inl)$', p, re.I):
            text.append(open(p, 'rb').read().decode('latin-1'))
    ident = set(re.findall(r'\b[A-Za-z_]\w*\b', '\n'.join(text)))
    rows = []
    per = collections.defaultdict(lambda: collections.defaultdict(list))
    for n in names:
        m = re.match(r'^\?([A-Za-z_]\w*)@([A-Za-z_]\w*)@Ogre@@', n)
        if not m:
            continue
        meth, cls = m.group(1), m.group(2)
        if cls in CLASSES:
            per[cls][meth].append(n)
    summ = {}
    for cls in CLASSES:
        new = 0
        for meth, ms in sorted(per[cls].items()):
            in085 = meth in ident
            new += 0 if in085 else 1
            rows.append((cls, meth, len(ms), 'Y' if in085 else 'NEW', ms[0]))
        summ[cls] = (len(per[cls]), new)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write('class\tmethod\toverloads\tidentifier_in_0.85_src\tsample_mangled\n')
        for r in rows:
            f.write('%s\t%s\t%d\t%s\t%s\n' % r)
    for cls, (a, b) in summ.items():
        if a:
            print('%-28s methods=%3d new_vs_0.85=%3d  %s' % (cls, a, b, ' '.join(r[1] for r in rows if r[0] == cls and r[3] == 'NEW')[:600]))


if __name__ == '__main__':
    main()
