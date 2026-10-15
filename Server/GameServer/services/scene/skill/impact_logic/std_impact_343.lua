local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_343 = class("std_impact_343", base)

function std_impact_343:is_over_timed()
    return true
end

function std_impact_343:is_intervaled()
    return false
end

function std_impact_343:get_value_of_refix_miss_rate(imp)
    return imp.params["闪避率+"] or 0
end

function std_impact_343:get_value_of_refix_hit_rate(imp)
    return imp.params["命中率+"] or 0
end

function std_impact_343:refix_miss_rate(imp, obj_me)
    return self:get_value_of_refix_miss_rate(imp)
end

function std_impact_343:refix_skill_info(imp, obj, skill_info)
    local rate_up = skill_info:get_accuracy_rate_up()
    local value = self:get_value_of_refix_hit_rate(imp)
    rate_up = rate_up + value
    skill_info:set_accuracy_rate_up(rate_up)
end

return std_impact_343