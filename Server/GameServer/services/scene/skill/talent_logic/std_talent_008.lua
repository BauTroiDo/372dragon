local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_008 = class("std_talent_008", base)
function std_talent_008:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_008:on_skill_miss(talent, level, sender, reciver, skill_id)
    local odd = self:get_odd(talent, level)
    local num = math.random(100)
    if num <= odd then
        reciver:strike_point_increment(1, reciver)
    end
end

return std_talent_008