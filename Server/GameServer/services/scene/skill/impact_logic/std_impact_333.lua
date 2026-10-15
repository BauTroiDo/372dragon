local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_333 = class("std_impact_333", base)

function std_impact_333:is_over_timed()
    return true
end

function std_impact_333:is_intervaled()
    return false
end

return std_impact_333