local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_290 = class("skill_290", base)

function skill_290:get_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts[1] or define.INVAILD_ID
end

function skill_290:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    value = self:get_impact(skill_info)
    if value ~= define.INVAILD_ID then
        print("skill_290:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(value, imp)
        self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
    end
end

return skill_290