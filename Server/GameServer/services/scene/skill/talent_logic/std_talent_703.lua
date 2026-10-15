local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_703 = class("std_talent_703", base)

function std_talent_703:is_specific_skill(skill_id)
    return skill_id == 335
end

function std_talent_703:get_talent_value(talent,level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_703:refix_impact(talent, level, imp, sender, reciver)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
		if imp:get_logic_id() == 81 then
			local odd = self:get_talent_value(talent, level)
			local num = math.random(100)
			if num <= odd then
				local template = skillenginer:get_skill_template(3293)
				local cool_down_id = template.cool_down_id
				local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
				sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
			end
		end
	end
end

return std_talent_703