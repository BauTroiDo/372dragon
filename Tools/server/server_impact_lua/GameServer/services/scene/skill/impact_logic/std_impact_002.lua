-- server-impact: logic 2 (tlbb15 "STD_IMPACT_001/StdImpact002": 秒人, 开膛(伤半血NPC), 玉石俱焚自爆)
-- Nhãn: 伤害百分率 = % sinh lực TỐI ĐA của mục tiêu bị trừ ngay (sát thương trực tiếp, không qua kháng).
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE = DI_DamagesByValue_T.enum_DAMAGE_TYPE
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK
local std_impact_002 = class("std_impact_002", base)

function std_impact_002:is_over_timed()
    return false
end

function std_impact_002:is_intervaled()
    return false
end

-- sát thương = tỉ lệ % * máu tối đa (tối thiểu 1 khi tỉ lệ > 0)
function std_impact_002:calc_damage(imp, obj)
    local rate = util.num(imp, "伤害百分率", 0)
    if rate <= 0 then
        return 0
    end
    local max_hp = obj:get_max_hp() or 0
    return math.max(1, math.floor(max_hp * rate / 100))
end

function std_impact_002.build_direct_damages(damage)
    local damages = {hp_damage = damage, direcht_rate = true}
    for _, key in ipairs(DAMAGE_TYPE_RATE) do damages[key] = 100 end
    for _, key in ipairs(DAMAGE_TYPE_POINT) do damages[key] = 0 end
    for _, key in ipairs(DAMAGE_TYPE_BACK) do damages[key] = {} end
    for _, key in pairs(DAMAGE_TYPE) do damages[key] = 0 end
    damages[DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = damage
    return damages
end

function std_impact_002:on_active(imp, obj)
    if not imp or not obj or not obj:is_alive() then
        return
    end
    local caster_id = imp:get_caster_obj_id()
    local damage = self:calc_damage(imp, obj)
    if damage <= 0 then
        return
    end
    obj:on_damages(std_impact_002.build_direct_damages(damage), caster_id, imp:is_critical_hit(), imp:get_skill_id(), imp)
end

return std_impact_002
