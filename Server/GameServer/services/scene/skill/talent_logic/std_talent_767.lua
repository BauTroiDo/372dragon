local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_767 = class("std_talent_767", base)

function std_talent_767:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_767:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 411 then
		if imp:get_logic_id() == 10 then
			local value = self:get_refix_value(talent, level)
			if value then
				local logic = impactenginer:get_logic(imp)
				if logic then
					logic:set_add_buff(imp,51710)
					logic:set_add_buff_rate(imp,value)
				end
			end
		end
	end
end

return std_talent_767