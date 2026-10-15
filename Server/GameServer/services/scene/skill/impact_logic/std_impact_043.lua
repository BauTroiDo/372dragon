-- server-impact: logic 43 (tlbb15 STD_IMPACT_043 中冲破抗冰火玄…): sửa kháng 4 hệ theo điểm (âm = phá kháng).
-- Nhãn: 怒气增长修正, 冰抗性修正, 火抗性修正, 电抗性修正, 毒抗性修正.
-- 怒气增长修正: skynet có key rage_regenerate kiểu hệ số (std_impact_060: (100+v)/100) → dùng cùng quy ước.
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local std_impact_043 = class("std_impact_043", base)

function std_impact_043:is_over_timed()
    return true
end

function std_impact_043:is_intervaled()
    return false
end

function std_impact_043:get_refix_def_cold(imp, args)
    util.add_point(args, util.num(imp, "冰抗性修正"))
end

function std_impact_043:get_refix_def_fire(imp, args)
    util.add_point(args, util.num(imp, "火抗性修正"))
end

function std_impact_043:get_refix_def_light(imp, args)
    util.add_point(args, util.num(imp, "电抗性修正"))
end

function std_impact_043:get_refix_def_poison(imp, args)
    util.add_point(args, util.num(imp, "毒抗性修正"))
end

function std_impact_043:get_refix_rage_regenerate(imp)
    local value = util.num(imp, "怒气增长修正", 0)
    if value == 0 or value == -1 then
        return nil
    end
    return (100 + value) / 100
end

return std_impact_043
