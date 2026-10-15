local class = require "class"
local base = require "scene.skill.impact_logic.base"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

-- 寂海生澜：释放门派控制技能或破天式飞剑命中目标后
-- 使自身造成的伤害提高X%，持续10秒
local std_impact_538 = class("std_impact_538", base)

-- 持续性效果（有持续时间，10秒）
function std_impact_538:is_over_timed()
    return true
end

-- 获取伤害增加百分比（1.5/3/4.5/6/7.5，对应5级）
function std_impact_538:get_damage_percent(imp)
    return imp.params["伤害增加百分比"] or 0
end

-- on_damage_target：在施法者对目标造成伤害时，增加伤害百分比
-- obj = 持有该BUFF的角色（施法者），target = 被攻击目标
function std_impact_538:on_damage_target(imp, obj, target, damages)
    local percent = self:get_damage_percent(imp)
    if percent ~= 0 then
        if damages and damages.damage_rate then
            for _, key in ipairs(DAMAGE_TYPE_RATE) do
                damages[key] = (damages[key] or 0) + percent
            end
        end
    end
end

return std_impact_538
