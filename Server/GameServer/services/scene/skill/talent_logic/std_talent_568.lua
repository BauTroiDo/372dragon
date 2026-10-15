local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_568 = class("std_talent_568", base)
function std_talent_568:is_specific_impact(data_index)
    return data_index >= 2420 and data_index <= 2431
end

function std_talent_568:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_568:get_refix_value_2(talent, level)
    local params = talent.params[level]
    return params[2] or 0
end

function std_talent_568:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = self:get_refix_value(talent, level)
            local value_2 = self:get_refix_value_2(talent, level)
            logic:set_rate_of_refix_attrib_hit(imp, value)
            logic:set_rate_of_refix_attrib_miss(imp, -1 * value_2)
        end
    end
end

return std_talent_568