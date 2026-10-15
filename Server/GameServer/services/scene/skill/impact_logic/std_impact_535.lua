local class = require "class"
local combat_core = require "scene.skill.combat_core"
local impact = require "scene.skill.impact"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"

-- 抱剑同酣：星河虹吸额外召唤的飞剑环绕效果
-- 每2秒对目标周围5米范围内最多3个敌对目标造成30%普通攻击伤害，并有概率使其麻痹1秒
-- 状态持续6秒，触发周期由 StandardImpact.txt 中的 interval 字段控制
local std_impact_535 = class("std_impact_535", base)

-- 持续性效果（有持续时间）
function std_impact_535:is_over_timed()
    return true
end

-- 周期性触发（每2秒触发一次）
function std_impact_535:is_intervaled()
    return true
end

-- 获取范围扫描半径（参数1：扫描半径，值为5米）
function std_impact_535:get_affect_radious(imp)
    return imp.params["扫描半径"]
end

-- 获取最大影响目标数（参数2：影响目标人数，值为3）
function std_impact_535:get_affect_target_count(imp)
    return imp.params["影响目标人数"]
end

-- 获取普通攻击伤害百分比（参数3：伤害百分比，值为30，即30%）
function std_impact_535:get_damage_rate(imp)
    return imp.params["伤害百分比"] or 30
end

-- 获取麻痹触发概率（参数4：触发概率，按技能等级不同为20/40/60/80/100）
function std_impact_535:get_paralyze_rate(imp)
    return imp.params["触发概率"] or 0
end

-- 获取麻痹子效果ID（参数5：子效果ID，值为19106）
function std_impact_535:get_paralyze_impact_id(imp)
    return imp.params["子效果ID"] or -1
end

-- 每周期（每2秒）触发：对obj周围范围内的敌对目标造成伤害并概率麻痹
function std_impact_535:on_interval_over(imp, obj)
    if not obj or not obj:is_alive() then
        return
    end

    -- 获取施法者（飞剑的释放者）
    local caster_obj_id = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
    if not sender then
        return
    end

    -- 读取配置参数
    local radious       = self:get_affect_radious(imp)          -- 扫描半径（5米）
    local affect_count  = self:get_affect_target_count(imp)     -- 最大目标数（3个）
    local damage_rate   = self:get_damage_rate(imp)             -- 伤害百分比（30%）
    local paralyze_rate = self:get_paralyze_rate(imp)           -- 麻痹触发概率
    local paralyze_id   = self:get_paralyze_impact_id(imp)      -- 麻痹Impact ID（19106）

    -- 以 obj 位置为圆心进行范围扫描
    local position = obj:get_world_pos()
    local operate = {
        obj    = obj,
        x      = position.x,
        y      = position.y,
        radious = radious,
        count  = affect_count,
    }
    local nearbys = obj:get_scene():scan(operate)

    local scene = obj:get_scene()
    local eventenginer = scene:get_event_enginer()
    local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

    for _, nb in ipairs(nearbys) do
        if nb:is_character_obj() and sender:is_enemy(nb) and nb:is_alive() then

            -- 1. 发送30%普通攻击伤害子效果（从子效果1读取伤害Impact ID）
            local dmg_sub_id = imp.params["子效果1"] or -1
            if dmg_sub_id ~= -1 then
                local dmg_imp = impact.new()
                dmg_imp:clean_up()
                impactenginer:init_impact_from_data(dmg_sub_id, dmg_imp)
                -- 同步暴击状态
                if imp:is_critical_hit() then
                    dmg_imp:mark_critical_hit_flag()
                end
                dmg_imp:set_skill_id(imp:get_skill_id())
                dmg_imp:set_skill_level(imp:get_skill_level())
                -- 叠加伤害倍率（damage_rate 为30，即按30%计算）
                for _, key in ipairs(DAMAGE_TYPE_RATE) do
                    dmg_imp:add_rate_params(key, damage_rate)
                end
                -- 如果是伤害类Impact，通过 combat_core 计算结果
                if dmg_imp:get_logic_id() == DI_DamagesByValue_T.ID then
                    local co = combat_core.new()
                    co:get_result_impact(sender, nb, dmg_imp)
                end
                eventenginer:register_impact_event(nb, sender, dmg_imp, 0, imp:get_skill_id())
            end

            -- 2. 按概率触发麻痹效果（paralyze_id = 19106）
            if paralyze_id ~= -1 and paralyze_rate > 0 then
                if math.random(100) <= paralyze_rate then
                    local para_imp = impact.new()
                    para_imp:clean_up()
                    impactenginer:init_impact_from_data(paralyze_id, para_imp)
                    para_imp:set_skill_id(imp:get_skill_id())
                    para_imp:set_skill_level(imp:get_skill_level())
                    eventenginer:register_impact_event(nb, sender, para_imp, 0, imp:get_skill_id())
                end
            end
        end
    end
end

return std_impact_535
