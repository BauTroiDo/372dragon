local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_454 = class("std_talent_454", base)
function std_talent_454:is_specific_impact(data_index)
    return data_index >= 705 and data_index <= 716
end

function std_talent_454:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_454:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local rage_damage = logic:get_rage_modify(imp)
            if rage_damage < 0 then
                local value = self:get_refix_value(talent, level)
                reciver:mana_increment(rage_damage * value, sender, false)
            end
        end
    end
end

return std_talent_454