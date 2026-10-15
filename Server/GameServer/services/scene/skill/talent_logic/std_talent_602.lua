local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_602 = class("std_talent_602", base)
function std_talent_602:is_specific_skill(skill_id)
    return skill_id == 761
end

function std_talent_602:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_602:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info:get_skill_id()) then
        local value = self:get_refix_value(talent, level)
        do
            local coll_down_time = skill_info:get_cool_down_time()
            coll_down_time = coll_down_time - value * 1000
            skill_info:set_cool_down_time(coll_down_time)
        end
    end
end

return std_talent_602