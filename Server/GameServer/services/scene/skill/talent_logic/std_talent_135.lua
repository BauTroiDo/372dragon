local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_135 = class("std_talent_135", base)
function std_talent_135:is_specific_impact(impact_id)
    return impact_id == 173
end

function std_talent_135:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_135:refix_impact(talent, level, imp)
    if self:is_specific_impact(imp:get_impact_id()) then
        if imp:get_logic_id() == 13 then
            local percent = self:get_refix_value(talent, level)
            local logic = impactenginer:get_logic(imp)
            local value = logic:get_value_of_refix_mind_attack(imp)
            value = math.ceil(value * (100 + percent) / 100)
            logic:set_value_of_refix_mind_attack(imp, value)
        end
    end
end

return std_talent_135