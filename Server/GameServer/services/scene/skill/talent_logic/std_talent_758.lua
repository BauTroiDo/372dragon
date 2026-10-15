local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_758 = class("std_talent_758", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

function std_talent_758:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_758:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 374 then
		if imp:get_logic_id() == 14 then
			if imp:is_critical_hit() then
				local value = self:get_refix_value(talent, level)
				if math.random(100) <= value then
					imp:set_continuance(12000)
				end
			end
		end
	end
end

return std_talent_758