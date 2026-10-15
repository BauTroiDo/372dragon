local class = require "class"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local item_rule_checker = class("item_rule_checker")

function item_rule_checker:check_type_ruler(rule, itemindex)
    local cls = self:get_serial_class(itemindex)
    if cls == define.ITEM_CLASS.ICLASS_EQUIP then
        local equip_base = configenginer:get_config("equip_base")
        local equip_tb = equip_base[itemindex]
        return self:check_ruler(rule, equip_tb.rule)
    elseif cls == define.ITEM_CLASS.ICLASS_GEM then
        local gem_info = configenginer:get_config("gem_info")
        local gem_tb = gem_info[itemindex]
        return self:check_ruler(rule, gem_tb.rule)
    elseif cls == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        local gem_info = configenginer:get_config("pet_equip_base")
        local gem_tb = gem_info[itemindex]
        return self:check_ruler(rule, gem_tb.rule)
    else
        local common_item = configenginer:get_config("common_item")
        local item_info = common_item[itemindex]
        assert(item_info, itemindex)
        print("check_type_ruler itemindex =", itemindex, "; item_info.rule =",  item_info.rule)
        return self:check_ruler(rule, item_info.rule)
    end
end

function item_rule_checker:get_serial_class(serial)
    return math.floor(serial / 10000000)
end

function item_rule_checker:get_serial_qual(serial)
    return math.floor((serial % 10000000) / 100000)
end

function item_rule_checker:check_ruler(rule, id)
    -- print("check_ruler rule =", rule, ";id =", id)
    local item_rule_conf = configenginer:get_config("item_ruler")
    local this_rule = item_rule_conf[id]
    if rule == define.ITEM_RULER_LIST.IRL_DISCARD then
        return this_rule.discard
    elseif rule == define.ITEM_RULER_LIST.IRL_TILE then
        return this_rule.tile
    elseif rule == define.ITEM_RULER_LIST.IRL_SHORTCUT then
        return this_rule.short_cut
    elseif rule == define.ITEM_RULER_LIST.IRL_CANSELL then
        return this_rule.can_sell
    elseif rule == define.ITEM_RULER_LIST.IRL_CANEXCHANGE then
        return this_rule.can_exchange
    elseif rule == define.ITEM_RULER_LIST.IRL_CANUSE then
        return this_rule.can_use
    elseif rule == define.ITEM_RULER_LIST.IRL_PICKBIND then
        return this_rule.is_pick_bind
    elseif rule == define.ITEM_RULER_LIST.IRL_EQUIPBIND then
        return this_rule.is_equip_bind
    elseif rule == define.ITEM_RULER_LIST.IRL_UNIQUE then
        return this_rule.is_unqiue
    elseif rule == define.ITEM_RULER_LIST.IRL_NEED_IDENT then
        return this_rule.need_ident
    end
end

return item_rule_checker