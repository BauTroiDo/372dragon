local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_811 = class("std_talent_811", base)

-- function std_talent_811:is_specific_skill(skill_id)
    -- return skill_id == 454
-- end

function std_talent_811:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_811:refix_skill_info(talent, level, skill_info, sender)
	local params = sender:get_targeting_and_depleting_params()
	local target_obj_id = params:get_target_obj()
	local reciver = sender:get_scene():get_obj_by_id(target_obj_id)
	if reciver and reciver:get_obj_type() == "human" then
		local imp = reciver:impact_get_first_impact_of_specific_data_index_2(2012,2023)
		if imp then
			local percent = self:get_refix_value(talent, level)
			if percent > 0 then
				local max_mp = sender:get_max_mp()
				max_mp = max_mp * percent / 100
				if reciver:get_max_mp() < max_mp then
					local rate_up = skill_info:get_mind_attack_rate_up()
					rate_up = rate_up + 0.03
					skill_info:set_mind_attack_rate_up(rate_up)
				end
			end
		end
	end
end

return std_talent_811