local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_699 = class("std_talent_699", base)

function std_talent_699:is_specific_skill(skill_id)
    return skill_id == 306
end

function std_talent_699:get_talent_value(talent,level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_699:refix_impact(talent, level, imp, sender, reciver)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
		if sender ~= reciver and imp:get_logic_id() == 123 then
			local value = self:get_talent_value(talent,level)
			if value > 0 then
				local logic = impactenginer:get_logic(imp)
				if logic then
					value = value + logic:get_target_beaing_rate(imp)
					logic:set_target_beaing_rate(imp, value)
				end
			end
		end
    end
end

return std_talent_699