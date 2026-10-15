local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_127 = class("std_talent_127", base)
function std_talent_127:is_specific_impact(data_index)
    return data_index >= 2713 and data_index <= 2724
end

function std_talent_127:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_127:refix_impact(talent, level, imp, sender, reciver)
	if not imp then return end
    if self:is_specific_impact(imp:get_data_index()) then
        if imp:get_logic_id() == 70 then
            local percent = self:get_refix_value(talent, level)
            local logic = impactenginer:get_logic(imp)
			if not logic then return end
            do
                local value = logic:get_damage_rage(imp)
                value = math.ceil(value * (100 + percent) / 100)
                logic:set_damage_rage(imp, value)
            end
            do
                local value = logic:get_suck_rage_rate(imp)
                value = math.ceil(value * (100 + percent) / 100)
                logic:set_suck_rage_rate(imp, value)
            end
        end
    end
end

return std_talent_127