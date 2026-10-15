local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_825 = class("std_talent_825", base)

function std_talent_825:is_specific_skill(skill_id)
    return skill_id == 501
end

function std_talent_825:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_825:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		local value = self:get_refix_value(talent, level)
		if value > 0 then
			local radious = skill_info:get_radious()
			skill_info:set_radious(radious + value)
		end
	end
end

return std_talent_825