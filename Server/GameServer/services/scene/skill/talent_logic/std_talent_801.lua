local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_801 = class("std_talent_801", base)

function std_talent_801:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_801:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() == 451 then
		if imp:get_logic_id() == 15 then
			local rate = self:get_refix_value(talent, level)
			if rate > 0 then
				local poison = sender:get_attrib("att_poison")
				rate = -1 * rate * poison / 100
				local logic = impactenginer:get_logic(imp)
				if logic then
					logic:set_damage_modifier_to_target(imp, rate)
					logic:set_target_guid(imp, sender:get_guid())
				end
			end
		end
	end
end

return std_talent_801