local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_624 = class("std_talent_624", base)
function std_talent_624:is_specific_skill(skill_info)
    return skill_info.id == 791
end

function std_talent_624:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_624:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info) then
        local accuracy_rate_up = skill_info:get_accuracy_rate_up()
        local value = self:get_refix_value(talent, level)
        skill_info:set_accuracy_rate_up(accuracy_rate_up + value)
    end
end

return std_talent_624