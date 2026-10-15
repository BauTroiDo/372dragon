local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_196 = class("std_talent_196", base)

function std_talent_196:is_specific_impact(impact_id)
    return impact_id == 582
end

function std_talent_196:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_196:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        if imp:get_logic_id() == 309 then
            local logic = impactenginer:get_logic(imp)
            local refix_value = self:get_refix_value(talent, level)
            local value = logic:get_value_of_refix_speed(imp)
            value = value + refix_value
            logic:set_value_of_refix_speed(imp, value)
        end
    end
end

return std_talent_196