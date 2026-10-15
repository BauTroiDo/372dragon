local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_695 = class("std_talent_695", base)
local impacts = {
    51636, 51637, 51638, 51639, 51640
}

function std_talent_695:is_specific_skill(skill_id)
    return skill_id == 291
end

function std_talent_695:get_give_impact(level)
    return impacts[level] or define.INVAILD_ID
end

function std_talent_695:refix_impact(talent, level, imp, sender, reciver)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
		if imp:get_logic_id() == 11 then
			local impact = self:get_give_impact(level)
			if impact ~= define.INVAILD_ID then
				impactenginer:send_impact_to_unit(sender, impact, sender, 0, false, 0)
			end
		end
    end
end

return std_talent_695