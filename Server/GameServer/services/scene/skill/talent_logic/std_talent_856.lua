local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_856 = class("std_talent_856", base)

-- function std_talent_856:is_specific_skill(skill_id)
    -- return skill_id == 510
-- end

function std_talent_856:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_856:on_use_skill_success_fully(talent, level, skill_info, human)
    local skill_id = skill_info:get_skill_id()
	if skillenginer:is_skill_in_collection(skill_id, 476) then
		if math.random(100) <= self:get_talent_value(talent, level) then
			local cool_down_id = skillenginer:get_skill_template(535,"cool_down_id")
			if cool_down_id then
				human:update_cool_down_by_cool_down_id(cool_down_id, 2000)
			end
		end
	end
end

return std_talent_856