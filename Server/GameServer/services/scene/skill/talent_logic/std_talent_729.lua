local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_729 = class("std_talent_729", base)
function std_talent_729:is_specific_skill(skill_id)
    return skill_id == 364
end

function std_talent_729:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_729:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		local value = self:get_refix_value(talent, level)
		if value > 0 then
			local cool_down_id = skillenginer:get_skill_template(351,"cool_down_id")
			if cool_down_id then
				local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
				cool_down_time = cool_down_time - value * 1000
				sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
			end
		
		end
	end
end



return std_talent_729