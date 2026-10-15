-- server-impact: logic 91 (tlbb15 StdImpact091 养精蓄锐…): sửa công ngoại/nội theo phần trăm.
-- Nhãn: 外功攻击修正率, 内功攻击修正率 (logic 109 cùng nghĩa với nhãn 物理/魔法攻击修正率 + MAX_HP修正率).
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local std_impact_091 = class("std_impact_091", base)

function std_impact_091:is_over_timed()
    return true
end

function std_impact_091:is_intervaled()
    return false
end

function std_impact_091:get_refix_attrib_att_physics(imp, args)
    util.add_rate(args, util.num(imp, "外功攻击修正率") + util.num(imp, "物理攻击修正率"))
end

function std_impact_091:get_refix_attrib_att_magic(imp, args)
    util.add_rate(args, util.num(imp, "内功攻击修正率") + util.num(imp, "魔法攻击修正率"))
end

function std_impact_091:get_refix_hp_max(imp, args)
    util.add_rate(args, util.num(imp, "MAX_HP修正率"))
end

return std_impact_091
