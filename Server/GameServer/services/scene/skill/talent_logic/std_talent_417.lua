local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_417 = class("std_talent_417", base)
function std_talent_417:is_specific_skill(skill_id)
    return skill_id == 763
end

function std_talent_417:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_417:on_critical_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local odd = self:get_odd(talent, level)
        local num = math.random(100)
        if num <= odd then
            sender:datura_flower_increment(1, sender)
        end
    end
end

return std_talent_417