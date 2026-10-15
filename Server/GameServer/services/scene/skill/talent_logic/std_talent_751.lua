local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_751 = class("std_talent_751", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

function std_talent_751:is_specific_skill(skill_id)
    return skill_id == 371
end

function std_talent_751:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_751:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    if self:is_specific_skill(skill_id) then
		if imp and imp:is_critical_hit() then
			local value = self:get_refix_value(talent, level)
			if math.random(100) <= value then
				if damages and damages.damage_rate then
					local curmp = sender:get_mp()
					local key = DAMAGE_TYPE_POINT[7]
					damages[key] = (damages[key] or 0) + math.floor(curmp * 0.03)
				end
			end
		end
	end
end

return std_talent_751