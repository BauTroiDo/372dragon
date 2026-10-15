local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_545 = class("std_talent_545", base)
function std_talent_545:is_specific_skill(skill_id)
    return skill_id == 462
end

function std_talent_545:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_545:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info:get_skill_id()) then
        local value = self:get_refix_value(talent, level)
        local channel_time = skill_info:get_channel_time()
        skill_info:set_channel_time(math.ceil(channel_time * (100 + value) / 100))
    end
end

return std_talent_545