local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_874 = class("std_talent_874", base)
-- function std_talent_874:is_specific_skill(skill_id)
    -- return skill_id == 768
-- end

function std_talent_874:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_874:trigger_talent_cost(talent, level, cost, sender)
	if cost and cost > 0 then
        local value = self:get_refix_value(talent, level)
		if value > 0 then
			local cool_down_id = skillenginer:get_skill_template(787,"cool_down_id")
			if cool_down_id then
				sender:update_cool_down_by_cool_down_id(cool_down_id, value * cost * 1000)
			end
		end
	end
end

return std_talent_874