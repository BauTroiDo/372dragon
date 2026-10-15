# -*- coding: utf-8 -*-
"""V03 obj_integrity - every reference of an all.obj object resolves INSIDE the data root
(Docs/05 muc 6.1 / 7, Docs/08 muc 2.7-2.9 / 2.15 / 2.17).

The object is taken from its FIRST occurrence in all.obj (WXLogicModelManager.cpp inserts templates into a
std::map keyed by the lower-case name, so later duplicates are ignored). Checked references:
  <Entity file>                  mesh exists and walks (V01 rules); ambiguous copies warned
  submesh materials              engine rule (WXLogicModel): entity material "a;b" gives sub-entity i the i-th
                                 name (else the first); a name not defined keeps the material stored in the
                                 .mesh (warn); the material used must be defined in all.material (error)
  mesh skeleton link             skeleton exists and walks; bones per submesh (V02 check_mesh_bones)
  <Skeleton skeleton animations> extra skeletons exist, listed animations exist in them (warn)
  <Material material>            defined in all.material
  <Effect effect locator>        effect defined in all.effect; locator declared in the object (warn)
  <Slot object>                  object defined in all.obj (case-insensitive, like the engine)
  <Locator bonename>             bone exists in the object's skeleton(s)
  <ShadowUncasts><Mesh meshname> one of the object's entity meshes (warn)
  DefaultAnimation attribute     animation exists in the skeleton (warn)
check_object() returns what it resolved so that the runner can hand materials / effects / files to
V04 / V06 / V05.
"""
from . import v01_mesh, v02_skeleton
from .common import ERROR, WARN, INFO, BUILTIN_MATS, Report, disp, tags

VID = 'V03'


