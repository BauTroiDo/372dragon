local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_321 = class("std_impact_321", base)

function std_impact_321:is_over_timed()
    return true
end

function std_impact_321:is_intervaled()
    return false
end

function std_impact_321:get_skill_accuracy_rate_up(imp)
    return imp.params["命中率+"] or 0
end

function std_impact_321:refix_skill(imp, obj_me, skill_info)
    local up = self:get_skill_accuracy_rate_up(imp)
    local skill_up_rate = skill_info:get_accuracy_rate_up()
    skill_info:set_accuracy_rate_up(skill_up_rate + up)
end

return std_impact_321