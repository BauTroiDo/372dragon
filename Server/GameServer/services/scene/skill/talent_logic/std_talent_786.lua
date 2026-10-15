local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_786 = class("std_talent_786", base)

function std_talent_786:is_specific_skill(skill_id)
    return skill_id == 451
end

function std_talent_786:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_786:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		local percent = self:get_refix_value(talent, level)
		if percent > 0 then
			local rate_up = skill_info:get_mind_attack_rate_up()
			rate_up = rate_up + percent / 100
			skill_info:set_mind_attack_rate_up(rate_up)
		end
	end
end

return std_talent_786