local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_066 = class("std_talent_066", base)
function std_talent_066:is_specific_impact(impact_id)
    return impact_id== 121
end

function std_talent_066:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_066:refix_impact(talent, level, imp, sender)
    if self:is_specific_impact(imp:get_impact_id()) then
        local percent = self:get_refix_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        if imp:get_logic_id() == 64 then
            do
                local attack_physics = sender:get_attack_physics()
                local value = math.ceil(attack_physics * percent / 100)
                logic:set_value_of_refix_attrib_att_physics(imp, value)
            end
            do
                local attack_magic = sender:get_attack_magic()
                local value = math.ceil(attack_magic * percent / 100)
                logic:set_value_of_refix_attrib_att_magic(imp, value)
            end
        end
    end
end

return std_talent_066