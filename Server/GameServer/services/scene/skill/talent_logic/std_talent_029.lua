local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_029 = class("std_talent_029", base)
function std_talent_029:is_specific_skill(skill_id)
    return skill_id == 297
end

function std_talent_029:get_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_029:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
        if imp:get_logic_id() == 13 then
            local logic = impactenginer:get_logic(imp)
            if logic then
                local value = logic:get_value_of_refix_mind_attack(imp) + self:get_value(talent, level)
                logic:set_value_of_refix_mind_attack(imp, value)
            end
        end
    end
end

return std_talent_029