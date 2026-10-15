local skynet = require "skynet"
local class = require "class"
local base = require "scene.skill.impact_logic.base"

-- 弑神闪：瞬移到目的地后，对周围3米范围内最多3个敌对目标造成60%普攻伤害
-- 伤害由 SpecialObj 2023 (trap) → effect_on_char → Impact 8425 投递
-- std_impact_536 仅负责创建 SpecialObj 2023 并设置伤害倍率
local std_impact_536 = class("std_impact_536", base)

-- SpecialObj 2023：弑神闪追击爆炸（3米范围，最多3目标）
local SHISHENSHAN_TRAP_DATA_ID = 2023

-- 非持续性效果（即时触发）
function std_impact_536:is_over_timed()
    return false
end

-- 获取普通攻击伤害百分比（参数3：伤害百分比，值为60，即60%）
function std_impact_536:get_damage_rate(imp)
    return imp.params["伤害百分比"] or 60
end

-- 即时触发：创建 SpecialObj 2023，由 trap.lua 扫描并投递 Impact 8425 伤害
function std_impact_536:on_impact(imp, obj)
    if not obj or not obj:is_alive() then
        return
    end

    local position = obj:get_world_pos()
    local skill_id = imp:get_skill_id()
    local damage_rate = self:get_damage_rate(imp) -- 60%

    -- 创建 SpecialObj 2023（effect1=8425，由 trap.lua effect_on_char 投递伤害）
    local trap_obj = obj:skill_create_obj_specail(position, SHISHENSHAN_TRAP_DATA_ID, skill_id)
    if not trap_obj then
        return
    end

    -- 设置伤害倍率：trap.lua 的 effect_on_char 会将此值作为 refix_by_rate
    -- 传递给 send_impact_to_unit，最终 Impact 8425 按 60% 普攻计算伤害
    trap_obj:set_power_refix_by_rate(damage_rate)
end

return std_impact_536
