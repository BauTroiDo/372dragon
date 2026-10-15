local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_749 = class("std_talent_749", base)

function std_talent_749:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_749:refix_impact(talent, level, imp, sender, reciver)
	if sender:get_obj_id() ~= reciver:get_obj_id() then return end
	if imp:get_skill_id() == 382 then
		if imp:get_logic_id() == 4 then
			local max_mp = sender:get_attrib("mp_max") or 0
			local mp = sender:get_attrib("mp") or 0
			if max_mp > 0 and mp <= max_mp * 0.3 then
				local value = self:get_talent_value(talent, level)
				if value > 0 then
					local logic = impactenginer:get_logic(imp)
					if logic then
						local mp_modify = logic:get_mp_modify(imp)
						if mp_modify > 0 then
							local bonus = math.ceil(mp_modify * value / 100)
							if bonus > 0 then
								sender:mana_increment(bonus, sender)
							end
						end
					end
				end
			end
		end
	end
end

return std_talent_749