local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_642 = class("std_talent_642", base)

function std_talent_642:is_specific_skill(skill_id)
    return skill_id == 811
end

function std_talent_642:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_642:on_die(talent, level, sender, reciver, skill_id)
	if self:is_specific_skill(skill_id) then
		local value = self:get_refix_value(talent, level) * 1000
		local target_skill_id = 811
		local cool_down_id = skillenginer:get_skill_template(target_skill_id,"cool_down_id")
		sender:update_cool_down_by_cool_down_id(cool_down_id, value)
	end
end

return std_talent_642