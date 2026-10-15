local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"
local std_impact_322 = class("std_impact_322", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_322:is_over_timed()
    return true
end

function std_impact_322:is_intervaled()
    return false
end

function std_impact_322:get_take_effect_time(imp)
    return imp.params["开始时间"] or 0
end

function std_impact_322:set_value_of_take_effect_time(imp, time)
    imp.params["开始时间"] = time
end

function std_impact_322:get_take_effect_diff(imp)
    return imp.params["每X秒增加伤害"] or 1
end

function std_impact_322:set_take_effect_diff(imp,value)
    imp.params["每X秒增加伤害"] = value
end

function std_impact_322:get_take_effect_damage_per(imp)
    return imp.params["每X秒增加伤害值"] or 1
end

function std_impact_322:get_active_time(imp)
    return imp.params["激活时间"] or os.time()
end

function std_impact_322:set_active_time(imp, time)
    imp.params["激活时间"] = time
end

function std_impact_322:get_max_add_damage_percent(imp)
    return imp.params["追加伤害上限百分比"] or 10
end

function std_impact_322:set_value_of_max_add_damage_percent(imp, value)
    imp.params["追加伤害上限百分比"] = value
end

function std_impact_322:get_refix_mind_attack(imp, args, obj)
    local value = imp.params["会心攻击+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
    local rate = imp.params["会心攻击+(%)"] or 0
    rate = math.floor(rate)
    args.rate = (args.rate or 0) + rate
end
function std_impact_322:set_value_of_refix_mind_attack(imp, value)
    imp.params["会心攻击+"] = value
end
function std_impact_322:set_value_of_refix_mind_attack_rate(imp, value)
    imp.params["会心攻击+(%)"] = value
end

function std_impact_322:get_skill_mind_attck_rate_up(imp)
    return imp.params["会心一击率"] or 0
end

function std_impact_322:set_skill_mind_attck_rate_up(imp,value)
    imp.params["会心一击率"] = value
end

function std_impact_322:set_trigger_probability(imp,value)
    imp.params["触发概率"] = value
end

function std_impact_322:get_trigger_probability(imp)
    return imp.params["触发概率"]
end

function std_impact_322:refix_critical_rate(imp, critical_rate,skill_info)
	if self:get_trigger_probability(imp) then
		if 431 == skill_info.id then
			critical_rate = critical_rate + self:get_skill_mind_attck_rate_up(imp) / 100
		end
	end
    return critical_rate
end

function std_impact_322:get_curennt_add_damage_percent(imp)
    local active_time = self:get_active_time(imp)
    local now = os.time()
    local diff = now - active_time
    local take_effect_time = self:get_take_effect_time(imp)
    if take_effect_time >= diff then
        return 0
    end
    local take_effect_diff = self:get_take_effect_diff(imp)
    local take_effect_damage_per = self:get_take_effect_damage_per(imp)
    local add_damage_diff = math.floor((diff - take_effect_time) / take_effect_diff)
    local percent = add_damage_diff * take_effect_damage_per
    local max_percent = self:get_max_add_damage_percent(imp)
    percent = percent > max_percent and max_percent or percent
    return percent
end

function std_impact_322:on_active(imp)
    local now = os.time()
    self:set_active_time(imp, now)
end

function std_impact_322:on_damage_target(imp, obj, target, damages)
	local trigger_probability = self:get_trigger_probability(imp)
	if trigger_probability then
		if 431 == imp:get_skill_id() then
			if imp:is_critical_hit() then
				self:set_skill_mind_attck_rate_up(imp,0)
			else
				if math.random(100) <= trigger_probability then
					local rate = self:get_skill_mind_attck_rate_up(imp) + 5
					self:set_skill_mind_attck_rate_up(imp,rate)
				end
			end
		end
	end
    local percent = self:get_curennt_add_damage_percent(imp)
	if damages and damages.damage_rate then
		for _,j in ipairs(DAMAGE_TYPE_RATE) do
			damages[j] = damages[j] + percent
		end
	end
end

return std_impact_322