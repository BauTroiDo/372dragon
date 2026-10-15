-- 吞花卧酒：叠层伤害增幅BUFF
-- 最多叠加3层，每层增加X%借力返施最终伤害，持续5秒，借力返施触发后自消耗
local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"

local std_impact_542 = class("std_impact_542", base)
local BORROW_LOGIC_ID = 532
local MAX_STACKS = 3

function std_impact_542:is_over_timed()
    return true
end

function std_impact_542:is_intervaled()
    return false
end

-- 首次激活初始化1层；替换时从保存值继承并+1
function std_impact_542:on_active(imp, obj)
    local saved = obj._saved_542_stack
    obj._saved_542_stack = nil
    if saved then
        imp._stack_count = saved < MAX_STACKS and saved + 1 or saved
        return
    end
    imp._stack_count = 1
end

-- 伤害增幅：按叠层数增加伤害百分比
function std_impact_542:on_damage_target(imp, obj, target, damages)
    if not damages then return end
    local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
    if not DAMAGE_TYPE_RATE then return end
    local percent_per_stack = imp.params["每层增伤百分比"] or 0
    local stacks = imp._stack_count or 1
    local total = percent_per_stack * stacks
    if total <= 0 then return end
    for _, key in ipairs(DAMAGE_TYPE_RATE) do
        damages[key] = (damages[key] or 0) + total
    end
end

-- 借力返施技能释放时自消耗（与借力532同步检测时机）
function std_impact_542:refix_critical_rate(imp, critical_rate, skill_info, obj)
    if not skill_info then return critical_rate end
    -- 检查施法者是否仍有借力状态（532），以确保是借力返施触发
    local impact_list = obj:get_impact_list()
    local has_borrow = false
    for i = 1, #impact_list do
        if impact_list[i] ~= imp and impact_list[i]:get_logic_id() == BORROW_LOGIC_ID then
            has_borrow = true
            break
        end
    end
    if has_borrow then
        -- 借力状态存在，本次技能即将触发借力返施，消耗本BUFF
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
    end
    return critical_rate
end

return std_impact_542
