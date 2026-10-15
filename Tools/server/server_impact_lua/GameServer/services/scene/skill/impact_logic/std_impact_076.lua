-- server-impact: logic 76 (tlbb15 STD_IMPACT_076 伤害附加 / 破绽：受火烧赤壁伤害增加…)
-- Người mang impact bị đánh bởi impact thuộc 目标效果集合ID → cộng 附加伤害数值 vào hệ 附加伤害的类型(0~5: 外、内、冰、火、玄、毒).
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
local std_impact_076 = class("std_impact_076", base)

function std_impact_076:is_over_timed()
    return true
end

function std_impact_076:is_intervaled()
    return false
end

function std_impact_076:on_damages(imp, obj, damages, caster_obj_id, is_critical, skill_id, src_imp)
    if not damages or not damages.damage_rate or not src_imp then
        return
    end
    local collection = util.num(imp, "目标效果集合ID", -1)
    local value = util.num(imp, "附加伤害数值")
    local kind = util.num(imp, "附加伤害的类型(0~5:外、内、冰、火、玄、毒)", 0)
    if collection < 0 or value == 0 or kind < 0 or kind > 5 then
        return
    end
    local impactenginer = obj:get_scene():get_impact_enginer()
    if not impactenginer or not impactenginer:is_impact_in_collection(src_imp, collection) then
        return
    end
    local key = DAMAGE_TYPE_POINT[kind + 1]
    damages[key] = (damages[key] or 0) + value
end

return std_impact_076
