local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_492 = class("std_talent_492", base)
function std_talent_492:is_specific_impact(data_index)
    return data_index >= 1282 and data_index <= 1293
end

function std_talent_492:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_492:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local value = self:get_refix_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            local refix_value = logic:get_value_of_refix_mind_attack(imp)
            refix_value = math.ceil(refix_value * (100 +value) / 100)
            logic:set_value_of_refix_mind_attack(imp, refix_value)
        end
    end
end

return std_talent_492