local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_720 = class("std_talent_720", base)

function std_talent_720:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0,params[2] or 0
end

function std_talent_720:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == 331
	and imp:get_logic_id() == 11 then
		local value1,value2 = self:get_talent_value(talent, level)
		if value1 > 0 and value2 > 0 then
			local logic = impactenginer:get_logic(imp)
			if logic then
				value1 = value1 + logic:get_value_of_refix_att_fire(imp)
				logic:set_value_of_refix_att_fire(imp,value1)
				logic:set_value_of_reduce_def_fire(imp,value2)
				imp:set_impact_id(7595)
			end
		end
	end
end

return std_talent_720