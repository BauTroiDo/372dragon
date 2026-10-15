local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_721 = class("std_talent_721", base)
local impacts = {
    51664, 51665, 51666, 51667, 51668
}

function std_talent_721:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_721:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == 318
	and imp:get_logic_id() == 20 then
		imp:set_is_out()
		local impact = impacts[level] or -1
		if impact ~= -1 then
			impactenginer:send_impact_to_unit(reciver, impact, sender, 0, false, 0)
		end
	end
end

return std_talent_721