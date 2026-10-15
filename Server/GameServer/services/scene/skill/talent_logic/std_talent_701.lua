local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_701 = class("std_talent_701", base)
local impacts = {
    51641, 51642, 51643, 51644, 51645
}


function std_talent_701:is_specific_skill(skill_id)
    return skill_id == 293
end

-- function std_talent_701:get_talent_value(talent,level)
    -- local params = talent.params[level]
    -- return params[1] or 0
-- end

function std_talent_701:refix_impact(talent, level, imp, sender, reciver)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
		-- if imp:get_logic_id() == 17 then
			-- local value = self:get_talent_value(talent,level)
			value = impacts[level] or -1
			if value ~= -1 then
				impactenginer:send_impact_to_unit(sender, value, sender, 0, false, 0)
			end
		-- end
    end
end

return std_talent_701