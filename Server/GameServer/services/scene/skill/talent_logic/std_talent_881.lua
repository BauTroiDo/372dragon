local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_881 = class("std_talent_881", base)

function std_talent_881:is_specific_skill(skill_id)
    return skill_id == 765
end

function std_talent_881:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_881:get_refix_value_2(talent, level)
    local params = talent.params[level]
    return params[2] or 0
end

function std_talent_881:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		local datura_flower = sender:get_datura_flower()
		if datura_flower > 0 then
			local random_num = math.random(100)
			if random_num <= self:get_refix_value_2(talent, level) and datura_flower >= 2 then
				sender:datura_flower_increment(-2, sender)
				impactenginer:send_impact_to_unit(reciver, 63086, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
			elseif random_num <= self:get_refix_value(talent, level) then
				sender:datura_flower_increment(-1, sender)
				impactenginer:send_impact_to_unit(reciver, 63087, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
			end
		end
	end
end

return std_talent_881