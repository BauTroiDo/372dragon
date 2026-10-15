local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_389 = class("std_talent_389", base)
function std_talent_389:is_specific_impact(impact_id)
    return impact_id == 4946
end

function std_talent_389:get_refix_value(talent, level, cls)
    local params = talent.params[level]
    return params[cls] or 0
end

function std_talent_389:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        if imp:get_logic_id() == 304 then
            local logic = impactenginer:get_logic(imp)
            do
                local value = self:get_refix_value(talent, level, 1)
                logic:set_damage_rate(imp, 1, value)
            end
            do
                local value = self:get_refix_value(talent, level, 2)
                logic:set_damage_rate(imp, 4, value)
            end
        end
    end
end

return std_talent_389