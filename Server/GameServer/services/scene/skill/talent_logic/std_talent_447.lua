local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_447 = class("std_talent_447", base)

function std_talent_447:is_specific_impact(impact_id)
    return impact_id == 293
end

function std_talent_447:get_refix_value_1(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_447:get_refix_value_2(talent, level)
    local params = talent.params[level]
    return params[2] or 0
end

function std_talent_447:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local value_1 = self:get_refix_value_1(talent, level)
        local value_2 = self:get_refix_value_2(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            local refix_fire = logic:get_value_of_refix_att_fire(imp)
            refix_fire = refix_fire + value_1
            logic:set_value_of_refix_att_fire(imp, refix_fire)
            local refix_def_fire = logic:get_value_of_refix_def_fire(imp)
            refix_def_fire = refix_def_fire - value_2
            logic:set_value_of_refix_def_fire(imp, refix_def_fire)
        end
    end
end

return std_talent_447