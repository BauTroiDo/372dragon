local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_015 = class("std_impact_015", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_015:is_over_timed()
    return true
end

function std_impact_015:is_intervaled()
    return false
end

function std_impact_015:get_refix_str(imp, args)
    local value = imp.params["STR修正(0为无效)"] or 0
    args.point = (args.point or 0) + value
end

function std_impact_015:get_refix_con(imp, args)
    local value = imp.params["Con修正(0为无效)"] or 0
    args.point = (args.point or 0) + value
end

function std_impact_015:get_refix_spr(imp, args)
    local value = imp.params["SPR修正(0为无效)"] or 0
    args.point = (args.point or 0) + value
end

function std_impact_015:get_value_of_refix_spr(imp)
    return imp.params["SPR修正(0为无效)"] or 0
end

function std_impact_015:get_refix_int(imp, args)
    local value = imp.params["INT修正(0为无效)"] or 0
    args.point = (args.point or 0) + value
end

function std_impact_015:get_value_of_refix_int(imp)
    return imp.params["INT修正(0为无效)"] or 0
end

function std_impact_015:set_value_of_refix_int(imp, value)
    imp.params["INT修正(0为无效)"] = value
end

function std_impact_015:get_refix_dex(imp, args)
    local value = imp.params["DEX修正(0为无效)"] or 0
    args.point = (args.point or 0) + value
end

function std_impact_015:get_value_of_refix_dex(imp)
    return imp.params["DEX修正(0为无效)"] or 0
end

function std_impact_015:set_value_of_refix_dex(imp, value)
    imp.params["DEX修正(0为无效)"] = value
end

function std_impact_015:set_damage_modifier_to_target(imp, value)
    imp.params["对目标的伤害修正"] = value
end

function std_impact_015:get_damage_modifier_to_target(imp)
    return imp.params["对目标的伤害修正"] or 0
end

function std_impact_015:set_target_guid(imp, value)
    imp.params["目标GUID"] = value
end

function std_impact_015:get_target_guid(imp)
    return imp.params["目标GUID"] or 0
end

function std_impact_015:on_damage_target(imp, obj, target, damages, skill_id)
	if damages and damages.damage_rate then
		local rate = self:get_damage_modifier_to_target(imp, value)
		if rate ~= 0 then
			if target:get_obj_type() == "human"
			and target:get_guid() == self:get_target_guid(imp) then
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					damages[key] = damages[key] + rate
				end
			end
		end
	end
end



return std_impact_015