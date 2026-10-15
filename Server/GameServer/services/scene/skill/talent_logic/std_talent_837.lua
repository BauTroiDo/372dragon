local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_837 = class("std_talent_837", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK
local impacts = {
	51768,
	51769,
	51770,
	51771,
	51772,
}

function std_talent_837:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end
function std_talent_837:on_skill_miss_target(talent, level, sender, reciver, skill_id)
	if skill_id == 493 then
		local impact = impacts[level] or -1
		if impact ~= -1 then
			impactenginer:send_impact_to_unit(sender, impact, sender, 0, false, 0)
		end
	end
end


return std_talent_837