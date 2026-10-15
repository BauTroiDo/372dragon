local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_756 = class("std_talent_756", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

function std_talent_756:is_specific_skill(skill_id)
    return skill_id == 395
end

function std_talent_756:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_756:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		local params = sender:get_targeting_and_depleting_params()
		if params:get_activated_skill() == skill_id then
			if not params:get_talent_id(756) then
				local hit_count = params:get_target_count()
				local value = self:get_refix_value(talent, level)
				if value > 0 and value < hit_count then
					params:set_talent_id(756)
					impactenginer:send_impact_to_unit(sender, 63070, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
				end
			end
		end
	end
end

return std_talent_756