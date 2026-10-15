local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_593 = class("std_talent_593", base)
function std_talent_593:is_specific_skill(skill_id)
    return skill_id == 522
end

function std_talent_593:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_593:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info:get_skill_id()) then
        local percent = self:get_refix_value(talent, level)
        local charge_time = skill_info:get_charge_time()
        charge_time = math.ceil(charge_time * (100 - percent) / 100)
        skill_info:set_charge_time(charge_time)
    end
end

return std_talent_593