-- server-impact: logic 67 (tlbb15 StdImpact067 开膛(伤半血NPC))
-- Nhãn: 发生几率 (%), 伤害最小值, 当前生命值的百分比伤害 (% máu HIỆN TẠI của mục tiêu).
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local std_impact_002 = require "scene.skill.impact_logic.std_impact_002"
local std_impact_067 = class("std_impact_067", base)

function std_impact_067:is_over_timed()
    return false
end

function std_impact_067:is_intervaled()
    return false
end

function std_impact_067:calc_damage(imp, obj, roll)
    local odds = util.num(imp, "发生几率", 100)
    roll = roll or math.random(100)
    if roll > odds then
        return 0
    end
    local rate = util.num(imp, "当前生命值的百分比伤害", 0)
    local damage = math.floor((obj:get_hp() or 0) * rate / 100)
    return math.max(damage, util.num(imp, "伤害最小值", 0))
end

function std_impact_067:on_active(imp, obj)
    if not imp or not obj or not obj:is_alive() then
        return
    end
    local damage = self:calc_damage(imp, obj)
    if damage <= 0 then
        return
    end
    obj:on_damages(std_impact_002.build_direct_damages(damage), imp:get_caster_obj_id(), imp:is_critical_hit(), imp:get_skill_id(), imp)
end

return std_impact_067
