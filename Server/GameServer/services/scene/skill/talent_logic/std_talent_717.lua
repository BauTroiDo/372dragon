local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_717 = class("std_talent_717", base)
function std_talent_717:is_specific_skill(skill_id)
    return skill_id == 315
end

function std_talent_717:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_717:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		local percent = self:get_refix_value(talent, level)
		local n = math.random(100)
		if n <= percent then
			local cool_down_id = skillenginer:get_skill_template(334,"cool_down_id")
			if cool_down_id then
				local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
				sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
			end
		end
	end
end



return std_talent_717