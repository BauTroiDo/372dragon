local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_680 = class("std_talent_680", base)
function std_talent_680:is_specific_impact(data_index)
    return data_index >= 49161 and data_index <= 49176
end

function std_talent_680:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_680:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        if imp:get_logic_id() == 4 then
            local percent = self:get_refix_value(talent, level)
            local logic = imp:get_logic(imp)
			local value = logic:get_rage_modify(imp)
			logic:set_rage_modify(imp, value + percent)
        end
    end
end

return std_talent_680