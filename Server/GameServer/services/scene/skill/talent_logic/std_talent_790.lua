local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_790 = class("std_talent_790", base)
local impacts = {
	51727,
	51728,
	51729,
	51730,
	51731,
}

function std_talent_790:is_specific_skill(skill_id)
    return skill_id == 433
end

-- function std_talent_790:get_refix_value(talent, level)
    -- local params = talent.params[level]
    -- return params[1] or 0
-- end

function std_talent_790:on_critical_hit_target(talent, level, sender, reciver, skill_id)
	if self:is_specific_skill(skill_id) then
		if math.random(100) <= 75 then
			local cool_down_id = skillenginer:get_skill_template(433,"cool_down_id")
			if cool_down_id then
				local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
				sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
			end
		end
		local impact = impacts[level] or -1
		if impact ~= -1 then
			impactenginer:send_impact_to_unit(sender, impact, sender, 0, false, 0)
		end
	end
end


return std_talent_790