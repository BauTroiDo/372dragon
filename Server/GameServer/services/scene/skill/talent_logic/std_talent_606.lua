local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_606 = class("std_talent_606", base)
function std_talent_606:is_specific_impact(data_index)
    return data_index >= 21252 and data_index <= 21267
end

function std_talent_606:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_606:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local value = self:get_refix_value(talent, level)
        local continuance = imp:get_continuance()
        imp:set_continuance(continuance + value * 1000)
    end
end

return std_talent_606