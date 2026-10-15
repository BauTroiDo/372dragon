local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_743 = class("std_talent_743", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

function std_talent_743:is_specific_skill(skill_id)
    return skill_id == 371
end

function std_talent_743:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_743:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		if damages and damages.damage_rate then
			if reciver:impact_have_impact_of_specific_mutex_id(14)
			and reciver:impact_have_impact_of_specific_mutex_id(639) then
				local value = self:get_refix_value(talent, level)
				if math.random(100) <= value then
					if reciver:get_obj_type() == "human" then
						table.insert(damages.recover_mp_rate,{rate = 5})
					else
						table.insert(damages.recover_mp_rate,{rate = 2.5})
					end
				end
			end
		end
	end
end

return std_talent_743