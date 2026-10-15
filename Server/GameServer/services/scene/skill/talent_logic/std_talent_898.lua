local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_898 = class("std_talent_898", base)
function std_talent_898:is_specific_skill(skill_id)
    return skill_id == 796
end

function std_talent_898:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_898:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info:get_skill_id()) then
		local params = sender:get_targeting_and_depleting_params()
		local target_obj_id = params:get_target_obj()
		local reciver = sender:get_scene():get_obj_by_id(target_obj_id)
		if reciver then
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				if reciver:impact_have_impact_of_specific_impact_id(6522) then
					local rate_up = skill_info:get_accuracy_rate_up()
					rate_up = rate_up + value
					skill_info:set_accuracy_rate_up(rate_up)
				end
			end
		end
    end
end

return std_talent_898