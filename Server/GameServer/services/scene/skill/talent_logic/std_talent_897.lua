local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_897 = class("std_talent_897", base)

function std_talent_897:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_897:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 791 then
		if imp:get_logic_id() == 504 then
			if imp:is_critical_hit() then
				if math.random(100) <= self:get_refix_value(talent, level) then
					imp:set_continuance(20 * 1000)
				end
			end
		end
	end
end

return std_talent_897