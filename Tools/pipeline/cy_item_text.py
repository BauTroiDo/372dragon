"""cy_item_text.py - item text of the CY 3.71 tables in Vietnamese (agent item-text, 15/09/2026).

Problem (gui-live-8, 14/09): item names/descriptions in the shop, bag and tooltip showed boxes. The CY 3.71 item
tables (S4 Config.axp, binary DBC 00CCBBDD) keep their strings in GBK; Game.exe x64 hands every string to CEGUI as
UTF-8 (font Noto) -> GBK bytes are invalid UTF-8 -> boxes / empty labels.

Decision: fix the data layer, not the loader. build_canonical_cy.py (cy_gui_generate) calls generate() and writes the
item tables into Assets/CanonicalCY/_generated/gui-cy/ConfigFolder as layer `cy-item-text-vi` (manifest files.tsv +
_manifest/item_text*.tsv), exactly like the StrDictionary layer. Only the DISPLAY columns listed in DISPLAY (struct
member names from Tests/abi/check_dbc_layout.py --columns: szName/szDesc/szTypeDesc/szExplain) are rewritten:
GBK -> UTF-8, then Vietnamese when a translation exists. Every other cell (INT/FLOAT and the resource-key STRING
columns: szIcon, szColor, ...) keeps its exact bytes; verify() proves it cell by cell (0 keys changed), and a
display cell that looks like a resource (path / file extension) is left untouched as well.

Vietnamese, first hit wins (same exact-match rules as cy_gui_dict.translate_strings):
  1. Registry/i18n/cy_items_vi_override.tsv   hand fixes (zh -> vi)
  2. translation memory analysis/translation/translation.db (vimap clean|color_diff, StrDictionary exclusions)
  3. Registry/i18n/cy_items_vi.tsv            API results of this tool (translate mode)
  4. Registry/i18n/cy_vi_api.tsv + cy_vi_override.tsv (cy-gui-2 project dictionary)
  5. Registry/i18n/cy_items_vi_hanviet.tsv    NAMES only: Han-Viet reading (hanviet mode; TM phrases + per character,
                                              used while the API has no balance - API/override results win)
  6. otherwise the Chinese text itself, as UTF-8 (readable with Noto SC, listed in item_text_untranslated.tsv)

usage:  python -B cy_item_text.py stats                       coverage per table/column (no writes)
        python -B cy_item_text.py build --out DIR             write converted tables + manifests into DIR, verify
        python -B cy_item_text.py translate [--kind name|desc|all] [--max N] [--workers 6] [--out LOGDIR]
        python -B cy_item_text.py hanviet                     names without translation -> cy_items_vi_hanviet.tsv
        python -B cy_item_text.py selftest
"""
import argparse
import collections
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'Docs', 'evidence', 'assetinv'))
sys.path.insert(0, HERE)
import cy_gui_dict as GDICT                 # noqa: E402

S4 = r'C:\TLBB\085\Tools\DATA NEW\CY Game\Data'
I18N = GDICT.I18N
ITEMS_TSV = os.path.join(I18N, 'cy_items_vi.tsv')                  # zh \t vi \t src \t when (translate mode)
ITEMS_FAIL_TSV = os.path.join(I18N, 'cy_items_vi_fail.tsv')
ITEMS_OVERRIDE_TSV = os.path.join(I18N, 'cy_items_vi_override.tsv')  # zh \t vi \t note (hand)
LAYER = 'cy-item-text-vi'
REPO_MAIN = r'C:\TLBB\085\CY-Source'   # Assets live in the main tree (worktrees have none)

