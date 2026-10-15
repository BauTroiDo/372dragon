local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_730 = class("std_talent_730", base)
function std_talent_730:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_730:on_skill_miss(talent, level, sender, reciver, skill_id)
	if sender:impact_have_impact_of_specific_impact_id(131) then
		local odd = self:get_value(talent, level)
		local n = math.random(1, 100)
		if n <= odd then
			local cool_down_id = skillenginer:get_skill_template(343,"cool_down_id")
			if cool_down_id then
				local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
				cool_down_time = cool_down_time - 5000
				sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
			end
		end
	end
end

return std_talent_730