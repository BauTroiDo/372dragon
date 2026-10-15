local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_768 = class("std_talent_768", base)

function std_talent_768:is_specific_skill(skill_id)
    return skill_id == 424
end

function std_talent_768:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_768:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info.id) then
		local percent = self:get_refix_value(talent, level)
		if percent > 0 then
			local term = skill_info:get_condition_and_deplete()
			if term and term.params and term.params[1] and term.params[1] > 0 then
				term.params[1] = math.floor(term.params[1] - term.params[1] * percent / 100)
				if term.params[1] < 0 then
					term.params[1] = 0
				end
			end
		end
    end
end

return std_talent_768