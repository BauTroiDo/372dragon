local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_690 = class("std_talent_690", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT


function std_talent_690:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_690:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
	local have_buff = 0
    if reciver:impact_have_impact_of_specific_impact_id(3831) then
		have_buff = 3831
	elseif reciver:impact_have_impact_of_specific_impact_id(346) then
		have_buff = 346
	end
	if have_buff > 0 then
        local percent = self:get_refix_value(talent, level)
		if math.random(100) <= percent then
			local hp_max = sender:get_max_hp()
			local damage = math.ceil(hp_max * 2 / 100)
			if damages and damages.mp_damage then
				local idx = DAMAGE_TYPE_POINT[7]
				damages[idx] = damages[idx] + damage
			end
			if have_buff == 3831 then
				reciver:impact_cancel_impact_in_specific_impact_id(have_buff)
			end
		end
	end
end

return std_talent_690