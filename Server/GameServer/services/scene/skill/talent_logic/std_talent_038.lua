local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_038 = class("std_talent_038", base)
function std_talent_038:is_specific_skill(skill_id)
    return skill_id == 301
end

function std_talent_038:get_value(talent, level, cls)
    local params = talent.params[level]
    return params[cls] or 0
end

function std_talent_038:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
        if imp:get_logic_id() == 12 then
            local logic = impactenginer:get_logic(imp)
            if logic then
                local value = logic:get_value_of_refix_hp_max(imp) + self:get_value(talent, level, 1)
                logic:set_value_of_refix_hp_max(imp, value)
            end
        elseif imp:get_logic_id() == 5 then
            local logic = impactenginer:get_logic(imp)
            if logic then
                local value = logic:get_hp_modify_percent(imp) + self:get_value(talent, level, 21)
                logic:set_hp_modify_percent(imp, value)
            end
        end
    end
end

return std_talent_038