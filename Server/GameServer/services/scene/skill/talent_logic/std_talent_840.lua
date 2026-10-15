local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_840 = class("std_talent_840", base)

function std_talent_840:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_840:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 511 then
		if imp:get_logic_id() == 14 then
			if imp:is_critical_hit() then
				local value = self:get_refix_value(talent, level)
				if value > 0 then
					--value = value + imp:get_continuance()
					imp:set_continuance(value)
				end
			end
		end
	end
end

return std_talent_840