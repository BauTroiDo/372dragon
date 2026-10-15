local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_459 = class("std_talent_459", base)
function std_talent_459:is_specific_impact(impact_id)
    return impact_id == 121
end

function std_talent_459:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_459:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local refix_value = self:get_refix_value(talent, level)
            logic:set_is_ignore_defence(imp, 0)
            logic:set_value_of__refix_reduce_def_fire_low_limit(imp, refix_value)
            imp:set_impact_id(define.INVAILD_ID)
        end
    end
end

return std_talent_459