local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_761 = class("std_talent_761", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

function std_talent_761:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_761:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 387 then
		if imp:get_logic_id() == 21 then
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				local logic = impactenginer:get_logic(imp)
				if logic then
					logic:set_value_of_refix_mind_attack_rate(imp, value)
				end
			end
		end
	end
end

return std_talent_761