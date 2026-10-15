# -*- coding: utf-8 -*-
"""Reference checks of composite LogicModel files against client_GL (read-only).

Levels
  FAIL  the engine would reject the object, log a missing resource, or draw error.dds/BaseWhite
  WARN  the look differs from the game or a declared link is broken, rendering continues
  INFO  noted only (not counted)
Per object - and recursively per all.obj template reached through a slot:
  * names unique in the file and not colliding with all.obj (LogicModelManager keeps the first
    definition, WXLogicModelManager.cpp:633-655)
  * attribute hints consistent with EntityList / MaterialList / Slot (WXLogicModel.cpp:619-669)
  * entity meshes exist and parse, linked skeletons exist, one skeleton per object
    (shareSkeletonInstanceWith, WXLogicModel.cpp:1287-1325)
  * effective materials defined in all.material / MaterialTemplates.zip, their textures exist
    (';' lists apply per sub-entity, first as fallback, unknown names skipped: 2601-2661)
  * slot objects exist, locator bones exist in the skeleton
  * effect templates exist in all.effect, their particle systems in all.particle
  * DefaultAnimation found in the skeleton or through a <Skeletons> link (3699-3714)
"""
from . import objxml
from .objxml import B
from .data import gbk, PARTICLE_REF

RES_KEYS = ('objects', 'meshes', 'skeletons', 'dynbones', 'materials', 'textures', 'effects', 'particles',
            'animations')


class Report(object):
    def __init__(self, path):
        self.path = path
        self.issues = []
        self.res = dict((k, set()) for k in RES_KEYS)
        self.local = []

    def add(self, level, where, msg):
        self.issues.append((level, where, msg))

    def count(self, level):
        return sum(1 for i in self.issues if i[0] == level)

    @property
    def status(self):
        return 'FAIL' if self.count('FAIL') else ('WARN' if self.count('WARN') else 'OK')

    def resources_text(self, sep='|'):
        parts = []
        for k in RES_KEYS:
            vals = sorted(gbk(v) for v in self.res[k])
            parts.append('%s(%d)=%s' % (k, len(vals), sep.join(vals)))
        return '; '.join(parts)


def validate_bytes(cd, data, path='<memory>'):
    rep = Report(path)
    try:
        objs, root_tag = objxml.parse_document(data)
    except Exception as ex:            # noqa: BLE001 - report any XML error
        rep.add('FAIL', path, 'XML parse error: %s' % ex)
        return rep
    if root_tag != 'AllObjects':
        rep.add('WARN', path, 'root element <%s>: a single-object file is named after the file' % root_tag)
    local = {}
    for el in objs:
        nm = objxml.name_of(el)
        k = nm.lower()
        rep.local.append(nm)
        if k in local:
            rep.add('FAIL', gbk(nm), 'duplicate object name in the file (the engine keeps the first)')
            continue
        if cd.obj_block(nm) is not None:
            rep.add('FAIL', gbk(nm), 'object name collides with an all.obj template (the first definition wins)')
        local[k] = el
    seen = set()
    for el in objs:
        _check_object(cd, rep, el, local, seen, True)
    return rep


def validate_file(cd, path):
    with open(path, 'rb') as f:
        return validate_bytes(cd, f.read(), path)


