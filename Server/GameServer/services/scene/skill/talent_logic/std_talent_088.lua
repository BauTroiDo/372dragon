local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_088 = class("std_talent_088", base)
function std_talent_088:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_088:on_hit_target(talent, level, sender, reciver, skill_id)
    local have = sender:impact_have_impact_of_specific_impact_id(141)
    if have then
        local value = self:get_value(talent, level)
        sender:rage_increment(value, sender)
    end
end

return std_talent_088