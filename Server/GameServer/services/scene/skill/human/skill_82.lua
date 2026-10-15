local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local impactenginer = require "impactenginer":getinstance()
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_82 = class("skill_82", base)
skill_82.IMPACT_NUMBER = 3

function skill_82:get_give_self_activate_once_impact_by_index(skill_info, index)
    local descriptor = skill_info:get_descriptor()
    local key = string.format("给自己生效一次的附加效果%d", index)
    return descriptor[key] or define.INVAILD_ID
end

function skill_82:get_give_target_activate_once_impact_by_index(skill_info, index)
    local descriptor = skill_info:get_descriptor()
    local key = string.format("给目标生效一次的附加效果%d", index)
    return descriptor[key] or define.INVAILD_ID
end

function skill_82:effect_on_unit_once(obj_me, obj_tar, is_critical)
    -- print("skill_82:effect_on_unit_once")
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    for i = 1, self.IMPACT_NUMBER do
        local value = self:get_give_self_activate_once_impact_by_index(skill_info, i)
        if value ~= define.INVAILD_ID then
            -- print("skill_82:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value, ";tar =", obj_tar:get_obj_id())
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
    for i = 1, self.IMPACT_NUMBER do
        local value = self:get_give_target_activate_once_impact_by_index(skill_info, i)
        if value ~= define.INVAILD_ID then
            -- print("skill_82:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value, ";tar =", obj_tar:get_obj_id())
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

return skill_82