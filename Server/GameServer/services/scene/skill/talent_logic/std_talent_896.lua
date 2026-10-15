local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_896 = class("std_talent_896", base)

function std_talent_896:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0,params[2] or 0
end

function std_talent_896:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 810 then
		if imp:get_logic_id() == 14 then
			local value1,value2 = self:get_refix_value(talent, level)
			if value1 > 0 and value2 > 0 then
				local impact = imp:get_data_index()
				if impact >= 49081 and impact <= 49096 then
					imp:set_continuance(value1 * 1000)
				else
					imp:set_continuance(value2 * 1000)
				end
			end
		end
	end
end

return std_talent_896