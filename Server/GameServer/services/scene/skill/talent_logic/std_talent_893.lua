local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_893 = class("std_talent_893", base)
local skills = {791,795,797,809}
function std_talent_893:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_893:on_skill_miss_target(talent, level, sender, reciver, skill_id)
	if skill_id == 797 then
		if math.random(100) <= self:get_refix_value(talent, level) then
			local cool_down_id
			for _,skill in ipairs(skills) do
				cool_down_id = skillenginer:get_skill_template(skill,"cool_down_id")
				if cool_down_id then
					sender:update_cool_down_by_cool_down_id(cool_down_id, 2000)
				end
			end
		end
	end
end


return std_talent_893