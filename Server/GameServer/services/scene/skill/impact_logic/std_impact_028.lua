local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local enum_damage_type = damage_impact_logic.enum_DAMAGE_TYPE
local base = require "scene.skill.impact_logic.base"
local std_impact_028 = class("std_impact_028", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
function std_impact_028:is_over_timed()
    return true
end

function std_impact_028:is_intervaled()
    return false
end

function std_impact_028:get_cold_refix(imp)
    return imp.params["冰系伤害修正%"] or 0
end

function std_impact_028:get_fire_refix(imp)
    return imp.params["火系伤害修正%"] or 0
end

function std_impact_028:get_light_refix(imp)
    return imp.params["电系伤害修正%"] or 0
end

function std_impact_028:get_poison_refix(imp)
    return imp.params["毒系伤害修正%"] or 0
end

function std_impact_028:on_damages(imp, obj, damages)
	local idx
    local cold_refix = self:get_cold_refix(imp)
    if cold_refix ~= 0 then
		idx = DAMAGE_TYPE_RATE[3]
		damages[idx] = damages[idx] + cold_refix
        -- damages[enum_damage_type.IDX_DAMAGE_COLD] = (damages[enum_damage_type.IDX_DAMAGE_COLD] or 0) * math.ceil(cold_refix / 100)
    end
    local fire_refix = self:get_fire_refix(imp)
    if fire_refix ~= 0 then
		idx = DAMAGE_TYPE_RATE[4]
		damages[idx] = damages[idx] + fire_refix
        -- damages[enum_damage_type.IDX_DAMAGE_FIRE] = (damages[enum_damage_type.IDX_DAMAGE_FIRE] or 0) * math.ceil(fire_refix / 100)
    end
    local light_refix = self:get_light_refix(imp)
    if light_refix ~= 0 then
		idx = DAMAGE_TYPE_RATE[5]
		damages[idx] = damages[idx] + light_refix
        -- damages[enum_damage_type.IDX_DAMAGE_LIGHT] = (damages[enum_damage_type.IDX_DAMAGE_LIGHT] or 0) * math.ceil(light_refix / 100)
    end
    local poison_refix = self:get_poison_refix(imp)
    if poison_refix ~= 0 then
		idx = DAMAGE_TYPE_RATE[6]
		damages[idx] = damages[idx] + poison_refix
        -- damages[enum_damage_type.IDX_DAMAGE_POISON] = (damages[enum_damage_type.IDX_DAMAGE_POISON] or 0) * math.ceil(poison_refix / 100)
    end
    -- local damage = 0
    -- for i = 0, 6 do
        -- damage = damage + (damages[i] or 0)
    -- end
    -- damage = math.floor(damage)
    -- damage = damage < 1 and 1 or damage
    -- damages.hp_damage = damage
end

return std_impact_028