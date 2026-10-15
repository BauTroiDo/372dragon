local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_669 = class("std_talent_669", base)
function std_talent_669:is_specific_skill(skill_id)
    return skill_id == 795
end

function std_talent_669:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_669:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		if reciver:get_obj_type() == "human" then
			local odd = self:get_refix_value(talent, level)
			local num = math.random(100)
			if num <= odd then
				-- sender is the character entity; self is only the talent logic object.
				local hp_health = math.ceil(sender:get_max_hp() * 5 / 100)
				sender:health_increment(hp_health, sender, false, nil)
			end
        end
    end
end

return std_talent_669