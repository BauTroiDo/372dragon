local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local impactenginer = require "impactenginer":getinstance()
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_80 = class("skill_80", base)
skill_80.IMPACT_NUMBER = 2


function skill_80:ctor()

end

function skill_80:get_segment_effect(skill_info, index)
    print("skill_80:get_segment_effect index =", index)
    local descriptor = skill_info:get_descriptor()
    local key = "一段连击对应效果"
    if index == 2 then
        key = "二段连击对应效果"
    elseif index == 3 then
        key = "三段连击对应效果"
    end
    return descriptor[key] or define.INVAILD_ID
end

function skill_80:get_activate_once_impact_by_index(skill_info, index)
    return skill_info:get_activate_once_impact_by_index(index) or define.INVAILD_ID
end

function skill_80:get_activate_each_tick_impact_by_index(skill_info, index)
    return skill_info:get_activate_each_tick_impact_by_index(index) or define.INVAILD_ID
end

function skill_80:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local segment = math.ceil(params:get_depleted_strike_point() / define.STRIKE_POINT_SEGMENT_SIZE)
    local value = self:get_segment_effect(skill_info, segment)
    if value ~= define.INVAILD_ID then
        -- print("skill_80:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value, ";tar =", obj_tar:get_obj_id())
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(value, imp)
        imp:set_skill_segment(segment)
        -- if imp:get_logic_id() == DI_DamagesByValue_T.ID then
            -- local co = combat_core.new()
            -- co:get_result_impact(obj_me, obj_tar, imp)
        -- end
        self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
    end

    for i = 1, self.IMPACT_NUMBER do
        value = self:get_activate_once_impact_by_index(skill_info, i)
        if value ~= define.INVAILD_ID then
            -- print("skill_80:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value, ";tar =", obj_tar:get_obj_id())
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            imp:set_skill_segment(segment)
            -- if imp:get_logic_id() == DI_DamagesByValue_T.ID then
                -- local co = combat_core.new()
                -- co:get_result_impact(obj_me, obj_tar, imp)
            -- end
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
    pcall(require("cy_skill_extra").apply, self, obj_me, obj_tar, is_critical)  -- skill-logic
end

return skill_80