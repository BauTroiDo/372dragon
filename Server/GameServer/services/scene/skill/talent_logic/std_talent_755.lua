local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_755 = class("std_talent_755", base)
local impacts = {
	51697,
	51698,
	51699,
	51700,
	51701,
}

function std_talent_755:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_755:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 377 then
		local impact = impacts[level] or -1
		if impact ~= -1 then
			impactenginer:send_impact_to_unit(sender, impact, sender, 0, false, 0)
		end
	end
end

return std_talent_755