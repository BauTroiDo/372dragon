local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_718 = class("std_talent_718", base)
local impacts = {
    51659, 51660, 51661, 51662, 51663
}

function std_talent_718:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_718:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == 319
	and imp:get_logic_id() == 4 then
		local impact = impacts[level] or -1
		local value = self:get_talent_value(talent, level)
		if value > 0 and impact ~= -1 then
			local logic = impactenginer:get_logic(imp)
			if logic then
				logic:set_rage_to(imp,value)
				logic:set_add_buff(imp,impact)
			end
		end
	end
end

return std_talent_718