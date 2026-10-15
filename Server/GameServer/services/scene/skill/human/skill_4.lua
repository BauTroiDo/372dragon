local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local skill_4 = class("skill_4", base)

function skill_4:get_attack_impact(skill_info)
    return skill_info:get_attack_impact() or define.INVAILD_ID
end

function skill_4:get_give_target_impact(skill_info)
    return skill_info:get_give_target_impact()
end

function skill_4:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    local trigger_index = 1
    do
        value = self:get_attack_impact(skill_info)
        if value ~= define.INVAILD_ID then
            -- print("skill_4:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            if DI_DamagesByValue_T.ID == imp:get_logic_id() then
                -- local co = combat_core.new()
                -- co:get_result_impact(obj_me, obj_tar, imp)
                local logic = impactenginer:get_logic(imp)
                logic:set_trigger_index(imp, trigger_index)
                trigger_index = trigger_index + 1
            end
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
    do
        local impact_tar = self:get_give_target_impact(skill_info)
        value = impact_tar.id or define.INVAILD_ID
        if value ~= define.INVAILD_ID then
            local num = math.random(100)
            -- print("skill_4:effect_on_unit_once num =", num)
            assert(impact_tar.p)
            if num <= impact_tar.p then
                -- print("skill_4:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
                assert(impact_tar.c)
                for i = 1, impact_tar.c do
                    local imp = impact.new()
                    imp:clean_up()
                    impactenginer:init_impact_from_data(value, imp)
                    if DI_DamagesByValue_T.ID == imp:get_logic_id() then
                        -- local co = combat_core.new()
                        -- co:get_result_impact(obj_me, obj_tar, imp)
                        local logic = impactenginer:get_logic(imp)
                        logic:set_trigger_index(imp, trigger_index)
                        trigger_index = trigger_index + 1
                    end
                    self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
                end
            end
        end
    end
end

return skill_4