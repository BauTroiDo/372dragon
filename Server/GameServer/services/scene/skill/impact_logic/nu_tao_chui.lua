local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local nu_tao_chui = class("nu_tao_chui", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function nu_tao_chui:is_over_timed()
    return true
end

function nu_tao_chui:is_intervaled()
    return false
end

function nu_tao_chui:get_combo_skill_id(imp)
	return imp.params["连续技ID"] or -1
end

function nu_tao_chui:on_active(imp,obj)
	 obj:set_shenbind_status(imp:get_data_index())
end

function nu_tao_chui:on_fade_out(imp, obj)
	obj:set_shenbind_status(0)
end

function nu_tao_chui:on_damage_target(imp, obj, target, damages, skill_id, damage_imp)
	if skill_id and skill_id ~= -1 then
		local buffid = imp.params["会心一击时获得效果"] or -1
		if buffid ~= -1 then
			if damage_imp then
				if damage_imp:is_critical_hit() then
					impactenginer:send_impact_to_unit(target,buffid,obj,0, true, 0,damage_imp:get_skill_id())
				end
			end
		end
	end
end

return nu_tao_chui