local class = require "class"
local define = require "define"
-- local condition_delplete_core = require "scene.skill.condition_delplete_core"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_799 = class("std_talent_799", base)

function std_talent_799:is_specific_skill(skill_id)
    return skill_id == 454
end

function std_talent_799:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_799:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		local params = sender:get_targeting_and_depleting_params()
		local target_obj_id = params:get_target_obj()
		local reciver = sender:get_scene():get_obj_by_id(target_obj_id)
		if reciver then
			local imp = reciver:impact_get_first_impact_of_specific_data_index_2(29887,29902)
			if imp then
				local percent = self:get_refix_value(talent, level)
				if percent > 0 then
					local logic = impactenginer:get_logic(imp)
					if logic then
						logic:set_value_of_refix_hit_rate(imp,-1 * percent / 100)
					end
				end
			end
		end
	end
end

return std_talent_799