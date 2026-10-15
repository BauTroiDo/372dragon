local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_282 = class("std_talent_282", base)

function std_talent_282:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_282:refix_skill_info(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 415 then
        local rate_up = skill_info:get_accuracy_rate_up()
        local value = self:get_refix_value(talent, level)
        rate_up = rate_up + value
        skill_info:set_accuracy_rate_up(rate_up)
    end
end

return std_talent_282