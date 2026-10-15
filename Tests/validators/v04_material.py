# -*- coding: utf-8 -*-
"""V04 material_refs - material chain, texture aliases, texture files (Docs/05 muc 6.2 / 7, Docs/08 muc 3.1-3.3).

For one material of all.material (first definition):
  * parent chain: parents defined in all.material are followed; the first parent that is not there must be a
    template of the data root's MaterialTemplates.zip (templates may inherit inside the zip); a missing
    parent is an error;
  * texture aliases: every 'set_texture_alias <A> tex' of the chain should be declared by a 'texture_alias <A>'
    of the chain (all.material ancestors + zip templates). None of the material's aliases declared = error
    (the textures are never applied, the material renders wrong without any log); some undeclared = warn
    (extra aliases are ignored by the engine, e.g. <envTexture> on a template without that slot);
    template declares aliases but the chain sets none = warn;
  * texture files ('set_texture_alias', 'texture', 'anim_texture' frames, 'cubic_texture' faces) exist in the
    data root (error) and are not ambiguous (warn);
  * the name is defined once (duplicates warn: Docs/08 muc 2.17).
Returns the resolved texture paths so that the runner can run V05 on them.
"""
import os
import re

from .common import ERROR, WARN, INFO, BUILTIN_MATS, Report, disp

VID = 'V04'
CUBE_SUFFIX = (b'_fr', b'_bk', b'_lf', b'_rt', b'_up', b'_dn')


def texture_refs(block):
    """Texture file names referenced by one material block (templates' '<...>' placeholders skipped)."""
    out = []
    for ln in block.splitlines():
        t = ln.split(b'//', 1)[0].split()
        if len(t) < 2:
            continue
        k = t[0]
        if k == b'set_texture_alias' and len(t) >= 3:
            names = [t[2]]
        elif k == b'texture':
            names = [t[1]]
        elif k == b'anim_texture':
            if len(t) == 4 and t[2].isdigit():
                stem, ext = os.path.splitext(t[1].decode('latin-1'))
                names = [('%s_%d%s' % (stem, i, ext)).encode('latin-1') for i in range(int(t[2]))]
            else:
                names = t[1:-1]
        elif k == b'cubic_texture':
            if len(t) == 3 and t[2] == b'separateUV':
                stem, ext = os.path.splitext(t[1].decode('latin-1'))
                names = [(stem.encode('latin-1') + s + ext.encode('latin-1')) for s in CUBE_SUFFIX]
            elif len(t) >= 8:
                names = t[1:7]
            else:
                names = [t[1]]
        else:
            continue
        for n in names:
            if n and b'<' not in n and n not in out:
                out.append(n)
    return out


def chain_of(root, name):
    """-> (chain of all.material names, template name or b'', declared aliases, error or '')."""
    defs = root.defs('material')
    tmpl = root.templates()
    chain = []
    declared = set()
    cur = name
    for _ in range(16):
        if cur in defs['first'] and cur not in chain:
            chain.append(cur)
            declared |= set(re.findall(rb'texture_alias\s+(\S+)', root.def_block('material', cur)))
            parent = defs['parents'].get(cur) or b''
            if not parent:
                return chain, b'', declared, ''
            cur = parent
            continue
        if cur in tmpl:
            t, seen = cur, set()
            while t and t in tmpl and t not in seen:
                seen.add(t)
                declared |= tmpl[t]['aliases']
                t = tmpl[t]['parent']
            if t and t not in tmpl and t not in defs['first']:
                return chain, cur, declared, 'template parent "%s" missing in MaterialTemplates.zip' % disp(t)
            return chain, cur, declared, ''
        if cur in chain:
            return chain, b'', declared, 'parent cycle at "%s"' % disp(cur)
        return chain, b'', declared, 'parent "%s" is neither in all.material nor in MaterialTemplates.zip' % disp(cur)
    return chain, b'', declared, 'parent chain deeper than 16'


def check_material(root, name, report=None):
    rep = report if report is not None else Report()
    textures = []
    if name in BUILTIN_MATS:
        return rep, textures
    defs = root.defs('material')
    if name not in defs['first']:
        rep.add(VID, ERROR, name, 'material not defined in all.material')
        return rep, textures
    if name in defs['dup']:
        rep.add(VID, WARN, name, 'defined %d times in all.material' % defs['dup'][name])
    chain, template, declared, err = chain_of(root, name)
    if err:
        rep.add(VID, ERROR, name, err)
    sets = {}
    for m in reversed(chain):                       # parent first, child overrides
        for ln in root.def_block('material', m).splitlines():
            t = ln.split(b'//', 1)[0].split()
            if len(t) >= 3 and t[0] == b'set_texture_alias':
                sets[t[1]] = t[2]
    if sets:
        undeclared = [a for a in sets if a not in declared]
        if undeclared and len(undeclared) == len(sets):
            rep.add(VID, ERROR, name, 'no alias of %s is declared by the chain (template %s declares %s)'
                    % (', '.join(map(disp, undeclared)), disp(template) or '-',
                       ', '.join(sorted(map(disp, declared))) or 'nothing'))
        elif undeclared:
            rep.add(VID, WARN, name, 'alias(es) %s not declared by the chain (ignored by the engine)'
                    % ', '.join(map(disp, undeclared)))
    elif declared and template:
        rep.add(VID, WARN, name, 'template %s declares %s but the material sets no alias'
                % (disp(template), ', '.join(sorted(map(disp, declared)))))
    for m in chain:
        for t in texture_refs(root.def_block('material', m)):
            rel = root.resolve(t)
            if not rel:
                rep.add(VID, ERROR, name, 'texture missing: %s (material %s)' % (disp(t), disp(m)))
                continue
            amb = root.ambiguity(t)
            if amb:
                rep.add(VID, WARN, name, 'texture %s has %d copies with different content' % (disp(t), len(amb)))
            if rel not in textures:
                textures.append(rel)
    rep.add(VID, INFO, name, 'chain %s -> %s, %d texture(s)' % (
        ' : '.join(map(disp, chain)), disp(template) or '(none)', len(textures)))
    return rep, textures