# table -> {column: (member, kind)}; members from Tests/abi/check_dbc_layout.py --columns (CY 3.71 structs).
# kind 'name' = short label (shop/bag/tooltip title), 'desc' = long text. Resource-key columns are never listed.
DISPLAY = {
    'EquipBase.txt': {10: ('szName', 'name'), 13: ('szDesc', 'desc'), 19: ('szTypeDesc', 'name')},
    'WhiteEquipBase.txt': {10: ('szName', 'name'), 12: ('szDesc', 'desc'), 89: ('szTypeDesc', 'name')},
    'GreenEquipBase.txt': {10: ('szName', 'name'), 12: ('szDesc', 'desc'), 21: ('szTypeDesc', 'name')},
    'BlueEquipBase.txt': {10: ('szName', 'name'), 12: ('szDesc', 'desc'), 87: ('szTypeDesc', 'name')},
    'CommonItem.txt': {6: ('szName', 'name'), 7: ('szDesc', 'desc'), 19: ('szTypeDesc', 'name')},
    'GemInfo.txt': {7: ('szName', 'name'), 8: ('szDesc', 'desc')},
    'StoreMapItem.txt': {6: ('szName', 'name'), 7: ('szDesc', 'desc')},
    'EquipSetAttr.txt': {1: ('szName', 'name')},
    'ItemCompound.txt': {1: ('szName', 'name'), 24: ('szExplain', 'desc')},
    # CYS-SKILL (skills-ui 15/09): skill book / quick bar tooltip / xinfa window text, same GBK -> UTF-8 + Vietnamese
    # rule. Members: Shared/Common/GameStruct_Skill.h _DBC_SKILL_DATA, Engine/Interface/TDDBC_Struct.h
    # _DBC_SKILL_XINFA / _DBC_SKILLDATA_V1_DEPLETE. Effect/locator/action-set/impact-label columns stay keys.
    'SkillTemplate_V1.txt': {2: ('m_lpszName', 'name'), 79: ('m_pszDesc', 'desc')},
    'XinFa_V1.txt': {2: ('pszName', 'name'), 3: ('pszDesc', 'desc')},
    'SkillData_V1.txt': {1: ('szSkillDesc_Tip', 'desc'), 2: ('Skill_Desc_Interface', 'desc'), 4: ('szEffectDesc', 'name')},
    # CYS-QUEST (npc-quest 15/09): scene names - minimap title (GetCurrentSceneName), large map / world map tooltips,
    # scene-enter messages. Members: Engine/Interface/TDDBC_Struct.h _DBC_SCENE_DEFINE; columns 4-7/10/17-21/23 are
    # resource keys (scene/path/collision/minimap file, imagesets) and stay byte-identical.
    'SceneDefineEx.txt': {1: ('szName', 'name'), 22: ('szDisplayName', 'desc')},
    # CYS-I18N (i18n-cy 17/09): the cultivation (修炼) windows. Src/Client/WXClient/Network/CysPowerNet.cpp opens
    # these two tables itself (not through OpenAllDataBase) and hands the cell to CEGUI unchanged - "GBK exactly as
    # the table stores it" - so the Xiulian window showed boxes. Columns from CysPowerNet::MiJiText / ::BookText:
    # MiJi  0 id, 1 bookId, 2 name, 3 icon (Xiulian1_14 - resource key), 4 description
    # Book  0 id, 1 name, 2 icon (Xiulian1_1 - resource key), 3 description
    # XiuLianDetail.txt is NOT listed: 63 columns, every one INT/FLOAT, no STRING cell at all.
    'XiuLianMiJi.txt': {2: ('szName', 'name'), 4: ('szExplain', 'desc')},
    'XiuLianBook.txt': {1: ('szName', 'name'), 3: ('szExplain', 'desc')},
    # CYS-I18N (i18n-2 17/09): the handoff's next-in-line order was MonsterPaoPao c1 -> PetAttrTable c1/c43 ->
    # ImpactSEData_V1 c16 -> MissionTrack c1. Verified each against Src (grep for the exact struct member access, not
    # just the column name) before adding - three of those four turned out to be UNREAD by this client build:
    #   MissionTrack.txt        no DBC_MISSION_TRACK id exists anywhere; DataPool:GetLuaMissionTrackInfo (the only
    #                            Lua call that would show row text) is an un-overridden LuaApiGen catalog Stub().
    #   PetAttrTable.txt c1/43  DBC_PET_EX_ATT has exactly one read site in all of Src (GMDataPool.cpp
    #                            Pet_GetPetFoodType) and it only touches m_FoodType. The pet name shown in-game
    #                            (GMGameInterface_Script_Pet.cpp: state->PushString(pPet->pName)) comes from the
    #                            runtime creature's pName, i.e. MonsterAttrExTable - already excluded project-wide
    #                            (wire translation owns monster/NPC names). m_Name/unk_43 are dead columns.
    #   ImpactDirectly.txt c23  struct comment claims "效果描述" (GameStruct_Skill.h _DBC_DIRECT_IMPACT::m_pszInfo)
    #                            but grep for m_pszInfo across all of Src only turns up the SEPARATE _DBC_BUFF_IMPACT
    #                            (ImpactSEData_V1) reads (GMDataPool.cpp BuffImpact_GetToolTips*, PlayerMySelf.cpp
    #                            GetBuffToolTipsByIndex, Script_Pet.cpp) - never a pDirectlyImpact->m_pszInfo. The
    #                            only DirectlyImpact fields actually read are effect/locator (Obj_Character_Logic.cpp
    #                            skill-fx-parity log). Confirmed dead the same way as PetAttrTable.
    # Only MonsterPaoPao.txt c1 survived verification. The 64-table survey (Build/Logs/2026-09-17-i18n-2/survey64.tsv)
    # turned up ~20 more tables whose column NAME suggested display text; each was checked the same way (does Src
    # read this exact struct member, not just "does the column look name-shaped") before being added or dropped.
    # Confirmed READ and added below: CharTitle (szTitle/szTitleDesc - PlayerMySelf.cpp state->PushString), Ability
    # (szName/szExplain/szProgressbarName - PushString + GE_PROGRESSBAR_SHOW), ChatMood (szNobody/szMyself/szOther -
    # act.m_actMsg.push_back, szToolTip - act.m_tip), CharHairGeo/CharFaceGeo (pShowName - GetHairModelShowName /
    # GetFaceModelShowName, char-creation hairstyle/face picker), ScenePosDefine (szAimName only - WorldManager.cpp
    # copies it into the scene transport-point list; szSceneName c1 is never read in that same loop).
    # Confirmed UNREAD (struct field exists, comment looks display-ish, but grep finds zero consumer) and therefore
    # left untouched, so nobody re-adds them from the column-name heuristic alone: CharMount.txt c1 m_pszName (mount
    # name shown in-game is EquipBase.szName, the mount ITEM; CharMount's own name field has no reader - grep
    # "->m_pszName" across Src is empty), CodeConvert.txt c1 szName (its one read site, UIString.cpp
    # GenerateEmoticonTable-equivalent loop, only uses nID/szCode), ReputationTable.txt c1/c67 pszName/pszDesc
    # (CampDataMgr.cpp - the class that would read them - is entirely commented out; no other reader found),
    # SpecialObjData.txt c1/c2 m_lpszName/m_lpszToolTips (Obj_Special.cpp only reads the effect/sound/bullet fields of
    # this struct), CityBuilding.txt c2 szName and GrowPoint.txt c1 szName (struct is read - Scene.cpp / life-skill
    # code - but never the name field), FullCompareFilter.txt c2 szFullTxt (feeds a text-matching set keyed by
    # szFilterType, not obviously ever displayed - left out precautionarily), CharTitle.txt c7/c9 szComment/szCol9
    # (only szTitle/szTitleDesc are ever pushed to Lua). See Timeline/handoff/i18n-2.md for the full evidence chain.
    # Still-forbidden resource/caption columns re-confirmed while surveying (do not add these, ever):
    #   ActionSet/ActionSetKV.txt c1, CharActionSet.txt c1-9, ItemVisualLocator.txt pEffectName[]/pTail[] columns -
    #     animation-track / effect-locator names looked up BY THE TEXT ITSELF, no file extension to catch them.
    #   SkillData_V1.txt c9,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52 (paraPair.szDesc[0..14] + szCondition1Desc) and
    #   SpecialObjData.txt c25,27,29,31,33,35,37 (m_aParam.szDesc[0..6]) - a small fixed vocabulary of column-caption
    #     text repeated across many rows (proven by uniq-value counts far below row counts), not per-row flavor text.
    #   SystemColour.txt c1 strDesc - looks like a name ("名字_主角") but is a config-slot key mirroring the struct's
    #     own const-int comments (NAME_PLAYER_MYSELF etc.); translating it risks the same silent-break class as
    #     ActionSetKV if anything compares against the literal string.
    # kind='desc' (not 'name') on these two on purpose: content is full colloquial sentences/dialogue, not short
    # proper-noun-style labels - keeps them OUT of hanviet_cmd()'s per-character Han-Viet fallback (collect_need
    # filters by kind=='name'), which reads fine on a 2-4 character compound noun but produces stilted nonsense on a
    # whole sentence. A cell here with no TM hit simply stays as clean Han (UTF-8), same as any other gap.
    'MonsterPaoPao.txt': {1: ('szPaoPaoTxt', 'desc')},   # monster speech-bubble text; Obj_Character says it via
                                                         # GMInterface_Script_Talk.cpp pObj->Say(STRING(pLine->szPaoPaoTxt))
    'ImpactSEData_V1.txt': {16: ('m_pszInfo', 'desc')},  # buff/impact tooltip; BuffImpact_GetToolTips(ByIndex) in
                                                         # GMDataPool.cpp, PlayerMySelf.cpp GetBuffToolTipsByIndex assert,
                                                         # Script_Pet.cpp - c3/4/6/7/8/9/15 stay keys (icon/effect/sound/
                                                         # locator names); c23/25 (unk_23/unk_25) are commented "not used"
                                                         # in GameStruct_Skill.h and confirmed unread - do not add them.
    'CharTitle.txt': {2: ('szTitle', 'name'), 3: ('szTitleDesc', 'desc')},
    'Ability.txt': {1: ('szName', 'name'), 13: ('szExplain', 'desc'), 15: ('szProgressbarName', 'name')},
    'ChatMood.txt': {2: ('szNobody', 'desc'), 3: ('szMyself', 'desc'), 4: ('szOther', 'desc'),
                     11: ('szToolTip', 'desc')},         # c1 szCmd stays a key: m_TalkActMap.find/insert(szCmd) in
                                                         # GMInterface_Script_Talk.cpp looks it up BY THE TEXT ITSELF
    'CharHairGeo.txt': {6: ('pShowName', 'name')},
    'CharFaceGeo.txt': {4: ('pShowName', 'name')},       # table file is CharFaceGeo.txt; struct is _DBC_CHAR_HEAD_GEO
    'ScenePosDefine.txt': {5: ('szAimName', 'name')},    # c1 szSceneName has no confirmed reader; leave it
}
# CYS-I18N (i18n-2 17/09): added "model" after finding BuildingDefine.txt szLevel[0..4] city-building paths
# ("自建城市/一级县衙.model") that no other extension in this list would have caught; BuildingDefine.txt itself is
# NOT added to DISPLAY (not surveyed for a display-text column), this only widens the resource-key guard.
RES_EXT = re.compile(r'\\|\.(?:mesh|dds|tga|jpg|png|obj|skeleton|material|effect|wav|mp3|ogg|txt|lua|xml|layout|model)\b',
                     re.I)
