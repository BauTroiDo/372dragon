local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_700 = class("std_talent_700", base)

function std_talent_700:is_specific_skill(skill_id)
    return skill_id == 301
end

function std_talent_700:get_talent_value(talent,level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_700:refix_impact(talent, level, imp, sender, reciver)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
		if imp:get_logic_id() == 12 then
			local value = self:get_talent_value(talent,level)
			if value > 0 then
				local continuance = imp:get_continuance() + value * 1000
				continuance = continuance > 0 and continuance or 0
				imp:set_continuance(continuance)
			end
		end
    end
end

return std_talent_700