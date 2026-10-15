local class = require "class"
local define = require "define"
local condition_delplete_core = require "scene.skill.condition_delplete_core"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_099 = class("std_talent_099", base)

function std_talent_099:is_specific_impact(impact_id)
    return impact_id == 132
end

function std_talent_099:is_specific_skill(skill_id)
    return skill_id == 411
end

function std_talent_099:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_099:refix_impact(talent, level, imp, sender, reciver)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local impact_id = imp:get_impact_id()
        if self:is_specific_impact(impact_id) then
            local percent = self:get_refix_value(talent, level)
            if imp:get_logic_id() == 4 then
                local logic = impactenginer:get_logic(imp)
                local recover_value = logic:get_hp_modify(imp)
                local value = math.ceil(recover_value * (100 + percent) / 100)
                logic:set_hp_modify(imp, value)
            end
        end
    end
end

function std_talent_099:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info.id) then
        for i = 1,  define.CONDITION_AND_DEPLETE_TERM_NUMBER do
            local term = skill_info.condition_and_deplete[i]
            if term.type == define.ConditionAndDepleteID.CD_MANA_BY_VALUE then
                term.params[1] = math.floor(term.params[1] * (100 + 30) / 100)
            end
        end
    end
end

return std_talent_099