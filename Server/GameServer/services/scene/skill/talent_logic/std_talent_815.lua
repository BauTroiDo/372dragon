local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_815 = class("std_talent_815", base)

function std_talent_815:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_815:refix_impact(talent, level, imp, sender, reciver)
	-- if imp:get_skill_id() == 488 then
		local impact = imp:get_data_index()
		if impact == 50055 then
			imp:set_continuance(6000)
			if reciver:impact_get_first_impact_of_specific_data_index(63078) then -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
				impactenginer:send_impact_to_unit(reciver, 63003, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
			end
		elseif impact == 50059 then
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				imp:set_continuance(value * 1000)
			end
		end
	-- end
end

return std_talent_815