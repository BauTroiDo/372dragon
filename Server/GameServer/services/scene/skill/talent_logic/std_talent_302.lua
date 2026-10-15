local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_302 = class("std_talent_302", base)

function std_talent_302:is_specific_skill(skill_id)
    return skill_id == 433
end

function std_talent_302:refix_skill_info(talent, level, skill_info, human)
    if self:is_specific_skill(skill_info:get_skill_id()) then
        local rate_up = skill_info:get_accuracy_rate_up()
        local value = self:get_refix_value(talent, level)
        rate_up = rate_up + value
        skill_info:set_accuracy_rate_up(rate_up)
    end
end

return std_talent_302