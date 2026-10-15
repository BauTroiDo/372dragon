local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_736 = class("std_talent_736", base)

function std_talent_736:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_736:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 346 then
		if imp:get_logic_id() == 13 then
			if reciver:get_obj_id() == sender:get_obj_id() then
				local value = self:get_talent_value(talent, level)
				if value > 0 then
					value = value / 100
					local logic = impactenginer:get_logic(imp)
					if logic then
						logic:set_value_of_refix_miss_rate(imp,value)
					end
				end
			end
		end
	end
end

return std_talent_736