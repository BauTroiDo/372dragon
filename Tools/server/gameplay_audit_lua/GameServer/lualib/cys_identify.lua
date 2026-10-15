-- Identification scroll limits are generated from CY CommonItem descriptions,
-- not from item ID arithmetic (the level 11+ IDs are not contiguous).
local define = require 'define'
local guard = require 'cys_inventory_guard'
local limits = require 'cys_identify_limits'
local logic = require 'human_item_logic'
local packets = require 'game.packet'
local M = {}
function M.use(h, scroll_pos, equip_pos)
    local R, T, E = define.USEITEM_RESULT, define.COMMON_ITEM_TYPE, define.HUMAN_EQUIP
    local bag = h:get_prop_bag_container()
    if not guard.accepts(bag, scroll_pos) or not guard.accepts(bag, equip_pos)
        or scroll_pos == equip_pos then return R.USEITEM_IDENT_TARGET_TYPE_FAIL end
    local scroll, equip = bag:get_item(scroll_pos), bag:get_item(equip_pos)
    if not scroll or scroll:is_empty() or scroll:is_lock() or scroll:get_lay_count() < 1 then
        return R.USEITEM_IDENT_TYPE_FAIL
    end
    local typ, maximum = scroll:get_serial_type(), limits[scroll:get_index()]
    if not maximum or scroll:get_serial_quality() ~= define.COMMON_ITEM_QUAL.COMITEM_QUAL_MIS then
        return R.USEITEM_IDENT_TYPE_FAIL
    end
    if not equip or equip:is_empty() or equip:is_lock() or not equip:is_equip() or equip:is_identd() then
        return R.USEITEM_IDENT_TARGET_TYPE_FAIL
    end
    if not h:is_alive() then return R.USEITEM_SKILL_FAIL end
    -- Config lookup may yield; identities are checked again below.
    local cfg = equip:get_base_config()
    if not cfg then return R.USEITEM_IDENT_TARGET_TYPE_FAIL end
    local point = cfg.equip_point
    local expected = point == E.HEQUIP_WEAPON and T.COMITEM_WPIDENT
        or (point == E.HEQUIP_CAP or point == E.HEQUIP_ARMOR or point == E.HEQUIP_CUFF or point == E.HEQUIP_GLOVE or point == E.HEQUIP_SHOULDER
            or point == E.HEQUIP_BOOT or point == E.HEQUIP_SASH) and T.COMITEM_ARIDENT
        or (point == E.HEQUIP_RING_1 or point == E.HEQUIP_RING_2 or point == E.HEQUIP_NECKLACE
            or point == E.HEQUIP_AMULET_1 or point == E.HEQUIP_AMULET_2) and T.COMITEM_NCIDENT
    if typ ~= T.COMITEM_COIDENT and typ ~= expected then return R.USEITEM_IDENT_TARGET_TYPE_FAIL end
    if (cfg.require_level or cfg.level or 0) > maximum then return R.USEITEM_IDENT_LEVEL_FAIL end
    if bag:get_item(scroll_pos) ~= scroll or bag:get_item(equip_pos) ~= equip
        or scroll:is_lock() or equip:is_lock() or scroll:get_lay_count() < 1 or equip:is_identd()
        or not h:is_alive() then return R.USEITEM_IDENT_TARGET_TYPE_FAIL end
    if not logic:dec_item_lay_count({}, h, scroll_pos, 1, scroll:get_index()) then return R.USEITEM_IDENT_TYPE_FAIL end
    equip:set_is_identd(true)
    local msg = packets.GCItemInfo.new()
    msg.bagIndex, msg.item = equip_pos, equip:copy_raw_data()
    h:get_scene():send2client(h, msg)
    h:get_scene():get_impact_enginer():send_impact_to_unit(h, 18, h, 0, false, 0)
    return R.USEITEM_SUCCESS
end
return M
