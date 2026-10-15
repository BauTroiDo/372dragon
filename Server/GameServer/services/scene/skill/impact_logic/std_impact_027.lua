local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_027 = class("std_impact_027", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_027:is_over_timed()
    return true
end

function std_impact_027:is_intervaled()
    return false
end

function std_impact_027:get_damage_transfer_rate(imp)
    return imp.params["伤害转移率"]
end

function std_impact_027:on_damages(imp, obj, damages)
	if damages and damages.damage_rate then
		local recover_dmg_rate = self:get_damage_transfer_rate(imp)
		if recover_dmg_rate > 0 then
			local idx = DAMAGE_TYPE_BACK[1]
			table.insert(damages[idx],imp)
		end
	end
	
	
end
function std_impact_027:on_damages_back(imp, obj, damage_value,sender)
	if damage_value <= 0 then
		return 0
	end
    local pet = obj:get_pet()
    if not pet then
        return 0
    end
    local hp_damage = math.ceil(damage_value *  self:get_damage_transfer_rate(imp) / 100)
    -- damages.hp_damage = damages.hp_damage - hp_damage
    -- if damages.hp_damage < 0 then
        -- damages.hp_damage = 0
    -- end
    pet:health_increment(-1 * hp_damage, sender, is_critical)
	return hp_damage
end
return std_impact_027