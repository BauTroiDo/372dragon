local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_863 = class("std_talent_863", base)

function std_talent_863:is_specific_skill(skill_id)
    return skill_id == 760
end

function std_talent_863:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end
function std_talent_863:on_critical_hit_target(talent, level, sender, reciver, skill_id)
	if self:is_specific_skill(skill_id) then
		if math.random(100) <= self:get_refix_value(talent, level) then
			sender:datura_flower_increment(1, sender)
		end
	end
end


return std_talent_863