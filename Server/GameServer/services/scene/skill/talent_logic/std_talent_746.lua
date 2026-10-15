local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_746 = class("std_talent_746", base)
function std_talent_746:is_specific_skill(skill_id)
    return skill_id == 372
end

function std_talent_746:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_746:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		local value = self:get_refix_value(talent, level)
		if value > 0 then
			skill_info:set_radious(value)
			skill_info:set_target_count(8)
		end
    end
end


return std_talent_746