local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_738 = class("std_talent_738", base)
local impacts = {
	51685,
	51686,
	51687,
	51688,
	51689,
}

-- function std_talent_738:get_talent_value(talent, level)
    -- local params = talent.params[level]
    -- return params[1] or 0
-- end

function std_talent_738:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 348 then
		if imp:get_logic_id() == 35 then
			local impact = impacts[level] or -1
			if impact ~= -1 then
				impactenginer:send_impact_to_unit(reciver, impact, sender, 0, false, 0)
			end
		end
	end
end

return std_talent_738