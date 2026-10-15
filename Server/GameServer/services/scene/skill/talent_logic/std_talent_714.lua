local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_714 = class("std_talent_714", base)
local impacts = {
    51821, 51822, 51823, 51824, 51825
}

function std_talent_714:is_specific_skill(skill_id)
    return skill_id == 334
end

function std_talent_714:get_talent_value(talent,level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_714:refix_impact(talent, level, imp, sender, reciver)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
		if imp:get_logic_id() == 14 then
			local value = impacts[level] or -1
			if value ~= -1 then
				impactenginer:send_impact_to_unit(reciver, value, sender, 0, false, 0)
			end
		end
	end
end

return std_talent_714