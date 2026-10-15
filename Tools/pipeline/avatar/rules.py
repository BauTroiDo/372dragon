# -*- coding: utf-8 -*-
"""Player-avatar assembly rules with evidence (recovered 2026-09-12).

Evidence prefixes
  SRC   CY-Source/Src (0.85 source; GBK files, line numbers as in the file)
  B     client_GL Game.exe (the B line), Ghidra decompiles under C:/TLBB/085/analysis/ghidra/;
        "B-src" line = the __LINE__ baked into a tThrowAssertException of that function
        (the B build compiled Obj_PlayerOther.cpp / Obj_Character.cpp from a newer source tree)
  DATA  client_GL/Data/ConfigFolder tables and ModelFolder/all.obj as of 2026-09-12
  MEM   project memory notes (C:/Users/PC -Sam/.claude/projects/C--TLBB-085/memory/)
kind: 'fact' = read from code/data; 'inference' = reasoned from facts, stated as such.
"""

LM = 'SRC Engine/WXCore/ModelSystem/WXLogicModel.cpp'
LMM = 'SRC Engine/WXCore/ModelSystem/WXLogicModelManager.cpp'
POT = 'SRC Client/WXClient/Object/Character/Obj_PlayerOther.cpp'
OCH = 'SRC Client/WXClient/Object/Character/Obj_Character.cpp'
ACT = 'SRC Engine/WXRender/Object/RFObj_Actor.cpp'
DBC = 'SRC Engine/Interface/TDDBC_Struct.h'
WO = 'B analysis/ghidra/weapon-out/'
LOADER = WO + 'loader_FUN_140124ea0_140124ea0.c'

