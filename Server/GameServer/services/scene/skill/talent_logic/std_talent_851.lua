local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_851 = class("std_talent_851", base)

function std_talent_851:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_851:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 535 then
		if imp:get_logic_id() == 69 then
			if math.random(100) <= self:get_refix_value(talent, level) then
				local cool_down_id = skillenginer:get_skill_template(535,"cool_down_id")
				if cool_down_id then
					local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
					sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
				end
			end
		end
	end
end

return std_talent_851