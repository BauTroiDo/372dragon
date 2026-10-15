local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_838 = class("std_talent_838", base)
function std_talent_838:is_specific_skill(skill_id)
    return skill_id == 516
end

function std_talent_838:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_838:on_use_skill_success_fully(talent, level, skill_info, human)
    local skill_id = skill_info:get_skill_id()
    if self:is_specific_skill(skill_id) then
		local value = self:get_talent_value(talent, level)
		if value > 0 then
			value = value * 1000
			local cool_down_id = skillenginer:get_skill_template(248,"cool_down_id")
			if cool_down_id then
				human:update_cool_down_by_cool_down_id(cool_down_id, value)
			end
			cool_down_id = skillenginer:get_skill_template(514,"cool_down_id")
			if cool_down_id then
				human:update_cool_down_by_cool_down_id(cool_down_id, value)
			end
		end
	end
end

return std_talent_838