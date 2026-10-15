local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impact = require "scene.skill.impact"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"
local std_impact_530 = class("std_impact_530", base)
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK
--IDCollections.txt  重楼带关联效果
std_impact_530.control_effect = {40,41,42,43,44,130,131,132,133,134,135,137,321,332}
--IDCollections.txt  重楼带清除效果
std_impact_530.control_empty_effect = {5,6,40,41,42,43,44,45,52,53,60,130,131,132,133,134,135,137,321,332}

function std_impact_530:is_over_timed()
    return true
end

function std_impact_530:is_intervaled()
    return false
end

function std_impact_530:get_exceeded_player_damage_above_hp_limit_percent(imp)
    return imp.params["受玩家伤害超血上限%"] or 0
end

function std_impact_530:get_hp_below_percent_trigger(imp)
    return imp.params["血量低于百分比触发"] or 0
end

function std_impact_530:get_trigger_effect_rate(imp)
    return imp.params["触发机率"] or 0
end

function std_impact_530:get_trigger_effect(imp)
    return imp.params["触发效果"] or 0
end

function std_impact_530:get_cool_down_id(imp)
    return imp.params["冷却ID"] or -1
end

function std_impact_530:get_cool_down_time_milliseconds(imp)
    return imp.params["冷却时间(毫秒)"] or -1
end

function std_impact_530:get_calculate_total_damage_taken(imp)
    return imp.params["累计受到伤害"]
end

function std_impact_530:set_calculate_total_damage_taken(imp,value)
	imp.params["累计受到伤害"] = value
end

function std_impact_530:reset_calculate_total_damage_taken(imp,value)
	if not imp.params["累计受到伤害"] then
		imp.params["累计受到伤害"] = value
	end
end

function std_impact_530:on_damages(imp, obj, damages, caster_obj_id)
	local attacker = obj:get_scene():get_obj_by_id(caster_obj_id)
	if attacker then
		local cool_down_id = self:get_cool_down_id(imp)
		local cool_down_time = self:get_cool_down_time_milliseconds(imp)
		if cool_down_id > define.OTHER_SKILL_OR_STATUS_COOLDOWN and cool_down_time > 0 then
			local cur_damage = self:get_calculate_total_damage_taken(imp)
			if cur_damage and obj:get_cool_down(cool_down_id) == 0 then
				local attacker = obj:get_scene():get_obj_by_id(caster_obj_id)
				if attacker:get_obj_type() == "human" then
					if damages and damages.damage_rate then
						local key = DAMAGE_TYPE_BACK[1]
						table.insert(damages[key],imp)
					end
				end
			end
		end
		local add_impact = self:get_trigger_effect(imp)
		if add_impact ~= -1 then
			local need_hp = self:get_hp_below_percent_trigger(imp)
			if need_hp > 0 then
				if obj:get_hp() <= obj:get_max_hp() * need_hp / 100 then
					if math.random(100) <= self:get_trigger_effect_rate(imp) then
						impactenginer:send_impact_to_unit(obj, add_impact, attacker, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp), imp:get_skill_id())
					end
				end
			end
		end
	end
	
end

function std_impact_530:on_damages_back(imp, obj, damage_value)
	local cur_damage = self:get_calculate_total_damage_taken(imp)
	if cur_damage then
		cur_damage = cur_damage + damage_value
		local value = self:get_exceeded_player_damage_above_hp_limit_percent(imp)
		if value > 0 then
			local value = value * obj:get_max_hp() / 100
			if cur_damage >= value then
				local cool_down_time = self:get_cool_down_time_milliseconds(imp)
				obj:set_cool_down(self:get_cool_down_id(imp),cool_down_time)
				obj:empty_all_control(self.control_empty_effect)
				local msg = string.format("重楼御身:清除所有负面效果,冷却%d秒。",cool_down_time // 1000)
				obj:notify_tips(msg)
			else
				self:set_calculate_total_damage_taken(imp,cur_damage)
			end
		end
	end
end

return std_impact_530