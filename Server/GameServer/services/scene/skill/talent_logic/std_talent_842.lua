local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_842 = class("std_talent_842", base)
local impacts = {
	51773,
	51774,
	51775,
	51776,
	51777,
}

function std_talent_842:is_specific_skill(skill_id)
    return skill_id == 510
end

-- function std_talent_842:get_talent_value(talent, level)
    -- local params = talent.params[level]
    -- return params[1] or 0
-- end

function std_talent_842:on_use_skill_success_fully(talent, level, skill_info, human)
    local skill_id = skill_info:get_skill_id()
    if self:is_specific_skill(skill_id) then
		local impact = impacts[level] or -1
		if impact ~= -1 then
			impactenginer:send_impact_to_unit(human, impact, human, 0, false, 0)
		end
	end
end

return std_talent_842