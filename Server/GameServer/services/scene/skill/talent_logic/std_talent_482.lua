local class = require "class"
local define = require "define"
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_255 = class("std_talent_255", base)

function std_talent_255:get_refix_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_255:on_damages(talent, level, damages, obj_me, caster_obj_id, is_critical)
	if damages and damages.mp_damage then
		local mp_damage = math.ceil(damages.mp_damage)
		if mp_damage > 0 then
			local imp = obj_me:impact_get_first_impact_of_specific_impact_id(138)
			if imp then
				local current_mp = obj_me:get_mp()
				if current_mp <= mp_damage then
					obj_me:on_impact_fade_out(imp)
					obj_me:remove_impact(imp)
					local percent = self:get_refix_percent(talent, level)
					local recover_mp = math.ceil(obj_me:get_max_mp() * percent / 100)
					obj_me:mana_increment(recover_mp, obj_me, false)
				end
			end
		end
	end
end

return std_talent_255