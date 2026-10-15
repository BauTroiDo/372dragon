local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_064 = class("std_talent_064", base)
function std_talent_064:is_specific_impact(impact_id)
    return impact_id== 581
end

function std_talent_064:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_064:refix_impact(talent, level, imp)
    if self:is_specific_impact(imp:get_impact_id()) then
        local value = self:get_refix_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        if imp:get_logic_id() == 81 then
            imp:set_hit_target_count(5)
            imp:set_use_skill_success_fully_count(5)
            logic:set_skill_mind_attck_rate_up(imp, value)
        end
    end
end

return std_talent_064