def _check_object(cd, rep, el, local, seen, is_local):
    nm = objxml.name_of(el)
    key = nm.lower()
    if key in seen:
        return
    seen.add(key)
    where = gbk(nm)
    if not is_local:
        rep.res['objects'].add(nm)
    attrs = [(B(a.get('name', '')), B(a.get('value', '')), B(a.get('hints', ''))) for a in objxml.iter_attrs(el)]
    ents = objxml.entities(el)
    ent_by = dict((B(e.get('name', '')), e) for e in ents)
    mslots = objxml.material_slots(el)
    matslot = {}
    for m in mslots:
        en, mt = B(m.get('entity', '')), B(m.get('material', ''))
        if en not in ent_by:
            if is_local:
                rep.add('WARN', where, 'MaterialList %s targets unknown entity %s' % (gbk(B(m.get('name', ''))), gbk(en)))
        elif mt:
            matslot[en] = mt
    locs = objxml.locators(el)
    loc_names = set(B(l.get('name', '')) for l in locs)
    slots = {}
    for l in locs:
        for s in l.findall('Slot'):
            slots[B(s.get('name', ''))] = B(s.get('object', ''))

    if is_local:
        mslot_names = set(B(m.get('name', '')) for m in mslots)
        for n, v, h in attrs:
            if h == b'Mesh':
                e = ent_by.get(n)
                if e is None:
                    rep.add('WARN', where, 'Mesh attribute %s has no entity of that name' % gbk(n))
                elif B(e.get('file', '')) != v:
                    rep.add('WARN', where, 'Mesh attribute %s=%s but the entity file is %s'
                            % (gbk(n), gbk(v), gbk(B(e.get('file', '')))))
            elif h == b'Material' and n not in mslot_names:
                rep.add('WARN', where, 'Material attribute %s has no MaterialList entry' % gbk(n))
            elif h == b'SlotCreate' and n in slots and slots[n] != v:
                rep.add('WARN', where, 'slot %s holds %s but its attribute says %s' % (gbk(n), gbk(slots[n]), gbk(v)))

    # entities, skeleton, materials
    skels = []
    for e in ents:
        f = B(e.get('file', ''))
        if not f:
            continue
        rep.res['meshes'].add(f)
        info = cd.mesh(f)
        if info is None:
            rep.add('FAIL', where, 'mesh %s not found' % gbk(f))
            continue
        if info.get('err'):
            rep.add('FAIL', where, 'mesh %s unreadable (%s)' % (gbk(f), info['err']))
        sk = info.get('skel') or b''
        if sk:
            rep.res['skeletons'].add(sk)
            if cd.skeleton(sk) is None:
                rep.add('FAIL', where, 'skeleton %s (linked by %s) not found' % (gbk(sk), gbk(f)))
            skels.append(sk)
        explicit = matslot.get(B(e.get('name', ''))) or B(e.get('material', ''))
        _check_materials(cd, rep, where, f, info, explicit)
    dsk = next((v for n, v, h in attrs if n == b'DefaultSkeleton'), None)
    skel = dsk or (skels[0] if skels else None)          # B: DefaultSkeleton; 0.85: first skinned entity
    if skel:
        mi = cd.skeleton(skel)
        mb = set(mi['bones']) if mi else set()
        done = set()
        for s in skels:
            if s.lower() == skel.lower() or s.lower() in done:
                continue
            done.add(s.lower())
            si = cd.skeleton(s)
            if si is None:
                continue                                   # reported above as missing
            sb = set(si['bones'])
            dyn = (s[:-9] if s.lower().endswith(b'.skeleton') else s) + b'.dynbone'
            has_dyn = cd.find_file(dyn) is not None
            if has_dyn:
                rep.res.setdefault('dynbones', set()).add(dyn)
            if mb and mb <= sb:
                rep.add('WARN', where, 'extended skeleton %s (%s + %d bones%s): B merges it by bone name; the 0.85 '
                        'LogicModel shareSkeletonInstanceWith throws (R17)'
                        % (gbk(s), gbk(skel), len(sb - mb), ', .dynbone present' if has_dyn else ''))
            else:
                rep.add('FAIL', where, 'entities link different skeletons (%s, %s): shareSkeletonInstanceWith fails'
                        % (gbk(skel), gbk(s)))
    sinfo = cd.skeleton(skel) if skel else None
    bones = set(sinfo['bones']) if sinfo else None

    # locators and slot objects
    for l in locs:
        bn = B(l.get('bonename', ''))
        filled = [B(s.get('object', '')) for s in l.findall('Slot') if s.get('object')]
        if bn and bones is not None and bn not in bones:
            level = 'WARN' if (filled or is_local) else 'INFO'
            rep.add(level, where, 'locator %s: bone %s not in %s' % (gbk(B(l.get('name', ''))), gbk(bn), gbk(skel)))
        for o in filled:
            if o.lower() in local:
                continue                         # validated by the caller loop
            blk = cd.obj_block(o)
            if blk is None:
                rep.add('FAIL', where, 'slot object %s not found (neither in this file nor in all.obj)' % gbk(o))
                continue
            try:
                child = objxml.parse_object(blk)
            except Exception as ex:          # noqa: BLE001
                rep.add('FAIL', where, 'slot object %s is not parsable: %s' % (gbk(o), ex))
                continue
            _check_object(cd, rep, child, local, seen, False)

    # effects
    for x in objxml.effects(el):
        en, ln = B(x.get('effect', '')), B(x.get('locator', ''))
        if not en:
            continue
        rep.res['effects'].add(en)
        body = cd.effects().get(en)
        if body is None:
            rep.add('FAIL', where, 'effect template %s not in all.effect' % gbk(en))
        else:
            for ps in PARTICLE_REF.findall(body):
                rep.res['particles'].add(ps)
                if ps not in cd.particles():
                    rep.add('WARN', where, 'effect %s: particle system %s not in all.particle' % (gbk(en), gbk(ps)))
        if ln and ln not in loc_names:
            rep.add('WARN', where, 'effect %s: locator %s is not declared' % (gbk(en), gbk(ln)))

    # default animation
    da = next((v for n, v, h in attrs if n == b'DefaultAnimation'), None)
    if da:
        _check_anim(cd, rep, where, da, sinfo, objxml.skeleton_links(el), skel)


