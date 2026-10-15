local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_659 = class("std_talent_659", base)

function std_talent_659:is_specific_skill(skill_id)
    return skill_id == 795
end


function std_talent_659:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_659:on_critical_hit_target(talent, level, human, obj_tar, skill_id)
    if self:is_specific_skill(skill_id) then
		if obj_tar:get_obj_type() == "human" then
			local odd = self:get_refix_value(talent, level)
			local num = math.random(100)
			if num <= odd then
				local hp_health = math.ceil(human:get_max_hp() * 3 / 100)
				human:health_increment(hp_health, human, false, nil)
			end
		end
    end
end

return std_talent_659

