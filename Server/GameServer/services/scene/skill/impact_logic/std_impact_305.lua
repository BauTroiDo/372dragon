local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local skillenginer = require "skillenginer":getinstance()
local std_impact_305 = class("std_impact_305", base)

function std_impact_305:is_over_timed()
    return true
end

function std_impact_305:is_intervaled()
    return false
end

function std_impact_305:get_deplete_refix_by_value(imp)
    return imp.params["减少消耗"]
end

function std_impact_305:get_affect_skill_collection_id(imp)
    return imp.params["影响的技能集合ID"]
end

function std_impact_305:refix_skill(imp, obj_me, skill_info)
    if imp:get_activate_times() == 0 then
        return
    end
    local collection_id = self:get_affect_skill_collection_id(imp)
    local in_collection = true
    if collection_id ~= define.INVAILD_ID then
        in_collection = skillenginer:is_skill_in_collection(skill_info:get_skill_id(), collection_id)
    end
    if not in_collection then
        return
    end
    local value = self:get_deplete_refix_by_value(imp)
    if value > 0 then
        skill_info:set_deplete_refix_by_value(value)
    end
    local activate_times = imp:get_activate_times()
    if activate_times > 0 then
        activate_times = activate_times - 1
        if activate_times == 0 then
            obj_me:on_impact_fade_out(imp)
            obj_me:remove_impact(imp)
        end
        imp:set_activate_times(activate_times)
    end
end

return std_impact_305