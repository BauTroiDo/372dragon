local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_828 = class("std_talent_828", base)

function std_talent_828:is_specific_skill(skill_id)
    return skill_id == 493
end

function std_talent_828:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_828:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		local value = self:get_refix_value(talent, level)
		if math.random(100) <= value then
			local cool_down_id = skillenginer:get_skill_template(492,"cool_down_id")
			if cool_down_id then
				local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
				sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
			end
		end
	end
end



return std_talent_828