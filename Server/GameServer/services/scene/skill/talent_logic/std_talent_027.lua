local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_026 = class("std_talent_026", base)
function std_talent_026:is_specific_skill(skill_id)
    return skill_id == 295
end

function std_talent_026:get_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_026:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local percent = self:get_value(talent, level)
        if imp:get_logic_id() == 14 then
            local logic = impactenginer:get_logic(imp)
            if logic then
                local value = logic:get_value_of_refix_speed(imp)
                value = math.ceil(value * (100 + percent) / 100)
                logic:set_refix_speed(imp, value)
            end
        end
    end
end

return std_talent_026