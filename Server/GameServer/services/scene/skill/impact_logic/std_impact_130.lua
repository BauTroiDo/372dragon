-- server-impact: logic 130 (tlbb15 STD_IMPACT_130 金玉满堂): nâng giới hạn dưới của "giảm kháng" theo hệ.
-- Nhãn: 冰减抗下限, 火减抗下限, 玄减抗下限, 毒减抗下限 → key refix reduce_def_<hệ>_low_limit (đã có ở std_impact_014/064/327).
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local std_impact_130 = class("std_impact_130", base)

function std_impact_130:is_over_timed()
    return true
end

function std_impact_130:is_intervaled()
    return false
end

function std_impact_130:get_refix_reduce_def_cold_low_limit(imp, args)
    util.add_point(args, util.num(imp, "冰减抗下限"))
end

function std_impact_130:get_refix_reduce_def_fire_low_limit(imp, args)
    util.add_point(args, util.num(imp, "火减抗下限"))
end

function std_impact_130:get_refix_reduce_def_light_low_limit(imp, args)
    util.add_point(args, util.num(imp, "玄减抗下限"))
end

function std_impact_130:get_refix_reduce_def_poison_low_limit(imp, args)
    util.add_point(args, util.num(imp, "毒减抗下限"))
end

return std_impact_130
