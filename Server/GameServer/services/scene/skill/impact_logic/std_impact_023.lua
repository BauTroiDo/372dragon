local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impact = require "scene.skill.impact"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local ModifyHpMpRageStrikePointByValue_T = require "scene.skill.impact_logic.std_impact_004"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.impact_logic.base"
local std_impact_023 = class("std_impact_023", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_023:is_over_timed()
    return true
end

function std_impact_023:is_intervaled()
    return false
end

function std_impact_023:get_activate_odds(imp)
    return imp.params["生效几率"]
end

function std_impact_023:set_activate_odds(imp, odds)
    imp.params["生效几率"] = odds
end

function std_impact_023:get_damage_tolerance(imp)
    return imp.params["伤害承受率（0为无效）"] or 0
end

function std_impact_023:get_mana_drain_efficiency(imp)
    return imp.params["吸魔效率"]
end

function std_impact_023:get_dispels_rage_efficiency(imp)
    return imp.params["驱散怒气效率"]
end

function std_impact_023:on_damages(imp, obj, damages, caster_obj_id)
    local attacker = obj:get_scene():get_obj_by_id(caster_obj_id)
    if not attacker then
        return
    end
    local odds = self:get_activate_odds(imp)
    local num = math.random(100)
    if num > odds then
        return
    end
    local damage_tolerance = self:get_damage_tolerance(imp)
    if damage_tolerance > 0 then
		if damages and damages.damage_rate then
			if not imp:is_critical_hit() then
				damage_tolerance = damage_tolerance - 100
			end
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				-- damages[j] = damages[j] + damage_tolerance
				damages[j] = damage_tolerance
				
			end
		end
        -- damages.hp_damage = 0
        -- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
        -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
            -- damages[i] = math.floor((damages[i] or 0) * (damage_tolerance / 100))
            -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
        -- end
    end
end
function std_impact_023:on_damage_target(imp, obj, tar)
    local odd = self:get_activate_odds(imp)
    local num = math.random(100)
    if num > odd then
        return
    end
    local rate = self:get_dispels_rage_efficiency(imp)
    if tar then
        local value = math.ceil(1000 * rate / 100)
        tar:rage_increment(-1 * value, obj, false)
    end
end

return std_impact_023