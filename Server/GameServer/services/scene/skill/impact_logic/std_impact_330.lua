local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"
local std_impact_330 = class("std_impact_330", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_330:is_over_timed()
    return true
end

function std_impact_330:is_intervaled()
    return false
end

function std_impact_330:get_send_impact_id(imp)
    return imp.params["获得效果"] or define.INVAILD_ID
end

function std_impact_330:get_skill_damage_up(imp)
    return imp.params["伤害提升率"] or 0
end

function std_impact_330:set_skill_damage_up(imp, rate)
    imp.params["伤害提升率"] = rate
end

function std_impact_330:get_skill_critical_damage_up(imp)
    return imp.params["会心伤害提升率"] or 200
end

function std_impact_330:set_skill_critical_damage_up(imp, rate)
    imp.params["会心伤害提升率"] = rate
end

function std_impact_330:on_damage_target(imp, sender, reciver, damages, skill_id, damage_imp)
    local rate_up = self:get_skill_damage_up(imp)
	if rate_up ~= 0 then
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + rate_up
			end
		end
	end
    -- damages.hp_damage = 0
    -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
        -- damages[i] = math.floor((damages[i] or 0) * (100 + rate_up) / 100)
        -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
    -- end
    if damage_imp and damage_imp:is_critical_hit() then
        rate_up = self:get_skill_critical_damage_up(imp)
		if rate_up ~= 0 then
			-- if sender:set_is_stealth_flag() then
				-- 276  集合
				for _,j in ipairs(DAMAGE_TYPE_RATE) do
					damages[j] = damages[j] + rate_up
				end
				-- sender:set_is_stealth_flag()
			-- end
		end
        -- damages.hp_damage = 0
        -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
            -- damages[i] = math.floor((damages[i] or 0) * (rate_up) / 200)
            -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
        -- end
    end
    local impact_id = self:get_send_impact_id(imp)
	if impact_id ~= define.INVAILD_ID then
		impactenginer:send_impact_to_unit(sender, impact_id, sender, 0, false, 0)
	end
    sender:remove_impact(imp)
    sender:on_impact_fade_out(imp)
end

return std_impact_330