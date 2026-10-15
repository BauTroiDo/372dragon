local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_709 = class("std_talent_709", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

function std_talent_709:is_specific_skill(skill_id)
    return skill_id == 321
end

function std_talent_709:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_709:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		local zs_imp = reciver:impact_get_first_impact_of_specific_data_index_2(464,475)
		if zs_imp then
			if damages and damages.damage_rate then
				local value = self:get_refix_value(talent, level)
				if value > 0 then
					local fire = sender:get_attrib("att_fire")
					local key = DAMAGE_TYPE_POINT[7]
					damages[key] = damages[key] + value * fire
					reciver:remove_impact(zs_imp)
					reciver:on_impact_fade_out(zs_imp)
				end
			end
		end
	end
end



return std_talent_709