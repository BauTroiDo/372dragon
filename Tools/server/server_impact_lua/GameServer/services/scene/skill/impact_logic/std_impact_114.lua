-- server-impact: logic 114 (tlbb15 StdImpact114 龙战于野（加闪避）…) và 145/162 (修正率 bốn chỉ số) và 122 (闪避修正 điểm).
-- 114: 命中率调整百分比 / 闪避率调整百分比 / 会心一击率调整百分比 — cộng thẳng vào tỉ lệ (%) khi đánh.
-- 145: 命中修正率 / 闪避修正率 / 会心攻击修正率 / 会心防御修正率 — % thuộc tính.
-- 162: như 145 (会心修正率 / 会防修正率) + 闪避修正百分率 (tỉ lệ né %) ; 给目标的效果 khi trúng đích.
-- 122: 闪避修正 (điểm né).
local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local std_impact_114 = class("std_impact_114", base)

function std_impact_114:is_over_timed()
    return true
end

function std_impact_114:is_intervaled()
    return false
end

-- tỉ lệ trúng (%) cho kỹ năng của người mang impact
function std_impact_114:refix_skill(imp, obj, skill_info)
    local rate = util.num(imp, "命中率调整百分比")
    if rate ~= 0 and skill_info and skill_info.get_accuracy_rate_up then
        skill_info:set_accuracy_rate_up((skill_info:get_accuracy_rate_up() or 0) + rate)
    end
end

function std_impact_114:refix_miss_rate(imp)
    return util.num(imp, "闪避率调整百分比") + util.num(imp, "闪避修正百分率")
end

function std_impact_114:refix_critical_rate(imp, critical_rate)
    -- combat_core uses a 0..1 ratio, as do living impact013/081.
    return (critical_rate or 0) + util.num(imp, "会心一击率调整百分比") / 100
end

function std_impact_114:get_refix_attrib_hit(imp, args)
    util.add_rate(args, util.num(imp, "命中修正率"))
end

function std_impact_114:get_refix_attrib_miss(imp, args)
    util.add_rate(args, util.num(imp, "闪避修正率"))
    util.add_point(args, util.num(imp, "闪避修正"))
end

function std_impact_114:get_refix_mind_attack(imp, args)
    util.add_rate(args, util.num(imp, "会心攻击修正率") + util.num(imp, "会心修正率"))
end

function std_impact_114:get_refix_mind_defend(imp, args)
    util.add_rate(args, util.num(imp, "会心防御修正率") + util.num(imp, "会防修正率"))
end

-- 162: 给目标的效果 (DataIndex) khi người mang impact đánh trúng
function std_impact_114:on_hit_target(imp, obj, reciver)
    local data_index = util.num(imp, "给目标的效果", define.INVAILD_ID)
    if data_index <= 0 or not reciver or not obj or not obj.get_scene then
        return
    end
    local impactenginer = obj:get_scene():get_impact_enginer()
    if impactenginer then
        impactenginer:send_impact_to_unit(reciver, data_index, obj, 0, false, 0, imp:get_skill_id())
    end
end

return std_impact_114
