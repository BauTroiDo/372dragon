local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_816 = class("std_talent_816", base)

function std_talent_816:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_816:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_data_index() == 50054 then
		local logic = impactenginer:get_logic(imp)
		if logic then
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				logic:set_increase_probability(imp,value)
			end
		end
	end
end

return std_talent_816