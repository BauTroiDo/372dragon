local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_793 = class("std_talent_793", base)

function std_talent_793:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_793:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_data_index() == 51732 then
		local logic = impactenginer:get_logic(imp)
		if logic then
			local poison = sender:get_attrib("att_poison")
			poison = poison * 20 / 100
			logic:set_heartbeat_damage(imp,poison)
		end
		return
	end
	if imp:get_skill_id() == 441 then
		if imp:get_logic_id() == 13 then
			if math.random(100) <= self:get_refix_value(talent, level) then
				impactenginer:send_impact_to_unit(reciver, 63075, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
			end
		end
	end
end

return std_talent_793