RULES = [
    dict(id='R01', kind='fact', title='Base model per race',
         rule='CharRace[race].col3 nModelID -> CharModelEx[id].col1 = the .obj template in all.obj. '
              'client_GL: race 0 -> model 1 女主角.obj, race 1 -> model 0 男主角.obj; races 2-7 -> '
              '2638-2643 (CY 红/蓝/绿 女/男 高新手套装, outfit entities baked into the template). '
              'CharRace col4 = default face, col5 = default hair, col6/7/8 = default body/arm/foot '
              'ItemVisualChar ids. The skeleton comes from the parts (template DefaultSkeleton names it).',
         evidence=[DBC + ':14-27 (_DBC_CHAR_RACE nID,nGender,nIsPlayer,nModelID,nDefHeadGeo,nDefHairGeo,nDefBody,nDefArm,nDefFoot)',
                   POT + ':140-183 (CreateRenderInterface: CharModelEx.m_pszModelName -> Actor_SetFile; '
                   'then UpdateFaceMesh/UpdateHairMesh/UpdateHairColor/UpdateEquip x6 when Get_ModelID()==-1)',
                   POT + ':727-742 (CalcCharModelID = CharRace.nModelID unless transformed)',
                   'DATA CharRace rows 0-7; CharModelEx rows 0, 1, 2638-2643; all.obj 女主角.obj/男主角.obj']),
    dict(id='R02', kind='fact', title='Runtime assembly = attribute changes on one LogicModel',
         rule='The client never builds geometry itself: it calls Actor_SetObjectProperty(name, value) -> '
              'LogicModel::changeAttribute. hint "Mesh" -> changeEntity(name) (entity of the same name is '
              'recreated from the mesh), hint "Material" -> changeMaterial -> MaterialList entry -> '
              '_setEntityMaterial (";" = one material per sub-entity, first as fallback, unknown names '
              'silently skipped), hint "SlotCreate" -> changeSlotAttrib -> a child LogicModel created from '
              'the named .obj template in that slot. Names used: FaceMesh HairMesh MainBodyMesh FootMesh '
              'CapMesh ArmMesh (+Mat), LeftWeaponObj RightWeaponObj, weaponMat.',
         evidence=[ACT + ':73-88 (Actor_SetObjectProperty -> changeAttribute)',
                   LM + ':619-669 (changeAttribute by hint)', LM + ':757-807 (changeEntity)',
                   LM + ':835-857 (changeMaterial)', LM + ':2601-2681 (_setEntityMaterial, ";" split)',
                   LM + ':964-998, 3208-3241 (changeSlotAttrib / _createModelInSlot)',
                   'SRC Client/WXClient/Object/ObjectDef.cpp:120-143 (attribute names)',
                   'DATA 女主角.obj/男主角.obj declare Mesh: Face/Hair/Hair2/MainBody/Foot/Arm/Cap/Piaodai, '
                   'SlotCreate: Left/Right/Foot/BackWeaponObj, KFSObj, PETObj/2/4, Back/HeadOrnamentsObj']),
    dict(id='R03', kind='fact', title='The same state can be written statically',
         rule='At load initModel creates entities from EntityList files, applies MaterialList materials, '
              'creates the models named by <Slot object=...>, creates <Effects>, and handles the extra '
              'attributes MovementType/DefaultAnimation/BoundingBox/Scale. Slot children are ticked by the '
              'parent every frame. A file may hold many objects under <AllObjects>; all *.obj files of the '
              'resource group are parsed; names are lower-cased and the first definition wins. Only the first '
              '<Attributes>/<EntityList>/<MaterialList>/<Locators>/<Effects>/<Skeletons> of an object is read.',
         evidence=[LM + ':1355-1378 (initModel)', LM + ':1076-1113 (_createEntity)',
                   LM + ':2683-2706 (_setEntityMaterials, _createEffects)', LM + ':1380-1402 (_createLocatorNode)',
                   LM + ':3243-3264 (_dealWithExtraAttributes)', LM + ':1509, 1752-1768 (_executeLocatorModel)',
                   LMM + ':126 ("*.obj" script pattern)', LMM + ':196-555 (FirstChildElement parsing)',
                   LMM + ':633-655 (_mbslwr name, insert fails on duplicates)', LMM + ':660-687 (<AllObjects>)',
                   LMM + ':808-830 (getTemplateByName lower-cases)']),
    dict(id='R04', kind='fact', title='One skeleton per LogicModel',
         rule='The first entity with a skeleton creates the skeleton entity; every other entity calls '
              'shareSkeletonInstanceWith, which throws/logs on a different skeleton. All player parts must '
              'link the race skeleton (女主角.skeleton / 男主角.skeleton). Animations missing from it are '
              'loaded through the object\'s <Skeletons> links (animation -> skeleton file).',
         evidence=[LM + ':1287-1325', LM + ':3322 (_createSkeletonEntity)', LM + ':3699-3714 (_getAnimationState)',
                   LMM + ':497-555 (<Skeletons> links)',
                   'DATA W_cloth_2026李师师.mesh -> 女主角.skeleton, M_cloth_2026李师师.mesh -> 男主角.skeleton']),
    dict(id='R05', kind='fact', title='Face',
         rule='FaceMesh = CharFaceGeo[face].col2 when col1 == race & 1 (no FaceMat: the mesh material is '
              'used). Default face = CharRace col4. Exterior_Face col1/col2 = CharFaceGeo id for female/male. '
              '0.85 used CharHeadGeo (DBC 104); client_GL registers id 0x67 = CharFaceGeo.txt.',
         evidence=[WO + 'part_FUN_140116c70_140116c70.c (s_pCharHeadGeo, B-src Obj_PlayerOther.cpp:2247; '
                   'race check, FaceMesh = record+8)', LOADER + ':1997-1998 (0x67 CharFaceGeo.txt)',
                   POT + ':304-336 (0.85 UpdateFaceMesh)', 'DATA Exterior_Face 8 cols']),
    dict(id='R06', kind='fact', title='Hair',
         rule='HairMesh = CharHairGeo[hair].col2, HairMesh2 = col3 (hair ornament), when col1 == race & 1; '
              'materials come from the meshes. Default hair = CharRace col5; Exterior_Hair col1/col2 = '
              'CharHairGeo id for female/male. B blanks both under two flags (FUN_140114c80, FUN_1401b78a0) '
              'that were not resolved (presumably hair-hiding caps/dresses): the composer keeps hair. Hair '
              'colour is a colour multiplier on the HairMesh entity only.',
         evidence=[WO + 'part_FUN_140116c70_140116c70.c (s_pCharHairMesh, B-src Obj_PlayerOther.cpp:2267)',
                   LOADER + ':1991-1992 (0x65 CharHairGeo.txt)', POT + ':338-380 (0.85 UpdateHairMesh/Color)',
                   ACT + ':230-243', LM + ':3266-3283 (setHairColour -> HairMesh entity)']),
    dict(id='R07', kind='fact', title='Body parts from ItemVisualChar',
         rule='Parts 1 cap -> CapMesh/CapMat, 2 armour -> MainBodyMesh/MainBodyMat, 3 cuff -> ArmMesh/ArmMat, '
              '4 boot -> FootMesh/FootMat. Record = id + 11 cells per race: mesh = col 1+11*race, material = '
              'col 1+11*race+k (k = colour slot, 1 = base; ";" separates sub-entity materials). Missing row -> '
              'mesh cleared. Only races 0/1 (assert nRaceID < CHAR_RACE_NUM). Without equipment: CharRace '
              'col6/7/8 body/arm/foot, no cap. The cap also depends on the View_CAP option.',
         evidence=[WO + 'part_FUN_140116570_140116570.c (s_pEquipItem, B-src Obj_PlayerOther.cpp:2072, '
                   'race assert 2102, stride 0x58 = 11 cells, View_CAP)', LOADER + ':2082 (0x72 ItemVisualChar.txt)',
                   POT + ':452-517 (0.85 EquipItem_BodyPart: pVisualEntity[race*2+0/1])',
                   POT + ':656-704 (0.85 UnEquipItem -> CharRace defaults)', DBC + ':237-245']),
    dict(id='R08', kind='fact', title='Costume (时装) replaces the four parts',
         rule='EquipBase Type 25 / EquipPoint 16, col6 Visual = EquipDress index. EquipDress: col1 cap, col2 '
              'body, col3 arm, col4 foot (ItemVisualChar ids, -1 = none), col6 colour slot k, col7 dye group. '
              'Wearing it first resets cap/body/arm/foot, then applies the four EquipDress parts with colour k; '
              'a -1 part stays empty. Dress effects: SpecialDressEffect[EquipDress index] col1 (female) / col2 '
              '(male) = "effect:locator," list.',
         evidence=[WO + 'partcaller_FUN_140115180_140115180.c (equip point 0x10, s_dbcEquipDress, B-src '
                   'Obj_PlayerOther.cpp:1346; reset with sentinel then FUN_140116b80 x4)',
                   LOADER + ':2124 (0x7a EquipDress.txt)',
                   'DATA 14/14 2026 costume items: EquipBase col6 -> EquipDress -> ItemVisualChar',
                   'MEM tlbb-costume-add-pipeline (Visual = EquipDress index; SpecialDressEffect keyed by it)']),
    dict(id='R09', kind='fact', title='Weapons from ItemVisualLocator',
         rule='EquipBase col6 (weapon) = ItemVisualLocator id. RightWeaponObj = col2 (material col1), '
              'LeftWeaponObj = col5 (col6), FootWeaponObj = col11 (col12), BackWeaponObj = col15 (col16), '
              'KFSObj = col9 (col10) for equip point 18. The material is applied to the child as '
              'changeAttribute("weaponMat") - effective only if the weapon .obj declares a weaponMat Material '
              'slot, otherwise the mesh material stays. Gem effect = col 19 + (gem effect index - 1) at '
              '武器特效点. Weapon skins: Exterior_Weapon col9-12 = IVL per level, col7 = EquipBase Type. '
              'The 0.85 struct order (obj, mat) disagrees with both 0.85 and client_GL data (mat, obj); '
              'the B code is authoritative.',
         evidence=[WO + 'part_FUN_140112b40_140112b40.c (s_pWeaponItem, B-src Obj_PlayerOther.cpp:1685; '
                   'record+16/+8, +40/+48, +88/+96, +120/+128, +72/+80, gem +152)',
                   WO + 'part_FUN_1400c6110_1400c6110.c (summoner: same columns)', LOADER + ':2088 (0x73)',
                   POT + ':519-654 (0.85 EquipItem_BodyLocator)', ACT + ':393-490 (weapon effect/material)',
                   DBC + ':250-263', 'DATA ItemVisualLocator 53 cols; Exterior_Weapon 13 cols',
                   'MEM tlbb-cy4-rasoat (IVL cols 2/5/11/15), tlbb-decoweapon-add-pipeline']),
    dict(id='R10', kind='fact', title='Stance / idle animation',
         rule='EquipBase Type % 30 -> group {0:2,1:1,2:4,3:3,4:5,5:6,6:7,7:8, else 0}; ActionSetLine column = '
              'group + 1; the 15-slot patch adds Types 8/9/16/17 -> columns 12-15. Chain: CharModelEx col9 '
              '(or the rider set) -> ActionSet.txt (idx, set, action, line) -> ActionSetLine[line][column] -> '
              'ActionSetKV name. Action 0 = standing. Mount actions use the rider\'s weapon type too.',
         evidence=['B analysis/ghidra/actionsetline-switch-out/caller_FUN_140421ff0_140421ff0.c',
                   'MEM tlbb-actionsetline-15slot-patch (column = group + 1; Types 8/9/16/17)',
                   OCH + ':314-360 (ChangeAction: GetCharActionNameByActionSetID / GetMountActionNameByActionSetID '
                   'with GetWeaponType())', OCH + ':1216-1275 (UpdateChar/MountActionSetFile)',
                   'SRC Client/WXClient/Object/Item/Obj_Item_Equip.cpp:345-380, Shared/Common/GameDefine_Item.h:155-160',
                   'DATA ActionSetLine#1096 = 空手站立01 长枪站立01 ... 桃花岛站立']),
    dict(id='R11', kind='fact', title='Head/back ornaments',
         rule='Exterior_TS (head, 0x17a) / Exterior_BG (back, 0x179) col4 = ItemOrnamentsVisual id. '
              'ItemOrnamentsVisual obj = col1 when race == 0, else col3 -> HeadOrnamentsObj / BackOrnamentsObj. '
              'Per-player position offsets ((byte - 0x80) * factor) and an optional colour/effect (col7/col8, '
              'when col7 != -1) are added at run time. ItemLocatorAction (id 400) gives per-action animations '
              'to weapon/ornament children; the ornament templates carry DefaultAnimation 站立.',
         evidence=[WO + 'part_FUN_140115730_140115730.c (s_Ornaments_Visual, B-src Obj_PlayerOther.cpp:3515)',
                   WO + 'part_FUN_140115c00_140115c00.c (B-src :3627)',
                   WO + 'part_FUN_1400f8960_1400f8960.c (s_pHeadItem 0x17a / s_pBackItem 0x179 / ItemLocatorAction 400)',
                   LOADER + ':3607-3625, 3769', 'DATA Exterior_TS#23 col4=43 -> top_2026夏日彩虹小马.obj']),
    dict(id='R12', kind='fact', title='Mount + rider',
         rule='Mount model = CharModelEx[CharMount col3]; the mount LogicModel attaches the rider LogicModel '
              'to a locator: attachModel parents the rider\'s main node to that locator node (a child of the '
              'mount\'s main node) and resets its position. B CharMount: col4 draw scale, col6/col7 rider '
              'ActionSet female/male, col8 seat locator (attach1/attach2), cols 9-11 second seat, col13 jump '
              'flag, col14 add-height. In game the ridden CharMount id comes from StandardImpact logic 14.',
         evidence=[OCH + ':273-302 (CreateMountRenderInterface -> Attach_Object(rider, "attach1"))',
                   ACT + ':327-339', LM + ':2487-2529 (attachModel)', LM + ':4056-4077 (locator node = child of '
                   'the main node)', LOADER + ':2028 (0x6e CharMount.txt)',
                   'DATA CharMount 15 cols (#235 seat attach2; all.obj ride_2026争霸赛龙第三名 has attach2+attach1)',
                   'MEM tlbb-mount-add-pipeline (StandardImpact logic 14; col4 = draw scale 0.6, rider at 1)']),
    dict(id='R13', kind='inference', title='Mount scale in a static composite',
         rule='A slot child is parented to the scaled locator node and keeps its template Scale on its own '
              'node (child models never rescale their node). So: mount root Scale = s, rider template Scale = '
              '1/s -> rider renders at 1 on a mount drawn at s, which is what the game shows.',
         evidence=[LM + ':3208-3241 (_createModelInSlot: setChildModel then setScaleFactor)',
                   LM + ':4459-4467 (setScaleFactor skips the node of child models)',
                   LM + ':1345-1353 (_createMainSceneNode applies the template Scale)', LM + ':3667 (_setScaleFactor)']),
    dict(id='R14', kind='inference', title='Not reproduced / unresolved',
         rule='Hair-hiding flags (R06), View_CAP option, FUN_140117470 visibility toggles of KFS/ornament '
              'slots, per-player ornament offsets, gem effects, dye colours other than the EquipDress one, '
              'PiaodaiMesh (set nowhere in the decompiles read), sect aura (Render.dll projector '
              'aura_rune_projector<menpai>; the composer can approximate it with an <Effect>).',
         evidence=[WO + 'part_FUN_140117470_140117470.c', 'MEM tlbb-cy4-rasoat (aura_rune_projector%d = sect id)']),
    dict(id='R15', kind='fact', title='Encoding of the written objects',
         rule='all.obj dialect: GBK bytes, no XML declaration, CRLF; composite object names are ASCII '
              '(avatar_*.obj) so they never collide with GBK names; mesh/material/object names are copied as '
              'bytes from the tables (key columns are GBK even in UTF-8 tables).',
         evidence=['Docs/08-BAY-VA-QUY-TAC_vi.md 1.2-1.5', 'DATA ModelFolder/all.obj header: "<AllObjects>\\n<Object name=..."']),
    dict(id='R16', kind='fact', title='client_GL ItemVisualChar material cells are UTF-8',
         rule='The 2026-08-24 UTF-8 migration converted the ItemVisualChar material columns (col 2-11, 13-22) to '
              'UTF-8: 2,626 non-ASCII cells, 0 GBK. all.material names are GBK and Game.exe passes table bytes to '
              'LogicModel unconverted, so it never resolves them and _setEntityMaterial silently keeps the '
              'mesh-internal material. 373 cells name a base material that differs from the mesh-internal one '
              '(colour/variant rows such as IVC 130-142 "b" variants and 685 李师师01), so those looks are wrong '
              'in game today. Fix = restore the columns to GBK, as was done for SpecialDressEffect. The composer '
              'writes the GBK spelling when it exists in all.material (--ivc-materials raw reproduces the game).',
         evidence=['DATA scan of client_GL ItemVisualChar 2026-09-12: 2626 UTF-8 / 0 GBK non-ASCII material cells; '
                   '2618 resolve after UTF-8 -> GBK; 18 ASCII cells resolve as-is',
                   LM + ':2647-2661 (unknown material name -> entity keeps its material)',
                   'MEM tlbb-locator-translation-bug (UTF-8 key cells reach LogicModel as UTF-8 bytes)',
                   'MEM tlbb-costume-add-pipeline ("cot material UTF-8 (nhu 545 dong hien co)")']),
    dict(id='R17', kind='fact', title='Parts with an extended skeleton (+ .dynbone)',
         rule='Several 2026 costume/hair meshes (M_cloth_2026聂风, 七夕项羽/虞姬, 步惊云, W_hair_2026夏日海洋主题/01 '
              '...) link their own skeleton: the race skeleton\'s 56 bones plus 6-24 physics bones, no animations, '
              'with a same-named .dynbone (EntityDynamicBones XML). They display correctly in client_GL, so the B '
              'engine drives such a skeleton from the master (DefaultSkeleton) by bone name and simulates the extra '
              'bones. The 0.85 LogicModel only shares identical skeletons and fails. Composite output is the same as '
              'in game; the CY-Source LogicModel/viewer must add this (validator: WARN "extended skeleton").',
         evidence=['DATA skeleton scan 2026-09-12: m_cloth_2026聂风 70 = 男主角 56 + 14 Mp_2026niefeng*; '
                   'w_cloth_2026七夕虞姬 80 = 女主角 56 + 24; w_hair_2026夏日海洋主题 62 = 56 + 6; 0 bones missing',
                   'analysis/costume-add/COSTUME-ADD-2026-09-04_vi.md:23,29,57 (mesh/skeleton/dynbone shipped; '
                   'MEM tlbb-costume-add-pipeline: confirmed in game 2026-09-04)',
                   LM + ':1287-1325 (0.85 shareSkeletonInstanceWith only)']),
    dict(id='R18', kind='fact', title='client_GL data gaps found by the 2026 gallery',
         rule='(1) ActionSet 1606/1607 (CharMount 212/213, ride_2026冰雪狮子/01) name ride_2026冰雪狮子_站立 etc. '
              'but the skeleton only has 站立 -> no mount animation in game (the prefix trap fixed for 233-238 on '
              '09-10). (2) 男主角.obj links only 桃花岛休闲 to 男主角桃花岛站立.skeleton although the file also holds '
              '桃花岛站立 -> the male Dao Hoa Dao stance (ActionSetLine col15) cannot play. (3) Of the EquipBase '
              'weapons of Types 17/9/16, 94/15/2 name weapon objects whose mesh or skeleton is missing. (4) all.obj '
              'ride_2026冰雪狮子01.obj sets material ride_2026冰雪狮子01特效片眼睛, absent from all.material. (5) R16. '
              'The composer falls back (suffix / next column / complete item) and records a note.',
         evidence=['Build/Logs/2026-09-12-avatar/validate.tsv and index.tsv notes',
                   'DATA ride_2026冰雪狮子.skeleton animations: 飞起 高空* 降落 跑步 跑跳 休闲 休闲2 站立',
                   'MEM tlbb-mount-add-pipeline (qc_<model>_站立 prefix trap)']),
]


def render():
    out = ['Player-avatar assembly rules (CY-Source avatar composer, 2026-09-12)', '']
    for r in RULES:
        out.append('%s  %s  [%s]' % (r['id'], r['title'], r['kind']))
        out.append('    ' + r['rule'])
        for e in r['evidence']:
            out.append('    - ' + e)
        out.append('')
    return '\n'.join(out)


def write(path):
    with open(path, 'w', encoding='utf-8', newline='\r\n') as f:
        f.write(render())
    return path
