local class = require "class"
local define = require "define"
local skynet = require "skynet"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_690 = class("skill_690", base)
function skill_690:ctor()

end

function skill_690:get_give_self_impact(skill_info, obj_me)
    local talent = obj_me:get_talent_by_skill_id(skill_info:get_skill_id())
    if talent == nil then
        return define.INVAILD_ID
    end
    local level = talent.level
    local key = string.format("生效一次的效果%d(自己)", level)
    local descriptor = skill_info:get_descriptor()
    local value = descriptor[key]
    if value == nil then
        if type(descriptor["生效一次的效果1(自己)"]) == "table" then
            value = descriptor["生效一次的效果1(自己)"][level]
        end
    end
    return value or define.INVAILD_ID
end

function skill_690:get_give_target_impact(skill_info, obj_me)
    local talent = obj_me:get_talent_by_skill_id(skill_info:get_skill_id())
    if talent == nil then
        return define.INVAILD_ID
    end
    local level = talent.level
    local key = string.format("生效一次的效果%d(目标)", level)
    local descriptor = skill_info:get_descriptor()
    local value = descriptor[key]
    if value == nil then
        if type(descriptor["生效一次的效果1(目标)"]) == "table" then
            value = descriptor["生效一次的效果1(目标)"][level]
        end
    end
    return value or define.INVAILD_ID
end

function skill_690:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()

    -- [FIX] 暗器护体(技能3596)：从暗器洗练数据获取动态Impact
    local cur_skill_id = skill_info:get_skill_id()
    if cur_skill_id == 3596 then
        local container = obj_me:get_equip_container()
        local anqi = container and container:get_item(define.HUMAN_EQUIP.HEQUIP_ANQI)
        if not anqi then
            return
        end
        local aq_data = anqi:get_equip_data()
        if not aq_data then
            return
        end

        local impact_id = aq_data:get_aq_skill(3)  -- 索引3=暗器护体

        if not impact_id or impact_id <= 0 then
            obj_me:notify_tips("未领悟暗器护体技能！")
            return
        end

        local imp = impact.new()
        imp:clean_up()
        local ok = impactenginer:init_impact_from_data(impact_id, imp)

        if not ok then
            return
        end

        self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
        return  -- 暗器护体处理完毕，不走默认逻辑
    end

    -- 以下保持原有逻辑不变（非暗器护体技能）
    do
        local value = self:get_give_self_impact(skill_info, obj_me)
        if value ~= define.INVAILD_ID then
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            -- if imp:get_logic_id() == DI_DamagesByValue_T.ID then
                -- local co = combat_core.new()
                -- co:get_result_impact(obj_me, obj_tar, imp)
            -- end
            self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
    do
        local value = self:get_give_target_impact(skill_info, obj_me)
        if value ~= define.INVAILD_ID then
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

return skill_690