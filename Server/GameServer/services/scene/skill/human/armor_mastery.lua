local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local armor_mastery = class("armor_mastery", base)

function armor_mastery:is_passive()
    return true
end

function armor_mastery:refix_item_effect(skill_info, slot, ia, iv, item_type)
    local descriptor = skill_info:get_descriptor()
    local refix_defence_physics_rate = descriptor["防具的基础物理防御修正%"]
    local refix_defence_magic_rate = descriptor["防具的基础魔法防御修正%"]
    if slot == define.HUMAN_EQUIP.HEQUIP_CAP
        or slot == define.HUMAN_EQUIP.HEQUIP_ARMOR
        or slot == define.HUMAN_EQUIP.HEQUIP_CUFF
        or slot == define.HUMAN_EQUIP.HEQUIP_BOOT
        or slot == define.HUMAN_EQUIP.HEQUIP_SASH then
            if ia == define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_DEFENCE_P then
                return  math.ceil((iv or 0) *  (100 + refix_defence_physics_rate) / 100)
            elseif ia == define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_DEFENCE_M then
                return  math.ceil((iv or 0) *  (100 + refix_defence_magic_rate) / 100)
            end
    end
    return iv
end


return armor_mastery