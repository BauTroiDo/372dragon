local class = require "class"
local define = require "define"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_307 = class("std_impact_307", base)
function std_impact_307:is_over_timed()
    return true
end

function std_impact_307:is_intervaled()
    return true
end

function std_impact_307:get_active_impact(imp)
    return imp.params["开始时效果"]
end

function std_impact_307:get_end_impact(imp)
    return imp.params["结束时效果"]
end

function std_impact_307:get_interval_over_impact(imp)
    return imp.params["持续性效果"]
end

function std_impact_307:get_range_limit(imp)
    return imp.params["效果范围"]
end

function std_impact_307:on_interval_over(imp, obj)
    if not obj:is_alive() then
        return
    end
    local caster_obj_id = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
    if sender then
        local my_pos = obj:get_world_pos()
        local sender_pos = sender:get_world_pos()
        local range = self:cal_dist(my_pos, sender_pos)
        local limit = self:get_range_limit(imp) / 1000
        if range < limit then
            local value = self:get_interval_over_impact(imp)
            impactenginer:send_impact_to_unit(obj, value, sender, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
        else
            obj:on_impact_fade_out(imp)
            obj:remove_impact(imp)
        end
    end
end

function std_impact_307:on_active(imp, obj)
    if not obj:is_alive() then
        return
    end
    local value = self:get_active_impact(imp)
    impactenginer:send_impact_to_unit(obj, value, obj, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
end

function std_impact_307:cal_dist(p1, p2)
    return math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y))
end

function std_impact_307:on_fade_out(imp, obj)
    if not obj:is_alive() then
        return
    end
    local caster_obj_id = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
    if sender then
        local my_pos = obj:get_world_pos()
        local sender_pos = sender:get_world_pos()
        local range = self:cal_dist(my_pos, sender_pos)
        local limit = self:get_range_limit(imp) / 1000
        if range < limit then
            local value = self:get_end_impact(imp)
            impactenginer:send_impact_to_unit(obj, value, obj, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
        end
    end
end

return std_impact_307