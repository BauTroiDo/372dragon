local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_435 = class("std_talent_435", base)

function std_talent_435:is_specific_impact(impact_id)
    return impact_id == 106
end

function std_talent_435:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_435:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local value = self:get_refix_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:set_recover_hp_rate(imp, value)
        end
    end
end

return std_talent_435