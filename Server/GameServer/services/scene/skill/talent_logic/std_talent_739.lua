local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_739 = class("std_talent_739", base)
function std_talent_739:is_specific_skill(skill_info)
    return skill_info.id == 342
end

function std_talent_739:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_739:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info) then
        local mind_attack_rate_up = skill_info:get_mind_attack_rate_up()
        local value = self:get_refix_value(talent, level)
        skill_info:set_mind_attack_rate_up(mind_attack_rate_up + (value / 100))
    end
end

return std_talent_739