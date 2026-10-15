-- 凌云破空：凌神式(技能835)的距离增加至X米
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_920 = class("std_talent_920", base)

function std_talent_920:refix_skill_info(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 835 then
        local params = talent.params[level]
        local new_range = params[1] or 0
        skill_info:set_optimal_range_max(new_range)
    end
end

return std_talent_920
