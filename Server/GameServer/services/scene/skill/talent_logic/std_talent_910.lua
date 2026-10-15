-- 江山几度：剑锁江山(技能827)额外增加X点玄攻击
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_910 = class("std_talent_910", base)

function std_talent_910:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == 827 then
        if imp:get_logic_id() == 3 then
            local params = talent.params[level]
            local value = params[1] or 0
            local logic = impactenginer:get_logic(imp)
            if logic then
                local cur = logic:get_value_of_refix_attrib_att_magic(imp)
                logic:set_value_of_refix_attrib_att_magic(imp, cur + value)
            end
        end
    end
end

return std_talent_910
