local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_154 = class("std_talent_154", base)

function std_talent_154:is_specific_impact(impact_id)
    return impact_id == 179
end

function std_talent_154:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_154:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        if imp:get_logic_id() == 13 then
            local logic = impactenginer:get_logic(imp)
            logic:set_value_of_refix_mind_attack(imp, 0)
            local value = self:get_refix_value(talent, level)
            logic:set_value_of_refix_attrib_hit(imp, value)
        end
    end
end

return std_talent_154