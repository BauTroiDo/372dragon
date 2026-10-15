local class = require "class"
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"
local std_impact_345 = class("std_impact_345", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_345:is_over_timed()
    return true
end

function std_impact_345:is_intervaled()
    return false
end

function std_impact_345:get_refix_speed(imp, args)
    local value = imp.params["移动速度修正%（0为无效）"]
    args.rate = (args.rate or 0) + value
end

function std_impact_345:get_damage_up_rate(imp)
    return imp.params["自身伤害提高%（0为无效）"] or 0
end

function std_impact_345:on_damage_target(imp, sender, reciver, damages, skill_id)
    local percent = self:get_damage_up_rate(imp)
	if percent ~= 0 then
		if damages and damages.damage_rate then
			for _,key in ipairs(DAMAGE_TYPE_RATE) do
				damages[key] = damages[key] + percent * 10
			end
		end
		-- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
			-- damages[i] = math.floor((damages[i] or 0) * (100 + percent) / 100)
			-- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
		-- end
	end
end


return std_impact_345