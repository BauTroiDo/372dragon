local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_019 = class("std_talent_019", base)
function std_talent_019:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_019:on_skill_miss(talent, level, sender, reciver, skill_id)
    local value = self:get_value(talent, level)
    reciver:rage_increment(value, reciver)
end

return std_talent_019