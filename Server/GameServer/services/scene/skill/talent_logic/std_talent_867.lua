local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_867 = class("std_talent_867", base)

function std_talent_867:is_specific_skill(skill_id)
    return skill_id == 775
end

function std_talent_867:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_867:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		local value = self:get_refix_value(talent, level)
		if value > 0 then
			local condition_and_deplete = skill_info:get_condition_and_deplete()
			for _,d in ipairs(condition_and_deplete) do
				if d.type == -1 then
					d.desc = "能量点消耗"
					d.type = 14
					d.params[1] = 1
					d.params[2] = -1
					break
				end
			end
			local give_target = skill_info:get_give_target_impact()
			give_target.p = give_target.p + value
		end
	end
end

return std_talent_867