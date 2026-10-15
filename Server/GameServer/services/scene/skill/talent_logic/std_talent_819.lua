local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_819 = class("std_talent_819", base)

function std_talent_819:is_specific_skill(skill_id)
    return skill_id == 475
end

function std_talent_819:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_819:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		local params = sender:get_targeting_and_depleting_params()
		local target_obj_id = params:get_target_obj()
		local reciver = sender:get_scene():get_obj_by_id(target_obj_id)
		if reciver then
			if reciver:impact_get_first_impact_of_specific_data_index_2(63080,29870) then -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
				local percent = self:get_refix_value(talent, level)
				if percent > 0 then
					local give_target = skill_info:get_give_target_impact()
					give_target.p = give_target.p + percent
				end
			end
		end
	end
end

return std_talent_819