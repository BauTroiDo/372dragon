local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_824 = class("std_talent_824", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_824:is_specific_skill(skill_id)
    return skill_id == 501
end

function std_talent_824:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_824:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		local value = self:get_refix_value(talent, level)
		if value > 0 then
			if damages and damages.damage_rate then
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					damages[key] = damages[key] + value
				end
			end
		end
	end
end

return std_talent_824