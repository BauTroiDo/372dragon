local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_469 = class("std_talent_469", base)
-- 两个武道共用: 151择风化雨(461) / 807金乌照影(462)
function std_talent_469:is_specific_impact(impact_id)
    return impact_id == 461 or impact_id == 462
end

function std_talent_469:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_469:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = self:get_refix_value(talent, level)
            logic:set_value_of_mind_attack_value_up(imp, value)
            logic:set_value_of_power_percent_refix(imp, 0)
        end
    end
end

return std_talent_469