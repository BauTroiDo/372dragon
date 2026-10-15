local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_619 = class("std_talent_619", base)
function std_talent_619:is_specific_impact(data_index)
    return data_index >= 21431 and data_index <= 21446
end

function std_talent_619:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_619:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = self:get_refix_value(talent, level)
            local rate_up = logic:get_damage_rate(imp, 1)
            rate_up = rate_up + value
            logic:set_damage_rate(imp, 1, rate_up)
        end
    end
end

return std_talent_619