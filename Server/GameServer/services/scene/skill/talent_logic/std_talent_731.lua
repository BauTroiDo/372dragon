local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_731 = class("std_talent_731", base)
local impacts = {
	51679,
	51680,
	51681,
	51682,
	51683,
}
-- function std_talent_731:get_refix_value(talent, level)
    -- local params = talent.params[level]
    -- return params[1] or 0
-- end

function std_talent_731:refix_skill_info(talent, level, skill_info, human)
	if skill_info.id == 347 then
		local impact = impacts[level] or -1
		if impact ~= -1 then
			impactenginer:send_impact_to_unit(human, impact, human, 0, false, 0)
		end
	end
end

return std_talent_731