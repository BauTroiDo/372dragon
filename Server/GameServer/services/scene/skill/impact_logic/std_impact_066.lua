local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_066 = class("std_impact_066", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_066:is_over_timed()
    return true
end

function std_impact_066:is_intervaled()
    return false
end

function std_impact_066:get_absorption_percent(imp)
    return ((imp.params["吸收百分率"] or 0) / 100)
end

function std_impact_066:get_cost_percent(imp)
    return ((imp.params["消耗百分率"] or 100) / 100)
end

function std_impact_066:set_cost_percent(imp, percent)
    imp.params["消耗百分率"] = percent
end

function std_impact_066:on_damages(imp, obj, damages)
	if damages and damages.damage_rate then
		local idx = DAMAGE_TYPE_BACK[1]
		table.insert(damages[idx],imp)
		-- local percent = self:get_absorption_percent(imp)
		-- local hp_damage = damage_value
		-- local all_mp = obj:get_attrib("mp")
		-- local mp_damage = math.ceil(hp_damage * percent)
		-- local cost_percent = self:get_cost_percent(imp)
		-- mp_damage = math.ceil(mp_damage * cost_percent)
		-- mp_damage = mp_damage > all_mp and all_mp or mp_damage
		
		-- self:mana_increment(mp_damage, sender)
		
	end
end
function std_impact_066:on_damages_back(imp, obj, damage_value,sender)
	if damage_value <= 0 then
		return 0
	elseif not obj or obj:get_obj_type() ~= "human" then
		return 0
	end
	local cur_mp = obj:get_attrib("mp")
	if cur_mp < 1 then
		return 0
	end
	local percent = self:get_absorption_percent(imp)
	if percent > 0 then
		local mp_damage = damage_value * percent
		local cost_percent = self:get_cost_percent(imp)
		local mp_damage_new = mp_damage * cost_percent
		if mp_damage_new > cur_mp then
			mp_damage = mp_damage - (mp_damage_new - cur_mp)
			mp_damage_new = cur_mp
		end
		obj:mana_increment(-1 * mp_damage_new, sender)
		return mp_damage
	end
	return 0
end

return std_impact_066