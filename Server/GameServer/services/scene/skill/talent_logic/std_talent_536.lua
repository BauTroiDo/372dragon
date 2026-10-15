local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_536 = class("std_talent_536", base)
function std_talent_536:is_specific_impact(impact_data_index)
    return impact_data_index >= 29483 and impact_data_index <= 29498
end

function std_talent_536:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_536:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        if imp:is_critical_hit() then
            local value = self:get_refix_value(talent, level)
            imp:set_continuance(value * 1000)
        end
    end
end

return std_talent_536