def _check_materials(cd, rep, where, mesh, info, explicit):
    subs = list(info.get('mats') or ())
    if explicit:
        ex = [m for m in explicit.split(b';') if m]
        for m in ex:
            if not cd.material_known(m):
                rep.add('WARN', where, 'material %s (set on %s) is undefined: the engine keeps the mesh material'
                        % (gbk(m), gbk(mesh)))
        if b';' in explicit:
            names = []
            for i, sm in enumerate(subs):
                cand = ex[i] if i < len(ex) else (ex[0] if ex else b'')
                names.append(cand if cd.material_known(cand) else sm)
        else:
            m = ex[0] if ex else b''
            names = [m] if cd.material_known(m) else subs
    else:
        names = subs
    for m in names:
        if not m:
            continue
        rep.res['materials'].add(m)
        if not cd.material_known(m):
            rep.add('FAIL', where, 'material %s (mesh %s) is undefined: drawn with BaseWhite' % (gbk(m), gbk(mesh)))
            continue
        mdef = cd.materials().get(m)
        if mdef and mdef['parent'] and not cd.material_known(mdef['parent']):
            rep.add('WARN', where, 'material %s: parent %s is in neither all.material nor MaterialTemplates.zip'
                    % (gbk(m), gbk(mdef['parent'])))
        for t in cd.material_textures(m):
            rep.res['textures'].add(t)
            if cd.find_file(t) is None:
                rep.add('FAIL', where, 'texture %s (material %s) not found' % (gbk(t), gbk(m)))


def _check_anim(cd, rep, where, anim, sinfo, links, skel):
    rep.res['animations'].add(anim)
    if sinfo is not None and anim in sinfo['anims']:
        return
    lk = links.get(anim)
    if lk:
        rep.res['skeletons'].add(lk)
        li = cd.skeleton(lk)
        if li is None:
            rep.add('WARN', where, 'DefaultAnimation %s: linked skeleton %s not found (bind pose)' % (gbk(anim), gbk(lk)))
        elif anim not in li['anims']:
            rep.add('WARN', where, 'DefaultAnimation %s is not in the linked skeleton %s (bind pose)' % (gbk(anim), gbk(lk)))
        return
    if sinfo is None:
        rep.add('WARN', where, 'DefaultAnimation %s: the object has no skeleton' % gbk(anim))
    else:
        rep.add('WARN', where, 'DefaultAnimation %s is neither in %s nor linked by <Skeletons> (bind pose)'
                % (gbk(anim), gbk(skel)))
