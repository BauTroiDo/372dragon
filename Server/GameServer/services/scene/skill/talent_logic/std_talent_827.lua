local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_827 = class("std_talent_827", base)

function std_talent_827:is_specific_skill(skill_id)
    return skill_id == 501
end

function std_talent_827:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_827:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		if sender:impact_get_first_impact_of_specific_data_index_2(63081,2200) then -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				local give_self = skill_info:get_give_self_impact()
				give_self.p = give_self.p + value
			end
		end
	end
end

return std_talent_827