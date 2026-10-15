-- 问心无愧/落绮濯衣：七霞映日(技能819)额外使自身受到的会心伤害降低X%
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_948 = class("std_talent_948", base)

function std_talent_948:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == 819 then
        if imp:get_logic_id() == 12 then
            local params = talent.params[level]
            local percent = params[1] or 0
            local logic = impactenginer:get_logic(imp)
            if logic then
                local cur = logic:get_value_of_refix_attrib_critical_def(imp)
                logic:set_value_of_refix_attrib_critical_def(imp, cur + percent)
            end
        end
    end
end

return std_talent_948
