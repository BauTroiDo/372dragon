local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_2 = class("skill_2", base)

function skill_2:get_instant_transport_impact(skill_info)
    return skill_info:get_instant_transport_impact()
end

function skill_2:get_impact(skill_info, index)
    local descriptor = skill_info:get_descriptor()
    local key = string.format("效果%d", index)
    return descriptor[key] or define.INVAILD_ID
end

function skill_2:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    do
        value = self:get_instant_transport_impact(skill_info)
        if value ~= define.INVAILD_ID then
            -- print("skill_2:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            local logic = impactenginer:get_logic(imp)
            if logic then
                local target_position = params:get_target_position()
                logic:set_impact_x(imp, target_position.x)
                logic:set_impact_y(imp, target_position.y)
            end
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
    for i = 1, 3 do
        value = self:get_impact(skill_info, i)
        if value ~= define.INVAILD_ID then
            -- print("skill_2:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
end

return skill_2