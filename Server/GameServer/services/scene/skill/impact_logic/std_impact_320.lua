local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_320 = class("std_impact_320", base)

function std_impact_320:is_over_timed()
    return true
end

function std_impact_320:is_intervaled()
    return false
end

function std_impact_320:get_skill_accuracy_rate_up(imp)
    return imp.params["命中率+"] or 0
end

function std_impact_320:set_skill_accuracy_rate_up(imp, up)
    imp.params["命中率+"] = up
end

function std_impact_320:get_value_of_refix_hit_rate(imp)
    return imp.params["对己方命中率+"] or 0
end

function std_impact_320:set_value_of_refix_hit_rate(imp, up)
    imp.params["对己方命中率+"] = up
end

function std_impact_320:target_refix_accuracy_rate(imp, obj_me, obj_tar)
    local caster_obj_id = imp:get_caster_obj_id()
    if caster_obj_id == obj_tar:get_obj_id() then
        local up = self:get_skill_accuracy_rate_up(imp)
        return up
    end
    return 0
end

function std_impact_320:refix_skill_info(imp, obj, skill_info)
    local rate_up = skill_info:get_accuracy_rate_up()
    local value = self:get_value_of_refix_hit_rate(imp)
    rate_up = rate_up + value
    skill_info:set_accuracy_rate_up(rate_up)
end

return std_impact_320