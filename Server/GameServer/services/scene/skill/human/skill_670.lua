local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_670 = class("skill_670", base)
skill_670.IMPACT_NUMBER = 17


function skill_670:ctor()

end

function skill_670:get_activate_once_impact_by_index(skill_info, index)
    return skill_info:get_activate_once_impact_by_index(index) or define.INVAILD_ID
end

function skill_670:get_activate_each_tick_impact_by_index(skill_info, index)
    return skill_info:get_activate_each_tick_impact_by_index(index) or define.INVAILD_ID
end

function skill_670:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    for i = 1, self.IMPACT_NUMBER do
        value = self:get_activate_once_impact_by_index(skill_info, i)
        if value ~= define.INVAILD_ID then
            -- print("skill_670:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value, ";tar =", obj_tar:get_obj_id())
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            -- if imp:get_logic_id() == DI_DamagesByValue_T.ID then
                -- local co = combat_core.new()
                -- co:get_result_impact(obj_me, obj_tar, imp)
            -- end
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
end

function skill_670:effect_on_unit_each_tick(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    for i = 1, self.IMPACT_NUMBER do
        value = self:get_activate_each_tick_impact_by_index(skill_info, i)
        if value ~= define.INVAILD_ID then
            -- print("skill_670:effect_on_unit_each_tick impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value, ";tar =", obj_tar:get_obj_id())
            -- local co = combat_core.new()
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            -- co:get_result_impact(obj_me, obj_tar, imp)
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
end

return skill_670