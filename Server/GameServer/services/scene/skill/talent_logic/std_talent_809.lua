local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_809 = class("std_talent_809", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_talent_809:is_specific_skill(skill_id)
    return skill_id == 461
end

function std_talent_809:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_809:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    if self:is_specific_skill(skill_id) then
		if reciver:get_obj_type() == "human" then
			if imp and imp:is_critical_hit() then
				local value = self:get_refix_value(talent, level)
				if value > 0 then
					if damages and damages.damage_rate then
						local key = DAMAGE_TYPE_BACK[6]
						table.insert(damages[key],{rate = value})
					end
				end
			end
		end
	end
end

return std_talent_809