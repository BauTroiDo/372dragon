-- 风云流转：气定六合(技能813)冷却时间减少X秒
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_905 = class("std_talent_905", base)

function std_talent_905:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_905:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
    if skill_info:get_skill_id() == 813 then
        local reduce_count = self:get_refix_value(talent, level)
        reduce_count = reduce_count * 1000
        cool_down_time = cool_down_time - reduce_count
    end
    return cool_down_time
end

return std_talent_905
