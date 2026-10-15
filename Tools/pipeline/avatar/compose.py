# -*- coding: utf-8 -*-
"""AvatarSpec -> composite LogicModel objects.  Rules and evidence: rules.py (R01..R16).

compose() returns the root <Object> first, followed by derived objects:
  player root   clone of the race's base template (CharRace -> CharModelEx -> all.obj) with the
                Mesh / Material / SlotCreate attributes, entity files, MaterialList materials and
                slot objects filled exactly as the client fills them at run time through
                Actor_SetObjectProperty -> LogicModel::changeAttribute (R02, R03, R15)
  weapon child  clone of the IVL weapon object with `weaponMat` baked in - only when the IVL row
                names a material AND the weapon object declares a weaponMat material slot (R09)
  mount root    clone of the mount template with Scale = CharMount col 4 and the rider in slot
                AvatarRider on the seat locator (CharMount col 8); the rider object carries
                Scale = 1/scale so it renders at 1 like the game's attachModel rider (R12, R13)
Every composite object gets a DefaultAnimation (idle of its ActionSet) so a viewer shows a
stance instead of the bind pose; the game itself never uses DefaultAnimation for characters
(Docs/08 2.9) - these objects are for viewers/tests only.

Material cells (R16): client_GL's 2026-08-24 UTF-8 migration rewrote the ItemVisualChar material
columns as UTF-8 while all.material names are GBK, and Game.exe passes table bytes to the engine
unconverted.  ivc_materials='gbk' (default) writes the GBK spelling when that name exists in
all.material (the designed look); 'raw' copies the cell bytes (reproduces the current game, which
then keeps the mesh-internal material).
"""
import hashlib
from dataclasses import dataclass, fields
from typing import Optional

from . import objxml
from .data import gbk, text

PART_ATTRS = {1: (b'CapMesh', b'CapMat'), 2: (b'MainBodyMesh', b'MainBodyMat'),
              3: (b'ArmMesh', b'ArmMat'), 4: (b'FootMesh', b'FootMat')}
PART_NAMES = {1: 'cap', 2: 'body', 3: 'arm', 4: 'foot'}
# CYS-AVATAR (14/09): IVL slot columns, KFS column, Type -> stance column and the mount/dress columns are taken from
# the column profile of the data set (data.COLUMN_PROFILES: 'cy' = CY 3.71, 'gl' = client_GL); the GL constants
# below are kept for reference only (FUN_140112b40 / FUN_140421ff0 of client_GL Game.exe).
IVL_SLOTS_GL = ((b'RightWeaponObj', 2, 1, 'rw'), (b'LeftWeaponObj', 5, 6, 'lw'),
                (b'FootWeaponObj', 11, 12, 'fw'), (b'BackWeaponObj', 15, 16, 'bw'))
KFS_SLOT_GL = (b'KFSObj', 9, 10, 'kfs')
TYPE_GROUP_GL = {0: 2, 1: 1, 2: 4, 3: 3, 4: 5, 5: 6, 6: 7, 7: 8, 8: 11, 9: 12, 16: 13, 17: 14}
SLOT_LABEL = {1: '空手', 2: '长枪', 3: '大刀', 4: '双短', 5: '单短', 6: '扇子', 7: '双环', 8: '背琴',
              9: '恶人谷', 10: 'ride/transform', 11: 'ride/transform', 12: '从刃', 13: '杖',
              14: '双手弩', 15: '桃花岛'}
# CY 3.71 ActionSetLine columns (column = CY slot + 1; CysActionSetTable.h Slot enum with the CY weapon Types of
# EquipBase: 0 刀, 1 枪/棍, 2 剑, 3 双短, 4 扇, 5 环, 6 弩, 7 杖, 8 箫剑, 16 双刀, 17 镰)
SLOT_LABEL_CY = {1: '空手', 2: '枪/棍', 3: '刀', 4: '双短', 5: '剑', 6: '扇', 7: '环', 8: '弩', 9: '箫剑',
                 10: 'Type 9', 11: 'Type 10', 12: '双刀', 13: '镰', 14: 'shared', 15: 'slot 14', 16: '杖'}
RIDER_SLOT = b'AvatarRider'
FEET_LOCATOR = '脚下光圈点'.encode('gbk')
IDLE_ACTION = 0          # ActionSet action 0 = standing (line 1096: 空手站立01, 长枪站立01, ...)
MATERIAL_MODES = ('gbk', 'raw')


