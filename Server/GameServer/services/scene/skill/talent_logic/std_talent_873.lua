local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_873 = class("std_talent_873", base)

function std_talent_873:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_873:refix_impact(talent, level, imp, sender, reciver)
	-- if imp:get_skill_id() == 780 then
		if imp:get_data_index() == 50071 then
			if math.random(100) <= self:get_refix_value(talent, level) then
				sender:datura_flower_increment(1, sender)
			end
		end
	-- end
end

return std_talent_873