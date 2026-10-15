local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_124 = class("std_talent_124", base)
function std_talent_124:is_specific_skill(skill_info)
    return skill_info.id == 435
end

function std_talent_124:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_124:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info) then
        local value = self:get_refix_value(talent, level)
        do
            local charge_time = skill_info:get_charge_time()
            charge_time = charge_time * (100 - value) / 100
            skill_info:set_charge_time(charge_time)
        end
    end
end

return std_talent_124