class ComposeError(Exception):
    pass


def stance_slot(wtype, cd=None):
    """EquipBase weapon Type -> ActionSetLine column (1 = unarmed); profile of cd (default client_GL)."""
    if cd is not None:
        return cd.stance_column(wtype)
    if wtype is None or wtype < 0:
        return 1
    return TYPE_GROUP_GL.get(wtype % 30, 0) + 1


def slot_label(cd, col):
    return (SLOT_LABEL_CY if cd.profile == 'cy' else SLOT_LABEL).get(col, '')


@dataclass
class AvatarSpec:
    race: int = 0                        # CharRace id: 0 female, 1 male (2..7 CY novice outfits)
    model: Optional[int] = None          # CharModelEx id used as the base object instead of CharRace col3
                                         # (CY sect previews 4950..4979: complete objects, parts left as baked)
    outfit: Optional[int] = None         # NewRoleEquipset id (creation starter set: body/foot/arm ItemVisualChar)
    menpai: Optional[int] = None         # sect id (metadata; --aura uses it)
    face: Optional[int] = None           # CharFaceGeo id
    face_style: Optional[int] = None     # Exterior_Face id (col 1 female / col 2 male geo)
    hair: Optional[int] = None           # CharHairGeo id
    hair_style: Optional[int] = None     # Exterior_Hair id (col 1 female / col 2 male geo)
    no_hair: bool = False
    costume: Optional[int] = None        # EquipBase item id (Type 25) or EquipDress index
    dress_color: Optional[int] = None    # ItemVisualChar colour slot k (1 = base)
    cap: Optional[int] = None            # ItemVisualChar ids of plain equipment
    armor: Optional[int] = None
    cuff: Optional[int] = None
    boot: Optional[int] = None
    weapon: Optional[int] = None         # EquipBase weapon item id
    weapon_skin: Optional[int] = None    # Exterior_Weapon id (weapon skin / 幻饰)
    weapon_level: Optional[int] = None   # 1..4 for weapon_skin (default: highest)
    weapon_ivl: Optional[int] = None     # ItemVisualLocator id
    weapon_type: Optional[int] = None    # EquipBase Type for weapon_ivl (stance)
    kfs_ivl: Optional[int] = None        # 武魂 ItemVisualLocator id (KFSObj)
    mount: Optional[int] = None          # CharMount id, or EquipBase mount item id (Type 41)
    head: Optional[int] = None           # Exterior_TS id (head ornament)
    back: Optional[int] = None           # Exterior_BG id (back ornament)
    head_iov: Optional[int] = None       # ItemOrnamentsVisual ids (direct)
    back_iov: Optional[int] = None
    aura: bool = False                   # sect aura effect (approximation)
    anim: Optional[str] = None           # DefaultAnimation override of the root ('' = none)

    def items(self):
        return [(f.name, getattr(self, f.name)) for f in fields(self)
                if getattr(self, f.name) is not None and getattr(self, f.name) is not False]

    def describe(self):
        return ', '.join('%s=%s' % kv for kv in self.items())

    def key(self):
        return hashlib.sha1(repr(self.items()).encode('utf-8')).hexdigest()[:10]


@dataclass
class Composite:
    root: str
    elements: list
    sources: list
    notes: list
    info: dict


class _Ctx(object):
    def __init__(self, cd, root, mode):
        if mode not in MATERIAL_MODES:
            raise ComposeError('ivc_materials must be one of %s' % (MATERIAL_MODES,))
        self.cd = cd
        self.root = root
        self.mode = mode
        self.elements = []
        self.sources = []
        self.notes = []
        self.info = {'utf8_cells': 0}

    def src(self, s):
        self.sources.append(s)

    def note(self, s):
        self.notes.append(s)


def obj_name(name):
    n = name.strip().lower()
    if not n.endswith('.obj'):
        n += '.obj'
    try:
        n.encode('ascii')
    except UnicodeEncodeError:
        raise ComposeError('composite object names must be ASCII: %r' % name)
    return n


