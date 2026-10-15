local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_894 = class("std_talent_894", base)

function std_talent_894:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_894:on_skill_miss_target(talent, level, sender, reciver, skill_id)
	if skill_id == 791 then
		local skill_info = sender:get_skill_info()
		if skill_info.id == skill_id then
			if math.random(100) <= self:get_refix_value(talent, level) then
				descriptor = skill_info:get_descriptor()
				if descriptor["自身获得的BUFF"] and descriptor["自身获得的BUFF"] ~= -1 then
					impactenginer:send_impact_to_unit(sender, descriptor["自身获得的BUFF"], sender, 0, false, 0)
				end
			end
		end
	end
end


return std_talent_894