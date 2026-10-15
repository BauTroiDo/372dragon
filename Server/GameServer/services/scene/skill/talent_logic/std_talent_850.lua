local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_850 = class("std_talent_850", base)
local impacts = {
	51779,
	51780,
	51781,
	51782,
	51783,
}

function std_talent_850:is_specific_skill(skill_id)
    return skill_id == 535
end

function std_talent_850:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_850:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		local skill_info = sender:get_skill_info()
		if skill_info.id == skill_id then
			if skill_info:get_target_impact_miss() then
				local impact = impacts[level] or -1
				if impact ~= -1 then
					impactenginer:send_impact_to_unit(sender, impact, sender, 0, false, 0)
				end
			end
		end
	end
end

return std_talent_850