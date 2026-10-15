local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_478 = class("std_talent_478", base)
local impacts = { 45936, 45937, 45938, 45939, 45940}
function std_talent_478:is_specific_skill(skill_id)
    return skill_id == 342
end

function std_talent_478:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_478:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info:get_skill_id()) then
        local value = self:get_refix_value(talent, level)
        skill_info:set_radious(value)
    end
end

function std_talent_478:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local impact = impacts[level] or define.INVAILD_ID
        if impact ~= define.INVAILD_ID then
            impactenginer:send_impact_to_unit(reciver, impact, sender, 0, false, 0)
        end
    end
end

return std_talent_478