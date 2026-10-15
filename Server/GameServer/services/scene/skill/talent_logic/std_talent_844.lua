local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_844 = class("std_talent_844", base)
function std_talent_844:is_specific_skill(skill_id)
    return skill_id == 533
end

function std_talent_844:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_844:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info:get_skill_id()) then
		local value = self:get_refix_value(talent, level)
		if value > 0 then
			local rate_up = skill_info:get_mind_attack_rate_up()
			rate_up = rate_up + value / 100
			skill_info:set_mind_attack_rate_up(rate_up)
		end
    end
end

return std_talent_844