def compose(cd, spec, name, ivc_materials='gbk'):
    name = obj_name(name)
    ctx = _Ctx(cd, name, ivc_materials)
    cr = cd.row('CharRace.txt', spec.race)
    if cr is None:
        raise ComposeError('CharRace %d not found' % spec.race)
    ctx.src('CharRace#%d col3 model=%d col4 face=%d col5 hair=%d col6/7/8 body/arm/foot=%d/%d/%d'
            % (spec.race, cr[3], cr[4], cr[5], cr[6], cr[7], cr[8]))
    ctx.info['race'] = spec.race
    if spec.mount is not None:
        top = _compose_mount(ctx, spec, cr, name)
    else:
        top = _compose_player(ctx, spec, cr, name, anim_override=spec.anim)
    ctx.elements.insert(0, top)
    return Composite(name, ctx.elements, ctx.sources, ctx.notes, ctx.info)


def _material_key(ctx, cell, where):
    """Material cell bytes -> bytes to write (R16).  Returns (value, was_utf8_fixed)."""
    if not cell or ctx.mode == 'raw' or all(b < 0x80 for b in cell):
        return cell, False
    out = []
    fixed = False
    for n in cell.split(b';'):
        if not n or ctx.cd.material_known(n):
            out.append(n)
            continue
        try:
            g = n.decode('utf-8').encode('gbk')
        except (UnicodeDecodeError, UnicodeEncodeError):
            out.append(n)
            continue
        if ctx.cd.material_known(g):
            out.append(g)
            fixed = True
        else:
            out.append(n)
    if fixed:
        ctx.info['utf8_cells'] += 1
        ctx.note('%s: material cell is UTF-8 in client_GL (Game.exe cannot resolve it and keeps the mesh '
                 'material); GBK spelling written' % where)
    return b';'.join(out), fixed


