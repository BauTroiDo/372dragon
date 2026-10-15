local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_615 = class("std_talent_615", base)
function std_talent_615:is_specific_impact(data_index)
    return data_index >= 21349 and data_index <= 21364
end

function std_talent_615:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_615:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local refix_value = self:get_refix_value(talent, level)
            local base_value = sender:get_mind_attack()
            base_value = math.ceil(base_value * refix_value / 100)
            base_value = base_value + logic:get_value_of_refix_mind_attack(imp)
            logic:set_value_of_refix_mind_attack(imp, base_value)
        end
    end
end

return std_talent_615