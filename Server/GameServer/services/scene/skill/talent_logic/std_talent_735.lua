local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_735 = class("std_talent_735", base)
function std_talent_735:is_specific_skill(skill_id)
    return skill_id == 361
end

function std_talent_735:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_735:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		if sender:impact_have_impact_of_specific_impact_id(128) then
			local value = self:get_refix_value(talent, level)
			if math.random(100) <= value then
				impactenginer:send_impact_to_unit(reciver, 63069, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
			end
		end
	end
end



return std_talent_735