HAN = GDICT.HAN
TOK = GDICT.TOK


def resource_like(s):
    """Path / file name, never a display label: extension or backslash; '/' only without Han (1/10, 他/她 are text)."""
    return bool(RES_EXT.search(s)) or ('/' in s and not HAN.search(s))


MAGIC = b'\x00\xcc\xbb\xdd'


# ------------------------------------------------------------------------------------------------ DBC
def parse(raw):
    """-> (fields, records, kinds tuple, cells list[int], cell_bytes {(r, c): bytes} for STRING cells)."""
    if raw[:4] != MAGIC:
        raise ValueError('not a binary DBC')
    _, nf, nr, ns = struct.unpack_from('<Iiii', raw, 0)
    kinds = struct.unpack_from('<%dI' % nf, raw, 16)
    base = 16 + 4 * nf
    cells = list(struct.unpack_from('<%dI' % (nf * nr), raw, base))
    pool = raw[base + 4 * nf * nr: base + 4 * nf * nr + ns]
    strings = {}
    for c in range(nf):
        if kinds[c] != 2:
            continue
        for r in range(nr):
            o = cells[r * nf + c]
            if o >= len(pool):
                strings[(r, c)] = b''
                continue
            e = pool.find(b'\0', o)
            strings[(r, c)] = pool[o:e if e >= 0 else len(pool)]
    return nf, nr, kinds, cells, strings


