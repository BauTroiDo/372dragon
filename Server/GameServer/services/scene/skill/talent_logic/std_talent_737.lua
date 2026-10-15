local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_737 = class("std_talent_737", base)

function std_talent_737:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_737:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 360 then
		if imp:get_logic_id() == 13 then
			local value = self:get_talent_value(talent, level)
			if value > 0 then
				value = value / 100
				local strike_point = reciver:get_strike_point()
				if strike_point > 0 then
					reciver:strike_point_increment(-1 * strike_point, reciver)
					--value = value * strike_point
					local segments = strike_point // define.STRIKE_POINT_SEGMENT_SIZE
					value = value * segments
					local logic = impactenginer:get_logic(imp)
					if logic then
						logic:set_value_of_refix_miss_rate(imp,value)
					end
				end
			end
		end
	end
end

return std_talent_737