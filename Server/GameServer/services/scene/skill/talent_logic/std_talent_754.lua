local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_754 = class("std_talent_754", base)

function std_talent_754:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_754:refix_impact(talent, level, imp, sender, reciver)
	-- if imp:get_skill_id() == 382 then
		if imp:get_impact_id() == 3864 then
			local value = self:get_talent_value(talent, level)
			if value > 0 then
				local logic = impactenginer:get_logic(imp)
				if logic then
					local dist = self:get_remaind_dist(imp)
					logic:set_remaind_dist(imp,dist - value)
				end
			end
		end
	-- end
end

return std_talent_754