local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_724 = class("std_talent_724", base)
function std_talent_724:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_724:refix_skill_info(talent, level, skill_info, human)
	if skill_info.id == 351 then
		local value = self:get_refix_value(talent, level)
		if value > 0 then
			value = value / 100 + skill_info:get_mind_attack_rate_up()
			skill_info:set_mind_attack_rate_up(value)
		end
	end
end

return std_talent_724