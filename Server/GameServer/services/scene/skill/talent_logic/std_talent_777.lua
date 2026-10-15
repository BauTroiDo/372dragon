local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_777 = class("std_talent_777", base)

function std_talent_777:is_specific_skill(skill_id)
    return skill_id == 415
end

function std_talent_777:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_777:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		local percent = self:get_refix_value(talent, level)
		if percent > 0 then
			if sender:get_hp() < sender:get_max_hp() / 2 then
				local give_target = skill_info:get_give_target_impact()
				give_target.p = give_target.p + percent
			end
		end
	end
end

return std_talent_777