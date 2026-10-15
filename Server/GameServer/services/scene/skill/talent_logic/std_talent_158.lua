local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_158 = class("std_talent_158", base)
function std_talent_158:is_specific_skill_id(skill_id)
    return skill_id == 493
end

function std_talent_158:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_158:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
    if self:is_specific_skill_id(skill_info:get_skill_id()) then
        local reduce_count = self:get_refix_value(talent, level)
        reduce_count = reduce_count * 1000
        cool_down_time = cool_down_time - reduce_count
    end
    -- 调试输出已屏蔽
    -- print("refix_skill_cool_down_time skill_id =", skill_info.id, ";cool_down_time =", cool_down_time)
    return cool_down_time
end

return std_talent_158