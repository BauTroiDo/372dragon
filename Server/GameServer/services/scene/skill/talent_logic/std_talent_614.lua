local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_579 = class("std_talent_579", base)
local impacts = {46045, 46046, 46047, 46048, 46049}
function std_talent_579:is_specific_impact(data_index)
    return data_index >= 44800 and data_index <= 44815
end

function std_talent_579:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_579:get_impact(talent, level)
    return impacts[level] or define.INVAILD_ID
end

function std_talent_579:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local data_index = self:get_impact(talent, level)
        impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
    end
end

return std_talent_579