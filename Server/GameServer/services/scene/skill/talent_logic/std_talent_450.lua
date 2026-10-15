local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_450 = class("std_talent_450", base)
function std_talent_450:is_specific_impact(impact_id)
    return impact_id == 586
end

function std_talent_450:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_450:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:set_value_of_refix_speed(imp, 0)
            local value = self:get_refix_value(talent, level)
            logic:set_value_of__refix_reduce_def_fire_low_limit(imp, value)
            imp:set_impact_id(define.INVAILD_ID)
        end
    end
end

return std_talent_450