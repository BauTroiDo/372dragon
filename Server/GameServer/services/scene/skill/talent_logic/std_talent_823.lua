local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_823 = class("std_talent_823", base)

function std_talent_823:is_specific_skill(skill_id)
    return skill_id == 503
end

function std_talent_823:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_823:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		local descriptor = skill_info:get_descriptor()
		descriptor["效果1"] = -1
		local percent = self:get_refix_value(talent, level)
		if percent > 0 then
			local max_hp = sender:get_max_hp()
			local hp_modify = max_hp * percent / 100
			sender:health_increment(hp_modify, sender)
		end
	end
end

return std_talent_823