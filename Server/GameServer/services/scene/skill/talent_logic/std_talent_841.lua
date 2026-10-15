local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_841 = class("std_talent_841", base)

function std_talent_841:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_841:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 497 then
		if imp:get_logic_id() == 14 then
			if math.random(100) <= self:get_refix_value(talent, level) then
				impactenginer:send_impact_to_unit(sender, 63082, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
				local mypet = sender:get_current_pet()
				if mypet then
					impactenginer:send_impact_to_unit(sender, imp:get_data_index(), sender, 0, false, 0)
					impactenginer:send_impact_to_unit(sender, 63082, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
					impactenginer:send_impact_to_unit(mypet, imp:get_data_index(), sender, 0, false, 0)
					impactenginer:send_impact_to_unit(mypet, 63082, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
				end
			end
		end
	end
end

return std_talent_841