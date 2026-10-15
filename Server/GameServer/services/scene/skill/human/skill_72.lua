-- 破天式 (效果由SkillData的附加效果配置驱动)
local class = require "class"
local define = require "define"
local skynet = require "skynet"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_72 = class("skill_72", base)

local DEBUG_POTIANSHI = skynet.getenv("debug_potianshi") == "1"
local function dlog(...) if DEBUG_POTIANSHI then skynet.logi(...) end end

skill_72.IMPACT_NUMBER = 17

function skill_72:get_attack_impact(skill_info)
    return skill_info:get_attack_impact() or define.INVAILD_ID
end

function skill_72:get_activate_once_impact_by_index(skill_info, index)
    local value = skill_info:get_activate_once_impact_by_index(index)
    if value == nil and index == 1 then
        local imps = skill_info:get_activate_once_impacts()
        value = imps.self
    end
    return value or define.INVAILD_ID
end

function skill_72:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    local delay_time = params:get_delay_time()

    dlog("[PoTianShi] skill_72 effect_on_unit_once fired")

    local is_self = (obj_tar:get_obj_id() == obj_me:get_obj_id())

    -- 攻击效果（仅对非自身目标）
    if not is_self then
        local atk_value = self:get_attack_impact(skill_info)
        if atk_value ~= define.INVAILD_ID then
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(atk_value, imp)
            self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
            dlog("[PoTianShi] atk_impact=", atk_value)
        end
    end

    -- 读取飞剑伤害百分比(按心法等级: 14%~24%)
    local descriptor = skill_info:get_descriptor()
    local sword_damage_rate = descriptor["飞剑伤害百分比"] or 0

    -- 附加效果：logic_id=96(飞剑状态)施加给自身，其他效果施加给目标（排除自身）
    for i = 1, self.IMPACT_NUMBER do
        local value = self:get_activate_once_impact_by_index(skill_info, i)
        if value ~= define.INVAILD_ID then
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            local logic_id = imp:get_logic_id()
            if logic_id == 96 then
                -- 飞剑状态：传递伤害百分比给SpecialObj
                imp.params["飞剑伤害百分比"] = sword_damage_rate
                self:register_impact_event(obj_me, obj_me, imp, delay_time, is_critical)
                dlog("[PoTianShi] effect[", i, "]=", value, " → self (飞剑状态, rate=", sword_damage_rate, "%)")
            elseif not is_self then
                -- 其他效果仅施加给非自身目标
                self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
                dlog("[PoTianShi] effect[", i, "]=", value, " → target")
            else
                dlog("[PoTianShi] effect[", i, "]=", value, " → skipped (self)")
            end
        end
    end
end

return skill_72
