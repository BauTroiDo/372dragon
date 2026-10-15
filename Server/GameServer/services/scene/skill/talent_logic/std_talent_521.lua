local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_521 = class("std_talent_521", base)
function std_talent_521:is_specific_impact(impact_data_index)
    return impact_data_index == 42881
end

function std_talent_521:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_521:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = self:get_refix_value(talent, level)
            logic:set_value_of_take_effect_time(imp, value)
        end
    end
end

return std_talent_521