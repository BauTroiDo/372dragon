local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_085 = class("std_talent_085", base)
function std_talent_085:is_specific_skill(skill_id)
    return skill_id == 431
end

function std_talent_085:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_085:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local odd = self:get_odd(talent, level)
        local num = math.random(100)
        if num <= odd then
            sender:rage_increment(30)
        end
    end
end

return std_talent_085