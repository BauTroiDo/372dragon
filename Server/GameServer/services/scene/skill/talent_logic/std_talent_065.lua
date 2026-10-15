local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_065 = class("std_talent_065", base)
function std_talent_065:is_specific_impact(impact_id)
    return impact_id== 581
end

function std_talent_065:get_refix_value(talent, level, i)
    local params = talent.params[level]
    return params[i] or 0
end

function std_talent_065:refix_impact(talent, level, imp, sender)
    if self:is_specific_impact(imp:get_impact_id()) then
        local value_1 = self:get_refix_value(talent, level, 1)
        local value_2 = self:get_refix_value(talent, level, 2)
        local logic = impactenginer:get_logic(imp)
        if imp:get_logic_id() == 81 then
            local hp = sender:get_hp()
            hp = math.floor(hp * 0.2)
            sender:health_increment(-1 * hp)
            logic:set_fobidden_heal(imp)

            local mind_attack_rate = logic:get_skill_mind_attck_rate_up(imp)
            logic:set_skill_mind_attck_rate_up(imp, mind_attack_rate + value_1)

            local immunity_control_rate = logic:get_immunity_control_rate_up(imp)
            logic:set_immunity_control_rate_up(imp, immunity_control_rate + value_2)
        end
    end
end

return std_talent_065