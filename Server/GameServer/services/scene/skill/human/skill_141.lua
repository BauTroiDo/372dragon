local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local impactenginer = require "impactenginer":getinstance()
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_141 = class("skill_141", base)

function skill_141:get_attack_impact(skill_info, index)
    local descriptor =  skill_info:get_descriptor()
    local key = string.format("|敌对效果%d", index)
    return descriptor[key] or define.INVAILD_ID
end

function skill_141:get_health_impact(skill_info, index)
    local descriptor =  skill_info:get_descriptor()
    local key = string.format("|友好效果%d", index)
    return descriptor[key] or define.INVAILD_ID
end

function skill_141:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    for i = 1, 2 do
        local value
        if obj_me:is_enemy(obj_tar) then
            value = self:get_attack_impact(skill_info, i)
        else
            value = self:get_health_impact(skill_info, i)
        end
        if value ~= define.INVAILD_ID then
            -- print("skill_141:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
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

return skill_141