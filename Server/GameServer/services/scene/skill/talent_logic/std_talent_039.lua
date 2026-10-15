local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_039 = class("std_talent_039", base)
local impacts = { 50026, 50027, 50028, 50029, 50030}
function std_talent_039:is_specific_skill(skill_id)
    return skill_id == 287
end

function std_talent_039:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_039:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
    if self:is_specific_skill(skill_info.id) then
        cool_down_time = 15 * 1000
    end
    -- 调试输出已屏蔽
    -- print("refix_skill_cool_down_time skill_id =", skill_info.id, ";cool_down_time =", cool_down_time)
    return cool_down_time
end

function std_talent_039:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local data_index = impacts[level]
        impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
    end
end

return std_talent_039