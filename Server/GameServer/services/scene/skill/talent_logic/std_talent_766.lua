local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_766 = class("std_talent_766", base)

function std_talent_766:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_766:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 415 then
		if imp:get_logic_id() == 35 then
			if math.random(100) <= self:get_refix_value(talent, level) then
				local max_hp = sender:get_max_hp()
				local hp_modify = max_hp * 0.05
				sender:health_increment(hp_modify, sender)
			end
		end
	end
end

return std_talent_766