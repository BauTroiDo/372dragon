local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_681 = class("std_talent_681", base)

function std_talent_681:is_specific_impact(impact_id)
    return impact_id == 6537 or impact_id == 6528 or impact_id == 6538
end

function std_talent_681:get_refix_impact_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_681:refix_impact(talent, level, imp)
    local impact_id = imp:get_impact_id()
    if self:is_specific_impact(impact_id) then
        local value = self:get_refix_impact_value(talent, level)
        local contianuce = imp:get_continuance()
        imp:set_continuance(contianuce + value * 1000)
    end
end

return std_talent_681