local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_791 = class("std_talent_791", base)

function std_talent_791:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_791:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 431 then
		if imp:get_data_index() == 42881 then
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				local logic = impactenginer:get_logic(imp)
				if logic then
					logic:set_trigger_probability(imp,value)
				end
			end
		end
	end
end

return std_talent_791