local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_657 = class("std_talent_657", base)
function std_talent_657:is_specific_skill(skill_id)
    return skill_id == 803
end

function std_talent_657:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_657:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_skill(imp:get_skill_id()) then
        if imp:get_logic_id() == 3 then
            local logic = impactenginer:get_logic(imp)
            local cold_damage = logic:get_damage_posion(imp)
            local value = self:get_refix_value(talent, level)
            logic:set_damage_posion(imp, cold_damage + value)
        end
    end
end

return std_talent_657