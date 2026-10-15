local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local qing_huan_jian = class("qing_huan_jian", base)

function qing_huan_jian:is_over_timed()
    return true
end

function qing_huan_jian:is_intervaled()
    return false
end

function qing_huan_jian:get_combo_skill_id(imp)
	return imp.params["连续技ID"] or -1
end

function qing_huan_jian:on_active(imp,obj)
	 obj:set_shenbind_status(imp:get_data_index())
end

function qing_huan_jian:on_fade_out(imp, obj)
	obj:set_shenbind_status(0)
end

function qing_huan_jian:on_damage_target(imp, obj, target, damages, skill_id, dmg_imp)
	local critical_hit = dmg_imp and dmg_imp:is_critical_hit() or false
	if skill_id and skill_id ~= -1 then
		if skillenginer:get_skill_template(skill_id,"is_shenbing_skill") then
			local new_imp_id = target:impact_qingyan_check(1)
			impactenginer:send_impact_to_unit(target,new_imp_id,obj,0, critical_hit, 0, skill_id)
		end
	end
end
return qing_huan_jian