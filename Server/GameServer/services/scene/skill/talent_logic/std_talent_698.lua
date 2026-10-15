local class = require "class"
local define = require "define"
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_698 = class("std_talent_698", base)

function std_talent_698:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_698:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_data_index() == 50024 then
		local value = self:get_talent_value(talent,level)
		if value > 0 then
			local logic = impactenginer:get_logic(imp)
			if logic then
				logic:set_value_of_refix_mind_defend(imp, value)
			end
		end
	end
end

return std_talent_698