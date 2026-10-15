local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_126 = class("std_talent_126", base)
function std_talent_126:is_specific_impact(impact_id)
    return impact_id == 152
end

function std_talent_126:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end
function std_talent_126:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        if imp:get_logic_id() == 14 then
            local value = self:get_refix_value(talent, level)
            local logic = impactenginer:get_logic(imp)
			value = value > 0 and 0 - value or value
            logic:set_value_of_refix_speed(imp, value)
        end
    end
end

return std_talent_126