# ------------------------------------------------------------------ player
def _compose_player(ctx, spec, cr, name, scale=None, anim_set=None, anim_override=None, label='avatar'):
    cd = ctx.cd
    race = spec.race
    parity = race % 2
    model_id = spec.model if spec.model is not None else cr[3]
    cme = cd.row('CharModelEx.txt', model_id)
    if cme is None:
        raise ComposeError('CharModelEx %d (CharRace %d) not found' % (model_id, race))
    base = cme[1]
    block = cd.obj_block(base)
    if block is None:
        raise ComposeError('all.obj has no template %s' % gbk(base))
    el = objxml.parse_object(block)
    el.set('name', name)
    aset = cd.cme_action_set(cme)
    ctx.src('CharModelEx#%d col1=%s col%d ActionSet=%d' % (model_id, gbk(base), cd.col('cme_action_set'), aset))
    ctx.info.setdefault('base_obj', gbk(base))
    if spec.model is not None:
        # complete object (CY 高模 sect preview): keep its baked entities, only pose it
        ctx.info['model'] = model_id
        if spec.face is None and spec.hair is None and spec.costume is None and spec.weapon is None \
                and spec.weapon_ivl is None and spec.outfit is None:
            if scale is not None:
                objxml.set_attr(el, b'Scale', ('%g %g %g' % (scale, scale, scale)).encode('ascii'))
            # baked weapon: the stance column follows --weapon-type (sect previews hold their artifact weapon)
            slot = stance_slot(spec.weapon_type, cd)
            ctx.info['stance_slot'] = slot
            _default_anim(ctx, el, anim_set if anim_set is not None else aset, slot, anim_override, label)
            return el
        if objxml.get_attr(el, b'FaceMesh') is None:
            raise ComposeError('CharModelEx %d (%s) declares no part attributes; parts cannot be applied'
                               % (model_id, gbk(base)))

    # face (R05)
    face_id = spec.face
    if face_id is None and spec.face_style is not None:
        ef = cd.row('Exterior_Face.txt', spec.face_style)
        if ef is None:
            raise ComposeError('Exterior_Face %d not found' % spec.face_style)
        face_id = ef[1 + parity]
        ctx.src('Exterior_Face#%d col%d=CharFaceGeo %d' % (spec.face_style, 1 + parity, face_id))
    if face_id is None:
        face_id = cr[4]
    _apply_face(ctx, el, face_id, parity)

    # hair (R06)
    if spec.no_hair:
        ctx.note('hair left empty on request')
    else:
        hair_id = spec.hair
        if hair_id is None and spec.hair_style is not None:
            eh = cd.row('Exterior_Hair.txt', spec.hair_style)
            if eh is None:
                raise ComposeError('Exterior_Hair %d not found' % spec.hair_style)
            hair_id = eh[1 + parity]
            ctx.src('Exterior_Hair#%d col%d=CharHairGeo %d "%s"'
                    % (spec.hair_style, 1 + parity, hair_id, text(eh[8]) if len(eh) > 8 else ''))
            ctx.info['hair_style'] = spec.hair_style
        if hair_id is None:
            hair_id = cr[5]
        _apply_hair(ctx, el, hair_id, parity)

    # body parts and costume (R07, R08)
    if race > 1:
        ctx.note('race %d: B FUN_140116570 asserts nRaceID < CHAR_RACE_NUM (2) and applies no '
                 'ItemVisualChar part; the template keeps its baked outfit' % race)
    else:
        dress = _resolve_dress(ctx, spec.costume) if spec.costume is not None else None
        if dress is not None:
            ed = cd.row('EquipDress.txt', dress)
            if ed is None:
                raise ComposeError('EquipDress %d not found' % dress)
            cc, cg = cd.col('dress_colour'), cd.col('dress_group')
            k = spec.dress_color if spec.dress_color else (ed[cc] if ed[cc] > 0 else 1)
            parts = {1: ed[1], 2: ed[2], 3: ed[3], 4: ed[4]}
            ctx.src('EquipDress#%d col1 cap=%d col2 body=%d col3 arm=%d col4 foot=%d col%d colour=%d col%d group=%d'
                    % (dress, ed[1], ed[2], ed[3], ed[4], cc, ed[cc], cg, ed[cg]))
            ctx.info['dress'] = dress
        elif spec.outfit is not None:
            ns = cd.row('NewRoleEquipset.txt', spec.outfit)
            if ns is None:
                raise ComposeError('NewRoleEquipset %d not found' % spec.outfit)
            k = 1
            parts = {1: spec.cap if spec.cap is not None else -1, 2: ns[2], 4: ns[3], 3: ns[4]}
            ctx.src('NewRoleEquipset#%d "%s" col2 body=%d col3 foot=%d col4 arm=%d (creation starter set)'
                    % (spec.outfit, text(ns[1]), ns[2], ns[3], ns[4]))
            ctx.info['outfit'] = spec.outfit
        else:
            k = 1
            parts = {1: spec.cap if spec.cap is not None else -1,
                     2: spec.armor if spec.armor is not None else cr[6],
                     3: spec.cuff if spec.cuff is not None else cr[7],
                     4: spec.boot if spec.boot is not None else cr[8]}
        for part in (1, 2, 3, 4):
            _apply_part(ctx, el, part, parts[part], race, k)
        if dress is not None:
            _apply_dress_effects(ctx, el, dress, parity)

    # weapons (R09, R10)
    ivl, wtype = _resolve_weapon(ctx, spec)
    slot = stance_slot(wtype, cd)
    if ivl is not None:
        _apply_ivl(ctx, el, name, ivl, cd.col('ivl_slots'))
        ctx.info.update(weapon_ivl=ivl, weapon_type=wtype, stance_slot=slot)
    if spec.kfs_ivl is not None:
        _apply_ivl(ctx, el, name, spec.kfs_ivl, (cd.col('kfs_slot'),))

    # ornaments (R11)
    _apply_ornament(ctx, el, race, 'head', 'Exterior_TS.txt', spec.head, spec.head_iov, b'HeadOrnamentsObj')
    _apply_ornament(ctx, el, race, 'back', 'Exterior_BG.txt', spec.back, spec.back_iov, b'BackOrnamentsObj')

    if spec.menpai is not None:
        ctx.info['menpai'] = spec.menpai
    if spec.aura:
        _apply_aura(ctx, el, spec.menpai)

    if scale is not None:
        objxml.set_attr(el, b'Scale', ('%g %g %g' % (scale, scale, scale)).encode('ascii'))
    _default_anim(ctx, el, anim_set if anim_set is not None else aset, slot, anim_override, label)
    return el


