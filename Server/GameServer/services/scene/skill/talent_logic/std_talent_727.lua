local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_727 = class("std_talent_727", base)

function std_talent_727:is_specific_skill(skill_id)
    return skill_id == 351
end

function std_talent_727:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end
function std_talent_727:on_critical_hit_target(talent, level, sender, reciver, skill_id)
    local skill_info = sender:get_skill_info()
	if skill_info then
		if self:is_specific_skill(skill_info.id) then
			local value = self:get_refix_value(talent, level)
			if math.random(100) <= value then
				local impact = skill_info:get_give_self_impact_index(1)
				if impact ~= define.INVAILD_ID then
					impactenginer:send_impact_to_unit(sender, impact, sender, 0, false, 0)
				end
			end
		end
	end
end


return std_talent_727