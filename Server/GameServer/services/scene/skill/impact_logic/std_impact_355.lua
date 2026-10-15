local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_355 = class("std_impact_355", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
function std_impact_355:is_over_timed()
    return true
end

function std_impact_355:is_intervaled()
    return false
end

function std_impact_355:get_refix_hp_max(imp, args)
    local rate = imp.params["MAX_HP修正%"] or 0
    rate = math.floor(rate)
    args.rate = (args.rate or 0) + rate
end

function std_impact_355:get_reduce_cold_damage_rate(imp)
    return imp.params["减少伤害%"]
end

function std_impact_355:on_damages(imp, obj, damages, caster_obj_id, is_critical, skill_id)
	local percent = self:get_reduce_cold_damage_rate(imp)
	if damages and damages.damage_rate then
		for _,j in ipairs(DAMAGE_TYPE_RATE) do
			damages[j] = damages[j] - percent
		end
	-- else
		-- damages.hp_damage = 0
		-- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
			-- damages[i] = math.floor((damages[i] or 0) * (100 - percent) / 100)
			-- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
		-- end
	end
end

return std_impact_355