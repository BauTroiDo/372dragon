local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_552 = class("std_talent_552", base)
function std_talent_552:is_specific_impact(impact_data_index)
    return impact_data_index >= 1975 and impact_data_index <= 1986
end

function std_talent_552:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_552:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = self:get_refix_value(talent, level)
            do
                logic:set_value_of_refix_def_cold(imp, 0)
                logic:set_value_of_refix_def_fire(imp, 0)
                logic:set_value_of_refix_def_light(imp, 0)
                logic:set_value_of_refix_def_poison(imp, 0)
            end
            do
                logic:set_value_of_reduce_def_cold(imp, value)
                logic:set_value_of_reduce_def_fire(imp, value)
                logic:set_value_of_reduce_def_light(imp, value)
                logic:set_value_of_reduce_def_poison(imp, value)
            end
        end
    end
end

return std_talent_552