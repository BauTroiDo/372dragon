local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_694 = class("std_talent_694", base)
local impacts = {
    51631, 51632, 51633, 51634, 51635
}

function std_talent_694:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_694:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_mutex_id() == 5478 then
		local value = impacts[level] or -1
		if value ~= -1 then
			local logic = impactenginer:get_logic(imp)
			if logic then
				logic:set_add_buff(imp,value)
			end
		end
	end
end

return std_talent_694