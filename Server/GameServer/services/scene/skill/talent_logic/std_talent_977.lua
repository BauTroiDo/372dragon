local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_977 = class("std_talent_977", base)

local ADDED_SKILL_ID = 848

function std_talent_977:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_977:on_active(talent, level, human)
    if not human:have_skill(ADDED_SKILL_ID) then
        human:add_skill(ADDED_SKILL_ID)
        human:send_skill_list()
    end
end

function std_talent_977:on_remove(talent, level, human)
    if human:have_skill(ADDED_SKILL_ID) then
        human:del_skill(ADDED_SKILL_ID)
    end
end

function std_talent_977:get_add_skill()
    return ADDED_SKILL_ID
end

function std_talent_977:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
    if skill_info:get_skill_id() == ADDED_SKILL_ID then
        return cool_down_time + self:get_refix_value(talent, level) * 1000
    end
    return cool_down_time
end

function std_talent_977:refix_skill_id(talent, level, skill_id)
    if skill_id == 835 then
        return ADDED_SKILL_ID  -- 848
    end
    return nil  -- 不修改
end

return std_talent_977
