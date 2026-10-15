local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_381 = class("std_talent_381", base)

function std_talent_381:is_specific_impact(impact_id)
    return impact_id == 1305
end

function std_talent_381:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_381:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        if imp:get_logic_id() == 13 then
            local logic = impactenginer:get_logic(imp)
            local percent = self:get_refix_value(talent, level)
            local value = logic:get_value_of_refix_attrib_hit(imp)
            value = math.ceil(value * (100 + percent) / 100)
            logic:set_value_of_refix_attrib_hit(imp, value)
        end
    end
end

return std_talent_381