local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_723 = class("std_talent_723", base)
function std_talent_723:is_specific_skill(skill_id)
    return skill_id == 355
end

function std_talent_723:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_723:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		local percent = self:get_refix_value(talent, level)
		local n = math.random(100)
		if n <= percent then
			sender:strike_point_increment(1, sender)
		end
	end
end



return std_talent_723