local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_843 = class("std_talent_843", base)

function std_talent_843:is_specific_skill(skill_id)
    return skill_id == 535
end

function std_talent_843:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_843:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		if sender:impact_have_impact_of_specific_impact_id(3877) then
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				local rate_up = skill_info:get_mind_attack_rate_up()
				rate_up = rate_up + value / 100
				skill_info:set_mind_attack_rate_up(rate_up)
			end
		end
	end
end

return std_talent_843