local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local weapon_mastery = class("weapon_mastery", base)

function weapon_mastery:is_passive()
    return true
end

function weapon_mastery:refix_item_effect(skill_info, slot, ia, iv, item_type)
    local descriptor = skill_info:get_descriptor()
    local refix_attr_physics_rate = descriptor["武器的基础物理攻击修正%"]
    local refix_attr_magic_rate = descriptor["武器的基础魔法攻击修正%"]
    local weapon_type_1 = descriptor["武器类型1"]
    local weapon_type_2 = descriptor["武器类型2"]
    if slot == define.HUMAN_EQUIP.HEQUIP_WEAPON then
        if item_type == weapon_type_1 or item_type == weapon_type_2 then
            if ia == define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_ATTACK_P then
                return  math.ceil((iv or 0) *  (100 + refix_attr_physics_rate) / 100)
            elseif ia == define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_MAGIC_P then
                return  math.ceil((iv or 0) *  (100 + refix_attr_magic_rate) / 100)
            end
        end
    end
    return iv
end


return weapon_mastery