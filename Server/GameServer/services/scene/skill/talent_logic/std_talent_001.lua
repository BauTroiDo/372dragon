local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_001 = class("std_talent_001", base)

function std_talent_001:is_deplete_strike_point_skill(skill_id)
    local template = skillenginer:get_skill_template(skill_id)
    for i = 1, define.CONDITION_AND_DEPLETE_TERM_NUMBER do
        if template and template.condition_and_deplete then
            local term = template.condition_and_deplete[i]
            if term then
                if term.type == define.ConditionAndDepleteID.CD_STRIKE_POINT_BY_SEGMENT then
                    return true
                end
            end
        end
    end
    return false
end

function std_talent_001:is_specific_target_skill(skill_id)
    local template = skillenginer:get_skill_template(skill_id)
    local target_mode = template.targeting_logic
    return target_mode == define.ENUM_TARGET_LOGIC.TARGET_SPECIFIC_UNIT
end

function std_talent_001:get_add_damage_rate(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_001:get_skill_xinfa_id(talent)
    return talent.params["技能心法"] or 0
end

function std_talent_001:is_specific_xinfa_skill(skill_id, talent)
    local xinfa = skillenginer:get_skill_xinfa(skill_id)
    return xinfa == self:get_skill_xinfa_id(talent)
end

function std_talent_001:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_deplete_strike_point_skill(skill_id) and self:is_specific_target_skill(skill_id) then
        local rate = self:get_add_damage_rate(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:refix_power_by_rate(imp, rate)
        end
    end
end

function std_talent_001:get_critical_odd(talent, level)
    local params = talent.params[level]
    return params[2] or 0
end

function std_talent_001:on_critical_hit_target(talent, level, human, obj_tar, skill_id)
    -- [FIX] 控鹤式技能暴击时，10%概率增加2段连击点
    if self:is_specific_xinfa_skill(skill_id, talent) then
        local odd = self:get_critical_odd(talent, level)
        local num = math.random(100)
        if num <= odd then
            human:strike_point_increment(6, human)  -- 2段 × 3点/段 = 6点
        end
    end
end

return std_talent_001