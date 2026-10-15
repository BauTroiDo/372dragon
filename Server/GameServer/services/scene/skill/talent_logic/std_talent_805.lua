local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_805 = class("std_talent_805", base)

function std_talent_805:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_805:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 471 then
		if imp:get_logic_id() == 11 then
			if math.random(100) <= self:get_refix_value(talent, level) then
				sender:rage_increment(50)
			end
		end
	end
end

return std_talent_805