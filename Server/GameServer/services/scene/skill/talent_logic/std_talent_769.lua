local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_769 = class("std_talent_769", base)

function std_talent_769:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_769:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 411 then
		if imp:get_logic_id() == 10 then
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				local cur_time = imp:get_continuance()
				cur_time = cur_time + value * 1000
				imp:set_continuance(cur_time)
			end
		end
	end
end

return std_talent_769