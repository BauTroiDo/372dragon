local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_829 = class("std_talent_829", base)

function std_talent_829:is_specific_skill(skill_id)
    return skill_id == 493
end

function std_talent_829:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end
function std_talent_829:on_critical_hit_target(talent, level, sender, reciver, skill_id)
	if self:is_specific_skill(skill_id) then
		local value = self:get_refix_value(talent, level)
		if value > 0 then
			local cool_down_id = skillenginer:get_skill_template(498,"cool_down_id")
			if cool_down_id then
				sender:update_cool_down_by_cool_down_id(cool_down_id, value * 1000)
			end
		end
	end
end


return std_talent_829