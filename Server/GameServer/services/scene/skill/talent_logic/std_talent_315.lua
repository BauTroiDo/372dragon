local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_315 = class("std_talent_315", base)
function std_talent_315:is_specific_impact(impact_data_index)
    return impact_data_index >= 1721 and impact_data_index <= 1732
end

function std_talent_315:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_315:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = self:get_refix_value(talent, level)
            local base_value = logic:get_rate_of_hp_recover(imp)
            base_value = base_value + (value)
            logic:set_rate_of_hp_recover(imp, base_value)
        end
    end
end

return std_talent_315