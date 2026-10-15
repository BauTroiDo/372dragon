"""codegen_cpp_rules.py - hand-checked decode rules for the C++ codec generator (codegen_cpp.py).

packets.yaml describes the SERVER's codecs.  A few branch conditions of server -> client packets test
server-side state that is not on the wire (element presence, a Lua type() test, the body size), and the
extractor keeps only the element count of `for i = a, b` loops (the start is lost).  The reference
decoder speccodec.py treats unknown state as nil (branch not taken); the generated C++ uses the rules
below instead.  Every rule cites the live server source it was checked against (read-only, 2026-09-12,
\\\\wsl.localhost\\TLBB\\home\\ubuntu\\GameServer).

Keys are (owner, line): owner = packet name, or 'struct:<Name>' for a struct codec; line = the spec
node's `line` (the Lua line of the if / loop / field in the authoritative codec).

Conditions with server state that are NOT listed here still generate code: branches with identical
wire layouts are merged, anything else becomes a selector member whose decode value is a documented
default (see PgCoverage.tsv).
"""

# Branch selectors.
#   name     C++ member that stores which branch is on the wire (bool for `if` / `if-else`, else int8)
#   decode   one condition per non-else branch (spec syntax, evaluated on already decoded fields;
#            `i` is the Lua loop variable, see LOOP_START)
#   default  value when there is no decode rule (and the initial value of the member)
SELECTORS = {
    ('CLAskLogin', 237): dict(
        name='is_new_format', default=True,
        why='services/login/packet.lua:237/267: is_new_format = (#buffer - size) >= 412. Decoded from the '
            'body size; the encoder takes the member (the 0x785 client sends the new format).'),
    ('CLAskLogin', 267): dict(name='is_new_format', default=True, why='same test as line 237'),
    ('CGExteriorSharePlan', 6299): dict(
        name='is_empty_body', default=False,
        why='misc.lua:6299 `if #buffer < 1 then ... return end`: decoded from the body size.'),
    ('GCDetailEquipList', 1585): dict(
        name='present', decode=['((m_wPartFlags[math.floor(i / 8) + 1] >> (i % 8)) & 1) == 1'],
        why='misc.lua:1571-1588: bos sets bit (i % 8) of m_wPartFlags[floor(i / 8) + 1] for every present '
            'itemList[i] (i = 0..83) and then writes only the present items.'),
    ('struct:CommisionShop', 4426): dict(
        name='present', decode=['i <= size'],
        why='misc.lua:4411-4433: bos writes size = number of present merchadise_list slots, then the present '
            'slots in slot order; the slot numbers are not on the wire, so the first `size` slots are used.'),
    ('GCPetBankListUPData', 93): dict(
        name='present', decode=['((flag >> (i - 1)) & 1) == 1'],
        why='annotations.py GCPetBankListUPData: bit i-1 of flag says which pet_list[i] exist (pet.lua:81-97).'),
    ('GCBankAcquireList', 4128): dict(
        name='present', decode=['true'],
        why='misc.lua:4126-4137: bos loops i = 1..used_space and skips nil slots; the bis at 4106-4118 reads '
            'every slot, so a consistent stream has all used_space slots present.'),
    ('struct:ItemInfo', 152): dict(
        name='creator_branch', decode=['true'], default=True,
        why='item_types.lua:152 (bis) `if flag ~= 7 or self.pet_equip_type ~= 1`: the bis never reads '
            'pet_equip_type and the ctor (line 15) is empty, so it is nil and `nil ~= 1` is true - the server '
            'always reads the first branch, and a client encoder must write it.'),
    ('GCItemList', 847): dict(
        name='item_type_branch', decode=['item_list[1].type == 0', 'item_list[1].type == 1', 'false'],
        why='item.lua:844-867: the third branch tests self.type (no such field, nil), so the server never '
            'writes it; branch 0 calls stream:write(item.data) without a length, which raises in bostream:write, '
            'so in practice only the TYPE_PET branch reaches the wire.'),
    ('GCDetailAttrib_Pet', 1036): dict(
        name='extra_data_view', default=0,
        why='pet_detail_types.lua:1036-1042: 0 = GCStallPetView_t (extra_data.flag == TYPE_STALL), '
            '1 = GCExchangePetView_t; only used when has_extra_data is set.'),
    ('GCDetailAttrib_Pet', 1035): dict(
        name='has_extra_data', default=False,
        why='pet_detail_types.lua:1035: the stall / exchange view is written only when the server attached '
            'extra_data; nothing on the wire announces it (annotations.py). speccodec assumes it absent too.'),
}

