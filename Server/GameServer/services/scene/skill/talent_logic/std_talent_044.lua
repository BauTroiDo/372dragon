local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_044 = class("std_talent_044", base)

function std_talent_044:is_specific_impact(impact_id)
    return impact_id == 103
end

function std_talent_044:get_refix_impact_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_044:refix_impact(talent, level, imp)
    local impact_id = imp:get_impact_id()
    if self:is_specific_impact(impact_id) then
        local value = self:get_refix_impact_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        if imp:get_logic_id() == 26 then
            local rate = logic:get_reflect_rate(imp)
            rate = rate + value
            logic:set_reflect_rate(imp, rate)
        end
    end
end

return std_talent_044