def write(nf, nr, kinds, cells, strings):
    """Binary DBC from cells + {(r, c): bytes}; pool deduplicated by bytes, offset 0 = first string."""
    pool = bytearray()
    at = {}
    out_cells = list(cells)
    for r in range(nr):
        for c in range(nf):
            if kinds[c] != 2:
                continue
            b = strings[(r, c)]
            o = at.get(b)
            if o is None:
                o = at[b] = len(pool)
                pool += b + b'\0'
            out_cells[r * nf + c] = o
    head = MAGIC + struct.pack('<iii', nf, nr, len(pool)) + struct.pack('<%dI' % nf, *kinds)
    return head + struct.pack('<%dI' % (nf * nr), *out_cells) + bytes(pool)


# ------------------------------------------------------------------------------------------------ lookup
class Lookup:
    def __init__(self, no_hanviet=False):
        self.over = GDICT.load_tsv_dict(ITEMS_OVERRIDE_TSV)
        self.tm = GDICT.TM(GDICT.DB, GDICT.DROP_DICT) if os.path.exists(GDICT.DB) else None
        self.items = GDICT.load_tsv_dict(ITEMS_TSV)
        self.extra = GDICT.Extra()
        self.hanviet = {} if no_hanviet else GDICT.load_tsv_dict(HANVIET_TSV)

    def get(self, zh):
        """-> (vi, source) or (None, 'untranslated')."""
        if zh in self.over:
            return self.over[zh], 'override'
        hit = self.tm.lookup(zh) if self.tm else None
        if hit is not None:
            return hit[0], 'tm-' + hit[1]
        if zh in self.items:
            return self.items[zh], 'api-items'
        st = zh.strip()
        if st and st != zh and st in self.items:
            i = len(zh) - len(zh.lstrip())
            return zh[:i] + self.items[st] + zh[len(zh.rstrip()):], 'api-items'
        vi = self.extra.lookup(zh)
        if vi is not None:
            return vi, 'api-gui'
        if zh in self.hanviet:
            return self.hanviet[zh], 'hanviet'
        return None, 'untranslated'


def clean(vi):
    return vi.replace('\t', ' ').replace('\r', ' ').replace('\n', ' ').replace('\0', '')


def decode(b):
    for enc in ('gbk', 'gb18030'):
        try:
            return b.decode(enc)
        except UnicodeDecodeError:
            pass
    return None