def check_object(root, name, report=None):
    rep = report if report is not None else Report()
    out = {'meshes': [], 'skeletons': [], 'materials': [], 'effects': [], 'textures': []}
    block = root.object_block(name)
    subj = name
    if block is None:
        rep.add(VID, ERROR, subj, 'object not defined in all.obj')
        return rep, out
    spans, first = root.objects()
    dups = sum(1 for nm, s, e in spans if nm == name)
    if dups > 1:
        rep.add(VID, WARN, subj, 'defined %d times in all.obj; the engine uses the first occurrence' % dups)
    mats = root.defs('material')['first']
    effects = root.defs('effect')['first']
    obj_names = {nm.lower() for nm in first}
    ents = tags(block, b'Entity')
    locators = {l.get(b'name', b''): l.get(b'bonename', b'').strip() for l in tags(block, b'Locator')}
    if not ents:
        rep.add(VID, WARN, subj, 'no <Entity>')
    bone_names = set()
    anim_names = set()
    entity_files = set()
    entity_names = set()
    for e in ents:
        f = e.get(b'file', b'').strip()
        entity_names.add(e.get(b'name', b''))
        if not f:
            rep.add(VID, WARN, subj, 'entity "%s" without file' % disp(e.get(b'name', b'')))
            continue
        entity_files.add(f.lower())
        rel = root.resolve(f)
        if not rel:
            rep.add(VID, ERROR, subj, 'mesh missing: ' + disp(f))
            continue
        amb = root.ambiguity(f)
        if amb:
            rep.add(VID, WARN, subj, 'mesh %s has %d copies with different content: %s' % (disp(f), len(amb), amb))
        out['meshes'].append(rel)
        mw = v01_mesh.walk_mesh(root.read(rel))
        if mw['err'] or not mw['subs']:
            rep.add(VID, ERROR, subj, 'mesh %s does not walk (%s)' % (disp(f), mw['err'] or 'no submesh'))
            continue
        attr = e.get(b'material', b'').strip()
        names = [x.strip() for x in attr.split(b';')] if attr else []
        for si, s in enumerate(mw['subs']):
            if len(names) > 1:
                cand = names[si] if si < len(names) else names[0]
            else:
                cand = names[0] if names else b''
            used = s['mat']
            if cand:
                if cand in mats or cand in BUILTIN_MATS:
                    used = cand
                else:
                    rep.add(VID, WARN, subj, 'entity material "%s" undefined, mesh material "%s" kept'
                            % (disp(cand), disp(s['mat'])))
            if used not in mats and used not in BUILTIN_MATS:
                rep.add(VID, ERROR, subj, 'material undefined: "%s" (submesh %d of %s)' % (disp(used), si, disp(f)))
            elif used not in out['materials']:
                out['materials'].append(used)
        if mw['skel']:
            srel = root.resolve(mw['skel'])
            if not srel:
                rep.add(VID, ERROR, subj, 'skeleton missing: %s (linked by %s)' % (disp(mw['skel']), disp(f)))
                continue
            if root.ambiguity(mw['skel']):
                rep.add(VID, WARN, subj, 'skeleton %s has copies with different content' % disp(mw['skel']))
            sw = v02_skeleton.walk_skeleton(root.read(srel))
            if sw['err']:
                rep.add(VID, ERROR, subj, 'skeleton %s does not walk (%s)' % (disp(mw['skel']), sw['err']))
                continue
            if srel not in out['skeletons']:
                out['skeletons'].append(srel)
            bone_names |= set(sw['bones'].values())
            anim_names |= {a for a, _l in sw['anims']}
            v02_skeleton.check_mesh_bones(mw, sw, subject='%s / %s' % (disp(name), disp(f)), report=rep)
            for ln, _span in sw['links']:
                if not root.resolve(ln):
                    rep.add(VID, ERROR, subj, 'skeleton animation link missing: ' + disp(ln))
    for sk in tags(block, b'Skeleton'):
        s = sk.get(b'skeleton', b'').strip()
        if not s:
            continue
        srel = root.resolve(s)
        if not srel:
            rep.add(VID, ERROR, subj, 'extra <Skeleton> missing: ' + disp(s))
            continue
        sw = v02_skeleton.walk_skeleton(root.read(srel))
        if sw['err']:
            rep.add(VID, ERROR, subj, 'extra skeleton %s does not walk (%s)' % (disp(s), sw['err']))
            continue
        out['skeletons'].append(srel)
        have = {a for a, _l in sw['anims']}
        miss = [a for a in sk.get(b'animations', b'').split() if a not in have]
        if miss:
            rep.add(VID, WARN, subj, 'extra skeleton %s lacks animation(s) %s' % (disp(s), ', '.join(map(disp, miss[:6]))))
    for m in tags(block, b'Material'):
        mn = m.get(b'material', b'').strip()
        if mn and mn not in mats and mn not in BUILTIN_MATS:
            rep.add(VID, ERROR, subj, '<Material> "%s" undefined' % disp(mn))
        elif mn and mn not in out['materials']:
            out['materials'].append(mn)
        ent = m.get(b'entity', b'')
        if ent and ent not in entity_names:
            rep.add(VID, WARN, subj, '<Material> for unknown entity "%s"' % disp(ent))
    for ef in tags(block, b'Effect'):
        en = ef.get(b'effect', b'').strip()
        if not en:
            continue
        if en not in effects:
            rep.add(VID, ERROR, subj, 'effect undefined in all.effect: ' + disp(en))
        elif en not in out['effects']:
            out['effects'].append(en)
        loc = ef.get(b'locator', b'').strip()
        if loc and loc not in locators:
            rep.add(VID, WARN, subj, 'effect %s on undeclared locator "%s"' % (disp(en), disp(loc)))
    for sl in tags(block, b'Slot'):
        o = sl.get(b'object', b'').strip()
        if o and o.lower() not in obj_names:
            rep.add(VID, ERROR, subj, 'slot object undefined in all.obj: ' + disp(o))
    if bone_names:
        for ln, bn in locators.items():
            if bn and bn not in bone_names:
                rep.add(VID, ERROR, subj, 'locator "%s" on bone "%s" missing in the skeleton' % (disp(ln), disp(bn)))
    for mm in tags(block, b'Mesh'):
        mn = mm.get(b'meshname', b'').strip()
        if mn and mn.lower() not in entity_files:
            rep.add(VID, WARN, subj, '<ShadowUncasts> mesh %s is not an entity of the object' % disp(mn))
    for at in tags(block, b'Attribute'):
        if at.get(b'name') == b'DefaultAnimation' and at.get(b'value', b'').strip():
            a = at[b'value'].strip()
            if anim_names and a not in anim_names:
                rep.add(VID, WARN, subj, 'DefaultAnimation "%s" not in the skeleton' % disp(a))
    rep.add(VID, INFO, subj, '%d mesh, %d skeleton, %d material, %d effect resolved' % (
        len(out['meshes']), len(out['skeletons']), len(out['materials']), len(out['effects'])))
    return rep, out
