local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_763 = class("std_talent_763", base)

function std_talent_763:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_763:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 409 then
		if imp:get_logic_id() == 29 then
			local value = self:get_refix_value(talent, level)
			if value > 0 then
				local max_mp = sender:get_max_mp()
				value = value * max_mp / 100
				sender:mana_increment(value,sender)
			end
		end
	end
end

return std_talent_763