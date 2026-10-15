local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_728 = class("std_talent_728", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

function std_talent_728:is_specific_skill(skill_id)
    return skill_id == 343
end

function std_talent_728:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_728:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		local strike_point = sender:get_strike_point()
		if strike_point > 0 then
			local value = self:get_refix_value(talent, level)
			if math.random(100) <= value then
				sender:strike_point_increment(-1 * strike_point, sender)
				local cool_down_id = skillenginer:get_skill_template(343,"cool_down_id")
				if cool_down_id then
					local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
					--cool_down_time = cool_down_time - strike_point * 1000
					cool_down_time = cool_down_time - (strike_point // define.STRIKE_POINT_SEGMENT_SIZE) * 4000
					sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
					
				end
			end
		end
	end
end



return std_talent_728