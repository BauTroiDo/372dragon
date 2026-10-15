local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_734 = class("std_talent_734", base)

function std_talent_734:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_734:refix_impact(talent, level, imp, sender, reciver)
	local buffid = imp:get_data_index()
	if buffid >= 1031 and buffid <= 1042 then
		if imp:get_skill_id() == 349 then
			local value = self:get_talent_value(talent, level)
			if value > 0 then
				value = value / 100 * -1
				local logic = impactenginer:get_logic(imp)
				if logic then
					logic:set_value_of_refix_hit_rate(imp,value)
				end
			end
		end
	end
end

return std_talent_734