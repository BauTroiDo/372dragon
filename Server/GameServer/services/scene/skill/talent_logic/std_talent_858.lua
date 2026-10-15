local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_858 = class("std_talent_858", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

function std_talent_858:is_specific_skill(skill_id)
    return skill_id == 522
end

function std_talent_858:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_858:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    if imp and self:is_specific_skill(skill_id) then
		local impact = imp:get_data_index()
		if (impact >= 2452 and impact <= 2463)
		or (impact >= 42889 and impact <= 42900) then
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				if damages and damages.damage_rate then
					local max_attr = math.max(
					sender:get_attrib("att_cold"),
					sender:get_attrib("att_fire"),
					sender:get_attrib("att_light"),
					sender:get_attrib("att_poison")
					)
					local key = DAMAGE_TYPE_POINT[7]
					damages[key] = damages[key] + value * max_attr / 100
				end
			end
		end
	end
end

return std_talent_858