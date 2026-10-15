local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_132 = class("std_talent_132", base)
function std_talent_132:is_specific_skill(skill_info)
    return skill_info.id == 450
end

function std_talent_132:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_132:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info) then
        local value = self:get_refix_value(talent, level)
        local p = skill_info:get_give_target_impact().p
        skill_info:set_give_target_impact_p(p + value)
    end
end

return std_talent_132