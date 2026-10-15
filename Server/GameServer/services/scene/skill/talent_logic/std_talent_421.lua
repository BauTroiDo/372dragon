local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_421 = class("std_talent_421", base)

function std_talent_421:is_specific_impact(impact_id)
    return impact_id == 3831
end

function std_talent_421:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_421:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local rate = self:get_refix_value(talent, level)
            logic:set_hp_max_damage_rate(imp, rate)
        end
    end
end

return std_talent_421