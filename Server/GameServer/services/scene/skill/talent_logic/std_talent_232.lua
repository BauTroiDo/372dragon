local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_232 = class("std_talent_232", base)
function std_talent_232:is_specific_impact(data_index)
    return data_index >= 525 and data_index <= 536
end

function std_talent_232:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_232:refix_impact(talent, level, imp, sender, reciver)
    if imp:is_critical_hit() then
        if self:is_specific_impact(imp:get_data_index()) then
            local logic = impactenginer:get_logic(imp)
            if logic then
                local percent = self:get_refix_value(talent, level)
                logic:refix_power_by_rate(imp, percent)
            end
        end
    end
end

return std_talent_232