def _apply_face(ctx, el, face_id, parity):
    cd = ctx.cd
    row, table = cd.row('CharFaceGeo.txt', face_id), 'CharFaceGeo'
    if row is None:
        row, table = cd.row('CharHeadGeo.txt', face_id), 'CharHeadGeo'
    if row is None:
        ctx.note('face %d is in neither CharFaceGeo nor CharHeadGeo: FaceMesh left empty' % face_id)
        return
    if row[1] != parity:
        ctx.note('%s#%d is for race %d, not %d (B compares race & 1): FaceMesh left empty'
                 % (table, face_id, row[1], parity))
        return
    mesh = row[2]
    objxml.set_attr(el, b'FaceMesh', mesh)
    objxml.set_entity(el, b'FaceMesh', mesh)
    ctx.src('%s#%d col2=%s -> FaceMesh' % (table, face_id, gbk(mesh)))
    ctx.info['face'] = face_id


def _apply_hair(ctx, el, hair_id, parity):
    row = ctx.cd.row('CharHairGeo.txt', hair_id)
    if row is None:
        ctx.note('CharHairGeo %d not found: hair left empty' % hair_id)
        return
    if row[1] != parity:
        ctx.note('CharHairGeo#%d is for race %d, not %d: hair left empty' % (hair_id, row[1], parity))
        return
    cd = ctx.cd
    mesh1, mesh2 = cd.hair_meshes(row)
    for attr, mesh in ((b'HairMesh', mesh1), (b'HairMesh2', mesh2)):
        objxml.set_attr(el, attr, mesh)
        objxml.set_entity(el, attr, mesh)
    ctx.src('CharHairGeo#%d col%d=%s -> HairMesh, col%d=%s -> HairMesh2 "%s"'
            % (hair_id, cd.col('hair_mesh'), gbk(mesh1) or '-', cd.col('hair_mesh2'), gbk(mesh2) or '-',
               text(row[cd.col('hair_label')])))
    ctx.info['hair'] = hair_id


def _resolve_dress(ctx, costume):
    if costume >= 1000000:
        eb = ctx.cd.row('EquipBase.txt', costume)
        if eb is None:
            raise ComposeError('EquipBase %d not found' % costume)
        if eb[5] != 16:
            ctx.note('EquipBase#%d has EquipPoint %d (costumes use 16)' % (costume, eb[5]))
        ctx.src('EquipBase#%d Type=%d EquipPoint=%d col6 Visual=EquipDress %d "%s"'
                % (costume, eb[3], eb[5], eb[6], text(eb[10])))
        ctx.info['item'] = costume
        return eb[6]
    return costume


def _apply_part(ctx, el, part, ivc_id, race, k):
    mesh_attr, mat_attr = PART_ATTRS[part]
    if ivc_id is None or ivc_id < 0:
        return                                   # mesh stays "" (B clears the part)
    row = ctx.cd.row('ItemVisualChar.txt', ivc_id)
    if row is None:
        ctx.note('ItemVisualChar %d (%s) not found: part left empty' % (ivc_id, PART_NAMES[part]))
        return
    base = 1 + 11 * race
    mesh = row[base]
    col = base + k if 1 <= k <= 10 else base + 1
    cell = row[col]
    if not cell and col != base + 1:
        ctx.note('ItemVisualChar#%d has no colour-%d material (col %d): base colour used' % (ivc_id, k, col))
        col = base + 1
        cell = row[col]
    if not mesh:
        ctx.note('ItemVisualChar#%d has no race-%d mesh: %s left empty' % (ivc_id, race, PART_NAMES[part]))
        return
    mat, fixed = _material_key(ctx, cell, 'ItemVisualChar#%d col%d' % (ivc_id, col))
    objxml.set_attr(el, mesh_attr, mesh)
    objxml.set_entity(el, mesh_attr, mesh)
    objxml.set_attr(el, mat_attr, mat)
    objxml.set_material_slot(el, mat_attr, mat)
    ctx.src('ItemVisualChar#%d %s col%d=%s col%d=%s%s' % (ivc_id, PART_NAMES[part], base, gbk(mesh), col,
                                                         gbk(mat), ' (UTF-8 cell)' if fixed else ''))


def _apply_dress_effects(ctx, el, dress, parity):
    row = ctx.cd.row('SpecialDressEffect.txt', dress)
    if row is None:
        return
    n = 0
    for item in row[1 + parity].split(b','):
        item = item.strip()
        if b':' not in item:
            continue
        eff, loc = [x.strip() for x in item.split(b':', 1)]
        if not eff:
            continue
        n += 1
        objxml.add_effect(el, ('avatar_dress_%d' % n).encode('ascii'), eff, loc)
    ctx.src('SpecialDressEffect#%d col%d: %d effect(s), colour %s' % (dress, 1 + parity, n, gbk(row[3])))


