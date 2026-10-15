local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_641 = class("std_talent_641", base)

function std_talent_641:is_specific_skill(skill_id)
    return skill_id == 796
end

function std_talent_641:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_641:on_die(talent, level, sender, reciver, skill_id)
	if self:is_specific_skill(skill_id) then
		local value = self:get_refix_value(talent, level)
		local target_skill_id = 796
		local cool_down_id = skillenginer:get_skill_template(target_skill_id,"cool_down_id")
		local cool_down_time = skillenginer:get_skill_info(target_skill_id,"cool_down_time")
		cool_down_time = math.ceil(cool_down_time * value)
		sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
		target_skill_id = 797
		cool_down_id = skillenginer:get_skill_template(target_skill_id,"cool_down_id")
		cool_down_time = skillenginer:get_skill_info(target_skill_id,"cool_down_time")
		cool_down_time = math.ceil(cool_down_time * value)
		sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
		target_skill_id = 791
		cool_down_id = skillenginer:get_skill_template(target_skill_id,"cool_down_id")
		cool_down_time = skillenginer:get_skill_info(target_skill_id,"cool_down_time")
		cool_down_time = math.ceil(cool_down_time * value)
		sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
		target_skill_id = 795
		cool_down_id = skillenginer:get_skill_template(target_skill_id,"cool_down_id")
		cool_down_time = skillenginer:get_skill_info(target_skill_id,"cool_down_time")
		cool_down_time = math.ceil(cool_down_time * value)
		sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
	end
end

return std_talent_641