# ------------------------------------------------------------------------------------------------ convert
def convert_table(name, raw, look, untr=None):
    """-> (bytes, rows [(table, col, member, counter)])."""
    nf, nr, kinds, cells, strings = parse(raw)
    spec = DISPLAY[name]
    out = dict(strings)
    rows = []
    for c, (member, kind) in sorted(spec.items()):
        if c >= nf or kinds[c] != 2:
            raise ValueError('%s column %d is not STRING in the CY table' % (name, c))
        cnt = collections.Counter()
        for r in range(nr):
            b = strings[(r, c)]
            cnt['cells'] += 1
            if not b or all(x < 0x80 for x in b):
                cnt['ascii'] += 1
                continue
            s = decode(b)
            if s is None:
                cnt['kept-undecodable'] += 1
                continue
            if resource_like(s):
                cnt['kept-resource-like'] += 1
                continue
            cnt['converted'] += 1
            vi, src = (look.get(s) if HAN.search(TOK.sub('', s)) else (None, 'no-han'))
            if vi is None:
                if src == 'untranslated':
                    cnt['untranslated'] += 1
                    if untr is not None:
                        untr[(name, c, kind)][s] += 1
                else:
                    cnt['no-han'] += 1
                out[(r, c)] = clean(s).encode('utf-8')
            else:
                cnt[src] += 1
                cnt['translated'] += 1
                out[(r, c)] = clean(vi).encode('utf-8')
        rows.append((name, c, member, cnt))
    return write(nf, nr, kinds, cells, out), rows


def verify(name, src_raw, new_raw):
    """Every non-display cell identical, display cells valid UTF-8. -> Counter."""
    a = parse(src_raw)
    b = parse(new_raw)
    nf, nr, kinds = a[0], a[1], a[2]
    if (nf, nr, kinds) != (b[0], b[1], b[2]):
        raise AssertionError('%s header/types differ' % name)
    spec = DISPLAY[name]
    cnt = collections.Counter()
    for c in range(nf):
        for r in range(nr):
            if kinds[c] != 2:
                if a[3][r * nf + c] != b[3][r * nf + c]:
                    raise AssertionError('%s r%d c%d number changed' % (name, r, c))
                cnt['number_cells_same'] += 1
                continue
            x, y = a[4][(r, c)], b[4][(r, c)]
            if c in spec:
                cnt['display_cells'] += 1
                if x == y:
                    try:
                        y.decode('utf-8')
                    except UnicodeDecodeError:
                        cnt['display_kept_gbk'] += 1
                    continue
                y.decode('utf-8')
                cnt['display_changed'] += 1
            else:
                if x != y:
                    raise AssertionError('%s r%d c%d key string changed' % (name, r, c))
                cnt['key_string_cells_same'] += 1
    return cnt


