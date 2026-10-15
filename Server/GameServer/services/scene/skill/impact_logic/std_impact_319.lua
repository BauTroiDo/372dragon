local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_319 = class("std_impact_319", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_319:is_over_timed()
    return true
end

function std_impact_319:is_intervaled()
    return true
end

function std_impact_319:get_skill_damage_up(imp)
    return imp.params["造成伤害+"] or 0
end


function std_impact_319:get_skill_mind_attck_rate_up(imp)
    return imp.params["会心一击率+"] or 0
end

function std_impact_319:get_recover_hp_rate(imp)
    return imp.params["恢复血量百分比"] or 0
end

function std_impact_319:set_recover_hp_rate(imp, rate)
    imp.params["恢复血量百分比"] = rate
end

function std_impact_319:on_damage_target(imp, _, _, damages)
    local up = self:get_skill_damage_up(imp)
	if damages and damages.damage_rate then
		for _,j in ipairs(DAMAGE_TYPE_RATE) do
			damages[j] = damages[j] + up
		end
	end
	-- damages.hp_damage = 0
    -- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
    -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
        -- damages[i] = math.floor((damages[i] or 0) * (100 + up) / 100)
        -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
    -- end
end

function std_impact_319:refix_critical_rate(imp, critical_rate)
    critical_rate = critical_rate + self:get_skill_mind_attck_rate_up(imp) / 100
    return critical_rate
end

function std_impact_319:on_interval_over(imp, obj)
    if not obj:is_alive() then
        return
    end
    local recover_hp_rate = self:get_recover_hp_rate(imp)
    if recover_hp_rate <= 0 then
        return
    end
    local max_hp = obj:get_max_hp()
    local recover_hp = math.ceil(max_hp * recover_hp_rate / 100)
    obj:health_increment(recover_hp, obj, false)
end


return std_impact_319