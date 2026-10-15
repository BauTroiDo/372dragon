-- 心潮澎湃：击鼓令(技能818)额外使自身的内功攻击增加原效果的X%
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_929 = class("std_talent_929", base)

function std_talent_929:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == 818 then
        if imp:get_logic_id() == 12 then
            local params = talent.params[level]
            local percent = params[1] or 0
            local logic = impactenginer:get_logic(imp)
            if logic then
                local cur = logic:get_value_of_refix_attrib_att_magic(imp)
                local bonus = math.ceil(cur * percent / 100)
                logic:set_value_of_refix_attrib_att_magic(imp, cur + bonus)
            end
        end
    end
end

return std_talent_929
