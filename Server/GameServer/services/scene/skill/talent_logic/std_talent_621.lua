local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_621 = class("std_talent_621", base)

function std_talent_621:get_reduce_count(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_621:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
	if talent_id == 621 then
		if skill_info.id == 797 or skill_info.id == 791 or skill_info.id == 795 then
			local reduce_count = self:get_reduce_count(talent, level)
			if reduce_count > 0 then
				reduce_count = reduce_count * 1000
				cool_down_time = reduce_count
			end
			-- print("refix_skill_cool_down_time skill_id =", skill_info.id, ";cool_down_time =", cool_down_time)
		end
	end
    return cool_down_time
end

return std_talent_621