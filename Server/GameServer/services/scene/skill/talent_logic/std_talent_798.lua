local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_798 = class("std_talent_798", base)
local impacts = {
	51732,
	51733,
}

function std_talent_798:is_specific_skill(skill_id)
    return skill_id == 435
end

function std_talent_798:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_798:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		local value = self:get_refix_value(talent, level)
		if math.random(100) <= value then
			for _,id in ipairs(impacts) do
				reciver:impact_empty_continuance_elapsed(id)
			end
		end
	end
end



return std_talent_798