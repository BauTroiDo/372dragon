local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_705 = class("std_talent_705", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_talent_705:is_specific_skill(skill_id)
    return skill_id == 319
end

function std_talent_705:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_705:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		if reciver and reciver:get_obj_type() == "monster" then
			if damages and damages.damage_rate then
				local value = self:get_refix_value(talent, level)
				if value > 0 then
					local key = DAMAGE_TYPE_BACK[4]
					table.insert(damages[key],{rate = value})
					damages.recover_hp_rate_enable = true
				end
			end
		end
	end
end



return std_talent_705