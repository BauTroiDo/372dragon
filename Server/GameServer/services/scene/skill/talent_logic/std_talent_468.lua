local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_468 = class("std_talent_468", base)
function std_talent_468:is_specific_impact(impact_id)
    return impact_id == 128
end

function std_talent_468:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_468:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = self:get_refix_value(talent, level)
            logic:set_value_of_mind_attack_rate_up(imp, value)
            logic:set_value_of_power_percent_refix(imp, 0)
            imp:set_activate_times(3)
        end
    end
end

return std_talent_468