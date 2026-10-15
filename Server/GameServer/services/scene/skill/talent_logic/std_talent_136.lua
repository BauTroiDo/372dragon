local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_136 = class("std_talent_136", base)
function std_talent_136:is_specific_skill(skill_id)
    return skill_id == 463
end

function std_talent_136:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_136:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id)  then
        local percent = self:get_refix_value(talent, level)
        if imp:get_logic_id() == 3 then
            local logic = impactenginer:get_logic(imp)
            if logic then
                local damage = logic:get_damage_direct(imp)
                damage = math.ceil(damage * ( 100 + percent) / 100)
                logic:set_damage_direct(imp, damage)
            end
        end
    end
end

return std_talent_136