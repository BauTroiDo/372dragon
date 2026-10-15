-- 化气纵横：化气式(技能833)的命中率提高X%
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_945 = class("std_talent_945", base)

function std_talent_945:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == 833 then
        if imp:get_logic_id() == 3 then
            local params = talent.params[level]
            local percent = params[1] or 0
            local logic = impactenginer:get_logic(imp)
            if logic then
                local hit = logic:get_hit(imp)
                hit = hit + percent
                logic:set_hit(imp, hit)
            end
        end
    end
end

return std_talent_945
