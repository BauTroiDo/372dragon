local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_808 = class("std_talent_808", base)

function std_talent_808:is_specific_skill(skill_id)
    return skill_id == 463
end

function std_talent_808:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_808:on_critical_hit_target(talent, level, sender, reciver, skill_id)
	if self:is_specific_skill(skill_id) then
		if math.random(100) <= self:get_refix_value(talent, level) then
			local imp = sender:impact_get_first_impact_of_specific_data_index(63024) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
			if imp then
				local data_index = imp:get_data_index()
				sender:on_impact_fade_out(imp)
				sender:remove_impact(imp)
				impactenginer:send_impact_to_unit(sender, data_index, sender, 0, false, 0)
			end
		end
	end
end

return std_talent_808