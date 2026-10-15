local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_354 = class("std_impact_354", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE



function std_impact_354:is_over_timed()
    return true
end

function std_impact_354:is_intervaled()
    return false
end

function std_impact_354:get_refix_hp_max(imp, args)
    local rate = imp.params["MAX_HP修正%"] or 0
    rate = math.floor(rate)
    args.rate = (args.rate or 0) + rate
end

function std_impact_354:get_reduce_cold_damage_rate(imp)
    return imp.params["减少冰属性伤害%"]
end

function std_impact_354:get_reduce_fire_damage_rate(imp)
    return imp.params["减少火属性伤害%"]
end

function std_impact_354:get_reduce_light_damage_rate(imp)
    return imp.params["减少电属性伤害%"]
end

function std_impact_354:get_reduce_poision_damage_rate(imp)
    return imp.params["减少毒属性伤害%"]
end

function std_impact_354:get_reduce_damage_rate_by_value(imp, value)
    if value == damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_COLD then
        return self:get_reduce_cold_damage_rate(imp)
    elseif value == damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_FIRE then
        return self:get_reduce_fire_damage_rate(imp)
    elseif value == damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_LIGHT then
        return self:get_reduce_light_damage_rate(imp)
    elseif value == damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_POISON then
        return self:get_reduce_poision_damage_rate(imp)
    else
        return 0
    end
end

function std_impact_354:on_damages(imp, obj, damages, caster_obj_id, is_critical, skill_id)
	local percent = self:get_reduce_damage_rate_by_value(imp, i)
	if damages and damages.damage_rate then
		for _,j in ipairs(DAMAGE_TYPE_RATE) do
			damages[j] = damages[j] - percent
		end
	end
	-- else
	-- damages.hp_damage = 0
    -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
        -- damages[i] = math.floor((damages[i] or 0) * (100 - percent) / 100)
        -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
    -- end
end

return std_impact_354