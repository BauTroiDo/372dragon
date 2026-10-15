local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_105 = class("std_talent_105", base)

function std_talent_105:is_specific_impact(impact_id)
    return impact_id == 23
end

function std_talent_105:is_specific_skill(skill_id)
    return skill_id == 404
end

function std_talent_105:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_105:refix_impact(talent, level, imp, sender, reciver)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local impact_id = imp:get_impact_id()
        if self:is_specific_impact(impact_id) then
            local value = self:get_refix_value(talent, level)
            if imp:get_logic_id() == 14 then
                local logic = impactenginer:get_logic(imp)
                logic:set_value_of_refix_speed(imp, -1 * value)
            end
        end
    end
end

return std_talent_105