local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_900 = class("std_talent_900", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_900:is_specific_skill(skill_id)
    return skill_id == 796
end

function std_talent_900:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_900:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		local skill_info = sender:get_skill_info()
		if skill_info.id == skill_id
		and skill_info:get_consume_life_soul_count() >= 3 then
			if damages and damages.damage_rate then
				local skill_lv = skill_info:get_skill_level()
				if skill_lv >= 12 and level >= 5 then
					local rate = 340 - 315
					for _,key in ipairs(DAMAGE_TYPE_RATE) do
						damages[key] = damages[key] + rate
					end
				else
					local rate = self:get_refix_value(talent, level)
					if rate > 0 then
						for _,key in ipairs(DAMAGE_TYPE_RATE) do
							damages[key] = damages[key] + rate
						end
					end
				end
			end
		end
	end
end

return std_talent_900