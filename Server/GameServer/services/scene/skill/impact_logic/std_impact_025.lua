local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_025 = class("std_impact_025", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_025:is_over_timed()
    return true
end

function std_impact_025:is_intervaled()
    return false
end

function std_impact_025:get_odds(imp)
    return imp.params["生效几率"]
end

function std_impact_025:on_damages(imp, obj, damages, _, is_critical)
    if not is_critical then
        return
    end
	if damages and damages.damage_rate then
		local idx = DAMAGE_TYPE_BACK[1]
		table.insert(damages[idx],imp)
	end
    -- local odd = self:get_odds(imp)
    -- local num = math.random(100)
    -- print("std_impact_025:on_damages num =", num, ";odd =", odd)
    -- if num > odd then
        -- return
    -- end
    -- local pet = obj:get_pet()
    -- if pet == nil then
        -- return
    -- end
    -- local hp_damage = damages.hp_damage
    -- damages.hp_damage = 0
    -- pet:health_increment(-1 * hp_damage, obj, false)
end
function std_impact_025:on_damages_back(imp, obj, damage_value)
	if damage_value <= 0 then
		return 0
	end
    local odd = self:get_odds(imp)
    local num = math.random(100)
    -- print("std_impact_025:on_damages num =", num, ";odd =", odd)
    if num > odd then
        return 0
    end
    local pet = obj:get_pet()
    if not pet then
        return 0
    end
	local subdamage_value = -1 * damage_value
    pet:health_increment(subdamage_value, obj, false)
	return damage_value
end

return std_impact_025