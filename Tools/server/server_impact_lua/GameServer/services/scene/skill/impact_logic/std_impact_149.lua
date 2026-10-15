-- server-impact: logic 149/157 (tlbb15 StdImpact149 破釜沉舟…) và 150 (猛袭难当: sửa % sát thương theo từng hệ) và 116 (煞月).
-- 149: 基础伤害增强 = +% sát thương gây ra (mọi hệ). Các nhãn 暴击伤害增强/门派检测/受到伤害/受到会心伤害: tlbb15 không mô tả
--      đơn vị (dòng mẫu 受到伤害=100) → CHƯA áp dụng [SL], ghi ở Docs/specs/server/server-impact_vi.md.
-- 150: 外功/内功/冰系/火系/玄系/毒系伤害修正率 = +% theo hệ.
-- 116: 血量左值百分比 + 伤害增幅% = +% sát thương khi máu mục tiêu (%) thấp hơn ngưỡng.
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local std_impact_149 = class("std_impact_149", base)

local TYPED = {"外功伤害修正率", "内功伤害修正率", "冰系伤害修正率", "火系伤害修正率", "玄系伤害修正率", "毒系伤害修正率"}

function std_impact_149:is_over_timed()
    return true
end

function std_impact_149:is_intervaled()
    return false
end

function std_impact_149:on_damage_target(imp, obj, target, damages)
    if not damages or not damages.damage_rate then
        return
    end
    util.add_damage_rate(damages, DAMAGE_TYPE_RATE, util.num(imp, "基础伤害增强"))
    for i, label in ipairs(TYPED) do
        local v = util.num(imp, label)
        if v ~= 0 then
            local key = DAMAGE_TYPE_RATE[i]
            damages[key] = (damages[key] or 100) + v
        end
    end
    local threshold = util.num(imp, "血量左值百分比")
    local up = util.num(imp, "伤害增幅%")
    if threshold > 0 and up ~= 0 and target then
        local max_hp = target:get_max_hp() or 0
        if max_hp > 0 and (target:get_hp() or 0) * 100 < threshold * max_hp then
            util.add_damage_rate(damages, DAMAGE_TYPE_RATE, up)
        end
    end
end

return std_impact_149