def _resolve_weapon(ctx, spec):
    cd = ctx.cd
    if spec.weapon is not None:
        eb = cd.row('EquipBase.txt', spec.weapon)
        if eb is None:
            raise ComposeError('EquipBase %d not found' % spec.weapon)
        ctx.src('EquipBase#%d Type=%d EquipPoint=%d col6 Visual=IVL %d "%s"'
                % (spec.weapon, eb[3], eb[5], eb[6], text(eb[10])))
        ctx.info['weapon_item'] = spec.weapon
        return eb[6], eb[3]
    if spec.weapon_skin is not None:
        if cd.col('exterior_weapon') is None:
            raise ComposeError('weapon skins (Exterior_Weapon levels) are a client_GL feature; the CY 3.71 table '
                               'is an item catalogue - use --weapon <item id> or --weapon-ivl')
        ew = cd.row('Exterior_Weapon.txt', spec.weapon_skin)
        if ew is None:
            raise ComposeError('Exterior_Weapon %d not found' % spec.weapon_skin)
        levels = [(i + 1, ew[9 + i]) for i in range(4) if len(ew) > 9 + i and ew[9 + i] >= 0]
        if not levels:
            raise ComposeError('Exterior_Weapon %d names no ItemVisualLocator' % spec.weapon_skin)
        lvl = spec.weapon_level or levels[-1][0]
        ivl = dict(levels).get(lvl)
        if ivl is None:
            raise ComposeError('Exterior_Weapon %d has no level %d' % (spec.weapon_skin, lvl))
        ctx.src('Exterior_Weapon#%d "%s" col7 Type=%d level %d col%d=IVL %d'
                % (spec.weapon_skin, text(ew[1]), ew[7], lvl, 8 + lvl, ivl))
        ctx.info.update(weapon_skin=spec.weapon_skin, weapon_level=lvl)
        return ivl, ew[7]
    if spec.weapon_ivl is not None:
        wtype = spec.weapon_type if spec.weapon_type is not None else cd.weapon_type_of_ivl(spec.weapon_ivl)
        if wtype is None:
            ctx.note('no EquipBase weapon row uses IVL %d: stance = unarmed' % spec.weapon_ivl)
        else:
            ctx.src('EquipBase weapon rows: col6 IVL %d -> col3 Type %d' % (spec.weapon_ivl, wtype))
        return spec.weapon_ivl, wtype
    return None, None


def _apply_ivl(ctx, el, owner, ivl_id, slots):
    row = ctx.cd.row('ItemVisualLocator.txt', ivl_id)
    if row is None:
        ctx.note('ItemVisualLocator %d not found: no weapon' % ivl_id)
        return
    for slot, ocol, mcol, tag in slots:
        obj = row[ocol] if ocol < len(row) else b''
        if not obj:
            continue
        cell = row[mcol] if mcol < len(row) else b''
        mat, fixed = _material_key(ctx, cell, 'ItemVisualLocator#%d col%d' % (ivl_id, mcol))
        child = _weapon_child(ctx, owner, tag, obj, mat)
        try:
            objxml.set_slot(el, slot, child)
        except KeyError as ex:
            ctx.note('%s (engine: changeAttribute fails silently)' % ex)
            continue
        ctx.src('ItemVisualLocator#%d col%d=%s col%d=%s -> %s'
                % (ivl_id, ocol, gbk(obj), mcol, (gbk(mat) or '-') + (' (UTF-8 cell)' if fixed else ''), gbk(slot)))


def _weapon_child(ctx, owner, tag, obj, mat):
    block = ctx.cd.obj_block(obj)
    if block is None:
        ctx.note('weapon object %s is not an all.obj template' % gbk(obj))
        return obj
    if not mat:
        return obj
    wel = objxml.parse_object(block)
    if objxml.get_attr(wel, b'weaponMat') is None or objxml.get_material_slot(wel, b'weaponMat') is None:
        ctx.note('%s declares no weaponMat slot: IVL material %s is ignored by the engine (mesh material kept)'
                 % (gbk(obj), gbk(mat)))
        return obj
    child = owner[:-4] + '__' + tag + '.obj'
    wel.set('name', child)
    objxml.set_attr(wel, b'weaponMat', mat)
    objxml.set_material_slot(wel, b'weaponMat', mat)
    ctx.elements.append(wel)
    ctx.src('derived %s = %s with weaponMat %s' % (child, gbk(obj), gbk(mat)))
    return child


