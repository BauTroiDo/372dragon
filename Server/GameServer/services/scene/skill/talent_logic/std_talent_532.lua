local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_512 = class("std_talent_512", base)
function std_talent_512:is_specific_impact(data_index)
    return data_index >= 29887 and data_index <= 29902
end

function std_talent_512:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_512:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local value = self:get_refix_value(talent, level)
        imp:set_interval(value * 1000)
    end
end

return std_talent_512