-- 剑影留痕：叠层伤害增幅debuff
-- 破天式(834)命中后贴在目标身上，受到自身破天式伤害时额外附带X%普攻伤害
-- 可叠加，最多4层，持续7秒，每次重新贴上刷新计时
local class = require "class"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"

local std_impact_544 = class("std_impact_544", base)
local MAX_STACKS = 4

function std_impact_544:is_over_timed()
    return true
end

function std_impact_544:is_intervaled()
    return false
end

-- 被替换时保存叠层
function std_impact_544:on_fade_out(imp, obj)
    if imp._stack_count then
        obj._saved_544_stack = imp._stack_count
    end
end

-- 首次激活初始化1层；替换时从保存值继承（不减不加，天赋已处理）
function std_impact_544:on_active(imp, obj)
    local saved = obj._saved_544_stack
    if saved then
        obj._saved_544_stack = nil
        imp._stack_count = saved
        return
    end
    imp._stack_count = 1
end

-- 受到伤害时：如果伤害来源是施法者，增加额外普攻伤害百分比
function std_impact_544:on_damages(imp, obj, damages, caster_obj_id)
    if not damages then return end
    if caster_obj_id ~= imp:get_caster_obj_id() then return end
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

return std_impact_544
