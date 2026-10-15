local class = require "class"
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"
local std_impact_349 = class("std_impact_349", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_349:is_over_timed()
    return true
end

function std_impact_349:is_intervaled()
    return false
end

function std_impact_349:get_damage_up_rate(imp)
    return imp.params["会心一击伤害+"] or 0
end

function std_impact_349:on_damage_target(imp, sender, reciver, damages, skill_id, damage_imp)
    local is_critical_hit = false
    if damage_imp then
        is_critical_hit = damage_imp:is_critical_hit()
    end
    if is_critical_hit then
        local percent = self:get_damage_up_rate(imp)
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + percent
			end
		end
        -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
            -- damages[i] = math.floor((damages[i] or 0) * (100 + percent) / 100)
            -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
        -- end
    end
end


return std_impact_349