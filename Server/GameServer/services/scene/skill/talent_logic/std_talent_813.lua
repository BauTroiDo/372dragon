local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_813 = class("std_talent_813", base)

function std_talent_813:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_813:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_data_index() == 50058 then
		local value = self:get_refix_value(talent, level)
		if value > 0 then
			local max_attr = math.max(
			sender:get_attrib("att_cold"),
			sender:get_attrib("att_fire"),
			sender:get_attrib("att_light"),
			sender:get_attrib("att_poison"))
			value = value * max_attr / 100
			local logic = impactenginer:get_logic(imp)
			if logic then
				logic:set_talent_813_value(imp,  value)
			end
		end
	end
end

return std_talent_813