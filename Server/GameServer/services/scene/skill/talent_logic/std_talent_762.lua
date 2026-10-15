local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_762 = class("std_talent_762", base)
local impacts = {
	51679,
	51680,
	51681,
	51682,
	51683,
}

function std_talent_762:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_762:refix_impact(talent, level, imp, sender, reciver)
	-- if imp:get_skill_id() == 3296 then
		if imp:get_logic_id() == 314 then
			local value = impacts[level]
			if value ~= -1 then
				local logic = impactenginer:get_logic(imp)
				if logic then
					logic:set_add_buff(imp, value)
				end
			end
		end
	-- end
end

return std_talent_762