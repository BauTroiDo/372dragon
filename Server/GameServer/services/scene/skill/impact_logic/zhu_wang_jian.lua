local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local zhu_wang_jian = class("zhu_wang_jian", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function zhu_wang_jian:is_over_timed()
    return true
end

function zhu_wang_jian:is_intervaled()
    return false
end

function zhu_wang_jian:get_combo_skill_id(imp)
	return imp.params["连续技ID"] or -1
end

function zhu_wang_jian:on_active(imp,obj)
	 obj:set_shenbind_status(imp:get_data_index())
end

function zhu_wang_jian:on_fade_out(imp, obj)
	obj:set_shenbind_status(0)
end

function zhu_wang_jian:on_damage_target(imp, obj, target, damages, skill_id)
	if skill_id and skill_id ~= -1
	and damages and damages.damage_rate then
		for _,key in ipairs(DAMAGE_TYPE_RATE) do
			damages[key] = damages[key] + 100
		end
	end
end
return zhu_wang_jian