def generate(axp, out_dir, man_dir=None):
    """Called by build_canonical_cy.cy_gui_generate with the open S4 Config.axp.
    -> ([(rel, path)], stats dict). Writes out_dir/ConfigFolder/<table> (only when bytes change)."""
    look = Lookup()
    names = {n.lower(): n for n, _ in axp.file_list()}
    files, allrows, stats = [], [], collections.Counter()
    untr = collections.defaultdict(collections.Counter)
    for table in sorted(DISPLAY):
        entry = names.get(table.lower())
        if entry is None:
            stats['table_missing'] += 1
            continue
        _, raw = axp.payload_full(entry, 256 << 20)
        data, rows = convert_table(table, raw, look, untr)
        v = verify(table, raw, data)
        for k, n in v.items():
            stats[k] += n
        allrows += rows
        rel = 'ConfigFolder\\' + table
        path = os.path.join(out_dir, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        old = open(path, 'rb').read() if os.path.exists(path) else None
        if old != data:
            with open(path + '.part', 'wb') as f:
                f.write(data)
            os.replace(path + '.part', path)
            stats['tables_written'] += 1
        files.append((rel, path))
    for _t, _c, _m, cnt in allrows:
        for k, n in cnt.items():
            stats['cell_' + k] += n
    stats['tables'] = len(files)
    stats['untranslated_unique'] = sum(len(v) for v in untr.values())
    if man_dir:
        os.makedirs(man_dir, exist_ok=True)
        keys = ['cells', 'ascii', 'converted', 'translated', 'untranslated', 'no-han', 'override', 'tm-clean',
                'tm-color_diff', 'api-items', 'api-gui', 'hanviet', 'kept-resource-like', 'kept-undecodable']
        with open(os.path.join(man_dir, 'item_text.tsv'), 'w', encoding='utf-8', newline='\n') as f:
            f.write('table\tcolumn\tmember\t' + '\t'.join(keys) + '\n')
            for t, c, m, cnt in allrows:
                f.write('%s\t%d\t%s\t%s\n' % (t, c, m, '\t'.join(str(cnt.get(k, 0)) for k in keys)))
        with open(os.path.join(man_dir, 'item_text_untranslated.tsv'), 'w', encoding='utf-8', newline='\n') as f:
            f.write('table\tcolumn\tkind\tcells\tzh\n')
            for (t, c, kind), ctr in sorted(untr.items()):
                for s, n in sorted(ctr.items(), key=lambda kv: (-kv[1], kv[0])):
                    f.write('%s\t%d\t%s\t%d\t%s\n' % (t, c, kind, n, s))
    return files, dict(stats), untr


def open_config():
    import axp_index as AX
    return AX.Axp(os.path.join(S4, 'Config.axp'))


# ------------------------------------------------------------------------------------------------ translate
NAME_PROMPT = (
    'Bạn là dịch giả game kiếm hiệp Thiên Long Bát Bộ (Trung → Việt). Các dòng sau là TÊN VẬT PHẨM / loại vật phẩm '
    'hiện trong túi đồ, cửa hàng và tooltip. Dịch theo lối Hán-Việt quen thuộc của bản Việt hoá TLBB, viết hoa chữ '
    'đầu mỗi từ, ngắn gọn (ví dụ: 青铜刀 = Thanh Đồng Đao; 猫眼石(1级) = Miêu Nhãn Thạch (Cấp 1); 馒头配方 = Phối '
    'Phương Màn Thầu; 藏宝图 = Tàng Bảo Đồ; 刀斧类 = Đao Phủ; 银票 = Ngân Phiếu; 初级药材 = Dược Liệu Sơ Cấp).\n'
    'QUY TẮC BẮT BUỘC:\n'
    '1. Các mốc dạng [[0]] [[1]] ... là MÃ ĐIỀU KHIỂN: giữ NGUYÊN VẸN, đúng số lượng; KHÔNG dịch/xoá/thêm mốc.\n'
    '2. Giữ số, chữ La-tinh, dấu ngoặc, dấu · như bản gốc. Không để sót chữ Hán.\n'
    '3. Tuân thủ THUẬT NGỮ BẮT BUỘC nếu có trong danh sách dưới.\n'
    '4. Không giải thích, không ngoặc kép. Trả về ĐÚNG định dạng: mỗi dòng `ID<TAB>bản dịch`, đủ mọi ID.\n')


def collect_need(kind='all'):
    look = Lookup(no_hanviet=True)
    ax = open_config()
    names = {n.lower(): n for n, _ in ax.file_list()}
    need = collections.defaultdict(set)
    for table, spec in DISPLAY.items():
        _, raw = ax.payload_full(names[table.lower()], 256 << 20)
        nf, nr, kinds, cells, strings = parse(raw)
        for c, (_member, k) in spec.items():
            if kind != 'all' and k != kind:
                continue
            for r in range(nr):
                b = strings[(r, c)]
                if not b or all(x < 0x80 for x in b):
                    continue
                s = decode(b)
                if s is None or resource_like(s) or not HAN.search(TOK.sub('', s)):
                    continue
                if look.get(s)[0] is None:
                    need[s].add('items-' + k)
    ax.f.close()
    return need, look


def translate(args):
    import cy_translate as CT
    CT.API_TSV = ITEMS_TSV
    CT.FAIL_TSV = ITEMS_FAIL_TSV
    need, look = collect_need(args.kind)
    if args.kind == 'name':
        CT.PROMPT = NAME_PROMPT
    tm_code = look.tm

    def fake_collect(out_dir=None):
        if out_dir:
            os.makedirs(out_dir, exist_ok=True)
            with open(os.path.join(out_dir, 'need-%s.tsv' % args.kind), 'w', encoding='utf-8', newline='\n') as f:
                f.write('zh\tsources\n')
                for z in sorted(need):
                    f.write('%s\t%s\n' % (z, ','.join(sorted(need[z]))))
        return need, set(), {'need': len(need)}, tm_code, tm_code
    CT.collect = fake_collect
    args.sources = 'items-name,items-desc'
    args.retry_failed = getattr(args, 'retry_failed', False)
    print('item strings without translation (%s): %d' % (args.kind, len(need)), flush=True)
    CT.run(args)


# ------------------------------------------------------------------------------------------------ Han-Viet names
HANVIET_JSON = r'C:\TLBB\085\analysis\translation\hanviet_from_tm.json'   # char -> reading (translation pipeline)
HANVIET_EXTRA = os.path.join(I18N, 'cy_items_hanviet_extra.tsv')          # hand readings for chars it lacks
HANVIET_TSV = os.path.join(I18N, 'cy_items_vi_hanviet.tsv')               # generated: zh \t vi \t src
_HAN_ONLY = re.compile(r'^[\u4e00-\u9fff]{2,6}$')
_FULLWIDTH = str.maketrans({'（': '(', '）': ')', '【': '[', '】': ']', '「': '"', '」': '"', '《': '"', '》': '"',
                            '：': ':', '，': ',', '、': ',', '！': '!', '？': '?', '～': '~', '－': '-', '　': ' ',
                            '＋': '+', '·': '·', '•': '·', '；': ';', '。': '.'})
_LEVEL = re.compile(r'(\d+)\s*级')


def hanviet_model(tm_db=GDICT.DB):
    """-> (readings {char: syllable}, phrases {zh: vi}) from the translation memory.
    A TM pair counts as Han-Viet when zh is 2-6 Han characters and vi has as many capitalised syllables; the most
    frequent syllable per character wins (ties keep analysis/translation/hanviet_from_tm.json)."""
    import json
    import sqlite3
    base = json.load(open(HANVIET_JSON, encoding='utf-8')) if os.path.exists(HANVIET_JSON) else {}
    db = sqlite3.connect('file:%s?mode=ro' % tm_db.replace('\\', '/'), uri=True)
    cnt = collections.defaultdict(collections.Counter)
    pairs = []
    for zh, vi in db.execute("SELECT zh, vi FROM vimap WHERE status IN ('clean','color_diff')"):
        if not _HAN_ONLY.match(zh):
            continue
        syl = vi.split()
        if len(syl) != len(zh) or not all(s[:1].isupper() and re.fullmatch(r'\w+', s) for s in syl):
            continue
        # literal alignment only: at least 2/3 of the syllables are the known reading of their character (drops
        # same-length Vietnamese rewordings such as 高级净化 = Thanh Lọc Cao Cấp)
        known = sum(1 for ch, s in zip(zh, syl) if base.get(ch, '').lower() == s.lower())
        if known * 3 < len(zh) * 2:
            continue
        pairs.append((zh, syl))
        for ch, s in zip(zh, syl):
            cnt[ch][s] += 1
    # readings: the curated hanviet_from_tm.json first (the TM count only fills characters it lacks - a count override
    # turned 等 into "Hổ"), then the hand readings
    read = dict(base)
    for ch, c in cnt.items():
        top = c.most_common(2)
        if ch not in read or (top[0][1] >= 3 and (len(top) == 1 or top[0][1] * 2 >= top[1][1] * 3)):
            read[ch] = top[0][0]     # clear TM majority (净 Tịnh 9 vs json "Cao") or the only source
    extra = GDICT.load_tsv_dict(HANVIET_EXTRA)
    read.update({h: v for h, v in extra.items() if len(h) == 1})
    # phrases (polyphones such as 长/行/乐): every syllable is the reading of its character, except at most one that is
    # an attested alternative reading of that character (>= 3 aligned TM pairs); plus hand phrases (Danh Hiệu ...)
    phrases = {}
    for zh, syl in pairs:
        miss = [(ch, s) for ch, s in zip(zh, syl) if read.get(ch, '').lower() != s.lower()]
        if not miss or (len(miss) == 1 and len(zh) >= 2 and cnt[miss[0][0]][miss[0][1]] >= 3):
            phrases[zh] = ' '.join(syl)
    phrases.update({h: v for h, v in extra.items() if len(h) > 1})
    return read, phrases


def hanviet_name(zh, read, phrases):
    """Item name -> Han-Viet (greedy longest TM phrase, then per character); None when a Han char has no reading."""
    s = _LEVEL.sub(lambda m: '<L%s>' % m.group(1), zh.translate(_FULLWIDTH)).replace('的', '')
    out, i, n = [], 0, len(s)
    while i < n:
        ch = s[i]
        if s.startswith('<L', i):
            j = s.index('>', i)
            out.append(('w', 'Cấp ' + s[i + 2:j]))
            i = j + 1
            continue
        if HAN.match(ch):
            for L in range(min(6, n - i), 1, -1):
                seg = s[i:i + L]
                if seg in phrases:
                    out.append(('w', phrases[seg]))
                    i += L
                    break
            else:
                r = read.get(ch)
                if r is None:
                    return None
                out.append(('w', r))
                i += 1
            continue
        out.append(('p', ch))
        i += 1
    text = ''
    for kind, v in out:
        if kind == 'w':
            if text and not text.endswith((' ', '(', '[', '"', '·', '-')):
                text += ' '
            text += v
        else:
            if v in '([' and text and not text.endswith(' '):
                text += ' '
            text += v
    return re.sub(r'\s+', ' ', text).strip()


def hanviet_cmd():
    read, phrases = hanviet_model()
    need, _look = collect_need('name')
    rows, miss = [], 0
    for z in sorted(need):
        vi = hanviet_name(z, read, phrases)
        if vi is None or HAN.search(vi):
            miss += 1
            continue
        rows.append((z, vi))
    # npc-quest 15/09: rows appended by cy_quest_text.py (src hanviet-quest: mission / NPC / place names) are kept
    kept = []
    if os.path.exists(HANVIET_TSV):
        names = {z for z, _ in rows}
        for ln in open(HANVIET_TSV, encoding='utf-8').read().split('\n')[1:]:
            parts = ln.rstrip('\r').split('\t')
            if len(parts) >= 3 and parts[2] == 'hanviet-quest' and parts[0] not in names:
                kept.append((parts[0], parts[1]))
    with open(HANVIET_TSV, 'w', encoding='utf-8', newline='\n') as f:
        f.write('zh\tvi\tsrc\n')
        for z, vi in rows:
            f.write('%s\t%s\thanviet\n' % (z, clean(vi)))
        for z, vi in kept:
            f.write('%s\t%s\thanviet-quest\n' % (z, clean(vi)))
    print('readings %d, TM phrases %d, names %d -> Han-Viet %d, no reading %d -> %s'
          % (len(read), len(phrases), len(need), len(rows), miss, os.path.relpath(HANVIET_TSV, REPO)))


# ------------------------------------------------------------------------------------------------ cli
def verify_cmd(data):
    """Tables on disk against the S4 originals: every key/number cell identical, display cells UTF-8, no GBK left."""
    ax = open_config()
    names = {n.lower(): n for n, _ in ax.file_list()}
    total = collections.Counter()
    for table in sorted(DISPLAY):
        _, raw = ax.payload_full(names[table.lower()], 256 << 20)
        with open(os.path.join(data, 'ConfigFolder', table), 'rb') as f:
            disk = f.read()
        v = verify(table, raw, disk)
        nf, nr, kinds, cells, strings = parse(disk)
        han = sum(1 for (r, c), b in strings.items() if c in DISPLAY[table] and HAN.search(b.decode('utf-8', 'replace')))
        print('%-20s rows %6d  key-cells same %7d  number-cells same %8d  display changed %6d  kept GBK %d  '
              'display with Han %d' % (table, nr, v['key_string_cells_same'], v['number_cells_same'],
                                       v['display_changed'], v['display_kept_gbk'], han))
        total.update(v)
        total['display_with_han'] += han
    ax.f.close()
    print('TOTAL', dict(total))
    print('keys changed: 0 (verify raises on the first changed key/number cell)')


def stats_cmd():
    ax = open_config()
    files, stats, _ = generate(ax, os.path.join(os.environ.get('TEMP', '.'), 'cy_item_text_stats'), None)
    ax.f.close()
    for k in sorted(stats):
        print('%-32s %s' % (k, stats[k]))


def selftest():
    kinds = (0, 2, 2)
    strings = {(0, 1): 'Broadsword1_1'.encode(), (0, 2): '青铜刀'.encode('gbk'),
               (1, 1): '青铜刀'.encode('gbk'), (1, 2): '青铜刀'.encode('gbk')}
    raw = write(3, 2, kinds, [7, 0, 0, 8, 0, 0], strings)
    DISPLAY['_self.txt'] = {2: ('szName', 'name')}

    class L:
        def get(self, zh):
            return ('Thanh Đồng Đao', 'tm-clean') if zh == '青铜刀' else (None, 'untranslated')
    new, rows = convert_table('_self.txt', raw, L())
    v = verify('_self.txt', raw, new)
    p = parse(new)
    assert p[4][(0, 2)] == 'Thanh Đồng Đao'.encode() and p[4][(1, 1)] == '青铜刀'.encode('gbk'), p[4]
    assert p[3][0] == 7 and p[3][3] == 8 and v['key_string_cells_same'] == 2 and v['display_changed'] == 2, v
    del DISPLAY['_self.txt']
    print('selftest OK', dict(rows[0][3]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('mode', choices=('stats', 'build', 'verify', 'translate', 'hanviet', 'selftest'))
    ap.add_argument('--data', help='verify: data root holding ConfigFolder (default Assets/CanonicalCY/Data)')
    ap.add_argument('--out')
    ap.add_argument('--kind', choices=('name', 'desc', 'all'), default='name')
    ap.add_argument('--max', type=int, default=0)
    ap.add_argument('--workers', type=int, default=6)
    ap.add_argument('--batch', type=int, default=12)
    ap.add_argument('--chars', type=int, default=1100)
    ap.add_argument('--retry-failed', action='store_true')
    args = ap.parse_args()
    if args.mode == 'selftest':
        selftest()
    elif args.mode == 'stats':
        stats_cmd()
    elif args.mode == 'build':
        ax = open_config()
        files, stats, _ = generate(ax, args.out, os.path.join(args.out, '_manifest'))
        ax.f.close()
        for k in sorted(stats):
            print('%-32s %s' % (k, stats[k]))
    elif args.mode == 'verify':
        verify_cmd(args.data or os.path.join(REPO_MAIN, 'Assets', 'CanonicalCY', 'Data'))
    elif args.mode == 'hanviet':
        hanviet_cmd()
    else:
        translate(args)


if __name__ == '__main__':
    main()
