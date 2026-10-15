local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_097 = class("std_talent_097", base)

function std_talent_097:is_specific_impact(impact_id)
    return impact_id == 131
end

function std_talent_097:is_specific_skill(skill_id)
    return skill_id == 426
end

function std_talent_097:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_097:refix_impact(talent, level, imp, sender, reciver)
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

return std_talent_097