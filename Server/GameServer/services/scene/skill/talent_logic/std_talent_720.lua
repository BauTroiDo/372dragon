local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_720 = class("std_talent_720", base)
-- local impacts = {
    -- 51659, 51660, 51661, 51662, 51663
-- }

function std_talent_720:get_talent_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_720:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == 335
	and imp:get_logic_id() == 81 then
		local value = self:get_talent_value(talent, level)
		if value > 0 then
			local logic = impactenginer:get_logic(imp)
			if logic then
				logic:set_free_chain_attack_prob(imp,value)
			end
		end
	end
end

return std_talent_720