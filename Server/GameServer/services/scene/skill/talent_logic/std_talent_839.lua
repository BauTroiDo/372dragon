local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_839 = class("std_talent_839", base)

function std_talent_839:is_specific_skill(skill_id)
    return skill_id == 505 or skill_id == 501
end

function std_talent_839:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_839:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		local value = self:get_refix_value(talent, level)
		if value > 0 then
			local cool_down_id = skillenginer:get_skill_template(493,"cool_down_id")
			if cool_down_id then
				sender:update_cool_down_by_cool_down_id(cool_down_id, value * 1000)
			end
		end
	end
end



return std_talent_839