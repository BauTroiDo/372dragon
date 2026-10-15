local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_3 = class("skill_3", base)
skill_3.IMPACT_NUMBER = 2

function skill_3:get_attack_impact(skill_info)
    return skill_info:get_attack_impact() or define.INVAILD_ID
end

function skill_3:get_give_self_impact(skill_info)
    return skill_info:get_give_self_impact()
end

function skill_3:get_give_target_impact(skill_info)
    return skill_info:get_give_target_impact()
end


function skill_3:get_activate_once_impact_by_index(skill_info, index)
    local value = skill_info:get_activate_once_impact_by_index(index)
    if value == nil and index == 1 then
        local imps = skill_info:get_activate_once_impacts()
        value = imps.self
    end
    return value or define.INVAILD_ID
end

function skill_3:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    do
        value = self:get_attack_impact(skill_info)
        if value ~= define.INVAILD_ID then
            -- print("skill_3:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            -- local co = combat_core.new()
            -- co:get_result_impact(obj_me, obj_tar, imp)
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
    do
        local impact_self = self:get_give_self_impact(skill_info)
        value = impact_self.id or define.INVAILD_ID
        if value ~= define.INVAILD_ID then
            local num = math.random(100)
            -- print("skill_3:effect_on_unit_once num =", num)
            if num <= impact_self.p then
                -- print("skill_3:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
                local imp = impact.new()
                imp:clean_up()
                impactenginer:init_impact_from_data(value, imp)
                self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
            end

        end
    end
    do
        local impact_tar = self:get_give_target_impact(skill_info)
        value = impact_tar.id or define.INVAILD_ID
        if value ~= define.INVAILD_ID then
            local num = math.random(100)
            -- print("skill_3:effect_on_unit_once num =", num)
            if num <= impact_tar.p then
                -- print("skill_3:effect_on_unit_once impact tar obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
                local imp = impact.new()
                imp:clean_up()
                impactenginer:init_impact_from_data(value, imp)
                self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
            else
				skill_info:get_target_impact_miss()
			end
        end
    end
    do
        for i = 1, self.IMPACT_NUMBER do
            value = self:get_activate_once_impact_by_index(skill_info, i)
            if value ~= define.INVAILD_ID then
                print("skill_3:effect_on_unit_once impact value =", value, "skill_id", skill_info:get_skill_id())
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
end

return skill_3