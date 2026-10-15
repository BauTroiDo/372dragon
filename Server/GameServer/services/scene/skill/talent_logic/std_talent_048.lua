local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_048 = class("std_talent_048", base)
local skills = {
    [313] = true,
    [325] = true
}
function std_talent_048:is_specific_skill(skill_id)
    return skills[skill_id]
end

function std_talent_048:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_048:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info.id) then
        local rate_up = skill_info:get_accuracy_rate_up()
        rate_up = rate_up + self:get_refix_value(talent, level)
        skill_info:set_accuracy_rate_up(rate_up)
    end
end

return std_talent_048