def _apply_ornament(ctx, el, race, kind, table, sid, iov_id, slot):
    cd = ctx.cd
    if sid is not None:
        r = cd.row(table, sid)
        if r is None:
            raise ComposeError('%s %d not found' % (table[:-4], sid))
        iov_id = r[4]
        ctx.src('%s#%d col4=ItemOrnamentsVisual %d "%s"' % (table[:-4], sid, iov_id, text(r[1])))
    if iov_id is None:
        return
    iov = cd.row('ItemOrnamentsVisual.txt', iov_id)
    if iov is None:
        ctx.note('ItemOrnamentsVisual %d not found' % iov_id)
        return
    col = 1 if race == 0 else 3
    obj = iov[col]
    if not obj:
        ctx.note('ItemOrnamentsVisual#%d col%d is empty' % (iov_id, col))
        return
    try:
        objxml.set_slot(el, slot, obj)
    except KeyError as ex:
        ctx.note('%s (engine: changeAttribute fails silently)' % ex)
        return
    ctx.src('ItemOrnamentsVisual#%d col%d=%s -> %s' % (iov_id, col, gbk(obj), gbk(slot)))
    ctx.info[kind] = iov_id


def _apply_aura(ctx, el, menpai):
    if menpai is None:
        ctx.note('--aura needs --menpai')
        return
    eff = ('aura_rune_projector%d' % menpai).encode('ascii')
    if eff not in ctx.cd.effects():
        ctx.note('effect %s is not in all.effect: sect aura skipped' % eff.decode('ascii'))
        return
    objxml.add_effect(el, b'avatar_aura', eff, FEET_LOCATOR)
    ctx.note('sect aura approximated by an <Effect> at 脚下光圈点; in game Render.dll attaches '
             'aura_rune_projector%d itself (memory tlbb-cy4-rasoat)' % menpai)


def _default_anim(ctx, el, set_id, slot, override, label):
    if override is not None:
        if override:
            objxml.set_attr(el, b'DefaultAnimation', override.encode('gbk'), b'')
            ctx.info[label + '_anim'] = override
        return
    line_id, line = ctx.cd.action_line(set_id, IDLE_ACTION)
    if line is None:
        ctx.note('ActionSet %d has no action %d: no DefaultAnimation (%s)' % (set_id, IDLE_ACTION, label))
        return
    # fallbacks: bare hands, then the shared slot (CY 13 -> column 14, GL 9 -> column 10) and the one after it
    shared = ctx.cd.col('shared_slot') + 1
    cols = [slot] + [c for c in (1, shared, shared + 1) if c != slot]
    cands = []
    for c in cols:
        if c < len(line) and line[c] >= 0:
            nm = ctx.cd.kv(line[c])
            if nm:
                cands.append((c, line[c], nm))
    if not cands:
        ctx.note('ActionSetLine#%d has no animation in columns %s (%s)' % (line_id, cols, label))
        return
    if cands[0][0] != slot:
        ctx.note('%s idle: ActionSetLine#%d column %d is empty' % (label, line_id, slot))
    avail = _anim_names(ctx, el)
    chosen = None
    for c, kid, nm in cands:
        if nm in avail:
            chosen = (c, kid, nm, nm)
            break
        suffix = nm.rsplit(b'_', 1)[-1]
        if suffix != nm and suffix in avail:
            chosen = (c, kid, nm, suffix)
            break
    if chosen is None:
        c, kid, nm = cands[0]
        chosen = (c, kid, nm, nm)
        ctx.note('%s idle "%s" (ActionSetLine#%d col%d) is neither in the skeleton nor linked by <Skeletons>: '
                 'the model shows its bind pose' % (label, gbk(nm), line_id, c))
    c, kid, nm, play = chosen
    objxml.set_attr(el, b'DefaultAnimation', play, b'')
    ctx.src('ActionSet %d action %d -> ActionSetLine#%d col%d -> ActionSetKV#%d "%s" (%s)'
            % (set_id, IDLE_ACTION, line_id, c, kid, gbk(nm), label))
    first = cands[0]
    if c != first[0]:
        ctx.note('%s idle: ActionSetLine#%d col%d "%s" cannot play on this model (not in its skeleton or '
                 '<Skeletons> links); col%d used' % (label, line_id, first[0], gbk(first[2]), c))
    if play != nm:
        ctx.note('%s idle: ActionSetKV name "%s" is not in the skeleton, its suffix "%s" is; in game this '
                 'action does not play' % (label, gbk(nm), gbk(play)))
    ctx.info[label + '_anim'] = gbk(play)