# Lua loop start for arrays whose loop variable is used by a condition (spec keeps only the count).
LOOP_START = {
    ('GCAuctionBoxList', 2495): 11,   # shop.lua:2495 `for i = 11, 15` (pets use flag bits 10..14)
    ('GCDetailEquipList', 1583): 0,   # misc.lua:1583 `for i = 0, 83`
}

# Spec node overrides: keys to set on the node; '_drop' = keys to remove; '_why' = evidence.
NODE_PATCHES = {
    # CYS-INV (inventory-equip, 15/09): GCShopSoldList (buy-back list, sent by human:send_sold_out_list after every
    # CGShopSell) failed the strict decode in bot live-2 with one sold item (body 193 = 1 + 188 + 4).
    ('struct:EquipStream', 20): {
        'len_expr': '188',
        '_why': 'equip_types.lua:20 writes the bytes of item:get_stream() (lualib/item.lua:2464): ItemGUID 8 + '
                'item_index 4 + rule 1 + status 1, then 174 bytes for every class (equip_data:get_stream 174 for '
                'equip_type 0..4, material 74+1+91+8, gem 122+1+43+8, task/store map/pet equip the same size); only '
                'item_index == -1 writes 182, and an empty slot is never listed. EquipInfo bos notes "--188".'},
    ('GCUICommand', 203): {
        'len_expr': 'm_Param.m_aStrOffset[m_Param.m_StrCount] + 1',
        '_why': 'core.lua:198-203 bos: len = the last m_aStrOffset, then write(m_aStrValue, len + 1); '
                'the bis at 176-183 reads the same bytes (strings by offset, then 1 byte).'},
    ('GCPetBankListUPData', 95): {
        'type': 'struct GCDetailAttrib_Pet', 'codec': 'bos', '_drop': ['len_expr'],
        '_why': 'annotations.py: each present element is a pre-serialized GCDetailAttrib_Pet body written '
                'without a length prefix; the bis decodes it with GCDetailAttrib_Pet:bis.'},
    ('GCScriptCommand', 282): {
        'guard': '#event[i].str > 0 && #event[i].str < 256',
        '_why': 'mission.lua:280-285 (m_nCmdID == 4): writes len = #event[i].str, then the bytes only when the '
                'server-side event[i].len is in 1..255. That value is not on the wire (nil would raise in Lua); '
                'the rule assumes event[i].len == #str, as in the m_nCmdID 0/2/3 branches.'},
    ('struct:GCPlayerShopItemListForOther_t', 2098): {
        'count': 10, '_drop': ['count_expr', 'count_on_wire', 'loop'],
        '_why': 'shop.lua:2098 bos writes `for _, v in ipairs(self.stall_is_open)`; the same struct\'s bis '
                '(shop.lua:2059) reads exactly 10 bytes, so a stream the server can read back has 10.'},
    ('struct:GCPlayerShopItemListForSelf_t', 98): {
        'count': 10, '_drop': ['count_expr', 'count_on_wire', 'loop'],
        '_why': 'playershop_types.lua:98 bos writes ipairs(self.stall_is_open); the bis (line 55) reads 10 bytes.'},
    ('GCPlayerShopRecordList', 1787): {
        'count_field': '#entrys', '_drop': ['count_expr', 'count_on_wire', 'notes'],
        '_why': 'shop.lua:1783-1791: num = min(#entrys, 10) is written as the u8 `#entrys`, then exactly '
                'num entries (i = #entrys - num + 1 .. #entrys).'},
}

# (owner, if-line, original when) -> replacement condition text.
COND_PATCHES = {}
