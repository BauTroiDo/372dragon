local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_814 = class("std_talent_814", base)

function std_talent_814:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_814:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 488 then
		if imp:get_logic_id() == 523 then
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				value = value * 1000 + imp:get_continuance()
				imp:set_continuance(value)
			end
		end
	end
end

return std_talent_814