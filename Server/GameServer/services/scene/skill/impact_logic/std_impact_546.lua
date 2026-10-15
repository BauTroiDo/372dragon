-- 怒意灼心：珍兽自损增强效果
-- 施加在珍兽自身身上，激活时消耗寿命，设置伤害减免与禁疗标记
-- 每秒按最大血量10%扣血，血量归零时触发死亡
-- 消失时清除伤害减免与禁疗标记，恢复正常状态
local class         = require "class"
local skynet        = require "skynet"
local base          = require "scene.skill.impact_logic.base"

local std_impact_546 = class("std_impact_546", base)

-- 激活时消耗的寿命点数
local LIFE_COST       = 5000
-- 每 interval 扣除的最大血量百分比
local HP_DRAIN_RATE   = 10
-- 伤害减免百分比（存到 imp.params 供 on_damages 读取）
local DAMAGE_REDUCE   = 50
-- 参数键名（与引擎约定的命名保持一致）
local KEY_DMG_REDUCE  = "reduce_damage"
local KEY_FORBID_HEAL = "禁止治疗"

--------------------------------------------------------------
-- 持续型 + 周期型 buff
--------------------------------------------------------------
function std_impact_546:is_over_timed()
    return true
end

function std_impact_546:is_intervaled()
    return true
end

--------------------------------------------------------------
-- 激活：消耗寿命 / 设置减免 / 设置禁疗
--------------------------------------------------------------
function std_impact_546:on_active(imp, obj)
    if not obj then return end

    -- 只作用于珍兽
    if obj:get_obj_type() ~= "pet" then return end

    -- 消耗5000寿命（通过owner标准路径获取detail，避免场景pet的get_detail()返回nil）
    local detail = obj:get_detail()
    if not detail then
        local owner = obj:get_owner()
        if owner then
            local pet_guid = owner:get_current_pet_guid()
            if pet_guid and not pet_guid:is_null() then
                local container = owner:get_pet_bag_container()
                if container then
                    detail = container:get_pet_by_guid(pet_guid)
                end
            end
        end
    end
    if detail then
        local cur_life = detail:get_life()
        if cur_life then
            local new_life = cur_life - LIFE_COST
            if new_life < 0 then new_life = 0 end
            detail:set_life(new_life)
            -- 通知客户端属性刷新
            if obj.send_refresh_attrib then
                obj:send_refresh_attrib()
            end
        end
    end

    -- 设置伤害减免标记（供 on_damages 使用）
    imp.params[KEY_DMG_REDUCE]  = DAMAGE_REDUCE
    -- 设置禁止治疗标记（供 on_be_heal 使用）
    imp.params[KEY_FORBID_HEAL] = 1

    skynet.error(string.format("[IMPACT_546] on_active: pet=%s life_cost=%d",
        tostring(obj:get_name()), LIFE_COST))
end

--------------------------------------------------------------
-- 每秒扣除最大血量 10%
--------------------------------------------------------------
function std_impact_546:on_interval_over(imp, obj)
    if not obj or not obj:is_alive() then return end
    if obj:get_obj_type() ~= "pet" then return end

    local max_hp = obj:get_max_hp()
    if not max_hp or max_hp <= 0 then return end

    local drain = math.ceil(max_hp * HP_DRAIN_RATE / 100)
    local cur_hp = obj:get_hp()
    local new_hp = cur_hp - drain

    skynet.error(string.format("[IMPACT_546] on_interval_over: pet=%s cur_hp=%d drain=%d new_hp=%d",
        tostring(obj:get_name()), cur_hp, drain, new_hp))

    if new_hp <= 1 then
        -- 血量扣至最低保留1点，不触发死亡
        obj:set_hp(1)
    else
        obj:set_hp(new_hp)
    end
end

--------------------------------------------------------------
-- 伤害减免：50% 伤害减免
--------------------------------------------------------------
function std_impact_546:on_damages(imp, reciver, damages, caster_obj_id, is_critical, skill_id)
    if not damages then return end
    local reduce = imp.params[KEY_DMG_REDUCE] or 0
    if reduce <= 0 then return end
    -- 将所有数值类伤害乘以 (100 - reduce) / 100
    local factor = (100 - reduce) / 100
    if damages.hp_damage then
        damages.hp_damage = math.floor(damages.hp_damage * factor)
    end
    if damages.mp_damage then
        damages.mp_damage = math.floor(damages.mp_damage * factor)
    end
end

--------------------------------------------------------------
-- 禁止治疗：将本次治疗量清零
--------------------------------------------------------------
function std_impact_546:on_be_heal(imp, obj_me, sender, health, skill_id)
    if imp.params[KEY_FORBID_HEAL] == 1 then
        health.hp_modify = 0
    end
end

--------------------------------------------------------------
-- 消失：清除减免与禁疗标记
--------------------------------------------------------------
function std_impact_546:on_fade_out(imp, obj)
    imp.params[KEY_DMG_REDUCE]  = 0
    imp.params[KEY_FORBID_HEAL] = 0

    if obj and obj:get_obj_type() == "pet" then
        skynet.error(string.format("[IMPACT_546] on_fade_out: pet=%s 状态解除，已清除减免与禁疗",
            tostring(obj:get_name())))
        -- 刷新客户端属性显示
        if obj.send_refresh_attrib then
            obj:send_refresh_attrib()
        end
    end
end

return std_impact_546
