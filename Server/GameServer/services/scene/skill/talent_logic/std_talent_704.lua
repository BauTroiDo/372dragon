local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_704 = class("std_talent_704", base)

-- function std_talent_704:is_specific_skill(skill_id)
    -- return skill_id == 335
-- end

function std_talent_704:get_talent_value(talent,level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_704:on_die(talent, level, sender, reciver, skill_id)
	if reciver:impact_get_first_impact_of_specific_data_index(63067) then -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
		local odd = self:get_talent_value(talent, level)
		local num = math.random(100)
		if num <= odd then
			local cool_down_id = skillenginer:get_skill_template(3293,"cool_down_id")
			if cool_down_id then
				local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
				sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
			end
		end
	end
end

return std_talent_704