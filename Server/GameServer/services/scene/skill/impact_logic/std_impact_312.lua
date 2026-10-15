local class = require "class"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_312 = class("std_impact_312", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_312:is_over_timed()
    return true
end

function std_impact_312:is_intervaled()
    return false
end

function std_impact_312:get_impact_id_collection(imp)
    return imp.params["效果集合ID"]
end

function std_impact_312:get_refix_damage_percent(imp)
    return ((imp.params["伤害加强百分率"] or 0) + 100) / 100
end

function std_impact_312:on_damage_target(imp, obj, target, damages)
    local id = self:get_impact_id_collection(imp)
	if not target:impact_get_first_impact_in_specific_collection(id) then
		return
	end
	local refix_damage_percent = imp.params["伤害加强百分率"] or 0
	if refix_damage_percent ~= 0 then
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + refix_damage_percent
			end
		end
	end
    -- local refix_damage_percent = self:get_refix_damage_percent(imp)
    -- print("std_impact_312:on_damage_target refix_damage_percent =", refix_damage_percent)
    -- local hp_damage = math.ceil(damages.hp_damage * refix_damage_percent)
    -- print("std_impact_312:on_damage_target hp_damage =", hp_damage, ";damages.hp_damage =", damages.hp_damage)
    -- damages.hp_damage = hp_damage
end

return std_impact_312