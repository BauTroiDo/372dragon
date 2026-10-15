local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_441 = class("std_talent_441", base)
function std_talent_441:is_specific_impact(impact_id)
    return impact_id == 3833
end

function std_talent_441:get_refix_value_1(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_441:get_refix_value_2(talent, level)
    local params = talent.params[level]
    return params[2] or 0
end

function std_talent_441:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local v1 = self:get_refix_value_1(talent, level)
        local v2 = self:get_refix_value_2(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:set_skill_accuracy_rate_up(imp, v1)
            logic:set_value_of_refix_hit_rate(imp, v2)
        end
    end
end

return std_talent_441