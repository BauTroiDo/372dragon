-- 气贯八方：气定六合(技能813)的影响范围增加X米
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_916 = class("std_talent_916", base)

function std_talent_916:refix_skill_info(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 813 then
        local params = talent.params[level]
        local add_range = params[1] or 0
        local cur_range = skill_info:get_optimal_range_max()
        skill_info:set_optimal_range_max(cur_range + add_range)
    end
end

return std_talent_916
