local class = require "class"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_501 = class("std_impact_501", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_501:is_over_timed()
    return true
end

function std_impact_501:is_intervaled()
    return false
end

function std_impact_501:get_impact_self_menpai(imp)
    return imp.params["自身门派ID"] or -1
end
function std_impact_501:get_impact_target_menpai(imp)
    return imp.params["目标门派ID"] or -1
end

function std_impact_501:get_impact_damage_percent(imp)
	return imp.params["伤害百分率"] or 0
end

function std_impact_501:set_impact_damage_percent(imp,value)
	imp.params["伤害百分率"] = value
end

function std_impact_501:on_damage_target(imp, obj, target, damages)
    local refix_damage_percent = self:get_impact_damage_percent(imp)
	if refix_damage_percent ~= 0 then
		local selfmp = self:get_impact_self_menpai(imp)
		if selfmp ~= -1 then
			if obj:get_obj_type() ~= "human" then
				return
			end
			if obj:get_menpai() ~= selfmp then
				return
			end
		end
		local targetmp = self:get_impact_target_menpai(imp)
		if targetmp ~= -1 then
			if target:get_obj_type() ~= "human" then
				return
			end
			if target:get_menpai() ~= targetmp then
				return
			end
		end
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + refix_damage_percent
			end
		end
	end
end

return std_impact_501