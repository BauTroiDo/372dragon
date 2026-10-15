local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_888 = class("std_talent_888", base)

function std_talent_888:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_888:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 799 then
		if imp:get_logic_id() == 13 then
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				local logic = impactenginer:get_logic(imp)
				if logic then
					logic:set_rate_of_refix_attrib_miss(imp, -1 * value)
				end
			end
		end
	end
end

return std_talent_888