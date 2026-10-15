local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_899 = class("std_talent_899", base)
function std_talent_899:is_specific_skill(skill_id)
    return skill_id == 808
end

function std_talent_899:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0,params[2] or 0
end

function std_talent_899:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_skill(imp:get_skill_id()) then
		if imp:get_logic_id() == 502 then
			local value1 = self:get_refix_value(talent, level)
			if value1 > 0 then
				local logic = impactenginer:get_logic(imp)
				if logic then
					value1 = value1 * logic:get_end_restore_percentage_health(imp) / 100
					logic:set_end_restore_percentage_health(imp,value1)
				end
			end
		end
	end
end

function std_talent_899:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info:get_skill_id()) then
		local value1,value2 = self:get_refix_value(talent, level)
		if value1 > 0 and value2 > 0 then
			local condition_and_deplete = skill_info:get_condition_and_deplete()
			for _,d in ipairs(condition_and_deplete) do
				if d.type == 11 and d.params[1] ~= -1 then
					d.params[1] = math.ceil(d.params[1] * value1 / 100)
				elseif d.type == 12 and d.params[1] ~= -1 then
					d.params[1] = math.ceil(d.params[1] * value2 / 100)
				end
			end
		end
    end
end

return std_talent_899