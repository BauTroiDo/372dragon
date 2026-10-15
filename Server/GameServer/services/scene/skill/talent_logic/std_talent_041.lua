local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_041 = class("std_talent_041", base)

function std_talent_041:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_041:on_be_hit(talent, level, human, sender, skill)
    local value = self:get_value(talent, level)
    human:rage_increment(value, human)
end

return std_talent_041