def _anim_names(ctx, el):
    """Animation names this object can play (R04): its skeleton (DefaultSkeleton attribute, else the
    first entity in std::map order whose mesh links one) plus the names of its <Skeletons> links."""
    cd = ctx.cd
    names = set(objxml.skeleton_links(el))
    skel = objxml.attr_value(el, b'DefaultSkeleton')
    if not skel:
        for e in sorted(objxml.entities(el), key=lambda x: objxml.B(x.get('name', ''))):
            f = objxml.B(e.get('file', ''))
            mi = cd.mesh(f) if f else None
            if mi and mi.get('skel'):
                skel = mi['skel']
                break
    si = cd.skeleton(skel) if skel else None
    if si:
        names |= set(si['anims'])
    return names


# ------------------------------------------------------------------ mount (R12, R13)
def _compose_mount(ctx, spec, cr, name):
    cd = ctx.cd
    mid = spec.mount
    if mid >= 1000000:
        eb = cd.row('EquipBase.txt', mid)
        if eb is None:
            raise ComposeError('EquipBase %d not found' % mid)
        ctx.src('EquipBase#%d Type=%d col6 Visual=CharMount %d "%s"' % (mid, eb[3], eb[6], text(eb[10])))
        mid = eb[6]
    cm = cd.row('CharMount.txt', mid)
    if cm is None:
        raise ComposeError('CharMount %d not found' % mid)
    parity = spec.race % 2
    mcme = cd.row('CharModelEx.txt', cm[3])
    if mcme is None:
        raise ComposeError('CharModelEx %d (CharMount %d) not found' % (cm[3], mid))
    mblock = cd.obj_block(mcme[1])
    if mblock is None:
        raise ComposeError('all.obj has no mount template %s' % gbk(mcme[1]))
    mel = objxml.parse_object(mblock)
    mel.set('name', name)
    scale = cm[4] if cm[4] > 0 else 1.0
    loc = cm[8] or b'attach1'
    rider_set = cm[6 + parity]
    ah = cd.col('mount_add_height')
    add_h = cm[ah] if len(cm) > ah else 0.0
    ctx.src('CharMount#%d "%s" col3 model=%d col4 scale=%g col%d rider ActionSet=%d col8 seat=%s col%d addHeight=%g'
            % (mid, text(cm[1]), cm[3], scale, 6 + parity, rider_set, gbk(loc), ah, add_h))
    ctx.src('CharModelEx#%d col1=%s col%d ActionSet=%d' % (cm[3], gbk(mcme[1]), cd.col('cme_action_set'),
                                                         cd.cme_action_set(mcme)))
    ctx.info.update(mount=mid, mount_obj=gbk(mcme[1]), mount_scale=scale)
    objxml.set_attr(mel, b'Scale', ('%g %g %g' % (scale, scale, scale)).encode('ascii'))
    rider = name[:-4] + '__rider.obj'
    rel = _compose_player(ctx, spec, cr, rider, scale=1.0 / scale, anim_set=rider_set, label='rider')
    try:
        objxml.add_slot(mel, loc, RIDER_SLOT, rider)
    except KeyError as ex:
        raise ComposeError('%s: %s' % (gbk(mcme[1]), ex))
    _default_anim(ctx, mel, cd.cme_action_set(mcme), ctx.info.get('stance_slot', 1), spec.anim, 'mount')
    if add_h:
        ctx.note('CharMount col%d add-height %g not applied (it only lifts mount and rider together)' % (ah, add_h))
    ctx.elements.insert(0, rel)
    return mel
