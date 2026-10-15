local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_129 = class("std_talent_129", base)
function std_talent_129:is_specific_impact(data_index)
    return data_index >= 1867 and data_index <= 1878
end

function std_talent_129:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_129:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        if imp:get_logic_id() == 3 then
            local value = self:get_refix_value(talent, level)
            local logic = impactenginer:get_logic(imp)
            local index = logic:get_trigger_index(imp)
            if index == 2 then
                sender:rage_increment(value, sender)
            end
        end
    end
end

return std_talent_129