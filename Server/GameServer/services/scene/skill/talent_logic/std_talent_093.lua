local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_093 = class("std_talent_093", base)

function std_talent_093:is_specific_impact(impact_id)
    return impact_id == 145
end

function std_talent_093:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_093:refix_impact(talent, level, imp)
    if self:is_specific_impact(imp:get_impact_id()) then
        if imp:get_logic_id() == 29 then
            local logic = impactenginer:get_logic(imp)
            if logic then
                local value = logic:get_immunity_control_rate_up(imp)
                value = value + self:get_refix_value(talent, level)
                logic:set_immunity_control_rate_up(imp, value)
            end
        end
    end
end

return std_talent_093