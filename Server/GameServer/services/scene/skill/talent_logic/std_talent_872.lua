local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_872 = class("std_talent_872", base)
local GUANGLING_BUFF_ID = 63084 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)

function std_talent_872:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_872:refix_skill_info(talent, level, skill_info, sender)
	if skill_info:get_skill_id() ~= 780 then
		return
	end
	local guangling_imp = sender:impact_get_first_impact_of_specific_data_index(GUANGLING_BUFF_ID)
	if guangling_imp then
		if sender._872_guangling_used then
			return
		end
		sender._872_guangling_used = true
		local value = self:get_refix_value(talent, level)
		if value > 0 then
			local rate_up = skill_info:get_mind_attack_rate_up()
			rate_up = rate_up + value / 100
			skill_info:set_mind_attack_rate_up(rate_up)
		end
	else
		sender._872_guangling_used = nil
	end
end

return std_talent_872