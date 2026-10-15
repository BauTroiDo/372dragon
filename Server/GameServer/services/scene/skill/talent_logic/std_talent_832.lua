local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_832 = class("std_talent_832", base)

function std_talent_832:is_specific_skill(skill_id)
    return skill_id == 493
end

function std_talent_832:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_832:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		local params = sender:get_targeting_and_depleting_params()
		local target_obj_id = params:get_target_obj()
		local reciver = sender:get_scene():get_obj_by_id(target_obj_id)
		if reciver then
			-- 40，131
			if reciver:impact_have_impact_in_specific_collection(40) then
				skill_info:set_accuracy_rate_up(1)
				local value = self:get_refix_value(talent, level)
				if value > 0 then
					local rate_up = skill_info:get_mind_attack_rate_up()
					rate_up = rate_up + value / 100
					skill_info:set_mind_attack_rate_up(rate_up)
				end
			end
		end
	end
end

return std_talent_832