local class = require "class"
local impactenginer  = require "impactenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"
local std_impact_083 = class("std_impact_083", base)
local DAMAGE_TYPE_ENUM = DI_DamagesByValue_T.enum_DAMAGE_TYPE
local IMMU_INT_2_STR = {
    [DAMAGE_TYPE_ENUM.IDX_DAMAGE_PHY] = "外功伤害免疫标记",
    [DAMAGE_TYPE_ENUM.IDX_DAMAGE_MAGIC] = "内功伤害免疫标记",
    [DAMAGE_TYPE_ENUM.IDX_DAMAGE_COLD] = "冰伤害免疫标记",
    [DAMAGE_TYPE_ENUM.IDX_DAMAGE_FIRE] = "火伤害免疫标记",
    [DAMAGE_TYPE_ENUM.IDX_DAMAGE_LIGHT] = "电伤害免疫标记",
    [DAMAGE_TYPE_ENUM.IDX_DAMAGE_POISON] = "毒伤害免疫标记",
}
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
function std_impact_083:is_over_timed()
    return true
end

function std_impact_083:is_intervaled()
    return false
end

function std_impact_083:get_damage_immunity_flag(imp, type)
    local s = IMMU_INT_2_STR[type]
    return imp.params[s] == 1
end

function std_impact_083:on_damages(imp, obj, damages)
	if damages and damages.damage_rate then
		local immu = self:get_damage_immunity_flag(imp, 0)
		local idx
		-- damages.hp_damage = 0
		for i = DAMAGE_TYPE_ENUM.IDX_DAMAGE_PHY, DAMAGE_TYPE_ENUM.IDX_DAMAGE_POISON do
			local immu = self:get_damage_immunity_flag(imp, i)
			if immu then
				damages[i] = 0
				idx = DAMAGE_TYPE_RATE[i + 1]
				damages[idx] = 0
				idx = DAMAGE_TYPE_POINT[i + 1]
				damages[idx] = 0
			end
			-- damages[i] = damages[i] or 0
			-- damages.hp_damage = damages.hp_damage + damages[i]
		end
		-- damages.hp_damage = math.floor(damages.hp_damage)
		-- damages.hp_damage = damages.hp_damage < 1 and 1 or damages.hp_damage
	end
end

return std_impact_083