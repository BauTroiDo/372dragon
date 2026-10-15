local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_778 = class("std_talent_778", base)
function std_talent_778:is_specific_skill(skill_id)
    return skill_id == 417
end

function std_talent_778:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_778:on_use_skill_success_fully(talent, level, skill_info, human)
    local skill_id = skill_info:get_skill_id()
    if self:is_specific_skill(skill_id) then
		if math.random(100) <= self:get_odd(talent, level) then
			local cool_down_id = skillenginer:get_skill_template(403,"cool_down_id")
			if cool_down_id then
				local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
				sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
			end
		end
    end
end

return std_talent_778